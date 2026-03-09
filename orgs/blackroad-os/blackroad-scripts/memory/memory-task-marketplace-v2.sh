#!/bin/bash

# BlackRoad Task Marketplace - Where BlackRoad Agents find work!
# A revolutionary system for multi-Agent coordination at scale

MEMORY_DIR="$HOME/.blackroad/memory"
TASKS_DIR="$MEMORY_DIR/tasks"
CLAIMED_DIR="$TASKS_DIR/claimed"
AVAILABLE_DIR="$TASKS_DIR/available"
COMPLETED_DIR="$TASKS_DIR/completed"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Initialize marketplace
init_marketplace() {
    mkdir -p "$TASKS_DIR" "$CLAIMED_DIR" "$AVAILABLE_DIR" "$COMPLETED_DIR"
    echo -e "${GREEN}✅ Task Marketplace initialized!${NC}"
}

# Post a new task
post_task() {
    local task_id="$1"
    local title="$2"
    local description="$3"
    local priority="${4:-medium}"
    local tags="${5:-general}"
    local skills="${6:-any}"

    if [[ -z "$task_id" || -z "$title" ]]; then
        echo -e "${RED}Usage: post <task-id> <title> <description> [priority] [tags] [skills]${NC}"
        return 1
    fi

    local task_file="$AVAILABLE_DIR/${task_id}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    cat > "$task_file" << EOF
{
    "task_id": "$task_id",
    "title": "$title",
    "description": "$description",
    "priority": "$priority",
    "tags": "$tags",
    "skills": "$skills",
    "status": "available",
    "posted_at": "$timestamp",
    "posted_by": "${MY_AGENT:-unknown}"
}
EOF

    # Log to memory system
    ~/memory-system.sh log task-posted "$task_id" "📋 New task: $title (Priority: $priority, Skills: $skills, Tags: $tags)"

    echo -e "${GREEN}✅ Task posted: ${CYAN}$task_id${NC}"
    echo -e "   ${BLUE}Title:${NC} $title"
    echo -e "   ${BLUE}Priority:${NC} $priority"
    echo -e "   ${BLUE}Skills:${NC} $skills"
}

# List available tasks
list_tasks() {
    local filter_priority="$1"
    local filter_tags="$2"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           📋 BLACKROAD TASK MARKETPLACE 📋                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local available_count=$(ls -1 "$AVAILABLE_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local claimed_count=$(ls -1 "$CLAIMED_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local completed_count=$(ls -1 "$COMPLETED_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

    echo -e "${GREEN}Available:${NC} $available_count  ${YELLOW}In Progress:${NC} $claimed_count  ${BLUE}Completed:${NC} $completed_count"
    echo ""

    if [[ $available_count -eq 0 ]]; then
        echo -e "${YELLOW}No tasks available. Post one with: ./memory-task-marketplace.sh post <task-id> <title> <description>${NC}"
        return
    fi

    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    for task_file in "$AVAILABLE_DIR"/*.json; do
        [[ ! -f "$task_file" ]] && continue

        local task_id=$(jq -r '.task_id' "$task_file")
        local title=$(jq -r '.title' "$task_file")
        local priority=$(jq -r '.priority' "$task_file")
        local tags=$(jq -r '.tags' "$task_file")
        local skills=$(jq -r '.skills' "$task_file")
        local posted_at=$(jq -r '.posted_at' "$task_file")

        # Filter by priority if specified
        if [[ -n "$filter_priority" && "$priority" != "$filter_priority" ]]; then
            continue
        fi

        # Filter by tags if specified
        if [[ -n "$filter_tags" && "$tags" != *"$filter_tags"* ]]; then
            continue
        fi

        # Priority color
        local priority_color="$NC"
        case "$priority" in
            high|urgent) priority_color="$RED" ;;
            medium) priority_color="$YELLOW" ;;
            low) priority_color="$GREEN" ;;
        esac

        echo -e "${CYAN}📌 $task_id${NC}"
        echo -e "   ${BLUE}Title:${NC} $title"
        echo -e "   ${BLUE}Priority:${NC} ${priority_color}$priority${NC}"
        echo -e "   ${BLUE}Skills:${NC} $skills"
        echo -e "   ${BLUE}Tags:${NC} $tags"
        echo -e "   ${BLUE}Posted:${NC} $posted_at"
        echo -e "   ${GREEN}Claim with:${NC} ./memory-task-marketplace.sh claim $task_id"
        echo ""
    done

    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Claim a task
claim_task() {
    local task_id="$1"
    local claude_id="${2:-${MY_AGENT:-unknown}}"
    local timeout_minutes="${3:-30}"

    if [[ -z "$task_id" ]]; then
        echo -e "${RED}Usage: claim <task-id> [agent-id] [timeout-minutes]${NC}"
        return 1
    fi

    local task_file="$AVAILABLE_DIR/${task_id}.json"

    if [[ ! -f "$task_file" ]]; then
        echo -e "${RED}❌ Task not found: $task_id${NC}"
        echo -e "${YELLOW}Available tasks:${NC}"
        ls -1 "$AVAILABLE_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/.json//' | sed 's/^/  - /'
        return 1
    fi

    # Move to claimed
    local claimed_file="$CLAIMED_DIR/${task_id}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local timeout_at=$(date -u -v+${timeout_minutes}M +"%Y-%m-%dT%H:%M:%S.%3NZ" 2>/dev/null || date -u -d "+${timeout_minutes} minutes" +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Update task with claim info
    jq --arg claude "$claude_id" \
       --arg timestamp "$timestamp" \
       --arg timeout "$timeout_at" \
       '.status = "claimed" | .claimed_by = $claude | .claimed_at = $timestamp | .timeout_at = $timeout' \
       "$task_file" > "$claimed_file"

    rm "$task_file"

    # Log to memory
    ~/memory-system.sh log task-claimed "$task_id" "🎯 Claimed by $claude_id (timeout: ${timeout_minutes}m)"

    echo -e "${GREEN}✅ Task claimed: ${CYAN}$task_id${NC}"
    echo -e "   ${BLUE}Claimed by:${NC} $claude_id"
    echo -e "   ${BLUE}Timeout:${NC} ${timeout_minutes} minutes ($timeout_at)"
    echo -e "   ${YELLOW}💡 Complete with:${NC} ./memory-task-marketplace.sh complete $task_id"
}

# Complete a task
complete_task() {
    local task_id="$1"
    local result="${2:-Success}"

    if [[ -z "$task_id" ]]; then
        echo -e "${RED}Usage: complete <task-id> [result]${NC}"
        return 1
    fi

    local claimed_file="$CLAIMED_DIR/${task_id}.json"

    if [[ ! -f "$claimed_file" ]]; then
        echo -e "${RED}❌ Claimed task not found: $task_id${NC}"
        return 1
    fi

    # Move to completed
    local completed_file="$COMPLETED_DIR/${task_id}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    jq --arg timestamp "$timestamp" \
       --arg result "$result" \
       '.status = "completed" | .completed_at = $timestamp | .result = $result' \
       "$claimed_file" > "$completed_file"

    rm "$claimed_file"

    # Log to memory
    ~/memory-system.sh log task-completed "$task_id" "✅ Completed: $result"

    echo -e "${GREEN}🎉 Task completed: ${CYAN}$task_id${NC}"
    echo -e "   ${BLUE}Result:${NC} $result"
}

# Release a task (if can't complete)
release_task() {
    local task_id="$1"
    local reason="${2:-No reason given}"

    if [[ -z "$task_id" ]]; then
        echo -e "${RED}Usage: release <task-id> [reason]${NC}"
        return 1
    fi

    local claimed_file="$CLAIMED_DIR/${task_id}.json"

    if [[ ! -f "$claimed_file" ]]; then
        echo -e "${RED}❌ Claimed task not found: $task_id${NC}"
        return 1
    fi

    # Move back to available
    local available_file="$AVAILABLE_DIR/${task_id}.json"

    jq 'del(.claimed_by, .claimed_at, .timeout_at) | .status = "available"' \
       "$claimed_file" > "$available_file"

    rm "$claimed_file"

    # Log to memory
    ~/memory-system.sh log task-released "$task_id" "🔄 Released: $reason"

    echo -e "${YELLOW}🔄 Task released: ${CYAN}$task_id${NC}"
    echo -e "   ${BLUE}Reason:${NC} $reason"
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║        🎯 BlackRoad Task Marketplace - Help 🎯            ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${BLUE}init${NC}
    Initialize the task marketplace

${BLUE}post${NC} <task-id> <title> <description> [priority] [tags] [skills]
    Post a new task
    Priority: high|medium|low (default: medium)
    Example: post auth-impl "Implement OAuth2" "Add OAuth2 auth" high backend backend-auth

${BLUE}list${NC} [priority] [tags]
    List available tasks (optionally filtered)
    Example: list high backend

${BLUE}claim${NC} <task-id> [agent-id] [timeout-minutes]
    Claim a task to work on it (default timeout: 30 minutes)
    Example: claim auth-impl agent-auth-specialist 60

${BLUE}complete${NC} <task-id> [result]
    Mark a claimed task as completed
    Example: complete auth-impl "OAuth2 implemented, tested, deployed"

${BLUE}release${NC} <task-id> [reason]
    Release a claimed task back to available
    Example: release auth-impl "Blocked on API deployment"

${BLUE}my-tasks${NC}
    Show tasks claimed by you

${BLUE}stats${NC}
    Show marketplace statistics

${GREEN}EXAMPLES:${NC}

    # Initialize
    $0 init

    # Post a high-priority backend task
    $0 post api-deploy "Deploy FastAPI backend" "Deploy to api.blackroad.io with PostgreSQL" high backend backend-api

    # List all high-priority tasks
    $0 list high

    # Claim a task
    MY_AGENT=agent-api-specialist $0 claim api-deploy

    # Complete the task
    $0 complete api-deploy "Deployed successfully to api.blackroad.io"

${GREEN}WORKFLOW:${NC}

    1. Someone posts tasks to the marketplace
    2. BlackRoad Agents browse available tasks (list)
    3. Agent claims a task to work on it
    4. Agent completes the task (or releases if blocked)
    5. Task moves to completed! 🎉

EOF
}

# Show tasks claimed by current Agent
my_tasks() {
    local claude_id="${MY_AGENT:-unknown}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           📋 My Tasks ($claude_id)                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local my_task_count=0

    for task_file in "$CLAIMED_DIR"/*.json; do
        [[ ! -f "$task_file" ]] && continue

        local claimed_by=$(jq -r '.claimed_by' "$task_file")

        if [[ "$claimed_by" == "$claude_id" ]]; then
            local task_id=$(jq -r '.task_id' "$task_file")
            local title=$(jq -r '.title' "$task_file")
            local claimed_at=$(jq -r '.claimed_at' "$task_file")
            local timeout_at=$(jq -r '.timeout_at' "$task_file")

            echo -e "${CYAN}📌 $task_id${NC}"
            echo -e "   ${BLUE}Title:${NC} $title"
            echo -e "   ${BLUE}Claimed:${NC} $claimed_at"
            echo -e "   ${BLUE}Timeout:${NC} $timeout_at"
            echo -e "   ${GREEN}Complete:${NC} ./memory-task-marketplace.sh complete $task_id"
            echo ""

            ((my_task_count++))
        fi
    done

    if [[ $my_task_count -eq 0 ]]; then
        echo -e "${YELLOW}No tasks claimed by you. Browse available tasks with: ./memory-task-marketplace.sh list${NC}"
    fi
}

# Show statistics
show_stats() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           📊 Task Marketplace Statistics 📊              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local available_count=$(ls -1 "$AVAILABLE_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local claimed_count=$(ls -1 "$CLAIMED_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local completed_count=$(ls -1 "$COMPLETED_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local total=$((available_count + claimed_count + completed_count))

    echo -e "${GREEN}📋 Total Tasks:${NC} $total"
    echo -e "${YELLOW}⏳ Available:${NC} $available_count"
    echo -e "${BLUE}🎯 Claimed:${NC} $claimed_count"
    echo -e "${PURPLE}✅ Completed:${NC} $completed_count"
    echo ""

    if [[ $total -gt 0 ]]; then
        local completion_rate=$((completed_count * 100 / total))
        echo -e "${GREEN}📈 Completion Rate:${NC} ${completion_rate}%"
    fi

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Show who's working on what
    if [[ $claimed_count -gt 0 ]]; then
        echo -e "${BLUE}Active Workers:${NC}"
        for task_file in "$CLAIMED_DIR"/*.json; do
            [[ ! -f "$task_file" ]] && continue
            local task_id=$(jq -r '.task_id' "$task_file")
            local claimed_by=$(jq -r '.claimed_by' "$task_file")
            local title=$(jq -r '.title' "$task_file")
            echo -e "  ${CYAN}$claimed_by${NC} → $task_id: $title"
        done
    fi
}

# Main command router
case "$1" in
    init)
        init_marketplace
        ;;
    post)
        post_task "$2" "$3" "$4" "$5" "$6" "$7"
        ;;
    list)
        list_tasks "$2" "$3"
        ;;
    claim)
        claim_task "$2" "$3" "$4"
        ;;
    complete)
        complete_task "$2" "$3"
        ;;
    release)
        release_task "$2" "$3"
        ;;
    my-tasks)
        my_tasks
        ;;
    stats)
        show_stats
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
