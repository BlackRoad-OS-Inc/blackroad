#!/usr/bin/env zsh
# ⛓  BR CHAIN — PS-SHA∞ Hash Chain Explorer
# Inspect, verify, and query the BlackRoad memory journal

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
CACHE_DIR="$HOME/.blackroad/chain-cache"
mkdir -p "$CACHE_DIR"

# ── helpers ──────────────────────────────────────────────────────────

journal_exists() {
  [[ -f "$JOURNAL" ]] || { echo -e "${RED}✗ No journal found at $JOURNAL${NC}"; exit 1; }
}

line_count() { wc -l < "$JOURNAL" | tr -d ' '; }

# ── commands ─────────────────────────────────────────────────────────

cmd_tip() {
  journal_exists
  local last=$(tail -1 "$JOURNAL")
  local sha=$(echo "$last" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('sha256','(no sha)'))")
  local ts=$(echo "$last" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('timestamp','?'))")
  local act=$(echo "$last" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('action','?'))")
  local ent=$(echo "$last" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('entity','?'))")
  local total=$(line_count)
  echo -e ""
  echo -e "  ${CYAN}${BOLD}⛓  PS-SHA∞ Chain Tip${NC}"
  echo -e "  ${DIM}─────────────────────────────────────────${NC}"
  echo -e "  ${YELLOW}Hash${NC}    ${sha:0:16}...${sha: -8}"
  echo -e "  ${YELLOW}Time${NC}    $ts"
  echo -e "  ${YELLOW}Action${NC}  $act"
  echo -e "  ${YELLOW}Entity${NC}  $ent"
  echo -e "  ${YELLOW}Depth${NC}   ${PURPLE}${total}${NC} entries"
  echo -e ""
}

cmd_tail() {
  journal_exists
  local n=${1:-10}
  echo -e ""
  echo -e "  ${CYAN}${BOLD}⛓  Last $n Chain Entries${NC}"
  echo -e "  ${DIM}─────────────────────────────────────────────────────────${NC}"
  tail -$n "$JOURNAL" | python3 - <<'PYEOF'
import sys, json
for i, line in enumerate(sys.stdin):
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        sha = d.get('sha256','?')
        ts = d.get('timestamp','?')
        act = d.get('action','?')
        ent = d.get('entity','?')
        det = d.get('details','')[:60]
        print(f"  \033[2m{ts[:19]}\033[0m  \033[33m{sha[:8]}\033[0m  \033[36m{act:<16}\033[0m  {ent[:30]}")
    except:
        pass
PYEOF
  echo -e ""
}

cmd_show() {
  journal_exists
  local sha_prefix=${1:-}
  if [[ -z "$sha_prefix" ]]; then
    echo -e "${RED}Usage: br chain show <sha_prefix>${NC}"; exit 1
  fi
  local result=$(grep "\"sha256\": \"${sha_prefix}" "$JOURNAL" | head -1)
  if [[ -z "$result" ]]; then
    echo -e "${RED}✗ No entry found matching: $sha_prefix${NC}"; exit 1
  fi
  echo -e ""
  echo "$result" | python3 - <<'PYEOF'
import sys, json
d = json.loads(sys.stdin.read())
print(f"  \033[1m\033[36m⛓  Chain Entry\033[0m")
print(f"  \033[2m─────────────────────────────────────────\033[0m")
for k, v in d.items():
    val = str(v)
    if k == 'sha256': val = f"\033[33m{val}\033[0m"
    if k == 'parent_hash': val = f"\033[35m{val}\033[0m"
    if k == 'action': val = f"\033[36m{val}\033[0m"
    print(f"  \033[1m{k:<16}\033[0m {val}")
print()
PYEOF
}

cmd_verify() {
  journal_exists
  local sample=${1:-500}
  echo -e ""
  echo -e "  ${CYAN}${BOLD}⛓  Verifying Chain Integrity (sampling $sample entries)...${NC}"
  echo -e ""

  python3 <<PYEOF
import json, hashlib, sys

journal = "$JOURNAL"
sample_n = $sample

lines = []
with open(journal) as f:
    lines = [l.strip() for l in f if l.strip()]

total = len(lines)
step = max(1, total // sample_n)
indices = list(range(0, total, step))

errors = 0
checked = 0
prev_sha = None

for i in indices:
    try:
        d = json.loads(lines[i])
        sha = d.get('sha256','')
        parent = d.get('parent_hash','')
        if prev_sha and parent and parent != '0000000000000000' and parent != prev_sha:
            print(f"  \033[31m✗ Break at entry {i}: expected parent {prev_sha[:8]} got {parent[:8]}\033[0m")
            errors += 1
        prev_sha = sha
        checked += 1
    except Exception as e:
        print(f"  \033[31m✗ Parse error at line {i}: {e}\033[0m")
        errors += 1

if errors == 0:
    print(f"  \033[32m✓ Chain intact — {checked} entries verified (of {total} total)\033[0m")
else:
    print(f"  \033[31m✗ {errors} integrity errors found\033[0m")

# Stats
actions = {}
with open(journal) as f:
    for line in f:
        try:
            d = json.loads(line)
            a = d.get('action','?')
            actions[a] = actions.get(a, 0) + 1
        except:
            pass

print()
print("  \033[1mTop Actions:\033[0m")
for a, n in sorted(actions.items(), key=lambda x: -x[1])[:10]:
    bar = '█' * min(30, n // max(1, total // 300))
    print(f"  {a:<24} {bar} {n}")
print()
PYEOF
}

cmd_search() {
  journal_exists
  local query=${1:-}
  if [[ -z "$query" ]]; then
    echo -e "${RED}Usage: br chain search <query>${NC}"; exit 1
  fi
  local n=${2:-20}
  echo -e ""
  echo -e "  ${CYAN}${BOLD}⛓  Search: \"$query\" (top $n)${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────────────${NC}"
  grep -i "$query" "$JOURNAL" | tail -$n | python3 - <<'PYEOF'
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts = d.get('timestamp','?')[:19]
        sha = d.get('sha256','?')[:8]
        act = d.get('action','?')
        ent = d.get('entity','?')[:40]
        det = d.get('details','')[:50]
        print(f"  \033[2m{ts}\033[0m  \033[33m{sha}\033[0m  \033[36m{act:<16}\033[0m  {ent}")
        if det:
            print(f"                                 \033[2m{det}\033[0m")
    except:
        pass
PYEOF
  echo -e ""
}

cmd_stats() {
  journal_exists
  echo -e ""
  echo -e "  ${CYAN}${BOLD}⛓  Chain Statistics${NC}"
  echo -e ""
  python3 <<PYEOF
import json, collections
from datetime import datetime

journal = "$JOURNAL"

total = 0
actions = collections.Counter()
entities = collections.Counter()
dates = collections.Counter()
first_ts = None
last_ts = None

with open(journal) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            d = json.loads(line)
            total += 1
            actions[d.get('action','?')] += 1
            ent = d.get('entity','?')
            entities[ent] += 1
            ts = d.get('timestamp','')
            if ts:
                date = ts[:10]
                dates[date] += 1
                if first_ts is None: first_ts = ts
                last_ts = ts
        except:
            pass

print(f"  \033[1mTotal entries:\033[0m  \033[35m{total:,}\033[0m")
print(f"  \033[1mFirst entry:\033[0m    {first_ts}")
print(f"  \033[1mLast entry:\033[0m     {last_ts}")
print(f"  \033[1mUnique actions:\033[0m {len(actions)}")
print(f"  \033[1mUnique entities:\033[0m {len(entities)}")
print()
print("  \033[1mTop 10 Actions:\033[0m")
for a, n in actions.most_common(10):
    bar = '█' * min(40, n * 40 // max(1, actions.most_common(1)[0][1]))
    print(f"  \033[36m{a:<28}\033[0m {bar} \033[33m{n:,}\033[0m")
print()
print("  \033[1mTop 10 Entities:\033[0m")
for e, n in entities.most_common(10):
    print(f"  {e[:50]:<52}  \033[33m{n:,}\033[0m")
print()
print("  \033[1mActivity by Day (last 7):\033[0m")
for d, n in sorted(dates.items())[-7:]:
    bar = '▓' * min(50, n // max(1, max(dates.values()) // 50))
    print(f"  {d}  {bar}  {n:,}")
print()
PYEOF
}

cmd_export() {
  journal_exists
  local out=${1:-chain-export-$(date +%Y%m%d).jsonl}
  cp "$JOURNAL" "$out"
  echo -e "${GREEN}✓ Exported ${$(line_count)} entries → $out${NC}"
}

cmd_append() {
  journal_exists
  local action=${1:-note}
  local entity=${2:-user}
  local details=${3:-""}
  python3 <<PYEOF
import json, hashlib, time, sys, os

journal = "$journal"
action = "$action"
entity = "$entity"
details = "$details"

# Read last entry for parent hash
parent_hash = "0000000000000000"
try:
    with open(journal) as f:
        for line in f:
            pass
        last = json.loads(line.strip())
        parent_hash = last['sha256']
except:
    pass

entry = {
    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    "action": action,
    "entity": entity,
    "details": details,
    "parent_hash": parent_hash
}

content = json.dumps(entry, separators=(',', ':'), sort_keys=True)
sha = hashlib.sha256(content.encode()).hexdigest()
entry['sha256'] = sha

with open(journal, 'a') as f:
    f.write(json.dumps(entry, separators=(',', ':')) + '\n')

print(f"\033[32m✓ Appended [{action}] {entity} → {sha[:16]}...\033[0m")
PYEOF
}

cmd_help() {
  echo -e ""
  echo -e "  ${CYAN}${BOLD}⛓  BR CHAIN${NC}  ${DIM}PS-SHA∞ Hash Chain Explorer${NC}"
  echo -e "  ${DIM}BlockRoad memory journal: 157K+ entries, genesis Dec 2025${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br chain <command> [args]"
  echo -e ""
  echo -e "  ${YELLOW}EXPLORE${NC}"
  echo -e "  ${CYAN}  tip${NC}                          Show chain head (latest entry)"
  echo -e "  ${CYAN}  tail [n]${NC}                     Show last N entries (default 10)"
  echo -e "  ${CYAN}  show <sha>                   Show full entry by hash prefix"
  echo -e "  ${CYAN}  search <query> [n]${NC}           Search entries (default 20 results)"
  echo -e "  ${CYAN}  stats${NC}                        Chain statistics + top actions"
  echo -e ""
  echo -e "  ${YELLOW}INTEGRITY${NC}"
  echo -e "  ${CYAN}  verify [sample]${NC}              Verify chain integrity (default 500 entries)"
  echo -e ""
  echo -e "  ${YELLOW}WRITE${NC}"
  echo -e "  ${CYAN}  append <action> <entity> [details]${NC}  Add entry to chain"
  echo -e "  ${CYAN}  export [filename]${NC}             Export full chain to JSONL"
  echo -e ""
  echo -e "  ${DIM}Journal: $JOURNAL${NC}"
  echo -e ""
}

# ── dispatch ──────────────────────────────────────────────────────────
case "${1:-help}" in
  tip|head|latest)          cmd_tip ;;
  tail|log|last)            cmd_tail "${2:-10}" ;;
  show|entry|get)           cmd_show "$2" ;;
  verify|check|integrity)   cmd_verify "${2:-500}" ;;
  search|find|grep)         cmd_search "$2" "${3:-20}" ;;
  stats|stat|info)          cmd_stats ;;
  append|add|write)         cmd_append "$2" "$3" "$4" ;;
  export|dump)              cmd_export "$2" ;;
  help|--help|-h)           cmd_help ;;
  *)
    echo -e "${RED}✗ Unknown: $1${NC}"
    cmd_help; exit 1 ;;
esac
