#!/usr/bin/env zsh
# BR Fleet Dashboard — live view of all agents across all nodes

GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'; BLUE=$'\033[0;34m'; MAGENTA=$'\033[0;35m'
BOLD=$'\033[1m'; DIM=$'\033[2m'; NC=$'\033[0m'

TASKS_DB="$HOME/.blackroad/agent-tasks.db"
AGENTS_DIR="/Users/alexa/blackroad/agents/active"
PI_KEY="$HOME/.ssh/br_mesh_ed25519"
PI_NODES=("pi@192.168.4.38")

# Status color
sc() {
    case "$1" in
        idle)       echo "${GREEN}● idle${NC}" ;;
        working)    echo "${YELLOW}⚙ working${NC}" ;;
        dead|*)     echo "${RED}✗ dead${NC}" ;;
    esac
}

# Node status badge
node_badge() { echo "${BOLD}${BLUE}[$1]${NC}"; }

render_local_agents() {
    printf "${BOLD}${BLUE}[MAC · localhost]${NC}\n"
    local count=0 data name model pid astatus task dot status_str
    for f in $AGENTS_DIR/*.json(N); do
        data=$(python3 -c "
import json
d = json.load(open('$f'))
t = d.get('current_task') or ''
print(d['name']+'|'+d.get('model','?')+'|'+str(d.get('pid',0))+'|'+d.get('status','idle')+'|'+t)
" 2>/dev/null) || continue
        name="${data%%|*}";   local r1="${data#*|}"
        model="${r1%%|*}";    local r2="${r1#*|}"
        pid="${r2%%|*}";      local r3="${r2#*|}"
        astatus="${r3%%|*}";  task="${r3#*|}"

        kill -0 "$pid" 2>/dev/null || astatus="dead"

        case "$astatus" in
            idle)    dot="${GREEN}●${NC}"; status_str="idle" ;;
            working) dot="${YELLOW}⚙${NC}"; status_str="working" ;;
            *)       dot="${RED}✗${NC}"; status_str="dead" ;;
        esac

        printf "  ${BOLD}%-10s${NC} ${DIM}%-22s${NC} ${dot} %-8s" "$name" "$model" "$status_str"
        [[ -n "$task" && "$astatus" == "working" ]] && printf "${DIM}→ %s${NC}" "${task:0:25}"
        printf "\n"
        ((count++))
    done
    [[ $count -eq 0 ]] && printf "  ${DIM}no local agents — run: br wake LUCIDIA${NC}\n"
}

render_pi_agents() {
    for node_addr in $PI_NODES; do
        local ip="${node_addr#*@}"
        printf "$(node_badge "PI · $ip")"
        ping -c 1 -W 1 "$ip" > /dev/null 2>&1 || { echo " ${RED}unreachable${NC}"; continue }
        echo ""

        local raw=$(ssh -i "$PI_KEY" -o ConnectTimeout=3 -o BatchMode=yes "$node_addr" \
            'for f in ~/.blackroad/agents/active/*.json; do [[ -f "$f" ]] || continue; python3 -c "import json; d=json.load(open('"'"'$f'"'"')); print(d['"'"'name'"'"'],d.get('"'"'model'"'"','"'"'?'"'"'),d.get('"'"'pid'"'"',0),d.get('"'"'status'"'"','"'"'idle'"'"'),d.get('"'"'current_task'"'"') or '"'"''"'"')"; done' 2>/dev/null)

        if [[ -z "$raw" ]]; then
            echo "  ${DIM}no agents or SSH error${NC}"
        else
            while read -r name model pid astatus task; do
                printf "  %-10s %-20s %s" "$name" "${DIM}${model}${NC}" "$(sc $astatus)"
                [[ -n "$task" && "$task" != "None" ]] && printf "  ${DIM}→ %s${NC}" "${task:0:28}"
                printf "\n"
            done <<< "$raw"
        fi
    done
}

render_tasks() {
    [[ ! -f "$TASKS_DB" ]] && return
    echo ""
    echo "${BOLD}TASK QUEUE${NC}"
    local total pending active done_count
    total=$(sqlite3 "$TASKS_DB" "SELECT COUNT(*) FROM tasks;" 2>/dev/null || echo 0)
    pending=$(sqlite3 "$TASKS_DB" "SELECT COUNT(*) FROM tasks WHERE status='pending';" 2>/dev/null || echo 0)
    active=$(sqlite3 "$TASKS_DB" "SELECT COUNT(*) FROM tasks WHERE status='in_progress';" 2>/dev/null || echo 0)
    done_count=$(sqlite3 "$TASKS_DB" "SELECT COUNT(*) FROM tasks WHERE status='done';" 2>/dev/null || echo 0)

    echo "  Total: $total  ${YELLOW}Pending: $pending${NC}  ${CYAN}Active: $active${NC}  ${GREEN}Done: $done_count${NC}"
    echo ""

    sqlite3 "$TASKS_DB" \
        "SELECT assigned_to, status, title FROM tasks WHERE status!='done' ORDER BY priority DESC, created_at LIMIT 6;" \
        2>/dev/null | while IFS='|' read -r agent tstatus title; do
        case "$tstatus" in
            pending)     printf "  ⏸ %-10s %s\n" "$agent" "${title:0:45}" ;;
            in_progress) printf "  ⚙ %-10s %s\n" "$agent" "${title:0:45}" ;;
        esac
    done
}

render_ollama() {
    echo ""
    echo "${BOLD}OLLAMA${NC}"
    local running=$(curl -sf http://localhost:11434/api/tags 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('models',[])))" 2>/dev/null || echo "offline")
    if [[ "$running" == "offline" ]]; then
        echo "  ${RED}✗ offline${NC}"
    else
        echo "  ${GREEN}● running${NC}  ${running} models loaded"
    fi
}

cmd_once() {
    local ts=$(date '+%H:%M:%S')
    echo ""
    echo "${BOLD}${MAGENTA}◆ BLACKROAD AGENT FLEET${NC}  ${DIM}$ts${NC}"
    echo "${DIM}────────────────────────────────────────────${NC}"
    echo ""
    echo "${BOLD}AGENTS${NC}"
    render_local_agents
    render_pi_agents
    render_tasks
    render_ollama
    echo ""
}

cmd_live() {
    local interval=${1:-4}
    while true; do
        clear
        cmd_once
        echo "${DIM}Refreshing every ${interval}s — Ctrl+C to exit${NC}"
        sleep "$interval"
    done
}

case "${1:-once}" in
    live|watch) cmd_live "$2" ;;
    once|*)     cmd_once ;;
esac
