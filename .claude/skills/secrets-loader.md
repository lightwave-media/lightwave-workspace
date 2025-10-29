# Skill: AWS Secrets Loading Process

**Version**: 1.0.0
**Created**: 2025-10-28
**Purpose**: Load secrets from AWS Secrets Manager and Parameter Store
**Status**: Active

---

## Overview

This skill provides step-by-step guidance for loading secrets and parameters from AWS into your environment for use in development, testing, deployment, and CI/CD workflows.

**Use this skill when**:
- You need API keys, tokens, or passwords documented in SECRETS_MAP.md
- Setting up local development environment
- Configuring CI/CD pipelines
- Troubleshooting authentication issues
- Onboarding requires credentials (Step 3 of ONBOARDING.md)

---

## Prerequisites

Before loading secrets:

1. **AWS CLI installed**:
   ```bash
   aws --version
   # Should show version 2.x or higher
   ```

2. **AWS profile configured**:
   ```bash
   export AWS_PROFILE=lightwave-admin-new
   aws sts get-caller-identity
   # Should show Account: 738605694078
   ```

3. **Read SECRETS_MAP.md**:
   ```bash
   cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/SECRETS_MAP.md
   ```

---

## AWS Secret Types: Secrets Manager vs Parameter Store

### Secrets Manager
- **Use for**: Database credentials, API keys with rotation
- **Path format**: Name-based (no slashes), e.g., `lightwave/dev/database`
- **Features**: Automatic rotation, versioning, JSON format support
- **Cost**: $0.40/secret/month + $0.05 per 10,000 API calls

### Parameter Store
- **Use for**: Configuration values, simple tokens
- **Path format**: Hierarchical paths, e.g., `/lightwave/dev/cloudflare/api-token`
- **Features**: Free tier for standard parameters, hierarchical organization
- **Cost**: Free for standard (up to 10,000), $0.05/advanced parameter/month

**How to determine which to use**: Check SECRETS_MAP.md - it documents the location of each secret.

---

## Step-by-Step: Loading Secrets

### Step 1: Identify the Secret

**Read SECRETS_MAP.md to find**:
- Secret name
- Location (Secrets Manager or Parameter Store)
- Environment (dev, staging, prod)
- Format (plain text, JSON, key-value pairs)

**Example from SECRETS_MAP.md**:
```markdown
## CLOUDFLARE_API_TOKEN

**Location**: AWS Systems Manager Parameter Store
**Path**: `/lightwave/{environment}/cloudflare/api-token`
**Type**: SecureString
**Environments**: dev, staging, prod
**Format**: Plain text
**Used by**: Frontend deployment scripts, DNS management
```

---

### Step 2: Verify AWS Access

```bash
# Ensure correct profile
export AWS_PROFILE=lightwave-admin-new

# Verify identity
aws sts get-caller-identity | jq -r '.Account'
# Expected: 738605694078

# Test access to Parameter Store
aws ssm describe-parameters --max-items 1

# Test access to Secrets Manager
aws secretsmanager list-secrets --max-results 1
```

**If access denied**:
- Check IAM permissions for your user
- Verify you're using `lightwave-admin-new` profile (not `lightwave-email-service`)
- See `.claude/TROUBLESHOOTING.md` section "AWS Authentication Errors"

---

### Step 3: Load from Parameter Store

**For parameters** (paths starting with `/`):

#### Option A: Load Single Parameter (Plain Text)

```bash
# Basic load
aws ssm get-parameter \
  --name "/lightwave/dev/cloudflare/api-token" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text

# Load and export to environment variable
export CLOUDFLARE_API_TOKEN=$(aws ssm get-parameter \
  --name "/lightwave/dev/cloudflare/api-token" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)

# Verify (show only first 10 chars)
echo "Loaded CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN:0:10}..."
```

#### Option B: Load Multiple Parameters by Path

```bash
# Load all parameters under a path
aws ssm get-parameters-by-path \
  --path "/lightwave/dev" \
  --recursive \
  --with-decryption \
  --query 'Parameters[*].[Name,Value]' \
  --output text

# Load and export multiple parameters
while IFS=$'\t' read -r name value; do
  # Extract parameter name (last part of path)
  var_name=$(basename "$name" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  export "$var_name"="$value"
  echo "✅ Loaded: $var_name"
done < <(aws ssm get-parameters-by-path \
  --path "/lightwave/dev" \
  --recursive \
  --with-decryption \
  --query 'Parameters[*].[Name,Value]' \
  --output text)
```

#### Option C: Use Convenience Script

```bash
# Use the workspace's load-secrets script
/Users/joelschaeffer/dev/lightwave-workspace/.claude/load-secrets.sh dev

# Source it to export to current shell
source /Users/joelschaeffer/dev/lightwave-workspace/.claude/load-secrets.sh dev
```

---

### Step 4: Load from Secrets Manager

**For secrets** (names without slashes):

#### Option A: Load Secret (Plain Text Value)

```bash
# Load secret
aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/github-token" \
  --query 'SecretString' \
  --output text

# Load and export
export GITHUB_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/github-token" \
  --query 'SecretString' \
  --output text)

# Verify
echo "Loaded GITHUB_TOKEN: ${GITHUB_TOKEN:0:10}..."
```

#### Option B: Load Secret (JSON Format)

Many secrets in Secrets Manager are stored as JSON with multiple key-value pairs.

```bash
# View full JSON
aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/database" \
  --query 'SecretString' \
  --output text | jq '.'

# Example output:
# {
#   "username": "admin",
#   "password": "secretpassword",
#   "engine": "postgres",
#   "host": "db.example.com",
#   "port": 5432,
#   "dbname": "lightwave"
# }

# Extract specific keys
export DB_HOST=$(aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/database" \
  --query 'SecretString' \
  --output text | jq -r '.host')

export DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/database" \
  --query 'SecretString' \
  --output text | jq -r '.password')

export DB_USER=$(aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/database" \
  --query 'SecretString' \
  --output text | jq -r '.username')

export DB_NAME=$(aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/database" \
  --query 'SecretString' \
  --output text | jq -r '.dbname')

# Verify
echo "Loaded database config:"
echo "  Host: $DB_HOST"
echo "  User: $DB_USER"
echo "  Database: $DB_NAME"
echo "  Password: ${DB_PASSWORD:0:5}..."
```

#### Option C: Load All Keys from JSON Secret

```bash
# Load all keys from JSON secret and export as environment variables
eval $(aws secretsmanager get-secret-value \
  --secret-id "lightwave/dev/database" \
  --query 'SecretString' \
  --output text | jq -r 'to_entries | map("export \(.key | ascii_upcase)=\(.value | @sh)") | .[]')

# Verify
env | grep -E "^(USERNAME|PASSWORD|HOST|PORT|DBNAME)="
```

---

### Step 5: Verify Secrets Loaded

**Check environment variables**:

```bash
# List all exported secrets (be careful not to print values)
env | grep -E "^(CLOUDFLARE|GITHUB|AWS|DB_|DATABASE)" | cut -d= -f1

# Verify specific secret (show only first 10 chars)
echo "CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN:0:10}..."

# Check if secret is set (without printing value)
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  echo "✅ CLOUDFLARE_API_TOKEN is set"
else
  echo "❌ CLOUDFLARE_API_TOKEN is NOT set"
fi
```

---

## Usage in Different Contexts

### Context 1: Bash Scripts

```bash
#!/bin/bash

# Load secrets at script start
export AWS_PROFILE=lightwave-admin-new

export CLOUDFLARE_API_TOKEN=$(aws ssm get-parameter \
  --name "/lightwave/dev/cloudflare/api-token" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)

# Use in script
curl -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json"
```

---

### Context 2: Python Scripts

```python
import os
import boto3
import json

# Set AWS profile
os.environ['AWS_PROFILE'] = 'lightwave-admin-new'

# Initialize AWS clients
ssm = boto3.client('ssm', region_name='us-east-1')
secretsmanager = boto3.client('secretsmanager', region_name='us-east-1')

# Load from Parameter Store
def load_parameter(name):
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']

# Load from Secrets Manager
def load_secret(secret_id):
    response = secretsmanager.get_secret_value(SecretId=secret_id)
    return response['SecretString']

# Load secrets
cloudflare_token = load_parameter('/lightwave/dev/cloudflare/api-token')
database_secret = json.loads(load_secret('lightwave/dev/database'))

# Use secrets
db_host = database_secret['host']
db_password = database_secret['password']

print(f"Loaded Cloudflare token: {cloudflare_token[:10]}...")
print(f"Database host: {db_host}")
```

---

### Context 3: Node.js / TypeScript

```typescript
import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

// Initialize clients (uses AWS_PROFILE from environment)
const ssmClient = new SSMClient({ region: "us-east-1" });
const secretsClient = new SecretsManagerClient({ region: "us-east-1" });

// Load from Parameter Store
async function loadParameter(name: string): Promise<string> {
  const command = new GetParameterCommand({
    Name: name,
    WithDecryption: true,
  });
  const response = await ssmClient.send(command);
  return response.Parameter?.Value || "";
}

// Load from Secrets Manager
async function loadSecret(secretId: string): Promise<any> {
  const command = new GetSecretValueCommand({
    SecretId: secretId,
  });
  const response = await secretsClient.send(command);
  return JSON.parse(response.SecretString || "{}");
}

// Usage
async function main() {
  const cloudflareToken = await loadParameter("/lightwave/dev/cloudflare/api-token");
  const databaseSecret = await loadSecret("lightwave/dev/database");

  console.log(`Loaded Cloudflare token: ${cloudflareToken.substring(0, 10)}...`);
  console.log(`Database host: ${databaseSecret.host}`);
}

main();
```

---

### Context 4: Docker / Docker Compose

**Option A: Load secrets as environment variables**

```yaml
# docker-compose.yml
version: '3.8'

services:
  backend:
    image: lightwave-backend:latest
    environment:
      # Load from Parameter Store before running docker-compose
      CLOUDFLARE_API_TOKEN: ${CLOUDFLARE_API_TOKEN}
      DB_HOST: ${DB_HOST}
      DB_PASSWORD: ${DB_PASSWORD}
    env_file:
      - .env  # Or load from .env file
```

**Before running**:
```bash
# Load secrets into environment
source /Users/joelschaeffer/dev/lightwave-workspace/.claude/load-secrets.sh dev

# Run docker-compose (will inherit environment variables)
docker-compose up
```

**Option B: Use Docker secrets** (for Swarm mode):
```bash
# Create Docker secret from AWS
aws ssm get-parameter \
  --name "/lightwave/dev/cloudflare/api-token" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text | docker secret create cloudflare_token -
```

---

### Context 5: GitHub Actions / CI/CD

**Load secrets in workflow**:

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::738605694078:role/GitHubActionsRole
          aws-region: us-east-1

      - name: Load Secrets from Parameter Store
        id: load-secrets
        run: |
          # Load Cloudflare token
          CLOUDFLARE_TOKEN=$(aws ssm get-parameter \
            --name "/lightwave/prod/cloudflare/api-token" \
            --with-decryption \
            --query 'Parameter.Value' \
            --output text)

          # Export as GitHub Actions output (masked)
          echo "::add-mask::$CLOUDFLARE_TOKEN"
          echo "cloudflare-token=$CLOUDFLARE_TOKEN" >> $GITHUB_OUTPUT

      - name: Deploy to Cloudflare
        env:
          CLOUDFLARE_API_TOKEN: ${{ steps.load-secrets.outputs.cloudflare-token }}
        run: |
          # Deployment commands using $CLOUDFLARE_API_TOKEN
          npm run deploy
```

---

## Troubleshooting Secret Access Issues

### Issue: Access Denied

**Symptoms**:
```
An error occurred (AccessDeniedException) when calling the GetParameter operation:
User: arn:aws:iam::738605694078:user/developer is not authorized to perform:
ssm:GetParameter on resource: arn:aws:ssm:us-east-1:738605694078:parameter/lightwave/dev/cloudflare/api-token
```

**Diagnosis**: IAM user/role lacks required permissions.

**Solution**:
1. **Verify you're using correct profile**:
   ```bash
   echo $AWS_PROFILE
   # Should be: lightwave-admin-new
   ```

2. **Check IAM permissions**:
   ```bash
   aws iam get-user-policy \
     --user-name lightwave-admin \
     --policy-name ParameterStoreAccess
   ```

3. **Required permissions**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ssm:GetParameter",
           "ssm:GetParameters",
           "ssm:GetParametersByPath",
           "secretsmanager:GetSecretValue",
           "secretsmanager:DescribeSecret"
         ],
         "Resource": [
           "arn:aws:ssm:us-east-1:738605694078:parameter/lightwave/*",
           "arn:aws:secretsmanager:us-east-1:738605694078:secret:lightwave/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "kms:Decrypt"
         ],
         "Resource": "arn:aws:kms:us-east-1:738605694078:key/*"
       }
     ]
   }
   ```

4. **Escalate**: If permissions missing, contact AWS admin to add policies.

---

### Issue: Parameter Not Found

**Symptoms**:
```
An error occurred (ParameterNotFound) when calling the GetParameter operation:
Parameter /lightwave/dev/cloudflare/api-token not found.
```

**Diagnosis**: Parameter doesn't exist in AWS or path is wrong.

**Solution**:
1. **List available parameters**:
   ```bash
   aws ssm describe-parameters \
     --parameter-filters "Key=Name,Option=BeginsWith,Values=/lightwave/dev" \
     --query 'Parameters[*].Name'
   ```

2. **Check SECRETS_MAP.md for correct path**:
   ```bash
   grep -A 5 "CLOUDFLARE_API_TOKEN" /Users/joelschaeffer/dev/lightwave-workspace/.claude/SECRETS_MAP.md
   ```

3. **Verify environment** (dev vs prod):
   - `/lightwave/dev/...` = development
   - `/lightwave/prod/...` = production

4. **Create parameter if missing**:
   ```bash
   aws ssm put-parameter \
     --name "/lightwave/dev/cloudflare/api-token" \
     --value "your-token-here" \
     --type "SecureString" \
     --description "Cloudflare API token for dev environment"
   ```

---

### Issue: Decryption Failed

**Symptoms**:
```
An error occurred (InvalidKeyId) when calling the GetParameter operation:
The request is not valid for the key: arn:aws:kms:us-east-1:738605694078:key/...
```

**Diagnosis**: Parameter is encrypted with KMS key you don't have access to.

**Solution**:
1. **Check KMS key permissions**:
   ```bash
   aws kms describe-key --key-id "alias/parameter-store-key"
   ```

2. **Verify you have kms:Decrypt permission** (see IAM policy above)

3. **Contact AWS admin** to grant KMS key access

---

### Issue: Secret Value is Empty

**Symptoms**:
```bash
export TOKEN=$(aws ssm get-parameter --name "/path/to/token" --query 'Parameter.Value' --output text)
echo $TOKEN
# Output: (empty)
```

**Diagnosis**: Secret exists but value is empty string.

**Solution**:
1. **Check parameter value in AWS Console**
2. **Verify environment** (may be set in prod but not dev)
3. **Create/update parameter with actual value**

---

### Issue: jq Not Installed

**Symptoms**:
```
bash: jq: command not found
```

**Diagnosis**: `jq` utility not installed (needed for JSON parsing).

**Solution**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Verify
jq --version
```

---

## Security Best Practices

### 1. Never Print Secrets in Logs

**Bad**:
```bash
echo "Token: $CLOUDFLARE_API_TOKEN"  # Prints full token!
```

**Good**:
```bash
# Show only first 10 characters
echo "Token: ${CLOUDFLARE_API_TOKEN:0:10}..."

# Or just confirm it's set
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
  echo "✅ Token loaded successfully"
fi
```

---

### 2. Use --with-decryption Flag

Always use `--with-decryption` when loading SecureString parameters:

```bash
# Correct
aws ssm get-parameter --name "/path/to/secret" --with-decryption

# Wrong (returns encrypted value)
aws ssm get-parameter --name "/path/to/secret"
```

---

### 3. Don't Commit Secrets to Git

**Never**:
- Commit `.env` files with real secrets
- Hardcode secrets in code
- Put secrets in git history

**Instead**:
- Use `.env.example` with placeholder values
- Load secrets from AWS at runtime
- Add `.env` to `.gitignore`

---

### 4. Use Separate Secrets per Environment

```
/lightwave/dev/cloudflare/api-token    → Development token
/lightwave/staging/cloudflare/api-token → Staging token
/lightwave/prod/cloudflare/api-token   → Production token (different value!)
```

This prevents dev deployments from affecting production.

---

### 5. Rotate Secrets Regularly

- Database passwords: Every 90 days
- API tokens: Every 180 days
- Access keys: Every 90 days

Use Secrets Manager's automatic rotation for critical secrets.

---

## Reference: Complete Load Script

Here's a complete script to load all secrets for a given environment:

```bash
#!/bin/bash
# /Users/joelschaeffer/dev/lightwave-workspace/.claude/load-secrets.sh

set -euo pipefail

# Usage: source ./load-secrets.sh [environment]
ENVIRONMENT=${1:-dev}

echo "Loading secrets for environment: $ENVIRONMENT"

# Set AWS profile
export AWS_PROFILE=lightwave-admin-new

# Verify AWS access
if ! aws sts get-caller-identity &>/dev/null; then
  echo "❌ AWS authentication failed. Check AWS_PROFILE."
  return 1
fi

# Load from Parameter Store
load_parameter() {
  local param_name=$1
  local var_name=$2

  local value=$(aws ssm get-parameter \
    --name "$param_name" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text 2>/dev/null)

  if [ -n "$value" ]; then
    export "$var_name"="$value"
    echo "✅ Loaded: $var_name (${value:0:10}...)"
  else
    echo "⚠️  Warning: $param_name not found or empty"
  fi
}

# Load from Secrets Manager (JSON)
load_secret_json() {
  local secret_id=$1

  local secret_json=$(aws secretsmanager get-secret-value \
    --secret-id "$secret_id" \
    --query 'SecretString' \
    --output text 2>/dev/null)

  if [ -n "$secret_json" ]; then
    # Export all keys as environment variables
    eval $(echo "$secret_json" | jq -r 'to_entries | map("export \(.key | ascii_upcase)=\(.value | @sh)") | .[]')
    echo "✅ Loaded secret: $secret_id"
  else
    echo "⚠️  Warning: $secret_id not found"
  fi
}

# Load common secrets
load_parameter "/lightwave/$ENVIRONMENT/cloudflare/api-token" "CLOUDFLARE_API_TOKEN"
load_parameter "/lightwave/$ENVIRONMENT/github/token" "GITHUB_TOKEN"
load_secret_json "lightwave/$ENVIRONMENT/database"

echo ""
echo "✅ Secret loading complete for $ENVIRONMENT"
echo ""
echo "Loaded environment variables:"
env | grep -E "^(CLOUDFLARE|GITHUB|DB_|HOST|USERNAME|PASSWORD)" | cut -d= -f1 | sed 's/^/  - /'
```

**Usage**:
```bash
# Load dev secrets
source /Users/joelschaeffer/dev/lightwave-workspace/.claude/load-secrets.sh dev

# Load prod secrets
source /Users/joelschaeffer/dev/lightwave-workspace/.claude/load-secrets.sh prod
```

---

## Related Documentation

- **Secret locations**: `.claude/SECRETS_MAP.md`
- **Troubleshooting**: `.claude/TROUBLESHOOTING.md` (AWS Authentication section)
- **Onboarding**: `.claude/ONBOARDING.md` (Step 3: Load Secrets)
- **AWS IAM permissions**: Infrastructure repo IAM policies

---

**Maintained by**: Joel Schaeffer
**Last Updated**: 2025-10-28
**Version**: 1.0.0
