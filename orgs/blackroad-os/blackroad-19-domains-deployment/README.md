# BlackRoad 19 Domains - Complete Deployment Package

**🚀 Automated deployment system for 19 BlackRoad domains on Raspberry Pi infrastructure**

---

## 📦 Package Contents

This deployment package includes:
- **19 customized websites** (homepage, docs, pricing templates)
- **Docker containers** for each domain
- **Automated deployment pipeline** (octavia → lucidia)
- **Cloudflare DNS configuration** script
- **Testing utilities**

---

## 🏗️ Infrastructure

### Raspberry Pi Cluster
- **octavia** (192.168.4.74) - Build Hub with 1.8TB SSD
- **lucidia** (192.168.4.38) - Production Web Server
- **alice** (192.168.4.49) - Pi Node
- **aria** (192.168.4.64) - Pi Node

### External
- **shellfish** (174.138.44.45) - DigitalOcean VPS

---

## 🌐 Domains

| Domain | Type | Port |
|--------|------|------|
| blackboxprogramming.io | Homepage | 3000 |
| blackroad.company | Homepage | 3001 |
| blackroad.me | Homepage | 3003 |
| blackroad.network | Homepage | 3004 |
| blackroad.systems | Homepage | 3005 |
| blackroadai.com | Homepage | 3006 |
| blackroadinc.us | Homepage | 3007 |
| blackroadqi.com | Homepage | 3008 |
| blackroadquantum.com | Homepage | 3009 |
| blackroadquantum.info | Docs | 3010 |
| blackroadquantum.net | Homepage | 3011 |
| blackroadquantum.shop | Pricing | 3012 |
| blackroadquantum.store | Pricing | 3013 |
| lucidia.earth | Homepage | 3109 |
| lucidia.studio | Homepage | 3014 |
| lucidiaqi.com | Homepage | 3015 |
| roadchain.io | Homepage | 3016 |
| roadcoin.io | Pricing | 3017 |

---

## 🚀 Quick Start

### 1. Generate Sites (Already Done!)
```bash
python3 generate-sites.py
```
This creates all 19 customized sites in `sites/` directory.

### 2. Deploy All Domains
```bash
./deploy-all-domains.sh
```
This will:
- Transfer templates to octavia
- Build Docker images on octavia
- Transfer images to lucidia
- Deploy containers on lucidia
- Verify deployments

### 3. Configure DNS
```bash
export CLOUDFLARE_API_TOKEN='your_token_here'
./configure-dns.sh
```
Or run in manual mode for configuration instructions.

### 4. Test Deployments
```bash
./test-all-domains.sh
```

---

## 📁 Directory Structure

```
blackroad-19-domains-deployment/
├── README.md                      # This file
├── DEPLOYMENT_MANIFEST.md         # Complete deployment manifest
├── domain-config.json             # Domain configuration data
├── generate-sites.py              # Site generator script
├── deploy-all-domains.sh          # Master deployment script
├── docker-compose.yml             # Docker Compose configuration
├── configure-dns.sh               # Cloudflare DNS automation
├── test-all-domains.sh            # Testing script
└── sites/                         # Generated sites (19 directories)
    ├── blackboxprogramming.io/
    │   ├── index.html
    │   ├── Dockerfile
    │   ├── nginx.conf
    │   └── .dockerignore
    ├── blackroad.company/
    ├── ... (17 more domains)
    └── roadcoin.io/
```

---

## 🎨 Design System

**BlackRoad Template System - Golden Ratio Edition**

### Colors
- **Amber:** #F5A623
- **Hot Pink:** #FF1D6C
- **Violet:** #9C27B0
- **Electric Blue:** #2979FF
- **Gradient:** 135deg, amber → hot-pink (38.2%) → violet (61.8%) → electric-blue

### Spacing (Golden Ratio φ=1.618)
- **xs:** 8px
- **sm:** 13px
- **md:** 21px
- **lg:** 34px
- **xl:** 55px
- **2xl:** 89px
- **3xl:** 144px

### Typography
- **Font Stack:** -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif
- **Line Height:** 1.618 (golden ratio)

---

## 🔧 Manual Deployment (Per Domain)

If you want to deploy a single domain manually:

```bash
# On octavia - Build
cd /media/pi/Extreme\ SSD/blackroad-hub/repos/[DOMAIN]
docker build -t [DOMAIN]:latest .

# Transfer to lucidia
ssh octavia 'docker save [DOMAIN]:latest' | ssh 192.168.4.38 'docker load'

# On lucidia - Deploy
docker run -d --name [DOMAIN] -p [PORT]:3000 --restart unless-stopped [DOMAIN]:latest

# Test
curl -I http://192.168.4.38:[PORT]
```

---

## 🐳 Docker Compose Management

On lucidia, you can also use docker-compose:

```bash
cd ~/blackroad-services
docker-compose up -d          # Start all services
docker-compose ps             # View status
docker-compose logs [service] # View logs
docker-compose down           # Stop all services
docker-compose restart        # Restart all
```

---

## 🌐 Cloudflare Configuration

**Name Servers:**
- jade.ns.cloudflare.com
- chad.ns.cloudflare.com

**Each domain needs:**
1. A record: `@` → `192.168.4.38`
2. CNAME record: `www` → `[domain]`

---

## 🧪 Testing

### Test All Domains
```bash
./test-all-domains.sh
```

### Test Single Domain
```bash
curl -I http://192.168.4.38:[PORT]
```

### Check DNS Propagation
```bash
dig @8.8.8.8 [domain] +short
```

---

## 📊 Resource Requirements

- **Total Containers:** 18
- **Estimated RAM:** ~2GB (all containers)
- **Estimated Disk:** ~5GB (images + containers)
- **Network Ports:** 3000-3017, 3109, 8081

---

## 🔍 Troubleshooting

### Container won't start
```bash
ssh lucidia
docker logs [DOMAIN]
docker ps -a
```

### Port already in use
```bash
ssh lucidia
docker stop [CONTAINER_NAME]
docker rm [CONTAINER_NAME]
```

### DNS not resolving
- Wait 5-30 minutes for propagation
- Check Cloudflare dashboard
- Verify name servers: `dig [domain] NS`

### Can't reach Pi
```bash
ping 192.168.4.38
ping 192.168.4.74
ssh pi@lucidia
ssh pi@octavia
```

---

## 📝 Next Steps

1. ✅ **Sites Generated** - All 19 customized sites created
2. ⏳ **Deploy to Pi** - Run `./deploy-all-domains.sh`
3. ⏳ **Configure DNS** - Run `./configure-dns.sh`
4. ⏳ **Test Everything** - Run `./test-all-domains.sh`
5. ⏳ **Go Live** - Point DNS to production

---

## 📄 License

© 2024-2025 BlackRoad · All Rights Reserved

---

**Generated:** 2025-12-28
**Deployment Pipeline:** octavia → lucidia
**Total Domains:** 19
**Infrastructure:** Raspberry Pi Cluster
