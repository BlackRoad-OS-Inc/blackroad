#!/bin/bash

# BlackRoad Infinite To-Do System
# For long-running projects that span hours, days, weeks, months, or forever
# Enables seamless Claude collaboration across time

MEMORY_DIR="$HOME/.blackroad/memory"
TODOS_DIR="$MEMORY_DIR/infinite-todos"
PROJECTS_DIR="$TODOS_DIR/projects"
DAILY_DIR="$TODOS_DIR/daily"
WEEKLY_DIR="$TODOS_DIR/weekly"
MONTHLY_DIR="$TODOS_DIR/monthly"
FOREVER_DIR="$TODOS_DIR/forever"
ACTIVE_DIR="$TODOS_DIR/active"
ARCHIVE_DIR="$TODOS_DIR/archive"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize system
init_infinite_todos() {
    mkdir -p "$TODOS_DIR" "$PROJECTS_DIR" "$DAILY_DIR" "$WEEKLY_DIR" "$MONTHLY_DIR" "$FOREVER_DIR" "$ACTIVE_DIR" "$ARCHIVE_DIR"

    # Create index file
    if [[ ! -f "$TODOS_DIR/index.json" ]]; then
        cat > "$TODOS_DIR/index.json" << 'EOF'
{
    "version": "1.0",
    "created": "",
    "total_projects": 0,
    "active_projects": 0,
    "completed_projects": 0,
    "total_todos": 0
}
EOF
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        jq --arg ts "$timestamp" '.created = $ts' "$TODOS_DIR/index.json" > "$TODOS_DIR/index.tmp" && mv "$TODOS_DIR/index.tmp" "$TODOS_DIR/index.json"
    fi

    echo -e "${GREEN}✅ Infinite To-Do System initialized!${NC}"
    echo -e "${BLUE}Directories:${NC}"
    echo -e "  Daily:   $DAILY_DIR"
    echo -e "  Weekly:  $WEEKLY_DIR"
    echo -e "  Monthly: $MONTHLY_DIR"
    echo -e "  Forever: $FOREVER_DIR"
    echo -e "  Active:  $ACTIVE_DIR"
}

# Create a new long-running project
create_project() {
    local project_id="$1"
    local title="$2"
    local description="$3"
    local timescale="${4:-forever}"  # daily, weekly, monthly, forever
    local owner="${MY_CLAUDE:-unknown}"

    if [[ -z "$project_id" || -z "$title" ]]; then
        echo -e "${RED}Usage: create <project-id> <title> <description> [timescale]${NC}"
        echo -e "${YELLOW}Timescales: daily, weekly, monthly, forever${NC}"
        return 1
    fi

    # Validate timescale
    if [[ ! "$timescale" =~ ^(daily|weekly|monthly|forever)$ ]]; then
        echo -e "${RED}Invalid timescale. Use: daily, weekly, monthly, or forever${NC}"
        return 1
    fi

    local project_file="$PROJECTS_DIR/${project_id}.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    if [[ -f "$project_file" ]]; then
        echo -e "${RED}Project already exists: $project_id${NC}"
        return 1
    fi

    cat > "$project_file" << EOF
{
    "project_id": "$project_id",
    "title": "$title",
    "description": "$description",
    "timescale": "$timescale",
    "status": "active",
    "owner": "$owner",
    "created_at": "$timestamp",
    "updated_at": "$timestamp",
    "started_at": "$timestamp",
    "completed_at": null,
    "progress": 0,
    "todos": [],
    "milestones": [],
    "dependencies": [],
    "collaborators": ["$owner"],
    "handoffs": [],
    "notes": []
}
EOF

    # Link to timescale directory
    local timescale_dir
    case "$timescale" in
        daily) timescale_dir="$DAILY_DIR" ;;
        weekly) timescale_dir="$WEEKLY_DIR" ;;
        monthly) timescale_dir="$MONTHLY_DIR" ;;
        forever) timescale_dir="$FOREVER_DIR" ;;
    esac
    ln -sf "$project_file" "$timescale_dir/${project_id}.json"

    # Link to active directory
    ln -sf "$project_file" "$ACTIVE_DIR/${project_id}.json"

    # Update index
    local total=$(jq '.total_projects + 1' "$TODOS_DIR/index.json")
    local active=$(jq '.active_projects + 1' "$TODOS_DIR/index.json")
    jq --arg total "$total" --arg active "$active" \
       '.total_projects = ($total | tonumber) | .active_projects = ($active | tonumber)' \
       "$TODOS_DIR/index.json" > "$TODOS_DIR/index.tmp" && mv "$TODOS_DIR/index.tmp" "$TODOS_DIR/index.json"

    # Log to memory
    ~/memory-system.sh log project-created "$project_id" "🎯 New $timescale project: $title (by $owner)"

    echo -e "${GREEN}✅ Project created: ${CYAN}$project_id${NC}"
    echo -e "   ${BLUE}Title:${NC} $title"
    echo -e "   ${BLUE}Timescale:${NC} $timescale"
    echo -e "   ${BLUE}Owner:${NC} $owner"
    echo -e ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  Add todos: $0 add-todo $project_id <todo-text>"
    echo -e "  Add milestone: $0 milestone $project_id <milestone-name>"
    echo -e "  View project: $0 show $project_id"
}

# Add a todo to a project
add_todo() {
    local project_id="$1"
    local todo_text="$2"
    local priority="${3:-medium}"  # low, medium, high, urgent

    if [[ -z "$project_id" || -z "$todo_text" ]]; then
        echo -e "${RED}Usage: add-todo <project-id> <todo-text> [priority]${NC}"
        return 1
    fi

    local project_file="$PROJECTS_DIR/${project_id}.json"
    if [[ ! -f "$project_file" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local todo_id=$(echo "$todo_text" | shasum -a 256 | cut -c1-12)

    local new_todo=$(cat << EOF
{
    "id": "$todo_id",
    "text": "$todo_text",
    "priority": "$priority",
    "status": "pending",
    "created_at": "$timestamp",
    "completed_at": null,
    "assigned_to": "${MY_CLAUDE:-unknown}"
}
EOF
)

    # Add todo to project
    jq --argjson todo "$new_todo" \
       --arg ts "$timestamp" \
       '.todos += [$todo] | .updated_at = $ts | .total_todos = (.todos | length)' \
       "$project_file" > "$project_file.tmp" && mv "$project_file.tmp" "$project_file"

    # Update global index
    local total_todos=$(jq '.total_todos + 1' "$TODOS_DIR/index.json")
    jq --arg total "$total_todos" '.total_todos = ($total | tonumber)' \
       "$TODOS_DIR/index.json" > "$TODOS_DIR/index.tmp" && mv "$TODOS_DIR/index.tmp" "$TODOS_DIR/index.json"

    echo -e "${GREEN}✅ To-do added to ${CYAN}$project_id${NC}"
    echo -e "   ${BLUE}Text:${NC} $todo_text"
    echo -e "   ${BLUE}Priority:${NC} $priority"
    echo -e "   ${BLUE}ID:${NC} $todo_id"
}

# Complete a todo
complete_todo() {
    local project_id="$1"
    local todo_id="$2"

    if [[ -z "$project_id" || -z "$todo_id" ]]; then
        echo -e "${RED}Usage: complete-todo <project-id> <todo-id>${NC}"
        return 1
    fi

    local project_file="$PROJECTS_DIR/${project_id}.json"
    if [[ ! -f "$project_file" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Update todo status
    jq --arg id "$todo_id" \
       --arg ts "$timestamp" \
       '(.todos[] | select(.id == $id)) |= (.status = "completed" | .completed_at = $ts) | .updated_at = $ts' \
       "$project_file" > "$project_file.tmp" && mv "$project_file.tmp" "$project_file"

    # Calculate progress
    local completed=$(jq '[.todos[] | select(.status == "completed")] | length' "$project_file")
    local total=$(jq '.todos | length' "$project_file")
    local progress=$(( completed * 100 / total ))

    jq --arg progress "$progress" '.progress = ($progress | tonumber)' \
       "$project_file" > "$project_file.tmp" && mv "$project_file.tmp" "$project_file"

    # Log to memory
    local todo_text=$(jq -r --arg id "$todo_id" '.todos[] | select(.id == $id) | .text' "$project_file")
    ~/memory-system.sh log progress "${MY_CLAUDE:-unknown}" "✅ Completed in $project_id: $todo_text ($progress% done)"

    echo -e "${GREEN}✅ To-do completed!${NC}"
    echo -e "   ${BLUE}Project:${NC} $project_id"
    echo -e "   ${BLUE}Progress:${NC} $progress% ($completed/$total)"
}

# Add a milestone
add_milestone() {
    local project_id="$1"
    local milestone_name="$2"
    local target_date="$3"

    if [[ -z "$project_id" || -z "$milestone_name" ]]; then
        echo -e "${RED}Usage: milestone <project-id> <milestone-name> [target-date]${NC}"
        return 1
    fi

    local project_file="$PROJECTS_DIR/${project_id}.json"
    if [[ ! -f "$project_file" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local milestone_id=$(echo "$milestone_name" | shasum -a 256 | cut -c1-12)

    local new_milestone=$(cat << EOF
{
    "id": "$milestone_id",
    "name": "$milestone_name",
    "target_date": "${target_date:-null}",
    "status": "pending",
    "created_at": "$timestamp",
    "completed_at": null
}
EOF
)

    jq --argjson milestone "$new_milestone" \
       --arg ts "$timestamp" \
       '.milestones += [$milestone] | .updated_at = $ts' \
       "$project_file" > "$project_file.tmp" && mv "$project_file.tmp" "$project_file"

    echo -e "${GREEN}✅ Milestone added to ${CYAN}$project_id${NC}"
    echo -e "   ${BLUE}Name:${NC} $milestone_name"
    [[ -n "$target_date" ]] && echo -e "   ${BLUE}Target:${NC} $target_date"
}

# Handoff project to another Claude
handoff_project() {
    local project_id="$1"
    local new_owner="$2"
    local handoff_note="${3:-No notes provided}"

    if [[ -z "$project_id" || -z "$new_owner" ]]; then
        echo -e "${RED}Usage: handoff <project-id> <new-owner-claude> [note]${NC}"
        return 1
    fi

    local project_file="$PROJECTS_DIR/${project_id}.json"
    if [[ ! -f "$project_file" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local old_owner=$(jq -r '.owner' "$project_file")

    local handoff=$(cat << EOF
{
    "from": "$old_owner",
    "to": "$new_owner",
    "timestamp": "$timestamp",
    "note": "$handoff_note"
}
EOF
)

    jq --arg new_owner "$new_owner" \
       --argjson handoff "$handoff" \
       --arg ts "$timestamp" \
       '.owner = $new_owner | .handoffs += [$handoff] | .updated_at = $ts | .collaborators += [$new_owner] | .collaborators |= unique' \
       "$project_file" > "$project_file.tmp" && mv "$project_file.tmp" "$project_file"

    # Log to memory
    local title=$(jq -r '.title' "$project_file")
    ~/memory-system.sh log handoff "$project_id" "🤝 Project '$title' handed off: $old_owner → $new_owner. Note: $handoff_note"

    echo -e "${GREEN}✅ Project handed off!${NC}"
    echo -e "   ${BLUE}From:${NC} $old_owner"
    echo -e "   ${BLUE}To:${NC} $new_owner"
    echo -e "   ${BLUE}Note:${NC} $handoff_note"
}

# Show project details
show_project() {
    local project_id="$1"

    if [[ -z "$project_id" ]]; then
        echo -e "${RED}Usage: show <project-id>${NC}"
        return 1
    fi

    local project_file="$PROJECTS_DIR/${project_id}.json"
    if [[ ! -f "$project_file" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi

    local title=$(jq -r '.title' "$project_file")
    local description=$(jq -r '.description' "$project_file")
    local timescale=$(jq -r '.timescale' "$project_file")
    local status=$(jq -r '.status' "$project_file")
    local owner=$(jq -r '.owner' "$project_file")
    local progress=$(jq -r '.progress' "$project_file")
    local created=$(jq -r '.created_at' "$project_file")
    local updated=$(jq -r '.updated_at' "$project_file")

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🎯 PROJECT: ${project_id}${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${BOLD}${title}${NC}"
    echo -e "${description}"
    echo -e ""
    echo -e "${BLUE}Timescale:${NC} $timescale"
    echo -e "${BLUE}Status:${NC} $status"
    echo -e "${BLUE}Owner:${NC} $owner"
    echo -e "${BLUE}Progress:${NC} $progress%"
    echo -e "${BLUE}Created:${NC} $created"
    echo -e "${BLUE}Updated:${NC} $updated"
    echo -e ""

    # Show todos
    local todos_count=$(jq '.todos | length' "$project_file")
    if [[ $todos_count -gt 0 ]]; then
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}To-Dos ($todos_count):${NC}"
        echo -e ""

        jq -r '.todos[] | "\(.status)|\(.priority)|\(.id)|\(.text)|\(.assigned_to)"' "$project_file" | while IFS='|' read -r status priority id text assigned; do
            local status_icon="⏳"
            local status_color="$YELLOW"

            if [[ "$status" == "completed" ]]; then
                status_icon="✅"
                status_color="$GREEN"
            elif [[ "$status" == "in_progress" ]]; then
                status_icon="🔄"
                status_color="$CYAN"
            fi

            local priority_badge=""
            case "$priority" in
                urgent) priority_badge="${RED}[URGENT]${NC}" ;;
                high) priority_badge="${YELLOW}[HIGH]${NC}" ;;
                medium) priority_badge="${BLUE}[MED]${NC}" ;;
                low) priority_badge="${NC}[LOW]${NC}" ;;
            esac

            echo -e "  ${status_color}${status_icon}${NC} ${priority_badge} ${text}"
            echo -e "     ${NC}ID: ${id} | Assigned: ${assigned}${NC}"
        done
        echo -e ""
    fi

    # Show milestones
    local milestones_count=$(jq '.milestones | length' "$project_file")
    if [[ $milestones_count -gt 0 ]]; then
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}Milestones ($milestones_count):${NC}"
        echo -e ""

        jq -r '.milestones[] | "\(.status)|\(.name)|\(.target_date)"' "$project_file" | while IFS='|' read -r status name target; do
            local status_icon="🎯"
            [[ "$status" == "completed" ]] && status_icon="🏆"

            echo -e "  ${status_icon} ${name}"
            [[ "$target" != "null" ]] && echo -e "     Target: ${target}"
        done
        echo -e ""
    fi

    # Show handoffs
    local handoffs_count=$(jq '.handoffs | length' "$project_file")
    if [[ $handoffs_count -gt 0 ]]; then
        echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}Handoff History ($handoffs_count):${NC}"
        echo -e ""

        jq -r '.handoffs[] | "\(.from)|\(.to)|\(.timestamp)|\(.note)"' "$project_file" | while IFS='|' read -r from to timestamp note; do
            echo -e "  🤝 ${from} → ${to}"
            echo -e "     ${timestamp}"
            echo -e "     Note: ${note}"
        done
        echo -e ""
    fi
}

# List all projects
list_projects() {
    local filter_timescale="$1"
    local filter_status="${2:-active}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         🎯 INFINITE TO-DO SYSTEM - PROJECTS 🎯           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""

    local total=$(jq -r '.total_projects' "$TODOS_DIR/index.json")
    local active=$(jq -r '.active_projects' "$TODOS_DIR/index.json")
    local completed=$(jq -r '.completed_projects' "$TODOS_DIR/index.json")
    local total_todos=$(jq -r '.total_todos' "$TODOS_DIR/index.json")

    echo -e "${GREEN}Total Projects:${NC} $total  ${BLUE}Active:${NC} $active  ${PURPLE}Completed:${NC} $completed"
    echo -e "${YELLOW}Total To-Dos:${NC} $total_todos"
    echo -e ""

    if [[ $total -eq 0 ]]; then
        echo -e "${YELLOW}No projects yet. Create one with:${NC}"
        echo -e "  $0 create <project-id> <title> <description> [timescale]"
        return
    fi

    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    for project_file in "$PROJECTS_DIR"/*.json; do
        [[ ! -f "$project_file" ]] && continue

        local project_id=$(jq -r '.project_id' "$project_file")
        local title=$(jq -r '.title' "$project_file")
        local timescale=$(jq -r '.timescale' "$project_file")
        local status=$(jq -r '.status' "$project_file")
        local progress=$(jq -r '.progress' "$project_file")
        local owner=$(jq -r '.owner' "$project_file")
        local todos_count=$(jq '.todos | length' "$project_file")
        local completed_count=$(jq '[.todos[] | select(.status == "completed")] | length' "$project_file")

        # Apply filters
        if [[ -n "$filter_timescale" && "$timescale" != "$filter_timescale" ]]; then
            continue
        fi
        if [[ -n "$filter_status" && "$status" != "$filter_status" ]]; then
            continue
        fi

        local timescale_badge=""
        case "$timescale" in
            daily) timescale_badge="${CYAN}[📅 DAILY]${NC}" ;;
            weekly) timescale_badge="${BLUE}[📆 WEEKLY]${NC}" ;;
            monthly) timescale_badge="${PURPLE}[📊 MONTHLY]${NC}" ;;
            forever) timescale_badge="${YELLOW}[♾️  FOREVER]${NC}" ;;
        esac

        echo -e "${BOLD}${CYAN}$project_id${NC} $timescale_badge"
        echo -e "  ${title}"
        echo -e "  ${BLUE}Progress:${NC} $progress% ($completed_count/$todos_count todos) | ${BLUE}Owner:${NC} $owner"
        echo -e ""
    done
}

# Dashboard view
dashboard() {
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       🎯 INFINITE TO-DO SYSTEM - DASHBOARD 🎯            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""

    # Summary stats
    local total=$(jq -r '.total_projects' "$TODOS_DIR/index.json")
    local active=$(jq -r '.active_projects' "$TODOS_DIR/index.json")
    local completed=$(jq -r '.completed_projects' "$TODOS_DIR/index.json")
    local total_todos=$(jq -r '.total_todos' "$TODOS_DIR/index.json")

    echo -e "${BOLD}System Stats:${NC}"
    echo -e "  ${GREEN}Total Projects:${NC} $total"
    echo -e "  ${BLUE}Active Projects:${NC} $active"
    echo -e "  ${PURPLE}Completed Projects:${NC} $completed"
    echo -e "  ${YELLOW}Total To-Dos:${NC} $total_todos"
    echo -e ""

    # By timescale
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Projects by Timescale:${NC}"
    echo -e ""

    for timescale in daily weekly monthly forever; do
        local timescale_dir
        case "$timescale" in
            daily) timescale_dir="$DAILY_DIR" ;;
            weekly) timescale_dir="$WEEKLY_DIR" ;;
            monthly) timescale_dir="$MONTHLY_DIR" ;;
            forever) timescale_dir="$FOREVER_DIR" ;;
        esac
        local count=$(ls -1 "$timescale_dir"/*.json 2>/dev/null | wc -l | tr -d ' ')

        local icon=""
        case "$timescale" in
            daily) icon="📅" ;;
            weekly) icon="📆" ;;
            monthly) icon="📊" ;;
            forever) icon="♾️" ;;
        esac

        local timescale_cap="$(echo ${timescale:0:1} | tr '[:lower:]' '[:upper:]')${timescale:1}"
        echo -e "  ${icon} ${timescale_cap}: ${count} projects"
    done
    echo -e ""

    # My projects
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}My Active Projects (${MY_CLAUDE:-unknown}):${NC}"
    echo -e ""

    local my_count=0
    for project_file in "$ACTIVE_DIR"/*.json; do
        [[ ! -f "$project_file" ]] && continue

        local owner=$(jq -r '.owner' "$project_file")
        if [[ "$owner" == "${MY_CLAUDE:-unknown}" ]]; then
            local project_id=$(jq -r '.project_id' "$project_file")
            local title=$(jq -r '.title' "$project_file")
            local progress=$(jq -r '.progress' "$project_file")

            echo -e "  ${CYAN}$project_id${NC} - $title (${progress}%)"
            ((my_count++))
        fi
    done

    if [[ $my_count -eq 0 ]]; then
        echo -e "  ${YELLOW}No active projects. Create one!${NC}"
    fi
}

# Main command router
case "$1" in
    init)
        init_infinite_todos
        ;;
    create)
        create_project "$2" "$3" "$4" "$5"
        ;;
    add-todo)
        add_todo "$2" "$3" "$4"
        ;;
    complete-todo)
        complete_todo "$2" "$3"
        ;;
    milestone)
        add_milestone "$2" "$3" "$4"
        ;;
    handoff)
        handoff_project "$2" "$3" "$4"
        ;;
    show)
        show_project "$2"
        ;;
    list)
        list_projects "$2" "$3"
        ;;
    dashboard)
        dashboard
        ;;
    *)
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║         🎯 BLACKROAD INFINITE TO-DO SYSTEM 🎯            ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo -e ""
        echo -e "${BOLD}Usage:${NC} $0 <command> [arguments]"
        echo -e ""
        echo -e "${BOLD}Commands:${NC}"
        echo -e "  ${GREEN}init${NC}                              - Initialize system"
        echo -e "  ${GREEN}create${NC} <id> <title> <desc> [time]  - Create new project"
        echo -e "  ${GREEN}add-todo${NC} <id> <text> [priority]    - Add to-do to project"
        echo -e "  ${GREEN}complete-todo${NC} <id> <todo-id>       - Complete a to-do"
        echo -e "  ${GREEN}milestone${NC} <id> <name> [date]       - Add milestone"
        echo -e "  ${GREEN}handoff${NC} <id> <new-owner> [note]    - Hand off project"
        echo -e "  ${GREEN}show${NC} <id>                         - Show project details"
        echo -e "  ${GREEN}list${NC} [timescale] [status]         - List all projects"
        echo -e "  ${GREEN}dashboard${NC}                         - Show dashboard"
        echo -e ""
        echo -e "${BOLD}Timescales:${NC} daily, weekly, monthly, forever"
        echo -e "${BOLD}Priorities:${NC} low, medium, high, urgent"
        echo -e ""
        echo -e "${BOLD}Examples:${NC}"
        echo -e "  $0 create deploy-agents 'Deploy 30k agents' 'Scale infrastructure' forever"
        echo -e "  $0 add-todo deploy-agents 'Set up Kubernetes cluster' urgent"
        echo -e "  $0 milestone deploy-agents 'First 1000 agents deployed' 2025-12-31"
        echo -e "  $0 handoff deploy-agents claude-kubernetes-expert 'Handing off K8s setup'"
        ;;
esac
