#!/bin/zsh
# BR Tunnel - Cloudflare Tunnel Manager

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

CF_TOKEN=$(cat ~/.wrangler/config/default.toml 2>/dev/null | grep oauth_token | head -1 | sed "s/.*= *'//" | sed "s/'.*//")
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"
TUNNELS=(
  "0447556b-9f07-4506-ab03-0440731d3656:aria64"
  "52915859-da18-4aa6-add5-7bd9fcac2e0b:alice"
)

show_help() {
  echo -e "${CYAN}${BOLD}BR Tunnel — Cloudflare Tunnel Manager${NC}"
  echo ""
  echo "  br tunnel list        List all tunnels"
  echo "  br tunnel status      Check tunnel status via CF API"
  echo "  br tunnel domains     Show domains per tunnel"
}

cmd_list() {
  echo -e "${CYAN}${BOLD}Cloudflare Tunnels${NC}\n"
  for T in "${TUNNELS[@]}"; do
    ID="${T%%:*}"
    NAME="${T##*:}"
    echo -e "  ${CYAN}$NAME${NC}"
    echo -e "    ID: $ID"
  done
}

cmd_status() {
  echo -e "${CYAN}${BOLD}Tunnel Status (CF API)${NC}\n"
  if [[ -z "$CF_TOKEN" ]]; then
    echo -e "${RED}No CF token found${NC}"
    return 1
  fi
  for T in "${TUNNELS[@]}"; do
    ID="${T%%:*}"
    NAME="${T##*:}"
    RESULT=$(curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$ID" \
      -H "Authorization: Bearer $CF_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin).get('result',{})
print(d.get('status','unknown'))
" 2>/dev/null)
    if [[ "$RESULT" == "healthy" ]]; then
      echo -e "  ${GREEN}● $NAME${NC} — $RESULT"
    else
      echo -e "  ${YELLOW}● $NAME${NC} — ${RESULT:-unknown}"
    fi
  done
}

cmd_domains() {
  echo -e "${CYAN}${BOLD}Tunnel Domain Routes${NC}\n"
  echo -e "${CYAN}aria64 (0447556b...)${NC}"
  echo -e "  octavia.blackroad.io → :3000"
  echo -e "  api-octavia.blackroad.io → :8000"
  echo -e "  agents.blackroad.io → :3000"
  echo -e "  nodes.blackroad.io → :3000"
  echo -e "  ssh-octavia.blackroad.io → ssh:22"
  
  echo -e "\n${CYAN}alice (52915859...)${NC}"
  echo -e "  ops.blackroad.io → :8011"
  echo -e "  cluster.blackroad.io → :80"
  echo -e "  headscale.blackroad.io → :8000"
  echo -e "  alice.blackroad.io → :8011"
  echo -e "  fleet.blackroad.io → :8011"
  echo -e "  pi.blackroad.systems → :80"
}

case "${1:-help}" in
  list)    cmd_list ;;
  status)  cmd_status ;;
  domains) cmd_domains ;;
  *)       show_help ;;
esac
