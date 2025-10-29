# SOP: Deployment Health Troubleshooting

**Document ID**: SOP-DEPLOY-HEALTH-001
**Version**: 1.0.0
**Last Updated**: 2025-10-28
**Owner**: DevOps Team
**Status**: Active

---

## Purpose

This SOP defines the standard process for diagnosing and resolving deployment health check failures in the LightWave AWS ECS + ALB infrastructure.

---

## Scope

**Applies to**:
- AWS ECS service deployments (Django backend)
- Application Load Balancer (ALB) health checks
- Target group configuration
- Circuit breaker deployment failures

**Does NOT apply to**:
- Frontend deployments (Cloudflare Pages)
- Database migrations
- DNS/CDN issues

---

## Prerequisites

- AWS CLI installed and configured
- `jq` installed (for JSON parsing)
- AWS credentials with ECS/ELB permissions
- Access to `lightwave-admin-new` AWS profile

---

## Process

### Step 1: Initial Diagnosis (2 minutes)

Run the automated diagnostic script:

```bash
cd /Users/joelschaeffer/dev/lightwave
./scripts/deployment-health-check.sh dev
```

**Review output** for these indicators:

| Status | Indicator | Action Required |
|--------|-----------|-----------------|
| ✅ Healthy | All checks pass | No action needed |
| ⚠️ Warning | Health check path mismatch | Proceed to Step 2 |
| ❌ Error | Target unhealthy or deployment failed | Proceed to Step 2 |

**Decision Point**: If all checks pass, stop here. Otherwise, continue.

---

### Step 2: Root Cause Analysis (5 minutes)

Analyze the diagnostic output to identify the issue category:

#### Category A: Health Check Configuration Mismatch

**Symptoms**:
```
[WARNING] Health check path '/health/' may not match Django endpoints
[ERROR] Target is unhealthy: Target.ResponseCodeMismatch
Response Codes: [400] or [404]
```

**Root Cause**: ALB checking wrong path (e.g., `/health/` instead of `/api/v1/health/health/`)

**Solution**: Proceed to Step 3A

---

#### Category B: Application Not Starting

**Symptoms**:
```
[ERROR] Target is unhealthy: Target.FailedHealthChecks
[ERROR] Deployment failed: tasks failed to start
Running: 0, Desired: 1
```

**Root Cause**: Django application failing to start (database connection, missing env vars, etc.)

**Solution**: Proceed to Step 3B

---

#### Category C: Network/Infrastructure Issues

**Symptoms**:
```
[WARNING] No targets registered to target group
[ERROR] Target is unhealthy: Target.Timeout
```

**Root Cause**: VPC networking, security groups, or target group registration issues

**Solution**: Proceed to Step 3C

---

### Step 3A: Fix Health Check Configuration (3 minutes)

**Automated Fix**:

```bash
# Run fix mode
./scripts/deployment-health-check.sh dev --fix
```

**What this does**:
1. Updates ALB target group health check path to `/api/v1/health/health/`
2. Forces new ECS deployment
3. Waits for deployment to stabilize (up to 10 minutes)
4. Generates final health report

**Expected Result**: Service becomes healthy within 5-10 minutes

**If automated fix fails**, proceed to manual steps:

```bash
# 1. Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# 2. Update health check manually
aws elbv2 modify-target-group \
  --target-group-arn "$TG_ARN" \
  --health-check-path "/api/v1/health/health/" \
  --matcher HttpCode=200

# 3. Force new deployment
aws ecs update-service \
  --cluster lightwave-dev-ecs-cluster \
  --service lightwave-backend-api-dev \
  --force-new-deployment
```

**Verification**:
```bash
# Wait 5 minutes, then re-run diagnostic
./scripts/deployment-health-check.sh dev
```

---

### Step 3B: Fix Application Startup Issues (10-30 minutes)

**Investigation Steps**:

1. **Check ECS task logs**:
```bash
# Get recent task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster lightwave-dev-ecs-cluster \
  --service-name lightwave-backend-api-dev \
  --query 'taskArns[0]' \
  --output text)

# View task details
aws ecs describe-tasks \
  --cluster lightwave-dev-ecs-cluster \
  --tasks "$TASK_ARN" \
  --query 'tasks[0].containers[0].{exitCode:exitCode,reason:reason}'

# View CloudWatch logs
aws logs tail /ecs/lightwave-dev-django-backend --follow
```

2. **Common Issues**:

| Error | Cause | Fix |
|-------|-------|-----|
| `FATAL: database connection failed` | DB credentials wrong | Check AWS Secrets Manager |
| `ImproperlyConfigured: SECRET_KEY` | Missing env var | Add to ECS task definition |
| `ModuleNotFoundError: 'apps.XXX'` | Broken import | Fix code, redeploy |
| `Port 8000 already in use` | Container config issue | Check Dockerfile EXPOSE |

3. **Apply Fix**:
- **Code issue**: Fix in codebase, commit, push (triggers CI/CD)
- **Config issue**: Update ECS task definition in Terraform, apply
- **Secrets issue**: Update AWS Secrets Manager value

4. **Redeploy**:
```bash
# After fix, force new deployment
aws ecs update-service \
  --cluster lightwave-dev-ecs-cluster \
  --service lightwave-backend-api-dev \
  --force-new-deployment
```

---

### Step 3C: Fix Network/Infrastructure Issues (15-45 minutes)

**Investigation Steps**:

1. **Check target registration**:
```bash
TG_ARN=$(aws elbv2 describe-target-groups \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN"
```

2. **Check security groups**:
```bash
# Get ECS task security group
SG_ID=$(aws ecs describe-services \
  --cluster lightwave-dev-ecs-cluster \
  --services lightwave-backend-api-dev \
  --query 'services[0].networkConfiguration.awsvpcConfiguration.securityGroups[0]' \
  --output text)

# Check inbound rules (should allow port 8000 from ALB)
aws ec2 describe-security-groups --group-ids "$SG_ID"
```

3. **Common Issues**:

| Issue | Cause | Fix |
|-------|-------|-----|
| No targets registered | ECS tasks not starting | Check Step 3B |
| Targets deregistering | Health check failing | Check Step 3A |
| Timeout errors | Security group blocking traffic | Update security group rules |
| Connection refused | Wrong port mapping | Check ECS task definition |

4. **Apply Fix** (via Terraform):
```bash
cd Infrastructure/lightwave-infrastructure-live/dev/aws/ecs-service
# Edit terragrunt.hcl to fix security group rules
terragrunt apply
```

---

### Step 4: Verification (5 minutes)

After applying fixes, verify full health:

```bash
# Run final diagnostic
./scripts/deployment-health-check.sh dev

# Expected output:
# [SUCCESS] Prerequisites verified
# [SUCCESS] Health check path is valid
# [SUCCESS] Target is healthy
# [SUCCESS] Service is healthy and stable
```

**Additional Checks**:

```bash
# Test health endpoint directly
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

curl -v "http://${ALB_DNS}/api/v1/health/health/"
# Expected: HTTP 200 OK

# Check ECS service is stable
aws ecs describe-services \
  --cluster lightwave-dev-ecs-cluster \
  --services lightwave-backend-api-dev \
  --query 'services[0].deployments[0].rolloutState'
# Expected: "COMPLETED"
```

---

### Step 5: Documentation (2 minutes)

**If this was a new issue pattern**:

1. Create GitHub issue documenting the problem
2. Update this SOP with new troubleshooting steps
3. Update `.claude/TROUBLESHOOTING.md` with quick reference
4. Consider adding check to `deployment-health-check.sh` script

**Template**:
```markdown
## Issue: [Brief Description]
**Symptom**: [What the user sees]
**Root Cause**: [Technical cause]
**Fix**: [Step-by-step solution]
**Prevention**: [How to avoid in future]
```

---

## Escalation

If issue is not resolved within 1 hour:

1. **Check related systems**:
   - Database (RDS) availability
   - Redis (ElastiCache) availability
   - ECR image repository access

2. **Escalate to**:
   - **Infrastructure issues**: DevOps lead
   - **Application issues**: Backend lead
   - **Critical production outage**: On-call engineer

3. **Emergency rollback**:
```bash
# Rollback to previous stable image
aws ecs update-service \
  --cluster lightwave-prod-ecs-cluster \
  --service lightwave-backend-api-prod \
  --task-definition <PREVIOUS_TASK_DEFINITION_ARN> \
  --force-new-deployment
```

---

## Prevention

### Code Changes

When modifying health check endpoints in Django:

1. **Update both locations**:
   - Backend: `backend/config/urls.py`
   - Infrastructure: `Infrastructure/lightwave-infrastructure-live/*/aws/alb/terragrunt.hcl`

2. **Test locally**:
```bash
cd backend
docker-compose up
curl http://localhost:8000/health/
curl http://localhost:8000/api/v1/health/health/
```

3. **Deploy infrastructure first**, then backend code

### Infrastructure Changes

When modifying ALB configuration:

1. **Always run plan first**:
```bash
terragrunt plan
```

2. **Update health check incrementally**:
   - Deploy to dev first
   - Verify with script: `./scripts/deployment-health-check.sh dev`
   - Then promote to prod

3. **Coordinate with backend team** if changing paths

### CI/CD Integration

Add automated health check to deployment pipeline:

```yaml
# .github/workflows/ci-cd.yml
- name: Verify Deployment Health
  run: |
    ./scripts/deployment-health-check.sh ${{ env.ENVIRONMENT }}
  timeout-minutes: 15
```

---

## Related Documents

- **Script**: `/scripts/deployment-health-check.sh`
- **Skill**: `.claude/skills/deployment-health.md`
- **Troubleshooting**: `.claude/TROUBLESHOOTING.md`
- **Backend Health Endpoints**: `backend/config/urls.py`
- **Infrastructure Config**: `Infrastructure/lightwave-infrastructure-live/*/aws/alb/terragrunt.hcl`

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-10-28 | DevOps Team | Initial SOP based on issue #9 resolution |

---

**Approval**:
- **Author**: DevOps Team
- **Reviewed by**: [Pending]
- **Approved by**: Joel Schaeffer
- **Next Review**: 2025-11-28
