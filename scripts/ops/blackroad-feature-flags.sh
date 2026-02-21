#!/bin/bash
# BlackRoad Feature Flags
# Dynamic feature control across the cluster
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

FLAGS_DIR="$HOME/.blackroad/flags"
FLAGS_DB="$FLAGS_DIR/flags.db"
ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Initialize
init() {
    mkdir -p "$FLAGS_DIR"

    sqlite3 "$FLAGS_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS flags (
    name TEXT PRIMARY KEY,
    description TEXT,
    enabled INTEGER DEFAULT 0,
    percentage INTEGER DEFAULT 100,
    targets TEXT,
    variants TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS overrides (
    flag TEXT,
    target TEXT,
    enabled INTEGER,
    PRIMARY KEY (flag, target)
);

CREATE TABLE IF NOT EXISTS flag_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    flag TEXT,
    action TEXT,
    old_value TEXT,
    new_value TEXT,
    changed_by TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS evaluations (
    flag TEXT,
    target TEXT,
    result INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQL

    # Seed some default flags
    seed_flags

    echo -e "${GREEN}Feature flags system initialized${RESET}"
}

# Seed default flags
seed_flags() {
    sqlite3 "$FLAGS_DB" << 'SQL'
INSERT OR IGNORE INTO flags (name, description, enabled, percentage) VALUES
    ('new_router', 'Use new smart router for inference', 0, 100),
    ('hailo_acceleration', 'Enable Hailo-8 accelerator', 1, 100),
    ('experimental_models', 'Allow experimental model downloads', 0, 50),
    ('debug_logging', 'Enable verbose debug logging', 0, 100),
    ('cache_responses', 'Cache LLM responses', 1, 100),
    ('stream_responses', 'Stream responses by default', 1, 100),
    ('multi_node_inference', 'Distribute inference across nodes', 0, 100);
SQL
}

# Create flag
create() {
    local name="$1"
    local description="$2"
    local enabled="${3:-0}"
    local percentage="${4:-100}"

    sqlite3 "$FLAGS_DB" "
        INSERT OR REPLACE INTO flags (name, description, enabled, percentage, updated_at)
        VALUES ('$name', '$description', $enabled, $percentage, datetime('now'))
    "

    log_change "$name" "created" "null" "$enabled"

    echo -e "${GREEN}Created flag: $name${RESET}"
    echo "  Description: $description"
    echo "  Enabled: $enabled"
    echo "  Rollout: ${percentage}%"
}

# Enable flag
enable() {
    local name="$1"
    local percentage="${2:-100}"

    local old=$(sqlite3 "$FLAGS_DB" "SELECT enabled FROM flags WHERE name = '$name'")

    sqlite3 "$FLAGS_DB" "
        UPDATE flags SET enabled = 1, percentage = $percentage, updated_at = datetime('now')
        WHERE name = '$name'
    "

    log_change "$name" "enabled" "$old" "1"

    echo -e "${GREEN}Enabled: $name (${percentage}% rollout)${RESET}"

    # Sync to nodes
    sync_flag "$name"
}

# Disable flag
disable() {
    local name="$1"

    local old=$(sqlite3 "$FLAGS_DB" "SELECT enabled FROM flags WHERE name = '$name'")

    sqlite3 "$FLAGS_DB" "
        UPDATE flags SET enabled = 0, updated_at = datetime('now')
        WHERE name = '$name'
    "

    log_change "$name" "disabled" "$old" "0"

    echo -e "${YELLOW}Disabled: $name${RESET}"

    sync_flag "$name"
}

# Toggle flag
toggle() {
    local name="$1"

    local current=$(sqlite3 "$FLAGS_DB" "SELECT enabled FROM flags WHERE name = '$name'")

    if [ "$current" = "1" ]; then
        disable "$name"
    else
        enable "$name"
    fi
}

# Check if flag is enabled
check() {
    local name="$1"
    local target="${2:-default}"

    # Check for override first
    local override=$(sqlite3 "$FLAGS_DB" "SELECT enabled FROM overrides WHERE flag = '$name' AND target = '$target'")

    if [ -n "$override" ]; then
        echo "$override"
        return
    fi

    # Get flag config
    local flag=$(sqlite3 "$FLAGS_DB" "SELECT enabled, percentage FROM flags WHERE name = '$name'")

    if [ -z "$flag" ]; then
        echo "0"
        return
    fi

    local enabled=$(echo "$flag" | cut -d'|' -f1)
    local percentage=$(echo "$flag" | cut -d'|' -f2)

    if [ "$enabled" != "1" ]; then
        echo "0"
        return
    fi

    # Percentage rollout check
    if [ "$percentage" -lt 100 ]; then
        local hash=$(echo -n "${name}${target}" | md5sum | cut -c1-8)
        local hash_val=$((16#$hash % 100))

        if [ "$hash_val" -ge "$percentage" ]; then
            echo "0"
            return
        fi
    fi

    echo "1"

    # Log evaluation
    sqlite3 "$FLAGS_DB" "INSERT INTO evaluations (flag, target, result) VALUES ('$name', '$target', 1)"
}

# Set percentage rollout
rollout() {
    local name="$1"
    local percentage="$2"

    sqlite3 "$FLAGS_DB" "
        UPDATE flags SET percentage = $percentage, updated_at = datetime('now')
        WHERE name = '$name'
    "

    log_change "$name" "rollout" "" "$percentage"

    echo -e "${GREEN}Set $name to ${percentage}% rollout${RESET}"
}

# Set override for specific target
override() {
    local flag="$1"
    local target="$2"
    local value="$3"

    sqlite3 "$FLAGS_DB" "
        INSERT OR REPLACE INTO overrides (flag, target, enabled)
        VALUES ('$flag', '$target', $value)
    "

    echo -e "${GREEN}Override: $flag = $value for $target${RESET}"
}

# Remove override
remove_override() {
    local flag="$1"
    local target="$2"

    sqlite3 "$FLAGS_DB" "DELETE FROM overrides WHERE flag = '$flag' AND target = '$target'"

    echo -e "${GREEN}Removed override for $flag on $target${RESET}"
}

# Log change
log_change() {
    local flag="$1"
    local action="$2"
    local old="$3"
    local new="$4"

    sqlite3 "$FLAGS_DB" "
        INSERT INTO flag_history (flag, action, old_value, new_value, changed_by)
        VALUES ('$flag', '$action', '$old', '$new', 'cli')
    "
}

# List all flags
list() {
    echo -e "${PINK}=== FEATURE FLAGS ===${RESET}"
    echo

    sqlite3 "$FLAGS_DB" "
        SELECT name, description, enabled, percentage FROM flags ORDER BY name
    " | while IFS='|' read -r name desc enabled pct; do
        local status="${RED}○${RESET}"
        [ "$enabled" = "1" ] && status="${GREEN}●${RESET}"

        local pct_display=""
        [ "$pct" -lt 100 ] && pct_display=" (${pct}%)"

        printf "  %s %-25s %s%s\n" "$status" "$name" "$desc" "$pct_display"
    done
}

# Show flag details
show() {
    local name="$1"

    local flag=$(sqlite3 "$FLAGS_DB" "SELECT * FROM flags WHERE name = '$name'")

    if [ -z "$flag" ]; then
        echo -e "${RED}Flag not found: $name${RESET}"
        return 1
    fi

    echo -e "${PINK}=== FLAG: $name ===${RESET}"
    echo

    sqlite3 "$FLAGS_DB" -line "SELECT * FROM flags WHERE name = '$name'"

    echo
    echo "Overrides:"
    sqlite3 "$FLAGS_DB" "SELECT target, enabled FROM overrides WHERE flag = '$name'" | while IFS='|' read -r target enabled; do
        echo "  $target: $enabled"
    done

    echo
    echo "Recent evaluations:"
    sqlite3 "$FLAGS_DB" "
        SELECT target, result, timestamp FROM evaluations
        WHERE flag = '$name' ORDER BY timestamp DESC LIMIT 5
    " | while IFS='|' read -r target result ts; do
        echo "  $target: $result @ $ts"
    done
}

# Sync flag to all nodes
sync_flag() {
    local name="$1"

    local value=$(sqlite3 "$FLAGS_DB" "SELECT enabled FROM flags WHERE name = '$name'")

    for node in "${ALL_NODES[@]}"; do
        ssh -o ConnectTimeout=2 "$node" "mkdir -p ~/.blackroad/flags && echo '$value' > ~/.blackroad/flags/$name" 2>/dev/null &
    done
    wait
}

# Sync all flags to nodes
sync_all() {
    echo -e "${PINK}=== SYNCING FLAGS ===${RESET}"
    echo

    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=2 "$node" "mkdir -p ~/.blackroad/flags" 2>/dev/null; then
            echo "(offline)"
            continue
        fi

        sqlite3 "$FLAGS_DB" "SELECT name, enabled FROM flags" | while IFS='|' read -r name enabled; do
            ssh "$node" "echo '$enabled' > ~/.blackroad/flags/$name" 2>/dev/null
        done

        echo "synced"
    done
}

# Show history
history() {
    local flag="${1:-}"
    local limit="${2:-20}"

    echo -e "${PINK}=== FLAG HISTORY ===${RESET}"
    echo

    local where=""
    [ -n "$flag" ] && where="WHERE flag = '$flag'"

    sqlite3 "$FLAGS_DB" "
        SELECT flag, action, old_value, new_value, timestamp
        FROM flag_history $where
        ORDER BY timestamp DESC LIMIT $limit
    " | while IFS='|' read -r flag action old new ts; do
        echo "  [$ts] $flag: $action ($old -> $new)"
    done
}

# Stats
stats() {
    echo -e "${PINK}=== FLAG STATISTICS ===${RESET}"
    echo

    local total=$(sqlite3 "$FLAGS_DB" "SELECT COUNT(*) FROM flags")
    local enabled=$(sqlite3 "$FLAGS_DB" "SELECT COUNT(*) FROM flags WHERE enabled = 1")
    local evaluations=$(sqlite3 "$FLAGS_DB" "SELECT COUNT(*) FROM evaluations WHERE date(timestamp) = date('now')")

    echo "Total flags: $total"
    echo "Enabled: $enabled"
    echo "Evaluations today: $evaluations"

    echo
    echo "Most evaluated flags:"
    sqlite3 "$FLAGS_DB" "
        SELECT flag, COUNT(*) as cnt FROM evaluations
        GROUP BY flag ORDER BY cnt DESC LIMIT 5
    " | while IFS='|' read -r flag count; do
        printf "  %-25s %d evaluations\n" "$flag" "$count"
    done
}

# Export flags as JSON
export_flags() {
    sqlite3 "$FLAGS_DB" -json "SELECT name, enabled, percentage FROM flags"
}

# Import flags from JSON
import_flags() {
    local file="$1"

    echo "$(<"$file")" | jq -c '.[]' | while read -r flag; do
        local name=$(echo "$flag" | jq -r '.name')
        local enabled=$(echo "$flag" | jq -r '.enabled')
        local percentage=$(echo "$flag" | jq -r '.percentage // 100')

        sqlite3 "$FLAGS_DB" "
            INSERT OR REPLACE INTO flags (name, enabled, percentage, updated_at)
            VALUES ('$name', $enabled, $percentage, datetime('now'))
        "
    done

    echo -e "${GREEN}Imported flags from $file${RESET}"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Feature Flags${RESET}"
    echo
    echo "Dynamic feature control for the cluster"
    echo
    echo "Commands:"
    echo "  create <name> <desc> [on] [%]    Create flag"
    echo "  enable <name> [percentage]       Enable flag"
    echo "  disable <name>                   Disable flag"
    echo "  toggle <name>                    Toggle flag"
    echo "  check <name> [target]            Check if enabled"
    echo "  rollout <name> <percentage>      Set rollout %"
    echo "  override <flag> <target> <0|1>   Set override"
    echo "  list                             List all flags"
    echo "  show <name>                      Flag details"
    echo "  sync                             Sync to all nodes"
    echo "  history [flag] [limit]           View changes"
    echo "  stats                            Usage statistics"
    echo "  export                           Export as JSON"
    echo "  import <file>                    Import from JSON"
    echo
    echo "Examples:"
    echo "  $0 create new_feature 'Test new feature' 0 50"
    echo "  $0 enable new_feature 25"
    echo "  $0 check new_feature user_123"
}

# Ensure initialized
[ -f "$FLAGS_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    create|add)
        create "$2" "$3" "$4" "$5"
        ;;
    enable|on)
        enable "$2" "$3"
        ;;
    disable|off)
        disable "$2"
        ;;
    toggle)
        toggle "$2"
        ;;
    check|get)
        check "$2" "$3"
        ;;
    rollout)
        rollout "$2" "$3"
        ;;
    override)
        override "$2" "$3" "$4"
        ;;
    remove-override)
        remove_override "$2" "$3"
        ;;
    list|ls)
        list
        ;;
    show|info)
        show "$2"
        ;;
    sync)
        sync_all
        ;;
    history)
        history "$2" "$3"
        ;;
    stats)
        stats
        ;;
    export)
        export_flags
        ;;
    import)
        import_flags "$2"
        ;;
    *)
        help
        ;;
esac
