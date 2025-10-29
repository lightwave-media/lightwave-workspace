# Skill: Systematic Issue Diagnosis

**Version**: 1.0.0
**Created**: 2025-10-28
**Purpose**: Systematic troubleshooting process for technical issues
**Status**: Active

---

## Overview

This skill provides a methodical approach to diagnosing and resolving technical issues across the LightWave platform. It focuses on identifying root causes rather than treating symptoms, using a structured diagnostic process.

**Use this skill when**:
- Application is not working as expected
- Tests are failing unexpectedly
- Deployment issues occur
- Performance problems arise
- Integration issues between services
- User reports bugs or errors

---

## Prerequisites

Before troubleshooting:

1. **Context established**: Complete onboarding checklist
2. **Environment verified**: Know which environment (local, dev, staging, prod)
3. **Issue described**: Clear description of the problem
4. **TROUBLESHOOTING.md loaded**: Read common issues first

```bash
cat /Users/joelschaeffer/dev/lightwave-workspace/.claude/TROUBLESHOOTING.md
```

---

## The Troubleshooting Process

```
┌─────────────────────────────────────────────────────────────┐
│            SYSTEMATIC TROUBLESHOOTING PROCESS               │
└─────────────────────────────────────────────────────────────┘

1. GATHER INFORMATION
   ├─ What is the symptom?
   ├─ When did it start?
   ├─ What changed recently?
   └─ Can you reproduce it?

2. FORM HYPOTHESIS
   ├─ What could cause this?
   ├─ Check similar past issues
   └─ Consider system interactions

3. TEST HYPOTHESIS
   ├─ Run diagnostic commands
   ├─ Check logs
   ├─ Verify configuration
   └─ Test in isolation

4. IDENTIFY ROOT CAUSE
   ├─ Symptoms vs causes
   ├─ Follow the chain
   └─ Verify with data

5. IMPLEMENT FIX
   ├─ Apply targeted solution
   ├─ Test thoroughly
   └─ Verify resolved

6. DOCUMENT & PREVENT
   ├─ Update TROUBLESHOOTING.md
   ├─ Add monitoring
   └─ Prevent recurrence
```

---

## Step 1: Gather Information

### 1.1 Describe the Issue

**Ask the 5 Ws**:

| Question | Example Answer |
|----------|----------------|
| **What** is happening? | "Login endpoint returns 500 error" |
| **When** did it start? | "Started after deployment at 2:30 PM" |
| **Where** is it happening? | "Production environment, /api/auth/login/" |
| **Who** is affected? | "All users trying to log in" |
| **Why** is it a problem? | "Users cannot access their accounts" |

### 1.2 Gather Context

**Environment**:
```bash
# Which environment?
echo "Environment: production"

# Which service?
echo "Service: Django backend API"

# Which version/commit?
git log -1 --oneline
# Example: a1b2c3d feat(auth): update login endpoint
```

**Recent changes**:
```bash
# Check recent commits
git log --since="2 hours ago" --oneline

# Check recent deployments
gh run list --limit 5

# Check if infrastructure changed
cd Infrastructure/lightwave-infrastructure-live
git log --since="1 day ago" --oneline
```

### 1.3 Reproduce the Issue

**Attempt to reproduce**:

```bash
# Try the failing operation
curl -X POST https://api.lightwave-media.ltd/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}'

# Expected: 500 error (confirms issue)
# Actual: {"error": "Internal Server Error"}
```

**Document reproduction steps**:
```markdown
## Reproduction Steps
1. Navigate to https://lightwave-media.ltd/login
2. Enter valid email and password
3. Click "Log In"
4. Observe: Page hangs, then shows "Login failed"
5. Check Network tab: POST to /api/auth/login/ returns 500
```

**Check if intermittent or consistent**:
```bash
# Try multiple times
for i in {1..5}; do
  echo "Attempt $i:"
  curl -w "\nStatus: %{http_code}\n" -X POST ...
  sleep 2
done

# Result: Fails 5/5 times → Consistent issue (good for diagnosis)
# Result: Fails 2/5 times → Intermittent (harder to diagnose)
```

---

## Step 2: Form Hypothesis

### 2.1 Categorize the Issue

**Common categories**:

| Category | Indicators | Common Causes |
|----------|-----------|---------------|
| **Application Logic** | Wrong results, unexpected behavior | Code bugs, incorrect logic |
| **Configuration** | Can't connect, wrong endpoint | Environment variables, config files |
| **Infrastructure** | Timeouts, 503 errors, can't reach service | AWS issues, networking, capacity |
| **Dependencies** | Import errors, module not found | Missing packages, version conflicts |
| **Data** | Database errors, null values | Schema mismatch, migration issues |
| **Permissions** | 401, 403 errors | Authentication, IAM policies |
| **Performance** | Slow responses, timeouts | Database queries, memory leaks |

**For our example** (500 error on login):
- Category: **Application Logic** or **Configuration**
- Why: 500 = server error, likely code exception or missing config

### 2.2 Check Known Issues

**Search TROUBLESHOOTING.md**:
```bash
grep -i "500 error" /Users/joelschaeffer/dev/lightwave-workspace/.claude/TROUBLESHOOTING.md
grep -i "login" /Users/joelschaeffer/dev/lightwave-workspace/.claude/TROUBLESHOOTING.md
```

**Search past issues**:
```bash
# GitHub issues
gh issue list --search "500 error" --state closed

# Git history
git log --all --grep="500 error" --oneline
```

### 2.3 Formulate Hypotheses

**Possible causes for login 500 error**:
1. **Database connection failed** → Can't query user table
2. **Environment variable missing** → JWT secret key not set
3. **Code exception** → Recent code change introduced bug
4. **Dependency issue** → Library version incompatibility
5. **Resource exhaustion** → Out of memory, too many connections

**Rank by likelihood**:
```
1. Environment variable missing (MOST LIKELY)
   - Recent deployment
   - Config often forgotten

2. Code exception
   - Recent commit changed login endpoint

3. Database connection failed (LESS LIKELY)
   - Other endpoints would also fail
   - No reports of other issues
```

---

## Step 3: Test Hypothesis

### 3.1 Check Logs

**Application logs**:

```bash
# Django logs in AWS CloudWatch
aws logs tail /ecs/lightwave-prod-django-backend --follow

# Or via ECS container
aws ecs execute-command \
  --cluster lightwave-prod-ecs-cluster \
  --task <task-id> \
  --container django-backend \
  --command "/bin/bash" \
  --interactive

# Inside container
tail -f /var/log/django/error.log
```

**Look for**:
```
[ERROR] Exception in login view: KeyError: 'JWT_SECRET_KEY'
Traceback (most recent call last):
  File "views.py", line 45, in login
    secret = os.environ['JWT_SECRET_KEY']
KeyError: 'JWT_SECRET_KEY'
```

**Confirm hypothesis**: ✅ Environment variable missing!

### 3.2 Check Configuration

**Verify environment variables**:

```bash
# In ECS task definition
aws ecs describe-task-definition \
  --task-definition lightwave-prod-django-backend \
  --query 'taskDefinition.containerDefinitions[0].environment'

# Look for JWT_SECRET_KEY in output
# If missing → Confirms hypothesis
```

**Check secrets in AWS**:

```bash
# List parameters
aws ssm describe-parameters \
  --parameter-filters "Key=Name,Option=BeginsWith,Values=/lightwave/prod" \
  --query 'Parameters[*].Name'

# Check if JWT_SECRET_KEY exists
aws ssm get-parameter \
  --name "/lightwave/prod/jwt/secret-key" \
  --with-decryption

# If error → Secret not created
```

### 3.3 Check Infrastructure

**If hypothesis is infrastructure-related**:

```bash
# Check ECS service health
aws ecs describe-services \
  --cluster lightwave-prod-ecs-cluster \
  --services lightwave-backend-api-prod \
  --query 'services[0].{Running:runningCount,Desired:desiredCount,Events:events[0:3]}'

# Check ALB target health
TG_ARN=$(aws elbv2 describe-target-groups \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health --target-group-arn "$TG_ARN"

# Check RDS database
aws rds describe-db-instances \
  --db-instance-identifier lightwave-prod-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

### 3.4 Test in Isolation

**Isolate the problem**:

```bash
# Test database connection separately
aws ecs execute-command ... --command "/bin/bash"
# Inside container:
python manage.py shell
>>> from django.db import connection
>>> connection.ensure_connection()
>>> print("Database connected")  # If no error → DB is fine

# Test JWT generation separately
>>> import os
>>> print(os.environ.get('JWT_SECRET_KEY'))
None  # ← Confirms missing env var!
```

---

## Step 4: Identify Root Cause

### 4.1 Distinguish Symptoms from Causes

**Symptoms** (what you observe):
- Login endpoint returns 500 error
- Users cannot log in
- Error logged in CloudWatch

**Root cause** (underlying issue):
- `JWT_SECRET_KEY` environment variable not set in ECS task definition

**Why distinction matters**:
- Fixing symptom: Restart service (might temporarily work)
- Fixing root cause: Add environment variable (permanent fix)

### 4.2 Follow the Chain

**Trace backwards from symptom to cause**:

```
Symptom: 500 error on login
    ↓
Django view raises KeyError
    ↓
os.environ['JWT_SECRET_KEY'] missing
    ↓
ECS task definition doesn't include JWT_SECRET_KEY
    ↓
Terraform/Terragrunt config missing this environment variable
    ↓
ROOT CAUSE: Recent infrastructure update removed the env var
```

### 4.3 Verify with Data

**Confirm root cause**:

```bash
# Check Terraform configuration
cd Infrastructure/lightwave-infrastructure-live/prod/aws/ecs-service

# Check terragrunt.hcl for environment variables
grep -A 30 "environment" terragrunt.hcl

# Output shows JWT_SECRET_KEY is NOT in the list
# ✅ Root cause confirmed
```

**Check git history**:
```bash
git log --all --oneline -- terragrunt.hcl | head -5

# Shows recent commit:
# d4e5f6g refactor(infra): clean up environment variables

git show d4e5f6g -- terragrunt.hcl | grep JWT_SECRET_KEY
# Shows: - { name = "JWT_SECRET_KEY", value = ... }  # ← Was removed!

# ✅ Root cause definitively identified
```

---

## Step 5: Implement Fix

### 5.1 Apply Targeted Solution

**Fix the root cause** (not just symptoms):

```bash
# Navigate to infrastructure
cd Infrastructure/lightwave-infrastructure-live/prod/aws/ecs-service

# Edit terragrunt.hcl
# Add back the environment variable
```

```hcl
# terragrunt.hcl

environment = [
  {
    name  = "DJANGO_SETTINGS_MODULE"
    value = "config.settings.production"
  },
  {
    name  = "JWT_SECRET_KEY"
    value = "arn:aws:ssm:us-east-1:738605694078:parameter/lightwave/prod/jwt/secret-key"
  },
  # ... other env vars
]
```

```bash
# Apply the change
terragrunt plan  # Review changes
terragrunt apply # Apply changes

# Force new ECS deployment to pick up new task definition
aws ecs update-service \
  --cluster lightwave-prod-ecs-cluster \
  --service lightwave-backend-api-prod \
  --force-new-deployment
```

### 5.2 Test the Fix

**Verify the fix works**:

```bash
# Wait for deployment to stabilize (2-5 minutes)
aws ecs wait services-stable \
  --cluster lightwave-prod-ecs-cluster \
  --services lightwave-backend-api-prod

# Test login endpoint
curl -X POST https://api.lightwave-media.ltd/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"testpass"}'

# Expected: 200 OK with token
# Actual: {"token": "eyJhbGc...", "refresh": "..."}
# ✅ Fix successful!
```

**Test edge cases**:
```bash
# Test invalid credentials
curl -X POST ... -d '{"email":"test@example.com","password":"wrong"}'
# Expected: 401 Unauthorized
# ✅ Works correctly

# Test missing fields
curl -X POST ... -d '{"email":"test@example.com"}'
# Expected: 400 Bad Request
# ✅ Works correctly
```

### 5.3 Verify Side Effects

**Check other systems**:

```bash
# Test other endpoints that use JWT
curl https://api.lightwave-media.ltd/api/auth/me/ \
  -H "Authorization: Bearer $TOKEN"
# ✅ Works

# Check related services
curl https://api.lightwave-media.ltd/api/health/
# ✅ Healthy
```

---

## Step 6: Document & Prevent

### 6.1 Update TROUBLESHOOTING.md

**Add to the troubleshooting guide**:

```bash
# Edit TROUBLESHOOTING.md
cat >> /Users/joelschaeffer/dev/lightwave-workspace/.claude/TROUBLESHOOTING.md <<'EOF'

## Issue: Login Returns 500 Error

**Symptom**: POST to /api/auth/login/ returns 500 Internal Server Error

**Root Cause**: Missing JWT_SECRET_KEY environment variable in ECS task definition

**Diagnosis**:
1. Check CloudWatch logs: Look for KeyError: 'JWT_SECRET_KEY'
2. Verify ECS task definition: Check environment variables list
3. Check Terraform config: Ensure JWT_SECRET_KEY is defined

**Solution**:
1. Add JWT_SECRET_KEY to terragrunt.hcl:
   ```hcl
   environment = [
     {
       name  = "JWT_SECRET_KEY"
       value = "arn:aws:ssm:us-east-1:738605694078:parameter/lightwave/prod/jwt/secret-key"
     }
   ]
   ```
2. Apply Terraform: `terragrunt apply`
3. Force ECS deployment: `aws ecs update-service --force-new-deployment`

**Prevention**:
- Add JWT_SECRET_KEY to required environment variables checklist
- Add validation in deployment pipeline to check for required env vars
- Document all required environment variables in .agent/metadata/deployment.yaml

**Related Issues**: #456
**Date**: 2025-10-28
EOF
```

### 6.2 Add Monitoring

**Prevent future occurrences**:

```yaml
# .github/workflows/validate-deployment-config.yml

name: Validate Deployment Config

on:
  pull_request:
    paths:
      - 'Infrastructure/**'

jobs:
  validate-env-vars:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check Required Environment Variables
        run: |
          # Check that JWT_SECRET_KEY is in ECS task definition
          if ! grep -q "JWT_SECRET_KEY" Infrastructure/lightwave-infrastructure-live/prod/aws/ecs-service/terragrunt.hcl; then
            echo "❌ ERROR: JWT_SECRET_KEY missing from ECS task definition"
            exit 1
          fi
          echo "✅ All required environment variables present"
```

### 6.3 Create Preventive Measures

**Add to checklist**:

```markdown
## Deployment Checklist

- [ ] All required environment variables set
  - [ ] JWT_SECRET_KEY
  - [ ] DATABASE_URL
  - [ ] REDIS_URL
  - [ ] CLOUDFLARE_API_TOKEN
- [ ] Secrets exist in AWS Parameter Store
- [ ] ECS task definition includes all secrets
- [ ] Health check endpoint configured
- [ ] Monitoring and alerting enabled
```

---

## Common Diagnostic Commands

### Application Logs

```bash
# CloudWatch Logs
aws logs tail /ecs/lightwave-prod-django-backend --follow --since 30m

# ECS container logs
aws ecs describe-tasks \
  --cluster <cluster> \
  --tasks <task-arn> \
  --query 'tasks[0].containers[0].{name:name,reason:reason}'

# Application error logs
tail -f /var/log/django/error.log
```

### Database

```bash
# PostgreSQL connection test
psql -h <host> -U <user> -d <database> -c "SELECT 1;"

# Django database shell
python manage.py dbshell

# Check migrations
python manage.py showmigrations

# Check for long-running queries
SELECT pid, query, state, query_start
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY query_start;
```

### Network

```bash
# Check DNS resolution
nslookup api.lightwave-media.ltd

# Test connectivity
curl -v https://api.lightwave-media.ltd/api/health/

# Check ports
nc -zv localhost 8000

# Trace route
traceroute api.lightwave-media.ltd
```

### Infrastructure (AWS)

```bash
# ECS service status
aws ecs describe-services --cluster <cluster> --services <service>

# ALB target health
aws elbv2 describe-target-health --target-group-arn <arn>

# RDS instance status
aws rds describe-db-instances --db-instance-identifier <instance>

# CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=<service> \
  --start-time 2025-10-28T00:00:00Z \
  --end-time 2025-10-28T23:59:59Z \
  --period 3600 \
  --statistics Average
```

### Performance

```bash
# Memory usage
free -h

# Disk usage
df -h

# CPU usage
top -bn1 | head -20

# Process list
ps aux | grep python

# Django debug toolbar (local)
# Add to settings.py and access /__debug__/
```

---

## When to Check Logs vs Configuration vs Environment

### Check Logs When:
- Error messages visible to user
- Intermittent issues
- Performance problems
- Unexpected behavior
- Need to trace request flow

### Check Configuration When:
- Service won't start
- Connection errors
- Authentication failures
- Wrong endpoints
- Missing features

### Check Environment When:
- Deployment issues
- Infrastructure changes
- Networking problems
- Resource constraints
- Scaling issues

---

## Escalation Paths

### Level 1: Self-Diagnosis (0-30 minutes)
- Follow this troubleshooting skill
- Check TROUBLESHOOTING.md
- Search past issues
- Run diagnostic commands

### Level 2: Team Escalation (30-60 minutes)
- **Frontend issues** → Frontend lead
- **Backend issues** → Backend lead
- **Infrastructure issues** → DevOps lead
- **Database issues** → Database admin

### Level 3: Critical Escalation (1+ hour)
- **Production outage** → On-call engineer
- **Security incident** → Security team
- **Data loss** → CTO + backup team

**Escalation template**:
```markdown
## Issue Report

**Severity**: Critical / High / Medium / Low
**Impact**: [Who/what is affected]
**Environment**: Production / Staging / Dev

**Symptom**: [What's happening]
**Root Cause**: [If known] or "Under investigation"
**Attempted Fixes**: [What you tried]
**Next Steps**: [What needs to happen]

**Timeline**:
- 14:30 - Issue first detected
- 14:35 - Investigation started
- 14:45 - Root cause identified
- 15:00 - Fix applied (testing)

**Contact**: [Your name/handle]
```

---

## Reference: Troubleshooting Decision Tree

```
┌──────────────────────────────┐
│     Is it working at all?    │
└───────┬──────────────────────┘
        │
   ┌────┴────┐
   NO       YES
   │         │
   │         └─→ Performance issue?
   │              ├─ YES → Check logs, metrics, queries
   │              └─ NO → Intermittent? → Check logs for errors
   │
   └─→ Can you connect?
       ├─ NO → Network/infrastructure issue
       │       ├─ Check DNS
       │       ├─ Check security groups
       │       └─ Check service is running
       │
       └─ YES → Getting errors?
              ├─ 4xx → Client/auth issue
              │       ├─ Check credentials
              │       ├─ Check permissions
              │       └─ Check request format
              │
              └─ 5xx → Server issue
                      ├─ Check logs
                      ├─ Check configuration
                      ├─ Check dependencies
                      └─ Check resources
```

---

## Related Documentation

- **Common issues**: `.claude/TROUBLESHOOTING.md`
- **Deployment issues**: `.agent/sops/SOP_DEPLOYMENT_HEALTH_TROUBLESHOOTING.md`
- **AWS secrets**: `.claude/skills/secrets-loader.md`
- **Git issues**: `.agent/sops/THE_COMPLETE_GIT_WORKFLOW.md`
- **Architecture context**: `.agent/metadata/`

---

**Maintained by**: Joel Schaeffer
**Last Updated**: 2025-10-28
**Version**: 1.0.0
