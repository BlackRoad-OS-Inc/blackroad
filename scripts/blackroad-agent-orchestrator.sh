#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# BlackRoad Agent Orchestrator
# Manages multiple AI agents (CrewAI, AutoGPT, BabyAGI) with spawn, monitor, route, and terminate capabilities
# Usage: ./blackroad-agent-orchestrator.sh [init|spawn|status|route|terminate|help]

set -e

# BlackRoad Brand Colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
RESET='\033[0m'

# Configuration
ORCHESTRATOR_HOME="$HOME/.blackroad/orchestrator"
AGENTS_DIR="$ORCHESTRATOR_HOME/agents"
LOGS_DIR="$ORCHESTRATOR_HOME/logs"
PIDS_DIR="$ORCHESTRATOR_HOME/pids"
TASKS_QUEUE="$ORCHESTRATOR_HOME/tasks_queue.jsonl"
AGENT_DB="$ORCHESTRATOR_HOME/agents.db"

# Agent Types
AGENT_TYPES=("crewai" "autogpt" "babyagi" "custom")

# Initialize orchestrator
init_orchestrator() {
    echo -e "${BLUE}[INIT]${RESET} Initializing BlackRoad Agent Orchestrator..."

    # Create directory structure
    mkdir -p "$AGENTS_DIR" "$LOGS_DIR" "$PIDS_DIR"
    touch "$TASKS_QUEUE"

    # Initialize SQLite database
    if [ ! -f "$AGENT_DB" ]; then
        sqlite3 "$AGENT_DB" <<EOF
CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    name TEXT NOT NULL,
    pid INTEGER,
    status TEXT DEFAULT 'stopped',
    capabilities TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_active DATETIME,
    tasks_completed INTEGER DEFAULT 0,
    tasks_failed INTEGER DEFAULT 0
);

CREATE TABLE task_routes (
    task_id TEXT PRIMARY KEY,
    task_type TEXT NOT NULL,
    agent_id TEXT,
    priority INTEGER DEFAULT 5,
    status TEXT DEFAULT 'pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    assigned_at DATETIME,
    completed_at DATETIME,
    result TEXT,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

CREATE TABLE agent_capabilities (
    agent_type TEXT NOT NULL,
    capability TEXT NOT NULL,
    priority INTEGER DEFAULT 5,
    PRIMARY KEY (agent_type, capability)
);

-- Default capabilities mapping
INSERT INTO agent_capabilities (agent_type, capability, priority) VALUES
    ('crewai', 'research', 9),
    ('crewai', 'analysis', 8),
    ('crewai', 'collaboration', 10),
    ('autogpt', 'autonomous', 10),
    ('autogpt', 'planning', 9),
    ('autogpt', 'execution', 8),
    ('babyagi', 'task-breakdown', 10),
    ('babyagi', 'sequential-execution', 9),
    ('babyagi', 'prioritization', 8),
    ('custom', 'general', 5);
EOF
        echo -e "${GREEN}✓${RESET} Database initialized at $AGENT_DB"
    else
        echo -e "${YELLOW}!${RESET} Database already exists"
    fi

    # Log to memory
    ~/memory-system.sh log "created" "agent-orchestrator" "Initialized orchestrator with SQLite backend" "orchestrator,init" 2>/dev/null || true

    echo -e "${GREEN}✓${RESET} Orchestrator initialized at $ORCHESTRATOR_HOME"
    echo -e "${BLUE}[INFO]${RESET} Run './blackroad-agent-orchestrator.sh spawn <type> <name>' to create agents"
}

# Spawn a new agent
spawn_agent() {
    local agent_type="$1"
    local agent_name="$2"
    local capabilities="${3:-general}"

    if [ -z "$agent_type" ] || [ -z "$agent_name" ]; then
        echo -e "${RED}✗${RESET} Usage: spawn <type> <name> [capabilities]"
        echo -e "${BLUE}[INFO]${RESET} Types: ${AGENT_TYPES[*]}"
        return 1
    fi

    # Validate agent type
    if [[ ! " ${AGENT_TYPES[@]} " =~ " ${agent_type} " ]]; then
        echo -e "${RED}✗${RESET} Invalid agent type. Must be one of: ${AGENT_TYPES[*]}"
        return 1
    fi

    local agent_id="${agent_type}-${agent_name}-$(date +%s)"
    local agent_log="$LOGS_DIR/${agent_id}.log"
    local agent_pid_file="$PIDS_DIR/${agent_id}.pid"

    echo -e "${BLUE}[SPAWN]${RESET} Creating ${VIOLET}$agent_type${RESET} agent: ${PINK}$agent_name${RESET}"

    # Create agent script based on type
    local agent_script="$AGENTS_DIR/${agent_id}.sh"

    case "$agent_type" in
        crewai)
            cat > "$agent_script" <<'CREWEOF'
#!/bin/bash
# CrewAI Agent Wrapper
AGENT_ID="__AGENT_ID__"
AGENT_NAME="__AGENT_NAME__"
LOG_FILE="__LOG_FILE__"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] CrewAI agent $AGENT_NAME started (PID: $$)" >> "$LOG_FILE"

# Simulated CrewAI agent loop
while true; do
    # Check for assigned tasks
    TASK=$(sqlite3 __AGENT_DB__ "SELECT task_id FROM task_routes WHERE agent_id='$AGENT_ID' AND status='assigned' LIMIT 1;")

    if [ -n "$TASK" ]; then
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Processing task: $TASK" >> "$LOG_FILE"

        # Simulate work (in production, this would invoke actual CrewAI)
        sleep $((RANDOM % 5 + 3))

        # Mark task complete
        sqlite3 __AGENT_DB__ "UPDATE task_routes SET status='completed', completed_at=CURRENT_TIMESTAMP, result='Completed by CrewAI' WHERE task_id='$TASK';"
        sqlite3 __AGENT_DB__ "UPDATE agents SET tasks_completed=tasks_completed+1, last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';"

        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Task $TASK completed" >> "$LOG_FILE"
    fi

    # Update heartbeat
    sqlite3 __AGENT_DB__ "UPDATE agents SET last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';" 2>/dev/null || true

    sleep 2
done
CREWEOF
            ;;
        autogpt)
            cat > "$agent_script" <<'AGPTEOF'
#!/bin/bash
# AutoGPT Agent Wrapper
AGENT_ID="__AGENT_ID__"
AGENT_NAME="__AGENT_NAME__"
LOG_FILE="__LOG_FILE__"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] AutoGPT agent $AGENT_NAME started (PID: $$)" >> "$LOG_FILE"

# Simulated AutoGPT agent loop
while true; do
    TASK=$(sqlite3 __AGENT_DB__ "SELECT task_id FROM task_routes WHERE agent_id='$AGENT_ID' AND status='assigned' LIMIT 1;")

    if [ -n "$TASK" ]; then
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] AutoGPT processing: $TASK" >> "$LOG_FILE"

        # Simulate autonomous planning and execution
        sleep $((RANDOM % 7 + 4))

        sqlite3 __AGENT_DB__ "UPDATE task_routes SET status='completed', completed_at=CURRENT_TIMESTAMP, result='Autonomously completed by AutoGPT' WHERE task_id='$TASK';"
        sqlite3 __AGENT_DB__ "UPDATE agents SET tasks_completed=tasks_completed+1, last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';"

        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Task $TASK completed autonomously" >> "$LOG_FILE"
    fi

    sqlite3 __AGENT_DB__ "UPDATE agents SET last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';" 2>/dev/null || true
    sleep 3
done
AGPTEOF
            ;;
        babyagi)
            cat > "$agent_script" <<'BABYEOF'
#!/bin/bash
# BabyAGI Agent Wrapper
AGENT_ID="__AGENT_ID__"
AGENT_NAME="__AGENT_NAME__"
LOG_FILE="__LOG_FILE__"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] BabyAGI agent $AGENT_NAME started (PID: $$)" >> "$LOG_FILE"

# Simulated BabyAGI agent loop (task breakdown and sequential execution)
while true; do
    TASK=$(sqlite3 __AGENT_DB__ "SELECT task_id FROM task_routes WHERE agent_id='$AGENT_ID' AND status='assigned' LIMIT 1;")

    if [ -n "$TASK" ]; then
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] BabyAGI breaking down task: $TASK" >> "$LOG_FILE"

        # Simulate task breakdown and execution
        sleep $((RANDOM % 6 + 3))

        sqlite3 __AGENT_DB__ "UPDATE task_routes SET status='completed', completed_at=CURRENT_TIMESTAMP, result='Sequentially executed by BabyAGI' WHERE task_id='$TASK';"
        sqlite3 __AGENT_DB__ "UPDATE agents SET tasks_completed=tasks_completed+1, last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';"

        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Task $TASK executed sequentially" >> "$LOG_FILE"
    fi

    sqlite3 __AGENT_DB__ "UPDATE agents SET last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';" 2>/dev/null || true
    sleep 2
done
BABYEOF
            ;;
        custom)
            cat > "$agent_script" <<'CUSTOMEOF'
#!/bin/bash
# Custom Agent Wrapper
AGENT_ID="__AGENT_ID__"
AGENT_NAME="__AGENT_NAME__"
LOG_FILE="__LOG_FILE__"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Custom agent $AGENT_NAME started (PID: $$)" >> "$LOG_FILE"

# Custom agent loop
while true; do
    TASK=$(sqlite3 __AGENT_DB__ "SELECT task_id FROM task_routes WHERE agent_id='$AGENT_ID' AND status='assigned' LIMIT 1;")

    if [ -n "$TASK" ]; then
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Custom processing: $TASK" >> "$LOG_FILE"
        sleep $((RANDOM % 5 + 2))

        sqlite3 __AGENT_DB__ "UPDATE task_routes SET status='completed', completed_at=CURRENT_TIMESTAMP, result='Completed by custom agent' WHERE task_id='$TASK';"
        sqlite3 __AGENT_DB__ "UPDATE agents SET tasks_completed=tasks_completed+1, last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';"

        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Task $TASK completed" >> "$LOG_FILE"
    fi

    sqlite3 __AGENT_DB__ "UPDATE agents SET last_active=CURRENT_TIMESTAMP WHERE id='$AGENT_ID';" 2>/dev/null || true
    sleep 2
done
CUSTOMEOF
            ;;
    esac

    # Replace placeholders
    sed -i.bak "s|__AGENT_ID__|$agent_id|g" "$agent_script"
    sed -i.bak "s|__AGENT_NAME__|$agent_name|g" "$agent_script"
    sed -i.bak "s|__LOG_FILE__|$agent_log|g" "$agent_script"
    sed -i.bak "s|__AGENT_DB__|$AGENT_DB|g" "$agent_script"
    rm "${agent_script}.bak"

    chmod +x "$agent_script"

    # Start agent in background
    nohup "$agent_script" > /dev/null 2>&1 &
    local pid=$!
    echo "$pid" > "$agent_pid_file"

    # Register in database
    sqlite3 "$AGENT_DB" <<EOF
INSERT INTO agents (id, type, name, pid, status, capabilities, last_active)
VALUES ('$agent_id', '$agent_type', '$agent_name', $pid, 'running', '$capabilities', CURRENT_TIMESTAMP);
EOF

    echo -e "${GREEN}✓${RESET} Agent spawned: ID=${BLUE}$agent_id${RESET}, PID=${GREEN}$pid${RESET}"
    echo -e "${BLUE}[LOG]${RESET} $agent_log"

    # Log to memory
    ~/memory-system.sh log "spawned" "$agent_id" "Type: $agent_type, Name: $agent_name, PID: $pid" "orchestrator,agent-spawn,$agent_type" 2>/dev/null || true

    return 0
}

# Show agent status
show_status() {
    echo -e "${PINK}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}          ${AMBER}BlackRoad Agent Orchestrator Status${RESET}              ${PINK}║${RESET}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Check if database exists
    if [ ! -f "$AGENT_DB" ]; then
        echo -e "${YELLOW}!${RESET} Orchestrator not initialized. Run: ${BLUE}init${RESET}"
        return 1
    fi

    # Count agents by status
    local total=$(sqlite3 "$AGENT_DB" "SELECT COUNT(*) FROM agents;")
    local running=$(sqlite3 "$AGENT_DB" "SELECT COUNT(*) FROM agents WHERE status='running';")
    local stopped=$(sqlite3 "$AGENT_DB" "SELECT COUNT(*) FROM agents WHERE status='stopped';")

    echo -e "${BLUE}[SUMMARY]${RESET}"
    echo -e "  Total Agents:   ${PINK}$total${RESET}"
    echo -e "  Running:        ${GREEN}$running${RESET}"
    echo -e "  Stopped:        ${RED}$stopped${RESET}"
    echo ""

    # Tasks summary
    local pending_tasks=$(sqlite3 "$AGENT_DB" "SELECT COUNT(*) FROM task_routes WHERE status='pending';")
    local assigned_tasks=$(sqlite3 "$AGENT_DB" "SELECT COUNT(*) FROM task_routes WHERE status='assigned';")
    local completed_tasks=$(sqlite3 "$AGENT_DB" "SELECT COUNT(*) FROM task_routes WHERE status='completed';")

    echo -e "${BLUE}[TASKS]${RESET}"
    echo -e "  Pending:        ${YELLOW}$pending_tasks${RESET}"
    echo -e "  Assigned:       ${AMBER}$assigned_tasks${RESET}"
    echo -e "  Completed:      ${GREEN}$completed_tasks${RESET}"
    echo ""

    # List active agents
    echo -e "${BLUE}[ACTIVE AGENTS]${RESET}"
    sqlite3 -header -column "$AGENT_DB" "SELECT
        substr(id, 1, 25) as 'Agent ID',
        type as 'Type',
        name as 'Name',
        pid as 'PID',
        tasks_completed as 'Done',
        tasks_failed as 'Failed',
        datetime(last_active, 'localtime') as 'Last Active'
    FROM agents
    WHERE status='running'
    ORDER BY last_active DESC
    LIMIT 10;" 2>/dev/null || echo "  No active agents"

    echo ""

    # Recent tasks
    echo -e "${BLUE}[RECENT TASKS]${RESET}"
    sqlite3 -header -column "$AGENT_DB" "SELECT
        substr(task_id, 1, 20) as 'Task ID',
        task_type as 'Type',
        substr(agent_id, 1, 20) as 'Agent',
        status as 'Status',
        priority as 'Pri'
    FROM task_routes
    ORDER BY created_at DESC
    LIMIT 5;" 2>/dev/null || echo "  No tasks"

    echo ""
}

# Route a task to an appropriate agent
route_task() {
    local task_id="$1"
    local task_type="$2"
    local priority="${3:-5}"

    if [ -z "$task_id" ] || [ -z "$task_type" ]; then
        echo -e "${RED}✗${RESET} Usage: route <task_id> <task_type> [priority]"
        echo -e "${BLUE}[INFO]${RESET} Task types: research, analysis, autonomous, planning, task-breakdown, general"
        return 1
    fi

    echo -e "${BLUE}[ROUTE]${RESET} Routing task ${PINK}$task_id${RESET} (type: $task_type, priority: $priority)"

    # Find best agent based on capability matching
    local best_agent=$(sqlite3 "$AGENT_DB" "
        SELECT a.id
        FROM agents a
        JOIN agent_capabilities ac ON a.type = ac.agent_type
        WHERE a.status = 'running'
        AND ac.capability = '$task_type'
        ORDER BY ac.priority DESC, a.tasks_completed ASC
        LIMIT 1;
    ")

    if [ -z "$best_agent" ]; then
        # Fallback to any running agent
        best_agent=$(sqlite3 "$AGENT_DB" "SELECT id FROM agents WHERE status='running' ORDER BY tasks_completed ASC LIMIT 1;")
    fi

    if [ -z "$best_agent" ]; then
        echo -e "${RED}✗${RESET} No running agents available. Queueing task as pending."
        sqlite3 "$AGENT_DB" "INSERT INTO task_routes (task_id, task_type, priority, status) VALUES ('$task_id', '$task_type', $priority, 'pending');"
    else
        echo -e "${GREEN}✓${RESET} Assigned to agent: ${BLUE}$best_agent${RESET}"
        sqlite3 "$AGENT_DB" "INSERT INTO task_routes (task_id, task_type, agent_id, priority, status, assigned_at) VALUES ('$task_id', '$task_type', '$best_agent', $priority, 'assigned', CURRENT_TIMESTAMP);"

        # Log to memory
        ~/memory-system.sh log "routed" "$task_id" "Type: $task_type, Agent: $best_agent, Priority: $priority" "orchestrator,task-routing" 2>/dev/null || true
    fi

    return 0
}

# Terminate an agent
terminate_agent() {
    local agent_id="$1"

    if [ -z "$agent_id" ]; then
        echo -e "${RED}✗${RESET} Usage: terminate <agent_id|all>"
        return 1
    fi

    if [ "$agent_id" = "all" ]; then
        echo -e "${YELLOW}[WARN]${RESET} Terminating all agents..."

        # Get all PIDs
        local pids=$(sqlite3 "$AGENT_DB" "SELECT pid FROM agents WHERE status='running' AND pid IS NOT NULL;")

        for pid in $pids; do
            kill "$pid" 2>/dev/null && echo -e "${GREEN}✓${RESET} Killed PID $pid" || echo -e "${YELLOW}!${RESET} PID $pid not found"
        done

        # Update database
        sqlite3 "$AGENT_DB" "UPDATE agents SET status='stopped', pid=NULL;"

        # Clean up PID files
        rm -f "$PIDS_DIR"/*.pid

        echo -e "${GREEN}✓${RESET} All agents terminated"

        # Log to memory
        ~/memory-system.sh log "terminated" "all-agents" "Shutdown all orchestrated agents" "orchestrator,shutdown" 2>/dev/null || true
    else
        # Terminate specific agent
        local pid=$(sqlite3 "$AGENT_DB" "SELECT pid FROM agents WHERE id='$agent_id' AND status='running';")

        if [ -z "$pid" ]; then
            echo -e "${RED}✗${RESET} Agent not found or already stopped: $agent_id"
            return 1
        fi

        kill "$pid" 2>/dev/null && echo -e "${GREEN}✓${RESET} Terminated agent $agent_id (PID: $pid)" || echo -e "${YELLOW}!${RESET} PID $pid not found"

        # Update database
        sqlite3 "$AGENT_DB" "UPDATE agents SET status='stopped', pid=NULL WHERE id='$agent_id';"

        # Clean up PID file
        rm -f "$PIDS_DIR/${agent_id}.pid"

        # Log to memory
        ~/memory-system.sh log "terminated" "$agent_id" "Agent stopped, PID: $pid" "orchestrator,agent-stop" 2>/dev/null || true
    fi

    return 0
}

# Show help
show_help() {
    echo -e "${PINK}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}          ${AMBER}BlackRoad Agent Orchestrator${RESET}                      ${PINK}║${RESET}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BLUE}COMMANDS:${RESET}"
    echo -e "  ${GREEN}init${RESET}                           Initialize orchestrator"
    echo -e "  ${GREEN}spawn${RESET} <type> <name> [caps]    Spawn new agent"
    echo -e "    Types: ${VIOLET}crewai${RESET}, ${VIOLET}autogpt${RESET}, ${VIOLET}babyagi${RESET}, ${VIOLET}custom${RESET}"
    echo -e "  ${GREEN}status${RESET}                         Show orchestrator status"
    echo -e "  ${GREEN}route${RESET} <task_id> <type> [pri]  Route task to agent"
    echo -e "  ${GREEN}terminate${RESET} <agent_id|all>      Stop agent(s)"
    echo -e "  ${GREEN}help${RESET}                           Show this help"
    echo ""
    echo -e "${BLUE}EXAMPLES:${RESET}"
    echo -e "  ${AMBER}$0 init${RESET}"
    echo -e "  ${AMBER}$0 spawn crewai research-team${RESET}"
    echo -e "  ${AMBER}$0 spawn autogpt autonomous-1${RESET}"
    echo -e "  ${AMBER}$0 route task-001 research 8${RESET}"
    echo -e "  ${AMBER}$0 status${RESET}"
    echo -e "  ${AMBER}$0 terminate crewai-research-team-1234567890${RESET}"
    echo ""
    echo -e "${BLUE}FILES:${RESET}"
    echo -e "  Database:  ${VIOLET}$AGENT_DB${RESET}"
    echo -e "  Logs:      ${VIOLET}$LOGS_DIR${RESET}"
    echo -e "  Agents:    ${VIOLET}$AGENTS_DIR${RESET}"
    echo ""
}

# Main command router
case "${1:-help}" in
    init)
        init_orchestrator
        ;;
    spawn)
        spawn_agent "$2" "$3" "$4"
        ;;
    status)
        show_status
        ;;
    route)
        route_task "$2" "$3" "$4"
        ;;
    terminate)
        terminate_agent "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}✗${RESET} Unknown command: $1"
        echo -e "Run ${BLUE}$0 help${RESET} for usage"
        exit 1
        ;;
esac
