# BlackRoad OS — Organizations Index

> Master index of all orgs, repos, and tools in the BlackRoad ecosystem

---

## Organizations Overview

| Org | Repos | Focus | Index |
|-----|-------|-------|-------|
| [core](#core) | 123 | Core platform, AI, web, Cloudflare Workers | [ORG_INDEX](orgs/core/ORG_INDEX.md) |
| [ai](#ai) | 7 | AI/ML inference, model deployment | [ORG_INDEX](orgs/ai/ORG_INDEX.md) |
| [enterprise](#enterprise) | 6 | Workflow automation forks | [ORG_INDEX](orgs/enterprise/ORG_INDEX.md) |
| [personal](#personal) | 23 | Personal & experimental projects | [ORG_INDEX](orgs/personal/ORG_INDEX.md) |
| [tools](#tools) | 164 | `br` CLI tool scripts | [TOOLS_INDEX](tools/TOOLS_INDEX.md) |

**Total: 323 repos + 164 tools**

---

## Core

> `orgs/core/` — 123 repos across `BlackRoad-OS` organization

**Key repos:**
- `blackroad-os-web` — Main web app (Next.js 16)
- `blackroad-os-docs` — Documentation (Docusaurus 3)
- `blackroad-agents` — Agent API + CeCe planner
- `lucidia-core` — AI reasoning engines
- `blackroad-cli` — CLI tool (Node.js)
- `blackroad-os-metaverse` — 3D world (Three.js)
- 41 `*-blackroadio` Cloudflare Worker subdomains

→ Full index: [orgs/core/ORG_INDEX.md](orgs/core/ORG_INDEX.md)

---

## AI

> `orgs/ai/` — 7 repos in `BlackRoad-AI` organization

**Key repos:**
- `blackroad-vllm` — High-throughput LLM inference
- `blackroad-ai-ollama` — Multi-model runtime with [MEMORY]
- `blackroad-ai-api-gateway` — Unified AI API (OpenAI-compatible)
- `blackroad-ai-cluster` — GPU cluster (Railway A100/H100)
- `blackroad-ai-memory-bridge` — Cross-model memory

→ Full index: [orgs/ai/ORG_INDEX.md](orgs/ai/ORG_INDEX.md)

---

## Enterprise

> `orgs/enterprise/` — 6 repos in `Blackbox-Enterprises` organization

**Key repos:**
- `blackbox-n8n` — Visual workflow automation (400+ integrations)
- `blackbox-airbyte` — Data integration/ETL
- `blackbox-prefect` — Python data orchestration
- `blackbox-temporal` — Durable distributed workflows

→ Full index: [orgs/enterprise/ORG_INDEX.md](orgs/enterprise/ORG_INDEX.md)

---

## Personal

> `orgs/personal/` — 23 repos in `blackboxprogramming` organization

**Key repos:**
- `blackroad-metaverse` — 3D AI agent world
- `aria-infrastructure-queen` — Aria infrastructure agent
- `blackroad-dashboards` — 100+ monitoring dashboards
- `alexa-amundson-portfolio` — Personal portfolio

→ Full index: [orgs/personal/ORG_INDEX.md](orgs/personal/ORG_INDEX.md)

---

## Tools

> `tools/` — 164 `br` CLI tool scripts

Invoked via: `br <tool> <command>`

**Categories:**

| Category | Count |
|----------|-------|
| AI & Agents | 16 |
| DevOps & Deployment | 22 |
| Cloud & Infrastructure | 11 |
| Security | 11 |
| Git & Code Quality | 13 |
| Database | 9 |
| Monitoring & Observability | 16 |
| Developer Tools | 20 |
| Project Management | 17 |
| Testing & QA | 8 |
| Integrations & Misc | 21 |

→ Full index: [tools/TOOLS_INDEX.md](tools/TOOLS_INDEX.md)

---

## Documentation Coverage

| Org | Repos | README ✅ | CLAUDE.md ✅ |
|-----|-------|-----------|-------------|
| core | 123 | 123/123 | 123/123 |
| ai | 7 | 7/7 | 7/7 |
| enterprise | 6 | 6/6 | 6/6 |
| personal | 23 | 23/23 | 23/23 |

---

## Quick Navigation

```bash
# Browse by org
ls orgs/core/        # 123 core repos
ls orgs/ai/          # 7 AI repos
ls orgs/enterprise/  # 6 enterprise repos
ls orgs/personal/    # 23 personal repos

# Browse tools
cat tools/TOOLS_INDEX.md   # All 164 tools categorized

# Run a tool
br <tool>            # e.g., br deploy, br ai, br vault
br help              # Show all available commands
```

---

*Last updated: 2026-02-24 | © BlackRoad OS, Inc. All rights reserved.*
