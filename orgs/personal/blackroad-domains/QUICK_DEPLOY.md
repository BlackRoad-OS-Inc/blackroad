# Lucidia.Earth Quick Deployment Guide

**Last Updated:** 2025-12-22

---

## One-Command Deployments

### Deploy Everything
```bash
~/lucidia-deploy.sh
```

### Deploy Frontend Only
```bash
cd ~/lucidia-metaverse && npm run build && wrangler pages deploy dist --project-name=lucidia-earth
```

### Deploy Worker Only
```bash
cd ~/lucidia-earth-router && wrangler deploy
```

### Deploy Backend (Raspberry Pi) Only
```bash
ssh pi@192.168.4.38 'cd ~/lucidia-backend && git pull && docker-compose up -d --build'
```

---

## Emergency Procedures

### Complete Site Down
```bash
# 1. Check Cloudflare status
curl -I https://lucidia.earth

# 2. Check worker
wrangler tail

# 3. Check Pages
curl -I https://lucidia-earth.pages.dev

# 4. If worker issue, redeploy
cd ~/lucidia-earth-router && wrangler deploy

# 5. If Pages issue, redeploy
cd ~/lucidia-metaverse && wrangler pages deploy dist --project-name=lucidia-earth

# 6. Clear Cloudflare cache
curl -X POST "https://api.cloudflare.com/client/v4/zones/848cf0b18d51e0170e0d1537aec3505a/purge_cache" \
  -H "Authorization: Bearer yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'
```

### Backend API Down
```bash
# 1. Check Pi connectivity
ping 192.168.4.38

# 2. SSH and check Docker
ssh pi@192.168.4.38 'docker ps'

# 3. Restart containers
ssh pi@192.168.4.38 'cd ~/lucidia-backend && docker-compose restart'

# 4. Check logs
ssh pi@192.168.4.38 'cd ~/lucidia-backend && docker-compose logs --tail=100'

# 5. Full rebuild if needed
ssh pi@192.168.4.38 'cd ~/lucidia-backend && docker-compose up -d --build --force-recreate'
```

### Rollback to Previous Version
```bash
# Frontend rollback
wrangler pages deployment list --project-name=lucidia-earth
wrangler pages deployment rollback <DEPLOYMENT_ID> --project-name=lucidia-earth

# Worker rollback
wrangler deployments list
wrangler rollback [VERSION_ID]

# Backend rollback
ssh pi@192.168.4.38 << 'EOF'
  cd ~/lucidia-backend
  git log --oneline -10
  git reset --hard <COMMIT_SHA>
  docker-compose up -d --build
EOF
```

---

## Health Checks

### Quick Status Check
```bash
# All services
curl -I https://lucidia.earth && \
curl -I https://lucidia-earth.pages.dev && \
ssh pi@192.168.4.38 'docker ps | grep lucidia'
```

### Individual Service Checks
```bash
# Frontend
curl https://lucidia.earth | grep "Lucidia Metaverse"

# Worker
curl -I https://lucidia.earth | grep "X-Served-By"

# Backend API
curl https://api.lucidia.earth/health

# WebSocket
wscat -c wss://ws.lucidia.earth
```

---

## Common Tasks

### Update Frontend Code
```bash
cd ~/lucidia-metaverse
# Edit files
npm run build
wrangler pages deploy dist --project-name=lucidia-earth
```

### Update Backend Code
```bash
ssh pi@192.168.4.38 << 'EOF'
  cd ~/lucidia-backend
  git pull
  docker-compose up -d --build
EOF
```

### Add New Environment Variable
```bash
# For Worker
cd ~/lucidia-earth-router
wrangler secret put NEW_SECRET

# For Pages
# Add via Cloudflare Dashboard: Pages → Settings → Environment Variables

# For Pi/Docker
ssh pi@192.168.4.38
cd ~/lucidia-backend
nano .env
# Add: NEW_VAR=value
docker-compose up -d --force-recreate
```

### View Logs
```bash
# Worker logs
wrangler tail

# Pages deployment logs
wrangler pages deployment tail

# Pi/Docker logs
ssh pi@192.168.4.38 'cd ~/lucidia-backend && docker-compose logs -f'

# Specific container
ssh pi@192.168.4.38 'docker logs -f lucidia-api'
```

---

## Credentials Quick Access

```bash
# Cloudflare Account ID
463024cf9efed5e7b40c5fbe7938e256

# Cloudflare Zone ID (lucidia.earth)
848cf0b18d51e0170e0d1537aec3505a

# Cloudflare API Token
yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy

# Raspberry Pi IPs
# Lucidia: 192.168.4.38
# BlackRoad: 192.168.4.64
# iPhone: 192.168.4.68:8080
# DigitalOcean: 159.65.43.12
```

---

## URLs

```bash
# Production
https://lucidia.earth

# Pages Direct
https://lucidia-earth.pages.dev

# Backend API
https://api.lucidia.earth

# WebSocket
wss://ws.lucidia.earth

# Admin
https://admin.lucidia.earth

# Docs
https://docs.lucidia.earth
```

---

## Support

- **Email:** blackroad.systems@gmail.com
- **Primary:** amundsonalexa@gmail.com
- **Full Docs:** ~/lucidia-earth-router/LUCIDIA_EARTH_INFRASTRUCTURE.md
