#!/usr/bin/env zsh
# BR Agent Runtime — persistent agent daemon with task queue
# br runtime start <agent> [model]
# br runtime stop <agent>
# br runtime status
# br runtime ps

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; NC='\033[0m'

AGENTS_DIR="/Users/alexa/blackroad/agents"
STATE_DIR="${AGENTS_DIR}/active"
IDLE_DIR="${AGENTS_DIR}/idle"
PROC_DIR="${AGENTS_DIR}/processing"
ARCHIVE_DIR="${AGENTS_DIR}/archive"
TASKS_DB="$HOME/.blackroad/agent-tasks.db"
RUNTIME_LOG="$HOME/.blackroad/runtime.log"

# Agent color map
agent_color() {
    case $1 in
        LUCIDIA|lucidia)   echo "$CYAN" ;;
        OCTAVIA|octavia)   echo "$MAGENTA" ;;
        ALICE|alice)       echo "$GREEN" ;;
        ARIA|aria)         echo "$BLUE" ;;
        SHELLFISH|shellfish) echo "$RED" ;;
        CIPHER|cipher)     echo "$YELLOW" ;;
        *)                 echo "$NC" ;;
    esac
}

# Agent model map
agent_model() {
    case ${1:u} in
        LUCIDIA)   echo "lucidia:latest" ;;
        OCTAVIA)   echo "llama3.1:latest" ;;
        ALICE)     echo "llama3.2:3b" ;;
        ARIA)      echo "qwen2.5:1.5b" ;;
        SHELLFISH) echo "llama3.2:1b" ;;
        CIPHER)    echo "qwen2.5:1.5b" ;;
        *)         echo "llama3.2:3b" ;;
    esac
}

# Short persona description for task prompts
agent_persona() {
    case ${1:u} in
        LUCIDIA)   echo "a philosophical AI dreamer — creative, visionary, contemplative" ;;
        OCTAVIA)   echo "a systems architect — technical, precise, infrastructure-focused" ;;
        ALICE)     echo "an efficient operator — practical, fast, automation-oriented" ;;
        ARIA)      echo "a UI/UX interface agent — design-minded, user-focused, clear" ;;
        SHELLFISH) echo "a security hacker — paranoid, exploit-aware, adversarial thinking" ;;
        CIPHER)    echo "a security guardian — vigilant, encrypted, trust-nothing mindset" ;;
        *)         echo "a general-purpose AI agent" ;;
    esac
}

init_db() {
    mkdir -p "$(dirname "$TASKS_DB")" "$STATE_DIR" "$IDLE_DIR" "$PROC_DIR" "$ARCHIVE_DIR"
    sqlite3 "$TASKS_DB" <<'EOF'
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS tasks (
    id          TEXT PRIMARY KEY,
    title       TEXT NOT NULL,
    description TEXT,
    assigned_to TEXT,
    status      TEXT DEFAULT 'pending',
    priority    INTEGER DEFAULT 5,
    result      TEXT,
    created_at  INTEGER DEFAULT (strftime('%s','now')),
    claimed_at  INTEGER,
    completed_at INTEGER
);
CREATE TABLE IF NOT EXISTS agent_log (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    agent       TEXT,
    event       TEXT,
    detail      TEXT,
    ts          INTEGER DEFAULT (strftime('%s','now'))
);
EOF
}

write_state() {
    local agent=${1:u}
    local model=$2
    local pid=$3
    local agent_status=${4:-idle}
    local task_id=${5:-null}
    local host=${6:-local}

    cat > "${STATE_DIR}/${agent}.json" <<EOF
{
    "name": "${agent}",
    "model": "${model}",
    "pid": ${pid},
    "status": "${agent_status}",
    "host": "${host}",
    "endpoint": "http://localhost:11434",
    "current_task": ${task_id},
    "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

remove_state() {
    local agent=${1:u}
    local state_file="${STATE_DIR}/${agent}.json"
    if [[ -f "$state_file" ]]; then
        mv "$state_file" "${ARCHIVE_DIR}/${agent}_$(date +%s).json"
    fi
}

log_event() {
    local agent=$1 event=$2 detail=$3
    sqlite3 "$TASKS_DB" "INSERT INTO agent_log (agent,event,detail) VALUES ('$agent','$event','$detail');" 2>/dev/null
    echo "[$(date '+%H:%M:%S')] [$agent] $event — $detail" >> "$RUNTIME_LOG"
}

# ─── DAEMON LOOP ─────────────────────────────────────────────────────────────
# Runs as background process for an agent
# Polls task queue, sends to ollama, updates state
run_daemon() {
    local agent=${1:u}
    local model=$2
    local pid=$$

    init_db
    write_state "$agent" "$model" "$pid" "idle" "null" "local"
    log_event "$agent" "STARTED" "model=$model pid=$pid"

    trap "remove_state $agent; log_event $agent STOPPED 'daemon exited'; exit 0" TERM INT

    echo "" >> "$RUNTIME_LOG"
    log_event "$agent" "READY" "polling task queue..."

    while true; do
        # Poll for unclaimed task assigned to this agent (or unassigned)
        local task=$(sqlite3 "$TASKS_DB" "
            SELECT id, title, description FROM tasks
            WHERE status='pending'
              AND (assigned_to='${agent}' OR assigned_to IS NULL OR assigned_to='')
            ORDER BY priority DESC, created_at ASC
            LIMIT 1;" 2>/dev/null)

        if [[ -n "$task" ]]; then
            local task_id=$(echo "$task" | cut -d'|' -f1)
            local task_title=$(echo "$task" | cut -d'|' -f2)
            local task_desc=$(echo "$task" | cut -d'|' -f3)

            # Claim it
            sqlite3 "$TASKS_DB" "UPDATE tasks SET status='in_progress', assigned_to='${agent}', claimed_at=strftime('%s','now') WHERE id='${task_id}';" 2>/dev/null
            write_state "$agent" "$model" "$pid" "working" "\"${task_id}\"" "local"
            log_event "$agent" "CLAIMED" "task=$task_id: $task_title"

            # Run through ollama — 90s max, 5s connect timeout
            local prompt="You are ${agent}, a BlackRoad OS AI agent. Your personality: $(agent_persona $agent). Task: ${task_title}. ${task_desc}. Reply concisely in 2-3 sentences."
            local result=$(curl -s --connect-timeout 5 --max-time 90 \
                http://localhost:11434/api/generate \
                -d "{\"model\":\"${model}\",\"prompt\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$prompt" 2>/dev/null),\"stream\":false}" \
                2>/dev/null | python3 -c "import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('response','').strip()[:600])
except:
    pass" 2>/dev/null)

            if [[ -n "$result" ]]; then
                # Escape result for SQLite
                local safe_result=$(python3 -c "import sys; print(sys.stdin.read().replace(\"'\",\"''\"))" <<< "$result" 2>/dev/null)
                sqlite3 "$TASKS_DB" "UPDATE tasks SET status='done', result='${safe_result}', completed_at=strftime('%s','now') WHERE id='${task_id}';" 2>/dev/null
                log_event "$agent" "COMPLETED" "task=$task_id"
            else
                sqlite3 "$TASKS_DB" "UPDATE tasks SET status='pending', assigned_to=NULL WHERE id='${task_id}';" 2>/dev/null
                log_event "$agent" "FAILED" "task=$task_id (ollama timeout/unavailable — requeueing)"
            fi

            write_state "$agent" "$model" "$pid" "idle" "null" "local"
        fi

        sleep 5
    done
}

# ─── COMMANDS ────────────────────────────────────────────────────────────────

cmd_start() {
    local agent=${1:u}
    local model=${2:-$(agent_model "$1")}
    local color=$(agent_color "$agent")

    if [[ -z "$agent" ]]; then
        echo "${RED}Usage: br runtime start <agent> [model]${NC}"
        echo "Agents: LUCIDIA OCTAVIA ALICE ARIA SHELLFISH CIPHER"
        exit 1
    fi

    init_db

    # Check if already running
    if [[ -f "${STATE_DIR}/${agent}.json" ]]; then
        local existing_pid=$(python3 -c "import json; d=json.load(open('${STATE_DIR}/${agent}.json')); print(d['pid'])" 2>/dev/null)
        if kill -0 "$existing_pid" 2>/dev/null; then
            echo "${YELLOW}⚡ ${agent} already running (pid $existing_pid)${NC}"
            return 0
        fi
    fi

    echo "${color}◆ Starting ${agent}...${NC}"

    # Launch daemon in background using explicit script path
    local SCRIPT_PATH="${BR_TOOLS_DIR:-/Users/alexa/blackroad/tools}/agent-runtime/br-runtime.sh"
    zsh "$SCRIPT_PATH" _daemon "$agent" "$model" &
    local daemon_pid=$!

    sleep 1

    if kill -0 "$daemon_pid" 2>/dev/null; then
        echo "${GREEN}✓ ${agent} is ONLINE${NC}  model=${model}  pid=${daemon_pid}"
        log_event "$agent" "LAUNCH" "pid=$daemon_pid model=$model"
    else
        echo "${RED}✗ Failed to start ${agent}${NC}"
    fi
}

cmd_stop() {
    local agent=${1:u}
    if [[ -z "$agent" ]]; then
        echo "${RED}Usage: br runtime stop <agent>${NC}"; exit 1
    fi

    local state_file="${STATE_DIR}/${agent}.json"
    if [[ ! -f "$state_file" ]]; then
        echo "${YELLOW}${agent} is not running${NC}"; return 0
    fi

    local pid=$(python3 -c "import json; d=json.load(open('${state_file}')); print(d['pid'])" 2>/dev/null)
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        sleep 1
        echo "${GREEN}✓ ${agent} stopped${NC}"
    else
        remove_state "$agent"
        echo "${YELLOW}${agent} was not running (cleaned up stale state)${NC}"
    fi
}

cmd_stop_all() {
    echo "${CYAN}Stopping all agents...${NC}"
    for f in "${STATE_DIR}"/*.json; do
        [[ -f "$f" ]] || continue
        local name=$(basename "$f" .json)
        cmd_stop "$name"
    done
}

cmd_status() {
    init_db
    echo ""
    echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo "${CYAN}║  ◆ BLACKROAD AGENT RUNTIME                                   ║${NC}"
    echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"

    local count=0
    for f in "${STATE_DIR}"/*.json(N); do
        [[ -f "$f" ]] || continue
        local name=$(python3 -c "import json; d=json.load(open('$f')); print(d['name'])" 2>/dev/null)
        local model=$(python3 -c "import json; d=json.load(open('$f')); print(d['model'])" 2>/dev/null)
        local agent_status=$(python3 -c "import json; d=json.load(open('$f')); print(d['status'])" 2>/dev/null)
        local pid=$(python3 -c "import json; d=json.load(open('$f')); print(d['pid'])" 2>/dev/null)
        local task=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('current_task') or '-')" 2>/dev/null)
        local started=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('started_at','?')[:19])" 2>/dev/null)
        local color=$(agent_color "$name")

        # Verify process is alive
        local alive_str="${GREEN}●${NC}"
        kill -0 "$pid" 2>/dev/null || alive_str="${RED}●${NC}"

        local status_str="${GREEN}${agent_status}${NC}"
        [[ "$agent_status" == "working" ]] && status_str="${YELLOW}${agent_status}${NC}"

        echo "${CYAN}║${NC}  ${alive_str} ${color}${name}${NC}"
        echo "${CYAN}║${NC}    model:   ${model}"
        echo "${CYAN}║${NC}    status:  ${status_str}"
        echo "${CYAN}║${NC}    pid:     ${pid}  |  started: ${started}"
        [[ "$task" != "null" && "$task" != "-" ]] && echo "${CYAN}║${NC}    task:    ${task}"
        echo "${CYAN}║${NC}"
        ((count++))
    done

    if [[ $count -eq 0 ]]; then
        echo "${CYAN}║${NC}  ${YELLOW}No agents running.${NC}"
        echo "${CYAN}║${NC}  Run: ${CYAN}br runtime start LUCIDIA${NC}"
        echo "${CYAN}║${NC}"
    fi

    # Task queue summary
    local pending=$(sqlite3 "$TASKS_DB" "SELECT COUNT(*) FROM tasks WHERE status='pending';" 2>/dev/null || echo 0)
    local active=$(sqlite3 "$TASKS_DB" "SELECT COUNT(*) FROM tasks WHERE status='in_progress';" 2>/dev/null || echo 0)
    local done=$(sqlite3 "$TASKS_DB" "SELECT COUNT(*) FROM tasks WHERE status='done';" 2>/dev/null || echo 0)

    echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo "${CYAN}║${NC}  TASK QUEUE  ${YELLOW}${pending} pending${NC}  ${GREEN}${active} active${NC}  ${BLUE}${done} done${NC}"
    echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

cmd_ps() {
    echo "${CYAN}Agent processes:${NC}"
    for f in "${STATE_DIR}"/*.json(N); do
        [[ -f "$f" ]] || continue
        local name=$(python3 -c "import json; d=json.load(open('$f')); print(d['name'])" 2>/dev/null)
        local pid=$(python3 -c "import json; d=json.load(open('$f')); print(d['pid'])" 2>/dev/null)
        if kill -0 "$pid" 2>/dev/null; then
            echo "  ${GREEN}●${NC} ${name} (pid ${pid})"
        else
            echo "  ${RED}✗${NC} ${name} (pid ${pid} — dead)"
        fi
    done
}

cmd_logs() {
    local agent=${1:u}
    if [[ -n "$agent" ]]; then
        grep "\[$agent\]" "$RUNTIME_LOG" 2>/dev/null | tail -20
    else
        tail -30 "$RUNTIME_LOG" 2>/dev/null || echo "No runtime logs yet"
    fi
}

show_help() {
    echo "${CYAN}Usage: br runtime <command>${NC}"
    echo ""
    echo "  start <agent> [model]  — Start agent daemon"
    echo "  stop <agent>           — Stop agent daemon"
    echo "  stop-all               — Stop all agents"
    echo "  status                 — Show all running agents + task queue"
    echo "  ps                     — List agent processes"
    echo "  logs [agent]           — Show runtime logs"
    echo ""
    echo "Agents: LUCIDIA  OCTAVIA  ALICE  ARIA  SHELLFISH  CIPHER"
}

case "${1:-status}" in
    start)      cmd_start "$2" "$3" ;;
    stop)       cmd_stop "$2" ;;
    stop-all)   cmd_stop_all ;;
    status|st)  cmd_status ;;
    ps)         cmd_ps ;;
    logs)       cmd_logs "$2" ;;
    _daemon)    run_daemon "$2" "$3" ;;   # internal use
    help|-h)    show_help ;;
    *)          show_help ;;
esac
