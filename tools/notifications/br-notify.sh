#!/usr/bin/env zsh
# BR Notify — Multi-channel notifications: Desktop, Slack, Webhook

# ── Brand Palette ──────────────────────────────────────────────────────────────
AMBER='\033[38;5;214m'
PINK='\033[38;5;205m'
VIOLET='\033[38;5;135m'
BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'
# compat aliases
BLUE="$BBLUE"; CYAN="$AMBER"; YELLOW="$PINK"; MAGENTA="$VIOLET"

DB_FILE="$HOME/.blackroad/notifications.db"
CONFIG_FILE="$HOME/.blackroad/notify.conf"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS channels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    type TEXT,
    config TEXT,
    enabled INTEGER DEFAULT 1,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    message TEXT,
    priority TEXT DEFAULT 'normal',
    channels TEXT,
    status TEXT DEFAULT 'pending',
    sent_at INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT,
    condition TEXT,
    channel_name TEXT,
    priority TEXT DEFAULT 'normal',
    enabled INTEGER DEFAULT 1,
    created_at INTEGER
);
EOF
}

# Send notification
cmd_send() {
    init_db
    local title="${1}"
    local message="${2}"
    local priority="${3:-normal}"
    local channels="${4:-desktop}"
    
    if [[ -z "$title" ]] || [[ -z "$message" ]]; then
        echo -e "${RED}❌ Usage: br notify send <title> <message> [priority] [channels]${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🔔 Sending notification...${NC}\n"
    
    local notif_id=$(sqlite3 "$DB_FILE" "INSERT INTO notifications (title, message, priority, channels, created_at) VALUES ('$title', '$message', '$priority', '$channels', $(date +%s)); SELECT last_insert_rowid();")
    
    # Parse channels
    IFS=',' read -ra CHANNEL_ARRAY <<< "$channels"
    
    local success=0
    local failed=0
    
    for channel in "${CHANNEL_ARRAY[@]}"; do
        echo -e "${BLUE}Sending to:${NC} $channel"
        
        case "$channel" in
            desktop)
                cmd_send_desktop "$title" "$message" "$priority"
                [[ $? -eq 0 ]] && success=$((success + 1)) || failed=$((failed + 1))
                ;;
            email)
                cmd_send_email "$title" "$message" "$priority"
                [[ $? -eq 0 ]] && success=$((success + 1)) || failed=$((failed + 1))
                ;;
            slack)
                cmd_send_slack "$title" "$message" "$priority"
                [[ $? -eq 0 ]] && success=$((success + 1)) || failed=$((failed + 1))
                ;;
            webhook)
                cmd_send_webhook "$title" "$message" "$priority"
                [[ $? -eq 0 ]] && success=$((success + 1)) || failed=$((failed + 1))
                ;;
            *)
                echo -e "${YELLOW}⚠️  Unknown channel: $channel${NC}"
                failed=$((failed + 1))
                ;;
        esac
    done
    
    echo ""
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ Notification sent to $success channel(s)${NC}"
        sqlite3 "$DB_FILE" "UPDATE notifications SET status = 'sent', sent_at = $(date +%s) WHERE id = $notif_id;"
    else
        echo -e "${YELLOW}⚠️  Partial send: $success succeeded, $failed failed${NC}"
        sqlite3 "$DB_FILE" "UPDATE notifications SET status = 'partial', sent_at = $(date +%s) WHERE id = $notif_id;"
    fi
}

# Send desktop notification
cmd_send_desktop() {
    local title="${1}"
    local message="${2}"
    local priority="${3:-normal}"

    # macOS — subtitle shows priority, sound for high/critical
    if command -v osascript &>/dev/null; then
        local sound=""
        [[ "$priority" == "high" || "$priority" == "critical" ]] && sound=' sound name "Basso"'
        local subtitle="BlackRoad OS"
        [[ "$priority" == "critical" ]] && subtitle="⚠ CRITICAL"
        [[ "$priority" == "high" ]] && subtitle="◆ HIGH PRIORITY"
        osascript -e "display notification \"$message\" with title \"$title\" subtitle \"$subtitle\"$sound" 2>/dev/null
        return $?
    fi
    # Linux
    if command -v notify-send &>/dev/null; then
        local urgency="normal"
        [[ "$priority" == "high" ]] && urgency="critical"
        notify-send -u "$urgency" "$title" "$message"
        return $?
    fi
    # Fallback
    printf "\a"
    echo -e "${AMBER}◆ ${BOLD}$title${NC}  $message"
}

# Quick critical desktop alert — br notify alert "title" "message"
cmd_alert() {
    local title="${1:-BlackRoad Alert}"
    local message="${2:-System needs attention}"
    cmd_send_desktop "$title" "$message" "critical"
    # Log it
    sqlite3 "$DB_FILE" "INSERT INTO notifications (title, message, priority, channels, status, sent_at, created_at) VALUES ('$title', '$message', 'critical', 'desktop', 'sent', $(date +%s), $(date +%s));" 2>/dev/null
    echo -e "  ${PINK}◆${NC} ${BOLD}$title${NC}  ${DIM}$message${NC}  ${DIM}→ desktop${NC}"
}

# Send email notification
cmd_send_email() {
    local title="${1}"
    local message="${2}"
    local priority="${3}"
    
    # Load config
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}⚠️  No email config (run: br notify config email)${NC}"
        return 1
    fi
    
    local email_to=$(grep "EMAIL_TO=" "$CONFIG_FILE" | cut -d= -f2)
    local email_from=$(grep "EMAIL_FROM=" "$CONFIG_FILE" | cut -d= -f2)
    
    if [[ -z "$email_to" ]]; then
        echo -e "${YELLOW}⚠️  Email not configured${NC}"
        return 1
    fi
    
    # Use mail command if available
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "$title" "$email_to"
        return $?
    fi
    
    echo -e "${YELLOW}⚠️  mail command not found${NC}"
    return 1
}

# Send Slack notification
cmd_send_slack() {
    local title="${1}"
    local message="${2}"
    local priority="${3}"
    
    # Load webhook URL
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}⚠️  No Slack config (run: br notify config slack)${NC}"
        return 1
    fi
    
    local webhook=$(grep "SLACK_WEBHOOK=" "$CONFIG_FILE" | cut -d= -f2)
    
    if [[ -z "$webhook" ]]; then
        echo -e "${YELLOW}⚠️  Slack webhook not configured${NC}"
        return 1
    fi
    
    # Send to Slack
    local payload="{\"text\":\"*$title*\n$message\"}"
    curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$webhook" > /dev/null 2>&1
    return $?
}

# Send webhook notification
cmd_send_webhook() {
    local title="${1}"
    local message="${2}"
    local priority="${3}"
    
    # Load webhook URL
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}⚠️  No webhook config (run: br notify config webhook)${NC}"
        return 1
    fi
    
    local webhook=$(grep "WEBHOOK_URL=" "$CONFIG_FILE" | cut -d= -f2)
    
    if [[ -z "$webhook" ]]; then
        echo -e "${YELLOW}⚠️  Webhook not configured${NC}"
        return 1
    fi
    
    # Send webhook
    local payload="{\"title\":\"$title\",\"message\":\"$message\",\"priority\":\"$priority\",\"timestamp\":$(date +%s)}"
    curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$webhook" > /dev/null 2>&1
    return $?
}

# Add channel
cmd_add_channel() {
    init_db
    local name="${1}"
    local type="${2}"
    
    if [[ -z "$name" ]] || [[ -z "$type" ]]; then
        echo -e "${RED}❌ Usage: br notify add-channel <name> <type>${NC}"
        echo -e "Types: desktop, email, slack, webhook"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO channels (name, type, created_at) VALUES ('$name', '$type', $(date +%s));"
    
    echo -e "${GREEN}✓ Channel added:${NC} $name ($type)"
    echo -e "${YELLOW}Configure with:${NC} br notify config $type"
}

# List channels
cmd_list_channels() {
    init_db
    echo -e "${CYAN}🔔 Notification Channels:${NC}\n"
    
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM channels;")
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No channels configured${NC}"
        echo -e "Add with: br notify add-channel <name> <type>"
        exit 0
    fi
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, type, enabled FROM channels;" | while IFS=$'\t' read -r name type enabled; do
        local icon="✓"
        [[ $enabled -eq 0 ]] && icon="✗"
        
        echo -e "$icon ${GREEN}$name${NC} ($type)"
    done
}

# Configure channel
cmd_config() {
    local type="${1}"
    
    if [[ -z "$type" ]]; then
        echo -e "${RED}❌ Usage: br notify config <type>${NC}"
        echo -e "Types: email, slack, webhook"
        exit 1
    fi
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    touch "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    
    case "$type" in
        email)
            echo -e "${CYAN}📧 Email Configuration${NC}\n"
            echo -n "Email to: "
            read email_to
            echo -n "Email from (optional): "
            read email_from
            
            grep -v "EMAIL_" "$CONFIG_FILE" > /tmp/notify.conf.tmp 2>/dev/null
            echo "EMAIL_TO=$email_to" >> /tmp/notify.conf.tmp
            [[ -n "$email_from" ]] && echo "EMAIL_FROM=$email_from" >> /tmp/notify.conf.tmp
            mv /tmp/notify.conf.tmp "$CONFIG_FILE"
            
            echo -e "\n${GREEN}✓ Email configured${NC}"
            ;;
        slack)
            echo -e "${CYAN}💬 Slack Configuration${NC}\n"
            echo -n "Webhook URL: "
            read webhook
            
            grep -v "SLACK_WEBHOOK=" "$CONFIG_FILE" > /tmp/notify.conf.tmp 2>/dev/null
            echo "SLACK_WEBHOOK=$webhook" >> /tmp/notify.conf.tmp
            mv /tmp/notify.conf.tmp "$CONFIG_FILE"
            
            echo -e "\n${GREEN}✓ Slack configured${NC}"
            ;;
        webhook)
            echo -e "${CYAN}🔗 Webhook Configuration${NC}\n"
            echo -n "Webhook URL: "
            read webhook
            
            grep -v "WEBHOOK_URL=" "$CONFIG_FILE" > /tmp/notify.conf.tmp 2>/dev/null
            echo "WEBHOOK_URL=$webhook" >> /tmp/notify.conf.tmp
            mv /tmp/notify.conf.tmp "$CONFIG_FILE"
            
            echo -e "\n${GREEN}✓ Webhook configured${NC}"
            ;;
        *)
            echo -e "${RED}❌ Unknown type: $type${NC}"
            exit 1
            ;;
    esac
}

# List notifications
cmd_list() {
    init_db
    echo -e "${CYAN}📋 Notifications History:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT title, priority, channels, status, datetime(created_at, 'unixepoch') FROM notifications ORDER BY created_at DESC LIMIT 20;" | while IFS=$'\t' read -r title priority channels stat time; do
        local icon="✓"
        [[ "$stat" == "failed" ]] && icon="✗"
        [[ "$stat" == "partial" ]] && icon="⚠"
        [[ "$stat" == "pending" ]] && icon="⏳"
        
        echo -e "$icon ${GREEN}$title${NC}"
        echo -e "  Priority: $priority | Channels: $channels"
        echo -e "  Status: $stat | $time"
        echo ""
    done
}

# Add rule
cmd_add_rule() {
    init_db
    local event="${1}"
    local channel="${2}"
    local priority="${3:-normal}"
    
    if [[ -z "$event" ]] || [[ -z "$channel" ]]; then
        echo -e "${RED}❌ Usage: br notify add-rule <event> <channel> [priority]${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO rules (event_type, channel_name, priority, created_at) VALUES ('$event', '$channel', '$priority', $(date +%s));"
    
    echo -e "${GREEN}✓ Rule added:${NC} $event → $channel ($priority)"
}

# List rules
cmd_list_rules() {
    init_db
    echo -e "${CYAN}📋 Notification Rules:${NC}\n"
    
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM rules;")
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No rules configured${NC}"
        echo -e "Add with: br notify add-rule <event> <channel>"
        exit 0
    fi
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT event_type, channel_name, priority, enabled FROM rules;" | while IFS=$'\t' read -r event channel priority enabled; do
        local icon="✓"
        [[ $enabled -eq 0 ]] && icon="✗"
        
        echo -e "$icon ${GREEN}$event${NC} → $channel ($priority)"
    done
}

# Test notification
cmd_test() {
    local channel="${1:-desktop}"
    
    echo -e "${CYAN}🧪 Testing notification...${NC}\n"
    
    cmd_send "Test Notification" "This is a test from BlackRoad CLI" "normal" "$channel"
}

# Help
cmd_help() {
    cat << 'EOF'
🔔 Notification System

USAGE:
  br notify <command> [options]

SENDING:
  send <title> <msg> [priority] [channels]  Send notification
  test [channel]                            Test notification

CHANNELS:
  add-channel <name> <type>                 Add channel
  list-channels                             List channels
  config <type>                             Configure channel

RULES:
  add-rule <event> <channel> [priority]     Add notification rule
  list-rules                                List rules

HISTORY:
  list                                      List notification history

CHANNEL TYPES:
  desktop   - System desktop notifications
  email     - Email notifications
  slack     - Slack messages
  webhook   - Custom webhook

PRIORITY LEVELS:
  critical  - Urgent, immediate attention
  high      - Important, notify soon
  normal    - Regular notification
  low       - Informational only

EXAMPLES:
  # Send desktop notification
  br notify send "Build Complete" "All tests passed!" normal desktop

  # Send to multiple channels
  br notify send "Deploy Failed" "Check logs" critical desktop,slack,email

  # Configure Slack
  br notify config slack

  # Add rule
  br notify add-rule "ci_failed" "slack" "high"

  # Test notification
  br notify test desktop

  # List history
  br notify list

INTEGRATION:
  # From CI pipeline
  br ci run myapp && br notify send "CI Success" "Build passed" || br notify send "CI Failed" "Build failed" critical

  # From tests
  br test run && br notify send "Tests Passed" "All green" || br notify send "Tests Failed" "Some failed" high

  # From deployment
  br deploy quick && br notify send "Deployed" "Live now" high

EOF
}

# Main dispatch
init_db

case "${1:-list}" in
    send|s) cmd_send "${@:2}" ;;
    alert|a) cmd_alert "${@:2}" ;;
    test|t) cmd_test "${@:2}" ;;
    add-channel|add) cmd_add_channel "${@:2}" ;;
    list-channels|channels|lc) cmd_list_channels ;;
    config|configure) cmd_config "${@:2}" ;;
    list|ls|l) cmd_list ;;
    add-rule|rule) cmd_add_rule "${@:2}" ;;
    list-rules|rules|lr) cmd_list_rules ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
