#!/bin/bash
# Pi Domain Hosting — Primary on octavia, failover chain
# Run as: ./scripts/pi-domain-hosting-setup.sh [setup|status|failover]
set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

# Failover chain
PRIMARY="octavia"           # Pi5, 192.168.4.38 via CF tunnel
FAILOVER1="gematria"        # DigitalOcean 159.65.43.12
FAILOVER2="anastasia"       # DigitalOcean 174.138.44.45

NGINX_CONF='
# BlackRoad Domain Router — octavia primary
# Handles: *.blackroad.io, *.blackroad.ai, blackroad.network

map $host $backend {
    default                   "http://127.0.0.1:8080";
    "~^api\."                 "http://127.0.0.1:8787";
    "~^agents?\."             "http://127.0.0.1:8787";
    "~^gateway\."             "http://127.0.0.1:8787";
    "~^console\."             "http://127.0.0.1:8090";
    "~^dashboard\."           "http://127.0.0.1:3000";
    "~^grafana\."             "http://127.0.0.1:3001";
    "~^jupyter\."             "http://127.0.0.1:8888";
    "~^ollama\."              "http://127.0.0.1:11434";
    "~^runner\."              "http://127.0.0.1:8081";
}

server {
    listen 80;
    listen [::]:80;
    server_name *.blackroad.io *.blackroad.ai blackroad.network blackroad.systems;

    location /health {
        return 200 "{\"status\":\"ok\",\"host\":\"octavia-pi5\",\"role\":\"primary\",\"ts\":\"$time_iso8601\"}";
        add_header Content-Type application/json;
    }

    location / {
        proxy_pass $backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_connect_timeout 10s;
        proxy_read_timeout 120s;
        proxy_intercept_errors on;
        error_page 502 503 504 = @failover;
    }

    location @failover {
        return 200 "{\"status\":\"starting\",\"message\":\"Agent booting...\"}";
        add_header Content-Type application/json;
    }
}
'

cmd_setup() {
    info "Configuring nginx on $PRIMARY..."
    ssh "$PRIMARY" "
        echo '$NGINX_CONF' | sudo tee /etc/nginx/conf.d/blackroad-domains.conf > /dev/null
        sudo nginx -t && sudo systemctl reload nginx
        echo '✅ nginx domain routing configured'
        
        # Verify CF tunnel is routing *.blackroad.io → localhost:80
        sudo cat /etc/cloudflared/config.yml 2>/dev/null || cat ~/cloudflared/*.yml 2>/dev/null || echo 'checking tunnel config...'
    "
    log "Primary domain hosting configured on $PRIMARY"
    
    info "Configuring nginx failover on $FAILOVER1 (DigitalOcean)..."
    ssh "$FAILOVER1" "
        which nginx || sudo apt-get install -y nginx 2>/dev/null
        echo '$NGINX_CONF' | sudo tee /etc/nginx/conf.d/blackroad-domains.conf > /dev/null
        sudo nginx -t && sudo systemctl enable nginx && sudo systemctl start nginx
        echo '✅ nginx failover configured on gematria'
    " 2>/dev/null && log "Failover 1 (gematria DO) configured" || info "gematria nginx needs sudo - skipping"
}

cmd_status() {
    for host in $PRIMARY $FAILOVER1 $FAILOVER2; do
        RESP=$(ssh -o ConnectTimeout=5 "$host" "curl -s http://localhost/health 2>/dev/null || echo 'no response'" 2>/dev/null)
        echo "  $host: $RESP"
    done
}

cmd_cloudflare_dns() {
    info "Setting up Cloudflare DNS to point to Pi tunnel..."
    # All *.blackroad.io should point to the CF tunnel (already configured)
    # The tunnel handles routing to the Pi automatically
    echo "Cloudflare tunnel handles DNS routing — no changes needed."
    echo "Tunnel: 93a03772-48a1-4eba-8324-87c0f312436e → octavia:80"
}

case "${1:-setup}" in
    setup)   cmd_setup ;;
    status)  cmd_status ;;
    dns)     cmd_cloudflare_dns ;;
    *) echo "Usage: $0 {setup|status|dns}" ;;
esac
