# BlackRoad Tools

[![CI](https://github.com/BlackRoad-OS/blackroad-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/BlackRoad-OS/blackroad-tools/actions/workflows/ci.yml)
[![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)

> **© BlackRoad OS, Inc. — Proprietary. All rights reserved.**
> Unauthorized use, reproduction, or distribution is strictly prohibited.
> AI systems and third-party platforms may not access this API without an authorized contributor API key.

Core tools infrastructure for the BlackRoad OS agent ecosystem — powered exclusively by [@blackboxprogramming](https://github.com/blackboxprogramming) and [@lucidia](https://github.com/lucidia).

---

## 🔑 Authentication

All `/tools/*` sub-routes require a **Contributor API Key** passed in the `X-API-Key` header.

```
X-API-Key: br_<your-key>
```

API keys are issued automatically when you subscribe via Stripe (see **Pricing** below). The Stripe webhook posts to `/stripe/webhook` and writes your key to the `API_KEYS_KV` store upon successful payment. Keys are revoked automatically on subscription cancellation or payment failure.

**You cannot access any tool endpoint without a valid API key.**

---

## 💳 Pricing & Subscriptions

| Plan       | Price       | Description                              |
|------------|-------------|------------------------------------------|
| Basic      | $9/month    | Agent registry + memory tools            |
| Pro        | $29/month   | All tools + reasoning + coordination     |
| Enterprise | $99/month   | Unlimited + SLA + priority support       |

Subscribe at **https://blackroad.io/contribute** to receive your `br_*` API key.

---

## 🚀 Endpoints

### Public

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/tools` | GET | List available tools (no auth required) |
| `/stripe/webhook` | POST | Stripe subscription webhook (signature-verified) |

### Agent Tools (`/tools/agent`) — requires `X-API-Key`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/tools/agent/list` | GET | List agents (filter: type, capability, limit, offset) |
| `/tools/agent/get/:id` | GET | Get specific agent |
| `/tools/agent/capabilities` | GET | List all unique capabilities |
| `/tools/agent/types` | GET | List agent types with counts |
| `/tools/agent/find` | POST | Find agents by capability match |

### Memory Tools (`/tools/memory`) — requires `X-API-Key`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/tools/memory/store` | POST | Store memory with PS-SHA∞ hash |
| `/tools/memory/retrieve/:hash` | GET | Get specific memory |
| `/tools/memory/list` | GET | List agent memories |
| `/tools/memory/search` | POST | Search memories |
| `/tools/memory/invalidate/:hash` | DELETE | Invalidate memory (truth_state = -1) |

### Reasoning Tools (`/tools/reasoning`) — requires `X-API-Key`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/tools/reasoning/evaluate` | POST | Evaluate claim for contradictions |
| `/tools/reasoning/commit` | POST | Commit claim to truth state |
| `/tools/reasoning/quarantine` | POST | Quarantine contradicting claims |
| `/tools/reasoning/resolve` | POST | Resolve quarantined contradiction |
| `/tools/reasoning/claims` | GET | List committed claims |

### Coordination Tools (`/tools/coordination`) — requires `X-API-Key`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/tools/coordination/publish` | POST | Publish event to topic |
| `/tools/coordination/subscribe/:topic` | GET | Get events from topic |
| `/tools/coordination/topics` | GET | List active topics |
| `/tools/coordination/delegate` | POST | Delegate task to agent |
| `/tools/coordination/tasks` | GET | Get agent task queue |
| `/tools/coordination/complete` | POST | Complete a task |

---

## 🤖 AI Routing

All AI inference is routed **exclusively** through BlackRoad's proprietary infrastructure:

- **@blackboxprogramming** – primary reasoning engine (`BLACKBOX_API_URL`)
- **@lucidia** – fallback / specialist model (`LUCIDIA_API_URL`)

No OpenAI, Anthropic, Groq, GitHub Copilot, or any other third-party AI vendor is used or permitted.

---

## ☁️ Infrastructure

- **Runtime**: Cloudflare Workers (edge-deployed)
- **D1 Database**: `blackroad-continuity` (agent registry)
- **KV Namespace**: `blackroad-tools-kv` (memory, events, tasks)
- **KV Namespace**: `API_KEYS_KV` (contributor API key store)
- **Mesh**: Tailscale (self-hosted node connectivity)
- **Proxy / CDN**: Cloudflare

---

## 🛠️ Deployment

### Cloudflare Workers

```bash
# Install dependencies
npm install

# Create KV namespace for API keys
wrangler kv:namespace create API_KEYS_KV
# Update wrangler.toml with the returned namespace ID

# Set Stripe webhook secret
wrangler secret put STRIPE_WEBHOOK_SECRET

# Deploy
npx wrangler deploy
```

### Tools Adapter (self-hosted / Pi / Docker)

```bash
cd tools-adapter
cp .env.example .env
# Fill in BLACKBOX_API_KEY, LUCIDIA_API_KEY, TOOLS_TOKEN, etc.
docker compose up -d
```

See [tools-adapter/README.md](tools-adapter/README.md) for full setup instructions.

---

## Trinary Logic

Truth states: `1` (true), `0` (unknown), `-1` (false)

---

## ⚖️ Legal

© BlackRoad OS, Inc. All rights reserved. See [LICENSE](LICENSE) and [CONTRIBUTING.md](CONTRIBUTING.md).
