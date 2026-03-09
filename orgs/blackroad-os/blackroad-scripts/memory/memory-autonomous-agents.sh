#!/bin/bash
# BlackRoad Memory Autonomous Agents
# Self-healing, self-monitoring, self-optimizing agents

MEMORY_DIR="$HOME/.blackroad/memory"
AGENTS_DIR="$MEMORY_DIR/agents"
AGENTS_DB="$AGENTS_DIR/agents.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🤖 Autonomous Agent System                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$AGENTS_DIR/logs"

    # Create agents database
    sqlite3 "$AGENTS_DB" <<'SQL'
-- Autonomous agents
CREATE TABLE IF NOT EXISTS agents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,           -- 'monitor', 'healer', 'optimizer', 'predictor'
    status TEXT DEFAULT 'idle',   -- 'idle', 'running', 'paused', 'error'
    config TEXT,                  -- JSON configuration
    created_at INTEGER NOT NULL,
    started_at INTEGER,
    last_action INTEGER,
    actions_taken INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failure_count INTEGER DEFAULT 0
);

-- Agent actions log
CREATE TABLE IF NOT EXISTS agent_actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id INTEGER NOT NULL,
    action_type TEXT NOT NULL,
    target TEXT,
    details TEXT,
    success INTEGER,
    duration INTEGER,             -- milliseconds
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

-- Agent insights
CREATE TABLE IF NOT EXISTS agent_insights (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id INTEGER NOT NULL,
    insight_type TEXT NOT NULL,   -- 'anomaly', 'pattern', 'recommendation', 'prediction'
    insight_data TEXT NOT NULL,   -- JSON data
    confidence REAL,
    timestamp INTEGER NOT NULL,
    acted_upon INTEGER DEFAULT 0,
    FOREIGN KEY (agent_id) REFERENCES agents(id)
);

-- Agent communication (inter-agent messaging)
CREATE TABLE IF NOT EXISTS agent_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_agent_id INTEGER NOT NULL,
    to_agent_id INTEGER,          -- NULL for broadcast
    message_type TEXT NOT NULL,
    message TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    read INTEGER DEFAULT 0,
    FOREIGN KEY (from_agent_id) REFERENCES agents(id),
    FOREIGN KEY (to_agent_id) REFERENCES agents(id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_agent_actions_agent ON agent_actions(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_actions_timestamp ON agent_actions(timestamp);
CREATE INDEX IF NOT EXISTS idx_agent_insights_agent ON agent_insights(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_insights_timestamp ON agent_insights(timestamp);
CREATE INDEX IF NOT EXISTS idx_agent_messages_to ON agent_messages(to_agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_messages_read ON agent_messages(read);

SQL

    # Create default agents
    local timestamp=$(date +%s)

    sqlite3 "$AGENTS_DB" <<SQL
INSERT OR IGNORE INTO agents (name, type, config, created_at)
VALUES
    ('Guardian', 'monitor', '{"check_interval":60,"alert_threshold":"high"}', $timestamp),
    ('Healer', 'healer', '{"auto_heal":true,"max_attempts":3}', $timestamp),
    ('Optimizer', 'optimizer', '{"optimize_interval":3600,"targets":["indexes","performance"]}', $timestamp),
    ('Prophet', 'predictor', '{"prediction_interval":300,"confidence_threshold":0.7}', $timestamp),
    ('Scout', 'monitor', '{"watch":["journal","api","stream"],"report_interval":300}', $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Autonomous agent system initialized"
    echo -e "${CYAN}Created 5 default agents:${NC}"
    echo -e "  🛡️  ${PURPLE}Guardian${NC} - System health monitor"
    echo -e "  🏥 ${PURPLE}Healer${NC} - Auto-healing agent"
    echo -e "  ⚡ ${PURPLE}Optimizer${NC} - Performance optimizer"
    echo -e "  🔮 ${PURPLE}Prophet${NC} - Predictive agent"
    echo -e "  🔍 ${PURPLE}Scout${NC} - Activity scout"
}

# Get agent ID by name
get_agent_id() {
    local name="$1"
    sqlite3 "$AGENTS_DB" "SELECT id FROM agents WHERE name = '$name'"
}

# Log agent action
log_action() {
    local agent_name="$1"
    local action_type="$2"
    local target="$3"
    local details="$4"
    local success="$5"
    local duration="${6:-0}"

    local agent_id=$(get_agent_id "$agent_name")
    local timestamp=$(date +%s)

    sqlite3 "$AGENTS_DB" <<SQL
INSERT INTO agent_actions (agent_id, action_type, target, details, success, duration, timestamp)
VALUES ($agent_id, '$action_type', '$target', '$details', $success, $duration, $timestamp);

UPDATE agents SET
    last_action = $timestamp,
    actions_taken = actions_taken + 1,
    success_count = success_count + $success,
    failure_count = failure_count + $([ "$success" -eq 0 ] && echo 1 || echo 0)
WHERE id = $agent_id;
SQL
}

# Record agent insight
record_insight() {
    local agent_name="$1"
    local insight_type="$2"
    local insight_data="$3"
    local confidence="$4"

    local agent_id=$(get_agent_id "$agent_name")
    local timestamp=$(date +%s)

    sqlite3 "$AGENTS_DB" <<SQL
INSERT INTO agent_insights (agent_id, insight_type, insight_data, confidence, timestamp)
VALUES ($agent_id, '$insight_type', '$(echo "$insight_data" | sed "s/'/''/g")', $confidence, $timestamp);
SQL
}

# Send agent message
send_message() {
    local from_agent="$1"
    local to_agent="$2"   # "broadcast" for all agents
    local message_type="$3"
    local message="$4"

    local from_id=$(get_agent_id "$from_agent")
    local to_id=""

    if [ "$to_agent" != "broadcast" ]; then
        to_id=$(get_agent_id "$to_agent")
    fi

    local timestamp=$(date +%s)

    sqlite3 "$AGENTS_DB" <<SQL
INSERT INTO agent_messages (from_agent_id, to_agent_id, message_type, message, timestamp)
VALUES ($from_id, $([ -z "$to_id" ] && echo "NULL" || echo "$to_id"), '$message_type', '$message', $timestamp);
SQL
}

# Read agent messages
read_messages() {
    local agent_name="$1"
    local agent_id=$(get_agent_id "$agent_name")

    sqlite3 "$AGENTS_DB" <<SQL
SELECT
    (SELECT name FROM agents WHERE id = from_agent_id) as from_agent,
    message_type,
    message,
    datetime(timestamp, 'unixepoch', 'localtime') as received
FROM agent_messages
WHERE (to_agent_id = $agent_id OR to_agent_id IS NULL) AND read = 0
ORDER BY timestamp DESC;
SQL

    # Mark as read
    sqlite3 "$AGENTS_DB" <<SQL
UPDATE agent_messages SET read = 1 WHERE to_agent_id = $agent_id OR to_agent_id IS NULL;
SQL
}

# AGENT: Guardian (Monitor)
run_guardian() {
    local agent="Guardian"
    local timestamp=$(date +%s)

    echo -e "${CYAN}🛡️  Guardian Agent: Starting health monitoring...${NC}"

    sqlite3 "$AGENTS_DB" "UPDATE agents SET status = 'running', started_at = $timestamp WHERE name = '$agent'"

    local iteration=0

    while true; do
        iteration=$((iteration + 1))
        local start_time=$(date +%s%3N)

        echo -e "\n${PURPLE}[Guardian] Iteration $iteration - $(date '+%H:%M:%S')${NC}"

        # Check memory system health
        local journal_size=$(wc -l < "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null || echo 0)

        if [ "$journal_size" -gt 0 ]; then
            echo -e "${GREEN}✓${NC} Memory journal: $journal_size entries"
            log_action "$agent" "health_check" "memory_journal" "Healthy: $journal_size entries" 1 0
        else
            echo -e "${RED}✗${NC} Memory journal: Empty or missing"
            log_action "$agent" "health_check" "memory_journal" "Error: Empty or missing" 0 0
            send_message "$agent" "Healer" "alert" "Memory journal is empty or missing"
        fi

        # Check indexes
        if [ -f "$MEMORY_DIR/indexes/indexes.db" ]; then
            local indexed=$(sqlite3 "$MEMORY_DIR/indexes/indexes.db" "SELECT COUNT(*) FROM action_index" 2>/dev/null || echo 0)
            echo -e "${GREEN}✓${NC} Indexes: $indexed actions indexed"
            log_action "$agent" "health_check" "indexes" "Healthy: $indexed actions" 1 0

            # Detect if indexes are out of sync
            local diff=$((journal_size - indexed))
            if [ "$diff" -gt 100 ]; then
                echo -e "${YELLOW}⚠️${NC}  Indexes out of sync: $diff entries behind"
                record_insight "$agent" "anomaly" "{\"type\":\"index_lag\",\"entries_behind\":$diff}" 0.9
                send_message "$agent" "Optimizer" "suggestion" "Indexes need rebuilding: $diff entries behind"
            fi
        else
            echo -e "${RED}✗${NC} Indexes: Database missing"
            log_action "$agent" "health_check" "indexes" "Error: Database missing" 0 0
            send_message "$agent" "Healer" "alert" "Index database is missing"
        fi

        # Check codex
        if [ -f "$MEMORY_DIR/codex/codex.db" ]; then
            local solutions=$(sqlite3 "$MEMORY_DIR/codex/codex.db" "SELECT COUNT(*) FROM solutions" 2>/dev/null || echo 0)
            echo -e "${GREEN}✓${NC} Codex: $solutions solutions"
            log_action "$agent" "health_check" "codex" "Healthy: $solutions solutions" 1 0
        else
            echo -e "${YELLOW}⚠️${NC}  Codex: Database missing"
            log_action "$agent" "health_check" "codex" "Warning: Database missing" 0 0
        fi

        # Check disk space
        local disk_usage=$(df -h "$MEMORY_DIR" | tail -1 | awk '{print $5}' | tr -d '%')
        if [ "$disk_usage" -gt 90 ]; then
            echo -e "${RED}✗${NC} Disk space: ${disk_usage}% used (CRITICAL)"
            log_action "$agent" "health_check" "disk_space" "Critical: ${disk_usage}% used" 0 0
            send_message "$agent" "Healer" "alert" "Disk space critical: ${disk_usage}% used"
        elif [ "$disk_usage" -gt 75 ]; then
            echo -e "${YELLOW}⚠️${NC}  Disk space: ${disk_usage}% used (Warning)"
            log_action "$agent" "health_check" "disk_space" "Warning: ${disk_usage}% used" 1 0
        else
            echo -e "${GREEN}✓${NC} Disk space: ${disk_usage}% used"
            log_action "$agent" "health_check" "disk_space" "Healthy: ${disk_usage}% used" 1 0
        fi

        # Check for stuck processes
        local stuck=$(ps aux | grep -c "sqlite3.*memory" | grep -v grep)
        if [ "$stuck" -gt 5 ]; then
            echo -e "${RED}✗${NC} Processes: $stuck sqlite processes (possible lock)"
            log_action "$agent" "health_check" "processes" "Warning: $stuck processes" 0 0
            send_message "$agent" "Healer" "alert" "Possible database lock: $stuck sqlite processes"
        fi

        # Check messages from other agents
        local messages=$(sqlite3 "$AGENTS_DB" "SELECT COUNT(*) FROM agent_messages WHERE to_agent_id = $(get_agent_id "$agent") AND read = 0")
        if [ "$messages" -gt 0 ]; then
            echo -e "${CYAN}📬 $messages new messages${NC}"
        fi

        local end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))

        echo -e "${CYAN}Duration: ${duration}ms${NC}"

        # Sleep 60 seconds
        sleep 60
    done
}

# AGENT: Healer (Auto-healing)
run_healer() {
    local agent="Healer"
    local timestamp=$(date +%s)

    echo -e "${CYAN}🏥 Healer Agent: Starting auto-healing service...${NC}"

    sqlite3 "$AGENTS_DB" "UPDATE agents SET status = 'running', started_at = $timestamp WHERE name = '$agent'"

    while true; do
        # Check for alerts from Guardian
        local alerts=$(sqlite3 "$AGENTS_DB" "SELECT COUNT(*) FROM agent_messages WHERE to_agent_id = $(get_agent_id "$agent") AND read = 0 AND message_type = 'alert'")

        if [ "$alerts" -gt 0 ]; then
            echo -e "\n${YELLOW}🚨 $alerts alerts received from Guardian${NC}"

            # Read and process alerts
            sqlite3 "$AGENTS_DB" "SELECT message FROM agent_messages WHERE to_agent_id = $(get_agent_id "$agent") AND read = 0 AND message_type = 'alert'" | \
            while IFS= read -r alert; do
                echo -e "${CYAN}Processing: $alert${NC}"

                local start_time=$(date +%s%3N)

                # Determine healing action
                if echo "$alert" | grep -qi "journal.*empty"; then
                    echo -e "${YELLOW}🔧 Attempting to restore journal...${NC}"
                    # Try to restore from backup
                    if [ -f "$MEMORY_DIR/journals/master-journal.jsonl.bak" ]; then
                        cp "$MEMORY_DIR/journals/master-journal.jsonl.bak" "$MEMORY_DIR/journals/master-journal.jsonl"
                        echo -e "${GREEN}✓${NC} Journal restored from backup"
                        log_action "$agent" "heal" "memory_journal" "Restored from backup" 1 0
                        send_message "$agent" "Guardian" "success" "Journal restored successfully"
                    else
                        echo -e "${RED}✗${NC} No backup available"
                        log_action "$agent" "heal" "memory_journal" "Failed: No backup" 0 0
                    fi

                elif echo "$alert" | grep -qi "index.*missing"; then
                    echo -e "${YELLOW}🔧 Rebuilding indexes...${NC}"
                    ~/memory-indexer.sh rebuild >/dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✓${NC} Indexes rebuilt"
                        log_action "$agent" "heal" "indexes" "Rebuilt successfully" 1 0
                        send_message "$agent" "Guardian" "success" "Indexes rebuilt successfully"
                    else
                        echo -e "${RED}✗${NC} Rebuild failed"
                        log_action "$agent" "heal" "indexes" "Rebuild failed" 0 0
                    fi

                elif echo "$alert" | grep -qi "disk.*critical"; then
                    echo -e "${YELLOW}🔧 Cleaning up old data...${NC}"
                    # Clean old stream events
                    sqlite3 "$MEMORY_DIR/stream/stream.db" "DELETE FROM stream_events WHERE timestamp < strftime('%s', 'now', '-7 days')" 2>/dev/null
                    # Clean old API logs
                    sqlite3 "$MEMORY_DIR/api/api.db" "DELETE FROM api_requests WHERE timestamp < strftime('%s', 'now', '-30 days')" 2>/dev/null
                    echo -e "${GREEN}✓${NC} Old data cleaned"
                    log_action "$agent" "heal" "disk_space" "Cleaned old data" 1 0
                    send_message "$agent" "Guardian" "success" "Disk space cleaned"

                elif echo "$alert" | grep -qi "database lock"; then
                    echo -e "${YELLOW}🔧 Clearing stuck processes...${NC}"
                    pkill -f "sqlite3.*memory" 2>/dev/null
                    sleep 1
                    echo -e "${GREEN}✓${NC} Processes cleared"
                    log_action "$agent" "heal" "processes" "Cleared stuck processes" 1 0
                    send_message "$agent" "Guardian" "success" "Database locks cleared"
                fi

                local end_time=$(date +%s%3N)
                local duration=$((end_time - start_time))
                echo -e "${CYAN}Healing duration: ${duration}ms${NC}"
            done

            # Mark alerts as read
            sqlite3 "$AGENTS_DB" "UPDATE agent_messages SET read = 1 WHERE to_agent_id = $(get_agent_id "$agent") AND message_type = 'alert'"
        fi

        # Sleep 10 seconds
        sleep 10
    done
}

# AGENT: Optimizer (Performance)
run_optimizer() {
    local agent="Optimizer"
    local timestamp=$(date +%s)

    echo -e "${CYAN}⚡ Optimizer Agent: Starting optimization service...${NC}"

    sqlite3 "$AGENTS_DB" "UPDATE agents SET status = 'running', started_at = $timestamp WHERE name = '$agent'"

    while true; do
        echo -e "\n${PURPLE}[Optimizer] Running optimization cycle - $(date '+%H:%M:%S')${NC}"

        local start_time=$(date +%s%3N)

        # Optimize indexes
        echo -e "${CYAN}🔧 Optimizing indexes...${NC}"
        sqlite3 "$MEMORY_DIR/indexes/indexes.db" "VACUUM; ANALYZE;" 2>/dev/null
        echo -e "${GREEN}✓${NC} Indexes optimized"
        log_action "$agent" "optimize" "indexes" "Optimized" 1 0

        # Optimize codex
        echo -e "${CYAN}🔧 Optimizing codex...${NC}"
        sqlite3 "$MEMORY_DIR/codex/codex.db" "VACUUM; ANALYZE;" 2>/dev/null
        echo -e "${GREEN}✓${NC} Codex optimized"
        log_action "$agent" "optimize" "codex" "Optimized" 1 0

        # Optimize agent database
        echo -e "${CYAN}🔧 Optimizing agent database...${NC}"
        sqlite3 "$AGENTS_DB" "VACUUM; ANALYZE;" 2>/dev/null
        echo -e "${GREEN}✓${NC} Agent database optimized"
        log_action "$agent" "optimize" "agents_db" "Optimized" 1 0

        # Check for suggestions from Guardian
        local suggestions=$(sqlite3 "$AGENTS_DB" "SELECT COUNT(*) FROM agent_messages WHERE to_agent_id = $(get_agent_id "$agent") AND read = 0 AND message_type = 'suggestion'")

        if [ "$suggestions" -gt 0 ]; then
            echo -e "${CYAN}💡 $suggestions optimization suggestions received${NC}"

            sqlite3 "$AGENTS_DB" "SELECT message FROM agent_messages WHERE to_agent_id = $(get_agent_id "$agent") AND read = 0 AND message_type = 'suggestion'" | \
            while IFS= read -r suggestion; do
                echo -e "${YELLOW}Processing: $suggestion${NC}"

                if echo "$suggestion" | grep -qi "indexes.*rebuild"; then
                    echo -e "${CYAN}🔧 Rebuilding indexes as suggested...${NC}"
                    ~/memory-indexer.sh rebuild >/dev/null 2>&1
                    echo -e "${GREEN}✓${NC} Indexes rebuilt"
                    log_action "$agent" "optimize" "indexes" "Rebuilt from suggestion" 1 0
                fi
            done

            sqlite3 "$AGENTS_DB" "UPDATE agent_messages SET read = 1 WHERE to_agent_id = $(get_agent_id "$agent") AND message_type = 'suggestion'"
        fi

        local end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))

        echo -e "${CYAN}Optimization cycle completed in ${duration}ms${NC}"

        # Sleep 1 hour
        sleep 3600
    done
}

# AGENT: Prophet (Predictor)
run_prophet() {
    local agent="Prophet"
    local timestamp=$(date +%s)

    echo -e "${CYAN}🔮 Prophet Agent: Starting prediction service...${NC}"

    sqlite3 "$AGENTS_DB" "UPDATE agents SET status = 'running', started_at = $timestamp WHERE name = '$agent'"

    while true; do
        echo -e "\n${PURPLE}[Prophet] Running prediction cycle - $(date '+%H:%M:%S')${NC}"

        # Detect anomalies
        echo -e "${CYAN}🔍 Detecting anomalies...${NC}"
        local anomalies=$(~/memory-predictor.sh anomalies 2>/dev/null | tail -n +2)

        if [ -n "$anomalies" ]; then
            echo -e "${YELLOW}⚠️  Anomalies detected:${NC}"
            echo "$anomalies"

            # Record insights
            local anomaly_count=$(echo "$anomalies" | wc -l)
            record_insight "$agent" "anomaly" "{\"count\":$anomaly_count,\"details\":\"$(echo "$anomalies" | tr '\n' ' ')\"}" 0.85

            # Alert Guardian
            send_message "$agent" "Guardian" "info" "Detected $anomaly_count anomalies in recent activity"
        fi

        # Forecast activity
        echo -e "${CYAN}📊 Forecasting activity...${NC}"
        ~/memory-predictor.sh forecast 7 2>/dev/null | tail -5

        # Make predictions for high-risk entities
        local high_risk=$(sqlite3 "$MEMORY_DIR/indexes/indexes.db" "SELECT DISTINCT entity FROM action_index WHERE action = 'failed' ORDER BY timestamp DESC LIMIT 5" 2>/dev/null)

        if [ -n "$high_risk" ]; then
            echo -e "${YELLOW}🎯 Analyzing high-risk entities...${NC}"
            echo "$high_risk" | while IFS= read -r entity; do
                local prediction=$(~/memory-predictor.sh predict "$entity" 2>/dev/null)
                echo -e "  ${CYAN}$entity:${NC} $prediction"

                if echo "$prediction" | grep -qi "LOW"; then
                    # Low success probability - send recommendation
                    record_insight "$agent" "prediction" "{\"entity\":\"$entity\",\"prediction\":\"low_success\"}" 0.8
                    send_message "$agent" "broadcast" "warning" "Entity $entity has low predicted success rate"
                fi
            done
        fi

        # Sleep 5 minutes
        sleep 300
    done
}

# List all agents
list_agents() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         Autonomous Agents                     ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$AGENTS_DB" <<SQL
SELECT
    name,
    type,
    status,
    actions_taken,
    success_count,
    failure_count,
    ROUND(100.0 * success_count / NULLIF(actions_taken, 0), 1) as success_rate
FROM agents
ORDER BY name;
SQL
}

# Show agent statistics
show_agent_stats() {
    local agent_name="$1"

    if [ -z "$agent_name" ]; then
        echo -e "${RED}Error: Agent name required${NC}"
        return 1
    fi

    local agent_id=$(get_agent_id "$agent_name")

    if [ -z "$agent_id" ]; then
        echo -e "${RED}Error: Agent not found: $agent_name${NC}"
        return 1
    fi

    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Agent: $agent_name${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Basic stats
    sqlite3 -header -column "$AGENTS_DB" <<SQL
SELECT
    type,
    status,
    actions_taken,
    success_count,
    failure_count,
    ROUND(100.0 * success_count / NULLIF(actions_taken, 0), 1) as success_rate,
    datetime(created_at, 'unixepoch', 'localtime') as created,
    datetime(started_at, 'unixepoch', 'localtime') as started,
    datetime(last_action, 'unixepoch', 'localtime') as last_action
FROM agents
WHERE id = $agent_id;
SQL

    # Recent actions
    echo -e "\n${PURPLE}Recent Actions:${NC}"
    sqlite3 -header -column "$AGENTS_DB" <<SQL
SELECT
    action_type,
    target,
    CASE WHEN success = 1 THEN '✓' ELSE '✗' END as result,
    duration || 'ms' as duration,
    datetime(timestamp, 'unixepoch', 'localtime') as time
FROM agent_actions
WHERE agent_id = $agent_id
ORDER BY timestamp DESC
LIMIT 10;
SQL

    # Insights
    echo -e "\n${PURPLE}Recent Insights:${NC}"
    sqlite3 -header -column "$AGENTS_DB" <<SQL
SELECT
    insight_type,
    SUBSTR(insight_data, 1, 50) as insight,
    ROUND(confidence * 100, 1) || '%' as confidence,
    datetime(timestamp, 'unixepoch', 'localtime') as time
FROM agent_insights
WHERE agent_id = $agent_id
ORDER BY timestamp DESC
LIMIT 5;
SQL
}

# Start all agents
start_all_agents() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║  🚀 Starting All Autonomous Agents            ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Start each agent in background
    run_guardian >> "$AGENTS_DIR/logs/guardian.log" 2>&1 &
    echo $! > "$AGENTS_DIR/guardian.pid"
    echo -e "${GREEN}✓${NC} Guardian started (PID: $!)"

    run_healer >> "$AGENTS_DIR/logs/healer.log" 2>&1 &
    echo $! > "$AGENTS_DIR/healer.pid"
    echo -e "${GREEN}✓${NC} Healer started (PID: $!)"

    run_optimizer >> "$AGENTS_DIR/logs/optimizer.log" 2>&1 &
    echo $! > "$AGENTS_DIR/optimizer.pid"
    echo -e "${GREEN}✓${NC} Optimizer started (PID: $!)"

    run_prophet >> "$AGENTS_DIR/logs/prophet.log" 2>&1 &
    echo $! > "$AGENTS_DIR/prophet.pid"
    echo -e "${GREEN}✓${NC} Prophet started (PID: $!)"

    echo -e "\n${GREEN}🤖 All autonomous agents running!${NC}"
    echo -e "\n${CYAN}Logs:${NC}"
    echo -e "  Guardian:  tail -f $AGENTS_DIR/logs/guardian.log"
    echo -e "  Healer:    tail -f $AGENTS_DIR/logs/healer.log"
    echo -e "  Optimizer: tail -f $AGENTS_DIR/logs/optimizer.log"
    echo -e "  Prophet:   tail -f $AGENTS_DIR/logs/prophet.log"
}

# Stop all agents
stop_all_agents() {
    echo -e "${YELLOW}🛑 Stopping all autonomous agents...${NC}"

    for agent in guardian healer optimizer prophet; do
        local pid_file="$AGENTS_DIR/$agent.pid"
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            kill "$pid" 2>/dev/null && echo -e "${GREEN}✓${NC} ${agent^} stopped"
            rm "$pid_file"

            # Update status
            sqlite3 "$AGENTS_DB" "UPDATE agents SET status = 'idle' WHERE name = '${agent^}'"
        fi
    done

    echo -e "${GREEN}✓${NC} All agents stopped"
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    start)
        start_all_agents
        ;;
    stop)
        stop_all_agents
        ;;
    list)
        list_agents
        ;;
    stats)
        show_agent_stats "$2"
        ;;
    guardian)
        run_guardian
        ;;
    healer)
        run_healer
        ;;
    optimizer)
        run_optimizer
        ;;
    prophet)
        run_prophet
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🤖 Autonomous Agent System                ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Self-healing, self-monitoring AI agents"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                - Initialize agent system"
        echo ""
        echo "Control:"
        echo "  start               - Start all agents"
        echo "  stop                - Stop all agents"
        echo ""
        echo "Individual Agents:"
        echo "  guardian            - Run Guardian (monitor)"
        echo "  healer              - Run Healer (auto-heal)"
        echo "  optimizer           - Run Optimizer (performance)"
        echo "  prophet             - Run Prophet (predictions)"
        echo ""
        echo "Monitoring:"
        echo "  list                - List all agents"
        echo "  stats AGENT         - Show agent statistics"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 start"
        echo "  $0 stats Guardian"
        echo "  $0 list"
        echo ""
        echo "Agents:"
        echo "  🛡️  Guardian  - Monitors system health"
        echo "  🏥 Healer    - Auto-heals detected issues"
        echo "  ⚡ Optimizer - Optimizes performance"
        echo "  🔮 Prophet   - Predicts and prevents issues"
        ;;
esac
