#!/bin/bash
# BlackRoad Alerting System
# Multi-channel alerts for cluster events
# Agent: Icarus (b3e01bd9)

PINK='\033[38;5;205m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

ALERT_DIR="$HOME/.blackroad/alerts"
ALERT_DB="$ALERT_DIR/alerts.db"
CONFIG_FILE="$ALERT_DIR/config.json"

ALL_NODES=("lucidia" "cecilia" "octavia" "aria" "alice")

# Alert severity levels
SEVERITY_INFO="info"
SEVERITY_WARNING="warning"
SEVERITY_ERROR="error"
SEVERITY_CRITICAL="critical"

# Initialize
init() {
    mkdir -p "$ALERT_DIR"

    sqlite3 "$ALERT_DB" << 'SQL'
CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    severity TEXT,
    source TEXT,
    title TEXT,
    message TEXT,
    acknowledged INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ack_at DATETIME,
    ack_by TEXT
);

CREATE TABLE IF NOT EXISTS rules (
    id TEXT PRIMARY KEY,
    name TEXT,
    condition TEXT,
    severity TEXT,
    channels TEXT,
    enabled INTEGER DEFAULT 1,
    cooldown INTEGER DEFAULT 300
);

CREATE INDEX IF NOT EXISTS idx_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_ack ON alerts(acknowledged);
SQL

    # Default config
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
{
    "channels": {
        "console": {"enabled": true},
        "file": {"enabled": true, "path": "~/.blackroad/alerts/alert.log"},
        "webhook": {"enabled": false, "url": ""},
        "email": {"enabled": false, "to": "", "smtp": ""},
        "slack": {"enabled": false, "webhook": ""}
    },
    "thresholds": {
        "cpu_warning": 80,
        "cpu_critical": 95,
        "mem_warning": 85,
        "mem_critical": 95,
        "disk_warning": 80,
        "disk_critical": 90,
        "temp_warning": 70,
        "temp_critical": 80
    }
}
EOF
    fi

    echo -e "${GREEN}Alerting system initialized${RESET}"
}

# Send alert
send() {
    local severity="$1"
    local source="$2"
    local title="$3"
    local message="$4"

    local timestamp=$(date -Iseconds)

    # Store in database
    sqlite3 "$ALERT_DB" "
        INSERT INTO alerts (severity, source, title, message)
        VALUES ('$severity', '$source', '$(echo "$title" | sed "s/'/''/g")', '$(echo "$message" | sed "s/'/''/g")')
    "

    local alert_id=$(sqlite3 "$ALERT_DB" "SELECT last_insert_rowid()")

    # Console output
    local color=$RESET
    case $severity in
        info) color=$BLUE ;;
        warning) color=$YELLOW ;;
        error) color=$RED ;;
        critical) color="${RED}\033[1m" ;;
    esac

    echo -e "${color}[$severity] $title${RESET}"
    echo "  Source: $source"
    echo "  Message: $message"
    echo "  Alert ID: $alert_id"

    # File logging
    echo "$timestamp [$severity] [$source] $title: $message" >> "$ALERT_DIR/alert.log"

    # Webhook
    local webhook_enabled=$(jq -r '.channels.webhook.enabled' "$CONFIG_FILE")
    local webhook_url=$(jq -r '.channels.webhook.url' "$CONFIG_FILE")

    if [ "$webhook_enabled" = "true" ] && [ -n "$webhook_url" ]; then
        curl -s -X POST "$webhook_url" \
            -H "Content-Type: application/json" \
            -d "{\"severity\":\"$severity\",\"source\":\"$source\",\"title\":\"$title\",\"message\":\"$message\",\"timestamp\":\"$timestamp\"}" \
            >/dev/null 2>&1 &
    fi

    # Slack
    local slack_enabled=$(jq -r '.channels.slack.enabled' "$CONFIG_FILE")
    local slack_webhook=$(jq -r '.channels.slack.webhook' "$CONFIG_FILE")

    if [ "$slack_enabled" = "true" ] && [ -n "$slack_webhook" ]; then
        local slack_color="good"
        [ "$severity" = "warning" ] && slack_color="warning"
        [ "$severity" = "error" ] || [ "$severity" = "critical" ] && slack_color="danger"

        curl -s -X POST "$slack_webhook" \
            -H "Content-Type: application/json" \
            -d "{\"attachments\":[{\"color\":\"$slack_color\",\"title\":\"[$severity] $title\",\"text\":\"$message\",\"footer\":\"$source\"}]}" \
            >/dev/null 2>&1 &
    fi

    echo "$alert_id"
}

# Check cluster and generate alerts
check() {
    echo -e "${PINK}=== CLUSTER HEALTH CHECK ===${RESET}"
    echo

    local thresholds=$(cat "$CONFIG_FILE")

    for node in "${ALL_NODES[@]}"; do
        echo -n "  $node: "

        if ! ssh -o ConnectTimeout=3 "$node" "echo ok" >/dev/null 2>&1; then
            send "critical" "$node" "Node Offline" "Node $node is not reachable" >/dev/null
            echo -e "${RED}OFFLINE${RESET}"
            continue
        fi

        # Get metrics
        local metrics=$(ssh "$node" "
            cpu=\$(top -bn1 | grep 'Cpu(s)' | awk '{print 100-\$8}' 2>/dev/null || echo 0)
            mem=\$(free | awk '/Mem:/ {printf \"%.0f\", \$3/\$2*100}')
            disk=\$(df / | awk 'NR==2 {gsub(/%/,\"\"); print \$5}')
            temp=\$(vcgencmd measure_temp 2>/dev/null | grep -oP '[\d.]+' || echo 0)
            echo \"\$cpu|\$mem|\$disk|\$temp\"
        " 2>/dev/null)

        local cpu=$(echo "$metrics" | cut -d'|' -f1)
        local mem=$(echo "$metrics" | cut -d'|' -f2)
        local disk=$(echo "$metrics" | cut -d'|' -f3)
        local temp=$(echo "$metrics" | cut -d'|' -f4)

        local status="OK"
        local status_color=$GREEN

        # Check CPU
        local cpu_warn=$(echo "$thresholds" | jq -r '.thresholds.cpu_warning')
        local cpu_crit=$(echo "$thresholds" | jq -r '.thresholds.cpu_critical')

        if [ "$(echo "$cpu > $cpu_crit" | bc -l)" = "1" ]; then
            send "critical" "$node" "CPU Critical" "CPU usage at ${cpu}%" >/dev/null
            status="CRITICAL"
            status_color=$RED
        elif [ "$(echo "$cpu > $cpu_warn" | bc -l)" = "1" ]; then
            send "warning" "$node" "CPU Warning" "CPU usage at ${cpu}%" >/dev/null
            status="WARNING"
            status_color=$YELLOW
        fi

        # Check Memory
        local mem_warn=$(echo "$thresholds" | jq -r '.thresholds.mem_warning')
        local mem_crit=$(echo "$thresholds" | jq -r '.thresholds.mem_critical')

        if [ "$mem" -gt "$mem_crit" ]; then
            send "critical" "$node" "Memory Critical" "Memory usage at ${mem}%" >/dev/null
            status="CRITICAL"
            status_color=$RED
        elif [ "$mem" -gt "$mem_warn" ]; then
            send "warning" "$node" "Memory Warning" "Memory usage at ${mem}%" >/dev/null
            [ "$status" != "CRITICAL" ] && status="WARNING" && status_color=$YELLOW
        fi

        # Check Disk
        local disk_warn=$(echo "$thresholds" | jq -r '.thresholds.disk_warning')
        local disk_crit=$(echo "$thresholds" | jq -r '.thresholds.disk_critical')

        if [ "$disk" -gt "$disk_crit" ]; then
            send "critical" "$node" "Disk Critical" "Disk usage at ${disk}%" >/dev/null
            status="CRITICAL"
            status_color=$RED
        elif [ "$disk" -gt "$disk_warn" ]; then
            send "warning" "$node" "Disk Warning" "Disk usage at ${disk}%" >/dev/null
            [ "$status" != "CRITICAL" ] && status="WARNING" && status_color=$YELLOW
        fi

        # Check Temperature
        local temp_warn=$(echo "$thresholds" | jq -r '.thresholds.temp_warning')
        local temp_crit=$(echo "$thresholds" | jq -r '.thresholds.temp_critical')

        if [ "$(echo "$temp > $temp_crit" | bc -l)" = "1" ]; then
            send "critical" "$node" "Temperature Critical" "Temperature at ${temp}°C" >/dev/null
            status="CRITICAL"
            status_color=$RED
        elif [ "$(echo "$temp > $temp_warn" | bc -l)" = "1" ]; then
            send "warning" "$node" "Temperature Warning" "Temperature at ${temp}°C" >/dev/null
            [ "$status" != "CRITICAL" ] && status="WARNING" && status_color=$YELLOW
        fi

        echo -e "${status_color}$status${RESET} (cpu:${cpu}% mem:${mem}% disk:${disk}% temp:${temp}°C)"
    done
}

# Monitor daemon
monitor() {
    local interval="${1:-60}"

    echo -e "${PINK}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║           🔔 ALERT MONITOR DAEMON                            ║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Check interval: ${interval}s"
    echo "Press Ctrl+C to stop"
    echo

    while true; do
        echo "[$(date '+%H:%M:%S')] Checking cluster..."
        check >/dev/null 2>&1
        sleep "$interval"
    done
}

# List alerts
list() {
    local filter="${1:-all}"
    local limit="${2:-20}"

    echo -e "${PINK}=== ALERTS ===${RESET}"
    echo

    local where=""
    case "$filter" in
        unack) where="WHERE acknowledged = 0" ;;
        ack) where="WHERE acknowledged = 1" ;;
        critical) where="WHERE severity = 'critical'" ;;
        warning) where="WHERE severity = 'warning'" ;;
    esac

    sqlite3 "$ALERT_DB" "
        SELECT id, severity, source, title, acknowledged, created_at
        FROM alerts $where
        ORDER BY created_at DESC
        LIMIT $limit
    " | while IFS='|' read -r id severity source title ack created; do
        local color=$RESET
        case $severity in
            info) color=$BLUE ;;
            warning) color=$YELLOW ;;
            error|critical) color=$RED ;;
        esac

        local ack_status=""
        [ "$ack" = "1" ] && ack_status=" [ACK]"

        printf "${color}#%-5s %-10s %-10s %s${RESET}%s\n" "$id" "[$severity]" "$source" "$title" "$ack_status"
    done
}

# Acknowledge alert
ack() {
    local alert_id="$1"
    local by="${2:-system}"

    sqlite3 "$ALERT_DB" "
        UPDATE alerts SET acknowledged = 1, ack_at = datetime('now'), ack_by = '$by'
        WHERE id = $alert_id
    "

    echo -e "${GREEN}Acknowledged alert #$alert_id${RESET}"
}

# Acknowledge all
ack_all() {
    local by="${1:-system}"

    sqlite3 "$ALERT_DB" "
        UPDATE alerts SET acknowledged = 1, ack_at = datetime('now'), ack_by = '$by'
        WHERE acknowledged = 0
    "

    echo -e "${GREEN}Acknowledged all alerts${RESET}"
}

# Stats
stats() {
    echo -e "${PINK}=== ALERT STATISTICS ===${RESET}"
    echo

    echo "By severity (last 24h):"
    sqlite3 "$ALERT_DB" "
        SELECT severity, COUNT(*)
        FROM alerts
        WHERE datetime(created_at, '+1 day') > datetime('now')
        GROUP BY severity
    " | while IFS='|' read -r severity count; do
        echo "  $severity: $count"
    done

    echo
    echo "By source (last 24h):"
    sqlite3 "$ALERT_DB" "
        SELECT source, COUNT(*)
        FROM alerts
        WHERE datetime(created_at, '+1 day') > datetime('now')
        GROUP BY source
        ORDER BY COUNT(*) DESC
        LIMIT 5
    " | while IFS='|' read -r source count; do
        echo "  $source: $count"
    done

    echo
    local unack=$(sqlite3 "$ALERT_DB" "SELECT COUNT(*) FROM alerts WHERE acknowledged = 0")
    echo "Unacknowledged: $unack"
}

# Test alert
test_alert() {
    send "info" "test" "Test Alert" "This is a test alert from the alerting system"
}

# Help
help() {
    echo -e "${PINK}BlackRoad Alerting System${RESET}"
    echo
    echo "Multi-channel alerts for cluster events"
    echo
    echo "Commands:"
    echo "  send <sev> <src> <title> <msg>  Send alert"
    echo "  check                           Check cluster health"
    echo "  monitor [interval]              Run alert daemon"
    echo "  list [filter] [limit]           List alerts"
    echo "  ack <id>                        Acknowledge alert"
    echo "  ack-all                         Acknowledge all"
    echo "  stats                           Alert statistics"
    echo "  test                            Send test alert"
    echo
    echo "Severities: info, warning, error, critical"
    echo "Filters: all, unack, ack, critical, warning"
    echo
    echo "Examples:"
    echo "  $0 send warning cecilia 'High Load' 'Load average is 8.5'"
    echo "  $0 monitor 30"
    echo "  $0 list unack"
}

# Ensure initialized
[ -f "$ALERT_DB" ] || init >/dev/null

case "${1:-help}" in
    init)
        init
        ;;
    send|alert)
        send "$2" "$3" "$4" "$5"
        ;;
    check)
        check
        ;;
    monitor|daemon)
        monitor "$2"
        ;;
    list|ls)
        list "$2" "$3"
        ;;
    ack)
        ack "$2" "$3"
        ;;
    ack-all)
        ack_all "$2"
        ;;
    stats)
        stats
        ;;
    test)
        test_alert
        ;;
    *)
        help
        ;;
esac
