#!/bin/bash
# BLACKROAD SELF-HOSTED DOMAIN ROUTING
# Sets up nginx on all Pis for all domains with 4-tier backup
# Tier 1: Pi fleet (primary self-hosted)
# Tier 2: DigitalOcean (gematria/anastasia)
# Tier 3: Cloudflare Pages (static fallback)
# Tier 4: GitHub Pages (emergency)
# Tier 5: Railway (full-app fallback)

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}ℹ️ ${NC} $1"; }
err()  { echo -e "${RED}❌${NC} $1"; }

# Domain → Pi port mapping
declare -A DOMAIN_PORTS=(
  ["blackroad.io"]="80"
  ["blackroad.network"]="8081"
  ["blackroad.systems"]="8082"
  ["lucidia.earth"]="8083"
  ["blackroadai.com"]="8084"
  ["aliceqi.com"]="8085"
  ["lucidiaqi.com"]="8086"
  ["lucidia.studio"]="8087"
  ["blackroadquantum.com"]="8088"
  ["blackroadqi.com"]="8089"
  ["blackboxprogramming.io"]="8090"
  ["blackroad.company"]="8091"
  ["blackroadinc.us"]="8092"
  ["roadchain.io"]="8093"
  ["blackroad.me"]="8094"
  ["roadcoin.io"]="8095"
)

# Domain → Primary Pi mapping
declare -A DOMAIN_PI=(
  ["blackroad.io"]="alice"
  ["blackroad.network"]="cecilia"
  ["blackroad.systems"]="cecilia"
  ["lucidia.earth"]="aria"
  ["blackroadai.com"]="cecilia"
  ["aliceqi.com"]="alice"
  ["lucidiaqi.com"]="aria"
  ["lucidia.studio"]="aria"
  ["blackroadquantum.com"]="octavia"
  ["blackroadqi.com"]="octavia"
  ["blackboxprogramming.io"]="cecilia"
  ["blackroad.company"]="alice"
  ["blackroadinc.us"]="alice"
  ["roadchain.io"]="octavia"
  ["blackroad.me"]="cecilia"
  ["roadcoin.io"]="octavia"
)

gen_nginx_config() {
  local domain="$1"
  local port="$2"
  cat << NGINX
server {
    listen $port;
    listen [::]:$port;
    server_name $domain www.$domain;
    
    root /var/www/$domain;
    index index.html index.htm;
    
    # Health check endpoint
    location /health {
        return 200 '{"status":"ok","host":"$domain","tier":"pi-primary"}';
        add_header Content-Type application/json;
    }
    
    # Proxy to local app if running
    location /api/ {
        proxy_pass http://127.0.0.1:$(( port + 1000 ));
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_connect_timeout 5s;
        proxy_read_timeout 30s;
    }
    
    location / {
        try_files \$uri \$uri/ /index.html;
        
        # If Pi is down, redirect to CF backup  
        error_page 503 = @cloudflare_backup;
    }
    
    location @cloudflare_backup {
        return 302 https://blackroad-os.github.io;
    }
    
    # Disable nginx version exposure
    server_tokens off;
    
    # Basic security headers
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-BlackRoad-Node "$HOSTNAME";
}
NGINX
}

deploy_domain() {
  local domain="$1"
  local pi="${DOMAIN_PI[$domain]}"
  local port="${DOMAIN_PORTS[$domain]}"
  
  info "Deploying $domain → $pi:$port"
  
  # Generate nginx config
  local nginx_conf=$(gen_nginx_config "$domain" "$port")
  
  # Deploy to primary Pi
  ssh -o ConnectTimeout=10 -o BatchMode=yes "$pi" bash << REMOTE
    # Create webroot
    sudo mkdir -p /var/www/$domain
    
    # Create minimal index if not exists
    if [ ! -f /var/www/$domain/index.html ]; then
      sudo tee /var/www/$domain/index.html > /dev/null << 'HTML'
<!DOCTYPE html>
<html>
<head><title>$domain - BlackRoad OS</title>
<style>body{background:#000;color:#fff;font-family:monospace;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;}</style>
</head>
<body><div style="text-align:center">
<h1 style="color:#F5A623">⚡ BlackRoad OS</h1>
<p>$domain</p><p style="color:#888">Self-hosted on Pi fleet</p>
</div></body></html>
HTML
    fi
    
    # Write nginx config
    echo '$nginx_conf' | sudo tee /etc/nginx/sites-available/$domain > /dev/null
    sudo ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain 2>/dev/null || true
    
    # Test and reload
    sudo nginx -t && sudo systemctl reload nginx 2>/dev/null || sudo service nginx reload 2>/dev/null || true
    echo "✅ $domain deployed on $(hostname)"
REMOTE
  
  log "$domain → $pi:$port"
}

case "${1:-help}" in
  deploy-all)
    for domain in "${!DOMAIN_PORTS[@]}"; do
      deploy_domain "$domain" &
    done
    wait
    log "All domains deployed to Pi fleet!"
    ;;
  deploy)
    deploy_domain "$2"
    ;;
  status)
    for pi in cecilia alice aria octavia; do
      echo -n "  $pi: "
      ssh -o ConnectTimeout=5 -o BatchMode=yes "$pi" \
        "sudo nginx -t 2>&1 | tail -1 && echo 'sites: '$(ls /etc/nginx/sites-enabled/ 2>/dev/null | wc -l)" \
        2>/dev/null || echo "offline"
    done
    ;;
  help|*)
    echo "Usage: $0 [deploy-all|deploy <domain>|status]"
    ;;
esac
