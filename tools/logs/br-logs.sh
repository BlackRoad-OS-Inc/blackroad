#!/bin/zsh
# BR Logs - Log viewer and analyzer

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

show_help() {
  echo "${CYAN}BR Logs${NC}"
  echo "  br logs gateway     - Gateway server logs"
  echo "  br logs git         - Git operation log"
  echo "  br logs memory      - PS-SHA memory journal"
  echo "  br logs errors      - Error log across tools"
  echo "  br logs tail [file] - Tail any log file"
}

LOG_DIR="$HOME/.blackroad"
GW_LOG="$LOG_DIR/gateway.log"
MEM_JOURNAL="$LOG_DIR/gateway-memory/journal.jsonl"

cmd_gateway() {
  [[ -f "$GW_LOG" ]] && tail -50 "$GW_LOG" | sed "s/ERROR/${RED}ERROR${NC}/g; s/WARN/${YELLOW}WARN${NC}/g; s/INFO/${GREEN}INFO${NC}/g" || echo "${YELLOW}No gateway log at $GW_LOG${NC}"
}

cmd_git() {
  echo "${CYAN}Recent git operations:${NC}"
  git --no-pager reflog --date=relative 2>/dev/null | head -30 | sed 's/^/  /' || echo "${RED}Not a git repo${NC}"
}

cmd_memory() {
  [[ ! -f "$MEM_JOURNAL" ]] && { echo "${YELLOW}Memory journal not found${NC}"; return; }
  echo "${CYAN}PS-SHA∞ Memory Journal (last 20):${NC}"
  tail -20 "$MEM_JOURNAL" | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        e = json.loads(line.strip())
        ts = e.get('timestamp','')[:19]
        action = e.get('action','?')
        entity = e.get('entity','')
        print(f'  {ts}  {action:<20} {entity}')
    except: pass
"
}

cmd_errors() {
  echo "${RED}Error log:${NC}"
  find "$LOG_DIR" -name "*.log" 2>/dev/null | xargs grep -h "ERROR\|error\|Error" 2>/dev/null | tail -30 | sed 's/^/  /'
}

cmd_tail() {
  local f="${2:-$GW_LOG}"
  [[ -f "$f" ]] && tail -f "$f" || echo "${RED}File not found: $f${NC}"
}

case "$1" in
  gateway) cmd_gateway ;;
  git)     cmd_git ;;
  memory)  cmd_memory ;;
  errors)  cmd_errors ;;
  tail)    cmd_tail "$@" ;;
  help|--help) show_help ;;
  *)       show_help ;;
esac
