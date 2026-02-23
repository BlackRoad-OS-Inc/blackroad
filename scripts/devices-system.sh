#!/bin/bash
# [DEVICES] System - Device and Pi management for BlackRoad
# Usage: ~/devices-system.sh <command> [args]

set -e

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
RESET='\033[0m'

DEVICES_DB="$HOME/.blackroad/devices.db"

init_devices() {
    mkdir -p "$HOME/.blackroad"
    sqlite3 "$DEVICES_DB" <<EOF
CREATE TABLE IF NOT EXISTS devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,
    ip_address TEXT,
    mac_address TEXT,
    hostname TEXT,
    os TEXT,
    arch TEXT,
    cpu_cores INTEGER,
    memory_gb REAL,
    storage_gb REAL,
    location TEXT,
    role TEXT,
    ssh_user TEXT,
    ssh_port INTEGER DEFAULT 22,
    status TEXT DEFAULT 'unknown',
    last_seen TEXT,
    uptime_seconds INTEGER,
    agent_version TEXT,
    tags TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id INTEGER NOT NULL,
    cpu_percent REAL,
    memory_percent REAL,
    disk_percent REAL,
    temperature REAL,
    network_rx_bytes INTEGER,
    network_tx_bytes INTEGER,
    load_avg REAL,
    recorded_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS device_services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    port INTEGER,
    status TEXT DEFAULT 'unknown',
    last_check TEXT
);

CREATE TABLE IF NOT EXISTS device_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id INTEGER NOT NULL,
    event_type TEXT NOT NULL,
    message TEXT,
    severity TEXT DEFAULT 'info',
    occurred_at TEXT DEFAULT CURRENT_TIMESTAMP
);
EOF
    echo -e "${GREEN}[DEVICES]${RESET} System initialized"
}

# Register device
register() {
    local name="$1"
    local type="$2"
    local ip="$3"
    local role="${4:-}"
    local ssh_user="${5:-pi}"

    sqlite3 "$DEVICES_DB" "INSERT OR REPLACE INTO devices (name, type, ip_address, role, ssh_user) VALUES ('$name', '$type', '$ip', '$role', '$ssh_user');"
    echo -e "${GREEN}[DEVICES]${RESET} Registered: $name ($type) at $ip"
}

# List devices
list() {
    local filter="${1:-}"
    echo -e "${AMBER}[DEVICES]${RESET} Registered Devices"
    echo ""
    if [[ -n "$filter" ]]; then
        sqlite3 -column -header "$DEVICES_DB" "SELECT name, type, ip_address, status, role, last_seen FROM devices WHERE name LIKE '%$filter%' OR type LIKE '%$filter%' OR role LIKE '%$filter%' ORDER BY name;"
    else
        sqlite3 -column -header "$DEVICES_DB" "SELECT name, type, ip_address, status, role, last_seen FROM devices ORDER BY name;"
    fi
}

# Ping device
ping_device() {
    local name="$1"
    local ip=$(sqlite3 "$DEVICES_DB" "SELECT ip_address FROM devices WHERE name='$name';")

    if [[ -z "$ip" ]]; then
        echo -e "${RED}[DEVICES]${RESET} Device not found: $name"
        return 1
    fi

    echo -e "${BLUE}[DEVICES]${RESET} Pinging: $name ($ip)"

    if ping -c 1 -W 2 "$ip" > /dev/null 2>&1; then
        sqlite3 "$DEVICES_DB" "UPDATE devices SET status='online', last_seen=datetime('now') WHERE name='$name';"
        echo -e "${GREEN}[DEVICES]${RESET} $name: online"
    else
        sqlite3 "$DEVICES_DB" "UPDATE devices SET status='offline', last_seen=datetime('now') WHERE name='$name';"
        echo -e "${RED}[DEVICES]${RESET} $name: offline"
    fi
}

# Scan all devices
scan() {
    echo -e "${BLUE}[DEVICES]${RESET} Scanning all devices..."
    local devices=$(sqlite3 "$DEVICES_DB" "SELECT name, ip_address FROM devices;")

    echo "$devices" | while IFS='|' read -r name ip; do
        [[ -z "$name" ]] && continue
        if ping -c 1 -W 1 "$ip" > /dev/null 2>&1; then
            sqlite3 "$DEVICES_DB" "UPDATE devices SET status='online', last_seen=datetime('now') WHERE name='$name';"
            echo -e "  ${GREEN}●${RESET} $name ($ip)"
        else
            sqlite3 "$DEVICES_DB" "UPDATE devices SET status='offline' WHERE name='$name';"
            echo -e "  ${RED}○${RESET} $name ($ip)"
        fi
    done
}

# Get device details
get() {
    local name="$1"
    sqlite3 -column -header "$DEVICES_DB" "SELECT * FROM devices WHERE name='$name';"
}

# SSH to device
ssh_to() {
    local name="$1"
    local row=$(sqlite3 "$DEVICES_DB" "SELECT ip_address, ssh_user, ssh_port FROM devices WHERE name='$name';")

    if [[ -z "$row" ]]; then
        echo -e "${RED}[DEVICES]${RESET} Device not found: $name"
        return 1
    fi

    IFS='|' read -r ip user port <<< "$row"
    echo -e "${BLUE}[DEVICES]${RESET} Connecting to $name..."
    ssh -p "${port:-22}" "${user:-pi}@$ip"
}

# Record metrics
metrics() {
    local name="$1"
    local cpu="$2"
    local mem="$3"
    local disk="$4"
    local temp="${5:-}"

    local device_id=$(sqlite3 "$DEVICES_DB" "SELECT id FROM devices WHERE name='$name';")

    if [[ -z "$device_id" ]]; then
        echo -e "${RED}[DEVICES]${RESET} Device not found: $name"
        return 1
    fi

    sqlite3 "$DEVICES_DB" "INSERT INTO device_metrics (device_id, cpu_percent, memory_percent, disk_percent, temperature) VALUES ($device_id, $cpu, $mem, $disk, ${temp:-NULL});"
    echo -e "${GREEN}[DEVICES]${RESET} Metrics recorded for: $name"
}

# Show metrics
show_metrics() {
    local name="$1"
    echo -e "${AMBER}[DEVICES]${RESET} Metrics: $name"
    echo ""
    sqlite3 -column -header "$DEVICES_DB" "SELECT m.cpu_percent, m.memory_percent, m.disk_percent, m.temperature, m.recorded_at FROM device_metrics m JOIN devices d ON m.device_id=d.id WHERE d.name='$name' ORDER BY m.recorded_at DESC LIMIT 20;"
}

# Add service
add_service() {
    local device="$1"
    local service="$2"
    local port="$3"

    local device_id=$(sqlite3 "$DEVICES_DB" "SELECT id FROM devices WHERE name='$device';")

    if [[ -z "$device_id" ]]; then
        echo -e "${RED}[DEVICES]${RESET} Device not found: $device"
        return 1
    fi

    sqlite3 "$DEVICES_DB" "INSERT OR REPLACE INTO device_services (device_id, name, port) VALUES ($device_id, '$service', $port);"
    echo -e "${GREEN}[DEVICES]${RESET} Service added: $service:$port on $device"
}

# List services
services() {
    local device="${1:-}"
    echo -e "${AMBER}[DEVICES]${RESET} Device Services"
    echo ""
    if [[ -n "$device" ]]; then
        sqlite3 -column -header "$DEVICES_DB" "SELECT s.name, s.port, s.status, s.last_check FROM device_services s JOIN devices d ON s.device_id=d.id WHERE d.name='$device' ORDER BY s.name;"
    else
        sqlite3 -column -header "$DEVICES_DB" "SELECT d.name as device, s.name, s.port, s.status FROM device_services s JOIN devices d ON s.device_id=d.id ORDER BY d.name, s.name;"
    fi
}

# Log event
event() {
    local device="$1"
    local type="$2"
    local message="$3"
    local severity="${4:-info}"

    local device_id=$(sqlite3 "$DEVICES_DB" "SELECT id FROM devices WHERE name='$device';")

    if [[ -z "$device_id" ]]; then
        echo -e "${RED}[DEVICES]${RESET} Device not found: $device"
        return 1
    fi

    sqlite3 "$DEVICES_DB" "INSERT INTO device_events (device_id, event_type, message, severity) VALUES ($device_id, '$type', '$(echo "$message" | sed "s/'/''/g")', '$severity');"
    echo -e "${GREEN}[DEVICES]${RESET} Event logged: $type on $device"
}

# Show events
events() {
    local device="${1:-}"
    echo -e "${AMBER}[DEVICES]${RESET} Device Events"
    echo ""
    if [[ -n "$device" ]]; then
        sqlite3 -column -header "$DEVICES_DB" "SELECT e.event_type, e.message, e.severity, e.occurred_at FROM device_events e JOIN devices d ON e.device_id=d.id WHERE d.name='$device' ORDER BY e.occurred_at DESC LIMIT 20;"
    else
        sqlite3 -column -header "$DEVICES_DB" "SELECT d.name, e.event_type, e.severity, e.occurred_at FROM device_events e JOIN devices d ON e.device_id=d.id ORDER BY e.occurred_at DESC LIMIT 30;"
    fi
}

# Update device info
update() {
    local name="$1"
    local field="$2"
    local value="$3"

    sqlite3 "$DEVICES_DB" "UPDATE devices SET $field='$value' WHERE name='$name';"
    echo -e "${GREEN}[DEVICES]${RESET} Updated: $name.$field = $value"
}

# Delete device
delete() {
    local name="$1"
    local device_id=$(sqlite3 "$DEVICES_DB" "SELECT id FROM devices WHERE name='$name';")
    sqlite3 "$DEVICES_DB" "DELETE FROM device_events WHERE device_id=$device_id;"
    sqlite3 "$DEVICES_DB" "DELETE FROM device_services WHERE device_id=$device_id;"
    sqlite3 "$DEVICES_DB" "DELETE FROM device_metrics WHERE device_id=$device_id;"
    sqlite3 "$DEVICES_DB" "DELETE FROM devices WHERE name='$name';"
    echo -e "${GREEN}[DEVICES]${RESET} Deleted: $name"
}

# Stats
stats() {
    echo -e "${PINK}╔══════════════════════════════════════╗${RESET}"
    echo -e "${PINK}║${RESET}       ${AMBER}[DEVICES] System Stats${RESET}       ${PINK}║${RESET}"
    echo -e "${PINK}╚══════════════════════════════════════╝${RESET}"
    echo ""

    local total=$(sqlite3 "$DEVICES_DB" "SELECT COUNT(*) FROM devices;")
    local online=$(sqlite3 "$DEVICES_DB" "SELECT COUNT(*) FROM devices WHERE status='online';")
    local offline=$(sqlite3 "$DEVICES_DB" "SELECT COUNT(*) FROM devices WHERE status='offline';")
    local services=$(sqlite3 "$DEVICES_DB" "SELECT COUNT(*) FROM device_services;")
    local events=$(sqlite3 "$DEVICES_DB" "SELECT COUNT(*) FROM device_events;")
    local metrics=$(sqlite3 "$DEVICES_DB" "SELECT COUNT(*) FROM device_metrics;")

    echo -e "  ${GREEN}Total Devices:${RESET}  $total"
    echo -e "  ${GREEN}Online:${RESET}         $online"
    echo -e "  ${RED}Offline:${RESET}        $offline"
    echo -e "  ${GREEN}Services:${RESET}       $services"
    echo -e "  ${GREEN}Events:${RESET}         $events"
    echo -e "  ${GREEN}Metric Points:${RESET}  $metrics"
    echo ""
    echo -e "${BLUE}By Type:${RESET}"
    sqlite3 -column "$DEVICES_DB" "SELECT type, COUNT(*) as count FROM devices GROUP BY type ORDER BY count DESC;"
    echo ""
    echo -e "${BLUE}By Role:${RESET}"
    sqlite3 -column "$DEVICES_DB" "SELECT role, COUNT(*) as count FROM devices WHERE role IS NOT NULL AND role != '' GROUP BY role ORDER BY count DESC;"
}

show_help() {
    echo -e "${PINK}[DEVICES]${RESET} - BlackRoad Device Management"
    echo ""
    echo "Usage: ~/devices-system.sh <command> [args]"
    echo ""
    echo "Commands:"
    echo "  init                                   Initialize system"
    echo "  register <name> <type> <ip> [role]     Register device"
    echo "  list [filter]                          List devices"
    echo "  ping <name>                            Ping device"
    echo "  scan                                   Scan all devices"
    echo "  get <name>                             Show device details"
    echo "  ssh <name>                             SSH to device"
    echo "  metrics <name> <cpu> <mem> <disk>      Record metrics"
    echo "  show-metrics <name>                    Show metrics"
    echo "  add-service <device> <name> <port>     Add service"
    echo "  services [device]                      List services"
    echo "  event <device> <type> <msg> [sev]      Log event"
    echo "  events [device]                        Show events"
    echo "  update <name> <field> <value>          Update device"
    echo "  delete <name>                          Delete device"
    echo "  stats                                  Show statistics"
    echo ""
    echo "Types: pi, server, desktop, laptop, mobile, iot, vm, container"
}

case "${1:-help}" in
    init)         init_devices ;;
    register)     register "$2" "$3" "$4" "$5" "$6" ;;
    list)         list "$2" ;;
    ping)         ping_device "$2" ;;
    scan)         scan ;;
    get)          get "$2" ;;
    ssh)          ssh_to "$2" ;;
    metrics)      metrics "$2" "$3" "$4" "$5" "$6" ;;
    show-metrics) show_metrics "$2" ;;
    add-service)  add_service "$2" "$3" "$4" ;;
    services)     services "$2" ;;
    event)        event "$2" "$3" "$4" "$5" ;;
    events)       events "$2" ;;
    update)       update "$2" "$3" "$4" ;;
    delete)       delete "$2" ;;
    stats)        stats ;;
    help|*)       show_help ;;
esac
