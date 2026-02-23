#!/usr/bin/env zsh
# BR Pulse — compact live system heartbeat ticker
# br pulse [watch [N]] [once] [bar]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'
BLUE=$'\033[0;34m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
JOURNAL="$HOME/.blackroad/memory/journals/master-journal.jsonl"
INSTANCES_FILE="$BR_ROOT/coordination/collaboration/active-instances.json"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"

# ── pulse line ────────────────────────────────────────────────────────────────
pulse_line() {
    # git HEAD
    local git_head git_dirty
    git_head=$(cd "$BR_ROOT" && git --no-pager log -1 --format="%s" 2>/dev/null | cut -c1-35)
    git_dirty=$(cd "$BR_ROOT" && git status --short 2>/dev/null | wc -l | tr -d ' ')

    # journal rate (entries in last hour)
    local journal_rate=0
    if [[ -f "$JOURNAL" ]]; then
        local hour_ago
        hour_ago=$(date +%Y-%m-%dT%H)
        journal_rate=$(grep -ac "\"timestamp\":\"${hour_ago}" "$JOURNAL" 2>/dev/null || echo 0)
    fi

    # queue depth
    local queue=0
    [[ -d "$BR_ROOT/shared/mesh/queue" ]] && \
        queue=$(ls "$BR_ROOT/shared/mesh/queue/" 2>/dev/null | wc -l | tr -d ' ')

    # mesh online
    local mesh_online=0
    if [[ -f "$INSTANCES_FILE" ]]; then
        mesh_online=$(python3 -c "
import json
try:
    d=json.load(open('$INSTANCES_FILE'))
    insts=d.get('instances',d) if isinstance(d,dict) else d
    if isinstance(insts,dict): insts=list(insts.values())
    print(sum(1 for i in insts if i.get('status')=='ONLINE'))
except: print(0)
" 2>/dev/null)
    fi

    # agents active
    local agents_count=0
    [[ -d "$BR_ROOT/agents/active" ]] && \
        agents_count=$(ls "$BR_ROOT/agents/active/"*.json 2>/dev/null | wc -l | tr -d ' ')

    # ollama status
    local ollama_sym
    if curl -sf --max-time 1 "$OLLAMA_URL/api/tags" &>/dev/null; then
        ollama_sym="${GREEN}●${NC}"
    else
        ollama_sym="${RED}○${NC}"
    fi

    # cpu + mem
    local cpu mem
    cpu=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | awk '{print $3}' | tr -d '%' || echo "?")
    mem=$(python3 -c "
import subprocess, re
total_b = int(subprocess.check_output(['sysctl','-n','hw.memsize']).strip())
vm = subprocess.check_output(['vm_stat']).decode()
d = {}
for line in vm.splitlines():
    m = re.match(r'(.+?):\s+(\d+)', line)
    if m: d[m.group(1).strip()] = int(m.group(2)) * 4096
used = d.get('Pages active',0) + d.get('Pages wired down',0)
print(f'{used/1e9:.1f}G/{total_b/1e9:.0f}G')

" 2>/dev/null || echo "?")

    local ts
    ts=$(date '+%H:%M:%S')

    printf "${DIM}%s${NC}  " "$ts"
    printf "${VIOLET}git${NC} ${DIM}%s${NC} ${AMBER}+%s${NC}  " "${git_head:0:30}" "$git_dirty"
    printf "${CYAN}queue${NC} %s  " "$queue"
    printf "${BLUE}mesh${NC} %s  " "$mesh_online"
    printf "${PINK}agents${NC} %s  " "$agents_count"
    printf "ollama %b  " "$ollama_sym"
    printf "${DIM}cpu${NC} %s%%  ${DIM}mem${NC} %s\n" "$cpu" "$mem"
}

# ── full pulse panel ──────────────────────────────────────────────────────────
pulse_panel() {
    local ts
    ts=$(date '+%A %b %d  %H:%M:%S')

    # git
    local branch sha msg dirty ahead
    branch=$(cd "$BR_ROOT" && git branch --show-current 2>/dev/null || echo "?")
    sha=$(cd "$BR_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "?")
    msg=$(cd "$BR_ROOT" && git --no-pager log -1 --format="%s" 2>/dev/null | cut -c1-50)
    dirty=$(cd "$BR_ROOT" && git status --short 2>/dev/null | wc -l | tr -d ' ')

    # journal
    local j_total j_today j_rate
    j_total=0; j_today=0; j_rate=0
    if [[ -f "$JOURNAL" ]]; then
        j_total=$(wc -l < "$JOURNAL" | tr -d ' ')
        j_today=$(grep -ac "\"timestamp\":\"$(date +%Y-%m-%d)" "$JOURNAL" 2>/dev/null | tr -d ' \n' || echo 0)
        j_rate=$(grep -ac "\"timestamp\":\"$(date +%Y-%m-%dT%H)" "$JOURNAL" 2>/dev/null | tr -d ' \n' || echo 0)
    fi

    # queue
    local queue=0
    [[ -d "$BR_ROOT/shared/mesh/queue" ]] && \
        queue=$(ls "$BR_ROOT/shared/mesh/queue/" 2>/dev/null | wc -l | tr -d ' ')

    # mesh
    local mesh_online mesh_total
    mesh_online=0; mesh_total=0
    if [[ -f "$INSTANCES_FILE" ]]; then
        eval $(python3 -c "
import json
try:
    d=json.load(open('$INSTANCES_FILE'))
    insts=d.get('instances',d) if isinstance(d,dict) else d
    if isinstance(insts,dict): insts=list(insts.values())
    online=sum(1 for i in insts if i.get('status')=='ONLINE')
    print(f'mesh_online={online}; mesh_total={len(insts)}')
except: print('mesh_online=0; mesh_total=0')
" 2>/dev/null)
    fi

    # agents
    local agents_count=0
    [[ -d "$BR_ROOT/agents/active" ]] && \
        agents_count=$(ls "$BR_ROOT/agents/active/"*.json 2>/dev/null | wc -l | tr -d ' ')

    # ollama
    local ollama_status ollama_models
    if curl -sf --max-time 1 "$OLLAMA_URL/api/tags" &>/dev/null; then
        ollama_status="${GREEN}ONLINE${NC}"
        ollama_models=$(curl -sf --max-time 3 "$OLLAMA_URL/api/tags" | \
            python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('models',[])))" 2>/dev/null || echo "?")
    else
        ollama_status="${RED}OFFLINE${NC}"
        ollama_models="0"
    fi

    # cpu + mem
    local cpu mem
    cpu=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | awk '{print $3}' | tr -d '%' || echo "?")
    mem=$(python3 -c "
import subprocess, re
total_bytes = int(subprocess.check_output(['sysctl','-n','hw.memsize']).strip())
vm = subprocess.check_output(['vm_stat']).decode()
page_size = 4096
d = {}
for line in vm.splitlines():
    m = re.match(r'(.+?):\s+(\d+)', line)
    if m: d[m.group(1).strip()] = int(m.group(2)) * page_size
used = d.get('Pages active',0) + d.get('Pages wired down',0)
print(f'{used/1e9:.1f}G/{total_bytes/1e9:.0f}G')
" 2>/dev/null || echo "?")

    local W=68
    local line
    line=$(printf '─%.0s' {1..$W})

    echo
    echo "${VIOLET}${BOLD}◈ BLACKROAD PULSE${NC}  ${DIM}${ts}${NC}"
    echo "${DIM}${line}${NC}"
    printf "  ${YELLOW}%-12s${NC} %s  ${DIM}[%s]${NC} %s  ${AMBER}+%s dirty${NC}\n" \
        "git" "$branch" "$sha" "${msg:0:35}" "$dirty"
    printf "  ${YELLOW}%-12s${NC} ${j_total} total  ${GREEN}${j_today} today${NC}  ${DIM}${j_rate}/hr${NC}\n" \
        "journal"
    printf "  ${YELLOW}%-12s${NC} %s tasks pending\n" "queue" "$queue"
    printf "  ${YELLOW}%-12s${NC} %s/%s ONLINE\n" "mesh" "$mesh_online" "$mesh_total"
    printf "  ${YELLOW}%-12s${NC} %s active\n" "agents" "$agents_count"
    printf "  ${YELLOW}%-12s${NC} %b  %s models\n" "ollama" "$ollama_status" "$ollama_models"
    printf "  ${YELLOW}%-12s${NC} cpu %s%%  mem %s\n" "system" "$cpu" "$mem"
    echo "${DIM}${line}${NC}"
    echo
}

# ── spark bar (single line for tmux etc) ────────────────────────────────────
pulse_bar() {
    local j_today queue mesh_online agents_count ollama_dot git_dirty

    j_today=$(grep -ac "\"timestamp\":\"$(date +%Y-%m-%d)" "$JOURNAL" 2>/dev/null || echo 0)
    queue=0
    [[ -d "$BR_ROOT/shared/mesh/queue" ]] && \
        queue=$(ls "$BR_ROOT/shared/mesh/queue/" 2>/dev/null | wc -l | tr -d ' ')
    mesh_online=0
    [[ -f "$INSTANCES_FILE" ]] && mesh_online=$(python3 -c "
import json
try:
    d=json.load(open('$INSTANCES_FILE'))
    insts=d.get('instances',d) if isinstance(d,dict) else d
    if isinstance(insts,dict): insts=list(insts.values())
    print(sum(1 for i in insts if i.get('status')=='ONLINE'))
except: print(0)" 2>/dev/null)
    agents_count=0
    [[ -d "$BR_ROOT/agents/active" ]] && \
        agents_count=$(ls "$BR_ROOT/agents/active/"*.json 2>/dev/null | wc -l | tr -d ' ')
    git_dirty=$(cd "$BR_ROOT" && git status --short 2>/dev/null | wc -l | tr -d ' ')

    if curl -sf --max-time 1 "$OLLAMA_URL/api/tags" &>/dev/null; then
        ollama_dot="●"
    else
        ollama_dot="○"
    fi

    printf "BR %s │ j:%s q:%s mesh:%s agents:%s ollama:%s\n" \
        "$(date +%H:%M)" "$j_today" "$queue" "$mesh_online" "$agents_count" "$ollama_dot"
}

# ── watch mode ────────────────────────────────────────────────────────────────
cmd_watch() {
    local interval="${1:-5}"
    while true; do
        clear
        pulse_panel
        printf "  ${DIM}Refreshing every ${interval}s — Ctrl+C to stop${NC}\n\n"
        sleep "$interval"
    done
}

# ── help ──────────────────────────────────────────────────────────────────────
show_help() {
    echo
    echo "${VIOLET}${BOLD}BR PULSE${NC} — compact live system heartbeat"
    echo
    echo "  ${CYAN}br pulse${NC}              Full pulse panel (one shot)"
    echo "  ${CYAN}br pulse watch [N]${NC}    Live refresh every N seconds (default 5)"
    echo "  ${CYAN}br pulse line${NC}         Single-line ticker (for scripts/tmux)"
    echo "  ${CYAN}br pulse bar${NC}          Minimal status bar string"
    echo
}

# ── dispatch ──────────────────────────────────────────────────────────────────
case "${1:-panel}" in
    panel|show|"") pulse_panel ;;
    watch|live)    cmd_watch "${2:-5}" ;;
    line|tick)     pulse_line ;;
    bar|tmux)      pulse_bar ;;
    help|--help|-h) show_help ;;
    [0-9]*)        cmd_watch "$1" ;;
    *)             pulse_panel ;;
esac
