# BlackRoad OS — Region Sharding

## Overview

BlackRoad OS uses a geo-distributed Pi + Cloudflare architecture for zero-cost global distribution.

## Region Prefixes

| Prefix | Location | Infrastructure |
|--------|----------|----------------|
| `na1.blackroad.io` | North America (primary) | alice Pi @ 192.168.4.49 |
| `eu1.blackroad.io` | Europe | DO Droplet (159.65.43.12) fallback |
| `ap1.blackroad.io` | Asia-Pacific | Planned: Raspberry Pi expansion |

## How It Works

All traffic hits Cloudflare edge → subdomain-router Worker → routes by region prefix:
- `na1.*` → CF Tunnel → alice Pi (US/primary)
- `eu1.*` → CF Tunnel → DigitalOcean droplet (until EU Pi is up)
- `ap1.*` → CF Tunnel → fallback to na1 until AP Pi deployed

## Current Status

| Region | Status | Notes |
|--------|--------|-------|
| na1 | ✅ Live | alice@192.168.4.49 via CF tunnel |
| eu1 | ⚡ CF only | DO fallback, no dedicated Pi |
| ap1 | 🔜 Planned | Q2 2026 |

## DNS CNAMEs to add

```
na1.blackroad.io CNAME <tunnel-id>.cfargotunnel.com
eu1.blackroad.io CNAME <tunnel-id>.cfargotunnel.com  
ap1.blackroad.io CNAME <tunnel-id>.cfargotunnel.com
```

## Worker routing (subdomain-router)
Add to SUBDOMAIN_APPS:
```javascript
"na1": { name: "NA1 Region", handler: handleRegion, description: "North America primary region" },
"eu1": { name: "EU1 Region", handler: handleRegion, description: "Europe region" },
"ap1": { name: "AP1 Region", handler: handleRegion, description: "Asia-Pacific region" }
```
