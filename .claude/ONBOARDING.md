# Claude Code Onboarding Checklist

**🚨 READ THIS FIRST EVERY TIME YOU START A NEW CONVERSATION**

This checklist ensures you have all context before starting work.

**CRITICAL**: After completing this checklist, you MUST report validation status (READY or NOT READY) with proof.

---

## Step 1: Workspace Context (30 seconds)

**CRITICAL FIRST ACTION** - Set AWS Profile:
```bash
export AWS_PROFILE=lightwave-admin-new
```
**ALWAYS run this BEFORE any AWS commands. Failure to do so will cause "lightwave-email-service not authorized" errors.**

**Actions** (run these commands, report what you found):
- [ ] **Set AWS profile**: Run `export AWS_PROFILE=lightwave-admin-new` - MANDATORY
  - Verify: Run `echo $AWS_PROFILE` - Should output `lightwave-admin-new`
  - Verify: Run `aws sts get-caller-identity | grep Arn` - Should show `user/lightwave-admin`
- [ ] **Read workspace instructions**: `.claude/CLAUDE.md` (workspace-level SOP)
  - Verify: Report the version number from the file header
- [ ] **Check latest Notion docs**: `.agent/README.md` (last synced timestamp)
  - Verify: Report the actual "Last Sync" timestamp or "FILE NOT FOUND"
- [ ] **Review current work**: `.agent/tasks/` (PRDs and implementation plans)
  - Verify: List actual task files found or "DIRECTORY EMPTY"
- [ ] **Detect workspace structure**: Check if single-repo or multi-repo workspace
  - Run: `find . -name ".git" -type d -maxdepth 3 2>/dev/null | wc -l`
  - If count = 0: ERROR - no git repos found
  - If count = 1: Single-repo workspace
  - If count > 1: Multi-repo workspace (9+ repos in lightwave)

**Verification Output** (example):
```
✅ AWS Profile set: AWS_PROFILE=lightwave-admin-new
✅ AWS Identity verified: arn:aws:iam::738605694078:user/lightwave-admin
✅ Read CLAUDE.md - Version: 5.4.0
✅ Read .agent/README.md - Last Sync: 2025-10-25 14:30 UTC
✅ Scanned .agent/tasks/ - Found: 5 task files (auth_client.yaml, payload_shared.yaml, django_auth_endpoints.yaml, joelschaeffer_restructure.yaml, fix-onboarding-git-validation.yaml)
✅ Workspace structure: Multi-repo (9 git repositories found)
```

## Step 2: Identify Your Scope (15 seconds)

**CRITICAL**: If Step 1 detected a multi-repo workspace, you MUST ask which repo before running git commands.

**Ask user**: "Which repository are you working in?" (or "Just exploring - no specific repo")

**Repository options** (lightwave-workspace structure):
```
Backend/
└── (Clone your backend repos here)

Frontend/
└── (Clone your frontend repos here: lightwave-media-site, etc.)

Infrastructure/
├── lightwave-infrastructure-catalog/    → Terraform modules (to be cloned)
└── lightwave-infrastructure-live/       → Live Terragrunt configs (to be cloned)
```

**Actions** (after user responds):

**IF user selects a specific repo**:
- [ ] **Note the repo path** - Store for git commands in Step 4
- [ ] **Read repo-specific** `CLAUDE.md` - Report: First line of file or "FILE NOT FOUND"
- [ ] **Verify current directory** - Run: `pwd` to confirm location

**IF user says "just exploring"**:
- [ ] **Skip repo-specific validation** - Git commands will be skipped in Step 4
- [ ] **Stay at workspace root** - Continue with workspace-level context only

**Verification Output** (example - specific repo):
```
✅ User selected: Backend/lightwave-backend
✅ Repo path stored: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
✅ Read Backend/lightwave-backend/CLAUDE.md - Found, version 2.1.0
✅ Current directory: /Users/joelschaeffer/dev/lightwave-workspace (will cd to repo in Step 4)
```

**Verification Output** (example - just exploring):
```
✅ User selected: Just exploring (no specific repo)
✅ Git validation will be skipped
✅ Workspace-level context loaded
```

## Step 3: Load Secrets (if needed) (30 seconds)

**Ask user**: "Do you need credentials?" (AWS, Cloudflare, API keys, etc.)

**If YES**:
- [ ] **Read** `.claude/SECRETS_MAP.md` - Verify file exists
- [ ] **Use secrets-loader skill**: `.claude/skills/secrets-loader.md` - Follow step-by-step
- [ ] **Verify AWS profile**: Run `echo $AWS_PROFILE` - Should show `lightwave-admin-new`

**Verification Output** (example):
```
✅ Read SECRETS_MAP.md - Found
✅ Followed secrets-loader skill
✅ AWS Profile verified: AWS_PROFILE=lightwave-admin-new
✅ Loaded: CLOUDFLARE_API_TOKEN (first 10 chars: cf_1234567)
```

**If NO**:
```
⊘ Skipped - No credentials needed for this task
```

## Step 4: Verify Environment (30 seconds)

**Actions** (run these, report ACTUAL results):

**Git Validation** (depends on Step 2 selection):

**IF user selected a specific repo in Step 2**:
- [ ] **Navigate to repo**: Run `cd /Users/joelschaeffer/dev/lightwave-workspace/{REPO_PATH}`
- [ ] **Check git branch**: Run `git branch --show-current`
- [ ] **Check git status**: Run `git status --porcelain | wc -l` (count uncommitted files)
- [ ] **Verify current directory**: Run `pwd`

**IF user said "just exploring"**:
- [ ] **Skip git validation** - Git branch/status not required
- [ ] **Verify workspace location**: Run `pwd` (should be in /Users/joelschaeffer/dev/lightwave-workspace)

**AWS Validation** (if credentials needed):
- [ ] **Check AWS profile**: Run `echo $AWS_PROFILE` (should be `lightwave-admin-new`)
- [ ] **Verify AWS identity**: Run `aws sts get-caller-identity` (should be account 738605694078)

**Verification Output** (example - specific repo):
```
✅ Navigated to: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
✅ Git branch: dev
✅ Uncommitted changes: 10 files modified
✅ Current directory: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
✅ AWS profile: lightwave-admin-new
✅ AWS account: 738605694078 (User: lightwave-admin)
```

**Verification Output** (example - just exploring):
```
⊘ Git validation skipped (no specific repo selected)
✅ Workspace location: /Users/joelschaeffer/dev/lightwave-workspace
✅ AWS profile: lightwave-admin-new
✅ AWS account: 738605694078 (User: lightwave-admin)
```

**OR if error**:
```
❌ Navigate to repo: cd command failed
   ERROR: Repo path does not exist!
❌ Git branch: ERROR - not a git repository
✅ AWS account: 738605694078 (User: lightwave-admin)

BLOCKING ISSUE: Repository path invalid or not a git repo
```

## Step 5: Load Activity-Specific Context

**Ask user**: "What type of task are you working on?"

**Options**:
- Backend feature → Use `.claude/skills/task-workflow.md` + read `.agent/metadata/tech_stack.yaml`
- Frontend feature → Use `.claude/skills/task-workflow.md` + read `.agent/metadata/frontend_architecture.yaml`
- Infrastructure deployment → Read `.agent/metadata/deployment.yaml`
- Troubleshooting → Use `.claude/skills/troubleshooter.md`
- General/exploratory → Skip, ready to start

**Verification Output** (example):
```
✅ Task type: Backend feature implementation
✅ Read .claude/skills/task-workflow.md
✅ Read .agent/metadata/tech_stack.yaml
✅ Ready to follow TDD workflow
```

---

## Step 6: Execute Skills Reference

**Skills Available** (`.claude/skills/`):
- `onboarding.md` - Detailed onboarding workflow (you're following the checklist version)
- `secrets-loader.md` - AWS secrets loading process
- `task-workflow.md` - Complete TDD feature implementation
- `troubleshooter.md` - Systematic issue diagnosis

**When to use skills**: Reference the appropriate skill when you need step-by-step guidance for that activity.

---

## Final Validation Report

**After completing all steps, generate this report**:

```yaml
context_validation:
  status: READY | NOT_READY
  timestamp: [ISO 8601 UTC timestamp]

  workspace_context:
    claude_md_version: [actual version or ERROR]
    agent_docs_last_sync: [actual timestamp or ERROR]
    task_files_found: [count or ERROR]
    workspace_type: single-repo | multi-repo | unknown
    git_repos_found: [count for multi-repo, or 1 for single-repo]

  scope_identified:
    current_directory: [actual pwd output]
    selected_repo: [repo name or "just exploring" or N/A]
    repo_path: [full path to selected repo or N/A]
    repo_claude_md: [found/not found or N/A]
    git_branch: [actual branch or "skipped" or ERROR]

  secrets_status:
    needed: true/false
    aws_profile: [actual $AWS_PROFILE or N/A]
    tokens_loaded: [list of tokens or N/A]

  environment_verified:
    pwd: [actual output]
    git_branch: [actual output or "skipped"]
    git_uncommitted_files: [count or "skipped"]
    aws_account: [actual account ID or N/A]

  activity_context:
    task_type: [user provided task type]
    skill_loaded: [skill name or none]
    metadata_loaded: [file names or none]

  blocking_issues: [list or empty]

  ready_to_work: true/false
```

**Example READY report** (multi-repo, specific repo selected):
```yaml
context_validation:
  status: READY
  timestamp: 2025-10-28T19:30:00Z

  workspace_context:
    claude_md_version: 5.5.0
    agent_docs_last_sync: 2025-10-25 14:30 UTC
    task_files_found: 5
    workspace_type: multi-repo
    git_repos_found: 3

  scope_identified:
    current_directory: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
    selected_repo: Backend/lightwave-backend
    repo_path: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
    repo_claude_md: found
    git_branch: dev

  secrets_status:
    needed: true
    aws_profile: lightwave-admin-new
    tokens_loaded: [CLOUDFLARE_API_TOKEN]

  environment_verified:
    pwd: /Users/joelschaeffer/dev/lightwave-workspace/Backend/lightwave-backend
    git_branch: dev
    git_uncommitted_files: 10
    aws_account: 738605694078

  activity_context:
    task_type: backend_feature
    skill_loaded: task-workflow.md
    metadata_loaded: [tech_stack.yaml]

  blocking_issues: []

  ready_to_work: true
```

**Example READY report** (just exploring):
```yaml
context_validation:
  status: READY
  timestamp: 2025-10-28T19:30:00Z

  workspace_context:
    claude_md_version: 5.5.0
    agent_docs_last_sync: 2025-10-25 14:30 UTC
    task_files_found: 5
    workspace_type: multi-repo
    git_repos_found: 3

  scope_identified:
    current_directory: /Users/joelschaeffer/dev/lightwave-workspace
    selected_repo: "just exploring"
    repo_path: N/A
    repo_claude_md: N/A
    git_branch: skipped

  secrets_status:
    needed: false
    aws_profile: N/A
    tokens_loaded: []

  environment_verified:
    pwd: /Users/joelschaeffer/dev/lightwave-workspace
    git_branch: skipped
    git_uncommitted_files: skipped
    aws_account: N/A

  activity_context:
    task_type: exploratory
    skill_loaded: none
    metadata_loaded: []

  blocking_issues: []

  ready_to_work: true
```

**Example NOT READY report** (wrong directory):
```yaml
context_validation:
  status: NOT_READY
  timestamp: 2025-10-28T19:30:00Z

  workspace_context:
    claude_md_version: ERROR - File not found
    agent_docs_last_sync: ERROR - File not found: .agent/README.md
    task_files_found: ERROR - Directory not found: .agent/tasks/
    workspace_type: unknown
    git_repos_found: 0

  scope_identified:
    current_directory: /Users/joelschaeffer/dev
    selected_repo: N/A
    repo_path: N/A
    repo_claude_md: ERROR - not in workspace
    git_branch: ERROR - no git repos found

  secrets_status:
    needed: true
    aws_profile: ERROR - not set
    tokens_loaded: []

  environment_verified:
    pwd: /Users/joelschaeffer/dev
    git_branch: ERROR
    git_uncommitted_files: ERROR
    aws_account: ERROR - AWS profile not set

  activity_context:
    task_type: backend_feature
    skill_loaded: ERROR - cannot load without workspace context
    metadata_loaded: ERROR

  blocking_issues:
    - Not in lightwave-workspace directory (/Users/joelschaeffer/dev/lightwave-workspace)
    - .agent/ docs not found (not in workspace)
    - AWS profile not configured
    - No git repositories found

  ready_to_work: false
```

---

## Common Mistakes to Avoid

❌ **DON'T**:
- Ask for values that are in SECRETS_MAP.md
- Use wrong AWS profile (lightwave-email-service has limited permissions)
- Skip reading repo-specific CLAUDE.md
- Work without loading latest `.agent/` docs from Notion
- Create new solutions when existing scripts exist

✅ **DO**:
- Read SECRETS_MAP.md FIRST before asking for credentials
- Use `lightwave-admin-new` AWS profile for admin tasks
- Read repo CLAUDE.md to understand environment setup
- Check for existing scripts in `scripts/` folders
- Look for patterns in file names and folder structure

---

## Quick Reference

| Need | Location |
|------|----------|
| Secrets/Credentials | `.claude/SECRETS_MAP.md` |
| Common Issues | `.claude/TROUBLESHOOTING.md` |
| Workspace SOP | `.claude/CLAUDE.md` |
| Latest from Notion | `.agent/README.md` |
| Architecture Docs | `.agent/system/` |
| Current Tasks | `.agent/tasks/` |
| Process Guides | `.agent/sops/` |

---

## Time Investment

**2 minutes at start = saves 20+ minutes of confusion later**

This onboarding checklist prevents:
- Asking for information that's documented
- Using wrong AWS credentials
- Missing critical context
- Repeating solved problems

---

## Still Confused?

1. Read `.claude/TROUBLESHOOTING.md` - Common issues and solutions
2. Check `.agent/README.md` - Last sync status from Notion
3. Review workspace structure in root `CLAUDE.md`

---

**Last Updated**: 2025-10-28
**Version**: 2.0.1 (Updated paths for lightwave-workspace)
**Maintained By**: Joel Schaeffer
**Purpose**: Make Claude Code context persistent and reliable with hallucination prevention
