#!/bin/bash
# Enhanced Memory Logging System with Performance Tracking
# Extends memory-system.sh with bottleneck detection and analytics

MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL_FILE="$MEMORY_DIR/journals/master-journal.jsonl"
PERF_DB="$MEMORY_DIR/analytics/performance.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Initialize performance tracking database
init_perf_db() {
    mkdir -p "$MEMORY_DIR/analytics"

    sqlite3 "$PERF_DB" <<EOF
CREATE TABLE IF NOT EXISTS operation_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    action TEXT NOT NULL,
    entity TEXT,
    start_time REAL,
    end_time REAL,
    duration_ms INTEGER,
    success BOOLEAN,
    agent_hash TEXT,
    parent_hash TEXT,
    memory_usage_mb INTEGER,
    cpu_percent REAL,
    tags TEXT
);

CREATE TABLE IF NOT EXISTS bottleneck_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    detected_at TEXT,
    type TEXT,
    entity TEXT,
    severity TEXT,
    duration_ms INTEGER,
    retry_count INTEGER,
    resolved BOOLEAN DEFAULT 0,
    resolution_time TEXT
);

CREATE TABLE IF NOT EXISTS agent_performance (
    agent_hash TEXT PRIMARY KEY,
    agent_name TEXT,
    total_operations INTEGER DEFAULT 0,
    successful_ops INTEGER DEFAULT 0,
    failed_ops INTEGER DEFAULT 0,
    avg_duration_ms REAL,
    first_seen TEXT,
    last_seen TEXT,
    status TEXT
);

CREATE INDEX IF NOT EXISTS idx_timestamp ON operation_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_action ON operation_metrics(action);
CREATE INDEX IF NOT EXISTS idx_agent ON operation_metrics(agent_hash);
CREATE INDEX IF NOT EXISTS idx_duration ON operation_metrics(duration_ms);
EOF
}

# Enhanced logging with performance tracking
log_with_perf() {
    local action="$1"
    local entity="$2"
    local details="$3"
    local agent="${4:-$MY_CLAUDE}"
    local start_time="$5"
    local success="${6:-true}"

    # Calculate duration if start_time provided
    local duration_ms=0
    if [ -n "$start_time" ]; then
        local end_time=$(date +%s%3N)
        duration_ms=$((end_time - start_time))
    fi

    # Get system metrics
    local memory_mb=$(ps -o rss= -p $$ | awk '{print int($1/1024)}')
    local cpu_percent=$(ps -o %cpu= -p $$)

    # Log to standard memory system
    ~/memory-system.sh log "$action" "$entity" "$details" "$agent"

    # Enhanced performance logging
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    sqlite3 "$PERF_DB" <<EOF
INSERT INTO operation_metrics (
    timestamp, action, entity, duration_ms, success,
    agent_hash, memory_usage_mb, cpu_percent
) VALUES (
    '$timestamp', '$action', '$entity', $duration_ms, $success,
    '$agent', $memory_mb, $cpu_percent
);
EOF

    # Detect bottlenecks
    detect_bottleneck "$action" "$entity" "$duration_ms" "$success"

    # Update agent performance
    update_agent_stats "$agent" "$success" "$duration_ms"
}

# Real-time bottleneck detection
detect_bottleneck() {
    local action="$1"
    local entity="$2"
    local duration_ms="$3"
    local success="$4"

    local severity=""
    local alert=false

    # Define thresholds
    local SLOW_THRESHOLD=30000      # 30 seconds
    local VERY_SLOW_THRESHOLD=120000 # 2 minutes
    local CRITICAL_THRESHOLD=300000  # 5 minutes

    # Check duration
    if [ "$duration_ms" -gt "$CRITICAL_THRESHOLD" ]; then
        severity="CRITICAL"
        alert=true
    elif [ "$duration_ms" -gt "$VERY_SLOW_THRESHOLD" ]; then
        severity="HIGH"
        alert=true
    elif [ "$duration_ms" -gt "$SLOW_THRESHOLD" ]; then
        severity="MEDIUM"
        alert=true
    fi

    # Check for failures
    if [ "$success" = "false" ]; then
        severity="HIGH"
        alert=true
    fi

    # Check for retry patterns
    local retry_count=$(sqlite3 "$PERF_DB" \
        "SELECT COUNT(*) FROM operation_metrics
         WHERE entity='$entity' AND timestamp > datetime('now', '-1 hour')")

    if [ "$retry_count" -gt 3 ]; then
        severity="HIGH"
        alert=true
    fi

    # Log bottleneck alert
    if [ "$alert" = true ]; then
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

        sqlite3 "$PERF_DB" <<EOF
INSERT INTO bottleneck_alerts (detected_at, type, entity, severity, duration_ms, retry_count)
VALUES ('$timestamp', '$action', '$entity', '$severity', $duration_ms, $retry_count);
EOF

        # Display alert
        case $severity in
            CRITICAL)
                echo -e "${RED}🚨 CRITICAL BOTTLENECK: $entity took ${duration_ms}ms${NC}" >&2
                ;;
            HIGH)
                echo -e "${YELLOW}⚠️  HIGH: $entity - duration: ${duration_ms}ms, retries: $retry_count${NC}" >&2
                ;;
            MEDIUM)
                echo -e "${CYAN}ℹ️  MEDIUM: $entity slow (${duration_ms}ms)${NC}" >&2
                ;;
        esac
    fi
}

# Update agent performance stats
update_agent_stats() {
    local agent="$1"
    local success="$2"
    local duration_ms="$3"

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    sqlite3 "$PERF_DB" <<EOF
INSERT INTO agent_performance (agent_hash, total_operations, successful_ops, failed_ops, first_seen, last_seen, status)
VALUES ('$agent', 1, $([ "$success" = "true" ] && echo 1 || echo 0), $([ "$success" = "false" ] && echo 1 || echo 0), '$timestamp', '$timestamp', 'active')
ON CONFLICT(agent_hash) DO UPDATE SET
    total_operations = total_operations + 1,
    successful_ops = successful_ops + $([ "$success" = "true" ] && echo 1 || echo 0),
    failed_ops = failed_ops + $([ "$success" = "false" ] && echo 1 || echo 0),
    last_seen = '$timestamp',
    status = 'active';
EOF
}

# Get real-time bottleneck alerts
get_alerts() {
    local timeframe="${1:-1 hour}"

    echo -e "${PURPLE}🚨 Active Bottleneck Alerts (last $timeframe):${NC}\n"

    sqlite3 -column -header "$PERF_DB" <<EOF
SELECT
    detected_at,
    severity,
    type,
    entity,
    duration_ms || 'ms' as duration,
    retry_count
FROM bottleneck_alerts
WHERE detected_at > datetime('now', '-$timeframe')
  AND resolved = 0
ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    detected_at DESC;
EOF
}

# Show performance dashboard
show_dashboard() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     🌌 Memory Performance Dashboard          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}\n"

    # Active alerts
    local critical=$(sqlite3 "$PERF_DB" "SELECT COUNT(*) FROM bottleneck_alerts WHERE severity='CRITICAL' AND resolved=0")
    local high=$(sqlite3 "$PERF_DB" "SELECT COUNT(*) FROM bottleneck_alerts WHERE severity='HIGH' AND resolved=0")
    local medium=$(sqlite3 "$PERF_DB" "SELECT COUNT(*) FROM bottleneck_alerts WHERE severity='MEDIUM' AND resolved=0")

    echo -e "${YELLOW}Active Alerts:${NC}"
    echo -e "  ${RED}CRITICAL:${NC} $critical"
    echo -e "  ${YELLOW}HIGH:${NC} $high"
    echo -e "  ${CYAN}MEDIUM:${NC} $medium\n"

    # Slowest operations in last hour
    echo -e "${YELLOW}Slowest Operations (last hour):${NC}"
    sqlite3 -column "$PERF_DB" <<EOF
SELECT
    action,
    entity,
    duration_ms || 'ms' as duration
FROM operation_metrics
WHERE timestamp > datetime('now', '-1 hour')
ORDER BY duration_ms DESC
LIMIT 5;
EOF

    echo ""

    # Agent performance
    echo -e "${YELLOW}Agent Performance:${NC}"
    sqlite3 -column -header "$PERF_DB" <<EOF
SELECT
    agent_hash,
    total_operations as ops,
    successful_ops as success,
    failed_ops as failed,
    ROUND(100.0 * successful_ops / total_operations, 1) || '%' as success_rate
FROM agent_performance
WHERE last_seen > datetime('now', '-24 hours')
ORDER BY total_operations DESC
LIMIT 5;
EOF

    echo ""

    # Throughput
    echo -e "${YELLOW}Throughput (last 24 hours):${NC}"
    sqlite3 -column "$PERF_DB" <<EOF
SELECT
    strftime('%Y-%m-%d %H:00', timestamp) as hour,
    COUNT(*) as operations,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful,
    ROUND(AVG(duration_ms)) || 'ms' as avg_duration
FROM operation_metrics
WHERE timestamp > datetime('now', '-24 hours')
GROUP BY strftime('%Y-%m-%d %H:00', timestamp)
ORDER BY hour DESC
LIMIT 10;
EOF

    echo ""
}

# Export performance data
export_data() {
    local format="${1:-json}"
    local output_file="$MEMORY_DIR/analytics/performance-export-$(date +%Y%m%d-%H%M%S).$format"

    case $format in
        json)
            sqlite3 "$PERF_DB" <<EOF > "$output_file"
.mode json
SELECT * FROM operation_metrics WHERE timestamp > datetime('now', '-24 hours');
EOF
            ;;
        csv)
            sqlite3 -csv -header "$PERF_DB" <<EOF > "$output_file"
SELECT * FROM operation_metrics WHERE timestamp > datetime('now', '-24 hours');
EOF
            ;;
        *)
            echo -e "${RED}Unknown format: $format${NC}"
            return 1
            ;;
    esac

    echo -e "${GREEN}✅ Data exported to: $output_file${NC}"
}

# Get recommendations based on performance data
get_recommendations() {
    echo -e "${PURPLE}💡 Performance Recommendations:${NC}\n"

    # Check for slow operations
    local slow_ops=$(sqlite3 "$PERF_DB" \
        "SELECT COUNT(*) FROM operation_metrics WHERE duration_ms > 30000 AND timestamp > datetime('now', '-24 hours')")

    if [ "$slow_ops" -gt 10 ]; then
        echo -e "${YELLOW}⚠️  High number of slow operations ($slow_ops)${NC}"
        echo -e "   ${CYAN}→${NC} Consider implementing caching or parallel processing\n"
    fi

    # Check for high failure rate
    local total_ops=$(sqlite3 "$PERF_DB" \
        "SELECT COUNT(*) FROM operation_metrics WHERE timestamp > datetime('now', '-24 hours')")
    local failed_ops=$(sqlite3 "$PERF_DB" \
        "SELECT COUNT(*) FROM operation_metrics WHERE success=0 AND timestamp > datetime('now', '-24 hours')")

    if [ "$total_ops" -gt 0 ]; then
        local failure_rate=$((100 * failed_ops / total_ops))
        if [ "$failure_rate" -gt 20 ]; then
            echo -e "${YELLOW}⚠️  High failure rate: ${failure_rate}%${NC}"
            echo -e "   ${CYAN}→${NC} Implement retry logic with exponential backoff\n"
        fi
    fi

    # Check for retry patterns
    local retried_entities=$(sqlite3 "$PERF_DB" \
        "SELECT entity, COUNT(*) as cnt FROM operation_metrics
         WHERE timestamp > datetime('now', '-1 hour')
         GROUP BY entity HAVING cnt > 3")

    if [ -n "$retried_entities" ]; then
        echo -e "${YELLOW}⚠️  Entities with multiple retry attempts:${NC}"
        echo "$retried_entities" | while read entity count; do
            echo -e "   ${CYAN}→${NC} $entity ($count attempts)"
        done
        echo ""
    fi

    # Memory usage
    local avg_memory=$(sqlite3 "$PERF_DB" \
        "SELECT ROUND(AVG(memory_usage_mb)) FROM operation_metrics WHERE timestamp > datetime('now', '-1 hour')")

    if [ "$avg_memory" -gt 500 ]; then
        echo -e "${YELLOW}⚠️  High average memory usage: ${avg_memory}MB${NC}"
        echo -e "   ${CYAN}→${NC} Consider optimizing memory-intensive operations\n"
    fi
}

# Main execution
case "${1:-help}" in
    init)
        init_perf_db
        echo -e "${GREEN}✅ Enhanced memory performance tracking initialized${NC}"
        ;;
    log)
        shift
        log_with_perf "$@"
        ;;
    alerts)
        get_alerts "${2:-1 hour}"
        ;;
    dashboard)
        show_dashboard
        ;;
    export)
        export_data "${2:-json}"
        ;;
    recommendations)
        get_recommendations
        ;;
    *)
        echo "Enhanced Memory Logging System"
        echo ""
        echo "Usage:"
        echo "  $0 init                              - Initialize performance tracking"
        echo "  $0 log ACTION ENTITY DETAILS [AGENT] [START_TIME] [SUCCESS]"
        echo "  $0 alerts [timeframe]                - Show active bottleneck alerts"
        echo "  $0 dashboard                         - Show performance dashboard"
        echo "  $0 export [json|csv]                 - Export performance data"
        echo "  $0 recommendations                   - Get optimization recommendations"
        echo ""
        echo "Example:"
        echo "  START=\$(date +%s%3N)"
        echo "  # ... do work ..."
        echo "  $0 log 'enhanced' 'my-repo' 'Added features' 'agent-123' \$START true"
        ;;
esac
