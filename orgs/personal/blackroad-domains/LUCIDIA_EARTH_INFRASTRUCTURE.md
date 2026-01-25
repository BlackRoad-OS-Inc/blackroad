# Lucidia.Earth Infrastructure Documentation

**Owner:** Alexa Louise Amundson
**Domain:** lucidia.earth
**Primary Service:** Lucidia Metaverse
**Last Updated:** 2025-12-22

---

## Table of Contents

1. [Overview](#overview)
2. [Domain Architecture](#domain-architecture)
3. [Cloudflare Infrastructure](#cloudflare-infrastructure)
4. [GitHub Integration](#github-integration)
5. [Raspberry Pi Deployments](#raspberry-pi-deployments)
6. [Docker Containers](#docker-containers)
7. [Claude Code Integration](#claude-code-integration)
8. [All Domain Routing](#all-domain-routing)
9. [Deployment Workflows](#deployment-workflows)
10. [Troubleshooting](#troubleshooting)

---

## Overview

Lucidia.Earth is a comprehensive metaverse platform running across multiple infrastructure layers:

- **Frontend:** Three.js-based 3D metaverse on Cloudflare Pages
- **Routing:** Cloudflare Workers for domain routing
- **Edge:** Cloudflare global CDN
- **Backend:** Raspberry Pi devices + Docker containers
- **Version Control:** GitHub repositories
- **Development:** Claude Code for autonomous deployment

### Infrastructure Stack

```
┌─────────────────────────────────────────────────┐
│              lucidia.earth (DNS)                │
│                 Cloudflare                       │
└─────────────────┬───────────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼────────┐  ┌──────▼─────────┐
│ Worker Router  │  │  Pages Deploy  │
│ (Edge Routing) │  │  (Static Site) │
└───────┬────────┘  └────────────────┘
        │
        │ Proxies to Raspberry Pi backends
        │
┌───────▼────────────────────────────────────┐
│     Raspberry Pi Cluster (192.168.4.x)     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐   │
│  │ lucidia  │ │blackroad │ │  iPhone  │   │
│  │ .38      │ │ -pi .64  │ │ Koder.68 │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘   │
│       │ Docker     │ Docker     │ Docker  │
│  ┌────▼─────┐ ┌────▼─────┐ ┌────▼─────┐   │
│  │Services  │ │Services  │ │Services  │   │
│  └──────────┘ └──────────┘ └──────────┘   │
└────────────────────────────────────────────┘
```

---

## Domain Architecture

### Primary Domain: lucidia.earth

**DNS Configuration:**
- **Nameservers:** Cloudflare (via Zone ID: 848cf0b18d51e0170e0d1537aec3505a)
- **Root (@):** CNAME to lucidia-earth-router.workers.dev (proxied)
- **Cloudflare Proxy:** Enabled (orange cloud)

**Current Routing:**
```
lucidia.earth → Cloudflare Worker (lucidia-earth-router)
              → Cloudflare Pages (lucidia-earth.pages.dev)
              → Three.js Metaverse Application
```

### Subdomain Strategy

All services can be accessed via subdomains:

```
api.lucidia.earth       → Backend API (Raspberry Pi)
ws.lucidia.earth        → WebSocket multiplayer server
admin.lucidia.earth     → Admin dashboard
docs.lucidia.earth      → Documentation site
dev.lucidia.earth       → Development preview
```

---

## Cloudflare Infrastructure

### Account Details
- **Account ID:** 463024cf9efed5e7b40c5fbe7938e256
- **Zone ID (lucidia.earth):** 848cf0b18d51e0170e0d1537aec3505a
- **API Token:** yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy

### Cloudflare Pages

**Project:** lucidia-earth
**URL:** https://lucidia-earth.pages.dev
**Custom Domain:** lucidia.earth

**Build Configuration:**
```toml
# Build settings
Build command: npm run build
Build output directory: dist
Root directory: /
Node version: 18
```

**Deploy via Wrangler:**
```bash
cd ~/lucidia-metaverse
npm run build
wrangler pages deploy dist --project-name=lucidia-earth
```

**Deploy via Git:**
```bash
# Connect GitHub repo to Cloudflare Pages
# Auto-deploy on push to main branch
git push origin main
```

### Cloudflare Workers

**Worker:** lucidia-earth-router
**Location:** ~/lucidia-earth-router

**Purpose:** Routes lucidia.earth to the Pages deployment

**Configuration (wrangler.toml):**
```toml
name = "lucidia-earth-router"
main = "src/index.ts"
compatibility_date = "2025-01-01"

[vars]
PAGES_URL = "https://lucidia-earth.pages.dev"

[[routes]]
pattern = "lucidia.earth/*"
zone_name = "lucidia.earth"
```

**Deploy Worker:**
```bash
cd ~/lucidia-earth-router
wrangler deploy
```

**Environment Variables:**
```bash
# Set via wrangler
wrangler secret put API_KEY
wrangler secret put DATABASE_URL
```

### Cloudflare Tunnels (Shellfish)

**Use Case:** Connect Raspberry Pi services securely to the internet without port forwarding

**Setup:**
```bash
# On Raspberry Pi
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-archive-keyring.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update && sudo apt-get install cloudflared

# Login
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create lucidia-backend

# Configure routing
cloudflared tunnel route dns lucidia-backend api.lucidia.earth

# Run tunnel
cloudflared tunnel run lucidia-backend
```

**Tunnel Configuration (config.yml):**
```yaml
tunnel: <TUNNEL_ID>
credentials-file: /home/pi/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: api.lucidia.earth
    service: http://localhost:3000
  - hostname: ws.lucidia.earth
    service: http://localhost:8080
  - service: http_status:404
```

---

## GitHub Integration

### Repository Structure

**Organization:** BlackRoad-OS (or blackboxprogramming)

**Key Repositories:**
- `lucidia-metaverse` - Main metaverse application
- `lucidia-earth-router` - Cloudflare Worker router
- `lucidia-backend` - Backend API services
- `lucidia-pi-ops` - Raspberry Pi configurations

### Deployment from GitHub

**Method 1: Cloudflare Pages + GitHub**

1. Connect repo to Cloudflare Pages:
```bash
# Via Cloudflare Dashboard
# Pages → Create Project → Connect to Git → Select Repository
```

2. Configure build settings:
```
Framework preset: Vite
Build command: npm run build
Build output: dist
Root directory: /
```

3. Auto-deploy:
```bash
git push origin main
# Cloudflare automatically builds and deploys
```

**Method 2: Manual Deploy via CLI**

```bash
# Clone repo
git clone https://github.com/BlackRoad-OS/lucidia-metaverse.git
cd lucidia-metaverse

# Install and build
npm install
npm run build

# Deploy
wrangler pages deploy dist --project-name=lucidia-earth
```

**Method 3: GitHub Actions**

Create `.github/workflows/deploy.yml`:
```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: 18

      - name: Install dependencies
        run: npm install

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: 463024cf9efed5e7b40c5fbe7938e256
          command: pages deploy dist --project-name=lucidia-earth
```

### Git Workflow

```bash
# Standard development flow
git checkout -b feature/new-metaverse-feature
# Make changes
git add .
git commit -m "Add new portal system"
git push origin feature/new-metaverse-feature

# Create PR and merge to main
# Auto-deploys to production
```

---

## Raspberry Pi Deployments

### Available Raspberry Pis

| Device | IP Address | Hostname | Purpose |
|--------|------------|----------|---------|
| Lucidia Pi | 192.168.4.38 | lucidia | Primary backend services |
| Lucidia Pi Alt | 192.168.4.99 | lucidia | Alternate/backup |
| BlackRoad Pi | 192.168.4.64 | blackroad-pi | Secondary services |
| iPhone Koder | 192.168.4.68:8080 | iphone-koder | Mobile development |
| DigitalOcean | 159.65.43.12 | codex-infinity | Cloud VPS |

### SSH Access

```bash
# Connect to Lucidia Pi
ssh pi@192.168.4.38
# or
ssh pi@lucidia.local

# Default password: raspberry (should be changed)

# SSH with key
ssh -i ~/.ssh/lucidia_pi pi@192.168.4.38
```

### Setting Up New Pi Service

**1. Initial Setup:**
```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker pi

# Install Docker Compose
sudo apt-get install docker-compose -y

# Install Git
sudo apt-get install git -y
```

**2. Clone Repository:**
```bash
cd ~
git clone https://github.com/BlackRoad-OS/lucidia-backend.git
cd lucidia-backend
```

**3. Configure Environment:**
```bash
cp .env.example .env
nano .env

# Set variables:
# DATABASE_URL=postgresql://...
# CLOUDFLARE_API_KEY=...
# DOMAIN=lucidia.earth
```

**4. Deploy with Docker Compose:**
```bash
docker-compose up -d
```

### Connecting Pi to Cloudflare

**Option 1: Cloudflare Tunnel (Recommended)**

```bash
# Install cloudflared on Pi
sudo apt-get install cloudflared

# Authenticate
cloudflared tunnel login

# Create tunnel
cloudflared tunnel create lucidia-pi-backend

# Configure tunnel
nano ~/.cloudflared/config.yml
```

**Option 2: Dynamic DNS + Port Forwarding**

```bash
# Install ddclient
sudo apt-get install ddclient

# Configure for Cloudflare
sudo nano /etc/ddclient.conf

# Add:
# protocol=cloudflare
# login=amundsonalexa@gmail.com
# password=<API_TOKEN>
# zone=lucidia.earth
# api.lucidia.earth
```

### Pi Health Monitoring

```bash
# Check Docker containers
docker ps

# View logs
docker-compose logs -f

# Monitor resources
htop

# Check disk space
df -h

# Temperature
vcgencmd measure_temp
```

---

## Docker Containers

### Docker on Raspberry Pi

**Architecture:** ARM64/ARMv7

**Key Containers:**

#### 1. Backend API
```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    image: node:18-alpine
    container_name: lucidia-api
    working_dir: /app
    volumes:
      - ./api:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    command: npm start
    restart: unless-stopped
```

#### 2. WebSocket Server (Multiplayer)
```yaml
  websocket:
    image: node:18-alpine
    container_name: lucidia-ws
    working_dir: /app
    volumes:
      - ./websocket:/app
    ports:
      - "8080:8080"
    environment:
      - WS_PORT=8080
    command: npm start
    restart: unless-stopped
```

#### 3. PostgreSQL Database
```yaml
  postgres:
    image: postgres:15-alpine
    container_name: lucidia-db
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=lucidia
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=lucidia_metaverse
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

#### 4. Redis Cache
```yaml
  redis:
    image: redis:7-alpine
    container_name: lucidia-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  redis_data:
```

### Docker Management Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# View logs
docker-compose logs -f [service_name]

# Execute command in container
docker exec -it lucidia-api sh

# Check resource usage
docker stats

# Prune unused images/containers
docker system prune -a
```

### ARM-Specific Considerations

```dockerfile
# Use ARM-compatible base images
FROM --platform=linux/arm64 node:18-alpine

# or multi-platform
FROM node:18-alpine
# Docker will automatically pull the correct arch
```

---

## Claude Code Integration

### Using Claude Code for Deployment

Claude Code can autonomously deploy to all infrastructure components.

**Prerequisites:**
```bash
# Ensure wrangler is configured
wrangler login

# SSH keys for Pi access
ssh-keygen -t ed25519 -C "claude-deployment"
ssh-copy-id pi@192.168.4.38

# GitHub token (if using private repos)
export GITHUB_TOKEN="ghp_..."
```

### Deployment Commands via Claude

**Deploy Metaverse:**
```bash
# Claude can execute:
cd ~/lucidia-metaverse
npm run build
wrangler pages deploy dist --project-name=lucidia-earth
```

**Deploy Worker:**
```bash
cd ~/lucidia-earth-router
wrangler deploy
```

**Deploy to Raspberry Pi:**
```bash
# Claude can SSH and deploy:
ssh pi@192.168.4.38 << 'EOF'
cd ~/lucidia-backend
git pull origin main
docker-compose up -d --build
EOF
```

### Claude Automation Scripts

Create `~/lucidia-deploy.sh`:
```bash
#!/bin/bash
# Automated deployment script for Claude Code

set -e

echo "🚀 Deploying Lucidia.Earth..."

# Build and deploy frontend
echo "📦 Building metaverse..."
cd ~/lucidia-metaverse
npm install
npm run build
wrangler pages deploy dist --project-name=lucidia-earth

# Deploy worker
echo "⚡ Deploying router worker..."
cd ~/lucidia-earth-router
wrangler deploy

# Deploy to Raspberry Pi
echo "🥧 Deploying to Raspberry Pi..."
ssh pi@192.168.4.38 << 'ENDSSH'
cd ~/lucidia-backend
git pull origin main
docker-compose pull
docker-compose up -d --build
echo "✅ Pi deployment complete"
ENDSSH

echo "✨ Deployment complete! https://lucidia.earth"
```

Make executable:
```bash
chmod +x ~/lucidia-deploy.sh
```

### Claude Memory Integration

Add to `~/.claude/CLAUDE.md`:
```markdown
## Lucidia.Earth Infrastructure

- Domain: lucidia.earth
- Cloudflare Pages: lucidia-earth
- Worker: lucidia-earth-router
- Pi: 192.168.4.38 (lucidia)
- Deployment script: ~/lucidia-deploy.sh

Quick deploy command:
~/lucidia-deploy.sh
```

---

## All Domain Routing

### Complete Domain Mapping

#### BlackRoad Ecosystem

| Domain | Type | Route To | Purpose |
|--------|------|----------|---------|
| blackroad.io | Root | blackroad-io.pages.dev | Main corporate site |
| earth.blackroad.io | Sub | earth-blackroad-io.pages.dev | Earth visualization |
| demo.blackroad.io | Sub | blackroad-os-demo.pages.dev | Demo environment |
| home.blackroad.io | Sub | blackroad-os-home.pages.dev | Home dashboard |
| api.blackroad.io | Sub | 159.65.43.12:3000 (DigitalOcean) | API backend |

#### Lucidia Ecosystem

| Domain | Type | Route To | Purpose |
|--------|------|----------|---------|
| lucidia.earth | Root | lucidia-earth.pages.dev | Metaverse (via worker) |
| api.lucidia.earth | Sub | Pi 192.168.4.38:3000 | Backend API |
| ws.lucidia.earth | Sub | Pi 192.168.4.38:8080 | WebSocket server |
| docs.lucidia.earth | Sub | lucidia-docs.pages.dev | Documentation |
| admin.lucidia.earth | Sub | lucidia-admin.pages.dev | Admin panel |

#### Quantum Domains

| Domain | Type | Route To | Purpose |
|--------|------|----------|---------|
| blackroadquantum.info | Root | blackroad-os-web.pages.dev | Quantum info |
| blackroadquantum.net | Root | blackroad-os-web.pages.dev | Quantum net |
| blackroadquantum.shop | Root | blackroad-os-web.pages.dev | Quantum shop |
| blackroadquantum.store | Root | blackroad-os-web.pages.dev | Quantum store |
| blackroadqi.com | Root | blackroad-os-web.pages.dev | Quantum intelligence |

### DNS Configuration Pattern

**For Cloudflare Pages:**
```
Type: CNAME
Name: @ (or subdomain)
Content: <project-name>.pages.dev
Proxy: Enabled (orange cloud)
TTL: Auto
```

**For Workers:**
```
Type: CNAME
Name: @ (or subdomain)
Content: <worker-name>.workers.dev
Proxy: Enabled
TTL: Auto
```

**For Raspberry Pi (via Tunnel):**
```
Type: CNAME
Name: api (or subdomain)
Content: <tunnel-id>.cfargotunnel.com
Proxy: Enabled
TTL: Auto
```

### Adding New Domain

**1. Add Domain to Cloudflare:**
```bash
# Via Dashboard or API
curl -X POST "https://api.cloudflare.com/client/v4/zones" \
  -H "Authorization: Bearer yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy" \
  -H "Content-Type: application/json" \
  --data '{"name":"newdomain.com","account":{"id":"463024cf9efed5e7b40c5fbe7938e256"}}'
```

**2. Point to Pages Project:**
```bash
# Via wrangler or Cloudflare dashboard
# Dashboard: Pages → Project → Custom Domains → Add domain
```

**3. Create Worker Route (if needed):**
```toml
# wrangler.toml
[[routes]]
pattern = "newdomain.com/*"
zone_name = "newdomain.com"
```

---

## Deployment Workflows

### Full Stack Deployment

**Complete deployment from scratch:**

```bash
#!/bin/bash
# full-deploy.sh

# 1. Frontend (Metaverse)
echo "🎨 Deploying frontend..."
cd ~/lucidia-metaverse
npm install
npm run build
wrangler pages deploy dist --project-name=lucidia-earth

# 2. Worker Router
echo "⚡ Deploying worker..."
cd ~/lucidia-earth-router
wrangler deploy

# 3. Backend API (Raspberry Pi)
echo "🥧 Deploying backend to Pi..."
ssh pi@192.168.4.38 << 'EOF'
  cd ~/lucidia-backend
  git pull origin main
  npm install
  docker-compose up -d --build
EOF

# 4. Verify deployment
echo "✅ Verifying..."
curl -I https://lucidia.earth
curl -I https://api.lucidia.earth/health

echo "🎉 Full deployment complete!"
```

### Rollback Procedure

**Pages Rollback:**
```bash
# View deployments
wrangler pages deployment list --project-name=lucidia-earth

# Rollback to specific deployment
wrangler pages deployment rollback <DEPLOYMENT_ID> --project-name=lucidia-earth
```

**Worker Rollback:**
```bash
# View versions
wrangler deployments list

# Rollback
wrangler rollback [VERSION_ID]
```

**Pi Rollback:**
```bash
ssh pi@192.168.4.38 << 'EOF'
  cd ~/lucidia-backend
  git log --oneline -5  # Find commit
  git reset --hard <COMMIT_SHA>
  docker-compose up -d --build
EOF
```

### CI/CD Pipeline

**GitHub Actions - Full Pipeline:**

```yaml
# .github/workflows/production.yml
name: Production Deployment

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install
      - run: npm run build
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: 463024cf9efed5e7b40c5fbe7938e256
          command: pages deploy dist --project-name=lucidia-earth

  deploy-worker:
    runs-on: ubuntu-latest
    needs: deploy-frontend
    steps:
      - uses: actions/checkout@v3
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          command: deploy
          workingDirectory: 'worker'

  deploy-backend:
    runs-on: ubuntu-latest
    needs: deploy-worker
    steps:
      - name: Deploy to Raspberry Pi
        uses: appleboy/ssh-action@master
        with:
          host: 192.168.4.38
          username: pi
          key: ${{ secrets.PI_SSH_KEY }}
          script: |
            cd ~/lucidia-backend
            git pull origin main
            docker-compose up -d --build
```

---

## Troubleshooting

### Common Issues

**1. Pages not updating:**
```bash
# Clear cache
curl -X POST "https://api.cloudflare.com/client/v4/zones/848cf0b18d51e0170e0d1537aec3505a/purge_cache" \
  -H "Authorization: Bearer yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'

# Force new deployment
wrangler pages deploy dist --project-name=lucidia-earth --branch=production
```

**2. Worker not routing:**
```bash
# Check worker status
wrangler deployments list

# View logs
wrangler tail

# Redeploy
wrangler deploy --force
```

**3. Pi connection issues:**
```bash
# Test connectivity
ping 192.168.4.38

# Check SSH
ssh -v pi@192.168.4.38

# Check Docker
ssh pi@192.168.4.38 'docker ps'

# Restart services
ssh pi@192.168.4.38 'cd ~/lucidia-backend && docker-compose restart'
```

**4. DNS propagation:**
```bash
# Check DNS
dig lucidia.earth
dig api.lucidia.earth

# Check from different locations
curl -H "Host: lucidia.earth" http://104.21.89.100

# Cloudflare DNS flush (via dashboard or API)
```

### Health Check Endpoints

**Frontend:**
```bash
curl https://lucidia.earth
# Should return HTML with "Lucidia Metaverse"
```

**Worker:**
```bash
curl -I https://lucidia.earth
# Should include header: X-Served-By: lucidia-earth-router
```

**Backend API:**
```bash
curl https://api.lucidia.earth/health
# Should return: {"status": "ok", "timestamp": "..."}
```

### Monitoring

**Cloudflare Analytics:**
- Dashboard → Analytics → Traffic
- Web Analytics for visitor metrics
- Worker Analytics for edge performance

**Pi Monitoring:**
```bash
# Install monitoring
sudo apt-get install prometheus-node-exporter

# View metrics
curl http://192.168.4.38:9100/metrics
```

---

## Quick Reference

### Essential Commands

```bash
# Deploy everything
~/lucidia-deploy.sh

# Deploy frontend only
cd ~/lucidia-metaverse && npm run build && wrangler pages deploy dist --project-name=lucidia-earth

# Deploy worker only
cd ~/lucidia-earth-router && wrangler deploy

# Deploy to Pi only
ssh pi@192.168.4.38 'cd ~/lucidia-backend && git pull && docker-compose up -d --build'

# Check status
curl -I https://lucidia.earth
ssh pi@192.168.4.38 'docker ps'

# View logs
wrangler tail
ssh pi@192.168.4.38 'docker-compose logs -f'
```

### Important URLs

- **Production:** https://lucidia.earth
- **Pages Direct:** https://lucidia-earth.pages.dev
- **Cloudflare Dashboard:** https://dash.cloudflare.com
- **GitHub:** https://github.com/BlackRoad-OS
- **Pi Admin:** http://192.168.4.38 (local only)

### Credentials Location

- **Cloudflare API Token:** ~/.claude/CLAUDE.md
- **SSH Keys:** ~/.ssh/lucidia_pi
- **GitHub Token:** ~/.config/gh/hosts.yml
- **Environment Vars:** ~/lucidia-backend/.env

---

**Document Version:** 1.0
**Maintained By:** Claude Code + Alexa Louise Amundson
**Support:** blackroad.systems@gmail.com
