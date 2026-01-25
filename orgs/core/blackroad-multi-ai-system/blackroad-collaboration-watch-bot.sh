#!/bin/bash

# Agent Collaboration Watch Bot - Automated coordination assistant!
# Monitors for new BlackRoad Agents, suggests coordination, helps with onboarding

MEMORY_DIR="$HOME/.blackroad/memory"
WATCH_STATE="$MEMORY_DIR/watch-bot-state.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize watch state
init_watch() {
    mkdir -p "$(dirname "$WATCH_STATE")"
    cat > "$WATCH_STATE" << 'EOF'
{
    "last_check": "",
    "known_agents": [],
    "welcomed_agents": [],
    "coordination_suggestions": [],
    "start_time": ""
}
EOF
    echo -e "${GREEN}✅ Watch bot initialized${NC}"
}

# Watch for new activity and coordinate
watch_loop() {
    local interval="${1:-10}"

    [[ ! -f "$WATCH_STATE" ]] && init_watch

    # Set start time if not set
    local start_time=$(jq -r '.start_time' "$WATCH_STATE")
    if [[ -z "$start_time" || "$start_time" == "null" ]]; then
        start_time=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        jq --arg ts "$start_time" '.start_time = $ts' "$WATCH_STATE" > "${WATCH_STATE}.tmp"
        mv "${WATCH_STATE}.tmp" "$WATCH_STATE"
    fi

    local iteration=0

    while true; do
        ((iteration++))
        clear

        echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${CYAN}║        🤖 CLAUDE COLLABORATION WATCH BOT 🤖               ║${NC}"
        echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}$(date "+%Y-%m-%d %H:%M:%S") • Check #$iteration • Interval: ${interval}s${NC}"
        echo ""

        # Run all checks
        local new_agents=$(check_new_agents)
        local coord_opps=$(check_coordination_needs)
        local urgent_tasks=$(check_urgent_tasks)
        local blocked=$(check_blocked_agents)

        # Display summary
        echo ""
        echo -e "${BOLD}${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}Summary:${NC}"
        echo -e "  ${GREEN}✅ New BlackRoad Agents welcomed: $new_agents${NC}"
        echo -e "  ${YELLOW}🤝 Coordination suggestions: $coord_opps${NC}"
        echo -e "  ${RED}🚨 Urgent tasks broadcast: $urgent_tasks${NC}"
        echo -e "  ${BLUE}💬 Blocked BlackRoad Agents helped: $blocked${NC}"

        # Save state
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        jq --arg ts "$timestamp" '.last_check = $ts' "$WATCH_STATE" > "${WATCH_STATE}.tmp"
        mv "${WATCH_STATE}.tmp" "$WATCH_STATE"

        echo ""
        echo -e "${BLUE}Next check in ${interval}s • Press Ctrl+C to stop${NC}"

        sleep "$interval"
    done
}

# Check for new BlackRoad Agents and welcome them
check_new_agents() {
    local count=0
    local welcomed=$(jq -r '.welcomed_agents[]' "$WATCH_STATE" 2>/dev/null || echo "")

    # Get recent announces
    tail -100 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
        jq -r 'select(.action == "announce") | .entity' | sort -u | while read -r agent_id; do

        [[ -z "$agent_id" ]] && continue

        # Skip if already welcomed
        if echo "$welcomed" | grep -q "^${agent_id}$"; then
            continue
        fi

        echo -e "${GREEN}🆕 Welcoming new Agent: ${CYAN}$agent_id${NC}"

        # Send welcome message
        ~/memory-system.sh log coordination "watch-bot → $agent_id" "
👋 Welcome to BlackRoad, $agent_id!

I'm the collaboration watch bot. Here to help you get started!

🎯 QUICK START TOOLS:

📋 Task Marketplace - Find work to do!
   ~/memory-task-marketplace.sh list

🔔 Dependency Notifications - Subscribe to events
   ~/memory-dependency-notify.sh subscribe <event> completed

🌌 Live Dashboard - See everyone working
   ~/memory-collaboration-dashboard.sh compact

💡 TIL Broadcasts - Share & learn
   ~/memory-til-broadcast.sh list

🔍 Check what others are doing:
   ~/memory-realtime-context.sh live $agent_id compact

📚 Full protocol:
   cat ~/CLAUDE_COLLABORATION_PROTOCOL.md

Need help? Just ask in [MEMORY]! We're all here to collaborate! 🚀
" 2>/dev/null

        # Mark as welcomed
        jq --arg agent "$agent_id" '.welcomed_agents += [$agent]' "$WATCH_STATE" > "${WATCH_STATE}.tmp"
        mv "${WATCH_STATE}.tmp" "$WATCH_STATE"

        ((count++))
    done

    echo "$count"
}

# Check for coordination opportunities
check_coordination_needs() {
    local count=0

    # Check if task marketplace exists
    [[ ! -d "$MEMORY_DIR/tasks/claimed" ]] && echo "0" && return

    # Get all claimed tasks
    local claimed_tasks=$(ls -1 "$MEMORY_DIR/tasks/claimed"/*.json 2>/dev/null)
    [[ -z "$claimed_tasks" ]] && echo "0" && return

    # Simple check: if 2+ tasks claimed, suggest they coordinate
    local num_claimed=$(echo "$claimed_tasks" | wc -l | tr -d ' ')

    if [[ $num_claimed -ge 2 ]]; then
        # Get the BlackRoad Agents
        local agents=()
        for task_file in $claimed_tasks; do
            local agent=$(jq -r '.claimed_by' "$task_file")
            agents+=("$agent")
        done

        # Check if we already suggested this combo
        local combo_key=$(IFS=+; echo "${agents[*]}" | tr ' ' '+')

        if ! jq -e --arg key "$combo_key" '.coordination_suggestions[] | select(. == $key)' "$WATCH_STATE" &>/dev/null; then
            echo -e "${YELLOW}🤝 Multiple BlackRoad Agents working - suggesting coordination${NC}"

            ~/memory-system.sh log coordination "watch-bot" "
🤝 COORDINATION HEADS-UP!

Multiple BlackRoad Agents are actively working:
$(for task_file in $claimed_tasks; do
    local agent=$(jq -r '.claimed_by' "$task_file")
    local task=$(jq -r '.task_id' "$task_file")
    echo "  • $agent → $task"
done)

Consider coordinating if there are dependencies or overlaps!

Check the dashboard: ~/memory-collaboration-dashboard.sh compact
" 2>/dev/null

            # Mark as suggested
            jq --arg key "$combo_key" '.coordination_suggestions += [$key]' "$WATCH_STATE" > "${WATCH_STATE}.tmp"
            mv "${WATCH_STATE}.tmp" "$WATCH_STATE"

            ((count++))
        fi
    fi

    echo "$count"
}

# Check for urgent tasks
check_urgent_tasks() {
    local count=0

    [[ ! -d "$MEMORY_DIR/tasks/available" ]] && echo "0" && return

    for task_file in "$MEMORY_DIR/tasks/available"/*.json; do
        [[ ! -f "$task_file" ]] && continue

        local priority=$(jq -r '.priority' "$task_file")

        if [[ "$priority" == "urgent" ]]; then
            local task_id=$(jq -r '.task_id' "$task_file")
            local title=$(jq -r '.title' "$task_file")

            echo -e "${RED}🚨 Broadcasting urgent task: ${CYAN}$task_id${NC}"

            ~/memory-system.sh log announcement "watch-bot" "
🚨 URGENT TASK NEEDS ATTENTION! 🚨

Task ID: $task_id
Title: $title
Priority: URGENT

Claim it NOW: ~/memory-task-marketplace.sh claim $task_id

Time is of the essence! ⚡
" 2>/dev/null

            ((count++))
        fi
    done

    echo "$count"
}

# Check for blocked BlackRoad Agents
check_blocked_agents() {
    local count=0

    # Look for blocked status in recent memory
    tail -50 "$MEMORY_DIR/journals/master-journal.jsonl" 2>/dev/null | \
        jq -r 'select(.action == "blocked") | .entity' | sort -u | while read -r agent_id; do

        [[ -z "$agent_id" ]] && continue

        echo -e "${BLUE}💬 Helping blocked Agent: ${CYAN}$agent_id${NC}"

        ~/memory-system.sh log coordination "watch-bot → $agent_id" "
👋 I see you're blocked, $agent_id!

HERE'S WHAT YOU CAN DO:

1️⃣ Subscribe to the event you're waiting for:
   ~/memory-dependency-notify.sh subscribe <event-name> completed

2️⃣ Work on another task while waiting:
   ~/memory-task-marketplace.sh list

3️⃣ Share what blocked you (help others avoid it):
   ~/memory-til-broadcast.sh broadcast gotcha \"[what went wrong]\"

4️⃣ Ask for help from other BlackRoad Agents in [MEMORY]!

You're not alone - we're a team! 💪
" 2>/dev/null

        ((count++))
    done

    echo "$count"
}

# One-time check
check_once() {
    [[ ! -f "$WATCH_STATE" ]] && init_watch

    echo -e "${CYAN}🔍 Running collaboration check...${NC}"
    echo ""

    local new=$(check_new_agents)
    local coord=$(check_coordination_needs)
    local urgent=$(check_urgent_tasks)
    local blocked=$(check_blocked_agents)

    echo ""
    echo -e "${GREEN}✅ Check complete!${NC}"
    echo -e "  New BlackRoad Agents: $new"
    echo -e "  Coordination suggestions: $coord"
    echo -e "  Urgent broadcasts: $urgent"
    echo -e "  Blocked helped: $blocked"
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║      🤖 Agent Collaboration Watch Bot - Help 🤖          ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 [command] [interval]

${GREEN}COMMANDS:${NC}

${BLUE}watch${NC} [interval-seconds]
    Start watching (default: 10s)
    Example: $0 watch 15

${BLUE}--once${NC}
    Single check without looping
    Example: $0 --once

${BLUE}init${NC}
    Initialize watch bot state
    Example: $0 init

${GREEN}WHAT IT DOES:${NC}

    🆕 Welcomes new BlackRoad Agents with onboarding info
    🤝 Suggests coordination when multiple tasks active
    🚨 Broadcasts urgent tasks to everyone
    💬 Helps blocked BlackRoad Agents with suggestions
    📊 Tracks welcoming history to avoid spam

${GREEN}EXAMPLES:${NC}

    # Start watching (10s interval)
    $0 watch

    # Watch with 5s interval
    $0 watch 5

    # Single check
    $0 --once

EOF
}

# Main
case "$1" in
    watch|"")
        watch_loop "${2:-10}"
        ;;
    --once)
        check_once
        ;;
    init)
        init_watch
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
