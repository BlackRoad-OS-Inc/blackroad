# BlackRoad Ecosystem Architecture
**Constitution for long-lived, multi-agent, multi-domain infrastructure**

---

## Context & Role

This is **large, multi-domain, multi-repo, multi-agent** infrastructure.
Multiple AI agents and human contributors work in parallel.
**Clarity, boundaries, and repeatable patterns matter more than speed.**

Assumptions:
- We are designing **long-lived infrastructure**, not a demo
- We want **clear ownership boundaries**, **least privilege**, and **deployable reality**
- Avoid over-engineering (no unnecessary gateways, no magic routers)

---

## High-Level Vision

BlackRoad ecosystem consists of:
- Public products
- Internal AI / employee systems
- A simulation / world engine (Lucidia)
- Company, investor, creator, and personal hubs
- A blockchain + currency layer

**Domains are NOT marketing labels — they represent sovereign system boundaries.**

---

## Infrastructure Rules (The Constitution)

### Rule 1: Sovereign Computing (3 Layers)
```
Cloudflare Edge (DNS/TLS/WAF) → Your Compute (Railway/Pi/Jetson) → Failover (cloud is insurance)
```

### Rule 2: Subdomain-Oriented Architecture
```
One subdomain = one container/service
DNS is the router
No giant internal router needed
```

### Rule 3: Project = Boundary
```
Railway Project = one domain / bounded context
Railway Service = one deployable runtime
Subdomain = one service
Repo ≠ service by default (repos are implementation details)
```

### Rule 4: Isolation is Intentional
```
No shared "mega project"
Each domain can fail independently
Service-to-service auth via tokens
```

---

## Canonical Domain Map

| Domain | Purpose | Railway Project | Access Level |
|--------|---------|----------------|--------------|
| blackroad.io | Public apps & products | br-apps | Public |
| blackroad.systems | Internal AI/employee hubs | br-internal | Private (Zero Trust) |
| lucidia.earth | Simulation / world engine | lucidia-engine | Public API, private studio |
| blackroad.company | Company operations | br-company | Mixed |
| blackroad.me | Personal hub | br-me | Private (Alexa only) |
| blackroadinc.us | Investor relations | br-investors | Mixed |
| roadchain.io | Blockchain / ledger | roadchain-core | Public |
| roadcoin.io | Currency & payments | roadcoin-payments | Public API, auth wallets |
| blackroad.studio | Creator platform | br-studio | Authenticated |

---

## Minimum Viable Canonical Structure (Phase 1)

### br-apps (blackroad.io) - IMPLEMENT THIS FIRST

**Priority: P0 - Core Infrastructure**

| Subdomain | Service Name | Repo | Purpose | Required |
|-----------|--------------|------|---------|----------|
| www / @ | web | blackroad-os-web | Main portal/landing | ✅ YES |
| api | api | blackroad-os-api | Core API backend | ✅ YES |
| app | app | blackroad-os-prism-console | Console UI | ✅ YES |
| agents | agents | blackroad-os-agents | Agent orchestration | ⚠️ Phase 1B |
| ops | ops | blackroad-os-operator | Operational control | ⚠️ Phase 1B |

**DO NOT create gateway unless you prove you need it after deploying the above.**

**Phase 1A (Week 1):**
1. Deploy: web, api, app
2. Get them talking to each other
3. Verify end-to-end: www → api → app
4. Test service-to-service calls via Railway internal networking

**Phase 1B (Week 2):**
1. Add: agents (if needed)
2. Add: ops (if needed)
3. Decision point: Do we need gateway? (Probably no)

**Environments:**
- dev
- staging
- prod

**Database:**
- Postgres (shared across services in br-apps)
- Redis (if needed for queues/cache)

---

## Service Naming Conventions

### Railway Projects
```
br-apps          → blackroad.io
br-internal      → blackroad.systems
br-company       → blackroad.company
br-me            → blackroad.me
br-investors     → blackroadinc.us
br-studio        → blackroad.studio
lucidia-engine   → lucidia.earth
roadchain-core   → roadchain.io
roadcoin-payments → roadcoin.io
```

### Railway Services (within a project)
Standard names:
- `web` - Frontend application
- `api` - Backend API
- `app` - Console/admin UI
- `worker` - Background jobs/agents
- `ops` - Operational tools
- `db` - Postgres database
- `redis` - Redis cache/queue

### Subdomains
Format: `{service}.{domain}`

Examples:
- www.blackroad.io
- api.blackroad.io
- app.blackroad.io
- agents.blackroad.io

---

## When to Split a Service

**Create a new service when:**
- Different deployment cadence needed
- Different resource requirements (CPU/memory)
- Clear bounded context (agents vs API)
- Different access control requirements

**DO NOT create a new service for:**
- Different routes in same API
- Different pages in same web app
- Shared libraries (those are npm packages, not services)

---

## When NOT to Create a New Repo or Project

**DO NOT create new repo for:**
- Shared types (use monorepo or npm package)
- Config files (store in main app repo)
- Documentation (use main repo or br-company)

**DO NOT create new Railway project for:**
- Different environments (use Railway environments)
- Different services in same domain (use services within project)

---

## Repository Classification

### Deployable (Maps to Railway Service)
- blackroad-os-web → br-apps/web
- blackroad-os-api → br-apps/api
- blackroad-os-prism-console → br-apps/app
- blackroad-os-agents → br-apps/agents
- blackroad-os-operator → br-apps/ops
- lucidia-platform → lucidia-engine/api

### Non-Deployable (Libraries/Tools)
- blackroad-os-core → npm package / shared library
- blackroad-os-brand → static assets / Cloudflare Pages
- blackroad-os-docs → Cloudflare Pages / GitHub Pages
- blackroad-os-infra → Infrastructure as code

---

## Environment Variables Convention

### Shared (Project-level)
```bash
NODE_ENV=production
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
```

### Service-specific (Service-level)
```bash
# web service
NEXT_PUBLIC_API_URL=https://api.blackroad.io
NEXT_PUBLIC_APP_URL=https://app.blackroad.io

# api service
PORT=3000
CORS_ORIGIN=https://www.blackroad.io,https://blackroad.io

# app service
VITE_API_URL=https://api.blackroad.io

# worker service
QUEUE_URL=${{Redis.REDIS_URL}}
```

### Service-to-Service Communication
Use Railway's internal networking:
```bash
API_PRIVATE_URL=http://${{api.RAILWAY_PRIVATE_DOMAIN}}:3000
```

---

## Permission Architecture

### Layer 1: Cloudflare Zero Trust

**Public domains (no auth):**
- blackroad.io
- lucidia.earth
- roadchain.io
- roadcoin.io
- blackroad.company (public pages)

**Protected domains (Cloudflare Access required):**
- *.blackroad.systems (all subdomains)
- ops.blackroad.io
- blackroad.me
- data.blackroadinc.us
- studio.blackroad.studio

**Access methods:**
- Email OTP (amundsonalexa@gmail.com)
- GitHub OAuth (blackboxprogramming org members)
- Device posture (registered devices)

### Layer 2: Service-Level Tokens

Each service validates tokens independently.

**Token types:**
- User tokens (JWT from auth service)
- Service tokens (for service-to-service)
- API keys (for third-party)

**The Rule:** "Don't talk to me, go there"
- All permission decisions happen at id.blackroad.systems
- Services validate tokens, don't make permission decisions

---

## Deployment Checklist (br-apps)

### Railway Setup
- [ ] Create project: `br-apps`
- [ ] Create environments: dev, staging, prod
- [ ] Add Postgres database
- [ ] Deploy service: web (blackroad-os-web)
- [ ] Deploy service: api (blackroad-os-api)
- [ ] Deploy service: app (blackroad-os-prism-console)
- [ ] Configure environment variables (all services)
- [ ] Test service-to-service communication
- [ ] Get Railway public domains for each service

### Cloudflare DNS
- [ ] Create CNAME: www.blackroad.io → web domain
- [ ] Create CNAME: @ (root) → web domain
- [ ] Create CNAME: api.blackroad.io → api domain
- [ ] Create CNAME: app.blackroad.io → app domain
- [ ] Enable proxy (orange cloud) for all
- [ ] Verify SSL certificates issued

### Testing
- [ ] https://www.blackroad.io returns 200
- [ ] https://blackroad.io redirects to www
- [ ] https://api.blackroad.io/health returns 200
- [ ] https://app.blackroad.io returns 200
- [ ] Check Railway logs for errors
- [ ] Test API calls from web/app to api
- [ ] Verify database connections

---

## Risks & Simplifications

### Risks
1. **Over-engineering gateway** - Only add if proven necessary
2. **Too many services too fast** - Start with web+api+app, then expand
3. **Inconsistent naming** - Follow conventions strictly
4. **Missing auth layer** - Deploy id.blackroad.systems early

### Recommended Simplifications
1. **Skip gateway initially** - Use direct service-to-service calls
2. **Share Postgres** - One DB per project, not per service
3. **Use Railway's internal networking** - Don't expose everything publicly
4. **Cloudflare for static assets** - Don't deploy trivial services to Railway

---

## Agents & Multi-Contributor Pattern

### For AI Agents
- Each agent should own ONE domain (e.g., one agent for br-apps, one for br-internal)
- Agents read this ARCHITECTURE.md before making changes
- Agents propose changes, humans approve
- No agent modifies another agent's domain without approval

### For Humans
- Follow the same domain ownership pattern
- Use Linear for task tracking per domain
- Deploy to staging first, then prod
- Document decisions in relevant domain's README

---

## Questions to Ask Before Proceeding

1. **Do I need a new service, or can this be part of an existing one?**
2. **Do I need a new project, or is this a service within an existing domain?**
3. **Do I need a new repo, or can this be in a monorepo/package?**
4. **Is this public or private? (Determines Cloudflare Access setup)**
5. **Does this need a subdomain, or is it just a route?**

**Default answer: Use existing structure unless you can prove you need new.**

---

## Next Immediate Actions

### TODAY (You)
1. Open Railway dashboard: https://railway.app/new
2. Create project: `br-apps`
3. Add environments: dev, staging, prod
4. Deploy: web, api, app (in that order)
5. Configure env vars for each service
6. Get Railway domains

### TOMORROW (After Railway setup)
1. Run Cloudflare DNS automation script
2. Test all endpoints
3. Verify service-to-service communication
4. Monitor Railway logs for 24 hours

### WEEK 2
1. Add agents + ops if needed
2. Evaluate: Do we need gateway?
3. Start planning br-internal (blackroad.systems)

---

## Reference

**Created:** 2025-12-14
**Owner:** Alexa Amundson (amundsonalexa@gmail.com)
**Status:** Canonical - All agents and humans must follow this
**Version:** 1.0

**Related Docs:**
- `DOMAIN-ARCHITECTURE-MASTER.md` - Full 9-domain map
- `BR-APPS-COMPLETE-SETUP.md` - Detailed setup guide
- `INFRASTRUCTURE_INVENTORY.md` - Current state audit (in blackroad-os-operator)

**Approval Required For:**
- Adding new domains
- Creating new Railway projects
- Changing naming conventions
- Modifying permission architecture

**This is the constitution. Follow it.**
