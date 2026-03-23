# blackroad

> BlackRoad OS monorepo — CLI, agents, CarPool coordination, tools, and core platform

Part of the [BlackRoad OS](https://blackroad.io) ecosystem — [BlackRoad-OS-Inc](https://github.com/BlackRoad-OS-Inc)

---

# BlackRoad OS

**The sovereign AI operating system.** Your hardware. Your data. Your agents.

Built on Raspberry Pi hardware with Hailo-8 AI accelerators. Zero cloud dependency. 35 autonomous agents running on 5 edge nodes.

## What is BlackRoad OS?

BlackRoad OS is a multi-agent operating system that runs entirely on hardware you own. No AWS. No Azure. No API keys to expire. Five Raspberry Pi nodes, two cloud droplets, and 52 TOPS of AI compute — all connected via WireGuard mesh.

**Live at [blackroad.io](https://blackroad.io)**

## Quick Start

```bash
# Chat with an agent
curl -X POST https://roundtrip.blackroad.io/api/chat \
  -H "Content-Type: application/json" \
  -d '{"agent":"alice","message":"hello","channel":"general"}'

# Search the ecosystem
curl https://search.blackroad.io/api/search?q=agent

# Check fleet status
curl https://blackroad-live-stats.amundsonalexa.workers.dev/api/stats
```

## Infrastructure

| Node | Role | Services |
|------|------|----------|
| **Alice** (.49) | Gateway | Pi-hole, PostgreSQL, Qdrant, Redis, nginx |
| **Cecilia** (.96) | AI Engine | Ollama (4 models), MinIO, nomic-embed-text |
| **Octavia** (.101) | Architect | Gitea (238 repos), 15 Workers, NATS, Docker |
| **Aria** (.98) | Interface | Backup services |
| **Lucidia** (.38) | Dreamer | 334 web apps, nginx, PowerDNS, Ollama |
| **Gematria** (DO) | Edge | Caddy TLS (151 domains), PowerDNS ns1 |
| **Anastasia** (DO) | Backup | PowerDNS ns2 |

## Products

| Product | What it does | URL |
|---------|-------------|-----|
| **Lucidia** | Personal AI assistant | [lucidia.earth](https://lucidia.earth) |
| **RoadPay** | Billing system (4 plans) | [roadpay](https://roadpay.amundsonalexa.workers.dev) |
| **RoadSearch** | AI-powered search | [search.blackroad.io](https://search.blackroad.io) |
| **RoundTrip** | Agent chat hub | [roundtrip.blackroad.io](https://roundtrip.blackroad.io) |
| **RoadChain** | Python blockchain | [roadchain.io](https://roadchain.io) |
| **BlackRoad Code** | AI coding assistant | Coming soon |

## The Stack

All self-hosted. All sovereign.

- **Git**: Gitea (RoadCode) — 238 repos, 8 orgs
- **AI**: Ollama (Passenger) — local inference, 52 TOPS via Hailo-8
- **DNS**: PowerDNS (RoadDNS) — 151 records
- **TLS**: Caddy (OneWay) — auto-HTTPS for all domains
- **Storage**: MinIO (Curb) — S3-compatible object storage
- **VPN**: WireGuard (TollBooth) — encrypted mesh
- **Cache**: Redis (RoadCache) — session store
- **Vectors**: Qdrant (RearView) — 32K+ code chunks indexed
- **Messages**: NATS (CarPool) — pub/sub agent communication

## Company

**BlackRoad OS, Inc.** — Delaware C-Corp, est. November 2025.

Founded by [Alexa Louise Amundson](mailto:alexa@blackroad.io).

Monthly infrastructure cost: **$19**.

---

© 2026 BlackRoad OS, Inc. All rights reserved. Proprietary.

**Pave Tomorrow.**
