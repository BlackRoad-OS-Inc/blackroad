#!/bin/zsh
# BR Status - Full Platform Status

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'
NC='\033[0m'; BOLD='\033[1m'

WORKERS=(worlds verify studio docs blog api analytics search nodes portal status console)
PI_DOMAINS=(octavia.blackroad.io ops.blackroad.io)

show_help() {
  echo -e "${CYAN}${BOLD}BR Status${NC}"
  echo "  br status          Full platform status"
  echo "  br status workers  Check CF workers only"
  echo "  br status pi       Check Pi nodes only"
  echo "  br status git      Show git status"
  echo "  br status tools    Count installed tools"
}

cmd_full() {
  echo -e "${PURPLE}${BOLD}╔══════════════════════════════╗${NC}"
  echo -e "${PURPLE}${BOLD}║   BlackRoad Platform Status   ║${NC}"
  echo -e "${PURPLE}${BOLD}╚══════════════════════════════╝${NC}\n"

  echo -e "${CYAN}Gateway${NC}"
  GW=$(curl -s -m 3 http://127.0.0.1:8787/health 2>/dev/null)
  if [[ -n "$GW" ]]; then
    echo -e "  ${GREEN}● gateway:8787${NC} — online"
  else
    echo -e "  ${RED}● gateway:8787${NC} — offline"
  fi

  echo -e "\n${CYAN}Pi Nodes${NC}"
  for DOMAIN in "${PI_DOMAINS[@]}"; do
    RESULT=$(curl -s -m 5 "https://$DOMAIN/health" 2>/dev/null)
    if [[ -n "$RESULT" ]]; then
      echo -e "  ${GREEN}●${NC} $DOMAIN — online"
    else
      echo -e "  ${RED}●${NC} $DOMAIN — offline"
    fi
  done

  echo -e "\n${CYAN}CF Workers${NC}"
  OK=0; FAIL=0
  for W in "${WORKERS[@]}"; do
    CODE=$(curl -s -m 4 -o /dev/null -w "%{http_code}" "https://$W.blackroad.io/health" 2>/dev/null)
    if [[ "$CODE" == "200" ]]; then
      echo -e "  ${GREEN}●${NC} $W.blackroad.io"
      ((OK++))
    else
      echo -e "  ${RED}●${NC} $W.blackroad.io (${CODE:-timeout})"
      ((FAIL++))
    fi
  done
  echo -e "\n  ${YELLOW}$OK online / $FAIL offline${NC}"

  echo -e "\n${CYAN}CLI Tools${NC}"
  TOOL_COUNT=$(ls /Users/alexa/blackroad/tools/ 2>/dev/null | wc -l | tr -d ' ')
  echo -e "  ${GREEN}●${NC} $TOOL_COUNT tools installed"

  echo -e "\n${CYAN}Git${NC}"
  cd /Users/alexa/blackroad
  BRANCH=$(git branch --show-current 2>/dev/null)
  LAST=$(git --no-pager log --oneline -1 2>/dev/null)
  echo -e "  Branch: ${YELLOW}$BRANCH${NC}"
  echo -e "  Last: $LAST"
}

cmd_workers() {
  echo -e "${CYAN}CF Workers${NC}"
  for W in "${WORKERS[@]}"; do
    CODE=$(curl -s -m 4 -o /dev/null -w "%{http_code}" "https://$W.blackroad.io/health" 2>/dev/null)
    if [[ "$CODE" == "200" ]]; then
      echo -e "  ${GREEN}● $W.blackroad.io${NC} — $CODE"
    else
      echo -e "  ${RED}● $W.blackroad.io${NC} — ${CODE:-timeout}"
    fi
  done
}

cmd_pi() {
  echo -e "${CYAN}Pi Nodes${NC}"
  for DOMAIN in "${PI_DOMAINS[@]}"; do
    RESULT=$(curl -s -m 5 "https://$DOMAIN/health" 2>/dev/null)
    if [[ -n "$RESULT" ]]; then
      echo -e "  ${GREEN}● $DOMAIN${NC} — online"
    else
      echo -e "  ${RED}● $DOMAIN${NC} — offline"
    fi
  done
}

cmd_git() {
  cd /Users/alexa/blackroad
  BRANCH=$(git branch --show-current 2>/dev/null)
  UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  LAST=$(git --no-pager log --oneline -1 2>/dev/null)
  echo -e "${CYAN}Git Status${NC}"
  echo -e "  Branch:      ${YELLOW}$BRANCH${NC}"
  echo -e "  Uncommitted: ${YELLOW}$UNCOMMITTED${NC} files"
  echo -e "  Last commit: $LAST"
}

cmd_tools() {
  TOOL_COUNT=$(ls /Users/alexa/blackroad/tools/ 2>/dev/null | wc -l | tr -d ' ')
  echo -e "${CYAN}CLI Tools${NC}"
  echo -e "  ${GREEN}$TOOL_COUNT${NC} tools installed"
  ls /Users/alexa/blackroad/tools/ 2>/dev/null | column
}

case "${1:-full}" in
  full|"") cmd_full ;;
  workers) cmd_workers ;;
  pi)      cmd_pi ;;
  git)     cmd_git ;;
  tools)   cmd_tools ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    show_help ;;
esac
