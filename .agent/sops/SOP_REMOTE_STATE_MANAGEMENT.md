# SOP: Remote State Management, Verification, and Recovery

**Version:** 1.0.0
**Last Updated:** 2025-10-28
**Owner:** Platform Team
**Purpose:** Ensure Terragrunt remote state (S3 + DynamoDB) is healthy and provide step-by-step procedures for verifying state integrity, troubleshooting lock issues, and recovering from state corruption. Prevents hours of debugging common state-related issues.

---

## Prerequisites

- AWS CLI configured with `AWS_PROFILE=lightwave-admin-new`
- Terragrunt installed (version from mise.toml)
- OpenTofu/Terraform installed
- Read access to S3 bucket: `lightwave-terraform-state-*`
- Read/write access to DynamoDB table: `lightwave-terraform-locks`

---

## Pre-Flight State Verification

### Verify S3 Bucket Access

1. Set AWS profile:
   ```bash
   export AWS_PROFILE=lightwave-admin-new
   ```

2. List state buckets:
   ```bash
   aws s3 ls | grep terraform-state
   ```

3. Test read access:
   ```bash
   aws s3 ls s3://lightwave-terraform-state-non-prod-us-east-1/
   ```

4. **Expected:** List of .tfstate files returned

5. **If error:** Verify IAM permissions for S3 GetObject/ListBucket actions

### Verify DynamoDB Lock Table

1. Check table exists:
   ```bash
   aws dynamodb describe-table --table-name lightwave-terraform-locks
   ```

2. **Expected:** Table status = ACTIVE

3. List current locks:
   ```bash
   aws dynamodb scan --table-name lightwave-terraform-locks
   ```

4. **Expected:** Empty or minimal items (only active operations)

5. **If stale locks present:** See "Resolving State Lock Issues" below

### Test State Access in Terragrunt

1. Navigate to infrastructure directory:
   ```bash
   cd Infrastructure/lightwave-infrastructure-live/non-prod/us-east-1
   ```

2. Run initialization:
   ```bash
   terragrunt run-all init --terragrunt-non-interactive
   ```

3. **Expected:** All modules initialize successfully

4. **If error:** Check backend configuration in `root.hcl` (lines 44-58)

---

## Resolving State Lock Issues

### Understanding State Locks

DynamoDB locks prevent concurrent Terraform operations. Lock format:
- **LockID:** `{bucket}/{key}-md5`
- **Info:** Contains who acquired lock and when
- **Automatic release:** When operation completes
- **Stale locks:** When operation fails/crashes without cleanup

### Identifying Stale Locks

1. List all locks:
   ```bash
   aws dynamodb scan --table-name lightwave-terraform-locks --output table
   ```

2. Check lock age: Look at `Info` field for timestamp

3. **Identify stale:** Locks older than 30 minutes with no active process

4. Verify no one is running terragrunt: Ask team in Slack

### Force Unlock (CAUTION)

1. Get LockID from error message or DynamoDB scan

2. Run force unlock:
   ```bash
   terragrunt force-unlock <LOCK_ID>
   ```

3. Confirm: Type `yes` when prompted

4. Verify: Lock removed from DynamoDB

5. Re-run original command

**⚠️ WARNINGS:**
- NEVER force-unlock if someone is actively running terragrunt
- ALWAYS verify with team before force-unlock in production
- Document who/why you force-unlocked in incident log

---

## State File Backup and Recovery

### Manual State Backup

1. Navigate to module:
   ```bash
   cd /path/to/module
   ```

2. Pull current state:
   ```bash
   terragrunt state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate
   ```

3. Store backup securely:
   ```bash
   aws s3 cp backup-*.tfstate s3://lightwave-terraform-state-backups/
   ```

4. Verify backup:
   ```bash
   aws s3 ls s3://lightwave-terraform-state-backups/
   ```

### Restoring from Backup

1. Download backup:
   ```bash
   aws s3 cp s3://lightwave-terraform-state-backups/backup-{timestamp}.tfstate .
   ```

2. Push to remote:
   ```bash
   terragrunt state push backup-{timestamp}.tfstate
   ```

3. Verify restoration:
   ```bash
   terragrunt plan
   ```
   Should show no changes if backup is current

4. Test resources: Verify critical resources are accessible

**⚠️ WARNINGS:**
- Restoring state does NOT restore actual infrastructure
- Use this to recover from state corruption, not resource deletion
- Always run `terragrunt plan` after restore to verify consistency

### S3 Versioning for State Files

1. Verify versioning enabled:
   ```bash
   aws s3api get-bucket-versioning --bucket lightwave-terraform-state-non-prod-us-east-1
   ```

2. **Expected:** Status: Enabled

3. List versions:
   ```bash
   aws s3api list-object-versions --bucket {bucket} --prefix {key}
   ```

4. Restore previous version:
   ```bash
   aws s3api copy-object --copy-source {bucket}/{key}?versionId={id} --bucket {bucket} --key {key}
   ```

---

## Troubleshooting Common Issues

### Error: Failed to get existing workspaces

**Cause:** S3 bucket permissions or backend configuration incorrect

**Solution:**
1. Verify AWS_PROFILE is set correctly
2. Check `root.hcl` remote_state block (lines 44-58)
3. Verify IAM permissions for S3 bucket
4. Test: `aws s3 ls s3://{bucket}`

### Error: Error acquiring the state lock

**Cause:** Another process holds lock or stale lock exists

**Solution:**
1. Wait 5 minutes and retry (may be active operation)
2. Check for stale lock:
   ```bash
   aws dynamodb scan --table-name lightwave-terraform-locks
   ```
3. If stale, force-unlock (see above section)

### Error: State file corrupt or unreadable

**Cause:** State file damaged, interrupted write, or version mismatch

**Solution:**
1. Check S3 bucket for state file:
   ```bash
   aws s3 ls s3://{bucket}/{key}
   ```

2. Download and inspect:
   ```bash
   aws s3 cp s3://{bucket}/{key} ./inspect.tfstate
   ```

3. Validate JSON:
   ```bash
   jq . inspect.tfstate
   ```

4. If corrupt: Restore from S3 version history (see above)

5. If version mismatch: Update Terragrunt/OpenTofu version

---

## Verification Checklist

Before running `terragrunt apply`, verify:

- [ ] S3 bucket accessible (`aws s3 ls`)
- [ ] DynamoDB table accessible (`aws dynamodb describe-table`)
- [ ] No stale locks present (`aws dynamodb scan`)
- [ ] State backup created (if making risky changes)
- [ ] AWS_PROFILE set correctly
- [ ] Team notified of deployment (if prod)

---

## Rollback Procedures

If deployment fails mid-apply and state is inconsistent:

1. **DO NOT panic or force changes**

2. Run `terragrunt plan` to see current drift

3. If resources partially created: Run `terragrunt apply` again to complete

4. If state corrupt: Restore from backup (see above)

5. If lock stuck: Wait 30 min, then force-unlock if safe

6. Document incident in Slack for team awareness

---

## Automation Scripts

### scripts/verify-remote-state.sh

```bash
#!/bin/bash
# Verifies remote state is healthy before deployment
set -e

AWS_PROFILE=${AWS_PROFILE:-lightwave-admin-new}
ENVIRONMENT=${1:-non-prod}
REGION=${2:-us-east-1}
BUCKET="lightwave-terraform-state-${ENVIRONMENT}-${REGION}"
TABLE="lightwave-terraform-locks"

echo "Verifying remote state for ${ENVIRONMENT}/${REGION}..."

# Check S3 bucket
if aws s3 ls "s3://${BUCKET}" > /dev/null 2>&1; then
    echo "✅ S3 bucket accessible: ${BUCKET}"
else
    echo "❌ S3 bucket NOT accessible: ${BUCKET}"
    exit 1
fi

# Check DynamoDB table
if aws dynamodb describe-table --table-name "${TABLE}" > /dev/null 2>&1; then
    echo "✅ DynamoDB lock table accessible: ${TABLE}"
else
    echo "❌ DynamoDB lock table NOT accessible: ${TABLE}"
    exit 1
fi

# Check for stale locks
LOCK_COUNT=$(aws dynamodb scan --table-name "${TABLE}" --select COUNT --output text | awk '{print $2}')
if [ "${LOCK_COUNT}" -gt 0 ]; then
    echo "⚠️  Warning: ${LOCK_COUNT} active locks found"
    echo "Run: aws dynamodb scan --table-name ${TABLE} --output table"
else
    echo "✅ No active locks"
fi

echo "✅ Remote state verification complete"
```

---

## Related Documents

- Infrastructure Deployment: `SOP_INFRASTRUCTURE_DEPLOYMENT.md`
- Disaster Recovery: `SOP_DISASTER_RECOVERY.md`
- Root Terragrunt Configuration: `Infrastructure/lightwave-infrastructure-live/root.hcl:44-58`

---

**Revision History:**
- 2025-10-28: Initial version (1.0.0)
