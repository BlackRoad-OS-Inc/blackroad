#!/usr/bin/env zsh
# ◆ BR SEARCH — Smart cross-repo code search
# br search <query> [--code|--journal|--docs|--agents|--tasks|ai]

AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"

#──────────────────────────────────────────────────────────────────────────────
# Helpers
#──────────────────────────────────────────────────────────────────────────────
_print_match() {
  local file="$1" line="$2" content="$3" score="${4:-}"
  local short="${file#$BR_ROOT/}"
  # Highlight query term (if possible)
  local hi; hi=$(printf '%s' "$content" | sed "s/${_QUERY_ESC}/$(printf '\033[1;33m')&$(printf '\033[0m')/gi" 2>/dev/null || printf '%s' "$content")
  if [[ -n "$score" ]]; then
    printf "  ${AMBER}%-40s${NC} ${DIM}%4s${NC}  ${DIM}[%s]${NC}  %s\n" "$short" "$line" "$score" "${hi:0:72}"
  else
    printf "  ${AMBER}%-40s${NC} ${DIM}%4s${NC}  %s\n" "$short" "$line" "${hi:0:72}"
  fi
}

_section() { echo -e "\n  ${BOLD}${DIM}── $1${NC}"; }

#──────────────────────────────────────────────────────────────────────────────
# Search modes
#──────────────────────────────────────────────────────────────────────────────
search_code() {
  local q="$1"
  _section "CODE"
  local dirs=("$BR_ROOT/tools" "$BR_ROOT/scripts" "$BR_ROOT/lib" "$BR_ROOT/br")
  for target in "${dirs[@]}"; do
    [[ ! -e "$target" ]] && continue
    rg -in --with-filename --line-number "$q" "$target" \
       --type sh --type py --type js --type ts \
       -m 5 2>/dev/null | head -15 | while IFS=: read -r file line content; do
      _print_match "$file" "$line" "$content"
    done
  done
}

search_agents() {
  local q="$1"
  _section "AGENTS / COORDINATION"
  local dirs=("$BR_ROOT/agents" "$BR_ROOT/coordination" "$BR_ROOT/shared")
  for d in "${dirs[@]}"; do
    [[ ! -d "$d" ]] && continue
    rg -in --with-filename --line-number "$q" "$d" -m 3 2>/dev/null | head -8 | while IFS=: read -r file line content; do
      _print_match "$file" "$line" "$content"
    done
  done
}

search_docs() {
  local q="$1"
  _section "DOCS"
  rg -in --with-filename --line-number "$q" "$BR_ROOT" \
     --type md --max-depth 2 -m 3 2>/dev/null | head -10 | while IFS=: read -r file line content; do
    _print_match "$file" "$line" "$content"
  done
}

search_journal() {
  local q="$1"
  _section "JOURNAL"
  local hits; hits=$(grep -ic "$q" "$JOURNAL" 2>/dev/null || echo 0)
  echo "  ${DIM}$hits matches${NC}"
  grep -i "$q" "$JOURNAL" 2>/dev/null | tail -8 | python3 -c "
import json,sys
for line in sys.stdin:
    line=line.strip()
    if not line: continue
    try:
        d=json.loads(line)
        ts=d.get('timestamp','?')[:16].replace('T',' ')
        action=d.get('action','?')
        entity=str(d.get('entity','?'))[:25]
        detail=str(d.get('details',''))[:45]
        print(f'  \033[2m{ts}\033[0m  \033[38;5;214m{action:<18}\033[0m  \033[1m{entity:<25}\033[0m  \033[2m{detail}\033[0m')
    except: print(f'  {line[:90]}')
"
}

search_tasks() {
  local q="$1"
  _section "TASKS"
  local dirs=("$BR_ROOT/shared/mesh/queue" "$BR_ROOT/shared/inbox")
  for d in "${dirs[@]}"; do
    [[ ! -d "$d" ]] && continue
    rg -in --with-filename --line-number "$q" "$d" -m 3 2>/dev/null | head -6 | while IFS=: read -r file line content; do
      _print_match "$file" "$line" "$content"
    done
  done
}

#──────────────────────────────────────────────────────────────────────────────
# AI mode — smart ranked results with file-type scoring
#──────────────────────────────────────────────────────────────────────────────
search_ai() {
  local q="$1"
  echo -e "\n  ${AMBER}${BOLD}◆ BR SEARCH${NC}  ${DIM}AI mode — ranked by relevance${NC}\n"

  # Collect all hits with metadata
  local tmpfile; tmpfile=$(mktemp)
  rg -in --with-filename --line-number --no-heading "$q" \
     "$BR_ROOT/tools" "$BR_ROOT/scripts" "$BR_ROOT/lib" "$BR_ROOT/br" \
     "$BR_ROOT/agents" "$BR_ROOT/coordination" \
     -m 10 2>/dev/null >> "$tmpfile"
  rg -in --with-filename --line-number --no-heading --type md "$q" \
     "$BR_ROOT" --max-depth 2 2>/dev/null >> "$tmpfile"

  local total; total=$(wc -l < "$tmpfile")
  echo -e "  ${DIM}${total} raw hits — scoring...${NC}\n"

  python3 << PYEOF
import sys, re, os

query = "${q}".lower()
results = []

with open("${tmpfile}") as f:
    for raw in f:
        raw = raw.rstrip('\n')
        if not raw: continue
        # file:line:content
        parts = raw.split(':', 2)
        if len(parts) < 3: continue
        filepath, lineno, content = parts[0], parts[1], parts[2]

        short = filepath.replace("${BR_ROOT}/", "")
        content_lower = content.lower().strip()
        score = 0

        # Exact match in content
        count = content_lower.count(query)
        score += count * 10

        # Match in filename
        if query in os.path.basename(filepath).lower():
            score += 20

        # File type bonuses
        ext = os.path.splitext(filepath)[1]
        if ext in ('.sh', '.zsh'):   score += 5
        if ext in ('.py',):          score += 4
        if ext in ('.ts', '.js'):    score += 3
        if ext in ('.md',):          score += 1

        # Penalise deep paths (less relevant)
        score -= filepath.count('/') // 3

        # Query appears at start of content line → big bonus
        stripped = content_lower.lstrip('# /\t ')
        if stripped.startswith(query):
            score += 15

        results.append((score, short, lineno, content.strip()[:72]))

results.sort(key=lambda x: -x[0])
seen = set()
AMBER='\033[38;5;214m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'; YELLOW='\033[1;33m'

for score, short, lineno, content in results[:20]:
    key = f"{short}:{lineno}"
    if key in seen: continue
    seen.add(key)
    hi = re.sub(re.escape(query), f'{YELLOW}\\g<0>{NC}', content, flags=re.IGNORECASE)
    bar = '█' * min(score, 20) if score > 0 else ''
    print(f"  {AMBER}{short:<42}{NC} {DIM}{lineno:>4}{NC}  {DIM}[{score:>2}] {bar[:10]:<10}{NC}  {hi}")

PYEOF
  rm -f "$tmpfile"
  echo ""
}

#──────────────────────────────────────────────────────────────────────────────
# Help
#──────────────────────────────────────────────────────────────────────────────
show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR SEARCH${NC}  ${DIM}Smart code search. Finds what you mean, not just what you type.${NC}"
  echo -e "  ${DIM}Ripgrep-powered across tools, agents, docs, journals — with AI ranking.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br search ${DIM}<query> [mode]${NC}"
  echo -e ""
  echo -e "  ${BOLD}MODES${NC}"
  echo -e "  ${AMBER}  ai                ${NC} ${BOLD}Smart ranked results${NC} — relevance-scored hits across everything"
  echo -e "  ${AMBER}  --code            ${NC} Tools, scripts, lib — .sh .py .ts"
  echo -e "  ${AMBER}  --docs            ${NC} Markdown docs"
  echo -e "  ${AMBER}  --journal         ${NC} PS-SHA∞ memory journal"
  echo -e "  ${AMBER}  --agents          ${NC} Agents + coordination dirs"
  echo -e "  ${AMBER}  --tasks           ${NC} Task queue + inboxes"
  echo -e "  ${AMBER}  (no flag)         ${NC} Search everything"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br search deploy ai${NC}"
  echo -e "  ${DIM}  br search 'ollama' --code${NC}"
  echo -e "  ${DIM}  br search 'bond' --journal${NC}"
  echo -e "  ${DIM}  br search 'gateway' --docs${NC}"
  echo -e ""
}

#──────────────────────────────────────────────────────────────────────────────
# Main
#──────────────────────────────────────────────────────────────────────────────
local query="" mode="all" _QUERY_ESC=""
local -a args=("$@")
local i=1
while (( i <= ${#args[@]} )); do
  local arg="${args[$i]}"
  case "$arg" in
    ai)        mode="ai" ;;
    --code)    mode="code" ;;
    --journal) mode="journal" ;;
    --agents)  mode="agents" ;;
    --docs)    mode="docs" ;;
    --tasks)   mode="tasks" ;;
    --all)     mode="all" ;;
    help|--help|-h) show_help; exit 0 ;;
    -*)        ;;
    *)         [[ -z "$query" ]] && query="$arg" ;;
  esac
  (( i++ ))
done

[[ -z "$query" ]] && { show_help; exit 0; }
_QUERY_ESC="${query//\//\\/}"

if [[ "$mode" == "ai" ]]; then
  search_ai "$query"
  exit 0
fi

echo -e ""
echo -e "  ${AMBER}${BOLD}◆ BR SEARCH${NC}  ${DIM}\"${query}\"  [${mode}]${NC}"
echo -e "  ${DIM}────────────────────────────────────────────────────────────${NC}"

case "$mode" in
  code)    search_code "$query" ;;
  journal) search_journal "$query" ;;
  agents)  search_agents "$query" ;;
  docs)    search_docs "$query" ;;
  tasks)   search_tasks "$query" ;;
  all)
    search_code "$query"
    search_agents "$query"
    search_journal "$query"
    ;;
esac
echo ""
