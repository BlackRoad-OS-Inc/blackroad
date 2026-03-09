# 🎛️ BlackRoad Command Center

Unified API for controlling all BlackRoad services.

## Endpoints

### GitHub
- `GET /github/orgs` - List all organizations
- `GET /github/repos/:org` - List repos in org
- `POST /github/repo` - Create new repo
- `POST /github/file` - Create/update file

### Stripe
- `GET /stripe/products` - List products
- `POST /stripe/product` - Create product + price + payment link
- `GET /stripe/customers` - List customers

### HuggingFace
- `GET /hf/models?q=` - Search models
- `GET /hf/spaces?q=` - Search spaces

### Cloudflare
- `GET /cf/workers` - List workers
- `GET /cf/kv` - List KV namespaces
- `GET /cf/d1` - List D1 databases

### Agents
- `GET /agents` - List agents
- `POST /agents` - Create agent
- `GET /agents/:id` - Get agent details

### Utility
- `GET /stats` - System statistics
- `POST /notify` - Multi-channel notifications

## Deploy

```bash
npm install
wrangler secret put GITHUB_TOKEN
wrangler secret put STRIPE_SECRET_KEY
wrangler secret put HF_TOKEN
wrangler secret put CLOUDFLARE_API_TOKEN
wrangler deploy
```

## Quick Examples

```bash
# Create a repo
curl -X POST https://cmd.blackroad.io/github/repo \
  -H "Content-Type: application/json" \
  -d '{"name": "my-new-repo", "org": "BlackRoad-AI"}'

# Create a product with payment link
curl -X POST https://cmd.blackroad.io/stripe/product \
  -H "Content-Type: application/json" \
  -d '{"name": "Pro Plan", "price": 29.99, "recurring": "month"}'

# Create an agent
curl -X POST https://cmd.blackroad.io/agents \
  -H "Content-Type: application/json" \
  -d '{"name": "Atlas", "type": "researcher", "capabilities": ["search", "analyze"]}'
```
