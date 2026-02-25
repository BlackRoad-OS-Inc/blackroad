# BlackRoad-OS Organization

> 1,233+ repositories — the core BlackRoad OS platform

## Status

**Not cloned locally** — disk constraints (6.8GB free / 460GB).

Full repo metadata is in [`MANIFEST.json`](./MANIFEST.json) (1,038 repos indexed).

## Clone Locally

```bash
# Clone all repos (shallow, parallel 4x)
cd /Users/alexa/blackroad
gh repo list BlackRoad-OS --limit 1000 --json name --jq '.[].name' \
  | xargs -P4 -I{} sh -c 'gh repo clone BlackRoad-OS/{} orgs/blackroad-os/{} -- --depth=1 --quiet && echo "✓ {}"'

# Or clone specific repo
gh repo clone BlackRoad-OS/<repo-name> orgs/blackroad-os/<repo-name> -- --depth=1
```

## Key Repos

| Repo | Purpose |
|------|---------|
| `blackroad-os-core` | Core platform services |
| `blackroad-os-web` | Main web app (Next.js) |
| `blackroad-os-docs` | Documentation (Docusaurus) |
| `blackroad-os-agents` | Agent system |
| `blackroad-os-mesh` | WebSocket mesh |
| `blackroad-os-prism-enterprise` | Full ERP/CRM |
| `blackroad-os-prism-console` | Admin dashboard |

## Storage Requirements

~2.5GB for full shallow clone of all 1,233 repos.
Requires freeing disk space first: `brew cleanup && docker system prune -a`
