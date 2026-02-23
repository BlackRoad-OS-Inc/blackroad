#!/usr/bin/env zsh
# BR Timeline — ASCII activity timeline from journal + git + tasks
# br timeline [hours <N>] [today] [git] [journal] [tasks]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'
BLUE=$'\033[0;34m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"

# ── helpers ────────────────────────────────────────────────────────────────
hr() { echo "${DIM}────────────────────────────────────────────────────────────────────${NC}"; }

action_icon() {
    case "$1" in
        task-posted|task-assigned)  echo "📋" ;;
        task-complete*)             echo "✅" ;;
        code-change|file-edit)      echo "📝" ;;
        git-commit|git-push)        echo "🔀" ;;
        agent-spawn|agent-wake)     echo "🤖" ;;
        memory-write|memory-sync)   echo "💾" ;;
        session-start|session-end)  echo "🔌" ;;
        mesh-join|collab-join)      echo "🕸️ " ;;
        deploy|deployment)          echo "🚀" ;;
        error|failure)              echo "❌" ;;
        *)                          echo "·" ;;
    esac
}

# ── build timeline from journal ──────────────────────────────────────────────
journal_events() {
    local hours="${1:-8}"
    local today
    today=$(date +%Y-%m-%d)

    if [[ ! -f "$JOURNAL" ]]; then
        echo "  ${DIM}No journal found${NC}"
        return
    fi

    # Collect events, group by hour
    grep -a "\"timestamp\":\"$today" "$JOURNAL" 2>/dev/null | python3 -c "
import sys, json
from collections import defaultdict

events_by_hour = defaultdict(list)
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts = d.get('timestamp','')
        if len(ts) >= 13:
            hour = ts[11:13]
            action = d.get('action','?')
            entity = d.get('entity','')
            events_by_hour[hour].append((action, entity))
    except: pass

hours = sorted(events_by_hour.keys())
for h in hours:
    evts = events_by_hour[h]
    count = len(evts)
    bar_len = min(count // 2 + 1, 40)
    bar = '█' * bar_len
    # sample top actions
    from collections import Counter
    top = Counter(e[0] for e in evts).most_common(3)
    top_str = ' | '.join(f'{a}({n})' for a,n in top)
    print(f'  {h}:00  {bar:<42}  {count:>4} events  {top_str}')
" 2>/dev/null
}

# ── build timeline from git log ──────────────────────────────────────────────
git_events() {
    local hours="${1:-8}"
    cd "$BR_ROOT" 2>/dev/null || return

    git --no-pager log \
        --oneline \
        --format="%ai %s" \
        --since="${hours} hours ago" 2>/dev/null | \
    python3 -c "
import sys
for line in sys.stdin:
    parts = line.strip().split(' ', 3)
    if len(parts) < 4: continue
    hour = parts[1][:2]
    msg = parts[3][:60] if len(parts) > 3 else ''
    print(f'  {hour}:xx  \033[0;32m🔀 git\033[0m  {msg}')
"
}

# ── combined display ──────────────────────────────────────────────────────────
cmd_show() {
    local hours="${1:-8}"
    local mode="${2:-all}"

    echo
    echo "${VIOLET}${BOLD}◈ ACTIVITY TIMELINE${NC}  ${DIM}$(date '+%A %B %d, %Y')  last ${hours}h${NC}"
    hr

    local today
    today=$(date +%Y-%m-%d)
    local now_hour
    now_hour=$(date +%H)

    # Draw hour axis
    echo
    echo "  ${DIM}Hour  Activity bar                              Events  Top actions${NC}"
    echo

    if [[ -f "$JOURNAL" ]]; then
        journal_events "$hours"
    else
        echo "  ${DIM}(no journal)${NC}"
    fi

    echo
    echo "  ${DIM}── git commits ──────────────────────────────────────────────────${NC}"
    git_events "$hours"

    echo
    echo "  ${DIM}── task queue ───────────────────────────────────────────────────${NC}"
    if [[ -d "$BR_ROOT/shared/mesh/queue" ]]; then
        ls "$BR_ROOT/shared/mesh/queue/" 2>/dev/null | while read -r f; do
            printf "  ${YELLOW}📋${NC}  %s\n" "$f"
        done
        [[ -z "$(ls $BR_ROOT/shared/mesh/queue/ 2>/dev/null)" ]] && echo "  ${DIM}Queue empty${NC}"
    fi

    echo
    echo "  ${DIM}── recent journal entries ────────────────────────────────────────${NC}"
    if [[ -f "$JOURNAL" ]]; then
        tail -8 "$JOURNAL" | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts = d.get('timestamp','')[:16].replace('T',' ')
        action = d.get('action','?')[:20]
        entity = d.get('entity','')[:30]
        print(f'  {ts}  {action:<22}  {entity}')
    except: pass
" 2>/dev/null
    fi

    echo
}

# ── 24h heat map ─────────────────────────────────────────────────────────────
cmd_heatmap() {
    echo
    echo "${VIOLET}${BOLD}◈ 24H HEATMAP${NC}  ${DIM}$(date '+%Y-%m-%d')${NC}"
    hr
    echo

    if [[ ! -f "$JOURNAL" ]]; then
        echo "  ${DIM}No journal${NC}"; return
    fi

    local today
    today=$(date +%Y-%m-%d)

    grep -a "\"timestamp\":\"$today" "$JOURNAL" 2>/dev/null | python3 -c "
import sys, json
from collections import Counter

counts = Counter()
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        ts = d.get('timestamp','')
        if len(ts) >= 13:
            counts[int(ts[11:13])] += 1
    except: pass

max_c = max(counts.values()) if counts else 1
print('  Hour  Heat')
for h in range(24):
    c = counts.get(h, 0)
    bar_len = int((c / max_c) * 30) if max_c > 0 else 0
    bar = '▓' * bar_len
    marker = '◀ now' if h == int('$(date +%H)') else ''
    print(f'  {h:02d}:00  {bar:<32} {c:>5}  {marker}')
" 2>/dev/null
    echo
}

# ── watch mode ────────────────────────────────────────────────────────────────
cmd_watch() {
    local interval="${1:-10}"
    while true; do
        clear
        cmd_show 2
        echo "  ${DIM}Refreshing every ${interval}s — Ctrl+C to stop${NC}"
        sleep "$interval"
    done
}

# ── help ──────────────────────────────────────────────────────────────────────
show_help() {
    echo
    echo "${VIOLET}${BOLD}BR TIMELINE${NC} — ASCII activity timeline from journal + git + tasks"
    echo
    echo "  ${CYAN}br timeline${NC}               Last 8h timeline"
    echo "  ${CYAN}br timeline hours <N>${NC}     Last N hours"
    echo "  ${CYAN}br timeline today${NC}         Full day view"
    echo "  ${CYAN}br timeline heatmap${NC}       24h heat map"
    echo "  ${CYAN}br timeline watch [N]${NC}     Live refresh every N seconds"
    echo
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-show}" in
    show|"")      cmd_show 8 ;;
    today)        cmd_show 24 ;;
    hours)        cmd_show "${2:-8}" ;;
    heatmap|heat) cmd_heatmap ;;
    watch)        cmd_watch "${2:-10}" ;;
    help|--help|-h) show_help ;;
    *)            cmd_show "${1}" ;;
esac
