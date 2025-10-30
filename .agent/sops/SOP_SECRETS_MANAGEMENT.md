# SOP: Secrets Management with AWS Secrets Manager

**Version:** 1.0.0
**Last Updated:** 2025-10-28
**Owner:** Platform Team / Security Team
**Purpose:** Define the complete lifecycle for managing sensitive configuration values (database passwords, API keys, JWT secrets) using AWS Secrets Manager. Ensures secrets are never stored in plaintext in code or state files, and provides clear procedures for creation, rotation, and emergency response.

---

## Prerequisites

- AWS CLI configured with `AWS_PROFILE=lightwave-admin-new`
- IAM permissions for `secretsmanager:*` actions
- Understanding of secret naming conventions (see `naming_conventions.yaml`)

---

## Secret Naming Convention

### Pattern

```
/{environment}/{service}/{secret_type}
```

### Examples

- `/prod/backend/database_password`
- `/prod/backend/jwt_secret_key`
- `/non-prod/redis/auth_token`
- `/prod/cloudflare/api_token`
- `/non-prod/backend/stripe_api_key`

### Rules

- Use **snake_case** for secret names
- Always include **environment prefix** (`/prod/`, `/non-prod/`)
- Never include actual secret values in name
- Use descriptive secret types (`database_password`, not `db_pw`)

---

## Creating Secrets

### Method 1: Manual Secret Creation (Development)

Use for quick development/testing secrets:

1. Generate strong secret:
   ```bash
   openssl rand -base64 32
   ```

2. Create in AWS Secrets Manager:
   ```bash
   aws secretsmanager create-secret \
     --name /non-prod/backend/database_password \
     --secret-string 'your-generated-password-here'
   ```

3. Add description:
   ```bash
   aws secretsmanager update-secret \
     --secret-id /non-prod/backend/database_password \
     --description 'PostgreSQL password for non-prod backend'
   ```

4. Tag secret:
   ```bash
   aws secretsmanager tag-resource \
     --secret-id /non-prod/backend/database_password \
     --tags Key=Environment,Value=non-prod Key=ManagedBy,Value=Manual
   ```

5. Verify creation:
   ```bash
   aws secretsmanager describe-secret \
     --secret-id /non-prod/backend/database_password
   ```

### Method 2: Terraform-Managed Secrets (Production)

Use for production secrets managed as infrastructure:

1. Create Terraform module in `lightwave-infrastructure-catalog/units/secret/`:

```hcl
# main.tf
resource "random_password" "this" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "this" {
  name        = var.secret_name
  description = var.description

  tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = random_password.this.result
}
```

```hcl
# outputs.tf
output "secret_arn" {
  description = "ARN of the secret"
  value       = aws_secretsmanager_secret.this.arn
  sensitive   = true
}

output "secret_name" {
  description = "Name of the secret"
  value       = aws_secretsmanager_secret.this.name
}
```

2. Use in Terragrunt:

```hcl
# terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/lightwave-infrastructure-catalog//units/secret"
}

inputs = {
  secret_name = "/prod/backend/database_password"
  description = "PostgreSQL master password for production"
  tags = {
    Environment = "prod"
    Service     = "backend"
    SecretType  = "database_password"
  }
}
```

### Method 3: Secret Rotation Configuration

For secrets that require automatic rotation:

1. Create rotation Lambda function (use AWS SAR template):
   ```bash
   aws serverlessrepo create-cloud-formation-change-set \
     --application-id arn:aws:serverlessrepo:us-east-1:297356227924:applications/SecretsManagerRDSPostgreSQLRotationSingleUser \
     --stack-name rotation-lambda
   ```

2. Enable rotation:
   ```bash
   aws secretsmanager rotate-secret \
     --secret-id /prod/backend/database_password \
     --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789012:function:rotation-lambda \
     --rotation-rules AutomaticallyAfterDays=30
   ```

3. Test rotation:
   ```bash
   aws secretsmanager rotate-secret \
     --secret-id /prod/backend/database_password
   ```

4. Verify application continues working with new secret

---

## Referencing Secrets in Infrastructure

### In Terragrunt Configuration

```hcl
# In terragrunt.hcl
dependency "secrets" {
  config_path = "../secrets"
}

inputs = {
  database_password_arn = dependency.secrets.outputs.db_password_arn
}
```

### In Terraform Module

```hcl
# variables.tf
variable "database_password_arn" {
  description = "ARN of database password in Secrets Manager"
  type        = string
  sensitive   = true
}

# main.tf
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.database_password_arn
}

resource "aws_db_instance" "this" {
  identifier = "prod-postgres"
  engine     = "postgres"

  # Reference secret value
  master_password = data.aws_secretsmanager_secret_version.db_password.secret_string

  # Other configuration...
}
```

### In Application Code (Django Backend)

```python
# backend/core/settings.py
import boto3
import json
from functools import lru_cache

@lru_cache(maxsize=128)
def get_secret(secret_name: str, region_name: str = 'us-east-1') -> dict:
    """Retrieve secret from AWS Secrets Manager with caching."""
    client = boto3.client('secretsmanager', region_name=region_name)

    try:
        response = client.get_secret_value(SecretId=secret_name)
        return json.loads(response['SecretString'])
    except Exception as e:
        logger.error(f"Failed to retrieve secret {secret_name}: {e}")
        raise

# Database configuration
db_password = get_secret('/prod/backend/database_password')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'lightwave',
        'USER': 'admin',
        'PASSWORD': db_password,
        'HOST': os.environ.get('DB_HOST'),
        'PORT': '5432',
    }
}

# JWT secret
jwt_secret = get_secret('/prod/backend/jwt_secret_key')
SECRET_KEY = jwt_secret
```

### In Application Code (Next.js Frontend)

```typescript
// lib/secrets.ts
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";

const client = new SecretsManagerClient({ region: "us-east-1" });

export async function getSecret(secretName: string): Promise<string> {
  try {
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await client.send(command);

    if (response.SecretString) {
      return JSON.parse(response.SecretString);
    }
    throw new Error("Secret not found");
  } catch (error) {
    console.error(`Failed to retrieve secret ${secretName}:`, error);
    throw error;
  }
}

// Usage in API route
export async function GET() {
  const apiKey = await getSecret('/prod/frontend/stripe_publishable_key');
  // Use apiKey...
}
```

---

## Secret Rotation Procedures

### Automated Rotation (Recommended for Production)

**Best for:** Database passwords, API keys with rotation support

1. Configure rotation Lambda (AWS provides templates for RDS, Redshift, etc.)

2. Enable rotation:
   ```bash
   aws secretsmanager rotate-secret \
     --secret-id /prod/backend/database_password \
     --rotation-lambda-arn <lambda-arn> \
     --rotation-rules AutomaticallyAfterDays=30
   ```

3. Test rotation in non-prod first

4. Monitor application logs during rotation window

5. Verify no connection errors

**Rotation Schedule:**
- **Production databases:** Every 30 days
- **API keys:** Every 90 days (if supported by provider)
- **Service accounts:** Every 60 days

### Manual Rotation (Emergency or Unsupported Services)

**Use when:** Secret compromised or service doesn't support auto-rotation

1. Generate new secret value:
   ```bash
   NEW_SECRET=$(openssl rand -base64 32)
   echo $NEW_SECRET  # Save this temporarily
   ```

2. Create new version in Secrets Manager:
   ```bash
   aws secretsmanager update-secret \
     --secret-id /prod/backend/jwt_secret \
     --secret-string "$NEW_SECRET"
   ```

3. Update application to use new version:
   - **ECS:** Force new deployment (tasks will fetch new secret)
     ```bash
     aws ecs update-service \
       --cluster lightwave-prod \
       --service backend-prod \
       --force-new-deployment
     ```

   - **Lambda:** Update environment variable or redeploy function

4. Wait for all instances to update:
   ```bash
   # Check ECS task deployment status
   aws ecs describe-services \
     --cluster lightwave-prod \
     --services backend-prod
   ```

5. Verify application functionality:
   ```bash
   curl https://api.lightwave-media.ltd/health
   ```

6. Delete old versions (optional, after 24-hour grace period):
   ```bash
   aws secretsmanager list-secret-version-ids \
     --secret-id /prod/backend/jwt_secret

   # Delete specific old version if needed
   aws secretsmanager delete-secret-version \
     --secret-id /prod/backend/jwt_secret \
     --version-id <old-version-id>
   ```

---

## Emergency Secret Rotation (Compromise)

**Use when:** Secret has been leaked, credentials compromised, or security incident

### Immediate Actions (< 5 minutes)

**Goal:** Stop the bleeding immediately

1. Identify compromised secret:
   - Example: Database password found in GitHub commit

2. Generate new secret immediately:
   ```bash
   NEW_SECRET=$(openssl rand -base64 32)
   ```

3. Update Secrets Manager:
   ```bash
   aws secretsmanager update-secret \
     --secret-id /prod/backend/database_password \
     --secret-string "$NEW_SECRET"
   ```

4. If database password, update RDS immediately:
   ```bash
   aws rds modify-db-instance \
     --db-instance-identifier prod-postgres \
     --master-user-password "$NEW_SECRET" \
     --apply-immediately
   ```

5. Notify team in **#security-incidents** channel:
   ```
   🚨 SECURITY INCIDENT
   - Secret compromised: /prod/backend/database_password
   - Action taken: Rotated immediately
   - Next: Forcing application redeployment
   - Incident lead: @yourname
   ```

### Application Update (< 15 minutes)

**Goal:** Get applications using new secret

1. For ECS services:
   ```bash
   aws ecs update-service \
     --cluster lightwave-prod \
     --service backend-prod \
     --force-new-deployment
   ```

2. For Lambda functions:
   ```bash
   aws lambda update-function-configuration \
     --function-name backend-api \
     --environment Variables={SECRET_UPDATED=true}
   ```

3. Monitor application logs for connection errors:
   ```bash
   aws logs tail /aws/ecs/lightwave-prod/backend --follow
   ```

4. Verify health endpoints:
   ```bash
   curl https://api.lightwave-media.ltd/health
   # Expected: {"status": "healthy"}
   ```

### Post-Incident Actions (< 1 hour)

**Goal:** Understand what happened and prevent recurrence

1. Review access logs for secret retrieval:
   ```bash
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=ResourceName,AttributeValue=/prod/backend/database_password \
     --max-results 50
   ```

2. Investigate how secret was compromised:
   - Check git history for leaked credentials
   - Review IAM policies for overly permissive access
   - Check application logs for unauthorized access

3. Update IAM policies to restrict access if needed:
   ```json
   {
     "Effect": "Allow",
     "Action": "secretsmanager:GetSecretValue",
     "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:/prod/backend/*",
     "Condition": {
       "StringEquals": {
         "aws:PrincipalTag/Environment": "prod"
       }
     }
   }
   ```

4. Document incident in security log:
   - Create file: `.claude/incidents/incident-YYYY-MM-DD.md`
   - Include timeline, root cause, remediation steps

5. Create task to prevent recurrence:
   - Example: Add pre-commit hook for secret scanning
   - Example: Implement secret rotation automation

---

## Local Development Access

Developers need access to secrets for local development. **Never hardcode secrets in `.env` files committed to Git.**

### Option 1: AWS CLI (Quick)

```bash
export AWS_PROFILE=lightwave-admin-new
aws secretsmanager get-secret-value \
  --secret-id /non-prod/backend/database_password \
  --query SecretString \
  --output text
```

### Option 2: Environment Variable Script (Convenient)

Create `scripts/load-dev-secrets.sh`:

```bash
#!/bin/bash
# Load development secrets into environment
set -e

export AWS_PROFILE=lightwave-admin-new

echo "Loading development secrets..."

export DATABASE_PASSWORD=$(aws secretsmanager get-secret-value --secret-id /non-prod/backend/database_password --query SecretString --output text)
export JWT_SECRET=$(aws secretsmanager get-secret-value --secret-id /non-prod/backend/jwt_secret --query SecretString --output text)
export REDIS_AUTH_TOKEN=$(aws secretsmanager get-secret-value --secret-id /non-prod/redis/auth_token --query SecretString --output text)

echo "✅ Secrets loaded into environment"
```

Usage:
```bash
source scripts/load-dev-secrets.sh
python manage.py runserver
```

### Option 3: Chamber (Secrets Manager CLI Tool)

Install Chamber:
```bash
brew install chamber
```

Usage:
```bash
chamber exec /non-prod/backend -- python manage.py runserver
```

Chamber automatically loads all secrets with prefix `/non-prod/backend/` into environment.

---

## Troubleshooting

### Issue: "AccessDeniedException when retrieving secret"

**Cause:** IAM permissions insufficient

**Solution:**
1. Verify IAM permissions include `secretsmanager:GetSecretValue`:
   ```bash
   aws iam get-user-policy --user-name your-user --policy-name SecretAccess
   ```

2. Check resource-based policy on secret:
   ```bash
   aws secretsmanager get-resource-policy --secret-id /prod/backend/database_password
   ```

3. Verify AWS_PROFILE is set:
   ```bash
   echo $AWS_PROFILE
   # Should output: lightwave-admin-new
   ```

### Issue: "Secret not found"

**Cause:** Secret name incorrect or doesn't exist in region

**Solution:**
1. Verify secret name matches convention (check for typos)

2. Check region (secrets are region-specific):
   ```bash
   aws secretsmanager list-secrets --region us-east-1
   ```

3. List all secrets to find correct name:
   ```bash
   aws secretsmanager list-secrets \
     --query 'SecretList[].Name' \
     --output table
   ```

### Issue: "Invalid secret value format"

**Cause:** Secrets Manager stores strings, not always JSON

**Solution:**

Secrets Manager supports two formats:

**1. Plain string:**
```bash
aws secretsmanager create-secret \
  --name /non-prod/backend/api_key \
  --secret-string 'sk_test_abc123'
```

Retrieve:
```python
secret = get_secret('/non-prod/backend/api_key')  # Returns: "sk_test_abc123"
```

**2. JSON object:**
```bash
aws secretsmanager create-secret \
  --name /non-prod/backend/database \
  --secret-string '{"username":"admin","password":"secret123"}'
```

Retrieve:
```python
secret = get_secret('/non-prod/backend/database')
db_creds = json.loads(secret)  # Returns: {"username": "admin", "password": "secret123"}
```

---

## Best Practices

### 1. Never Store Secrets in Code

❌ **Bad:**
```python
# settings.py
SECRET_KEY = 'django-insecure-hardcoded-secret'
```

✅ **Good:**
```python
# settings.py
SECRET_KEY = get_secret('/prod/backend/jwt_secret')
```

### 2. Use Least Privilege IAM Policies

Only grant access to specific secrets needed:

```json
{
  "Effect": "Allow",
  "Action": "secretsmanager:GetSecretValue",
  "Resource": [
    "arn:aws:secretsmanager:us-east-1:*:secret:/prod/backend/database_password",
    "arn:aws:secretsmanager:us-east-1:*:secret:/prod/backend/jwt_secret"
  ]
}
```

### 3. Rotate Secrets Regularly

- Production databases: Every 30 days
- API keys: Every 90 days
- Service accounts: Every 60 days

### 4. Monitor Secret Access

Enable CloudTrail logging for all `secretsmanager:GetSecretValue` calls:

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetSecretValue
```

### 5. Tag All Secrets Consistently

Required tags:
- `Environment`: prod/non-prod
- `ManagedBy`: Terraform/Manual
- `Service`: backend/frontend/redis
- `SecretType`: database_password/api_key/etc

---

## Related Documents

- Infrastructure Deployment: `SOP_INFRASTRUCTURE_DEPLOYMENT.md`
- Naming Conventions: `.agent/metadata/naming_conventions.yaml`
- Emergency Procedures: `SOP_EMERGENCY_SECRET_ROTATION.md`

---

**Revision History:**
- 2025-10-28: Initial version (1.0.0)
