#!/bin/zsh
# BR RAILWAY PI - Deploy Railway services from Pi fleet
# Extends br railway with Pi-native deployment

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Use railway binary from npm-global or system PATH
RAILWAY_BIN="${HOME}/npm-global/bin/railway"
command -v railway &>/dev/null && RAILWAY_BIN="railway"
test -f "$RAILWAY_BIN" || { echo -e "${RED}❌ railway CLI not found${NC}"; exit 1; }

case "$1" in
  status)
    echo -e "${CYAN}Railway services:${NC}"
    $RAILWAY_BIN status 2>/dev/null || echo "Not authenticated. Run: railway login"
    ;;
  deploy)
    SERVICE="${2:-}"
    echo -e "${CYAN}Deploying ${SERVICE:-all} to Railway...${NC}"
    if [[ -n "$SERVICE" ]]; then
      $RAILWAY_BIN up --service "$SERVICE"
    else
      $RAILWAY_BIN up
    fi
    ;;
  logs)
    $RAILWAY_BIN logs "${2:---all}"
    ;;
  migrate-to-pi)
    echo -e "${CYAN}Migrating Railway service to Pi fleet...${NC}"
    echo "1. Stop Railway service: railway down"
    echo "2. Export env vars: railway variables"  
    echo "3. Deploy to Pi: br pi deploy"
    echo "4. Update Cloudflare tunnel to point to Pi"
    ;;
  help|*)
    echo "br railway pi [status|deploy <service>|logs|migrate-to-pi]"
    ;;
esac
