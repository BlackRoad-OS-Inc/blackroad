# Lucidia.earth Deployment Architecture

## Infrastructure Overview

### Current State
- **aria64 (192.168.4.64)**: Main web server hosting all BlackRoad sites
  - Running Caddy reverse proxy (ports 80/443)
  - 20+ Next.js containers on ports 3000-3031
  - Portainer for container management
- **lucidia (192.168.4.38)**: Available Pi (needs Docker permissions)
- **shellfish (174.138.44.45)**: DigitalOcean droplet with Caddy + LLM service
- **DNS**: Currently all domains proxied through Cloudflare

### Deployment Strategy: Direct to aria64

**Why aria64:**
- Already hosting all BlackRoad infrastructure
- Caddy reverse proxy configured and working
- Proven stable (2+ days uptime with 20+ containers)
- Port 3040 available for lucidia.earth

**Architecture:**
```
User Request (lucidia.earth)
    ↓
DNS (A record → 192.168.4.64 OR keep Cloudflare proxy)
    ↓
Caddy on aria64:80/443
    ↓
lucidia-earth container on aria64:3040
    ↓
Next.js app (standalone build)
```

## Deployment Pipeline

### Build Process
```
Local Development
    ↓ git push
GitHub (BlackRoad-OS/lucidia-earth)
    ↓ git pull on aria64
Docker Build on aria64
    ↓
Docker Container (lucidia-earth:latest)
    ↓ mapped to
Port 3040 on aria64
```

### Container Configuration
```dockerfile
# Dockerfile for lucidia.earth
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]
```

### Caddy Configuration Addition
```caddyfile
lucidia.earth, www.lucidia.earth {
    reverse_proxy localhost:3040
}

# Future subdomains
app.lucidia.earth {
    reverse_proxy localhost:3041
}

tube.lucidia.earth {
    reverse_proxy localhost:3042
}

studio.lucidia.earth {
    reverse_proxy localhost:3043
}
```

### DNS Configuration Options

**Option 1: Direct (No Cloudflare Proxy)**
```
Type: A
Name: @
Content: 192.168.4.64
Proxy: OFF (DNS only)
TTL: Auto

Type: A
Name: www
Content: 192.168.4.64
Proxy: OFF (DNS only)
TTL: Auto
```

**Option 2: Keep Cloudflare Proxy (Recommended for Security)**
```
Type: A
Name: @
Content: 192.168.4.64
Proxy: ON (Proxied through Cloudflare)
TTL: Auto

Type: A
Name: www
Content: 192.168.4.64
Proxy: ON (Proxied through Cloudflare)
TTL: Auto
```

**Recommendation:** Use Option 2 (Cloudflare proxy ON) for:
- DDoS protection
- Free SSL/TLS
- Caching and performance
- Hide origin IP
- But traffic still goes directly to your Pi (Cloudflare just proxies)

## Deployment Steps

### 1. Create Repository
```bash
cd ~/projects
mkdir lucidia-earth
cd lucidia-earth
git init
# (create Next.js app structure)
gh repo create BlackRoad-OS/lucidia-earth --public
git remote add origin git@github.com:BlackRoad-OS/lucidia-earth.git
git add .
git commit -m "Initial commit: Lucidia.earth website"
git push -u origin main
```

### 2. Deploy to aria64
```bash
# SSH to aria64
ssh aria64

# Clone repo
cd /opt/blackroad-deploy
git clone https://github.com/BlackRoad-OS/lucidia-earth.git
cd lucidia-earth

# Build Docker image
docker build -t lucidia-earth:latest .

# Run container
docker run -d \
  --name lucidia-earth \
  --restart unless-stopped \
  -p 3040:3000 \
  lucidia-earth:latest

# Verify
docker ps | grep lucidia
curl -I localhost:3040
```

### 3. Update Caddy
```bash
# SSH to aria64
ssh aria64

# Backup current config
docker exec caddy cat /etc/caddy/Caddyfile > ~/Caddyfile.backup

# Add lucidia.earth config
docker exec caddy sh -c 'cat >> /etc/caddy/Caddyfile << EOF

lucidia.earth, www.lucidia.earth {
    reverse_proxy localhost:3040
}
EOF'

# Reload Caddy
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### 4. Update DNS
- Login to Cloudflare
- Navigate to lucidia.earth zone
- Add/update A records to point to 192.168.4.64
- Keep proxy ON for security
- Wait for DNS propagation (5-30 minutes)

### 5. Verify Deployment
```bash
# Check DNS
dig +short lucidia.earth

# Test HTTP
curl -I http://lucidia.earth

# Test HTTPS
curl -I https://lucidia.earth

# Check container logs
ssh aria64 "docker logs lucidia-earth"
```

## Update/Rebuild Process

```bash
# SSH to aria64
ssh aria64
cd /opt/blackroad-deploy/lucidia-earth

# Pull latest changes
git pull origin main

# Rebuild image
docker build -t lucidia-earth:latest .

# Stop and remove old container
docker stop lucidia-earth
docker rm lucidia-earth

# Start new container
docker run -d \
  --name lucidia-earth \
  --restart unless-stopped \
  -p 3040:3000 \
  lucidia-earth:latest

# Verify
docker ps | grep lucidia
curl -I localhost:3040
```

## Monitoring

### Check Container Status
```bash
ssh aria64 "docker ps | grep lucidia"
```

### View Logs
```bash
ssh aria64 "docker logs -f lucidia-earth"
```

### Resource Usage
```bash
ssh aria64 "docker stats lucidia-earth --no-stream"
```

### Caddy Status
```bash
ssh aria64 "docker logs caddy | tail -50"
```

## Backup Strategy

### Code
- Primary: GitHub repository (BlackRoad-OS/lucidia-earth)
- Local: ~/projects/lucidia-earth

### Container Images
```bash
# Save image to tar
ssh aria64 "docker save lucidia-earth:latest | gzip > ~/backups/lucidia-earth-$(date +%Y%m%d).tar.gz"

# Copy to local
scp aria64:~/backups/lucidia-earth-*.tar.gz ~/blackroad-backup/
```

### Caddy Configuration
```bash
# Backup before changes
ssh aria64 "docker exec caddy cat /etc/caddy/Caddyfile > ~/Caddyfile.$(date +%Y%m%d)"
```

## Rollback Plan

### If deployment fails:
```bash
# Stop new container
ssh aria64 "docker stop lucidia-earth && docker rm lucidia-earth"

# Restore previous image (if saved)
ssh aria64 "docker load < ~/backups/lucidia-earth-YYYYMMDD.tar.gz"

# Start previous version
ssh aria64 "docker run -d --name lucidia-earth --restart unless-stopped -p 3040:3000 lucidia-earth:previous"
```

### If Caddy config breaks:
```bash
# Restore backup
ssh aria64 "cat ~/Caddyfile.backup | docker exec -i caddy tee /etc/caddy/Caddyfile"
ssh aria64 "docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
```

## Security Notes

- **Cloudflare Proxy**: Keeps origin IP hidden, provides DDoS protection
- **Caddy**: Handles automatic HTTPS via Let's Encrypt
- **Docker**: Isolated container environment
- **Firewall**: Ensure aria64 firewall allows 80/443 from Cloudflare IPs only
- **Updates**: Regular `docker pull node:20-alpine` for base image updates

## Performance Optimization

- **Next.js Standalone Build**: Minimal runtime dependencies
- **Static Asset Caching**: Caddy caches static files
- **Cloudflare CDN**: Caches at edge when proxy is ON
- **Image Optimization**: Use Next.js Image component
- **Code Splitting**: Automatic with Next.js App Router

## Port Allocation

| Service | Port | Status |
|---------|------|--------|
| lucidia.earth | 3040 | Reserved |
| app.lucidia.earth | 3041 | Reserved (future) |
| tube.lucidia.earth | 3042 | Reserved (future) |
| studio.lucidia.earth | 3043 | Reserved (future) |

## Future Considerations

### High Availability
- If traffic grows, add load balancing
- Deploy to shellfish droplet as backup
- Use Cloudflare Load Balancing between aria64 and shellfish

### Scaling
- Currently: Single container on aria64
- Phase 2: Add replica on lucidia Pi (192.168.4.38)
- Phase 3: Add replica on shellfish droplet
- Use Caddy load balancing or Cloudflare health checks

### Monitoring
- Add health check endpoint: /api/health
- Monitor with Uptime Robot or Cloudflare Workers
- Set up alerts for container restarts

---

**Target Timeline:**
- Repository setup: Today
- Next.js build: Dec 23-24
- Deployment to aria64: Dec 26
- DNS update: Dec 27
- Public launch: January 5, 2026
