# BlackRoad OS — Workers

> Cloudflare Workers for all BlackRoad domains — real-time data, edge-deployed, tokenless

## Architecture

```
domains/
├── _shared/         Shared brand tokens, data fetchers, HTML utilities
├── root/            blackroad.io — OS landing page
├── agents/          agents.blackroad.io — 8-agent mesh
├── api/             api.blackroad.io — REST API gateway
├── dashboard/       dashboard.blackroad.io — CI/CD dashboard
├── docs/            docs.blackroad.io — Documentation hub
├── console/         console.blackroad.io — BR CLI reference
├── ai/              ai.blackroad.io — AI model registry
├── analytics/       analytics.blackroad.io — Platform metrics
├── dev/             dev.blackroad.io — Developer hub
├── cli/             cli.blackroad.io — CLI download + reference
├── cdn/             cdn.blackroad.io — R2 storage + CDN status
├── edge/            edge.blackroad.io — Edge region status
├── network/         network.blackroad.io — Network topology
├── security/        security.blackroad.io — Security controls
├── status/          status.blackroad.io — System status
├── help/            help.blackroad.io — FAQ + support
├── blog/            blog.blackroad.io — Engineering blog
└── about/           about.blackroad.io — Company info
```

## Deploy

```bash
# Deploy all workers
npx wrangler deploy --config domains/<name>/wrangler.toml

# Or use BR CLI
br cloudflare deploy

# GitHub Actions deploys automatically on push to main
```

## Required Secrets (set via wrangler secret put or GitHub secrets)

| Secret | Used By | Purpose |
|--------|---------|---------|
| `GITHUB_TOKEN` | all | GitHub API — repos, CI runs, commits |
| `RAILWAY_TOKEN` | root, dashboard, api | Railway project status |
| `CF_API_TOKEN` | console, cdn, api, root | Cloudflare API — workers, R2, zones |
| `CLOUDFLARE_API_TOKEN` | GitHub Actions | Deploy workers |
| `CLOUDFLARE_ACCOUNT_ID` | GitHub Actions | Account: 848cf0b18d51e0170e0d1537aec3505a |

## Brand

All workers use consistent brand tokens from `_shared/index.js`:

```
Background: #000
Surface:    #0a0a0a
Border:     #1a1a1a
Gradient:   linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%)
```

## Adding a New Worker

1. `mkdir -p domains/<name>/src`
2. Copy any existing worker as template
3. Update `wrangler.toml` with new name + route
4. `git push` — GitHub Actions auto-deploys

---

© BlackRoad OS, Inc. All rights reserved. Proprietary — not licensed for external use.
