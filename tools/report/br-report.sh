#!/bin/zsh
# BR Report - Generate system status report

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; PURPLE='\033[0;35m'; NC='\033[0m'

show_help() {
  echo "${CYAN}BR Report${NC}"
  echo "  br report daily   - Daily system report"
  echo "  br report git     - Git activity report"
  echo "  br report tools   - Installed br tools"
}

cmd_daily() {
  local ts=$(date "+%Y-%m-%d %H:%M")
  echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo "${PURPLE}  BlackRoad Daily Report — ${ts}${NC}"
  echo "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  echo ""
  echo "${CYAN}System:${NC}"
  echo "  OS:       $(uname -s) $(uname -r)"
  echo "  Uptime:   $(uptime | awk -F'up' '{print $2}' | awk -F',' '{print $1}' | xargs)"
  echo "  Disk:     $(df -h / | tail -1 | awk '{print $3 " used / " $2 " total (" $5 " used)"}')"
  
  echo ""
  echo "${CYAN}Git (last 24h):${NC}"
  local commits=$(git --no-pager log --since="24 hours ago" --oneline 2>/dev/null | wc -l | xargs)
  echo "  Commits:  ${commits}"
  git --no-pager log --since="24 hours ago" --oneline 2>/dev/null | head -5 | sed 's/^/  /'
  
  echo ""
  echo "${CYAN}BR Tools:${NC}"
  local tool_count=$(ls /Users/alexa/blackroad/tools/*/br-*.sh 2>/dev/null | wc -l | xargs)
  echo "  Installed: ${tool_count} tools"
  
  echo ""
  echo "${CYAN}Live Services:${NC}"
  for svc in "worlds.blackroad.io/health" "analytics.blackroad.io/health" "verify.blackroad.io/health"; do
    local ok=$(curl -s --max-time 3 "https://${svc}" 2>/dev/null | grep -c '"ok"' || echo "0")
    [[ "$ok" -gt 0 ]] && echo "  ${GREEN}✓${NC} ${svc%%/*}" || echo "  ${RED}✗${NC} ${svc%%/*}"
  done
}

cmd_git() {
  echo "${PURPLE}━━━ Git Activity Report ━━━${NC}"
  echo "${CYAN}Recent commits:${NC}"
  git --no-pager log --oneline -20 2>/dev/null | sed 's/^/  /'
  echo ""
  echo "${CYAN}Modified files (last 7 days):${NC}"
  git --no-pager log --since="7 days ago" --name-only --pretty=format: 2>/dev/null | sort | uniq -c | sort -rn | head -10 | sed 's/^/  /'
}

cmd_tools() {
  echo "${PURPLE}━━━ BR Tools Inventory ━━━${NC}"
  for f in /Users/alexa/blackroad/tools/*/br-*.sh; do
    local name=$(basename "$f" .sh | sed 's/br-//')
    local desc=$(head -3 "$f" | grep "# BR" | sed 's/# BR //' | sed 's/ -.*//' || echo "")
    printf "  ${CYAN}br %-20s${NC} %s\n" "$name" "$desc"
  done
}

case "$1" in
  daily|"")   cmd_daily ;;
  git)        cmd_git ;;
  tools)      cmd_tools ;;
  help|--help) show_help ;;
  *)          show_help ;;
esac
