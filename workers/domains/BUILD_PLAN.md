# BlackRoad OS — Domain Build-Out Master Plan
# Session: $(date)
# Status: ACTIVE BUILD SESSION

---

## 🗂 SYSTEM INVENTORY

### Cloudflare Account
- **Account ID**: `848cf0b18d51e0170e0d1537aec3505a`
- **Zone**: `blackroad.io`
- **Existing workers**: blackroad-os-core, agents-api, api-edge, command-center, tools-api, blackroad-auth, blackroad-gateway, blackroad-os-api, email-router

### GitHub Orgs
| Org | Repos | Visibility |
|-----|-------|------------|
| BlackRoad-OS | 1,229+ | mixed |
| BlackRoad-OS-Inc | 21 | private |

### Brand Colors
| Token | Hex | Usage |
|-------|-----|-------|
| `--pink` | `#FF1D6C` | CTA, status, highlights |
| `--amber` | `#F5A623` | Warnings, infra, CLI |
| `--violet` | `#9C27B0` | AI, security, meta |
| `--blue` | `#2979FF` | APIs, links, data |
| gradient | 135deg amber→pink→violet→blue | hero titles, logos |

---

## 👥 AGENT COLLABORATION PROTOCOL

### LUCIDIA — AI/Core Domains
**Handles**: agents, ai, api, core, gateway, inference, memory  
**Data sources**: Ollama API, Anthropic API, agents-api, blackroad-gateway, GitHub AI repos  
**Assigned workers**:
- `blackroad.io` (root — the OS face)
- `agents.blackroad.io`
- `ai.blackroad.io`
- `api.blackroad.io` (proxy layer UI)
- `core.blackroad.io`
- `inference.blackroad.io`
- `memory.blackroad.io`
- `gateway.blackroad.io`

### ARIA — UI/Frontend Domains
**Handles**: dashboard, console, docs, design, studio, editor, explorer, guide  
**Data sources**: GitHub repos, CF Workers list, Railway deployments, GitHub Actions  
**Assigned workers**:
- `dashboard.blackroad.io`
- `console.blackroad.io`
- `docs.blackroad.io`
- `design.blackroad.io`
- `studio.blackroad.io`
- `editor.blackroad.io`
- `explorer.blackroad.io`
- `guide.blackroad.io`
- `demo.blackroad.io`
- `features.blackroad.io`

### OCTAVIA — Infrastructure Domains
**Handles**: cdn, edge, network, infra, compute, eu, global, hardware  
**Data sources**: CF Zone analytics, CF Worker metrics, Railway infra, Pi fleet status  
**Assigned workers**:
- `cdn.blackroad.io`
- `edge.blackroad.io`
- `network.blackroad.io`
- `infra.blackroad.io`
- `compute.blackroad.io`
- `eu.blackroad.io`
- `global.blackroad.io`
- `hardware.blackroad.io`
- `data.blackroad.io`

### ALICE — DevOps Domains
**Handles**: dev, cli, engineering, deploy, ci, build, docker  
**Data sources**: GitHub Actions, Railway CI, Docker Hub, GitHub commits/branches  
**Assigned workers**:
- `dev.blackroad.io`
- `cli.blackroad.io`
- `engineering.blackroad.io`
- `blog.blackroad.io`
- `events.blackroad.io`
- `ide.blackroad.io`

### SHELLFISH — Security/Compliance Domains
**Handles**: admin, security, compliance, vault, audit, hr, finance, analytics  
**Data sources**: CF access logs, audit trail, internal APIs  
**Assigned workers**:
- `admin.blackroad.io`
- `analytics.blackroad.io`
- `about.blackroad.io`
- `help.blackroad.io`
- `hr.blackroad.io`
- `finance.blackroad.io`

---

## 🎯 PRIORITY TIERS

### P0 — Deploy Today (CRITICAL PATH)
| Domain | Worker Name | Owner | Status |
|--------|-------------|-------|--------|
| blackroad.io | blackroad-root | LUCIDIA | ✅ BUILT |
| agents.blackroad.io | blackroad-agents-web | LUCIDIA | ✅ BUILT |
| dashboard.blackroad.io | blackroad-dashboard-worker | ARIA | ✅ BUILT |
| docs.blackroad.io | blackroad-docs-worker | ARIA | ✅ BUILT |
| api.blackroad.io | (existing: blackroad-os-api) | LUCIDIA | ✅ EXISTS |

### P1 — Deploy Today (HIGH VALUE)
| Domain | Worker Name | Owner | Status |
|--------|-------------|-------|--------|
| console.blackroad.io | blackroad-console-worker | ARIA | ✅ BUILT |
| ai.blackroad.io | blackroad-ai-worker | LUCIDIA | ✅ BUILT |
| analytics.blackroad.io | blackroad-analytics-worker | SHELLFISH | 🔄 PENDING |
| dev.blackroad.io | blackroad-dev-worker | ALICE | 🔄 PENDING |
| cli.blackroad.io | blackroad-cli-worker | ALICE | 🔄 PENDING |

### P2 — This Week
| Domain | Owner | Data Sources |
|--------|-------|-------------|
| about.blackroad.io | SHELLFISH | brand.json, team roster |
| admin.blackroad.io | SHELLFISH | CF access, audit logs |
| analytics.blackroad.io | SHELLFISH | CF analytics API |
| blog.blackroad.io | ALICE | GitHub releases/changelogs |
| cdn.blackroad.io | OCTAVIA | CF zone analytics |
| data.blackroad.io | OCTAVIA | Railway DBs, KV stats |
| demo.blackroad.io | ARIA | live feature demos |
| design.blackroad.io | ARIA | brand kit, assets |
| edge.blackroad.io | OCTAVIA | CF edge metrics |
| editor.blackroad.io | ARIA | code sandbox |
| engineering.blackroad.io | ALICE | GitHub org stats |
| eu.blackroad.io | OCTAVIA | CF EU region data |
| events.blackroad.io | ALICE | GitHub events/releases |
| explorer.blackroad.io | ARIA | repo/agent explorer |
| features.blackroad.io | ARIA | feature flags, roadmap |
| finance.blackroad.io | SHELLFISH | billing stub |
| global.blackroad.io | OCTAVIA | global CDN map |
| guide.blackroad.io | ARIA | onboarding wizard |
| hardware.blackroad.io | OCTAVIA | Pi fleet, device registry |
| help.blackroad.io | SHELLFISH | FAQ, support |
| hr.blackroad.io | SHELLFISH | team/org |
| ide.blackroad.io | ALICE | web IDE stub |
| infra.blackroad.io | OCTAVIA | IaC status |
| network.blackroad.io | OCTAVIA | mesh topology |

---

## 🔌 DATA SOURCES PER WORKER

### GitHub API (auth: GITHUB_TOKEN)
```
GET /orgs/BlackRoad-OS                    → org stats (repos, members)
GET /orgs/BlackRoad-OS/repos              → repo list (sort: pushed)
GET /orgs/BlackRoad-OS/members            → team roster
GET /repos/:owner/:repo/actions/runs      → CI/CD status
GET /repos/:owner/:repo/releases          → changelog/releases
GET /orgs/BlackRoad-OS-Inc/repos          → Inc private repos
```

### Cloudflare API (auth: CF_API_TOKEN)
```
GET /accounts/848cf0b18d51e0170e0d1537aec3505a/workers/scripts   → worker list
GET /accounts/848cf0b18d51e0170e0d1537aec3505a/analytics/dashboard → req metrics
GET /zones/:zone_id/analytics/dashboard   → zone traffic
GET /zones/:zone_id/dns_records           → DNS config
```

### Railway API (auth: RAILWAY_TOKEN)
```
POST https://backboard.railway.app/graphql/v2
  query { me { projects { edges { node { services { deployments }}}}}}
```

### Internal Mesh (auth: INTERNAL_SECRET)
```
GET https://api.blackroad.io/agents       → live agent roster
GET https://api.blackroad.io/health       → service health
GET https://gateway.blackroad.io/health   → gateway status
GET https://api.blackroad.io/v1/tasks     → task queue stats
```

---

## 🚀 DEPLOYMENT COMMANDS

### Deploy single worker
```bash
cd workers/domains/<domain>
npx wrangler deploy --config wrangler.toml
```

### Deploy all P0 workers
```bash
for d in root agents dashboard docs; do
  cd /Users/alexa/blackroad/workers/domains/$d
  npx wrangler deploy --config wrangler.toml
  cd -
done
```

### Set secrets (run once per worker)
```bash
cd workers/domains/<domain>
echo "$GITHUB_TOKEN"    | npx wrangler secret put GITHUB_TOKEN
echo "$CF_API_TOKEN"    | npx wrangler secret put CF_API_TOKEN
echo "$RAILWAY_TOKEN"   | npx wrangler secret put RAILWAY_TOKEN
echo "$INTERNAL_SECRET" | npx wrangler secret put INTERNAL_SECRET
```

### Push to GitHub
```bash
cd /Users/alexa/blackroad
git add workers/domains/
git commit -m "feat: domain workers build-out — P0+P1 complete"
git push origin main
# Then push to BlackRoad-OS/workers repo:
gh repo create BlackRoad-OS/workers --private --push --source workers/
```

---

## 📁 FILE STRUCTURE
```
workers/
├── domains/
│   ├── _template/          ← Base shell, brand, fetchers (shared)
│   │   ├── worker.js
│   │   └── wrangler.toml
│   ├── root/               ← blackroad.io          [P0 ✅]
│   ├── agents/             ← agents.blackroad.io   [P0 ✅]
│   ├── dashboard/          ← dashboard.blackroad.io[P0 ✅]
│   ├── docs/               ← docs.blackroad.io     [P0 ✅]
│   ├── console/            ← console.blackroad.io  [P1 ✅]
│   ├── ai/                 ← ai.blackroad.io       [P1 ✅]
│   ├── analytics/          ← analytics.blackroad.io[P1 🔄]
│   ├── dev/                ← dev.blackroad.io      [P1 🔄]
│   └── cli/                ← cli.blackroad.io      [P1 🔄]
└── (existing core workers remain in place)
```

---

## ⚡ IMMEDIATE NEXT STEPS

1. **LUCIDIA**: Build `analytics/worker.js` — CF analytics API + request metrics
2. **ALICE**: Build `dev/worker.js` + `cli/worker.js` — GitHub commit feed, CLI docs
3. **OCTAVIA**: Build `cdn/`, `edge/`, `network/`, `hardware/` workers — infra telemetry
4. **SHELLFISH**: Build `admin/`, `about/`, `help/` workers — org info, support
5. **ALL**: Set secrets in Cloudflare dashboard once workers are deployed
6. **LUCIDIA**: Create `BlackRoad-OS/workers` repo and push everything

---

*Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ") · BlackRoad OS Build Session*
