# .agent/ - Structured Context System

**Version**: 1.0.0  
**Created**: 2025-10-25  
**Purpose**: Fast, structured context for AI agents with minimal token usage

---

## Overview

This directory contains **structured, queryable documentation** designed for optimal RAG (Retrieval-Augmented Generation) performance. Unlike traditional markdown files, these files use YAML/JSON formats for fast, reliable queries.

**Key Principles**:
1. **Minimize context loading while maximizing accuracy**
2. **Status-filtered sync from Notion** - Only `Active` documents appear here
3. **Declarative context control** - Change status in Notion, Claude Code adapts instantly

### 🎯 Context Control via Notion Status

**Critical Concept**: Files in `.agent/` are **synced from Notion** and **filtered by Status**.

- ✅ `Status = Active` in Notion → Document appears in `.agent/` → Claude Code sees it
- ❌ `Status = Draft/Deprecated/Superseded` → Document filtered out → Claude Code doesn't see it

**Why This Matters**: You control what Claude Code knows by marking documents Active/Inactive in Notion. This prevents outdated decisions from causing implementation mistakes.

**See**: [`.agent/sops/SOP_CONTEXT_CONTROL_SYSTEM.md`](./sops/SOP_CONTEXT_CONTROL_SYSTEM.md) for complete documentation.

---

## Directory Structure

```
.agent/
├── README.md                    # This file
├── metadata/                    # Structured architecture metadata (YAML)
│   ├── frontend_architecture.yaml
│   ├── deployment.yaml
│   ├── tech_stack.yaml
│   ├── packages.json
│   ├── namespaces.yaml          # ⭐ NEW: Namespace naming and story
│   ├── git_conventions.yaml     # ⭐ NEW: Git branching, tags, commits
│   ├── decisions.yaml           # ⭐ NEW: Architecture Decision Records
│   └── system_story.md          # ⭐ NEW: The "why" behind LightWave
├── tasks/                       # Task definitions (YAML)
│   ├── auth_client.yaml
│   ├── payload_shared.yaml
│   ├── django_auth_endpoints.yaml
│   └── joelschaeffer_restructure.yaml
├── sops/                        # Standard Operating Procedures (Markdown)
│   ├── SOP_CONTEXT_CONTROL_SYSTEM.md  # ⭐ NEW: How status filtering works
│   ├── SOP_CREATE_LIGHTWAVE_AUTH_CLIENT.md
│   ├── SOP_CREATE_PAYLOAD_SHARED_PACKAGE.md
│   ├── SOP_CREATE_DJANGO_AUTH_ENDPOINTS.md
│   └── SOP_RESTRUCTURE_FRONTEND_SITE.md
└── schemas/                     # JSON Schema validation
    ├── task.schema.json
    ├── package.schema.json
    └── architecture.schema.json
```

---

## File Types and Usage

### 1. Metadata Files (`metadata/`)

**Format**: YAML  
**Purpose**: Fast queries for architecture decisions, tech stack, deployment config  
**When to use**: Need specific facts without reading long markdown

**Example**: Get auth strategy
```yaml
# Query: What's our auth strategy?
# File: frontend_architecture.yaml
auth_strategy:
  type: "session-based"
  flow: "Django sessions + cookies"
  frontend_implementation: "@lightwave/auth-client (thin wrapper)"
```

**Files** (all synced from Notion with `Status=Active` filter):
- `frontend_architecture.yaml` - Frontend architecture decisions
- `tech_stack.yaml` - Technology choices and rationale
- `deployment.yaml` - Deployment configuration for all environments
- `packages.json` - Package registry with metadata
- `namespaces.yaml` - Namespace naming strategy and story (status-filtered)
- `git_conventions.yaml` - Git branching, tagging, commit patterns (status-filtered)
- `decisions.yaml` - Architecture Decision Records / ADRs (status-filtered)
- `system_story.md` - The narrative "why" behind LightWave

**Status Filtering**: Files marked with "(status-filtered)" only include entries where `Status=Active` in Notion. Draft/Deprecated/Superseded entries are automatically excluded.

### 2. Task Definitions (`tasks/`)

**Format**: YAML  
**Purpose**: Structured task specs with acceptance criteria, tests, DOD checklist  
**When to use**: Starting work on a task - load ONLY the relevant task file

**Structure**:
```yaml
task_id: "LW-AUTH-CLIENT-001"
title: "Create @lightwave/auth-client Package"
status: "not_started"
priority: "P0"
assigned_agent: "v_senior_developer"
acceptance_criteria:
  - criterion: "Login function calls Django /api/auth/login/ endpoint"
    testable: true
    test_type: "integration"
    test_file: "__tests__/auth.test.ts"
testing:
  coverage_requirement: 100
  test_types: [...]
checklist: [...]
```

**Query Pattern**: "What are the acceptance criteria for LW-AUTH-CLIENT-001?"  
**Answer**: Parse task YAML, return `acceptance_criteria` array

**Files**:
- `auth_client.yaml` - Create @lightwave/auth-client package
- `payload_shared.yaml` - Create @lightwave/payload-shared package
- `django_auth_endpoints.yaml` - Build Django auth API endpoints
- `joelschaeffer_restructure.yaml` - Restructure joelschaeffer.com site

### 3. SOPs (`sops/`)

**Format**: Markdown  
**Purpose**: Detailed step-by-step implementation guides  
**When to use**: Executing a task - read AFTER loading task definition

**Structure**:
- Prerequisites checklist
- Step-by-step TDD workflow (RED → GREEN → REFACTOR)
- Code examples
- Testing requirements
- Troubleshooting section
- Definition of Done checklist

**Files**:
- `SOP_CREATE_LIGHTWAVE_AUTH_CLIENT.md` - How to create auth client package
- `SOP_CREATE_PAYLOAD_SHARED_PACKAGE.md` - How to create Payload shared package
- `SOP_CREATE_DJANGO_AUTH_ENDPOINTS.md` - How to build Django auth endpoints
- `SOP_RESTRUCTURE_FRONTEND_SITE.md` - How to migrate a site to shared packages

### 4. Schemas (`schemas/`)

**Format**: JSON Schema  
**Purpose**: Validate YAML/JSON files for correctness  
**When to use**: Creating new task/metadata files, CI/CD validation

**Files**:
- `task.schema.json` - Validates task definition files
- `package.schema.json` - Validates package metadata
- `architecture.schema.json` - Validates architecture metadata

---

## Workflow: How to Use This System

### Scenario 1: Starting a New Task

**User says**: "Work on task LW-AUTH-CLIENT-001"

**Agent workflow**:
1. **Load task definition**: Read `.agent/tasks/auth_client.yaml`
   - Get acceptance criteria
   - Get testing requirements
   - Get SOP reference
2. **Load SOP**: Read `.agent/sops/SOP_CREATE_LIGHTWAVE_AUTH_CLIENT.md`
   - Get step-by-step instructions
3. **Load metadata** (if needed): Read `.agent/metadata/frontend_architecture.yaml`
   - Verify auth strategy
   - Check CORS configuration
4. **Start implementation**: Follow SOP with TDD approach

**Context loaded**: ~3 files instead of 10+ markdown files

### Scenario 2: Architecture Question

**User asks**: "What's our deployment strategy?"

**Agent workflow**:
1. **Load metadata**: Read `.agent/metadata/deployment.yaml`
2. **Parse YAML**: Extract `environments` → `production` → `frontend`
3. **Answer**: "Cloudflare Pages with auto-deploy from main branch"

**Context loaded**: 1 file, <500 tokens

### Scenario 3: Verifying Task Completeness

**User asks**: "Is LW-AUTH-CLIENT-001 complete?"

**Agent workflow**:
1. **Load task**: Read `.agent/tasks/auth_client.yaml`
2. **Check checklist**: Parse `checklist` array
3. **Verify**:
   - [ ] Package structure created? Check filesystem
   - [ ] 100% test coverage? Run coverage report
   - [ ] Published to npm? Check registry
4. **Answer**: "No - missing npm publish step"

**Context loaded**: 1 file, no SOP needed

---

## RAG Query Patterns

### Fast Queries (Metadata Only)

| Question | File | Query |
|----------|------|-------|
| What framework for frontend? | `tech_stack.yaml` | `.frontend.framework.name` |
| Where is backend deployed? | `deployment.yaml` | `.environments.production.backend.platform` |
| What's our auth strategy? | `frontend_architecture.yaml` | `.auth_strategy.type` |
| Which packages exist? | `packages.json` | `.packages[].name` |
| What's the namespace pattern? | `namespaces.yaml` | `.naming_patterns.shared_packages` |
| What's the git branch pattern? | `git_conventions.yaml` | `.branches.pattern` |
| How should I name a repository? | `naming_conventions.yaml` | `.decision_trees.repository_naming` |
| What case style for Python files? | `naming_conventions.yaml` | `.case_styles.snake_case` |
| What's the branch naming pattern? | `naming_conventions.yaml` | `.decision_trees.branch_naming.patterns.feature` |
| Why did we choose X? | `decisions.yaml` | `.decisions[] | select(.title == "X")` |
| What's the product vision? | `system_story.md` | See "The Origin Story" section |

### Task-Specific Queries (Task + SOP)

| Question | Files | What to Load |
|----------|-------|--------------|
| How do I create auth client? | `auth_client.yaml` + SOP | Task acceptance criteria → SOP steps |
| What are DOD requirements? | `auth_client.yaml` | `.checklist[]` |
| Where are test files? | `auth_client.yaml` | `.testing.test_files[]` |
| What's blocked? | `auth_client.yaml` | `.blocked_by_tasks[]` |

### Deep Queries (Full Context)

| Question | Files | What to Load |
|----------|-------|--------------|
| Implement auth client end-to-end | All auth_client files | Task → SOP → Architecture → Tech Stack |
| Plan frontend restructure | All frontend files | Tasks → SOPs → Frontend Architecture |

---

## Validation

All YAML/JSON files can be validated against schemas:

```bash
# Validate task definition
ajv validate -s .agent/schemas/task.schema.json -d .agent/tasks/auth_client.yaml

# Validate package metadata
ajv validate -s .agent/schemas/package.schema.json -d .agent/metadata/packages.json

# Validate architecture metadata
ajv validate -s .agent/schemas/architecture.schema.json -d .agent/metadata/frontend_architecture.yaml
```

---

## Maintenance

### Adding a New Task

1. Create task YAML: `.agent/tasks/{task-id}.yaml`
2. Validate: `ajv validate -s .agent/schemas/task.schema.json -d .agent/tasks/{task-id}.yaml`
3. Create SOP (if needed): `.agent/sops/SOP_{TASK_NAME}.md`
4. Link SOP in task: `sop_file: ".agent/sops/SOP_{TASK_NAME}.md"`

### Adding New Metadata

1. Create metadata file: `.agent/metadata/{domain}.yaml`
2. Validate: `ajv validate -s .agent/schemas/architecture.schema.json -d .agent/metadata/{domain}.yaml`
3. Update this README if new query patterns emerge

### Updating SOPs

1. Edit SOP markdown file
2. Update `version` and `last_updated` fields
3. Add changelog entry

---

## Comparison: .agent/ vs .claude/

| Directory | Purpose | Format | Audience | Update Frequency |
|-----------|---------|--------|----------|------------------|
| `.agent/` | Structured context for RAG | YAML/JSON | AI agents | As architecture evolves |
| `.claude/` | Persistent context across sessions | Markdown | Claude Code specifically | As needed (secrets, troubleshooting) |

**Use .agent/ when**:
- Need fast, structured queries
- Building context for task execution
- Validating completeness
- Querying architecture decisions

**Use .claude/ when**:
- Need secrets locations (SECRETS_MAP.md)
- Troubleshooting common issues
- Understanding terminology (GLOSSARY.md)
- Onboarding new Claude sessions

---

## Benefits of This Approach

### 1. Minimal Token Usage
- Load only what you need
- YAML/JSON more compact than markdown
- Specific queries don't require full context

### 2. Repeatable Queries
- Same query always returns same result
- No ambiguity in parsing
- Schema-validated for correctness

### 3. Fast Retrieval
- No reading entire markdown files
- Direct access to specific fields
- Perfect for RAG systems

### 4. Testable
- JSON Schema validation
- Can verify completeness automatically
- CI/CD integration

---

## Examples

### Example 1: Load Task Context

```yaml
# Query: Get acceptance criteria for auth client
# File: tasks/auth_client.yaml

acceptance_criteria:
  - criterion: "Package structure created with proper TypeScript configuration"
    testable: true
    test_type: "unit"
  
  - criterion: "Login function calls Django /api/auth/login/ endpoint"
    testable: true
    test_type: "integration"
    test_file: "__tests__/auth.test.ts"
  
  - criterion: "100% test coverage achieved"
    testable: true
    test_type: "coverage"
    test_command: "pnpm test --coverage"
```

### Example 2: Query Deployment Config

```yaml
# Query: Where is production backend deployed?
# File: metadata/deployment.yaml

environments:
  production:
    backend:
      platform: "AWS ECS Fargate"
      cluster: "lightwave-prod"
      url: "https://api.lightwave-media.ltd"
      auto_scaling:
        min: 1
        max: 5
```

### Example 3: Get Package Info

```json
// Query: What packages exist and their status?
// File: metadata/packages.json

{
  "packages": [
    {
      "name": "@lightwave/ui",
      "status": "published",
      "version": "0.1.0",
      "location": "Backend/Lightwave-Platform/lightwave-ui"
    },
    {
      "name": "@lightwave/auth-client",
      "status": "not_started",
      "location": "Backend/Lightwave-Platform/lightwave-auth-client"
    }
  ]
}
```

---

## Agent Knowledge Mapping

Each specialized agent loads only the metadata sections it needs for its role:

### api-architect
**Role**: Design REST APIs, authentication, database schemas

**Required metadata**:
- `naming_conventions.yaml` → `.api_conventions`, `.django_specifics`, `.fastapi_specifics`
- `frontend_architecture.yaml` → `.auth`, `.api_conventions`
- `tech_stack.yaml` → `.backend`, `.database`

**Use cases**:
- Designing API endpoints
- Authentication flow implementation
- Database schema design
- CORS configuration

**Token estimate**: ~2,500 tokens (10x more efficient than loading full docs)

### zen-code-generator
**Role**: Generate production-quality code in any language

**Required metadata**:
- `naming_conventions.yaml` → `.code_elements`, `.testing_conventions`, `.decision_trees.file_naming`
- `tech_stack.yaml` → All sections
- `git_conventions.yaml` → `.commits`

**Use cases**:
- Writing new features
- Refactoring code
- Generating tests
- Code review

**Token estimate**: ~3,000 tokens

### software-architect
**Role**: System design, architecture decisions, documentation

**Required metadata**:
- `naming_conventions.yaml` → All sections
- `frontend_architecture.yaml` → All sections
- `decisions.yaml` → All sections
- `deployment.yaml` → All sections

**Use cases**:
- Creating architecture documents
- Making design decisions
- System documentation
- Infrastructure planning

**Token estimate**: ~8,000 tokens (comprehensive view)

### codebase-structure-auditor
**Role**: Verify file organization, naming conventions, repository structure

**Required metadata**:
- `naming_conventions.yaml` → `.decision_trees`, `.directory_structures`, `.validation_rules`
- `frontend_architecture.yaml` → `.directory_structure`
- `git_conventions.yaml` → `.branches`, `.commits`

**Use cases**:
- File placement validation
- Naming convention audits
- Repository structure checks
- Migration verification

**Token estimate**: ~2,000 tokens

### Query Syntax for Agents

Agents can use YAML path notation to load specific sections:

```python
# Example agent query
from yaml import safe_load

# Load full file
naming = safe_load(open('.agent/metadata/naming_conventions.yaml'))

# Query specific section
repo_rules = naming['decision_trees']['repository_naming']
python_case = naming['case_styles']['snake_case']
api_pattern = naming['api_conventions']['endpoint_structure']
```

**Benefits**:
- **Precision**: Load only what's needed
- **Speed**: Parse structured data faster than markdown
- **Validation**: Decision trees enforce rules programmatically
- **Efficiency**: 5-10x token savings per operation

---

## Future Enhancements

- [ ] Add automation to sync from Notion databases
- [ ] Create validation scripts for CI/CD
- [ ] Add metrics tracking (task completion, coverage)
- [ ] Generate documentation from schemas automatically
- [ ] Add more granular schemas for different metadata types
- [ ] Populate story-driven metadata files from Notion content
- [ ] Create schemas for `namespaces.yaml`, `git_conventions.yaml`, `decisions.yaml`
- [ ] Add cross-validation between ADRs and tech stack choices

---

**Related Documentation**:
- Root workspace guide: `/Users/joelschaeffer/dev/lightwave-workspace/CLAUDE.md`
- Persistent context: `.claude/README.md`
- Onboarding checklist: `.claude/ONBOARDING.md`
- Secrets map: `.claude/SECRETS_MAP.md`

---

**Maintained By**: Joel Schaeffer  
**Version**: 1.0.0  
**Last Updated**: 2025-10-25
