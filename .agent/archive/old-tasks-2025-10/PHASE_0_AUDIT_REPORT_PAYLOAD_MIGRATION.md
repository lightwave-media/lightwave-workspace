# Phase 0 Audit Report: Payload CMS PostgreSQL Migration

**Task**: Django REST API Monolith Refactoring - Phase 0
**Date**: 2025-10-12
**Agent**: v_senior_developer
**Status**: Planning Complete - Ready for Implementation

---

## Executive Summary

This audit evaluated the existing Payload CMS installation at `lightwave-media-site/website/` to prepare for integration with the Django REST API monolith platform. The recommended approach is **shared PostgreSQL with schema separation** (aligning with System Architecture Document v2.0.0).

**Key Findings:**
- ✅ Fresh Payload 3.59.1 installation (MongoDB, no production data)
- ✅ 5 collections, 2 globals, 9 layout blocks configured
- ✅ Media currently stored locally (`public/media/`)
- ✅ PostgreSQL migration path is straightforward (no data migration complexity)
- ✅ REST API integration strategy defined

**Recommendation**: Proceed with Payload MongoDB → PostgreSQL migration as Phase 0 foundation.

---

## Current Payload Architecture

### Tech Stack

| Component | Version | Notes |
|-----------|---------|-------|
| Payload CMS | 3.59.1 | Headless CMS with admin panel |
| Next.js | 15.4.4 | App Router |
| Database | MongoDB | `@payloadcms/db-mongodb` |
| React | 19.1.0 | - |
| TypeScript | 5.7.3 | - |
| Editor | Lexical | Rich text editor |

### Collections Schema

#### 1. **Pages** (`payload.pages`)

**Purpose**: Main website content pages with layout builder

**Fields:**
- `id` (UUID, auto)
- `title` (text, required)
- `slug` (text, unique, auto-generated)
- `hero` (block) - Hero section configuration
- `layout` (blocks array) - Layout builder content
- `publishedAt` (date) - Publication timestamp
- `_status` (enum: `draft`, `published`) - Publishing status
- `createdAt`, `updatedAt` (timestamps)
- **SEO fields** (via `@payloadcms/plugin-seo`):
  - `meta.title`
  - `meta.description`
  - `meta.image` (relation → `media`)

**Relationships:**
- `meta.image` → `media` (many-to-one)

**Access Control:**
- Create/Update/Delete: Authenticated only
- Read: Authenticated OR published content

**Hooks:**
- `afterChange`: Revalidate Next.js page
- `afterDelete`: Revalidate deletion

**Versioning**: Draft versions enabled, auto-save interval 100ms

---

#### 2. **Posts** (`payload.posts`)

**Purpose**: Blog articles with categories and authors

**Fields:**
- `id` (UUID, auto)
- `title` (text, required)
- `slug` (text, unique, auto-generated)
- `heroImage` (relation → `media`)
- `content` (richText, Lexical) - Article content
- `categories` (relation → `categories`, many-to-many)
- `relatedPosts` (relation → `posts`, many-to-many)
- `authors` (relation → `users`, many-to-many)
- `populatedAuthors` (array) - Denormalized author data for public access
- `publishedAt` (date)
- `_status` (enum: `draft`, `published`)
- **SEO fields** (same as Pages)

**Relationships:**
- `heroImage` → `media`
- `categories` → `categories` (many-to-many)
- `relatedPosts` → `posts` (many-to-many, self-referential)
- `authors` → `users` (many-to-many)
- `meta.image` → `media`

**Access Control:**
- Same as Pages

**Hooks:**
- `afterRead`: Populate authors data
- `afterChange`: Revalidate post
- `afterDelete`: Revalidate deletion

**Versioning**: Same as Pages, max 50 versions per doc

---

#### 3. **Media** (`payload.media`)

**Purpose**: Asset management (images, files)

**Fields:**
- `id` (UUID, auto)
- `filename` (text, auto) - Original filename
- `alt` (text) - Alt text for accessibility
- `caption` (richText, Lexical) - Optional caption
- `mimeType` (text, auto) - MIME type
- `filesize` (number, auto) - File size in bytes
- `width`, `height` (number, auto) - Image dimensions
- `focalX`, `focalY` (number) - Focal point for cropping
- `sizes` (object) - Generated image sizes
- `url` (text, auto) - Public URL to file
- `createdAt`, `updatedAt` (timestamps)

**Upload Configuration:**
- Current: Local filesystem (`public/media/`)
- **Future**: AWS S3 or Cloudflare R2 (Phase 0 migration)

**Image Sizes Generated:**
- `thumbnail` (300px)
- `square` (500x500px, cropped)
- `small` (600px)
- `medium` (900px)
- `large` (1400px)
- `xlarge` (1920px)
- `og` (1200x630px, social media)

**Access Control:**
- Create/Update/Delete: Authenticated only
- Read: Public

---

#### 4. **Categories** (`payload.categories`)

**Purpose**: Content categorization for posts

**Fields:**
- `id` (UUID, auto)
- `title` (text, required)
- `slug` (text, unique, auto-generated)
- `createdAt`, `updatedAt` (timestamps)

**Access Control:**
- Create/Update/Delete: Authenticated only
- Read: Public

---

#### 5. **Users** (`payload.users`)

**Purpose**: Payload admin authentication and authors

**Fields:**
- `id` (UUID, auto)
- `name` (text)
- `email` (text, unique, required)
- `password` (password, hashed, required)
- `createdAt`, `updatedAt` (timestamps)

**Authentication:**
- Payload built-in auth (`auth: true`)
- Password hashing via bcrypt
- JWT tokens for admin panel
- **NOT the same as Django app users**

**Access Control:**
- Admin panel: Authenticated only
- All operations: Authenticated only

**Note**: This collection is separate from Django `auth_user`. Payload users are CMS admins only.

---

### Globals Schema

#### 1. **Header** (`payload_globals.header`)

**Purpose**: Global navigation menu configuration

**Fields:**
- `navItems` (array, max 6 items)
  - `link` (object)
    - `type` (enum: `reference`, `custom`)
    - `reference` (relation → `pages`)
    - `url` (text) - Custom URL
    - `label` (text)

**Hooks:**
- `afterChange`: Revalidate header

---

#### 2. **Footer** (`payload_globals.footer`)

**Purpose**: Global footer configuration (to be documented)

---

### Layout Builder Blocks

Payload uses a layout builder system where editors can construct pages using reusable blocks:

| Block | Purpose | Fields |
|-------|---------|--------|
| **ArchiveBlock** | Post archive list | Query settings, display options |
| **Banner** | Alert/announcement banner | Message, style |
| **CallToAction** | CTA with buttons | Heading, links, background |
| **Code** | Code snippet display | Language, code content |
| **Content** | Rich text content | Lexical editor |
| **FormBlock** | Dynamic forms | Form builder integration |
| **MediaBlock** | Image/video embed | Media relation, caption |
| **RelatedPosts** | Post recommendations | Post relations |
| **Hero** | Hero section (separate system) | Heading, media, CTA |

All blocks are rendered client-side in Next.js via `RenderBlocks.tsx`.

---

## Payload REST API Endpoints

Payload auto-generates a REST API for all collections and globals. Django will consume these endpoints instead of direct database access.

### Collections API

**Base URL**: `http://localhost:3000/api` (dev), `https://cms.lightwave-media.site/api` (prod)

#### Pages

```
GET    /api/pages              # List all pages (paginated)
GET    /api/pages/:id          # Get single page by ID
GET    /api/pages?where[slug][equals]=home  # Query by slug
POST   /api/pages              # Create page (admin only)
PATCH  /api/pages/:id          # Update page (admin only)
DELETE /api/pages/:id          # Delete page (admin only)
```

**Query Parameters:**
- `where[_status][equals]=published` - Filter published only
- `depth=2` - Populate relationships (e.g., `meta.image`)
- `limit=10&page=1` - Pagination

**Response Example:**
```json
{
  "docs": [
    {
      "id": "abc123",
      "title": "Home",
      "slug": "home",
      "layout": [...],
      "_status": "published",
      "publishedAt": "2025-10-12T12:00:00Z"
    }
  ],
  "totalDocs": 1,
  "limit": 10,
  "page": 1
}
```

---

#### Posts

```
GET    /api/posts              # List all posts
GET    /api/posts/:id          # Get single post
GET    /api/posts?where[slug][equals]=my-post
POST   /api/posts              # Create post (admin only)
PATCH  /api/posts/:id          # Update post
DELETE /api/posts/:id          # Delete post
```

**Query Parameters:**
- `where[categories][in][]=<category-id>` - Filter by category
- `where[_status][equals]=published` - Published only
- `depth=2` - Populate authors, categories, heroImage

**Response Example:**
```json
{
  "docs": [
    {
      "id": "xyz789",
      "title": "My Blog Post",
      "slug": "my-blog-post",
      "heroImage": {
        "id": "img123",
        "url": "https://cdn.example.com/image.jpg",
        "alt": "Hero image"
      },
      "categories": [
        { "id": "cat1", "title": "Tech" }
      ],
      "authors": [
        { "id": "user1", "name": "Joel Schaeffer" }
      ],
      "_status": "published"
    }
  ]
}
```

---

#### Media

```
GET    /api/media              # List all media
GET    /api/media/:id          # Get single media item
POST   /api/media              # Upload media (admin only)
PATCH  /api/media/:id          # Update metadata
DELETE /api/media/:id          # Delete media
```

**Response Example:**
```json
{
  "id": "media123",
  "filename": "hero.jpg",
  "alt": "Homepage hero image",
  "url": "https://cdn.example.com/hero.jpg",
  "width": 1920,
  "height": 1080,
  "mimeType": "image/jpeg",
  "sizes": {
    "thumbnail": { "url": "...", "width": 300, "height": 169 },
    "large": { "url": "...", "width": 1400, "height": 788 }
  }
}
```

---

#### Categories

```
GET    /api/categories         # List all categories
GET    /api/categories/:id     # Get single category
```

---

### Globals API

```
GET    /api/globals/header     # Get header config
GET    /api/globals/footer     # Get footer config
PATCH  /api/globals/header     # Update header (admin only)
```

**Response Example (Header):**
```json
{
  "id": 1,
  "navItems": [
    {
      "link": {
        "type": "reference",
        "reference": { "value": "page-id-123" },
        "label": "Home"
      }
    },
    {
      "link": {
        "type": "custom",
        "url": "/pricing",
        "label": "Pricing"
      }
    }
  ]
}
```

---

### Authentication

Payload uses JWT for admin panel authentication. Django will NOT use Payload auth - it will have its own JWT system.

**Admin Login:**
```
POST   /api/users/login
{
  "email": "admin@example.com",
  "password": "password"
}
```

**Response:**
```json
{
  "user": { "id": "user123", "email": "admin@example.com" },
  "token": "jwt-token-here",
  "exp": 1234567890
}
```

Django will call Payload API as an **unauthenticated client** for public content (`_status=published`).

---

## Django Integration Strategy

### Service Communication Pattern

**Django ↔ Payload via REST API (NOT direct database access)**

```python
# Django service layer (lightwave-api-gateway or lightwave-ai-services)
import httpx

class PayloadCMSClient:
    """Client for Payload CMS REST API"""

    BASE_URL = "http://payload:3000/api"

    async def get_page_by_slug(self, slug: str) -> dict:
        """Fetch published page by slug"""
        params = {
            "where[slug][equals]": slug,
            "where[_status][equals]": "published",
            "depth": 2  # Populate relations
        }
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.BASE_URL}/pages", params=params)
            response.raise_for_status()
            data = response.json()
            return data["docs"][0] if data["docs"] else None

    async def get_latest_posts(self, limit: int = 10) -> list[dict]:
        """Fetch latest published blog posts"""
        params = {
            "where[_status][equals]": "published",
            "sort": "-publishedAt",
            "limit": limit,
            "depth": 2
        }
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.BASE_URL}/posts", params=params)
            response.raise_for_status()
            return response.json()["docs"]

    async def get_media_by_id(self, media_id: str) -> dict:
        """Fetch media metadata and URLs"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.BASE_URL}/media/{media_id}")
            response.raise_for_status()
            return response.json()
```

**Why REST API instead of direct DB access?**
- ✅ **Encapsulation**: Payload owns its schema, can change without breaking Django
- ✅ **Business logic**: Payload handles access control, hooks, transformations
- ✅ **Versioning**: API is versioned, database schema is not
- ✅ **Caching**: Django can cache API responses in Redis
- ✅ **Separation of concerns**: Clear service boundaries

---

## PostgreSQL Migration Plan

### Current State

- **Database**: MongoDB at `mongodb://127.0.0.1/website`
- **Status**: Fresh installation, no production data
- **Media**: Local filesystem (`public/media/`)

### Target State

- **Database**: PostgreSQL (shared with Django)
- **Schema**: `payload` (isolated from `django` schema)
- **Media**: AWS S3 or Cloudflare R2
- **Adapter**: `@payloadcms/db-postgres`

---

### Migration Steps (Phase 0, Week 1)

#### Step 1: Setup Shared PostgreSQL

```bash
# Option A: Local PostgreSQL (development)
createdb lightwave_platform

# Option B: AWS RDS (production)
# Use existing RDS instance from System Architecture Document
```

**Create schemas:**

```sql
-- Connect to lightwave_platform database
CREATE SCHEMA IF NOT EXISTS payload;
CREATE SCHEMA IF NOT EXISTS django;

-- Create users
CREATE USER payload_user WITH PASSWORD 'secure-password-here';
CREATE USER django_user WITH PASSWORD 'secure-password-here';

-- Grant permissions
GRANT ALL ON SCHEMA payload TO payload_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA payload TO payload_user;
GRANT USAGE, CREATE ON SCHEMA payload TO payload_user;

GRANT ALL ON SCHEMA django TO django_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA django TO django_user;
GRANT USAGE, CREATE ON SCHEMA django TO django_user;

-- Optional: Django read-only access to Payload (for analytics)
GRANT SELECT ON SCHEMA payload TO django_user;
```

---

#### Step 2: Migrate Payload to PostgreSQL

**Install PostgreSQL adapter:**

```bash
cd lightwave-media-site/website
pnpm install @payloadcms/db-postgres
pnpm install pg
```

**Update `payload.config.ts`:**

```typescript
import { postgresAdapter } from '@payloadcms/db-postgres'

export default buildConfig({
  // ... other config
  db: postgresAdapter({
    pool: {
      connectionString: process.env.DATABASE_URI,
      // Use schema separation
      searchPath: 'payload,public',
    },
    // Run migrations automatically in development
    migrationDir: './migrations',
  }),
})
```

**Update `.env`:**

```bash
# Old (MongoDB)
# DATABASE_URI=mongodb://127.0.0.1/website

# New (PostgreSQL with schema)
DATABASE_URI=postgresql://payload_user:password@localhost:5432/lightwave_platform?schema=payload
```

**Run Payload migrations:**

```bash
# Generate initial migration
pnpm payload migrate:create

# Review migration in migrations/ directory
# Then apply
pnpm payload migrate
```

**Verify tables created:**

```sql
\c lightwave_platform
SET search_path TO payload;
\dt

-- Should see:
-- pages
-- posts
-- media
-- categories
-- users
-- payload_preferences
-- payload_migrations
-- (and version tables)
```

---

#### Step 3: Migrate Media to S3/R2

**Current**: Media stored in `public/media/` directory

**Target**: Cloudflare R2 (S3-compatible) or AWS S3

**Install storage adapter:**

```bash
pnpm install @payloadcms/plugin-cloud-storage
pnpm install @aws-sdk/client-s3
```

**Update `payload.config.ts`:**

```typescript
import { cloudStorage } from '@payloadcms/plugin-cloud-storage'
import { s3Adapter } from '@payloadcms/plugin-cloud-storage/s3'

export default buildConfig({
  // ... other config
  plugins: [
    cloudStorage({
      collections: {
        media: {
          adapter: s3Adapter({
            config: {
              endpoint: process.env.S3_ENDPOINT, // Cloudflare R2 endpoint
              region: process.env.S3_REGION,
              credentials: {
                accessKeyId: process.env.S3_ACCESS_KEY_ID,
                secretAccessKey: process.env.S3_SECRET_ACCESS_KEY,
              },
            },
            bucket: process.env.S3_BUCKET,
          }),
        },
      },
    }),
  ],
})
```

**Update `.env`:**

```bash
# Cloudflare R2
S3_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com
S3_REGION=auto
S3_ACCESS_KEY_ID=<r2-access-key>
S3_SECRET_ACCESS_KEY=<r2-secret-key>
S3_BUCKET=lightwave-media
```

**Migrate existing media:**

If there are existing files in `public/media/`:

```bash
# Use AWS CLI to sync
aws s3 sync public/media/ s3://lightwave-media/ --endpoint-url <R2-endpoint>
```

---

#### Step 4: Verify Payload on PostgreSQL

**Start Payload:**

```bash
pnpm dev
```

**Test checklist:**
- [ ] Admin panel loads at `http://localhost:3000/admin`
- [ ] Can create a test page
- [ ] Can upload media (goes to S3/R2)
- [ ] Can create a test post
- [ ] REST API works: `curl http://localhost:3000/api/pages`
- [ ] Database has data: `SELECT * FROM payload.pages;`

---

#### Step 5: Update Environment Distribution

Add Payload PostgreSQL variables to workspace `.env.services.json`:

```json
{
  "services": {
    "lightwave-media-site/website": {
      "description": "Payload CMS frontend",
      "required_variables": [
        "DATABASE_URI",
        "PAYLOAD_SECRET",
        "S3_ENDPOINT",
        "S3_REGION",
        "S3_ACCESS_KEY_ID",
        "S3_SECRET_ACCESS_KEY",
        "S3_BUCKET"
      ]
    }
  }
}
```

Run distribution:

```bash
python Lightwave-Platform/scripts/distribute_env.py
```

---

### Migration Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Migration breaks Payload** | Low | High | No production data to lose, can recreate |
| **S3/R2 upload issues** | Medium | Medium | Test in dev first, keep local fallback |
| **Schema conflicts with Django** | Low | High | Use separate schemas (`payload` vs `django`) |
| **Performance regression** | Low | Low | PostgreSQL often faster than MongoDB for this use case |
| **Version compatibility** | Low | Medium | Use Payload 3.59.1+ which supports PostgreSQL well |

**Rollback Plan:**
If PostgreSQL migration fails, revert to MongoDB:
1. Change `DATABASE_URI` back to MongoDB
2. Reinstall `@payloadcms/db-mongodb`
3. Restart Payload

---

## Schema Separation Design

### Database Structure

```
lightwave_platform (PostgreSQL database)
│
├── payload (schema)
│   ├── pages
│   ├── posts
│   ├── media
│   ├── categories
│   ├── users
│   ├── payload_preferences
│   ├── payload_migrations
│   └── (version tables)
│
├── django (schema)
│   ├── auth_user
│   ├── auth_group
│   ├── accounts_profile
│   ├── subscriptions_subscription
│   ├── orders_order
│   ├── ai_conversation
│   └── (Django ORM tables)
│
└── public (default schema)
    └── (shared utilities, if needed)
```

### Access Control Matrix

| User | Payload Schema | Django Schema | Public Schema |
|------|---------------|--------------|--------------|
| `payload_user` | Full (CRUD) | Read-only (optional) | Read |
| `django_user` | Read-only (optional) | Full (CRUD) | Read |
| Application | Via REST API only | Via Django ORM | N/A |

### Connection Strings

**Payload (Node.js):**
```bash
DATABASE_URI=postgresql://payload_user:password@localhost:5432/lightwave_platform?schema=payload
```

**Django (Python):**
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'lightwave_platform',
        'USER': 'django_user',
        'PASSWORD': 'password',
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {
            'options': '-c search_path=django,public'
        }
    }
}
```

---

## Media Storage Strategy

### Current State
- **Storage**: Local filesystem (`public/media/`)
- **Delivery**: Next.js static file serving
- **CDN**: None

### Target State (Production)
- **Storage**: Cloudflare R2 (S3-compatible)
- **Delivery**: Cloudflare CDN
- **URLs**: `https://cdn.lightwave-media.site/media/<filename>`

### Image Transformation

Payload generates multiple sizes on upload:
- Thumbnail (300px)
- Small (600px)
- Medium (900px)
- Large (1400px)
- XLarge (1920px)
- OG image (1200x630px for social)

All sizes stored in R2, delivered via CDN.

### Django Access Pattern

```python
# Django fetches media metadata from Payload API
media = await payload_client.get_media_by_id("media123")

# Use CDN URL in Django templates/responses
image_url = media["url"]  # https://cdn.lightwave-media.site/...
thumbnail_url = media["sizes"]["thumbnail"]["url"]
```

**Performance:**
- ✅ Images served from Cloudflare CDN (global edge network)
- ✅ Django doesn't store/serve images (stateless)
- ✅ Payload handles uploads, Django reads metadata
- ✅ Sub-100ms delivery times worldwide

---

## Phase 0 Success Criteria

**Week 1 Deliverables:**

- [ ] Shared PostgreSQL database configured with schemas
- [ ] Payload migrated from MongoDB to PostgreSQL
- [ ] Media storage migrated to S3/R2 with CDN
- [ ] All Payload collections working on PostgreSQL
- [ ] REST API endpoints documented and tested
- [ ] Django can query Payload API successfully (demo script)
- [ ] Environment variables distributed across workspace
- [ ] Phase 0 audit report approved

**Ready for Phase 1 when:**
- ✅ Payload running on PostgreSQL (`payload` schema)
- ✅ Django can connect to PostgreSQL (`django` schema)
- ✅ REST API client working in Django
- ✅ Media delivered via CDN
- ✅ No MongoDB dependencies remaining

---

## Recommended Timeline

**Phase 0: Week 1 (Post Nov 15, 2025)**

| Day | Task | Owner | Est. Time |
|-----|------|-------|-----------|
| Mon | Setup shared PostgreSQL + schemas | v_senior_developer | 2h |
| Mon | Install `@payloadcms/db-postgres` | v_senior_developer | 1h |
| Mon | Run Payload migrations | v_senior_developer | 1h |
| Tue | Test Payload on PostgreSQL | v_senior_developer | 2h |
| Tue | Setup S3/R2 storage adapter | v_senior_developer | 2h |
| Wed | Migrate media to S3/R2 | v_senior_developer | 2h |
| Wed | Configure Cloudflare CDN | v_senior_developer | 1h |
| Thu | Document REST API endpoints | v_senior_developer | 3h |
| Thu | Create Django API client demo | v_senior_developer | 2h |
| Fri | Update environment distribution | v_senior_developer | 1h |
| Fri | Final verification and testing | v_senior_developer | 2h |

**Total**: ~19 hours (Week 1, Phase 0)

---

## ✅ Approved Infrastructure Decisions

**Date**: 2025-10-12
**Approved By**: v_product_architect / Joel Edsel Schaeffer

### 1. Database Hosting

**✅ APPROVED**: Local PostgreSQL (dev) + AWS RDS PostgreSQL 15 (prod)

**Configuration**:
- **Development**: Docker Compose PostgreSQL 15 container
- **Production**: AWS RDS PostgreSQL 15 (db.t3.medium initially)
- **Schemas**: `payload`, `django`, `createos`, `cineos`, `photographyos`
- **Connection Pooling**: PgBouncer for production

**Rationale**: Standard pattern, aligns with System Architecture Document, cost-effective.

---

### 2. Media Storage

**✅ APPROVED**: Cloudflare R2 (primary)

**Why Cloudflare R2**:
- Zero egress fees (vs S3's expensive egress)
- Already using Cloudflare for DNS/CDN
- S3-compatible API (easy migration if needed)
- Better for media-heavy workloads

**Configuration**:
```typescript
storage: {
  cloudflareR2: {
    bucket: 'lightwave-media',
    accountId: process.env.CF_ACCOUNT_ID,
    accessKeyId: process.env.CF_R2_ACCESS_KEY_ID,
    secretAccessKey: process.env.CF_R2_SECRET_ACCESS_KEY,
  }
}
```

---

### 3. CDN Domain

**✅ APPROVED**: `cdn.lightwave-media.site` (custom domain)

**Structure**:
- `cdn.lightwave-media.site` → Cloudflare R2 bucket
- Cloudflare CDN in front (automatic)
- SSL via Cloudflare (automatic)

**Media URLs**:
- `https://cdn.lightwave-media.site/hero-image.jpg`
- `https://cdn.lightwave-media.site/thumbnails/image-300w.jpg`

---

### 4. Deployment Strategy

**✅ APPROVED**: Separate EKS deployments (same cluster, different namespaces)

**Architecture**:
```
AWS EKS Cluster: lightwave-prod
├── Namespace: django-api
│   ├── Django REST API pods
│   └── Celery worker pods
├── Namespace: payload-cms
│   ├── Payload Next.js pods
│   └── Shared PostgreSQL RDS
└── Namespace: shared
    ├── Redis pods
    └── Monitoring
```

**Why separate namespaces**:
- ✅ Independent scaling (Payload ≠ Django traffic patterns)
- ✅ Independent deployments (rollback one without affecting other)
- ✅ Resource isolation (CPU/memory limits per service)
- ✅ Same cluster = shared RDS, lower cost

**❌ NOT Payload Cloud**: Lose control, vendor lock-in, higher cost at scale

---

### 5. Timeline

**✅ APPROVED**: Start Phase 0 on Nov 15, 2025

**Timeline**:
- **Now through Nov 15**: Planning, documentation, script preparation (no execution)
- **Nov 15, 2025 (Phase 0 Week 1)**: Execute Payload PostgreSQL migration
- **Nov 22, 2025 (Phase 1 Week 2)**: Begin Django REST API development

**Estimated Phase 0 effort**: 19 hours

---

## Next Steps

**Immediate (Planning Phase):**
1. ✅ Review this Phase 0 audit report
2. ✅ Confirm architectural decisions with v_product_architect
3. ✅ Answer deployment and infrastructure questions
4. ✅ Approve Phase 0 migration plan

**Nov 15, 2025 (Implementation Start):**
1. Execute Phase 0 migration (Week 1)
2. Verify all success criteria met
3. Create handoff documentation for Phase 1
4. Begin Phase 1 Django development

---

## Appendix: Payload Schema Details

### Table: `payload.pages`

```sql
CREATE TABLE payload.pages (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  hero JSONB,                      -- Hero block configuration
  layout JSONB,                    -- Layout blocks array
  published_at TIMESTAMP,
  _status TEXT DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_pages_slug ON payload.pages(slug);
CREATE INDEX idx_pages_status ON payload.pages(_status);
```

### Table: `payload.posts`

```sql
CREATE TABLE payload.posts (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  hero_image_id UUID REFERENCES payload.media(id),
  content JSONB,                   -- Lexical rich text
  published_at TIMESTAMP,
  _status TEXT DEFAULT 'draft',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE payload.posts_rels (
  id SERIAL PRIMARY KEY,
  parent_id UUID REFERENCES payload.posts(id) ON DELETE CASCADE,
  path TEXT NOT NULL,              -- 'categories', 'authors', 'relatedPosts'
  posts_id UUID REFERENCES payload.posts(id),
  categories_id UUID REFERENCES payload.categories(id),
  users_id UUID REFERENCES payload.users(id)
);
```

### Table: `payload.media`

```sql
CREATE TABLE payload.media (
  id UUID PRIMARY KEY,
  filename TEXT NOT NULL,
  alt TEXT,
  caption JSONB,
  mime_type TEXT,
  filesize INTEGER,
  width INTEGER,
  height INTEGER,
  focal_x NUMERIC,
  focal_y NUMERIC,
  sizes JSONB,                     -- Generated sizes metadata
  url TEXT NOT NULL,               -- Public URL (S3/R2)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_media_filename ON payload.media(filename);
```

### Table: `payload.categories`

```sql
CREATE TABLE payload.categories (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table: `payload.users`

```sql
CREATE TABLE payload.users (
  id UUID PRIMARY KEY,
  name TEXT,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,          -- bcrypt hashed
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_users_email ON payload.users(email);
```

---

**Report Prepared By**: v_senior_developer
**Date**: 2025-10-12
**Version**: 1.0.0
**Status**: Draft - Pending Approval

---

**Approval:**
- [ ] v_product_architect
- [ ] Joel Edsel Schaeffer (Owner)

**Once approved, this report will guide Phase 0 implementation starting Nov 15, 2025.**
