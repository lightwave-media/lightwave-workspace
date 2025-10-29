# SOP: Context Control System - Managing Claude Code's Knowledge

**Version**: 1.0.0
**Created**: 2025-10-26
**Owner**: Joel Schaeffer
**Purpose**: Define how to use Notion as a declarative context control system for Claude Code

---

## 📖 Overview

### What is the Context Control System?

The **Context Control System** uses Notion's database filtering to control **exactly what context** Claude Code loads during a session. By marking documents as `Active` or `Deprecated` in Notion, you control whether Claude Code sees that information—preventing outdated decisions from causing mistakes.

### Why Does This Matter?

**Problem Without Context Control:**
- Claude Code reads outdated architecture decisions from 6 months ago
- Implements deprecated patterns that were replaced
- Context window fills with irrelevant historical docs
- Mistakes happen because "old context" conflicts with "new reality"

**Solution With Context Control:**
- You mark documents as `Active` (Claude sees them) or `Deprecated` (Claude doesn't)
- Only **current, approved** documentation syncs to `.agent/` files
- Context window stays focused on **present system state**
- Architecture migrations are clean: flip status, Claude adapts instantly

---

## 🎯 Core Concept: Status as Context Filter

### The Pattern

```
Notion Database (SSOT)
  ↓ Filter by Status=Active + Agent Tags
Sync to .agent/ files
  ↓ Claude Code reads .agent/
Claude implements using current context
```

**Key Insight:** Notion's `Status` field acts as a **binary switch** for context visibility:
- `Status = Active` → Synced to `.agent/` → Claude Code sees it
- `Status = Draft/Deprecated/Superseded` → Not synced → Claude Code doesn't see it

---

## 📊 Status Lifecycle

### Status Values & Meanings

| Status | Visibility | Use When | Example |
|--------|------------|----------|---------|
| **Draft** | Hidden | Writing/discussing decision | "Should we use Redis or Memcached?" (exploring options) |
| **Active** | Visible | Decision is finalized & implemented | "Use Redis for sessions" (Claude follows this) |
| **Deprecated** | Hidden | No longer recommended, no replacement yet | "Use AWS RDS" (moving away, but not migrated yet) |
| **Superseded** | Hidden | Replaced by newer decision | "Use MySQL" (superseded by "Use PostgreSQL" in ADR-005) |

### Status Flow Diagram

```
Draft
  ↓ (Decision finalized)
Active
  ↓ (New approach adopted)
Deprecated
  ↓ (Replacement implemented)
Superseded
```

---

## 🗃️ Notion Database Schema

### Required Fields

Your **Global Documents DB** should have these fields:

| Field Name | Type | Options/Values | Purpose |
|------------|------|----------------|---------|
| **Status** | Select | `Active`, `Draft`, `Deprecated`, `Superseded` | Controls visibility to Claude Code |
| **Agent Tags** | Multi-select | `agent:v_senior_developer`, `agent:v_product_architect`, etc. | Controls which agents see this doc |
| **Document Type** | Select | `ADR`, `SOP`, `Task`, `Architecture`, `Reference`, `Namespace`, `Git Convention` | Categorizes doc type |
| **Life Domain** | Select | `Product-Development`, `cineOS`, `photoOS`, etc. | Associates with product domain |
| **Last Reviewed** | Date | (Date picker) | When doc was last validated |
| **Notion ID** | Formula | `id()` | Auto-generated Notion page ID |

### Recommended Views

Create **filtered database views** per agent:

**View: "v_senior_developer:(active)"**
```yaml
Filters:
  - Agent Tags contains "agent:v_senior_developer"
  - Status is "Active"

Sort:
  - Last Reviewed (descending)
```

**View: "All Draft Docs"**
```yaml
Filters:
  - Status is "Draft"

Sort:
  - Created Time (descending)
```

**View: "Deprecated (Needs Migration)"**
```yaml
Filters:
  - Status is "Deprecated"
  - Life Domain is "Product-Development"
```

---

## 🔄 Sync Process

### How Notion → `.agent/` Sync Works

**Step 1: Notion Database Query**
```yaml
Query: Global Documents DB
Filters:
  - Agent Tags contains "agent:v_senior_developer"
  - Status equals "Active"
  - Document Type in ["ADR", "Namespace", "Git Convention"]
```

**Step 2: Transform to YAML**
```yaml
# .agent/metadata/decisions.yaml
decisions:
  - id: "ADR-002"
    status: "Active"  # Only Active decisions appear
    notion_id: "abc123"
    notion_url: "https://notion.so/abc123"
    title: "Use Cloudflare for frontend"
    # ... rest of decision
```

**Step 3: Claude Code Reads `.agent/`**
- When Claude Code starts a task, it reads `.agent/metadata/` files
- Only sees **Active** decisions/conventions/namespaces
- Implements accordingly

### Sync Frequency

**Options:**
1. **On-demand (Manual)**: Run sync script when you update Notion
2. **On task start**: MCP tool queries Notion at session start
3. **Scheduled**: Cron job syncs every 30 minutes

**Recommended**: On-demand for now, scheduled sync for production.

---

## 🛠️ Workflows

### Workflow 1: Creating a New Architecture Decision

**Scenario**: You're deciding whether to use JWT or sessions for auth.

**Steps:**

1. **Create ADR in Notion**
   - Open Global Documents DB
   - New page: "ADR-005: Use JWT for Authentication"
   - Set `Status = Draft`
   - Set `Document Type = ADR`
   - Set `Agent Tags = agent:v_senior_developer`

2. **Research & Document**
   - Fill in context, decision, consequences
   - Status stays `Draft` (Claude Code doesn't see it yet)

3. **Finalize Decision**
   - After team agreement, change `Status = Active`
   - Run sync: `python scripts/sync_notion_to_agent.py`

4. **Verify Sync**
   - Check `.agent/metadata/decisions.yaml`
   - ADR-005 should now appear with `status: Active`

5. **Claude Code Implements**
   - Next Claude Code session reads ADR-005
   - Implements JWT auth following your decision

**Result**: Claude Code only saw the decision **after** you finalized it.

---

### Workflow 2: Deprecating Old Architecture

**Scenario**: You're migrating from AWS RDS to Supabase.

**Steps:**

1. **Identify Old Decision**
   - Find ADR-002 "Use AWS RDS" in Notion
   - Currently `Status = Active`

2. **Create New Decision**
   - New page: "ADR-010: Use Supabase PostgreSQL"
   - Set `Status = Draft` (not visible yet)
   - Document migration plan

3. **Transition Period**
   - Keep ADR-002 `Status = Active` (Claude still references RDS)
   - Implement migration in stages

4. **Complete Migration**
   - Mark ADR-010 `Status = Active`
   - Mark ADR-002 `Status = Superseded`
   - Set ADR-002 `superseded_by = ADR-010`
   - Run sync

5. **Verify Context Switch**
   - Check `.agent/metadata/decisions.yaml`
   - ADR-002 should be **gone** (superseded decisions filtered out)
   - ADR-010 should appear with `status: Active`

6. **Claude Code Adapts**
   - Next session, Claude Code only sees Supabase (ADR-010)
   - No longer references AWS RDS

**Result**: Clean architecture transition with no context confusion.

---

### Workflow 3: Preventing Mistakes During Migration

**Scenario**: You're halfway through migrating from Django sessions to JWT. You don't want Claude Code to accidentally implement JWT before migration is ready.

**Steps:**

1. **During Planning Phase**
   - Create "ADR-011: Migrate to JWT" with `Status = Draft`
   - Old decision "ADR-004: Use Django Sessions" stays `Status = Active`

2. **During Implementation**
   - Keep ADR-004 Active (Claude still follows session-based auth)
   - Update ADR-011 Draft with progress notes

3. **Testing Phase**
   - Both ADR-004 (Active) and ADR-011 (Draft) exist
   - Claude Code only sees ADR-004 (sessions)
   - Manual testing of JWT happens in staging

4. **Deployment Day**
   - Mark ADR-011 `Status = Active`
   - Mark ADR-004 `Status = Superseded`
   - Run sync
   - Deploy backend + frontend together

5. **Post-Deployment**
   - Claude Code now only sees ADR-011 (JWT)
   - Future features use JWT automatically

**Result**: No risk of Claude Code implementing half-migrated architecture.

---

## 📋 Agent Tag Strategy

### Why Agent Tags Matter

Different agents need different context:
- `v_senior_developer` needs technical implementation details
- `v_product_architect` needs high-level system design
- `v_write` needs communication guidelines

**Agent Tags** control **which agents see which docs**.

### Tagging Examples

**ADR-002: Infrastructure Split (Cloudflare + AWS)**
- `agent:v_senior_developer` ✅ (implements deployment)
- `agent:v_product_architect` ✅ (designed the split)
- `agent:v_devops_engineer` ✅ (manages infrastructure)
- `agent:v_write` ❌ (doesn't need infra details)

**SOP: Writing User-Facing Docs**
- `agent:v_write` ✅ (follows this SOP)
- `agent:v_senior_developer` ❌ (not relevant)

**Namespace: @lightwave/ui**
- `agent:v_senior_developer` ✅ (uses this package)
- `agent:v_product_architect` ✅ (designed the pattern)

### Tag Naming Convention

```
agent:<agent_name>
```

Examples:
- `agent:v_senior_developer`
- `agent:v_product_architect`
- `agent:v_scrum_manager`
- `agent:v_write`

---

## 🎯 Best Practices

### DO:

✅ **Mark documents Active only when finalized**
- Don't mark `Active` while still drafting/debating

✅ **Use Superseded for replaced decisions**
- Include `superseded_by` field pointing to new ADR

✅ **Review Active docs quarterly**
- Update `Last Reviewed` date in Notion
- Confirm still current or mark Deprecated

✅ **Tag documents with relevant agents**
- Multiple agents can see same doc if relevant

✅ **Document status transitions in Notion**
- Add comment: "Marked Deprecated on 2025-10-26 because..."

### DON'T:

❌ **Don't leave old docs Active indefinitely**
- They'll confuse Claude Code 6 months from now

❌ **Don't mark Deprecated without replacement plan**
- Use Draft for "future state" before marking old state Deprecated

❌ **Don't forget to run sync after status changes**
- Claude Code won't see changes until `.agent/` files update

❌ **Don't use status for "priority" or "importance"**
- Status = visibility control only
- Use separate "Priority" field for that

---

## 🔍 Troubleshooting

### Issue: Claude Code is Using Outdated Pattern

**Symptoms:**
- Claude implements architecture that was replaced 2 months ago
- References deprecated APIs

**Diagnosis:**
1. Check Notion: Is old decision still `Status = Active`?
2. Check `.agent/metadata/decisions.yaml`: Does old decision appear?

**Solution:**
1. Find old decision in Notion
2. Mark `Status = Superseded`
3. Create new decision with `Status = Active`
4. Run sync: `python scripts/sync_notion_to_agent.py`
5. Verify: Old decision removed from `.agent/` files

---

### Issue: Claude Code Doesn't Know About New Decision

**Symptoms:**
- You created new ADR/namespace, Claude Code doesn't reference it

**Diagnosis:**
1. Check Notion: Is new decision `Status = Active`?
2. Check Agent Tags: Does it include `agent:v_senior_developer`?
3. Check `.agent/metadata/`: Has sync run recently?

**Solution:**
1. Verify `Status = Active` in Notion
2. Verify `Agent Tags` includes relevant agent
3. Run sync script
4. Check `.agent/` files for new entry
5. Start new Claude Code session (reloads context)

---

### Issue: Too Many Active Docs, Context Window Full

**Symptoms:**
- Claude Code hits 200K token limit
- Slow response times due to context loading

**Diagnosis:**
1. Check Notion: How many docs have `Status = Active`?
2. Estimate: Each ADR/namespace ~1-2K tokens

**Solution:**
1. Review Active docs: Which are still relevant?
2. Mark rarely-used docs as `Archived` (new status)
3. Use more specific Agent Tags (fewer agents see each doc)
4. Consider splitting large docs into focused pages

---

## 📊 Metrics & Monitoring

### Key Metrics to Track

**Context Health Metrics:**
- **Active Docs Count**: How many docs have `Status = Active`?
- **Last Sync Time**: When was `.agent/` last updated?
- **Stale Docs**: How many docs have `Last Reviewed > 90 days ago`?

**Agent-Specific Metrics:**
- **Docs per Agent**: How many Active docs each agent sees?
- **Token Estimate**: Estimated context window usage per agent?

### Recommended Notion Views

**Dashboard: Context Health**
```yaml
View: "Active Docs by Agent"
Group By: Agent Tags
Filter: Status = Active
Show: Count per group
```

**Dashboard: Stale Documentation**
```yaml
View: "Needs Review"
Filter:
  - Status = Active
  - Last Reviewed < 90 days ago
Sort: Last Reviewed (ascending)
```

---

## 🚀 Advanced: Automated Sync

### Option 1: GitHub Actions Sync

```yaml
# .github/workflows/sync-notion-context.yml
name: Sync Notion to Agent Context

on:
  workflow_dispatch:  # Manual trigger
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run sync script
        env:
          NOTION_API_KEY: ${{ secrets.NOTION_API_KEY }}
        run: python scripts/sync_notion_to_agent.py
      - name: Commit changes
        run: |
          git config user.name "notion-sync-bot"
          git commit -am "chore: sync Notion context" || exit 0
          git push
```

### Option 2: Pre-Task Hook

```python
# scripts/pre_task_sync.py
"""
Run before Claude Code starts a task.
Syncs Notion → .agent/ if data is stale.
"""

import os
from datetime import datetime, timedelta
from notion_client import Client

SYNC_THRESHOLD = timedelta(hours=6)

def should_sync():
    sync_file = ".agent/metadata/.last_sync"
    if not os.path.exists(sync_file):
        return True

    with open(sync_file) as f:
        last_sync = datetime.fromisoformat(f.read().strip())

    return datetime.now() - last_sync > SYNC_THRESHOLD

if __name__ == "__main__":
    if should_sync():
        print("Syncing Notion context...")
        # Run sync logic
        os.system("python scripts/sync_notion_to_agent.py")
    else:
        print("Context is fresh, skipping sync")
```

---

## 📚 Related Documentation

- [`.agent/README.md`](../README.md) - Structured context system overview
- [`.agent/metadata/decisions.yaml`](../metadata/decisions.yaml) - ADR template with status fields
- [`.agent/metadata/namespaces.yaml`](../metadata/namespaces.yaml) - Namespace template with status fields
- [`.agent/metadata/git_conventions.yaml`](../metadata/git_conventions.yaml) - Git conventions with status fields
- [`.claude/MCP_TOOLS.md`](../../.claude/MCP_TOOLS.md) - How to use Notion MCP tools

---

## 📝 Changelog

**v1.0.0 (2025-10-26)**
- Initial SOP created
- Defined status lifecycle (Draft → Active → Deprecated → Superseded)
- Documented Notion database schema requirements
- Added 3 core workflows (create, deprecate, migrate)
- Included agent tag strategy
- Added troubleshooting section

---

**Maintained By**: Joel Schaeffer
**Last Updated**: 2025-10-26
**Status**: Active
