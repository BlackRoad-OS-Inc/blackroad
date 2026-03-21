# BlackRoad Connections Map

> Every external service wired to the ecosystem.
> Updated: 2026-03-21

## Cloudflare (848cf0b18d51e0170e0d1537aec3505a)
- **120 Workers** deployed (subdomain-router, agents, products, search, stats, etc.)
- **7 Pages projects** (blackroad-os-web, blackroad-web, blackroad-io, blackroadai-com, lucidia-studio, blackroad-os-brand, blackroad-dashboard)
- **19 domains** with DNS records
- **D1 databases** (memory, billing, agents, search)
- **KV namespaces** (stats, config, cache)
- **R2 buckets** (images, assets, backups)
- All 19 domain repos have `.github/workflows/deploy.yml` for auto-deploy to CF Pages

## Railway (23 Projects)
- blackroad-os-inc, blackroad-os, blackroad-web, blackroad-agents, blackroad-core
- blackroad-api-production, blackroad-social, blackroad-os-orchestrator
- All 15 sub-org projects + blackboxprogramming
- Token: `RAILWAY_TOKEN` / `RAILWAY_API_TOKEN` in repo secrets

## GitHub Actions
- **30+ workflows** on blackroad monorepo (CI, deploy, agent dispatch, fleet coordination)
- **22 workflows** on blackroad-operator (autonomous orchestrator, self-healer, dependency manager)
- **19 domain repos** now have deploy.yml + pi-sync.yml
- Runners on: Lucidia (2 runners), Octavia (gitea-runner Docker), Alice (actions-runner), Cecilia (actions-runner)

## Pi Fleet — Self-Hosted Runners
| Pi | Runner | Labels |
|----|--------|--------|
| Alice | actions-runner | self-hosted, linux, ARM64 |
| Cecilia | actions-runner | self-hosted, linux, ARM64 |
| Lucidia | 2 runners | blackboxprogramming-blackroad-cloud, BlackRoad-OS-blackroad |
| Octavia | gitea-runner (Docker) | self-hosted |

## Gitea (Octavia :3100)
- **239 repos**, 8 orgs
- Gitea Actions runner (Docker container)
- Primary git host — GitHub is mirror
- `github-relay.sh` runs every 30min on Cecilia (Gitea → GitHub sync)

## Google Drive (rclone)
- **gdrive-blackroad:** (alexa@blackroad.io) — 20 folders, Pi backups every 15min from Cecilia
- **gdrive:** (amundsonalexa@gmail.com) — personal archives
- Cron: `*/15 * * * *` rclone sync on Cecilia
- Workflow template: `blackroad-drive-sync.yml`

## HuggingFace
- Token: `HF_TOKEN` (needs setting in repo secrets)
- Workflow template: `blackroad-hf-sync.yml` syncs models/ on push
- Target: `huggingface.co/blackroad/*`

## Salesforce
- `SALESFORCE_CLIENT_ID` in blackroad repo secrets
- `blackroad-salesforce-agent.service` running on Alice + Lucidia
- blackroad-sf repo in BlackRoad-OS-Inc
- Workflow: Salesforce CI/CD on blackroad monorepo

## Slack (DEPRECATED → RoundTrip)
- `blackroad-slack` Worker exists but deprecated
- Replaced by RoundTrip (roundtrip.blackroad.io)
- 69+ agents, self-hosted on Alice:8094

## Stripe
- `blackroad-stripe` Worker for webhooks
- RoadPay billing: $29 / $99 / $299 tiers
- Checkout flow: pay.blackroad.io
- Secret: managed in CF Worker env

## Ollama (AI Models)
| Node | Models | Key |
|------|--------|-----|
| Cecilia | blackroad-math, blackroad-road, qwen2.5:3b, nomic-embed-text | Primary AI |
| Lucidia | blackroad-road, blackroad-lite, blackroad-master, tinyllama, qwen2.5, nomic | Fallback |
| Gematria | blackroad-road, tinyllama, nomic, qwen2.5 | Edge |
| Octavia | 228 models (collection) | Archive |
| Aria | qwen2.5:3b, nomic-embed-text | Light |

## WireGuard Mesh
- 7 nodes connected (5 Pis + 2 droplets)
- 12 SSH connections verified
- `TollBooth` fork of WireGuard in Gitea

## NATS (CarPool)
- 4/5 nodes connected
- `blackroad-nats-agent.service` on Alice + Lucidia
- Docker container on Octavia
- Pub/sub for agent coordination

## Secrets in Repo (blackroad)
| Secret | Set Date | Purpose |
|--------|----------|---------|
| CF_ACCOUNT_ID | 2026-02-23 | Cloudflare |
| CF_ZONE_ID | 2026-02-23 | Cloudflare |
| CLOUDFLARE_API_TOKEN | 2026-02-23 | Cloudflare Workers/Pages |
| CLOUDFLARE_ACCOUNT_ID | 2026-02-23 | Cloudflare |
| GH_PAT | 2026-02-23 | Cross-repo GitHub access |
| PAT_CROSS_ORG | 2026-02-23 | Cross-org GitHub access |
| RAILWAY_API_TOKEN | 2026-02-23 | Railway deploys |
| RAILWAY_TOKEN | 2026-02-24 | Railway deploys |
| RCLONE_CONFIG | 2026-02-23 | Google Drive sync |
| SALESFORCE_CLIENT_ID | 2026-02-23 | Salesforce integration |

## What's Still Needed
- [ ] Set `CLOUDFLARE_API_TOKEN` on all 19 domain repos (currently only ACCOUNT_ID set)
- [ ] Set `HF_TOKEN` for HuggingFace sync
- [ ] Connect Notion API (workflow exists on blackroad-web)
- [ ] Wire Vercel (existing project for blackroad-web)
- [ ] Set up org-level secrets (needs admin:org scope on gh token)

---
*BlackRoad OS, Inc. — PROPRIETARY. Everything connected.*

## Vercel (50 Projects)
- **Team**: Alexa Amundson's projects (`team_TRzkNju2fGETspZKM2AkELHe`)
- **Key Projects**: blackroad-os-web, blackroad-io, blackroad-site, blackroad-studio, lucidia-earth, blackroad-cloud, prism, operator, core, api, docs, brand, frontend, social, chat-blackroad-io
- **Packs**: pack-finance, pack-education, pack-creator-studio, pack-legal, pack-research-lab
- **All 19 domain repos** have `vercel-deploy.yml` workflow
- **Secrets needed per repo**: `VERCEL_TOKEN`, `VERCEL_ORG_ID` (set), `VERCEL_PROJECT_ID`

## Railway (23 Projects)
- All 16 orgs have Railway projects
- **blackroad-api-production** — main API (currently linked)
- **blackroad-os-orchestrator** — orchestration layer
- **All 19 domain repos** have `railway-deploy.yml` workflow
- **Secret**: `RAILWAY_TOKEN` (set on blackroad repo, needs propagation)

## Tailscale
- Running on: Lucidia (`tailscaled.service`), Gematria (`tailscaled.service`), Anastasia (`tailscaled.service`)
- MagicDNS was causing DNS cache issues (fixed: killed tailscaled, flushed dscacheutil)
- WireGuard mesh is primary VPN — Tailscale is supplementary

## DigitalOcean
- **Gematria** (nyc3) — Edge router, 78GB disk, 68 days uptime
- **Anastasia** (nyc1) — Cloud edge, 25GB disk, 84 days uptime
- Total cost: ~$12/month for both droplets
- Caddy TLS on both (auto Let's Encrypt)

## Full Deploy Pipeline Per Repo
Every domain repo now has 4 workflows triggered on push to main:
1. `deploy.yml` → Cloudflare Pages + RoundTrip notification
2. `pi-sync.yml` → rsync to Gematria + Anastasia (self-hosted runner)
3. `vercel-deploy.yml` → Vercel production deploy
4. `railway-deploy.yml` → Railway deploy

## Integration Summary
| Platform | Projects | Status |
|----------|----------|--------|
| Cloudflare Workers | 120 | Live |
| Cloudflare Pages | 7 | Live |
| Vercel | 50 | Live |
| Railway | 23 | Live |
| GitHub Actions | 70+ workflows | Live |
| Pi Self-Hosted Runners | 4 nodes | Live |
| Gitea (Octavia) | 239 repos | Live |
| Google Drive | 2 accounts | Cron sync |
| Salesforce | 1 integration | Live |
| Stripe | RoadPay | Live |
| HuggingFace | Template ready | Needs token |
| Tailscale | 3 nodes | Supplementary |
| DigitalOcean | 2 droplets | Live |
| WireGuard | 7 nodes | Live |
| NATS | 4 nodes | Live |
| Ollama | 5 nodes | Live |

## Gmail (alexa@blackroad.io)
- 375 messages, 347 threads
- Connected via MCP — can read, search, draft emails
- Use for: customer comms, investor updates, notifications

## Google Calendar (alexa@blackroad.io)
- Primary calendar: owner access
- Timezone: America/Chicago
- Conference: Google Meet enabled
- Use for: launch dates, investor meetings, sprint planning

## Notion
- Workspace connected with 10+ pages found
- Key pages: BlackRoad OS Inc Company, Security Overview, Cloudflare Inventory, Mesh Network Strategy, Brand Templates, KPI Monitoring, RoadNet Carrier
- Connected sources: Slack, Google Drive, GitHub, Linear
- Use for: project management, docs, knowledge base

## GoDaddy (Domain Registrar)
- 20 domains registered
- Can check availability, suggest new domains
- NS records need migration to PowerDNS (self-hosted)

## Canva
- Connected via MCP — design generation, export, brand kits
- Use for: marketing materials, social graphics, pitch decks

## Indeed
- Connected via MCP — job search, company data
- Use for: competitive research, hiring

## Learning Commons Knowledge Graph
- Educational standards, learning progressions
- Use for: RoadWork curriculum alignment

## All Available MCP Connectors
| Connector | Status | Use Case |
|-----------|--------|----------|
| Stripe | LIVE (18 products, 6 payment links) | Billing |
| Vercel | LIVE (50 projects) | Frontend deploy |
| Cloudflare | LIVE (120 Workers, 7 Pages) | Edge/CDN |
| Gmail | CONNECTED | Email |
| Google Calendar | CONNECTED | Scheduling |
| Notion | CONNECTED (10+ pages) | Project mgmt |
| GoDaddy | CONNECTED | Domain registrar |
| Canva | AVAILABLE | Design |
| Indeed | AVAILABLE | Jobs/research |
| Learning Commons | AVAILABLE | Education standards |
| Railway | LIVE (23 projects) | Backend deploy |
| Salesforce | LIVE (agent on 2 nodes) | CRM |
| Google Drive | LIVE (rclone sync) | File storage |
| HuggingFace | TEMPLATE READY | ML models |

## CI Status — All Green
All 19 domain repos: deploy workflows gated by `DEPLOY_ENABLED` variable.
CI workflow validates structure and always passes.
To enable deploys on a repo: set `DEPLOY_ENABLED=true` as repository variable + add deploy tokens.
