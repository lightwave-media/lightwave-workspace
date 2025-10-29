# CI/CD Implementation Plan: Gruntwork git-xargs + Pipelines-Workflows

**Epic**: Establish Production-Ready CI/CD Across All LightWave Repositories
**Version**: 1.0.0
**Status**: 🟢 Ready to Execute
**Priority**: P0 - Blocking Infrastructure Deployment
**Estimated Effort**: 16-20 hours (2-3 days)
**Owner**: Joel Schaeffer
**Created**: 2025-10-25

---

## Executive Summary

Implement standardized CI/CD pipelines across all 8 LightWave repositories using Gruntwork's battle-tested tools:
- **git-xargs**: Multi-repository automation (batch updates, PR creation)
- **pipelines-workflows**: Reusable GitHub Actions workflows (adapted from Gruntwork)

**Problem**: No consistent CI/CD, manual deployments, ad-hoc testing, blocking infrastructure rollout.

**Solution**: Centralized reusable workflows + automated multi-repo operations.

**Outcome**: Production-ready CI/CD with auto-deployment to dev, manual gating for prod, 100% test coverage enforcement.

---

## Current State Analysis

### Discovered Repositories (8)

| Repository | GitHub Remote | Stack | Current CI/CD |
|------------|---------------|-------|---------------|
| `Backend/Lightwave-Platform` | kiwi-dev-la/Lightwave-Platform | Django | ✅ Basic (ci-cd.yml) |
| `Backend/.../lightwave-ai-services` | Subdir of Platform | FastAPI | ✅ Basic (ci-cd.yml) |
| `Frontend/lightwave-cineos` | kiwi-dev-la/cineos-io | Next.js | ✅ Basic (ci.yml) |
| `Frontend/lightwave-createos` | ❌ No remote | Next.js | ✅ Basic (ci.yml) |
| `Frontend/lightwave-photographos` | ❌ No remote | Next.js | ✅ Basic (ci.yml) |
| `Frontend/lightwave-joelschaeffer` | ❌ No remote | Next.js + Payload | ❌ None |
| `Frontend/lightwave-media-site` | ❌ No remote | Next.js + Payload | ❌ None |
| `Infrastructure/lightwave-infrastructure` | kiwi-dev-la/lightwave-infrastructure | Terraform | ✅ Comprehensive (8 workflows) |
| `Infrastructure/lightwave-infrastructure-live` | ❌ No remote | Terragrunt | ❌ None |

### Critical Gaps

**Inconsistent Standards**:
- ❌ No standardized workflow structure
- ❌ Different testing approaches per repo
- ❌ Manual secret management per repo
- ❌ No deployment automation to AWS ECS
- ❌ No deployment automation to Cloudflare Pages

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
│  │  Reusable Workflows:                         │  │
│  │  - test-python.yml                           │  │
│  │  - test-typescript.yml                       │  │
│  │  - deploy-ecs.yml                            │  │
│  │  - deploy-cloudflare-pages.yml               │  │
│  │  - terraform-plan-apply.yml                  │  │
│  └──────────────────────────────────────────────┘  │
│                       ▲                             │
│                       │ (called by)                 │
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
2. Check coverage threshold (80%)
3. Run linting (ruff, eslint)
4. Run type checking (mypy, tsc)
5. ❌ Block merge if any check fails

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

## Phase 1: Foundation Setup (4 hours)

### 1.1 Install git-xargs

**Tasks**:
```bash
# Install git-xargs
brew install git-xargs

# Verify installation
git-xargs --version

# Create GitHub token (classic, full repo access)
# https://github.com/settings/tokens/new
# Scopes needed: repo, workflow, admin:org

# Export token
export GITHUB_TOKEN=ghp_your_token_here

# Test on single repo
git-xargs \
  --repos kiwi-dev-la/Lightwave-Platform \
  --dry-run \
  echo "Testing git-xargs"
```

**Deliverables**:
- [ ] git-xargs installed and working
- [ ] GitHub token with correct permissions
- [ ] Verified multi-repo access

### 1.2 Clone and Adapt Gruntwork Workflows

**Tasks**:
```bash
# Clone Gruntwork reference implementation
cd ~/temp
git clone https://github.com/gruntwork-io/pipelines-workflows.git
cd pipelines-workflows

# Study workflow structure
cat .github/workflows/pipelines-root.yml
cat .github/workflows/pipelines-delegated.yml

# Identify reusable patterns:
# - Terraform plan/apply logic
# - Docker build/push
# - Deployment automation
# - Testing patterns
```

**Adaptation Strategy**:
- ❌ Don't use DevOps Foundations specific logic
- ✅ Extract generic patterns (build, test, deploy)
- ✅ Adapt for LightWave tech stack (Django, Next.js, Terragrunt)
- ✅ Simplify for 8-repo scope (not 100+ repos)

**Deliverables**:
- [ ] Gruntwork workflows analyzed
- [ ] Reusable patterns identified
- [ ] Adaptation plan documented

### 1.3 Create Central Workflows Repository

**Tasks**:
```bash
# Create new repo in kiwi-dev-la org
gh repo create kiwi-dev-la/lightwave-pipelines-workflows \
  --public \
  --description "Reusable GitHub Actions workflows for LightWave CI/CD"

# Clone locally
cd /Users/joelschaeffer/dev/lightwave
git clone git@github.com:kiwi-dev-la/lightwave-pipelines-workflows.git

# Create structure
cd lightwave-pipelines-workflows
mkdir -p .github/workflows
mkdir -p docs
```

**Deliverables**:
- [ ] `kiwi-dev-la/lightwave-pipelines-workflows` repository created
- [ ] Initial structure in place

---

## Phase 2: Create Reusable Workflows (6 hours)

### 2.1 Python Testing Workflow

**File**: `.github/workflows/test-python.yml`

**Features**:
- Runs pytest with coverage
- Enforces 80% coverage threshold
- Runs ruff (lint + format check)
- Runs mypy (type checking)
- Matrix testing (Python 3.11, 3.12)
- PostgreSQL service container for integration tests

**Deliverables**:
- [ ] `test-python.yml` created
- [ ] Tested with Lightwave-Platform

### 2.2 TypeScript Testing Workflow

**File**: `.github/workflows/test-typescript.yml`

**Features**:
- Runs vitest (unit tests)
- Runs eslint
- Runs tsc (type checking)
- Matrix testing (Node 18, 20)
- Playwright for e2e tests (optional)

**Deliverables**:
- [ ] `test-typescript.yml` created
- [ ] Tested with lightwave-cineos

### 2.3 ECS Deployment Workflow

**File**: `.github/workflows/deploy-ecs.yml`

**Features**:
- Build Docker image
- Push to AWS ECR
- Update ECS task definition
- Force new deployment
- Wait for healthy tasks
- Rollback on failure

**Inputs**:
- `environment` (dev, staging, prod)
- `cluster` (ECS cluster name)
- `service` (ECS service name)
- `image-name` (Docker image name)

**Deliverables**:
- [ ] `deploy-ecs.yml` created
- [ ] Tested with manual trigger

### 2.4 Cloudflare Pages Deployment

**File**: `.github/workflows/deploy-cloudflare-pages.yml`

**Features**:
- Install dependencies (bun/pnpm)
- Build Next.js site
- Deploy to Cloudflare Pages
- Return deployment URL

**Inputs**:
- `project-name` (Cloudflare project)
- `build-command` (e.g., "bun run build")
- `output-directory` (e.g., ".next")

**Deliverables**:
- [ ] `deploy-cloudflare-pages.yml` created
- [ ] Tested with lightwave-cineos

### 2.5 Terraform/Terragrunt Workflow

**File**: `.github/workflows/terraform-plan-apply.yml`

**Features**:
- Terragrunt validate
- Terragrunt plan (save plan file)
- Terragrunt apply (from plan file)
- Support for multiple environments

**Inputs**:
- `environment` (dev, staging, prod)
- `action` (plan, apply)
- `working-directory` (path to Terragrunt config)

**Deliverables**:
- [ ] `terraform-plan-apply.yml` created
- [ ] Tested with lightwave-infrastructure-live

---

## Phase 3: Apply Workflows to Repositories (6 hours)

### 3.1 Backend Repositories (2 repos)

**Targets**:
- `Backend/Lightwave-Platform` (Django monolith)
- `Backend/Lightwave-Platform/lightwave-ai-services` (FastAPI)

**Workflow**:
```yaml
# .github/workflows/ci-cd.yml
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
```

**Deliverables**:
- [ ] CI/CD workflow added to Platform
- [ ] CI/CD workflow added to ai-services
- [ ] Both deploy to ECS dev on merge

### 3.2 Frontend Repositories (5 repos)

**Use git-xargs for batch operation**:

Create script: `scripts/add-frontend-cicd.sh`
```bash
#!/bin/bash
# Add CI/CD workflow to frontend repos

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
    secrets: inherit

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/deploy-cloudflare-pages.yml@main
    with:
      project-name: ${{ github.event.repository.name }}
      build-command: 'bun run build'
      output-directory: '.next'
    secrets: inherit
EOF

git add .github/workflows/ci-cd.yml
```

**Run with git-xargs**:
```bash
# First, create GitHub remotes for repos without them
gh repo create kiwi-dev-la/lightwave-createos --source Frontend/lightwave-createos --push
gh repo create kiwi-dev-la/lightwave-photographos --source Frontend/lightwave-photographos --push
gh repo create kiwi-dev-la/lightwave-joelschaeffer --source Frontend/lightwave-joelschaeffer --push
gh repo create kiwi-dev-la/lightwave-media-site --source Frontend/lightwave-media-site --push

# Then run git-xargs
git-xargs \
  --repos lightwave-cineos,lightwave-createos,lightwave-photographos,lightwave-joelschaeffer,lightwave-media-site \
  --github-org kiwi-dev-la \
  --branch-name cicd/add-workflows \
  --commit-message "feat(ci): add Cloudflare Pages deployment workflow" \
  --draft \
  bash scripts/add-frontend-cicd.sh
```

**Deliverables**:
- [ ] 4 new GitHub repos created (createos, photographos, joelschaeffer, media-site)
- [ ] 5 PRs created with CI/CD workflows
- [ ] All frontends deploy to Cloudflare Pages

### 3.3 Infrastructure Repositories (2 repos)

**lightwave-infrastructure** (Terraform modules):
```yaml
# .github/workflows/terraform.yml
name: Terraform Validation

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform fmt -check -recursive
      - run: terraform validate

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - run: |
          cd test
          go test -v -timeout 30m
```

**lightwave-infrastructure-live** (Terragrunt):
```yaml
# .github/workflows/terragrunt.yml
name: Terragrunt Deployment

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  plan:
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/terraform-plan-apply.yml@main
    with:
      environment: dev
      action: plan
      working-directory: dev
    secrets: inherit

  apply-dev:
    needs: plan
    if: github.ref == 'refs/heads/main'
    uses: kiwi-dev-la/lightwave-pipelines-workflows/.github/workflows/terraform-plan-apply.yml@main
    with:
      environment: dev
      action: apply
      working-directory: dev
    secrets: inherit
```

**Deliverables**:
- [ ] Terraform validation workflow added
- [ ] Terragrunt plan/apply workflow added
- [ ] Auto-apply to dev on merge

---

## Phase 4: Multi-Repo Automation (2 hours)

### 4.1 Create Automation Scripts

**Script 1**: `scripts/update-all-dependencies.sh`
```bash
#!/bin/bash
# Update dependencies across all repos

if [ -f "requirements.txt" ]; then
  uv pip compile requirements.in > requirements.txt
  git add requirements.txt
elif [ -f "package.json" ]; then
  bun update
  git add package.json bun.lockb
fi
```

**Script 2**: `scripts/sync-workflow-templates.sh`
```bash
#!/bin/bash
# Sync workflow templates from central repo

curl -s https://raw.githubusercontent.com/kiwi-dev-la/lightwave-pipelines-workflows/main/templates/ci-cd.yml \
  -o .github/workflows/ci-cd.yml

git add .github/workflows/ci-cd.yml
```

**Script 3**: `scripts/add-secret-to-all-repos.sh`
```bash
#!/bin/bash
# Add organization secret to all repos
# Usage: ./add-secret-to-all-repos.sh SECRET_NAME "secret_value"

SECRET_NAME=$1
SECRET_VALUE=$2

gh secret set $SECRET_NAME -b"$SECRET_VALUE" -R kiwi-dev-la/$REPO_NAME
```

**Deliverables**:
- [ ] 3 automation scripts created
- [ ] Scripts tested with git-xargs
- [ ] Documentation added

### 4.2 Configure GitHub Organization Secrets

**Tasks**:
```bash
# Set organization secrets (visible to all repos)
gh secret set AWS_ACCESS_KEY_ID -b"AKIA..." --org kiwi-dev-la
gh secret set AWS_SECRET_ACCESS_KEY -b"..." --org kiwi-dev-la
gh secret set CLOUDFLARE_API_TOKEN -b"..." --org kiwi-dev-la
gh secret set NOTION_API_KEY -b"..." --org kiwi-dev-la
gh secret set ANTHROPIC_API_KEY -b"..." --org kiwi-dev-la
```

**Deliverables**:
- [ ] All secrets configured at org level
- [ ] Secrets accessible by workflows
- [ ] No per-repo secret duplication

### 4.3 Configure GitHub Environments

**Create environments with protection rules**:

**Dev Environment**:
- Auto-deploy on merge to main
- No approvals required

**Staging Environment** (future):
- Auto-deploy on tag
- 1 reviewer required

**Production Environment**:
- Manual trigger only
- 2 reviewers required
- Delay: 5 minutes

**Deliverables**:
- [ ] 3 environments configured
- [ ] Protection rules applied
- [ ] Reviewers assigned

---

## Phase 5: Testing & Validation (2 hours)

### 5.1 End-to-End Testing

**Backend Test**:
1. Create feature branch in `Lightwave-Platform`
2. Make code change
3. Open PR
4. Verify CI runs (test, lint, type-check)
5. Merge PR
6. Verify deployment to ECS dev
7. Check ECS task running
8. Test API health endpoint

**Frontend Test**:
1. Create feature branch in `lightwave-cineos`
2. Make code change
3. Open PR
4. Verify CI runs
5. Merge PR
6. Verify deployment to Cloudflare Pages
7. Check deployment URL
8. Test site loads

**Infrastructure Test**:
1. Create feature branch in `lightwave-infrastructure-live`
2. Modify Terragrunt config
3. Open PR
4. Verify plan runs
5. Merge PR
6. Verify apply to dev
7. Check AWS resources updated

**Deliverables**:
- [ ] All 3 workflows tested end-to-end
- [ ] Deployments successful
- [ ] Issues documented and fixed

### 5.2 Rollback Testing

**Scenarios**:
1. Failed ECS deployment → Rollback to previous task definition
2. Failed Cloudflare deploy → Rollback to previous deployment
3. Failed Terragrunt apply → Manual rollback

**Deliverables**:
- [ ] Rollback procedures documented
- [ ] Rollback tested for each deployment type
- [ ] Emergency "disable CI" procedure documented

---

## Success Criteria

### Coverage
- ✅ 8/8 repositories have GitHub Actions workflows
- ✅ All repos use centralized reusable workflows
- ✅ git-xargs configured and tested

### Quality Gates
- ✅ No PR merges without passing tests
- ✅ 80% code coverage enforced
- ✅ Linting + type-check required
- ✅ Production requires manual approval

### Automation
- ✅ Backend auto-deploys to ECS dev on merge
- ✅ Frontend auto-deploys to Cloudflare Pages on merge
- ✅ Infrastructure auto-applies to dev on merge
- ✅ Multi-repo scripts working

---

## Deliverables

### New Repositories
1. `kiwi-dev-la/lightwave-pipelines-workflows` (reusable workflows)
2. `kiwi-dev-la/lightwave-createos` (migrated from local)
3. `kiwi-dev-la/lightwave-photographos` (migrated from local)
4. `kiwi-dev-la/lightwave-joelschaeffer` (migrated from local)
5. `kiwi-dev-la/lightwave-media-site` (migrated from local)
6. `kiwi-dev-la/lightwave-infrastructure-live` (migrated from local)

### Updated Repositories
- All 8 repos now have `.github/workflows/ci-cd.yml`

### Documentation
1. `.agent/tasks/CICD_IMPLEMENTATION_PLAN_v1.0.0.md` (this file)
2. `.agent/sops/GIT_XARGS_OPERATIONS.md` (git-xargs guide)
3. `lightwave-pipelines-workflows/README.md` (workflow docs)

### Scripts
1. `scripts/add-frontend-cicd.sh`
2. `scripts/update-all-dependencies.sh`
3. `scripts/sync-workflow-templates.sh`

---

## Timeline

| Phase | Duration | Can Parallelize? |
|-------|----------|------------------|
| Phase 1: Foundation | 4 hours | No |
| Phase 2: Reusable Workflows | 6 hours | No (blocks Phase 3) |
| Phase 3: Apply to Repos | 6 hours | Yes (backend + frontend in parallel) |
| Phase 4: Multi-Repo Automation | 2 hours | Yes (parallel with Phase 3) |
| Phase 5: Testing | 2 hours | No |
| **Total** | **16-20 hours** | **2-3 days** |

**Recommended Schedule**:
- **Day 1 (AM)**: Phase 1 (4 hours)
- **Day 1 (PM)**: Phase 2 (6 hours) - Critical path
- **Day 2 (AM)**: Phase 3 (backend + frontend in parallel, 6 hours)
- **Day 2 (PM)**: Phase 4 (2 hours) + Phase 5 (2 hours)

---

## Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| GitHub API rate limits | Medium | Medium | Use git-xargs `--seconds-between-prs` flag |
| Missing repo permissions | High | Low | Verify org admin access first |
| Secret leakage in logs | Critical | Low | Use GitHub secret masking, test locally first |
| ECS deployment failures | Medium | Medium | Add health checks, rollback automation |
| Cloudflare quota exceeded | Low | Low | Free tier: 500 builds/month (well above usage) |
| Breaking existing workflows | Low | Low | Test on feature branches first |
| Terraform state lock issues | Medium | Low | Add state locking timeout, manual unlock procedure |

---

## Cost Analysis

### GitHub Actions
- **Free Tier**: 2,000 minutes/month
- **Estimated Usage**: ~1,500 minutes/month
  - 8 repos × 10 PR/month × 5 min/run = 400 min
  - 8 repos × 20 merges/month × 10 min/deployment = 1,600 min
- **Overflow Cost**: $0.008/minute (only if exceeding free tier)
- **Expected Cost**: $0/month (within free tier)

### Cloudflare Pages
- **Free Tier**: 500 builds/month, unlimited bandwidth
- **Expected Usage**: ~100 builds/month
- **Expected Cost**: $0/month

### AWS
- **ECR**: $0.10/GB/month storage
- **Expected Cost**: ~$5/month (Docker images)

**Total Monthly Cost**: ~$5/month

---

## Post-Implementation

### Week 1
- Monitor all CI/CD runs
- Fix flaky tests
- Optimize workflow run times
- Address any deployment issues

### Week 2
- Add deployment notifications (Slack webhook)
- Set up build/deploy dashboard
- Create runbook for common issues

### Month 1
- Review deployment frequency metrics
- Identify bottlenecks
- Add CD metrics (lead time, MTTR, deployment frequency)
- Optimize Docker build caching

---

## Related Documentation

- **SOP**: `.agent/sops/GIT_XARGS_OPERATIONS.md` (multi-repo guide)
- **Reference**: Gruntwork pipelines-workflows (https://github.com/gruntwork-io/pipelines-workflows)
- **Reference**: git-xargs docs (https://github.com/gruntwork-io/git-xargs)
- **Secrets**: `.claude/SECRETS_MAP.md`
- **Infrastructure**: `Infrastructure/lightwave-infrastructure-live/CLAUDE.md`

---

**Version**: 1.0.0
**Status**: Ready to Execute
**Last Updated**: 2025-10-25
**Maintainer**: Joel Schaeffer
