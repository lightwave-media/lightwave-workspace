# Security & Infrastructure Incident Documentation

This directory contains documentation for security incidents, infrastructure failures, and other critical operational events.

## Purpose

Incident documentation serves multiple purposes:
- **Post-mortem analysis**: Learn from failures to prevent recurrence
- **Compliance**: Maintain audit trail for security events
- **Knowledge sharing**: Help team members understand past issues
- **Process improvement**: Identify gaps in procedures and automation

## When to Create an Incident File

Create an incident file for:

1. **Security Incidents**
   - Credential leaks or compromises
   - Unauthorized access attempts
   - Data breaches or exposure
   - Secret rotation emergencies
   - IAM policy violations

2. **Infrastructure Failures**
   - Complete infrastructure destruction
   - Region-wide outages requiring DR activation
   - Data loss requiring restoration from backups
   - State file corruption or loss
   - Production deployment failures with significant impact

3. **Operational Incidents**
   - Service outages > 30 minutes
   - Data corruption events
   - Failed disaster recovery tests
   - Critical misconfigurations

## Incident File Naming Convention

```
incident-YYYY-MM-DD-brief-description.md
```

### Examples

- `incident-2025-10-28-database-password-leaked.md`
- `incident-2025-11-15-prod-rds-failure.md`
- `incident-2025-12-01-state-lock-corruption.md`

## Incident Documentation Template

Use this template for all incidents:

```markdown
# Incident: [Brief Title]

**Date:** YYYY-MM-DD  
**Severity:** [P1-Critical | P2-High | P3-Medium | P4-Low]  
**Status:** [Investigating | Resolved | Mitigated]  
**Incident Commander:** @username  
**Duration:** XX minutes/hours  
**Impact:** [Description of services/users affected]

---

## Summary

One-paragraph summary of what happened, the impact, and the resolution.

---

## Timeline

- **HH:MM UTC** - Incident detected (describe how)
- **HH:MM UTC** - Team assembled, incident declared
- **HH:MM UTC** - Root cause identified
- **HH:MM UTC** - Mitigation started
- **HH:MM UTC** - Service restored
- **HH:MM UTC** - Incident resolved

---

## Impact Assessment

### Services Affected
- Service 1: [impact description]
- Service 2: [impact description]

### Users Affected
- Number of users: X
- Geographic regions: [list]
- Duration of impact: XX minutes

### Data Impact
- Data loss: [Yes/No - describe if yes]
- Data corruption: [Yes/No - describe if yes]
- Backup status: [describe]

---

## Root Cause Analysis

### What Happened
[Detailed technical description of the incident]

### Why It Happened
[Underlying causes - technical, process, or human factors]

### Contributing Factors
- Factor 1
- Factor 2
- Factor 3

---

## Resolution Steps

### Immediate Actions (< 5 minutes)
1. Step 1
2. Step 2
3. Step 3

### Mitigation Actions (< 30 minutes)
1. Step 1
2. Step 2

### Recovery Actions (< 2 hours)
1. Step 1
2. Step 2

### Verification
- [ ] Service health checks passing
- [ ] No active errors in logs
- [ ] User reports confirm resolution
- [ ] Monitoring shows normal metrics

---

## What Went Well

- Thing 1
- Thing 2
- Thing 3

---

## What Didn't Go Well

- Issue 1
- Issue 2
- Issue 3

---

## Action Items

### Immediate (Complete within 1 week)
- [ ] [TASK-XXX] Action item 1 - @owner
- [ ] [TASK-XXX] Action item 2 - @owner

### Short-term (Complete within 1 month)
- [ ] [TASK-XXX] Action item 3 - @owner
- [ ] [TASK-XXX] Action item 4 - @owner

### Long-term (Backlog)
- [ ] [TASK-XXX] Action item 5 - @owner

---

## Lessons Learned

### Technical Lessons
1. Lesson 1
2. Lesson 2

### Process Lessons
1. Lesson 1
2. Lesson 2

### Communication Lessons
1. Lesson 1
2. Lesson 2

---

## Related Documentation

- [SOP: Disaster Recovery](../../.agent/sops/SOP_DISASTER_RECOVERY.md)
- [SOP: Secrets Management](../../.agent/sops/SOP_SECRETS_MANAGEMENT.md)
- Related incidents: [list if applicable]

---

## Appendix

### Commands Executed
```bash
# List important commands run during incident
```

### Log Excerpts
```
# Relevant log entries
```

### Metrics/Graphs
- Links to CloudWatch dashboards
- Screenshots of metrics during incident
```

---

## Severity Levels

### P1 - Critical
- Complete service outage
- Security breach with data exposure
- Data loss affecting users
- Revenue-impacting issues

### P2 - High
- Partial service degradation
- Security incident with no data exposure
- Infrastructure failure with working failover
- Performance issues affecting majority of users

### P3 - Medium
- Minor service degradation
- Security incident contained to non-production
- Failed deployment (rolled back successfully)
- Infrastructure issues affecting non-critical services

### P4 - Low
- No user impact
- Security scan findings
- Test environment issues
- Documentation-only changes needed

---

## Best Practices

1. **Document while fresh**: Write the incident report within 24 hours
2. **Be specific**: Include exact commands, timestamps, error messages
3. **No blame**: Focus on process improvement, not individuals
4. **Actionable items**: Every incident should result in improvements
5. **Follow up**: Verify action items are completed
6. **Share learnings**: Present to team in post-mortem meeting

---

## Example Incidents

See these example incident reports for reference:

- [incident-2025-10-28-example-database-failure.md](./incident-2025-10-28-example-database-failure.md) *(to be created)*

---

Last Updated: 2025-10-28
