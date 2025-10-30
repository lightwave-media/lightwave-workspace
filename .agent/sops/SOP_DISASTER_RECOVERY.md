# SOP: Disaster Recovery Procedures and Testing

**Version:** 1.0.0
**Last Updated:** 2025-10-28
**Owner:** Platform Team
**Purpose:** Provide comprehensive procedures for recovering from catastrophic failures including data loss, region outages, and complete infrastructure destruction. Defines RTO/RPO targets and ensures team can execute recovery procedures under pressure.

---

## Recovery Time Objectives (RTO) and Recovery Point Objectives (RPO)

| Environment | RTO (max downtime) | RPO (max data loss) |
|-------------|-------------------|---------------------|
| Non-Production | 8 hours       | 24 hours            |
| Production  | 30 minutes       | 5 minutes           |

These targets drive backup frequency and recovery procedures.

---

## Backup Strategy

### RDS Database Backups

- **Automated daily snapshots** (retention: 30 days)
- **Point-in-time recovery enabled** (5-minute granularity)
- **Manual snapshot before major changes**
- **Cross-region snapshot copy** (disaster recovery to us-west-2)

Verify backups:
```bash
aws rds describe-db-snapshots \
  --db-instance-identifier prod-postgres \
  --query 'DBSnapshots[0].{ID:DBSnapshotIdentifier,Time:SnapshotCreateTime,Status:Status}'
```

### Infrastructure State Backups

- **Terragrunt/OpenTofu state in S3** with versioning enabled
- **DynamoDB table for state locks**
- **State backup script** runs before major deployments

Verify state backups:
```bash
aws s3 ls s3://lightwave-terraform-state-prod-us-east-1/ \
  | sort -r | head -5
```

### Application Data Backups

- **Media files in S3** with versioning enabled
- **User-uploaded content** replicated cross-region
- **Lifecycle policy:** Archive to Glacier after 90 days

Verify S3 versioning:
```bash
aws s3api get-bucket-versioning \
  --bucket lightwave-media-prod
```

---

## Disaster Scenarios and Recovery Procedures

### Scenario 1: Accidental Data Deletion

**Detection:** User reports missing data, database queries return no results

**Recovery Steps:**

1. **Confirm data loss:**
   ```sql
   SELECT COUNT(*) FROM users WHERE created_at > '2025-10-28';
   -- Expected: 150, Actual: 0 (data deleted!)
   ```

2. **Identify deletion time:**
   ```bash
   aws logs filter-log-events \
     --log-group-name /aws/rds/prod-postgres/postgresql \
     --filter-pattern "DELETE FROM users" \
     --start-time $(date -d '1 hour ago' +%s)000
   ```

3. **Calculate RPO:** Can we accept data loss since deletion?
   - If **yes:** Restore from nearest backup
   - If **no:** Use point-in-time recovery to exact pre-deletion time

4. **Restore database** (see "RDS Point-in-Time Recovery" below)

5. **Verify restored data:**
   ```sql
   SELECT COUNT(*) FROM users WHERE created_at > '2025-10-28';
   -- Expected: 150 (data restored!)
   ```

6. **Notify users of recovery completion**

**Estimated Time:** 30-60 minutes

---

### Scenario 2: Complete RDS Instance Failure

**Detection:** Application cannot connect to database, RDS console shows instance stopped/failed

**Recovery Steps:**

1. **Check RDS instance status:**
   ```bash
   aws rds describe-db-instances \
     --db-instance-identifier prod-postgres \
     --query 'DBInstances[0].DBInstanceStatus'
   ```

2. **If stopped:** Start instance
   ```bash
   aws rds start-db-instance \
     --db-instance-identifier prod-postgres
   ```

3. **If failed:** Create new instance from latest snapshot
   ```bash
   # List available snapshots
   aws rds describe-db-snapshots \
     --db-instance-identifier prod-postgres \
     --query 'DBSnapshots[0].DBSnapshotIdentifier'

   # Restore from snapshot
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier prod-postgres-restored \
     --db-snapshot-identifier rds:prod-postgres-2025-10-28-06-00 \
     --db-subnet-group-name prod-db-subnet \
     --vpc-security-group-ids sg-0abc123def456
   ```

4. **Wait for instance availability:**
   ```bash
   aws rds wait db-instance-available \
     --db-instance-identifier prod-postgres-restored
   ```

5. **Update DNS or connection string** to point to new instance:
   - Option A: Update Route53 CNAME record
   - Option B: Update ECS task definition environment variables

6. **Run application smoke tests:**
   ```bash
   curl https://api.lightwave-media.ltd/health
   # Expected: {"status": "healthy", "database": "connected"}
   ```

7. **Monitor for data consistency issues**

**Estimated Time:**
- Start instance: 15-30 minutes
- Restore from snapshot: 30-60 minutes (depending on database size)

---

### Scenario 3: AWS Region Outage (us-east-1)

**Detection:** AWS Health Dashboard shows region issues, all services unreachable

**Recovery Steps:**

1. **Verify outage:**
   - Check: https://status.aws.amazon.com
   - AWS Health Dashboard in console
   - Check internal services in other regions

2. **Activate DR region (us-west-2):**
   ```bash
   # Navigate to DR region (ensure infrastructure exists in us-west-2)
   cd Infrastructure/lightwave-infrastructure-live/prod/us-west-2
   export AWS_PROFILE=lightwave-admin-new

   # Deploy infrastructure to DR region
   terragrunt run-all apply --terragrunt-non-interactive
   ```

3. **Restore database from cross-region snapshot:**
   ```bash
   # List snapshots in DR region
   aws rds describe-db-snapshots \
     --region us-west-2 \
     --db-instance-identifier prod-postgres

   # Restore latest snapshot
   aws rds restore-db-instance-from-db-snapshot \
     --region us-west-2 \
     --db-instance-identifier prod-postgres-dr \
     --db-snapshot-identifier <latest-snapshot-arn>
   ```

4. **Update Route53 to point to DR region:**
   ```bash
   # Update DNS records to us-west-2 endpoints
   aws route53 change-resource-record-sets \
     --hosted-zone-id Z1234567890ABC \
     --change-batch file://dns-failover-us-west-2.json
   ```

5. **Deploy application to new region:**
   ```bash
   # Update ECS service in us-west-2
   aws ecs update-service \
     --region us-west-2 \
     --cluster lightwave-prod-dr \
     --service backend-prod \
     --desired-count 2
   ```

6. **Run full integration tests:**
   ```bash
   make test-prod-dr
   ```

7. **Notify users of temporary service disruption:**
   ```
   We experienced an AWS regional outage affecting our primary datacenter.
   Service has been restored via our disaster recovery site.
   All data is intact. Some users may need to log in again.
   ```

**Estimated Time:** 2-4 hours (depending on infrastructure complexity)

**Cost Impact:** Running duplicate infrastructure in DR region (~2x cost during outage)

---

### Scenario 4: Complete Infrastructure Destruction

**Detection:** All infrastructure gone (accidental `terragrunt destroy` or compromised credentials)

**Recovery Steps:**

1. **Secure AWS account immediately:**
   ```bash
   # Rotate credentials
   aws iam update-access-key --access-key-id AKIA... --status Inactive
   aws iam create-access-key --user-name admin

   # Enable MFA if not already enabled
   # Review CloudTrail for unauthorized actions
   ```

2. **Assess damage:**
   ```bash
   # List remaining resources in AWS console
   aws ec2 describe-instances
   aws rds describe-db-instances
   aws ecs list-clusters
   aws s3 ls
   ```

3. **Restore infrastructure from code:**
   ```bash
   # Navigate to production infrastructure
   cd Infrastructure/lightwave-infrastructure-live/prod/us-east-1
   export AWS_PROFILE=lightwave-admin-new

   # Restore all infrastructure (runs across all services)
   terragrunt run-all apply --terragrunt-non-interactive
   ```

4. **Restore database from latest snapshot:**
   ```bash
   # Find latest snapshot (may still exist even if instance deleted)
   aws rds describe-db-snapshots \
     --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime) | [-1]'

   # Restore
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier prod-postgres \
     --db-snapshot-identifier <snapshot-id>
   ```

5. **Restore application configuration from Git:**
   ```bash
   git pull origin main
   # All infrastructure and application config is in Git
   ```

6. **Deploy latest application version:**
   ```bash
   # ECS will pull latest container from GHCR
   aws ecs update-service \
     --cluster lightwave-prod \
     --service backend-prod \
     --force-new-deployment
   ```

7. **Run full system tests:**
   ```bash
   make test-prod-full
   ```

8. **Document incident and implement safeguards:**
   - Create file: `.claude/incidents/incident-YYYY-MM-DD.md`
   - Add MFA requirements for destructive actions
   - Implement AWS Organizations SCPs to prevent deletion

**Estimated Time:** 4-8 hours

---

## RDS Point-in-Time Recovery Procedure

Use when you need to restore database to a specific moment in time (e.g., 5 minutes before data deletion).

### Steps

1. **Identify target restore time:**
   ```bash
   # Example: October 28, 2025 at 2:30 PM UTC
   TARGET_TIME="2025-10-28T14:30:00Z"
   ```

2. **Create new instance from PITR:**
   ```bash
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier prod-postgres \
     --target-db-instance-identifier prod-postgres-restored \
     --restore-time $TARGET_TIME
   ```

3. **Wait for instance creation:**
   ```bash
   aws rds wait db-instance-available \
     --db-instance-identifier prod-postgres-restored
   ```

4. **Test restored instance:**
   ```bash
   # Get endpoint
   RESTORED_ENDPOINT=$(aws rds describe-db-instances \
     --db-instance-identifier prod-postgres-restored \
     --query 'DBInstances[0].Endpoint.Address' \
     --output text)

   # Connect and verify data
   psql -h $RESTORED_ENDPOINT -U admin -d lightwave \
     -c "SELECT COUNT(*) FROM users;"
   ```

5. **If data correct, update application connection string:**
   - Update ECS task definition
   - Update Secrets Manager
   - Or promote restored instance (rename)

6. **Run application smoke tests:**
   ```bash
   curl https://api.lightwave-media.ltd/health
   ```

7. **Promote restored instance to production:**
   - Option A: Rename instances (downtime required)
   - Option B: Update DNS (CNAME record)
   - Option C: Update application config (no downtime)

### Warnings

⚠️ **PITR creates NEW instance, does not modify existing**

⚠️ **Connection string will change** (new endpoint)

⚠️ **Security groups must be configured on new instance**

⚠️ **Manual snapshot of current state before PITR** (in case you need to go back)

---

## Communication Plan During Disaster

### Incident Declaration

1. Post in **#incidents** channel:
   ```
   🚨 INCIDENT DECLARED

   Severity: P1 (Critical)
   Type: [Data Loss / Service Outage / Security Breach]
   Impact: [Production database unavailable]
   Incident Commander: @yourname
   War room: https://zoom.us/j/incident-123

   Initial assessment: [brief description]
   Next update: In 15 minutes
   ```

2. Update status page: `status.lightwave-media.ltd`
   - Status: "Major Outage"
   - Message: "We are currently investigating a database issue affecting our services."

### Progress Updates

**Frequency:** Every 15 minutes during active recovery

**Template:**
```
Update #2 - 14:45 UTC

Status: Identified root cause, executing recovery
Impact: Production API unavailable, frontend read-only
Actions taken:
  - Identified database failure at 14:30 UTC
  - Initiated restore from snapshot taken at 14:20 UTC
  - ETA for database restoration: 15:00 UTC

Next steps:
  - Complete database restoration
  - Verify data integrity
  - Bring services back online

Next update: 15:00 UTC
```

### Resolution

1. Verify all systems operational:
   ```bash
   # Run full health check
   make health-check-prod

   # Check error rates
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ECS \
     --metric-name HTTPCode_Target_5XX_Count \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum
   ```

2. Post resolution message:
   ```
   ✅ INCIDENT RESOLVED

   Duration: 45 minutes (14:30 - 15:15 UTC)
   Root cause: RDS instance failure
   Resolution: Restored from automated snapshot
   Data loss: None (RPO: 0 minutes)

   All services are now operational.

   Post-mortem scheduled: Tomorrow 10am
   ```

3. Update status page to "All Systems Operational"

4. Schedule post-mortem meeting within 24 hours

---

## Disaster Recovery Testing Schedule

Regular testing ensures procedures work when needed.

### Quarterly (Production)

**What to test:**
- Full database restore from snapshot
- Verify backup integrity
- Test cross-region failover (to us-west-2)
- Update runbooks based on findings

**When:** Last Friday of each quarter, during low-traffic window

**Procedure:**
1. Announce test in #infrastructure channel (1 week advance notice)
2. Create manual snapshot of production database
3. Restore snapshot to test instance
4. Verify data integrity
5. Document timing and any issues
6. Delete test instance

### Bi-annually (Non-Production)

**What to test:**
- Complete infrastructure rebuild from scratch
- Test all disaster scenarios
- Train new team members on procedures

**When:** January and July

**Procedure:**
1. Delete all non-prod infrastructure (terragrunt destroy)
2. Rebuild from code (terragrunt apply)
3. Restore database from backup
4. Deploy application
5. Run integration tests
6. Document lessons learned

### Annual

**What to test:**
- Conduct tabletop disaster exercise
- Review and update RTO/RPO targets
- Audit backup retention policies
- Cross-region failover test (production-like)

**When:** October (before holiday season)

**Procedure:**
1. Assemble team for 2-hour session
2. Walk through each disaster scenario
3. Identify gaps in procedures
4. Update documentation
5. Assign action items for improvements

---

## Post-Disaster Activities

After any disaster (real or test), complete these activities:

1. **Document timeline of events:**
   ```markdown
   # Incident: Database Failure - 2025-10-28

   ## Timeline
   - 14:30 UTC: Database became unavailable
   - 14:35 UTC: Incident declared, team assembled
   - 14:40 UTC: Root cause identified (RDS instance failure)
   - 14:45 UTC: Restore initiated from snapshot
   - 15:00 UTC: Restore complete, testing begun
   - 15:15 UTC: Services restored, incident resolved

   ## Impact
   - Duration: 45 minutes
   - Affected: All API requests (100% outage)
   - Data loss: None
   ```

2. **Identify root cause:**
   - What caused the disaster?
   - Could it have been prevented?
   - Were there warning signs?

3. **List what went well and what didn't:**
   - **Went well:** Automated snapshots worked, team responded quickly
   - **Needs improvement:** Monitoring didn't alert us before complete failure

4. **Create action items to prevent recurrence:**
   ```
   - [ ] Set up RDS enhanced monitoring (INFRA-XXX)
   - [ ] Create CloudWatch alarm for database CPU >80% (INFRA-YYY)
   - [ ] Add database health check to monitoring dashboard (INFRA-ZZZ)
   ```

5. **Update disaster recovery procedures:**
   - Add lessons learned
   - Update timing estimates (if actual time differed)
   - Add new troubleshooting steps

6. **Schedule follow-up training:**
   - Present post-mortem findings to team
   - Update runbooks based on actual experience
   - Train new team members on updated procedures

---

## Related Documents

- Remote State Management: `SOP_REMOTE_STATE_MANAGEMENT.md`
- Infrastructure Deployment: `SOP_INFRASTRUCTURE_DEPLOYMENT.md`
- Emergency Shutdown: `SOP_EMERGENCY_SHUTDOWN_PROCEDURE.md`
- Deployment Configuration: `.agent/metadata/deployment.yaml`

---

**Revision History:**
- 2025-10-28: Initial version (1.0.0)
