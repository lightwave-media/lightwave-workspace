# SOP: Multi-Repository Operations with git-xargs

**Purpose**: Standard procedures for automating changes across multiple LightWave repositories
**Tool**: git-xargs (Gruntwork)
**Last Updated**: 2025-10-25
**Version**: 1.0.0

---

## Overview

git-xargs enables batch operations across multiple GitHub repositories, automating:
- Workflow updates
- Dependency updates
- Configuration changes
- Documentation sync
- Security patches

**Core Principle**: Make the same change once, apply everywhere automatically.

---

## Prerequisites

### Installation

```bash
# Install git-xargs
brew install git-xargs

# Verify installation
git-xargs --version
```

### GitHub Token Setup

```bash
# Create token: https://github.com/settings/tokens/new
# Required scopes:
# - repo (full control)
# - workflow (update workflows)
# - admin:org (if managing org-level settings)

# Export token
export GITHUB_TOKEN=ghp_your_token_here

# Verify access
gh auth status
```

### Repository List

LightWave has 8 repositories in `kiwi-dev-la` organization:

**Backend**:
- `Lightwave-Platform`

**Frontend**:
- `lightwave-cineos` (cineos.io)
- `lightwave-createos` (createos.io)
- `lightwave-photographos` (photographyos.io)
- `lightwave-joelschaeffer` (joelschaeffer.com)
- `lightwave-media-site` (lightwave-media.site)

**Infrastructure**:
- `lightwave-infrastructure` (Terraform modules)
- `lightwave-infrastructure-live` (Terragrunt configs)

---

## Common Operations

### 1. Update GitHub Actions Workflows

**Scenario**: Sync workflow templates from central `lightwave-pipelines-workflows` repo.

**Script**: `scripts/sync-workflow-templates.sh`
```bash
#!/bin/bash
# Sync CI/CD workflow template

WORKFLOW_URL="https://raw.githubusercontent.com/kiwi-dev-la/lightwave-pipelines-workflows/main/templates/ci-cd.yml"

# Download latest template
curl -s $WORKFLOW_URL -o .github/workflows/ci-cd.yml

# Stage changes
git add .github/workflows/ci-cd.yml
```

**Execute**:
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos Lightwave-Platform,lightwave-cineos,lightwave-createos \
  --branch-name chore/update-workflows-$(date +%Y%m%d) \
  --commit-message "chore(ci): sync workflow template from central repo" \
  --draft \
  bash scripts/sync-workflow-templates.sh
```

**Result**: Opens draft PRs in 3 repos with updated workflow files.

---

### 2. Update Dependencies

**Scenario**: Update Python dependencies across backend repos.

**Script**: `scripts/update-python-deps.sh`
```bash
#!/bin/bash
# Update Python dependencies

if [ ! -f "requirements.txt" ]; then
  echo "No requirements.txt found, skipping"
  exit 0
fi

# Update dependencies
uv pip compile requirements.in --upgrade > requirements.txt

# Stage changes
git add requirements.txt
```

**Execute**:
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos Lightwave-Platform \
  --branch-name deps/python-update-$(date +%Y%m%d) \
  --commit-message "chore(deps): update Python dependencies" \
  bash scripts/update-python-deps.sh
```

**For Frontend (Node.js)**:
```bash
#!/bin/bash
# scripts/update-node-deps.sh

if [ ! -f "package.json" ]; then
  exit 0
fi

# Update dependencies
bun update

# Stage changes
git add package.json bun.lockb
```

---

### 3. Add New Secret to All Repos

**Scenario**: Add organization-level secret (preferred) or per-repo secret.

**Org-Level** (Recommended):
```bash
# Add secret at org level (accessible by all repos)
gh secret set NEW_SECRET_NAME \
  --body "secret_value_here" \
  --org kiwi-dev-la \
  --visibility all
```

**Per-Repo** (if needed):
```bash
# Script: scripts/add-secret.sh
#!/bin/bash
SECRET_NAME="NEW_SECRET_NAME"
SECRET_VALUE="secret_value_here"

# Get repo name from git remote
REPO=$(git remote get-url origin | sed 's/.*://;s/.git$//')

# Add secret
gh secret set $SECRET_NAME -b"$SECRET_VALUE" -R kiwi-dev-la/$REPO
```

**Execute**:
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos Lightwave-Platform,lightwave-cineos \
  bash scripts/add-secret.sh
```

---

### 4. Update Documentation

**Scenario**: Add standardized README section to all repos.

**Script**: `scripts/add-readme-section.sh`
```bash
#!/bin/bash
# Add "Development Workflow" section to README

if [ ! -f "README.md" ]; then
  echo "No README.md found, skipping"
  exit 0
fi

# Check if section already exists
if grep -q "## Development Workflow" README.md; then
  echo "Section already exists, skipping"
  exit 0
fi

# Append section
cat >> README.md <<'EOF'

---

## Development Workflow

1. **Read** `.claude/ONBOARDING.md` for prerequisites
2. **Create branch**: `git checkout -b feature/task-name`
3. **Make changes** with tests
4. **Run checks**: `make test lint`
5. **Open PR** with conventional commit message
6. **CI/CD**: Auto-deploy to dev on merge

See [workspace CLAUDE.md](../../CLAUDE.md) for detailed workflows.
EOF

git add README.md
```

**Execute**:
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos Lightwave-Platform,lightwave-cineos,lightwave-createos,lightwave-photographos \
  --branch-name docs/add-dev-workflow \
  --commit-message "docs: add Development Workflow section to README" \
  --draft \
  bash scripts/add-readme-section.sh
```

---

### 5. Security Patch Rollout

**Scenario**: Critical security update needed across all repos.

**Script**: `scripts/security-patch.sh`
```bash
#!/bin/bash
# Apply security patch

# Python repos
if [ -f "requirements.txt" ]; then
  # Update vulnerable package
  sed -i '' 's/vulnerable-package==1.0.0/vulnerable-package==1.0.1/g' requirements.txt
  git add requirements.txt
fi

# Node repos
if [ -f "package.json" ]; then
  # Update vulnerable package
  bun update vulnerable-package@latest
  git add package.json bun.lockb
fi
```

**Execute with urgency**:
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos Lightwave-Platform,lightwave-cineos,lightwave-createos,lightwave-photographos,lightwave-joelschaeffer,lightwave-media-site \
  --branch-name security/patch-cve-2025-1234 \
  --commit-message "security: patch CVE-2025-1234 in vulnerable-package" \
  --skip-pr-creation false \
  --reviewers joelschaeffer \
  bash scripts/security-patch.sh
```

**Note**: For critical security issues, skip `--draft` flag and add `--reviewers`.

---

## Advanced Usage

### Dry Run Mode

**Always test with dry-run first**:
```bash
git-xargs \
  --repos repo1,repo2 \
  --dry-run \
  bash scripts/my-script.sh
```

**What it does**:
- Clones repos locally
- Runs script
- Shows what would be committed
- **Does NOT** create branches or PRs

### Filtering Repositories

**By repo name pattern**:
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos-regex "^lightwave-" \
  bash scripts/my-script.sh
```

**By file existence**:
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos-with-file package.json \
  bash scripts/update-node-deps.sh
```

### Rate Limiting

**Avoid GitHub API rate limits**:
```bash
git-xargs \
  --repos repo1,repo2,repo3 \
  --seconds-between-prs 30 \
  bash scripts/my-script.sh
```

**Recommended**:
- `--seconds-between-prs 30` for 10+ repos
- `--seconds-between-prs 60` for 50+ repos

### Parallel Execution

**Speed up with concurrency** (use with caution):
```bash
git-xargs \
  --repos repo1,repo2,repo3 \
  --max-concurrent-repos 5 \
  bash scripts/my-script.sh
```

**Trade-offs**:
- ✅ Faster execution
- ⚠️ Higher API usage
- ⚠️ Harder to debug failures

### Skip PR Creation

**Run script without creating PRs** (for read-only operations):
```bash
git-xargs \
  --repos repo1,repo2 \
  --skip-pr-creation \
  bash scripts/audit-dependencies.sh
```

---

## Best Practices

### Script Design

**1. Idempotent Scripts**
```bash
# ✅ Good: Check if change already exists
if grep -q "pattern" file.txt; then
  echo "Already updated, skipping"
  exit 0
fi

# ❌ Bad: Always applies change (can break on re-run)
echo "new line" >> file.txt
```

**2. Error Handling**
```bash
#!/bin/bash
set -e  # Exit on error

# Check prerequisites
if [ ! -f "requirements.txt" ]; then
  echo "No requirements.txt found"
  exit 0  # Exit 0 = success (skip this repo)
fi

# Make changes
uv pip compile requirements.in > requirements.txt || {
  echo "Failed to compile requirements"
  exit 1  # Exit 1 = failure (will be reported)
}

git add requirements.txt
```

**3. Git Staging**
```bash
# ✅ Always stage specific files
git add file1.txt file2.txt

# ❌ Never use
git add .  # Too broad
git add -A  # Too broad
```

### Commit Messages

Follow **Conventional Commits**:
```
type(scope): subject

body (optional)

footer (optional)
```

**Examples**:
- `feat(ci): add automated deployment workflow`
- `fix(deps): update vulnerable package to v2.0.1`
- `chore(docs): sync README template`
- `security: patch CVE-2025-1234`

### PR Strategy

**Draft PRs** (for review before merge):
```bash
git-xargs \
  --draft \
  bash scripts/my-script.sh
```

**Auto-assign reviewers**:
```bash
git-xargs \
  --reviewers joelschaeffer,teammate \
  bash scripts/my-script.sh
```

**Add labels**:
```bash
git-xargs \
  --labels dependencies,automated \
  bash scripts/update-deps.sh
```

---

## Troubleshooting

### Issue: "Repository not found"

**Cause**: Missing permissions or repo doesn't exist.

**Fix**:
```bash
# Verify access
gh repo view kiwi-dev-la/repo-name

# Check GitHub token has correct scopes
gh auth status

# Refresh token if needed
gh auth refresh -s repo,workflow
```

### Issue: "API rate limit exceeded"

**Cause**: Too many API calls in short period.

**Fix**:
```bash
# Add delay between operations
git-xargs \
  --seconds-between-prs 60 \
  bash scripts/my-script.sh

# Check rate limit status
gh api rate_limit
```

### Issue: Script fails on some repos

**Cause**: Repos have different structures.

**Fix**: Add conditional logic to script.
```bash
#!/bin/bash
# Handle different repo types

if [ -f "requirements.txt" ]; then
  # Python repo
  uv pip compile requirements.in > requirements.txt
  git add requirements.txt
elif [ -f "package.json" ]; then
  # Node repo
  bun update
  git add package.json bun.lockb
else
  echo "Unknown repo type, skipping"
  exit 0
fi
```

### Issue: PR created but no changes

**Cause**: Script ran but didn't modify any files.

**Fix**: git-xargs automatically skips PRs with no changes. This is expected behavior.

### Issue: Merge conflicts in generated PRs

**Cause**: Base branch diverged since PR creation.

**Fix**:
```bash
# Update PRs with latest from main
gh pr checks PR_NUMBER --watch  # Wait for CI
gh pr merge PR_NUMBER --rebase  # Rebase and merge
```

---

## Common Recipes

### Recipe 1: Sync All Workflows
```bash
git-xargs \
  --github-org kiwi-dev-la \
  --repos Lightwave-Platform,lightwave-cineos,lightwave-createos,lightwave-photographos,lightwave-joelschaeffer,lightwave-media-site \
  --branch-name chore/sync-workflows-$(date +%Y%m%d) \
  --commit-message "chore(ci): sync workflow templates" \
  --draft \
  bash scripts/sync-workflow-templates.sh
```

### Recipe 2: Update All Dependencies
```bash
# Python
git-xargs \
  --github-org kiwi-dev-la \
  --repos-with-file requirements.txt \
  --branch-name deps/python-$(date +%Y%m%d) \
  --commit-message "chore(deps): update Python dependencies" \
  bash scripts/update-python-deps.sh

# Node
git-xargs \
  --github-org kiwi-dev-la \
  --repos-with-file package.json \
  --branch-name deps/node-$(date +%Y%m%d) \
  --commit-message "chore(deps): update Node dependencies" \
  bash scripts/update-node-deps.sh
```

### Recipe 3: Add .gitignore Entry
```bash
#!/bin/bash
# scripts/add-gitignore-entry.sh

ENTRY=".DS_Store"

if [ ! -f ".gitignore" ]; then
  echo "$ENTRY" > .gitignore
  git add .gitignore
  exit 0
fi

if grep -q "^$ENTRY$" .gitignore; then
  echo "Entry already exists"
  exit 0
fi

echo "$ENTRY" >> .gitignore
git add .gitignore
```

```bash
git-xargs \
  --github-org kiwi-dev-la \
  --branch-name chore/gitignore-ds-store \
  --commit-message "chore: add .DS_Store to .gitignore" \
  bash scripts/add-gitignore-entry.sh
```

### Recipe 4: Audit All Repos (No PRs)
```bash
#!/bin/bash
# scripts/audit-dependencies.sh

echo "=== Repo: $(basename $(pwd)) ==="

if [ -f "requirements.txt" ]; then
  echo "Python dependencies:"
  grep "==" requirements.txt | wc -l
fi

if [ -f "package.json" ]; then
  echo "Node dependencies:"
  jq '.dependencies | length' package.json
fi
```

```bash
git-xargs \
  --github-org kiwi-dev-la \
  --skip-pr-creation \
  bash scripts/audit-dependencies.sh > audit-report.txt
```

---

## Safety Checklist

Before running git-xargs on multiple repos:

- [ ] **Tested script locally** on one repo first
- [ ] **Ran with `--dry-run`** flag to preview changes
- [ ] **Script is idempotent** (safe to run multiple times)
- [ ] **Error handling** added (exit 0 for skip, exit 1 for fail)
- [ ] **Git staging** targets specific files (not `git add .`)
- [ ] **Commit message** follows conventional commits
- [ ] **Using `--draft`** flag for review (if not urgent)
- [ ] **Rate limiting** configured for 10+ repos (`--seconds-between-prs`)
- [ ] **GitHub token** has correct scopes (repo, workflow)

---

## Reference

### git-xargs CLI Flags

| Flag | Description | Example |
|------|-------------|---------|
| `--repos` | Comma-separated repo list | `--repos repo1,repo2` |
| `--github-org` | Target repos in org | `--github-org kiwi-dev-la` |
| `--branch-name` | PR branch name | `--branch-name feat/update` |
| `--commit-message` | Commit message | `--commit-message "feat: add X"` |
| `--dry-run` | Preview without PRs | `--dry-run` |
| `--draft` | Create draft PRs | `--draft` |
| `--reviewers` | Add PR reviewers | `--reviewers user1,user2` |
| `--labels` | Add PR labels | `--labels bug,urgent` |
| `--skip-pr-creation` | Run without PRs | `--skip-pr-creation` |
| `--seconds-between-prs` | Rate limit delay | `--seconds-between-prs 30` |
| `--max-concurrent-repos` | Parallel execution | `--max-concurrent-repos 5` |

### Exit Codes

- `0` = Success (or intentional skip)
- `1` = Failure (will be reported)
- `2+` = Custom error codes (treated as failure)

---

**Version**: 1.0.0
**Last Updated**: 2025-10-25
**Maintainer**: Joel Schaeffer
**Related**: `.agent/tasks/CICD_IMPLEMENTATION_PLAN_v1.0.0.md`
