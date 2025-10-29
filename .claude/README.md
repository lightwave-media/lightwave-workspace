# .claude/ - Persistent Claude Code Configuration

**Purpose**: Static, git-committed documentation that persists across Claude Code sessions.

This folder solves the problem of Claude not remembering context between conversations.

---

## 📁 Contents

### Core Documentation

- **`ONBOARDING.md`** - 🚨 **READ THIS FIRST** - Mandatory checklist for every Claude Code session
- **`SECRETS_MAP.md`** - Definitive guide to where every secret lives (AWS, .env.master, GitHub)
- **`TROUBLESHOOTING.md`** - Common issues and solutions, lessons learned
- **`CLAUDE.md`** - Copy of workspace-level SOP (mirrored from root)

### Templates & Tools

- **`CLAUDE.md.template`** - Template for repo-specific CLAUDE.md files
- **`commands/`** - Custom slash commands (e.g., `/deploy`, `/test-all`)
- **`skills/`** - Custom Claude Code skills

### Configuration

- **`settings.local.json`** - Claude Code local settings

---

## 🎯 How This System Works

### The Problem We Solved

**Before**: Claude kept asking for the same information (Cloudflare token, AWS profile, etc.) every conversation because:
- No persistent memory between sessions
- Documentation scattered across repos
- Secrets location not documented
- No enforced "read this first" pattern

**After**: This `.claude/` folder provides:
- ✅ Persistent, git-committed documentation
- ✅ Mandatory onboarding checklist
- ✅ Centralized secrets management guide
- ✅ Common issues documented with solutions

### The Architecture

```
/Users/joelschaeffer/dev/lightwave-workspace/
│
├── .claude/              # STATIC (git-committed, persistent)
│   ├── ONBOARDING.md     # Start here every time
│   ├── SECRETS_MAP.md    # Where every secret lives
│   ├── TROUBLESHOOTING.md # Known issues & solutions
│   └── README.md         # This file
│
├── .agent/               # DYNAMIC (Notion-synced, auto-generated)
│   ├── metadata/         # Architecture docs from Notion
│   ├── tasks/            # Task definitions
│   └── sops/             # SOPs from Notion
│
└── CLAUDE.md             # Entry point (points to .claude/ONBOARDING.md)
```

**Two Systems, Clear Roles:**
- `.claude/` = Persistent instructions (what Claude should always know)
- `.agent/` = Fresh data from Notion (current work, latest architecture)

---

## 📖 Usage Guide

### For Claude Code

**Every new conversation MUST:**

1. Read `ONBOARDING.md` (2 minutes)
2. Check `.agent/README.md` for Notion sync status
3. Navigate to specific repo
4. Read repo-specific `CLAUDE.md`
5. Check `SECRETS_MAP.md` if credentials needed

**Never skip step 1.** It prevents 90% of repeated issues.

### For Joel

**When Claude asks for something documented:**
- Point to the relevant file (`SECRETS_MAP.md`, `TROUBLESHOOTING.md`, etc.)
- If not documented, add it to the appropriate file
- Keep documentation up to date

**When adding new repos:**
- Copy `CLAUDE.md.template`
- Fill in repo-specific details
- Link back to workspace `.claude/` folder

---

## 🔄 Maintenance

### Updating Documentation

```bash
# Edit files as needed
vim .claude/SECRETS_MAP.md
vim .claude/TROUBLESHOOTING.md

# Commit changes
git add .claude/
git commit -m "docs: update secrets map with new API key location"
git push
```

### Adding New Secrets

1. Store in AWS Secrets Manager (if production)
2. Document in `SECRETS_MAP.md` with exact secret ID and load commands
3. Update `.env.master` if needed for local dev
4. Run `distribute_env.py` to sync

### Documenting New Issues

1. Add to `TROUBLESHOOTING.md` with:
   - Symptoms
   - Root cause
   - Solution (step-by-step)
   - Prevention strategy
2. Reference in `ONBOARDING.md` if critical

---

## ✅ Success Criteria

This system is working if:
- ✅ Claude reads `ONBOARDING.md` at start of every session
- ✅ Claude checks `SECRETS_MAP.md` before asking for credentials
- ✅ Common issues are solved by referencing `TROUBLESHOOTING.md`
- ✅ New issues are documented when they occur
- ✅ Secrets are loaded correctly using documented commands

---

## 🚀 Benefits

**For Claude Code:**
- Persistent context across sessions
- Clear "start here" pattern
- No more asking for documented information
- Faster onboarding (2 minutes vs 20+ minutes of questions)

**For Joel:**
- Less repetition
- Documented solutions to common problems
- Easy to point Claude to relevant docs
- Git history of what's been tried/solved

**For the Project:**
- Knowledge capture and institutional memory
- Onboarding guide for new team members
- Clear documentation structure
- Scalable across multi-repo workspace

---

## 📝 File Versioning

Files in this folder follow semantic versioning principles:

- **Major change** - New required step in ONBOARDING.md
- **Minor change** - New secret added to SECRETS_MAP.md
- **Patch change** - Fix typo, clarify instruction

Update the "Last Updated" timestamp when making changes.

---

## 🔗 Related Documentation

- **Dynamic Docs**: `../.agent/README.md` (synced from Notion)
- **Workspace SOP**: `../CLAUDE.md` (root-level instructions)
- **Repo-Specific**: See `CLAUDE.md` in each repository

---

**Created**: 2025-01-24
**Purpose**: Solve the "Claude doesn't remember" problem
**Maintained By**: Joel Schaeffer + Claude Code
