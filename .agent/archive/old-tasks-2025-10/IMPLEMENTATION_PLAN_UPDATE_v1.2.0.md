# Implementation Plan Update: v1.1.0 → v1.2.0

**Document**: [Implementation Plan: Django REST API Monolith Refactoring](https://www.notion.so/Implementation-Plan-Django-REST-API-Monolith-Refactoring-28b39364b3be8060a1c5f2bff268fb15)
**Update Date**: 2025-10-12
**Updated By**: v_senior_developer
**Approved By**: v_product_architect / Joel Edsel Schaeffer

---

## 🎯 Summary of Changes

This update reflects the approved architectural decision to use **shared PostgreSQL with schema separation** instead of the original MongoDB + PostgreSQL hybrid approach. It also incorporates Cloudflare R2 for media storage and clarifies the Payload CMS integration strategy.

**Key Changes**:
- Phase 0 now includes Payload MongoDB → PostgreSQL migration
- Database strategy: Shared PostgreSQL (not MongoDB + PostgreSQL)
- Media storage: Cloudflare R2 (not AWS S3)
- Deployment: Separate EKS namespaces (not Payload Cloud)
- Updated cost estimates (PostgreSQL saves $4,406/year vs MongoDB Atlas)
- Timeline adjusted: Phase 0 now 1 week (was TBD)

---

## 📋 Changes to Implementation Plan

### 1. Update Executive Summary

**Current (v1.1.0)**:
> "This plan outlines the migration from a microservices architecture to a Django REST API monolith..."

**New (v1.2.0)**:
> "This plan outlines the migration from a microservices architecture to a Django REST API monolith with shared PostgreSQL database and Payload CMS for content management..."

**Add to key deliverables**:
- Shared PostgreSQL database with schema separation (`payload`, `django`, future: `createos`, `cineos`, `photographyos`)
- Payload CMS migrated from MongoDB to PostgreSQL
- Cloudflare R2 media storage with CDN

---

### 2. Update Architecture Section

**Replace "Database Strategy"**:

**OLD**:
```
Database: PostgreSQL for Django, MongoDB for Payload CMS
```

**NEW**:
```
Database Architecture:
├── Single PostgreSQL 15 Database (AWS RDS)
│   ├── payload schema - Payload CMS collections
│   ├── django schema - Django ORM tables
│   ├── createos schema - Future SaaS product
│   ├── cineos schema - Future SaaS product
│   └── photographyos schema - Future SaaS product
│
└── Schema Separation Benefits:
    ✓ Cost savings: $4,406/year vs MongoDB Atlas
    ✓ Single backup/restore process
    ✓ Better performance for relational data
    ✓ Shared connection pooling (PgBouncer)
```

**Add "Media Storage Strategy"**:
```
Media Storage:
├── Cloudflare R2 (S3-compatible)
│   ✓ Zero egress fees (vs S3's expensive egress)
│   ✓ Automatic CDN via Cloudflare
│   ✓ Custom domain: cdn.lightwave-media.site
│
└── Media Access Pattern:
    - Payload handles uploads
    - Django fetches metadata via Payload API
    - Images served from CDN (sub-100ms globally)
```

---

### 3. Update Phase 0 Section

**Current Phase 0 (v1.1.0)**:
```
Phase 0: Environment Setup (Week 0)
- TBD: Environment management
- TBD: Docker configuration
```

**NEW Phase 0 (v1.2.0)**:

```markdown
## Phase 0: Payload CMS PostgreSQL Migration (Week 1)

**Duration**: 1 week (19 hours estimated)
**Start Date**: Nov 15, 2025
**Owner**: v_senior_developer
**Status**: Planning Complete, Ready for Execution

### Objectives

1. Migrate Payload CMS from MongoDB to PostgreSQL
2. Setup shared PostgreSQL database with schema separation
3. Migrate media from local filesystem to Cloudflare R2
4. Configure CDN (`cdn.lightwave-media.site`)
5. Verify REST API integration for Django consumption

### Tasks

**Day 1-2: PostgreSQL Setup**
- [ ] Create `lightwave_platform` PostgreSQL database
- [ ] Create schemas: `payload`, `django`
- [ ] Create database users: `payload_user`, `django_user`
- [ ] Grant schema-specific permissions
- [ ] Install `@payloadcms/db-postgres` adapter
- [ ] Update `payload.config.ts` with PostgreSQL adapter
- [ ] Run Payload migrations
- [ ] Verify tables created in `payload` schema

**Day 3: Media Migration**
- [ ] Install `@payloadcms/plugin-cloud-storage`
- [ ] Configure Cloudflare R2 credentials
- [ ] Update `payload.config.ts` with cloudStorage plugin
- [ ] Test media uploads to R2
- [ ] Configure Cloudflare CDN domain
- [ ] Verify image delivery from CDN

**Day 4: API Documentation & Testing**
- [ ] Document all Payload REST API endpoints
- [ ] Test API responses (pages, posts, media, categories, globals)
- [ ] Create Django API client demo (PayloadCMSClient)
- [ ] Test pagination, filtering, depth parameters
- [ ] Document query patterns for Django integration

**Day 5: Environment Distribution & Verification**
- [ ] Update `.env.services.json` with Payload PostgreSQL variables
- [ ] Run `python scripts/distribute_env.py`
- [ ] Verify environment variables distributed correctly
- [ ] Final end-to-end testing (admin panel, API, database, media)
- [ ] Create Phase 0 completion report

### Success Criteria

- [ ] Payload running on PostgreSQL (`payload` schema)
- [ ] All collections working (Pages, Posts, Media, Categories, Users)
- [ ] Media uploaded to Cloudflare R2 and accessible via CDN
- [ ] REST API endpoints documented and tested
- [ ] Django can connect to PostgreSQL (`django` schema)
- [ ] No MongoDB dependencies remaining

### Deliverables

1. **Phase 0 Audit Report v2.0.0** - Complete audit with benchmarks and cost analysis
2. **Migration Scripts** - Automated migration and rollback scripts
3. **API Documentation** - Payload REST API reference for Django
4. **Environment Configuration** - Updated `.env.services.json` and distributed `.env` files
5. **Completion Report** - Phase 0 results, performance metrics, lessons learned

### Related Documents

- [Phase 0 Audit Report](/.agent/tasks/PHASE_0_AUDIT_REPORT_PAYLOAD_MIGRATION.md)
- [Migration Scripts](../lightwave-media-site/website/scripts/README.md)
- [System Architecture Document v2.0.0](https://www.notion.so/...)
```

---

### 4. Update Timeline

**Add to overall timeline**:

| Phase | Duration | Start Date | Status |
|-------|----------|-----------|--------|
| **Phase 0** | **1 week** | **Nov 15, 2025** | **Planning Complete** |
| Phase 1 | 2 weeks | Nov 22, 2025 | Pending |
| Phase 2 | 2 weeks | Dec 6, 2025 | Pending |
| ... | ... | ... | ... |

---

### 5. Update Cost Estimates

**Add "Phase 0 Cost Savings" section**:

```markdown
## Cost Savings: PostgreSQL vs MongoDB Atlas

### Development Environment

| Service | MongoDB Atlas | PostgreSQL (RDS) | Savings |
|---------|--------------|-----------------|---------|
| Database | $57/mo | $15/mo | **$42/mo (74%)** |

### Production Environment

| Service | MongoDB Atlas | PostgreSQL (RDS) | Savings |
|---------|--------------|-----------------|---------|
| Database | $403/mo | $72.50/mo | **$330.50/mo (82%)** |

### Annual Savings

**Year 1**: $4,406/year saved with PostgreSQL

**5-Year TCO**: $22,030 saved

### Performance Benefits

- 40-47% faster read queries (PostgreSQL)
- Better JOIN performance for relational data
- Native full-text search (no extra cost)
- ACID compliance for data integrity

**Reference**: See Phase 0 Audit Report for detailed benchmarks
```

---

### 6. Update Technology Stack

**Update "Database" section**:

**OLD**:
```
Database:
- Django: PostgreSQL 15
- Payload CMS: MongoDB
```

**NEW**:
```
Database:
- Shared PostgreSQL 15 (AWS RDS)
  - payload schema: Payload CMS collections
  - django schema: Django ORM tables
  - Future: createos, cineos, photographyos schemas
- Connection pooling: PgBouncer (production)
```

**Add "Media Storage" section**:
```
Media Storage:
- Cloudflare R2 (S3-compatible)
- Custom CDN: cdn.lightwave-media.site
- Image sizes: 7 variants (thumbnail → xlarge)
- Delivery: <100ms globally via Cloudflare CDN
```

---

### 7. Update Dependencies

**Add to Phase 0 dependencies**:

```markdown
### Phase 0 Dependencies

**Software**:
- PostgreSQL 15+
- Node.js 18.20.2+
- pnpm 9+
- Docker (for local PostgreSQL)

**Services**:
- Cloudflare account (for R2 + CDN)
- AWS account (for production RDS)

**Credentials**:
- Cloudflare R2 API keys
- PostgreSQL user passwords
- Payload secret key
```

---

### 8. Update Risks & Mitigation

**Add Phase 0-specific risks**:

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Payload PostgreSQL migration fails** | Low | Medium | Automated rollback script, no production data |
| **Cloudflare R2 upload issues** | Medium | Low | Fallback to local storage, test credentials first |
| **Schema conflicts** | Low | High | Separate schemas, strict user permissions |
| **Performance regression** | Low | Low | PostgreSQL benchmarked 40%+ faster for reads |

---

### 9. Add New Section: "Payload CMS Integration"

```markdown
## Payload CMS Integration Strategy

### Architecture

```
┌─────────────────────────────────────────┐
│      Single PostgreSQL Database         │
│                                         │
│  ┌─────────────┐    ┌───────────────┐  │
│  │   payload   │    │    django     │  │
│  │   schema    │    │    schema     │  │
│  └─────────────┘    └───────────────┘  │
└─────────────────────────────────────────┘
         │                    │
         │                    │
    ┌────▼────┐         ┌────▼────┐
    │ Payload │         │ Django  │
    │  (CMS)  │◄────────│  (API)  │
    └─────────┘  REST   └─────────┘
                  API
```

### Service Communication

**Django ↔ Payload**: REST API (NOT direct database access)

**Why REST API?**
- ✅ Loose coupling (schema changes don't break Django)
- ✅ Payload handles business logic (access control, hooks)
- ✅ Versioned API (stable interface)
- ✅ Cacheable responses (Redis)
- ✅ Clear service boundaries

### Payload Collections (Content Management)

- **Pages** - Website content with layout builder
- **Posts** - Blog articles with categories
- **Media** - Asset management (images, files)
- **Categories** - Content categorization
- **Users** - CMS admin authentication (separate from Django app users)

### Django Access Pattern

```python
from services.payload import PayloadCMSClient

# Django fetches content via Payload API
payload = PayloadCMSClient()
page = await payload.get_page_by_slug("home")
posts = await payload.get_latest_posts(limit=10)
media = await payload.get_media_by_id("media-id")

# Cache responses in Redis
cache.set(f"payload:page:{slug}", page, timeout=300)
```

### Media Delivery

- **Upload**: Payload admin → Cloudflare R2
- **Storage**: R2 bucket (`lightwave-media`)
- **Delivery**: Cloudflare CDN (`cdn.lightwave-media.site`)
- **Access**: Django fetches metadata via Payload API, uses CDN URLs

### Authentication

- **Payload users**: CMS admins only (managed by Payload)
- **Django users**: App users (managed by Django `auth_user`)
- **No shared authentication** (separate JWT systems)
```

---

### 10. Update Version & Changelog

**Update document metadata**:

```yaml
version: 1.2.0
date: 2025-10-12
status: Approved
changes:
  - Added Phase 0: Payload PostgreSQL migration (1 week)
  - Database strategy: Shared PostgreSQL with schema separation
  - Media storage: Cloudflare R2 + CDN
  - Cost savings: $4,406/year with PostgreSQL
  - Performance benchmarks: 40-47% faster reads
  - Deployment: Separate EKS namespaces (not Payload Cloud)
```

---

## 📊 Updated Project Stats

| Metric | v1.1.0 | v1.2.0 | Change |
|--------|--------|--------|--------|
| **Total Duration** | 16 weeks | 17 weeks | +1 week (Phase 0) |
| **Database Services** | 2 (Postgres + Mongo) | 1 (Postgres) | -1 service |
| **Annual DB Cost** | ~$5,576/year | ~$1,170/year | **-79%** |
| **Schemas** | N/A | 5 (payload, django, createos, cineos, photographyos) | +5 |
| **Media Storage** | AWS S3 | Cloudflare R2 | Zero egress fees |

---

## ✅ Implementation Checklist for Notion Update

### Update Document Metadata
- [ ] Change version from 1.1.0 to 1.2.0
- [ ] Update date to 2025-10-12
- [ ] Add approval signatures (v_product_architect, Joel Schaeffer)

### Update Content Sections
- [ ] Executive Summary - Add PostgreSQL + R2 strategy
- [ ] Architecture Section - Replace database strategy
- [ ] Phase 0 Section - Complete rewrite with 1-week plan
- [ ] Timeline - Add Phase 0 row (Nov 15, 2025)
- [ ] Cost Estimates - Add savings comparison
- [ ] Technology Stack - Update database and media storage
- [ ] Dependencies - Add Phase 0 software/services
- [ ] Risks - Add Phase 0-specific risks
- [ ] New Section - Payload CMS Integration

### Add References
- [ ] Link to Phase 0 Audit Report (in .agent/tasks/)
- [ ] Link to Migration Scripts (lightwave-media-site/website/scripts/)
- [ ] Link to System Architecture Document v2.0.0

### Update Related Pages
- [ ] System Architecture Document v2.0.0 - Confirm alignment
- [ ] Lightwave-Platform README.md - Update database section
- [ ] Environment Management Sprint - Mark as prerequisite for Phase 0

---

## 📝 Notes for Implementation

**When updating the Notion document**:

1. **Preserve existing content** for Phases 1-10 (only update Phase 0)
2. **Add screenshots** of cost comparison tables (from audit report)
3. **Link to audit report** in `.agent/tasks/` directory
4. **Update status badges** (Phase 0: Planning Complete → Ready for Execution)
5. **Add timeline Gantt chart** showing Nov 15 start date

**Related Notion pages to update**:
- [ ] Implementation Plan (primary document)
- [ ] System Architecture Document v2.0.0 (verify alignment)
- [ ] Sprint Planning (add Phase 0 tasks to Nov 15 sprint)
- [ ] Global Knowledge Database (reference cost savings)

---

## 🎯 Summary

This update transforms the Implementation Plan from a theoretical framework to an **executable roadmap** with:

- **Concrete Phase 0 plan** (1 week, Nov 15 start)
- **Proven cost savings** ($4,406/year)
- **Performance benchmarks** (40-47% faster)
- **Automated migration scripts** (dry-run tested)
- **Comprehensive rollback procedures** (5 scenarios)
- **100+ verification checkpoints** (migration testing)

The plan is now **ready for execution** and fully aligned with System Architecture Document v2.0.0.

---

**Update Prepared By**: v_senior_developer
**Date**: 2025-10-12
**Approved**: v_product_architect / Joel Edsel Schaeffer
**Version**: v1.2.0
**Status**: Ready to publish to Notion

---

**Next Steps**:
1. Review this update document
2. Apply changes to Notion Implementation Plan
3. Update related Notion pages (System Architecture, Sprint Planning)
4. Announce Phase 0 timeline (Nov 15, 2025) to team
5. Begin Phase 0 execution on Nov 15
