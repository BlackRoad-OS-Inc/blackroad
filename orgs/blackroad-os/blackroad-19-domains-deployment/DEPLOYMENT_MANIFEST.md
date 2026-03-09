# BlackRoad 19 Domains - Complete Deployment Manifest

**Generated:** 2025-12-28
**Infrastructure:** Raspberry Pi Cluster (octavia → lucidia)
**Total Domains:** 19
**Design System:** BlackRoad Templates (Golden Ratio φ=1.618)

---

## Infrastructure Map

### Pi Cluster
- **alice** (192.168.4.49) - Pi Node
- **aria** (192.168.4.64) - Pi Node
- **octavia** (192.168.4.74) - Build Hub (1.8TB Extreme SSD)
  - Location: `/media/pi/Extreme SSD/blackroad-hub/`
  - Role: Docker image builder
- **lucidia** (192.168.4.38) - Production Web Server
  - Ports: 3000-3017, 3109, 8081
  - Role: Docker container host

### External
- **shellfish** (174.138.44.45) - DigitalOcean VPS

---

## Domain → Service Mapping

| # | Domain | Template | Port | Status |
|---|--------|----------|------|--------|
| 1 | blackboxprogramming.io | homepage | 3000 | pending |
| 2 | blackroad.company | homepage | 3001 | pending |
| 3 | blackroad.io | auth | 3000 | ✅ deployed |
| 4 | blackroad.me | homepage | 3003 | pending |
| 5 | blackroad.network | homepage | 3004 | pending |
| 6 | blackroad.systems | homepage | 3005 | pending |
| 7 | blackroadai.com | homepage | 3006 | pending |
| 8 | blackroadinc.us | homepage | 3007 | pending |
| 9 | blackroadqi.com | homepage | 3008 | pending |
| 10 | blackroadquantum.com | homepage | 3009 | pending |
| 11 | blackroadquantum.info | docs | 3010 | pending |
| 12 | blackroadquantum.net | homepage | 3011 | pending |
| 13 | blackroadquantum.shop | pricing | 3012 | pending |
| 14 | blackroadquantum.store | pricing | 3013 | pending |
| 15 | lucidia.earth | homepage | 3109 | pending |
| 16 | lucidia.studio | homepage | 3014 | pending |
| 17 | lucidiaqi.com | homepage | 3015 | pending |
| 18 | roadchain.io | homepage | 3016 | pending |
| 19 | roadcoin.io | pricing | 3017 | pending |

---

## Design System

**Colors:**
- Amber: #F5A623
- Hot Pink: #FF1D6C
- Violet: #9C27B0
- Electric Blue: #2979FF
- Gradient: 135deg, amber 0%, hot-pink 38.2%, violet 61.8%, electric-blue 100%

**Spacing (Golden Ratio φ=1.618):**
- xs: 8px, sm: 13px, md: 21px, lg: 34px, xl: 55px, 2xl: 89px, 3xl: 144px

**Typography:**
- Font: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif
- Line height: 1.618

---

## Deployment Pipeline

### Stage 1: Build (on octavia)
```bash
cd /media/pi/Extreme SSD/blackroad-hub/repos/[DOMAIN]
docker build -t [DOMAIN]:latest .
```

### Stage 2: Transfer (octavia → lucidia)
```bash
ssh octavia 'docker save [DOMAIN]:latest' | ssh 192.168.4.38 'docker load'
```

### Stage 3: Deploy (on lucidia)
```bash
docker run -d --name [DOMAIN] -p [PORT]:3000 --restart unless-stopped [DOMAIN]:latest
```

### Stage 4: Verify
```bash
curl -I http://192.168.4.38:[PORT]
```

---

## Cloudflare DNS Configuration

**Name Servers:**
- jade.ns.cloudflare.com
- chad.ns.cloudflare.com

**Required A Records:**
- All 19 domains → 192.168.4.38 (lucidia)

**Required CNAME Records:**
- www.[domain] → [domain]

---

## Next Steps

1. ✅ Generate 19 customized HTML files
2. ⏳ Create docker-compose.yml for all services
3. ⏳ Create master deployment script
4. ⏳ Create Cloudflare DNS automation script
5. ⏳ Deploy to octavia
6. ⏳ Transfer to lucidia
7. ⏳ Configure Cloudflare DNS
8. ⏳ Test all 19 domains

---

**Total Services:** 19 containers
**Total Resources:** ~2GB RAM, ~5GB disk
**Estimated Deployment Time:** 30-45 minutes
