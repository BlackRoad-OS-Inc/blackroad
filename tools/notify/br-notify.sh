#!/usr/bin/env zsh
# BR Notify — send notifications (desktop, webhook, journal) on BR events
# br notify [send|webhook|desktop|slack|watch|test|list|config]

AMBER=$'\033[38;5;214m'; PINK=$'\033[38;5;205m'; VIOLET=$'\033[38;5;135m'
CYAN=$'\033[0;36m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; NC=$'\033[0m'

BR_ROOT="${BR_ROOT:-$HOME/blackroad}"
NOTIFY_DB="$HOME/.blackroad/notify.db"
NOTIFY_CONF="$HOME/.blackroad/notify.conf"

mkdir -p "$(dirname "$NOTIFY_DB")"

init_db() {
    sqlite3 "$NOTIFY_DB" <<'SQL'
CREATE TABLE IF NOT EXISTS notifications (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    channel     TEXT,
    level       TEXT DEFAULT 'info',
    title       TEXT,
    message     TEXT,
    sent_at     TEXT DEFAULT (datetime('now')),
    status      TEXT DEFAULT 'sent'
);
CREATE TABLE IF NOT EXISTS webhooks (
    name        TEXT PRIMARY KEY,
    url         TEXT,
    enabled     INTEGER DEFAULT 1,
    created_at  TEXT DEFAULT (datetime('now'))
);
SQL
}
init_db

hr()  { echo "${DIM}────────────────────────────────────────────────────────────────────${NC}"; }
hdr() { echo; echo "${VIOLET}◈ $1${NC}"; hr; }

level_icon() {
    case "$1" in
        success|ok)  echo "✅" ;;
        warn*)       echo "⚠️ " ;;
        error|fail*) echo "❌" ;;
        deploy*)     echo "🚀" ;;
        agent*)      echo "🤖" ;;
        *)           echo "ℹ️ " ;;
    esac
}

# ── desktop notification (macOS) ─────────────────────────────────────────────
notify_desktop() {
    local title="$1" message="$2" level="${3:-info}"
    local icon
    icon=$(level_icon "$level")
    osascript -e "display notification \"$message\" with title \"$icon $title\"" 2>/dev/null && \
        echo "  ${GREEN}✓ desktop notification sent${NC}" || \
        echo "  ${DIM}(osascript not available)${NC}"
}

# ── webhook POST ────────────────────────────────────────────────────────────
notify_webhook() {
    local url="$1" title="$2" message="$3" level="${4:-info}"
    [[ -z "$url" ]] && { echo "  ${RED}No URL provided${NC}"; return 1; }

    local payload
    payload=$(python3 -c "
import json, sys, datetime
print(json.dumps({
    'text': f'{sys.argv[1]}: {sys.argv[2]}',
    'title': sys.argv[1],
    'message': sys.argv[2],
    'level': sys.argv[3],
    'source': 'blackroad-br',
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z'
}))
" "$title" "$message" "$level" 2>/dev/null)

    local code
    code=$(curl -sf -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --max-time 10 2>/dev/null)

    if [[ "$code" =~ ^2 ]]; then
        echo "  ${GREEN}✓ webhook sent (HTTP $code): $url${NC}"
    else
        echo "  ${RED}✗ webhook failed (HTTP $code): $url${NC}"
    fi
}

# ── slack-formatted webhook ─────────────────────────────────────────────────
notify_slack() {
    local url="$1" title="$2" message="$3" level="${4:-info}"
    [[ -z "$url" ]] && url="${SLACK_WEBHOOK_URL:-}"
    [[ -z "$url" ]] && { echo "  ${RED}No Slack webhook URL — set SLACK_WEBHOOK_URL or: br notify config slack <url>${NC}"; return 1; }

    local icon
    icon=$(level_icon "$level")

    local payload
    payload=$(python3 -c "
import json, sys
icon, title, msg = sys.argv[1], sys.argv[2], sys.argv[3]
print(json.dumps({'text': f'{icon} *{title}*\n{msg}'}))
" "$icon" "$title" "$message" 2>/dev/null)

    local code
    code=$(curl -sf -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        --max-time 10 2>/dev/null)

    [[ "$code" =~ ^2 ]] && \
        echo "  ${GREEN}✓ Slack sent (HTTP $code)${NC}" || \
        echo "  ${RED}✗ Slack failed (HTTP $code)${NC}"
}

# ── log to BR journal ─────────────────────────────────────────────────────────
notify_journal() {
    local title="$1" message="$2" level="${3:-info}"
    local journal="$HOME/.blackroad/memory/journals/master-journal.jsonl"
    if [[ -f "$journal" ]]; then
        local parent_hash
        parent_hash=$(tail -1 "$journal" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('sha256','0000000000000000'))" 2>/dev/null || echo "0000000000000000")
        python3 -c "
import json, hashlib, datetime, sys
ts = datetime.datetime.now(datetime.timezone.utc).isoformat()
entry = {'timestamp': ts, 'action': 'notification', 'entity': sys.argv[1],
         'details': sys.argv[2], 'level': sys.argv[3], 'parent_hash': sys.argv[4]}
raw = json.dumps(entry, sort_keys=True) + sys.argv[4]
entry['sha256'] = hashlib.sha256(raw.encode()).hexdigest()[:16]
print(json.dumps(entry))
" "$title" "$message" "$level" "$parent_hash" >> "$journal" 2>/dev/null
    fi
}

# ── send to all channels ──────────────────────────────────────────────────────
cmd_send() {
    local level="${1:-info}" title="${2:-BlackRoad}" message="${3:-Notification}"
    local icon
    icon=$(level_icon "$level")

    echo
    printf "  ${VIOLET}◈ NOTIFY${NC}  %s %s\n" "$icon" "$title"
    echo "  ${DIM}$message${NC}"
    echo

    # Desktop
    notify_desktop "$title" "$message" "$level"

    # All registered webhooks
    sqlite3 "$NOTIFY_DB" "SELECT name, url FROM webhooks WHERE enabled=1;" 2>/dev/null | \
        while IFS='|' read -r name url; do
            printf "  ${CYAN}webhook %-12s${NC} " "$name"
            notify_webhook "$url" "$title" "$message" "$level"
        done

    # Slack if configured
    local slack_url
    slack_url=$(grep "^SLACK_WEBHOOK_URL=" "$NOTIFY_CONF" 2>/dev/null | cut -d= -f2-)
    if [[ -n "$slack_url" ]]; then
        printf "  ${CYAN}slack${NC}                "
        notify_slack "$slack_url" "$title" "$message" "$level"
    fi

    # Journal
    notify_journal "$title" "$message" "$level"

    echo
}

# ── register webhook ──────────────────────────────────────────────────────────
cmd_webhook() {
    local subcmd="${1:-list}"
    case "$subcmd" in
        add)
            local name="$2" url="$3"
            [[ -z "$name" || -z "$url" ]] && { echo "  Usage: br notify webhook add <name> <url>"; return 1; }
            sqlite3 "$NOTIFY_DB" "INSERT OR REPLACE INTO webhooks (name,url) VALUES ('$name','$url');"
            echo "  ${GREEN}✓ Webhook registered: $name${NC}"
            ;;
        remove|rm)
            sqlite3 "$NOTIFY_DB" "DELETE FROM webhooks WHERE name='$2';"
            echo "  ${GREEN}✓ Removed: $2${NC}"
            ;;
        list|"")
            hdr "REGISTERED WEBHOOKS"
            sqlite3 "$NOTIFY_DB" "SELECT name, url, (CASE enabled WHEN 1 THEN 'ON' ELSE 'OFF' END) FROM webhooks;" | \
                while IFS='|' read -r name url st; do
                    printf "  %-16s  %-8s  %s\n" "$name" "$st" "$url"
                done
            echo
            ;;
    esac
}

# ── queue watcher ─────────────────────────────────────────────────────────────
cmd_watch() {
    local interval="${1:-30}"
    local prev_queue=0
    echo "  ${CYAN}Watching for events every ${interval}s — Ctrl+C to stop${NC}"
    while true; do
        local queue=0
        [[ -d "$BR_ROOT/shared/mesh/queue" ]] && \
            queue=$(ls "$BR_ROOT/shared/mesh/queue/" 2>/dev/null | wc -l | tr -d ' ')

        if [[ "$queue" -gt "$prev_queue" ]]; then
            local delta=$((queue - prev_queue))
            cmd_send "info" "Queue Update" "+${delta} new task(s) in queue (total: ${queue})"
        fi
        prev_queue=$queue
        sleep "$interval"
    done
}

# ── list recent notifications ─────────────────────────────────────────────────
cmd_list() {
    hdr "RECENT NOTIFICATIONS"
    sqlite3 "$NOTIFY_DB" \
        "SELECT sent_at, level, title, message FROM notifications ORDER BY id DESC LIMIT 20;" | \
        while IFS='|' read -r ts lvl title msg; do
            local icon
            icon=$(level_icon "$lvl")
            printf "  %s %s  ${CYAN}%-20s${NC}  ${DIM}%s${NC}\n" "$icon" "${ts:5:11}" "$title" "${msg:0:50}"
        done
    echo
}

# ── config ───────────────────────────────────────────────────────────────────
cmd_config() {
    case "$1" in
        slack)
            echo "SLACK_WEBHOOK_URL=$2" >> "$NOTIFY_CONF"
            echo "  ${GREEN}✓ Slack webhook saved${NC}"
            ;;
        show)
            echo; cat "$NOTIFY_CONF" 2>/dev/null || echo "  ${DIM}No config yet${NC}"; echo
            ;;
        *)
            echo "  Usage: br notify config slack <url>"
            ;;
    esac
}

# ── test ─────────────────────────────────────────────────────────────────────
cmd_test() {
    cmd_send "success" "BR Notify Test" "BlackRoad notification system working! 🔥"
}

show_help() {
    echo
    echo "${VIOLET}${BOLD}BR NOTIFY${NC} — multi-channel notifications"
    echo
    echo "  ${CYAN}br notify send <level> <title> <msg>${NC}  Send notification"
    echo "  ${CYAN}br notify test${NC}                        Send test notification"
    echo "  ${CYAN}br notify webhook add <name> <url>${NC}    Register webhook"
    echo "  ${CYAN}br notify webhook list${NC}                List webhooks"
    echo "  ${CYAN}br notify webhook remove <name>${NC}       Remove webhook"
    echo "  ${CYAN}br notify config slack <url>${NC}          Set Slack webhook URL"
    echo "  ${CYAN}br notify watch [seconds]${NC}             Watch queue + auto-notify"
    echo "  ${CYAN}br notify list${NC}                        Recent notifications"
    echo
    echo "  ${DIM}Levels: info  success  warn  error  deploy  agent${NC}"
    echo
}

case "${1:-help}" in
    send|notify)    shift; cmd_send "$@" ;;
    test)           cmd_test ;;
    desktop)        shift; notify_desktop "$@" ;;
    slack)          shift; notify_slack "" "$@" ;;
    webhook)        shift; cmd_webhook "$@" ;;
    watch)          cmd_watch "${2:-30}" ;;
    list|history)   cmd_list ;;
    config)         shift; cmd_config "$@" ;;
    help|--help|-h) show_help ;;
    # shorthand: br notify "message"
    *)              cmd_send "info" "BlackRoad" "$1" ;;
esac
