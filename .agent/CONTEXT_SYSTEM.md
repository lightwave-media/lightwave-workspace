# Hybrid Context System Guide

**Version**: 1.0.0
**Last Updated**: 2025-10-25
**Purpose**: Structured metadata + markdown guides for precise RAG queries

---

## 🎯 Why This Exists

**Problem**: Markdown files flood agent context windows with irrelevant information.

**Solution**: Hybrid system - structured metadata (YAML/JSON) for fast queries + markdown guides for detailed instructions.

**Result**: Agents get **exactly the context they need** (10x less tokens, repeatable queries).

---

## 📂 New Structure (Hybrid)

```
.agent/
│
├── metadata/                           # ✨ NEW - STRUCTURED (YAML/JSON)
│   ├── frontend_architecture.yaml      # Architecture decisions
│   ├── packages.json                   # Package registry
│   └── tech_stack.yaml                 # Technology choices
│
├── tasks/                              # ✨ NEW - YAML (Executable tasks)
│   ├── auth_client.yaml                # Task: Create @lightwave/auth-client
│   ├── payload_shared.yaml             # Task: Create @lightwave/payload-shared
│   └── django_auth_endpoints.yaml      # Task: Create Django auth endpoints
│
├── sops/                               # MARKDOWN (Step-by-step guides)
│   └── SOP_CREATE_LIGHTWAVE_AUTH_CLIENT.md
│
└── README.md                           # Auto-generated from Notion
└── CONTEXT_SYSTEM.md                   # ← You are here
```

---

## 🔍 How to Use It

### **Structured Metadata** (YAML/JSON)

**Query Examples**:

```bash
# What's the auth strategy?
yq '.auth.strategy' .agent/metadata/frontend_architecture.yaml
# Result: "session-based"

# What packages exist?
jq '.packages[].name' .agent/metadata/packages.json
# Result: "@lightwave/ui", "@lightwave/auth-client", "@lightwave/payload-shared"

# Why did we choose Payload CMS?
yq '.stack.frontend[] | select(.name == "Payload CMS") | .why_chosen' .agent/metadata/tech_stack.yaml
# Result: ["Code-first schema", "Self-hosted", ...]
```

**Benefits**:
- ✅ Precise (exact data, not 10,000 words)
- ✅ Fast (JSONPath/YAML queries)
- ✅ Repeatable (same query = same result)

---

### **Task Files** (YAML)

**Example**: `tasks/auth_client.yaml`

```yaml
task:
  id: "LW-FRONTEND-001"
  title: "Create @lightwave/auth-client package"

context:
  # Points to metadata (agent loads minimal context)
  architecture:
    file: ".agent/metadata/frontend_architecture.yaml"
    queries: ["auth.strategy", "auth.endpoints"]

acceptance_criteria:
  - condition: "100% test coverage"
    verification:
      command: "pnpm test:coverage | grep '100%'"
      critical: true
```

**How Agents Use It**:
1. Load task file
2. Query metadata files (precise, minimal context)
3. Load SOP sections only when needed
4. Execute, verify acceptance criteria

---

### **Standard Operating Procedures** (Markdown)

Still markdown! Used for:
- Detailed step-by-step implementation
- Code examples
- Troubleshooting
- Human-readable guides

**Task files point to SOPs** when detailed guidance needed.

---

## 📊 Comparison

| Aspect | Markdown Only | Hybrid (Structured + MD) |
|--------|--------------|---------------------------|
| Context Size | ❌ 10,000+ words | ✅ 50-100 words |
| Repeatability | ❌ Varies | ✅ Same every time |
| Queryability | ❌ Search/grep | ✅ JSONPath/YAML |
| Human Readable | ✅ Easy | ⚠️ Need query tools |

---

## 🛠️ Query Tools

```bash
# YAML queries
brew install yq
yq '.auth.strategy' .agent/metadata/frontend_architecture.yaml

# JSON queries
brew install jq
jq '.packages[].name' .agent/metadata/packages.json
```

---

## ✅ Best Practices

**For Agents**:
1. Load task file first
2. Query metadata (don't load full files)
3. Load SOP sections only when needed

**For Humans**:
1. Query metadata for quick answers (yq/jq)
2. Read SOPs for detailed guidance

---

**Questions?** See [`.claude/TROUBLESHOOTING.md`](../.claude/TROUBLESHOOTING.md)
