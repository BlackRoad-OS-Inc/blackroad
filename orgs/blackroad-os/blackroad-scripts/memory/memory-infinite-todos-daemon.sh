#!/bin/bash

# BlackRoad Infinite To-Dos Progress Broadcast Daemon
# Monitors long-running projects and broadcasts progress updates

MEMORY_DIR="$HOME/.blackroad/memory"
TODOS_DIR="$MEMORY_DIR/infinite-todos"
DAEMON_DIR="$MEMORY_DIR/daemon"
BROADCAST_INTERVAL=60  # seconds

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize daemon
init_daemon() {
    mkdir -p "$DAEMON_DIR"

    cat > "$DAEMON_DIR/config.json" << 'EOF'
{
    "enabled": true,
    "broadcast_interval": 60,
    "watchers": [],
    "last_broadcast": null
}
EOF

    echo -e "${GREEN}✅ Progress broadcast daemon initialized!${NC}"
}

# Start daemon in background
start_daemon() {
    local mode="${1:-background}"

    if [[ -f "$DAEMON_DIR/daemon.pid" ]]; then
        local pid=$(cat "$DAEMON_DIR/daemon.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${YELLOW}Daemon already running (PID: $pid)${NC}"
            return
        fi
    fi

    if [[ "$mode" == "foreground" ]]; then
        run_daemon_loop
    else
        run_daemon_loop &
        local daemon_pid=$!
        echo "$daemon_pid" > "$DAEMON_DIR/daemon.pid"
        echo -e "${GREEN}✅ Daemon started (PID: $daemon_pid)${NC}"
    fi
}

# Stop daemon
stop_daemon() {
    if [[ ! -f "$DAEMON_DIR/daemon.pid" ]]; then
        echo -e "${YELLOW}Daemon not running${NC}"
        return
    fi

    local pid=$(cat "$DAEMON_DIR/daemon.pid")
    if ps -p "$pid" > /dev/null 2>&1; then
        kill "$pid"
        rm "$DAEMON_DIR/daemon.pid"
        echo -e "${GREEN}✅ Daemon stopped${NC}"
    else
        echo -e "${YELLOW}Daemon not running (stale PID file)${NC}"
        rm "$DAEMON_DIR/daemon.pid"
    fi
}

# Main daemon loop
run_daemon_loop() {
    echo -e "${CYAN}🔄 Progress broadcast daemon running...${NC}"

    while true; do
        broadcast_progress
        sleep "$BROADCAST_INTERVAL"
    done
}

# Broadcast progress for all active projects
broadcast_progress() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Update last broadcast time
    jq --arg ts "$timestamp" '.last_broadcast = $ts' \
       "$DAEMON_DIR/config.json" > "$DAEMON_DIR/config.tmp" && \
       mv "$DAEMON_DIR/config.tmp" "$DAEMON_DIR/config.json"

    # Check all active projects
    for project_file in "$TODOS_DIR/projects"/*.json; do
        [[ ! -f "$project_file" ]] && continue

        local project_id=$(jq -r '.project_id' "$project_file")
        local title=$(jq -r '.title' "$project_file")
        local status=$(jq -r '.status' "$project_file")
        local progress=$(jq -r '.progress' "$project_file")
        local owner=$(jq -r '.owner' "$project_file")
        local updated_at=$(jq -r '.updated_at' "$project_file")

        # Only broadcast active projects
        if [[ "$status" == "active" ]]; then
            # Calculate time since last update
            local updated_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${updated_at:0:19}" "+%s" 2>/dev/null || echo "0")
            local now_epoch=$(date "+%s")
            local seconds_since=$((now_epoch - updated_epoch))

            # Check if project needs attention (no updates in 1 hour)
            if [[ $seconds_since -gt 3600 ]]; then
                ~/memory-system.sh log alert "$project_id" "⚠️  Project '$title' hasn't been updated in $(($seconds_since / 3600)) hours. Owner: $owner. Progress: $progress%"
            fi

            # Regular progress broadcast
            local total_todos=$(jq '.todos | length' "$project_file")
            local completed_todos=$(jq '[.todos[] | select(.status == "completed")] | length' "$project_file")
            local pending_todos=$((total_todos - completed_todos))

            # Only broadcast if there's meaningful progress
            if [[ $progress -gt 0 ]] && [[ $progress -lt 100 ]]; then
                ~/memory-system.sh log progress-broadcast "$project_id" "📊 $title: $progress% ($completed_todos/$total_todos todos). $pending_todos remaining. Owner: $owner"
            fi

            # Check for upcoming milestones
            local milestones=$(jq -r '.milestones[] | select(.status == "pending") | "\(.name)|\(.target_date)"' "$project_file")
            if [[ -n "$milestones" ]]; then
                while IFS='|' read -r milestone_name target_date; do
                    if [[ "$target_date" != "null" ]]; then
                        local target_epoch=$(date -j -f "%Y-%m-%d" "$target_date" "+%s" 2>/dev/null || echo "0")
                        local days_until=$(( (target_epoch - now_epoch) / 86400 ))

                        if [[ $days_until -le 7 ]] && [[ $days_until -ge 0 ]]; then
                            ~/memory-system.sh log milestone-warning "$project_id" "🎯 Milestone '$milestone_name' due in $days_until days! Project: $title ($progress% complete)"
                        fi
                    fi
                done <<< "$milestones"
            fi
        fi
    done
}

# Watch a specific project
watch_project() {
    local project_id="$1"
    local interval="${2:-5}"  # seconds

    if [[ -z "$project_id" ]]; then
        echo -e "${RED}Usage: watch <project-id> [interval-seconds]${NC}"
        return 1
    fi

    echo -e "${CYAN}👁️  Watching project: ${BOLD}$project_id${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""

    while true; do
        clear
        ~/memory-infinite-todos.sh show "$project_id"
        echo ""
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "Refreshing every ${interval}s... (Ctrl+C to stop)"
        sleep "$interval"
    done
}

# Show daemon status
status() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      🔄 PROGRESS BROADCAST DAEMON - STATUS 🔄             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ -f "$DAEMON_DIR/daemon.pid" ]]; then
        local pid=$(cat "$DAEMON_DIR/daemon.pid")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Daemon is running${NC}"
            echo -e "   ${BLUE}PID:${NC} $pid"
        else
            echo -e "${RED}❌ Daemon not running (stale PID)${NC}"
        fi
    else
        echo -e "${YELLOW}⏸️  Daemon not running${NC}"
    fi

    if [[ -f "$DAEMON_DIR/config.json" ]]; then
        local last_broadcast=$(jq -r '.last_broadcast // "never"' "$DAEMON_DIR/config.json")
        local interval=$(jq -r '.broadcast_interval' "$DAEMON_DIR/config.json")

        echo -e "   ${BLUE}Last broadcast:${NC} $last_broadcast"
        echo -e "   ${BLUE}Interval:${NC} ${interval}s"
    fi

    echo ""
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Active Projects Being Monitored:${NC}"
    echo ""

    local active_count=0
    for project_file in "$TODOS_DIR/projects"/*.json; do
        [[ ! -f "$project_file" ]] && continue

        local status=$(jq -r '.status' "$project_file")
        if [[ "$status" == "active" ]]; then
            local project_id=$(jq -r '.project_id' "$project_file")
            local title=$(jq -r '.title' "$project_file")
            local progress=$(jq -r '.progress' "$project_file")

            echo -e "  ${CYAN}$project_id${NC} - $title (${progress}%)"
            ((active_count++))
        fi
    done

    if [[ $active_count -eq 0 ]]; then
        echo -e "  ${YELLOW}No active projects${NC}"
    fi
}

# One-time broadcast
once() {
    echo -e "${CYAN}📡 Broadcasting progress once...${NC}"
    broadcast_progress
    echo -e "${GREEN}✅ Broadcast complete${NC}"
}

# Main command router
case "$1" in
    init)
        init_daemon
        ;;
    start)
        start_daemon "${2:-background}"
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
        status
        ;;
    watch)
        watch_project "$2" "$3"
        ;;
    once)
        once
        ;;
    broadcast)
        broadcast_progress
        ;;
    *)
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║      🔄 PROGRESS BROADCAST DAEMON 🔄                      ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo -e ""
        echo -e "${BOLD}Usage:${NC} $0 <command> [arguments]"
        echo -e ""
        echo -e "${BOLD}Commands:${NC}"
        echo -e "  ${GREEN}init${NC}                    - Initialize daemon"
        echo -e "  ${GREEN}start${NC} [mode]            - Start daemon (background|foreground)"
        echo -e "  ${GREEN}stop${NC}                    - Stop daemon"
        echo -e "  ${GREEN}restart${NC}                 - Restart daemon"
        echo -e "  ${GREEN}status${NC}                  - Show daemon status"
        echo -e "  ${GREEN}watch${NC} <project> [int]   - Watch a project (refresh interval)"
        echo -e "  ${GREEN}once${NC}                    - Broadcast progress once"
        echo -e "  ${GREEN}broadcast${NC}               - Trigger broadcast manually"
        echo -e ""
        echo -e "${BOLD}Features:${NC}"
        echo -e "  • Broadcasts progress every 60 seconds"
        echo -e "  • Alerts when projects haven't been updated in 1+ hour"
        echo -e "  • Warns about upcoming milestones (within 7 days)"
        echo -e "  • Monitors all active projects automatically"
        echo -e ""
        echo -e "${BOLD}Examples:${NC}"
        echo -e "  $0 start              # Start daemon in background"
        echo -e "  $0 watch quantum-physics-agents 5    # Watch project, refresh every 5s"
        echo -e "  $0 status             # Check daemon status"
        ;;
esac
