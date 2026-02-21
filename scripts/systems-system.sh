#!/bin/bash
# [SYSTEMS] System - Meta-system managing all BlackRoad systems
# Usage: ~/systems-system.sh <command> [args]
# THE 100TH SYSTEM! 🎯

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
CYAN='\033[38;5;51m'
RESET='\033[0m'

SYSTEMS_DB="$HOME/.blackroad/systems.db"

init_systems() {
    mkdir -p "$HOME/.blackroad"
    sqlite3 "$SYSTEMS_DB" <<EOSQL
CREATE TABLE IF NOT EXISTS systems (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    script_path TEXT NOT NULL,
    db_path TEXT,
    category TEXT DEFAULT 'general',
    description TEXT,
    status TEXT DEFAULT 'active',
    version TEXT DEFAULT '1.0.0',
    tables INTEGER DEFAULT 0,
    commands INTEGER DEFAULT 0,
    last_used TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS system_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT
);

CREATE TABLE IF NOT EXISTS system_dependencies (
    system_id TEXT NOT NULL,
    depends_on TEXT NOT NULL,
    type TEXT DEFAULT 'optional',
    PRIMARY KEY (system_id, depends_on)
);

CREATE TABLE IF NOT EXISTS system_health (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    system_id TEXT NOT NULL,
    status TEXT NOT NULL,
    db_size_bytes INTEGER,
    record_count INTEGER,
    checked_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS system_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    system_id TEXT NOT NULL,
    command TEXT,
    used_at TEXT DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO system_categories (id, name, description, color) VALUES
    ('core', 'Core', 'Core infrastructure systems', 'pink'),
    ('data', 'Data', 'Data management systems', 'blue'),
    ('security', 'Security', 'Security & auth systems', 'red'),
    ('comms', 'Communications', 'Messaging & notifications', 'cyan'),
    ('commerce', 'Commerce', 'E-commerce systems', 'green'),
    ('devops', 'DevOps', 'Development operations', 'amber'),
    ('content', 'Content', 'Content management', 'violet'),
    ('analytics', 'Analytics', 'Reporting & analytics', 'yellow');

CREATE INDEX IF NOT EXISTS idx_systems_category ON systems(category);
CREATE INDEX IF NOT EXISTS idx_systems_status ON systems(status);
CREATE INDEX IF NOT EXISTS idx_health_system ON system_health(system_id);
EOSQL
    echo -e "${GREEN}[SYSTEMS]${RESET} System initialized - THE 100TH SYSTEM!"
}

discover() {
    echo -e "${AMBER}[SYSTEMS]${RESET} Discovering systems..."

    local count=0
    for script in ~/*-system.sh; do
        [[ ! -f "$script" ]] && continue

        local basename_script=$(basename "$script")
        local name=$(echo "$basename_script" | sed 's/-system\.sh//' | tr '[:lower:]' '[:upper:]')
        local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        local db_path="$HOME/.blackroad/${name_lower}.db"

        # Count commands in script (looking for case patterns)
        local cmds=0
        cmds=$(grep -E "^\s+[a-z_-]+\)" "$script" 2>/dev/null | wc -l | tr -d ' ')
        [[ -z "$cmds" ]] && cmds=0

        # Check if DB exists and count tables
        local tables=0
        if [[ -f "$db_path" ]]; then
            tables=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null)
            [[ -z "$tables" ]] && tables=0
        fi

        sqlite3 "$SYSTEMS_DB" "INSERT OR REPLACE INTO systems (id, name, script_path, db_path, commands, tables) VALUES ('$name_lower', '$name', '$script', '$db_path', $cmds, $tables);"
        ((count++))
    done

    echo -e "${GREEN}[SYSTEMS]${RESET} Discovered: $count systems"
}

health_check() {
    local system_id="${1:-}"

    if [[ -n "$system_id" ]]; then
        check_single "$system_id"
    else
        echo -e "${AMBER}[SYSTEMS]${RESET} Running health checks..."
        local systems=$(sqlite3 "$SYSTEMS_DB" "SELECT id, db_path FROM systems;")

        while IFS='|' read -r id db_path; do
            [[ -z "$id" ]] && continue
            check_single "$id" "$db_path"
        done <<< "$systems"

        echo -e "${GREEN}[SYSTEMS]${RESET} Health check complete"
    fi
}

check_single() {
    local system_id="$1"
    local db_path="${2:-$(sqlite3 "$SYSTEMS_DB" "SELECT db_path FROM systems WHERE id='$system_id';")}"

    local status="healthy"
    local size=0
    local records=0

    if [[ -f "$db_path" ]]; then
        size=$(stat -f%z "$db_path" 2>/dev/null || stat -c%s "$db_path" 2>/dev/null || echo "0")
        records=$(sqlite3 "$db_path" "SELECT SUM(cnt) FROM (SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='table');" 2>/dev/null || echo "0")
    else
        status="no_database"
    fi

    sqlite3 "$SYSTEMS_DB" "INSERT INTO system_health (system_id, status, db_size_bytes, record_count) VALUES ('$system_id', '$status', $size, $records);"
    sqlite3 "$SYSTEMS_DB" "UPDATE systems SET status='$status' WHERE id='$system_id';"
}

set_category() {
    local system_id="$1"
    local category="$2"

    sqlite3 "$SYSTEMS_DB" "UPDATE systems SET category='$category' WHERE id='$system_id';"
    echo -e "${GREEN}[SYSTEMS]${RESET} Category: $system_id -> $category"
}

set_description() {
    local system_id="$1"
    local description="$2"

    sqlite3 "$SYSTEMS_DB" "UPDATE systems SET description='$description' WHERE id='$system_id';"
    echo -e "${GREEN}[SYSTEMS]${RESET} Description updated: $system_id"
}

add_dependency() {
    local system_id="$1"
    local depends_on="$2"
    local type="${3:-optional}"

    sqlite3 "$SYSTEMS_DB" "INSERT OR IGNORE INTO system_dependencies (system_id, depends_on, type) VALUES ('$system_id', '$depends_on', '$type');"
    echo -e "${GREEN}[SYSTEMS]${RESET} Dependency: $system_id -> $depends_on"
}

log_usage() {
    local system_id="$1"
    local command="$2"

    sqlite3 "$SYSTEMS_DB" "INSERT INTO system_usage (system_id, command) VALUES ('$system_id', '$command');"
    sqlite3 "$SYSTEMS_DB" "UPDATE systems SET last_used=datetime('now') WHERE id='$system_id';"
}

list() {
    local category="${1:-}"
    echo -e "${AMBER}[SYSTEMS]${RESET} All Systems"
    echo ""
    if [[ -n "$category" ]]; then
        sqlite3 -column -header "$SYSTEMS_DB" "SELECT name, category, status, commands, tables FROM systems WHERE category='$category' ORDER BY name;"
    else
        sqlite3 -column -header "$SYSTEMS_DB" "SELECT name, category, status, commands, tables FROM systems ORDER BY category, name;"
    fi
}

get() {
    local system_id="$1"
    echo -e "${AMBER}[SYSTEMS]${RESET} System: $system_id"
    echo ""
    sqlite3 -column -header "$SYSTEMS_DB" "SELECT * FROM systems WHERE id='$system_id';"
    echo ""
    echo -e "${BLUE}Dependencies:${RESET}"
    sqlite3 -column "$SYSTEMS_DB" "SELECT depends_on, type FROM system_dependencies WHERE system_id='$system_id';"
}

categories() {
    echo -e "${AMBER}[SYSTEMS]${RESET} Categories"
    echo ""
    sqlite3 -column -header "$SYSTEMS_DB" "SELECT c.name, c.description, COUNT(s.id) as systems FROM system_categories c LEFT JOIN systems s ON c.id=s.category GROUP BY c.id ORDER BY systems DESC;"
}

top_used() {
    local limit="${1:-10}"
    echo -e "${AMBER}[SYSTEMS]${RESET} Most Used Systems"
    echo ""
    sqlite3 -column -header "$SYSTEMS_DB" "SELECT s.name, COUNT(u.id) as uses, s.last_used FROM systems s LEFT JOIN system_usage u ON s.id=u.system_id GROUP BY s.id ORDER BY uses DESC LIMIT $limit;"
}

health_report() {
    echo -e "${AMBER}[SYSTEMS]${RESET} Health Report"
    echo ""
    sqlite3 -column -header "$SYSTEMS_DB" "SELECT s.name, h.status, h.db_size_bytes as size, h.checked_at FROM systems s JOIN system_health h ON s.id=h.system_id WHERE h.id IN (SELECT MAX(id) FROM system_health GROUP BY system_id) ORDER BY s.name;"
}

banner() {
    echo -e "${PINK}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║    ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██████╗  ██████╗  ║"
    echo "║    ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██╔══██╗██╔═══██╗ ║"
    echo "║    ██████╔╝██║     ███████║██║     █████╔╝ ██████╔╝██║   ██║ ║"
    echo "║    ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██╔══██╗██║   ██║ ║"
    echo "║    ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗██║  ██║╚██████╔╝ ║"
    echo "║    ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝  ║"
    echo "║                                                              ║"
    echo -e "║              ${AMBER}🎯 100 SYSTEMS STRONG 🎯${PINK}                       ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

stats() {
    banner
    echo ""

    local total=$(sqlite3 "$SYSTEMS_DB" "SELECT COUNT(*) FROM systems;")
    local healthy=$(sqlite3 "$SYSTEMS_DB" "SELECT COUNT(*) FROM systems WHERE status='healthy';")
    local total_cmds=$(sqlite3 "$SYSTEMS_DB" "SELECT COALESCE(SUM(commands), 0) FROM systems;")
    local total_tables=$(sqlite3 "$SYSTEMS_DB" "SELECT COALESCE(SUM(tables), 0) FROM systems;")
    local categories=$(sqlite3 "$SYSTEMS_DB" "SELECT COUNT(DISTINCT category) FROM systems WHERE category IS NOT NULL;")
    local total_size=$(sqlite3 "$SYSTEMS_DB" "SELECT COALESCE(SUM(db_size_bytes), 0) FROM system_health WHERE id IN (SELECT MAX(id) FROM system_health GROUP BY system_id);")

    local size_human
    if [[ $total_size -gt 1048576 ]]; then
        size_human="$((total_size / 1048576)) MB"
    elif [[ $total_size -gt 1024 ]]; then
        size_human="$((total_size / 1024)) KB"
    else
        size_human="$total_size bytes"
    fi

    echo -e "  ${CYAN}╭─────────────────────────────────────╮${RESET}"
    echo -e "  ${CYAN}│${RESET}  ${GREEN}Total Systems:${RESET}     ${AMBER}$total${RESET}              ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}  ${GREEN}Healthy:${RESET}           $healthy              ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}  ${GREEN}Total Commands:${RESET}    $total_cmds            ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}  ${GREEN}Total Tables:${RESET}      $total_tables            ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}  ${GREEN}Categories:${RESET}        $categories              ${CYAN}│${RESET}"
    echo -e "  ${CYAN}│${RESET}  ${GREEN}Total DB Size:${RESET}     $size_human        ${CYAN}│${RESET}"
    echo -e "  ${CYAN}╰─────────────────────────────────────╯${RESET}"
    echo ""
    echo -e "${BLUE}By Category:${RESET}"
    sqlite3 -column "$SYSTEMS_DB" "SELECT category, COUNT(*) as count FROM systems GROUP BY category ORDER BY count DESC;"
}

show_help() {
    echo -e "${PINK}[SYSTEMS]${RESET} - BlackRoad Meta-System Manager"
    echo -e "${AMBER}THE 100TH SYSTEM!${RESET}"
    echo ""
    echo "Usage: ~/systems-system.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init                              Initialize system"
    echo "  discover                          Discover all systems"
    echo "  health [system]                   Run health checks"
    echo "  category <system> <cat>           Set category"
    echo "  description <system> <desc>       Set description"
    echo "  depend <system> <on> [type]       Add dependency"
    echo "  list [category]                   List all systems"
    echo "  get <system>                      Get system details"
    echo "  categories                        List categories"
    echo "  top-used [limit]                  Most used systems"
    echo "  health-report                     Health report"
    echo "  stats                             Show statistics"
    echo "  banner                            Show celebration banner"
}

case "${1:-help}" in
    init)          init_systems ;;
    discover)      discover ;;
    health)        health_check "$2" ;;
    category)      set_category "$2" "$3" ;;
    description)   set_description "$2" "$3" ;;
    depend)        add_dependency "$2" "$3" "$4" ;;
    list)          list "$2" ;;
    get)           get "$2" ;;
    categories)    categories ;;
    top-used)      top_used "$2" ;;
    health-report) health_report ;;
    stats)         stats ;;
    banner)        banner ;;
    help|*)        show_help ;;
esac
