#!/bin/zsh
# BR Ping — check live endpoints quickly

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

ENDPOINTS=(
  "worlds.blackroad.io/stats"
  "dashboard-api.blackroad.io/health"
  "agents-status.blackroad.io/status"
  "gateway.blackroad.io/health"
  "api.blackroad.io/health"
  "models.blackroad.io/health"
)

check_url() {
  local url="$1"
  local start=$(date +%s%3N)
  local code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 "https://$url" 2>/dev/null)
  local end=$(date +%s%3N)
  local ms=$((end - start))
  if [[ "$code" == "200" ]]; then
    printf "  ${GREEN}✓${NC} %-45s ${GREEN}%s${NC} ${CYAN}%dms${NC}\n" "$url" "$code" "$ms"
  elif [[ "$code" == "000" ]]; then
    printf "  ${RED}✗${NC} %-45s ${RED}timeout${NC}\n" "$url"
  else
    printf "  ${YELLOW}~${NC} %-45s ${YELLOW}%s${NC} ${CYAN}%dms${NC}\n" "$url" "$code" "$ms"
  fi
}

cmd_all() {
  echo -e "${CYAN}🏓 Pinging BlackRoad endpoints...${NC}\n"
  for ep in "${ENDPOINTS[@]}"; do
    check_url "$ep" &
  done
  # Add custom endpoints from args
  for ep in "${@:2}"; do
    check_url "$ep" &
  done
  wait
  echo ""
  # worlds stats
  local stats=$(curl -sf --max-time 5 "https://worlds.blackroad.io/stats" 2>/dev/null)
  if [[ -n "$stats" ]]; then
    local total=$(echo "$stats" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('total',0))" 2>/dev/null)
    echo -e "  ${CYAN}🌍${NC} worlds.blackroad.io: ${GREEN}${total} worlds${NC}"
  fi
}

cmd_pi() {
  echo -e "${CYAN}🍓 Pinging Pi fleet...${NC}\n"
  local pis=("alexa@192.168.4.38:aria64" "blackroad@192.168.4.49:alice" "pi@192.168.4.99:blackroad-pi")
  for entry in "${pis[@]}"; do
    local user_host="${entry%%:*}"
    local name="${entry##*:}"
    local result=$(ssh -o ConnectTimeout=4 -o StrictHostKeyChecking=no "$user_host" "echo ok" 2>/dev/null)
    if [[ "$result" == "ok" ]]; then
      local worlds=$(ssh -o ConnectTimeout=4 "$user_host" "ls ~/.blackroad/worlds/ 2>/dev/null | wc -l | tr -d ' '" 2>/dev/null)
      local cpu=$(ssh -o ConnectTimeout=4 "$user_host" "top -bn1 | grep 'Cpu' | awk '{print \$2}' | head -1" 2>/dev/null || echo "?")
      printf "  ${GREEN}✓${NC} %-15s %s worlds, CPU: %s%%\n" "$name" "$worlds" "$cpu"
    else
      printf "  ${RED}✗${NC} %-15s unreachable\n" "$name"
    fi
  done
}

show_help() {
  echo -e "${CYAN}BR Ping${NC}"
  echo "  br ping           Check all live CF workers"
  echo "  br ping pi        Check Pi fleet"
  echo "  br ping <url>     Check specific URL"
}

case "${1:-all}" in
  pi|fleet|pis) cmd_pi ;;
  all|"")       cmd_all "$@" ;;
  help)         show_help ;;
  *)            
    echo -e "${CYAN}Checking $1...${NC}"
    check_url "$1"
    ;;
esac
