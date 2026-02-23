#!/bin/zsh
# BR Session - Workspace State Manager  v2
SESSION_HOME="${HOME}/.blackroad/sessions"

AMBER='\033[38;5;214m'; VIOLET='\033[38;5;135m'; GREEN='\033[0;32m'
RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

mkdir -p "$SESSION_HOME"

save_session() {
    local name=${1:-$(date +%Y%m%d-%H%M)}
    local session_file="${SESSION_HOME}/${name}.session"
    local branch; branch=$(git branch --show-current 2>/dev/null || echo 'none')
    local changed; changed=$(git status --short 2>/dev/null | wc -l | tr -d ' ')

    cat > "$session_file" <<EOF
{
  "name": "$name",
  "timestamp": $(date +%s),
  "dir": "$(pwd)",
  "branch": "$branch",
  "changed": $changed
}
EOF
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR SESSION${NC}  ${DIM}saved${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo -e "  ${BOLD}name${NC}    $name"
    echo -e "  ${BOLD}dir${NC}     $(pwd)"
    echo -e "  ${BOLD}branch${NC}  $branch  ${DIM}($changed changed)${NC}"
    echo -e "  ${DIM}→  br session restore $name${NC}"
    echo ""
}

list_sessions() {
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR SESSION${NC}  ${DIM}saved workspaces${NC}"
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
    echo ""
    local count=0
    for file in "$SESSION_HOME"/*.session; do
        [[ ! -f "$file" ]] && continue
        ((count++))
        local name; name=$(basename "$file" .session)
        local dir; dir=$(python3 -c "import json,sys; d=json.load(open('$file')); print(d.get('dir','?'))" 2>/dev/null || echo "?")
        local branch; branch=$(python3 -c "import json,sys; d=json.load(open('$file')); print(d.get('branch','?'))" 2>/dev/null || echo "?")
        local ts; ts=$(python3 -c "import json,sys; d=json.load(open('$file')); print(d.get('timestamp',0))" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}${BOLD}${name}${NC}"
        echo -e "  ${DIM}$dir  [$branch]${NC}"
        echo ""
    done
    [[ $count -eq 0 ]] && echo -e "  ${DIM}No sessions yet.  br session save <name>${NC}" || echo -e "  ${DIM}total: $count${NC}"
    echo ""
}

restore_session() {
    local name=$1
    local session_file="${SESSION_HOME}/${name}.session"
    if [[ ! -f "$session_file" ]]; then
        echo -e "  ${RED}✗${NC} Session not found: $name"; return 1
    fi
    local dir; dir=$(python3 -c "import json; d=json.load(open('$session_file')); print(d['dir'])" 2>/dev/null)
    local branch; branch=$(python3 -c "import json; d=json.load(open('$session_file')); print(d['branch'])" 2>/dev/null)
    echo ""
    echo -e "  ${AMBER}${BOLD}◆ BR SESSION${NC}  ${DIM}restoring $name${NC}"
    cd "$dir" 2>/dev/null && echo -e "  ${GREEN}✓${NC} cd $dir"
    [[ "$branch" != "none" ]] && git checkout "$branch" 2>/dev/null && echo -e "  ${GREEN}✓${NC} branch $branch"
    echo -e "  ${GREEN}✓${NC} session restored"
    echo ""
}

show_help() {
    echo ""
    echo -e "  ${AMBER}${BOLD}BR SESSION${NC}  ${DIM}workspace state manager${NC}"
    echo ""
    echo -e "  ${BOLD}br session${NC}              ${DIM}list saved sessions${NC}"
    echo -e "  ${BOLD}br session save <name>${NC}  ${DIM}snapshot current workspace${NC}"
    echo -e "  ${BOLD}br session restore <n>${NC}  ${DIM}restore dir + branch${NC}"
    echo ""
}

case ${1:-list} in
    save|s)           save_session "$2" ;;
    restore|r|load)   restore_session "$2" ;;
    list|l|ls|"")     list_sessions ;;
    help|-h|--help)   show_help ;;
    *)                list_sessions ;;
esac
