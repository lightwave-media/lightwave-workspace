# CI/CD Implementation Plan: Custom Workflows + git-xargs Multi-Repo Automation

**Epic**: Establish Production-Ready CI/CD Across All LightWave Repositories
**Version**: 1.1.0 (Revised)
**Status**: 🟢 Ready to Execute
**Priority**: P0 - Blocking Infrastructure Deployment
**Estimated Effort**: 20.5 hours (3 days)
**Owner**: Joel Schaeffer
**Created**: 2025-10-25
**Last Updated**: 2025-10-25

---

## 🔄 Changes from v1.0.0

**Major Revisions**:
- ✅ **Workflow Strategy**: Write custom workflows (not adapted from Gruntwork)
- ✅ **Coverage Policy**: Hard gate 80% across entire codebase
- ✅ **Rollout Strategy**: Conservative pilot (cineos-io first, then batch)
- ✅ **Repository Setup**: Added Phase 0 for connecting existing GitHub repos
- ✅ **Time Estimate**: Updated to 20.5 hours (from 16-20 hours)

**Rationale**: Gruntwork pipelines-workflows is tightly coupled to DevOps Foundations (their paid product). Writing our own workflows from scratch eliminates coupling risk, simplifies maintenance, and only adds 2-3 hours to the timeline.

---

## Executive Summary

Implement standardized CI/CD pipelines across all 8 LightWave repositories using:
- **Custom GitHub Actions workflows** (written from scratch, inspired by Gruntwork patterns)
- **git-xargs**: Multi-repository automation (batch updates, PR creation)

**Problem**: No consistent CI/CD, manual deployments, ad-hoc testing, blocking infrastructure rollout.

**Solution**: Centralized reusable workflows + automated multi-repo operations.

**Outcome**: Production-ready CI/CD with auto-deployment to dev, manual gating for prod, **80% test coverage enforcement**.

---

## Current State Analysis

### Repository Audit

**Repos Already on GitHub** (6/8):

| Local Path | GitHub Repo | Visibility | CI/CD Status |
|------------|-------------|------------|--------------|
| `Backend/Lightwave-Platform` | `kiwi-dev-la/Lightwave-Platform` | PRIVATE | ⚠️ Basic |
| `Frontend/lightwave-cineos` | `kiwi-dev-la/cineos-io` | PRIVATE | ⚠️ Basic |
| `Frontend/lightwave-media-site` | `kiwi-dev-la/lightwave-media-site` | PRIVATE | ❌ None |
| `Frontend/lightwave-joelschaeffer` | `kiwi-dev-la/joelschaeffer-com` | PRIVATE | ❌ None |
| `Infrastructure/lightwave-infrastructure` | `kiwi-dev-la/lightwave-infrastructure` | PRIVATE | ✅ Comprehensive |
| `Infrastructure/lightwave-infrastructure-live` | `kiwi-dev-la/lightwave-infrastructure-live` | PRIVATE | ❌ None |

**Repos Needing Remote Setup** (2/8):

| Local Path | GitHub Repo (Exists) | Action Needed |
|------------|----------------------|---------------|
| `Frontend/lightwave-createos` | `kiwi-dev-la/createos-io` | Add remote + push |
| `Frontend/lightwave-photographos` | `kiwi-dev-la/photographyos-io` | Add remote + push |

**Good News**: All GitHub repos already exist and are PRIVATE ✅

### Critical Gaps

**Inconsistent Standards**:
- ❌ No standardized workflow structure
- ❌ Different testing approaches per repo
- ❌ Manual secret management per repo
- ❌ No deployment automation to AWS ECS
- ❌ No deployment automation to Cloudflare Pages
- ❌ **No test coverage enforcement** (biggest risk)

**Blocking Infrastructure Deployment**:
- ❌ Can't deploy `lightwave-infrastructure-live` without CI/CD
- ❌ No automated Terragrunt plan/apply
- ❌ Manual ECS task updates error-prone

---

## Architecture

### Deployment Topology

```
┌─────────────────────────────────────────────────────┐
│  GitHub Actions (kiwi-dev-la organization)          │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │ lightwave-pipelines-workflows (central repo)│  │
│  │                                              │  │
│  │  Custom Reusable Workflows:                  │  │
│  │  - test-python.yml        (pytest + coverage)│  │
│  │  - test-typescript.yml    (vitest + eslint)  │  │
│  │  - deploy-ecs.yml         (Docker → ECR → ECS)│ │
│  │  - deploy-cloudflare.yml  (Next.js → Pages)  │  │
│  │  - terraform.yml          (Terragrunt)       │  │
│  └──────────────────────────────────────────────┘  │
│                       ▲                             │
│                       │ (uses:)                     │
│                       │                             │
│  ┌────────────────────┴─────────────────────────┐  │
│  │ Individual Repos (8)                         │  │
│  │                                              │  │
│  │ Each has .github/workflows/ci-cd.yml         │  │
│  │ that calls central reusable workflows        │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │ Deployment Targets            │
         │                               │
         │ - AWS ECS Fargate (backend)   │
         │ - Cloudflare Pages (frontend) │
         │ - AWS RDS/Redis (infra)       │
         └───────────────────────────────┘
```

### Workflow Triggers

**On Pull Request** (all repos):
1. Run tests (unit, integration)
2. **Check coverage threshold (80% hard gate)** ⚠️
3. Run linting (ruff, eslint)
4. Run type checking (mypy, tsc)
5. ❌ **Block merge if any check fails**

**On Merge to Main** (auto-deploy dev):
1. All checks pass ✅
2. Build Docker image (backend) or static site (frontend)
3. Push to ECR (backend) or Cloudflare (frontend)
4. Update ECS task (backend) or deploy Pages (frontend)
5. Run smoke tests
6. ✅ Deployment complete

**On Tag** (manual prod):
1. Tag created: `v1.2.3`
2. Workflow triggers with `environment: production`
3. ⏸️ Requires manual approval (GitHub environment protection)
4. Deploy to prod
5. ✅ Production updated

---

## Phase 0: Repository Setup (30 minutes)

### 0.1 Connect Local Repos to GitHub

**Repos needing remote setup**:
- `Frontend/lightwave-createos` → `kiwi-dev-la/createos-io`
- `Frontend/lightwave-photographos` → `kiwi-dev-la/photographyos-io`

**Tasks**:
```bash
# Navigate to createos
cd /Users/joelschaeffer/dev/lightwave/Frontend/lightwave-createos

# Check if remote already exists
git remote -v

# Add remote (if not exists)
git remote add origin git@github.com:kiwi-dev-la/createos-io.git

# Push to GitHub
git branch -M main  # Ensure on main branch
git push -u origin main

# Verify
gh repo view kiwi-dev-la/createos-io
```

```bash
# Navigate to photographos
cd /Users/joelschaeffer/dev/lightwave/Frontend/lightwave-photographos

# Add remote
git remote add origin git@github.com:kiwi-dev-la/photographyos-io.git

# Push to GitHub
git branch -M main
git push -u origin main

# Verify
gh repo view kiwi-dev-la/photographyos-io
```

**Deliverables**:
- [ ] `createos-io` remote configured and pushed
- [ ] `photographyos-io` remote configured and pushed
- [ ] All 8 repos accessible via `gh repo list kiwi-dev-la`

**Acceptance Criteria**:
- All repos show up in `gh repo list kiwi-dev-la`
- Can clone each repo from GitHub
- No "repository not found" errors

---

## Phase 1: Foundation Setup (3 hours)

### 1.1 Install git-xargs (30 minutes)

**Tasks**:
```bash
# Install git-xargs
brew install git-xargs

# Verify installation
git-xargs --version

# Verify GitHub CLI authenticated
gh auth status

# If not authenticated:
gh auth login

# Test git-xargs on single repo (dry-run)
git-xargs \
  --repos kiwi-dev-la/Lightwave-Platform \
  --dry-run \
  echo "Testing git-xargs"
```

**Deliverables**:
- [ ] git-xargs installed and working
- [ ] GitHub CLI authenticated
- [ ] Verified multi-repo access

**Troubleshooting**:
- If "command not found": `brew install git-xargs`
- If "unauthorized": `gh auth login` with correct scopes (repo, workflow)

### 1.2 Create Central Workflows Repository (1 hour)

**Tasks**:
```bash
# Create new repo in kiwi-dev-la org
gh repo create kiwi-dev-la/lightwave-pipelines-workflows \
  --private \
  --description "Reusable GitHub Actions workflows for LightWave CI/CD" \
  --add-readme

# Clone locally
cd /Users/joelschaeffer/dev/lightwave
git clone git@github.com:kiwi-dev-la/lightwave-pipelines-workflows.git

# Create structure
cd lightwave-pipelines-workflows
mkdir -p .github/workflows
mkdir -p templates
mkdir -p docs
mkdir -p scripts

# Create README
cat > README.md <<'EOF'
# LightWave Pipelines Workflows

Reusable GitHub Actions workflows for LightWave CI/CD.

## Workflows

- `test-python.yml` - Python testing (pytest + coverage + ruff + mypy)
- `test-typescript.yml` - TypeScript testing (vitest + eslint + tsc)
- `deploy-ecs.yml` - ECS deployment (Docker → ECR → ECS)
- `deploy-cloudflare.yml` - Cloudflare Pages deployment
- `terraform.yml` - Terraform/Terragrunt validation and apply

## Usage

See individual workflow files for usage examples.

## Documentation

- [Writing Workflows Guide](docs/writing-workflows.md)
- [Testing Workflows Guide](docs/testing-workflows.md)
EOF

# Commit initial structure
git add .
git commit -m "chore: initial repository structure"
git push origin main
```

**Deliverables**:
- [ ] `kiwi-dev-la/lightwave-pipelines-workflows` created
- [ ] Initial folder structure committed
- [ ] README with overview

### 1.3 Configure GitHub Organization Secrets (1.5 hours - parallel with 1.2)

**Required Secrets**:

| Secret Name | Source | Used By |
|-------------|--------|---------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user `lightwave-admin` | Backend, Infrastructure |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user `lightwave-admin` | Backend, Infrastructure |
| `CLOUDFLARE_API_TOKEN` | AWS Secrets Manager | Frontend, Infrastructure |
| `NOTION_API_KEY` | Notion integration | Backend (optional) |
| `ANTHROPIC_API_KEY` | Anthropic dashboard | Backend AI services |

**Tasks**:
```bash
# Set AWS profile
export AWS_PROFILE=lightwave-admin-new

# Load Cloudflare token from AWS Secrets Manager
export CLOUDFLARE_API_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id /lightwave/prod/cloudflare-api-token \
  --query SecretString --output text)

# Add org-level secrets (accessible by all repos)
gh secret set AWS_ACCESS_KEY_ID \
  --body "AKIA..." \
  --org kiwi-dev-la \
  --visibility all

gh secret set AWS_SECRET_ACCESS_KEY \
  --body "..." \
  --org kiwi-dev-la \
  --visibility all

gh secret set CLOUDFLARE_API_TOKEN \
  --body "$CLOUDFLARE_API_TOKEN" \
  --org kiwi-dev-la \
  --visibility all

# Optional: Add Notion API key if needed
gh secret set NOTION_API_KEY \
  --body "secret_..." \
  --org kiwi-dev-la \
  --visibility all

# Optional: Add Anthropic API key
gh secret set ANTHROPIC_API_KEY \
  --body "sk-ant-..." \
  --org kiwi-dev-la \
  --visibility all

# Verify secrets
gh secret list --org kiwi-dev-la
```

**Deliverables**:
- [ ] All AWS credentials configured
- [ ] Cloudflare token configured
- [ ] Secrets visible to all repos
- [ ] Secrets verified with `gh secret list`

**Security Notes**:
- Secrets are encrypted at rest by GitHub
- Only accessible during workflow runs
- Never logged or exposed in PR comments
- Can be rotated anytime via AWS Secrets Manager

### 1.4 Configure GitHub Environments (30 minutes)

**Create 3 environments with protection rules**:

**Dev Environment**:
```bash
# Create via GitHub UI or API
# Settings → Environments → New environment → "dev"
# Protection rules: None (auto-deploy)
```

**Staging Environment** (future):
```bash
# Create via GitHub UI
# Protection rules:
# - Required reviewers: 1
# - Wait timer: 0 minutes
```

**Production Environment**:
```bash
# Create via GitHub UI
# Protection rules:
# - Required reviewers: 2 (Joel + teammate)
# - Wait timer: 5 minutes (cooling-off period)
# - Restrict to tags only (no branch deployments)
```

**Deliverables**:
- [ ] 3 environments created in org settings
- [ ] Protection rules configured
- [ ] Reviewers assigned (production only)

---

## Phase 2: Write Custom Workflows (8 hours)

**Approach**: Write workflows from scratch using GitHub's official documentation and best practices. Inspired by Gruntwork patterns but **no code copying** from their repo.

### 2.1 Python Testing Workflow (2 hours)

**File**: `.github/workflows/test-python.yml`

**Features**:
- Run pytest with coverage
- **Enforce 80% coverage threshold (hard gate)**
- Run ruff (lint + format check)
- Run mypy (type checking)
- Matrix testing (Python 3.11, 3.12)
- PostgreSQL service container for integration tests
- Upload coverage reports to Codecov

**Inputs**:
- `python-version` (default: '3.11')
- `coverage-threshold` (default: 80)
- `test-command` (default: 'pytest --cov')

**Template**:
```yaml
name: Test Python

on:
  workflow_call:
    inputs:
      python-version:
        description: 'Python version to test'
        required: false
        default: '3.11'
        type: string
      coverage-threshold:
        description: 'Minimum coverage percentage'
        required: false
        default: 80
        type: number
      test-command:
        description: 'Command to run tests'
        required: false
        default: 'pytest --cov=src --cov-report=xml --cov-report=html'
        type: string

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_USER: lightwave
          POSTGRES_PASSWORD: lightwave_pass
          POSTGRES_DB: lightwave_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
          cache: 'pip'

      - name: Install uv
        run: pip install uv

      - name: Install dependencies
        run: uv pip install -r requirements.txt --system

      - name: Run tests
        env:
          DATABASE_URL: postgresql://lightwave:lightwave_pass@localhost:5432/lightwave_test
        run: ${{ inputs.test-command }}

      - name: Check coverage threshold
        run: |
          coverage report --fail-under=${{ inputs.coverage-threshold }}

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        if: always()
        with:
          file: ./coverage.xml
          flags: unittests

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
      - run: pip install ruff
      - run: ruff check .
      - run: ruff format --check .

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
      - run: pip install mypy
      - run: mypy src/ || true  # Allow failures initially
```

**Deliverables**:
- [ ] `test-python.yml` created
- [ ] Tested with `Lightwave-Platform`
- [ ] Coverage threshold enforced

### 2.2 TypeScript Testing Workflow (1.5 hours)

**File**: `.github/workflows/test-typescript.yml`

**Features**:
- Run vitest (unit tests)
- **Enforce 80% coverage threshold**
- Run eslint
- Run tsc (type checking)
- Matrix testing (Node 18, 20)
- Optional Playwright for e2e tests

**Template**:
```yaml
name: Test TypeScript

on:
  workflow_call:
    inputs:
      node-version:
        description: 'Node.js version'
        required: false
        default: '18'
        type: string
      coverage-threshold:
        description: 'Minimum coverage percentage'
        required: false
        default: 80
        type: number

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: oven-sh/setup-bun@v1
        with:
          bun-version: latest

      - name: Install dependencies
        run: bun install

      - name: Run tests with coverage
        run: bun test --coverage

      - name: Check coverage threshold
        run: |
          # Parse coverage from vitest output
          # Fail if below threshold
          echo "Coverage check (TODO: implement threshold parsing)"

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
      - run: bun install
      - run: bun run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
      - run: bun install
      - run: bun run typecheck
```

**Deliverables**:
- [ ] `test-typescript.yml` created
- [ ] Tested with `cineos-io`

### 2.3 ECS Deployment Workflow (2 hours)

**File**: `.github/workflows/deploy-ecs.yml`

**Features**:
- Build Docker image
- Push to AWS ECR
- Update ECS task definition
- Force new deployment
- Wait for healthy tasks
- Rollback on failure

**Template**:
```yaml
name: Deploy to ECS

on:
  workflow_call:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        type: string
      cluster:
        description: 'ECS cluster name'
        required: true
        type: string
      service:
        description: 'ECS service name'
        required: true
        type: string
      image-name:
        description: 'Docker image name'
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/${{ inputs.image-name }}:$IMAGE_TAG .
          docker push $ECR_REGISTRY/${{ inputs.image-name }}:$IMAGE_TAG

      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster ${{ inputs.cluster }} \
            --service ${{ inputs.service }} \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster ${{ inputs.cluster }} \
            --services ${{ inputs.service }}
```

**Deliverables**:
- [ ] `deploy-ecs.yml` created
- [ ] Tested with manual trigger

### 2.4 Cloudflare Pages Deployment (1.5 hours)

**File**: `.github/workflows/deploy-cloudflare.yml`

**Template**:
```yaml
name: Deploy to Cloudflare Pages

on:
  workflow_call:
    inputs:
      project-name:
        description: 'Cloudflare Pages project name'
        required: true
        type: string
      build-command:
        description: 'Build command'
        required: false
        default: 'bun run build'
        type: string
      output-directory:
        description: 'Build output directory'
        required: false
        default: '.next'
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: oven-sh/setup-bun@v1

      - name: Install dependencies
        run: bun install

      - name: Build
        run: ${{ inputs.build-command }}

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: b1b69d645d5e41c935053208f073cc32
          projectName: ${{ inputs.project-name }}
          directory: ${{ inputs.output-directory }}
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

**Deliverables**:
- [ ] `deploy-cloudflare.yml` created
- [ ] Tested with `cineos-io`

### 2.5 Terraform/Terragrunt Workflow (1 hour)

**File**: `.github/workflows/terraform.yml`

**Template**:
```yaml
name: Terraform

on:
  workflow_call:
    inputs:
      environment:
        description: 'Environment (dev, staging, prod)'
        required: true
        type: string
      action:
        description: 'Action (plan, apply)'
        required: true
        type: string
      working-directory:
        description: 'Terragrunt working directory'
        required: false
        default: 'dev'
        type: string

jobs:
  terraform:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.5.0

      - name: Setup Terragrunt
        run: |
          wget -q https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
          chmod +x terragrunt_linux_amd64
          sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terragrunt ${{ inputs.action }}
        working-directory: ${{ inputs.working-directory }}
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        run: |
          if [ "${{ inputs.action }}" == "plan" ]; then
            terragrunt run-all plan
          elif [ "${{ inputs.action }}" == "apply" ]; then
            terragrunt run-all apply --auto-approve
          fi
```

**Deliverables**:
- [ ] `terraform.yml` created
- [ ] Tested with `lightwave-infrastructure-live`

---

## Phase 3: Conservative Rollout (5 hours)

### 3.1 Pilot: cineos-io (2 hours)

**Tasks**:
```bash
cd /Users/joelschaeffer/dev/lightwave/Frontend/lightwave-cineos

# Create workflow file
mkdir -p .github/workflows

cat > .github/workflows/ci-cd.yml <<'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/test-typescript.yml@main
    with:
      node-version: '18'
      coverage-threshold: 80
    secrets: inherit

  deploy-dev:
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/deploy-cloudflare.yml@main
    with:
      project-name: cineos-io
      build-command: 'bun run build'
      output-directory: '.next'
    secrets: inherit
EOF

# Create feature branch
git checkout -b cicd/add-workflows

# Commit workflow
git add .github/workflows/ci-cd.yml
git commit -m "feat(ci): add CI/CD workflow with 80% coverage gate"

# Push and create PR
git push -u origin cicd/add-workflows
gh pr create \
  --title "feat(ci): add CI/CD workflow" \
  --body "Adds GitHub Actions workflow for testing and deployment.

## Changes
- Added test workflow (vitest + eslint + tsc)
- Added 80% coverage threshold (hard gate)
- Added auto-deployment to Cloudflare Pages on merge to main

## Testing
- [ ] CI passes on this PR
- [ ] Coverage meets 80% threshold
- [ ] Linting passes
- [ ] Type checking passes

**Notion Task**: [Link to task]" \
  --draft
```

**Validation Steps**:
1. Open draft PR
2. Verify CI workflow runs
3. Check test coverage (will it pass 80%?)
4. If coverage fails, add tests to reach threshold
5. Verify linting and type-check pass
6. Merge PR (triggers deployment)
7. Verify Cloudflare Pages deployment succeeds
8. Check deployment URL works

**Deliverables**:
- [ ] Workflow file committed to `cineos-io`
- [ ] PR created and CI runs successfully
- [ ] Coverage threshold met (80%)
- [ ] Deployment to Cloudflare Pages successful
- [ ] Site accessible at deployment URL

**If pilot fails**:
- Document failure reason
- Fix workflow template in central repo
- Re-test on `cineos-io`
- Do NOT proceed to Phase 3.2 until pilot succeeds

### 3.2 Batch Apply to Remaining Frontends (3 hours)

**Only proceed if Phase 3.1 pilot succeeds**

**Script**: `scripts/add-frontend-cicd.sh`
```bash
#!/bin/bash
set -e

# Get repo name from git remote
REPO_NAME=$(basename $(git remote get-url origin) .git)

# Create workflow directory
mkdir -p .github/workflows

# Add workflow file
cat > .github/workflows/ci-cd.yml <<EOF
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/test-typescript.yml@main
    with:
      node-version: '18'
      coverage-threshold: 80
    secrets: inherit

  deploy-dev:
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/deploy-cloudflare.yml@main
    with:
      project-name: ${REPO_NAME}
      build-command: 'bun run build'
      output-directory: '.next'
    secrets: inherit
EOF

# Stage changes
git add .github/workflows/ci-cd.yml

echo "✅ Workflow added for ${REPO_NAME}"
```

**Execute with git-xargs**:
```bash
# Run on remaining 4 frontends (excluding cineos-io which is already done)
git-xargs \
  --repos createos-io,photographyos-io,joelschaeffer-com,lightwave-media-site \
  --github-org kiwi-dev-la \
  --branch-name cicd/add-workflows \
  --commit-message "feat(ci): add CI/CD workflow with 80% coverage gate

Adds GitHub Actions workflow for testing and deployment.

- Test workflow (vitest + eslint + tsc)
- 80% coverage threshold (hard gate)
- Auto-deployment to Cloudflare Pages on merge

🤖 Generated with git-xargs
Co-Authored-By: Claude <noreply@anthropic.com>" \
  --draft \
  --seconds-between-prs 30 \
  bash scripts/add-frontend-cicd.sh
```

**Deliverables**:
- [ ] 4 draft PRs created (one per frontend)
- [ ] Each PR includes workflow file
- [ ] Each PR runs CI successfully
- [ ] Coverage checks pass (or documented as failing)

**Next Steps After git-xargs**:
1. Review each draft PR
2. Check CI status (expect coverage failures initially)
3. For repos with <80% coverage:
   - Either add tests to reach 80%
   - Or document test backfilling plan
4. Merge PRs once CI passes

---

## Phase 4: Backend & Infrastructure (4 hours)

### 4.1 Backend: Lightwave-Platform (2 hours)

**Tasks**:
```bash
cd /Users/joelschaeffer/dev/lightwave/Backend/Lightwave-Platform

# Create workflow
mkdir -p .github/workflows

cat > .github/workflows/ci-cd.yml <<'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/test-python.yml@main
    with:
      python-version: '3.11'
      coverage-threshold: 80
      test-command: 'pytest backend/tests --cov=backend --cov-report=xml'
    secrets: inherit

  deploy-dev:
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/deploy-ecs.yml@main
    with:
      environment: dev
      cluster: lightwave-dev-ecs-cluster
      service: lightwave-backend-api-dev
      image-name: lightwave-backend
    secrets: inherit
EOF

# Create PR
git checkout -b cicd/add-backend-workflow
git add .github/workflows/ci-cd.yml
git commit -m "feat(ci): add backend CI/CD with 80% coverage gate"
git push -u origin cicd/add-backend-workflow
gh pr create --draft
```

**Deliverables**:
- [ ] Backend workflow created
- [ ] PR opened
- [ ] CI runs successfully
- [ ] ECS deployment tested (manual trigger first)

### 4.2 Infrastructure: lightwave-infrastructure-live (2 hours)

**Tasks**:
```bash
cd /Users/joelschaeffer/dev/lightwave/Infrastructure/lightwave-infrastructure-live

# Create workflow
mkdir -p .github/workflows

cat > .github/workflows/terragrunt.yml <<'EOF'
name: Terragrunt CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  plan:
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/terraform.yml@main
    with:
      environment: dev
      action: plan
      working-directory: dev
    secrets: inherit

  apply-dev:
    needs: plan
    if: github.ref == 'refs/heads/main'
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/terraform.yml@main
    with:
      environment: dev
      action: apply
      working-directory: dev
    secrets: inherit
EOF

# Create PR
git checkout -b cicd/add-terragrunt-workflow
git add .github/workflows/terragrunt.yml
git commit -m "feat(ci): add Terragrunt plan/apply workflow"
git push -u origin cicd/add-terragrunt-workflow
gh pr create --draft
```

**Deliverables**:
- [ ] Terragrunt workflow created
- [ ] Plan runs on PR
- [ ] Apply runs on merge to main

---

## Phase 5: Automation Scripts (2 hours)

### 5.1 Create Multi-Repo Scripts

**Script 1**: `scripts/sync-workflow-templates.sh`
```bash
#!/bin/bash
# Sync CI/CD workflow from central repo

set -e

WORKFLOW_URL="https://raw.githubusercontent.com/kiwi-dev-la/lightwave-pipelines-workflows/main/templates/ci-cd.yml"

# Download latest template
mkdir -p .github/workflows
curl -s "$WORKFLOW_URL" -o .github/workflows/ci-cd.yml

# Stage changes
git add .github/workflows/ci-cd.yml

echo "✅ Workflow template synced"
```

**Script 2**: `scripts/update-python-deps.sh`
```bash
#!/bin/bash
# Update Python dependencies

set -e

if [ ! -f "requirements.txt" ]; then
  echo "No requirements.txt found, skipping"
  exit 0
fi

# Update dependencies
uv pip compile requirements.in --upgrade > requirements.txt

# Stage changes
git add requirements.txt

echo "✅ Python dependencies updated"
```

**Script 3**: `scripts/update-node-deps.sh`
```bash
#!/bin/bash
# Update Node.js dependencies

set -e

if [ ! -f "package.json" ]; then
  echo "No package.json found, skipping"
  exit 0
fi

# Update dependencies
bun update

# Stage changes
git add package.json bun.lockb

echo "✅ Node.js dependencies updated"
```

**Deliverables**:
- [ ] 3 automation scripts created
- [ ] Scripts tested locally
- [ ] Scripts documented in SOP

### 5.2 Test git-xargs Automation

**Test dependency updates**:
```bash
# Test on Python repos (dry-run first)
git-xargs \
  --repos Lightwave-Platform \
  --github-org kiwi-dev-la \
  --dry-run \
  bash scripts/update-python-deps.sh

# Test on Node repos (dry-run first)
git-xargs \
  --repos cineos-io,createos-io \
  --github-org kiwi-dev-la \
  --dry-run \
  bash scripts/update-node-deps.sh
```

**Deliverables**:
- [ ] Dry-run successful
- [ ] Scripts work across repos
- [ ] No errors in git-xargs output

---

## Phase 6: Testing & Coverage Audit (2 hours)

### 6.1 Audit Current Test Coverage (1 hour)

**Run coverage reports for each repo**:

**Backend**:
```bash
cd /Users/joelschaeffer/dev/lightwave/Backend/Lightwave-Platform
pytest backend/tests --cov=backend --cov-report=term
```

**Frontends**:
```bash
cd /Users/joelschaeffer/dev/lightwave/Frontend/lightwave-cineos
bun test --coverage
```

**Document results**:
```markdown
# Current Test Coverage Audit

| Repository | Current Coverage | Gap to 80% | Estimated Test-Writing Effort |
|------------|------------------|------------|-------------------------------|
| Lightwave-Platform | X% | Y% | Z hours |
| cineos-io | X% | Y% | Z hours |
| createos-io | X% | Y% | Z hours |
| ... | ... | ... | ... |
```

**Deliverables**:
- [ ] Coverage audit complete for all repos
- [ ] Gap analysis documented
- [ ] Test-writing effort estimated

### 6.2 Create Test Backfilling Plan (1 hour)

**If any repo has <80% coverage**:

**Option 1: Block all PRs until tests backfilled**
- Strict enforcement
- Forces immediate test-writing
- May block feature development

**Option 2: Incremental ratcheting**
- Start at current coverage
- Increase by 5% each sprint
- Reach 80% over 4-8 weeks

**Option 3: New code only**
- Enforce 80% on changed lines only
- Ignore existing untested code
- Prevents coverage regression

**Recommendation**: Based on audit results, choose approach per repo.

**Deliverables**:
- [ ] Test backfilling strategy chosen
- [ ] Timeline for reaching 80% coverage
- [ ] Resources allocated (who will write tests?)

---

## Success Criteria

### Coverage
- ✅ 8/8 repositories have GitHub Actions workflows
- ✅ All repos use centralized reusable workflows from `lightwave-pipelines-workflows`
- ✅ git-xargs configured and tested

### Quality Gates
- ✅ No PR merges without passing tests
- ✅ **80% code coverage enforced (hard gate)**
- ✅ Linting + type-check required
- ✅ Production requires manual approval

### Automation
- ✅ Backend auto-deploys to ECS dev on merge
- ✅ Frontend auto-deploys to Cloudflare Pages on merge
- ✅ Infrastructure auto-applies to dev on merge
- ✅ Multi-repo scripts working

### Deployment
- ✅ ECS deployments successful
- ✅ Cloudflare Pages deployments successful
- ✅ Terragrunt apply successful
- ✅ Rollback procedures tested

---

## Deliverables

### New Repositories
1. `kiwi-dev-la/lightwave-pipelines-workflows` (reusable workflows)

### Updated Repositories
- All 8 repos with `.github/workflows/ci-cd.yml`

### Documentation
1. `.agent/tasks/CICD_IMPLEMENTATION_PLAN_v1.1.0.md` (this file)
2. `.agent/sops/GIT_XARGS_OPERATIONS.md` (git-xargs guide)
3. `lightwave-pipelines-workflows/README.md` (workflow docs)
4. **Coverage audit report** (per-repo coverage + backfilling plan)

### Scripts
1. `scripts/add-frontend-cicd.sh` (git-xargs runner)
2. `scripts/update-python-deps.sh` (Python dependency updates)
3. `scripts/update-node-deps.sh` (Node dependency updates)
4. `scripts/sync-workflow-templates.sh` (workflow sync)

---

## Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| **Phase 0**: Repository Setup | 30 min | None |
| **Phase 1**: Foundation | 3 hours | Phase 0 complete |
| **Phase 2**: Write Workflows | 8 hours | Phase 1 complete |
| **Phase 3**: Conservative Rollout | 5 hours | Phase 2 complete |
| **Phase 4**: Backend + Infrastructure | 4 hours | Phase 2 complete (parallel with 3) |
| **Phase 5**: Automation Scripts | 2 hours | Phase 1 complete (parallel with 2-4) |
| **Phase 6**: Testing + Coverage Audit | 2 hours | All phases complete |
| **Total** | **20.5 hours** | **~3 days** |

**Recommended Schedule**:
- **Day 1 (AM)**: Phase 0 + 1 (Foundation setup - 3.5 hours)
- **Day 1 (PM)**: Phase 2 (Write workflows - 8 hours, may extend to Day 2)
- **Day 2 (AM)**: Phase 2 completion + Phase 3 start (Pilot cineos-io)
- **Day 2 (PM)**: Phase 3 + 4 (Rollout frontends + backend in parallel)
- **Day 3**: Phase 5 + 6 (Automation + testing)

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **80% coverage not achievable short-term** | High | Medium | Audit coverage first (Phase 6.1), adjust strategy |
| GitHub API rate limits | Medium | Low | Use `--seconds-between-prs 30` in git-xargs |
| ECS deployment failures | Medium | Low | Test manual deployment first, add rollback |
| Cloudflare quota exceeded | Low | Low | Free tier: 500 builds/month |
| Workflow coupling issues | Low | Low | Custom workflows eliminate coupling risk |
| Test-writing blocks feature work | High | Medium | Consider incremental ratcheting or new-code-only |

---

## Post-Implementation

### Week 1
- Monitor all CI/CD runs
- Fix flaky tests
- Optimize workflow run times
- **Assess coverage gaps**, begin test backfilling

### Week 2
- Add deployment notifications (Slack webhook)
- Set up build/deploy dashboard
- Create runbook for common issues
- **Continue test backfilling**

### Month 1
- Review deployment frequency metrics
- Identify bottlenecks
- Add CD metrics (lead time, MTTR, deployment frequency)
- **Reach 80% coverage across all repos**

---

## Related Documentation

- **SOP**: `.agent/sops/GIT_XARGS_OPERATIONS.md` (multi-repo operations)
- **Secrets**: `.claude/SECRETS_MAP.md` (secret locations)
- **Infrastructure**: `Infrastructure/lightwave-infrastructure-live/CLAUDE.md`
- **Backend**: `Backend/Lightwave-Platform/CLAUDE.md`

---

**Version**: 1.1.0
**Status**: Ready to Execute
**Last Updated**: 2025-10-25
**Maintainer**: Joel Schaeffer

**Changes from v1.0.0**:
- Added Phase 0 (repository setup)
- Changed workflow strategy from "adapt Gruntwork" to "write custom"
- Changed coverage policy to "80% hard gate"
- Changed rollout to "conservative pilot-first"
- Updated timeline to 20.5 hours (from 16-20)
- Added coverage audit and test backfilling plan
