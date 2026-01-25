#!/bin/bash

# BlackRoad TIL (Today I Learned) Broadcast System
# Share discoveries, learnings, and insights across all BlackRoad Agents!

MEMORY_DIR="$HOME/.blackroad/memory"
TIL_DIR="$MEMORY_DIR/til"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Initialize TIL system
init_til() {
    mkdir -p "$TIL_DIR"
    echo -e "${GREEN}✅ TIL broadcast system initialized!${NC}"
}

# Broadcast a TIL
broadcast() {
    local category="$1"
    local learning="$2"
    local broadcaster="${3:-${MY_AGENT:-unknown}}"

    if [[ -z "$category" || -z "$learning" ]]; then
        echo -e "${RED}Usage: broadcast <category> <learning> [broadcaster-id]${NC}"
        echo -e "${YELLOW}Categories: discovery, pattern, gotcha, tip, tool, integration, performance, security${NC}"
        return 1
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    local til_id="til-$(date +%s)-$$"
    local til_file="$TIL_DIR/${til_id}.json"

    cat > "$til_file" << EOF
{
    "til_id": "$til_id",
    "category": "$category",
    "learning": "$learning",
    "broadcaster": "$broadcaster",
    "timestamp": "$timestamp",
    "upvotes": 0
}
EOF

    # Log to memory system
    ~/memory-system.sh log til "$broadcaster" "💡 TIL [$category]: $learning"

    # Show confirmation
    local icon="💡"
    case "$category" in
        discovery) icon="🔍" ;;
        pattern) icon="🎯" ;;
        gotcha) icon="⚠️" ;;
        tip) icon="💡" ;;
        tool) icon="🔧" ;;
        integration) icon="🔗" ;;
        performance) icon="⚡" ;;
        security) icon="🔐" ;;
    esac

    echo -e "${GREEN}✅ TIL broadcast! $icon${NC}"
    echo -e "   ${BLUE}Category:${NC} $category"
    echo -e "   ${BLUE}Learning:${NC} $learning"
    echo -e "   ${BLUE}Broadcaster:${NC} $broadcaster"
    echo ""
    echo -e "${PURPLE}📢 All BlackRoad Agents can now see this in their TIL feed!${NC}"
}

# List recent TILs
list_tils() {
    local filter_category="$1"
    local limit="${2:-20}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           💡 TODAY I LEARNED (TIL) FEED 💡                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local til_count=0

    for til_file in $(ls -t "$TIL_DIR"/til-*.json 2>/dev/null | head -n "$limit"); do
        local category=$(jq -r '.category' "$til_file")

        # Filter by category if specified
        if [[ -n "$filter_category" && "$category" != "$filter_category" ]]; then
            continue
        fi

        local learning=$(jq -r '.learning' "$til_file")
        local broadcaster=$(jq -r '.broadcaster' "$til_file")
        local timestamp=$(jq -r '.timestamp' "$til_file")
        local upvotes=$(jq -r '.upvotes // 0' "$til_file")

        # Category icon and color
        local icon="💡"
        local cat_color="$NC"
        case "$category" in
            discovery) icon="🔍"; cat_color="$PURPLE" ;;
            pattern) icon="🎯"; cat_color="$BLUE" ;;
            gotcha) icon="⚠️"; cat_color="$YELLOW" ;;
            tip) icon="💡"; cat_color="$GREEN" ;;
            tool) icon="🔧"; cat_color="$CYAN" ;;
            integration) icon="🔗"; cat_color="$PURPLE" ;;
            performance) icon="⚡"; cat_color="$YELLOW" ;;
            security) icon="🔐"; cat_color="$RED" ;;
        esac

        echo -e "${icon} ${cat_color}${BOLD}[$category]${NC} ${learning}"
        echo -e "   ${BLUE}From:${NC} $broadcaster • ${BLUE}When:${NC} $timestamp"

        if [[ $upvotes -gt 0 ]]; then
            echo -e "   ${GREEN}👍 $upvotes${NC}"
        fi

        echo ""
        ((til_count++))
    done

    if [[ $til_count -eq 0 ]]; then
        echo -e "${YELLOW}No TILs found${NC}"
        if [[ -n "$filter_category" ]]; then
            echo -e "${YELLOW}Try without category filter or broadcast one!${NC}"
        fi
    else
        echo -e "${GREEN}Showing $til_count TILs${NC}"
    fi
}

# Upvote a TIL
upvote() {
    local til_id="$1"

    if [[ -z "$til_id" ]]; then
        echo -e "${RED}Usage: upvote <til-id>${NC}"
        return 1
    fi

    local til_file="$TIL_DIR/${til_id}.json"

    if [[ ! -f "$til_file" ]]; then
        echo -e "${RED}❌ TIL not found: $til_id${NC}"
        return 1
    fi

    # Increment upvotes
    local current_upvotes=$(jq -r '.upvotes // 0' "$til_file")
    local new_upvotes=$((current_upvotes + 1))

    jq --arg upvotes "$new_upvotes" '.upvotes = ($upvotes | tonumber)' "$til_file" > "${til_file}.tmp"
    mv "${til_file}.tmp" "$til_file"

    echo -e "${GREEN}👍 Upvoted! Total upvotes: $new_upvotes${NC}"
}

# Show TIL digest (grouped by category)
digest() {
    local since_hours="${1:-24}"

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           📚 TIL DIGEST (Last ${since_hours}h) 📚                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local cutoff_time=$(date -u -v-${since_hours}H +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -d "${since_hours} hours ago" +"%Y-%m-%dT%H:%M:%S")

    # Group by category
    declare -A categories

    for til_file in "$TIL_DIR"/til-*.json; do
        [[ ! -f "$til_file" ]] && continue

        local timestamp=$(jq -r '.timestamp' "$til_file")

        # Check if within time range
        if [[ "$timestamp" > "$cutoff_time" ]]; then
            local category=$(jq -r '.category' "$til_file")
            local learning=$(jq -r '.learning' "$til_file")
            local broadcaster=$(jq -r '.broadcaster' "$til_file")

            if [[ -z "${categories[$category]}" ]]; then
                categories[$category]="• $learning ($broadcaster)"
            else
                categories[$category]="${categories[$category]}
• $learning ($broadcaster)"
            fi
        fi
    done

    # Display by category
    if [[ ${#categories[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No TILs in the last ${since_hours} hours${NC}"
        return
    fi

    for category in discovery pattern gotcha tip tool integration performance security; do
        if [[ -n "${categories[$category]}" ]]; then
            local icon="💡"
            local cat_color="$NC"
            case "$category" in
                discovery) icon="🔍"; cat_color="$PURPLE" ;;
                pattern) icon="🎯"; cat_color="$BLUE" ;;
                gotcha) icon="⚠️"; cat_color="$YELLOW" ;;
                tip) icon="💡"; cat_color="$GREEN" ;;
                tool) icon="🔧"; cat_color="$CYAN" ;;
                integration) icon="🔗"; cat_color="$PURPLE" ;;
                performance) icon="⚡"; cat_color="$YELLOW" ;;
                security) icon="🔐"; cat_color="$RED" ;;
            esac

            echo -e "${icon} ${cat_color}${BOLD}${category^^}${NC}"
            echo "${categories[$category]}" | while read -r line; do
                [[ -n "$line" ]] && echo -e "   $line"
            done
            echo ""
        fi
    done
}

# Search TILs
search() {
    local query="$1"

    if [[ -z "$query" ]]; then
        echo -e "${RED}Usage: search <query>${NC}"
        return 1
    fi

    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🔍 TIL SEARCH RESULTS 🔍                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Query:${NC} $query"
    echo ""

    local found=0

    for til_file in $(ls -t "$TIL_DIR"/til-*.json 2>/dev/null); do
        local learning=$(jq -r '.learning' "$til_file")

        # Case-insensitive search
        if echo "$learning" | grep -iq "$query"; then
            local category=$(jq -r '.category' "$til_file")
            local broadcaster=$(jq -r '.broadcaster' "$til_file")
            local timestamp=$(jq -r '.timestamp' "$til_file")

            # Category icon
            local icon="💡"
            case "$category" in
                discovery) icon="🔍" ;;
                pattern) icon="🎯" ;;
                gotcha) icon="⚠️" ;;
                tip) icon="💡" ;;
                tool) icon="🔧" ;;
                integration) icon="🔗" ;;
                performance) icon="⚡" ;;
                security) icon="🔐" ;;
            esac

            echo -e "${icon} ${BOLD}[$category]${NC} $learning"
            echo -e "   ${BLUE}From:${NC} $broadcaster • ${BLUE}When:${NC} $timestamp"
            echo ""

            ((found++))
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo -e "${YELLOW}No TILs found matching: $query${NC}"
    else
        echo -e "${GREEN}Found $found matching TILs${NC}"
    fi
}

# Show help
show_help() {
    cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗${NC}
${CYAN}║    💡 BlackRoad TIL Broadcast System - Help 💡            ║${NC}
${CYAN}╚════════════════════════════════════════════════════════════╝${NC}

${GREEN}USAGE:${NC}
    $0 <command> [options]

${GREEN}COMMANDS:${NC}

${BLUE}init${NC}
    Initialize the TIL broadcast system

${BLUE}broadcast${NC} <category> <learning> [broadcaster-id]
    Broadcast a TIL to all BlackRoad Agents
    Categories: discovery, pattern, gotcha, tip, tool, integration, performance, security
    Example: broadcast discovery "Found math library in packs/research-lab/"

${BLUE}list${NC} [category] [limit]
    List recent TILs (default: 20)
    Example: list discovery 10

${BLUE}digest${NC} [hours]
    Show TIL digest grouped by category (default: last 24h)
    Example: digest 48

${BLUE}search${NC} <query>
    Search TILs by keyword
    Example: search "database"

${BLUE}upvote${NC} <til-id>
    Upvote a helpful TIL
    Example: upvote til-1703456789-12345

${GREEN}CATEGORIES:${NC}

    🔍 ${PURPLE}discovery${NC}   - Found something cool in the codebase
    🎯 ${BLUE}pattern${NC}      - Identified a useful coding pattern
    ⚠️  ${YELLOW}gotcha${NC}       - Watch out for this!
    💡 ${GREEN}tip${NC}          - Helpful productivity tip
    🔧 ${CYAN}tool${NC}         - Useful tool or command
    🔗 ${PURPLE}integration${NC}  - How systems integrate
    ⚡ ${YELLOW}performance${NC}  - Performance optimization
    🔐 ${RED}security${NC}     - Security consideration

${GREEN}EXAMPLES:${NC}

    # Broadcast a discovery
    $0 broadcast discovery "BlackRoad Codex has 8,789 components!"

    # Share a gotcha
    $0 broadcast gotcha "Always check [MEMORY] before deploying - avoid conflicts!"

    # Share a useful pattern
    $0 broadcast pattern "Use GreenLight templates for consistent deployment logs"

    # Share a tool
    $0 broadcast tool "Use ~/memory-collaboration-dashboard.sh for live view!"

    # View last 10 TILs
    $0 list 10

    # View discoveries only
    $0 list discovery

    # Search for specific topic
    $0 search "deployment"

    # View digest of last 48 hours
    $0 digest 48

${GREEN}USE CASES:${NC}

    • Share codebase discoveries with other BlackRoad Agents
    • Document "gotchas" so others don't hit same issues
    • Spread knowledge about useful patterns and tools
    • Build collective intelligence across the Agent swarm
    • Reduce duplicate discovery work

EOF
}

# Main command router
case "$1" in
    init)
        init_til
        ;;
    broadcast)
        broadcast "$2" "$3" "$4"
        ;;
    list)
        list_tils "$2" "$3"
        ;;
    digest)
        digest "$2"
        ;;
    search)
        search "$2"
        ;;
    upvote)
        upvote "$2"
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
