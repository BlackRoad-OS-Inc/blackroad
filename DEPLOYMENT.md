# Deployment Guide

> Complete guide for deploying BlackRoad OS infrastructure

---

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Cloudflare Deployment](#cloudflare-deployment)
- [Railway Deployment](#railway-deployment)
- [Vercel Deployment](#vercel-deployment)
- [DigitalOcean Deployment](#digitalocean-deployment)
- [Raspberry Pi Deployment](#raspberry-pi-deployment)
- [Multi-Cloud Setup](#multi-cloud-setup)
- [Monitoring & Observability](#monitoring--observability)
- [Rollback Procedures](#rollback-procedures)

---

## Overview

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  DEPLOYMENT TARGETS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐  │
│  │ CLOUDFLARE  │     │   RAILWAY   │     │   VERCEL    │  │
│  │             │     │             │     │             │  │
│  │ • Workers   │     │ • Services  │     │ • Next.js   │  │
│  │ • Pages     │     │ • GPU nodes │     │ • Edge      │  │
│  │ • KV/D1/R2  │     │ • Databases │     │ • Serverless│  │
│  └─────────────┘     └─────────────┘     └─────────────┘  │
│                                                             │
│  ┌─────────────┐     ┌─────────────┐                       │
│  │DIGITALOCEAN │     │RASPBERRY PI │                       │
│  │             │     │             │                       │
│  │ • Droplets  │     │ • Edge nodes│                       │
│  │ • Volumes   │     │ • LED/Holo  │                       │
│  │ • Spaces    │     │ • Ollama    │                       │
│  └─────────────┘     └─────────────┘                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required Tools

```bash
# Install deployment tools
npm install -g wrangler           # Cloudflare
npm install -g vercel             # Vercel
npm install -g @railway/cli       # Railway
brew install doctl                # DigitalOcean

# Verify installations
wrangler --version
vercel --version
railway --version
doctl version
```

### Environment Variables

```bash
# Create .env.deploy file
cat > .env.deploy << 'EOF'
# Cloudflare
CLOUDFLARE_API_TOKEN=your-token
CLOUDFLARE_ACCOUNT_ID=848cf0b18d51e0170e0d1537aec3505a

# Railway
RAILWAY_TOKEN=your-token

# Vercel
VERCEL_TOKEN=your-token
VERCEL_ORG_ID=your-org-id

# DigitalOcean
DIGITALOCEAN_TOKEN=your-token
DO_DROPLET_IP=159.65.43.12

# GitHub
GITHUB_TOKEN=your-token
EOF
```

---

## Cloudflare Deployment

### Workers

```bash
# Navigate to worker directory
cd orgs/core/api-blackroadio

# Deploy worker
wrangler deploy

# Deploy with environment
wrangler deploy --env production

# View logs
wrangler tail
```

### Pages

```bash
# Deploy to Pages
wrangler pages deploy ./dist --project-name=blackroad-web

# Or using the dashboard
# 1. Connect GitHub repo
# 2. Configure build settings
# 3. Deploy
```

### KV Namespaces

```bash
# Create KV namespace
wrangler kv:namespace create "BLACKROAD_KV"

# Add to wrangler.toml
[[kv_namespaces]]
binding = "BLACKROAD_KV"
id = "your-namespace-id"

# Put/get values
wrangler kv:key put --binding=BLACKROAD_KV "key" "value"
wrangler kv:key get --binding=BLACKROAD_KV "key"
```

### D1 Database

```bash
# Create D1 database
wrangler d1 create blackroad-db

# Run migrations
wrangler d1 migrations apply blackroad-db

# Query database
wrangler d1 execute blackroad-db --command="SELECT * FROM agents"
```

### R2 Storage

```bash
# Create R2 bucket
wrangler r2 bucket create blackroad-storage

# Upload file
wrangler r2 object put blackroad-storage/file.txt --file=./file.txt
```

### Tunnel Setup

```bash
# Create tunnel
cloudflared tunnel create blackroad-tunnel

# Configure tunnel
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: 52915859-da18-4aa6-add5-7bd9fcac2e0b
credentials-file: ~/.cloudflared/52915859-da18-4aa6-add5-7bd9fcac2e0b.json

ingress:
  - hostname: api.blackroad.io
    service: http://localhost:8000
  - hostname: "*.blackroad.io"
    service: http://localhost:3000
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run blackroad-tunnel
```

---

## Railway Deployment

### Service Deployment

```bash
# Login
railway login

# Initialize project
railway init

# Link to existing project
railway link

# Deploy
railway up

# View logs
railway logs
```

### Railway Configuration

```toml
# railway.toml
[build]
builder = "dockerfile"

[deploy]
numReplicas = 1
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"

[deploy.resources]
cpus = 2
memory = "4Gi"
```

### GPU Services

```toml
# railway.toml for GPU service
[build]
builder = "dockerfile"

[deploy]
numReplicas = 1

[deploy.resources]
gpuType = "a100-80gb"
gpuCount = 1
```

### Database Setup

```bash
# Add PostgreSQL
railway add --database postgres

# Get connection string
railway variables get DATABASE_URL

# Add Redis
railway add --database redis
```

---

## Vercel Deployment

### Project Setup

```bash
# Login
vercel login

# Initialize project
vercel init

# Deploy preview
vercel

# Deploy production
vercel --prod
```

### Configuration

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "regions": ["sfo1", "iad1"],
  "env": {
    "NEXT_PUBLIC_API_URL": "@api-url"
  }
}
```

### Environment Variables

```bash
# Add secret
vercel secrets add api-url "https://api.blackroad.io"

# Link to project
vercel env add NEXT_PUBLIC_API_URL production
```

---

## DigitalOcean Deployment

### Droplet Setup

```bash
# Create droplet
doctl compute droplet create codex-infinity \
  --region nyc1 \
  --size s-4vcpu-8gb \
  --image ubuntu-22-04-x64 \
  --ssh-keys your-key-id

# List droplets
doctl compute droplet list

# SSH into droplet
ssh root@159.65.43.12
```

### Application Deployment

```bash
# On the droplet
# Clone repository
git clone https://github.com/blackboxprogramming/blackroad.git
cd blackroad

# Install dependencies
curl -fsSL https://get.docker.com | sh
docker compose up -d

# Setup systemd service
cat > /etc/systemd/system/blackroad.service << 'EOF'
[Unit]
Description=BlackRoad OS
After=docker.service

[Service]
Type=simple
WorkingDirectory=/root/blackroad
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable blackroad
systemctl start blackroad
```

### Firewall Configuration

```bash
# Setup UFW
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 8080/tcp  # API
ufw enable
```

---

## Raspberry Pi Deployment

### Initial Setup

```bash
# Flash Raspberry Pi OS
# Enable SSH
# Connect to network

# SSH into Pi
ssh pi@192.168.4.38

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3-pip python3-venv git
```

### BlackRoad Agent Setup

```bash
# Clone repository
git clone https://github.com/blackboxprogramming/blackroad-pi-ops.git
cd blackroad-pi-ops

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -e ".[rpi]"

# Run agent
pi-ops start
```

### LED Bridge Setup

```bash
# Install LED dependencies
sudo pip3 install rpi_ws281x

# Configure LED service
sudo cat > /etc/systemd/system/led-bridge.service << 'EOF'
[Unit]
Description=BlackRoad LED Bridge
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/pi/blackroad-pi-ops
ExecStart=/home/pi/blackroad-pi-ops/venv/bin/led-bridge
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable led-bridge
sudo systemctl start led-bridge
```

### Ollama Setup (Pi 5)

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull models
ollama pull llama3.2:1b
ollama pull phi3:mini

# Configure as service
sudo systemctl enable ollama
sudo systemctl start ollama
```

---

## Multi-Cloud Setup

### DNS Configuration

```
blackroad.io          → Cloudflare Pages
api.blackroad.io      → Cloudflare Workers
app.blackroad.io      → Vercel
gpu.blackroad.io      → Railway
edge.blackroad.io     → DigitalOcean
```

### Load Balancing

```yaml
# Cloudflare load balancer config
pools:
  - name: api-pool
    origins:
      - address: railway-api.blackroad.io
        weight: 0.7
      - address: vercel-api.blackroad.io
        weight: 0.3
    monitor: /health

steering_policy: random
```

### Failover Configuration

```
Primary:   Railway (GPU services)
Secondary: DigitalOcean (fallback)
Edge:      Cloudflare Workers (always)
```

---

## Monitoring & Observability

### Health Checks

```bash
# Run infrastructure mesh check
./blackroad-mesh.sh

# Check specific service
./blackroad-mesh.sh --service railway

# Output as JSON
./blackroad-mesh.sh --json
```

### Logging

```bash
# Cloudflare logs
wrangler tail

# Railway logs
railway logs -f

# Vercel logs
vercel logs production

# DigitalOcean logs
ssh root@159.65.43.12 "journalctl -u blackroad -f"
```

### Metrics

```bash
# Check Prometheus metrics
curl http://localhost:9090/metrics

# Grafana dashboards
open http://localhost:3001
```

---

## Rollback Procedures

### Cloudflare Rollback

```bash
# List deployments
wrangler deployments list

# Rollback to previous
wrangler rollback
```

### Railway Rollback

```bash
# List deployments
railway deployments

# Rollback
railway rollback
```

### Vercel Rollback

```bash
# List deployments
vercel list

# Promote previous deployment
vercel promote <deployment-url>
```

### Emergency Procedures

```bash
# Kill switch - disable all services
./emergency-stop.sh

# Restart all services
./emergency-restart.sh

# Contact on-call
./alert.sh critical "Emergency: All services down"
```

---

## Quick Reference

### Deploy All

```bash
# Deploy everything
./deploy.sh all

# Deploy specific target
./deploy.sh cloudflare
./deploy.sh railway
./deploy.sh vercel
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Wrangler auth failed | `wrangler login` |
| Railway timeout | Increase healthcheck timeout |
| Vercel build failed | Check build logs |
| Pi offline | Check network/power |

---

*Last updated: 2026-02-05*
