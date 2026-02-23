#!/bin/zsh
# BR Worker - Cloudflare Worker Management

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

CF_API="https://api.cloudflare.com/client/v4"
CF_ACCOUNT="${CLOUDFLARE_ACCOUNT_ID:-848cf0b18d51e0170e0d1537aec3505a}"

KNOWN_WORKERS=(
  blackroad-os-core blackroad-os-dashboard blackroad-os-metaverse
  blackroad-os-pitstop blackroad-os-roadworld blackroad-os-landing-worker
  tools-api agents-api roadgateway command-center
  worlds-blackroadio api-blackroadio ai-blackroadio analytics-blackroadio
  agents-blackroadio docs-blackroadio blog-blackroadio search-blackroadio
)

show_help() {
  echo -e "${CYAN}${BOLD}BR Worker{{NC}"
  echo "  br worker list           List known workers"
  echo "  br worker status         Check worker endpoints"
  echo "  br worker deploy <name>  Deploy a worker (requires wrangler)"
  echo "  br worker logs <name>    Tail worker logs (requires wrangler)"
  echo "  br worker tail <name>    Alias for logs"
}

cmd_list() {
  echo -e "${CYAN}Known CF Workers{{NC}\n"
  for W in "${KNOWN_WORKERS[@]}"; do
    echo -e "  ${YELLOW}●{{NC} $W"
  done
  echo -e "\n  ${YELLOW}${#KNOWN_WORKERS[@]} workers registered{{NC}"
}

cmd_status() {
  echo -e "${CYAN}Worker Status Check{{NC}\n"
  ENDPOINTS=(
    "worlds.blackroad.io"
    "api.blackroad.io"
    "ai.blackroad.io"
    "agents.blackroad.io"
    "analytics.blackroad.io"
    "docs.blackroad.io"
    "search.blackroad.io"
    "console.blackroad.io"
  )
  OK=0; FAIL=0
  for E in "${ENDPOINTS[@]}"; do
    CODE=$(curl -s -m 5 -o /dev/null -w "%{http_code}" "https://$E" 2>/dev/null)
    if [[ "$CODE" =~ ^2|^3 ]]; then
      echo -e "  ${GREEN}● $E{{NC} — $CODE"
      ((OK++))
    else
      echo -e "  ${RED}● $E{{NC} — ${CODE:-timeout}"
      ((FAIL++))
    fi
  done
  echo -e "\n  ${YELLOW}$OK up / $FAIL down{{NC}"
}

cmd_deploy() {
  local NAME="$1"
  if [[ -z "$NAME" ]]; then
    echo -e "${RED}Usage: br worker deploy <worker-name>{{NC}"
    exit 1
  fi
  if ! command -v wrangler &>/dev/null; then
    echo -e "${RED}wrangler not found. Install: npm install -g wrangler{{NC}"
    exit 1
  fi
  WORKER_DIR=$(find /Users/alexa/blackroad -name "wrangler.toml" -maxdepth 4 2>/dev/null | \
    xargs -I{} dirname {} | grep -i "$NAME" | head -1)
  if [[ -n "$WORKER_DIR" ]]; then
    echo -e "${CYAN}Deploying $NAME from $WORKER_DIR{{NC}"
    cd "$WORKER_DIR" && wrangler deploy
  else
    echo -e "${YELLOW}Worker directory not found for: $NAME{{NC}"
    echo "Try: cd <worker-dir> && wrangler deploy"
  fi
}

cmd_logs() {
  local NAME="$1"
  if [[ -z "$NAME" ]]; then
    echo -e "${RED}Usage: br worker logs <worker-name>{{NC}"
    exit 1
  fi
  if ! command -v wrangler &>/dev/null; then
    echo -e "${RED}wrangler not found. Install: npm install -g wrangler{{NC}"
    exit 1
  fi
  echo -e "${CYAN}Tailing logs for: $NAME{{NC}"
  wrangler tail "$NAME" 2>/dev/null || echo -e "${RED}Failed to tail $NAME{{NC}"
}

case "${1:-help}" in
  list)    cmd_list ;;
  status)  cmd_status ;;
  deploy)  cmd_deploy "$2" ;;
  logs|tail) cmd_logs "$2" ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1{{NC}"
    show_help ;;
esac
