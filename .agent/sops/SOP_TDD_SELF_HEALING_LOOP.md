# SOP: Self-Healing TDD Loop

**Version**: 1.0.0
**Created**: 2025-10-28
**Owner**: Joel Schaeffer
**Status**: Active

---

## Overview

The **Self-Healing TDD Loop** is an AI-driven continuous testing system that automatically:

1. ✅ **Runs tests** on every push/PR
2. 🔍 **Detects failures** and extracts details
3. 📋 **Creates GitHub issues** with failure context
4. 🤖 **Tags @claude** to trigger AI fixes
5. 🔧 **AI implements fixes** based on test expectations
6. ✅ **Verifies fixes** and closes issues
7. 📈 **Improves test quality** over time

**This enables TRUE test-driven development where tests lead and AI follows.**

---

## The Loop Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SELF-HEALING TDD LOOP                    │
└─────────────────────────────────────────────────────────────┘

1. CODE PUSH
   ↓
2. TESTS RUN (pytest/vitest/terragrunt validate)
   ↓
3. FAILURE DETECTED?
   ├─ NO → ✅ Deploy to environment
   └─ YES → Continue to step 4
   ↓
4. PARSE FAILURE DETAILS
   - Extract test name, file, line, error message
   - Generate failure report
   ↓
5. CREATE GITHUB ISSUE
   - Title: "🔴 Auto-Healing: Test Failures in {branch}"
   - Body: Failure details + @claude tag
   - Labels: auto-healing, bug, tdd
   ↓
6. CREATE TASK CONTEXT (.agent/tasks/fix-*.yaml)
   - Structured YAML with failure details
   - Acceptance criteria
   - Related docs
   ↓
7. @CLAUDE TRIGGERED
   - AI reads issue
   - Loads .agent/tasks/ context
   - Reads failing test to understand expected behavior
   ↓
8. AI IMPLEMENTS FIX
   - Writes code to pass tests
   - Runs tests locally
   - Creates PR with fixes
   ↓
9. HEALING VERIFICATION
   - PR triggers full test suite
   - If pass → Comment ✅ + close issue
   - If fail → Comment ❌ + @claude retry
   ↓
10. MERGE TO DEV
    ↓
11. TESTS RUN AGAIN (continuous validation)
    ↓
LOOP BACK TO STEP 2
```

---

## How It Works

### 1. Test Execution (`.github/workflows/self-healing-tdd-loop.yml`)

The workflow runs on:
- **Every push** to `dev` or `prod`
- **Every PR** to `dev` or `prod`
- **Every 6 hours** (scheduled health check)

It auto-detects project type:
- **TypeScript**: Runs `bun test` + coverage via Vitest
- **Python**: Runs `pytest` + coverage
- **Terraform**: Runs `terragrunt validate` + `plan`

### 2. Failure Detection

When tests fail:
```json
{
  "tests": [
    {
      "fullName": "User Authentication > should issue JWT on login",
      "status": "failed",
      "location": {
        "file": "backend/apps/auth/tests/test_login.py",
        "line": 45
      },
      "failureMessages": [
        "AssertionError: Expected token to be present, got None"
      ]
    }
  ]
}
```

The workflow parses this and creates a human-readable report.

### 3. Issue Creation

**If no existing `auto-healing` issue exists**, creates new issue:

```markdown
## 🔴 Test Failures Detected

**Repository**: kiwi-dev-la/Lightwave-Platform
**Branch**: dev
**Commit**: a1b2c3d
**Workflow Run**: [link]

---

## Failed Tests

**Test**: User Authentication > should issue JWT on login
**File**: backend/apps/auth/tests/test_login.py:45
**Error**: AssertionError: Expected token to be present, got None

---

## Context for AI

**Task Context**: See `.agent/tasks/fix-test-failures-12345.yaml`

---

@claude Please fix these test failures and create a PR.
```

**If issue already exists**, adds a comment with new failures.

### 4. Task Context Creation

Creates structured YAML in `.agent/tasks/`:

```yaml
id: fix-test-failures-12345
title: "Fix test failures in dev"
type: bug-fix
priority: high
auto_generated: true
github_issue: "kiwi-dev-la/Lightwave-Platform#89"

test_failures: |
  **Test**: User Authentication > should issue JWT on login
  **File**: backend/apps/auth/tests/test_login.py:45
  **Error**: AssertionError: Expected token to be present, got None

acceptance_criteria:
  - All failing tests pass
  - No new test failures introduced
  - Coverage remains >= 80%

implementation_approach:
  - Read test expectations from test files
  - Understand what behavior is expected
  - Fix implementation to match test expectations

related_docs:
  - .agent/sops/SOP_TDD_WORKFLOW.md
  - .agent/sops/SOP_DEBUGGING.md
```

This file is **committed and pushed** so it's available in the repo.

### 5. @claude Responds

When @claude sees the tag:

1. **Reads the issue** to understand failures
2. **Loads task context** from `.agent/tasks/fix-*.yaml`
3. **Reads the failing test** to understand expected behavior:
   ```python
   def test_login_issues_jwt():
       response = client.post('/api/auth/login', json={
           'email': 'test@example.com',
           'password': 'password123'
       })
       assert response.status_code == 200
       assert 'token' in response.json()  # ← Test expects token in response
   ```
4. **Analyzes implementation** to find bug
5. **Writes fix** to make test pass
6. **Runs tests locally** to verify
7. **Creates PR** with clear description

### 6. Healing Verification

When @claude's PR is created:

1. **`verify-healing` job runs**
2. **Full test suite executes** on PR branch
3. **If tests pass**:
   - ✅ Comment on PR: "Healing Verification Passed"
   - Close the auto-healing issue
4. **If tests still fail**:
   - ❌ Comment on PR: "Still failing, please retry"
   - @claude sees comment and updates fix

### 7. Test Quality Improvement (Scheduled)

Every 6 hours, the `improve-test-quality` job:

1. **Analyzes coverage** across codebase
2. **Finds files < 80% coverage**
3. **Creates issue** asking @claude to write tests:
   ```markdown
   ## 📈 Improve Test Coverage (Currently 65%)

   ### Files Needing Tests
   - backend/apps/auth/services.py: 45% coverage
   - backend/apps/billing/models.py: 60% coverage

   @claude Please create comprehensive tests for these files.
   ```

---

## Key Benefits

### 1. Tests Drive Development (TRUE TDD)

Traditional: Write code → Write tests → Fix bugs

**Self-Healing Loop**: Write tests → AI writes code to pass tests → Deploy

### 2. Continuous Health Monitoring

Every 6 hours, tests run automatically. If something breaks:
- Issue created immediately
- @claude investigates
- Fix PR created within minutes
- No human intervention needed for simple bugs

### 3. Test Quality Improves Over Time

The system actively seeks untested code and creates issues to add tests. Over time, coverage approaches 100%.

### 4. No Context Loss

Failures are captured with full context:
- Exact file and line number
- Error message
- Git commit
- Workflow run link
- Generated task YAML

@claude has EVERYTHING needed to fix the issue.

### 5. Verification Before Merge

All fixes must pass the FULL test suite before merging. No regressions allowed.

---

## Repository Setup

To enable self-healing in a repo:

### Step 1: Add Workflow

```bash
# Copy workflow to repo
cp /Users/joelschaeffer/dev/lightwave-workspace/.github/workflows/self-healing-tdd-loop.yml \
   /Users/joelschaeffer/dev/lightwave-workspace/Backend/{your-repo}/.github/workflows/

# Commit and push
cd /Users/joelschaeffer/dev/lightwave-workspace/Backend/{your-repo}
git add .github/workflows/self-healing-tdd-loop.yml
git commit -m "feat: add self-healing TDD loop"
git push
```

### Step 2: Ensure Tests Exist

The repo must have a test suite:

**Python (Django)**:
```bash
pytest  # Must be runnable
pytest --cov  # Must have coverage configured
```

**TypeScript (Next.js)**:
```bash
bun test  # Must be runnable
bun run test:coverage  # Must have coverage configured
```

### Step 3: Add SOPs to `.agent/`

Create these files in `.agent/sops/`:
- `SOP_TDD_WORKFLOW.md` (this file)
- `SOP_DEBUGGING.md`
- `SOP_WRITING_TESTS.md`

These guide @claude on how to fix issues.

### Step 4: Test the Loop

1. **Intentionally break a test**:
   ```python
   def test_example():
       assert 1 == 2  # This will fail
   ```

2. **Push to dev**:
   ```bash
   git add .
   git commit -m "test: intentionally break test to verify healing loop"
   git push origin dev
   ```

3. **Watch for issue creation**:
   - Go to repo's Issues tab
   - Within ~5 minutes, issue should appear with title "🔴 Auto-Healing: Test Failures in dev"
   - Issue should have `@claude` tag

4. **@claude should respond**:
   - Within minutes, @claude analyzes issue
   - Creates PR with fix
   - PR shows passing tests

5. **Merge PR**:
   - Tests pass in PR
   - Merge to dev
   - Issue automatically closes

---

## Writing Tests That Enable Self-Healing

### Good Test (Clear Expectations)

```python
def test_user_can_login_with_valid_credentials():
    """
    GIVEN a user with email and password
    WHEN they POST to /api/auth/login with valid credentials
    THEN they receive a 200 status and JWT token in response
    """
    response = client.post('/api/auth/login', json={
        'email': 'test@example.com',
        'password': 'correct_password'
    })

    assert response.status_code == 200
    assert 'token' in response.json()
    assert len(response.json()['token']) > 0
```

**Why this is good**:
- ✅ Clear docstring explains WHAT should happen
- ✅ Specific assertions (status, token presence, token length)
- ✅ @claude can read this and understand expected behavior

### Bad Test (Vague)

```python
def test_login():
    result = do_login()
    assert result
```

**Why this is bad**:
- ❌ No context on what "result" should be
- ❌ No docstring explaining expectations
- ❌ @claude can't understand what behavior to implement

### Test Naming Convention

Use descriptive names that explain the scenario:

```python
# Good
def test_login_returns_jwt_when_credentials_are_valid()
def test_login_returns_401_when_password_is_wrong()
def test_login_returns_400_when_email_is_missing()

# Bad
def test_login()
def test_login_2()
def test_auth()
```

---

## Monitoring the Loop

### GitHub Actions Dashboard

View all workflow runs:
```
https://github.com/kiwi-dev-la/{repo}/actions
```

Filter by workflow:
- Select "Self-Healing TDD Loop"
- See success/failure rate
- View test results artifacts

### Open Issues

View auto-healing issues:
```bash
gh issue list --label "auto-healing" --state open
```

### Closed Issues (Fixed)

View fixed issues:
```bash
gh issue list --label "auto-healing" --state closed
```

---

## Troubleshooting

### Issue: Tests fail but no issue created

**Diagnosis**: Workflow may not have `issues: write` permission

**Fix**: Add to workflow:
```yaml
permissions:
  contents: write
  issues: write
  pull-requests: write
```

### Issue: @claude doesn't respond to tag

**Diagnosis**: GitHub App not installed or wrong permissions

**Fix**:
```bash
# Verify app is installed
gh api /repos/kiwi-dev-la/{repo}/installation

# Reinstall if needed
/install-github-app
```

### Issue: AI creates PR but tests still fail

**Diagnosis**: Test expectations unclear or AI misunderstood

**Fix**:
1. Review the test - is it clear what should happen?
2. Add docstring to test explaining expected behavior
3. Comment on PR: "@claude The test expects X, please try again"

### Issue: Workflow runs too often (cost concerns)

**Diagnosis**: Scheduled runs every 6 hours may be excessive

**Fix**: Adjust cron schedule:
```yaml
schedule:
  - cron: '0 0 * * *'  # Daily at midnight instead
```

---

## Cost Estimates

### GitHub Actions Minutes

**Per workflow run** (~5 minutes):
- Run tests: 2 min
- Parse failures: 1 min
- Create issue: 1 min
- Create task context: 1 min

**Monthly usage**:
- Push to dev: ~20 runs/month
- PRs: ~10 runs/month
- Scheduled: 120 runs/month (every 6 hours)
- **Total**: ~150 runs × 5 min = 750 minutes/month

**Cost**: $0 (included in free tier: 2000 min/month for private repos)

### Claude API Usage (@claude fixes)

**Per fix** (~50K tokens):
- Read issue + context: 5K tokens
- Analyze code: 10K tokens
- Generate fix: 10K tokens
- Create PR description: 5K tokens

**Monthly usage** (estimate 20 fixes):
- 20 fixes × 50K tokens = 1M tokens
- **Cost**: ~$15/month (Claude Sonnet API pricing)

---

## Success Metrics

Track these to measure loop effectiveness:

1. **Mean Time To Fix (MTTF)**:
   - Time from test failure → PR created by @claude
   - Target: < 30 minutes

2. **Fix Success Rate**:
   - % of @claude PRs that pass tests on first try
   - Target: > 80%

3. **Test Coverage**:
   - % of code covered by tests
   - Target: > 80% (improves over time via `improve-test-quality` job)

4. **Failure Recurrence**:
   - % of tests that fail multiple times
   - Target: < 10% (tests should stabilize)

5. **Human Intervention Rate**:
   - % of issues requiring human to fix (not @claude)
   - Target: < 20%

---

## Future Enhancements

### Phase 2: Multi-Repo Healing

When a backend test fails due to breaking API change:
1. Detect frontend repos that consume that API
2. Create issues in frontend repos
3. @claude updates frontend code to match new API

### Phase 3: Performance Regression Detection

Add performance testing:
```yaml
- name: Detect Performance Regressions
  run: |
    # Run performance tests
    # Compare to baseline
    # Create issue if > 20% slower
```

### Phase 4: Security Vulnerability Healing

Integrate with `npm audit` / `pip-audit`:
```yaml
- name: Detect Security Issues
  run: |
    npm audit --json > audit-results.json
    # Parse vulnerabilities
    # Create healing issues for each CVE
    # @claude updates dependencies
```

---

## Related Documentation

- `.agent/sops/SOP_DEBUGGING.md` - How to debug test failures
- `.agent/sops/SOP_WRITING_TESTS.md` - How to write good tests
- `.claude/workflows/AGENT_PLAYBOOK.md` - Agent workflows
- `lightwave-pipelines-workflows/README.md` - Centralized workflows

---

**Status**: ✅ Active
**Next Review**: 2025-11-28
**Maintainer**: Joel Schaeffer + @claude
