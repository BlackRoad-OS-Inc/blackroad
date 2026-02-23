#!/bin/zsh
# BR secret-rotation — Secret rotation tracker and reminder system
# Track when secrets expire, schedule rotations, audit history

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

DB="$HOME/.blackroad/secret-rotation.db"

init_db() {
    mkdir -p "$(dirname "$DB")"
    sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS secrets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    service TEXT,
    env TEXT DEFAULT 'production',
    type TEXT DEFAULT 'api-key',
    description TEXT,
    last_rotated TEXT,
    rotation_days INTEGER DEFAULT 90,
    expires_at TEXT,
    notify_days_before INTEGER DEFAULT 14,
    status TEXT DEFAULT 'active',
    fingerprint TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS rotation_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    secret_name TEXT NOT NULL,
    action TEXT,
    notes TEXT,
    rotated_by TEXT DEFAULT 'manual',
    ts TEXT DEFAULT (datetime('now'))
);
SQL
}

days_until() {
    local target="$1"
    local now=$(date +%s)
    local exp=$(date -j -f "%Y-%m-%d" "$target" "+%s" 2>/dev/null || date -d "$target" +%s 2>/dev/null)
    [[ -z "$exp" ]] && echo "?" && return
    echo $(( (exp - now) / 86400 ))
}

cmd_add() {
    local name="$1"; shift
    local service="" env="production" type="api-key" days=90 desc="" expires=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --service|-s)   service="$2"; shift 2 ;;
            --env|-e)       env="$2"; shift 2 ;;
            --type|-t)      type="$2"; shift 2 ;;
            --days|-d)      days="$2"; shift 2 ;;
            --desc)         desc="$2"; shift 2 ;;
            --expires)      expires="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [[ -z "$name" ]] && echo -e "${RED}✗ Name required: br secret-rotation add <name>${NC}" && return 1

    local last_rotated=$(date +%Y-%m-%d)
    [[ -z "$expires" ]] && expires=$(date -v+${days}d +%Y-%m-%d 2>/dev/null || date -d "+${days} days" +%Y-%m-%d 2>/dev/null)

    sqlite3 "$DB" "INSERT OR REPLACE INTO secrets (name, service, env, type, description, last_rotated, rotation_days, expires_at, status)
        VALUES ('$name', '${service}', '$env', '$type', '${desc}', '$last_rotated', $days, '${expires}', 'active');"
    sqlite3 "$DB" "INSERT INTO rotation_log (secret_name, action, notes) VALUES ('$name', 'added', 'Initial registration');"

    echo -e "${GREEN}✓${NC} Secret '${BOLD}$name${NC}' registered"
    echo -e "  Service: ${service:-—}  Env: $env  Type: $type"
    echo -e "  Rotates every: ${CYAN}${days} days${NC}  Next: ${CYAN}${expires}${NC}"
}

cmd_list() {
    local filter="${1:-all}"
    echo -e "${BOLD}${BLUE}🔑 Secret Rotation Status${NC}\n"

    printf "  %-28s %-14s %-10s %-12s %s\n" "Name" "Service" "Env" "Expires" "Days"
    echo "  ──────────────────────────────────────────────────────────────"

    local query="SELECT name, service, env, expires_at, rotation_days, status FROM secrets WHERE status='active' ORDER BY expires_at ASC"
    [[ "$filter" == "overdue" ]] && query="SELECT name, service, env, expires_at, rotation_days, status FROM secrets WHERE status='active' AND expires_at < date('now') ORDER BY expires_at ASC"
    [[ "$filter" == "soon" ]]    && query="SELECT name, service, env, expires_at, rotation_days, status FROM secrets WHERE status='active' AND expires_at <= date('now', '+30 days') ORDER BY expires_at ASC"

    local count=0
    sqlite3 "$DB" "$query" 2>/dev/null | while IFS='|' read -r name svc env exp days jstatus; do
        ((count++))
        local d=$(days_until "$exp")
        local color="$GREEN" icon="✓"
        if [[ "$d" =~ ^[0-9]+$ ]]; then
            [[ $d -le 30 ]] && color="$YELLOW" && icon="⚠"
            [[ $d -le 7  ]] && color="$RED" && icon="✗"
            [[ $d -le 0  ]] && color="$RED" && icon="‼" && d="OVERDUE"
        fi
        printf "  ${color}${icon}${NC} %-26s %-14s %-10s %-12s ${color}%s${NC}\n" \
            "${name:0:25}" "${svc:0:13}" "$env" "${exp:--}" "${d}d"
    done

    echo ""
    local total=$(sqlite3 "$DB" "SELECT COUNT(*) FROM secrets WHERE status='active';" 2>/dev/null)
    local overdue=$(sqlite3 "$DB" "SELECT COUNT(*) FROM secrets WHERE status='active' AND expires_at < date('now');" 2>/dev/null)
    local soon=$(sqlite3 "$DB" "SELECT COUNT(*) FROM secrets WHERE status='active' AND expires_at <= date('now', '+30 days') AND expires_at >= date('now');" 2>/dev/null)
    echo -e "  Total: ${total:-0}  ${RED}Overdue: ${overdue:-0}${NC}  ${YELLOW}Due soon (30d): ${soon:-0}${NC}"
}

cmd_rotate() {
    local name="$1"
    local notes="${2:-Manual rotation}"
    [[ -z "$name" ]] && echo -e "${RED}✗ Name required${NC}" && return 1

    local days=$(sqlite3 "$DB" "SELECT rotation_days FROM secrets WHERE name='$name';" 2>/dev/null)
    [[ -z "$days" ]] && echo -e "${RED}✗ Secret '$name' not found${NC}" && return 1

    local today=$(date +%Y-%m-%d)
    local next=$(date -v+${days}d +%Y-%m-%d 2>/dev/null || date -d "+${days} days" +%Y-%m-%d 2>/dev/null)

    sqlite3 "$DB" "UPDATE secrets SET last_rotated='$today', expires_at='$next', updated_at=datetime('now') WHERE name='$name';"
    sqlite3 "$DB" "INSERT INTO rotation_log (secret_name, action, notes) VALUES ('$name', 'rotated', '$notes');"

    echo -e "${GREEN}✓${NC} Secret '${BOLD}$name${NC}' marked as rotated"
    echo -e "  Rotated: $today  Next due: ${CYAN}$next${NC} (+${days}d)"
}

cmd_due() {
    echo -e "${BOLD}${YELLOW}⚠ Secrets Due for Rotation${NC}\n"
    local count=0
    sqlite3 "$DB" "SELECT name, service, env, expires_at FROM secrets WHERE status='active' AND expires_at <= date('now', '+30 days') ORDER BY expires_at ASC;" 2>/dev/null \
        | while IFS='|' read -r name svc env exp; do
            ((count++))
            local d=$(days_until "$exp")
            local color="$YELLOW" icon="⚠"
            [[ "$d" =~ ^[0-9]+$ ]] && [[ $d -le 0 ]] && color="$RED" && icon="‼" && d="OVERDUE"
            [[ "$d" =~ ^[0-9]+$ ]] && [[ $d -le 7 ]] && color="$RED" && icon="✗"
            echo -e "  ${color}${icon}${NC} ${BOLD}$name${NC} (${svc:-$env}) — ${color}${d}d${NC} — due: $exp"
            echo -e "    Rotate: ${CYAN}br secret-rotation rotate $name${NC}"
        done
    [[ $count -eq 0 ]] && echo -e "  ${GREEN}✓ No secrets due in next 30 days${NC}"
}

cmd_history() {
    local name="${1:-}"
    echo -e "${BOLD}${BLUE}📜 Rotation History${NC}\n"
    local query="SELECT ts, secret_name, action, notes FROM rotation_log ORDER BY ts DESC LIMIT 30"
    [[ -n "$name" ]] && query="SELECT ts, secret_name, action, notes FROM rotation_log WHERE secret_name='$name' ORDER BY ts DESC LIMIT 20"

    sqlite3 "$DB" "$query" 2>/dev/null | while IFS='|' read -r ts sname action notes; do
        local color="$GREEN"
        [[ "$action" == "overdue" ]] && color="$RED"
        echo -e "  ${CYAN}$ts${NC}  ${color}${action}${NC}  ${BOLD}$sname${NC}  $notes"
    done
}

cmd_remove() {
    local name="$1"
    sqlite3 "$DB" "UPDATE secrets SET status='archived' WHERE name='$name';"
    sqlite3 "$DB" "INSERT INTO rotation_log (secret_name, action, notes) VALUES ('$name', 'archived', 'Removed from tracking');"
    echo -e "${GREEN}✓${NC} '$name' archived"
}

cmd_import() {
    # Import from .env file — register all keys for rotation tracking
    local envfile="${1:-.env}"
    [[ ! -f "$envfile" ]] && echo -e "${RED}✗ File not found: $envfile${NC}" && return 1

    local count=0
    while IFS='=' read -r key val; do
        [[ "$key" =~ ^# ]] && continue
        [[ -z "$key" || -z "$val" ]] && continue
        # Only track likely secrets
        if echo "$key" | grep -qiE 'key|token|secret|pass|pwd|auth|cred|cert|api'; then
            local svc=$(echo "$key" | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')
            sqlite3 "$DB" "INSERT OR IGNORE INTO secrets (name, service, type, description) VALUES ('$key', '$svc', 'env-var', 'Imported from $envfile');" 2>/dev/null
            ((count++))
        fi
    done < "$envfile"
    echo -e "${GREEN}✓${NC} Imported $count secret(s) from $envfile"
}

show_help() {
    echo -e "${BOLD}${BLUE}BR secret-rotation${NC} — Secret rotation tracker\n"
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  ${CYAN}br secret-rotation add <name> [opts]${NC}   — Track a secret"
    echo -e "  ${CYAN}br secret-rotation list [filter]${NC}       — List all (all/overdue/soon)"
    echo -e "  ${CYAN}br secret-rotation due${NC}                 — Show what needs rotation"
    echo -e "  ${CYAN}br secret-rotation rotate <name>${NC}       — Mark secret as rotated"
    echo -e "  ${CYAN}br secret-rotation history [name]${NC}      — Rotation history"
    echo -e "  ${CYAN}br secret-rotation import [.env]${NC}       — Import secrets from .env"
    echo -e "  ${CYAN}br secret-rotation remove <name>${NC}       — Stop tracking\n"
    echo -e "${BOLD}Add options:${NC}"
    echo -e "  --service <svc>    Service name (github, aws, stripe...)"
    echo -e "  --days <n>         Rotation interval in days (default: 90)"
    echo -e "  --type <t>         api-key|token|password|cert|ssh-key"
    echo -e "  --env <e>          production|staging|dev\n"
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  br secret-rotation add GITHUB_TOKEN --service github --days 90"
    echo -e "  br secret-rotation add STRIPE_SECRET_KEY --service stripe --days 30"
    echo -e "  br secret-rotation rotate GITHUB_TOKEN 'Rotated during quarterly audit'"
    echo -e "  br secret-rotation import .env.production"
}

init_db
case "${1:-list}" in
    add|register|track)    shift; cmd_add "$@" ;;
    list|ls|status)        cmd_list "${2:-all}" ;;
    due|upcoming|check)    cmd_due ;;
    rotate|rotated|done)   cmd_rotate "$2" "${3:-}" ;;
    history|log|audit)     cmd_history "$2" ;;
    remove|rm|archive)     cmd_remove "$2" ;;
    import)                cmd_import "${2:-.env}" ;;
    help|--help|-h)        show_help ;;
    *)                     show_help ;;
esac
