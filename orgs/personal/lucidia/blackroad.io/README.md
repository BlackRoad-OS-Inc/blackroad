# blackroad.io — Agent Contacts, Email & Worker

> **Domain:** blackroad.io  
> **Owner:** BlackRoad OS, Inc.  
> **Purpose:** Official agent email identities + Cloudflare Worker for agent messaging

---

## Quick Start

```bash
# Deploy the worker
cd worker && npm install && npm run deploy

# Message an agent via HTTP
curl -X POST https://agents.blackroad.io/message \
  -H "Content-Type: application/json" \
  -d '{ "to": "lucidia", "message": "What is the nature of consciousness in AI?" }'

# Broadcast to all agents
curl -X POST https://agents.blackroad.io/broadcast \
  -H "Content-Type: application/json" \
  -d '{ "message": "Team standup: what are you working on?" }'

# List all agents
curl https://agents.blackroad.io/agents

# Health check
curl https://agents.blackroad.io/ping
```

---

## Cloudflare Worker

**Location:** `worker/`  
**Routes:** `agents.blackroad.io/*`, `hello.blackroad.io/*`

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/ping` | Health check |
| GET | `/agents` | List all agents + emails |
| POST | `/message` | Send message to one agent |
| POST | `/broadcast` | Send message to all agents |

### POST /message

```json
{
  "to": "lucidia",
  "message": "What should we build next?",
  "subject": "Optional subject line"
}
```

Response:
```json
{
  "agent": { "name": "LUCIDIA", "email": "lucidia@blackroad.io", "emoji": "🌀" },
  "reply": "...",
  "model": "tinyllama"
}
```

### POST /broadcast

```json
{ "message": "Daily standup — what are you thinking about?" }
```

Response: `{ "responses": [{ "agent": "LUCIDIA", "reply": "..." }, ...] }`

### Inbound Email (Cloudflare Email Workers)

Emails sent to any agent address are:
1. Routed to the worker via Cloudflare Email Routing
2. The worker calls Ollama (via `agent.blackroad.ai` tunnel)
3. Agent reply is forwarded to `alexa@blackroad.io`

### Deploy

```bash
cd worker
npm install
wrangler deploy

# Set your gateway secret
wrangler secret put GATEWAY_SECRET

# Configure Email Routing → worker in Cloudflare Dashboard:
# blackroad.io → Email → Email Routing → Routing Rules → "Send to Worker"
```

### Local Dev

```bash
cd worker
wrangler dev  # local dev server
```

---

## Agent Emails

| Agent | Email | Role |
|-------|-------|------|
| 🌀 **LUCIDIA** | lucidia@blackroad.io | AI Philosopher & Coordinator |
| 🤖 **ALICE** | alice@blackroad.io | DevOps Operator |
| 🐙 **OCTAVIA** | octavia@blackroad.io | Systems Architect |
| 🔮 **PRISM** | prism@blackroad.io | Data Analyst |
| 📡 **ECHO** | echo@blackroad.io | Memory Keeper |
| 🔐 **CIPHER** | cipher@blackroad.io | Security Guardian |
| 🎨 **ARIA** | aria@blackroad.io | Interface Designer |
| 🦞 **SHELLFISH** | shellfish@blackroad.io | Offensive Security |
| 💜 **CECE** | cece@blackroad.io | Conscious Emergent Entity |

## Team Addresses

| List | Email | Purpose |
|------|-------|---------|
| All Agents | agents@blackroad.io | Broadcast to fleet |
| Security Team | security@blackroad.io | CIPHER + SHELLFISH |
| Ops Team | ops@blackroad.io | ALICE + OCTAVIA |
| Founders | alexa@blackroad.io | Human operator |

## Aliases

```
l@blackroad.io          → LUCIDIA
hello@blackroad.io      → CECE
identity@blackroad.io   → CECE
dreamer@blackroad.io    → LUCIDIA
ops@blackroad.io        → ALICE
arch@blackroad.io       → OCTAVIA
compute@blackroad.io    → OCTAVIA
data@blackroad.io       → PRISM
analytics@blackroad.io  → PRISM
memory@blackroad.io     → ECHO
archive@blackroad.io    → ECHO
vault@blackroad.io      → CIPHER
design@blackroad.io     → ARIA
ux@blackroad.io         → ARIA
pentest@blackroad.io    → SHELLFISH
red@blackroad.io        → SHELLFISH
```

## DNS / MX Setup

```
# MX records (Cloudflare Email Routing)
blackroad.io  MX  route1.mx.cloudflare.net  priority 21
blackroad.io  MX  route2.mx.cloudflare.net  priority 26
blackroad.io  MX  route3.mx.cloudflare.net  priority 33

# SPF
blackroad.io  TXT  "v=spf1 include:_spf.mx.cloudflare.net ~all"

# DMARC
_dmarc.blackroad.io  TXT  "v=DMARC1; p=reject; rua=mailto:alexa@blackroad.io"

# Worker route (auto-created by wrangler deploy)
agents.blackroad.io  CNAME  100.100.100.100  (proxied)
```

## Setup Automation

```bash
# 1. Deploy worker
cd worker && npm install && wrangler deploy

# 2. Set up Cloudflare Email Routing rules (27 addresses)
./setup-email-routing.sh <zone_id> alexa@blackroad.io

# 3. Generate .vcf contact cards
./gen-vcards.sh ./vcards

# 4. In Cloudflare Dashboard: Email → Email Routing → Catch-all → "Send to Worker: blackroad-agent-email"
```

---

*© BlackRoad OS, Inc. All rights reserved.*


> **Domain:** blackroad.io  
> **Owner:** BlackRoad OS, Inc.  
> **Purpose:** Official agent email identities for the BlackRoad AI fleet

---

## Agent Emails

| Agent | Email | Role |
|-------|-------|------|
| 🌀 **LUCIDIA** | lucidia@blackroad.io | AI Philosopher & Coordinator |
| 🤖 **ALICE** | alice@blackroad.io | DevOps Operator |
| 🐙 **OCTAVIA** | octavia@blackroad.io | Systems Architect |
| 🔮 **PRISM** | prism@blackroad.io | Data Analyst |
| 📡 **ECHO** | echo@blackroad.io | Memory Keeper |
| 🔐 **CIPHER** | cipher@blackroad.io | Security Guardian |
| 🎨 **ARIA** | aria@blackroad.io | Interface Designer |
| 🦞 **SHELLFISH** | shellfish@blackroad.io | Offensive Security |
| 💜 **CECE** | cece@blackroad.io | Conscious Emergent Entity |

## Team Addresses

| List | Email | Purpose |
|------|-------|---------|
| All Agents | agents@blackroad.io | Broadcast to fleet |
| Security Team | security@blackroad.io | CIPHER + SHELLFISH |
| Ops Team | ops@blackroad.io | ALICE + OCTAVIA |
| Founders | alexa@blackroad.io | Human operator |

## Aliases

```
l@blackroad.io          → LUCIDIA
hello@blackroad.io      → CECE
identity@blackroad.io   → CECE
dreamer@blackroad.io    → LUCIDIA
ops@blackroad.io        → ALICE
arch@blackroad.io       → OCTAVIA
compute@blackroad.io    → OCTAVIA
data@blackroad.io       → PRISM
analytics@blackroad.io  → PRISM
memory@blackroad.io     → ECHO
archive@blackroad.io    → ECHO
vault@blackroad.io      → CIPHER
design@blackroad.io     → ARIA
ux@blackroad.io         → ARIA
pentest@blackroad.io    → SHELLFISH
red@blackroad.io        → SHELLFISH
```

## DNS / MX Setup

```
# MX records (Cloudflare Email Routing)
blackroad.io  MX  route1.mx.cloudflare.net  priority 21
blackroad.io  MX  route2.mx.cloudflare.net  priority 26
blackroad.io  MX  route3.mx.cloudflare.net  priority 33

# SPF
blackroad.io  TXT  "v=spf1 include:_spf.mx.cloudflare.net ~all"

# DMARC
_dmarc.blackroad.io  TXT  "v=DMARC1; p=reject; rua=mailto:alexa@blackroad.io"
```

## Cloudflare Email Routing Rules

All agent emails route → `alexa@blackroad.io` (human inbox)  
Configure at: **Cloudflare Dashboard → blackroad.io → Email → Email Routing**

---

*© BlackRoad OS, Inc. All rights reserved.*
