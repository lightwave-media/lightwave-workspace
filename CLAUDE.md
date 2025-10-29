# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Repository Overview

This is the **lightwave-workspace** root repository - a multi-repository workspace orchestrating the LightWave Media software ecosystem. This is NOT a monorepo; each subdirectory contains separate Git repositories with their own history.

**Organization:** lightwave-media
**Structure:** Multi-repo workspace with Infrastructure, Backend, and Frontend

---

## CRITICAL: First Steps for Every Session

**🚨 MANDATORY - Read this FIRST:**

1. **Read the onboarding checklist:** `.claude/ONBOARDING.md` (contains critical AWS profile setup)
2. **Set AWS profile before ANY AWS commands:**
   ```bash
   export AWS_PROFILE=lightwave-admin-new
   ```
3. **Check Notion sync status:** `.agent/README.md` for latest architecture docs
4. **Identify which repository** you're working in (this is a multi-repo workspace)

**Never skip step 1.** It prevents 90% of repeated issues and contains verification steps you must report.

---

## Repository Structure

```
lightwave-workspace/                       (THIS REPO - root orchestrator)
├── .claude/                               # Persistent Claude Code context & skills
│   ├── ONBOARDING.md                      # 🚨 READ FIRST - Mandatory checklist
│   ├── README.md                          # Claude context system documentation
│   └── agents/                            # Specialized agent definitions
├── .agent/                                # Notion-synced metadata (status-filtered)
│   ├── README.md                          # Sync status & RAG query patterns
│   ├── metadata/                          # Architecture metadata (YAML)
│   ├── tasks/                             # Task definitions (YAML)
│   └── sops/                              # Standard Operating Procedures
├── Backend/                               # Backend repositories (to be cloned)
│   └── (lightwave-backend, etc.)
├── Frontend/                              # Frontend repositories (to be cloned)
│   └── (lightwave-media-site, etc.)
└── Infrastructure/                        # Infrastructure repositories
    ├── lightwave-infrastructure-catalog/  # Terraform modules (separate repo)
    └── lightwave-infrastructure-live/     # Live configs (separate repo)
```

**Important:** Each subdirectory in `Backend/`, `Frontend/`, and `Infrastructure/` contains separate Git repositories. Always verify which repository you're working in before running git commands.

---

## Development Commands

### Infrastructure (OpenTofu/Terragrunt)

**Prerequisites:** OpenTofu, Terragrunt installed (use `mise install` for pinned versions)

```bash
# Navigate to live infrastructure
cd Infrastructure/lightwave-infrastructure-live/dev

# Plan infrastructure changes
terragrunt run-all plan

# Apply infrastructure changes
terragrunt run-all apply

# Deploy specific environment
cd Infrastructure/lightwave-infrastructure-live/prod
terragrunt run-all apply
```

**Important:** Infrastructure uses OpenTofu (not Terraform) and Terragrunt for orchestration. Configurations are in `lightwave-infrastructure-live`, modules are in `lightwave-infrastructure-catalog`.

### Backend (Django/Python)

**Prerequisites:** Python 3.11+, Docker, uv package manager

```bash
# Navigate to backend (when cloned)
cd Backend/lightwave-backend

# Start local development with Docker Compose
docker compose up

# Install dependencies
uv pip install -r requirements.txt

# Run tests
pytest

# Run single test
pytest path/to/test_file.py::test_function_name
```

### Frontend (Next.js/Payload CMS)

**Prerequisites:** Node.js, pnpm

```bash
# Navigate to frontend (when cloned)
cd Frontend/lightwave-media-site

# Install dependencies
pnpm install

# Run development server
pnpm dev

# Run tests
pnpm test

# Build for production
pnpm build

# Lint
pnpm lint
```

---

## Key Architecture Patterns

### Context System Architecture

**Two-layer context system:**
- **`.claude/`** - Static, persistent documentation (git-committed)
  - Onboarding checklist, secrets map, troubleshooting
  - Skills and custom agents
  - Persists across Claude Code sessions
- **`.agent/`** - Dynamic, Notion-synced metadata (auto-generated)
  - Status-filtered: Only `Active` documents from Notion appear
  - Structured YAML/JSON for fast RAG queries
  - Task definitions, architecture metadata, SOPs

**Control mechanism:** Change document `Status` in Notion → Claude Code sees/ignores it automatically.

### Infrastructure as Code

- **Pattern:** `infrastructure-catalog` (modules) + `infrastructure-live` (configs)
- **Tool:** Terragrunt orchestrating OpenTofu (fork of Terraform)
- **Structure:** `account/region/resources` hierarchy
- **State:** Remote state in S3, managed by Terragrunt
- **Deployment:** Use Terragrunt Stacks for multi-component deployments

### Naming Conventions

All conventions are documented in `.agent/metadata/naming_conventions.yaml`:

- **Repositories:** `lightwave-[function]` (kebab-case)
- **Branches:** `feature/[task-id]-[description]` or `bugfix/[description]`
- **Commits:** Conventional Commits format (`feat:`, `fix:`, `docs:`, etc.)
- **Docker images:** `ghcr.io/lightwave-media/[service]:[tag]`
- **Python:** snake_case for files, functions, variables; PascalCase for classes
- **JavaScript/TypeScript:** camelCase for variables/functions; PascalCase for classes/components

### Multi-Repo Workflow

**Critical:** This is a multi-repo workspace. Before running git commands:
1. Verify current directory with `pwd`
2. Ensure you're in the correct repository (not workspace root)
3. Check git status to confirm repository context

---

## Common Tasks

### Emergency Shutdown

If AWS costs are unexpectedly high, trigger emergency shutdown:

```bash
gh workflow run emergency-shutdown.yml -f environment=dev
```

This stops all ECS tasks, sets service counts to 0, stops RDS and ElastiCache (~2 minutes).

### Working with Secrets

**Never ask for credentials without checking first:**
1. Read `.claude/reference/SECRETS_MAP.md` (if it exists)
2. Use documented AWS Secrets Manager IDs
3. Always use `AWS_PROFILE=lightwave-admin-new` for admin access

### Task-Driven Development

When working on a specific task:
1. Load task definition: `.agent/tasks/{task-id}.yaml`
2. Read SOP: `.agent/sops/SOP_{TASK_NAME}.md`
3. Check architecture metadata: `.agent/metadata/` (relevant YAML files)
4. Follow TDD workflow from SOP

---

## Architecture Reference

### Query Patterns for Fast Lookups

Instead of reading full documentation, query structured metadata:

| Question | File | Path |
|----------|------|------|
| What framework for frontend? | `tech_stack.yaml` | `.frontend.framework.name` |
| Where is backend deployed? | `deployment.yaml` | `.environments.production.backend.platform` |
| What's our auth strategy? | `frontend_architecture.yaml` | `.auth_strategy.type` |
| Naming conventions? | `naming_conventions.yaml` | Various decision trees |
| Git branch patterns? | `git_conventions.yaml` | `.branches.pattern` |

All files in `.agent/metadata/` directory.

### Tech Stack Summary

- **Backend:** Django 5.0+, Python 3.11+, PostgreSQL, Redis
- **Frontend:** Next.js 15, Payload CMS 3.x, TypeScript, Tailwind CSS
- **Infrastructure:** AWS (ECS Fargate, RDS, ElastiCache), OpenTofu, Terragrunt
- **Package Manager:** uv (Python), pnpm (Node.js)
- **Container Registry:** GitHub Container Registry (ghcr.io)
- **Deployment:** Cloudflare Pages (frontend), AWS ECS (backend)

---

## Documentation Hierarchy

**Read in this order when starting work:**

1. **Workspace-level:** `CLAUDE.md` (this file) + `.claude/ONBOARDING.md`
2. **Repository-specific:** Navigate to specific repo, read its `CLAUDE.md`
3. **Task-specific:** `.agent/tasks/{task-id}.yaml` + corresponding SOP
4. **Reference:** `.agent/metadata/` files as needed for specific queries

**Never skip the onboarding checklist** - it contains verification steps you must complete and report.

---

## Specialized Agents

This workspace includes custom agent definitions in `.claude/agents/`:

- **api-architect** - API design, REST endpoints, authentication patterns
- **software-architect** - System documentation, architecture decisions
- **zen-code-generator** - Production-quality code generation
- **codebase-structure-auditor** - File organization verification

These agents automatically load relevant sections from `.agent/metadata/` for efficiency.

---

## Common Pitfalls

❌ **Don't:**
- Run AWS commands without setting `AWS_PROFILE=lightwave-admin-new`
- Skip reading `.claude/ONBOARDING.md` at session start
- Run git commands in workspace root (need to be in specific repo)
- Ask for credentials documented in SECRETS_MAP.md
- Create new solutions when existing scripts/docs exist

✅ **Do:**
- Set AWS profile BEFORE any AWS commands
- Complete and report onboarding verification
- Verify which repository you're in with `pwd`
- Check `.agent/` metadata before asking architectural questions
- Follow TDD workflow from SOPs

---

## Emergency Contacts & Resources

- **Documentation:** `.claude/` folder (persistent) + `.agent/` folder (dynamic)
- **Issues:** Check `.claude/reference/TROUBLESHOOTING.md` (if exists)
- **Architecture:** `.agent/metadata/` (structured YAML/JSON)
- **Tasks:** `.agent/tasks/` (current work)
- **Processes:** `.agent/sops/` (step-by-step guides)

---

**Last Updated:** 2025-10-28
**Maintained By:** Joel Schaeffer + Claude Code
**Version:** 1.0.0
