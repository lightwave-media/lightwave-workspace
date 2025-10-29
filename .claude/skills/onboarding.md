# Skill: Detailed Onboarding Workflow

**Version**: 1.0.0
**Created**: 2025-10-28
**Purpose**: Comprehensive onboarding guidance for Claude Code sessions
**Status**: Active

---

## Overview

This skill provides detailed, step-by-step guidance for completing the onboarding checklist found in `.claude/ONBOARDING.md`. It expands each verification step with specific instructions, expected outcomes, troubleshooting, and integration with other documentation.

**Use this skill when**:
- Starting a new Claude Code session
- Onboarding checks fail and you need detailed remediation
- You need to understand WHY each step matters
- Setting up a new developer or agent for the workspace

---

## Prerequisites

Before starting:
- You have terminal access to the workspace
- You have basic understanding of git, AWS CLI, and shell commands
- You are connected to the internet (for AWS API calls)

---

## Step-by-Step Onboarding

### Step 1: Workspace Context (Detailed)

#### 1.1 Set AWS Profile (CRITICAL)

**Why this matters**: The workspace uses multiple AWS profiles. Using the wrong profile will cause authorization errors for most operations.

**Command**:
```bash
export AWS_PROFILE=lightwave-admin-new
```

**Verification**:
```bash
# Check the profile is set
echo $AWS_PROFILE
# Expected output: lightwave-admin-new

# Verify AWS identity
aws sts get-caller-identity
```

**Expected output**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "738605694078",
    "Arn": "arn:aws:iam::738605694078:user/lightwave-admin"
}
```

**Common issues**:

| Issue | Symptom | Solution |
|-------|---------|----------|
| Profile not found | `could not be found` | Check `~/.aws/credentials` has `[lightwave-admin-new]` section |
| Wrong account | Account ID is not 738605694078 | You're using wrong profile - re-export |
| No credentials | `Unable to locate credentials` | Run AWS configure or check credentials file |

**Reference**: See `.claude/SECRETS_MAP.md` for credential locations

---

#### 1.2 Read Workspace Instructions

**Why this matters**: `.claude/CLAUDE.md` contains workspace-specific conventions, directory structure, and critical context.

**Command**:
```bash
# Read the file
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/CLAUDE.md | head -20
```

**What to extract**:
- Version number (found in header or metadata)
- Directory structure diagram
- Key conventions (git workflow, naming patterns)
- Special instructions for this workspace

**Verification**:
Report the version number you found. Example:
```
✅ Read CLAUDE.md - Version: 5.5.0
✅ Workspace type: Multi-repo monorepo
✅ Special notes: Always use lightwave-admin-new profile
```

**If file not found**:
```bash
# Check current directory
pwd
# Expected: /Users/joelschaeffer/dev/lightwave-workspace

# If wrong directory:
cd /Users/joelschaeffer/dev/lightwave-workspace
```

---

#### 1.3 Check Latest Notion Docs

**Why this matters**: `.agent/README.md` shows when documentation was last synced from Notion. Stale docs can lead to using deprecated patterns.

**Command**:
```bash
# Check if file exists
ls -la /Users/joelschaeffer/dev/lightwave-workspace/.agent/README.md

# Read metadata
head -20 /Users/joelschaeffer/dev/lightwave-workspace/.agent/README.md | grep -E "(Last Updated|Version|Last Sync)"
```

**What to extract**:
- Last sync timestamp
- Version number
- Status indicators

**Verification**:
```
✅ Read .agent/README.md
✅ Last Updated: 2025-10-25
✅ Version: 1.0.0
✅ Status: Documents are current (< 7 days old)
```

**If docs are stale** (> 7 days old):
```
⚠️  WARNING: Docs last synced 14 days ago
⚠️  Recommend: Ask user if they want to sync from Notion before proceeding
```

---

#### 1.4 Review Current Work

**Why this matters**: Task files define active work. Loading the wrong task or missing a task leads to implementing wrong features.

**Commands**:
```bash
# List all task files
ls -la /Users/joelschaeffer/dev/lightwave-workspace/.agent/tasks/

# Count tasks
ls /Users/joelschaeffer/dev/lightwave-workspace/.agent/tasks/*.yaml 2>/dev/null | wc -l

# Get task names
for file in /Users/joelschaeffer/dev/lightwave-workspace/.agent/tasks/*.yaml; do
  echo "- $(basename "$file")"
done
```

**Verification**:
```
✅ Scanned .agent/tasks/
✅ Found: 5 task files
✅ Tasks:
  - auth_client.yaml
  - payload_shared.yaml
  - django_auth_endpoints.yaml
  - joelschaeffer_restructure.yaml
  - fix-onboarding-git-validation.yaml
```

**If directory empty or not found**:
```
⊘ No active tasks found
⊘ This is normal for general workspace exploration
```

---

#### 1.5 Detect Workspace Structure

**Why this matters**: Single-repo vs multi-repo workspaces require different git workflows. Running `git status` at workspace root in a multi-repo setup is meaningless.

**Commands**:
```bash
# Find all git repositories
find /Users/joelschaeffer/dev/lightwave-workspace -name ".git" -type d -maxdepth 3 2>/dev/null

# Count them
find /Users/joelschaeffer/dev/lightwave-workspace -name ".git" -type d -maxdepth 3 2>/dev/null | wc -l
```

**Interpretation**:
- **Count = 0**: ERROR - No git repos found (likely wrong directory)
- **Count = 1**: Single-repo workspace (simple git workflow)
- **Count > 1**: Multi-repo workspace (must ask user which repo)

**Verification (single-repo)**:
```
✅ Workspace structure: Single-repo
✅ Git repository at workspace root
✅ Can run git commands from anywhere in workspace
```

**Verification (multi-repo)**:
```
✅ Workspace structure: Multi-repo
✅ Found: 3 git repositories
✅ Repos:
  - Backend/lightwave-backend
  - Frontend/lightwave-media-site
  - Infrastructure/lightwave-infrastructure-live
⚠️  CRITICAL: Must ask user which repo before running git commands
```

---

### Step 2: Identify Your Scope (Detailed)

#### 2.1 Multi-Repo Workspace Handling

**If Step 1.5 detected multi-repo**, you MUST ask:

**Question to user**:
> "I detected this is a multi-repo workspace with [N] repositories. Which repository are you working in?
>
> Options:
> - Backend/lightwave-backend
> - Frontend/lightwave-media-site
> - Infrastructure/lightwave-infrastructure-live
> - Just exploring (no specific repo)
> - Other: [specify path]"

**Why this matters**: Running git commands without specifying a repo in a multi-repo workspace will fail or give wrong results.

---

#### 2.2 Load Repo-Specific Context

**After user responds with a specific repo**:

```bash
# Store the repo path
REPO_PATH="/Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend"

# Check if repo-specific CLAUDE.md exists
if [ -f "${REPO_PATH}/.claude/CLAUDE.md" ]; then
  echo "✅ Found repo-specific CLAUDE.md"
  head -20 "${REPO_PATH}/.claude/CLAUDE.md"
else
  echo "⊘ No repo-specific CLAUDE.md found (using workspace-level only)"
fi

# Verify you're in the right place
ls -la "${REPO_PATH}"
```

**What to extract from repo CLAUDE.md**:
- Version number
- Local development setup (Docker, dependencies)
- Environment variables required
- Testing commands
- Deployment workflow

**Verification**:
```
✅ User selected: Backend/lightwave-backend
✅ Repo path: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
✅ Read repo CLAUDE.md - Version: 2.1.0
✅ Local setup: Docker Compose required
✅ Test command: pytest --cov
✅ Deployment: Automatic via GitHub Actions to ECS
```

---

#### 2.3 "Just Exploring" Mode

**If user says "just exploring"**:

```
✅ User selected: Just exploring
✅ Mode: Workspace-level context only
✅ Git validation: SKIPPED
✅ Will stay at workspace root
⚠️  Note: Cannot run repo-specific git commands in this mode
```

**What you CAN do**:
- Browse workspace structure
- Read documentation
- View task files
- Answer architecture questions

**What you CANNOT do**:
- Run git status/branch/commit commands
- Make code changes
- Run tests (without knowing which repo)
- Deploy anything

---

### Step 3: Load Secrets (Detailed)

#### 3.1 Determine if Secrets Needed

**Ask user**:
> "Do you need credentials for this task?
>
> Common needs:
> - AWS access (already configured via AWS_PROFILE)
> - Cloudflare API token (for DNS/CDN changes)
> - GitHub token (for API operations beyond `gh` CLI)
> - OpenAI API key (for AI features)
> - Database passwords (for direct DB access)
> - Other service credentials
>
> Type 'yes' with what you need, or 'no' to skip."

---

#### 3.2 Read SECRETS_MAP.md

**Why this matters**: This file documents WHERE secrets are stored (AWS Secrets Manager, Parameter Store, .env files). Never ask user for secrets that are documented here.

**Command**:
```bash
# Read the secrets map
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/SECRETS_MAP.md
```

**What to extract**:
- Secret name in AWS
- Path in AWS Secrets Manager vs Parameter Store
- Which environments have this secret (dev/staging/prod)
- Format of the secret (JSON, plain text, key-value)

**Example entry**:
```markdown
## CLOUDFLARE_API_TOKEN

**Location**: AWS Systems Manager Parameter Store
**Path**: `/lightwave/dev/cloudflare/api-token`
**Type**: SecureString
**Environments**: dev, staging, prod (separate parameters)
**Used by**: Frontend deployment, DNS management
```

---

#### 3.3 Use secrets-loader Skill

**Reference the skill**:
```bash
# Read the secrets-loader skill
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/skills/secrets-loader.md
```

**Follow the skill's process** (summarized):

1. **Verify AWS profile is set** (should already be done in Step 1.1)
2. **Determine secret type** (Secrets Manager vs Parameter Store)
3. **Load the secret**
4. **Export to environment variable**
5. **Verify loaded correctly**

**Example for Cloudflare token**:
```bash
# Load from Parameter Store
export CLOUDFLARE_API_TOKEN=$(aws ssm get-parameter \
  --name "/lightwave/dev/cloudflare/api-token" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)

# Verify (show only first 10 chars for security)
echo "Loaded: ${CLOUDFLARE_API_TOKEN:0:10}..."
```

**Verification**:
```
✅ Read SECRETS_MAP.md
✅ Secret found: CLOUDFLARE_API_TOKEN
✅ Location: Parameter Store /lightwave/dev/cloudflare/api-token
✅ Loaded successfully
✅ Verification: cf_1234567... (20 more chars hidden)
```

---

#### 3.4 Troubleshooting Secret Loading

**Common issues**:

| Issue | Symptom | Solution |
|-------|---------|----------|
| Access denied | `AccessDeniedException` | Check AWS profile has correct permissions |
| Secret not found | `ParameterNotFound` | Verify secret name, check environment (dev vs prod) |
| Decryption error | `InvalidKeyId` | Secret may be encrypted with KMS key you don't have access to |
| Empty value | Secret loads but is empty string | Secret may not be set in this environment |

**Reference**: See `.claude/TROUBLESHOOTING.md` section on "Secret Access Issues"

---

### Step 4: Verify Environment (Detailed)

#### 4.1 Git Validation (Repo-Specific Mode)

**Only run if user selected a specific repo in Step 2.**

```bash
# Navigate to the repo
cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend

# Verify navigation
pwd
# Expected: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend

# Check git branch
git branch --show-current

# Check uncommitted changes
git status --porcelain | wc -l

# Get detailed status
git status
```

**Verification (clean state)**:
```
✅ Navigated to: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
✅ Git branch: dev
✅ Uncommitted changes: 0 (clean working tree)
✅ Status: Ready for new work
```

**Verification (dirty state)**:
```
✅ Navigated to: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
✅ Git branch: feat/auth/oauth-integration
✅ Uncommitted changes: 10 files modified
⚠️  Working tree has uncommitted changes
⚠️  Recommend: Review changes with 'git status' before proceeding
```

---

#### 4.2 Git Validation (Exploring Mode)

**If user said "just exploring"**:

```
⊘ Git validation: SKIPPED (no specific repo selected)
✅ Current directory: /Users/joelschaeffer/dev/lightwave-workspace
✅ Mode: Workspace-level exploration
```

---

#### 4.3 AWS Validation

**If credentials were loaded in Step 3**:

```bash
# Check profile is still set (should persist in session)
echo $AWS_PROFILE
# Expected: lightwave-admin-new

# Verify identity
aws sts get-caller-identity | jq -r '.Account'
# Expected: 738605694078

# Full identity
aws sts get-caller-identity
```

**Verification**:
```
✅ AWS profile: lightwave-admin-new
✅ AWS account: 738605694078
✅ AWS user: arn:aws:iam::738605694078:user/lightwave-admin
✅ Identity verified
```

**If AWS check fails**:
```
❌ AWS profile: ERROR - not set
❌ Solution: Re-run 'export AWS_PROFILE=lightwave-admin-new'
```

---

### Step 5: Load Activity-Specific Context (Detailed)

#### 5.1 Determine Task Type

**Ask user**:
> "What type of task are you working on?
>
> Options:
> 1. Backend feature (Django/Python)
> 2. Frontend feature (Next.js/React)
> 3. Infrastructure deployment (Terraform/Terragrunt)
> 4. Troubleshooting/debugging
> 5. General exploration
> 6. Other: [specify]"

---

#### 5.2 Load Context for Backend Feature

**If user selects backend feature**:

```bash
# Load task workflow skill
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/skills/task-workflow.md

# Load tech stack metadata
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/tech_stack.yaml | grep -A 20 "backend:"

# Load backend architecture if exists
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/backend_architecture.yaml 2>/dev/null || echo "No backend architecture file"
```

**What to extract**:
- Python version
- Django version
- Database (PostgreSQL, MySQL)
- Testing framework (pytest)
- Code style (black, flake8)
- TDD workflow

**Verification**:
```
✅ Task type: Backend feature
✅ Read task-workflow.md skill
✅ Tech stack loaded:
  - Python: 3.11
  - Django: 5.0
  - Database: PostgreSQL 15
  - Tests: pytest with 80% coverage requirement
  - Style: black + flake8
✅ Ready to follow TDD workflow (RED → GREEN → REFACTOR)
```

---

#### 5.3 Load Context for Frontend Feature

**If user selects frontend feature**:

```bash
# Load task workflow skill
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/skills/task-workflow.md

# Load frontend architecture
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/frontend_architecture.yaml

# Load packages
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/packages.json
```

**What to extract**:
- Framework (Next.js, React)
- Package manager (pnpm, npm, bun)
- UI library (Tailwind, shadcn/ui)
- State management (Zustand, React Query)
- Testing (Vitest, Testing Library)
- Build configuration

**Verification**:
```
✅ Task type: Frontend feature
✅ Read task-workflow.md skill
✅ Frontend architecture loaded:
  - Framework: Next.js 14 (App Router)
  - Package manager: pnpm
  - UI: Tailwind + shadcn/ui
  - State: Zustand
  - Tests: Vitest + Testing Library
✅ Packages: @lightwave/ui, @lightwave/auth-client
✅ Ready for component development
```

---

#### 5.4 Load Context for Infrastructure

**If user selects infrastructure**:

```bash
# Load deployment metadata
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/deployment.yaml

# Load git conventions (for terraform branch naming)
cat /Users/joelschaeffer/dev/lightwave-workspace/.agent/metadata/git_conventions.yaml
```

**What to extract**:
- Deployment environments (dev, staging, prod)
- Infrastructure as Code tool (Terraform, Terragrunt)
- Cloud provider (AWS, GCP)
- Deployment targets (ECS, Lambda, S3)
- Approval workflows

**Verification**:
```
✅ Task type: Infrastructure deployment
✅ Read deployment.yaml
✅ Environments: dev, staging, prod
✅ Tool: Terragrunt (wrapping Terraform)
✅ Provider: AWS
✅ Targets: ECS Fargate, RDS, S3, CloudFront
✅ Workflow: Plan → Review → Apply (manual approval for prod)
```

---

#### 5.5 Load Context for Troubleshooting

**If user selects troubleshooting**:

```bash
# Load troubleshooter skill
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/skills/troubleshooter.md

# Load troubleshooting reference
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/TROUBLESHOOTING.md

# Check for relevant SOPs
ls /Users/joelschaeffer/dev/lightwave-workspace/.agent/sops/ | grep -i troubleshoot
```

**What to extract**:
- Common issues and solutions
- Diagnostic commands
- Log locations
- Escalation paths

**Verification**:
```
✅ Task type: Troubleshooting
✅ Read troubleshooter.md skill
✅ Read TROUBLESHOOTING.md reference
✅ Found SOPs:
  - SOP_DEPLOYMENT_HEALTH_TROUBLESHOOTING.md
✅ Ready to systematically diagnose issues
```

---

### Step 6: Generate Final Validation Report

**After completing all steps**, generate a structured report:

```yaml
context_validation:
  status: READY
  timestamp: 2025-10-28T19:45:00Z

  workspace_context:
    claude_md_version: 5.5.0
    agent_docs_last_sync: "2025-10-25 14:30 UTC"
    task_files_found: 5
    workspace_type: multi-repo
    git_repos_found: 3

  scope_identified:
    current_directory: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
    selected_repo: Backend/lightwave-backend
    repo_path: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
    repo_claude_md: found
    git_branch: dev

  secrets_status:
    needed: true
    aws_profile: lightwave-admin-new
    tokens_loaded: [CLOUDFLARE_API_TOKEN]

  environment_verified:
    pwd: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
    git_branch: dev
    git_uncommitted_files: 0
    aws_account: "738605694078"

  activity_context:
    task_type: backend_feature
    skill_loaded: task-workflow.md
    metadata_loaded: [tech_stack.yaml]

  blocking_issues: []

  ready_to_work: true
```

**Present to user**:
> "Onboarding complete! Here's my validation report:
>
> ✅ READY to work
> ✅ Workspace: lightwave-workspace (multi-repo, 3 repos found)
> ✅ Scope: Backend/lightwave-backend on branch 'dev'
> ✅ AWS: Authenticated as lightwave-admin
> ✅ Secrets: CLOUDFLARE_API_TOKEN loaded
> ✅ Context: Backend feature (Django, TDD workflow)
> ✅ No blocking issues
>
> I'm ready to start work. What would you like me to do?"

---

## When Checks Fail

### Scenario: Wrong Directory

**Symptoms**:
```
❌ .claude/CLAUDE.md not found
❌ .agent/ directory not found
```

**Diagnosis**: You're not in the workspace root.

**Solution**:
```bash
# Check where you are
pwd

# Navigate to workspace
cd /Users/joelschaeffer/dev/lightwave-workspace

# Verify
ls -la | grep -E "(\.claude|\.agent)"
# Should see both directories
```

---

### Scenario: AWS Profile Wrong or Not Set

**Symptoms**:
```
❌ aws sts get-caller-identity: Unable to locate credentials
❌ AWS account: ERROR
```

**Diagnosis**: AWS_PROFILE not set or wrong profile.

**Solution**:
```bash
# Check current profile
echo $AWS_PROFILE

# If empty or wrong:
export AWS_PROFILE=lightwave-admin-new

# Verify
aws sts get-caller-identity
```

**Reference**: See `.claude/SECRETS_MAP.md` for AWS profile names and `.claude/TROUBLESHOOTING.md` for "AWS Authentication Errors"

---

### Scenario: Multi-Repo Confusion

**Symptoms**:
```
❌ git status: fatal: not a git repository
❌ Multiple .git directories found at workspace root
```

**Diagnosis**: Trying to run git commands at workspace root in a multi-repo workspace.

**Solution**:
1. **Ask user which repo** (see Step 2.1)
2. **Navigate to that repo**:
   ```bash
   cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
   ```
3. **Now run git commands**

---

### Scenario: Stale Documentation

**Symptoms**:
```
⚠️  .agent/README.md last updated: 2025-10-01 (28 days ago)
```

**Diagnosis**: Documentation not synced from Notion recently.

**Solution**:
1. **Ask user**: "Documentation is 28 days old. Should I proceed with potentially stale context, or would you like to sync from Notion first?"
2. **If user says sync**: Provide instructions for their sync tool or manual process
3. **If user says proceed**: Note in validation report that docs may be stale

---

### Scenario: Secret Access Denied

**Symptoms**:
```
❌ AccessDeniedException when loading secret
```

**Diagnosis**: AWS profile doesn't have permission to access this secret.

**Solution**:
1. **Verify correct profile**:
   ```bash
   echo $AWS_PROFILE
   # Should be lightwave-admin-new for full access
   ```
2. **Check secret exists**:
   ```bash
   aws ssm describe-parameters --filters "Key=Name,Values=/lightwave/dev/cloudflare/api-token"
   ```
3. **Check IAM permissions**: May need to add `ssm:GetParameter` permission to IAM user

**Reference**: See `.claude/TROUBLESHOOTING.md` section "Secret Access Issues"

---

## Integration with Other Documentation

### SECRETS_MAP.md
- **When to use**: Step 3 (Load Secrets)
- **What it provides**: Locations and names of all secrets
- **How to use**: Read before asking user for any credentials

### TROUBLESHOOTING.md
- **When to use**: When any onboarding check fails
- **What it provides**: Common issues and solutions
- **How to use**: Reference specific sections by issue type

### task-workflow.md skill
- **When to use**: Step 5 (Load Activity Context) for feature work
- **What it provides**: TDD workflow guidance
- **How to use**: Load after onboarding for implementation guidance

### troubleshooter.md skill
- **When to use**: Step 5 for debugging tasks
- **What it provides**: Systematic troubleshooting process
- **How to use**: Load after onboarding for diagnostic guidance

---

## Time Estimates

| Step | Duration | Can Skip If |
|------|----------|-------------|
| 1. Workspace Context | 30 seconds | Never skip |
| 2. Identify Scope | 15 seconds | Single-repo workspace |
| 3. Load Secrets | 30 seconds | No credentials needed |
| 4. Verify Environment | 30 seconds | Just exploring |
| 5. Activity Context | 30 seconds | General exploration |
| 6. Generate Report | 15 seconds | Never skip |
| **Total** | **2.5 minutes** | - |

---

## Success Criteria

You have completed onboarding successfully when:

- ✅ All verification commands run without errors
- ✅ Validation report shows `status: READY`
- ✅ No blocking issues reported
- ✅ User confirms you have correct context
- ✅ You can answer: "What branch am I on?" or "What AWS account am I using?"

---

## Related Documentation

- **Checklist version**: `.claude/ONBOARDING.md` (quick reference)
- **Secrets loading**: `.claude/skills/secrets-loader.md`
- **Troubleshooting**: `.claude/TROUBLESHOOTING.md`
- **Workspace guide**: `.claude/CLAUDE.md`
- **Latest from Notion**: `.agent/README.md`

---

**Maintained by**: Joel Schaeffer
**Last Updated**: 2025-10-28
**Version**: 1.0.0
