# Failover Worker Setup

The `blackroad-failover` worker files are staged at `/tmp/failover-worker/`.

## Why not deployed yet
The Cloudflare account has hit the 500 worker limit. Files are ready for deployment
when a slot opens up (delete an unused worker first).

## Deploy when ready
```bash
cp -r /tmp/failover-worker ~/blackroad-failover-worker
cd ~/blackroad-failover-worker
wrangler deploy
```

## What it does
3-tier failover chain:
1. **Primary** → https://blackroad.io (cached 30s)
2. **GitHub Pages fallback** → https://blackroad-os.github.io (with `x-failover: true` header)
3. **Emergency inline HTML** → Branded maintenance page (`x-failover: emergency`)

## Files
- `wrangler.toml` — Worker config with account_id and env vars
- `src/index.js` — Fetch handler with 3-tier failover logic
