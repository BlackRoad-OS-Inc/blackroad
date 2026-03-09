# Domain Architecture Master Plan
**Principle:** Domain = Boundary, Subdomain = Service
**Pattern:** Cloudflare Edge → Railway Service → Internal Calls

---

## The Two Laws

1. **Sovereign Computing = 3 Layers**
   - Cloudflare Edge (routing/TLS/WAF)
   - Your Compute (Railway/Pi/Jetson)
   - Failover (cloud is insurance, not the computer)

2. **Subdomain-Oriented Architecture**
   - One subdomain = one container/service
   - DNS is the router
   - No giant internal router needed

---

## Master Domain Map (9 Projects)

### 1) blackroad.io → br-apps (Public Apps & Products)

**Railway Project:** `br-apps`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| www / @ | web | blackroad-os-web | Main landing/portal |
| api | api | blackroad-os-api | Core API backend |
| app | prism | blackroad-os-prism-console | Console UI |
| agents | agents | blackroad-os-agents | Agent orchestration |
| ops | operator | blackroad-os-operator | Operational control |
| gateway | gateway | blackroad-os-api-gateway | (Optional) API gateway |

**Access:** Public (except ops - requires auth)

---

### 2) blackroad.systems → br-internal (Internal Employee/AI Hubs)

**Railway Project:** `br-internal`

| Subdomain | Service | Repo/Tool | Purpose |
|-----------|---------|-----------|---------|
| id | auth | Keycloak/Auth0 | SSO/Identity provider |
| console | admin | blackroad-os-operator | Internal admin console |
| policies | governance | Custom | Rules engine |
| vault | secrets | Vault/Custom | Secrets/internal docs |

**Access:** Locked down via Cloudflare Zero Trust
**Rule:** "Don't talk to me, go there" - all permissions enforced here

---

### 3) lucidia.earth → lucidia-engine (View Engine/Visualization)

**Railway Project:** `lucidia-engine`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| engine | renderer | lucidia-platform | Renderer/sim API |
| sim | simulation | lucidia-sim | Simulation output |
| api | platform-api | lucidia-platform/api | Platform API |
| studio | tools | lucidia-studio | Tools UI (optional) |

**Access:** Public API, authenticated studio
**Compute:** Heavy lifting on Jetson/Pi fleet, Railway is edge

---

### 4) blackroad.company → br-company (Company Operations)

**Railway Project:** `br-company`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| handbook | docs | blackroad-os-home | Company handbook |
| legal | legal-docs | blackroad-os-pack-legal | Legal resources |
| hr | hr-portal | Custom | HR tools |
| status | status-page | Custom/BetterUptime | Status dashboard |

**Access:** Public docs, internal tools restricted

---

### 5) blackroad.me → br-personal (Personal Hub)

**Railway Project:** `br-me`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| me / @ | dashboard | Custom | Personal dashboard |
| memory | memory-api | Custom | Personal memory UI/API |

**Access:** Private (Alexa only)
**Isolation:** SOA isolation for safety

---

### 6) blackroadinc.us → br-investors (Investor Relations)

**Railway Project:** `br-investors`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| ir | investor-site | Custom | Investor relations |
| data | metrics | Custom | Metrics room (locked) |

**Access:** Public IR, private data room

---

### 7) roadchain.io → roadchain-core (Canon Blockchain)

**Railway Project:** `roadchain-core`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| docs | protocol-docs | roadchain-docs | Protocol documentation |
| api | chain-api | roadchain-node | Chain API |
| explorer | block-explorer | roadchain-explorer | Explorer UI |

**Access:** Public
**Purpose:** Append-only audit ledger

---

### 8) roadcoin.io → roadcoin-payments (Currency/Payments)

**Railway Project:** `roadcoin-payments`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| pay | payments-ui | roadcoin-pay | Payments interface |
| api | payments-api | roadcoin-api | Payments API |
| wallet | wallet-ui | roadcoin-wallet | Wallet UI/API |

**Access:** Public API, authenticated wallets
**Purpose:** Internal credit/economic layer

---

### 9) blackroad.studio → br-studio (Creator Platform)

**Railway Project:** `br-studio`

| Subdomain | Service | Repo | Purpose |
|-----------|---------|------|---------|
| studio / @ | creator-ui | lucidia-studio | Creator suite UI |
| api | creator-api | Custom | Creator API |
| assets | media-cdn | Custom | Media bucket/CDN |

**Access:** Authenticated creators
**Purpose:** Publishing tools, assets pipeline

---

## Permission Architecture (Zero Trust)

### Layer 1: Cloudflare Access Policies

**Public Domains (No auth required):**
- blackroad.io
- lucidia.earth
- roadchain.io
- roadcoin.io
- blackroad.company (public pages)

**Protected Domains (Cloudflare Zero Trust):**
- *.blackroad.systems (all subdomains)
- ops.blackroad.io
- blackroad.me
- data.blackroadinc.us
- studio.blackroad.studio

**Access Methods:**
- Email OTP (amundsonalexa@gmail.com)
- GitHub OAuth (blackboxprogramming org)
- Device posture (registered devices only)

### Layer 2: Service-Level Token Auth

Each service validates tokens independently (SOA principle).

**Token Types:**
- User tokens (JWT from id.blackroad.systems)
- Service tokens (for service-to-service calls)
- API keys (for third-party integrations)

**Service-to-Service Calls:**
Use Railway's internal networking:
```
http://${SERVICE_NAME}.railway.internal:${PORT}
```
or
```
${{service.RAILWAY_PRIVATE_DOMAIN}}
```

---

## Implementation Order (Phased Rollout)

### Phase 1: Core Infrastructure (Week 1)
1. **br-apps** (blackroad.io)
   - Deploy: web, api
   - DNS: www, api
   - Verify end-to-end
   - Add: app (prism console)
   - Decision point: Do we need gateway?

### Phase 2: Internal Systems (Week 2)
2. **br-internal** (blackroad.systems)
   - Deploy: auth (Keycloak)
   - Deploy: console (operator)
   - Configure Cloudflare Zero Trust
   - Test permission flows

### Phase 3: Visualization (Week 3)
3. **lucidia-engine** (lucidia.earth)
   - Deploy: api, engine
   - Connect to Pi/Jetson fleet
   - Test rendering pipeline

### Phase 4: Company Operations (Week 4)
4. **br-company** (blackroad.company)
   - Deploy: handbook, status
   - Public documentation site

### Phase 5: Blockchain/Payments (Month 2)
5. **roadchain-core** (roadchain.io)
6. **roadcoin-payments** (roadcoin.io)
   - Deploy chain infrastructure
   - Deploy payment gateway

### Phase 6: Studio & Personal (Month 3)
7. **br-studio** (blackroad.studio)
8. **br-me** (blackroad.me)
9. **br-investors** (blackroadinc.us)

---

## Railway Project Naming Convention

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

Prefix rules:
- `br-*` = BlackRoad domains
- `lucidia-*` = Lucidia domains
- `road*-*` = Blockchain/currency domains

---

## Cost Projection

**Railway (all 9 projects):**
- Hobby: $5/user/month
- Usage: ~$10-30 per project
- **Total:** ~$100-300/month

**Cloudflare:**
- Free tier (DNS, basic proxy)
- Zero Trust: $0-7/user/month
- Workers/Pages: Pay-as-you-go
- **Total:** ~$0-20/month

**Infrastructure Total:** ~$120-320/month

---

## Next Immediate Steps (Today)

For **blackroad.io (br-apps)** specifically:

1. Open Railway dashboard
2. Create `br-apps` project
3. Add environments: dev, staging, prod
4. Deploy services in this order:
   - ✅ web (blackroad-os-web) → www.blackroad.io
   - ✅ api (blackroad-os-api) → api.blackroad.io
   - ✅ app (blackroad-os-prism-console) → app.blackroad.io
   - ⚠️ Evaluate if gateway is needed
   - ✅ agents (blackroad-os-agents) - internal only
   - ✅ ops (blackroad-os-operator) → ops.blackroad.io (locked)

5. Get Railway domains from deployed services
6. Run Cloudflare DNS automation:
   ```bash
   ./setup-cloudflare-dns-blackroad-io.sh
   ```

---

## Automation Scripts Created

- ✅ `BR-APPS-COMPLETE-SETUP.md` - Full manual setup guide
- ✅ `setup-cloudflare-dns-automated.sh` - DNS automation (generic)
- 🔄 Need: `setup-cloudflare-dns-blackroad-io.sh` - Full blackroad.io DNS setup
- 🔄 Need: `setup-all-9-domains.sh` - Master automation script

---

**Status:** Phase 1 ready to implement
**Owner:** Alexa Amundson
**Created:** 2025-12-14
**Last Updated:** 2025-12-14
