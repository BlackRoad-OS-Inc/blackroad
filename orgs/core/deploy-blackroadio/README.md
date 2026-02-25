# deploy.blackroad.io

> Cloudflare Worker serving [deploy.blackroad.io](https://deploy.blackroad.io)

## Overview

This is the Cloudflare Worker powering the **deploy** subdomain of blackroad.io.

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
| **Domain** | deploy.blackroad.io |
| **Account** | 848cf0b18d51e0170e0d1537aec3505a |

## Related

- [BlackRoad OS](https://github.com/BlackRoad-OS/blackroad)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
