#!/bin/zsh
# BR Session - Workspace State Manager
SESSION_HOME="/Users/alexa/blackroad/tools/session-manager"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

mkdir -p "$SESSION_HOME"

save_session() {
    local name=${1:-$(date +%Y%m%d-%H%M)}
    local session_file="${SESSION_HOME}/${name}.session"
    
    echo -e "${BLUE}💾 Saving session: ${name}${NC}\n"
    
    cat > "$session_file" <<EOF
{
  "name": "$name",
  "timestamp": $(date +%s),
  "dir": "$(pwd)",
  "branch": "$(git branch --show-current 2>/dev/null || echo 'none')",
  "files": $(git status --short 2>/dev/null | wc -l | tr -d ' ')
}
EOF
    
    echo -e "${GREEN}✓ Session saved: $name${NC}"
    echo "  Directory: $(pwd)"
    echo "  Branch: $(git branch --show-current 2>/dev/null || echo 'none')"
}

list_sessions() {
    echo -e "${CYAN}📚 Saved Sessions:${NC}\n"
    for file in "$SESSION_HOME"/*.session; do
        [[ ! -f "$file" ]] && continue
        local name=$(basename "$file" .session)
        local dir=$(jq -r '.dir' "$file" 2>/dev/null || echo "?")
        local branch=$(jq -r '.branch' "$file" 2>/dev/null || echo "?")
        echo -e "${GREEN}• $name${NC}"
        echo "  $dir ($branch)"
    done
}

restore_session() {
    local name=$1
    local session_file="${SESSION_HOME}/${name}.session"
    
    if [[ ! -f "$session_file" ]]; then
        echo -e "${RED}Session not found: $name${NC}"
        return 1
    fi
    
    local dir=$(jq -r '.dir' "$session_file")
    local branch=$(jq -r '.branch' "$session_file")
    
    echo -e "${BLUE}🔄 Restoring session: ${name}${NC}\n"
    cd "$dir" 2>/dev/null && echo "  ✓ Changed to: $dir"
    [[ "$branch" != "none" ]] && git checkout "$branch" 2>/dev/null && echo "  ✓ Checked out: $branch"
    echo -e "\n${GREEN}✓ Session restored${NC}"
}

case ${1:-list} in
    save|s) save_session "$2" ;;
    restore|r|load) restore_session "$2" ;;
    list|l|ls) list_sessions ;;
    *) list_sessions ;;
esac
