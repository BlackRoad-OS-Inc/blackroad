# I built a self-hosted Railway alternative for $20/month

After spending $200+/month on Railway, I built my own deployment platform.

**What it does:**
- Deploy Node, Python, Go, Rust, Docker apps
- GitHub webhook auto-deployment
- Cloudflare DNS integration
- Automatic SSL with Caddy
- Deploy to Raspberry Pis or VPSes

**vs. Railway:**
| Railway | BlackRoad Deploy |
|---------|------------------|
| $5 base + $10/GB RAM | $20 flat fee |
| Cloud-only | Self-hosted |
| Vendor lock-in | You own everything |

**Tech stack:**
- Python orchestrator
- Docker buildpacks
- Caddy reverse proxy
- Cloudflare API

Repo: https://github.com/blackboxprogramming/blackroad-deploy
Pricing: $20/mo unlimited apps

Happy to answer questions!
