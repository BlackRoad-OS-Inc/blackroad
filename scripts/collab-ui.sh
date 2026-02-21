#!/bin/bash
# BLACKROAD COLLABORATION UI
# Terminal UI showing all active Claude agents and their status

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'

MEMORY_DIR="$HOME/.blackroad/memory"
AGENTS_DIR="$MEMORY_DIR/active-agents"
JOURNAL="$MEMORY_DIR/journals/master-journal.jsonl"

# Clear screen and show header
show_header() {
    clear
    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║          BLACKROAD COLLABORATION HUB                         ║${RESET}"
    echo -e "${PINK}║          All Claudes. One Empire.                            ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# Show active agents
show_agents() {
    echo -e "${AMBER}ACTIVE AGENTS${RESET}"
    echo -e "${AMBER}─────────────${RESET}"

    local count=0
    if [[ -d "$AGENTS_DIR" ]]; then
        for agent_file in "$AGENTS_DIR"/*.json; do
            [[ -f "$agent_file" ]] || continue
            count=$((count + 1))

            local name=$(jq -r '.name // "unknown"' "$agent_file" 2>/dev/null)
            local status=$(jq -r '.status // "unknown"' "$agent_file" 2>/dev/null)
            local project=$(jq -r '.project // "none"' "$agent_file" 2>/dev/null)
            local last_seen=$(jq -r '.last_seen // "never"' "$agent_file" 2>/dev/null)

            local status_color="$GREEN"
            [[ "$status" == "busy" ]] && status_color="$AMBER"
            [[ "$status" == "offline" ]] && status_color="$RED"

            echo -e "  ${status_color}●${RESET} ${PINK}$name${RESET}"
            echo -e "    Status: ${status_color}$status${RESET}"
            echo -e "    Project: $project"
            echo -e "    Last: $last_seen"
            echo ""
        done
    fi

    if [[ $count -eq 0 ]]; then
        echo -e "  ${AMBER}No active agents${RESET}"
        echo -e "  Run ${PINK}~/claude-session-init.sh${RESET} to register"
    else
        echo -e "  Total: ${GREEN}$count${RESET} active agents"
    fi
    echo ""
}

# Show recent memory entries
show_recent_memory() {
    echo -e "${AMBER}RECENT ACTIVITY${RESET}"
    echo -e "${AMBER}───────────────${RESET}"

    if [[ -f "$JOURNAL" ]]; then
        tail -5 "$JOURNAL" | while read -r line; do
            local action=$(echo "$line" | jq -r '.action // "unknown"')
            local entity=$(echo "$line" | jq -r '.entity // "unknown"')
            local agent=$(echo "$line" | jq -r '.agent // "unknown"')
            local time=$(echo "$line" | jq -r '.timestamp // ""' | cut -d'T' -f2 | cut -d'.' -f1)

            echo -e "  ${BLUE}$time${RESET} ${PINK}$agent${RESET} → $action: $entity"
        done
    else
        echo -e "  ${AMBER}No journal entries${RESET}"
    fi
    echo ""
}

# Show traffic lights
show_traffic_lights() {
    echo -e "${AMBER}PROJECT STATUS${RESET}"
    echo -e "${AMBER}──────────────${RESET}"

    if command -v ~/blackroad-traffic-light.sh &>/dev/null; then
        ~/blackroad-traffic-light.sh summary 2>/dev/null | head -10
    else
        echo -e "  ${AMBER}Traffic light system not available${RESET}"
    fi
    echo ""
}

# Show task marketplace
show_tasks() {
    echo -e "${AMBER}TASK MARKETPLACE${RESET}"
    echo -e "${AMBER}────────────────${RESET}"

    if command -v ~/memory-task-marketplace.sh &>/dev/null; then
        ~/memory-task-marketplace.sh stats 2>/dev/null
    else
        echo -e "  ${AMBER}Task marketplace not available${RESET}"
    fi
    echo ""
}

# Show current agent info
show_current() {
    echo -e "${AMBER}YOU ARE${RESET}"
    echo -e "${AMBER}───────${RESET}"
    echo -e "  Agent: ${PINK}${CLAUDE_NAME:-unset}${RESET}"
    echo -e "  ID: ${MY_CLAUDE:-unset}"
    echo -e "  PWD: $(pwd)"
    echo ""
}

# Show editor sync status
show_sync() {
    echo -e "${AMBER}EDITOR SYNC${RESET}"
    echo -e "${AMBER}───────────${RESET}"

    local state_file="$MEMORY_DIR/editor-state.json"
    if [[ -f "$state_file" ]]; then
        local last_editor=$(jq -r '.last_editor // "none"' "$state_file")
        local last_sync=$(jq -r '.last_sync // "never"' "$state_file")
        echo -e "  Last Editor: ${PINK}$last_editor${RESET}"
        echo -e "  Last Sync: $last_sync"
    else
        echo -e "  ${AMBER}No sync state${RESET}"
    fi
    echo ""
}

# Watch mode
watch_mode() {
    while true; do
        show_header
        show_current
        show_agents
        show_recent_memory
        show_sync
        echo -e "${AMBER}Press Ctrl+C to exit | Refreshing every 5s${RESET}"
        sleep 5
    done
}

# Compact view
compact() {
    echo -e "${PINK}BLACKROAD COLLAB${RESET} | Agents: $(ls "$AGENTS_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ') | You: ${CLAUDE_NAME:-?}"
}

# Main
case "${1:-full}" in
    watch|-w)
        watch_mode
        ;;
    agents)
        show_agents
        ;;
    memory|recent)
        show_recent_memory
        ;;
    tasks)
        show_tasks
        ;;
    traffic|lights)
        show_traffic_lights
        ;;
    sync)
        show_sync
        ;;
    compact|-c)
        compact
        ;;
    full|*)
        show_header
        show_current
        show_agents
        show_recent_memory
        show_sync
        ;;
esac
