#!/bin/zsh
# BR STATUS-LIVE — Live platform status
export PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
GRAY='\033[0;37m'; BOLD='\033[1m'; NC='\033[0m'

check_url() {
  local name="$1" url="$2"
  local start; start=$(/usr/bin/python3 -c "import time; print(int(time.time()*1000))")
  local code; code=$(/usr/bin/curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
  local end; end=$(/usr/bin/python3 -c "import time; print(int(time.time()*1000))")
  local ms=$(( end - start ))

  if [[ "$code" -ge 200 && "$code" -lt 400 ]]; then
    printf "  ${GREEN}●${NC} %-40s ${GREEN}%s${NC} %sms\n" "$name" "$code" "$ms"
  elif [[ "$code" -eq 0 || -z "$code" ]]; then
    printf "  ${RED}●${NC} %-40s ${RED}TIMEOUT${NC}\n" "$name"
  else
    printf "  ${YELLOW}●${NC} %-40s ${YELLOW}%s${NC} %sms\n" "$name" "$code" "$ms"
  fi
}

cmd_all() {
  echo -e "\n${CYAN}${BOLD}  BLACKROAD OS — LIVE STATUS${NC}\n"
  echo -e "  ${GRAY}Workers${NC}"
  check_url "blackroad-status worker"    "https://blackroad-status.amundsonalexa.workers.dev/api/ping"
  check_url "blackroad-auth worker"      "https://blackroad-auth.amundsonalexa.workers.dev/auth/status"
  check_url "blackroad-email worker"     "https://blackroad-email.amundsonalexa.workers.dev/"
  check_url "agents-status worker"       "https://agents-status.blackroad.io/"

  echo -e "\n  ${GRAY}Web apps${NC}"
  check_url "blackroad-os-web (Vercel)"  "https://blackroad-os-web.vercel.app/"
  check_url "blackroad.io"               "https://blackroad.io/"
  check_url "blackroadai.com"            "https://blackroadai.com/"

  echo -e "\n  ${GRAY}Pi nodes${NC}"
  check_url "aria64 (192.168.4.38)"      "http://192.168.4.38:8080/health"
  check_url "blackroad-pi (192.168.4.64)" "http://192.168.4.64:8080/health"
  check_url "alice (192.168.4.49)"       "http://192.168.4.49:8080/health"

  echo -e "\n  ${GRAY}APIs${NC}"
  check_url "CF API"                     "https://api.cloudflare.com/client/v4/user/tokens/verify"
  check_url "GitHub API"                 "https://api.github.com/orgs/BlackRoad-OS-Inc"

  local ts; ts=$(date "+%H:%M:%S")
  echo -e "\n  ${GRAY}Checked at $ts${NC}\n"
}

cmd_workers() {
  echo -e "\n${CYAN}  Workers status${NC}\n"
  check_url "blackroad-status"   "https://blackroad-status.amundsonalexa.workers.dev/api/ping"
  check_url "blackroad-auth"     "https://blackroad-auth.amundsonalexa.workers.dev/auth/status"
  check_url "blackroad-email"    "https://blackroad-email.amundsonalexa.workers.dev/"
  check_url "agents-status"      "https://agents-status.blackroad.io/"
  echo ""
}

cmd_pi() {
  echo -e "\n${CYAN}  Pi fleet status${NC}\n"
  check_url "aria64"        "http://192.168.4.38:8080/health"
  check_url "blackroad-pi"  "http://192.168.4.64:8080/health"
  check_url "alice"         "http://192.168.4.49:8080/health"
  echo ""
}

show_help() {
  echo -e "\n${BOLD}  BR STATUS${NC}  Live platform health\n"
  echo -e "  ${CYAN}br status all${NC}       Check everything"
  echo -e "  ${CYAN}br status workers${NC}   CF Workers only"
  echo -e "  ${CYAN}br status pi${NC}        Pi fleet only"
  echo ""
}

case "$1" in
  all|"")    cmd_all ;;
  workers)   cmd_workers ;;
  pi|fleet)  cmd_pi ;;
  *)         show_help ;;
esac
