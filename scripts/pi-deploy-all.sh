#!/bin/bash
# BLACKROAD PI DEPLOY ALL
# Deploys everything to the Pi fleet from a single command
# Usage: bash scripts/pi-deploy-all.sh [--dry-run]

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
DRY="${1:-}"

log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}▶${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }

info "BLACKROAD PI DEPLOY — Full Stack"
echo "   Pis: cecilia alice aria octavia"
echo "   Targets: nginx domains, cloudflare tunnel, Pi agents"
echo ""

# ── 1. NGINX DOMAIN CONFIGS ────────────────────────────────────────────────
info "Deploying nginx domain configs..."

DOMAINS_ALICE=("blackroad.io" "blackroad.company" "blackroadinc.us" "aliceqi.com" "blackroad.me")
DOMAINS_CECILIA=("blackroad.network" "blackroad.systems" "blackroadai.com" "blackboxprogramming.io" "roadcoin.io")
DOMAINS_ARIA=("lucidia.earth" "lucidiaqi.com" "lucidia.studio")
DOMAINS_OCTAVIA=("blackroadquantum.com" "blackroadqi.com" "roadchain.io")

gen_vhost() {
  local domain="$1" port="$2"
  cat << NGINX
server {
    listen 80;
    server_name $domain www.$domain;
    root /var/www/$domain;
    index index.html;
    location /health { return 200 '{"ok":true,"host":"$domain"}'; add_header Content-Type application/json; }
    location / { try_files \$uri \$uri/ /index.html =404; }
    server_tokens off;
    add_header X-BR-Node "\$hostname";
}
NGINX
}

gen_landing() {
  local domain="$1"
  cat << HTML
<!DOCTYPE html><html><head><meta charset=utf-8><title>${domain} — BlackRoad OS</title>
<meta name=viewport content="width=device-width,initial-scale=1">
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;color:#fff;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh}
.c{text-align:center;padding:2rem}.logo{font-size:3rem;background:linear-gradient(135deg,#F5A623,#FF1D6C,#9C27B0,#2979FF);-webkit-background-clip:text;-webkit-text-fill-color:transparent;font-weight:900;margin-bottom:1rem}
.domain{color:#888;font-size:1.2rem;letter-spacing:.1em}a{color:#F5A623;text-decoration:none}</style></head>
<body><div class=c><div class=logo>⚡ BlackRoad OS</div>
<div class=domain>${domain}</div>
<p style="color:#555;margin-top:1rem;font-size:.9rem">Self-hosted on Pi fleet</p></div></body></html>
HTML
}

deploy_domains_to_pi() {
  local pi="$1"
  shift
  local domains=("$@")
  
  [[ "$DRY" == "--dry-run" ]] && { echo "  [dry] would deploy ${#domains[@]} domains to $pi"; return; }
  
  for domain in "${domains[@]}"; do
    ssh -o ConnectTimeout=8 -o BatchMode=yes "$pi" bash -s << REMOTE 2>/dev/null &
      sudo mkdir -p /var/www/$domain
      echo '$(gen_landing "$domain")' | sudo tee /var/www/$domain/index.html > /dev/null
      echo '$(gen_vhost "$domain" 80)' | sudo tee /etc/nginx/sites-available/$domain > /dev/null
      sudo ln -sf /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain 2>/dev/null || true
      echo "  [$pi] $domain configured"
REMOTE
  done
  wait
  
  # Reload nginx once
  ssh -o ConnectTimeout=8 -o BatchMode=yes "$pi" "sudo nginx -t 2>&1 | tail -1 && sudo systemctl reload nginx 2>/dev/null || sudo service nginx reload 2>/dev/null" 2>/dev/null
  log "$pi: ${#domains[@]} domains deployed"
}

deploy_domains_to_pi alice    "${DOMAINS_ALICE[@]}" &
deploy_domains_to_pi cecilia  "${DOMAINS_CECILIA[@]}" &
deploy_domains_to_pi aria     "${DOMAINS_ARIA[@]}" &
deploy_domains_to_pi octavia  "${DOMAINS_OCTAVIA[@]}" &
wait

log "All domains deployed to Pi fleet!"
echo ""

# ── 2. SUMMARY ──────────────────────────────────────────────────────────────
echo "Backup tiers:"
echo "  Tier 1: Pi fleet (self-hosted) — primary"
echo "  Tier 2: DigitalOcean (gematria 159.65.43.12) — backup"
echo "  Tier 3: Cloudflare Pages — static fallback"
echo "  Tier 4: GitHub Pages — emergency"
echo "  Tier 5: Railway — full-app fallback"
