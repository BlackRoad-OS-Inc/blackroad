#!/bin/bash

# BlackRoad Traffic Light System
# GreenLight = Approved/Go, YellowLight = Needs Review/Caution, RedLight = Blocked/Stop
# Perfect for deployment gates, PR approvals, and quality checks

MEMORY_DIR="$HOME/.blackroad/memory"
LIGHTS_DIR="$MEMORY_DIR/traffic-lights"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize traffic light system
init_lights() {
    mkdir -p "$LIGHTS_DIR"/{green,yellow,red,history}
    
    cat > "$LIGHTS_DIR/config.json" << 'EOF'
{
    "system": "BlackRoad Traffic Light System",
    "lights": {
        "green": "Approved - Go ahead",
        "yellow": "Needs review - Proceed with caution",
        "red": "Blocked - Stop and fix"
    },
    "auto_rules": {
        "all_tests_pass": "green",
        "some_tests_fail": "yellow",
        "critical_failure": "red",
        "security_issue": "red",
        "needs_review": "yellow"
    }
}
EOF
    
    echo -e "${GREEN}✅ Traffic Light System initialized${NC}"
}

# Set a traffic light
set_light() {
    local entity="$1"
    local color="$2"
    local reason="$3"
    local set_by="${4:-${MY_AGENT:-unknown}}"
    
    if [[ -z "$entity" || -z "$color" ]]; then
        echo -e "${RED}Usage: set <entity> <green|yellow|red> <reason> [set-by]${NC}"
        return 1
    fi
    
    # Validate color
    if [[ ! " green yellow red " =~ " ${color} " ]]; then
        echo -e "${RED}Invalid color. Use: green, yellow, or red${NC}"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local light_file="$LIGHTS_DIR/${color}/${entity}.json"
    
    # Remove from other light states
    rm -f "$LIGHTS_DIR/green/${entity}.json" 2>/dev/null
    rm -f "$LIGHTS_DIR/yellow/${entity}.json" 2>/dev/null
    rm -f "$LIGHTS_DIR/red/${entity}.json" 2>/dev/null
    
    # Create new light state
    cat > "$light_file" << EOF
{
    "entity": "$entity",
    "light": "$color",
    "reason": "$reason",
    "set_by": "$set_by",
    "timestamp": "$timestamp"
}
EOF

    # Log to history
    cat >> "$LIGHTS_DIR/history/${entity}.log" << EOF
$timestamp | $color | $reason | $set_by
EOF
    
    # Log to memory
    ~/memory-system.sh log "traffic-light-${color}" "$entity" "🚦 $(echo "$color" | tr a-z A-Z): $reason (by $set_by)" 2>/dev/null
    
    # Show confirmation with appropriate color
    case "$color" in
        green)
            echo -e "${GREEN}🟢 GREEN LIGHT: ${BOLD}$entity${NC}"
            echo -e "   ${GREEN}✅ $reason${NC}"
            ;;
        yellow)
            echo -e "${YELLOW}🟡 YELLOW LIGHT: ${BOLD}$entity${NC}"
            echo -e "   ${YELLOW}⚠️  $reason${NC}"
            ;;
        red)
            echo -e "${RED}🔴 RED LIGHT: ${BOLD}$entity${NC}"
            echo -e "   ${RED}🛑 $reason${NC}"
            ;;
    esac
    
    echo -e "   ${BLUE}Set by:${NC} $set_by"
}

# Check light status
check_light() {
    local entity="$1"
    
    if [[ -z "$entity" ]]; then
        echo -e "${RED}Usage: check <entity>${NC}"
        return 1
    fi
    
    # Check each color
    for color in green yellow red; do
        local light_file="$LIGHTS_DIR/${color}/${entity}.json"
        
        if [[ -f "$light_file" ]]; then
            local reason=$(jq -r '.reason' "$light_file")
            local set_by=$(jq -r '.set_by' "$light_file")
            local timestamp=$(jq -r '.timestamp' "$light_file")
            
            case "$color" in
                green)
                    echo -e "${GREEN}🟢 GREEN LIGHT${NC}"
                    echo -e "   ${GREEN}Status: GO AHEAD ✅${NC}"
                    ;;
                yellow)
                    echo -e "${YELLOW}🟡 YELLOW LIGHT${NC}"
                    echo -e "   ${YELLOW}Status: PROCEED WITH CAUTION ⚠️${NC}"
                    ;;
                red)
                    echo -e "${RED}🔴 RED LIGHT${NC}"
                    echo -e "   ${RED}Status: BLOCKED - STOP 🛑${NC}"
                    ;;
            esac
            
            echo -e "   ${BLUE}Entity:${NC} $entity"
            echo -e "   ${BLUE}Reason:${NC} $reason"
            echo -e "   ${BLUE}Set by:${NC} $set_by"
            echo -e "   ${BLUE}When:${NC} $timestamp"
            
            return 0
        fi
    done
    
    echo -e "${YELLOW}No light set for: $entity${NC}"
    return 1
}

# List all lights
list_lights() {
    local filter_color="$1"
    
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║        🚦 BLACKROAD TRAFFIC LIGHT DASHBOARD 🚦           ║${NC}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local green_count=$(ls -1 "$LIGHTS_DIR/green"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local yellow_count=$(ls -1 "$LIGHTS_DIR/yellow"/*.json 2>/dev/null | wc -l | tr -d ' ')
    local red_count=$(ls -1 "$LIGHTS_DIR/red"/*.json 2>/dev/null | wc -l | tr -d ' ')
    
    echo -e "${GREEN}🟢 Green: $green_count${NC}  ${YELLOW}🟡 Yellow: $yellow_count${NC}  ${RED}🔴 Red: $red_count${NC}"
    echo ""
    
    # Show green lights
    if [[ -z "$filter_color" || "$filter_color" == "green" ]]; then
        if [[ $green_count -gt 0 ]]; then
            echo -e "${BOLD}${GREEN}🟢 GREEN LIGHTS (GO AHEAD)${NC}"
            for light_file in "$LIGHTS_DIR/green"/*.json; do
                [[ ! -f "$light_file" ]] && continue
                
                local entity=$(jq -r '.entity' "$light_file")
                local reason=$(jq -r '.reason' "$light_file")
                local set_by=$(jq -r '.set_by' "$light_file")
                
                echo -e "  ${GREEN}✅${NC} ${BOLD}$entity${NC}"
                echo -e "     $reason ${BLUE}(by $set_by)${NC}"
            done
            echo ""
        fi
    fi
    
    # Show yellow lights
    if [[ -z "$filter_color" || "$filter_color" == "yellow" ]]; then
        if [[ $yellow_count -gt 0 ]]; then
            echo -e "${BOLD}${YELLOW}🟡 YELLOW LIGHTS (CAUTION)${NC}"
            for light_file in "$LIGHTS_DIR/yellow"/*.json; do
                [[ ! -f "$light_file" ]] && continue
                
                local entity=$(jq -r '.entity' "$light_file")
                local reason=$(jq -r '.reason' "$light_file")
                local set_by=$(jq -r '.set_by' "$light_file")
                
                echo -e "  ${YELLOW}⚠️${NC}  ${BOLD}$entity${NC}"
                echo -e "     $reason ${BLUE}(by $set_by)${NC}"
            done
            echo ""
        fi
    fi
    
    # Show red lights
    if [[ -z "$filter_color" || "$filter_color" == "red" ]]; then
        if [[ $red_count -gt 0 ]]; then
            echo -e "${BOLD}${RED}🔴 RED LIGHTS (BLOCKED)${NC}"
            for light_file in "$LIGHTS_DIR/red"/*.json; do
                [[ ! -f "$light_file" ]] && continue
                
                local entity=$(jq -r '.entity' "$light_file")
                local reason=$(jq -r '.reason' "$light_file")
                local set_by=$(jq -r '.set_by' "$light_file")
                
                echo -e "  ${RED}🛑${NC} ${BOLD}$entity${NC}"
                echo -e "     $reason ${BLUE}(by $set_by)${NC}"
            done
            echo ""
        fi
    fi
}

# Show history for an entity
show_history() {
    local entity="$1"
    
    if [[ -z "$entity" ]]; then
        echo -e "${RED}Usage: history <entity>${NC}"
        return 1
    fi
    
    local history_file="$LIGHTS_DIR/history/${entity}.log"
    
    if [[ ! -f "$history_file" ]]; then
        echo -e "${YELLOW}No history found for: $entity${NC}"
        return 1
    fi
    
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        📜 TRAFFIC LIGHT HISTORY 📜                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Entity: $entity${NC}"
    echo ""
    
    while IFS='|' read -r timestamp light reason set_by; do
        timestamp=$(echo "$timestamp" | xargs)
        light=$(echo "$light" | xargs)
        reason=$(echo "$reason" | xargs)
        set_by=$(echo "$set_by" | xargs)
        
        case "$light" in
            green)
                echo -e "${GREEN}🟢${NC} $timestamp | ${GREEN}$reason${NC} | ${BLUE}$set_by${NC}"
                ;;
            yellow)
                echo -e "${YELLOW}🟡${NC} $timestamp | ${YELLOW}$reason${NC} | ${BLUE}$set_by${NC}"
                ;;
            red)
                echo -e "${RED}🔴${NC} $timestamp | ${RED}$reason${NC} | ${BLUE}$set_by${NC}"
                ;;
        esac
    done < "$history_file"
}

# Auto-check based on rules (for CI/CD integration)
auto_check() {
    local entity="$1"
    local test_result="$2"
    
    if [[ -z "$entity" || -z "$test_result" ]]; then
        echo -e "${RED}Usage: auto <entity> <pass|fail|critical>${NC}"
        return 1
    fi
    
    case "$test_result" in
        pass|success|green)
            set_light "$entity" "green" "Automated check passed - all clear" "auto-checker"
            ;;
        warn|warning|yellow)
            set_light "$entity" "yellow" "Automated check has warnings - review needed" "auto-checker"
            ;;
        fail|error|red|critical)
            set_light "$entity" "red" "Automated check failed - blocking deployment" "auto-checker"
            ;;
        *)
            echo -e "${RED}Invalid test result. Use: pass, warn, or fail${NC}"
            return 1
            ;;
    esac
}

# Bulk operations
bulk_green() {
    local pattern="$1"
    local reason="${2:-Bulk approval}"
    
    if [[ -z "$pattern" ]]; then
        echo -e "${RED}Usage: bulk-green <pattern> [reason]${NC}"
        return 1
    fi
    
    local count=0
    for entity in $pattern; do
        set_light "$entity" "green" "$reason" "${MY_AGENT:-bulk-operator}"
        ((count++))
    done
    
    echo -e "${GREEN}✅ Set $count entities to GREEN${NC}"
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║      🚦 BlackRoad Traffic Light System - Help 🚦         ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${CYAN}init${NC}
    Initialize traffic light system

${CYAN}set${NC} <entity> <green|yellow|red> <reason> [set-by]
    Set traffic light for an entity
    Example: $0 set pr-123 green "All tests passed"

${CYAN}check${NC} <entity>
    Check current light status for entity
    Example: $0 check pr-123

${CYAN}list${NC} [green|yellow|red]
    List all traffic lights (optionally filter by color)
    Example: $0 list red

${CYAN}history${NC} <entity>
    Show full history of light changes for entity
    Example: $0 history pr-123

${CYAN}auto${NC} <entity> <pass|warn|fail>
    Auto-set light based on test results
    Example: $0 auto deployment-prod pass

${CYAN}bulk-green${NC} <pattern> [reason]
    Set multiple entities to green
    Example: $0 bulk-green "pr-*" "Bulk approval"

${GREEN}LIGHT MEANINGS:${NC}

    ${GREEN}🟢 GREEN${NC}  - Go ahead, approved, ready
    ${YELLOW}🟡 YELLOW${NC} - Proceed with caution, needs review
    ${RED}🔴 RED${NC}    - Stop, blocked, fix required

${GREEN}USE CASES:${NC}

    • Deployment gates (prod/staging/dev)
    • PR approval workflow
    • Quality gate checks
    • Release management
    • Feature flag controls
    • Security clearance

${GREEN}EXAMPLES:${NC}

    # Initialize
    $0 init

    # Deploy ready
    $0 set deploy-prod green "All tests passed, security reviewed"

    # PR needs work
    $0 set pr-456 yellow "Failing tests, needs fixes"

    # Critical issue
    $0 set deploy-prod red "Security vulnerability detected"

    # Check status
    $0 check deploy-prod

    # View all blocked
    $0 list red

    # Auto-check from CI
    $0 auto build-main pass

EOF
}

# Main command router
case "$1" in
    init)
        init_lights
        ;;
    set)
        set_light "$2" "$3" "$4" "$5"
        ;;
    check)
        check_light "$2"
        ;;
    list)
        list_lights "$2"
        ;;
    history)
        show_history "$2"
        ;;
    auto)
        auto_check "$2" "$3"
        ;;
    bulk-green)
        bulk_green "$2" "$3"
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
