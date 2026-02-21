#!/bin/zsh
#===============================================================================
# Context Radar - File Watcher Daemon
# Monitors file access and builds contextual relationships
#===============================================================================

RADAR_HOME="/Users/alexa/blackroad/tools/context-radar"
RADAR_DB="${RADAR_HOME}/data/radar.db"
WATCH_DIR="/Users/alexa/blackroad"
PID_FILE="${RADAR_HOME}/data/radar.pid"
LOG_FILE="${RADAR_HOME}/data/radar.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Source database functions
source "${RADAR_HOME}/radar-db.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Track recently accessed files for relationship building
typeset -a RECENT_FILES
MAX_RECENT=10
TIME_WINDOW=300  # 5 minutes

add_to_recent() {
    local filepath=$1
    local timestamp=$(date +%s)
    
    # Add to front of array
    RECENT_FILES=("${filepath}:${timestamp}" "${RECENT_FILES[@]}")
    
    # Trim old entries and limit size
    local new_recent=()
    local count=0
    for entry in "${RECENT_FILES[@]}"; do
        local file="${entry%%:*}"
        local time="${entry##*:}"
        if (( timestamp - time < TIME_WINDOW && count < MAX_RECENT )); then
            new_recent+=("$entry")
            ((count++))
        fi
    done
    RECENT_FILES=("${new_recent[@]}")
}

# Process file access event
process_file_event() {
    local filepath=$1
    local event_type=$2
    
    # Ignore hidden files, git internals, and common noise
    if [[ "$filepath" =~ "/\." ]] || \
       [[ "$filepath" =~ "\.git/" ]] || \
       [[ "$filepath" =~ "\.log$" ]] || \
       [[ "$filepath" =~ "\.tmp$" ]] || \
       [[ "$filepath" =~ "node_modules/" ]] || \
       [[ "$filepath" =~ "__pycache__/" ]] || \
       [[ "$filepath" =~ "\.pyc$" ]]; then
        return
    fi
    
    # Log the access
    log_access "$filepath" "$event_type"
    
    # Build relationships with recently accessed files
    for entry in "${RECENT_FILES[@]}"; do
        local recent_file="${entry%%:*}"
        if [[ "$recent_file" != "$filepath" ]]; then
            update_relationship "$filepath" "$recent_file" "co-accessed"
        fi
    done
    
    # Add to recent files
    add_to_recent "$filepath"
    
    log "📝 Tracked: ${filepath##*/} ($event_type)"
}

# Detect relationship type based on filenames
detect_relationship_type() {
    local file1=$1
    local file2=$2
    
    local base1="${file1##*/}"
    local base2="${file2##*/}"
    local name1="${base1%.*}"
    local name2="${base2%.*}"
    
    # Test relationship detection
    if [[ "$name1" =~ "test" ]] && [[ "$file2" =~ "$name2" ]]; then
        echo "test-source"
    elif [[ "$name2" =~ "test" ]] && [[ "$file1" =~ "$name1" ]]; then
        echo "test-source"
    elif [[ "$file1" =~ "README" ]] || [[ "$file1" =~ "\.md$" ]]; then
        echo "documentation"
    elif [[ "$base1" == "$base2" ]]; then
        echo "same-name"
    else
        echo "co-accessed"
    fi
}

# Start the daemon
start_daemon() {
    if [[ -f "$PID_FILE" ]]; then
        local old_pid=$(cat "$PID_FILE")
        if ps -p $old_pid > /dev/null 2>&1; then
            echo -e "${YELLOW}Daemon already running (PID: $old_pid)${NC}"
            return 1
        else
            rm "$PID_FILE"
        fi
    fi
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     🎯 CECE's Context Radar - Starting       ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    log "Starting Context Radar daemon..."
    log "Watching: $WATCH_DIR"
    
    # Check for fswatch
    if ! command -v fswatch &> /dev/null; then
        echo -e "${RED}Error: fswatch not found${NC}"
        echo "Install with: brew install fswatch"
        return 1
    fi
    
    # Initialize recent files from database
    log "Loading recent activity..."
    
    # Start the standalone watcher in background
    nohup "${RADAR_HOME}/radar-watcher.sh" >> "$LOG_FILE" 2>&1 &
    
    local daemon_pid=$!
    echo $daemon_pid > "$PID_FILE"
    
    echo -e "${GREEN}✓ Daemon started (PID: $daemon_pid)${NC}"
    echo "Monitor logs: tail -f $LOG_FILE"
    log "Daemon started successfully (PID: $daemon_pid)"
}

# Stop the daemon
stop_daemon() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo -e "${YELLOW}Daemon not running${NC}"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    if ps -p $pid > /dev/null 2>&1; then
        kill $pid
        rm "$PID_FILE"
        echo -e "${GREEN}✓ Daemon stopped${NC}"
        log "Daemon stopped"
    else
        echo -e "${YELLOW}Daemon not running (stale PID file)${NC}"
        rm "$PID_FILE"
    fi
}

# Check daemon status
check_status() {
    if [[ ! -f "$PID_FILE" ]]; then
        echo -e "${YELLOW}● Daemon: not running${NC}"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    if ps -p $pid > /dev/null 2>&1; then
        echo -e "${GREEN}● Daemon: running (PID: $pid)${NC}"
        echo ""
        get_stats
        return 0
    else
        echo -e "${RED}● Daemon: dead (stale PID file)${NC}"
        rm "$PID_FILE"
        return 1
    fi
}

# Show help
show_help() {
    cat <<EOF
Context Radar Daemon - File Activity Monitor

Usage: radar-daemon.sh {start|stop|restart|status}

Commands:
  start    - Start the file watching daemon
  stop     - Stop the daemon
  restart  - Restart the daemon
  status   - Check daemon status and show stats

The daemon watches $WATCH_DIR for file changes and builds
a contextual map of file relationships.

Logs: $LOG_FILE
Database: $RADAR_DB
EOF
}

# Main dispatch
case ${1:-} in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    status)
        check_status
        ;;
    *)
        show_help
        ;;
esac
