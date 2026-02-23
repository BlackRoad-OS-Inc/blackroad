#!/bin/zsh
# BR Domains — Route all BlackRoad domains to Pi fleet via Cloudflare tunnel
# Usage: br domains [route|failover|status|update]

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

TUNNEL_ID="${CLOUDFLARE_TUNNEL_ID:-52915859-da18-4aa6-add5-7bd9fcac2e0b}"
CF_ACCOUNT="${CLOUDFLARE_ACCOUNT_ID:-848cf0b18d51e0170e0d1537aec3505a}"
CF_TOKEN="${CLOUDFLARE_API_TOKEN:-}"
PI_PRIMARY="192.168.4.38"    # octavia
PI_SECONDARY="192.168.4.82"  # aria
DO_FALLBACK="159.65.43.12"   # gematria

# Domains to route to Pi fleet
DOMAINS=(
  "blackroad.io" "api.blackroad.io" "agents.blackroad.io" "docs.blackroad.io"
  "dashboard.blackroad.io" "console.blackroad.io" "ai.blackroad.io"
  "blackroad.ai" "api.blackroad.ai" "agents.blackroad.ai"
  "blackroad.network" "blackroad.systems" "blackroad.me"
  "lucidia.earth" "lucidia.studio"
)

cmd_status() {
  echo -e "${CYAN}═══ Domain Fleet Status ══════════════════════${NC}"
  echo -e "${CYAN}Cloudflare Tunnel: ${YELLOW}$TUNNEL_ID${NC}"
  echo ""
  for domain in "${DOMAINS[@]}"; do
    IP=$(dig +short "$domain" 2>/dev/null | head -1)
    if [ -n "$IP" ]; then
      echo -e "${GREEN}✅ $domain${NC} → $IP"
    else
      echo -e "${YELLOW}⚠️  $domain${NC} → not resolving"
    fi
  done
}

cmd_route() {
  echo -e "${CYAN}🌐 Routing domains to Pi fleet via Cloudflare tunnel...${NC}"
  if [ -z "$CF_TOKEN" ]; then
    echo -e "${RED}✗ CLOUDFLARE_API_TOKEN not set${NC}"
    echo -e "${YELLOW}  export CLOUDFLARE_API_TOKEN=your_token${NC}"
    echo ""
    echo -e "${CYAN}Manual steps:${NC}"
    echo "1. Go to Cloudflare → Zero Trust → Networks → Tunnels"
    echo "2. Select tunnel: $TUNNEL_ID"
    echo "3. Add public hostnames:"
    for domain in "${DOMAINS[@]}"; do
      echo "   $domain → http://localhost:80"
    done
    return 1
  fi
  
  # Generate cloudflared tunnel config
  local config_file="$HOME/.cloudflared/config.yml"
  mkdir -p "$HOME/.cloudflared"
  cat > "$config_file" << CFCONFIG
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/${TUNNEL_ID}.json

ingress:
  # API endpoints
  - hostname: api.blackroad.io
    service: http://localhost:8787
  - hostname: api.blackroad.ai
    service: http://localhost:8787
  - hostname: agents.blackroad.io
    service: http://localhost:4010
  - hostname: agents.blackroad.ai
    service: http://localhost:4010
  # Docs / Web
  - hostname: docs.blackroad.io
    service: http://localhost:3001
  - hostname: dashboard.blackroad.io
    service: http://localhost:3000
  - hostname: console.blackroad.io
    service: http://localhost:3000
  # Wildcard blackroad.io → nginx
  - hostname: "*.blackroad.io"
    service: http://localhost:80
  - hostname: "*.blackroad.ai"
    service: http://localhost:80
  - hostname: blackroad.network
    service: http://localhost:80
  - hostname: blackroad.systems
    service: http://localhost:80
  - hostname: blackroad.me
    service: http://localhost:80
  - hostname: lucidia.earth
    service: http://localhost:80
  - hostname: lucidia.studio
    service: http://localhost:80
  # Fallback
  - service: http_status:404
CFCONFIG
  
  echo -e "${GREEN}✅ Tunnel config written to $config_file${NC}"
  echo -e "${CYAN}   Deploy: ${NC}ssh octavia 'sudo cp ~/.cloudflared/config.yml /etc/cloudflared/ && sudo systemctl restart cloudflared'"
  
  # Push config to octavia (Cloudflare tunnel runs there)
  scp "$config_file" octavia:/tmp/cloudflared-config.yml 2>/dev/null && \
    ssh octavia "mkdir -p ~/.cloudflared && cp /tmp/cloudflared-config.yml ~/.cloudflared/config.yml && echo '✅ Tunnel config deployed to octavia'" 2>/dev/null || \
    echo -e "${YELLOW}⚠️  Manual: copy $config_file to octavia:~/.cloudflared/config.yml${NC}"
}

cmd_failover() {
  echo -e "${CYAN}🔄 4-Layer Failover Architecture${NC}"
  echo ""
  echo "Layer 1: Pi fleet (self-hosted, free)"
  echo "  Primary:    octavia ($PI_PRIMARY:80)"
  echo "  Secondary:  aria    ($PI_SECONDARY:80)"
  echo ""
  echo "Layer 2: DigitalOcean droplet"
  echo "  Fallback:   gematria ($DO_FALLBACK:80)"
  echo ""
  echo "Layer 3: Cloudflare Pages (static fallback)"
  echo "  Auto-deployed via .github/workflows/deploy-cloudflare.yml"
  echo ""
  echo "Layer 4: GitHub Pages"
  echo "  Auto-deployed via GitHub Actions on push to main"
  echo ""
  echo -e "${CYAN}Health Check URLs:${NC}"
  echo "  Pi:          http://$PI_PRIMARY/health"
  echo "  DO:          http://$DO_FALLBACK/health"
  echo "  Cloudflare:  https://blackroad.io/health"
  echo ""
  echo -e "${CYAN}Nginx failover rule (already in infra/nginx/nginx.conf):${NC}"
  echo "  error_page 502 503 504 @do_fallback → $DO_FALLBACK"
}

cmd_update() {
  local domain="$1"
  local target="$2"
  if [ -z "$domain" ] || [ -z "$target" ]; then
    echo "Usage: br domains update <domain> <target>"
    echo "Example: br domains update api.blackroad.io http://localhost:8787"
    return 1
  fi
  echo -e "${CYAN}Updating $domain → $target${NC}"
  # Update cloudflared config
  if grep -q "$domain" "$HOME/.cloudflared/config.yml" 2>/dev/null; then
    sed -i.bak "s|hostname: $domain.*|hostname: $domain\n    service: $target|" "$HOME/.cloudflared/config.yml"
    echo -e "${GREEN}✅ Updated${NC}"
  else
    echo -e "${YELLOW}Domain not found in config — adding...${NC}"
    cmd_route
  fi
}

show_help() {
  echo -e "${CYAN}BR Domains — Self-Hosted Domain Router${NC}"
  echo ""
  echo "Commands:"
  echo "  status    — Check all domain DNS resolution"
  echo "  route     — Generate Cloudflare tunnel config + deploy"
  echo "  failover  — Show 4-layer failover architecture"
  echo "  update    — Update a domain's routing target"
  echo ""
  echo "Environment:"
  echo "  CLOUDFLARE_API_TOKEN  — CF API token (required for route)"
  echo "  CLOUDFLARE_TUNNEL_ID  — Tunnel ID (default: $TUNNEL_ID)"
}

case "${1:-help}" in
  status)   cmd_status ;;
  route)    cmd_route ;;
  failover) cmd_failover ;;
  update)   cmd_update "$2" "$3" ;;
  *)        show_help ;;
esac
