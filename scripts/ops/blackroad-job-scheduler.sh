#!/bin/bash
# BlackRoad Job Scheduler
# Distributed job scheduling and execution across the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

SCHEDULER_DIR="$HOME/.blackroad/scheduler"
JOBS_DB="$SCHEDULER_DIR/jobs.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Job priorities
PRIORITY_LOW=1
PRIORITY_NORMAL=5
PRIORITY_HIGH=10
PRIORITY_CRITICAL=20

# Initialize
init() {
    mkdir -p "$SCHEDULER_DIR"/{logs,results}

    sqlite3 "$JOBS_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS jobs (
    id TEXT PRIMARY KEY,
    name TEXT,
    command TEXT,
    node TEXT,
    priority INTEGER DEFAULT 5,
    status TEXT DEFAULT 'pending',
    retries INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    timeout INTEGER DEFAULT 300,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    completed_at DATETIME,
    exit_code INTEGER,
    output TEXT,
    error TEXT
);

CREATE TABLE IF NOT EXISTS schedules (
    id TEXT PRIMARY KEY,
    job_name TEXT,
    cron TEXT,
    command TEXT,
    node TEXT,
    enabled INTEGER DEFAULT 1,
    last_run DATETIME,
    next_run DATETIME
);

CREATE INDEX IF NOT EXISTS idx_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_priority ON jobs(priority DESC);
SQL

    echo -e "${GREEN}Job scheduler initialized${RESET}"
}

# Submit a job
submit() {
    local name="$1"
    local command="$2"
    local node="${3:-auto}"
    local priority="${4:-$PRIORITY_NORMAL}"

    local job_id="job_$(date +%s)_$(openssl rand -hex 4)"

    sqlite3 "$JOBS_DB" "
        INSERT INTO jobs (id, name, command, node, priority)
        VALUES ('$job_id', '$name', '$(echo "$command" | sed "s/'/''/g")', '$node', $priority)
    "

    echo -e "${GREEN}Job submitted: $job_id${RESET}"
    echo "  Name: $name"
    echo "  Node: $node"
    echo "  Priority: $priority"

    echo "$job_id"
}

# Select best node for job
select_node() {
    local best_node=""
    local best_load=999

    for node in "${ALL_NODES[@]}"; do
        if ! ssh -o ConnectTimeout=2 "$node" "echo ok" >/dev/null 2>&1; then
            continue
        fi

        local load=$(ssh "$node" "cat /proc/loadavg | awk '{print \$1}'" 2>/dev/null || echo 999)

        if [ "$(echo "$load < $best_load" | bc -l)" = "1" ]; then
            best_load=$load
            best_node=$node
        fi
    done

    echo "$best_node"
}

# Execute a single job
execute_job() {
    local job_id="$1"

    local job=$(sqlite3 "$JOBS_DB" "
        SELECT command, node, timeout FROM jobs WHERE id = '$job_id'
    ")

    local command=$(echo "$job" | cut -d'|' -f1)
    local node=$(echo "$job" | cut -d'|' -f2)
    local timeout=$(echo "$job" | cut -d'|' -f3)

    # Auto-select node if needed
    [ "$node" = "auto" ] && node=$(select_node)

    if [ -z "$node" ]; then
        sqlite3 "$JOBS_DB" "
            UPDATE jobs SET status = 'failed', error = 'No available nodes'
            WHERE id = '$job_id'
        "
        return 1
    fi

    # Mark as running
    sqlite3 "$JOBS_DB" "
        UPDATE jobs SET status = 'running', node = '$node', started_at = datetime('now')
        WHERE id = '$job_id'
    "

    # Execute
    local output_file="$SCHEDULER_DIR/results/${job_id}.out"
    local error_file="$SCHEDULER_DIR/results/${job_id}.err"

    local exit_code
    timeout "$timeout" ssh "$node" "$command" > "$output_file" 2> "$error_file"
    exit_code=$?

    # Update job status
    local status="completed"
    [ $exit_code -ne 0 ] && status="failed"

    local output=$(cat "$output_file" 2>/dev/null | head -c 10000 | sed "s/'/''/g")
    local error=$(cat "$error_file" 2>/dev/null | head -c 5000 | sed "s/'/''/g")

    sqlite3 "$JOBS_DB" "
        UPDATE jobs SET
            status = '$status',
            completed_at = datetime('now'),
            exit_code = $exit_code,
            output = '$output',
            error = '$error'
        WHERE id = '$job_id'
    "

    return $exit_code
}

# Process pending jobs
process() {
    local max_parallel="${1:-3}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           ⚙️  JOB SCHEDULER PROCESSING                        ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo

    local pending=$(sqlite3 "$JOBS_DB" "
        SELECT COUNT(*) FROM jobs WHERE status = 'pending'
    ")

    echo "Pending jobs: $pending"
    echo "Max parallel: $max_parallel"
    echo

    local running=0
    local processed=0

    while true; do
        # Get next job by priority
        local job_id=$(sqlite3 "$JOBS_DB" "
            SELECT id FROM jobs
            WHERE status = 'pending'
            ORDER BY priority DESC, created_at ASC
            LIMIT 1
        ")

        [ -z "$job_id" ] && break

        # Wait if at capacity
        while [ $running -ge $max_parallel ]; do
            wait -n 2>/dev/null
            ((running--))
        done

        echo -n "  Processing $job_id... "

        (
            if execute_job "$job_id"; then
                echo -e "${GREEN}done${RESET}"
            else
                echo -e "${RED}failed${RESET}"
            fi
        ) &

        ((running++))
        ((processed++))
    done

    wait

    echo
    echo -e "${GREEN}Processed $processed jobs${RESET}"
}

# Run scheduler daemon
daemon() {
    local interval="${1:-10}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔄 JOB SCHEDULER DAEMON                            ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Check interval: ${interval}s"
    echo "Press Ctrl+C to stop"
    echo

    while true; do
        local pending=$(sqlite3 "$JOBS_DB" "SELECT COUNT(*) FROM jobs WHERE status = 'pending'")
        local running=$(sqlite3 "$JOBS_DB" "SELECT COUNT(*) FROM jobs WHERE status = 'running'")

        echo "[$(date '+%H:%M:%S')] Pending: $pending, Running: $running"

        if [ "$pending" -gt 0 ]; then
            process 3 >/dev/null 2>&1 &
        fi

        # Check scheduled jobs
        check_schedules

        sleep "$interval"
    done
}

# Schedule a recurring job
schedule() {
    local name="$1"
    local cron="$2"
    local command="$3"
    local node="${4:-auto}"

    local schedule_id="sched_$(openssl rand -hex 4)"

    sqlite3 "$JOBS_DB" "
        INSERT INTO schedules (id, job_name, cron, command, node)
        VALUES ('$schedule_id', '$name', '$cron', '$(echo "$command" | sed "s/'/''/g")', '$node')
    "

    echo -e "${GREEN}Schedule created: $schedule_id${RESET}"
    echo "  Name: $name"
    echo "  Cron: $cron"
}

# Check and run scheduled jobs
check_schedules() {
    # Simplified - would need proper cron parsing
    local schedules=$(sqlite3 "$JOBS_DB" "
        SELECT id, job_name, command, node FROM schedules
        WHERE enabled = 1
    ")

    # In production, parse cron expressions and check if due
}

# List jobs
list() {
    local status="${1:-all}"
    local limit="${2:-20}"

    echo -e "${PINK}=== JOBS ===${RESET}"
    echo

    local where=""
    [ "$status" != "all" ] && where="WHERE status = '$status'"

    sqlite3 "$JOBS_DB" "
        SELECT id, name, status, node, priority, created_at
        FROM jobs $where
        ORDER BY created_at DESC
        LIMIT $limit
    " | while IFS='|' read -r id name status node priority created; do
        local color=$RESET
        case $status in
            pending) color=$YELLOW ;;
            running) color=$BLUE ;;
            completed) color=$GREEN ;;
            failed) color=$RED ;;
        esac

        printf "%-20s %-15s ${color}%-10s${RESET} %-10s P%s\n" "$id" "$name" "$status" "$node" "$priority"
    done
}

# Get job details
info() {
    local job_id="$1"

    local job=$(sqlite3 "$JOBS_DB" "
        SELECT * FROM jobs WHERE id = '$job_id'
    ")

    if [ -z "$job" ]; then
        echo -e "${RED}Job not found: $job_id${RESET}"
        return 1
    fi

    echo -e "${PINK}=== JOB DETAILS ===${RESET}"
    echo

    sqlite3 "$JOBS_DB" -line "SELECT * FROM jobs WHERE id = '$job_id'"
}

# Cancel job
cancel() {
    local job_id="$1"

    sqlite3 "$JOBS_DB" "
        UPDATE jobs SET status = 'cancelled'
        WHERE id = '$job_id' AND status IN ('pending', 'running')
    "

    echo -e "${GREEN}Cancelled: $job_id${RESET}"
}

# Retry failed job
retry() {
    local job_id="$1"

    sqlite3 "$JOBS_DB" "
        UPDATE jobs SET status = 'pending', retries = retries + 1
        WHERE id = '$job_id' AND status = 'failed'
    "

    echo -e "${GREEN}Retrying: $job_id${RESET}"
}

# Clear old jobs
cleanup() {
    local days="${1:-7}"

    sqlite3 "$JOBS_DB" "
        DELETE FROM jobs
        WHERE status IN ('completed', 'failed', 'cancelled')
        AND datetime(completed_at, '+$days days') < datetime('now')
    "

    echo -e "${GREEN}Cleaned jobs older than $days days${RESET}"
}

# Stats
stats() {
    echo -e "${PINK}=== SCHEDULER STATS ===${RESET}"
    echo

    echo "Job counts:"
    sqlite3 "$JOBS_DB" "
        SELECT status, COUNT(*) FROM jobs GROUP BY status
    " | while IFS='|' read -r status count; do
        echo "  $status: $count"
    done

    echo
    echo "By node:"
    sqlite3 "$JOBS_DB" "
        SELECT node, COUNT(*), AVG(CASE WHEN exit_code = 0 THEN 1 ELSE 0 END) * 100
        FROM jobs WHERE status = 'completed'
        GROUP BY node
    " | while IFS='|' read -r node count success; do
        printf "  %-10s %d jobs (%.0f%% success)\n" "$node" "$count" "$success"
    done

    echo
    echo "Schedules:"
    sqlite3 "$JOBS_DB" "SELECT COUNT(*) FROM schedules WHERE enabled = 1" | xargs echo "  Active:"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Job Scheduler${RESET}"
    echo
    echo "Distributed job scheduling for the cluster"
    echo
    echo "Commands:"
    echo "  submit <name> <cmd> [node] [pri]  Submit job"
    echo "  process [parallel]                Process pending jobs"
    echo "  daemon [interval]                 Run scheduler daemon"
    echo "  schedule <name> <cron> <cmd>      Create scheduled job"
    echo "  list [status] [limit]             List jobs"
    echo "  info <job_id>                     Job details"
    echo "  cancel <job_id>                   Cancel job"
    echo "  retry <job_id>                    Retry failed job"
    echo "  cleanup [days]                    Clear old jobs"
    echo "  stats                             Scheduler statistics"
    echo
    echo "Priorities: low=1, normal=5, high=10, critical=20"
    echo
    echo "Examples:"
    echo "  $0 submit backup 'tar czf /tmp/backup.tar.gz /opt' auto 10"
    echo "  $0 schedule nightly-backup '0 2 * * *' '/opt/backup.sh'"
    echo "  $0 daemon 30"
}

# Ensure initialized
[ -f "$JOBS_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    submit|add)
        submit "$2" "$3" "$4" "$5"
        ;;
    process|run)
        process "$2"
        ;;
    daemon|start)
        daemon "$2"
        ;;
    schedule|cron)
        schedule "$2" "$3" "$4" "$5"
        ;;
    list|ls)
        list "$2" "$3"
        ;;
    info|show)
        info "$2"
        ;;
    cancel|kill)
        cancel "$2"
        ;;
    retry)
        retry "$2"
        ;;
    cleanup|clean)
        cleanup "$2"
        ;;
    stats)
        stats
        ;;
    *)
        help
        ;;
esac
