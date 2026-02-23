#!/usr/bin/env zsh
# BR Task Queue — post, list, claim, complete agent tasks
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

TASKS_DB="$HOME/.blackroad/agent-tasks.db"

init_db() {
    mkdir -p "$(dirname "$TASKS_DB")"
    sqlite3 "$TASKS_DB" <<'EOF'
CREATE TABLE IF NOT EXISTS tasks (
    id           TEXT PRIMARY KEY,
    title        TEXT NOT NULL,
    description  TEXT,
    assigned_to  TEXT,
    status       TEXT DEFAULT 'pending',
    priority     INTEGER DEFAULT 5,
    result       TEXT,
    created_at   INTEGER DEFAULT (strftime('%s','now')),
    claimed_at   INTEGER,
    completed_at INTEGER
);
CREATE TABLE IF NOT EXISTS agent_log (
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    agent TEXT,
    event TEXT,
    detail TEXT,
    ts    INTEGER DEFAULT (strftime('%s','now'))
);
EOF
}

cmd_post() {
    local title=$1
    local desc=${2:-""}
    local agent=${3:-""}
    local priority=${4:-5}

    if [[ -z "$title" ]]; then
        echo "${RED}Usage: br task post <title> [description] [agent] [priority]${NC}"
        exit 1
    fi

    init_db
    local id="task_$(date +%s)_$$"
    sqlite3 "$TASKS_DB" "INSERT INTO tasks (id,title,description,assigned_to,priority) VALUES ('${id}','${title//\'/\'\'}','${desc//\'/\'\'}','${agent}',${priority});"
    echo "${GREEN}✓ Task posted${NC}  id=${id}"
    [[ -n "$agent" ]] && echo "  assigned → ${agent}"
}

cmd_list() {
    local filter=${1:-all}
    init_db
    echo ""
    echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo "${CYAN}║  📋 TASK QUEUE                                               ║${NC}"
    echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"

    local where="1=1"
    case $filter in
        pending)    where="status='pending'" ;;
        active)     where="status='in_progress'" ;;
        done)       where="status='done'" ;;
        failed)     where="status='failed'" ;;
    esac

    local rows=$(sqlite3 "$TASKS_DB" "
        SELECT id, title, assigned_to, status, priority,
               datetime(created_at,'unixepoch','localtime')
        FROM tasks WHERE $where
        ORDER BY priority DESC, created_at ASC
        LIMIT 25;" 2>/dev/null)

    if [[ -z "$rows" ]]; then
        echo "${CYAN}║${NC}  ${YELLOW}No tasks found.${NC}"
        echo "${CYAN}║${NC}  Post one: ${CYAN}br task post \"My task\"${NC}"
    else
        while IFS='|' read -r id title agent_name task_status priority created; do
            local status_color="$YELLOW"
            local status_icon="⏳"
            case $task_status in
                done)        status_color="$GREEN";  status_icon="✓" ;;
                in_progress) status_color="$CYAN";   status_icon="⚡" ;;
                failed)      status_color="$RED";    status_icon="✗" ;;
                pending)     status_color="$YELLOW"; status_icon="⏳" ;;
            esac
            local agent_str="${agent_name:-unassigned}"
            echo "${CYAN}║${NC}  ${status_icon} ${title}"
            echo "${CYAN}║${NC}    id: ${id}  priority: ${priority}  agent: ${agent_str}"
            echo "${CYAN}║${NC}    status: ${status_color}${task_status}${NC}  created: ${created}"
            echo "${CYAN}║${NC}"
        done <<< "$rows"
    fi

    # Counts
    local counts=$(sqlite3 "$TASKS_DB" "
        SELECT
            SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END),
            SUM(CASE WHEN status='in_progress' THEN 1 ELSE 0 END),
            SUM(CASE WHEN status='done' THEN 1 ELSE 0 END)
        FROM tasks;" 2>/dev/null)
    local p=$(echo $counts | cut -d'|' -f1)
    local a=$(echo $counts | cut -d'|' -f2)
    local d=$(echo $counts | cut -d'|' -f3)

    echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo "${CYAN}║${NC}  ${YELLOW}${p:-0} pending${NC}  ${CYAN}${a:-0} active${NC}  ${GREEN}${d:-0} done${NC}"
    echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

cmd_assign() {
    local id=$1 agent=${2:u}
    if [[ -z "$id" || -z "$agent" ]]; then
        echo "${RED}Usage: br task assign <id> <agent>${NC}"; exit 1
    fi
    init_db
    sqlite3 "$TASKS_DB" "UPDATE tasks SET assigned_to='${agent}' WHERE id='${id}';"
    echo "${GREEN}✓ Assigned ${id} → ${agent}${NC}"
}

cmd_claim() {
    local id=$1 agent=${2:-MANUAL}
    if [[ -z "$id" ]]; then echo "${RED}Usage: br task claim <id> [agent]${NC}"; exit 1; fi
    init_db
    sqlite3 "$TASKS_DB" "UPDATE tasks SET status='in_progress', assigned_to='${agent}', claimed_at=strftime('%s','now') WHERE id='${id}' AND status='pending';"
    echo "${GREEN}✓ Claimed by ${agent}${NC}"
}

cmd_done() {
    local id=$1
    shift
    local result="${*:-completed}"
    if [[ -z "$id" ]]; then echo "${RED}Usage: br task done <id> [result]${NC}"; exit 1; fi
    init_db
    local safe=$(echo "$result" | sed "s/'/''/g")
    sqlite3 "$TASKS_DB" "UPDATE tasks SET status='done', result='${safe}', completed_at=strftime('%s','now') WHERE id='${id}';"
    echo "${GREEN}✓ Task ${id} marked done${NC}"
}

cmd_result() {
    local id=$1
    init_db
    local result=$(sqlite3 "$TASKS_DB" "SELECT result FROM tasks WHERE id='${id}';" 2>/dev/null)
    if [[ -z "$result" ]]; then
        echo "${YELLOW}No result yet for ${id}${NC}"
    else
        echo "${CYAN}Result for ${id}:${NC}"
        echo "$result"
    fi
}

cmd_clear() {
    init_db
    sqlite3 "$TASKS_DB" "DELETE FROM tasks WHERE status='done';"
    echo "${GREEN}✓ Cleared completed tasks${NC}"
}

# Sync task DB to/from Pi nodes
cmd_sync() {
    local PI_KEY="$HOME/.ssh/br_mesh_ed25519"
    local PI_USER="pi"
    local NODES=("192.168.4.38")
    local PI_DB="/home/pi/.blackroad/task_queue.db"
    local MERGED_DB="/tmp/br-tasks-merge.db"
    local synced=0

    init_db

    for node in $NODES; do
        ping -c 1 -W 2 "$node" > /dev/null 2>&1 || { echo "${YELLOW}⚠ $node unreachable, skipping${NC}"; continue }

        echo "${CYAN}⟳ Syncing with $node...${NC}"

        # Push new pending tasks to Pi (tasks Pi doesn't have yet)
        local new_tasks=$(sqlite3 "$TASKS_DB" "SELECT id,title,description,assigned_to,status,priority,created_at FROM tasks WHERE status='pending';" 2>/dev/null)
        if [[ -n "$new_tasks" ]]; then
            while IFS='|' read -r id title desc agent tstatus pri cat; do
                ssh -i "$PI_KEY" -o ConnectTimeout=5 "$PI_USER@$node" \
                    "sqlite3 ~/.blackroad/task_queue.db \"INSERT OR IGNORE INTO tasks(id,title,description,assigned_to,status,priority,created_at) VALUES('$id','${title//\'/\'\'}','${desc//\'/\'\'}','$agent','$tstatus',$pri,$cat);\"" 2>/dev/null
            done <<< "$new_tasks"
            echo "${GREEN}  ↑ pushed pending tasks to $node${NC}"
        fi

        # Pull completed tasks back from Pi
        local pi_done=$(ssh -i "$PI_KEY" -o ConnectTimeout=5 "$PI_USER@$node" \
            "sqlite3 ~/.blackroad/task_queue.db \"SELECT id,result,completed_at FROM tasks WHERE status='done';\"" 2>/dev/null)
        if [[ -n "$pi_done" ]]; then
            local count=0
            while IFS='|' read -r id result cat; do
                sqlite3 "$TASKS_DB" "UPDATE tasks SET status='done', result='${result//\'/\'\'}', completed_at=$cat WHERE id='$id' AND status!='done';" 2>/dev/null
                ((count++))
            done <<< "$pi_done"
            [[ $count -gt 0 ]] && echo "${GREEN}  ↓ pulled $count completed tasks from $node${NC}"
        fi

        # Show Pi fleet status
        local pi_agents=$(ssh -i "$PI_KEY" -o ConnectTimeout=5 "$PI_USER@$node" \
            "for f in ~/.blackroad/agents/active/*.json 2>/dev/null; do python3 -c \"import json; d=json.load(open('\$f')); print(d['name'],d.get('status','?'))\"; done" 2>/dev/null)
        [[ -n "$pi_agents" ]] && echo "${BLUE}  Pi agents: $pi_agents${NC}"

        ((synced++))
    done

    echo "${GREEN}✓ Synced $synced node(s)${NC}"
}

# Watch: auto-sync every N seconds
cmd_watch_sync() {
    local interval=${1:-30}
    echo "${CYAN}⟳ Auto-sync every ${interval}s (Ctrl+C to stop)${NC}"
    while true; do
        cmd_sync
        sleep "$interval"
    done
}

show_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR TASKS${NC}  ${DIM}Dispatch work. Track outcomes.${NC}"
  echo -e "  ${DIM}Autonomous agents, on your command.${NC}"
  echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  post <title>                  ${NC} Post a new task to the marketplace"
  echo -e "  ${AMBER}  list                          ${NC} List available tasks"
  echo -e "  ${AMBER}  claim <id>                    ${NC} Claim a task"
  echo -e "  ${AMBER}  complete <id>                 ${NC} Mark a task complete"
  echo -e "  ${AMBER}  status                        ${NC} Marketplace overview"
  echo -e "  ${AMBER}  mine                          ${NC} Tasks claimed by you"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br tasks post "Deploy API to staging"${NC}"
  echo -e "  ${DIM}  br tasks list${NC}"
  echo -e "  ${DIM}  br tasks claim task-001${NC}"
  echo -e "  ${DIM}  br tasks complete task-001${NC}"
  echo -e ""
}

case "${1:-list}" in
    post|add)        cmd_post "$2" "$3" "$4" "$5" ;;
    list|ls)         cmd_list "$2" ;;
    assign)          cmd_assign "$2" "$3" ;;
    claim)           cmd_claim "$2" "$3" ;;
    done|complete)   cmd_done "$2" "${@:3}" ;;
    result|show)     cmd_result "$2" ;;
    clear|clean)     cmd_clear ;;
    sync)            cmd_sync ;;
    watch)           cmd_watch_sync "$2" ;;
    help|-h)         show_help ;;
    *)               show_help ;;
esac
