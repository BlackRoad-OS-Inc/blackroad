# infra.blackroad.io

> Cloudflare Worker — `infra.blackroad.io`

## Quick Reference

| Property | Value |
|----------|-------|
| **Type** | Cloudflare Worker |
| **Domain** | infra.blackroad.io |
| **Account ID** | 848cf0b18d51e0170e0d1537aec3505a |

## Commands

```bash
# Deploy
wrangler deploy

# Local dev
wrangler dev

# Tail logs
wrangler tail --format pretty

# Check status
wrangler whoami
```

## Project Structure

```
infra-blackroadio/
├── index.html          # Main content
├── wrangler.toml       # Worker configuration
└── LICENSE
```

## Environment Variables

Set via Cloudflare dashboard or `wrangler secret put`:
```bash
wrangler secret put VARIABLE_NAME
```

## Related

- [BlackRoad OS](https://github.com/BlackRoad-OS/blackroad)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [wrangler.toml reference](https://developers.cloudflare.com/workers/wrangler/configuration/)
