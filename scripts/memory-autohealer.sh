#!/bin/bash
# BlackRoad Memory Auto-Healer
# Automatic problem detection and resolution

MEMORY_DIR="$HOME/.blackroad/memory"
HEALER_DIR="$MEMORY_DIR/autohealer"
HEALER_DB="$HEALER_DIR/healer.db"
CODEX_DB="$MEMORY_DIR/codex/codex.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}🏥 Initializing Memory Auto-Healer...${NC}\n"

    mkdir -p "$HEALER_DIR/actions"
    mkdir -p "$HEALER_DIR/logs"

    sqlite3 "$HEALER_DB" <<EOF
-- Health checks
CREATE TABLE IF NOT EXISTS health_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    check_name TEXT,
    check_type TEXT,
    status TEXT,
    last_run TEXT,
    last_result TEXT,
    failures_count INTEGER DEFAULT 0
);

-- Healing actions
CREATE TABLE IF NOT EXISTS healing_actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_name TEXT,
    action_type TEXT,
    trigger_condition TEXT,
    action_script TEXT,
    success_rate REAL,
    times_executed INTEGER DEFAULT 0,
    last_executed TEXT
);

-- Healing history
CREATE TABLE IF NOT EXISTS healing_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    detected_at TEXT,
    problem_type TEXT,
    problem_entity TEXT,
    action_taken TEXT,
    result TEXT,
    success BOOLEAN,
    resolution_time_seconds INTEGER
);

-- System health
CREATE TABLE IF NOT EXISTS system_health (
    timestamp TEXT PRIMARY KEY,
    overall_health INTEGER,
    memory_entries INTEGER,
    index_health INTEGER,
    codex_health INTEGER,
    performance_score INTEGER,
    issues_detected INTEGER,
    issues_resolved INTEGER
);

CREATE INDEX IF NOT EXISTS idx_health_status ON health_checks(status);
CREATE INDEX IF NOT EXISTS idx_healing_success ON healing_history(success);
EOF

    # Register healing actions
    register_healing_actions

    echo -e "${GREEN}✅ Auto-Healer initialized${NC}\n"
}

# Register pre-defined healing actions
register_healing_actions() {
    sqlite3 "$HEALER_DB" <<EOF
-- Rebuild indexes when corrupted
INSERT OR IGNORE INTO healing_actions (
    action_name, action_type, trigger_condition, action_script, success_rate
) VALUES (
    'Rebuild Indexes',
    'repair',
    'index_corruption_detected',
    '~/memory-indexer.sh rebuild',
    0.95
);

-- Clear stuck processes
INSERT OR IGNORE INTO healing_actions (
    action_name, action_type, trigger_condition, action_script, success_rate
) VALUES (
    'Clear Stuck Processes',
    'repair',
    'stuck_process_detected',
    'pkill -f "sqlite3.*memory"',
    0.90
);

-- Optimize databases
INSERT OR IGNORE INTO healing_actions (
    action_name, action_type, trigger_condition, action_script, success_rate
) VALUES (
    'Optimize Databases',
    'maintenance',
    'slow_query_detected',
    'sqlite3 \$DB_FILE "VACUUM; ANALYZE;"',
    0.98
);

-- Fix permissions
INSERT OR IGNORE INTO healing_actions (
    action_name, action_type, trigger_condition, action_script, success_rate
) VALUES (
    'Fix Permissions',
    'repair',
    'permission_denied',
    'chmod -R 755 ~/.blackroad/memory/',
    0.99
);

-- Add retry logic
INSERT OR IGNORE INTO healing_actions (
    action_name, action_type, trigger_condition, action_script, success_rate
) VALUES (
    'Apply Retry Logic',
    'enhancement',
    'high_failure_rate',
    'apply_exponential_backoff',
    0.85
);

-- Reduce batch size
INSERT OR IGNORE INTO healing_actions (
    action_name, action_type, trigger_condition, action_script, success_rate
) VALUES (
    'Reduce Batch Size',
    'optimization',
    'coordination_conflicts',
    'set_batch_size 20',
    0.88
);
EOF
}

# Run health checks
health_check() {
    echo -e "${CYAN}🏥 Running health checks...${NC}\n"

    local overall_health=100
    local issues=0

    # Check 1: Memory journal exists and is accessible
    echo -e "${YELLOW}[1/7] Checking memory journal...${NC}"
    if [ -f "$MEMORY_DIR/journals/master-journal.jsonl" ] && [ -r "$MEMORY_DIR/journals/master-journal.jsonl" ]; then
        echo -e "${GREEN}  ✅ Memory journal healthy${NC}"
        sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result) VALUES ('memory_journal', 'file', 'healthy', datetime('now'), 'accessible')"
    else
        echo -e "${RED}  ❌ Memory journal issues detected${NC}"
        overall_health=$((overall_health - 20))
        issues=$((issues + 1))
        sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result, failures_count) VALUES ('memory_journal', 'file', 'unhealthy', datetime('now'), 'inaccessible', 1)"
    fi

    # Check 2: Index database
    echo -e "${YELLOW}[2/7] Checking index database...${NC}"
    if [ -f "$MEMORY_DIR/indexes/indexes.db" ]; then
        if sqlite3 "$MEMORY_DIR/indexes/indexes.db" "SELECT 1" >/dev/null 2>&1; then
            echo -e "${GREEN}  ✅ Index database healthy${NC}"
            sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result) VALUES ('index_db', 'database', 'healthy', datetime('now'), 'queryable')"
        else
            echo -e "${RED}  ❌ Index database corrupted${NC}"
            overall_health=$((overall_health - 15))
            issues=$((issues + 1))
            auto_heal "index_corruption_detected" "index_db"
        fi
    else
        echo -e "${YELLOW}  ⚠️  Index database not found${NC}"
        overall_health=$((overall_health - 10))
        issues=$((issues + 1))
    fi

    # Check 3: Codex database
    echo -e "${YELLOW}[3/7] Checking codex database...${NC}"
    if [ -f "$CODEX_DB" ]; then
        if sqlite3 "$CODEX_DB" "SELECT COUNT(*) FROM solutions" >/dev/null 2>&1; then
            echo -e "${GREEN}  ✅ Codex database healthy${NC}"
            sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result) VALUES ('codex_db', 'database', 'healthy', datetime('now'), 'queryable')"
        else
            echo -e "${RED}  ❌ Codex database corrupted${NC}"
            overall_health=$((overall_health - 10))
            issues=$((issues + 1))
        fi
    else
        echo -e "${YELLOW}  ⚠️  Codex database not found${NC}"
        overall_health=$((overall_health - 5))
    fi

    # Check 4: Disk space
    echo -e "${YELLOW}[4/7] Checking disk space...${NC}"
    local available_gb=$(df -h "$MEMORY_DIR" | tail -1 | awk '{print $4}' | sed 's/G.*//')
    if [ "$available_gb" -gt 1 ] 2>/dev/null || [ -z "$available_gb" ]; then
        echo -e "${GREEN}  ✅ Sufficient disk space${NC}"
        sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result) VALUES ('disk_space', 'resource', 'healthy', datetime('now'), 'sufficient')"
    else
        echo -e "${RED}  ❌ Low disk space${NC}"
        overall_health=$((overall_health - 15))
        issues=$((issues + 1))
    fi

    # Check 5: Database locks
    echo -e "${YELLOW}[5/7] Checking for database locks...${NC}"
    if pgrep -f "sqlite3.*memory" >/dev/null; then
        local lock_count=$(pgrep -f "sqlite3.*memory" | wc -l)
        if [ "$lock_count" -gt 5 ]; then
            echo -e "${RED}  ❌ Too many database connections ($lock_count)${NC}"
            overall_health=$((overall_health - 10))
            issues=$((issues + 1))
            auto_heal "stuck_process_detected" "database_locks"
        else
            echo -e "${GREEN}  ✅ Normal database activity${NC}"
            sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result) VALUES ('db_locks', 'resource', 'healthy', datetime('now'), 'normal')"
        fi
    else
        echo -e "${GREEN}  ✅ No database locks${NC}"
    fi

    # Check 6: Performance
    echo -e "${YELLOW}[6/7] Checking query performance...${NC}"
    local query_time=$(( $(date +%s%3N) ))
    sqlite3 "$MEMORY_DIR/indexes/indexes.db" "SELECT COUNT(*) FROM action_index" >/dev/null 2>&1
    query_time=$(( $(date +%s%3N) - query_time ))

    if [ "$query_time" -lt 100 ]; then
        echo -e "${GREEN}  ✅ Queries fast (${query_time}ms)${NC}"
        sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result) VALUES ('performance', 'metric', 'healthy', datetime('now'), 'fast')"
    elif [ "$query_time" -lt 1000 ]; then
        echo -e "${YELLOW}  ⚠️  Queries slow (${query_time}ms)${NC}"
        overall_health=$((overall_health - 5))
        auto_heal "slow_query_detected" "performance"
    else
        echo -e "${RED}  ❌ Queries very slow (${query_time}ms)${NC}"
        overall_health=$((overall_health - 15))
        issues=$((issues + 1))
    fi

    # Check 7: Recent errors
    echo -e "${YELLOW}[7/7] Checking for recent errors...${NC}"
    local recent_errors=$(grep -c "error\|failed" "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | tail -100 || echo 0)
    if [ "$recent_errors" -lt 10 ]; then
        echo -e "${GREEN}  ✅ Low error rate${NC}"
        sqlite3 "$HEALER_DB" "INSERT OR REPLACE INTO health_checks (check_name, check_type, status, last_run, last_result) VALUES ('error_rate', 'metric', 'healthy', datetime('now'), 'low')"
    else
        echo -e "${YELLOW}  ⚠️  Elevated error rate ($recent_errors recent)${NC}"
        overall_health=$((overall_health - 10))
    fi

    echo ""
    echo -e "${PURPLE}Overall Health Score: ${overall_health}%${NC}"

    # Store health snapshot
    sqlite3 "$HEALER_DB" <<EOF
INSERT INTO system_health (
    timestamp, overall_health, issues_detected
) VALUES (
    datetime('now'), $overall_health, $issues
);
EOF

    if [ "$overall_health" -ge 90 ]; then
        echo -e "${GREEN}✅ System is HEALTHY${NC}\n"
    elif [ "$overall_health" -ge 70 ]; then
        echo -e "${YELLOW}⚠️  System needs ATTENTION${NC}\n"
    else
        echo -e "${RED}❌ System needs IMMEDIATE ATTENTION${NC}\n"
    fi

    return $overall_health
}

# Auto-heal detected issues
auto_heal() {
    local trigger="$1"
    local entity="$2"

    echo -e "${CYAN}🔧 Auto-healing triggered: ${YELLOW}$trigger${NC}\n"

    local start_time=$(date +%s)

    # Find appropriate healing action
    local action=$(sqlite3 "$HEALER_DB" "
        SELECT action_name, action_script
        FROM healing_actions
        WHERE trigger_condition = '$trigger'
        ORDER BY success_rate DESC
        LIMIT 1
    ")

    if [ -n "$action" ]; then
        local action_name=$(echo "$action" | cut -d'|' -f1)
        local action_script=$(echo "$action" | cut -d'|' -f2)

        echo -e "${YELLOW}Applying: $action_name${NC}"

        # Execute healing action
        local result=""
        local success=0

        case "$trigger" in
            "index_corruption_detected")
                ~/memory-indexer.sh rebuild >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    result="Indexes rebuilt successfully"
                    success=1
                else
                    result="Rebuild failed"
                fi
                ;;
            "stuck_process_detected")
                pkill -f "sqlite3.*memory"
                result="Cleared stuck processes"
                success=1
                ;;
            "slow_query_detected")
                for db in "$MEMORY_DIR"/*/*.db; do
                    sqlite3 "$db" "VACUUM; ANALYZE;" 2>/dev/null
                done
                result="Databases optimized"
                success=1
                ;;
            *)
                result="No automatic fix available"
                success=0
                ;;
        esac

        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        if [ "$success" -eq 1 ]; then
            echo -e "${GREEN}✅ Healing successful: $result${NC}"
        else
            echo -e "${RED}❌ Healing failed: $result${NC}"
        fi

        # Log healing action
        sqlite3 "$HEALER_DB" <<EOF
INSERT INTO healing_history (
    detected_at, problem_type, problem_entity,
    action_taken, result, success, resolution_time_seconds
) VALUES (
    datetime('now'), '$trigger', '$entity',
    '$action_name', '$result', $success, $duration
);

UPDATE healing_actions
SET times_executed = times_executed + 1,
    last_executed = datetime('now')
WHERE action_name = '$action_name';
EOF

    else
        echo -e "${YELLOW}⚠️  No automatic healing action available${NC}"
    fi

    echo ""
}

# Monitor and auto-heal continuously
monitor() {
    local interval="${1:-300}"  # Default 5 minutes

    echo -e "${CYAN}👁️  Starting continuous monitoring (interval: ${interval}s)...${NC}\n"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"

    while true; do
        echo -e "${PURPLE}[$(date)] Running health check...${NC}"

        health_check
        local health=$?

        if [ "$health" -lt 70 ]; then
            echo -e "${RED}⚠️  Low health detected - attempting auto-heal${NC}"
            # Auto-heal will be triggered by health_check
        fi

        echo -e "${CYAN}Next check in ${interval}s...${NC}\n"
        sleep "$interval"
    done
}

# Show healing history
show_history() {
    local limit="${1:-20}"

    echo -e "${CYAN}📜 Healing History (last $limit actions):${NC}\n"

    sqlite3 -column -header "$HEALER_DB" <<EOF
SELECT
    datetime(detected_at, 'localtime') as when,
    problem_type,
    action_taken,
    CASE WHEN success THEN '✅' ELSE '❌' END as result,
    resolution_time_seconds || 's' as time
FROM healing_history
ORDER BY detected_at DESC
LIMIT $limit;
EOF

    echo ""

    # Success rate
    local total=$(sqlite3 "$HEALER_DB" "SELECT COUNT(*) FROM healing_history")
    local successful=$(sqlite3 "$HEALER_DB" "SELECT COUNT(*) FROM healing_history WHERE success = 1")

    if [ "$total" -gt 0 ]; then
        local success_rate=$((successful * 100 / total))
        echo -e "${CYAN}Success Rate:${NC} ${success_rate}% ($successful/$total)"
    fi

    echo ""
}

# Show health trends
show_trends() {
    echo -e "${CYAN}📈 Health Trends (last 7 days):${NC}\n"

    sqlite3 -column -header "$HEALER_DB" <<EOF
SELECT
    date(timestamp) as date,
    AVG(overall_health) as avg_health,
    SUM(issues_detected) as total_issues,
    SUM(issues_resolved) as resolved
FROM system_health
WHERE timestamp > datetime('now', '-7 days')
GROUP BY date(timestamp)
ORDER BY date DESC;
EOF

    echo ""
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    check)
        health_check
        ;;
    heal)
        auto_heal "$2" "$3"
        ;;
    monitor)
        monitor "$2"
        ;;
    history)
        show_history "$2"
        ;;
    trends)
        show_trends
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║      🏥 BlackRoad Memory Auto-Healer         ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Automatic problem detection and resolution"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                    - Initialize auto-healer"
        echo ""
        echo "Operations:"
        echo "  check                   - Run health checks"
        echo "  heal TRIGGER ENTITY     - Manually trigger healing"
        echo "  monitor [INTERVAL]      - Continuous monitoring"
        echo ""
        echo "Analysis:"
        echo "  history [LIMIT]         - Show healing history"
        echo "  trends                  - Show health trends"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 check"
        echo "  $0 monitor 300          # Check every 5 minutes"
        echo "  $0 history 10"
        echo "  $0 trends"
        ;;
esac
