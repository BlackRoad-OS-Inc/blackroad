#!/usr/bin/env bash
# setup-pi-domains.sh — Run this ON the Pi to wire up carpool.blackroad.io + br.blackroad.io
# Usage: bash setup-pi-domains.sh
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
REPO_DIR="${REPO_DIR:-$HOME/blackroad}"
TUNNEL_ID="52915859-da18-4aa6-add5-7bd9fcac2e0b"
CLOUDFLARED_CONFIG="/etc/cloudflared/config.yml"
CARPOOL_PORT=4040
BR_PORT=4041
# Target Pi: alice (192.168.4.49) — this is where the CF tunnel runs

log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
echo "🚗  CarPool + BR Domain Setup for BlackRoad Pi"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Pull latest repo
info "Pulling latest from BlackRoad repo..."
cd "$REPO_DIR" && git pull --ff-only origin master
log "Repo up to date"

# 2. Start carpool web server (systemd service)
info "Setting up CarPool web server on port $CARPOOL_PORT..."
sudo tee /etc/systemd/system/carpool-server.service > /dev/null <<EOF
[Unit]
Description=CarPool Web Server — carpool.blackroad.io
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=$REPO_DIR/blackroad-web/carpool-server
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5s
Environment=CARPOOL_PORT=$CARPOOL_PORT
Environment=CARPOOL_SH=$REPO_DIR/carpool.sh
Environment=CARPOOL_MODEL=tinyllama

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable carpool-server
sudo systemctl restart carpool-server
log "CarPool server running on port $CARPOOL_PORT"

# 3. Serve br-landing on port 4041 with a simple static server
info "Setting up BR landing page on port $BR_PORT..."
sudo tee /etc/systemd/system/br-landing.service > /dev/null <<EOF
[Unit]
Description=BR Landing Page — br.blackroad.io
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=$REPO_DIR/blackroad-web/br-landing
ExecStart=/usr/bin/node -e "require('http').createServer((req,res)=>{require('fs').readFile('index.html',(e,d)=>{res.writeHead(e?404:200,{'Content-Type':'text/html'});res.end(d||'not found')})}).listen($BR_PORT,'0.0.0.0',()=>console.log('BR landing on $BR_PORT'))"
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable br-landing
sudo systemctl restart br-landing
log "BR landing running on port $BR_PORT"

# 4. Update cloudflared tunnel config
info "Updating Cloudflare tunnel config..."
if [ ! -f "$CLOUDFLARED_CONFIG" ]; then
  warn "No config at $CLOUDFLARED_CONFIG — creating..."
  sudo mkdir -p /etc/cloudflared
fi

# Read existing config, inject new routes before the catch-all
TMPCONFIG=$(mktemp)
sudo cat "$CLOUDFLARED_CONFIG" 2>/dev/null > "$TMPCONFIG" || true

# Check if already configured
if grep -q "carpool.blackroad.io" "$TMPCONFIG" 2>/dev/null; then
  warn "carpool.blackroad.io already in tunnel config — skipping"
else
  # Inject before the last catch-all service line
  if grep -q "http_status:404" "$TMPCONFIG"; then
    sudo sed -i "s|  - service: http_status:404|  - hostname: carpool.blackroad.io\n    service: http://localhost:$CARPOOL_PORT\n  - hostname: br.blackroad.io\n    service: http://localhost:$BR_PORT\n  - service: http_status:404|" "$CLOUDFLARED_CONFIG"
  else
    # Append ingress if config exists but has no catch-all
    sudo tee -a "$CLOUDFLARED_CONFIG" >> /dev/null <<EOF

  - hostname: carpool.blackroad.io
    service: http://localhost:$CARPOOL_PORT
  - hostname: br.blackroad.io
    service: http://localhost:$BR_PORT
EOF
  fi
  log "Tunnel config updated"
fi
rm -f "$TMPCONFIG"

# 5. Register DNS routes via cloudflared
info "Registering DNS routes with Cloudflare..."
cloudflared tunnel route dns "$TUNNEL_ID" carpool.blackroad.io 2>/dev/null && log "carpool.blackroad.io DNS registered" || warn "DNS route may already exist for carpool.blackroad.io"
cloudflared tunnel route dns "$TUNNEL_ID" br.blackroad.io 2>/dev/null && log "br.blackroad.io DNS registered" || warn "DNS route may already exist for br.blackroad.io"

# 6. Restart cloudflared
info "Restarting cloudflared tunnel..."
sudo systemctl restart cloudflared
sleep 2
sudo systemctl is-active cloudflared && log "cloudflared restarted OK" || warn "Check: sudo systemctl status cloudflared"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! Domains live in ~30s:"
echo "   🚗 https://carpool.blackroad.io"
echo "   💻 https://br.blackroad.io"
echo ""
