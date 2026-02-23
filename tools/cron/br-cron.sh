#!/usr/bin/env zsh
# BR Cron — schedule br commands to run automatically
# br cron [add|list|remove|run|log|enable|disable]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
BR_BIN="${BR_BIN:-$BR_ROOT/br}"
CRON_DB="$HOME/.blackroad/cron.db"
CRON_LOG="$HOME/.blackroad/logs/cron.log"

mkdir -p "$(dirname "$CRON_DB")" "$(dirname "$CRON_LOG")"

init_db() {
    sqlite3 "$CRON_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS schedules (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT UNIQUE,
    command     TEXT,
    schedule    TEXT,
    enabled     INTEGER DEFAULT 1,
    last_run    TEXT,
    last_status TEXT,
    run_count   INTEGER DEFAULT 0,
    created_at  TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

hr()  { echo "${DIM}────────────────────────────────────────────────────────────────────${NC}"; }
hdr() { echo; echo "${VIOLET}◈ $1${NC}"; hr; }

# ── parse human schedule to cron expression ──────────────────────────────────
parse_schedule() {
    local sched="$1"
    case "$sched" in
        hourly|"every hour")     echo "0 * * * *" ;;
        daily|"every day")       echo "0 9 * * *" ;;
        "every morning")         echo "0 8 * * *" ;;
        "every night")           echo "0 23 * * *" ;;
        "every 5min"|"5m")       echo "*/5 * * * *" ;;
        "every 15min"|"15m")     echo "*/15 * * * *" ;;
        "every 30min"|"30m")     echo "*/30 * * * *" ;;
        weekly|"every week")     echo "0 9 * * 1" ;;
        midnight)                echo "0 0 * * *" ;;
        *)                       echo "$sched" ;;  # pass through raw cron
    esac
}

# ── add a schedule ────────────────────────────────────────────────────────────
cmd_add() {
    local name="$1" cmd="$2" sched="$3"
    [[ -z "$name" || -z "$cmd" ]] && {
        echo "  Usage: br cron add <name> <br-command> [schedule]"
        echo "  Example: br cron add morning-roundup 'roundup write' daily"
        return 1
    }
    sched="${sched:-daily}"
    local cron_expr
    cron_expr=$(parse_schedule "$sched")

    sqlite3 "$CRON_DB" \
        "INSERT OR REPLACE INTO schedules (name, command, schedule) VALUES ('$name','$cmd','$cron_expr');" 2>/dev/null

    echo "  ${GREEN}✓ Scheduled: ${name}${NC}"
    echo "  ${DIM}Command:  br $cmd${NC}"
    echo "  ${DIM}Schedule: $cron_expr  (${sched})${NC}"
    echo

    # Offer to install in system cron
    local full_cmd="$BR_BIN $cmd >> $CRON_LOG 2>&1"
    echo "  To install in system cron:"
    echo "  ${DIM}echo '$cron_expr $full_cmd' | crontab -${NC}"
    echo
}

# ── install all enabled schedules into crontab ───────────────────────────────
cmd_install() {
    echo "  ${CYAN}Installing BR schedules to crontab...${NC}"

    # Read current crontab, strip old br entries
    local tmp
    tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -v "# br-cron:" > "$tmp"

    # Add enabled schedules
    local added=0
    sqlite3 "$CRON_DB" "SELECT schedule, command, name FROM schedules WHERE enabled=1;" | \
        while IFS='|' read -r sched cmd name; do
            echo "$sched $BR_BIN $cmd >> $CRON_LOG 2>&1  # br-cron: $name" >> "$tmp"
            added=$((added+1))
            printf "  ${GREEN}+${NC} %s  →  %s\n" "$name" "$sched"
        done

    crontab "$tmp" && echo "  ${GREEN}✓ Crontab updated${NC}" || echo "  ${RED}✗ crontab failed${NC}"
    rm -f "$tmp"
}

# ── remove from system cron ───────────────────────────────────────────────────
cmd_uninstall() {
    local tmp
    tmp=$(mktemp)
    crontab -l 2>/dev/null | grep -v "# br-cron:" > "$tmp"
    crontab "$tmp"
    rm -f "$tmp"
    echo "  ${GREEN}✓ All BR cron entries removed from crontab${NC}"
}

# ── list schedules ────────────────────────────────────────────────────────────
cmd_list() {
    hdr "BR SCHEDULES"
    printf "  ${DIM}%-20s  %-22s  %-16s  %-6s  %s${NC}\n" \
        "NAME" "COMMAND" "SCHEDULE" "STATUS" "LAST RUN"

    local found=0
    sqlite3 "$CRON_DB" \
        "SELECT name, command, schedule, enabled, last_run, last_status, run_count FROM schedules ORDER BY name;" | \
        while IFS='|' read -r name cmd sched enabled last_run last_status run_count; do
            found=$((found+1))
            s_col="${GREEN}ON${NC}"; [[ "$enabled" != "1" ]] && s_col="${DIM}OFF${NC}"
            r_col="${DIM}never${NC}"; [[ -n "$last_run" ]] && r_col="${DIM}${last_run:0:16}${NC}"
            printf "  %-20s  %-22s  %-16s  %b      %b  ${DIM}(${run_count}x)${NC}\n" \
                "$name" "br $cmd" "$sched" "$s_col" "$r_col"
        done

    [[ $found -eq 0 ]] && echo "  ${DIM}No schedules — br cron add <name> <command> [schedule]${NC}"
    echo

    # Show active cron entries
    local active
    active=$(crontab -l 2>/dev/null | grep "# br-cron:" | wc -l | tr -d ' ')
    printf "  ${DIM}%s installed in crontab${NC}\n" "$active"
    echo
}

# ── run a schedule now ────────────────────────────────────────────────────────
cmd_run() {
    local name="$1"
    [[ -z "$name" ]] && { echo "  Usage: br cron run <name>"; return 1; }

    local cmd
    cmd=$(sqlite3 "$CRON_DB" "SELECT command FROM schedules WHERE name='$name';" 2>/dev/null)
    [[ -z "$cmd" ]] && { echo "  ${RED}Schedule not found: $name${NC}"; return 1; }

    echo "  ${CYAN}Running: br $cmd${NC}"
    local start ts
    start=$(date +%s)
    eval "$BR_BIN $cmd" 2>&1 | tee -a "$CRON_LOG"
    local exit_code=$?
    ts=$(date '+%Y-%m-%d %H:%M:%S')
    local duration=$(( $(date +%s) - start ))

    local pstatus="success"
    [[ $exit_code -ne 0 ]] && pstatus="failed"

    sqlite3 "$CRON_DB" \
        "UPDATE schedules SET last_run='$ts', last_status='$pstatus', run_count=run_count+1 WHERE name='$name';" 2>/dev/null

    echo
    printf "  ${DIM}Duration: %ds  Exit: %d  Status: %s${NC}\n" "$duration" "$exit_code" "$pstatus"
}

# ── view logs ─────────────────────────────────────────────────────────────────
cmd_log() {
    local lines="${1:-30}"
    echo
    [[ -f "$CRON_LOG" ]] && tail -n "$lines" "$CRON_LOG" || echo "  ${DIM}No cron log yet${NC}"
}

# ── enable / disable ──────────────────────────────────────────────────────────
cmd_enable()  { sqlite3 "$CRON_DB" "UPDATE schedules SET enabled=1 WHERE name='$1';"; echo "  ${GREEN}✓ Enabled: $1${NC}"; }
cmd_disable() { sqlite3 "$CRON_DB" "UPDATE schedules SET enabled=0 WHERE name='$1';"; echo "  ${DIM}Disabled: $1${NC}"; }
cmd_remove()  { sqlite3 "$CRON_DB" "DELETE FROM schedules WHERE name='$1';"; echo "  ${GREEN}✓ Removed: $1${NC}"; }

# ── seed sensible defaults ────────────────────────────────────────────────────
cmd_defaults() {
    echo "  ${CYAN}Adding default schedules...${NC}"
    sqlite3 "$CRON_DB" <<'SQL'
INSERT OR IGNORE INTO schedules (name, command, schedule) VALUES
    ('morning-standup',  'standup save',   '0 8 * * *'),
    ('morning-roundup',  'roundup write',  '0 8 * * *'),
    ('hourly-pulse',     'pulse line',     '0 * * * *'),
    ('night-snapshot',   'snapshot save nightly', '0 23 * * *');
SQL
    cmd_list
}

show_help() {
    echo
    echo "${VIOLET}${BOLD}BR CRON${NC} — schedule br commands"
    echo
    echo "  ${CYAN}br cron list${NC}                     List all schedules"
    echo "  ${CYAN}br cron add <n> <cmd> [sched]${NC}    Add schedule"
    echo "  ${CYAN}br cron remove <name>${NC}            Remove schedule"
    echo "  ${CYAN}br cron run <name>${NC}               Run a schedule now"
    echo "  ${CYAN}br cron install${NC}                  Install all → system crontab"
    echo "  ${CYAN}br cron uninstall${NC}                Remove BR entries from crontab"
    echo "  ${CYAN}br cron enable/disable <name>${NC}    Toggle schedule"
    echo "  ${CYAN}br cron log [N]${NC}                  View cron log"
    echo "  ${CYAN}br cron defaults${NC}                 Add sensible default schedules"
    echo
    echo "  ${DIM}Schedules: hourly  daily  weekly  midnight  '*/15 * * * *'${NC}"
    echo
}

case "${1:-list}" in
    add)            shift; cmd_add "$@" ;;
    list|ls|"")     cmd_list ;;
    remove|rm|del)  cmd_remove "$2" ;;
    run|exec)       cmd_run "$2" ;;
    install)        cmd_install ;;
    uninstall)      cmd_uninstall ;;
    enable)         cmd_enable "$2" ;;
    disable)        cmd_disable "$2" ;;
    log|logs)       cmd_log "${2:-30}" ;;
    defaults|init)  cmd_defaults ;;
    help|--help|-h) show_help ;;
    *)              show_help ;;
esac
