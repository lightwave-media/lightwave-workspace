# SOP: Infrastructure Cost Monitoring and Optimization

**Version:** 1.0.0
**Last Updated:** 2025-10-28
**Owner:** Platform Team / Finance
**Purpose:** Prevent unexpected AWS costs through proactive monitoring, alerting, and regular optimization reviews. Provides procedures for cost allocation, budget management, and emergency cost control.

---

## Prerequisites

- AWS Cost Explorer enabled (free, but data delayed 24hrs)
- AWS Budgets configured for each environment
- Cost allocation tags applied to all resources
- SNS topic set up for budget alerts
- Access to billing dashboard

---

## Cost Allocation Tagging Strategy

### Required Tags on ALL Resources

```hcl
default_tags {
  tags = {
    Environment = "prod"           # dev|staging|prod
    ManagedBy   = "Terragrunt"     # Terragrunt|Manual
    Owner       = "Platform Team"  # Team name
    CostCenter  = "Engineering"    # Department
    Project     = "LightWave Media"
  }
}
```

### Example Terraform Implementation

```hcl
# In provider.tf or root.hcl
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terragrunt"
      Owner       = "Platform Team"
      CostCenter  = "Engineering"
      Project     = "LightWave Media"
    }
  }
}
```

### Verify Tags Applied

```bash
# Check RDS instance tags
aws rds list-tags-for-resource \
  --resource-name arn:aws:rds:us-east-1:123456789012:db:prod-postgres

# Check ECS service tags
aws ecs list-tags-for-resource \
  --resource-arn arn:aws:ecs:us-east-1:123456789012:service/lightwave-prod/backend-prod
```

---

## Budget Configuration

### Development Environment

**Monthly Budget:** $50

**Alerts:**
- **80% threshold:** Email to team (`team@lightwave-media.ltd`)
- **100% threshold:** Email + Slack alert to `#infrastructure`
- **150% threshold:** Trigger emergency shutdown workflow

### Staging Environment

**Monthly Budget:** $100

**Alerts:**
- **80% threshold:** Email to team
- **100% threshold:** Email + Slack alert to `#infrastructure`

### Production Environment

**Monthly Budget:** $500

**Alerts:**
- **70% threshold:** Email to management
- **85% threshold:** Email + Slack alert to team
- **100% threshold:** Emergency meeting scheduled

---

## Setting Up Budget Alerts with Terraform

### Terraform Module

```hcl
# modules/budget/main.tf
resource "aws_budgets_budget" "monthly" {
  name         = "${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_amount
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  # 70% threshold - Email to management
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 70
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.management_emails
  }

  # 85% threshold - Email + Slack
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 85
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.team_emails
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
  }

  # 100% threshold - Critical alert
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = concat(var.team_emails, var.management_emails)
    subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts_critical.arn]
  }

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Environment$${var.environment}"]
  }
}

resource "aws_sns_topic" "budget_alerts" {
  name = "${var.environment}-budget-alerts"
}

resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}
```

### Deploy Budget Monitoring

```bash
cd Infrastructure/lightwave-infrastructure-live/prod/us-east-1/budgets
terragrunt apply
```

---

## Monthly Cost Review Process

**Frequency:** First Monday of each month (30-minute meeting)

### Preparation (Before Meeting)

1. **Generate cost report:**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2025-10-01,End=2025-10-31 \
     --granularity MONTHLY \
     --metrics BlendedCost \
     --group-by Type=TAG,Key=Environment \
     --output table
   ```

2. **Export to spreadsheet:**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2025-10-01,End=2025-10-31 \
     --granularity MONTHLY \
     --metrics BlendedCost UnblendedCost \
     --group-by Type=SERVICE \
     --output json > cost-report-$(date +%Y-%m).json
   ```

### During Meeting

1. **Review top 10 cost drivers in Cost Explorer:**
   - Open: https://console.aws.amazon.com/cost-management/home#/cost-explorer
   - Group by: Service
   - Time range: Last month
   - Sort by: Cost (descending)

2. **Identify unexpected increases:**
   - Look for >20% month-over-month increase
   - Investigate cause (new feature? Bug? Attack?)

3. **Check for idle resources:**
   - Unattached EBS volumes
   - Stopped RDS instances (still charged for storage)
   - Unused Elastic Load Balancers ($16/month each)
   - Old EBS snapshots

4. **Review Reserved Instance coverage:**
   - Open: Cost Explorer > Reserved Instance Coverage
   - Target: >80% coverage for stable workloads
   - Identify opportunities for 1-year or 3-year RIs

5. **Document findings:**
   ```bash
   # Create cost review document
   cat > .agent/cost-reviews/cost-review-2025-10.md <<EOF
   # Cost Review - October 2025

   ## Total Spend
   - Development: \$42 (-16% vs budget)
   - Staging: \$95 (-5% vs budget)
   - Production: \$478 (-4% vs budget)
   - **Total:** \$615

   ## Top Cost Drivers
   1. RDS - \$280 (46%)
   2. ECS Fargate - \$180 (29%)
   3. Data Transfer - \$75 (12%)
   4. ElastiCache - \$50 (8%)
   5. Application Load Balancer - \$30 (5%)

   ## Anomalies
   - Data Transfer increased 30% due to media uploads spike
   - No unexpected costs

   ## Optimization Opportunities
   - [ ] Purchase RDS Reserved Instance (save \$120/mo)
   - [ ] Enable S3 Intelligent Tiering for media (save \$15/mo)
   - [ ] Delete old EBS snapshots >90 days (save \$10/mo)

   ## Action Items
   - INFRA-XXX: Implement RDS Reserved Instance
   - INFRA-YYY: Configure S3 lifecycle policies
   EOF
   ```

6. **Create tasks for optimization opportunities**

---

## Cost Optimization Opportunities

### 1. RDS Reserved Instances

**Savings:** Up to 40% for 1-year RI, 60% for 3-year RI

**Recommendation:** Purchase RIs for production databases after 3 months of stable usage

**Steps:**

1. **Check current RDS usage:**
   ```bash
   aws rds describe-db-instances \
     --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine]' \
     --output table
   ```

2. **Calculate monthly cost:**
   - Open Cost Explorer
   - Filter: Service = RDS
   - Time range: Last 3 months

3. **Review RI recommendations:**
   - Open: https://console.aws.amazon.com/cost-management/home#/ri/recommendations
   - Service: Amazon RDS
   - Term: 1 year or 3 year
   - Payment: All upfront (maximum savings)

4. **Purchase RI:**
   ```bash
   aws rds purchase-reserved-db-instances-offering \
     --reserved-db-instances-offering-id <offering-id> \
     --db-instance-count 1
   ```

**Example Savings:**
- On-demand db.t3.medium: $0.068/hour = $50/month
- 1-year RI all upfront: $365/year = $30/month
- **Savings: $20/month (40%)**

### 2. ECS Fargate Savings Plans

**Savings:** Up to 50% for 1-year commitment

**Recommendation:** Analyze 90-day Fargate usage before committing

**Steps:**

1. **Review Savings Plans recommendations:**
   - Open: https://console.aws.amazon.com/cost-management/home#/savings-plans/recommendations
   - Select: Compute Savings Plans

2. **Commit to consistent baseline usage:**
   - Example: Commit to $100/month Fargate usage
   - Pay for baseline at discounted rate
   - Burst usage at on-demand rate

3. **Purchase Savings Plan:**
   - Navigate to: Savings Plans > Purchase Savings Plans
   - Hourly commitment: Calculate based on baseline usage
   - Term: 1 year
   - Payment: All upfront or No upfront

**Example Savings:**
- Baseline Fargate: $150/month on-demand
- 1-year Savings Plan: $75/month (50% off)
- Burst usage: $50/month on-demand
- **Total: $125/month instead of $200/month**

### 3. S3 Lifecycle Policies

**Savings:** 90% by moving old data to Glacier

**Recommendation:** Archive media files older than 90 days

**Steps:**

1. **Create lifecycle policy:**
   ```bash
   cat > s3-lifecycle-policy.json <<EOF
   {
     "Rules": [
       {
         "Id": "ArchiveOldMedia",
         "Status": "Enabled",
         "Filter": {
           "Prefix": "media/"
         },
         "Transitions": [
           {
             "Days": 90,
             "StorageClass": "GLACIER"
           }
         ],
         "Expiration": {
           "Days": 2555
         }
       }
     ]
   }
   EOF
   ```

2. **Apply to bucket:**
   ```bash
   aws s3api put-bucket-lifecycle-configuration \
     --bucket lightwave-media-prod \
     --lifecycle-configuration file://s3-lifecycle-policy.json
   ```

3. **Verify:**
   ```bash
   aws s3api get-bucket-lifecycle-configuration \
     --bucket lightwave-media-prod
   ```

**Example Savings:**
- 100GB in S3 Standard: $2.30/month
- 100GB in Glacier: $0.40/month
- **Savings: $1.90/month per 100GB**

### 4. Idle Resource Cleanup

**Savings:** Varies (often $100+/month)

**Targets:**
- Unattached EBS volumes ($0.10/GB-month)
- Old EBS snapshots >30 days ($0.05/GB-month)
- Unused Elastic IPs ($0.005/hour = $3.60/month each)
- Test databases not deleted

**Automation Tool:**

```bash
# Use cloud-nuke to clean up test resources
make cleanup-test-resources

# Or manually
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' \
  --output table

# Delete unattached volumes (after verification!)
aws ec2 delete-volume --volume-id vol-0abc123def456
```

---

## Emergency Cost Control Procedures

### When to Trigger Emergency Shutdown

**Indicators:**
- Budget exceeded by >200% within 24 hours
- Unexpected resources created (e.g., crypto mining attack)
- Cost increasing >$50/hour with no known cause
- Unauthorized EC2 instances detected

### Emergency Shutdown Workflow

See `SOP_EMERGENCY_SHUTDOWN_PROCEDURE.md` for full details.

**Quick Steps:**

1. **Assess situation:**
   ```bash
   # Check cost over last 24 hours
   aws ce get-cost-and-usage \
     --time-period Start=$(date -d '1 day ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
     --granularity HOURLY \
     --metrics BlendedCost
   ```

2. **Notify team:**
   ```
   🚨 EMERGENCY COST ALERT
   - Current hourly rate: $75/hour (expected: $20/hour)
   - Triggering emergency shutdown for dev environment
   - Investigating root cause
   ```

3. **Run emergency shutdown:**
   ```bash
   gh workflow run emergency-shutdown.yml -f environment=dev
   ```

4. **Verify shutdown:**
   ```bash
   # Check ECS services scaled to 0
   aws ecs describe-services \
     --cluster lightwave-dev \
     --services backend-dev

   # Check RDS stopped
   aws rds describe-db-instances \
     --db-instance-identifier dev-postgres
   ```

5. **Investigate root cause:**
   ```bash
   # Review CloudTrail for unauthorized actions
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
     --max-results 50
   ```

6. **Document incident**

### Post-Shutdown Recovery

After emergency shutdown, restart only necessary resources:

```bash
# Restart ECS service
aws ecs update-service \
  --cluster lightwave-dev \
  --service backend-dev \
  --desired-count 1

# Start RDS
aws rds start-db-instance \
  --db-instance-identifier dev-postgres

# Monitor costs for 24 hours
```

---

## Cost Reporting Dashboard

### Create Saved Cost Explorer Reports

**1. Monthly Cost by Environment**
- Navigate to: Cost Explorer
- Group by: Tag (Environment)
- Granularity: Monthly
- Chart type: Bar chart
- Save as: "Monthly Cost by Environment"

**2. Daily Cost Trend (Last 30 Days)**
- Granularity: Daily
- Chart type: Line chart
- Use for: Anomaly detection
- Save as: "Daily Cost Trend"

**3. Top Services by Cost**
- Group by: Service
- Sort: Cost (descending)
- Show: Top 10 services
- Save as: "Top Cost Drivers"

**4. Reserved Instance Coverage**
- Navigate to: Cost Management > RI Reports
- View: RI Coverage
- Identify: Opportunities for RIs
- Target: >80% coverage

### CloudWatch Dashboard

Create custom dashboard for real-time monitoring:

```bash
cat > cloudwatch-cost-dashboard.json <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          [ "AWS/Billing", "EstimatedCharges", { "stat": "Maximum" } ]
        ],
        "period": 21600,
        "stat": "Maximum",
        "region": "us-east-1",
        "title": "Estimated Monthly Charges"
      }
    }
  ]
}
EOF

aws cloudwatch put-dashboard \
  --dashboard-name LightWaveCosts \
  --dashboard-body file://cloudwatch-cost-dashboard.json
```

---

## Troubleshooting Cost Issues

### Issue: Unexpected RDS Costs

**Investigation:**

1. **Check for manual snapshots:**
   ```bash
   aws rds describe-db-snapshots \
     --snapshot-type manual \
     --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime,AllocatedStorage]' \
     --output table
   ```

2. **Check for stopped instances (still charged for storage):**
   ```bash
   aws rds describe-db-instances \
     --query 'DBInstances[?DBInstanceStatus==`stopped`]'
   ```

3. **Verify Multi-AZ is intentional:**
   ```bash
   aws rds describe-db-instances \
     --query 'DBInstances[*].[DBInstanceIdentifier,MultiAZ]'
   ```

**Resolution:**
- Delete old manual snapshots (keep automated snapshots)
- Terminate stopped instances if not needed
- Disable Multi-AZ in non-prod environments

### Issue: High Data Transfer Costs

**Investigation:**

1. **Check S3 Data Transfer Out:**
   - Cost Explorer > Service: S3
   - Usage type filter: DataTransfer-Out

2. **Check CloudFront usage:**
   ```bash
   aws cloudfront get-distribution-config \
     --id E1234567890ABC
   ```

3. **Review VPC Flow Logs for unusual traffic:**
   ```bash
   aws ec2 describe-flow-logs
   ```

**Resolution:**
- Enable CloudFront for S3 content (reduces data transfer)
- Check for data scraping or DDoS
- Implement rate limiting

### Issue: Idle Load Balancer Costs

**Investigation:**

1. **List all load balancers:**
   ```bash
   aws elbv2 describe-load-balancers \
     --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State]' \
     --output table
   ```

2. **Check target health:**
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn <target-group-arn>
   ```

**Resolution:**
- Delete unused load balancers ($16/month each)
- Consolidate services under fewer load balancers
- Use NLB instead of ALB if HTTP features not needed ($6/month difference)

---

## Cost Savings Checklist

### Daily
- [ ] Monitor budget alerts in Slack
- [ ] Review any unusual spend notifications

### Weekly
- [ ] Check Cost Explorer for anomalies
- [ ] Review ECS task counts (right-sized?)
- [ ] Check for idle resources (stopped instances, unattached volumes)

### Monthly
- [ ] Conduct cost review meeting
- [ ] Review RI/Savings Plan coverage
- [ ] Analyze top cost drivers
- [ ] Create optimization tasks
- [ ] Update budget forecasts

### Quarterly
- [ ] Review Reserved Instance needs
- [ ] Audit all resources for utilization
- [ ] Update cost allocation tags
- [ ] Review and renew Savings Plans

---

## Best Practices

### 1. Tag Everything

Use consistent tags on all resources for cost allocation:
```hcl
tags = {
  Environment = "prod"
  ManagedBy   = "Terragrunt"
  Owner       = "Platform Team"
  CostCenter  = "Engineering"
  Project     = "LightWave Media"
}
```

### 2. Right-Size Resources

Don't over-provision:
- Start with smaller instance types (t3.micro, t3.small)
- Scale up based on actual usage
- Use auto-scaling for variable workloads

### 3. Use Spot Instances for Non-Critical Workloads

Save up to 90% on compute for:
- CI/CD runners
- Batch processing
- Dev/test environments

### 4. Enable Cost Allocation Tags

```bash
# Activate cost allocation tags
aws ce activate-cost-allocation-tags \
  --tag-keys Environment ManagedBy Owner CostCenter Project
```

### 5. Set Up Billing Alerts

Don't rely on budgets alone:
```bash
# Create SNS topic for billing alerts
aws sns create-topic --name billing-alerts

# Subscribe email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:billing-alerts \
  --protocol email \
  --notification-endpoint team@lightwave-media.ltd
```

---

## Related Documents

- Emergency Shutdown: `SOP_EMERGENCY_SHUTDOWN_PROCEDURE.md`
- Infrastructure Deployment: `SOP_INFRASTRUCTURE_DEPLOYMENT.md`
- Root Terragrunt: `Infrastructure/lightwave-infrastructure-live/root.hcl`

---

**Revision History:**
- 2025-10-28: Initial version (1.0.0)
