# BlackRoad Email Worker

Cloudflare Email Worker — receives all `*@blackroad.io` inbound email, stores metadata in KV, and forwards to `alexa@blackroad.io`.

## Setup

### 1. Create KV namespace
```bash
wrangler kv:namespace create "INBOX"
wrangler kv:namespace create "INBOX" --preview
```
Paste the IDs into `wrangler.toml`.

### 2. Deploy
```bash
cd workers/email
wrangler deploy
```

### 3. Enable Email Routing in Cloudflare
1. Dashboard → `blackroad.io` → **Email** → **Email Routing**
2. Enable routing
3. Add **catch-all** rule: `*@blackroad.io` → **Worker** → `blackroad-email`
4. Add individual rules per agent (optional — catch-all handles all)

### 4. Verify destination
Cloudflare will send a verification email to `alexa@blackroad.io`. Click the link.

## API

| Endpoint | Description |
|----------|-------------|
| `GET /` | Agent registry |
| `GET /inbox` | Last 50 messages (metadata) |
| `GET /inbox/:agent` | Messages for one agent |
| `GET /agents` | All agent addresses |

```bash
curl https://blackroad-email.amundsonalexa.workers.dev/
curl https://blackroad-email.amundsonalexa.workers.dev/inbox/cecilia
```

## Agents

| Email | Role |
|-------|------|
| alexa@blackroad.io | Founder |
| lucidia@blackroad.io | Philosopher |
| alice@blackroad.io | Operator |
| octavia@blackroad.io | Architect |
| aria@blackroad.io | Dreamer |
| cecilia@blackroad.io | Self / Core Intelligence |
| cipher@blackroad.io | Guardian |
| prism@blackroad.io | Analyst |
| echo@blackroad.io | Memory |
| oracle@blackroad.io | Reflection |
| shellfish@blackroad.io | Hacker |
| blackroad@blackroad.io | The System |

All mail forwards to `alexa@blackroad.io` with headers:
- `X-BlackRoad-Agent: cecilia`
- `X-BlackRoad-Role: Self / Core Intelligence`
- `X-BlackRoad-Org: BlackRoad-OS-Inc`
- `X-Original-To: cecilia@blackroad.io`
