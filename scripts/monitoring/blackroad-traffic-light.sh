#!/bin/bash
# BlackRoad Traffic Light System
# Tracks project status: green (go), yellow (caution), red (blocked)

DB_PATH="$HOME/.blackroad-traffic-light.db"
PINK='\033[38;5;205m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

init_db() {
    sqlite3 "$DB_PATH" <<EOF
CREATE TABLE IF NOT EXISTS migrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    repo_name TEXT UNIQUE NOT NULL,
    status TEXT CHECK(status IN ('red', 'yellow', 'green')) NOT NULL,
    reason TEXT,
    source_org TEXT DEFAULT 'blackboxprogramming',
    target_org TEXT DEFAULT 'BlackRoad-OS',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_status ON migrations(status);
CREATE INDEX IF NOT EXISTS idx_repo ON migrations(repo_name);
EOF
    echo -e "${GREEN}✅ Traffic light database initialized${NC}"
}

show_help() {
    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}      ${WHITE}🚦 BLACKROAD TRAFFIC LIGHT SYSTEM 🚦${NC}      ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Usage:${NC} $0 <command> [args]"
    echo ""
    echo -e "${WHITE}Commands:${NC}"
    echo -e "  ${GREEN}init${NC}                      Initialize database"
    echo -e "  ${GREEN}set${NC} <id> <status> [reason] Set project status (green/yellow/red)"
    echo -e "  ${GREEN}status${NC} <id>               Check project status"
    echo -e "  ${GREEN}list${NC} [status]             List all projects (optionally filter by status)"
    echo -e "  ${GREEN}summary${NC}                   Show status summary"
    echo -e "  ${GREEN}stats${NC}                     Show statistics"
    echo -e "  ${GREEN}help${NC}                      Show this help"
    echo ""
    echo -e "${WHITE}Examples:${NC}"
    echo -e "  $0 set blackroad-api green \"Ready for production\""
    echo -e "  $0 status blackroad-api"
    echo -e "  $0 list yellow"
    echo -e "  $0 summary"
}

set_status() {
    local id="$1"
    local status="$2"
    local reason="$3"

    if [[ -z "$id" || -z "$status" ]]; then
        echo -e "${RED}Error: Usage: $0 set <id> <status> [reason]${NC}"
        return 1
    fi

    if [[ ! "$status" =~ ^(green|yellow|red)$ ]]; then
        echo -e "${RED}Error: Status must be green, yellow, or red${NC}"
        return 1
    fi

    sqlite3 "$DB_PATH" "INSERT OR REPLACE INTO migrations (repo_name, status, reason, updated_at) VALUES ('$id', '$status', '$reason', datetime('now'));"

    local color=$GREEN
    local icon="🟢"
    case "$status" in
        yellow) color=$YELLOW; icon="🟡" ;;
        red) color=$RED; icon="🔴" ;;
    esac

    echo -e "${color}$icon Set ${WHITE}$id${NC} → ${color}$status${NC}"
    [[ -n "$reason" ]] && echo -e "   ${CYAN}Reason:${NC} $reason"
}

get_status() {
    local id="$1"

    if [[ -z "$id" ]]; then
        echo -e "${RED}Error: Usage: $0 status <id>${NC}"
        return 1
    fi

    local result=$(sqlite3 "$DB_PATH" "SELECT status, reason, updated_at FROM migrations WHERE repo_name='$id';")

    if [[ -z "$result" ]]; then
        echo -e "${YELLOW}⚠️  No status found for: $id${NC}"
        return 1
    fi

    IFS='|' read -r status reason updated <<< "$result"

    local color=$GREEN
    local icon="🟢"
    case "$status" in
        yellow) color=$YELLOW; icon="🟡" ;;
        red) color=$RED; icon="🔴" ;;
    esac

    echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Project:${NC} $id"
    echo -e "${WHITE}Status:${NC}  ${color}$icon $status${NC}"
    [[ -n "$reason" ]] && echo -e "${WHITE}Reason:${NC}  $reason"
    echo -e "${WHITE}Updated:${NC} $updated"
    echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

list_projects() {
    local filter="$1"

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}         ${WHITE}🚦 PROJECT STATUS LIST 🚦${NC}         ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local query="SELECT repo_name, status, reason FROM migrations"
    [[ -n "$filter" ]] && query="$query WHERE status='$filter'"
    query="$query ORDER BY status, repo_name;"

    sqlite3 "$DB_PATH" "$query" | while IFS='|' read -r name status reason; do
        local color=$GREEN
        local icon="🟢"
        case "$status" in
            yellow) color=$YELLOW; icon="🟡" ;;
            red) color=$RED; icon="🔴" ;;
        esac
        echo -e "  ${color}$icon${NC} ${WHITE}$name${NC}"
        [[ -n "$reason" ]] && echo -e "     ${CYAN}$reason${NC}"
    done
}

show_summary() {
    local green=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM migrations WHERE status='green';")
    local yellow=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM migrations WHERE status='yellow';")
    local red=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM migrations WHERE status='red';")
    local total=$((green + yellow + red))

    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${NC}       ${WHITE}🚦 TRAFFIC LIGHT SUMMARY 🚦${NC}       ${PINK}║${NC}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}🟢 Green:${NC}  $green projects ready"
    echo -e "  ${YELLOW}🟡 Yellow:${NC} $yellow projects need attention"
    echo -e "  ${RED}🔴 Red:${NC}    $red projects blocked"
    echo -e "  ${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${CYAN}Total:${NC}    $total projects tracked"
    echo ""

    if [[ $yellow -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Yellow Projects:${NC}"
        sqlite3 "$DB_PATH" "SELECT repo_name, reason FROM migrations WHERE status='yellow';" | while IFS='|' read -r name reason; do
            echo -e "   • ${WHITE}$name${NC}: $reason"
        done
        echo ""
    fi

    if [[ $red -gt 0 ]]; then
        echo -e "${RED}🚨 Red Projects (Blocked):${NC}"
        sqlite3 "$DB_PATH" "SELECT repo_name, reason FROM migrations WHERE status='red';" | while IFS='|' read -r name reason; do
            echo -e "   • ${WHITE}$name${NC}: $reason"
        done
    fi
}

show_stats() {
    show_summary
}

# Main command router
case "${1:-help}" in
    init) init_db ;;
    set) set_status "$2" "$3" "$4" ;;
    status) get_status "$2" ;;
    list) list_projects "$2" ;;
    summary|stats) show_summary ;;
    help|--help|-h) show_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
