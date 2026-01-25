#!/bin/bash

# BlackRoad Project Management System
# Full project lifecycle: planning, sprints, milestones, dependencies, resources

MEMORY_DIR="$HOME/.blackroad/memory"
PROJECTS_DIR="$MEMORY_DIR/projects"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize project system
init_system() {
    mkdir -p "$PROJECTS_DIR"/{active,archived,templates}
    
    cat > "$PROJECTS_DIR/config.json" << 'EOF'
{
    "system": "BlackRoad Project Management",
    "version": "1.0",
    "features": ["projects", "milestones", "sprints", "dependencies", "resources"]
}
EOF
    
    echo -e "${GREEN}✅ Project Management System initialized${NC}"
}

# Create new project
create_project() {
    local project_id="$1"
    local project_name="$2"
    local description="$3"
    local owner="${4:-${MY_AGENT:-unknown}}"
    
    if [[ -z "$project_id" || -z "$project_name" ]]; then
        echo -e "${RED}Usage: create <project-id> <project-name> <description> [owner]${NC}"
        return 1
    fi
    
    local project_dir="$PROJECTS_DIR/active/$project_id"
    mkdir -p "$project_dir"/{milestones,sprints,tasks,resources}
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    cat > "$project_dir/project.json" << EOF
{
    "project_id": "$project_id",
    "project_name": "$project_name",
    "description": "$description",
    "owner": "$owner",
    "status": "planning",
    "created_at": "$timestamp",
    "updated_at": "$timestamp",
    "team": ["$owner"],
    "milestones": [],
    "sprints": [],
    "budget": {
        "estimated_hours": 0,
        "spent_hours": 0
    },
    "health": "green"
}
EOF
    
    # Log to memory
    ~/memory-system.sh log project-created "$project_id" "🚀 Project created: $project_name (owner: $owner)" 2>/dev/null
    
    echo -e "${GREEN}✅ Project created:${NC} ${BOLD}${CYAN}$project_id${NC}"
    echo -e "   ${BLUE}Name:${NC} $project_name"
    echo -e "   ${BLUE}Owner:${NC} $owner"
    echo -e "   ${BLUE}Status:${NC} planning"
}

# Add milestone
add_milestone() {
    local project_id="$1"
    local milestone_id="$2"
    local milestone_name="$3"
    local target_date="$4"
    
    if [[ -z "$project_id" || -z "$milestone_id" || -z "$milestone_name" ]]; then
        echo -e "${RED}Usage: milestone <project-id> <milestone-id> <name> <target-date>${NC}"
        return 1
    fi
    
    local project_dir="$PROJECTS_DIR/active/$project_id"
    
    if [[ ! -d "$project_dir" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    cat > "$project_dir/milestones/${milestone_id}.json" << EOF
{
    "milestone_id": "$milestone_id",
    "milestone_name": "$milestone_name",
    "target_date": "$target_date",
    "status": "pending",
    "created_at": "$timestamp",
    "tasks": [],
    "completion_percent": 0
}
EOF
    
    # Add to project
    jq --arg mid "$milestone_id" '.milestones += [$mid]' "$project_dir/project.json" > "$project_dir/project.json.tmp"
    mv "$project_dir/project.json.tmp" "$project_dir/project.json"
    
    echo -e "${GREEN}✅ Milestone added:${NC} ${CYAN}$milestone_id${NC}"
    echo -e "   ${BLUE}Target:${NC} $target_date"
}

# Create sprint
create_sprint() {
    local project_id="$1"
    local sprint_id="$2"
    local sprint_name="$3"
    local start_date="$4"
    local end_date="$5"
    
    if [[ -z "$project_id" || -z "$sprint_id" || -z "$sprint_name" ]]; then
        echo -e "${RED}Usage: sprint <project-id> <sprint-id> <name> <start-date> <end-date>${NC}"
        return 1
    fi
    
    local project_dir="$PROJECTS_DIR/active/$project_id"
    
    if [[ ! -d "$project_dir" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    cat > "$project_dir/sprints/${sprint_id}.json" << EOF
{
    "sprint_id": "$sprint_id",
    "sprint_name": "$sprint_name",
    "start_date": "$start_date",
    "end_date": "$end_date",
    "status": "planned",
    "created_at": "$timestamp",
    "tasks": [],
    "velocity": 0,
    "committed_points": 0,
    "completed_points": 0
}
EOF
    
    # Add to project
    jq --arg sid "$sprint_id" '.sprints += [$sid]' "$project_dir/project.json" > "$project_dir/project.json.tmp"
    mv "$project_dir/project.json.tmp" "$project_dir/project.json"
    
    echo -e "${GREEN}✅ Sprint created:${NC} ${CYAN}$sprint_id${NC}"
    echo -e "   ${BLUE}Duration:${NC} $start_date to $end_date"
}

# Update project status
update_status() {
    local project_id="$1"
    local new_status="$2"
    
    if [[ -z "$project_id" || -z "$new_status" ]]; then
        echo -e "${RED}Usage: status <project-id> <planning|active|on-hold|completed|archived>${NC}"
        return 1
    fi
    
    local project_file="$PROJECTS_DIR/active/$project_id/project.json"
    
    if [[ ! -f "$project_file" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    jq --arg status "$new_status" \
       --arg timestamp "$timestamp" \
       '.status = $status | .updated_at = $timestamp' \
       "$project_file" > "${project_file}.tmp"
    mv "${project_file}.tmp" "$project_file"
    
    echo -e "${GREEN}✅ Project status updated:${NC} ${CYAN}$new_status${NC}"
}

# List all projects
list_projects() {
    local filter_status="$1"
    
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${PURPLE}║        📋 BLACKROAD PROJECTS 📋                           ║${NC}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local total=0
    
    for project_dir in "$PROJECTS_DIR/active"/*; do
        [[ ! -d "$project_dir" ]] && continue
        
        local project_file="$project_dir/project.json"
        [[ ! -f "$project_file" ]] && continue
        
        local project_id=$(jq -r '.project_id' "$project_file")
        local project_name=$(jq -r '.project_name' "$project_file")
        local status=$(jq -r '.status' "$project_file")
        local owner=$(jq -r '.owner' "$project_file")
        local health=$(jq -r '.health // "green"' "$project_file")
        
        # Filter by status if specified
        if [[ -n "$filter_status" && "$status" != "$filter_status" ]]; then
            continue
        fi
        
        # Status indicator
        local status_icon="📝"
        case "$status" in
            planning) status_icon="📝" ;;
            active) status_icon="🚀" ;;
            on-hold) status_icon="⏸️" ;;
            completed) status_icon="✅" ;;
        esac
        
        # Health indicator
        local health_icon="🟢"
        case "$health" in
            yellow) health_icon="🟡" ;;
            red) health_icon="🔴" ;;
        esac
        
        echo -e "${status_icon} ${health_icon} ${BOLD}${CYAN}$project_id${NC} - $project_name"
        echo -e "   ${BLUE}Status:${NC} $status | ${BLUE}Owner:${NC} $owner"
        echo ""
        
        ((total++))
    done
    
    if [[ $total -eq 0 ]]; then
        echo -e "${YELLOW}No projects found${NC}"
    else
        echo -e "${GREEN}Total: $total projects${NC}"
    fi
}

# Show project dashboard
show_project() {
    local project_id="$1"
    
    if [[ -z "$project_id" ]]; then
        echo -e "${RED}Usage: show <project-id>${NC}"
        return 1
    fi
    
    local project_file="$PROJECTS_DIR/active/$project_id/project.json"
    
    if [[ ! -f "$project_file" ]]; then
        echo -e "${RED}Project not found: $project_id${NC}"
        return 1
    fi
    
    local project_name=$(jq -r '.project_name' "$project_file")
    local description=$(jq -r '.description' "$project_file")
    local status=$(jq -r '.status' "$project_file")
    local owner=$(jq -r '.owner' "$project_file")
    local health=$(jq -r '.health // "green"' "$project_file")
    local created_at=$(jq -r '.created_at' "$project_file")
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║        PROJECT DASHBOARD: $(echo "$project_id" | tr a-z A-Z)${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}${project_name}${NC}"
    echo -e "$description"
    echo ""
    
    # Status
    local health_icon="🟢"
    case "$health" in
        yellow) health_icon="🟡" ;;
        red) health_icon="🔴" ;;
    esac
    
    echo -e "${BOLD}Status:${NC} ${PURPLE}$status${NC} | ${BOLD}Health:${NC} $health_icon $health"
    echo -e "${BOLD}Owner:${NC} $owner"
    echo -e "${BOLD}Created:${NC} $created_at"
    echo ""
    
    # Milestones
    local milestone_count=$(ls -1 "$PROJECTS_DIR/active/$project_id/milestones"/*.json 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${BOLD}Milestones:${NC} $milestone_count"
    
    if [[ $milestone_count -gt 0 ]]; then
        for milestone_file in "$PROJECTS_DIR/active/$project_id/milestones"/*.json; do
            local m_id=$(jq -r '.milestone_id' "$milestone_file")
            local m_name=$(jq -r '.milestone_name' "$milestone_file")
            local m_status=$(jq -r '.status' "$milestone_file")
            local m_target=$(jq -r '.target_date' "$milestone_file")
            
            local m_icon="📍"
            [[ "$m_status" == "completed" ]] && m_icon="✅"
            
            echo -e "  $m_icon ${CYAN}$m_id${NC}: $m_name (${BLUE}target: $m_target${NC})"
        done
    fi
    echo ""
    
    # Sprints
    local sprint_count=$(ls -1 "$PROJECTS_DIR/active/$project_id/sprints"/*.json 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${BOLD}Sprints:${NC} $sprint_count"
    
    if [[ $sprint_count -gt 0 ]]; then
        for sprint_file in "$PROJECTS_DIR/active/$project_id/sprints"/*.json; do
            local s_id=$(jq -r '.sprint_id' "$sprint_file")
            local s_name=$(jq -r '.sprint_name' "$sprint_file")
            local s_status=$(jq -r '.status' "$sprint_file")
            
            local s_icon="📅"
            case "$s_status" in
                active) s_icon="🏃" ;;
                completed) s_icon="✅" ;;
            esac
            
            echo -e "  $s_icon ${CYAN}$s_id${NC}: $s_name (${PURPLE}$s_status${NC})"
        done
    fi
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║      📋 BlackRoad Project Management - Help 📋           ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${CYAN}init${NC}
    Initialize project management system

${CYAN}create${NC} <project-id> <name> <description> [owner]
    Create a new project
    Example: $0 create proj-001 "API Rewrite" "Rebuild API with new framework"

${CYAN}milestone${NC} <project-id> <milestone-id> <name> <target-date>
    Add milestone to project
    Example: $0 milestone proj-001 m1 "MVP Ready" "2025-02-01"

${CYAN}sprint${NC} <project-id> <sprint-id> <name> <start-date> <end-date>
    Create sprint for project
    Example: $0 sprint proj-001 s1 "Sprint 1" "2025-01-01" "2025-01-14"

${CYAN}status${NC} <project-id> <planning|active|on-hold|completed|archived>
    Update project status
    Example: $0 status proj-001 active

${CYAN}list${NC} [status]
    List all projects (optionally filter by status)
    Example: $0 list active

${CYAN}show${NC} <project-id>
    Show project dashboard with full details
    Example: $0 show proj-001

${GREEN}PROJECT STATUSES:${NC}

    📝 ${CYAN}planning${NC}  - Initial planning phase
    🚀 ${BLUE}active${NC}    - Actively being worked on
    ⏸️  ${YELLOW}on-hold${NC}  - Temporarily paused
    ✅ ${GREEN}completed${NC} - Successfully completed
    📦 ${PURPLE}archived${NC}  - Archived for reference

${GREEN}HEALTH INDICATORS:${NC}

    🟢 ${GREEN}green${NC}  - On track
    🟡 ${YELLOW}yellow${NC} - At risk
    🔴 ${RED}red${NC}    - Critical issues

${GREEN}EXAMPLES:${NC}

    # Create project
    $0 init
    $0 create api-v2 "API Version 2" "Complete API rewrite" cecilia-arch-001

    # Add milestones
    $0 milestone api-v2 alpha "Alpha Release" "2025-02-15"
    $0 milestone api-v2 beta "Beta Release" "2025-03-01"
    $0 milestone api-v2 prod "Production" "2025-04-01"

    # Create sprints
    $0 sprint api-v2 sprint-1 "Foundation" "2025-01-15" "2025-01-29"
    $0 sprint api-v2 sprint-2 "Core Features" "2025-01-30" "2025-02-13"

    # Update status
    $0 status api-v2 active

    # View dashboard
    $0 show api-v2

EOF
}

# Main command router
case "$1" in
    init)
        init_system
        ;;
    create)
        create_project "$2" "$3" "$4" "$5"
        ;;
    milestone)
        add_milestone "$2" "$3" "$4" "$5"
        ;;
    sprint)
        create_sprint "$2" "$3" "$4" "$5" "$6"
        ;;
    status)
        update_status "$2" "$3"
        ;;
    list)
        list_projects "$2"
        ;;
    show)
        show_project "$2"
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
