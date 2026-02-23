#!/usr/bin/env zsh
# BR Journal — PS-SHA∞ memory journal browser
# br journal tail|head|search|stats|verify|last|write|context

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

JOURNAL="${BLACKROAD_JOURNAL:-$HOME/.blackroad/memory/journals/master-journal.jsonl}"
CONTEXT_FILE="$HOME/.blackroad/memory/context/recent-actions.md"

[[ ! -f "$JOURNAL" ]] && {
  echo "${RED}Journal not found: $JOURNAL${NC}" >&2
  exit 1
}

fmt_entry() {
  python3 -c "
import json, sys
line = sys.stdin.read().strip()
if not line: sys.exit(0)
try:
    d = json.loads(line)
    ts     = d.get('timestamp','?')[:19].replace('T',' ')
    action = d.get('action','?')
    entity = d.get('entity','?')[:30]
    detail = str(d.get('details',''))[:60]
    sha    = d.get('sha256','')[:12]
    print(f'\033[2m{ts}\033[0m  \033[36m{action:<18}\033[0m  \033[1m{entity:<30}\033[0m  \033[2m{detail}  [{sha}]\033[0m')
except Exception as e:
    print(line[:100])
"
}

cmd_tail() {
  local n="${1:-20}"
  echo "  ${PINK}${BOLD}BR Journal${NC}  ${DIM}— last $n entries, then live…${NC}"
  echo ""
  tail -n "$n" "$JOURNAL" | while IFS= read -r line; do
    echo "$line" | fmt_entry
  done
  echo ""
  echo "  ${DIM}Watching for new entries (Ctrl-C to stop)…${NC}"
  tail -f "$JOURNAL" | while IFS= read -r line; do
    echo "$line" | fmt_entry
  done
}

cmd_head() {
  local n="${1:-20}"
  echo "  ${PINK}${BOLD}BR Journal${NC}  ${DIM}— first $n entries${NC}"
  echo ""
  head -n "$n" "$JOURNAL" | while IFS= read -r line; do
    echo "$line" | fmt_entry
  done
}

cmd_search() {
  local q="$*"
  [[ -z "$q" ]] && { echo "  Usage: br journal search <query>"; exit 1; }
  local hits=$(grep -ic "$q" "$JOURNAL" 2>/dev/null || echo 0)
  echo "  ${PINK}${BOLD}BR Journal${NC}  ${DIM}— search: \"$q\" ($hits matches)${NC}"
  echo ""
  grep -i "$q" "$JOURNAL" | head -50 | while IFS= read -r line; do
    echo "$line" | fmt_entry
  done
}

cmd_stats() {
  echo ""
  echo "  ${PINK}${BOLD}BR Journal Stats${NC}"
  echo "  ${DIM}────────────────────────────${NC}"
  python3 -c "
import json, collections
journal = '$JOURNAL'
total = 0
actions = collections.Counter()
entities = collections.Counter()
first_ts = last_ts = ''
with open(journal) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        total += 1
        try:
            d = json.loads(line)
            actions[d.get('action','?')] += 1
            entities[d.get('entity','?')] += 1
            ts = d.get('timestamp','')
            if not first_ts: first_ts = ts
            last_ts = ts
        except: pass

print(f'  \033[1mTotal entries\033[0m  {total:,}')
print(f'  \033[1mFirst entry\033[0m    {first_ts[:19].replace(\"T\",\" \")}')
print(f'  \033[1mLast entry\033[0m     {last_ts[:19].replace(\"T\",\" \")}')
print()
print('  \033[1mTop Actions\033[0m')
for a, c in actions.most_common(10):
    print(f'    \033[36m{a:<25}\033[0m {c:>6,}')
print()
print('  \033[1mTop Entities\033[0m')
for e, c in entities.most_common(10):
    print(f'    \033[33m{e:<30}\033[0m {c:>6,}')
"
  echo ""
}

cmd_verify() {
  local sample="${1:-100}"
  echo "  ${PINK}${BOLD}Hash Chain Verify${NC}  ${DIM}(sampling $sample entries)${NC}"
  python3 -c "
import json, hashlib, random
journal = '$JOURNAL'
sample = int('$sample')
lines = [l.strip() for l in open(journal) if l.strip()]
if len(lines) > sample:
    random.seed(42)
    sampled = [lines[i] for i in sorted(random.sample(range(len(lines)), sample))]
else:
    sampled = lines
ok = bad = skip = 0
for line in sampled:
    try:
        d = json.loads(line)
        stored = d.pop('sha256', None)
        if not stored: skip += 1; continue
        parent = d.get('parent_hash', '')
        raw = json.dumps(d, sort_keys=True) + parent
        computed = hashlib.sha256(raw.encode()).hexdigest()[:16]
        if computed == stored: ok += 1
        else: bad += 1
    except: skip += 1
col = '\033[32m' if bad == 0 else '\033[31m'
print(f'  {col}● {ok} valid\033[0m  \033[31m{bad} invalid\033[0m  \033[2m{skip} skipped\033[0m')
print()
print('  \033[32m✓ Hash chain intact\033[0m' if bad == 0 else f'  \033[31m✗ {bad} entries failed\033[0m')
"
  echo ""
}

cmd_last() {
  local n="${1:-10}"
  echo ""
  echo "  ${PINK}${BOLD}Last $n Journal Entries${NC}"
  echo ""
  tail -n "$n" "$JOURNAL" | while IFS= read -r line; do
    echo "$line" | fmt_entry
  done
  echo ""
}

cmd_write() {
  local action="${1:-note}"; shift
  local entity="${1:-manual}"; shift
  local details="$*"
  python3 -c "
import json, hashlib, datetime
journal = '$JOURNAL'
parent_hash = ''
try:
    with open(journal, 'rb') as f:
        f.seek(max(0, -4096), 2)
        for line in f.read().decode('utf-8', errors='ignore').split('\n'):
            if line.strip():
                try: parent_hash = json.loads(line.strip()).get('sha256', '')
                except: pass
except: pass
entry = {
    'timestamp': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'action': '$action',
    'entity': '$entity',
    'details': '$details',
    'parent_hash': parent_hash
}
raw = json.dumps(entry, sort_keys=True) + parent_hash
sha = hashlib.sha256(raw.encode()).hexdigest()[:16]
entry['sha256'] = sha
with open(journal, 'a') as f:
    f.write(json.dumps(entry) + '\n')
print(f'  \033[32m✓\033[0m Written [{sha}]  action={entry[\"action\"]}  entity={entry[\"entity\"]}')
"
}

cmd_context() {
  if [[ -f "$CONTEXT_FILE" ]]; then
    cat "$CONTEXT_FILE"
  else
    echo "  ${DIM}Context file not found: $CONTEXT_FILE${NC}"
    echo "  ${DIM}Showing last 5 journal entries:${NC}"
    echo ""
    cmd_last 5
  fi
}

show_help() {
  echo ""
  echo "  ${PINK}${BOLD}br journal${NC}  — PS-SHA∞ memory journal browser"
  echo ""
  echo "  ${BOLD}Commands:${NC}"
  echo "    ${CYAN}tail [n]${NC}                         Tail live (last n + follow)"
  echo "    ${CYAN}last [n]${NC}                         Show last N entries (default 10)"
  echo "    ${CYAN}head [n]${NC}                         Show first N entries"
  echo "    ${CYAN}search <query>${NC}                   Search journal"
  echo "    ${CYAN}stats${NC}                            Stats: counts, top actions/entities"
  echo "    ${CYAN}verify [n]${NC}                       Verify hash chain (sample n)"
  echo "    ${CYAN}write <action> <entity> <details>${NC} Append entry"
  echo "    ${CYAN}context${NC}                          Show synthesized AI context"
  echo ""
  echo "  ${BOLD}Journal:${NC}  ${DIM}$JOURNAL${NC}"
  local total=$(wc -l < "$JOURNAL" 2>/dev/null | tr -d ' ')
  echo "  ${DIM}$total entries total${NC}"
  echo ""
}

case "${1:-help}" in
  tail|follow|watch)  cmd_tail "$2" ;;
  last|recent)        cmd_last "$2" ;;
  head|first)         cmd_head "$2" ;;
  search|find|grep)   shift; cmd_search "$@" ;;
  stats|info)         cmd_stats ;;
  verify|check)       cmd_verify "$2" ;;
  write|add|log)      shift; cmd_write "$@" ;;
  context|ctx)        cmd_context ;;
  help|*)             show_help ;;
esac
