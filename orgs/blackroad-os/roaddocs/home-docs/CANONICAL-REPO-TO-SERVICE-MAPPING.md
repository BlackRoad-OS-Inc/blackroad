# Canonical Repository → Service Mapping
**Created:** 2025-12-14
**Purpose:** Definitive mapping of GitHub repos to Railway services and subdomains

---

## Classification Summary

| Type | Count | Description |
|------|-------|-------------|
| **Deployable (Railway)** | 5 | Runtime apps that need compute |
| **Deployable (Cloudflare)** | 1 | Edge workers on Cloudflare |
| **Non-Deployable** | 8+ | Libraries, docs, static sites |

---

## Part 1: Deployable Services → br-apps (blackroad.io)

### ✅ Deploy These to Railway

| # | Repo | Service Name | Subdomain | Runtime | Purpose |
|---|------|--------------|-----------|---------|---------|
| 1 | **blackroad-os-web** | `web` | www.blackroad.io | Next.js 14 (static) | Main landing/portal, browser shell |
| 2 | **blackroad-api** | `api` | api.blackroad.io | Hono + Cloudflare Workers | Agency detection & mesh API (⚠️ Note below) |
| 3 | **blackroad-os-prism-console** | `app` | app.blackroad.io | Next.js 14 | Prism admin console, desktop UI |
| 4 | **blackroad-os-agents** | `agents` | agents.blackroad.io (optional) | Node.js CLI | Agent registry & SDK (⚠️ Note below) |
| 5 | **blackroad-os-operator** | `ops` | ops.blackroad.io | Python (FastAPI) + TypeScript workers | Orchestration engine, job queues |

**Total for Phase 1:** Deploy #1, #3, #5 (web, app, ops)
**Phase 1B:** Evaluate #2 (api) and #4 (agents)

---

### Special Notes on Each Service

#### 1. blackroad-os-web → `web` service
**Type:** Next.js 14 static export
**Deploy to:** Railway
**Subdomain:** www.blackroad.io + @ (root)

**Characteristics:**
- Static-first architecture (`output: 'export'`)
- Content via Contentlayer (MDX docs + blog)
- No server runtime (serves from `.out/`)
- Uses `serve` package for static serving

**Environment Variables:**
```bash
NODE_ENV=production
SITE_URL=https://blackroad.io
PLAUSIBLE_DOMAIN=analytics.blackroad.io
PORT=3000
```

**Build Command:** `pnpm build`
**Start Command:** `serve -s out -l ${PORT:-3000}`

**Why Deploy:** Public-facing portal and documentation

---

#### 2. blackroad-api → `api` service ⚠️
**Type:** Hono app (Cloudflare Workers)
**Deploy to:** ⚠️ **Cloudflare Workers** (NOT Railway)
**Subdomain:** api.blackroad.io

**Characteristics:**
- Built for Cloudflare Workers runtime
- Uses Wrangler for deployment
- Lightweight Hono framework
- Agency detection + mesh API

**Deployment:**
```bash
# Deploy via Wrangler
cd blackroad-api
wrangler deploy
```

**Why NOT Railway:** This is a Cloudflare Worker, designed for edge deployment. It should go to Cloudflare, not Railway.

**Alternative for Railway:** If you need an API on Railway, consider:
- Creating `blackroad-os-api` as a new repo (Express/Fastify/Hono on Node)
- Or deploying `blackroad-os-operator` Python API as the main API

---

#### 3. blackroad-os-prism-console → `app` service
**Type:** Next.js 14 app
**Deploy to:** Railway
**Subdomain:** app.blackroad.io

**Characteristics:**
- Desktop-style admin console
- Next.js 14 App Router
- Minimal dependencies (class-variance-authority, tailwind)
- Prism branding

**Environment Variables:**
```bash
NODE_ENV=production
VITE_API_URL=https://api.blackroad.io
PORT=3000
```

**Build Command:** `pnpm build`
**Start Command:** `next start -p ${PORT:-3000}`

**Why Deploy:** Core admin/console interface for BlackRoad OS

---

#### 4. blackroad-os-agents → `agents` service ⚠️
**Type:** Node.js CLI + Registry
**Deploy to:** ⚠️ **MAYBE** (see notes)
**Subdomain:** agents.blackroad.io (if deployed)

**Characteristics:**
- Agent registry (YAML-based)
- CLI tool (`br-agent`)
- SDK for agent development
- Not a web service by default

**Should you deploy it?**
- **NO** if it's just a CLI tool / npm package
- **YES** if you add a web API layer to query agent registry
- **MAYBE** if you expose agent.yaml as a service endpoint

**Decision Point:** Evaluate in Phase 1B. Likely this should be:
- Published to npm as a package (not deployed)
- Registry served via `ops` service instead

---

#### 5. blackroad-os-operator → `ops` service
**Type:** Dual runtime (Python FastAPI + TypeScript workers)
**Deploy to:** Railway
**Subdomain:** ops.blackroad.io

**Characteristics:**
- Primary: Python FastAPI (port 8080)
- Secondary: TypeScript BullMQ workers (port 4000)
- Agent orchestration, job queues, workflows
- Policy engine, ledger, LLM integration

**Environment Variables (Python):**
```bash
PORT=8080
REDIS_URL=${{Redis.REDIS_URL}}
CATALOG_PATH=/app/agent-catalog/agents.yaml
OPENAI_API_KEY=${OPENAI_API_KEY}
COMMIT_SHA=${RAILWAY_GIT_COMMIT_SHA}
```

**Environment Variables (TypeScript - if deployed separately):**
```bash
PORT=4000
REDIS_URL=${{Redis.REDIS_URL}}
NODE_ENV=production
```

**Build Commands:**
- Python: `pip install -r requirements.txt`
- TypeScript: `pnpm build`

**Start Commands:**
- Python: `uvicorn br_operator.main:app --host 0.0.0.0 --port 8080`
- TypeScript: `node dist/index.js`

**Railway Strategy:**
- Deploy as ONE service with Python as primary
- Or deploy as TWO services (`ops-api` + `ops-workers`)

**Why Deploy:** Critical orchestration layer, needs to run 24/7

---

## Part 2: Non-Deployable Repos

### 🚫 DO NOT Deploy These (Reasons)

| Repo | Type | Why Not Deploy | What To Do Instead |
|------|------|----------------|-------------------|
| **blackroad-console** | Tauri desktop app | Desktop app, not web service | Distribute as downloadable app |
| **blackroad-os-core** | Shared library | No runtime, just types/utils | Publish to npm as package |
| **blackroad-os-brand** | Static assets | Design files, logos, fonts | Deploy to Cloudflare Pages or S3 |
| **blackroad-os-docs** | Documentation | Static docs | Deploy to Cloudflare Pages or use blackroad-os-web |
| **blackroad-os-home** | Company handbook | Static content | Deploy to Cloudflare Pages or br-company |
| **blackroad-os-demo** | Demo/example | Not production code | Keep in GitHub for reference |
| **blackroad-os-infra** | Infrastructure as code | Terraform/config files | Use for deployments, don't deploy itself |
| **blackroad-os-archive** | Audit logs | Append-only storage | Backend service, not web-facing |
| **lucidia-platform** | Monorepo | Contains multiple apps | Deploy sub-apps individually (api/, web/) |

---

## Part 3: Special Cases

### lucidia-platform (Monorepo)

This is a **monorepo** with multiple deployable parts:

```
lucidia-platform/
├── api/          → Deploy as lucidia-engine/api
├── web/          → Deploy as lucidia-engine/web (or studio)
├── deploy/       → Deployment configs
└── packages/     → Shared libs (don't deploy)
```

**How to deploy:**
1. Create Railway project: `lucidia-engine`
2. Add service: `api` (point to `lucidia-platform/api/`)
3. Add service: `web` (point to `lucidia-platform/web/`)
4. Configure build paths in Railway

---

### blackroad-api (Cloudflare Worker)

**DO NOT** add to Railway. This goes to Cloudflare:

```bash
# Deploy to Cloudflare
cd blackroad-api
wrangler deploy

# Will be available at:
# api.blackroad.io (via Cloudflare Workers)
```

**Alternative:** If you want a traditional API on Railway:
- Option A: Create new repo `blackroad-os-api` with Express/Fastify
- Option B: Use `blackroad-os-operator` Python API endpoints
- Option C: Keep blackroad-api on Cloudflare, use as edge API

---

## Part 4: Recommended Service Architecture

### Phase 1: Minimum Viable (br-apps)

```
br-apps (Railway Project)
├── web          blackroad-os-web              → www.blackroad.io
├── app          blackroad-os-prism-console    → app.blackroad.io
├── ops          blackroad-os-operator         → ops.blackroad.io
└── Postgres     (Railway add-on)              → ${{Postgres.DATABASE_URL}}
```

**DO NOT deploy yet:**
- api (Cloudflare Worker)
- agents (CLI tool / npm package)
- gateway (don't need it)

---

### Phase 1B: Evaluate & Add

After Phase 1 is stable, consider:

1. **Do we need a separate API service on Railway?**
   - If yes: Create `blackroad-os-api` (Express/Fastify)
   - If no: Use `ops` service endpoints

2. **Do we need agents service?**
   - If yes: Add web API layer to blackroad-os-agents
   - If no: Keep as npm package

3. **Do we need gateway?**
   - Probably no (subdomain-oriented architecture)
   - Use Cloudflare for routing instead

---

## Part 5: Environment Variable Templates

### web service (blackroad-os-web)

```bash
# Railway Environment Variables
NODE_ENV=production
SITE_URL=https://blackroad.io
PLAUSIBLE_DOMAIN=analytics.blackroad.io
PORT=3000

# No database needed (static site)
```

### app service (blackroad-os-prism-console)

```bash
# Railway Environment Variables
NODE_ENV=production
VITE_API_URL=https://api.blackroad.io
# or: VITE_API_URL=http://${{ops.RAILWAY_PRIVATE_DOMAIN}}:8080
PORT=3000

# Optional: If it needs DB
DATABASE_URL=${{Postgres.DATABASE_URL}}
```

### ops service (blackroad-os-operator)

```bash
# Railway Environment Variables - Python Runtime
PORT=8080
NODE_ENV=production
REDIS_URL=${{Redis.REDIS_URL}}
DATABASE_URL=${{Postgres.DATABASE_URL}}

# Paths
CATALOG_PATH=/app/agent-catalog/agents.yaml

# Integrations
OPENAI_API_KEY=<set in Railway secrets>
ANTHROPIC_API_KEY=<set in Railway secrets>

# Metadata
COMMIT_SHA=${{RAILWAY_GIT_COMMIT_SHA}}
RAILWAY_ENVIRONMENT=${{RAILWAY_ENVIRONMENT_NAME}}
```

---

## Part 6: Decision Matrix

### Should I deploy this repo?

Ask these questions:

| Question | If YES | If NO |
|----------|--------|-------|
| Does it have a `start` script? | Consider deploying | Don't deploy |
| Does it need to run 24/7? | Deploy to Railway | Don't deploy |
| Is it a web app or API? | Deploy to Railway or Cloudflare | Don't deploy |
| Is it a library/package? | Don't deploy | Publish to npm |
| Is it static content? | Deploy to Cloudflare Pages | Don't deploy to Railway |
| Is it a CLI tool? | Don't deploy | Distribute as package |
| Is it infrastructure code? | Don't deploy | Use for setup |

---

## Part 7: Deployment Checklist (Per Service)

For each deployable service:

- [ ] Repo has `package.json` with `start` script (or equivalent)
- [ ] Identified runtime (Node.js, Python, etc.)
- [ ] Determined port (default: 3000, 8080, etc.)
- [ ] Listed required environment variables
- [ ] Identified dependencies (DB, Redis, etc.)
- [ ] Decided on subdomain (e.g., app.blackroad.io)
- [ ] Confirmed it belongs to correct Railway project (br-apps, br-internal, etc.)
- [ ] Verified it's not better suited for Cloudflare Workers or Pages

---

## Part 8: Summary Table

### Immediate Deployment (Phase 1)

| Service | Repo | Deploy To | Subdomain | Priority |
|---------|------|-----------|-----------|----------|
| web | blackroad-os-web | Railway | www.blackroad.io | P0 |
| app | blackroad-os-prism-console | Railway | app.blackroad.io | P0 |
| ops | blackroad-os-operator | Railway | ops.blackroad.io | P0 |

### Evaluate Later (Phase 1B)

| Service | Repo | Decision Needed |
|---------|------|-----------------|
| api | blackroad-api | Deploy to Cloudflare OR create new Railway API |
| agents | blackroad-os-agents | Add web API OR keep as npm package |

### Never Deploy

| Repo | Reason |
|------|--------|
| blackroad-console | Desktop app (Tauri) |
| blackroad-os-core | Library |
| blackroad-os-brand | Static assets |
| blackroad-os-docs | Static docs |
| black road-os-infra | Infrastructure code |

---

## Questions & Clarifications

### Q: What about blackroad-os-master, blackroad-os-archive, etc.?

**A:** Based on naming patterns:
- `*-master`: Likely a meta/overview repo (don't deploy)
- `*-archive`: Audit logs/storage (backend only, not web-facing)
- `*-helper`: Utility scripts (don't deploy)
- `*-pack-*`: Content packs (likely static or library)

**Need to investigate these repos further if they exist on GitHub.**

### Q: Should gateway be deployed?

**A:** Probably **NO**. The subdomain-oriented architecture means:
- Cloudflare handles routing by hostname
- Each service is independent
- No need for a central API gateway

**Only deploy gateway if:**
- You prove you need request aggregation
- You need centralized auth middleware
- You have existing gateway logic you can't move

---

## Next Steps

1. ✅ Use this mapping for Phase 1 deployment
2. ✅ Follow PHASE-1-DEPLOYMENT-CHECKLIST.md
3. ⚠️ Decide on API strategy (Cloudflare Worker vs Railway service)
4. ⚠️ Decide on agents (npm package vs web service)
5. ⚠️ Investigate other repos on GitHub if not covered here

---

**This is the canonical mapping. Use it as source of truth for deployments.**

**Last Updated:** 2025-12-14
**Status:** Complete for known repos
**Owner:** Alexa Amundson
