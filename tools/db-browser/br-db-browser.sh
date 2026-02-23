#!/bin/zsh
# BR db-browser — Interactive SQLite browser, query runner, schema explorer

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

DB_FILE="${BR_DB:-}"
HISTORY_DB="$HOME/.blackroad/db-browser-history.db"

init_history() {
    mkdir -p "$(dirname "$HISTORY_DB")"
    sqlite3 "$HISTORY_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS query_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    db_file TEXT,
    query TEXT,
    rows_returned INTEGER,
    exec_ms REAL,
    ts TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS saved_queries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    db_file TEXT,
    query TEXT,
    description TEXT,
    created_at TEXT DEFAULT (datetime('now'))
);
SQL
}

resolve_db() {
    local arg="$1"
    # Try exact path first
    [[ -f "$arg" ]] && echo "$arg" && return
    # Try with .db extension
    [[ -f "${arg}.db" ]] && echo "${arg}.db" && return
    # Search ~/.blackroad/
    local found=$(ls "$HOME/.blackroad/${arg}.db" 2>/dev/null | head -1)
    [[ -n "$found" ]] && echo "$found" && return
    # Find in current dir
    local found2=$(find . -name "${arg}.db" -maxdepth 3 2>/dev/null | head -1)
    [[ -n "$found2" ]] && echo "$found2" && return
    echo ""
}

cmd_tables() {
    local db="$1"
    [[ -z "$db" ]] && echo -e "${RED}✗ Usage: br db-browser tables <db-file>${NC}" && return 1
    echo -e "${BOLD}${BLUE}📋 Tables${NC}: ${CYAN}$db${NC}\n"
    sqlite3 "$db" ".tables" 2>/dev/null | tr ' ' '\n' | grep -v '^$' | sort | while read -r tbl; do
        local count=$(sqlite3 "$db" "SELECT COUNT(*) FROM \"$tbl\";" 2>/dev/null)
        printf "  ${CYAN}%-30s${NC} ${BOLD}%s${NC} rows\n" "$tbl" "$count"
    done
}

cmd_schema() {
    local db="$1"
    local table="${2:-}"
    [[ -z "$db" ]] && echo -e "${RED}✗ Usage: br db-browser schema <db-file> [table]${NC}" && return 1
    echo -e "${BOLD}${BLUE}🏗 Schema${NC}: ${CYAN}$db${NC}\n"
    if [[ -n "$table" ]]; then
        echo -e "  ${BOLD}$table${NC}"
        sqlite3 "$db" "PRAGMA table_info(\"$table\");" 2>/dev/null \
            | while IFS='|' read -r cid name type notnull dflt pk; do
                local pk_mark=""; [[ "$pk" == "1" ]] && pk_mark=" ${YELLOW}PK${NC}"
                local nn_mark=""; [[ "$notnull" == "1" ]] && nn_mark=" ${RED}NOT NULL${NC}"
                printf "  ${CYAN}  %-20s${NC} %-15s${pk_mark}${nn_mark}\n" "$name" "$type"
            done
    else
        sqlite3 "$db" "SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name;" 2>/dev/null \
            | while IFS='|' read -r name sql; do
                echo -e "\n  ${BOLD}${CYAN}$name${NC}"
                echo "$sql" | sed 's/^/    /' | head -20
            done
    fi
}

cmd_query() {
    local db="$1"; shift
    local sql="$*"
    [[ -z "$db" ]] && echo -e "${RED}✗ Specify DB: br db-browser query <db-file> <sql>${NC}" && return 1
    [[ -z "$sql" ]] && echo -e "${RED}✗ Specify SQL: br db-browser query <db-file> <sql>${NC}" && return 1

    local start=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
    local result
    result=$(sqlite3 -column -header "$db" "$sql" 2>&1)
    local ec=$?
    local end=$(date +%s%3N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
    local ms=$((end - start))

    if [[ $ec -ne 0 ]]; then
        echo -e "${RED}✗ Query error:${NC}\n  $result"
        return 1
    fi

    echo -e "${BOLD}${BLUE}⚡ Query Result${NC}\n"
    echo "$result" | head -100 | while read -r line; do
        echo -e "  $line"
    done

    local rows=$(echo "$result" | grep -c '.' || echo 0)
    echo ""
    echo -e "  ${CYAN}${rows} row(s)${NC} in ${ms}ms"

    # Save to history
    sqlite3 "$HISTORY_DB" "INSERT INTO query_history (db_file, query, rows_returned, exec_ms) VALUES ('$db', '$(echo "$sql" | sed "s/'/''/g")', $rows, $ms);" 2>/dev/null
}

cmd_preview() {
    local db="$1"
    local table="$2"
    local limit="${3:-20}"
    [[ -z "$db" || -z "$table" ]] && echo -e "${RED}✗ Usage: br db-browser preview <db> <table> [limit]${NC}" && return 1
    echo -e "${BOLD}${BLUE}👁 Preview${NC}: ${CYAN}$table${NC} (first $limit rows)\n"
    sqlite3 -column -header "$db" "SELECT * FROM \"$table\" LIMIT $limit;" 2>/dev/null | while read -r line; do
        echo -e "  $line"
    done
    local total=$(sqlite3 "$db" "SELECT COUNT(*) FROM \"$table\";" 2>/dev/null)
    echo -e "\n  ${CYAN}$total${NC} total rows"
}

cmd_export() {
    local db="$1"
    local table="$2"
    local fmt="${3:-csv}"
    local out="${4:-}"
    [[ -z "$db" || -z "$table" ]] && echo -e "${RED}✗ Usage: br db-browser export <db> <table> [csv|json|sql] [file]${NC}" && return 1

    local outfile="${out:-${table}.${fmt}}"

    case "$fmt" in
        csv)
            sqlite3 -csv -header "$db" "SELECT * FROM \"$table\";" > "$outfile" 2>/dev/null
            ;;
        json)
            sqlite3 -json "$db" "SELECT * FROM \"$table\";" > "$outfile" 2>/dev/null
            ;;
        sql)
            echo "-- Export of $table from $db" > "$outfile"
            echo "-- Generated: $(date)" >> "$outfile"
            sqlite3 "$db" ".dump \"$table\"" >> "$outfile" 2>/dev/null
            ;;
        *)
            echo -e "${RED}✗ Unknown format: $fmt (use csv/json/sql)${NC}" && return 1
            ;;
    esac

    local rows=$(wc -l < "$outfile" 2>/dev/null | tr -d ' ')
    echo -e "${GREEN}✓${NC} Exported ${BOLD}$table${NC} → ${CYAN}$outfile${NC} (${rows} lines, $fmt)"
}

cmd_find() {
    # Find all SQLite DBs on the system (under home)
    echo -e "${BOLD}${BLUE}🔍 SQLite Databases Found${NC}\n"
    find "$HOME" -name "*.db" -type f 2>/dev/null | grep -v '__pycache__\|node_modules\|\.git' | head -50 | while read -r f; do
        local size=$(du -sh "$f" 2>/dev/null | cut -f1)
        local tables=$(sqlite3 "$f" ".tables" 2>/dev/null | wc -w | tr -d ' ')
        printf "  ${CYAN}%-50s${NC} ${BOLD}%4s${NC} tables  %s\n" "$f" "$tables" "$size"
    done
}

cmd_save_query() {
    local name="$1" db="$2"; shift 2
    local sql="$*"
    [[ -z "$name" || -z "$sql" ]] && echo -e "${RED}✗ Usage: br db-browser save <name> <db> <sql>${NC}" && return 1
    sqlite3 "$HISTORY_DB" "INSERT OR REPLACE INTO saved_queries (name, db_file, query) VALUES ('$name', '$db', '$(echo "$sql" | sed "s/'/''/g")');" 2>/dev/null
    echo -e "${GREEN}✓${NC} Saved query '${BOLD}$name${NC}'"
}

cmd_run_saved() {
    local name="$1"
    local row
    row=$(sqlite3 "$HISTORY_DB" "SELECT db_file, query FROM saved_queries WHERE name='$name';" 2>/dev/null)
    [[ -z "$row" ]] && echo -e "${RED}✗ Query '$name' not found${NC}" && return 1
    local db=$(echo "$row" | cut -d'|' -f1)
    local sql=$(echo "$row" | cut -d'|' -f2-)
    echo -e "${CYAN}Running:${NC} $sql\n"
    cmd_query "$db" "$sql"
}

cmd_history() {
    echo -e "${BOLD}${BLUE}📜 Query History${NC}\n"
    sqlite3 "$HISTORY_DB" "SELECT ts, db_file, exec_ms, rows_returned, query FROM query_history ORDER BY ts DESC LIMIT 20;" 2>/dev/null \
        | while IFS='|' read -r ts db ms rows sql; do
            echo -e "  ${CYAN}${ts:0:16}${NC} ${BOLD}${ms}ms${NC} ${GREEN}${rows}r${NC}  ${db##*/}"
            echo -e "    ${sql:0:80}"
        done
}

cmd_stats_db() {
    local db="$1"
    [[ -z "$db" ]] && echo -e "${RED}✗ Usage: br db-browser stats <db>${NC}" && return 1
    echo -e "${BOLD}${BLUE}📊 Database Stats${NC}: ${CYAN}$db${NC}\n"
    local size=$(du -sh "$db" 2>/dev/null | cut -f1)
    local page_count=$(sqlite3 "$db" "PRAGMA page_count;" 2>/dev/null)
    local page_size=$(sqlite3 "$db" "PRAGMA page_size;" 2>/dev/null)
    local table_count=$(sqlite3 "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null)
    local idx_count=$(sqlite3 "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='index';" 2>/dev/null)

    echo -e "  Size:      ${BOLD}$size${NC}"
    echo -e "  Tables:    ${BOLD}${table_count}${NC}"
    echo -e "  Indexes:   ${BOLD}${idx_count}${NC}"
    echo -e "  Pages:     $page_count × ${page_size}B"
    echo ""
    echo -e "  ${BOLD}Row counts:${NC}"
    sqlite3 "$db" ".tables" 2>/dev/null | tr ' ' '\n' | grep -v '^$' | sort | while read -r tbl; do
        local n=$(sqlite3 "$db" "SELECT COUNT(*) FROM \"$tbl\";" 2>/dev/null)
        printf "  %-35s ${CYAN}%d${NC} rows\n" "$tbl" "$n"
    done
}

show_help() {
    echo -e "${BOLD}${BLUE}BR db-browser${NC} — SQLite database browser\n"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}br db-browser find${NC}                        — Find all .db files"
    echo -e "  ${CYAN}br db-browser tables <db>${NC}                 — List tables + row counts"
    echo -e "  ${CYAN}br db-browser schema <db> [table]${NC}         — Show schema"
    echo -e "  ${CYAN}br db-browser preview <db> <table> [n]${NC}    — Preview rows"
    echo -e "  ${CYAN}br db-browser query <db> <sql>${NC}            — Run SQL query"
    echo -e "  ${CYAN}br db-browser stats <db>${NC}                  — Database statistics"
    echo -e "  ${CYAN}br db-browser export <db> <table> [fmt]${NC}   — Export (csv/json/sql)"
    echo -e "  ${CYAN}br db-browser save <name> <db> <sql>${NC}      — Save a query"
    echo -e "  ${CYAN}br db-browser run <name>${NC}                  — Run saved query"
    echo -e "  ${CYAN}br db-browser history${NC}                     — Query history\n"
    echo -e "${BOLD}Shortcuts:${NC}"
    echo -e "  DB path resolves automatically: 'cece' → ~/.blackroad/cece.db\n"
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  br db-browser tables ~/.blackroad/cece-identity.db"
    echo -e "  br db-browser preview cece-identity relationships 5"
    echo -e "  br db-browser query cece-identity 'SELECT * FROM skills'"
    echo -e "  br db-browser export cece-identity skills json"
    echo -e "  br db-browser find"
}

init_history

# First arg can be a DB path shortcut
case "${1:-help}" in
    find|search|ls)         cmd_find ;;
    tables|list)            cmd_tables "$(resolve_db "$2")" ;;
    schema|describe|desc)   cmd_schema "$(resolve_db "$2")" "$3" ;;
    preview|view|head)      cmd_preview "$(resolve_db "$2")" "$3" "${4:-20}" ;;
    query|sql|q)            shift; db=$(resolve_db "$1"); shift; cmd_query "$db" "$@" ;;
    stats|info)             cmd_stats_db "$(resolve_db "$2")" ;;
    export|dump)            cmd_export "$(resolve_db "$2")" "$3" "${4:-csv}" "$5" ;;
    save)                   cmd_save_query "$2" "$(resolve_db "$3")" "${@:4}" ;;
    run|exec)               cmd_run_saved "$2" ;;
    history|hist)           cmd_history ;;
    help|--help|-h)         show_help ;;
    *)                      show_help ;;
esac
