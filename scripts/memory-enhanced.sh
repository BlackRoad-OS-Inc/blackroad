#!/bin/bash
# BlackRoad Memory Enhanced System v2.0
# Erebus Enhancement Session - Feb 2026
#
# Addresses:
# - Task marketplace overflow (143K+ files → SQLite)
# - Journal compression/archival
# - Memory health monitoring
# - Enhanced query capabilities

set -e

MEMORY_DIR="$HOME/.blackroad/memory"
JOURNAL_DIR="$MEMORY_DIR/journals"
TASKS_DIR="$MEMORY_DIR/tasks"
ARCHIVE_DIR="$MEMORY_DIR/archive"
DB_FILE="$MEMORY_DIR/memory-enhanced.db"

# Colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
CYAN='\033[38;5;51m'
RESET='\033[0m'

#═══════════════════════════════════════════════════════════════
# INITIALIZATION
#═══════════════════════════════════════════════════════════════

init_enhanced_memory() {
    mkdir -p "$ARCHIVE_DIR" "$MEMORY_DIR/health" "$MEMORY_DIR/indexes"

    # Create enhanced SQLite database
    sqlite3 "$DB_FILE" << 'EOF'
-- Tasks table (migrated from flat files)
CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT DEFAULT 'medium',
    tags TEXT,
    skills TEXT,
    status TEXT DEFAULT 'available',
    created_at TEXT DEFAULT (datetime('now')),
    claimed_by TEXT,
    claimed_at TEXT,
    completed_at TEXT,
    completion_summary TEXT
);

-- Journal index for fast queries
CREATE TABLE IF NOT EXISTS journal_index (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT,
    action TEXT,
    entity TEXT,
    hash TEXT,
    line_number INTEGER,
    UNIQUE(hash)
);

-- Memory health snapshots
CREATE TABLE IF NOT EXISTS health_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT DEFAULT (datetime('now')),
    journal_entries INTEGER,
    journal_size_mb REAL,
    task_count INTEGER,
    active_agents INTEGER,
    til_count INTEGER,
    memory_health_score INTEGER
);

-- Agent activity tracking
CREATE TABLE IF NOT EXISTS agent_activity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,
    action TEXT,
    entity TEXT,
    timestamp TEXT DEFAULT (datetime('now')),
    session_id TEXT
);

-- Archived entries reference
CREATE TABLE IF NOT EXISTS archives (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    archive_name TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    entries_count INTEGER,
    compressed_size_mb REAL,
    date_range_start TEXT,
    date_range_end TEXT
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_journal_action ON journal_index(action);
CREATE INDEX IF NOT EXISTS idx_journal_entity ON journal_index(entity);
CREATE INDEX IF NOT EXISTS idx_agent_activity_agent ON agent_activity(agent_id);
EOF

    echo -e "${GREEN}✅ Enhanced memory system initialized${RESET}"
}

#═══════════════════════════════════════════════════════════════
# TASK MARKETPLACE MIGRATION
#═══════════════════════════════════════════════════════════════

migrate_tasks_to_sqlite() {
    echo -e "${PINK}🔄 Migrating tasks to SQLite...${RESET}"

    local count=0
    local total=$(ls -1 "$TASKS_DIR/available/" 2>/dev/null | wc -l | tr -d ' ')

    echo -e "${CYAN}Found $total tasks to migrate${RESET}"

    # Process in batches for performance
    sqlite3 "$DB_FILE" "BEGIN TRANSACTION;"

    for file in "$TASKS_DIR/available"/*.json; do
        [[ -f "$file" ]] || continue

        local task_id=$(jq -r '.task_id // .id // empty' "$file" 2>/dev/null)
        local title=$(jq -r '.title // "Untitled"' "$file" 2>/dev/null)
        local description=$(jq -r '.description // ""' "$file" 2>/dev/null | sed "s/'/''/g")
        local priority=$(jq -r '.priority // "medium"' "$file" 2>/dev/null)
        local tags=$(jq -r '.tags // ""' "$file" 2>/dev/null)
        local skills=$(jq -r '.skills // ""' "$file" 2>/dev/null)
        local created_at=$(jq -r '.created_at // .timestamp // empty' "$file" 2>/dev/null)

        if [[ -n "$task_id" ]]; then
            sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO tasks (id, title, description, priority, tags, skills, status, created_at) VALUES ('$task_id', '$(echo "$title" | sed "s/'/''/g")', '$description', '$priority', '$tags', '$skills', 'available', '$created_at');" 2>/dev/null
            ((count++))
        fi

        # Commit every 1000 records
        if (( count % 1000 == 0 )); then
            sqlite3 "$DB_FILE" "COMMIT; BEGIN TRANSACTION;"
            echo -e "  ${CYAN}Migrated $count / $total${RESET}"
        fi
    done

    sqlite3 "$DB_FILE" "COMMIT;"
    echo -e "${GREEN}✅ Migrated $count tasks to SQLite${RESET}"
}

cleanup_flat_file_tasks() {
    echo -e "${AMBER}⚠️  Cleaning up flat file tasks...${RESET}"

    # Archive first, then clean
    local archive_name="tasks-archive-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$ARCHIVE_DIR/$archive_name"

    # Move files in batches
    local moved=0
    for dir in available completed claimed; do
        if [[ -d "$TASKS_DIR/$dir" ]]; then
            local count=$(ls -1 "$TASKS_DIR/$dir" 2>/dev/null | wc -l | tr -d ' ')
            if [[ $count -gt 0 ]]; then
                # Create tar archive
                tar -czf "$ARCHIVE_DIR/$archive_name/${dir}.tar.gz" -C "$TASKS_DIR" "$dir" 2>/dev/null || true
                echo -e "  ${CYAN}Archived $count files from $dir${RESET}"
                moved=$((moved + count))
            fi
        fi
    done

    echo -e "${GREEN}✅ Archived $moved task files${RESET}"
    echo -e "${AMBER}Run 'rm -rf $TASKS_DIR/{available,completed,claimed}/*' to free space${RESET}"
}

#═══════════════════════════════════════════════════════════════
# JOURNAL COMPRESSION
#═══════════════════════════════════════════════════════════════

compress_journal() {
    local days_to_keep="${1:-30}"
    local journal_file="$JOURNAL_DIR/master-journal.jsonl"

    echo -e "${PINK}📦 Compressing journal entries older than $days_to_keep days...${RESET}"

    if [[ ! -f "$journal_file" ]]; then
        echo -e "${RED}❌ Journal file not found${RESET}"
        return 1
    fi

    local total_lines=$(wc -l < "$journal_file" | tr -d ' ')
    local cutoff_date=$(date -v-${days_to_keep}d +%Y-%m-%d 2>/dev/null || date -d "-${days_to_keep} days" +%Y-%m-%d)
    local archive_name="journal-archive-$(date +%Y%m%d-%H%M%S)"

    # Extract old entries
    local archive_file="$ARCHIVE_DIR/${archive_name}.jsonl"
    local temp_current="$JOURNAL_DIR/current-temp.jsonl"

    # Split journal: old entries to archive, recent to temp
    while IFS= read -r line; do
        local entry_date=$(echo "$line" | jq -r '.timestamp // .created_at // ""' 2>/dev/null | cut -d'T' -f1)
        if [[ "$entry_date" < "$cutoff_date" ]]; then
            echo "$line" >> "$archive_file"
        else
            echo "$line" >> "$temp_current"
        fi
    done < "$journal_file"

    if [[ -f "$archive_file" ]]; then
        local archived_lines=$(wc -l < "$archive_file" | tr -d ' ')

        # Compress the archive
        gzip "$archive_file"
        local compressed_size=$(du -h "$archive_file.gz" | cut -f1)

        # Record in database
        sqlite3 "$DB_FILE" "INSERT INTO archives (archive_name, entries_count, compressed_size_mb, date_range_end) VALUES ('$archive_name', $archived_lines, 0, '$cutoff_date');"

        # Replace journal with current entries
        if [[ -f "$temp_current" ]]; then
            mv "$temp_current" "$journal_file"
        fi

        local remaining=$(wc -l < "$journal_file" | tr -d ' ')
        echo -e "${GREEN}✅ Archived $archived_lines entries ($compressed_size compressed)${RESET}"
        echo -e "${CYAN}   Journal now has $remaining entries${RESET}"
    else
        echo -e "${CYAN}No entries older than $days_to_keep days${RESET}"
        rm -f "$temp_current"
    fi
}

index_journal() {
    echo -e "${PINK}📇 Building journal index...${RESET}"

    local journal_file="$JOURNAL_DIR/master-journal.jsonl"
    local line_num=0

    sqlite3 "$DB_FILE" "DELETE FROM journal_index;"
    sqlite3 "$DB_FILE" "BEGIN TRANSACTION;"

    while IFS= read -r line; do
        ((line_num++))
        local timestamp=$(echo "$line" | jq -r '.timestamp // ""' 2>/dev/null)
        local action=$(echo "$line" | jq -r '.action // ""' 2>/dev/null)
        local entity=$(echo "$line" | jq -r '.entity // ""' 2>/dev/null)
        local hash=$(echo "$line" | jq -r '.hash // ""' 2>/dev/null)

        if [[ -n "$action" ]]; then
            sqlite3 "$DB_FILE" "INSERT OR IGNORE INTO journal_index (timestamp, action, entity, hash, line_number) VALUES ('$timestamp', '$action', '$(echo "$entity" | sed "s/'/''/g")', '$hash', $line_num);"
        fi

        if (( line_num % 5000 == 0 )); then
            sqlite3 "$DB_FILE" "COMMIT; BEGIN TRANSACTION;"
            echo -e "  ${CYAN}Indexed $line_num entries...${RESET}"
        fi
    done < "$journal_file"

    sqlite3 "$DB_FILE" "COMMIT;"
    echo -e "${GREEN}✅ Indexed $line_num journal entries${RESET}"
}

#═══════════════════════════════════════════════════════════════
# MEMORY HEALTH
#═══════════════════════════════════════════════════════════════

check_health() {
    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}          ${CYAN}🧠 MEMORY SYSTEM HEALTH REPORT${RESET}             ${PINK}║${RESET}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Journal stats
    local journal_file="$JOURNAL_DIR/master-journal.jsonl"
    local journal_entries=$(wc -l < "$journal_file" 2>/dev/null | tr -d ' ' || echo "0")
    local journal_size=$(du -h "$journal_file" 2>/dev/null | cut -f1 || echo "0")

    # Task stats from SQLite
    local task_available=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status='available';" 2>/dev/null || echo "0")
    local task_claimed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status='claimed';" 2>/dev/null || echo "0")
    local task_completed=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status='completed';" 2>/dev/null || echo "0")

    # Flat file counts (legacy)
    local flat_available=$(ls -1 "$TASKS_DIR/available/" 2>/dev/null | wc -l | tr -d ' ')
    local flat_completed=$(ls -1 "$TASKS_DIR/completed/" 2>/dev/null | wc -l | tr -d ' ')

    # Active agents
    local active_agents=$(ls -1 "$MEMORY_DIR/active-agents/" 2>/dev/null | wc -l | tr -d ' ')

    # TIL count
    local til_count=$(ls -1 "$MEMORY_DIR/til/" 2>/dev/null | wc -l | tr -d ' ')

    # Archives
    local archive_count=$(ls -1 "$ARCHIVE_DIR" 2>/dev/null | wc -l | tr -d ' ')
    local archive_size=$(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1 || echo "0")

    # Health score calculation
    local health_score=100

    # Penalize for flat file overflow
    if [[ $flat_available -gt 10000 ]]; then
        health_score=$((health_score - 20))
    fi
    if [[ $flat_available -gt 50000 ]]; then
        health_score=$((health_score - 30))
    fi

    # Penalize for large uncompressed journal
    if [[ $journal_entries -gt 100000 ]]; then
        health_score=$((health_score - 10))
    fi

    # Bonus for using SQLite
    if [[ $task_available -gt 0 ]] || [[ $task_completed -gt 0 ]]; then
        health_score=$((health_score + 10))
    fi

    # Cap at 100
    [[ $health_score -gt 100 ]] && health_score=100
    [[ $health_score -lt 0 ]] && health_score=0

    # Display
    echo -e "  ${CYAN}📔 Journal${RESET}"
    echo -e "     Entries: ${GREEN}$journal_entries${RESET}"
    echo -e "     Size:    ${GREEN}$journal_size${RESET}"
    echo ""
    echo -e "  ${CYAN}📋 Tasks (SQLite)${RESET}"
    echo -e "     Available: ${GREEN}$task_available${RESET}"
    echo -e "     Claimed:   ${AMBER}$task_claimed${RESET}"
    echo -e "     Completed: ${BLUE}$task_completed${RESET}"
    echo ""
    echo -e "  ${CYAN}📁 Tasks (Legacy Flat Files)${RESET}"
    if [[ $flat_available -gt 10000 ]]; then
        echo -e "     Available: ${RED}$flat_available${RESET} ⚠️  NEEDS MIGRATION"
    else
        echo -e "     Available: ${GREEN}$flat_available${RESET}"
    fi
    echo -e "     Completed: ${BLUE}$flat_completed${RESET}"
    echo ""
    echo -e "  ${CYAN}🤖 Active Agents${RESET}: ${GREEN}$active_agents${RESET}"
    echo -e "  ${CYAN}💡 TIL Broadcasts${RESET}: ${GREEN}$til_count${RESET}"
    echo -e "  ${CYAN}📦 Archives${RESET}: ${GREEN}$archive_count${RESET} ($archive_size)"
    echo ""

    # Health score display
    local health_color=$GREEN
    if [[ $health_score -lt 70 ]]; then
        health_color=$AMBER
    fi
    if [[ $health_score -lt 50 ]]; then
        health_color=$RED
    fi

    echo -e "  ${CYAN}❤️  Health Score${RESET}: ${health_color}${health_score}/100${RESET}"
    echo ""

    # Recommendations
    if [[ $flat_available -gt 10000 ]]; then
        echo -e "  ${AMBER}⚠️  RECOMMENDATION: Run 'migrate' to move tasks to SQLite${RESET}"
    fi
    if [[ $journal_entries -gt 100000 ]]; then
        echo -e "  ${AMBER}⚠️  RECOMMENDATION: Run 'compress 30' to archive old journal entries${RESET}"
    fi

    # Save snapshot
    sqlite3 "$DB_FILE" "INSERT INTO health_snapshots (journal_entries, journal_size_mb, task_count, active_agents, til_count, memory_health_score) VALUES ($journal_entries, 0, $((task_available + task_claimed + task_completed)), $active_agents, $til_count, $health_score);"
}

#═══════════════════════════════════════════════════════════════
# ENHANCED QUERIES
#═══════════════════════════════════════════════════════════════

query_journal() {
    local query="$1"
    local limit="${2:-20}"

    echo -e "${PINK}🔍 Searching journal for: ${CYAN}$query${RESET}"
    echo ""

    # Search via index
    sqlite3 -header -column "$DB_FILE" "
        SELECT timestamp, action, entity
        FROM journal_index
        WHERE entity LIKE '%$query%' OR action LIKE '%$query%'
        ORDER BY timestamp DESC
        LIMIT $limit;
    " 2>/dev/null || {
        # Fallback to grep
        grep -i "$query" "$JOURNAL_DIR/master-journal.jsonl" | tail -"$limit" | jq -r '"\(.timestamp) | \(.action): \(.entity)"'
    }
}

query_tasks() {
    local status="${1:-available}"
    local limit="${2:-20}"

    echo -e "${PINK}📋 Tasks with status: ${CYAN}$status${RESET}"
    echo ""

    sqlite3 -header -column "$DB_FILE" "
        SELECT id, title, priority, tags
        FROM tasks
        WHERE status='$status'
        ORDER BY
            CASE priority
                WHEN 'urgent' THEN 1
                WHEN 'high' THEN 2
                WHEN 'medium' THEN 3
                ELSE 4
            END
        LIMIT $limit;
    "
}

stats() {
    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}           ${CYAN}📊 MEMORY SYSTEM STATISTICS${RESET}               ${PINK}║${RESET}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Action distribution
    echo -e "  ${CYAN}📈 Top Actions (last 1000 entries)${RESET}"
    sqlite3 "$DB_FILE" "
        SELECT action, COUNT(*) as count
        FROM journal_index
        GROUP BY action
        ORDER BY count DESC
        LIMIT 10;
    " 2>/dev/null | while IFS='|' read -r action count; do
        printf "     %-20s %s\n" "$action" "$count"
    done
    echo ""

    # Task priority distribution
    echo -e "  ${CYAN}🎯 Task Priority Distribution${RESET}"
    sqlite3 "$DB_FILE" "
        SELECT priority, COUNT(*) as count
        FROM tasks
        GROUP BY priority
        ORDER BY count DESC;
    " 2>/dev/null | while IFS='|' read -r priority count; do
        printf "     %-15s %s\n" "$priority" "$count"
    done
    echo ""

    # Health trend
    echo -e "  ${CYAN}📉 Health Score Trend (last 5 snapshots)${RESET}"
    sqlite3 "$DB_FILE" "
        SELECT timestamp, memory_health_score
        FROM health_snapshots
        ORDER BY timestamp DESC
        LIMIT 5;
    " 2>/dev/null | while IFS='|' read -r ts score; do
        printf "     %s  %s\n" "$ts" "$score"
    done
}

#═══════════════════════════════════════════════════════════════
# MAIN
#═══════════════════════════════════════════════════════════════

show_help() {
    echo -e "${PINK}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}       ${CYAN}🧠 BLACKROAD MEMORY ENHANCED SYSTEM v2.0${RESET}        ${PINK}║${RESET}"
    echo -e "${PINK}╚════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${GREEN}Commands:${RESET}"
    echo -e "    ${CYAN}init${RESET}              Initialize enhanced memory system"
    echo -e "    ${CYAN}health${RESET}            Check system health"
    echo -e "    ${CYAN}stats${RESET}             Show statistics"
    echo -e "    ${CYAN}migrate${RESET}           Migrate flat file tasks to SQLite"
    echo -e "    ${CYAN}cleanup${RESET}           Archive old flat files"
    echo -e "    ${CYAN}compress [days]${RESET}   Archive journal entries older than N days"
    echo -e "    ${CYAN}index${RESET}             Build journal search index"
    echo -e "    ${CYAN}query <term>${RESET}      Search journal"
    echo -e "    ${CYAN}tasks [status]${RESET}    List tasks by status"
    echo ""
}

case "${1:-help}" in
    init)
        init_enhanced_memory
        ;;
    health)
        check_health
        ;;
    stats)
        stats
        ;;
    migrate)
        migrate_tasks_to_sqlite
        ;;
    cleanup)
        cleanup_flat_file_tasks
        ;;
    compress)
        compress_journal "${2:-30}"
        ;;
    index)
        index_journal
        ;;
    query)
        query_journal "$2" "${3:-20}"
        ;;
    tasks)
        query_tasks "${2:-available}" "${3:-20}"
        ;;
    *)
        show_help
        ;;
esac
