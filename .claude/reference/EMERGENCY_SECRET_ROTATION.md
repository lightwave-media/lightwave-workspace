# Emergency Secret Rotation Runbook

**Version:** 1.0.0
**Last Updated:** 2025-10-28
**Owner:** Platform Team / Security Team
**Purpose:** Step-by-step procedure for emergency secret rotation when credentials are compromised

---

## When to Use This Runbook

Execute emergency rotation when:
- Secret found in Git commit history
- Secret exposed in logs or error messages
- Unauthorized access detected to secret
- Suspected credential compromise
- Security incident involving credentials
- Third-party breach affecting shared credentials

**Severity Level:** CRITICAL - Execute immediately upon discovery

---

## Prerequisites

- AWS CLI configured with `AWS_PROFILE=lightwave-admin-new`
- Access to AWS Secrets Manager (IAM permission: `secretsmanager:*`)
- Access to affected services (ECS, RDS, Lambda, etc.)
- Incident response channel access (#security-incidents)
- On-call engineer availability

---

## Phase 1: Immediate Response (0-5 minutes)

**Goal:** Stop active compromise immediately

### Step 1: Notify Team

```bash
# Post to #security-incidents Slack channel
🚨 SECURITY INCIDENT - Secret Compromise
Secret: [secret-name]
Discovered: [timestamp]
Incident Lead: @[your-name]
Status: ROTATING NOW
```

### Step 2: Identify Compromised Secret

```bash
# Verify secret exists and get metadata
export SECRET_NAME="[compromised-secret-name]"  # e.g., /prod/backend/database_password
export AWS_REGION="us-east-1"

aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION"
```

**Document:**
- Secret name: ______________________
- Last changed: _____________________
- Services affected: _________________

### Step 3: Generate New Secret Value

```bash
# Generate cryptographically secure password
NEW_SECRET=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-32)
echo "New secret generated (DO NOT LOG THIS VALUE)"
```

**CRITICAL:** Never log, commit, or share the new secret value in plaintext

### Step 4: Rotate Secret in AWS Secrets Manager

```bash
# Update secret with new value
aws secretsmanager update-secret \
  --secret-id "$SECRET_NAME" \
  --secret-string "$NEW_SECRET" \
  --region "$AWS_REGION"

# Verify rotation
aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" | jq '.LastChangedDate'
```

**Checkpoint:** New secret version created in Secrets Manager ✓

---

## Phase 2: Update Target Resources (5-15 minutes)

**Goal:** Update services and databases with new secret

### Database Passwords (RDS/Aurora)

```bash
# For RDS database password
DB_INSTANCE_ID="prod-backend-db"  # Change to your DB identifier

# Update RDS master password
aws rds modify-db-instance \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --master-user-password "$NEW_SECRET" \
  --apply-immediately \
  --region "$AWS_REGION"

# Monitor status
aws rds describe-db-instances \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --region "$AWS_REGION" | jq '.DBInstances[0].DBInstanceStatus'
```

**Wait for:** Status changes to "available" (may take 2-5 minutes)

### Application Secrets (JWT, API Keys)

For non-database secrets, skip to Phase 3 (no target resource update needed).

---

## Phase 3: Restart Services (5-20 minutes)

**Goal:** Force services to fetch new secret from Secrets Manager

### ECS Fargate Services

```bash
# Parse environment and service from secret name
# Pattern: /{environment}/{service}/{secret_type}
if [[ "$SECRET_NAME" =~ ^/([^/]+)/([^/]+)/([^/]+)$ ]]; then
  ENVIRONMENT="${BASH_REMATCH[1]}"
  SERVICE="${BASH_REMATCH[2]}"

  CLUSTER_NAME="lightwave-${ENVIRONMENT}"
  SERVICE_NAME="${SERVICE}-${ENVIRONMENT}"

  echo "Detected:"
  echo "  Environment: $ENVIRONMENT"
  echo "  Service: $SERVICE"
  echo "  Cluster: $CLUSTER_NAME"
  echo "  Service Name: $SERVICE_NAME"
else
  echo "⚠️  Could not parse secret name. Manually identify cluster and service."
  exit 1
fi

# Force new deployment
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --force-new-deployment \
  --region "$AWS_REGION"

# Monitor deployment
echo "Monitoring ECS deployment (press Ctrl+C when stable)..."
watch -n 5 "aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $AWS_REGION | jq '.services[0] | {runningCount, desiredCount, deployments: .deployments | length}'"
```

**Wait for:**
- New tasks launched
- Old tasks drained
- Running count = Desired count
- Only 1 deployment (primary)

### Lambda Functions

```bash
# If secret is used by Lambda
FUNCTION_NAME="backend-api"  # Change to your function name

# Trigger redeployment by updating environment variable
aws lambda update-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --environment Variables={SECRET_ROTATED_AT=$(date +%s)} \
  --region "$AWS_REGION"

# Verify update
aws lambda get-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --region "$AWS_REGION" | jq '.LastModified'
```

---

## Phase 4: Verification (15-25 minutes)

**Goal:** Confirm services are healthy with new secret

### Health Check Verification

```bash
# For backend service
curl -f https://api.lightwave-media.ltd/health || echo "❌ Health check FAILED"

# Expected response: {"status":"healthy"}
```

### Database Connection Test

```bash
# Test database connectivity
psql -h "$DB_ENDPOINT" -U admin -d lightwave_prod -c "SELECT 1;"
# Enter new password when prompted
```

### Application Logs Review

```bash
# Check ECS logs for errors
aws logs tail /aws/ecs/$CLUSTER_NAME/$SERVICE_NAME --follow --since 5m | grep -i "error\|fail\|auth"
```

**Red Flags:**
- Authentication errors
- Connection refused
- Invalid credentials
- 5xx errors

**If issues found:** Proceed to Rollback section

---

## Phase 5: Audit & Cleanup (25-60 minutes)

**Goal:** Investigate compromise and prevent recurrence

### Review Secret Access Logs

```bash
# Check who accessed the compromised secret in last 7 days
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue="$SECRET_NAME" \
  --max-results 100 \
  --region "$AWS_REGION" | jq '.Events[] | {time: .EventTime, user: .Username, ip: .SourceIPAddress}'
```

**Analyze:**
- Unusual IP addresses
- Unexpected users/roles
- Access patterns outside normal hours

### Identify Compromise Source

Common sources:
1. **Git commit:** Search repository history
   ```bash
   git log -S "compromised-value" --all
   ```

2. **Application logs:** Check CloudWatch Logs for secret exposure

3. **CI/CD logs:** Review GitHub Actions, GitLab CI logs

4. **Developer machines:** Check local environment files

### Revoke Old Secret Versions

```bash
# List all versions
aws secretsmanager list-secret-version-ids \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION"

# Delete old compromised versions (after 24h grace period)
OLD_VERSION_ID="xxxxx"  # Get from above command

aws secretsmanager delete-secret-version \
  --secret-id "$SECRET_NAME" \
  --version-id "$OLD_VERSION_ID" \
  --region "$AWS_REGION"
```

### Remove Exposed Secrets from Git (if applicable)

```bash
# If secret was committed to Git
# Option 1: Rewrite history (destructive - coordinate with team)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch [file-with-secret]" \
  --prune-empty --tag-name-filter cat -- --all

# Option 2: Use BFG Repo-Cleaner (recommended)
bfg --replace-text passwords.txt  # List of secrets to remove

# Force push (after team coordination)
git push origin --force --all
git push origin --force --tags
```

**IMPORTANT:** All team members must re-clone repository after history rewrite

---

## Rollback Procedure

**Use when:** New secret causes service failures

### Step 1: Identify Previous Version

```bash
# List versions
aws secretsmanager list-secret-version-ids \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" | jq '.Versions'

# Find version with stage "AWSPREVIOUS"
PREVIOUS_VERSION=$(aws secretsmanager list-secret-version-ids \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" | jq -r '.Versions[] | select(.VersionStages[]? == "AWSPREVIOUS") | .VersionId')

echo "Previous version: $PREVIOUS_VERSION"
```

### Step 2: Restore Previous Version

```bash
# Move AWSCURRENT stage to previous version
aws secretsmanager update-secret-version-stage \
  --secret-id "$SECRET_NAME" \
  --version-stage AWSCURRENT \
  --move-to-version-id "$PREVIOUS_VERSION" \
  --region "$AWS_REGION"
```

### Step 3: Restart Services Again

Repeat Phase 3 to force services to fetch restored secret.

**CRITICAL:** Rollback only buys time. Previous secret is still compromised. Generate new secret and retry rotation.

---

## Post-Incident Actions

### Incident Report

Create incident report: `.claude/incidents/incident-$(date +%Y-%m-%d).md`

**Include:**
1. Timeline of events
2. Root cause analysis
3. Services affected
4. Downtime duration
5. Remediation steps taken
6. Preventive measures

### Preventive Measures

- [ ] Add secret scanning to pre-commit hooks (already configured)
- [ ] Enable automatic rotation for this secret
- [ ] Review IAM policies for least privilege
- [ ] Implement secret scanning in CI/CD
- [ ] Train team on secret handling
- [ ] Enable AWS GuardDuty for anomaly detection

### Team Communication

```bash
# Post final status to #security-incidents
✅ INCIDENT RESOLVED - Secret Rotation Complete
Secret: [secret-name]
Duration: [X minutes]
Services: All healthy
Action Items: [link to incident report]
```

---

## Quick Reference Commands

```bash
# List all secrets
/scripts/list-secrets.sh --filter prod

# Rotate secret (dry-run)
/scripts/rotate-secret.sh $SECRET_NAME --generate --dry-run

# Rotate secret (actual)
/scripts/rotate-secret.sh $SECRET_NAME --generate --force-deployment

# Validate secret references
/scripts/validate-secret-references.sh . --strict

# Check ECS service status
aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $AWS_REGION

# View CloudTrail events
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=$SECRET_NAME
```

---

## Escalation

**If unable to complete rotation within 30 minutes:**

1. Escalate to Platform Team Lead
2. Consider:
   - Temporarily disabling affected service
   - Enabling maintenance mode
   - Failing over to secondary region (if configured)

**Emergency Contacts:**
- Platform Team Lead: [contact]
- Security Team: [contact]
- On-call Engineer: PagerDuty

---

## Related Documentation

- [SOP: Secrets Management](/.agent/sops/SOP_SECRETS_MANAGEMENT.md)
- [Helper Scripts](/Infrastructure/lightwave-infrastructure-live/scripts/)
- [Secret Module Documentation](/Infrastructure/lightwave-infrastructure-catalog/units/secret/README.md)

---

**Revision History:**
- 2025-10-28: Initial version (1.0.0) - Infrastructure Ops Auditor
