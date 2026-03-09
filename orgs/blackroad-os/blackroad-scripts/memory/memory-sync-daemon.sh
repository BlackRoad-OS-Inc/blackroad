#!/bin/bash
# BlackRoad Real-Time Memory Sync Daemon
# Enables multiple concurrent Claude instances to share memory in real-time
# Polls journal changes at 1ms intervals and broadcasts updates

set -e

VERSION="2.0.0-realtime"

# Configuration
MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL_DIR="$MEMORY_DIR/journals"
SYNC_DIR="$MEMORY_DIR/sync"
DAEMON_PID_FILE="$SYNC_DIR/daemon.pid"
POLL_INTERVAL=0.001  # 1ms

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Helper functions
log_info() {
    echo -e "${BLUE}[SYNC]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SYNC]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SYNC]${NC} $1"
}

log_error() {
    echo -e "${RED}[SYNC]${NC} $1"
}

log_broadcast() {
    echo -e "${CYAN}[BROADCAST]${NC} $1"
}

# Initialize sync infrastructure
init_sync() {
    log_info "Initializing real-time sync system..."

    mkdir -p "$SYNC_DIR/instances"
    mkdir -p "$SYNC_DIR/broadcasts"
    mkdir -p "$SYNC_DIR/checkpoints"

    # Create instance registry
    cat > "$SYNC_DIR/instance-registry.jsonl" <<EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)","action":"registry_init","details":"Real-time sync initialized"}
EOF

    # Create sync config
    cat > "$SYNC_DIR/sync-config.json" <<EOF
{
  "version": "${VERSION}",
  "poll_interval_ms": 1,
  "max_instances": 100,
  "broadcast_ttl_seconds": 60,
  "checkpoint_interval_entries": 100
}
EOF

    log_success "Sync infrastructure ready"
}

# Register Claude instance
register_instance() {
    local instance_id="${1:-claude-$(date +%s)-$$}"
    local instance_file="$SYNC_DIR/instances/${instance_id}.json"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)"

    cat > "$instance_file" <<EOF
{
  "instance_id": "${instance_id}",
  "pid": $$,
  "registered_at": "${timestamp}",
  "last_seen": "${timestamp}",
  "hostname": "$(hostname)",
  "working_directory": "$(pwd)",
  "journal_position": 0,
  "status": "active"
}
EOF

    # Log to instance registry
    echo "{\"timestamp\":\"${timestamp}\",\"action\":\"instance_registered\",\"instance_id\":\"${instance_id}\",\"pid\":$$}" >> "$SYNC_DIR/instance-registry.jsonl"

    echo "$instance_id"
}

# Update instance heartbeat
update_heartbeat() {
    local instance_id="$1"
    local journal_position="$2"
    local instance_file="$SYNC_DIR/instances/${instance_id}.json"

    if [ -f "$instance_file" ]; then
        # Update last_seen and position using jq
        local temp_file="${instance_file}.tmp"
        jq --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)" \
           --arg position "$journal_position" \
           '.last_seen = $timestamp | .journal_position = ($position | tonumber)' \
           "$instance_file" > "$temp_file" && mv "$temp_file" "$instance_file"
    fi
}

# Get journal position (last line read)
get_journal_position() {
    local instance_id="$1"
    local instance_file="$SYNC_DIR/instances/${instance_id}.json"

    if [ -f "$instance_file" ]; then
        jq -r '.journal_position' "$instance_file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Broadcast new entries to all instances
broadcast_entries() {
    local start_line="$1"
    local end_line="$2"
    local broadcast_id="broadcast-$(date +%s%3N)"
    local broadcast_file="$SYNC_DIR/broadcasts/${broadcast_id}.jsonl"

    # Extract new entries
    sed -n "${start_line},${end_line}p" "$JOURNAL_DIR/master-journal.jsonl" > "$broadcast_file"

    # Add metadata
    local entry_count=$((end_line - start_line + 1))
    log_broadcast "New entries: ${entry_count} (lines ${start_line}-${end_line})"

    # Cleanup old broadcasts (older than TTL)
    find "$SYNC_DIR/broadcasts" -name "broadcast-*.jsonl" -mmin +1 -delete 2>/dev/null || true
}

# Watch journal and broadcast changes
watch_journal() {
    local instance_id="$1"
    local last_line_count=0

    log_info "Starting real-time journal watcher (${POLL_INTERVAL}s polling)"
    log_info "Instance: $instance_id"

    if [ ! -f "$JOURNAL_DIR/master-journal.jsonl" ]; then
        log_error "Master journal not found. Initialize memory system first."
        return 1
    fi

    while true; do
        # Get current line count
        local current_line_count=$(wc -l < "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null || echo "0")

        # Check if new entries exist
        if [ "$current_line_count" -gt "$last_line_count" ]; then
            local start_line=$((last_line_count + 1))
            local end_line=$current_line_count

            # Broadcast new entries
            broadcast_entries "$start_line" "$end_line"

            # Update position
            update_heartbeat "$instance_id" "$current_line_count"

            last_line_count=$current_line_count
        else
            # Just update heartbeat
            update_heartbeat "$instance_id" "$last_line_count"
        fi

        # Poll at configured interval
        sleep $POLL_INTERVAL
    done
}

# Get real-time updates for specific instance
get_updates() {
    local instance_id="$1"
    local last_position=$(get_journal_position "$instance_id")
    local current_line_count=$(wc -l < "$JOURNAL_DIR/master-journal.jsonl" 2>/dev/null || echo "0")

    if [ "$current_line_count" -gt "$last_position" ]; then
        local start_line=$((last_position + 1))

        echo -e "${CYAN}[UPDATES]${NC} New entries available (${start_line}-${current_line_count}):"
        echo ""

        sed -n "${start_line},${current_line_count}p" "$JOURNAL_DIR/master-journal.jsonl" | \
            jq -r '"  [" + .timestamp + "] " + .action + ": " + .entity + " — " + .details'

        # Update position
        update_heartbeat "$instance_id" "$current_line_count"
    else
        echo "No new updates"
    fi
}

# List active instances
list_instances() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  🔄 Active Claude Instances                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ ! -d "$SYNC_DIR/instances" ]; then
        log_warning "No instances directory found"
        return 0
    fi

    local instance_count=0

    for instance_file in "$SYNC_DIR/instances"/*.json; do
        if [ -f "$instance_file" ]; then
            local instance_id=$(jq -r '.instance_id' "$instance_file")
            local pid=$(jq -r '.pid' "$instance_file")
            local last_seen=$(jq -r '.last_seen' "$instance_file")
            local position=$(jq -r '.journal_position' "$instance_file")
            local status=$(jq -r '.status' "$instance_file")

            # Check if process is still running
            if ps -p "$pid" > /dev/null 2>&1; then
                status="${GREEN}active${NC}"
            else
                status="${RED}dead${NC}"
            fi

            echo -e "  ${GREEN}Instance:${NC} $instance_id"
            echo -e "  ${GREEN}PID:${NC} $pid (${status})"
            echo -e "  ${GREEN}Position:${NC} $position entries"
            echo -e "  ${GREEN}Last seen:${NC} $last_seen"
            echo ""

            ((instance_count++))
        fi
    done

    if [ $instance_count -eq 0 ]; then
        log_warning "No active instances"
    else
        echo -e "Total: $instance_count instances"
    fi
}

# Start daemon in background
start_daemon() {
    if [ -f "$DAEMON_PID_FILE" ]; then
        local old_pid=$(cat "$DAEMON_PID_FILE")
        if ps -p "$old_pid" > /dev/null 2>&1; then
            log_warning "Daemon already running (PID: $old_pid)"
            return 0
        else
            log_warning "Removing stale PID file"
            rm "$DAEMON_PID_FILE"
        fi
    fi

    # Initialize if needed
    if [ ! -f "$SYNC_DIR/sync-config.json" ]; then
        init_sync
    fi

    # Register instance
    local instance_id=$(register_instance "daemon-$(date +%s)")

    # Start watcher in background
    nohup "$0" _internal_watch "$instance_id" \
        > "$SYNC_DIR/daemon.log" 2>&1 &

    local daemon_pid=$!
    echo "$daemon_pid" > "$DAEMON_PID_FILE"

    log_success "Daemon started (PID: $daemon_pid, Instance: $instance_id)"
    echo "  Log: $SYNC_DIR/daemon.log"
}

# Stop daemon
stop_daemon() {
    if [ ! -f "$DAEMON_PID_FILE" ]; then
        log_warning "No daemon PID file found"
        return 0
    fi

    local daemon_pid=$(cat "$DAEMON_PID_FILE")

    if ps -p "$daemon_pid" > /dev/null 2>&1; then
        log_info "Stopping daemon (PID: $daemon_pid)..."
        kill "$daemon_pid"
        rm "$DAEMON_PID_FILE"
        log_success "Daemon stopped"
    else
        log_warning "Daemon not running (stale PID)"
        rm "$DAEMON_PID_FILE"
    fi
}

# Show daemon status
daemon_status() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  🔄 Real-Time Sync Daemon Status                  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ -f "$DAEMON_PID_FILE" ]; then
        local daemon_pid=$(cat "$DAEMON_PID_FILE")

        if ps -p "$daemon_pid" > /dev/null 2>&1; then
            echo -e "  ${GREEN}Status:${NC} Running ✅"
            echo -e "  ${GREEN}PID:${NC} $daemon_pid"
            echo -e "  ${GREEN}Poll interval:${NC} ${POLL_INTERVAL}s (1ms)"

            # Show CPU/Memory usage
            local ps_stats=$(ps -p "$daemon_pid" -o %cpu,%mem,vsz,rss | tail -1)
            echo -e "  ${GREEN}Resources:${NC} $ps_stats"

            # Show recent log entries
            if [ -f "$SYNC_DIR/daemon.log" ]; then
                echo ""
                echo -e "${BLUE}Recent activity:${NC}"
                tail -5 "$SYNC_DIR/daemon.log" | sed 's/^/  /'
            fi
        else
            echo -e "  ${RED}Status:${NC} Dead ❌ (stale PID)"
        fi
    else
        echo -e "  ${YELLOW}Status:${NC} Not running"
    fi

    echo ""
}

# Show help
show_help() {
    cat <<EOF
BlackRoad Real-Time Memory Sync Daemon v${VERSION}

USAGE:
    memory-sync-daemon.sh <command> [options]

COMMANDS:
    init                          Initialize sync infrastructure
    start                         Start sync daemon (1ms polling)
    stop                          Stop sync daemon
    status                        Show daemon status
    register [instance-id]        Register new Claude instance
    updates <instance-id>         Get updates for instance
    instances                     List all active instances
    help                          Show this help

EXAMPLES:
    # Start daemon
    memory-sync-daemon.sh init
    memory-sync-daemon.sh start

    # Register Claude instance
    INSTANCE_ID=\$(memory-sync-daemon.sh register "claude-session-1")
    echo \$INSTANCE_ID

    # Get real-time updates
    memory-sync-daemon.sh updates \$INSTANCE_ID

    # Monitor instances
    memory-sync-daemon.sh instances

    # Check daemon
    memory-sync-daemon.sh status

SYNC LOCATIONS:
    Instances:   $SYNC_DIR/instances/
    Broadcasts:  $SYNC_DIR/broadcasts/
    Daemon log:  $SYNC_DIR/daemon.log
    Registry:    $SYNC_DIR/instance-registry.jsonl

REAL-TIME FEATURES:
    ✅ 1ms polling interval
    ✅ Lock-free concurrent reads
    ✅ Atomic append-only writes
    ✅ Automatic position tracking
    ✅ Instance heartbeats
    ✅ Broadcast to all instances
    ✅ Automatic cleanup

EOF
}

# Main command handler
case "${1:-help}" in
    init)
        init_sync
        ;;
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        daemon_status
        ;;
    register)
        register_instance "${2:-}"
        ;;
    updates)
        if [ -z "$2" ]; then
            log_error "Usage: $0 updates <instance-id>"
            exit 1
        fi
        get_updates "$2"
        ;;
    _internal_watch)
        watch_journal "$2"
        ;;
    instances)
        list_instances
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
