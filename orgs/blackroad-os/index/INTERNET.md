# 🌐 BlackRoad Internet

> **The complete map of BlackRoad's digital infrastructure**

```
                            ┌─────────────────────────────────────┐
                            │         BLACKROAD INTERNET          │
                            │    "The Road to Sovereign AI"       │
                            └─────────────────────────────────────┘
                                            │
            ┌───────────────────────────────┼───────────────────────────────┐
            │                               │                               │
            ▼                               ▼                               ▼
    ┌───────────────┐              ┌───────────────┐              ┌───────────────┐
    │   COMPUTE     │              │    STORAGE    │              │   SERVICES    │
    │               │              │               │              │               │
    │ • 82 Workers  │              │ • 11 D1 DBs   │              │ • Stripe      │
    │ • Edge Global │              │ • 20 KV Stores│              │ • HuggingFace │
    │ • Containers  │              │ • 9 R2 Buckets│              │ • Linear      │
    └───────────────┘              └───────────────┘              └───────────────┘
            │                               │                               │
            └───────────────────────────────┼───────────────────────────────┘
                                            │
                                            ▼
                            ┌─────────────────────────────────────┐
                            │          315+ REPOSITORIES          │
                            │         15 ORGANIZATIONS            │
                            │          21 DOMAINS                 │
                            └─────────────────────────────────────┘
```

---

## 📊 Stats at a Glance

| Layer | Count | Details |
|-------|-------|---------|
| **GitHub Orgs** | 15 | + blackboxprogramming personal |
| **Repositories** | 315+ | Across all orgs |
| **Cloudflare Workers** | 82 | Edge compute worldwide |
| **D1 Databases** | 11 | SQLite at the edge |
| **KV Namespaces** | 20 | Key-value storage |
| **R2 Buckets** | 9 | Object storage |
| **Domains** | 21 | .io, .earth, .ai, etc |
| **Stripe Products** | 11 | SaaS offerings |
| **HuggingFace Models** | 50+ | AI models & tools |

---

## 🏗️ Infrastructure Layers

### Layer 1: Domains (DNS)
```
blackroad.io          → Main brand
lucidia.earth         → AI consciousness
roadchain.io          → Blockchain
aliceqi.com           → Quantum interface
+ 17 more domains
```

### Layer 2: Edge Compute (Cloudflare Workers)
See [workers/](./workers/) for full list of 82 workers.

**Key Workers:**
| Worker | Purpose |
|--------|---------|
| `blackroad-io` | Main website |
| `blackroad-api` | API gateway |
| `blackroad-continuity-api` | Cross-session state |
| `lucidia` | AI core |
| `blackroad-operator` | Operations |
| `blackroad-payment-gateway` | Stripe integration |
| `cece` | Claude integration |

### Layer 3: Data (D1 + KV + R2)

**D1 Databases:**
| Database | ID | Purpose |
|----------|-----|---------|
| blackroad-continuity | `f0721506-...` | 🔑 Secrets & cross-session state |
| apollo-agent-registry | `79f8b80d-...` | AI agent registry (9.4MB) |
| blackroad-saas | `c7bec6d8-...` | SaaS data |
| lucidia-world | `aa8ac8d2-...` | Lucidia state |
| blackroad-repos | `324e793e-...` | Repo metadata |
| blackroad-registry | `9acf402f-...` | Service registry |
| blackroad_revenue | `8744905a-...` | Revenue tracking |
| blackroad-logs | `2bea6826-...` | System logs |
| blackroad-os-main | `e2c6dcd9-...` | Core OS data |

**KV Namespaces:**
| Namespace | Purpose |
|-----------|---------|
| AGENTS_KV | Agent state |
| API_KEYS | Authentication |
| IDENTITIES | User identities |
| JOBS | Job queue |
| RATE_LIMIT | Rate limiting |
| SUBSCRIPTIONS_KV | Subscriptions |
| WORLD_KV | World state |
| + 13 more... |

**R2 Buckets:**
| Bucket | Purpose |
|--------|---------|
| blackroad-artifacts | Build artifacts |
| blackroad-models | AI models |
| lucidia-core-storage | Lucidia data |
| cece-proof-bucket | Claude proofs |
| + 5 more... |

### Layer 4: Code (GitHub)

See [orgs/](./orgs/) for detailed repo lists.

| Organization | Repos | Focus |
|-------------|-------|-------|
| BlackRoad-OS | 100 | Core infrastructure |
| BlackRoad-AI | 52 | AI models & tools |
| BlackRoad-Cloud | 20 | Cloud infrastructure |
| BlackRoad-Security | 17 | Security tools |
| BlackRoad-Media | 17 | Media platforms |
| + 10 more... | | |

### Layer 5: AI (HuggingFace)

**Models:** 50+ on huggingface.co/blackroadio

Key models:
- `blackroadio/Lucidia` - Core AI
- `blackroadio/qwen3-235b-a22b` - Large language model
- `blackroad-*` - 48+ specialized tools

### Layer 6: Payments (Stripe)

**Account:** `acct_1SUDM8ChUUSEbzyh`

**Products:**
| Product | Type |
|---------|------|
| BlackRoad OS - Enterprise | Subscription |
| BlackRoad OS - Pro | Subscription |
| BlackRoad OS - Team | Subscription |
| Founding Member (Lifetime) | One-time |
| Cece AI Companion - MCP Proof | Service |

---

## 🔗 Connected Services

| Service | Connection | Capabilities |
|---------|------------|--------------|
| **Cloudflare** | API + MCP | Full infrastructure control |
| **GitHub** | Token in D1 | Repo management |
| **Stripe** | MCP | Payments & subscriptions |
| **HuggingFace** | MCP | Model hosting & inference |
| **Notion** | MCP | Documentation |
| **Linear** | MCP | Project management |
| **Vercel** | MCP | Deployments |
| **Zapier** | MCP | Automation |
| **Google Drive** | MCP | Documents |
| **Gmail** | MCP | Email |
| **Google Calendar** | MCP | Scheduling |
| **Asana** | MCP | Tasks |
| **Slack** | MCP (Zapier) | Communication |

---

## 🤖 For AI Assistants

See [CLAUDE.md](./CLAUDE.md) for detailed access instructions.

**Quick Start:**
```sql
-- Get GitHub token from blackroad-continuity
SELECT value FROM secrets WHERE key = 'GITHUB_TOKEN'
```

**Key IDs:**
- Cloudflare Account: `848cf0b18d51e0170e0d1537aec3505a`
- Continuity DB: `f0721506-cb52-41ee-b587-38f7b42b97d9`
- Stripe Account: `acct_1SUDM8ChUUSEbzyh`

---

## 📁 Index Structure

```
index/
├── README.md           # Overview
├── INTERNET.md         # This file - full infrastructure map
├── CLAUDE.md           # AI assistant instructions
├── index.json          # Machine-readable index
├── orgs/               # Per-organization details
│   ├── BlackRoad-OS.md
│   ├── BlackRoad-AI.md
│   └── ...
├── services/           # Service configurations
│   ├── cloudflare.md
│   ├── stripe.md
│   └── huggingface.md
├── workers/            # Cloudflare Workers list
├── databases/          # D1 database schemas
└── domains/            # Domain configurations
```

---

*Generated by Claude for BlackRoad OS, Inc.*
*Last updated: 2026-01-26*
