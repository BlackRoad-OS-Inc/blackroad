#!/usr/bin/env zsh
# BR Standup — formatted daily standup report (journal + git + PR + tasks)
# br standup [show|post|send <instance>|slack|copy]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
INSTANCES_FILE="$BR_ROOT/coordination/collaboration/active-instances.json"
STANDUP_DIR="$HOME/.blackroad/standups"

mkdir -p "$STANDUP_DIR"

# ── helpers ────────────────────────────────────────────────────────────────
hr()  { echo "${DIM}────────────────────────────────────────────────────────────────────${NC}"; }
hdr() { echo; echo "${VIOLET}◈ $1${NC}"; hr; }

# ── gather yesterday's git commits ──────────────────────────────────────────
section_git() {
    local commits
    commits=$(cd "$BR_ROOT" && git --no-pager log \
        --oneline \
        --since="yesterday midnight" \
        --until="now" \
        --format="  • %s  ${DIM}(%ar)${NC}" 2>/dev/null | head -10)

    echo "${YELLOW}Git commits${NC}"
    if [[ -n "$commits" ]]; then
        echo "$commits"
    else
        echo "  ${DIM}No commits since midnight${NC}"
    fi
}

# ── journal summary ──────────────────────────────────────────────────────────
section_journal() {
    local today
    today=$(date +%Y-%m-%d)

    if [[ ! -f "$JOURNAL" ]]; then
        echo "${YELLOW}Journal${NC}"
        echo "  ${DIM}No journal${NC}"
        return
    fi

    local stats
    stats=$(grep -ac "\"timestamp\":\"$today" "$JOURNAL" 2>/dev/null || echo 0)

    local top_actions
    top_actions=$(grep -a "\"timestamp\":\"$today" "$JOURNAL" 2>/dev/null | python3 -c "
import sys, json
from collections import Counter
actions = Counter()
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        actions[d.get('action','?')] += 1
    except: pass
for a, n in actions.most_common(5):
    print(f'  • {a}  ({n}x)')
" 2>/dev/null)

    echo "${YELLOW}Journal (today)${NC}"
    printf "  %s entries logged\n" "$stats"
    [[ -n "$top_actions" ]] && echo "$top_actions"
}

# ── task queue status ─────────────────────────────────────────────────────────
section_tasks() {
    echo "${YELLOW}Task queue${NC}"
    local queue_dir="$BR_ROOT/shared/mesh/queue"
    if [[ -d "$queue_dir" ]]; then
        local count
        count=$(ls "$queue_dir/" 2>/dev/null | wc -l | tr -d ' ')
        printf "  %s tasks pending\n" "$count"
        ls "$queue_dir/" 2>/dev/null | head -5 | while read -r f; do
            echo "  • $f"
        done
    else
        echo "  ${DIM}No queue${NC}"
    fi
}

# ── mesh / agent status ───────────────────────────────────────────────────────
section_mesh() {
    echo "${YELLOW}Collaboration mesh${NC}"
    if [[ -f "$INSTANCES_FILE" ]]; then
        python3 -c "
import json
try:
    d = json.load(open('$INSTANCES_FILE'))
    insts = d.get('instances', d) if isinstance(d, dict) else d
    if isinstance(insts, dict): insts = list(insts.values())
    online = [i for i in insts if i.get('status') == 'ONLINE']
    print(f'  {len(online)}/{len(insts)} instances ONLINE')
    for i in online:
        print(f'  • {i[\"id\"]}  ({i.get(\"role\",\"\")})')
except Exception as e:
    print(f'  (error: {e})')
" 2>/dev/null
    else
        echo "  ${DIM}No mesh data${NC}"
    fi
}

# ── blockers from journal ────────────────────────────────────────────────────
section_blockers() {
    echo "${YELLOW}Blockers / errors${NC}"
    if [[ -f "$JOURNAL" ]]; then
        local today
        today=$(date +%Y-%m-%d)
        local errors
        errors=$(grep -a "\"timestamp\":\"$today" "$JOURNAL" 2>/dev/null | \
            python3 -c "
import sys, json
found = []
for line in sys.stdin:
    try:
        d = json.loads(line.strip())
        act = d.get('action','').lower()
        det = d.get('details','').lower()
        if any(k in act+det for k in ['error','fail','block','conflict','timeout']):
            found.append(f'  • {d[\"action\"]}: {d.get(\"entity\",\"\")} — {d.get(\"details\",\"\")[:60]}')
    except: pass
for f in found[-5:]:
    print(f)
" 2>/dev/null)
        if [[ -n "$errors" ]]; then
            echo "$errors"
        else
            echo "  ${GREEN}None — clean run!${NC}"
        fi
    fi
}

# ── plain text output (for slack/copy) ──────────────────────────────────────
plain_standup() {
    local today
    today=$(date '+%A %B %d, %Y')
    local commits
    commits=$(cd "$BR_ROOT" && git --no-pager log \
        --oneline \
        --since="yesterday midnight" \
        --format="• %s" 2>/dev/null | head -8)

    local journal_count
    journal_count=$(grep -ac "\"timestamp\":\"$(date +%Y-%m-%d)" "$JOURNAL" 2>/dev/null || echo 0)

    local queue_count=0
    [[ -d "$BR_ROOT/shared/mesh/queue" ]] && \
        queue_count=$(ls "$BR_ROOT/shared/mesh/queue/" 2>/dev/null | wc -l | tr -d ' ')

    cat <<PLAIN
🗓️ BlackRoad Standup — $today

✅ DONE
${commits:-(nothing committed since midnight)}

📊 METRICS
• Journal entries today: $journal_count
• Task queue depth: $queue_count

🔄 IN PROGRESS
• Collaboration mesh active
• br CLI tools development ongoing

⚠️ BLOCKERS
• (none)
PLAIN
}

# ── commands ─────────────────────────────────────────────────────────────────
cmd_show() {
    echo
    echo "${VIOLET}${BOLD}◈ DAILY STANDUP${NC}  ${DIM}$(date '+%A %B %d, %Y  %H:%M')${NC}"
    hr

    echo; section_git
    echo; section_journal
    echo; section_tasks
    echo; section_mesh
    echo; section_blockers
    echo
}

cmd_copy() {
    local text
    text=$(plain_standup)
    echo "$text" | pbcopy
    echo "${GREEN}✓ Standup copied to clipboard${NC}"
    echo "$text"
}

cmd_save() {
    local label
    label="standup-$(date +%Y%m%d-%H%M)"
    local outfile="$STANDUP_DIR/${label}.md"
    plain_standup > "$outfile"
    echo "${GREEN}✓ Saved: $outfile${NC}"
}

cmd_send() {
    local target="${1:-lucidia}"
    local inbox="$BR_ROOT/shared/inbox/${target}"
    mkdir -p "$inbox"
    local ts
    ts=$(date +%s)
    local outfile="$inbox/standup-${ts}.json"
    local text
    text=$(plain_standup)
    python3 -c "
import json, sys
print(json.dumps({'type':'standup','from':'br-standup','to':sys.argv[1],'timestamp':sys.argv[2],'content':sys.argv[3]}, indent=2))
" "$target" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$text" > "$outfile"
    echo "${GREEN}✓ Standup sent to ${target}: $outfile${NC}"
}

cmd_list() {
    echo; echo "${VIOLET}◈ SAVED STANDUPS${NC}"
    ls -lh "$STANDUP_DIR/"*.md 2>/dev/null | awk '{print "  "$NF"  ("$5")"}' || \
        echo "  ${DIM}No standups yet${NC}"
}

show_help() {
    echo
    echo "${VIOLET}${BOLD}BR STANDUP${NC} — formatted daily standup from journal + git + tasks"
    echo
    echo "  ${CYAN}br standup${NC}               Show today's standup in terminal"
    echo "  ${CYAN}br standup copy${NC}          Copy plain-text standup to clipboard"
    echo "  ${CYAN}br standup save${NC}          Save to ~/.blackroad/standups/"
    echo "  ${CYAN}br standup list${NC}          List saved standups"
    echo "  ${CYAN}br standup send <inst>${NC}   Send to instance inbox"
    echo
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-show}" in
    show|"") cmd_show ;;
    copy)    cmd_copy ;;
    save)    cmd_save ;;
    list)    cmd_list ;;
    send)    cmd_send "${2:-lucidia}" ;;
    help|--help|-h) show_help ;;
    *)       cmd_show ;;
esac
