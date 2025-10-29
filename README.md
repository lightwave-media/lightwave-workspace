# LightWave Media Workspace

**Organization:** lightwave-media
**Root Repository:** lightwave-workspace
**Purpose:** Multi-repository workspace for LightWave Media software ecosystem

## Structure

```
lightwave-workspace/                      (THIS REPO)
├── .claude/                              # Claude Code persistent context
├── .agent/                               # Notion-synced metadata
├── .github/workflows/                    # Workspace-level automation
│   ├── emergency-shutdown.yml            # AWS kill switch
│   ├── sync-agent-context.yml            # Sync from Notion
│   └── validate-structure.yml            # Naming conventions check
├── Backend/
│   └── lightwave-backend/                # Django REST API (separate repo)
├── Infrastructure/
│   ├── lightwave-infrastructure-catalog/ # Terraform modules (separate repo)
│   └── lightwave-infrastructure-live/    # Live configs (separate repo)
└── Frontend/
    └── lightwave-media-site/             # Frontend site (separate repo)
```

## Quick Start

1. **Clone workspace:**
   ```bash
   git clone git@github.com:lightwave-media/lightwave-workspace.git
   cd lightwave-workspace
   ```

2. **Clone sub-repositories:**
   ```bash
   ./scripts/clone-all.sh
   ```

3. **Start backend locally:**
   ```bash
   cd Backend/lightwave-backend
   docker compose up
   ```

4. **Deploy infrastructure:**
   ```bash
   cd Infrastructure/lightwave-infrastructure-live/dev
   terragrunt run-all apply
   ```

## Emergency Shutdown

If you need to immediately stop all AWS resources (e.g., surprise bill):

```bash
gh workflow run emergency-shutdown.yml -f environment=dev
```

This will:
- Stop all ECS tasks
- Set ECS service desired count to 0
- Stop RDS instances
- Stop ElastiCache clusters
- All within ~2 minutes

## Repositories

| Repo | Purpose | URL |
|------|---------|-----|
| **lightwave-workspace** | Workspace root (docs, workflows) | https://github.com/lightwave-media/lightwave-workspace |
| **lightwave-backend** | Django REST API | https://github.com/lightwave-media/lightwave-backend |
| **lightwave-infrastructure-catalog** | Terraform modules | https://github.com/lightwave-media/lightwave-infrastructure-catalog |
| **lightwave-infrastructure-live** | Live environment configs | https://github.com/lightwave-media/lightwave-infrastructure-live |
| **lightwave-media-site** | Frontend website | https://github.com/lightwave-media/lightwave-media-site |

## Documentation

- **Workspace SOP:** [CLAUDE.md](./CLAUDE.md)
- **Onboarding:** [.claude/ONBOARDING.md](./.claude/ONBOARDING.md)
- **Secrets Map:** [.claude/reference/SECRETS_MAP.md](./.claude/reference/SECRETS_MAP.md)
- **Troubleshooting:** [.claude/reference/TROUBLESHOOTING.md](./.claude/reference/TROUBLESHOOTING.md)

## Naming Conventions

All repos follow the [LWM Naming Conventions](./NAMING_CONVENTIONS.md):
- Repositories: `lightwave-[function]` (kebab-case)
- Branches: `feature/[task-id]-[description]`
- Commits: Conventional Commits format
- Docker images: `ghcr.io/lightwave-media/[service]:[tag]`

## Development

- **Backend:** Python 3.11+, Django 5.0+, uv package manager
- **Infrastructure:** OpenTofu, Terragrunt, AWS
- **Frontend:** Next.js 15, Payload CMS 3.x, Tailwind CSS
