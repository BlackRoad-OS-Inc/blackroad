#!/bin/bash

# BlackRoad Collaboration Dashboard
# Real-time visualization of multi-Agent coordination!

MEMORY_DIR="$HOME/.blackroad/memory"
TASKS_DIR="$MEMORY_DIR/tasks"
DEPS_DIR="$MEMORY_DIR/dependencies"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Show full dashboard
show_dashboard() {
    local refresh_rate="${1:-5}"

    while true; do
        clear

        echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║                    🌌 BLACKROAD COLLABORATION DASHBOARD 🌌                   ║${NC}"
        echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        echo -e "${BLUE}📊 Live View${NC} • ${timestamp} • Refreshing every ${refresh_rate}s"
        echo ""

        # Active BlackRoad Agents section
        echo -e "${BOLD}${PURPLE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${BOLD}${PURPLE}┃ 👥 ACTIVE CLAUDES                                                          ┃${NC}"
        echo -e "${BOLD}${PURPLE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

        show_active_agents
        echo ""

        # Task Marketplace section
        echo -e "${BOLD}${YELLOW}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${BOLD}${YELLOW}┃ 📋 TASK MARKETPLACE                                                        ┃${NC}"
        echo -e "${BOLD}${YELLOW}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

        show_task_summary
        echo ""

        # Dependencies section
        echo -e "${BOLD}${CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${BOLD}${CYAN}┃ 🔔 DEPENDENCY TRACKING                                                     ┃${NC}"
        echo -e "${BOLD}${CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

        show_dependencies
        echo ""

        # Recent activity section
        echo -e "${BOLD}${GREEN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
        echo -e "${BOLD}${GREEN}┃ 📜 RECENT ACTIVITY                                                         ┃${NC}"
        echo -e "${BOLD}${GREEN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"

        show_recent_activity
        echo ""

        echo -e "${BLUE}Press Ctrl+C to exit${NC}"

        sleep "$refresh_rate"
    done
}

# Show active Agent instances
show_active_agents() {
    # Get active BlackRoad Agents from memory sync
    if [[ -d "$MEMORY_DIR/sync" ]]; then
        local active_count=0

        for sync_file in "$MEMORY_DIR/sync"/*.json; do
            [[ ! -f "$sync_file" ]] && continue

            local agent_id=$(jq -r '.agent_id // .id' "$sync_file" 2>/dev/null)
            local last_seen=$(jq -r '.last_seen // .timestamp' "$sync_file" 2>/dev/null)
            local status=$(jq -r '.status // "active"' "$sync_file" 2>/dev/null)

            if [[ -n "$agent_id" && "$agent_id" != "null" ]]; then
                # Check if active (seen in last 5 minutes)
                local now=$(date +%s)
                local last_seen_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo $last_seen | cut -d'.' -f1)" +%s 2>/dev/null || echo 0)
                local diff=$((now - last_seen_ts))

                if [[ $diff -lt 300 ]]; then  # 5 minutes
                    echo -e "  ${GREEN}●${NC} ${CYAN}$agent_id${NC} (Last seen: $(format_time_ago $diff))"
                    ((active_count++))
                fi
            fi
        done

        if [[ $active_count -eq 0 ]]; then
            echo -e "  ${YELLOW}No active BlackRoad Agents detected${NC}"
        else
            echo -e "  ${BOLD}Total active: $active_count${NC}"
        fi
    else
        echo -e "  ${YELLOW}Sync directory not found${NC}"
    fi
}

# Show task marketplace summary
show_task_summary() {
    if [[ ! -d "$TASKS_DIR" ]]; then
        echo -e "  ${YELLOW}Task marketplace not initialized${NC}"
        return
    fi

    local available=$(ls -1 "$TASKS_DIR/available"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local claimed=$(ls -1 "$TASKS_DIR/claimed"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local completed=$(ls -1 "$TASKS_DIR/completed"/*.json 2>/dev/null | wc -l | tr -d ' ')

    echo -e "  ${GREEN}✅ Completed: $completed${NC}  ${YELLOW}⏳ In Progress: $claimed${NC}  ${BLUE}📋 Available: $available${NC}"

    # Show urgent/high priority tasks
    if [[ $available -gt 0 ]]; then
        echo ""
        echo -e "  ${BOLD}High Priority Tasks:${NC}"

        for task_file in "$TASKS_DIR/available"/*.json; do
            [[ ! -f "$task_file" ]] && continue

            local priority=$(jq -r '.priority' "$task_file")

            if [[ "$priority" == "urgent" || "$priority" == "high" ]]; then
                local task_id=$(jq -r '.task_id' "$task_file")
                local title=$(jq -r '.title' "$task_file")

                if [[ "$priority" == "urgent" ]]; then
                    echo -e "    ${RED}🚨 URGENT${NC} $task_id: $title"
                else
                    echo -e "    ${YELLOW}⚡ HIGH${NC}   $task_id: $title"
                fi
            fi
        done
    fi

    # Show who's working on what
    if [[ $claimed -gt 0 ]]; then
        echo ""
        echo -e "  ${BOLD}Currently Working:${NC}"

        for task_file in "$TASKS_DIR/claimed"/*.json; do
            [[ ! -f "$task_file" ]] && continue

            local task_id=$(jq -r '.task_id' "$task_file")
            local claimed_by=$(jq -r '.claimed_by' "$task_file")
            local title=$(jq -r '.title' "$task_file")

            echo -e "    ${CYAN}$claimed_by${NC} → $task_id: ${title:0:50}..."
        done
    fi
}

# Show dependency tracking
show_dependencies() {
    if [[ ! -d "$DEPS_DIR/subscriptions" ]]; then
        echo -e "  ${YELLOW}Dependency system not initialized${NC}"
        return
    fi

    local sub_count=$(ls -1 "$DEPS_DIR/subscriptions"/*.json 2>/dev/null | wc -l | tr -d ' ')

    if [[ $sub_count -eq 0 ]]; then
        echo -e "  ${YELLOW}No active subscriptions${NC}"
        return
    fi

    echo -e "  ${BOLD}Active Subscriptions: $sub_count${NC}"
    echo ""

    # Group by subscriber
    declare -A subs_by_agent

    for sub_file in "$DEPS_DIR/subscriptions"/*.json; do
        [[ ! -f "$sub_file" ]] && continue

        local subscriber=$(jq -r '.subscriber' "$sub_file")
        local event_name=$(jq -r '.event_name' "$sub_file")
        local notify_when=$(jq -r '.notify_when' "$sub_file")

        if [[ -z "${subs_by_agent[$subscriber]}" ]]; then
            subs_by_agent[$subscriber]="$event_name ($notify_when)"
        else
            subs_by_agent[$subscriber]="${subs_by_agent[$subscriber]}, $event_name ($notify_when)"
        fi
    done

    for agent_id in "${!subs_by_agent[@]}"; do
        echo -e "  ${CYAN}$agent_id${NC}"
        echo -e "    ${BLUE}Waiting for:${NC} ${subs_by_agent[$agent_id]}"
    done
}

# Show recent memory activity
show_recent_activity() {
    if [[ ! -f "$MEMORY_DIR/journals/master-journal.jsonl" ]]; then
        echo -e "  ${YELLOW}No journal found${NC}"
        return
    fi

    tail -8 "$MEMORY_DIR/journals/master-journal.jsonl" | while read -r line; do
        local timestamp=$(echo "$line" | jq -r '.timestamp' | cut -d'T' -f2 | cut -d'.' -f1)
        local action=$(echo "$line" | jq -r '.action')
        local entity=$(echo "$line" | jq -r '.entity')
        local details=$(echo "$line" | jq -r '.details' | head -c 60)

        # Color by action
        local action_color="$NC"
        local icon="•"
        case "$action" in
            announce) action_color="$PURPLE"; icon="📢" ;;
            progress) action_color="$BLUE"; icon="⚡" ;;
            completed) action_color="$GREEN"; icon="✅" ;;
            coordination) action_color="$CYAN"; icon="🤝" ;;
            task-*) action_color="$YELLOW"; icon="📋" ;;
            *) action_color="$NC"; icon="•" ;;
        esac

        echo -e "  ${BLUE}$timestamp${NC} ${icon} ${action_color}$action${NC} • $entity"
    done
}

# Format time ago
format_time_ago() {
    local seconds=$1

    if [[ $seconds -lt 60 ]]; then
        echo "${seconds}s ago"
    elif [[ $seconds -lt 3600 ]]; then
        echo "$((seconds / 60))m ago"
    else
        echo "$((seconds / 3600))h ago"
    fi
}

# Compact view
show_compact() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       🌌 BLACKROAD COLLABORATION - QUICK VIEW 🌌          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Quick stats
    local available=$(ls -1 "$TASKS_DIR/available"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local claimed=$(ls -1 "$TASKS_DIR/claimed"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local completed=$(ls -1 "$TASKS_DIR/completed"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local subs=$(ls -1 "$DEPS_DIR/subscriptions"/*.json 2>/dev/null | wc -l | tr -d ' ')

    echo -e "${BOLD}Quick Stats:${NC}"
    echo -e "  Tasks: ${GREEN}$completed done${NC}, ${YELLOW}$claimed in progress${NC}, ${BLUE}$available available${NC}"
    echo -e "  Subscriptions: ${CYAN}$subs active${NC}"
    echo ""

    echo -e "${BOLD}Latest Activity:${NC}"
    tail -5 "$MEMORY_DIR/journals/master-journal.jsonl" | while read -r line; do
        local action=$(echo "$line" | jq -r '.action')
        local entity=$(echo "$line" | jq -r '.entity')
        echo -e "  • ${CYAN}$action${NC}: $entity"
    done
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║    🌌 BlackRoad Collaboration Dashboard - Help 🌌         ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 [command] [options]

${GREEN}COMMANDS:${NC}

${BLUE}dashboard${NC} [refresh-rate]
    Show full live dashboard (default: refresh every 5s)
    Example: $0 dashboard 10

${BLUE}compact${NC}
    Show compact quick view (single refresh)
    Example: $0 compact

${BLUE}watch${NC} [refresh-rate]
    Alias for dashboard
    Example: $0 watch 3

${GREEN}FEATURES:${NC}

    • Real-time view of all active Agent instances
    • Task marketplace status (available/claimed/completed)
    • Dependency tracking (who's waiting for what)
    • Recent collaboration activity stream
    • Color-coded priorities and statuses

${GREEN}EXAMPLES:${NC}

    # Full dashboard, refresh every 5 seconds
    $0 dashboard

    # Fast refresh (every 2 seconds)
    $0 dashboard 2

    # One-time quick view
    $0 compact

EOF
}

# Main command router
case "$1" in
    dashboard|watch|"")
        show_dashboard "${2:-5}"
        ;;
    compact)
        show_compact
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo -e "Run ${CYAN}$0 help${NC} for usage information"
        exit 1
        ;;
esac
