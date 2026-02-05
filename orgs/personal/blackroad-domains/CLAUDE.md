# BlackRoad Domains

> Domain management and DNS configuration

## Quick Reference

| Property | Value |
|----------|-------|
| **Type** | Domain Management |
| **DNS** | Cloudflare |
| **Registrar** | Various |

## Key Domains

| Domain | Purpose |
|--------|---------|
| blackroad.io | Main website |
| lucidia.earth | Lucidia landing |
| *.blackroadio.* | Worker subdomains |

## Structure

```
blackroad-domains/
├── configs/        # DNS configurations
├── workers/        # Edge workers
└── redirects/      # Redirect rules
```

## Related Repos

- `blackroad-os-web` - Main website
- `blackroad-redirect` - Redirect handling
- Infrastructure configs
