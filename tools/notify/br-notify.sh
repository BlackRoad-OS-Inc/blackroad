#!/bin/zsh
# BR Notify - Multi-channel notifications
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'

SHARED="/Users/alexa/blackroad/shared"
EMAIL_WORKER="https://blackroad-email.blackroad.workers.dev"

cmd_mesh() {
  local msg="$*"
  [[ -z "$msg" ]] && { echo -e "${RED}Usage: br notify mesh <message>${NC}"; exit 1; }
  local ts=$(date +%s)
  local file="${SHARED}/mesh/queue/notify-${ts}.json"
  mkdir -p "${SHARED}/mesh/queue"
  cat > "$file" << MSGEOF
{
  "protocol": "BRAT-RELAY-v1",
  "id": "notify-${ts}",
  "from": "BR_NOTIFY",
  "to": "all",
  "subject": "Notification",
  "message": "${msg}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
MSGEOF
  echo -e "${GREEN}✓ Broadcast to agent mesh${NC}: $msg"
}

cmd_email() {
  local msg="$*"
  [[ -z "$msg" ]] && { echo -e "${RED}Usage: br notify email <message>${NC}"; exit 1; }
  local token=""
  [[ -f ~/.blackroad/settings.json ]] && token=$(python3 -c "import json,sys; d=json.load(open('$HOME/.blackroad/settings.json')); print(d.get('emailToken',''))" 2>/dev/null)
  
  if [[ -n "$token" ]]; then
    curl -s -X POST "$EMAIL_WORKER/send" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d "{\"subject\":\"BlackRoad Notification\",\"text\":\"$msg\"}" > /dev/null
    echo -e "${GREEN}✓ Email sent${NC}: $msg"
  else
    echo -e "${YELLOW}⚠ No email token set. Message logged to mesh instead.${NC}"
    cmd_mesh "$msg"
  fi
}

cmd_mac() {
  local msg="$*"
  [[ -z "$msg" ]] && { echo -e "${RED}Usage: br notify mac <message>${NC}"; exit 1; }
  if command -v osascript &>/dev/null; then
    osascript -e "display notification \"$msg\" with title \"BlackRoad OS\""
    echo -e "${GREEN}✓ macOS notification sent${NC}"
  else
    echo -e "${YELLOW}osascript not available${NC}"
  fi
}

cmd_all() {
  local msg="$*"
  [[ -z "$msg" ]] && { echo -e "${RED}Usage: br notify all <message>${NC}"; exit 1; }
  echo -e "${CYAN}${BOLD}Broadcasting to all channels…${NC}"
  cmd_mesh "$msg"
  cmd_mac "$msg"
  echo -e "${GREEN}✓ Done${NC}"
}

show_help() {
  echo -e "${CYAN}${BOLD}BR Notify — Multi-channel Notifications${NC}\n"
  echo -e "  ${GREEN}br notify mesh <msg>${NC}   Broadcast to agent mesh"
  echo -e "  ${GREEN}br notify email <msg>${NC}  Send via email worker"
  echo -e "  ${GREEN}br notify mac <msg>${NC}    macOS notification"
  echo -e "  ${GREEN}br notify all <msg>${NC}    All channels"
}

case "${1:-help}" in
  mesh|agents) shift; cmd_mesh "$@" ;;
  email|mail) shift; cmd_email "$@" ;;
  mac|osx|desktop) shift; cmd_mac "$@" ;;
  all) shift; cmd_all "$@" ;;
  *) show_help ;;
esac
