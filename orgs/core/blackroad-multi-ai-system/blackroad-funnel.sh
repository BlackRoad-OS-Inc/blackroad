#!/bin/bash

# BlackRoad Funnel System
# Track items through workflow stages: Intake → Qualify → Develop → Test → Deploy → Complete
# Perfect for sales funnels, development pipelines, customer journeys

MEMORY_DIR="$HOME/.blackroad/memory"
FUNNEL_DIR="$MEMORY_DIR/funnels"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default stages
DEFAULT_STAGES="intake qualify develop test deploy complete"

# Initialize funnel system
init_funnel() {
    local funnel_name="${1:-default}"
    local stages="${2:-$DEFAULT_STAGES}"
    
    mkdir -p "$FUNNEL_DIR/$funnel_name"
    
    # Create stage directories
    for stage in $stages; do
        mkdir -p "$FUNNEL_DIR/$funnel_name/$stage"
    done
    
    # Create funnel config
    cat > "$FUNNEL_DIR/$funnel_name/config.json" << EOF
{
    "funnel_name": "$funnel_name",
    "stages": "$(echo $stages | sed 's/ /,/g')",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")",
    "metrics": {
        "total_items": 0,
        "completed": 0,
        "dropped": 0
    }
}
EOF
    
    echo -e "${GREEN}✅ Funnel '${BOLD}$funnel_name${NC}${GREEN}' initialized${NC}"
    echo -e "   ${BLUE}Stages:${NC} $(echo $stages | sed 's/ / → /g')"
}

# Add item to funnel
add_item() {
    local funnel_name="$1"
    local item_id="$2"
    local item_name="$3"
    local metadata="${4:-{}}"
    
    if [[ -z "$funnel_name" || -z "$item_id" || -z "$item_name" ]]; then
        echo -e "${RED}Usage: add <funnel-name> <item-id> <item-name> [metadata-json]${NC}"
        return 1
    fi
    
    # Get first stage
    local first_stage=$(jq -r '.stages' "$FUNNEL_DIR/$funnel_name/config.json" | cut -d',' -f1)
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local item_file="$FUNNEL_DIR/$funnel_name/$first_stage/${item_id}.json"
    
    cat > "$item_file" << EOF
{
    "item_id": "$item_id",
    "item_name": "$item_name",
    "current_stage": "$first_stage",
    "added_at": "$timestamp",
    "updated_at": "$timestamp",
    "added_by": "${MY_AGENT:-unknown}",
    "metadata": $metadata,
    "history": [
        {
            "stage": "$first_stage",
            "timestamp": "$timestamp",
            "action": "added",
            "by": "${MY_AGENT:-unknown}"
        }
    ]
}
EOF
    
    # Update metrics
    local config_file="$FUNNEL_DIR/$funnel_name/config.json"
    local total=$(jq -r '.metrics.total_items' "$config_file")
    total=$((total + 1))
    jq --arg total "$total" '.metrics.total_items = ($total | tonumber)' "$config_file" > "${config_file}.tmp"
    mv "${config_file}.tmp" "$config_file"
    
    # Log to memory
    ~/memory-system.sh log "funnel-$funnel_name" "$item_id" "🔽 Added to funnel: $item_name (stage: $first_stage)" 2>/dev/null
    
    echo -e "${GREEN}✅ Added to funnel:${NC} ${CYAN}$item_id${NC}"
    echo -e "   ${BLUE}Name:${NC} $item_name"
    echo -e "   ${BLUE}Stage:${NC} $first_stage"
}

# Move item to next stage
advance() {
    local funnel_name="$1"
    local item_id="$2"
    local notes="${3:-}"
    
    if [[ -z "$funnel_name" || -z "$item_id" ]]; then
        echo -e "${RED}Usage: advance <funnel-name> <item-id> [notes]${NC}"
        return 1
    fi
    
    # Find current stage
    local current_file=""
    local current_stage=""
    
    local stages=$(jq -r '.stages' "$FUNNEL_DIR/$funnel_name/config.json" | tr ',' ' ')
    
    for stage in $stages; do
        if [[ -f "$FUNNEL_DIR/$funnel_name/$stage/${item_id}.json" ]]; then
            current_file="$FUNNEL_DIR/$funnel_name/$stage/${item_id}.json"
            current_stage="$stage"
            break
        fi
    done
    
    if [[ -z "$current_file" ]]; then
        echo -e "${RED}Item not found: $item_id${NC}"
        return 1
    fi
    
    # Get next stage
    local found_current=0
    local next_stage=""
    
    for stage in $stages; do
        if [[ $found_current -eq 1 ]]; then
            next_stage="$stage"
            break
        fi
        if [[ "$stage" == "$current_stage" ]]; then
            found_current=1
        fi
    done
    
    if [[ -z "$next_stage" ]]; then
        echo -e "${YELLOW}Item is already at final stage: $current_stage${NC}"
        return 1
    fi
    
    # Update item
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local item_name=$(jq -r '.item_name' "$current_file")
    
    # Add to history
    local history_entry=$(cat <<EOF
{
    "stage": "$next_stage",
    "timestamp": "$timestamp",
    "action": "advanced",
    "by": "${MY_AGENT:-unknown}",
    "notes": "$notes"
}
EOF
)
    
    jq --arg stage "$next_stage" \
       --arg timestamp "$timestamp" \
       --argjson entry "$history_entry" \
       '.current_stage = $stage | .updated_at = $timestamp | .history += [$entry]' \
       "$current_file" > "${current_file}.tmp"
    
    # Move to next stage
    mv "${current_file}.tmp" "$FUNNEL_DIR/$funnel_name/$next_stage/${item_id}.json"
    rm -f "$current_file"
    
    # Check if completed
    if [[ "$next_stage" == "complete" ]]; then
        local config_file="$FUNNEL_DIR/$funnel_name/config.json"
        local completed=$(jq -r '.metrics.completed' "$config_file")
        completed=$((completed + 1))
        jq --arg completed "$completed" '.metrics.completed = ($completed | tonumber)' "$config_file" > "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
    fi
    
    # Log to memory
    ~/memory-system.sh log "funnel-$funnel_name" "$item_id" "➡️ Advanced: $current_stage → $next_stage ($item_name)" 2>/dev/null
    
    echo -e "${GREEN}✅ Advanced:${NC} ${CYAN}$item_id${NC}"
    echo -e "   ${BLUE}From:${NC} $current_stage"
    echo -e "   ${BLUE}To:${NC} $next_stage"
    if [[ -n "$notes" ]]; then
        echo -e "   ${BLUE}Notes:${NC} $notes"
    fi
}

# View funnel statistics
stats() {
    local funnel_name="${1:-default}"
    
    if [[ ! -d "$FUNNEL_DIR/$funnel_name" ]]; then
        echo -e "${RED}Funnel not found: $funnel_name${NC}"
        return 1
    fi
    
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${PURPLE}║        📊 FUNNEL STATISTICS: $(echo "$funnel_name" | tr a-z A-Z)${NC}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local stages=$(jq -r '.stages' "$FUNNEL_DIR/$funnel_name/config.json" | tr ',' ' ')
    local total=$(jq -r '.metrics.total_items' "$FUNNEL_DIR/$funnel_name/config.json")
    local completed=$(jq -r '.metrics.completed' "$FUNNEL_DIR/$funnel_name/config.json")
    
    echo -e "${BOLD}Overview:${NC}"
    echo -e "  Total items entered: ${CYAN}$total${NC}"
    echo -e "  Completed: ${GREEN}$completed${NC}"
    echo ""
    
    echo -e "${BOLD}Funnel Breakdown:${NC}"
    echo ""
    
    local max_width=0
    for stage in $stages; do
        [[ ${#stage} -gt $max_width ]] && max_width=${#stage}
    done
    
    for stage in $stages; do
        local count=$(ls -1 "$FUNNEL_DIR/$funnel_name/$stage"/*.json 2>/dev/null | wc -l | tr -d ' ')
        
        # Calculate percentage of total
        local percent=0
        [[ $total -gt 0 ]] && percent=$(( (count * 100) / total ))
        
        # Create bar
        local bar_length=$(( percent / 5 ))
        local bar=""
        for ((i=0; i<bar_length && i<20; i++)); do
            bar="${bar}█"
        done
        
        # Color based on stage
        local stage_color="$NC"
        case "$stage" in
            intake) stage_color="$CYAN" ;;
            qualify) stage_color="$BLUE" ;;
            develop) stage_color="$YELLOW" ;;
            test) stage_color="$PURPLE" ;;
            deploy) stage_color="$GREEN" ;;
            complete) stage_color="$GREEN" ;;
        esac
        
        printf "  ${stage_color}%-${max_width}s${NC}  %3d items  %3d%%  ${stage_color}%s${NC}\n" \
            "$stage" "$count" "$percent" "$bar"
    done
    
    echo ""
    
    # Conversion rate
    if [[ $total -gt 0 ]]; then
        local conversion=$(( (completed * 100) / total ))
        echo -e "${BOLD}Conversion Rate:${NC} ${GREEN}$conversion%${NC} (${completed}/${total})"
    fi
}

# List items in a stage
list_stage() {
    local funnel_name="$1"
    local stage="$2"
    
    if [[ -z "$funnel_name" || -z "$stage" ]]; then
        echo -e "${RED}Usage: list <funnel-name> <stage>${NC}"
        return 1
    fi
    
    if [[ ! -d "$FUNNEL_DIR/$funnel_name/$stage" ]]; then
        echo -e "${RED}Stage not found: $stage${NC}"
        return 1
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        Items in stage: ${BOLD}$stage${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local count=0
    
    for item_file in "$FUNNEL_DIR/$funnel_name/$stage"/*.json; do
        [[ ! -f "$item_file" ]] && continue
        
        local item_id=$(jq -r '.item_id' "$item_file")
        local item_name=$(jq -r '.item_name' "$item_file")
        local added_at=$(jq -r '.added_at' "$item_file")
        local updated_at=$(jq -r '.updated_at' "$item_file")
        
        echo -e "${PURPLE}▸${NC} ${BOLD}$item_id${NC}: $item_name"
        echo -e "  ${BLUE}Added:${NC} $added_at | ${BLUE}Updated:${NC} $updated_at"
        echo ""
        
        ((count++))
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No items in this stage${NC}"
    else
        echo -e "${GREEN}Total: $count items${NC}"
    fi
}

# Show item details
show_item() {
    local funnel_name="$1"
    local item_id="$2"
    
    if [[ -z "$funnel_name" || -z "$item_id" ]]; then
        echo -e "${RED}Usage: show <funnel-name> <item-id>${NC}"
        return 1
    fi
    
    # Find item
    local item_file=""
    local stages=$(jq -r '.stages' "$FUNNEL_DIR/$funnel_name/config.json" | tr ',' ' ')
    
    for stage in $stages; do
        if [[ -f "$FUNNEL_DIR/$funnel_name/$stage/${item_id}.json" ]]; then
            item_file="$FUNNEL_DIR/$funnel_name/$stage/${item_id}.json"
            break
        fi
    done
    
    if [[ -z "$item_file" ]]; then
        echo -e "${RED}Item not found: $item_id${NC}"
        return 1
    fi
    
    local item_name=$(jq -r '.item_name' "$item_file")
    local current_stage=$(jq -r '.current_stage' "$item_file")
    local added_at=$(jq -r '.added_at' "$item_file")
    local added_by=$(jq -r '.added_by' "$item_file")
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        📋 ITEM DETAILS 📋                                 ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BOLD}Item ID:${NC} $item_id"
    echo -e "${BOLD}Name:${NC} $item_name"
    echo -e "${BOLD}Current Stage:${NC} ${PURPLE}$current_stage${NC}"
    echo -e "${BOLD}Added:${NC} $added_at (by $added_by)"
    echo ""
    
    echo -e "${BOLD}History:${NC}"
    jq -r '.history[] | "\(.timestamp) | \(.stage) | \(.action) | \(.by) | \(.notes // "")"' "$item_file" | while IFS='|' read -r ts stage action by notes; do
        ts=$(echo "$ts" | xargs)
        stage=$(echo "$stage" | xargs)
        action=$(echo "$action" | xargs)
        by=$(echo "$by" | xargs)
        notes=$(echo "$notes" | xargs)
        
        echo -e "  ${BLUE}$ts${NC} → ${PURPLE}$stage${NC} (${action}) by ${CYAN}$by${NC}"
        [[ -n "$notes" ]] && echo -e "    ${YELLOW}Note: $notes${NC}"
    done
}

# Show help
show_help() {
    cat << EOF
${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}
${PURPLE}║      📊 BlackRoad Funnel System - Help 📊                ║${NC}
${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${CYAN}init${NC} <funnel-name> [stages]
    Initialize a new funnel with custom stages
    Default stages: intake → qualify → develop → test → deploy → complete
    Example: $0 init sales-pipeline "lead contact qualify propose close"

${CYAN}add${NC} <funnel-name> <item-id> <item-name> [metadata-json]
    Add item to funnel (starts at first stage)
    Example: $0 add dev-pipeline pr-123 "Add authentication"

${CYAN}advance${NC} <funnel-name> <item-id> [notes]
    Move item to next stage in funnel
    Example: $0 advance dev-pipeline pr-123 "Tests passed"

${CYAN}stats${NC} <funnel-name>
    View funnel statistics and conversion rates
    Example: $0 stats dev-pipeline

${CYAN}list${NC} <funnel-name> <stage>
    List all items in a specific stage
    Example: $0 list dev-pipeline test

${CYAN}show${NC} <funnel-name> <item-id>
    Show detailed item info and full history
    Example: $0 show dev-pipeline pr-123

${GREEN}DEFAULT STAGES:${NC}

    ${CYAN}intake${NC}   → Initial entry point
    ${BLUE}qualify${NC}  → Qualification/triage
    ${YELLOW}develop${NC} → Development/work
    ${PURPLE}test${NC}    → Testing/validation
    ${GREEN}deploy${NC}  → Deployment/delivery
    ${GREEN}complete${NC}→ Completed items

${GREEN}USE CASES:${NC}

    • Development pipeline (PR workflow)
    • Sales funnel (lead → close)
    • Customer onboarding journey
    • Content production pipeline
    • Feature request tracking
    • Bug triage workflow

${GREEN}EXAMPLES:${NC}

    # Dev pipeline
    $0 init dev-pipeline
    $0 add dev-pipeline pr-456 "Fix login bug"
    $0 advance dev-pipeline pr-456 "Code review done"
    $0 stats dev-pipeline

    # Sales funnel
    $0 init sales "lead contact qualify demo propose negotiate close"
    $0 add sales customer-789 "Acme Corp" '{"value": 50000, "source": "referral"}'
    $0 advance sales customer-789 "Great demo session"
    $0 list sales qualify

    # View details
    $0 show dev-pipeline pr-456

EOF
}

# Main command router
case "$1" in
    init)
        init_funnel "$2" "$3"
        ;;
    add)
        add_item "$2" "$3" "$4" "$5"
        ;;
    advance)
        advance "$2" "$3" "$4"
        ;;
    stats)
        stats "$2"
        ;;
    list)
        list_stage "$2" "$3"
        ;;
    show)
        show_item "$2" "$3"
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
