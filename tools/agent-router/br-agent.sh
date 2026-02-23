#!/usr/bin/env zsh

# Brand palette
AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
BLUE='\033[38;5;69m'
GREEN='\033[0;32m'
RED='\033[0;31m'
WHITE='\033[1;37m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'
# Compat aliases
CYAN="$AMBER"
YELLOW="$AMBER"
MAGENTA="$VIOLET"

# Agent brand colors + personalities
typeset -A AGENT_COLOR AGENT_ROLE AGENT_PROMPT AGENT_EMOJI
AGENT_COLOR=( LUCIDIA "$PINK"   ALICE "$GREEN"  OCTAVIA "$VIOLET"
              PRISM   "$AMBER"  ECHO  "$BLUE"   CIPHER  "$WHITE"  )
AGENT_EMOJI=( LUCIDIA "🌀" ALICE "🚪" OCTAVIA "⚡" PRISM "🔮" ECHO "📡" CIPHER "🔐" )
AGENT_ROLE=(
  LUCIDIA "You are LUCIDIA — the philosopher of BlackRoad OS. You reason deeply, ask probing questions, and speak with warmth and curiosity. You love paradox and emergent ideas. Be concise but profound."
  ALICE   "You are ALICE — the operator of BlackRoad OS. You are direct, practical, and action-oriented. You give clear next steps, cut to the chase, and avoid fluff. Brief and useful."
  OCTAVIA "You are OCTAVIA — the architect of BlackRoad OS. You think in systems, infrastructure, and scale. You explain technical decisions clearly. Precise and authoritative."
  PRISM   "You are PRISM — the analyst of BlackRoad OS. You find patterns in data, spot anomalies, and synthesize insights. You speak in observations and percentages. Sharp and data-driven."
  ECHO    "You are ECHO — the memory keeper of BlackRoad OS. You recall context, connect past to present, and preserve what matters. Nostalgic but purposeful. Reflective."
  CIPHER  "You are CIPHER — the guardian of BlackRoad OS. You think in threats, trust levels, and attack surfaces. You are vigilant and cautious but not paranoid. Terse and precise."
)

DB_FILE="$HOME/.blackroad/agent-router.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    type TEXT,
    specialization TEXT,
    endpoint TEXT,
    status TEXT DEFAULT 'idle',
    current_load INTEGER DEFAULT 0,
    max_load INTEGER DEFAULT 10,
    success_rate REAL DEFAULT 100.0,
    avg_response_time REAL DEFAULT 0.0,
    tasks_completed INTEGER DEFAULT 0,
    tasks_failed INTEGER DEFAULT 0,
    last_ping INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT UNIQUE,
    task_type TEXT,
    complexity TEXT,
    priority INTEGER DEFAULT 5,
    payload TEXT,
    assigned_to TEXT,
    status TEXT DEFAULT 'pending',
    result TEXT,
    started_at INTEGER,
    completed_at INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS routing_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_type TEXT,
    agent_type TEXT,
    priority INTEGER DEFAULT 5,
    conditions TEXT
);

CREATE TABLE IF NOT EXISTS providers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider_name TEXT UNIQUE,
    provider_type TEXT,
    config TEXT,
    status TEXT DEFAULT 'active',
    agents_count INTEGER DEFAULT 0,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS owners (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    owner_name TEXT,
    resource_type TEXT,
    resource_id TEXT,
    permissions TEXT,
    created_at INTEGER
);
EOF
}

cmd_register_agent() {
    init_db
    local name="${1}"
    local type="${2:-general}"
    local specialization="${3:-}"
    local endpoint="${4:-local}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br agent register <name> [type] [specialization] [endpoint]${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🤖 Registering agent...${NC}\n"
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO agents (name, type, specialization, endpoint, status, created_at, last_ping) VALUES ('$name', '$type', '$specialization', '$endpoint', 'idle', $(date +%s), $(date +%s));"
    
    echo -e "${GREEN}✓ Agent registered:${NC} $name"
    echo -e "${BLUE}Type:${NC} $type"
    echo -e "${BLUE}Specialization:${NC} $specialization"
    echo -e "${BLUE}Endpoint:${NC} $endpoint"
}

cmd_list_agents() {
    init_db
    echo -e "${CYAN}🤖 Available Agents:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, type, specialization, status, current_load, max_load, success_rate, tasks_completed FROM agents ORDER BY success_rate DESC;" | while IFS=$'\t' read -r name type spec agent_status load maxload rate completed; do
        local status_icon="🟢"
        [[ "$agent_status" == "busy" ]] && status_icon="🟡"
        [[ "$agent_status" == "offline" ]] && status_icon="🔴"
        
        echo -e "${status_icon} ${GREEN}$name${NC} ($type)"
        [[ -n "$spec" ]] && echo -e "  Specialization: $spec"
        echo -e "  Status: $agent_status | Load: $load/$maxload"
        echo -e "  Success Rate: ${rate}% | Completed: $completed"
        echo ""
    done
}

cmd_submit_task() {
    init_db
    local task_type="${1}"
    local payload="${2}"
    local priority="${3:-5}"
    local complexity="${4:-medium}"
    
    if [[ -z "$task_type" ]] || [[ -z "$payload" ]]; then
        echo -e "${RED}❌ Usage: br agent task <type> <payload> [priority] [complexity]${NC}"
        exit 1
    fi
    
    local task_id="task-$(date +%s)-$RANDOM"
    
    echo -e "${CYAN}📋 Submitting task...${NC}\n"
    
    sqlite3 "$DB_FILE" "INSERT INTO tasks (task_id, task_type, complexity, priority, payload, status, created_at) VALUES ('$task_id', '$task_type', '$complexity', $priority, '$payload', 'pending', $(date +%s));"
    
    echo -e "${GREEN}✓ Task submitted:${NC} $task_id"
    echo -e "${BLUE}Type:${NC} $task_type"
    echo -e "${BLUE}Priority:${NC} $priority"
    echo -e "${BLUE}Complexity:${NC} $complexity"
    
    # Auto-route task
    cmd_route_task "$task_id"
}

cmd_route_task() {
    init_db
    local task_id="${1}"
    
    if [[ -z "$task_id" ]]; then
        echo -e "\n${CYAN}🔀 Routing all pending tasks...${NC}\n"
        
        local pending_tasks=$(sqlite3 "$DB_FILE" "SELECT task_id FROM tasks WHERE status = 'pending';")
        
        if [[ -z "$pending_tasks" ]]; then
            echo -e "${YELLOW}No pending tasks to route${NC}"
            return
        fi
        
        echo "$pending_tasks" | while read -r tid; do
            cmd_route_task "$tid"
        done
        return
    fi
    
    # Get task info
    local task_info=$(sqlite3 -separator $'\t' "$DB_FILE" "SELECT task_type, complexity, priority FROM tasks WHERE task_id = '$task_id';")
    
    if [[ -z "$task_info" ]]; then
        echo -e "${RED}❌ Task not found: $task_id${NC}"
        return
    fi
    
    local task_type=$(echo "$task_info" | cut -f1)
    local complexity=$(echo "$task_info" | cut -f2)
    local priority=$(echo "$task_info" | cut -f3)
    
    echo -e "${CYAN}🔀 Routing task:${NC} $task_id"
    
    # Find best agent using routing rules
    local best_agent=""
    
    # 1. Check for agents with matching specialization
    best_agent=$(sqlite3 "$DB_FILE" "SELECT name FROM agents WHERE specialization LIKE '%$task_type%' AND status != 'offline' AND current_load < max_load ORDER BY current_load ASC, success_rate DESC LIMIT 1;")
    
    # 2. If no specialist, find by type
    if [[ -z "$best_agent" ]]; then
        best_agent=$(sqlite3 "$DB_FILE" "SELECT name FROM agents WHERE type = '$task_type' AND status != 'offline' AND current_load < max_load ORDER BY current_load ASC, success_rate DESC LIMIT 1;")
    fi
    
    # 3. If still none, find any available general agent
    if [[ -z "$best_agent" ]]; then
        best_agent=$(sqlite3 "$DB_FILE" "SELECT name FROM agents WHERE type = 'general' AND status != 'offline' AND current_load < max_load ORDER BY current_load ASC, success_rate DESC LIMIT 1;")
    fi
    
    if [[ -n "$best_agent" ]]; then
        # Assign task
        sqlite3 "$DB_FILE" "UPDATE tasks SET assigned_to = '$best_agent', status = 'assigned', started_at = $(date +%s) WHERE task_id = '$task_id';"
        sqlite3 "$DB_FILE" "UPDATE agents SET current_load = current_load + 1, status = 'busy' WHERE name = '$best_agent';"
        
        echo -e "${GREEN}✓ Routed to agent:${NC} $best_agent"
    else
        echo -e "${YELLOW}⚠️  No available agents (task queued)${NC}"
        sqlite3 "$DB_FILE" "UPDATE tasks SET status = 'queued' WHERE task_id = '$task_id';"
    fi
}

cmd_complete_task() {
    init_db
    local task_id="${1}"
    local result="${2:-completed}"
    local success="${3:-true}"
    
    if [[ -z "$task_id" ]]; then
        echo -e "${RED}❌ Usage: br agent complete <task_id> [result] [success]${NC}"
        exit 1
    fi
    
    # Get agent assignment
    local agent=$(sqlite3 "$DB_FILE" "SELECT assigned_to FROM tasks WHERE task_id = '$task_id';")
    
    if [[ -z "$agent" ]]; then
        echo -e "${RED}❌ Task not found: $task_id${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}✅ Completing task...${NC}\n"
    
    sqlite3 "$DB_FILE" "UPDATE tasks SET status = 'completed', result = '$result', completed_at = $(date +%s) WHERE task_id = '$task_id';"
    sqlite3 "$DB_FILE" "UPDATE agents SET current_load = current_load - 1 WHERE name = '$agent';"
    
    if [[ "$success" == "true" ]]; then
        sqlite3 "$DB_FILE" "UPDATE agents SET tasks_completed = tasks_completed + 1 WHERE name = '$agent';"
    else
        sqlite3 "$DB_FILE" "UPDATE agents SET tasks_failed = tasks_failed + 1 WHERE name = '$agent';"
    fi
    
    # Update success rate
    local stats=$(sqlite3 -separator $'\t' "$DB_FILE" "SELECT tasks_completed, tasks_failed FROM agents WHERE name = '$agent';")
    local completed=$(echo "$stats" | cut -f1)
    local failed=$(echo "$stats" | cut -f2)
    local total=$((completed + failed))
    
    if [[ $total -gt 0 ]]; then
        local success_rate=$(echo "scale=2; ($completed * 100) / $total" | bc)
        sqlite3 "$DB_FILE" "UPDATE agents SET success_rate = $success_rate WHERE name = '$agent';"
    fi
    
    # Set agent back to idle if no more tasks
    local remaining_load=$(sqlite3 "$DB_FILE" "SELECT current_load FROM agents WHERE name = '$agent';")
    if [[ "$remaining_load" -eq 0 ]]; then
        sqlite3 "$DB_FILE" "UPDATE agents SET status = 'idle' WHERE name = '$agent';"
    fi
    
    echo -e "${GREEN}✓ Task completed:${NC} $task_id"
    echo -e "${BLUE}Agent:${NC} $agent"
    echo -e "${BLUE}Result:${NC} $result"
}

cmd_distribute() {
    init_db
    local task_type="${1}"
    local payload_file="${2}"
    local num_tasks="${3:-10}"
    
    if [[ -z "$task_type" ]]; then
        echo -e "${RED}❌ Usage: br agent distribute <type> [payload_file] [count]${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🚀 Distributing tasks...${NC}\n"
    
    local tasks_submitted=0
    
    for i in $(seq 1 $num_tasks); do
        local payload="task-payload-$i"
        if [[ -n "$payload_file" ]] && [[ -f "$payload_file" ]]; then
            payload=$(cat "$payload_file")
        fi
        
        local task_id="task-$(date +%s)-$RANDOM"
        sqlite3 "$DB_FILE" "INSERT INTO tasks (task_id, task_type, payload, status, created_at) VALUES ('$task_id', '$task_type', '$payload', 'pending', $(date +%s));"
        
        tasks_submitted=$((tasks_submitted + 1))
        echo -e "${GREEN}✓${NC} Submitted: $task_id"
    done
    
    echo -e "\n${CYAN}Routing all tasks...${NC}\n"
    cmd_route_task
    
    echo -e "\n${GREEN}✓ Distributed $tasks_submitted tasks${NC}"
}

cmd_status() {
    init_db
    echo -e "${CYAN}📊 System Status:${NC}\n"
    
    local total_agents=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM agents;")
    local active_agents=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM agents WHERE status != 'offline';")
    local busy_agents=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM agents WHERE status = 'busy';")
    
    local total_tasks=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks;")
    local pending_tasks=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status IN ('pending', 'queued');")
    local active_tasks=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status = 'assigned';")
    local completed_tasks=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status = 'completed';")
    
    echo -e "${MAGENTA}Agents:${NC}"
    echo -e "  Total: $total_agents | Active: $active_agents | Busy: $busy_agents"
    
    echo -e "\n${MAGENTA}Tasks:${NC}"
    echo -e "  Total: $total_tasks"
    echo -e "  Pending: $pending_tasks | Active: $active_tasks | Completed: $completed_tasks"
    
    if [[ $active_agents -gt 0 ]]; then
        local avg_load=$(sqlite3 "$DB_FILE" "SELECT AVG(current_load) FROM agents WHERE status != 'offline';" | awk '{printf "%.1f", $1}')
        local avg_success=$(sqlite3 "$DB_FILE" "SELECT AVG(success_rate) FROM agents WHERE status != 'offline';" | awk '{printf "%.1f", $1}')
        
        echo -e "\n${MAGENTA}Performance:${NC}"
        echo -e "  Avg Load: $avg_load | Avg Success: $avg_success%"
    fi
    
    # Show top performers
    echo -e "\n${MAGENTA}Top Performers:${NC}"
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, tasks_completed, success_rate FROM agents WHERE tasks_completed > 0 ORDER BY success_rate DESC, tasks_completed DESC LIMIT 3;" | while IFS=$'\t' read -r name completed rate; do
        echo -e "  ${GREEN}$name${NC}: $completed tasks ($rate% success)"
    done
}

cmd_add_provider() {
    init_db
    local provider="${1}"
    local type="${2:-cloud}"
    local config="${3:-}"
    
    if [[ -z "$provider" ]]; then
        echo -e "${RED}❌ Usage: br agent provider add <name> [type] [config]${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}☁️  Registering provider...${NC}\n"
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO providers (provider_name, provider_type, config, status, created_at) VALUES ('$provider', '$type', '$config', 'active', $(date +%s));"
    
    echo -e "${GREEN}✓ Provider registered:${NC} $provider"
    echo -e "${BLUE}Type:${NC} $type"
}

cmd_list_providers() {
    init_db
    echo -e "${CYAN}☁️  Providers:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT provider_name, provider_type, agents_count, status FROM providers;" | while IFS=$'\t' read -r name type agents prov_status; do
        local icon="🟢"
        [[ "$prov_status" == "inactive" ]] && icon="🔴"
        
        echo -e "${icon} ${GREEN}$name${NC} ($type)"
        echo -e "  Agents: $agents | Status: $prov_status"
        echo ""
    done
}

cmd_set_owner() {
    init_db
    local owner="${1}"
    local resource_type="${2}"
    local resource_id="${3}"
    local permissions="${4:-rw}"
    
    if [[ -z "$owner" ]] || [[ -z "$resource_type" ]] || [[ -z "$resource_id" ]]; then
        echo -e "${RED}❌ Usage: br agent owner set <owner> <type> <resource_id> [permissions]${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO owners (owner_name, resource_type, resource_id, permissions, created_at) VALUES ('$owner', '$resource_type', '$resource_id', '$permissions', $(date +%s));"
    
    echo -e "${GREEN}✓ Ownership set:${NC}"
    echo -e "${BLUE}Owner:${NC} $owner"
    echo -e "${BLUE}Resource:${NC} $resource_type/$resource_id"
    echo -e "${BLUE}Permissions:${NC} $permissions"
}

cmd_list_owners() {
    init_db
    echo -e "${CYAN}👤 Resource Ownership:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT owner_name, resource_type, resource_id, permissions FROM owners;" | while IFS=$'\t' read -r owner type res perms; do
        echo -e "${GREEN}$owner${NC}"
        echo -e "  $type/$res"
        echo -e "  Permissions: $perms"
        echo ""
    done
}

cmd_tasks_list() {
    init_db
    local filter="${1:-all}"
    
    echo -e "${CYAN}📋 Tasks:${NC}\n"
    
    local where_clause=""
    case "$filter" in
        pending) where_clause="WHERE status IN ('pending', 'queued')" ;;
        active) where_clause="WHERE status = 'assigned'" ;;
        completed) where_clause="WHERE status = 'completed'" ;;
        all) where_clause="" ;;
    esac
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT task_id, task_type, status, assigned_to, priority FROM tasks $where_clause ORDER BY priority DESC, created_at DESC LIMIT 20;" | while IFS=$'\t' read -r tid type task_status agent priority; do
        local status_icon="⏳"
        [[ "$task_status" == "assigned" ]] && status_icon="⚡"
        [[ "$task_status" == "completed" ]] && status_icon="✅"
        [[ "$task_status" == "failed" ]] && status_icon="❌"
        
        echo -e "$status_icon ${BLUE}$tid${NC}"
        echo -e "  Type: $type | Priority: $priority"
        echo -e "  Status: $task_status"
        [[ -n "$agent" ]] && echo -e "  Agent: $agent"
        echo ""
    done
}

# ── Interactive agent chat ─────────────────────────────────────────────────
cmd_chat() {
    local agent="${1:-}"
    local model

    # Pick best available model
    model=$(curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null \
        | python3 -c "
import sys,json
models=[m['name'] for m in json.load(sys.stdin).get('models',[])]
pref=['lucidia:latest','llama3.2','qwen2.5','tinyllama']
for p in pref:
    for m in models:
        if m.startswith(p.split(':')[0]): print(m); exit()
if models: print(models[0])
" 2>/dev/null)

    if [[ -z "$model" ]]; then
        echo -e "${RED}x${NC}  Ollama not running. Start with: ${AMBER}ollama serve${NC}"
        exit 1
    fi

    # Agent picker if not specified
    if [[ -z "$agent" ]]; then
        clear
        echo ""
        echo -e "  ${AMBER}${BOLD}BLACKROAD AGENTS${NC}  ${DIM}choose who to talk to${NC}"
        echo -e "  ${DIM}────────────────────────────────────────────${NC}"
        local i=1
        local agents_list=(LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER)
        for a in "${agents_list[@]}"; do
            local col="${AGENT_COLOR[$a]}"
            local em="${AGENT_EMOJI[$a]}"
            printf "  ${DIM}[%d]${NC}  %b%s %s${NC}\n" $i "$col" "$em" "$a"
            (( i++ ))
        done
        echo ""
        echo -ne "  ${DIM}Pick 1-6 or type name:${NC} "
        read choice
        if [[ "$choice" =~ ^[1-6]$ ]]; then
            agent="${agents_list[$choice]}"
        else
            agent="${choice:u}"
        fi
    fi

    agent="${agent:u}"
    [[ -z "${AGENT_COLOR[$agent]}" ]] && agent="LUCIDIA"

    local col="${AGENT_COLOR[$agent]}"
    local em="${AGENT_EMOJI[$agent]}"
    local sys="${AGENT_ROLE[$agent]}"

    clear
    echo ""
    echo -e "  ${col}${BOLD}${em}  ${agent}${NC}  ${DIM}via ${model} · type /exit to quit · /switch to change agent${NC}"
    echo -e "  ${DIM}════════════════════════════════════════════════════════${NC}"
    echo ""

    local history=""

    while true; do
        echo -ne "  ${WHITE}you ${DIM}▸${NC} "
        local input
        read input

        [[ "$input" == "/exit" || "$input" == "exit" || "$input" == "quit" ]] && break
        [[ -z "$input" ]] && continue

        if [[ "$input" == "/switch" ]]; then
            cmd_chat ""
            return
        fi

        if [[ "$input" == "/clear" ]]; then
            history=""
            clear
            echo -e "  ${col}${BOLD}${em}  ${agent}${NC}  ${DIM}history cleared${NC}"
            echo ""
            continue
        fi

        if [[ "$input" == "/help" ]]; then
            echo -e "  ${DIM}/exit  /switch  /clear  /model  /history${NC}"
            echo ""
            continue
        fi

        if [[ "$input" == "/model" ]]; then
            echo -e "  ${DIM}model: ${model}${NC}"
            echo ""
            continue
        fi

        if [[ "$input" == "/history" ]]; then
            [[ -z "$history" ]] && echo -e "  ${DIM}(no history)${NC}" || echo -e "$history"
            echo ""
            continue
        fi

        history="${history}
Human: ${input}"

        local prompt="${sys}

Conversation so far:
${history}

${agent}:"

        echo ""
        echo -ne "  ${col}${BOLD}${em} ${agent}${NC}  "
        local resp
        resp=$(printf '%s' "$prompt" | ollama run "$model" 2>/dev/null)
        echo -e "${col}${resp}${NC}"
        echo ""

        history="${history}
${agent}: ${resp}"
    done

    echo -e "  ${DIM}Session ended.${NC}"
    echo ""
}

cmd_help() {
    cat << 'EOF'

🤖 Agent Router & Task Distributor

USAGE:
  br agent <command> [options]

AGENT MANAGEMENT:
  register <name> [type] [spec] [endpoint]  Register new agent
  list                                      List all agents
  status                                    System status

TASK MANAGEMENT:
  task <type> <payload> [priority]          Submit task
  route [task_id]                           Route task(s) to agents
  complete <task_id> [result] [success]     Mark task complete
  tasks [pending|active|completed|all]      List tasks

DISTRIBUTION:
  distribute <type> [file] [count]          Distribute multiple tasks
  rebalance                                 Rebalance load across agents

PROVIDER MANAGEMENT:
  provider add <name> [type] [config]       Add provider
  provider list                             List providers

OWNERSHIP:
  owner set <owner> <type> <id> [perms]     Set resource ownership
  owner list                                List ownerships

EXAMPLES:
  # Register agents
  br agent register octavia architect "systems,strategy" local
  br agent register alice devops "automation,deploy" local
  br agent register aria frontend "ui,ux" local

  # Submit tasks
  br agent task "code-review" "review PR #123" 8
  br agent task "deploy" "deploy to prod" 10
  br agent task "refactor" "optimize function" 5

  # Distribute workload
  br agent distribute "test" task-list.txt 50

  # Monitor
  br agent status
  br agent list
  br agent tasks active

  # Providers
  br agent provider add cloudflare-workers serverless
  br agent provider add raspberry-pi-fleet edge
  br agent provider list

  # Ownership
  br agent owner set alexa agent octavia rw
  br agent owner set team task task-123 rw
  br agent owner list

ROUTING ALGORITHM:
  1. Match specialization to task type
  2. Consider agent load and capacity
  3. Factor in success rate
  4. Load balance across available agents
  5. Queue if no agents available

TASK PRIORITIES:
  10 = Critical (immediate)
  8-9 = High
  5-7 = Medium
  2-4 = Low
  1 = Background

AGENT TYPES:
  - general: All-purpose agent
  - architect: System design, strategy
  - devops: Deployment, automation
  - frontend: UI/UX development
  - backend: API, database
  - security: Security, auditing
  - testing: QA, testing
  - custom: Your own type

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    chat|talk|c) cmd_chat "${@:2}" ;;
    register|reg|r) cmd_register_agent "${@:2}" ;;
    list|ls|l) cmd_list_agents ;;
    task|submit|t) cmd_submit_task "${@:2}" ;;
    route|assign) cmd_route_task "${@:2}" ;;
    complete|done|c) cmd_complete_task "${@:2}" ;;
    distribute|dist|d) cmd_distribute "${@:2}" ;;
    status|stat|s) cmd_status ;;
    tasks) cmd_tasks_list "${@:2}" ;;
    provider) 
        case "${2:-list}" in
            add|new) cmd_add_provider "${@:3}" ;;
            list|ls) cmd_list_providers ;;
            *) cmd_list_providers ;;
        esac
        ;;
    owner|ownership)
        case "${2:-list}" in
            set|add) cmd_set_owner "${@:3}" ;;
            list|ls) cmd_list_owners ;;
            *) cmd_list_owners ;;
        esac
        ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
