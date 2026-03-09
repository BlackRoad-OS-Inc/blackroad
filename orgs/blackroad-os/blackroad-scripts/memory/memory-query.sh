#!/bin/bash
# BlackRoad Memory Query System
# Powerful search and query capabilities for memory system

MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL_FILE="$MEMORY_DIR/journals/master-journal.jsonl"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

# Query by action type
query_action() {
    local action="$1"
    local limit="${2:-20}"

    echo -e "${CYAN}🔍 Searching for action: ${YELLOW}$action${NC}\n"

    grep "\"action\":\"$action\"" "$JOURNAL_FILE" | tail -n "$limit" | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)
        local details=$(echo "$line" | grep -o '"details":"[^"]*"' | cut -d'"' -f4 | head -c 100)

        echo -e "${GREEN}[$timestamp]${NC} ${PURPLE}$entity${NC}"
        echo -e "  ${CYAN}→${NC} $details"
        echo ""
    done
}

# Query by entity
query_entity() {
    local entity="$1"
    local limit="${2:-20}"

    echo -e "${CYAN}🔍 Searching for entity: ${YELLOW}$entity${NC}\n"

    grep "\"entity\":\".*$entity.*\"" "$JOURNAL_FILE" | tail -n "$limit" | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local full_entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)
        local details=$(echo "$line" | grep -o '"details":"[^"]*"' | cut -d'"' -f4 | head -c 100)

        echo -e "${GREEN}[$timestamp]${NC} ${BLUE}$action${NC} - ${PURPLE}$full_entity${NC}"
        echo -e "  ${CYAN}→${NC} $details"
        echo ""
    done
}

# Query by date range
query_date_range() {
    local start_date="$1"
    local end_date="${2:-$(date +%Y-%m-%d)}"

    echo -e "${CYAN}🔍 Searching from ${YELLOW}$start_date${CYAN} to ${YELLOW}$end_date${NC}\n"

    grep "\"timestamp\":\"20" "$JOURNAL_FILE" | \
    awk -v start="$start_date" -v end="$end_date" '
    {
        match($0, /"timestamp":"([^"]*)"/, ts);
        date = substr(ts[1], 1, 10);
        if (date >= start && date <= end) print $0;
    }' | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)

        echo -e "${GREEN}[$timestamp]${NC} ${BLUE}$action${NC} - ${PURPLE}$entity${NC}"
    done
}

# Query by agent
query_agent() {
    local agent="$1"
    local limit="${2:-50}"

    echo -e "${CYAN}🔍 Searching for agent: ${YELLOW}$agent${NC}\n"

    grep "$agent" "$JOURNAL_FILE" | tail -n "$limit" | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)

        echo -e "${GREEN}[$timestamp]${NC} ${BLUE}$action${NC} - ${PURPLE}$entity${NC}"
    done
}

# Search by keyword
search_keyword() {
    local keyword="$1"
    local limit="${2:-30}"

    echo -e "${CYAN}🔍 Searching for keyword: ${YELLOW}$keyword${NC}\n"

    grep -i "$keyword" "$JOURNAL_FILE" | tail -n "$limit" | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)
        local details=$(echo "$line" | grep -o '"details":"[^"]*"' | cut -d'"' -f4)

        # Highlight keyword in details
        details_highlighted=$(echo "$details" | sed "s/$keyword/${YELLOW}$keyword${NC}/gi" | head -c 150)

        echo -e "${GREEN}[$timestamp]${NC} ${BLUE}$action${NC} - ${PURPLE}$entity${NC}"
        echo -e "  ${CYAN}→${NC} $details_highlighted"
        echo ""
    done
}

# Get agent timeline
agent_timeline() {
    local agent="$1"

    echo -e "${CYAN}📅 Timeline for agent: ${YELLOW}$agent${NC}\n"

    grep "$agent" "$JOURNAL_FILE" | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)

        # Color code by action
        case $action in
            started) color=$BLUE ;;
            completed|enhanced) color=$GREEN ;;
            failed) color=$RED ;;
            progress) color=$CYAN ;;
            milestone) color=$YELLOW ;;
            *) color=$NC ;;
        esac

        echo -e "${GREEN}[$timestamp]${NC} ${color}$action${NC} - ${PURPLE}$entity${NC}"
    done
}

# Statistics
show_stats() {
    echo -e "${PURPLE}📊 Memory Statistics:${NC}\n"

    local total=$(wc -l < "$JOURNAL_FILE")
    echo -e "${YELLOW}Total Entries:${NC} $total"

    echo -e "\n${YELLOW}Top Actions:${NC}"
    grep -o '"action":"[^"]*"' "$JOURNAL_FILE" | cut -d'"' -f4 | \
        sort | uniq -c | sort -rn | head -10 | \
        while read count action; do
            echo -e "  ${CYAN}$action:${NC} $count"
        done

    echo -e "\n${YELLOW}Top Entities:${NC}"
    grep -o '"entity":"[^"]*"' "$JOURNAL_FILE" | cut -d'"' -f4 | \
        sort | uniq -c | sort -rn | head -10 | \
        while read count entity; do
            echo -e "  ${PURPLE}$entity:${NC} $count"
        done

    echo -e "\n${YELLOW}Activity by Date:${NC}"
    grep -o '"timestamp":"2026-[^"]*"' "$JOURNAL_FILE" | \
        cut -d'"' -f4 | cut -d'T' -f1 | \
        sort | uniq -c | sort | tail -7 | \
        while read count date; do
            local bar=$(printf '█%.0s' $(seq 1 $((count / 50))))
            echo -e "  ${GREEN}$date${NC} [$count] $bar"
        done

    echo ""
}

# Recent activity
recent() {
    local count="${1:-10}"

    echo -e "${CYAN}🕐 Recent Activity (last $count entries):${NC}\n"

    tail -n "$count" "$JOURNAL_FILE" | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)
        local details=$(echo "$line" | grep -o '"details":"[^"]*"' | cut -d'"' -f4 | head -c 80)

        # Color code by action
        case $action in
            started) color=$BLUE ;;
            completed|enhanced) color=$GREEN ;;
            failed) color=$RED ;;
            progress) color=$CYAN ;;
            milestone|broadcast) color=$YELLOW ;;
            *) color=$NC ;;
        esac

        echo -e "${GREEN}[$timestamp]${NC} ${color}$action${NC} - ${PURPLE}$entity${NC}"
        if [ -n "$details" ]; then
            echo -e "  ${details}"
        fi
        echo ""
    done
}

# Complex query
complex_query() {
    echo -e "${CYAN}🔎 Advanced Query Builder${NC}\n"

    # Interactive query builder
    read -p "Action type (or press Enter for any): " action
    read -p "Entity contains (or press Enter for any): " entity
    read -p "Keyword in details (or press Enter for any): " keyword
    read -p "Start date (YYYY-MM-DD or press Enter for any): " start_date
    read -p "Limit results: " limit

    limit=${limit:-20}

    echo -e "\n${YELLOW}Results:${NC}\n"

    local query=""

    if [ -n "$action" ]; then
        query="$query | grep '\"action\":\"$action\"'"
    fi

    if [ -n "$entity" ]; then
        query="$query | grep '\"entity\":\".*$entity.*\"'"
    fi

    if [ -n "$keyword" ]; then
        query="$query | grep -i '$keyword'"
    fi

    if [ -n "$start_date" ]; then
        query="$query | awk '/$start_date/ {found=1} found'"
    fi

    query="cat '$JOURNAL_FILE' $query | tail -n $limit"

    eval "$query" | \
    while IFS= read -r line; do
        local timestamp=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        local action=$(echo "$line" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
        local entity=$(echo "$line" | grep -o '"entity":"[^"]*"' | cut -d'"' -f4)
        local details=$(echo "$line" | grep -o '"details":"[^"]*"' | cut -d'"' -f4 | head -c 100)

        echo -e "${GREEN}[$timestamp]${NC} ${BLUE}$action${NC} - ${PURPLE}$entity${NC}"
        echo -e "  ${details}"
        echo ""
    done
}

# Export query results
export_query() {
    local query_type="$1"
    local query_param="$2"
    local output_file="$MEMORY_DIR/query-export-$(date +%Y%m%d-%H%M%S).json"

    echo -e "${CYAN}💾 Exporting query results...${NC}\n"

    case $query_type in
        action)
            grep "\"action\":\"$query_param\"" "$JOURNAL_FILE" > "$output_file"
            ;;
        entity)
            grep "\"entity\":\".*$query_param.*\"" "$JOURNAL_FILE" > "$output_file"
            ;;
        agent)
            grep "$query_param" "$JOURNAL_FILE" > "$output_file"
            ;;
        keyword)
            grep -i "$query_param" "$JOURNAL_FILE" > "$output_file"
            ;;
        *)
            echo -e "${RED}Unknown query type${NC}"
            return 1
            ;;
    esac

    local count=$(wc -l < "$output_file")
    echo -e "${GREEN}✅ Exported $count entries to: $output_file${NC}"
}

# Show help
show_help() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║       🌌 BlackRoad Memory Query System       ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
    echo "Usage: $0 COMMAND [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  action ACTION [LIMIT]          - Query by action type"
    echo "  entity ENTITY [LIMIT]          - Query by entity name"
    echo "  date START [END]               - Query by date range"
    echo "  agent AGENT [LIMIT]            - Query by agent"
    echo "  search KEYWORD [LIMIT]         - Search by keyword"
    echo "  timeline AGENT                 - Show agent timeline"
    echo "  stats                          - Show statistics"
    echo "  recent [COUNT]                 - Show recent activity"
    echo "  complex                        - Interactive query builder"
    echo "  export TYPE PARAM              - Export query results"
    echo ""
    echo "Examples:"
    echo "  $0 action enhanced 50"
    echo "  $0 entity blackroad-os"
    echo "  $0 date 2026-01-08 2026-01-09"
    echo "  $0 agent cecilia-production-enhancer"
    echo "  $0 search cloudflare"
    echo "  $0 timeline winston"
    echo "  $0 stats"
    echo "  $0 recent 20"
    echo ""
}

# Main execution
case "${1:-help}" in
    action)
        query_action "$2" "$3"
        ;;
    entity)
        query_entity "$2" "$3"
        ;;
    date)
        query_date_range "$2" "$3"
        ;;
    agent)
        query_agent "$2" "$3"
        ;;
    search)
        search_keyword "$2" "$3"
        ;;
    timeline)
        agent_timeline "$2"
        ;;
    stats)
        show_stats
        ;;
    recent)
        recent "$2"
        ;;
    complex)
        complex_query
        ;;
    export)
        export_query "$2" "$3"
        ;;
    help|*)
        show_help
        ;;
esac
