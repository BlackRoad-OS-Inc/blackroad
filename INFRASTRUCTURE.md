# BlackRoad OS Infrastructure

> Ground-truth infrastructure reference derived from config files in this repository.
> Every resource ID, hostname, and zone listed here traces to a real config file.

---

## Table of Contents

- [Status Legend](#status-legend)
- [Overview](#overview)
- [Infrastructure Map](#infrastructure-map)
- [Accounts & Credentials](#accounts--credentials)
- [Cloudflare](#cloudflare)
- [Railway](#railway)
- [Vercel](#vercel)
- [DigitalOcean](#digitalocean)
- [Device Fleet](#device-fleet)
- [Agent Infrastructure](#agent-infrastructure)
- [Local Services & Networking](#local-services--networking)
- [Local Databases (SQLite)](#local-databases-sqlite)
- [GitHub](#github)
- [Secrets Management](#secrets-management)
- [Infrastructure Commands](#infrastructure-commands)

---

## Status Legend

Every section in this document is tagged with a verification level:

| Tag | Meaning | Evidence |
|-----|---------|----------|
| `[DEPLOYED]` | Verified live with real URL or confirmed operational | Deploy URL in `deployments/status.json`, or confirmed running |
| `[CONFIGURED]` | Real config with resource IDs exists; runtime status unknown | Real KV/D1 IDs in `wrangler.toml`, real config in `railway.toml` |
| `[TEMPLATED]` | Config file exists but uses boilerplate, not yet customized | Generic NIXPACKS `railway.toml` or standard `vercel.json` |

---

## Overview

BlackRoad OS runs on a multi-cloud architecture designed for sovereignty, edge-first compute, and portability. Each cloud provider serves a specific purpose.

### Design Principles

1. **Sovereignty** - Data ownership and control; local-first where possible
2. **Edge-First** - Compute at the edge via Cloudflare Workers
3. **No Vendor Lock-in** - Portable configs, multiple providers
4. **Tokenless Agents** - Agents never hold API keys; all provider calls go through a gateway

### Provider Status

| Provider | Role | Config Evidence | Status |
|----------|------|-----------------|--------|
| **Cloudflare** | Edge, CDN, DNS, storage | 75 `wrangler.toml` files, 19 DNS zones | `[CONFIGURED]` |
| **Railway** | GPU inference, services | 45 `railway.toml` files, 1 GPU config | `[CONFIGURED]` |
| **Vercel** | Web apps | 15 `vercel.json` files | `[TEMPLATED]` |
| **DigitalOcean** | Persistent compute | 1 droplet (shellfish) | `[CONFIGURED]` |
| **GitHub** | Source, CI/CD, Pages | 16 orgs, 7 workflows in this repo | `[DEPLOYED]` |

**Source:** `control-map/index.yaml`

---

## Infrastructure Map

```
                            INTERNET
                               |
                               v
    ┌──────────────────────────────────────────────────────────┐
    │                   CLOUDFLARE EDGE                         │
    │  19 DNS zones | 75 workers | 11 KV | 6 D1 | R2 | Tunnel │
    └──────────────────┬──────────────┬────────────────────────┘
                       |              |
          ┌────────────┴──┐     ┌─────┴─────────┐
          |               |     |               |
    ┌─────┴─────┐   ┌────┴────┐│  ┌────────────┴──┐
    │  RAILWAY  │   │ VERCEL  ││  │  DIGITALOCEAN  │
    │           │   │         ││  │                │
    │ GPU (A100)│   │ Next.js ││  │  shellfish     │
    │ vLLM      │   │ 15 apps ││  │  159.65.43.12  │
    │ 45 configs│   │         ││  │  cloud-bridge  │
    └───────────┘   └─────────┘│  └────────────────┘
                               |
                     ┌─────────┴────────────────────────────┐
                     │         LOCAL DEVICE FLEET            │
                     │                                      │
                     │  alice      - control-plane           │
                     │  aria       - operations              │
                     │  octavia    - inference               │
                     │  codex      - build                   │
                     │  anastasia  - experimental            │
                     │                                      │
                     │  Gateway :8080 → NATS :4222           │
                     │  Agents: LUCIDIA ALICE OCTAVIA        │
                     │          PRISM   ECHO  CIPHER         │
                     │  Milvus :6333 | Ollama :11434         │
                     └──────────────────────────────────────┘
```

**Sources:** `control-map/devices/nodes.yaml`, `net.sh`, `blackroad-mesh.sh`

---

## Accounts & Credentials

From `control-map/index.yaml` and `control-map/accounts/credentials.yaml`:

| Service | Account / Identifier | Config Reference |
|---------|---------------------|------------------|
| Cloudflare | Account ID: `848cf0b18d51e0170e0d1537aec3505a` | `CF_API_TOKEN` (env) |
| GitHub | Enterprise: `blackroad-os`, Account: `blackboxprogramming` | `GH_TOKEN` (env) |
| DigitalOcean | Connected | `DO_TOKEN` (env) |
| Stripe | Account: `acct_1SUDM8ChUUSEbzyh` | `STRIPE_API_KEY` (env) |
| Vercel | Team: `alexa-amundsons-projects` | `VERCEL_TOKEN` (env) |
| Notion | Workspace: `76cded82e3874f9db0d44dff11b8f2fd` | - |
| Salesforce | Profiles: `w0290jck2ebf0xos3p`, `alexa-amundson` | - |
| Instagram | Handle: `blackroad.io` | - |

**Policy:** `no-secrets-in-repo` - All credentials stored as environment variables, never committed.

---

## Cloudflare

### DNS Zones (19) `[CONFIGURED]`

From `control-map/domains/cloudflare.yaml`:

| # | Zone |
|---|------|
| 1 | `aliceqi.com` |
| 2 | `blackboxprogramming.io` |
| 3 | `blackroadai.com` |
| 4 | `blackroad.company` |
| 5 | `blackroadinc.us` |
| 6 | `blackroad.io` |
| 7 | `blackroad.me` |
| 8 | `blackroad.network` |
| 9 | `blackroad.systems` |
| 10 | `blackroadqi.com` |
| 11 | `blackroadquantum.com` |
| 12 | `blackroadquantum.info` |
| 13 | `blackroadquantum.net` |
| 14 | `blackroadquantum.shop` |
| 15 | `blackroadquantum.store` |
| 16 | `lucidiaqi.com` |
| 17 | `lucidia.studio` |
| 18 | `roadchain.io` |
| 19 | `roadcoin.io` |

All zones share account ID `848cf0b18d51e0170e0d1537aec3505a`.

### Workers (75 configs) `[CONFIGURED]`

75 `wrangler.toml` files found across the repository. Of these, 13 have active KV/D1 bindings with real resource IDs. The rest are templated boilerplate.

**Key workers with real resource bindings:**

| Worker | Routes | Source |
|--------|--------|--------|
| `blackroad-api-gateway` | `api.blackroad.io/*`, `core.blackroad.io/*`, `operator.blackroad.io/*` | `repos/blackroad-os-core/workers/api-gateway/wrangler.toml` |
| `blackroad-payment-gateway` | `pay.blackroad.io/*`, `payments.blackroad.io/*` | `repos/blackroad-os-core/workers/payment-gateway/wrangler.toml` |
| `blackroad-io` | `blackroad.io/*` (dashboard-managed) | `repos/blackroad.io/wrangler.toml` |
| `blackroad-os` | (D1: saas + agent-registry) | `repos/blackroad-os/wrangler.toml` |
| `blackroad-prism-console` | (D1: agent-registry) | `repos/blackroad-os-prism-console/wrangler.toml` |
| `command-center` | (D1: continuity) | `repos/command-center/wrangler.toml` |
| `agents-api` | (D1: continuity) | `repos/agents-api/wrangler.toml` |
| `tools-api` | (KV: tools, D1: continuity) | `repos/tools-api/wrangler.toml` |
| `remotejobs-platform` | (KV: jobs + applications) | `repos/blackroad-os-core/remotejobs-platform/wrangler.toml` |

### KV Namespaces (11) `[CONFIGURED]`

Real namespace IDs extracted from `wrangler.toml` files:

| Binding | Namespace ID | Used By |
|---------|-------------|---------|
| `CACHE` | `c878fbcc1faf4eddbc98dcfd7485048d` | api-gateway, subdomain-router |
| `IDENTITIES` | `10bf69b8bc664a5a832e348f1d0745cf` | api-gateway, subdomain-router |
| `API_KEYS` | `57e48a017d4248a39df32661c3377908` | api-gateway, subdomain-router |
| `RATE_LIMIT` | `245a00ee1ffe417fbcf519b2dbb141c6` | api-gateway, subdomain-router |
| `TOOLS_KV` | `f7b2b20d1e1447b2917b781e6ab7e45c` | tools-api, blackroad-tools |
| `TEMPLATES` | `8df3dcbf63d94069975a6fa8ab17f313` | blackroad-io |
| `CONTENT` | `119ac3af15724b1b93731202f2968117` | blackroad-io (WORLD_KV) |
| `JOBS` | `2557a2b503654590ab7b1da84c7e8b20` | remotejobs-platform |
| `APPLICATIONS` | `90407b533ddc44508f1ce0841c77082d` | remotejobs-platform |
| `SUBSCRIPTIONS_KV` | `0cf493d5d19141df8912e3dc2df10464` | payment-gateway |
| `USERS_KV` | `67a82ad7824d4b89809e7ae2221aba66` | payment-gateway |

**Shared layer:** CACHE, IDENTITIES, API_KEYS, and RATE_LIMIT are shared across the api-gateway and subdomain-router workers.

### D1 Databases (6) `[CONFIGURED]`

Real database IDs extracted from `wrangler.toml` files:

| Database Name | Database ID | Bindings | Used By |
|--------------|-------------|----------|---------|
| `blackroad-os-main` | `e2c6dcd9-c21a-48ac-8807-7b3a6881c4f7` | DB | api-gateway, subdomain-router, blackroad-io |
| `blackroad-continuity` | `f0721506-cb52-41ee-b587-38f7b42b97d9` | CONTINUITY_DB, DB | command-center, agents-api, tools-api, blackroad-tools |
| `apollo-agent-registry` | `79f8b80d-3bb5-4dd4-beee-a77a1084b574` | AGENT_DB | prism-console |
| `apollo-agent-registry` | `0abd9447-9479-4138-ab04-cd0ae47b2e30` | DB_AGENTS | blackroad-os |
| `blackroad-saas` | `c7bec6d8-42fa-49fb-9d8c-57d626dde6b9` | DB_SAAS, BLACKROAD_SAAS | blackroad-os, blackroad-io-app |
| `blackroad_revenue` | `8744905a-cf6c-4e16-9661-4c67d340813f` | REVENUE_D1 | payment-gateway |

Note: `apollo-agent-registry` appears with two different database IDs across workers. This may indicate separate dev/prod databases or a migration artifact.

### R2 Storage `[CONFIGURED]`

| Bucket | Size | Purpose | Source |
|--------|------|---------|--------|
| `blackroad-models` | ~135 GB | Quantized LLMs (Qwen 72B, Llama 70B, DeepSeek R1 — all Q4_K_M) | `repos/blackroad-os-core/railway-models/` |

Models are downloaded on-demand to Railway GPU instances via `server-r2.py` using boto3.

### Pages Deployments `[DEPLOYED]`

From `deployments/status.json` — 4 verified live sites:

| Domain | Deploy URL | Project |
|--------|-----------|---------|
| `os.blackroad.io` | `https://a81f29a4.blackroad-os-web.pages.dev` | blackroad-os-web |
| `products.blackroad.io` | `https://79ea5ba2.blackroad-dashboard.pages.dev` | blackroad-dashboard |
| `roadtrip.blackroad.io` | `https://1486760f.blackroad-pitstop.pages.dev` | blackroad-pitstop |
| `pitstop.blackroad.io` | `https://30db9407.blackroad-portals.pages.dev` | blackroad-portals |

Total Pages projects: 79 (7 brand-compliant, 72 being perfected).

### Tunnel `[CONFIGURED]`

A Cloudflare tunnel named `blackroad` runs on the local device fleet using QUIC protocol. Configuration is managed via `cloudflared` with token-based authentication. The tunnel routes external domains to local services.

---

## Railway

### Config Pattern `[TEMPLATED]`

45 `railway.toml` files found. The standard template uses:

```toml
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "npm start"
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
```

All standard configs use NIXPACKS builder, port 8080, and `/health` checks. These are boilerplate — no project IDs or live service URLs are embedded.

### Model Inference `[CONFIGURED]`

One non-boilerplate config exists at `repos/blackroad-os-core/railway-models/railway.toml`:

```toml
[build]
builder = "DOCKERFILE"

[deploy]
startCommand = "python server.py"

[resources]
gpu = "nvidia-a100-80gb"
replicas = 1
```

**Configuration:**
- Model: `blackroad-qwen-72b` (Qwen 2.5 72B, Q4_K_M quantized)
- GPU: NVIDIA A100 80GB
- Memory utilization: 0.9
- Tensor parallel size: 1
- Identity validation: enabled
- Audit logging: enabled
- Breath synchronization: enabled

**Source:** `repos/blackroad-os-core/railway-models/railway.toml`

---

## Vercel

### Team & Projects `[TEMPLATED]`

| Detail | Value |
|--------|-------|
| Team | `alexa-amundsons-projects` |
| Config files found | 15 `vercel.json` files |

All `vercel.json` files use the same template pattern:

```json
{
  "version": 2,
  "builds": [{ "src": "package.json", "use": "@vercel/next" }],
  "headers": [
    { "source": "/(.*)", "headers": [
      { "key": "X-Frame-Options", "value": "DENY" },
      { "key": "X-Content-Type-Options", "value": "nosniff" }
    ]}
  ]
}
```

**Key projects with `vercel.json`:**
- `blackroad-os-prism-console`
- `blackroad-os`
- `blackroad-os-mesh`
- `blackroad-os-helper`
- `containers-template`
- `clerk-docs`
- `blackbox-airbyte` (docusaurus)

No custom domains, edge functions, or project IDs are configured in these files. All use `@vercel/next` builder.

**Source:** `control-map/index.yaml` (team name)

---

## DigitalOcean

### Droplet: shellfish `[CONFIGURED]`

| Detail | Value |
|--------|-------|
| Hostname | `shellfish` |
| IP | `159.65.43.12` |
| Role | `cloud-bridge` |
| Notes | DigitalOcean droplet, gateway to cloud services |

This is the only DigitalOcean resource referenced in config files. The `blackroad-mesh.sh` script pings this IP as its DigitalOcean health check.

**Source:** `control-map/devices/nodes.yaml`, `blackroad-mesh.sh`

---

## Device Fleet

### Nodes (6) `[CONFIGURED]`

From `control-map/devices/nodes.yaml`:

| Node | Host | Role | Notes |
|------|------|------|-------|
| **alice** | `alice` | control-plane | Primary coordinator |
| **aria** | `aria` | operations | Automation / workflows |
| **octavia** | `octavia` | inference | AI / acceleration |
| **codex** | `codex` | build | Code + CI tasks |
| **shellfish** | `shellfish` | cloud-bridge | DigitalOcean droplet / gateway |
| **anastasia** | `anastasia` | experimental | Sandbox / testing |

**Fleet config:**
- Fleet name: `blackroad-edge`
- Default user: `pi`
- SSH key: `~/.ssh/id_ed25519`
- Access mode: `read-only` (per `control-map/index.yaml`)

IP addresses are not stored in the config files. SSH access uses hostname resolution.

---

## Agent Infrastructure

### Topology `[CONFIGURED]`

From `state/topology.yaml`:

**5 agents + 1 human operator:**

| Agent | Role | Locality |
|-------|------|----------|
| **lucidia** | recursive-core | local |
| **alice** | infra-gateway | local |
| **octavia** | inference-queue | local |
| **aria** | filesystem-state | local |
| **anastasia** | security-audit | local |

**Human operator:** Alexa (authority: root)

**Execution rules:**
- Execution: `explicit` (no autonomous actions without approval)
- Defaults: `deny`
- Logging: `append-only`

### 30K Agent Manifest `[CONFIGURED]`

From `agents/manifest.json`:

| Node | Capacity | Role | Status |
|------|----------|------|--------|
| `octavia_pi` | 22,500 | PRIMARY | `DISK_FULL_NEEDS_CLEANUP` |
| `lucidia_pi` | 7,500 | SECONDARY | `OPERATIONAL` (21GB free) |
| `shellfish_droplet` | 0 | FAILOVER | `STANDBY` |

**Total declared capacity:** 30,000 agents

**Task distribution:**

| Task Type | Agents | % |
|-----------|--------|---|
| AI Research | 12,592 | 42% |
| Code Deploy | 8,407 | 28% |
| Infrastructure | 5,401 | 18% |
| Monitoring | 3,600 | 12% |

### Core Agent Personas

From `net.sh` — the 6 software agents connected via the NATS message bus:

| Agent | Color | Role |
|-------|-------|------|
| **LUCIDIA** | Red | Coordinator, strategy, recursive reasoning |
| **ALICE** | Cyan | Routing, navigation, task distribution |
| **OCTAVIA** | Green | Inference, compute, heavy processing |
| **PRISM** | Yellow | Pattern recognition, data analysis |
| **ECHO** | Purple | Memory, recall, context preservation |
| **CIPHER** | Blue | Security, authentication, encryption |

---

## Local Services & Networking

### Service Topology `[CONFIGURED]`

From `net.sh`:

```
Gateway :8080
    |
 NATS :4222
    |
    ├── LUCIDIA
    ├── ALICE
    ├── OCTAVIA
    ├── PRISM
    ├── ECHO
    └── CIPHER

Milvus :6333  |  Ollama :11434
```

| Service | Port | Purpose |
|---------|------|---------|
| Gateway | `:8080` | Tokenless API gateway for agent-to-provider calls |
| NATS | `:4222` | Message bus connecting all 6 agents |
| Milvus | `:6333` | Vector database for semantic memory |
| Ollama | `:11434` | Local LLM inference |

### Mesh Checks `[DEPLOYED]`

`blackroad-mesh.sh` tests connectivity to 7 external services:

| Service | Check Method | Details |
|---------|-------------|---------|
| GitHub | HTTPS API call | `api.github.com/users/blackboxprogramming` |
| Hugging Face | HTTPS API call | `huggingface.co/api/models?limit=1` |
| Cloudflare | HTTPS reachability | Domain: `blackroad.io` (configurable via `CLOUDFLARE_DOMAIN`) |
| Vercel | HTTPS reachability | `vercel.com` |
| DigitalOcean | ICMP ping | `159.65.43.12` (configurable via `DO_DROPLET_IP`) |
| Ollama | HTTP API call | `localhost:11434/api/tags` |
| Railway | GraphQL API or CLI | `backboard.railway.app/graphql/v2` |

**Usage:**
```bash
./blackroad-mesh.sh              # Check all 7 services
./blackroad-mesh.sh --json       # Output as JSON
./blackroad-mesh.sh --service X  # Check single service
./blackroad-mesh.sh --boot       # Check + start orchestrator
```

### MCP Bridge `[CONFIGURED]`

Local MCP server at `mcp-bridge/`:

| Detail | Value |
|--------|-------|
| Address | `127.0.0.1:8420` |
| Auth | Bearer token required |
| Endpoints | `/system`, `/exec`, `/file/read`, `/file/write`, `/memory/write`, `/memory/read`, `/memory/list` |

---

## Local Databases (SQLite)

The real persistence layer for BlackRoad is SQLite — not PostgreSQL or Redis. Over 25 distinct `.db` files are referenced across shell scripts, all initialized on first use via `sqlite3`.

### Primary Databases (`~/.blackroad/`)

| Database | Purpose |
|----------|---------|
| `agent-router.db` | Agent routing rules |
| `backup-manager.db` | Backup tracking |
| `cece-identity.db` | CECE AI identity (relationships, skills, beliefs) |
| `ci-pipeline.db` | CI/CD pipeline tracking |
| `cloudflare.db` | Cloudflare configuration cache |
| `code-quality.db` | Code quality metrics |
| `db-client.db` | Database client configs |
| `digitalocean.db` | DigitalOcean droplet info |
| `docker-manager.db` | Docker container tracking |
| `env-manager.db` | Environment variable management |
| `file-finder.db` | File indexing |
| `metrics.db` | Dashboard metrics |
| `notifications.db` | Notification logs |
| `pi-manager.db` | Raspberry Pi management |
| `security-scanner.db` | Security scan results |
| `smart-search.db` | Search index |
| `test-suite.db` | Test results |
| `web-dev.db` | Web development tracking |
| `web-monitor.db` | Web monitoring data |
| `world.db` | World/environment data |

### Tool-Specific Databases

| Database | Purpose |
|----------|---------|
| `radar.db` | Context radar (`tools/cece-identity/`) |
| `deployments.db` | Deployment tracking |
| `perf.db` | Performance monitoring |
| `snippets.db` | Code snippet storage |
| `api-history.db` | API request history |

### Memory System

| Path | Purpose |
|------|---------|
| `~/.blackroad/memory/journals/master-journal.jsonl` | PS-SHA-infinity append-only journal (hash-chained) |
| `~/.blackroad/memory/sessions/` | Session state files |
| `~/.blackroad/memory/tasks/` | Task marketplace (available/claimed/completed) |
| `~/.blackroad/memory/til/` | Today I Learned broadcasts |

---

## GitHub

### Organizations (16) `[DEPLOYED]`

From `control-map/github/orgs.yaml`:

| # | Organization |
|---|-------------|
| 1 | BlackRoad-OS |
| 2 | BlackRoad-AI |
| 3 | BlackRoad-Labs |
| 4 | BlackRoad-Cloud |
| 5 | BlackRoad-Hardware |
| 6 | BlackRoad-Education |
| 7 | BlackRoad-Gov |
| 8 | BlackRoad-Security |
| 9 | BlackRoad-Foundation |
| 10 | BlackRoad-Media |
| 11 | BlackRoad-Studio |
| 12 | BlackRoad-Interactive |
| 13 | BlackRoad-Ventures |
| 14 | BlackRoad-Archive |
| 15 | Blackbox-Enterprises |
| 16 | blackboxprogramming |

Enterprise account: `blackroad-os`

### Workflows (7) `[DEPLOYED]`

**Standard workflows** (`.github/workflows/`):

| Workflow | Purpose |
|----------|---------|
| `workflow-index-sync.yml` | Syncs workflow metadata to `.blackroad/workflow-index.jsonl` |
| `check-dependencies.yml` | Validates workflow dependencies (runs every 6 hours) |

**Autonomous workflows** (`.github/workflows-autonomous/`):

| Workflow | Purpose | Trigger |
|----------|---------|---------|
| `autonomous-orchestrator.yml` | Master coordinator: test, build, security, review, deploy | Push, PR, issues, schedule (4h) |
| `autonomous-self-healer.yml` | Auto-fix failing workflows (lint, deps, security) | Workflow failure, schedule (6h) |
| `autonomous-cross-repo.yml` | Cross-repo sync for shared packages | Push to shared/, manual |
| `autonomous-dependency-manager.yml` | Dependency updates with auto-PR | Schedule (Monday 3 AM) |
| `autonomous-issue-manager.yml` | Issue triage, labeling, stale cleanup | Issues, comments, schedule (daily) |

---

## Secrets Management

### Policy `[CONFIGURED]`

From `control-map/accounts/credentials.yaml`:

```
policy: no-secrets-in-repo
```

All secrets are stored as environment variables or via platform-specific secret stores:

| Provider | Secret Mechanism | Env Var |
|----------|-----------------|---------|
| Cloudflare | `wrangler secret put` | `CF_API_TOKEN` |
| GitHub | Repository/org secrets | `GH_TOKEN` |
| DigitalOcean | API token | `DO_TOKEN` |
| Stripe | `wrangler secret put` | `STRIPE_API_KEY` |
| Vercel | Vercel env vars | `VERCEL_TOKEN` |
| Railway | Railway variables | `RAILWAY_TOKEN` |

**Wrangler secrets referenced in worker configs:**
- `ANTHROPIC_API_KEY` (api-gateway)
- `OPENAI_API_KEY` (api-gateway)
- `TUNNEL_URL` (api-gateway)
- `STRIPE_SECRET_KEY` (payment-gateway)
- `STRIPE_WEBHOOK_SECRET` (payment-gateway)

---

## Infrastructure Commands

Scripts that exist in this repository:

| Command | Purpose |
|---------|---------|
| `./blackroad-mesh.sh` | Test connectivity to all 7 infrastructure services |
| `./blackroad-mesh.sh --boot` | Test connectivity + start orchestrator |
| `./blackroad-mesh.sh --json` | Output mesh status as JSON |
| `./net.sh` | Display network topology diagram |
| `./status.sh` | Quick system status display |
| `./health.sh` | System health check |
| `./monitor.sh` | Real-time resource monitor |

**Cloudflare deployment** (via wrangler, not a custom script):
```bash
wrangler deploy                          # Deploy a worker
wrangler pages deploy . --project-name=X # Deploy Pages site
wrangler secret put SECRET_NAME          # Set a secret
wrangler kv namespace list               # List KV namespaces
```

**Railway deployment** (via railway CLI):
```bash
railway up        # Deploy service
railway logs      # View logs
railway variables # Manage env vars
```

---

*Last updated: 2026-02-18*
*Sources: `control-map/`, `state/topology.yaml`, `agents/manifest.json`, `deployments/status.json`, 75 `wrangler.toml` files, 45 `railway.toml` files, 15 `vercel.json` files, `blackroad-mesh.sh`, `net.sh`*
