#!/bin/zsh
# BR db-migrate — Database migration manager
# Tracks, applies, and rolls back SQL migrations

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

DB="$HOME/.blackroad/db-migrate.db"
MIGRATIONS_DIR="${2:-./migrations}"

init_db() {
    mkdir -p "$(dirname "$DB")"
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    db_url TEXT,
    migrations_dir TEXT DEFAULT './migrations',
    created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS migrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project TEXT NOT NULL,
    version TEXT NOT NULL,
    name TEXT NOT NULL,
    filename TEXT NOT NULL,
    checksum TEXT,
    applied_at TEXT,
    rolled_back_at TEXT,
    status TEXT DEFAULT 'pending',
    execution_ms INTEGER,
    UNIQUE(project, version)
);
CREATE TABLE IF NOT EXISTS migration_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project TEXT NOT NULL,
    action TEXT NOT NULL,
    version TEXT,
    details TEXT,
    ts TEXT DEFAULT (datetime('now'))
);
SQL
}

cmd_init() {
    local project="${1:-default}"
    local dir="${2:-./migrations}"
    mkdir -p "$dir"
    sqlite3 "$DB" "INSERT OR REPLACE INTO projects (name, migrations_dir) VALUES ('$project', '$dir');"
    # Create example migration
    local ts=$(date +%Y%m%d%H%M%S)
    cat > "$dir/V${ts}__initial_schema.sql" <<'MIGRATION'
-- Migration: Initial schema
-- Version: auto-generated
-- Run: br db-migrate apply

-- Example: CREATE TABLE users (id SERIAL PRIMARY KEY, email TEXT UNIQUE);
MIGRATION
    echo -e "${GREEN}✓${NC} Initialized project '${BOLD}$project${NC}' → $dir"
    echo -e "  Created: $dir/V${ts}__initial_schema.sql"
}

cmd_new() {
    local name="${1:-migration}"
    local dir="${MIGRATIONS_DIR}"
    [[ ! -d "$dir" ]] && dir="./migrations" && mkdir -p "$dir"
    local ts=$(date +%Y%m%d%H%M%S)
    # Sanitize name
    local safe_name=$(echo "$name" | tr ' ' '_' | tr -dc '[:alnum:]_')
    local filename="V${ts}__${safe_name}.sql"
    cat > "$dir/$filename" <<MIGRATION
-- Migration: $name
-- Version: V${ts}
-- Created: $(date)
-- 
-- Write your UP migration below.
-- For rollback, create a corresponding V${ts}__${safe_name}.down.sql

-- UP:
MIGRATION
    echo -e "${GREEN}✓${NC} Created: $dir/$filename"
}

cmd_status() {
    local project="${1:-default}"
    echo -e "${BOLD}${BLUE}📊 Migration Status${NC} — project: ${CYAN}$project${NC}\n"

    local dir
    dir=$(sqlite3 "$DB" "SELECT migrations_dir FROM projects WHERE name='$project';" 2>/dev/null)
    [[ -z "$dir" ]] && dir="./migrations"

    if [[ ! -d "$dir" ]]; then
        echo -e "  ${YELLOW}No migrations directory found: $dir${NC}"
        echo -e "  Run: ${CYAN}br db-migrate init $project${NC}"
        return
    fi

    # Scan filesystem for migrations
    local files=()
    if ls "$dir"/V*.sql 2>/dev/null | grep -qv '\.down\.sql$'; then
        while IFS= read -r f; do
            [[ "$f" == *".down.sql" ]] && continue
            files+=("$f")
        done < <(ls -1 "$dir"/V*.sql 2>/dev/null | grep -v '\.down\.sql$' | sort)
    fi

    if [[ ${#files[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No migrations found in $dir${NC}"
        return
    fi

    printf "  %-8s %-28s %-10s %s\n" "Version" "Name" "Status" "Applied"
    echo "  ────────────────────────────────────────────────────────"

    for f in "${files[@]}"; do
        local basename=$(basename "$f" .sql)
        local version=$(echo "$basename" | sed 's/^V\([0-9]*\)__.*/\1/')
        local migname=$(echo "$basename" | sed 's/^V[0-9]*__//' | tr '_' ' ')
        local row
        row=$(sqlite3 "$DB" "SELECT status, applied_at FROM migrations WHERE project='$project' AND version='$version';" 2>/dev/null)
        local mstatus=$(echo "$row" | cut -d'|' -f1)
        local applied=$(echo "$row" | cut -d'|' -f2)
        [[ -z "$mstatus" ]] && mstatus="pending"

        local sc="$YELLOW"
        local icon="○"
        [[ "$mstatus" == "applied" ]] && sc="$GREEN" && icon="✓"
        [[ "$mstatus" == "failed" ]] && sc="$RED" && icon="✗"
        [[ "$mstatus" == "rolled_back" ]] && sc="$CYAN" && icon="↩"

        printf "  ${sc}${icon}${NC} %-8s %-28s ${sc}%-10s${NC} %s\n" \
            "V$version" "${migname:0:27}" "$mstatus" "${applied:-—}"
    done
    echo ""
    local total=${#files[@]}
    local applied=$(sqlite3 "$DB" "SELECT COUNT(*) FROM migrations WHERE project='$project' AND status='applied';" 2>/dev/null)
    echo -e "  ${applied:-0}/${total} migrations applied"
}

cmd_apply() {
    local project="${1:-default}"
    local target="${2:-}"  # specific version or 'all'
    echo -e "${BOLD}${GREEN}🚀 Applying migrations${NC} — project: ${CYAN}$project${NC}\n"

    local dir
    dir=$(sqlite3 "$DB" "SELECT migrations_dir FROM projects WHERE name='$project';" 2>/dev/null)
    [[ -z "$dir" ]] && dir="./migrations"
    [[ ! -d "$dir" ]] && echo -e "${RED}✗ No migrations directory: $dir${NC}" && return 1

    local applied_count=0
    local files=()
    while IFS= read -r f; do
        [[ "$f" == *".down.sql" ]] && continue
        files+=("$f")
    done < <(ls -1 "$dir"/V*.sql 2>/dev/null | grep -v '\.down\.sql$' | sort)

    for f in "${files[@]}"; do
        local basename=$(basename "$f" .sql)
        local version=$(echo "$basename" | sed 's/^V\([0-9]*\)__.*/\1/')
        local migname=$(echo "$basename" | sed 's/^V[0-9]*__//' | tr '_' ' ')

        # Skip if already applied
        local existing
        existing=$(sqlite3 "$DB" "SELECT status FROM migrations WHERE project='$project' AND version='$version';" 2>/dev/null)
        [[ "$existing" == "applied" ]] && continue

        # Skip if targeting specific version
        [[ -n "$target" && "$target" != "all" && "$target" != "$version" ]] && continue

        local checksum=$(shasum "$f" 2>/dev/null | cut -d' ' -f1)
        local start=$(date +%s%3N)

        echo -e "  ${CYAN}▶${NC} Applying V${version}: $migname"

        # Check if DB_URL is set for real execution
        local db_url
        db_url=$(sqlite3 "$DB" "SELECT db_url FROM projects WHERE name='$project';" 2>/dev/null)

        local migration_ok=true
        if [[ -n "$db_url" ]]; then
            if command -v psql &>/dev/null && [[ "$db_url" == postgres* ]]; then
                psql "$db_url" -f "$f" 2>&1 || migration_ok=false
            elif command -v sqlite3 &>/dev/null && [[ "$db_url" == sqlite:* ]]; then
                sqlite3 "${db_url#sqlite:}" < "$f" 2>&1 || migration_ok=false
            else
                echo -e "    ${YELLOW}⚠ No DB driver for $db_url — tracking only${NC}"
            fi
        else
            echo -e "    ${YELLOW}⚠ No DB_URL set — tracking migration only${NC}"
            echo -e "    Set with: ${CYAN}br db-migrate config $project --db-url <url>${NC}"
        fi

        local end=$(date +%s%3N)
        local elapsed=$((end - start))
        local new_status="applied"
        $migration_ok || new_status="failed"

        sqlite3 "$DB" "INSERT OR REPLACE INTO migrations (project, version, name, filename, checksum, applied_at, status, execution_ms)
            VALUES ('$project', '$version', '$migname', '$basename', '$checksum', datetime('now'), '$new_status', $elapsed);"
        sqlite3 "$DB" "INSERT INTO migration_log (project, action, version, details) VALUES ('$project', 'apply', '$version', '$new_status in ${elapsed}ms');"

        if $migration_ok; then
            echo -e "    ${GREEN}✓${NC} Applied in ${elapsed}ms"
            ((applied_count++))
        else
            echo -e "    ${RED}✗${NC} Failed"
            break
        fi
    done

    echo ""
    echo -e "  ${GREEN}✓${NC} $applied_count migration(s) applied"
}

cmd_rollback() {
    local project="${1:-default}"
    local steps="${2:-1}"
    echo -e "${BOLD}${YELLOW}↩ Rolling back${NC} $steps step(s) — project: ${CYAN}$project${NC}\n"

    local dir
    dir=$(sqlite3 "$DB" "SELECT migrations_dir FROM projects WHERE name='$project';" 2>/dev/null)
    [[ -z "$dir" ]] && dir="./migrations"

    local i=0
    while IFS='|' read -r version migname; do
        [[ $i -ge $steps ]] && break
        echo -e "  ${CYAN}↩${NC} Rolling back V${version}: $migname"

        local down_file="$dir/V${version}"
        # Find the down file
        local full_down=$(ls "$dir"/V${version}__*.down.sql 2>/dev/null | head -1)
        if [[ -f "$full_down" ]]; then
            local db_url
            db_url=$(sqlite3 "$DB" "SELECT db_url FROM projects WHERE name='$project';" 2>/dev/null)
            if [[ -n "$db_url" ]] && command -v psql &>/dev/null; then
                psql "$db_url" -f "$full_down"
            else
                echo -e "    ${YELLOW}⚠ No DB_URL — marking rolled back only${NC}"
            fi
        else
            echo -e "    ${YELLOW}⚠ No down migration found — marking rolled back${NC}"
        fi

        sqlite3 "$DB" "UPDATE migrations SET status='rolled_back', rolled_back_at=datetime('now') WHERE project='$project' AND version='$version';"
        sqlite3 "$DB" "INSERT INTO migration_log (project, action, version) VALUES ('$project', 'rollback', '$version');"
        echo -e "    ${GREEN}✓${NC} Rolled back"
        ((i++))
    done < <(sqlite3 "$DB" "SELECT version, name FROM migrations WHERE project='$project' AND status='applied' ORDER BY version DESC LIMIT $steps;" 2>/dev/null)

    [[ $i -eq 0 ]] && echo -e "  ${YELLOW}No applied migrations to roll back${NC}"
}

cmd_config() {
    local project="${1:-default}"
    shift || true
    local db_url=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --db-url) db_url="$2"; shift 2 ;;
            --dir)    local mdir="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    sqlite3 "$DB" "INSERT OR REPLACE INTO projects (name, db_url, migrations_dir) VALUES ('$project', '${db_url:-}', '${mdir:-./migrations}');"
    echo -e "${GREEN}✓${NC} Config saved for project '${BOLD}$project${NC}'"
    [[ -n "$db_url" ]] && echo -e "  DB URL: $db_url"
}

cmd_history() {
    local project="${1:-default}"
    echo -e "${BOLD}${BLUE}📜 Migration History${NC} — $project\n"
    sqlite3 -separator '  ' "$DB" \
        "SELECT ts, action, version, details FROM migration_log WHERE project='$project' ORDER BY ts DESC LIMIT 20;" 2>/dev/null \
        | while IFS='  ' read -r ts action ver details; do
            local color="$GREEN"
            [[ "$action" == "rollback" ]] && color="$YELLOW"
            [[ "$action" == "failed" ]] && color="$RED"
            echo -e "  ${color}${ts}${NC}  ${BOLD}${action}${NC}  ${CYAN}V${ver}${NC}  ${details}"
        done
}

show_help() {
    echo -e "${BOLD}${BLUE}BR db-migrate${NC} — Database migration manager\n"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}br db-migrate init <project> [dir]${NC}    — Initialize project"
    echo -e "  ${CYAN}br db-migrate new <name>${NC}              — Create new migration file"
    echo -e "  ${CYAN}br db-migrate status [project]${NC}        — Show migration status"
    echo -e "  ${CYAN}br db-migrate apply [project]${NC}         — Apply pending migrations"
    echo -e "  ${CYAN}br db-migrate rollback [project] [n]${NC}  — Roll back N migrations"
    echo -e "  ${CYAN}br db-migrate config <project> --db-url <url>${NC}"
    echo -e "  ${CYAN}br db-migrate history [project]${NC}       — Migration history\n"
    echo -e "${BOLD}DB URL formats:${NC}"
    echo -e "  postgres://user:pass@host:5432/dbname"
    echo -e "  sqlite:/path/to/database.db\n"
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  br db-migrate init myapp ./db/migrations"
    echo -e "  br db-migrate new create_users_table"
    echo -e "  br db-migrate apply myapp"
    echo -e "  br db-migrate rollback myapp 2"
}

init_db
case "${1:-help}" in
    init)     cmd_init "$2" "$3" ;;
    new|create) cmd_new "${2:-migration}" ;;
    status|ls) cmd_status "${2:-default}" ;;
    apply|up|run) cmd_apply "${2:-default}" "$3" ;;
    rollback|down|undo) cmd_rollback "${2:-default}" "${3:-1}" ;;
    config|set) shift; cmd_config "$@" ;;
    history|log) cmd_history "${2:-default}" ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
