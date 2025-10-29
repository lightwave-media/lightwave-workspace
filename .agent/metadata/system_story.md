# The LightWave Story - System Narrative

**Purpose**: This document tells the story of WHY LightWave exists, WHAT it does, and HOW it's organized.

**Synced from**: LightWave Media LLC Command → Global Knowledge, Notes & Documents

**Last updated**: 2025-10-25

---

## 🎬 The Origin Story

### Why Does LightWave Exist?

LightWave was created to solve a fundamental problem facing creative professionals: **the operational complexity that steals time from creativity**.

Independent cinematographers, photographers, and multidisciplinary creative entrepreneurs navigate a fragmented landscape of disparate software tools, generic business applications, and manual processes. This leads to inefficiencies, lost creative momentum, data silos, and a persistent struggle to integrate creative workflows with sound business and life management practices.

They need a system that understands the unique sociotechnical demands of creative industries and supports their entire lifecycle—from ideation to delivery and beyond—while allowing them to focus on what they do best: create.

**The Vision:**

To become the indispensable operational hub for a global community of thriving creative professionals. LightWave aspires to be recognized as the leading approach for operational excellence in creative industries—a system where **creativity and business intelligence converge seamlessly**.

In 3-5 years, LightWave will serve tens of thousands of creative professionals who have transformed their practices from chaotic to systematized, from reactive to strategic, from isolated to integrated.

**The Mission:**

Provide a unified, systems-driven, and intelligently augmented operational environment that enables creative professionals to:

- Transform their "second brain" and "Life OS" methodologies into tangible, actionable digital workflows
- Reclaim invaluable time for creative pursuits
- Enhance project control and conceptual integrity
- Make data-informed business decisions
- Build more resilient, profitable, and fulfilling creative careers

Our day-to-day work: Building an AI-native business platform that scales intelligence, not headcount.

---

## 🏗️ The Architecture Story

### Why This Structure?

LightWave is organized around a core architectural principle: **domain-specific experiences powered by shared infrastructure**.

The three-layer architecture emerged from a fundamental insight: creative professionals wear multiple hats (cinematographer, photographer, business owner, financial manager), and each role has distinct workflows, mental models, and tool requirements. A one-size-fits-all interface would force users to navigate irrelevant complexity.

Instead, we provide **specialized domains that feel purpose-built** while sharing a robust backend that ensures data consistency, reduces operational overhead, and enables cross-domain intelligence.

**The Three Layers:**

### 1. Frontend Domains (cineos.io, photographyos.io, createos.io, joelschaeffer.com, lightwave-media.site)

**Story**: Each creative discipline has its own language, workflows, and mental models. A cinematographer thinks in scenes, shots, and call sheets. A photographer thinks in shoots, galleries, and print orders. A business owner thinks in projects, finances, and growth metrics.

Rather than force everyone through a generic interface, we created **dedicated domains** where each role gets exactly the tools and terminology they need—nothing more, nothing less.

**Purpose**:

- **Cognitive clarity**: Users see only what's relevant to their current role
- **Specialized workflows**: Domain-specific features (script breakdown for film, print fulfillment for photography)
- **Independent scaling**: Each domain can evolve at its own pace without breaking others
- **Marketing clarity**: cineos.io sells itself to cinematographers; photographyos.io sells itself to photographers

**Trade-offs**:

- **Development overhead**: Must build and maintain 5 separate frontends
- **Cross-domain navigation**: Users must switch domains to access different roles (though this can be automated)
- **Duplicate UI patterns**: Some components are replicated across domains (mitigated by shared component library @lightwave/ui)

### 2. Backend Platform (api.lightwave-media.ltd)

**Story**: While the front-end is deliberately fragmented, the **backend must be unified**. All creative work ultimately flows through common primitives: projects, tasks, files, finances, clients.

A single Django backend ensures that when a cinematography project generates an invoice, that invoice appears in financial reports without manual data entry. When a photography client books a new shoot, the system can recommend pricing based on past projects. **Data flows freely; insights emerge naturally**.

**Purpose**:

- **Single source of truth**: All domains read/write to the same PostgreSQL database
- **Cross-domain intelligence**: AI agents can analyze patterns across all your creative work
- **Reduced complexity**: One authentication system, one billing system, one admin interface
- **API-first design**: Future integrations (mobile apps, third-party tools) are trivial

**Trade-offs**:

- **Monolith risks**: A backend bug affects all domains simultaneously (mitigated by comprehensive testing)
- **Coupling concerns**: Changes to core data models require coordination across frontend teams
- **Single point of failure**: If the API goes down, all domains are affected (mitigated by robust infrastructure and caching)

### 3. Shared Infrastructure (Cloudflare + AWS + Terraform)

**Story**: The split infrastructure is a **best-of-both-worlds approach**.

Cloudflare excels at edge computing—serving static sites blazingly fast from 250+ locations worldwide. AWS excels at stateful services—managed databases, container orchestration, background jobs.

Why pay AWS to serve static files when Cloudflare does it faster and cheaper? Why force Cloudflare to manage complex stateful workloads when AWS has a decade of tooling?

**Purpose**:

- **Performance**: Next.js sites on Cloudflare Pages load in <100ms globally
- **Cost efficiency**: Cloudflare's generous free tier + AWS's pay-per-use pricing
- **Developer experience**: Cloudflare's git-based deployments are instant; AWS ECS enables zero-downtime backend updates
- **Reliability**: Geographic redundancy (Cloudflare edge + AWS multi-AZ)

**Trade-offs**:

- **Operational complexity**: Must manage two cloud providers instead of one
- **Networking complexity**: Cross-provider communication requires careful security configuration
- **Vendor lock-in (partial)**: Some Cloudflare features (Workers, R2) don't have direct AWS equivalents

---

## 🧭 The Naming Story

### Why "LightWave"?

The name **LightWave** emerged from the intersection of two core concepts:

**Light**: Represents clarity, insight, and vision—the tools to see your creative business clearly and make informed decisions. It also evokes the photographic and cinematic arts, where light is the fundamental medium.

**Wave**: Represents rhythm, flow, and the transmission of energy—how creative work moves through phases (ideation → production → delivery), and how our platform enables smooth transitions between these states.

Together, **LightWave** suggests illuminating the path forward while maintaining creative flow. It's a nod to the physics of light (cinematography, photography) while implying forward momentum.

Founded in 2015 as LightWave Media LLC in Los Angeles, the name has remained constant even as the product vision evolved from production services to AI-native platforms.

### Domain Naming Philosophy

The naming pattern **{discipline}os.io** reflects our core belief: each creative discipline deserves an **operating system**—not just software, but a complete environment for living and working in that craft.

**Pattern**: `{domain}os.io` (cineos.io, photographyos.io, createos.io)

**Rationale**:

- **"OS" suffix**: Signals that these aren't just apps—they're comprehensive platforms that orchestrate all aspects of that creative practice (like macOS or iOS orchestrate your computer/phone)
- **.io TLD**: Tech industry convention; implies API-driven, developer-friendly, modern SaaS
- **Discipline prefix**: Immediately clear who the product is for (cineOS = cinematographers, photographyOS = photographers)
- **Pronunciation**: "cine-o-s" reads as "cinema OS" phonetically

**Exception: createos.io** is the meta-layer—the operating system for creative **businesses** and **lives**, not just one discipline. It's the integration hub.

### Package Naming Philosophy

Our package namespace follows industry-standard conventions while encoding organizational hierarchy.

**Pattern**: `@lightwave/{feature}` for shared packages, `@{domain}/{feature}` for domain-specific packages

**Examples**:

- `@lightwave/ui` — Shared design system
- `@lightwave/auth-client` — Shared authentication
- `@cineos/shot-list` — Film-specific components
- `@photographyos/gallery` — Photography-specific components

**Rationale**:

- **NPM scoping**: Prevents name collisions (no one else can publish @lightwave/ui)
- **Clear ownership**: @lightwave/* = maintained by core platform team
- **Dependency management**: Easy to audit which packages are shared vs. domain-specific
- **Future flexibility**: Can publish domain-specific packages to NPM independently

---

## 🎯 The Product Story

### What Does LightWave Do?

At its core, LightWave is **a systems-thinking platform for creative professionals**. It transforms the chaos of running a creative business into a coherent, intelligent operating environment.

In plain English: LightWave helps cinematographers, photographers, and creative entrepreneurs **run their businesses like a well-oiled machine** so they can spend more time creating and less time on spreadsheets, paperwork, and hunting for files.

**For Users (Creative Professionals)**:

- **Unified workspace**: All projects, clients, finances, and files in one system—no more context-switching between 10 different apps
- **Intelligent automation**: AI agents draft invoices, tag photos, suggest equipment rentals, analyze profitability—augmenting your decision-making without replacing it
- **Financial clarity**: Real-time P&L, tax estimates, equipment depreciation tracking—built by a cinematographer who understands creative accounting
- **Project intelligence**: Learn from past projects ("What did I charge for a similar shoot?", "How long did post-production actually take?")

**For Creators (The LightWave Philosophy)**:

- **Systems over chaos**: Inspired by systems thinkers (Meadows, Ackoff, Brooks)—design for emergence, not rigid control
- **Data ownership**: Your creative work and business data belong to you, fully exportable, never held hostage
- **Human-in-the-loop AI**: AI assists and suggests; you decide and approve. No black-box automation.
- **Networked thinking**: Zettelkasten-inspired knowledge management—connect ideas across projects, see patterns emerge

### The Domain Breakdown

### cineOS (cineos.io)

**Purpose**: A complete operating system for cinematographers and film production teams—from script breakdown to final delivery.

**Target Audience**:

- Independent cinematographers (owner-operators)
- Small production companies (1-10 person crews)
- Directors of Photography who run their own businesses

**Key Features**:

- **Script breakdown & shot listing**: Scene-by-scene planning with equipment requirements
- **Crew & call sheet management**: Schedule coordination, contact management
- **Equipment tracking**: Own vs. rent decisions, depreciation tracking
- **On-set tools**: Shot logging, continuity notes, dailies review
- **Post-production coordination**: Handoff to editors, DI workflow
- **Project costing**: Accurate job pricing based on historical data

**What makes it unique**: Built by a working cinematographer (Joel Schaeffer) for the actual workflows cinematographers use—not generic project management adapted to film.

### photographyOS (photographyos.io)

**Purpose**: Streamline the entire photography business lifecycle—from client inquiry to print delivery.

**Target Audience**:

- Professional photographers (portraiture, events, fine art)
- Photography studios with 1-5 photographers
- Photographers transitioning from hobbyist to professional

**Key Features**:

- **Client & shoot management**: Inquiry → booking → shoot → delivery pipeline
- **Image organization**: AI-powered tagging, smart collections, archive management
- **Gallery & proofing**: Client-facing galleries with purchase/approval workflows
- **Print fulfillment**: Integration with print labs, order tracking
- **Portfolio management**: Curated public portfolios, SEO optimization
- **Pricing intelligence**: Suggest rates based on project type, market, and history

**What makes it unique**: Treats photography as both art and business—integrates creative portfolio presentation with back-office operations.

### createOS (createos.io)

**Purpose**: The flagship platform—a complete Life and Business Operating System for creative entrepreneurs who work across multiple disciplines.

**Target Audience**:

- Multidisciplinary creatives (photographer + filmmaker + designer)
- Creative business owners managing teams
- Solo creatives who want integrated life + work management

**Key Features**:

- **Universal project management**: Agile Scrum adapted for creative work (not software)
- **Financial command center**: Income/expenses, tax estimates, P&L, cash flow forecasting
- **Knowledge management**: Zettelkasten-style note-taking, networked thinking
- **Life Domains integration**: Personal goals aligned with business objectives
- **AI orchestration**: 14 specialized virtual agents handling routine tasks
- **Cross-domain intelligence**: Insights that span all your creative work

**What makes it unique**: It's not just business management or just personal productivity—it's a holistic operating system that recognizes creatives don't separate "work" and "life" cleanly.

### joelschaeffer.com

**Purpose**: Personal portfolio and professional website for Joel Schaeffer (founder/cinematographer)—serves as both showcase and product demonstration.

**Target Audience**:

- Potential clients looking to hire Joel for cinematography
- Industry peers evaluating his work
- Users curious about the person behind LightWave

**Key Features**:

- **Film portfolio**: Curated cinematography reels and case studies
- **Photography archive**: Fine art photography series (LA Street Light Series, etc.)
- **Writing & insights**: Blog posts on systems thinking, creative business, AI workflows
- **Live demo**: The site itself is built on LightWave infrastructure—walking proof of concept

**What makes it unique**: It's simultaneously a personal brand site and a "dogfooding" example of LightWave's capabilities.

### lightwave-media.site

**Purpose**: Public-facing marketing and community hub for the entire LightWave ecosystem.

**Target Audience**:

- Prospective users researching LightWave products
- Existing users seeking documentation and support
- Partners, investors, and press

**Key Features**:

- **Product pages**: Feature overviews for cineos.io, photographyos.io, createos.io
- **Documentation hub**: Getting started guides, API docs, best practices
- **Community resources**: Case studies, user stories, courses on systems thinking
- **Company information**: About, team, principles, contact

**What makes it unique**: Reflects LightWave's principles—transparent, educational, systems-focused (not typical SaaS marketing hype).

---

## 🛠️ The Technology Story

### Why These Tools?

LightWave's technology choices are driven by three principles:

1. **Pick boring technology** for infrastructure (proven, stable, well-documented)
2. **Pick modern technology** for developer experience (fast feedback loops, strong typing)
3. **Pick open-source** wherever possible (avoid vendor lock-in, support community)

### Why Next.js?

**Reason 1: React ecosystem dominance**

- Largest talent pool, most libraries, best documentation
- Joel already proficient in React from previous projects
- @lightwave/ui design system is React-based

**Reason 2: File-based routing + SSR flexibility**

- Zero-config routing (pages/ directory = routes)
- Mix static pages (marketing content) with dynamic pages (user dashboards)
- Edge rendering on Cloudflare = <100ms global load times
- Image optimization built-in (critical for photo portfolios)

**Trade-off accepted**: Next.js is a framework, not just a library—some opinions are forced (file structure, build process). But the DX (developer experience) gains outweigh the lock-in.

### Why Django?

**Reason 1: "Batteries included" for business logic**

- Built-in admin panel (critical for Joel to manage data without building custom UIs)
- ORM that handles 95% of queries elegantly
- Authentication, permissions, middleware = solved problems
- Strong conventions ("The Django Way") = less decision fatigue

**Reason 2: Python is the AI language**

- LightWave's AI agents (v_accountant, v_cinematographer, etc.) are Python-based
- Direct access to pandas, numpy, scikit-learn for financial modeling and data analysis
- Integration with Anthropic Claude API is trivial in Python
- Same language for backend API and AI services = shared code, easier debugging

**Trade-off accepted**: Django is monolithic and "opinionated"—some magic happens behind the scenes (middleware, signals). But for a solo developer (Joel) + AI agents, the productivity boost is massive.

### Why Payload CMS?

**Reason 1: Typescript + React + Modern DX**

- CMS UI is built in React—can customize with same component library as frontends
- Strongly typed content models (unlike WordPress's anything-goes PHP)
- Git-based workflow (CMS config is code, not database clicks)

**Reason 2: Flexible content modeling**

- Block-based content (similar to Notion)—editors can compose rich layouts
- Relationships between content types (e.g., "Film Project" → "Crew Members")
- Localization support (future-proofing for international users)

**Trade-off accepted**: Payload is newer (less mature than WordPress/Contentful)—some features require custom code. But the TypeScript DX and modern architecture align with LightWave's "Everything as Code" principle.

### Why Cloudflare + AWS (not just one)?

**Reason 1: Cloudflare's edge is unbeatable for static content**

- 250+ global POPs (points of presence)
- Free tier includes unlimited bandwidth (AWS charges $0.09/GB egress)
- Workers enable edge compute (dynamic API routes without backend calls)
- R2 object storage (S3-compatible) is 10x cheaper than S3

**Reason 2: AWS is the gold standard for stateful services**

- RDS (PostgreSQL) with automated backups, read replicas, multi-AZ failover
- ECS Fargate for containerized Django backend (no server management)
- ElastiCache (Redis) for sessions, caching, Celery task queue
- Secrets Manager for secure credential storage
- Mature ecosystem (CloudFormation, Terraform support, 10+ years of battle-testing)

**Trade-off accepted**: Operating two cloud providers adds complexity (must understand both billing models, networking, IAM). But the cost savings and performance gains are 10x—this is how modern startups build efficiently.

**The hybrid approach**: Static frontends live on Cloudflare (fast, cheap), stateful backend lives on AWS (reliable, scalable). Best of both worlds.

---

## 📖 The Development Story

### How We Build Features

LightWave follows a modified Agile Scrum methodology adapted for a solo founder + AI agents team. The key difference: **Notion is the single source of truth** for all product decisions, task tracking, and documentation.

**The Workflow:**

1. **Idea** → Notion task created in Global Tasks DB with "Status: Backlog"
    - Ideas come from: user feedback, Joel's own needs (dogfooding), strategic vision sessions
    - Each task gets: Title, Description, Life Domain tag, Priority
2. **Planning** → Definition of Ready (DoR) checklist verified
    - DoR criteria: User story format ("As X, I want Y, so that Z"), Acceptance criteria defined, Dependencies identified, Estimated effort (points)
    - Tasks that pass DoR move to "Status: Ready for Sprint"
3. **Implementation** → Code + Tests + Docs (atomic commits)
    - Developer (Joel or v_senior_developer agent via Claude Code) writes code
    - Every feature includes: Unit tests (pytest/vitest), Integration tests (where applicable), Updated README/docs
    - Git commits follow Conventional Commits (feat:, fix:, docs:, refactor:)
4. **Review** → PR opened with link back to Notion task
    - PR description includes: Notion task URL, What changed, Why it changed, How to test
    - Automated CI runs tests, linting, type checking (GitHub Actions)
    - Manual review by Joel (if agent wrote the code) or agent review (if Joel wrote it)
5. **Deploy** → Merged to main → Auto-deploy to staging, then production
    - Staging: Automatic deployment on every merge to `main` (dev environment on AWS)
    - Production: Manual approval trigger (ensures human-in-the-loop for prod changes)
    - Deployment includes: Database migrations, cache invalidation, health checks
6. **Complete** → Notion task marked "Status: Done" with "Date Completed" timestamp
    - Retrospective notes added to task ("What went well? What could improve?")
    - Sprint velocity calculated (actual points completed vs. estimated)

**Why This Workflow?**

**Reason 1: Notion as SSOT eliminates tool fragmentation**

- No context switching between Jira (tasks), Confluence (docs), Slack (discussion)
- AI agents can read Notion via API → understand full context without human explaining
- Rich formatting (tables, databases, linked pages) captures nuance that plaintext tickets can't

**Reason 2: This specific flow optimizes for solo founder + AI velocity**

- DoR checklist prevents half-baked ideas from consuming dev time
- Auto-deploy to staging means "see it live" within minutes of merge
- Manual prod approval is safety net (solo founder can't rely on team to catch mistakes)
- Retrospective notes feed into future sprint planning (continuous improvement)

### How We Organize Work

LightWave operates as a **one-person company augmented by specialized AI agents**. Joel Schaeffer (founder) is the only human, but he's not alone.

**The Virtual Agent Team:**

**Core Agents:**

- **v_core**: System orchestrator—routes requests to appropriate agents
- **v_general_manager**: Strategic decisions, roadmap prioritization, resource allocation
- **v_scrum_manager**: Sprint planning, DoR verification, velocity tracking

**Development Agents:**

- **v_senior_developer**: Writes production code (Django, Next.js, Python)
- **v_product_architect**: System design, technical specifications, architecture decisions
- **v_notion_developer**: Notion workspace management, database design, automation

**Domain Agents:**

- **v_cinematographer**: Film-specific workflows, equipment recommendations
- **v_photographer**: Photography workflows, image processing, portfolio curation
- **v_accountant**: Financial modeling, tax estimates, bookkeeping
- **v_legal**: Contract review, compliance checks, terms of service

**Communication Agents:**

- **v_write**: Documentation, blog posts, marketing copy
- **v_speak**: Presentations, video scripts, pitch decks
- **v_note**: Meeting summaries, research synthesis, knowledge organization

**Why Virtual Agents?**

**Reason 1: Scale specialized expertise without hiring**

- Can't afford (or need) full-time accountant, lawyer, devops engineer—but need their skills occasionally
- AI agents provide on-demand expertise at fraction of cost
- Agents never get tired, never quit, always available

**Reason 2: Enforce discipline on solo founder**

- Easy for solo founders to skip documentation ("I'll remember this!")
- Agents require machine-readable specifications → forces Joel to document decisions
- Sprint retrospectives with v_scrum_manager create accountability

**The Model**: Think of it as a **virtual studio**—Joel is Creative Director, agents are specialized team members. Decisions require human approval (v_accountant suggests, Joel confirms), but execution is augmented (v_senior_developer writes boilerplate, Joel reviews critical logic).

---

## 🗺️ The System Map

### How Everything Connects

Here's the data flow when a user interacts with LightWave:

```
User visits cineos.io
     ↓
Cloudflare DNS resolves to Cloudflare Pages
     ↓
Next.js site serves static HTML/CSS/JS from edge (< 50ms)
     ↓
User clicks "Load My Projects" → JavaScript makes API call
     ↓
API request to api.lightwave-media.ltd
     ↓
Cloudflare proxies request to AWS
     ↓
AWS Application Load Balancer (ALB) receives request
     ↓
ALB routes to ECS Fargate task running Django container
     ↓
Django checks Redis cache for data
     │
     ├─ Cache hit → Return data immediately (< 10ms)
     │
     └─ Cache miss → Query PostgreSQL RDS
           ↓
       PostgreSQL returns data
           ↓
       Django caches result in Redis
           ↓
       Django serializes data to JSON
           ↓
       Response returns through ALB → Cloudflare → User
           ↓
       Next.js frontend renders data in UI
```

**Story: Why Each Layer Exists**

**Cloudflare Edge**: Intercepts static requests (HTML, CSS, JS, images) before they reach AWS—reduces latency by 200ms+ and AWS bandwidth costs by 90%.

**Next.js Static**: Pre-rendered pages (marketing content, blog posts) load instantly—no server required. Dynamic pages (dashboards) fetch data via API.

**API Gateway (ALB)**: Single entry point for all API requests—handles SSL termination, rate limiting, health checks.

**Django Backend**: Business logic, authentication, authorization—the brain of the system.

**Redis Cache**: Avoids redundant database queries for frequently accessed data (user profiles, project lists)—reduces DB load by 80%.

**PostgreSQL**: Source of truth for all application data—enforces referential integrity, supports complex queries.

**The key insight**: Each layer does what it's best at—edge for speed, backend for logic, database for truth.

---

## 🚀 The Deployment Story

### How Code Becomes Production

LightWave uses a **GitOps-based CI/CD pipeline**—infrastructure and deployments are defined in code and triggered by git pushes.

**Frontend Deployment (Next.js sites):**

1. Developer pushes code to GitHub (`main` branch)
2. Cloudflare Pages webhook detects push
3. Cloudflare builds Next.js site (`npm run build`)
    - Runs linting (`eslint`)
    - Runs type checking (`tsc --noEmit`)
    - Runs tests (`vitest run`)
    - Optimizes images, generates static pages
4. Build artifacts deployed to Cloudflare edge network (250+ locations)
5. DNS automatically points to new deployment (zero-downtime)
6. Previous deployment kept as rollback option (instant rollback via dashboard)

**Total time: 2-3 minutes** from push to live globally.

**Backend Deployment (Django API):**

1. Developer pushes code to GitHub (`main` branch)
2. GitHub Actions workflow triggered
3. CI pipeline runs:
    - Linting (`ruff`)
    - Type checking (`mypy`)
    - Unit tests (`pytest --cov`)
    - Integration tests (against test database)
4. If tests pass, Docker image built:
    - Base image: `python:3.11-slim`
    - Installs dependencies from `requirements.txt`
    - Copies application code
    - Runs `collectstatic` (gathers static files)
5. Image tagged with git SHA and pushed to AWS ECR (Elastic Container Registry)
6. ECS task definition updated with new image tag
7. ECS performs rolling deployment:
    - Starts new tasks with new image
    - Waits for health checks to pass
    - Drains connections from old tasks
    - Terminates old tasks
8. Database migrations run automatically (Django `migrate` command)
9. Cache invalidated (Redis `FLUSHDB`)

**Total time: 8-10 minutes** from push to live.

**Why This Deployment Strategy?**

**Reason 1: Automated testing catches bugs before users do**

- 80% code coverage requirement enforced—PRs fail if coverage drops
- Type checking prevents runtime errors ("undefined is not a function")
- Integration tests verify end-to-end workflows ("Can user create project?")

**Reason 2: Zero-downtime deployments enable frequent releases**

- Rolling ECS deployments mean API never goes offline
- Cloudflare's atomic deployments mean frontend never shows half-updated state
- Can deploy 5x per day without user disruption (vs. traditional "maintenance windows")

**Rollback strategy**: Cloudflare Pages = instant rollback via UI. AWS ECS = redeploy previous task definition (2 min). Database migrations = always backward-compatible (additive changes only, never destructive).

---

## 🔐 The Security Story

### How We Protect Users

Security at LightWave is based on **defense in depth**—multiple overlapping layers, so a single failure doesn't compromise the system.

**Authentication Strategy:**

**How it works:**

- JWT (JSON Web Token) based authentication
- User logs in → Django verifies credentials → issues signed JWT
- Frontend stores JWT in httpOnly cookie (not localStorage—prevents XSS attacks)
- Every API request includes JWT → Django verifies signature → allows/denies

**Why this approach:**

- **Stateless**: No session storage on backend (scales horizontally)
- **Secure**: httpOnly cookies can't be accessed by JavaScript (XSS protection)
- **Fast**: JWT verification is CPU-only (no database lookup)
- **Standard**: Industry best practice for SPA (Single Page App) + API architectures

**Additional auth features:**

- Refresh tokens (long-lived, stored in Redis) + access tokens (short-lived, 15min expiry)
- Email verification required before account activation
- Password reset via time-limited signed tokens
- Rate limiting on login endpoint (10 attempts per hour per IP)

**Data Protection:**

**How data is secured:**

- **Encryption at rest**: PostgreSQL RDS uses AES-256 encryption for all data
- **Encryption in transit**: All connections use TLS 1.3 (HTTP requests, database connections, Redis connections)
- **Secrets management**: API keys, database passwords stored in AWS Secrets Manager (not in code)
- **Least privilege**: Each service has minimal IAM permissions (Django can't access S3, frontend can't access database)

**Why this approach:**

- **Compliance**: Meets GDPR, CCPA requirements for data encryption
- **Defense in depth**: Even if attacker gets database dump, data is encrypted
- **Zero trust**: Assume network is hostile—encrypt everything, even internal traffic

**Infrastructure Security:**

**How infrastructure is secured:**

- **Private subnets**: Database and Redis live in VPC private subnets (no public internet access)
- **Bastion host**: SSH access to servers only via bastion host with MFA
- **Security groups**: Firewall rules limit traffic (e.g., PostgreSQL only accepts connections from Django containers)
- **Automated patching**: OS-level security updates applied automatically (AWS Systems Manager)
- **CloudTrail logging**: All AWS API calls logged for audit trail

**Why this approach:**

- **Minimize attack surface**: Database literally can't be reached from internet
- **Auditability**: CloudTrail logs answer "who did what, when?"
- **Compliance**: Satisfies SOC 2 requirements for infrastructure security

**Human factor**: Joel (solo founder) uses 1Password for credential management, hardware security keys (YubiKey) for 2FA on critical accounts (AWS root, GitHub, etc.).

---

## 📊 The Data Story

### How We Store and Manage Information

LightWave's data architecture follows a **polyglot persistence** pattern—different data types live in databases optimized for their access patterns.

**Database Strategy:**

**PostgreSQL (Primary relational database):**

- **What data**: Users, projects, tasks, clients, financial transactions, invoices
- **Why PostgreSQL**: ACID guarantees (critical for financial data), rich query capabilities (JOINs, aggregations), mature ecosystem (backups, replication, monitoring)
- **Scale strategy**: Vertical scaling (larger RDS instance) + read replicas (route analytics queries to replica)

**Redis (In-memory cache + task queue):**

- **What data**: Session tokens, API response cache, Celery task queue, rate limit counters
- **Why Redis**: Sub-millisecond latency (critical for session lookups), atomic operations (rate limiting), native pub/sub (Celery integration)
- **Scale strategy**: ElastiCache with automatic failover (replica promoted to primary if master fails)

**S3/R2 (Object storage):**

- **What data**: Images (photography portfolios, film stills), videos (cinematography reels), PDFs (contracts, invoices), backups (database dumps)
- **Why object storage**: Unlimited scale, 99.999999999% durability (11 nines), cheap ($0.01/GB/month for R2), CDN-friendly (CloudFlare R2 integrates with CDN)
- **Scale strategy**: Infinite (S3 automatically shards across availability zones)

**Notion (Knowledge management + task tracking):**

- **What data**: Documentation, meeting notes, sprint planning, architectural decisions, research
- **Why Notion**: Rich formatting, relational databases, API access (agents can read/write), collaboration features (for future team growth)
- **Scale strategy**: Notion's problem, not ours (SaaS)

**Data Flow Example (User uploads project photo):**

1. User uploads photo via photographyos.io frontend
2. Frontend sends multipart/form-data to Django API
3. Django validates file (type, size, virus scan)
4. Django uploads file to S3/R2 with unique key (UUID)
5. Django creates database record in PostgreSQL:
    ```sql
    INSERT INTO media_files (id, user_id, project_id, s3_key, filename, mime_type)
    VALUES (uuid, user_id, project_id, 's3://bucket/uuid', 'photo.jpg', 'image/jpeg')
    ```
6. Django returns API response with file URL
7. Frontend displays photo (served from CloudFlare CDN)

**Why This Data Architecture?**

**Reason 1: Right tool for the job**

- Relational data (users, projects) needs referential integrity → PostgreSQL
- Hot data (sessions, cache) needs speed → Redis
- Large files (photos, videos) need cheap storage → S3/R2
- Don't force everything into one database (avoid MongoDB's "store everything as JSON" anti-pattern)

**Reason 2: Independent scaling**

- Can scale PostgreSQL (larger instance) without affecting S3
- Can flush Redis cache without affecting source-of-truth database
- Each service scales based on its own bottlenecks

**Data consistency strategy**: PostgreSQL is source of truth. Redis cache can be flushed anytime (data regenerated from PostgreSQL). S3 files are immutable (never modified after upload, only deleted). Notion is eventually consistent (agents poll API every 30s).

---

## 🎨 The Design Story

### How We Build UI

LightWave's design philosophy: **Accessible, consistent, fast, and beautiful—in that order**.

**Design System (@lightwave/ui):**

**Source**: Based on Untitled UI (https://untitledui.com), a comprehensive Figma design system with 250+ components.

**Why Untitled UI**:

- **Professional quality**: Designed by experienced UI/UX designers (not engineers playing designer)
- **Accessibility first**: All components meet WCAG 2.1 AA standards (critical for dyslexia-friendly interfaces)
- **React implementation included**: Not just Figma mockups—comes with coded components
- **Customizable**: Built on design tokens (colors, spacing, typography) that can be themed

**Components include**:

- Forms (inputs, selects, checkboxes, radio buttons, file uploads)
- Navigation (sidebars, breadcrumbs, tabs, pagination)
- Feedback (alerts, toasts, modals, loading states)
- Data display (tables, cards, lists, badges, avatars)
- And 200+ more...

**Usage across domains**:

- **Shared base**: All domains use @lightwave/ui core components
- **Domain customization**: Each domain applies its own color palette:
    - cineOS: Deep blues and grays (cinematic, professional)
    - photographyOS: Warm earth tones (inviting, artistic)
    - createOS: Vibrant multi-color (energetic, creative)
- **Consistent patterns**: Button behavior, form validation, loading states identical across all domains

**Design Principles:**

**1. Accessibility is non-negotiable**

- All interactive elements have keyboard navigation
- Color contrast ratios meet WCAG AA (4.5:1 for text)
- Screen reader announcements for dynamic content
- Dyslexia-friendly: San-serif fonts, generous spacing, no justified text

**2. Progressive disclosure**

- Show only what's needed right now—hide advanced features behind "Show more" toggles
- Example: Project creation starts with 3 fields (name, client, date), advanced settings revealed on demand

**3. Speed is a feature**

- Optimistic UI updates (show success immediately, rollback if API call fails)
- Skeleton screens instead of spinners (give visual structure during load)
- Debounced inputs (wait for user to stop typing before querying API)

**4. Responsive first**

- Mobile-first design (start with small screen, enhance for larger)
- Touch targets minimum 44x44px (Apple HIG recommendation)
- Breakpoints: mobile (< 768px), tablet (768-1024px), desktop (> 1024px)

**Design workflow**: Joel designs in Figma (using Untitled UI as base) → Exports components → v_senior_developer implements in React → Joel reviews in Storybook (component playground) → Merge to @lightwave/ui.

---

## 🔮 The Future Story

### Where Is LightWave Going?

**Short-Term (Next 3 Months: Nov 2025 - Jan 2026):**

**Goal 1: Launch joelschaeffer.com/photo (Photography Portfolio)**

- Sprint Zero complete (archive organization, website foundation)
- Public launch: January 2026
- Success metric: 1,000 unique visitors in first month
- Strategic purpose: Dogfood photographyOS features, establish personal brand

**Goal 2: Complete IRON DAN Feature Film Production (Nov-Dec 2025)**

- 6-week principal photography in Alabama
- Test cineOS workflows in real production environment
- Document pain points and feature gaps
- Success metric: Ship film on time, identify 10+ cineOS improvements

**Medium-Term (Next 12 Months: Nov 2025 - Nov 2026):**

**Goal 1: Launch LightWave Platform MVP (lightwave-media.site + Backend API)**

- Complete CI/CD pipeline (current epic)
- Deploy production infrastructure (AWS ECS + RDS + Cloudflare)
- Public beta for createOS.io
- Success metric: 10 paying beta users by Nov 2026

**Goal 2: Productize Virtual Agent System**

- Package agent configs as Notion templates
- Launch in Notion template marketplace
- Success metric: 100 template sales, $2,000 MRR
- Strategic purpose: Early revenue + marketing channel for LightWave platform

**Goal 3: Establish Financial Backbone SSOT**

- Monthly financial close process automated
- Tax compliance streamlined (S-corp, quarterly estimates)
- Equipment depreciation tracking
- Success metric: Monthly close in < 2 hours (currently ~8 hours)

**Long-Term Vision (3-5 Years: 2028-2030):**

**Vision 1: LightWave becomes the operating system for 10,000+ creative professionals**

- All three platforms (cineos.io, photographyos.io, createos.io) in production
- Freemium model: Free tier for solo creators, paid tiers for teams
- ARR (Annual Recurring Revenue): $1M+ (100 users @ $10k/year or 1,000 users @ $1k/year)
- Community: Active forums, case studies, annual conference

**Vision 2: LightWave ecosystem enables "Creative OS" marketplace**

- Third-party developers build integrations (Stripe for payments, QuickBooks for accounting)
- Template marketplace (project templates, client onboarding workflows)
- API ecosystem (similar to Zapier—connect LightWave to 1,000+ apps)
- Platform becomes infrastructure layer, not just product

**Vision 3: AI agents evolve from assistants to collaborators**

- v_cinematographer doesn't just suggest equipment—it auto-generates shot lists from scripts
- v_accountant doesn't just calculate taxes—it optimizes business structure (LLC vs. S-corp)
- v_write doesn't just draft emails—it maintains consistent brand voice across all communications
- Human-in-the-loop always, but agents handle 80% of execution

**What success looks like in 2030**:

- A cinematographer can run a 6-figure business solo (no bookkeeper, no assistant)
- A photographer can launch new service line in 1 day (pricing, contracts, booking flow—automated)
- A creative entrepreneur can confidently answer "Am I profitable?" in 30 seconds

**The North Star**: LightWave empowers creatives to **create more, manage less**.

---

## 💡 Key Principles

### The "Laws" of LightWave Development

These principles are non-negotiable—when in doubt, defer to these:

**1. Systems Thinking Over Features**

**Explanation**: Design for the **system**, not isolated features. Every feature must answer: "How does this interact with existing features? What emergent behaviors might arise?"

**Example**: Don't just add "Export to CSV" button—design a holistic data portability system (export, import, API access, webhooks). Users should never feel trapped.

**Inspired by**: Donella Meadows (Thinking in Systems), Russell Ackoff (Systems Thinking), John Gall (Systemantics)

**2. Human-in-the-Loop AI**

**Explanation**: AI **augments** human decision-making; it never replaces it. Agents suggest, humans decide. No black-box automation that surprises users.

**Example**: v_accountant calculates tax estimate → shows math → asks for approval before filing. User sees the logic, learns, and maintains control.

**Why**: Creative work requires judgment, taste, and ethics—qualities AI doesn't possess. We build tools for creatives, not replacements.

**3. Everything as Code (Infrastructure, Config, Decisions)**

**Explanation**: If it's important, it should be in version control. Infrastructure (Terraform), configuration (YAML), decisions (Architecture Decision Records in Notion).

**Example**: Don't click buttons in AWS console—write Terraform. Don't store API keys in .env files—use AWS Secrets Manager. Don't have verbal conversations about architecture—document in Notion.

**Why**: Code is reviewable, auditable, reproducible. Click-ops is ephemeral and error-prone.

**4. Accessibility is Not Optional**

**Explanation**: Every interface must be usable by people with disabilities (visual, motor, cognitive). WCAG 2.1 AA compliance is the baseline, not the goal.

**Example**: Joel has dyslexia—LightWave's design accommodates his needs (clear typography, generous spacing, no walls of text). If it works for Joel, it works for millions of others.

**Why**: Accessible design is good design. Constraints breed creativity.

**5. Dogfood Everything**

**Explanation**: LightWave must be used internally before it's sold externally. Joel runs his cinematography business on cineOS, his photography practice on photographyOS, his company on createOS.

**Example**: If a feature is too clunky for Joel to use daily, it's too clunky to ship.

**Why**: Dogfooding reveals real pain points that user interviews miss. You can't fake empathy when you're the user.

**6. Conceptual Integrity Over Feature Bloat**

**Explanation**: A coherent, simple system beats a feature-rich, inconsistent mess. Saying "no" to features is often the right choice.

**Example**: Resist adding "blockchain integration" just because it's trendy. Does it serve the core mission (empowering creative professionals)? No? Then no.

**Inspired by**: Fred Brooks (The Mythical Man-Month), Robert Pirsig (Zen and the Art of Motorcycle Maintenance)

**7. Data Ownership Belongs to Users**

**Explanation**: Users' data (projects, finances, files) is **theirs**, not ours. Full export at any time, no lock-in, no ransom.

**Example**: One-click "Export Everything" generates JSON dump + CSV files + PDF reports. User can leave LightWave anytime.

**Why**: Trust is earned by respecting autonomy. Lock-in is short-term revenue, long-term betrayal.

**8. Transparency Over Perfection**

**Explanation**: Communicate openly about limitations, bugs, and roadmap. Users prefer honesty to polished PR speak.

**Example**: If a feature is experimental (beta), label it clearly. If there's a known bug, acknowledge it in UI ("We're working on fixing the slow export—hang tight!").

**Why**: Creative professionals are sophisticated users—they appreciate candor. Transparency builds community.

---

## 📚 Story-Driven Questions This Answers

**For New Developers:**

- "Why is the system organized this way?" → See [The Architecture Story](#🏗️-the-architecture-story)
- "What does LightWave do?" → See [The Product Story](#🎯-the-product-story)
- "How do I deploy code?" → See [The Deployment Story](#🚀-the-deployment-story)
- "What are the coding standards?" → See [Key Principles](#💡-key-principles)

**For AI Agents:**

- "Where should this new feature go?" → See [The System Map](#🗺️-the-system-map)
- "Why these technology choices?" → See [The Technology Story](#🛠️-the-technology-story)
- "What are the architectural principles?" → See [Key Principles](#💡-key-principles)
- "How does the team work?" → See [The Development Story](#📖-the-development-story)

**For Stakeholders:**

- "What is the product vision?" → See [The Origin Story](#🎬-the-origin-story)
- "What's the roadmap?" → See [The Future Story](#🔮-the-future-story)
- "How do you build securely?" → See [The Security Story](#🔐-the-security-story)
- "Why should I invest?" → See [The Product Story](#🎯-the-product-story) + [The Future Story](#🔮-the-future-story)

**For Users:**

- "Is my data safe?" → See [The Security Story](#🔐-the-security-story) + [The Data Story](#📊-the-data-story)
- "Can I export my data?" → See [Key Principles](#💡-key-principles) (#7: Data Ownership)
- "What makes LightWave different?" → See [The Product Story](#🎯-the-product-story) (unique value propositions)
- "Who builds this?" → See [The Development Story](#📖-the-development-story)

---

## 🔗 Cross-References

**Related Documentation:**
- [Namespace Strategy](.agent/metadata/namespaces.yaml)
- [Git Conventions](.agent/metadata/git_conventions.yaml)
- [Architecture Decisions](.agent/metadata/decisions.yaml)
- [Tech Stack](.agent/metadata/tech_stack.yaml)
- [Deployment Details](.agent/metadata/deployment.yaml)

**Notion Source of Truth:**
- [LightWave Media LLC Command](https://www.notion.so/LightWave-Media-LLC-Command-2261a8c38bf0451cab5eacb01b68f5ca?pvs=21) — Main workspace
- [LWM EcoSystem - PVD - v1.0](https://www.notion.so/LWM-EcoSystem-PVD-v1-0-21a39364b3be8013acb4f9791bcc790a?pvs=21) — Full Product Vision Document
- [LightWave Platform - Software Architecture Overview v1.0](https://www.notion.so/LightWave-Platform-Software-Architecture-Overview-v1-0-b3b58a29c1e44132bab3b1f4949ff6b5?pvs=21) — Technical architecture deep-dive
- [LWM EcoSystem - Planning & Documentation Workflow](https://www.notion.so/LWM-EcoSystem-Planning-Documentation-Workflow-21c39364b3be801d9c2bf1f59a752c86?pvs=21) — How we plan and document work

---

**Maintained By**: Joel Schaeffer
**Last Updated**: 2025-10-25
**Version**: 1.0.0
