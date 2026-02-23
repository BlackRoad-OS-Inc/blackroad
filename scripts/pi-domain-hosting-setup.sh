#!/bin/bash
# Self-hosted domain setup on Pi fleet
# Primary: octavia (192.168.4.38) via Cloudflare Tunnel
# Failover chain: DigitalOcean → Cloudflare Pages → Railway → GitHub Pages

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}ℹ️${NC} $1"; }

TARGET=${1:-octavia}

case $TARGET in
  octavia)
    info "Setting up nginx on octavia as primary domain host..."
    ssh octavia << 'REMOTE'
      set -e
      # Install nginx if needed
      sudo apt-get install -y nginx 2>/dev/null || true
      
      # Create wildcard vhost for *.blackroad.io → local services
      sudo tee /etc/nginx/sites-available/blackroad << 'NGINX'
# BlackRoad OS — Wildcard Domain Config
# All *.blackroad.io routes through this Pi via Cloudflare Tunnel

server {
    listen 80 default_server;
    server_name *.blackroad.io blackroad.io;
    
    # Route by subdomain
    location / {
        # Default: serve static from /var/www/blackroad
        root /var/www/blackroad;
        try_files $uri $uri/ @proxy;
    }
    
    location @proxy {
        # Proxy to local services by subdomain
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Agent endpoints
server {
    listen 80;
    server_name agents.blackroad.io api.blackroad.io;
    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_set_header Host $host;
    }
}
NGINX
      
      sudo ln -sf /etc/nginx/sites-available/blackroad /etc/nginx/sites-enabled/
      sudo mkdir -p /var/www/blackroad
      sudo nginx -t && sudo systemctl reload nginx
      echo "nginx configured on octavia"
REMOTE
    log "octavia nginx configured"
    ;;
    
  failover)
    info "Setting up failover chain..."
    # DigitalOcean backup
    ssh gematria "sudo apt-get install -y nginx && echo 'nginx ready on gematria'"
    log "DigitalOcean (gematria) ready as failover"
    ;;
esac

log "Domain hosting setup complete on $TARGET"
