# Cloudflare → Self-Hosted Migration Toolkit

Migrates all Cloudflare services (Workers, KV, D1, R2, Tunnels, DNS) to self-hosted
Raspberry Pis + DigitalOcean droplets.

## Architecture

```
INTERNET → codex-infinity (159.65.43.12) → WireGuard → Pis
                                         → shellfish (failover)
```

## Phases

| Phase | Directory | What |
|-------|-----------|------|
| 0 | phase0-export/ | Export all Cloudflare data |
| 1 | phase1-postgres-redis/ | PostgreSQL + Redis on Cecilia |
| 2 | phase2-minio/ | MinIO object storage on Lucidia |
| 3 | phase3-wireguard-caddy/ | WireGuard mesh + Caddy reverse proxy |
| 4 | phase4-services/ | Port Workers to Hono/Node.js |
| 5 | phase5-dns/ | Rolling DNS cutover |
| 6 | phase6-pihole/ | Pi-hole internal DNS |
| 7 | phase7-monitoring/ | Health checks + hardening |
| 8 | phase8-decommission/ | Remove Cloudflare services |

## Quick Start

```bash
# Phase 0: Export everything (safe, read-only)
cd phase0-export && ./export-all.sh

# Phase 1: Set up databases on Cecilia
scp phase1-postgres-redis/setup-cecilia.sh pi@192.168.4.89:/tmp/
ssh pi@192.168.4.89 'bash /tmp/setup-cecilia.sh'

# Phase 2: Set up MinIO on Lucidia
scp phase2-minio/setup-minio.sh pi@192.168.4.81:/tmp/
ssh pi@192.168.4.81 'bash /tmp/setup-minio.sh'

# Phase 3: WireGuard + Caddy on DO droplets
scp phase3-wireguard-caddy/setup-edge.sh root@159.65.43.12:/tmp/
ssh root@159.65.43.12 'bash /tmp/setup-edge.sh'

# Phase 4: Deploy services to Octavia
scp -r phase4-services/ pi@192.168.4.38:/home/pi/blackroad-services/
ssh pi@192.168.4.38 'cd /home/pi/blackroad-services && npm install && pm2 start ecosystem.config.cjs'

# Phase 5: DNS cutover (run from Mac)
cd phase5-dns && ./dns-migrate.sh batch1

# Phase 6: Pi-hole on Cecilia
scp phase6-pihole/setup-pihole.sh pi@192.168.4.89:/tmp/
ssh pi@192.168.4.89 'bash /tmp/setup-pihole.sh'

# Phase 7: Monitoring on Alice
scp phase7-monitoring/setup-monitoring.sh alice@192.168.4.49:/tmp/
ssh alice@192.168.4.49 'bash /tmp/setup-monitoring.sh'

# Phase 8: Decommission (after 7-day soak)
cd phase8-decommission && ./decommission.sh
```

## Device Roles After Migration

| Device | IP | Role | RAM Budget |
|--------|-----|------|-----------|
| Cecilia | 192.168.4.89 | DB + DNS | 4GB |
| Lucidia | 192.168.4.81 | Object Storage | 1GB |
| Octavia | 192.168.4.38 | App Server | 3GB |
| Aria | 192.168.4.82 | AI + Mesh | 4GB |
| Alice | 192.168.4.49 | Monitoring | 256MB |
| codex-infinity | 159.65.43.12 | Primary Edge | 2GB |
| shellfish | 174.138.44.45 | Failover Edge | 512MB |
