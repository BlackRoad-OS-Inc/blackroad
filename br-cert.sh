#!/bin/zsh
# BR Cert - SSL Certificate Checker

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

BLACKROAD_DOMAINS=(
  blackroad.io blackroad.ai blackroad.network blackroad.systems
  blackroad.me blackroad.inc lucidia.earth lucidia.studio
  api.blackroad.io worlds.blackroad.io agents.blackroad.io
)

show_help() {
  echo -e "${CYAN}${BOLD}BR Cert{{NC}"
  echo "  br cert check <domain>  Check SSL cert for a domain"
  echo "  br cert all             Check all blackroad domains"
  echo "  br cert expiry <domain> Show cert expiry date only"
  echo "  br cert info <domain>   Full cert details"
}

get_expiry() {
  local DOMAIN="$1"
  local PORT="${2:-443}"
  echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:$PORT" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null \
    | cut -d= -f2
}

days_until_expiry() {
  local EXPIRY="$1"
  if [[ -z "$EXPIRY" ]]; then echo "-1"; return; fi
  local EXPIRY_EPOCH
  EXPIRY_EPOCH=$(date -j -f "%b %d %T %Y %Z" "$EXPIRY" +%s 2>/dev/null || \
                 date -d "$EXPIRY" +%s 2>/dev/null)
  local NOW_EPOCH=$(date +%s)
  echo $(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
}

cmd_check() {
  local DOMAIN="${1:-blackroad.io}"
  echo -e "${CYAN}SSL Check: $DOMAIN{{NC}\n"
  EXPIRY=$(get_expiry "$DOMAIN")
  if [[ -z "$EXPIRY" ]]; then
    echo -e "  ${RED}● Could not retrieve certificate{{NC}"
    return
  fi
  DAYS=$(days_until_expiry "$EXPIRY")
  if [[ "$DAYS" -gt 30 ]]; then
    echo -e "  ${GREEN}● Valid{{NC}"
  elif [[ "$DAYS" -gt 7 ]]; then
    echo -e "  ${YELLOW}● Expiring soon{{NC}"
  else
    echo -e "  ${RED}● CRITICAL: Expiring in $DAYS days{{NC}"
  fi
  echo -e "  Expires: $EXPIRY"
  echo -e "  Days left: $DAYS"
}

cmd_all() {
  echo -e "${CYAN}SSL Certificate Check — All Domains{{NC}\n"
  for D in "${BLACKROAD_DOMAINS[@]}"; do
    EXPIRY=$(get_expiry "$D")
    if [[ -z "$EXPIRY" ]]; then
      echo -e "  ${RED}● $D{{NC} — no cert / unreachable"
      continue
    fi
    DAYS=$(days_until_expiry "$EXPIRY")
    if [[ "$DAYS" -gt 30 ]]; then
      echo -e "  ${GREEN}● $D{{NC} — ${DAYS}d left"
    elif [[ "$DAYS" -gt 7 ]]; then
      echo -e "  ${YELLOW}● $D{{NC} — ${DAYS}d left (renew soon)"
    else
      echo -e "  ${RED}● $D{{NC} — ${DAYS}d left (URGENT)"
    fi
  done
}

cmd_expiry() {
  local DOMAIN="${1:-blackroad.io}"
  EXPIRY=$(get_expiry "$DOMAIN")
  [[ -n "$EXPIRY" ]] && echo "$EXPIRY" || echo "Could not retrieve"
}

cmd_info() {
  local DOMAIN="${1:-blackroad.io}"
  echo -e "${CYAN}Cert Info: $DOMAIN{{NC}\n"
  echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null \
    | openssl x509 -noout -text 2>/dev/null \
    | grep -E "Subject:|Issuer:|Not Before|Not After|DNS:" \
    | sed 's/^/  /'
}

case "${1:-help}" in
  check)  cmd_check "$2" ;;
  all)    cmd_all ;;
  expiry) cmd_expiry "$2" ;;
  info)   cmd_info "$2" ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1{{NC}"
    show_help ;;
esac
