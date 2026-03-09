#!/bin/bash
# Task Delegator - AI-Powered Task Distribution
# BlackRoad OS, Inc. © 2026

DELEGATOR_DIR="$HOME/.blackroad/task-delegator"
DELEGATOR_DB="$DELEGATOR_DIR/delegator.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🤖 Task Delegator - AI Distribution       ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$DELEGATOR_DIR/queues"

    # Create database
    sqlite3 "$DELEGATOR_DB" <<'SQL'
-- Agents/Workers
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    skills TEXT NOT NULL,             -- JSON array of skills
    capacity INTEGER DEFAULT 5,       -- max concurrent tasks
    current_load INTEGER DEFAULT 0,
    success_rate REAL DEFAULT 0,
    total_completed INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active',     -- active, idle, offline
    last_seen INTEGER
);

-- Tasks
CREATE TABLE IF NOT EXISTS tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    required_skills TEXT NOT NULL,    -- JSON array
    priority TEXT DEFAULT 'medium',   -- low, medium, high, urgent
    complexity INTEGER DEFAULT 5,     -- 1-10
    status TEXT DEFAULT 'pending',    -- pending, assigned, in_progress, completed, failed
    assigned_to TEXT,
    created_at INTEGER NOT NULL,
    assigned_at INTEGER,
    completed_at INTEGER,
    estimated_duration INTEGER,       -- minutes
    actual_duration INTEGER
);

-- Assignments
CREATE TABLE IF NOT EXISTS assignments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    agent_id INTEGER NOT NULL,
    score REAL NOT NULL,              -- match score 0-1
    assigned_at INTEGER NOT NULL,
    completed_at INTEGER,
    success INTEGER,
    FOREIGN KEY (task_id) REFERENCES tasks(id),
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);

SQL

    # Register some example agents
    local timestamp=$(date +%s)
    sqlite3 "$DELEGATOR_DB" <<SQL
INSERT OR IGNORE INTO agents (agent_id, name, skills, capacity, status, last_seen)
VALUES
    ('guardian-agent', 'Guardian', '["monitoring","security","health-checks"]', 10, 'active', $timestamp),
    ('healer-agent', 'Healer', '["debugging","fixing","recovery"]', 5, 'active', $timestamp),
    ('optimizer-agent', 'Optimizer', '["performance","refactoring","optimization"]', 3, 'active', $timestamp),
    ('prophet-agent', 'Prophet', '["prediction","analytics","forecasting"]', 5, 'active', $timestamp),
    ('scout-agent', 'Scout', '["discovery","research","monitoring"]', 8, 'active', $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Task Delegator initialized"
    echo -e "${GREEN}✓${NC} Registered 5 AI agents"
}

# Add task
add_task() {
    local title="$1"
    local skills="$2"
    local priority="${3:-medium}"
    local description="$4"

    if [ -z "$title" ] || [ -z "$skills" ]; then
        echo -e "${RED}Error: Title and required skills are required${NC}"
        return 1
    fi

    local task_id="TASK-$(date +%s)-$(echo $RANDOM | shasum | cut -c1-6)"
    local timestamp=$(date +%s)

    sqlite3 "$DELEGATOR_DB" <<SQL
INSERT INTO tasks (task_id, title, description, required_skills, priority, created_at)
VALUES ('$task_id', '$title', '$description', '$skills', '$priority', $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Task created: $task_id"
    echo -e "  ${CYAN}Title:${NC} $title"
    echo -e "  ${CYAN}Skills:${NC} $skills"
    echo -e "  ${CYAN}Priority:${NC} $priority"

    # Auto-delegate
    delegate_task "$task_id"
}

# Intelligent task delegation
delegate_task() {
    local task_id="$1"

    # Get task details
    local required_skills=$(sqlite3 "$DELEGATOR_DB" "SELECT required_skills FROM tasks WHERE task_id = '$task_id'")
    local priority=$(sqlite3 "$DELEGATOR_DB" "SELECT priority FROM tasks WHERE task_id = '$task_id'")

    echo -e "\n${CYAN}🤖 Finding best agent...${NC}"

    # Simple skill matching (in production, would use ML)
    local best_agent=""
    local best_score=0

    while IFS='|' read -r agent_id name skills capacity current_load success_rate; do
        [ -z "$agent_id" ] && continue

        # Calculate match score
        local score=0.5  # Base score

        # Skill match (simplified)
        if echo "$skills" | grep -qi "$(echo $required_skills | tr '[]"' ' ')" 2>/dev/null; then
            score=$(echo "$score + 0.3" | bc)
        fi

        # Consider current load
        if [ "$current_load" -lt "$capacity" ]; then
            score=$(echo "$score + 0.1" | bc)
        fi

        # Consider success rate
        local success_bonus=$(echo "$success_rate * 0.1" | bc)
        score=$(echo "$score + $success_bonus" | bc)

        # Priority boost for specific agents
        if [ "$priority" = "urgent" ]; then
            score=$(echo "$score + 0.1" | bc)
        fi

        echo -e "  ${CYAN}Evaluating:${NC} $name (score: $score)"

        # Track best
        if (( $(echo "$score > $best_score" | bc -l) )); then
            best_score=$score
            best_agent=$agent_id
        fi
    done < <(sqlite3 "$DELEGATOR_DB" "SELECT agent_id, name, skills, capacity, current_load, success_rate FROM agents WHERE status = 'active'")

    if [ -z "$best_agent" ]; then
        echo -e "${RED}Error: No suitable agent found${NC}"
        return 1
    fi

    # Assign task
    local timestamp=$(date +%s)
    local db_task_id=$(sqlite3 "$DELEGATOR_DB" "SELECT id FROM tasks WHERE task_id = '$task_id'")
    local db_agent_id=$(sqlite3 "$DELEGATOR_DB" "SELECT id FROM agents WHERE agent_id = '$best_agent'")

    sqlite3 "$DELEGATOR_DB" <<SQL
UPDATE tasks
SET status = 'assigned', assigned_to = '$best_agent', assigned_at = $timestamp
WHERE task_id = '$task_id';

UPDATE agents
SET current_load = current_load + 1
WHERE agent_id = '$best_agent';

INSERT INTO assignments (task_id, agent_id, score, assigned_at)
VALUES ($db_task_id, $db_agent_id, $best_score, $timestamp);
SQL

    local agent_name=$(sqlite3 "$DELEGATOR_DB" "SELECT name FROM agents WHERE agent_id = '$best_agent'")

    echo -e "\n${GREEN}✅ Task delegated!${NC}"
    echo -e "  ${PURPLE}Assigned to:${NC} $agent_name"
    echo -e "  ${PURPLE}Match score:${NC} $best_score"

    # Log to memory
    ~/memory-system.sh log "task-delegated" "$task_id" "Task delegated to $agent_name (score: $best_score)" "delegation,ai" 2>/dev/null
}

# Complete task
complete_task() {
    local task_id="$1"
    local success="${2:-1}"

    local timestamp=$(date +%s)
    local agent_id=$(sqlite3 "$DELEGATOR_DB" "SELECT assigned_to FROM tasks WHERE task_id = '$task_id'")

    sqlite3 "$DELEGATOR_DB" <<SQL
UPDATE tasks
SET status = 'completed', completed_at = $timestamp
WHERE task_id = '$task_id';

UPDATE agents
SET current_load = current_load - 1,
    total_completed = total_completed + 1,
    success_rate = (success_rate * total_completed + $success) / (total_completed + 1)
WHERE agent_id = '$agent_id';

UPDATE assignments
SET completed_at = $timestamp, success = $success
WHERE task_id = (SELECT id FROM tasks WHERE task_id = '$task_id');
SQL

    echo -e "${GREEN}✓${NC} Task completed: $task_id"
}

# Dashboard
dashboard() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🤖 Task Delegator Dashboard               ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    local total_tasks=$(sqlite3 "$DELEGATOR_DB" "SELECT COUNT(*) FROM tasks")
    local pending_tasks=$(sqlite3 "$DELEGATOR_DB" "SELECT COUNT(*) FROM tasks WHERE status = 'pending'")
    local in_progress=$(sqlite3 "$DELEGATOR_DB" "SELECT COUNT(*) FROM tasks WHERE status IN ('assigned', 'in_progress')")
    local completed=$(sqlite3 "$DELEGATOR_DB" "SELECT COUNT(*) FROM tasks WHERE status = 'completed'")
    local active_agents=$(sqlite3 "$DELEGATOR_DB" "SELECT COUNT(*) FROM agents WHERE status = 'active'")

    echo -e "${CYAN}📊 Task Statistics${NC}"
    echo -e "  ${GREEN}Total Tasks:${NC} $total_tasks"
    echo -e "  ${YELLOW}Pending:${NC} $pending_tasks"
    echo -e "  ${CYAN}In Progress:${NC} $in_progress"
    echo -e "  ${GREEN}Completed:${NC} $completed"

    echo -e "\n${CYAN}🤖 Agent Statistics${NC}"
    echo -e "  ${GREEN}Active Agents:${NC} $active_agents"

    echo -e "\n${CYAN}🏆 Top Performers${NC}"
    sqlite3 -header -column "$DELEGATOR_DB" <<SQL
SELECT
    name,
    total_completed,
    printf('%.1f%%', success_rate * 100) as success_rate,
    current_load || '/' || capacity as load
FROM agents
WHERE status = 'active'
ORDER BY total_completed DESC
LIMIT 5;
SQL
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    add)
        add_task "$2" "$3" "$4" "$5"
        ;;
    delegate)
        delegate_task "$2"
        ;;
    complete)
        complete_task "$2" "$3"
        ;;
    dashboard)
        dashboard
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🤖 Task Delegator - AI Distribution       ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Intelligent task distribution across AI agents"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                                    - Initialize delegator"
        echo ""
        echo "Operations:"
        echo "  add TITLE SKILLS [PRIORITY] [DESC]      - Add task"
        echo "  delegate TASK_ID                        - Delegate task to agent"
        echo "  complete TASK_ID [SUCCESS]              - Mark task complete"
        echo "  dashboard                               - Show dashboard"
        echo ""
        echo "Examples:"
        echo "  $0 add 'Fix bug' '[\"debugging\",\"backend\"]' urgent"
        echo "  $0 delegate TASK-1234567890-abc123"
        echo "  $0 complete TASK-1234567890-abc123 1"
        ;;
esac
