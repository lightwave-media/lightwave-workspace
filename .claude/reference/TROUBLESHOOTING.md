# LightWave Workspace Troubleshooting Guide

**Version**: 1.0.0
**Last Updated**: 2025-10-28
**Purpose**: Document common issues and their solutions in the lightwave-workspace ecosystem

This guide provides solutions to frequently encountered issues across AWS, Git, Infrastructure, Development Environment, and Claude Code operations.

---

## Table of Contents

1. [AWS Issues](#aws-issues)
2. [Git Issues](#git-issues)
3. [Infrastructure Issues](#infrastructure-issues)
4. [Development Environment Issues](#development-environment-issues)
5. [Claude Code Agent Issues](#claude-code-agent-issues)
6. [Quick Reference](#quick-reference)

---

## AWS Issues

### Issue 1: Wrong AWS Profile - "lightwave-email-service not authorized"

#### Symptoms
```bash
An error occurred (AccessDeniedException) when calling the GetParameter operation:
User: arn:aws:iam::738605694078:user/lightwave-email-service is not authorized to perform: ssm:GetParameter
```

Or when running any AWS CLI command:
```bash
# Secrets Manager error
Error: User lightwave-email-service is not authorized to perform: secretsmanager:GetSecretValue

# Parameter Store error
Error: User lightwave-email-service is not authorized to perform: ssm:GetParameter

# S3 error
Error: User lightwave-email-service is not authorized to perform: s3:ListBucket
```

#### Root Cause
The `lightwave-email-service` AWS profile has **limited permissions** (only SES operations). Most operations require the `lightwave-admin-new` profile with full permissions.

**Why this happens**:
- Environment variable `AWS_PROFILE` is not set
- `AWS_PROFILE` is set to wrong profile (`lightwave-email-service` instead of `lightwave-admin-new`)
- Profile was set in previous session but shell was restarted
- Running commands in a new terminal window without setting profile

#### Solution

**Step 1: Set correct AWS profile**
```bash
export AWS_PROFILE=lightwave-admin-new
```

**Step 2: Verify profile is set correctly**
```bash
# Check environment variable
echo $AWS_PROFILE
# Expected output: lightwave-admin-new

# Verify AWS identity
aws sts get-caller-identity
# Expected output should include:
# "Arn": "arn:aws:iam::738605694078:user/lightwave-admin"
# "Account": "738605694078"
```

**Step 3: Retry your command**
```bash
# Example: Load a parameter
aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

#### Prevention

**Add to your shell profile** (`.zshrc`, `.bashrc`, or `.bash_profile`):
```bash
# LightWave AWS default profile
export AWS_PROFILE=lightwave-admin-new
```

**Or create an alias** for switching profiles:
```bash
# Add to ~/.zshrc or ~/.bashrc
alias lw-admin='export AWS_PROFILE=lightwave-admin-new'
alias lw-email='export AWS_PROFILE=lightwave-email-service'
alias lw-check='aws sts get-caller-identity | grep Arn'

# Usage:
# lw-admin     # Switch to admin profile
# lw-email     # Switch to email profile (only for SES)
# lw-check     # Verify current profile
```

**Always verify profile at start of work**:
- Include in your onboarding checklist
- Run `echo $AWS_PROFILE` before any AWS operations
- Look for `lightwave-admin` in the ARN when running `aws sts get-caller-identity`

---

### Issue 2: AWS CLI Configuration Missing or Invalid

#### Symptoms
```bash
# When running AWS CLI commands:
Unable to locate credentials. You can configure credentials by running "aws configure".

# Or:
The config profile (lightwave-admin-new) could not be found
```

#### Root Cause
AWS credentials are not configured in `~/.aws/credentials` or `~/.aws/config`, or the profile name doesn't match.

**Common causes**:
- Fresh machine setup without AWS CLI configuration
- Credentials file was deleted or corrupted
- Wrong profile name in configuration
- AWS CLI not installed

#### Solution

**Step 1: Verify AWS CLI is installed**
```bash
aws --version
# Expected: aws-cli/2.x.x or higher

# If not installed (macOS):
brew install awscli

# If not installed (Linux):
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Step 2: Check if credentials file exists**
```bash
ls -la ~/.aws/
# Should show: credentials, config

# View profiles
cat ~/.aws/credentials
cat ~/.aws/config
```

**Step 3: Configure AWS credentials**

If credentials don't exist, you need to add them:

```bash
# Edit credentials file
vim ~/.aws/credentials

# Add the following (replace with actual credentials):
[lightwave-admin-new]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>

[lightwave-email-service]
aws_access_key_id = <EMAIL_SERVICE_ACCESS_KEY_ID>
aws_secret_access_key = <EMAIL_SERVICE_SECRET_ACCESS_KEY>
```

```bash
# Edit config file
vim ~/.aws/config

# Add the following:
[profile lightwave-admin-new]
region = us-east-1
output = json

[profile lightwave-email-service]
region = us-east-1
output = json
```

**Step 4: Verify configuration**
```bash
export AWS_PROFILE=lightwave-admin-new
aws sts get-caller-identity
# Should show account 738605694078 with user lightwave-admin
```

#### Prevention

- Back up `~/.aws/credentials` and `~/.aws/config` files securely
- Document AWS account setup in team onboarding guide
- Use AWS SSO or IAM Identity Center for team access (future improvement)
- Never commit AWS credentials to git repositories

---

### Issue 3: Secrets Manager Secret Not Found

#### Symptoms
```bash
An error occurred (ResourceNotFoundException) when calling the GetSecretValue operation:
Secrets Manager can't find the specified secret: /lightwave/dev/django/secret-key
```

#### Root Cause
**Possible causes**:
1. Secret ID is misspelled or has wrong path
2. Secret exists in different region (secrets are in `us-east-1`)
3. Wrong AWS profile (doesn't have permission to view)
4. Secret was deleted or never created

#### Solution

**Step 1: Verify AWS profile and region**
```bash
export AWS_PROFILE=lightwave-admin-new
export AWS_DEFAULT_REGION=us-east-1
```

**Step 2: List all secrets to find correct name**
```bash
# List all secrets
aws secretsmanager list-secrets \
  --query 'SecretList[*].Name' \
  --output table

# List secrets with /lightwave/ prefix
aws secretsmanager list-secrets \
  --query 'SecretList[?starts_with(Name, `/lightwave/`)].Name' \
  --output table
```

**Step 3: Get the exact secret ID from list and retry**
```bash
# Copy exact secret ID from list output
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/secret-key \
  --query SecretString \
  --output text
```

**Step 4: If secret truly doesn't exist, create it**
```bash
# Create new secret (example for Django secret key)
aws secretsmanager create-secret \
  --name /lightwave/dev/django/secret-key \
  --description "Django SECRET_KEY for development environment" \
  --secret-string "your-secret-value-here"
```

#### Prevention

- Document all secret IDs in `.claude/reference/SECRETS_MAP.md`
- Use consistent naming convention: `/lightwave/{env}/{service}/{key-name}`
- Always verify secret exists before referencing in code
- Use infrastructure-as-code to create secrets (Terraform/Terragrunt)

---

### Issue 4: Parameter Store Parameter Not Found

#### Symptoms
```bash
An error occurred (ParameterNotFound) when calling the GetParameter operation:
Parameter /lightwave/prod/ANTHROPIC_API_KEY not found
```

#### Root Cause
Similar to Secrets Manager issue - parameter name is wrong, doesn't exist, or wrong region/profile.

#### Solution

**Step 1: Set correct profile and region**
```bash
export AWS_PROFILE=lightwave-admin-new
export AWS_DEFAULT_REGION=us-east-1
```

**Step 2: List all parameters**
```bash
# List all parameters with /lightwave/ prefix
aws ssm get-parameters-by-path \
  --path /lightwave/ \
  --recursive \
  --query 'Parameters[*].Name' \
  --output table

# List only production parameters
aws ssm get-parameters-by-path \
  --path /lightwave/prod/ \
  --recursive \
  --query 'Parameters[*].Name' \
  --output table
```

**Step 3: Get parameter with exact name from list**
```bash
aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

**Step 4: Create parameter if missing**
```bash
# Create new parameter
aws ssm put-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --description "Anthropic Claude API key for production" \
  --value "your-api-key-here" \
  --type SecureString \
  --tier Standard
```

#### Prevention

- Document all parameter names in `.claude/reference/SECRETS_MAP.md`
- Use Parameter Store for API keys and configuration
- Use Secrets Manager for credentials that need rotation (database passwords)
- Tag parameters consistently for easy filtering

---

## Git Issues

### Issue 5: Running Git Commands in Workspace Root vs Sub-Repositories

#### Symptoms
```bash
# When running git commands in workspace root:
fatal: not a git repository (or any of the parent directories): .git

# Or getting confusing results:
git status
# Shows: Not currently on any branch.
# Or shows files from wrong repository
```

**Confusion about which repository you're in**:
- Running `git status` and seeing unexpected files
- Trying to commit but affecting wrong repository
- Branch commands not working as expected

#### Root Cause
The lightwave-workspace is a **multi-repo workspace**. The workspace root (`/Users/joelschaeffer/dev/lightwave-workspace/`) is **not itself a git repository**.

**Directory structure**:
```
/Users/joelschaeffer/dev/lightwave-workspace/  ← NOT a git repo
├── Backend/
│   └── lightwave-backend/                     ← GIT REPO
│       └── .git/
├── Frontend/
│   ├── lightwave-media-site/                  ← GIT REPO
│   │   └── .git/
│   └── joelschaeffer/                         ← GIT REPO
│       └── .git/
└── Infrastructure/
    ├── lightwave-infrastructure-catalog/      ← GIT REPO
    │   └── .git/
    └── lightwave-infrastructure-live/         ← GIT REPO
        └── .git/
```

**Why this happens**:
- Not changing directory to specific repository before running git commands
- Forgetting which repository you're currently in
- Running `git` commands from workspace root by mistake

#### Solution

**Step 1: Identify which repository you need to work in**
```bash
# List all git repositories in workspace
find /Users/joelschaeffer/dev/lightwave-workspace -name ".git" -type d -maxdepth 3

# Example output:
# /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend/.git
# /Users/joelschaeffer/dev/lightwave-workspace/Frontend/lightwave-media-site/.git
# /Users/joelschaeffer/dev/lightwave-workspace/Frontend/joelschaeffer/.git
# /Users/joelschaeffer/dev/lightwave-workspace/Infrastructure/lightwave-infrastructure-catalog/.git
# /Users/joelschaeffer/dev/lightwave-workspace/Infrastructure/lightwave-infrastructure-live/.git
```

**Step 2: Navigate to correct repository**
```bash
# Navigate to specific repo (example: Backend)
cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend

# Verify you're in a git repo
pwd
git rev-parse --show-toplevel
# Should show: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
```

**Step 3: Run git commands**
```bash
# Now git commands work correctly
git status
git branch --show-current
git log --oneline -5
```

**Alternative: Use git -C flag to run commands in specific repo**
```bash
# Run git command in specific repo without changing directory
git -C /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend status

# Example: Check branch of multiple repos
git -C Backend/lightwave-backend branch --show-current
git -C Frontend/lightwave-media-site branch --show-current
git -C Infrastructure/lightwave-infrastructure-catalog branch --show-current
```

#### Prevention

**1. Always verify current directory before git commands**
```bash
# Add to your workflow:
pwd                          # Where am I?
git rev-parse --show-toplevel 2>/dev/null || echo "Not in a git repo"
```

**2. Create shell aliases for quick navigation**
```bash
# Add to ~/.zshrc or ~/.bashrc
alias lw-backend='cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend'
alias lw-frontend='cd /Users/joelschaeffer/dev/lightwave-workspace/Frontend/lightwave-media-site'
alias lw-infra-catalog='cd /Users/joelschaeffer/dev/lightwave-workspace/Infrastructure/lightwave-infrastructure-catalog'
alias lw-infra-live='cd /Users/joelschaeffer/dev/lightwave-workspace/Infrastructure/lightwave-infrastructure-live'
alias lw-joel='cd /Users/joelschaeffer/dev/lightwave-workspace/Frontend/joelschaeffer'

# Usage:
# lw-backend  → navigate to backend repo
# lw-frontend → navigate to frontend repo
```

**3. Use VS Code workspace with multi-root**
```json
// lightwave-workspace.code-workspace
{
  "folders": [
    {
      "name": "Backend - lightwave-backend",
      "path": "Backend/lightwave-backend"
    },
    {
      "name": "Frontend - lightwave-media-site",
      "path": "Frontend/lightwave-media-site"
    },
    {
      "name": "Frontend - joelschaeffer",
      "path": "Frontend/joelschaeffer"
    },
    {
      "name": "Infrastructure - Catalog",
      "path": "Infrastructure/lightwave-infrastructure-catalog"
    },
    {
      "name": "Infrastructure - Live",
      "path": "Infrastructure/lightwave-infrastructure-live"
    }
  ],
  "settings": {}
}
```

**4. For Claude Code: Always ask which repo**
When starting a new conversation, Claude Code should:
1. Detect multi-repo workspace (using `find . -name ".git" -type d -maxdepth 3`)
2. Ask user which repository to work in
3. Store repo path and use it for all git operations
4. Never run git commands from workspace root

---

### Issue 6: Branch Naming Convention Errors

#### Symptoms
- Creating branches with inconsistent names
- Unable to find branches because naming doesn't follow pattern
- Confusion about what a branch is for based on its name

**Examples of problematic branch names**:
```bash
my-feature          # Missing type and domain
new-stuff           # Not descriptive
fix                 # Too generic
auth-oauth-feature  # Type at end instead of beginning
```

#### Root Cause
Not following the documented branch naming convention from `.agent/metadata/git_conventions.yaml`.

**Expected pattern**: `<type>/<domain>/<task-id>-<slug>`

**Types**: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`
**Domains**: `auth`, `cineos`, `photographos`, `createos`, `platform`, `infra`

#### Solution

**Step 1: Review git conventions**
```bash
# Read the conventions file
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/git_conventions.yaml

# Look for branch naming pattern
```

**Step 2: Create branch with correct naming**
```bash
# Pattern: <type>/<domain>/<task-id>-<slug>

# Examples of correct branch names:
git checkout -b feat/auth/LW-123-oauth-integration
git checkout -b fix/cineos/LW-456-video-player-crash
git checkout -b chore/platform/update-django-deps
git checkout -b docs/auth/update-api-documentation
```

**Step 3: Rename existing branch if needed**
```bash
# If you're on a poorly named branch, rename it:
git branch -m feat/auth/LW-789-new-login-flow

# If branch is already pushed to remote:
git push origin :old-branch-name                    # Delete remote branch
git push origin -u feat/auth/LW-789-new-login-flow  # Push with new name
```

#### Prevention

**Create a branch creation script**:
```bash
#!/bin/bash
# save as: scripts/create-branch.sh

# Usage: ./scripts/create-branch.sh feat auth LW-123 "oauth integration"

TYPE=$1
DOMAIN=$2
TASK_ID=$3
SLUG=$4

# Validate inputs
if [ -z "$TYPE" ] || [ -z "$DOMAIN" ] || [ -z "$SLUG" ]; then
  echo "Usage: $0 <type> <domain> <task-id> <slug>"
  echo "Example: $0 feat auth LW-123 'oauth integration'"
  echo ""
  echo "Valid types: feat, fix, chore, docs, refactor, test"
  echo "Valid domains: auth, cineos, photographos, createos, platform, infra"
  exit 1
fi

# Convert slug to kebab-case
SLUG_KEBAB=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Create branch name
if [ -n "$TASK_ID" ]; then
  BRANCH_NAME="$TYPE/$DOMAIN/$TASK_ID-$SLUG_KEBAB"
else
  BRANCH_NAME="$TYPE/$DOMAIN/$SLUG_KEBAB"
fi

echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"
```

**Add git alias**:
```bash
# Add to ~/.gitconfig
[alias]
  create-branch = "!sh -c 'git checkout -b $1/$2/${3:+$3-}$(echo $4 | tr \"[:upper:]\" \"[:lower:]\" | tr \" \" \"-\")' -"

# Usage:
# git create-branch feat auth LW-123 "oauth integration"
```

---

### Issue 7: Commit Message Format Errors

#### Symptoms
- Inconsistent commit messages across repositories
- Difficulty generating changelogs automatically
- Unclear what changed in a commit from the message alone

**Examples of problematic commit messages**:
```bash
"updated files"
"fix"
"changes"
"WIP"
"asdf"
```

#### Root Cause
Not following Conventional Commits format documented in `.agent/metadata/git_conventions.yaml`.

**Expected pattern**: `<type>(<scope>): <subject>`

#### Solution

**Step 1: Review commit message conventions**
```bash
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/git_conventions.yaml
# Look for commits.pattern and commits.examples
```

**Step 2: Write commit messages in correct format**
```bash
# Pattern: <type>(<scope>): <subject>

# Examples of correct commit messages:
git commit -m "feat(auth): add OAuth2 provider support"
git commit -m "fix(cineos): resolve video player memory leak"
git commit -m "chore(deps): bump Django to 5.1"
git commit -m "docs(api): update authentication endpoint documentation"
git commit -m "refactor(platform): simplify user service logic"
git commit -m "test(auth): add OAuth integration tests"

# For breaking changes:
git commit -m "feat(api)!: change auth endpoint response format"
```

**Step 3: If commit message is wrong, amend it**
```bash
# If you just committed with wrong message (not yet pushed):
git commit --amend -m "feat(auth): add OAuth2 provider support"

# If already pushed (use with caution):
git commit --amend -m "feat(auth): add OAuth2 provider support"
git push --force-with-lease
```

#### Prevention

**Create commit message template**:
```bash
# Create template file
cat > ~/.gitmessage << 'EOF'
# <type>(<scope>): <subject>
#
# Types: feat, fix, docs, style, refactor, test, chore
# Scopes: auth, ui, api, deploy, deps, cineos, photographos, etc.
#
# Examples:
#   feat(auth): add OAuth2 provider support
#   fix(cineos): resolve video player memory leak
#   chore(deps): bump Django to 5.1
#
# Breaking changes: Add ! before colon
#   feat(api)!: change auth endpoint response format
EOF

# Configure git to use template
git config --global commit.template ~/.gitmessage
```

**Use commitlint (optional)**:
```bash
# Install commitlint
npm install --save-dev @commitlint/{config-conventional,cli}

# Create commitlint.config.js
cat > commitlint.config.js << 'EOF'
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'scope-enum': [
      2,
      'always',
      ['auth', 'ui', 'api', 'deploy', 'deps', 'cineos', 'photographos', 'createos', 'platform', 'infra']
    ]
  }
};
EOF

# Add husky hook to validate commit messages
npx husky add .husky/commit-msg 'npx --no -- commitlint --edit ${1}'
```

---

## Infrastructure Issues

### Issue 8: Terragrunt/OpenTofu State Lock Errors

#### Symptoms
```bash
Error: Error acquiring the state lock

Error message: ConditionalCheckFailedException: The conditional request failed
Lock Info:
  ID:        a1b2c3d4-5e6f-7g8h-9i0j-k1l2m3n4o5p6
  Path:      lightwave-infrastructure/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.5.0
  Created:   2025-10-28 10:15:30.123456789 +0000 UTC
  Info:
```

#### Root Cause
**Terraform/Terragrunt uses state locking to prevent concurrent modifications**. A lock file was created but not released.

**Common causes**:
1. Previous `terragrunt apply` or `terraform apply` was interrupted (Ctrl+C, network issue, crash)
2. Multiple people/processes trying to apply at same time
3. CI/CD pipeline didn't release lock after failure
4. Process was killed before completing

#### Solution

**Step 1: Verify lock is actually stale**
```bash
# Check lock info in error message:
# - Who: Is this you or someone else?
# - Created: How long ago? (If >30 minutes and no one is working, likely stale)
# - Operation: What was being done?

# If someone else has the lock, confirm they're not actively working before proceeding
```

**Step 2: Forcefully unlock (use with caution)**
```bash
# Navigate to terragrunt module directory
cd /Users/joelschaeffer/dev/lightwave-workspace/Infrastructure/lightwave-infrastructure-live/dev/us-east-1/service-name

# Force unlock using lock ID from error message
terragrunt force-unlock a1b2c3d4-5e6f-7g8h-9i0j-k1l2m3n4o5p6

# Confirm when prompted
# Type: yes
```

**Step 3: Verify unlock was successful and retry operation**
```bash
# Try your operation again
terragrunt plan
# or
terragrunt apply
```

**Alternative: Check DynamoDB lock table directly**
```bash
# State locks are stored in DynamoDB table
# List lock table items
aws dynamodb scan \
  --table-name terraform-state-lock-table \
  --region us-east-1

# Delete specific lock item (extreme caution)
aws dynamodb delete-item \
  --table-name terraform-state-lock-table \
  --key '{"LockID": {"S": "lightwave-infrastructure/terraform.tfstate-md5"}}' \
  --region us-east-1
```

#### Prevention

**1. Always let Terragrunt/Terraform complete**
- Don't interrupt with Ctrl+C unless absolutely necessary
- If you must interrupt, let it finish current operation first

**2. Use Terragrunt/Terraform properly**
```bash
# Always run plan before apply
terragrunt plan

# Review plan output carefully

# Apply only after confirming plan
terragrunt apply

# If you need to cancel, wait for current resource to finish
# Press Ctrl+C once, not repeatedly
```

**3. Implement lock timeout in terragrunt.hcl**
```hcl
# In your terragrunt.hcl
remote_state {
  backend = "s3"
  config = {
    bucket         = "lightwave-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-table"

    # Add lock timeout
    skip_metadata_api_check     = false
    skip_credentials_validation = false
  }
}

# Configure backend to automatically release locks after timeout
```

**4. Add cleanup script**
```bash
#!/bin/bash
# save as: scripts/cleanup-stale-locks.sh

# List all locks older than 1 hour
aws dynamodb scan \
  --table-name terraform-state-lock-table \
  --region us-east-1 \
  --filter-expression "Created < :one_hour_ago" \
  --expression-attribute-values "{\":one_hour_ago\":{\"N\":\"$(date -u -d '1 hour ago' +%s)\"}}"

# TODO: Add logic to automatically clean up stale locks
```

---

### Issue 9: AWS Resource Deployment Failures

#### Symptoms
```bash
# Terragrunt/Terraform errors during apply:
Error: Error creating ECS Service: InvalidParameterException: Unable to assume role
Error: Error creating RDS instance: DBSubnetGroupNotFoundFault
Error: Error creating ALB: SecurityGroupNotFoundFault
```

**Or partial deployment**:
- Some resources created successfully
- Some resources failed
- Inconsistent state between actual AWS and Terraform state

#### Root Cause
**Common causes**:
1. Dependency resources not created yet (wrong order)
2. Incorrect IAM permissions or roles
3. Resource limits exceeded (AWS service quotas)
4. Invalid configuration values
5. Network/subnet configuration issues

#### Solution

**Step 1: Read the error message carefully**
```bash
# Terraform/Terragrunt errors are usually descriptive
# Look for:
# - Which resource failed (resource type and name)
# - Specific error reason (InvalidParameter, NotFound, etc.)
# - AWS error code and message

# Example error:
Error: Error creating ECS Service (lightwave-backend-service):
InvalidParameterException: Unable to assume role arn:aws:iam::738605694078:role/ecsTaskExecutionRole
```

**Step 2: Verify dependencies exist**
```bash
# Check if required resources exist in AWS
# Example: Verify IAM role exists
aws iam get-role --role-name ecsTaskExecutionRole

# Example: Verify security group exists
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0

# Example: Verify subnet exists
aws ec2 describe-subnets --subnet-ids subnet-0123456789abcdef0
```

**Step 3: Apply dependencies first**
```bash
# In Terragrunt, apply modules in dependency order
# Example dependency tree:
# 1. VPC and networking
# 2. Security groups
# 3. IAM roles
# 4. Database (RDS)
# 5. ECS cluster
# 6. ECS service

# Apply in order:
cd Infrastructure/lightwave-infrastructure-live/dev/us-east-1/vpc
terragrunt apply

cd ../security-groups
terragrunt apply

cd ../iam-roles
terragrunt apply

# ... continue in order
```

**Step 4: Check AWS service quotas**
```bash
# List service quotas for ECS
aws service-quotas list-service-quotas \
  --service-code ecs \
  --region us-east-1

# List service quotas for RDS
aws service-quotas list-service-quotas \
  --service-code rds \
  --region us-east-1
```

**Step 5: Fix configuration and retry**
```bash
# After fixing configuration
terragrunt plan
terragrunt apply
```

#### Prevention

**1. Use Terragrunt dependency blocks**
```hcl
# In dependent module's terragrunt.hcl
dependency "vpc" {
  config_path = "../vpc"
}

dependency "security_group" {
  config_path = "../security-groups"
}

inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  security_group_ids = [dependency.security_group.outputs.sg_id]
}
```

**2. Use terragrunt run-all with care**
```bash
# Plan all modules first to see what will change
terragrunt run-all plan

# Apply all in correct dependency order
terragrunt run-all apply
```

**3. Validate configuration before applying**
```bash
# Use Terraform validation
terragrunt validate

# Use terragrunt hclfmt to format
terragrunt hclfmt

# Use custom validation scripts
./scripts/validate-infrastructure.sh
```

---

### Issue 10: Emergency Infrastructure Shutdown

#### Symptoms
**Need to quickly shut down all infrastructure** (e.g., runaway costs, security incident, testing emergency procedures).

#### Root Cause
Planned emergency shutdown or unexpected need to stop all running resources.

#### Solution

**WARNING: This will stop all running services. Use only in true emergencies.**

**Step 1: Stop all ECS services (Application Tier)**
```bash
# List all ECS services
aws ecs list-services \
  --cluster lightwave-prod \
  --region us-east-1

# Update service to desired count 0 (stops all tasks)
aws ecs update-service \
  --cluster lightwave-prod \
  --service lightwave-backend-service \
  --desired-count 0 \
  --region us-east-1

# Repeat for all services
```

**Step 2: Stop all EC2 instances (if any)**
```bash
# List running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Project,Values=lightwave" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Stop instances
aws ec2 stop-instances --instance-ids i-0123456789abcdef0 i-0123456789abcdef1
```

**Step 3: Disable Auto Scaling (prevents restart)**
```bash
# Suspend auto scaling processes
aws autoscaling suspend-processes \
  --auto-scaling-group-name lightwave-asg \
  --region us-east-1
```

**Step 4: Stop RDS databases (optional - for extreme cases)**
```bash
# Stop RDS instance (can be started again within 7 days)
aws rds stop-db-instance \
  --db-instance-identifier lightwave-prod-db \
  --region us-east-1

# Note: RDS will auto-start after 7 days
```

**Step 5: Document shutdown**
```bash
# Create incident log
cat > /tmp/shutdown-$(date +%Y%m%d-%H%M%S).log << EOF
Emergency shutdown initiated
Date: $(date)
User: $(whoami)
Reason: [DESCRIBE REASON]
Services stopped:
- ECS services: lightwave-backend-service
- EC2 instances: [list instance IDs]
- RDS databases: [list if stopped]

To restart:
1. Start RDS: aws rds start-db-instance --db-instance-identifier lightwave-prod-db
2. Start EC2: aws ec2 start-instances --instance-ids [ids]
3. Resume ASG: aws autoscaling resume-processes --auto-scaling-group-name lightwave-asg
4. Scale ECS: aws ecs update-service --cluster lightwave-prod --service lightwave-backend-service --desired-count 1
EOF

# Review log
cat /tmp/shutdown-$(date +%Y%m%d-%H%M%S).log
```

**Step 6: Restart procedure (when ready)**
```bash
# Reverse order: Database → EC2 → Auto Scaling → ECS

# 1. Start RDS
aws rds start-db-instance \
  --db-instance-identifier lightwave-prod-db

# Wait for RDS to be available
aws rds wait db-instance-available --db-instance-identifier lightwave-prod-db

# 2. Start EC2 instances
aws ec2 start-instances --instance-ids i-0123456789abcdef0

# 3. Resume Auto Scaling
aws autoscaling resume-processes --auto-scaling-group-name lightwave-asg

# 4. Scale up ECS services
aws ecs update-service \
  --cluster lightwave-prod \
  --service lightwave-backend-service \
  --desired-count 2

# 5. Verify all services are healthy
aws ecs describe-services \
  --cluster lightwave-prod \
  --services lightwave-backend-service
```

#### Prevention

**1. Implement cost alerts**
```bash
# Set up AWS Budgets
aws budgets create-budget \
  --account-id 738605694078 \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

**2. Create runbook for emergencies**
- Document shutdown procedure in `.agent/sops/SOP_EMERGENCY_SHUTDOWN.md`
- Practice shutdown/restart procedure in dev environment
- Keep contact list for escalation

**3. Use infrastructure tags**
```bash
# Tag all resources for easy filtering
aws resourcegroupstaggingapi tag-resources \
  --resource-arn-list [list of arns] \
  --tags Project=lightwave,Environment=prod,AutoShutdown=true
```

---

## Development Environment Issues

### Issue 11: Docker Compose Services Not Starting

#### Symptoms
```bash
# When running docker-compose up:
ERROR: for postgres  Cannot start service postgres: driver failed programming external connectivity
ERROR: for redis  Cannot start service redis: Bind for 0.0.0.0:6379 failed: port is already allocated

# Or:
ERROR: Service 'backend' failed to build: Error response from daemon: Dockerfile not found
```

#### Root Cause
**Common causes**:
1. Port conflicts (service already running on host)
2. Docker daemon not running
3. Incorrect docker-compose.yml configuration
4. Missing Dockerfile or build context
5. Insufficient Docker resources (memory, disk)

#### Solution

**Step 1: Check if Docker daemon is running**
```bash
# Check Docker status
docker info

# If not running (macOS):
open -a Docker

# If not running (Linux):
sudo systemctl start docker
```

**Step 2: Check for port conflicts**
```bash
# Find what's using the port
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :8000  # Django

# If another service is using the port, stop it:
# Example: stop local PostgreSQL
brew services stop postgresql

# Or change port in docker-compose.yml:
services:
  postgres:
    ports:
      - "5433:5432"  # Use 5433 on host instead of 5432
```

**Step 3: Verify docker-compose.yml**
```bash
# Validate docker-compose.yml syntax
docker-compose config

# Should output parsed configuration without errors
```

**Step 4: Clean up and restart**
```bash
# Stop all containers
docker-compose down

# Remove volumes (WARNING: deletes data)
docker-compose down -v

# Rebuild and start
docker-compose up --build
```

**Step 5: Check Docker resources**
```bash
# Check disk space
docker system df

# Clean up unused resources
docker system prune -a

# For Docker Desktop:
# Settings → Resources → Advanced
# Increase Memory to at least 4GB
# Increase Disk to at least 60GB
```

#### Prevention

**1. Use .env file for ports**
```bash
# .env file
POSTGRES_PORT=5432
REDIS_PORT=6379
DJANGO_PORT=8000

# docker-compose.yml
services:
  postgres:
    ports:
      - "${POSTGRES_PORT}:5432"
  redis:
    ports:
      - "${REDIS_PORT}:6379"
```

**2. Create health checks**
```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    depends_on:
      postgres:
        condition: service_healthy
```

**3. Document Docker setup in repo CLAUDE.md**
```markdown
## Local Development Setup

1. Install Docker Desktop
2. Copy `.env.example` to `.env`
3. Start services: `docker-compose up`
4. Run migrations: `docker-compose exec backend python manage.py migrate`
```

---

### Issue 12: Python/uv Package Manager Problems

#### Symptoms
```bash
# When using uv (modern Python package manager):
error: No solution found when resolving dependencies

# Or:
ERROR: Could not find a version that satisfies the requirement django==5.1.0

# Or:
uv: command not found
```

#### Root Cause
**Common causes**:
1. `uv` not installed
2. Incompatible package versions
3. Python version mismatch
4. Virtual environment not activated
5. Corrupted package cache

#### Solution

**Step 1: Install uv if missing**
```bash
# macOS/Linux (using curl)
curl -LsSf https://astral.sh/uv/install.sh | sh

# macOS (using Homebrew)
brew install uv

# Verify installation
uv --version
```

**Step 2: Create and activate virtual environment**
```bash
# Navigate to project
cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend

# Create virtual environment with specific Python version
uv venv --python 3.12

# Activate virtual environment
source .venv/bin/activate  # macOS/Linux
# or
.venv\Scripts\activate  # Windows

# Verify activation
which python  # Should show .venv/bin/python
python --version  # Should show Python 3.12.x
```

**Step 3: Install dependencies**
```bash
# Install from pyproject.toml
uv pip install -e .

# Or install from requirements.txt
uv pip install -r requirements.txt

# Or sync exact versions from uv.lock
uv sync
```

**Step 4: Resolve dependency conflicts**
```bash
# If dependency resolution fails, try:

# 1. Clear cache
uv cache clean

# 2. Update lock file
uv lock

# 3. Sync again
uv sync

# 4. If specific package is problematic, pin compatible version
# Edit pyproject.toml:
[project]
dependencies = [
    "django>=5.0,<5.2",  # Allow range instead of exact version
]
```

#### Prevention

**1. Use pyproject.toml for dependency management**
```toml
# pyproject.toml
[project]
name = "lightwave-backend"
version = "0.1.0"
description = "LightWave backend application"
requires-python = ">=3.12"
dependencies = [
    "django>=5.0",
    "djangorestframework>=3.14",
    "psycopg[binary]>=3.1",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-django>=4.5",
    "ruff>=0.1",
]
```

**2. Create development setup script**
```bash
#!/bin/bash
# save as: scripts/setup-dev.sh

set -e

echo "Setting up Python development environment..."

# Install uv if not present
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Create virtual environment
echo "Creating virtual environment..."
uv venv --python 3.12

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
uv sync

echo "✅ Setup complete!"
echo "Activate environment: source .venv/bin/activate"
```

**3. Document Python version in .python-version**
```bash
# .python-version
3.12
```

---

### Issue 13: Node.js/pnpm Dependency Issues

#### Symptoms
```bash
# When using pnpm:
ERROR  No lockfile found

# Or:
ERR_PNPM_OUTDATED_LOCKFILE  Cannot install with "frozen-lockfile" because pnpm-lock.yaml is not up to date with package.json

# Or:
Module not found: Error: Can't resolve '@lightwave/ui'
```

#### Root Cause
**Common causes**:
1. `pnpm` not installed
2. Lockfile out of sync with package.json
3. Workspace dependencies not linked
4. Node version mismatch
5. Corrupted node_modules

#### Solution

**Step 1: Install pnpm if missing**
```bash
# macOS/Linux
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Or using npm
npm install -g pnpm

# Verify installation
pnpm --version
```

**Step 2: Install dependencies**
```bash
# Navigate to project
cd /Users/joelschaeffer/dev/lightwave-workspace/Frontend/lightwave-media-site

# Install dependencies
pnpm install

# If lockfile is out of sync:
pnpm install --no-frozen-lockfile

# Or force update lockfile:
rm pnpm-lock.yaml
pnpm install
```

**Step 3: Fix workspace dependencies**
```bash
# If using pnpm workspaces, verify pnpm-workspace.yaml exists
cat pnpm-workspace.yaml

# Should contain:
packages:
  - 'packages/*'
  - 'apps/*'

# Install workspace dependencies
pnpm install -r  # Recursive install
```

**Step 4: Clear cache and reinstall**
```bash
# Remove node_modules
rm -rf node_modules

# Clear pnpm cache
pnpm store prune

# Reinstall
pnpm install
```

#### Prevention

**1. Use .nvmrc or .node-version for version consistency**
```bash
# .nvmrc or .node-version
20.10.0

# Install and use specified version:
nvm install
nvm use
```

**2. Use pnpm workspaces for monorepo**
```yaml
# pnpm-workspace.yaml
packages:
  - 'packages/*'
  - 'apps/*'
```

**3. Add postinstall script**
```json
// package.json
{
  "scripts": {
    "postinstall": "pnpm build --filter @lightwave/ui"
  }
}
```

---

### Issue 14: Environment Variable Loading Problems

#### Symptoms
```bash
# Application fails to load environment variables:
KeyError: 'DATABASE_URL'

# Or:
django.core.exceptions.ImproperlyConfigured: The SECRET_KEY setting must not be empty

# Or variables have wrong values:
DEBUG=True  # In production (should be False)
```

#### Root Cause
**Common causes**:
1. `.env` file missing or not loaded
2. `.env` file in wrong directory
3. Environment variables not exported
4. Wrong environment loaded (dev instead of prod)
5. Secrets not loaded from AWS

#### Solution

**Step 1: Verify .env file exists**
```bash
# Check if .env exists
ls -la .env

# If missing, create from template
cp .env.example .env

# Or load from AWS (see SECRETS_MAP.md)
./scripts/load-dev-secrets.sh
```

**Step 2: Verify .env file contents**
```bash
# View .env (be careful not to expose secrets)
cat .env

# Check specific variable
grep DATABASE_URL .env

# Ensure no trailing spaces or quotes issues:
# GOOD:
DATABASE_URL=postgresql://user:pass@localhost:5432/db

# BAD:
DATABASE_URL = "postgresql://user:pass@localhost:5432/db"  # Extra spaces and quotes
```

**Step 3: Export environment variables**
```bash
# Option 1: Export manually
export $(cat .env | grep -v '^#' | xargs)

# Option 2: Use direnv (automatic loading)
# Install direnv
brew install direnv

# Create .envrc
echo "dotenv" > .envrc

# Allow direnv for this directory
direnv allow

# Now .env is automatically loaded when you cd into directory
```

**Step 4: Verify variables are loaded**
```bash
# Check if variable exists
echo $DATABASE_URL

# Should output: postgresql://user:pass@localhost:5432/db

# If empty, variable not loaded
```

**Step 5: For Python/Django, use python-dotenv**
```python
# In Django settings.py
from pathlib import Path
from dotenv import load_dotenv
import os

# Load .env file
BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / '.env')

# Access variables
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')
DATABASE_URL = os.getenv('DATABASE_URL')

# Validate required variables
if not SECRET_KEY:
    raise ValueError("DJANGO_SECRET_KEY environment variable is not set")
```

#### Prevention

**1. Create .env.example template**
```bash
# .env.example - Committed to git (no real secrets)
DJANGO_SECRET_KEY=your-secret-key-here
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
REDIS_URL=redis://localhost:6379/0
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1

# AI APIs
ANTHROPIC_API_KEY=your-anthropic-key-here
OPENAI_API_KEY=your-openai-key-here

# AWS
AWS_PROFILE=lightwave-admin-new
AWS_REGION=us-east-1
```

**2. Add .env to .gitignore**
```bash
# .gitignore
.env
.env.local
.env.*.local
```

**3. Create environment loading script**
```bash
#!/bin/bash
# save as: scripts/load-env.sh

# Load environment-specific .env file
ENVIRONMENT=${1:-dev}
ENV_FILE=".env.${ENVIRONMENT}"

if [ -f "$ENV_FILE" ]; then
    echo "Loading environment from $ENV_FILE"
    export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
else
    echo "ERROR: $ENV_FILE not found"
    exit 1
fi

# Verify critical variables
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL not set"
    exit 1
fi

echo "✅ Environment loaded successfully"

# Usage:
# source scripts/load-env.sh dev
# source scripts/load-env.sh prod
```

---

## Claude Code Agent Issues

### Issue 15: Skipping ONBOARDING.md Checklist

#### Symptoms
- Claude Code asks for information that's documented in `.claude/ONBOARDING.md`
- Claude Code runs commands without setting AWS profile
- Claude Code runs git commands in workspace root instead of repository
- Claude Code doesn't know about multi-repo structure

**Examples**:
- "What's your AWS account ID?" (documented in ONBOARDING.md)
- "Which AWS profile should I use?" (documented in ONBOARDING.md)
- Running `git status` in workspace root and getting "not a git repository"

#### Root Cause
Claude Code conversation started without reading and following `.claude/ONBOARDING.md` checklist.

**Why this happens**:
- Starting task immediately without onboarding
- Assuming context from previous conversations
- Not validating environment before starting work

#### Solution

**Step 1: Stop current work and run onboarding**
```
User: "Please stop and complete the onboarding checklist from .claude/ONBOARDING.md"
```

**Step 2: Claude Code should read and follow ONBOARDING.md**
```bash
# Claude should execute:
# 1. Read .claude/ONBOARDING.md
# 2. Set AWS_PROFILE=lightwave-admin-new
# 3. Verify AWS identity
# 4. Detect workspace type (multi-repo)
# 5. Ask which repository
# 6. Load repo-specific context
# 7. Generate validation report
```

**Step 3: Verify onboarding completion**
Claude Code should provide a validation report like:
```yaml
context_validation:
  status: READY
  workspace_context:
    workspace_type: multi-repo
    git_repos_found: 9
  scope_identified:
    selected_repo: Backend/lightwave-backend
  secrets_status:
    aws_profile: lightwave-admin-new
  ready_to_work: true
```

#### Prevention

**For Claude Code**:
- ALWAYS read `.claude/ONBOARDING.md` at start of every new conversation
- NEVER skip validation steps
- ALWAYS generate validation report before starting work
- ASK which repository in multi-repo workspace before git commands

**For User (Joel)**:
- Remind Claude to complete onboarding if skipped: "Did you complete the onboarding checklist?"
- Reference ONBOARDING.md when Claude asks documented questions: "See .claude/ONBOARDING.md Step 1"

---

### Issue 16: Not Loading .agent/ Metadata

#### Symptoms
- Claude Code makes architecture decisions that contradict documented conventions
- Claude Code uses wrong naming patterns
- Claude Code doesn't follow git branch naming conventions
- Claude Code unaware of recent Notion updates

**Examples**:
- Creating branch named `my-feature` instead of `feat/auth/LW-123-oauth-integration`
- Asking "What's your deployment strategy?" (documented in `.agent/metadata/deployment.yaml`)
- Using wrong commit message format

#### Root Cause
Claude Code not reading structured context from `.agent/` directory.

**Why this happens**:
- Not checking `.agent/README.md` for last sync timestamp
- Not reading relevant metadata files before making decisions
- Not following documented conventions from `.agent/metadata/`

#### Solution

**Step 1: Check last Notion sync**
```bash
# Read .agent/README.md
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/README.md

# Look for last_synced timestamp
# Example: last_synced: "2025-10-25 14:30 UTC"
```

**Step 2: Load relevant metadata before starting work**
```bash
# For git operations, read:
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/git_conventions.yaml

# For naming decisions, read:
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/naming_conventions.yaml

# For deployment questions, read:
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/deployment.yaml

# For architecture decisions, read:
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/decisions.yaml
```

**Step 3: Follow documented conventions**
- Branch names: Use pattern from `git_conventions.yaml`
- Commit messages: Use format from `git_conventions.yaml`
- API design: Follow patterns from `naming_conventions.yaml`
- Deployment: Follow config from `deployment.yaml`

#### Prevention

**For Claude Code**:
- ALWAYS check `.agent/README.md` during onboarding (Step 1)
- ALWAYS read relevant metadata files before making architectural decisions
- NEVER guess conventions when they're documented
- ALWAYS verify sync timestamp (if outdated, notify user)

**For User (Joel)**:
- Keep `.agent/` metadata synced from Notion
- Update `last_synced` timestamp after sync
- Review Claude's decisions against documented conventions

---

### Issue 17: Missing Context from Notion Sync

#### Symptoms
- `.agent/` directory empty or outdated
- Claude Code makes decisions without full context
- Recent architecture decisions not reflected in Claude's work
- Task definitions missing

#### Root Cause
`.agent/` metadata not synced from Notion, or sync is outdated.

**Why this happens**:
- Manual sync not run recently
- Notion status filtering excludes documents (Status != Active)
- Sync script not configured or broken
- Documents in Notion are Draft/Deprecated

#### Solution

**Step 1: Check current sync status**
```bash
# Read .agent/README.md
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/README.md

# Check last_synced timestamp
# If >7 days old, sync is stale
```

**Step 2: Verify .agent/ directory contents**
```bash
# List all metadata files
ls -la /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/

# Expected files:
# - git_conventions.yaml
# - naming_conventions.yaml
# - deployment.yaml
# - decisions.yaml
# - tech_stack.yaml
# - etc.

# List task files
ls -la /Users/joelschaeffer/dev/lightwave-workspace/.agent/tasks/

# Expected files:
# - auth_client.yaml
# - payload_shared.yaml
# - etc.
```

**Step 3: Request sync from user**
```
Claude: "The .agent/ directory appears outdated (last synced: [date]).
Would you like to sync from Notion to get the latest context?"

User: [runs Notion sync script or manual sync]
```

**Step 4: Reload context after sync**
```bash
# After sync completes, read updated files
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/README.md
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/git_conventions.yaml
# etc.
```

#### Prevention

**For Claude Code**:
- ALWAYS check `.agent/README.md` last_synced timestamp during onboarding
- WARN user if last sync is >7 days old
- NEVER proceed with critical work if context is stale

**For User (Joel)**:
- Set up automated Notion sync (GitHub Action, cron job, etc.)
- Update last_synced timestamp after manual sync
- Mark documents as "Active" in Notion to include in sync
- Mark outdated documents as "Deprecated" to exclude from sync

**Automation (future)**:
```yaml
# .github/workflows/notion-sync.yml
name: Sync from Notion
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  workflow_dispatch:  # Manual trigger

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Sync Notion to .agent/
        env:
          NOTION_API_KEY: ${{ secrets.NOTION_API_KEY }}
        run: |
          python scripts/notion_sync.py
          git add .agent/
          git commit -m "chore(docs): sync from Notion [automated]"
          git push
```

---

### Issue 18: Outdated Task Definitions

#### Symptoms
- Working on task that has changed in Notion
- Task acceptance criteria don't match current requirements
- Task marked as complete in Notion but still shows "not_started" in `.agent/tasks/`

#### Root Cause
Task YAML files in `.agent/tasks/` are out of sync with Notion.

**Why this happens**:
- Task updated in Notion but not re-synced
- Manual edits to task YAML without updating Notion
- Task status changed in Notion but not reflected locally

#### Solution

**Step 1: Check task status in YAML**
```bash
# Read task file
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/tasks/auth_client.yaml

# Look for:
# - status: not_started | in_progress | completed
# - last_updated: [timestamp]
```

**Step 2: Compare with Notion**
```
Claude: "The task file shows status: not_started and last_updated: 2025-10-15.
Can you verify the current status in Notion?"

User: [checks Notion]
"Notion shows status: In Progress, updated 2025-10-28"
```

**Step 3: Request task re-sync**
```
Claude: "Task definition is outdated. Please re-sync this task from Notion to get latest requirements."

User: [runs notion sync for specific task]
```

**Step 4: Reload task after sync**
```bash
# Read updated task
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/tasks/auth_client.yaml

# Verify status and last_updated are current
```

#### Prevention

**For Claude Code**:
- CHECK task last_updated timestamp before starting work
- WARN if task is >7 days old: "This task definition may be outdated"
- ASK user to confirm task is current before proceeding

**For User (Joel)**:
- Update task YAML immediately after Notion changes
- Use automated sync for task definitions
- Include task sync in regular workflow

---

## Quick Reference

### AWS Quick Fixes

```bash
# Set correct AWS profile (ALWAYS RUN FIRST)
export AWS_PROFILE=lightwave-admin-new

# Verify profile
echo $AWS_PROFILE
aws sts get-caller-identity | grep Arn

# List all secrets
aws secretsmanager list-secrets --query 'SecretList[*].Name' --output table

# List all parameters
aws ssm get-parameters-by-path --path /lightwave/ --recursive --query 'Parameters[*].Name' --output table
```

### Git Quick Fixes

```bash
# Find all git repos in workspace
find /Users/joelschaeffer/dev/lightwave-workspace -name ".git" -type d -maxdepth 3

# Verify you're in a git repo
git rev-parse --show-toplevel

# Create branch with correct naming
git checkout -b feat/auth/LW-123-oauth-integration

# Correct commit format
git commit -m "feat(auth): add OAuth2 provider support"
```

### Infrastructure Quick Fixes

```bash
# Force unlock Terragrunt state
terragrunt force-unlock <LOCK_ID>

# Validate Terragrunt configuration
terragrunt validate

# Plan before apply
terragrunt plan
```

### Development Quick Fixes

```bash
# Docker: Check if daemon running
docker info

# Docker: Clean up
docker system prune -a

# Python: Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Python: Create venv and install
uv venv --python 3.12
source .venv/bin/activate
uv sync

# Node: Install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Node: Install dependencies
pnpm install

# Environment: Load .env
export $(cat .env | grep -v '^#' | xargs)
```

### Claude Code Quick Fixes

```bash
# Always read onboarding first
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/ONBOARDING.md

# Check .agent/ sync status
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/README.md | grep last_synced

# Read git conventions
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/git_conventions.yaml

# Read secrets map
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/reference/SECRETS_MAP.md
```

---

## Related Documentation

- **Onboarding**: `.claude/ONBOARDING.md` - Start here every session
- **Secrets**: `.claude/reference/SECRETS_MAP.md` - Where every secret lives
- **Workspace SOP**: `CLAUDE.md` - Root workspace instructions
- **Agent Metadata**: `.agent/README.md` - Structured context system
- **Git Conventions**: `.agent/metadata/git_conventions.yaml` - Branch and commit patterns

---

## Contributing to This Guide

When you encounter a new issue:

1. **Document it immediately** - Add to this file while solution is fresh
2. **Use the format**: Symptoms → Root Cause → Solution → Prevention
3. **Include commands**: Show exact commands that fixed the issue
4. **Add verification**: Show how to verify the fix worked
5. **Commit**: `git commit -m "docs(troubleshooting): add solution for [issue]"`

**Template for new issues**:
```markdown
### Issue N: [Brief Description]

#### Symptoms
[What the user sees - error messages, unexpected behavior]

#### Root Cause
[Why it's happening - underlying cause]

#### Solution
**Step 1: [First action]**
[Commands and explanation]

**Step 2: [Second action]**
[Commands and explanation]

#### Prevention
[How to avoid this issue in the future]
```

---

**Remember**: Every problem solved is a lesson learned. Document it so we never solve it twice.

**Last Updated**: 2025-10-28
**Maintained By**: Joel Schaeffer + Claude Code
**Version**: 1.0.0
