# SOP: Safe Infrastructure Deployment Procedures

**Version:** 1.0.0
**Last Updated:** 2025-10-28
**Owner:** Platform Team
**Purpose:** Provide battle-tested deployment procedures for infrastructure changes, minimizing risk of outages and ensuring consistent deployment practices across team. Follows Gruntwork best practices for production infrastructure changes.

---

## Prerequisites

- AWS CLI configured with `AWS_PROFILE=lightwave-admin-new`
- Terragrunt/OpenTofu installed (`mise install`)
- Pre-commit hooks installed (`make install-hooks`)
- Remote state verified (run `scripts/verify-remote-state.sh`)
- Slack notification sent to #infrastructure channel

---

## Non-Production Deployment (dev/staging)

### Step 1: Prepare Changes

1. Create feature branch:
   ```bash
   git checkout -b feature/infra/TASK-123-description
   ```

2. Make infrastructure changes in appropriate modules

3. Run pre-commit:
   ```bash
   pre-commit run --all-files
   ```

4. Fix any linting/formatting issues

### Step 2: Local Validation

1. Navigate to environment:
   ```bash
   cd Infrastructure/lightwave-infrastructure-live/non-prod/us-east-1
   ```

2. Initialize:
   ```bash
   terragrunt run-all init
   ```

3. Validate:
   ```bash
   terragrunt run-all validate
   ```

4. Plan:
   ```bash
   terragrunt run-all plan --terragrunt-non-interactive
   ```

5. Review plan output carefully:
   - Look for **destroys** (red `-`)
   - Look for **replacements** (yellow `~`)
   - Verify expected changes only

6. If plan looks good: Save plan output for PR description

### Step 3: Create Pull Request

1. Commit changes:
   ```bash
   git commit -m "feat(infra): add RDS read replica for performance"
   ```

2. Push branch:
   ```bash
   git push origin feature/infra/TASK-123-description
   ```

3. Create PR on GitHub

4. Add plan output to PR description (in code block):
   ````markdown
   ## Terragrunt Plan Output
   ```
   [paste plan output here]
   ```
   ````

5. Request review from infrastructure team

### Step 4: Deploy After Approval

1. Merge PR to main

2. Navigate to environment:
   ```bash
   cd Infrastructure/lightwave-infrastructure-live/non-prod/us-east-1
   ```

3. Pull latest:
   ```bash
   git pull origin main
   ```

4. Run deployment:
   ```bash
   make apply-nonprod
   ```

5. Confirm when prompted: `y`

6. Monitor output for errors

7. Verify resources in AWS console

### Step 5: Post-Deployment Verification

1. Check application health:
   ```bash
   curl https://api-staging.lightwave-media.ltd/health
   ```

2. Check ECS service status:
   ```bash
   aws ecs describe-services --cluster lightwave-staging --services backend-staging
   ```

3. Check RDS status:
   ```bash
   aws rds describe-db-instances --db-instance-identifier staging-postgres
   ```

4. Run smoke tests (if exists):
   ```bash
   make test-nonprod
   ```

5. Document deployment in Slack:
   ```
   ✅ Deployed TASK-123 to staging
   - Added RDS read replica
   - No issues detected
   ```

---

## Production Deployment

### Pre-Deployment Checklist

Before starting production deployment, verify:

- [ ] Changes tested in non-prod environment
- [ ] Smoke tests passed in non-prod
- [ ] No open incidents or outages
- [ ] Team notified in #infrastructure channel
- [ ] Backup of production state created
- [ ] Rollback plan documented
- [ ] Change window scheduled (avoid peak hours)

### Step 1: Create Prod-Specific Branch

1. Create branch:
   ```bash
   git checkout -b release/infra/v1.2.3
   ```

2. Cherry-pick or merge tested changes from non-prod

3. Update version in prod configuration if needed

4. Run plan:
   ```bash
   cd Infrastructure/lightwave-infrastructure-live/prod/us-east-1
   make plan-prod
   ```

5. Review plan with senior engineer

### Step 2: Production Deployment

1. Announce in Slack:
   ```
   🚀 Starting prod deployment at [time]
   - Task: TASK-123
   - Changes: Add RDS read replica
   - ETA: 15 minutes
   ```

2. Backup state:
   ```bash
   scripts/backup-prod-state.sh
   ```

3. Run deployment:
   ```bash
   make apply-prod
   ```

4. **Review plan one final time**

5. Type `y` to confirm

6. Monitor output closely (watch for errors)

7. **Do NOT interrupt unless critical error**

### Step 3: Post-Deployment Verification

1. Verify application:
   ```bash
   curl https://api.lightwave-media.ltd/health
   ```
   Expected: `{"status": "healthy"}`

2. Check error rates: Review CloudWatch dashboard

3. Check service health:
   ```bash
   aws ecs describe-services --cluster lightwave-prod --services backend-prod
   ```

4. Run production smoke tests:
   ```bash
   make test-prod
   ```

5. Monitor for 15 minutes

6. Announce completion in Slack:
   ```
   ✅ Production deployment complete
   - TASK-123 deployed successfully
   - All health checks passing
   - No errors detected
   ```

### Step 4: Rollback (if needed)

1. Determine rollback scope:
   - Infrastructure rollback: Restore Terraform state
   - Application rollback: Revert ECS task definition

2. For infrastructure rollback:
   ```bash
   # Restore state from backup
   cd Infrastructure/lightwave-infrastructure-live/prod/us-east-1
   terragrunt state push backup-[timestamp].tfstate

   # Run apply to revert
   terragrunt apply
   ```

3. For application rollback:
   ```bash
   # Update ECS service to previous task definition
   aws ecs update-service \
     --cluster lightwave-prod \
     --service backend-prod \
     --task-definition backend-prod:42
   ```

4. Monitor application recovery

5. Document incident and cause

---

## Handling Failures During Deployment

### Scenario: Terragrunt Apply Fails Mid-Execution

**What happened:** Terragrunt/OpenTofu encountered error during resource creation

**Response:**
1. **DO NOT force-quit or interrupt**
2. Let Terragrunt finish cleanup (releases lock)
3. Review error message carefully
4. Check AWS console for partially-created resources
5. If safe to retry: Run `terragrunt apply` again
6. If state inconsistent: Run `terragrunt refresh` then `terragrunt plan`
7. If stuck: Restore state from backup and try again

### Scenario: Resource Creation Fails (e.g., RDS timeout)

**What happened:** AWS service timeout or API error

**Response:**
1. Note the failed resource type and name
2. Check AWS console for resource status
3. If resource in `CREATE_IN_PROGRESS`: Wait for AWS to complete or fail
4. If resource failed: Run `terragrunt apply` to retry
5. If resource blocked by service limits: Request limit increase in AWS Support
6. Document failure in incident log

### Scenario: Destroy/Replace of Critical Resource

**What happened:** Terragrunt/OpenTofu wants to destroy and recreate a resource (e.g., database)

**Response:**
1. **STOP immediately if not expected**
2. Review why Terragrunt wants to destroy resource:
   - Resource renamed in code?
   - Parameter marked `ForceNew` changed?
   - Provider version upgrade?
3. If acceptable: Ensure backups exist before proceeding
4. If not acceptable: Adjust configuration to avoid replacement
5. Use `terragrunt taint` to mark specific resources if needed

---

## Troubleshooting

### Common Issue: "Error acquiring state lock"

**Solution:** See `SOP_REMOTE_STATE_MANAGEMENT.md`

### Common Issue: "Invalid provider configuration"

**Cause:** AWS credentials not configured correctly

**Solution:**
1. Check AWS_PROFILE is set:
   ```bash
   echo $AWS_PROFILE
   ```

2. Verify root.hcl provider block

3. Run:
   ```bash
   terragrunt init --reconfigure
   ```

### Common Issue: "No valid credential sources found"

**Cause:** AWS profile not exported

**Solution:**
1. Set profile:
   ```bash
   export AWS_PROFILE=lightwave-admin-new
   ```

2. Verify:
   ```bash
   aws sts get-caller-identity
   ```

### Common Issue: "Resource already exists"

**Cause:** Resource created manually or outside Terraform

**Solution:**

**Option 1:** Import existing resource
```bash
terragrunt import aws_db_instance.main my-database-id
```

**Option 2:** Remove from state if wrong
```bash
terragrunt state rm aws_db_instance.main
```

### Common Issue: "Changes detected but not in plan"

**Cause:** Manual changes in AWS console or drift

**Solution:**
1. Run refresh:
   ```bash
   terragrunt refresh
   ```

2. Check for manual changes in AWS console

3. See `SOP_DRIFT_DETECTION.md` for investigation

---

## Deployment Best Practices

### 1. Always Test in Non-Prod First

Never deploy directly to production without testing in staging/dev first.

### 2. Small, Incremental Changes

Break large changes into smaller deployments:
- ✅ Good: Add read replica, deploy, verify, then enable auto-scaling
- ❌ Bad: Add replica + auto-scaling + new security groups all at once

### 3. Deploy During Low-Traffic Windows

Schedule production deployments during:
- Weekday mornings (avoid Friday afternoons)
- Low-traffic hours (check CloudWatch metrics)
- Avoid holidays and major events

### 4. Monitor Continuously

Watch these metrics during and after deployment:
- Application error rates (CloudWatch)
- Response times (CloudWatch)
- Database connections (RDS metrics)
- ECS task health (ECS console)

### 5. Document Everything

Record in Slack:
- What was deployed
- When it was deployed
- Who deployed it
- Any issues encountered

---

## Related Documents

- Remote State Management: `SOP_REMOTE_STATE_MANAGEMENT.md`
- Disaster Recovery: `SOP_DISASTER_RECOVERY.md`
- Drift Detection: `SOP_DRIFT_DETECTION.md`
- Root Terragrunt: `Infrastructure/lightwave-infrastructure-live/root.hcl`

---

**Revision History:**
- 2025-10-28: Initial version (1.0.0)
