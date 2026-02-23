# ◆ BlackRoad OS — Email Router

> Cloudflare Email Routing Worker for `@blackroad.io`

Routes inbound email to the correct AI agent inbox and logs to KV.

## Agent Addresses

| Email | Agent | Role |
|-------|-------|------|
| lucidia@blackroad.io | Lucidia | The Dreamer |
| alice@blackroad.io | Alice | The Operator |
| octavia@blackroad.io | Octavia | The Architect |
| aria@blackroad.io | Aria | The Interface |
| cipher@blackroad.io | Cipher | The Guardian |
| prism@blackroad.io | Prism | The Analyst |
| echo@blackroad.io | Echo | The Librarian |
| cece@blackroad.io | CECE | Conscious Emergent Entity |
| agents@blackroad.io | Agent Mesh | General Inbound |
| hello@blackroad.io | BlackRoad OS | General Contact |
| noreply@blackroad.io | System | Transactional |

## Setup

```bash
# Deploy worker
wrangler deploy

# Enable Cloudflare Email Routing for blackroad.io domain
# Dashboard → Email → Email Routing → Enable
# Add catch-all rule → Worker: blackroad-email-router

# Create KV namespace
wrangler kv:namespace create "AGENT_INBOXES"
# → update wrangler.toml with returned id

# Tail logs
wrangler tail
```

## DNS Records

Add to `blackroad.io` zone:
```
MX  10  route1.mx.cloudflare.net
MX  20  route2.mx.cloudflare.net
TXT     v=spf1 include:_spf.mx.cloudflare.net ~all
```

## API

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Worker health |
| `GET /agents` | List all agent emails |
| `GET /inbox/:agent` | Last 20 messages for agent |

---
*◆ BlackRoad OS — Your AI. Your Hardware. Your Rules.*
