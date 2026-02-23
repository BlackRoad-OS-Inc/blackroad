#!/bin/zsh
# BR Health - Deep Health Check

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

show_help() {
  echo -e "${CYAN}${BOLD}BR Health{{NC}"
  echo "  br health            Full health check"
  echo "  br health gateway    Check gateway health"
  echo "  br health services   Check external services"
  echo "  br health local      Check local system"
  echo "  br health quick      Quick ping all endpoints"
}

check_endpoint() {
  local NAME="$1"
  local URL="$2"
  local START=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo 0)
  local CODE=$(curl -s -m 8 -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null)
  local END=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo 0)
  local MS=$((END - START))
  if [[ "$CODE" =~ ^2 ]]; then
    echo -e "  ${GREEN}●{{NC} $NAME — ${CODE} (${MS}ms)"
  elif [[ "$CODE" =~ ^3 ]]; then
    echo -e "  ${YELLOW}●{{NC} $NAME — ${CODE} redirect (${MS}ms)"
  else
    echo -e "  ${RED}●{{NC} $NAME — ${CODE:-timeout}"
  fi
}

cmd_full() {
  echo -e "${CYAN}${BOLD}╔═══════════════════════════╗{{NC}"
  echo -e "${CYAN}${BOLD}║   BlackRoad Health Check   ║{{NC}"
  echo -e "${CYAN}${BOLD}╚═══════════════════════════╝{{NC}\n"

  echo -e "${CYAN}Local Services{{NC}"
  check_endpoint "Gateway :8787"      "http://127.0.0.1:8787/health"
  check_endpoint "Ollama :11434"      "http://localhost:11434/api/tags"
  check_endpoint "Memory :8001"       "http://localhost:8001/health"

  echo -e "\n${CYAN}BlackRoad Platform{{NC}"
  check_endpoint "worlds.blackroad.io"  "https://worlds.blackroad.io/health"
  check_endpoint "api.blackroad.io"     "https://api.blackroad.io/health"
  check_endpoint "agents.blackroad.io"  "https://agents.blackroad.io/health"

  echo -e "\n${CYAN}External Dependencies{{NC}"
  check_endpoint "GitHub API"           "https://api.github.com"
  check_endpoint "Cloudflare"           "https://cloudflare.com"
  check_endpoint "Railway API"          "https://backboard.railway.app/graphql/v2"

  echo -e "\n${CYAN}System{{NC}"
  local CPU=$(top -l 1 2>/dev/null | awk '/CPU usage/{print $3}' | tr -d '%' || echo "?")
  local DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $5}')
  echo -e "  CPU: ${YELLOW}${CPU}%{{NC}}  Disk: ${YELLOW}${DISK}{{NC}"
}

cmd_gateway() {
  echo -e "${CYAN}Gateway Health{{NC}\n"
  RESULT=$(curl -s -m 5 "http://127.0.0.1:8787/health" 2>/dev/null)
  if [[ -n "$RESULT" ]]; then
    echo -e "  ${GREEN}● Online{{NC}"
    echo "$RESULT" | python3 -m json.tool 2>/dev/null || echo "$RESULT"
  else
    echo -e "  ${RED}● Offline{{NC}"
    echo -e "  Run: ${CYAN}br gateway start{{NC}"
  fi
}

cmd_services() {
  echo -e "${CYAN}External Services{{NC}\n"
  check_endpoint "GitHub API"        "https://api.github.com"
  check_endpoint "Cloudflare API"    "https://api.cloudflare.com/client/v4/user/tokens/verify"
  check_endpoint "Vercel API"        "https://api.vercel.com"
  check_endpoint "Railway API"       "https://backboard.railway.app/graphql/v2"
  check_endpoint "DigitalOcean API"  "https://api.digitalocean.com/v2"
  check_endpoint "Hugging Face"      "https://huggingface.co"
}

cmd_local() {
  echo -e "${CYAN}Local System{{NC}\n"
  echo -e "${YELLOW}Processes:{{NC}"
  for PORT in 8787 11434 8001 3000 8080; do
    PID=$(lsof -ti:$PORT 2>/dev/null)
    if [[ -n "$PID" ]]; then
      PNAME=$(ps -p "$PID" -o comm= 2>/dev/null)
      echo -e "  ${GREEN}●{{NC} :$PORT — $PNAME (PID $PID)"
    else
      echo -e "  ${RED}●{{NC} :$PORT — nothing listening"
    fi
  done

  echo -e "\n${YELLOW}Databases:{{NC}"
  find ~/.blackroad -name "*.db" 2>/dev/null | while read DB; do
    SIZE=$(du -sh "$DB" 2>/dev/null | cut -f1)
    echo -e "  ${GREEN}●{{NC} $(basename $DB) — $SIZE"
  done
}

cmd_quick() {
  ENDPOINTS=(
    "http://127.0.0.1:8787/health"
    "https://blackroad.io"
    "https://api.blackroad.io/health"
    "https://worlds.blackroad.io/health"
  )
  echo -e "${CYAN}Quick Ping{{NC}"
  for URL in "${ENDPOINTS[@]}"; do
    CODE=$(curl -s -m 3 -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null)
    [[ "$CODE" =~ ^2 ]] && echo -e "  ${GREEN}● $URL — $CODE{{NC}" || echo -e "  ${RED}● $URL — ${CODE:-timeout}{{NC}"
  done
}

case "${1:-full}" in
  full|"") cmd_full ;;
  gateway) cmd_gateway ;;
  services) cmd_services ;;
  local)   cmd_local ;;
  quick)   cmd_quick ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1{{NC}"
    show_help ;;
esac
