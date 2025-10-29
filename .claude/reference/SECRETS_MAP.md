# Secrets Map - AWS Secrets Manager & Parameter Store

**CRITICAL**: All secrets are stored in AWS. Never hardcode secrets in code or commit them to git.

**Last Updated**: 2025-10-28
**AWS Account**: 738605694078
**Primary Profile**: `lightwave-admin-new`
**Region**: us-east-1

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [AWS Profile Setup](#aws-profile-setup)
3. [Secrets Manager Secrets](#secrets-manager-secrets)
4. [Parameter Store Parameters](#parameter-store-parameters)
5. [Loading Secrets](#loading-secrets)
6. [Environment-Specific Secrets](#environment-specific-secrets)
7. [Common Patterns](#common-patterns)
8. [Troubleshooting](#troubleshooting)

---

## Quick Start

**ALWAYS run this first**:
```bash
export AWS_PROFILE=lightwave-admin-new
```

**Verify profile is set**:
```bash
echo $AWS_PROFILE
# Expected output: lightwave-admin-new

aws sts get-caller-identity
# Expected output: Account 738605694078, User: lightwave-admin
```

**Load a single secret**:
```bash
# From Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/secret-key \
  --query SecretString \
  --output text

# From Parameter Store
aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

---

## AWS Profile Setup

### Primary Profiles

| Profile | Purpose | Permissions | When to Use |
|---------|---------|-------------|-------------|
| `lightwave-admin-new` | Admin operations | Full access to Secrets Manager, Parameter Store, S3, EC2, etc. | **DEFAULT** - Use for all development and deployment |
| `lightwave-email-service` | Email service only | Limited to SES operations | **ONLY** for email-specific operations |

### Critical Warning

**ALWAYS use `lightwave-admin-new` unless working specifically with SES email operations.**

If you see errors like:
- "User: arn:aws:iam::738605694078:user/lightwave-email-service is not authorized"
- "AccessDeniedException"

**Fix**: Run `export AWS_PROFILE=lightwave-admin-new`

### Verify Your Profile

```bash
# Check current profile
echo $AWS_PROFILE

# Verify identity (should show lightwave-admin user)
aws sts get-caller-identity | grep Arn
# Expected: "Arn": "arn:aws:iam::738605694078:user/lightwave-admin"
```

---

## Secrets Manager Secrets

**Location**: AWS Secrets Manager
**Format**: JSON or plaintext strings
**Use Case**: Sensitive credentials that need rotation (database passwords, API keys with high security requirements)

### Development Environment (`/lightwave/dev/`)

#### Django Application Secrets

```bash
# Django Secret Key (cryptographic key for Django)
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/secret-key \
  --query SecretString \
  --output text

# Database URL (PostgreSQL connection string)
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/database-url \
  --query SecretString \
  --output text
# Format: postgresql://user:password@host:5432/dbname

# Redis URL (cache and session storage)
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/redis-url \
  --query SecretString \
  --output text
# Format: redis://host:6379/0

# Allowed Hosts (comma-separated list of allowed Django hosts)
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/allowed-hosts \
  --query SecretString \
  --output text
# Format: localhost,127.0.0.1,.example.com
```

#### Payment Processing

```bash
# Stripe Secret Key (payment processing API key)
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/stripe/secret-key \
  --query SecretString \
  --output text
# Format: sk_test_...
```

### Load All Development Secrets

```bash
# Export all dev secrets to environment variables
export DJANGO_SECRET_KEY=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/secret-key \
  --query SecretString --output text)

export DATABASE_URL=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/database-url \
  --query SecretString --output text)

export REDIS_URL=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/redis-url \
  --query SecretString --output text)

export DJANGO_ALLOWED_HOSTS=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/allowed-hosts \
  --query SecretString --output text)

export STRIPE_SECRET_KEY=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/stripe/secret-key \
  --query SecretString --output text)
```

---

## Parameter Store Parameters

**Location**: AWS Systems Manager Parameter Store
**Format**: String, SecureString (encrypted), StringList
**Use Case**: Configuration values, API tokens, feature flags
**Count**: 90+ parameters

### Production Environment (`/lightwave/prod/`)

#### AI & APIs

```bash
# Anthropic API Key (Claude API access)
aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text

# OpenAI API Key
aws ssm get-parameter \
  --name /lightwave/prod/OPENAI_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

#### Infrastructure & DNS

```bash
# Cloudflare API Token (DNS management, CDN config)
aws ssm get-parameter \
  --name /lightwave/prod/CLOUDFLARE_API_TOKEN \
  --with-decryption \
  --query Parameter.Value \
  --output text

# Cloudflare Zone ID
aws ssm get-parameter \
  --name /lightwave/prod/CLOUDFLARE_ZONE_ID \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

#### Version Control & Project Management

```bash
# GitHub Personal Access Token (repo access, API operations)
aws ssm get-parameter \
  --name /lightwave/prod/GITHUB_TOKEN \
  --with-decryption \
  --query Parameter.Value \
  --output text

# Notion API Key (workspace integration)
aws ssm get-parameter \
  --name /lightwave/prod/NOTION_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text

# Notion Database IDs
aws ssm get-parameter \
  --name /lightwave/prod/NOTION_TASKS_DB_ID \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

### List All Parameters

```bash
# List all parameters with /lightwave/ prefix
aws ssm get-parameters-by-path \
  --path /lightwave/ \
  --recursive \
  --query 'Parameters[*].Name' \
  --output table

# List with values (WARNING: will show secrets)
aws ssm get-parameters-by-path \
  --path /lightwave/ \
  --recursive \
  --with-decryption \
  --query 'Parameters[*].[Name,Value]' \
  --output table
```

### List by Environment

```bash
# Production parameters only
aws ssm get-parameters-by-path \
  --path /lightwave/prod/ \
  --recursive \
  --query 'Parameters[*].Name' \
  --output table

# Development parameters only
aws ssm get-parameters-by-path \
  --path /lightwave/dev/ \
  --recursive \
  --query 'Parameters[*].Name' \
  --output table
```

---

## Loading Secrets

### Local Development (.env file)

**Never commit .env files to git**. Add `.env` to `.gitignore`.

#### Create .env from AWS Secrets

```bash
#!/bin/bash
# save as: scripts/load-dev-secrets.sh

# Ensure AWS profile is set
export AWS_PROFILE=lightwave-admin-new

# Create .env file from AWS secrets
cat > .env << EOF
# Django Configuration
DJANGO_SECRET_KEY=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/secret-key \
  --query SecretString --output text)

DATABASE_URL=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/database-url \
  --query SecretString --output text)

REDIS_URL=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/redis-url \
  --query SecretString --output text)

DJANGO_ALLOWED_HOSTS=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/allowed-hosts \
  --query SecretString --output text)

# Payment Processing
STRIPE_SECRET_KEY=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/stripe/secret-key \
  --query SecretString --output text)

# AI APIs (from Parameter Store)
ANTHROPIC_API_KEY=$(aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value --output text)

OPENAI_API_KEY=$(aws ssm get-parameter \
  --name /lightwave/prod/OPENAI_API_KEY \
  --with-decryption \
  --query Parameter.Value --output text)

# Infrastructure
CLOUDFLARE_API_TOKEN=$(aws ssm get-parameter \
  --name /lightwave/prod/CLOUDFLARE_API_TOKEN \
  --with-decryption \
  --query Parameter.Value --output text)

GITHUB_TOKEN=$(aws ssm get-parameter \
  --name /lightwave/prod/GITHUB_TOKEN \
  --with-decryption \
  --query Parameter.Value --output text)

NOTION_API_KEY=$(aws ssm get-parameter \
  --name /lightwave/prod/NOTION_API_KEY \
  --with-decryption \
  --query Parameter.Value --output text)
EOF

chmod 600 .env
echo "✅ Created .env file with secrets from AWS"
echo "⚠️  Remember: .env should be in .gitignore"
```

#### Load .env into Shell

```bash
# Export all variables from .env
export $(cat .env | grep -v '^#' | xargs)

# Verify secrets loaded
echo $DJANGO_SECRET_KEY | head -c 20
echo $ANTHROPIC_API_KEY | head -c 20
```

### Production Environment Variables

**Production applications load secrets directly from AWS at runtime**.

#### Docker/ECS Example

```dockerfile
# In Dockerfile or docker-compose.yml
# DO NOT hardcode secrets - pass via environment at runtime

# ECS Task Definition passes secrets from Parameter Store:
# "secrets": [
#   {
#     "name": "ANTHROPIC_API_KEY",
#     "valueFrom": "/lightwave/prod/ANTHROPIC_API_KEY"
#   }
# ]
```

#### Lambda Functions

```python
# Lambda loads from Parameter Store at runtime
import boto3
import os

ssm = boto3.client('ssm', region_name='us-east-1')

def get_secret(parameter_name):
    """Load secret from Parameter Store."""
    response = ssm.get_parameter(
        Name=parameter_name,
        WithDecryption=True
    )
    return response['Parameter']['Value']

# Usage
ANTHROPIC_API_KEY = get_secret('/lightwave/prod/ANTHROPIC_API_KEY')
```

---

## Environment-Specific Secrets

### Development (`/lightwave/dev/`)

**Purpose**: Local development, testing, staging environments
**Storage**: Primarily Secrets Manager
**Characteristics**:
- Lower security requirements (but still encrypted)
- Can be rotated less frequently
- Safe to use test API keys (e.g., Stripe test keys)

**Secrets**:
- Django configuration (secret key, database, Redis, allowed hosts)
- Stripe test keys
- Development database credentials

### Production (`/lightwave/prod/`)

**Purpose**: Live production systems
**Storage**: Primarily Parameter Store
**Characteristics**:
- Highest security requirements
- Encrypted SecureString type
- Regular rotation recommended
- Production API keys and credentials

**Secrets**:
- All API keys (Anthropic, OpenAI, GitHub, Notion, Cloudflare)
- Production service credentials
- Infrastructure access tokens

---

## Common Patterns

### Pattern 1: Load Secret into Variable

```bash
# Single secret
export API_KEY=$(aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text)

# Verify loaded (show first 20 chars only)
echo $API_KEY | head -c 20
```

### Pattern 2: Load Multiple Secrets

```bash
# Create array of parameter names
PARAMS=(
  "/lightwave/prod/ANTHROPIC_API_KEY"
  "/lightwave/prod/OPENAI_API_KEY"
  "/lightwave/prod/GITHUB_TOKEN"
)

# Load each parameter
for param in "${PARAMS[@]}"; do
  # Extract variable name from path (last segment)
  var_name=$(echo $param | awk -F/ '{print $NF}')

  # Load and export
  export $var_name=$(aws ssm get-parameter \
    --name $param \
    --with-decryption \
    --query Parameter.Value \
    --output text)

  echo "✅ Loaded $var_name"
done
```

### Pattern 3: Load Secret in Python

```python
import boto3
from typing import Optional

class SecretsManager:
    """Load secrets from AWS Secrets Manager and Parameter Store."""

    def __init__(self, region: str = 'us-east-1'):
        self.sm_client = boto3.client('secretsmanager', region_name=region)
        self.ssm_client = boto3.client('ssm', region_name=region)

    def get_secret(self, secret_id: str) -> str:
        """Get secret from Secrets Manager."""
        try:
            response = self.sm_client.get_secret_value(SecretId=secret_id)
            return response['SecretString']
        except Exception as e:
            raise ValueError(f"Failed to load secret {secret_id}: {e}")

    def get_parameter(self, parameter_name: str, decrypt: bool = True) -> str:
        """Get parameter from Parameter Store."""
        try:
            response = self.ssm_client.get_parameter(
                Name=parameter_name,
                WithDecryption=decrypt
            )
            return response['Parameter']['Value']
        except Exception as e:
            raise ValueError(f"Failed to load parameter {parameter_name}: {e}")

# Usage
secrets = SecretsManager()

# From Secrets Manager
django_secret = secrets.get_secret('/lightwave/dev/django/secret-key')
database_url = secrets.get_secret('/lightwave/dev/django/database-url')

# From Parameter Store
anthropic_key = secrets.get_parameter('/lightwave/prod/ANTHROPIC_API_KEY')
github_token = secrets.get_parameter('/lightwave/prod/GITHUB_TOKEN')
```

### Pattern 4: Load Secret in Node.js

```javascript
const {
  SecretsManagerClient,
  GetSecretValueCommand
} = require('@aws-sdk/client-secrets-manager');

const {
  SSMClient,
  GetParameterCommand
} = require('@aws-sdk/client-ssm');

const region = 'us-east-1';

// Secrets Manager client
const smClient = new SecretsManagerClient({ region });

// Parameter Store client
const ssmClient = new SSMClient({ region });

async function getSecret(secretId) {
  try {
    const command = new GetSecretValueCommand({ SecretId: secretId });
    const response = await smClient.send(command);
    return response.SecretString;
  } catch (error) {
    throw new Error(`Failed to load secret ${secretId}: ${error.message}`);
  }
}

async function getParameter(parameterName, decrypt = true) {
  try {
    const command = new GetParameterCommand({
      Name: parameterName,
      WithDecryption: decrypt
    });
    const response = await ssmClient.send(command);
    return response.Parameter.Value;
  } catch (error) {
    throw new Error(`Failed to load parameter ${parameterName}: ${error.message}`);
  }
}

// Usage
(async () => {
  // From Secrets Manager
  const djangoSecret = await getSecret('/lightwave/dev/django/secret-key');
  const databaseUrl = await getSecret('/lightwave/dev/django/database-url');

  // From Parameter Store
  const anthropicKey = await getParameter('/lightwave/prod/ANTHROPIC_API_KEY');
  const githubToken = await getParameter('/lightwave/prod/GITHUB_TOKEN');
})();
```

### Pattern 5: Secrets in CI/CD (GitHub Actions)

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
      - uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::738605694078:role/GitHubActionsRole
          aws-region: us-east-1

      - name: Load secrets from AWS
        run: |
          # Load from Secrets Manager
          export DJANGO_SECRET_KEY=$(aws secretsmanager get-secret-value \
            --secret-id /lightwave/dev/django/secret-key \
            --query SecretString --output text)

          # Load from Parameter Store
          export ANTHROPIC_API_KEY=$(aws ssm get-parameter \
            --name /lightwave/prod/ANTHROPIC_API_KEY \
            --with-decryption \
            --query Parameter.Value --output text)

          # Run deployment with secrets as env vars
          ./scripts/deploy.sh
```

---

## Secrets by Domain

### Django Backend

| Secret | Location | Environment | Type |
|--------|----------|-------------|------|
| Secret Key | `/lightwave/dev/django/secret-key` | Development | Secrets Manager |
| Database URL | `/lightwave/dev/django/database-url` | Development | Secrets Manager |
| Redis URL | `/lightwave/dev/django/redis-url` | Development | Secrets Manager |
| Allowed Hosts | `/lightwave/dev/django/allowed-hosts` | Development | Secrets Manager |

### Payment Processing

| Secret | Location | Environment | Type |
|--------|----------|-------------|------|
| Stripe Secret Key | `/lightwave/dev/stripe/secret-key` | Development | Secrets Manager |
| Stripe Publishable Key | (Frontend - not in AWS) | Development | Public |

### AI APIs

| Secret | Location | Environment | Type |
|--------|----------|-------------|------|
| Anthropic API Key | `/lightwave/prod/ANTHROPIC_API_KEY` | Production | Parameter Store |
| OpenAI API Key | `/lightwave/prod/OPENAI_API_KEY` | Production | Parameter Store |

### Infrastructure

| Secret | Location | Environment | Type |
|--------|----------|-------------|------|
| Cloudflare API Token | `/lightwave/prod/CLOUDFLARE_API_TOKEN` | Production | Parameter Store |
| Cloudflare Zone ID | `/lightwave/prod/CLOUDFLARE_ZONE_ID` | Production | Parameter Store |
| GitHub Token | `/lightwave/prod/GITHUB_TOKEN` | Production | Parameter Store |

### Project Management

| Secret | Location | Environment | Type |
|--------|----------|-------------|------|
| Notion API Key | `/lightwave/prod/NOTION_API_KEY` | Production | Parameter Store |
| Notion Tasks DB ID | `/lightwave/prod/NOTION_TASKS_DB_ID` | Production | Parameter Store |

---

## Troubleshooting

### Error: "User lightwave-email-service is not authorized"

**Cause**: Using wrong AWS profile (lightwave-email-service has limited permissions)

**Fix**:
```bash
export AWS_PROFILE=lightwave-admin-new

# Verify
aws sts get-caller-identity | grep lightwave-admin
```

### Error: "Secrets Manager can't find the specified secret"

**Possible causes**:
1. Secret doesn't exist (typo in secret ID)
2. Wrong region (secrets are in us-east-1)
3. Wrong AWS profile

**Fix**:
```bash
# Verify secret exists
aws secretsmanager list-secrets \
  --query 'SecretList[*].Name' \
  --output table

# Ensure using correct region
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/secret-key \
  --region us-east-1 \
  --query SecretString \
  --output text
```

### Error: "Parameter not found"

**Possible causes**:
1. Parameter doesn't exist (typo in parameter name)
2. Wrong AWS profile
3. Insufficient permissions

**Fix**:
```bash
# List all parameters to find correct name
aws ssm get-parameters-by-path \
  --path /lightwave/ \
  --recursive \
  --query 'Parameters[*].Name' \
  --output table

# Try with exact name from list
aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --with-decryption \
  --query Parameter.Value \
  --output text
```

### Error: "AccessDeniedException"

**Cause**: AWS profile doesn't have permission to access secret/parameter

**Fix**:
```bash
# Ensure using admin profile
export AWS_PROFILE=lightwave-admin-new

# Verify identity
aws sts get-caller-identity
# Should show: user/lightwave-admin in ARN
```

### Secret Value is Empty or Malformed

**Check secret format**:
```bash
# View full secret response (includes metadata)
aws secretsmanager get-secret-value \
  --secret-id /lightwave/dev/django/secret-key

# Check parameter type
aws ssm get-parameter \
  --name /lightwave/prod/ANTHROPIC_API_KEY \
  --query 'Parameter.Type' \
  --output text
# Should show: SecureString
```

### Can't Load Secret in Application

**Common issues**:
1. AWS credentials not configured in application environment
2. IAM role/user lacks permissions
3. Wrong region configured in SDK

**Fix**:
```python
# Explicitly configure region and credentials
import boto3

# Option 1: Use default credentials (profile from ~/.aws/credentials)
client = boto3.client('secretsmanager', region_name='us-east-1')

# Option 2: Use IAM role (for Lambda, ECS, EC2)
# No explicit credentials needed - role attached to service

# Option 3: Explicit credentials (NOT recommended - use IAM roles instead)
# client = boto3.client(
#     'secretsmanager',
#     region_name='us-east-1',
#     aws_access_key_id='...',
#     aws_secret_access_key='...'
# )
```

---

## Security Best Practices

### DO:
- Always use `lightwave-admin-new` profile for admin operations
- Always use `--with-decryption` flag when loading SecureString parameters
- Store secrets in AWS, never in code or git
- Use IAM roles for applications (Lambda, ECS, EC2) instead of hardcoded credentials
- Rotate secrets regularly (especially production API keys)
- Use environment-specific secrets (dev vs prod)
- Add `.env` to `.gitignore`
- Use `chmod 600 .env` to restrict file permissions

### DON'T:
- Never commit secrets to git
- Never hardcode secrets in application code
- Never use production secrets in development
- Never share secrets via email, Slack, or other insecure channels
- Never log secret values (even partially)
- Never use `lightwave-email-service` profile for non-email operations
- Never store secrets in plaintext files on your machine (except .env during development)

---

## Quick Reference Commands

```bash
# Set AWS profile (ALWAYS RUN THIS FIRST)
export AWS_PROFILE=lightwave-admin-new

# Verify profile
echo $AWS_PROFILE
aws sts get-caller-identity

# List all secrets (Secrets Manager)
aws secretsmanager list-secrets --query 'SecretList[*].Name' --output table

# List all parameters (Parameter Store)
aws ssm get-parameters-by-path --path /lightwave/ --recursive --query 'Parameters[*].Name' --output table

# Get secret (Secrets Manager)
aws secretsmanager get-secret-value --secret-id /lightwave/dev/django/secret-key --query SecretString --output text

# Get parameter (Parameter Store)
aws ssm get-parameter --name /lightwave/prod/ANTHROPIC_API_KEY --with-decryption --query Parameter.Value --output text

# Load secret into environment variable
export SECRET_VAR=$(aws secretsmanager get-secret-value --secret-id /path/to/secret --query SecretString --output text)

# Load parameter into environment variable
export PARAM_VAR=$(aws ssm get-parameter --name /path/to/param --with-decryption --query Parameter.Value --output text)
```

---

## Additional Resources

- **Secrets Loader Skill**: `.claude/skills/secrets-loader.md` - Step-by-step guide for loading secrets
- **AWS Secrets Manager Docs**: https://docs.aws.amazon.com/secretsmanager/
- **AWS Parameter Store Docs**: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html
- **Workspace SOP**: `.claude/CLAUDE.md` - Workspace-level procedures

---

**Remember**: Secrets are the keys to your kingdom. Handle them with care.
