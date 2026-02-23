#!/usr/bin/env zsh
# BR Dashboard — live single-pane terminal dashboard
# br dashboard [refresh-secs]  (default: 5s, Ctrl-C to exit)

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'; PURPLE=$'\033[0;35m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
INSTANCES_FILE="$BR_ROOT/coordination/collaboration/active-instances.json"
QUEUE_DIR="$BR_ROOT/shared/mesh/queue"

REFRESH="${1:-5}"

section_header() {
  local ts=$(date "+%Y-%m-%d %H:%M:%S")
  local cols=$(tput cols 2>/dev/null || echo 80)
  printf "${BOLD}${AMBER}  ▸ BLACKROAD DASHBOARD  %s${NC}\n" "$ts"
  printf "${DIM}%${cols}s${NC}\n" | tr ' ' '─'
}

section_health() {
  printf "  ${BOLD}%-20s${NC}" "SERVICES"
  if curl -sf --max-time 1 http://localhost:11434/api/tags &>/dev/null; then
    local mcount=$(curl -sf --max-time 2 http://localhost:11434/api/tags | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null)
    printf "${GREEN}● Ollama${NC} ${DIM}%s models${NC}  " "$mcount"
  else
    printf "${RED}○ Ollama${NC}  "
  fi
  if curl -sf --max-time 1 http://127.0.0.1:8787/ &>/dev/null || curl -sf --max-time 1 http://127.0.0.1:8080/ &>/dev/null; then
    printf "${GREEN}● Gateway${NC}  "
  else
    printf "${DIM}○ Gateway${NC}  "
  fi
  if curl -sf --max-time 1 http://127.0.0.1:8420/ &>/dev/null; then
    printf "${GREEN}● MCP${NC}"
  else
    printf "${DIM}○ MCP${NC}"
  fi
  echo ""
}

section_pis() {
  printf "  ${BOLD}%-20s${NC}" "PI FLEET"
  for entry in "192.168.4.38:aria64" "192.168.4.64:blackroad-pi" "192.168.4.99:alice-pi"; do
    local ip="${entry%%:*}" label="${entry#*:}"
    if ping -c1 -W1 -q "$ip" &>/dev/null 2>&1; then
      printf "${GREEN}● %s${NC}  " "$label"
    else
      printf "${DIM}○ %s${NC}  " "$label"
    fi
  done
  echo ""
}

section_system() {
  printf "  ${BOLD}%-20s${NC}" "SYSTEM"
  local cpu mem disk
  cpu=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f%%", s/8}' 2>/dev/null || echo "?")
  mem=$(vm_stat 2>/dev/null | python3 -c "
import sys, re
d = {m[0]:int(m[1]) for m in re.findall(r'(.+):\s+(\d+)', sys.stdin.read())}
pages_used = d.get('Pages active',0) + d.get('Pages inactive',0) + d.get('Pages wired down',0)
pages_total = pages_used + d.get('Pages free',0)
pct = int(pages_used * 100 / pages_total) if pages_total else 0
print(f'{pct}%')
" 2>/dev/null || echo "?")
  disk=$(df -h / 2>/dev/null | tail -1 | awk '{print $5}')
  printf "CPU ${CYAN}%s${NC}  MEM ${CYAN}%s${NC}  DISK ${CYAN}%s${NC}" "$cpu" "$mem" "$disk"
  echo ""
}

section_git() {
  printf "  ${BOLD}%-20s${NC}" "GIT"
  if git -C "$BR_ROOT" rev-parse --git-dir &>/dev/null; then
    local branch=$(git -C "$BR_ROOT" branch --show-current 2>/dev/null)
    local dirty=$(git -C "$BR_ROOT" status --short | grep -v "^?" | wc -l | tr -d ' ')
    local ahead=$(git -C "$BR_ROOT" rev-list HEAD..operator/master --count 2>/dev/null || echo "?")
    printf "branch ${CYAN}%s${NC}  dirty ${AMBER}%s${NC}  ahead ${VIOLET}%s${NC}" "$branch" "$dirty" "$ahead"
  fi
  echo ""
}

section_journal() {
  printf "  ${BOLD}%-20s${NC}" "JOURNAL"
  local total=$(wc -l < "$JOURNAL" 2>/dev/null | tr -d ' ')
  local last=$(tail -1 "$JOURNAL" 2>/dev/null | python3 -c "
import json,sys
try:
    d = json.loads(sys.stdin.read())
    ts = d.get('timestamp','?')[:16].replace('T',' ')
    action = d.get('action','?')
    entity = d.get('entity','?')[:20]
    print(f'{ts}  {action} / {entity}')
except: print('?')
" 2>/dev/null)
  printf "${DIM}%s entries${NC}  last: ${CYAN}%s${NC}" "$total" "$last"
  echo ""
}

section_worlds() {
  printf "  ${BOLD}%-20s${NC}" "WORLDS"
  local aria=$(ssh -o ConnectTimeout=2 alexa@192.168.4.38 "ls /home/alexa/blackroad-repos/blackroad-agents/worlds/*.md 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
  local alice=$(ssh -o ConnectTimeout=2 blackroad@192.168.4.49 "ls /home/blackroad/.blackroad/worlds/*.md 2>/dev/null | wc -l" 2>/dev/null | tr -d ' ')
  local total=$(( ${aria:-0} + ${alice:-0} ))
  printf "${PURPLE}aria64 %s${NC}  ${CYAN}alice %s${NC}  ${BOLD}total ${GREEN}%s${NC}" "${aria:-?}" "${alice:-?}" "$total"
  echo ""
}

section_workers() {
  printf "  ${BOLD}%-20s${NC}" "CF WORKERS"
  for W in worlds verify agents-status models worlds-feed studio; do
    local ok=$(curl -sf --max-time 2 "https://${W}.blackroad.io/health" 2>/dev/null && echo "1" || echo "0")
    [ "$ok" = "1" ] && printf "${GREEN}●${NC}${W} " || printf "${DIM}○${NC}${W} "
  done
  echo ""
}

section_collab() {
  printf "  ${BOLD}%-20s${NC}" "MESH"
  local online=0 standby=0 total=0
  if [[ -f "$INSTANCES_FILE" ]]; then
    local _r
    _r=$(python3 -c "
import json
with open('$INSTANCES_FILE') as f: d = json.load(f)
instances = list(d.get('instances', d).values()) if isinstance(d, dict) else d
on = sum(1 for i in instances if i.get('status') == 'ONLINE')
st = sum(1 for i in instances if i.get('status') == 'STANDBY')
print(on, st, len(instances))
" 2>/dev/null)
    read online standby total <<< "$_r"
  fi
  local qcount=$(ls "$QUEUE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  printf "${GREEN}%s online${NC}  ${YELLOW}%s standby${NC}  ${DIM}%s total${NC}  queue ${CYAN}%s${NC}" \
    "$online" "$standby" "$total" "$qcount"
  echo ""
}

section_recent_log() {
  local cols=$(tput cols 2>/dev/null || echo 80)
  printf "${DIM}%${cols}s${NC}\n" | tr ' ' '─'
  echo "  ${BOLD}${DIM}RECENT JOURNAL${NC}"
  tail -4 "$JOURNAL" 2>/dev/null | python3 -c "
import json, sys
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        ts = d.get('timestamp','')[:16].replace('T',' ')
        action = d.get('action','?')
        entity = d.get('entity','?')[:25]
        print(f'  \033[2m{ts}  \033[36m{action:<18}\033[0m\033[2m  {entity}\033[0m')
    except: pass
"
}

run_once() {
  clear
  section_header
  echo ""
  section_health
  section_pis
  section_worlds
  section_workers
  section_system
  section_git
  section_journal
  section_collab
  section_recent_log
  echo ""
  printf "  ${DIM}Refreshing every %ss — Ctrl-C to exit${NC}\n" "$REFRESH"
}

if [[ "${1}" == "once" || "${1}" == "--once" ]]; then
  REFRESH=0
  run_once
  exit 0
fi

trap 'tput cnorm 2>/dev/null; echo ""; exit 0' INT TERM
tput civis 2>/dev/null

while true; do
  run_once
  sleep "$REFRESH"
done
