#!/bin/zsh
# BR Memory - PS-SHA∞ Memory Journal Operations

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL="$MEMORY_DIR/journals/master-journal.jsonl"
LEDGER="$MEMORY_DIR/ledger/memory-ledger.jsonl"

init_memory() {
  mkdir -p "$MEMORY_DIR/journals" "$MEMORY_DIR/ledger" \
           "$MEMORY_DIR/context" "$MEMORY_DIR/sessions"
}

show_help() {
  echo -e "${CYAN}${BOLD}BR Memory${NC}"
  echo "  br memory write <key> <value>  Write to memory"
  echo "  br memory read <key>           Read from memory"
  echo "  br memory list                 List all keys"
  echo "  br memory search <query>       Search memory"
  echo "  br memory log <action> <data>  Log to journal"
  echo "  br memory stats                Memory statistics"
  echo "  br memory clear <key>          Clear a key"
}

cmd_write() {
  local KEY="$1"
  local VALUE="${@:2}"
  if [[ -z "$KEY" ]]; then
    echo -e "${RED}Usage: br memory write <key> <value>${NC}"
    return 1
  fi
  init_memory
  local HASH=$(echo "${KEY}:${VALUE}:$(date +%s)" | shasum -a 256 | cut -c1-16)
  local ENTRY="{\"key\":\"$KEY\",\"value\":\"$VALUE\",\"hash\":\"$HASH\",\"time\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  echo "$ENTRY" >> "$JOURNAL"
  echo "$ENTRY" >> "$LEDGER"
  echo -e "${GREEN}✓${NC} Stored [$HASH] $KEY"
}

cmd_read() {
  local KEY="$1"
  if [[ -z "$KEY" ]]; then
    echo -e "${RED}Usage: br memory read <key>${NC}"
    return 1
  fi
  if [[ ! -f "$JOURNAL" ]]; then
    echo -e "${YELLOW}No memory journal found${NC}"
    return 1
  fi
  local RESULT=$(grep "\"key\":\"$KEY\"" "$JOURNAL" 2>/dev/null | tail -1)
  if [[ -n "$RESULT" ]]; then
    echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['value'])" 2>/dev/null || echo "$RESULT"
  else
    echo -e "${YELLOW}Key not found: $KEY${NC}"
  fi
}

cmd_list() {
  if [[ ! -f "$JOURNAL" ]]; then
    echo -e "${YELLOW}No memory journal found${NC}"
    return
  fi
  echo -e "${CYAN}Memory Keys${NC}\n"
  python3 -c "
import json, sys
keys = {}
for line in open('$JOURNAL'):
    try:
        d = json.loads(line.strip())
        keys[d['key']] = d.get('time','?')
    except: pass
for k, t in sorted(keys.items()):
    print(f'  {k}  ({t})')
" 2>/dev/null || grep -o '"key":"[^"]*"' "$JOURNAL" | sort -u | sed 's/\"key\":\"//;s/\"//'
}

cmd_search() {
  local QUERY="${*:-}"
  if [[ -z "$QUERY" ]]; then
    echo -e "${RED}Usage: br memory search <query>${NC}"
    return 1
  fi
  if [[ ! -f "$JOURNAL" ]]; then
    echo -e "${YELLOW}No memory journal found${NC}"
    return
  fi
  echo -e "${CYAN}Search: \"$QUERY\"${NC}\n"
  grep -i "$QUERY" "$JOURNAL" 2>/dev/null | while read LINE; do
    echo "$LINE" | python3 -c "
import json,sys
try:
  d=json.loads(sys.stdin.read())
  print(f'  [{d.get(\"hash\",\"?\")}] {d.get(\"key\",\"?\")} = {d.get(\"value\",\"?\")[:80]}')
except: pass" 2>/dev/null
  done
}

cmd_log() {
  local ACTION="$1"
  local DATA="${@:2}"
  init_memory
  local HASH=$(echo "${ACTION}:${DATA}:$(date +%s)" | shasum -a 256 | cut -c1-16)
  local ENTRY="{\"type\":\"action\",\"action\":\"$ACTION\",\"data\":\"$DATA\",\"hash\":\"$HASH\",\"time\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  echo "$ENTRY" >> "$JOURNAL"
  echo -e "${GREEN}✓${NC} Logged [$HASH] $ACTION"
}

cmd_stats() {
  init_memory
  echo -e "${CYAN}Memory Statistics${NC}\n"
  if [[ -f "$JOURNAL" ]]; then
    ENTRIES=$(wc -l < "$JOURNAL" | tr -d ' ')
    SIZE=$(du -sh "$JOURNAL" 2>/dev/null | cut -f1)
    KEYS=$(grep -o '"key":"[^"]*"' "$JOURNAL" 2>/dev/null | sort -u | wc -l | tr -d ' ')
    echo -e "  Journal entries: ${GREEN}$ENTRIES${NC}"
    echo -e "  Unique keys:     ${GREEN}$KEYS${NC}"
    echo -e "  Journal size:    ${GREEN}$SIZE${NC}"
  else
    echo -e "  ${YELLOW}No journal yet${NC}"
  fi
  echo -e "  Memory dir: $MEMORY_DIR"
}

cmd_clear() {
  local KEY="$1"
  if [[ -z "$KEY" ]]; then
    echo -e "${RED}Usage: br memory clear <key>${NC}"
    return 1
  fi
  cmd_write "$KEY" "__DELETED__"
  echo -e "${YELLOW}Marked $KEY as deleted${NC}"
}

case "${1:-help}" in
  write)   cmd_write "$2" "${@:3}" ;;
  read)    cmd_read "$2" ;;
  list)    cmd_list ;;
  search)  cmd_search "${@:2}" ;;
  log)     cmd_log "$2" "${@:3}" ;;
  stats)   cmd_stats ;;
  clear)   cmd_clear "$2" ;;
  help|-h|--help) show_help ;;
  *)
    echo -e "${RED}Unknown command: $1${NC}"
    show_help ;;
esac
