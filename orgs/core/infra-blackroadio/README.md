# infra.blackroad.io

> Cloudflare Worker serving [infra.blackroad.io](https://infra.blackroad.io)

## Overview

This is the Cloudflare Worker powering the **infra** subdomain of blackroad.io.

## Deployment

```bash
# Deploy worker
wrangler deploy

# Tail live logs
wrangler tail
```

## Configuration

See `wrangler.toml` for deployment configuration.

| Property | Value |
|----------|-------|
| **Platform** | Cloudflare Workers |
| **Domain** | infra.blackroad.io |
| **Account** | 848cf0b18d51e0170e0d1537aec3505a |

## Related

- [BlackRoad OS](https://github.com/BlackRoad-OS/blackroad)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
