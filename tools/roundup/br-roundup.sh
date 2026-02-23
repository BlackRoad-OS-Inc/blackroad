#!/usr/bin/env zsh
# BR Roundup — AI-generated daily summary from journal + git + mesh
# br roundup [today|yesterday|hours <N>|write|send <instance>]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
INSTANCES_FILE="$BR_ROOT/coordination/collaboration/active-instances.json"
ROUNDUP_DIR="$HOME/.blackroad/roundups"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"

mkdir -p "$ROUNDUP_DIR"

# ── helpers ────────────────────────────────────────────────────────────────
hr()  { echo "${DIM}────────────────────────────────────────────────────────────────────${NC}"; }
hdr() { echo; echo "${VIOLET}◈ $1${NC}"; hr; }

# ── gather raw data ─────────────────────────────────────────────────────────
gather_data() {
    local hours="${1:-24}"
    local since_ts
    since_ts=$(python3 -c "
import datetime, time
now = datetime.datetime.now(datetime.timezone.utc)
delta = datetime.timedelta(hours=$hours)
since = now - delta
print(since.strftime('%Y-%m-%dT%H:%M:%S'))
")

    # Journal entries in window
    local journal_entries=""
    if [[ -f "$JOURNAL" ]]; then
        journal_entries=$(grep -a "\"timestamp\":\"${since_ts:0:10}" "$JOURNAL" 2>/dev/null | tail -200)
        # also grab entries from today regardless
        local today
        today=$(date +%Y-%m-%d)
        journal_entries+=$(grep -a "\"timestamp\":\"$today" "$JOURNAL" 2>/dev/null | tail -200)
    fi

    # Action summary from journal
    local action_summary=""
    if [[ -n "$journal_entries" ]]; then
        action_summary=$(echo "$journal_entries" | python3 -c "
import sys, json
from collections import Counter
actions = Counter()
entities = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        actions[d.get('action','?')] += 1
        ent = d.get('entity','')
        if ent and ent not in entities[-20:]:
            entities.append(ent)
    except: pass
top = actions.most_common(8)
print('ACTIONS: ' + ', '.join(f'{a}({n})' for a,n in top))
print('ENTITIES: ' + ', '.join(entities[-15:]))
" 2>/dev/null)
    fi

    # Git log summary
    local git_summary=""
    git_summary=$(cd "$BR_ROOT" && git --no-pager log --oneline --since="${hours} hours ago" 2>/dev/null | head -10)

    # Queue depth
    local queue_depth=0
    if [[ -d "$BR_ROOT/shared/mesh/queue" ]]; then
        queue_depth=$(ls "$BR_ROOT/shared/mesh/queue/" 2>/dev/null | wc -l | tr -d ' ')
    fi

    # Active agents
    local agent_list=""
    if [[ -d "$BR_ROOT/agents/active" ]]; then
        agent_list=$(ls "$BR_ROOT/agents/active/"*.json 2>/dev/null | xargs -I{} sh -c 'python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d[\"name\"],d[\"status\"])" {} 2>/dev/null' | paste -sd ', ' -)
    fi

    # Mesh instances
    local mesh_online=0
    if [[ -f "$INSTANCES_FILE" ]]; then
        mesh_online=$(python3 -c "
import json
try:
    d = json.load(open('$INSTANCES_FILE'))
    insts = d.get('instances', d) if isinstance(d, dict) else d
    if isinstance(insts, dict): insts = list(insts.values())
    print(sum(1 for i in insts if i.get('status') == 'ONLINE'))
except: print(0)
" 2>/dev/null)
    fi

    echo "HOURS=$hours"
    echo "SINCE=$since_ts"
    echo "GIT_LOG=$git_summary"
    echo "QUEUE=$queue_depth"
    echo "MESH=$mesh_online"
    echo "AGENTS=$agent_list"
    echo "$action_summary"
}

# ── AI summary via ollama ────────────────────────────────────────────────────
ai_summary() {
    local data="$1"
    local model="${2:-tinyllama:latest}"

    # Check ollama available
    if ! curl -sf "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
        echo "(Ollama offline — showing raw data)"
        echo "$data"
        return
    fi

    local prompt="You are LUCIDIA, the BlackRoad OS intelligence. Generate a concise daily roundup report from this system data.

DATA:
$data

Write a 3-section report:
1. DONE TODAY: What was accomplished (bullet points, past tense)
2. IN PROGRESS: What is actively running/pending
3. NEXT UP: Recommended priorities

Keep it short, technical, and direct. Use the agent's voice — confident, warm, precise."

    local payload
    payload=$(python3 -c "
import json, sys
prompt = sys.argv[1]
print(json.dumps({'model': sys.argv[2], 'prompt': prompt, 'stream': False, 'options': {'temperature': 0.7, 'num_predict': 400}}))
" "$prompt" "$model" 2>/dev/null)

    local response
    response=$(curl -sf -X POST "${OLLAMA_URL}/api/generate" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --max-time 60 2>/dev/null)

    if [[ -n "$response" ]]; then
        echo "$response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('response','(no response)'))" 2>/dev/null
    else
        echo "(AI timed out — showing raw data)"
        echo "$data"
    fi
}

# ── display ──────────────────────────────────────────────────────────────────
cmd_show() {
    local hours="${1:-24}"
    local model="${2:-tinyllama:latest}"

    echo
    echo "${VIOLET}${BOLD}◈ BLACKROAD DAILY ROUNDUP${NC}  ${DIM}$(date '+%A %B %d, %Y  %H:%M')${NC}"
    hr

    echo "${CYAN}Gathering data (last ${hours}h)...${NC}"
    local raw_data
    raw_data=$(gather_data "$hours")

    # Parse key fields for display
    local git_log queue mesh agents
    git_log=$(echo "$raw_data" | grep "^GIT_LOG=" | sed 's/^GIT_LOG=//')
    queue=$(echo "$raw_data" | grep "^QUEUE=" | sed 's/^QUEUE=//')
    mesh=$(echo "$raw_data" | grep "^MESH=" | sed 's/^MESH=//')
    agents=$(echo "$raw_data" | grep "^AGENTS=" | sed 's/^AGENTS=//')

    # Show quick stats
    echo
    printf "  ${YELLOW}Git commits${NC}    %s\n" "${git_log:-(none in last ${hours}h)}"
    printf "  ${YELLOW}Queue depth${NC}    %s tasks\n" "${queue:-0}"
    printf "  ${YELLOW}Mesh online${NC}    %s instances\n" "${mesh:-0}"
    [[ -n "$agents" ]] && printf "  ${YELLOW}Agents${NC}         %s\n" "$agents"

    hdr "AI SUMMARY  ${DIM}(${model})${NC}"
    echo "${CYAN}Asking LUCIDIA...${NC}"
    echo
    ai_summary "$raw_data" "$model"
    echo
}

# ── write roundup to file ────────────────────────────────────────────────────
cmd_write() {
    local hours="${1:-24}"
    local label
    label="roundup-$(date +%Y%m%d-%H%M)"
    local outfile="$ROUNDUP_DIR/${label}.md"

    echo "${CYAN}Generating roundup → ${outfile}${NC}"
    local raw_data
    raw_data=$(gather_data "$hours")
    local summary
    summary=$(ai_summary "$raw_data" "tinyllama:latest")

    cat > "$outfile" <<MDEOF
# BlackRoad Roundup — $(date '+%A %B %d, %Y  %H:%M')

**Period:** Last ${hours} hours
**Generated by:** LUCIDIA (tinyllama)

---

$summary

---

## Raw Data

\`\`\`
$raw_data
\`\`\`
MDEOF

    echo "${GREEN}✓ Written: $outfile${NC}"
}

# ── send to instance inbox ───────────────────────────────────────────────────
cmd_send() {
    local target="${1:-lucidia}"
    local hours="${2:-24}"
    local inbox="$BR_ROOT/shared/inbox/${target}"
    mkdir -p "$inbox"

    local ts
    ts=$(date +%s)
    local outfile="$inbox/roundup-${ts}.json"

    local raw_data
    raw_data=$(gather_data "$hours")
    local summary
    summary=$(ai_summary "$raw_data" "tinyllama:latest")

    python3 -c "
import json, sys
summary = sys.argv[1]
raw = sys.argv[2]
ts = sys.argv[3]
print(json.dumps({
    'type': 'roundup',
    'from': 'br-roundup',
    'to': sys.argv[4],
    'timestamp': ts,
    'summary': summary,
    'raw_data': raw
}, indent=2))
" "$summary" "$raw_data" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$target" > "$outfile"

    echo "${GREEN}✓ Roundup sent to ${target}: $outfile${NC}"
}

# ── list saved roundups ──────────────────────────────────────────────────────
cmd_list() {
    hdr "SAVED ROUNDUPS"
    if [[ -z "$(ls $ROUNDUP_DIR/*.md 2>/dev/null)" ]]; then
        echo "  ${DIM}No roundups yet — run: br roundup write${NC}"
        return
    fi
    ls -lh "$ROUNDUP_DIR/"*.md 2>/dev/null | awk '{print "  " $NF "  (" $5 ")"}'
}

# ── help ─────────────────────────────────────────────────────────────────────
show_help() {
    echo
    echo "${VIOLET}${BOLD}BR ROUNDUP${NC} — AI-generated daily summary from journal + git + mesh"
    echo
    echo "  ${CYAN}br roundup${NC}                    Show roundup for last 24h"
    echo "  ${CYAN}br roundup today${NC}              Same as above"
    echo "  ${CYAN}br roundup hours <N>${NC}          Last N hours"
    echo "  ${CYAN}br roundup write${NC}              Save roundup to ~/.blackroad/roundups/"
    echo "  ${CYAN}br roundup list${NC}               List saved roundups"
    echo "  ${CYAN}br roundup send <instance>${NC}    Send to instance inbox"
    echo
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-show}" in
    today|show|"") cmd_show 24 ;;
    yesterday)     cmd_show 48 ;;
    hours)         cmd_show "${2:-24}" ;;
    write)         cmd_write "${2:-24}" ;;
    list)          cmd_list ;;
    send)          cmd_send "${2:-lucidia}" "${3:-24}" ;;
    help|--help|-h) show_help ;;
    *)             cmd_show "${1}" ;;
esac
