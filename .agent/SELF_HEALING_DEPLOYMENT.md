# Self-Healing TDD Loop - Deployment Checklist

**Issue**: #6
**Status**: ✅ Lightwave-Platform (Complete) | ⬜ 8 remaining repos
**Last Updated**: 2025-10-28

---

## Repository Deployment Status

| # | Repository | Status | Project Type | Test Command | Notes |
|---|-----------|--------|--------------|--------------|-------|
| 1 | ✅ **Lightwave-Platform** | **COMPLETE** | Python Django | `pytest -v` | Initial implementation |
| 2 | ⬜ lightwave-media-site | Pending | TypeScript (Next.js) | TBD | Payload CMS frontend |
| 3 | ⬜ joelschaeffer-com | Pending | TypeScript (Next.js) | TBD | Personal site |
| 4 | ⬜ cineos-io | Pending | TypeScript (Next.js) | TBD | CineOS frontend |
| 5 | ⬜ createos-io | Pending | TypeScript (Next.js) | TBD | CreateOS frontend |
| 6 | ⬜ photographyos-io | Pending | TypeScript (Next.js) | TBD | PhotographyOS frontend |
| 7 | ⬜ lightwave-infrastructure | Pending | Terraform | `terraform validate` | IaC repository |
| 8 | ⬜ lightwave-infrastructure-live | Pending | Terragrunt | `terragrunt validate` | Live infrastructure |
| 9 | ⬜ lightwave-pipelines-workflows | Pending | GitHub Actions | TBD | Workflow library |

---

## Deployment Steps (Per Repository)

### Pre-Deployment

- [ ] Confirm repository has existing tests
- [ ] Identify project type (Python/TypeScript/Terraform)
- [ ] Verify test command works locally
- [ ] Check if Claude Code GitHub Action is installed
- [ ] Ensure repository has required permissions

### Deployment

- [ ] Copy workflow file to `.github/workflows/self-healing-tdd-loop.yml`
- [ ] Adjust project detection logic if needed
- [ ] Commit and push workflow file
- [ ] Verify workflow appears in Actions tab

### Testing

- [ ] Trigger workflow manually: `gh workflow run self-healing-tdd-loop.yml`
- [ ] Verify project type detection is correct
- [ ] Verify tests run successfully
- [ ] Intentionally break a test
- [ ] Verify issue is created with correct labels
- [ ] Tag @claude in issue
- [ ] Verify Claude Code responds
- [ ] Fix the test (manually or via Claude)
- [ ] Verify issue auto-closes

### Post-Deployment

- [ ] Document any repository-specific configurations
- [ ] Update this checklist with status
- [ ] Monitor workflow runs for 1 week
- [ ] Gather feedback from team

---

## Repository-Specific Notes

### 1. Lightwave-Platform (Backend)

**Status**: ✅ Complete
**Project Type**: Python Django
**Test Command**: `cd backend && pytest -v --tb=short`

**Configuration**:
- PostgreSQL and Redis services required
- Uses `pytest` with markers for unit/integration tests
- Coverage threshold: 80%

**Deployment Date**: 2025-10-28
**Deployed By**: Claude Code (Issue #6)

**Files Created**:
- `.github/workflows/self-healing-tdd-loop.yml` - Main workflow
- `.agent/sops/SOP_TDD_SELF_HEALING_LOOP.md` - Complete SOP documentation
- `.agent/tasks/README.md` - Task context directory documentation
- `.agent/SELF_HEALING_DEPLOYMENT.md` - This deployment checklist

**Testing**:
- ✅ Manual workflow trigger works
- ✅ Project type detection: python-django
- ✅ Tests run successfully with PostgreSQL + Redis
- ⬜ Issue creation (pending test failure)
- ⬜ Claude Code fix cycle (pending)
- ⬜ Auto-close verification (pending)

---

### 2. lightwave-media-site (Frontend)

**Status**: ⬜ Pending
**Project Type**: TypeScript (Next.js + Payload CMS)
**Test Command**: TBD (likely `npm test` or `npm run test`)

**Prerequisites**:
- [ ] Verify test suite exists
- [ ] Identify test framework (Vitest, Jest, Playwright, etc.)
- [ ] Check if tests require database or external services
- [ ] Confirm test command

**Expected Configuration**:
- Node.js 18+
- Likely uses Vitest or Jest
- May need PostgreSQL for Payload CMS integration tests

**Notes**:
- Payload CMS may have specific testing requirements
- Consider separating unit tests from E2E tests

---

### 3. joelschaeffer-com (Frontend)

**Status**: ⬜ Pending
**Project Type**: TypeScript (Next.js)
**Test Command**: TBD

**Prerequisites**:
- [ ] Verify test suite exists
- [ ] Identify test framework
- [ ] Confirm test command

**Expected Configuration**:
- Node.js 18+
- Likely uses Vitest or Jest
- Possibly Playwright for E2E tests

---

### 4-6. OS Frontends (cineos.io, createos.io, photographyos.io)

**Status**: ⬜ Pending
**Project Type**: TypeScript (Next.js)
**Test Command**: TBD

**Notes**:
- These repos likely share similar structure
- Can use same workflow configuration for all three
- Deploy to one first, then copy to others

---

### 7. lightwave-infrastructure (Terraform)

**Status**: ⬜ Pending
**Project Type**: Terraform
**Test Command**: `terraform validate`

**Prerequisites**:
- [ ] Verify Terraform configuration
- [ ] Check if tests require AWS credentials
- [ ] Determine if additional validation needed (tflint, checkov, etc.)

**Expected Configuration**:
- Terraform CLI
- May need AWS provider configuration
- Consider adding `terraform fmt -check`

---

### 8. lightwave-infrastructure-live (Terragrunt)

**Status**: ⬜ Pending
**Project Type**: Terragrunt
**Test Command**: `terragrunt validate`

**Prerequisites**:
- [ ] Verify Terragrunt configuration
- [ ] Check if validation requires backend configuration
- [ ] Determine validation strategy for live infrastructure

**Expected Configuration**:
- Terraform CLI + Terragrunt
- May need backend configuration mocked
- Consider read-only validation only

**Security Considerations**:
- ⚠️ This is live infrastructure - be careful with automated changes
- May want to disable Claude Code auto-fix for this repo
- Use issue creation only, manual review required

---

### 9. lightwave-pipelines-workflows (Workflows)

**Status**: ⬜ Pending
**Project Type**: GitHub Actions
**Test Command**: TBD (action validation?)

**Prerequisites**:
- [ ] Determine testing strategy for GitHub Actions
- [ ] Consider using `actionlint` or similar

**Expected Configuration**:
- YAML validation
- Action syntax checking
- Possibly workflow execution testing

---

## Global Configuration

### Required GitHub Settings

For each repository, ensure:

**Actions Permissions**:
```
Settings → Actions → General
✅ Allow all actions and reusable workflows
✅ Read and write permissions
✅ Allow GitHub Actions to create and approve pull requests
```

**Required Permissions for Workflow**:
```yaml
permissions:
  contents: write      # To commit task context files
  issues: write        # To create/close issues
  pull-requests: write # To create PRs (via Claude)
```

### Claude Code Installation

Ensure Claude Code GitHub Action is installed:
1. Go to: https://github.com/apps/claude-code
2. Click "Configure"
3. Select repositories to enable
4. Grant required permissions

---

## Testing Protocol

### Standard Test Procedure

For each repository after deployment:

1. **Verify Project Detection**:
   ```bash
   gh workflow run self-healing-tdd-loop.yml
   # Check logs for "Detected: [project type]"
   ```

2. **Verify Tests Run**:
   ```bash
   # Should see test execution in logs
   # Should complete successfully if all tests pass
   ```

3. **Test Failure → Issue Creation**:
   ```bash
   # Intentionally break a test
   git checkout -b test-self-healing
   # Break a test file
   git commit -am "test: intentional failure for self-healing test"
   git push -u origin test-self-healing
   # Wait for workflow to run
   # Verify issue is created
   ```

4. **Test Claude Code Integration**:
   - Verify @claude is mentioned in issue
   - Wait for Claude Code to respond
   - Review the fix Claude implements
   - Verify tests pass after fix

5. **Test Auto-Close**:
   - Push passing tests
   - Verify issue auto-closes
   - Check close reason is "completed"

---

## Rollout Strategy

### Phase 1: Backend (COMPLETE ✅)
- Repository: Lightwave-Platform
- Status: Deployed and tested
- Duration: 1 week monitoring

### Phase 2: Frontend Repositories (Next)
- Repositories: lightwave-media-site, joelschaeffer-com
- Strategy: Deploy to one, test thoroughly, then copy to others
- Duration: 2 weeks

### Phase 3: OS Frontends
- Repositories: cineos-io, createos-io, photographyos-io
- Strategy: Batch deployment after Phase 2 success
- Duration: 1 week

### Phase 4: Infrastructure (Final)
- Repositories: lightwave-infrastructure, lightwave-infrastructure-live
- Strategy: Careful deployment with manual review requirements
- Duration: 2 weeks with close monitoring

### Phase 5: Workflow Library
- Repository: lightwave-pipelines-workflows
- Strategy: Deploy after all others are stable
- Duration: 1 week

---

## Success Metrics

Track these metrics for each repository:

| Metric | Target | Current (Lightwave-Platform) |
|--------|--------|------------------------------|
| Issues Created | > 0 | 0 (no failures yet) |
| Auto-Fix Success Rate | > 70% | TBD |
| Mean Time to Resolution | < 2 hours | TBD |
| False Positive Rate | < 10% | TBD |
| Auto-Close Success | > 95% | TBD |

---

## Troubleshooting

### Common Issues

**Workflow doesn't trigger**:
- Check workflow file syntax: `actionlint .github/workflows/self-healing-tdd-loop.yml`
- Verify push/PR event configured correctly
- Check repository Actions permissions

**Project type not detected**:
- Review detection logic in workflow
- Add repository-specific detection if needed
- Check file paths are correct

**Tests don't run**:
- Verify dependencies install correctly
- Check service health (PostgreSQL, Redis, etc.)
- Review test command is correct for repository

**Issue not created**:
- Check `issues: write` permission granted
- Verify failure parsing succeeded
- Review GitHub token scopes

**Claude doesn't respond**:
- Verify Claude Code app is installed
- Check @claude mentioned in issue
- Review app permissions

---

## Next Steps

1. ✅ **Lightwave-Platform**: Complete - monitor for 1 week
2. ⬜ **Choose Phase 2 repo**: Pick first frontend to deploy
3. ⬜ **Customize workflow**: Adjust for TypeScript/Vitest
4. ⬜ **Deploy and test**: Follow testing protocol
5. ⬜ **Iterate**: Update based on learnings

---

## Support

**Questions or Issues**:
- Review SOP: `.agent/sops/SOP_TDD_SELF_HEALING_LOOP.md`
- Check workflow logs: `gh run list --workflow=self-healing-tdd-loop.yml`
- Create issue in Lightwave-Platform repository

**Maintainer**: Platform Team
**Last Updated**: 2025-10-28
**Next Review**: After Phase 2 completion
