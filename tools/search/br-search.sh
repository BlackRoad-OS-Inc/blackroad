#!/usr/bin/env zsh
# BR Search — fast cross-repo search across tools, agents, coordination, journal
# br search <query> [--type code|journal|agent|task|all] [--file <glob>]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"

show_help() {
  echo ""
  echo "  ${PINK}${BOLD}br search${NC}  — cross-repo search"
  echo ""
  echo "  ${BOLD}Usage:${NC}"
  echo "    ${CYAN}br search <query>${NC}                  Search everything"
  echo "    ${CYAN}br search <query> --code${NC}           Search tools/, scripts, br"
  echo "    ${CYAN}br search <query> --journal${NC}        Search PS-SHA∞ journal"
  echo "    ${CYAN}br search <query> --agents${NC}         Search agents/, coordination/"
  echo "    ${CYAN}br search <query> --docs${NC}           Search *.md docs"
  echo "    ${CYAN}br search <query> --tasks${NC}          Search task queue + inboxes"
  echo "    ${CYAN}br search <query> --file '*.sh'${NC}    Search specific file glob"
  echo ""
  echo "  ${BOLD}Examples:${NC}"
  echo "    br search 'collab-join'          # Find all collab join references"
  echo "    br search 'spawn' --code         # Find spawn in shell scripts"
  echo "    br search 'deploy' --journal     # Find deploy actions in memory"
  echo ""
}

# ── Section printers ───────────────────────────────────────────────────────────

print_match() {
  local file="$1" line="$2" content="$3" query="$4"
  local short="${file#$BR_ROOT/}"
  local highlighted
  highlighted=$(echo "$content" | sed "s/$query/$(printf '\033[1;33m')&$(printf '\033[0m')/gi" 2>/dev/null || echo "$content")
  printf "  ${CYAN}%-45s${NC} ${DIM}%4s${NC}  %s\n" "$short" "$line" "$highlighted"
}

search_code() {
  local query="$1"
  local dirs=("$BR_ROOT/tools" "$BR_ROOT/scripts" "$BR_ROOT/lib" "$BR_ROOT/br")
  local found=0

  echo "  ${BOLD}${DIM}── CODE${NC}"
  for target in "${dirs[@]}"; do
    [[ ! -e "$target" ]] && continue
    grep -rn --include="*.sh" --include="*.zsh" --include="*.py" --include="*.js" \
      -i "$query" "$target" 2>/dev/null | head -10 | while IFS=: read -r file line content; do
      print_match "$file" "$line" "${content:0:80}" "$query"
      ((found++))
    done
  done
  # Also search the main br file
  if [[ -f "$BR_ROOT/br" ]]; then
    grep -n -i "$query" "$BR_ROOT/br" 2>/dev/null | head -5 | while IFS=: read -r line content; do
      print_match "$BR_ROOT/br" "$line" "${content:0:80}" "$query"
    done
  fi
}

search_agents() {
  local query="$1"
  echo "  ${BOLD}${DIM}── AGENTS / COORDINATION${NC}"
  local dirs=("$BR_ROOT/agents" "$BR_ROOT/coordination" "$BR_ROOT/shared")
  for d in "${dirs[@]}"; do
    [[ ! -d "$d" ]] && continue
    grep -rn -i "$query" "$d" --include="*.json" --include="*.sh" --include="*.txt" 2>/dev/null \
      | head -8 | while IFS=: read -r file line content; do
      print_match "$file" "$line" "${content:0:80}" "$query"
    done
  done
}

search_docs() {
  local query="$1"
  echo "  ${BOLD}${DIM}── DOCS${NC}"
  grep -rn -i "$query" "$BR_ROOT" --include="*.md" --max-depth=2 2>/dev/null \
    | head -8 | while IFS=: read -r file line content; do
    print_match "$file" "$line" "${content:0:80}" "$query"
  done
}

search_journal() {
  local query="$1"
  echo "  ${BOLD}${DIM}── JOURNAL${NC}"
  local hits=$(grep -ic "$query" "$JOURNAL" 2>/dev/null || echo 0)
  echo "  ${DIM}$hits matches in $(wc -l < "$JOURNAL" | tr -d ' ') entries${NC}"
  grep -i "$query" "$JOURNAL" 2>/dev/null | tail -8 | python3 -c "
import json, sys
query = '$query'.lower()
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts     = d.get('timestamp','?')[:16].replace('T',' ')
        action = d.get('action','?')
        entity = d.get('entity','?')[:25]
        detail = str(d.get('details',''))[:50]
        print(f'  \033[2m{ts}\033[0m  \033[36m{action:<18}\033[0m  \033[1m{entity:<25}\033[0m  \033[2m{detail}\033[0m')
    except: print(f'  {line[:100]}')
"
}

search_tasks() {
  local query="$1"
  echo "  ${BOLD}${DIM}── TASKS / INBOXES${NC}"
  local dirs=("$BR_ROOT/shared/mesh/queue" "$BR_ROOT/shared/inbox")
  for d in "${dirs[@]}"; do
    [[ ! -d "$d" ]] && continue
    grep -rn -i "$query" "$d" 2>/dev/null | head -5 | while IFS=: read -r file line content; do
      print_match "$file" "$line" "${content:0:80}" "$query"
    done
  done
}

search_glob() {
  local query="$1" glob="$2"
  echo "  ${BOLD}${DIM}── FILES ($glob)${NC}"
  find "$BR_ROOT" -name "$glob" 2>/dev/null | head -50 | while read -r f; do
    grep -n -i "$query" "$f" 2>/dev/null | head -3 | while IFS=: read -r line content; do
      print_match "$f" "$line" "${content:0:80}" "$query"
    done
  done
}

# ── Main ───────────────────────────────────────────────────────────────────────

# Parse args
local query="" mode="all" glob_pat=""
local args=("$@")
local i=1
while [[ $i -le ${#args[@]} ]]; do
  local arg="${args[$i]}"
  case "$arg" in
    --code)    mode="code" ;;
    --journal) mode="journal" ;;
    --agents)  mode="agents" ;;
    --docs)    mode="docs" ;;
    --tasks)   mode="tasks" ;;
    --all)     mode="all" ;;
    --file)    ((i++)); glob_pat="${args[$i]}" ;;
    help|--help|-h) show_help; exit 0 ;;
    -*)        ;; # ignore unknown flags
    *)         [[ -z "$query" ]] && query="$arg" ;;
  esac
  ((i++))
done

[[ -z "$query" ]] && { show_help; exit 0; }

echo ""
echo "  ${PINK}${BOLD}◈ SEARCH${NC}  ${DIM}\"$query\"  mode: $mode${NC}"
echo "  ${DIM}────────────────────────────────────────────────────────────${NC}"
echo ""

case "$mode" in
  code)    search_code "$query" ;;
  journal) search_journal "$query" ;;
  agents)  search_agents "$query" ;;
  docs)    search_docs "$query" ;;
  tasks)   search_tasks "$query" ;;
  all)
    [[ -n "$glob_pat" ]] && search_glob "$query" "$glob_pat" || {
      search_code "$query"
      echo ""
      search_agents "$query"
      echo ""
      search_journal "$query"
    }
    ;;
esac

echo ""
