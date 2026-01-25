# Cloudflare Tunnel Setup Guide

## Overview
Use Cloudflare Tunnel to expose your deployment infrastructure (DigitalOcean + Raspberry Pi) without opening ports.

## Setup on DigitalOcean Droplet (159.65.43.12)

### 1. Install cloudflared
```bash
ssh root@159.65.43.12

# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared
```

### 2. Authenticate with Cloudflare
```bash
# This will open browser for auth
cloudflared tunnel login
```

### 3. Create Tunnel
```bash
# Create tunnel
cloudflared tunnel create blackroad-deploy

# This creates:
# - Tunnel credentials in ~/.cloudflared/<TUNNEL-ID>.json
# - Tunnel registered in your Cloudflare account
```

### 4. Configure Tunnel
Create `/root/.cloudflared/config.yml`:

```yaml
tunnel: <TUNNEL-ID>
credentials-file: /root/.cloudflared/<TUNNEL-ID>.json

ingress:
  # Deployment API
  - hostname: deploy-api.blackroad.systems
    service: http://localhost:3000

  # Deployed apps (dynamic routing via Caddy)
  - hostname: "*.blackroad.systems"
    service: http://localhost:8080

  # Catch-all
  - service: http_status:404
```

### 5. Route DNS
```bash
# Route DNS to tunnel
cloudflared tunnel route dns blackroad-deploy deploy-api.blackroad.systems
cloudflared tunnel route dns blackroad-deploy *.blackroad.systems
```

### 6. Run Tunnel as Service
```bash
# Install as systemd service
cloudflared service install

# Start tunnel
systemctl start cloudflared
systemctl enable cloudflared

# Check status
systemctl status cloudflared
```

## Setup on Raspberry Pi (192.168.4.49)

### 1. Install cloudflared
```bash
ssh alice@192.168.4.49  # or pi@192.168.4.49

# For ARM64
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o ~/cloudflared
chmod +x ~/cloudflared
sudo mv ~/cloudflared /usr/local/bin/

# For ARM32
# curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm -o ~/cloudflared
```

### 2. Create Pi Tunnel
```bash
cloudflared tunnel login
cloudflared tunnel create blackroad-pi
```

### 3. Configure Pi Tunnel
Create `~/.cloudflared/config.yml`:

```yaml
tunnel: <PI-TUNNEL-ID>
credentials-file: /home/alice/.cloudflared/<PI-TUNNEL-ID>.json

ingress:
  # Pi-hosted services
  - hostname: pi.blackroad.systems
    service: http://localhost:3000

  - hostname: "*.pi.blackroad.systems"
    service: http://localhost:8080

  - service: http_status:404
```

### 4. Route DNS
```bash
cloudflared tunnel route dns blackroad-pi pi.blackroad.systems
cloudflared tunnel route dns blackroad-pi *.pi.blackroad.systems
```

### 5. Run as Service
```bash
cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

## Using Your Credentials

Your Cloudflare credentials from CLAUDE.md:
```bash
CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
CF_ZONE='848cf0b18d51e0170e0d1537aec3505a'
TUNNEL_ID='72f1d60c-dcf2-4499-b02d-d7a063018b33'
```

## Automated Script

Create `setup-tunnel.sh`:

```bash
#!/bin/bash

CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
CF_ZONE='848cf0b18d51e0170e0d1537aec3505a'
TUNNEL_ID='72f1d60c-dcf2-4499-b02d-d7a063018b33'

# Add DNS record
echo "☁️ Adding DNS record for deploy-api.blackroad.systems"
cloudflared tunnel route dns $TUNNEL_ID deploy-api.blackroad.systems

# Start tunnel
echo "🚀 Starting tunnel..."
cloudflared service install
systemctl start cloudflared
systemctl status cloudflared
```

## Verification

```bash
# Check tunnel status
cloudflared tunnel info blackroad-deploy

# List all tunnels
cloudflared tunnel list

# Test connectivity
curl https://deploy-api.blackroad.systems/health
```

## Benefits

✅ **No Port Forwarding**: Works behind NAT/firewall
✅ **Automatic HTTPS**: Cloudflare handles SSL
✅ **DDoS Protection**: Cloudflare's network
✅ **Zero Trust**: Can add access policies
✅ **Works Anywhere**: Even on cellular/mobile networks
✅ **Free**: No cost for tunnels

## Next Steps

1. Set up tunnel on DigitalOcean droplet
2. Set up tunnel on Raspberry Pi
3. Configure Caddy for reverse proxy
4. Deploy API service
5. Test end-to-end deployment
