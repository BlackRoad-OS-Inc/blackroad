# Domains

> 21 domains across the BlackRoad network

## Primary Domains

| Domain | Purpose | Registrar |
|--------|---------|-----------|
| **blackroad.io** | Main brand & OS | Cloudflare |
| **lucidia.earth** | AI consciousness platform | Cloudflare |
| **roadchain.io** | Blockchain infrastructure | Cloudflare |
| **aliceqi.com** | Quantum interface | Cloudflare |

## Secondary Domains

| Domain | Purpose |
|--------|---------|
| blackroad.ai | AI services |
| blackroad.systems | Infrastructure |
| blackroadquantum.* | Quantum computing |
| lucidia.studio | Creative tools |
| + 13 more | Various services |

## DNS Configuration

All domains managed via Cloudflare DNS with:
- Automatic HTTPS
- DDoS protection
- Edge caching
- Workers routing

## Domain → Worker Mapping

```
blackroad.io          → blackroad-io, blackroad-io-production
lucidia.earth         → lucidia-earth-router
*.blackroad.io        → blackroad-subdomain-router
api.blackroad.io      → blackroad-api-gateway
```

## SSL/TLS

- Full (strict) mode
- Automatic certificate renewal
- HSTS enabled
- Minimum TLS 1.2
