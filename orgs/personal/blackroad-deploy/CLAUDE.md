# BlackRoad Deploy

> Deployment automation and CI/CD configurations

## Quick Reference

| Property | Value |
|----------|-------|
| **Type** | DevOps |
| **Targets** | Multi-cloud |
| **CI/CD** | GitHub Actions |

## Deployment Targets

- **Cloudflare**: Workers, Pages, KV
- **Vercel**: Next.js apps
- **Railway**: GPU services
- **DigitalOcean**: Droplets

## Structure

```
blackroad-deploy/
├── cloudflare/     # CF deployments
├── railway/        # Railway configs
├── vercel/         # Vercel projects
├── docker/         # Container builds
└── scripts/        # Deploy scripts
```

## Commands

```bash
./deploy.sh cloudflare   # Deploy to CF
./deploy.sh railway      # Deploy to Railway
./deploy.sh all          # Deploy everywhere
```

## Related Repos

- `blackroad-tools` - DevOps utilities
- `blackroad-cli` - CLI interface
- Infrastructure repos
