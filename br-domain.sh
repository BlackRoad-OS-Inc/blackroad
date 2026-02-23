#!/bin/zsh
# BR Domain - Domain and DNS Management

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

BLACKROAD_DOMAINS=(
  blackroad.io blackroad.ai blackroad.network blackroad.systems
  blackroad.me blackroad.inc lucidia.earth lucidia.studio
)

show_help() {
  echo -e "${CYAN}${BOLD}BR Domain${NC}"
  echo "  br domain list           List all domains"
  echo "  br domain check <domain> Check DNS for a domain"
  echo "  br domain live           Check which domains are live"
  echo "  br domain whois <domain> WHOIS lookup"
  echo "  br domain workers        List CF worker subdomain routes"
}

cmd_list() {
  echo -e "${CYAN}BlackRoad Domains{{NC}"
  for D in "${BLACKROAD_DOMAINS[@]}"; do
    echo -e "  ${GREEN}●{{NC} $D"
  done
}

cmd_check() {
  local DOMAIN="${1:-blackroad.io}"
  echo -e "${CYAN}DNS Check: $DOMAIN{{NC}\n"
  echo -e "${YELLOW}A Records:{{NC}"
  dig +short A "$DOMAIN" 2>/dev/null | while read LINE; do
    echo "  $LINE"
  done
  echo -e "${YELLOW}AAAA Records:{{NC}"
  dig +short AAAA "$DOMAIN" 2>/dev/null | while read LINE; do
    echo "  $LINE"
  done
  echo -e "${YELLOW}NS Records:{{NC}"
  dig +short NS "$DOMAIN" 2>/dev/null | while read LINE; do
    echo "  $LINE"
  done
  echo -e "${YELLOW}MX Records:{{NC}"
  dig +short MX "$DOMAIN" 2>/dev/null | while read LINE; do
    echo "  $LINE"
  done
}

cmd_live() {
  echo -e "${CYAN}Live Domain Check{{NC}\n"
  OK=0; FAIL=0
  for D in "${BLACKROAD_DOMAINS[@]}"; do
    CODE=$(curl -s -m 5 -o /dev/null -w "%{http_code}" "https://$D" 2>/dev/null)
    if [[ "$CODE" =~ ^2|^3 ]]; then
      echo -e "  ${GREEN}● $D{{NC} — $CODE"
      ((OK++))
    else
      echo -e "  ${RED}● $D{{NC} — ${CODE:-timeout}"
      ((FAIL++))
    fi
  done
  echo -e "\n  ${YELLOW}$OK live / $FAIL down{{NC}"
}

cmd_whois() {
  local DOMAIN="${1:-blackroad.io}"
  if command -v whois &>/dev/null; then
    whois "$DOMAIN" 2>/dev/null | head -30
  else
    echo -e "${YELLOW}whois not installed{{NC}"
    dig +short "$DOMAIN"
  fi
}

cmd_workers() {
  echo -e "${CYAN}CF Worker Subdomains (blackroad.io){{NC}\n"
  SUBS=(worlds verify studio docs blog api analytics search nodes portal status console admin agents ai cdn data dev demo)
  for S in "${SUBS[@]}"; do
    CODE=$(curl -s -m 3 -o /dev/null -w "%{http_code}" "https://$S.blackroad.io" 2>/dev/null)
    if [[ "$CODE" =~ ^2|^3 ]]; then
      echo -e "  ${GREEN}● $S.blackroad.io{{NC} — $CODE"
    else
      echo -e "  ${RED}● $S.blackroad.io{{NC} — ${CODE:-timeout}"
    fi
  done
}

case "${1:-help}" in
  list)    cmd_list ;;
  check)   cmd_check "$2" ;;
  live)    cmd_live ;;
  whois)   cmd_whois "$2" ;;
  workers) cmd_workers ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1{{NC}"
    show_help ;;
esac
