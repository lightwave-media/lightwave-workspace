# Agent Tasks Directory

This directory contains auto-generated task context files for the self-healing TDD loop and other automated workflows.

## Purpose

Task context files provide structured information about issues that need to be resolved, including:
- Test failures and their stack traces
- Expected behavior and validation criteria
- Relevant resources and documentation
- Links to workflow runs and artifacts

## File Naming Convention

```
fix-test-failure-YYYYMMDD-HHMMSS.yaml
```

Example: `fix-test-failure-20251028-031145.yaml`

## File Structure

```yaml
---
task_id: fix-test-failure-20251028-031145
created_at: 2025-10-28T03:11:45Z
trigger: test_failure
workflow_run: 123456789
commit: abc123def456
branch: feature-branch
project_type: python-django

failure_context:
  failed_tests: |
    FAILED apps/products/tests/test_views.py::TestProductAPI::test_create_product

  failure_details: |
    [Stack trace and error messages]

  test_command: cd backend && pytest -v --tb=short

expected_behavior: |
  All tests should pass. Review failure details and implement fixes.

validation:
  - Run the test suite and verify all tests pass
  - Ensure code quality checks still pass
  - Review test coverage hasn't decreased

resources:
  - Test output: [Link to workflow run]
  - Repository guidelines: See CLAUDE.md files
```

## Usage

### For Automated Workflows

Task files are automatically created by the `self-healing-tdd-loop` workflow when tests fail.

### For Claude Code

When tagged in a GitHub issue, Claude Code will:
1. Read the referenced task context file
2. Analyze the failure details
3. Implement a fix following TDD principles
4. Verify all tests pass
5. Create a pull request with the fix

### For Manual Review

You can also read these files manually to understand:
- What tests are failing
- Why they're failing
- What context was available to the AI
- What fixes were attempted

## Lifecycle

1. **Created**: When tests fail in CI/CD
2. **Referenced**: In GitHub issues for tracking
3. **Resolved**: When tests pass and issue is closed
4. **Archived**: Periodically moved to historical archive (optional)

## Cleanup

Task files can be safely deleted once:
- The corresponding issue is closed
- All tests are passing
- The fix has been merged to the main branch

You may want to keep them for:
- Learning and analysis
- Pattern recognition
- Training data for improvements

## Related Files

- **Workflow**: `.github/workflows/self-healing-tdd-loop.yml`
- **SOP**: `.agent/sops/SOP_TDD_SELF_HEALING_LOOP.md`
- **Issues**: GitHub issues with `self-healing` label

## Example Task Context

See the SOP document for complete examples and best practices.

---

**Note**: This directory is auto-created by workflows. Do not manually create task files unless for testing purposes.
