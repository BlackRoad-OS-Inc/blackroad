#!/usr/bin/env zsh
# 📊 Metrics Dashboard - Feature #31
# Real-time system metrics, performance tracking, and visualization

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/metrics.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS system_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cpu_usage REAL,
    memory_usage REAL,
    disk_usage REAL,
    network_in REAL,
    network_out REAL,
    load_avg REAL,
    recorded_at INTEGER
);

CREATE TABLE IF NOT EXISTS custom_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_name TEXT,
    metric_value REAL,
    tags TEXT,
    recorded_at INTEGER
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_name TEXT,
    threshold REAL,
    comparison TEXT,
    action TEXT,
    enabled INTEGER DEFAULT 1,
    created_at INTEGER
);
EOF
}

# Collect system metrics
collect_system_metrics() {
    local cpu_usage=0
    local memory_usage=0
    local disk_usage=0
    local load_avg=0
    
    # CPU Usage (macOS/Linux)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
        memory_usage=$(top -l 1 | grep "PhysMem" | awk '{print $2}' | sed 's/M//')
        disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    else
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        memory_usage=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
        disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    fi
    
    # Store in database
    sqlite3 "$DB_FILE" "INSERT INTO system_metrics (cpu_usage, memory_usage, disk_usage, load_avg, recorded_at) VALUES ($cpu_usage, $memory_usage, $disk_usage, $load_avg, $(date +%s));"
}

# Show dashboard
cmd_dashboard() {
    init_db
    
    while true; do
        clear
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║           📊 BLACKROAD METRICS DASHBOARD 📊               ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Get current metrics
        collect_system_metrics
        
        local latest=$(sqlite3 -separator $'\t' "$DB_FILE" "SELECT cpu_usage, memory_usage, disk_usage, load_avg, datetime(recorded_at, 'unixepoch') FROM system_metrics ORDER BY recorded_at DESC LIMIT 1;")
        
        if [[ -n "$latest" ]]; then
            local cpu=$(echo "$latest" | cut -f1)
            local mem=$(echo "$latest" | cut -f2)
            local disk=$(echo "$latest" | cut -f3)
            local load=$(echo "$latest" | cut -f4)
            local time=$(echo "$latest" | cut -f5)
            
            # CPU
            echo -e "${BLUE}CPU Usage:${NC}"
            draw_bar "$cpu" 100 "cyan"
            echo -e "  ${cpu}%\n"
            
            # Memory
            echo -e "${BLUE}Memory Usage:${NC}"
            draw_bar "$mem" 100 "yellow"
            echo -e "  ${mem}%\n"
            
            # Disk
            echo -e "${BLUE}Disk Usage:${NC}"
            draw_bar "$disk" 100 "magenta"
            echo -e "  ${disk}%\n"
            
            # Load Average
            echo -e "${BLUE}Load Average:${NC} $load"
            echo -e "${BLUE}Last Update:${NC} $time"
        fi
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # Show alerts
        local alert_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM alerts WHERE enabled = 1;")
        echo -e "${BLUE}Active Alerts:${NC} $alert_count"
        
        # Check for threshold breaches
        if [[ "$cpu" > 80 ]]; then
            echo -e "${RED}⚠️  High CPU usage detected!${NC}"
        fi
        
        if [[ "$mem" > 85 ]]; then
            echo -e "${RED}⚠️  High memory usage detected!${NC}"
        fi
        
        if [[ "$disk" > 90 ]]; then
            echo -e "${RED}⚠️  High disk usage detected!${NC}"
        fi
        
        echo ""
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
        
        sleep 5
    done
}

# Draw progress bar
draw_bar() {
    local value="${1}"
    local max="${2}"
    local color="${3:-green}"
    
    local percentage=$(echo "scale=0; ($value * 100) / $max" | bc)
    local filled=$(echo "scale=0; $percentage / 2" | bc)
    local empty=$((50 - filled))
    
    # Color selection
    local bar_color="$GREEN"
    [[ "$color" == "yellow" ]] && bar_color="$YELLOW"
    [[ "$color" == "cyan" ]] && bar_color="$CYAN"
    [[ "$color" == "magenta" ]] && bar_color="$MAGENTA"
    [[ $percentage -gt 80 ]] && bar_color="$RED"
    
    echo -n "  ["
    echo -n "${bar_color}"
    for ((i=0; i<filled; i++)); do echo -n "█"; done
    echo -n "${NC}"
    for ((i=0; i<empty; i++)); do echo -n "░"; done
    echo -n "]"
}

# Record custom metric
cmd_record() {
    init_db
    local name="${1}"
    local value="${2}"
    local tags="${3:-}"
    
    if [[ -z "$name" ]] || [[ -z "$value" ]]; then
        echo -e "${RED}❌ Usage: br metrics record <name> <value> [tags]${NC}"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO custom_metrics (metric_name, metric_value, tags, recorded_at) VALUES ('$name', $value, '$tags', $(date +%s));"
    
    echo -e "${GREEN}✓ Metric recorded:${NC} $name = $value"
    [[ -n "$tags" ]] && echo -e "${BLUE}Tags:${NC} $tags"
}

# Show metrics history
cmd_history() {
    init_db
    local metric="${1:-system}"
    local limit="${2:-20}"
    
    echo -e "${CYAN}📈 Metrics History: $metric${NC}\n"
    
    if [[ "$metric" == "system" ]]; then
        sqlite3 -separator $'\t' "$DB_FILE" "SELECT cpu_usage, memory_usage, disk_usage, datetime(recorded_at, 'unixepoch') FROM system_metrics ORDER BY recorded_at DESC LIMIT $limit;" | while IFS=$'\t' read -r cpu mem disk time; do
            echo -e "${BLUE}$time${NC}"
            echo -e "  CPU: ${cpu}% | Memory: ${mem}% | Disk: ${disk}%"
        done
    else
        sqlite3 -separator $'\t' "$DB_FILE" "SELECT metric_value, tags, datetime(recorded_at, 'unixepoch') FROM custom_metrics WHERE metric_name = '$metric' ORDER BY recorded_at DESC LIMIT $limit;" | while IFS=$'\t' read -r value tags time; do
            echo -e "${BLUE}$time${NC}"
            echo -e "  Value: $value"
            [[ -n "$tags" ]] && echo -e "  Tags: $tags"
        done
    fi
}

# Show statistics
cmd_stats() {
    init_db
    local metric="${1:-system}"
    
    echo -e "${CYAN}📊 Statistics: $metric${NC}\n"
    
    if [[ "$metric" == "system" ]]; then
        local cpu_avg=$(sqlite3 "$DB_FILE" "SELECT AVG(cpu_usage) FROM system_metrics WHERE recorded_at > $(date -d '1 hour ago' +%s 2>/dev/null || date -v-1H +%s);" | awk '{printf "%.1f", $1}')
        local mem_avg=$(sqlite3 "$DB_FILE" "SELECT AVG(memory_usage) FROM system_metrics WHERE recorded_at > $(date -d '1 hour ago' +%s 2>/dev/null || date -v-1H +%s);" | awk '{printf "%.1f", $1}')
        local disk_avg=$(sqlite3 "$DB_FILE" "SELECT AVG(disk_usage) FROM system_metrics WHERE recorded_at > $(date -d '1 hour ago' +%s 2>/dev/null || date -v-1H +%s);" | awk '{printf "%.1f", $1}')
        
        echo -e "${BLUE}Last Hour Averages:${NC}"
        echo -e "  CPU: ${cpu_avg}%"
        echo -e "  Memory: ${mem_avg}%"
        echo -e "  Disk: ${disk_avg}%"
    else
        local avg=$(sqlite3 "$DB_FILE" "SELECT AVG(metric_value) FROM custom_metrics WHERE metric_name = '$metric';" | awk '{printf "%.2f", $1}')
        local min=$(sqlite3 "$DB_FILE" "SELECT MIN(metric_value) FROM custom_metrics WHERE metric_name = '$metric';" | awk '{printf "%.2f", $1}')
        local max=$(sqlite3 "$DB_FILE" "SELECT MAX(metric_value) FROM custom_metrics WHERE metric_name = '$metric';" | awk '{printf "%.2f", $1}')
        local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM custom_metrics WHERE metric_name = '$metric';")
        
        echo -e "${BLUE}Statistics:${NC}"
        echo -e "  Average: $avg"
        echo -e "  Min: $min"
        echo -e "  Max: $max"
        echo -e "  Count: $count"
    fi
}

# Add alert
cmd_add_alert() {
    init_db
    local metric="${1}"
    local threshold="${2}"
    local comparison="${3:-gt}"
    local action="${4:-notify}"
    
    if [[ -z "$metric" ]] || [[ -z "$threshold" ]]; then
        echo -e "${RED}❌ Usage: br metrics add-alert <metric> <threshold> [comparison] [action]${NC}"
        echo -e "Comparisons: gt (>), lt (<), eq (=)"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO alerts (metric_name, threshold, comparison, action, created_at) VALUES ('$metric', $threshold, '$comparison', '$action', $(date +%s));"
    
    echo -e "${GREEN}✓ Alert added:${NC} $metric $comparison $threshold → $action"
}

# List alerts
cmd_list_alerts() {
    init_db
    echo -e "${CYAN}🚨 Active Alerts:${NC}\n"
    
    local count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM alerts WHERE enabled = 1;")
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No alerts configured${NC}"
        echo -e "Add with: br metrics add-alert <metric> <threshold>"
        exit 0
    fi
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT metric_name, comparison, threshold, action, enabled FROM alerts;" | while IFS=$'\t' read -r metric comp thresh action enabled; do
        local icon="✓"
        [[ $enabled -eq 0 ]] && icon="✗"
        
        local comp_symbol=">"
        [[ "$comp" == "lt" ]] && comp_symbol="<"
        [[ "$comp" == "eq" ]] && comp_symbol="="
        
        echo -e "$icon ${GREEN}$metric${NC} $comp_symbol $thresh → $action"
    done
}

# Export metrics
cmd_export() {
    init_db
    local format="${1:-csv}"
    local output="${2:-metrics-$(date +%Y%m%d-%H%M%S)}"
    
    echo -e "${CYAN}📤 Exporting metrics...${NC}\n"
    
    if [[ "$format" == "csv" ]]; then
        sqlite3 -header -csv "$DB_FILE" "SELECT * FROM system_metrics ORDER BY recorded_at DESC;" > "$output.csv"
        echo -e "${GREEN}✓ Exported to:${NC} $output.csv"
    elif [[ "$format" == "json" ]]; then
        sqlite3 "$DB_FILE" "SELECT json_group_array(json_object('cpu', cpu_usage, 'memory', memory_usage, 'disk', disk_usage, 'time', recorded_at)) FROM system_metrics;" > "$output.json"
        echo -e "${GREEN}✓ Exported to:${NC} $output.json"
    fi
}

# Cleanup old metrics
cmd_cleanup() {
    init_db
    local days="${1:-30}"
    
    echo -e "${CYAN}🧹 Cleaning metrics older than $days days...${NC}\n"
    
    local cutoff=$(($(date +%s) - (days * 86400)))
    
    local deleted_system=$(sqlite3 "$DB_FILE" "DELETE FROM system_metrics WHERE recorded_at < $cutoff; SELECT changes();")
    local deleted_custom=$(sqlite3 "$DB_FILE" "DELETE FROM custom_metrics WHERE recorded_at < $cutoff; SELECT changes();")
    
    echo -e "${GREEN}✓ Deleted:${NC}"
    echo -e "  System metrics: $deleted_system"
    echo -e "  Custom metrics: $deleted_custom"
}

# Help
cmd_help() {
    cat << 'EOF'
📊 Metrics Dashboard

USAGE:
  br metrics <command> [options]

DASHBOARD:
  dashboard                     Show live metrics dashboard
  
RECORDING:
  record <name> <value> [tags]  Record custom metric
  
VIEWING:
  history [metric] [limit]      Show metrics history
  stats [metric]                Show statistics
  
ALERTS:
  add-alert <metric> <thresh> [comp] [action]  Add alert
  list-alerts                                  List alerts
  
EXPORT:
  export [csv|json] [filename]  Export metrics
  cleanup [days]                Remove old metrics (default: 30)

EXAMPLES:
  # Watch live dashboard
  br metrics dashboard

  # Record custom metrics
  br metrics record api_requests 1523 "endpoint=/api/users"
  br metrics record response_time 245.5 "server=prod"

  # View history
  br metrics history system 50
  br metrics history api_requests 20

  # Statistics
  br metrics stats system
  br metrics stats response_time

  # Set alerts
  br metrics add-alert cpu_usage 80 gt notify
  br metrics add-alert disk_usage 90 gt notify
  br metrics add-alert response_time 1000 gt alert

  # Export data
  br metrics export csv my-metrics
  br metrics export json analytics-data

  # Cleanup
  br metrics cleanup 7

SYSTEM METRICS:
  - CPU Usage (%)
  - Memory Usage (%)
  - Disk Usage (%)
  - Load Average
  - Network I/O

CUSTOM METRICS:
  - Any numerical value
  - Tags for categorization
  - Historical tracking
  - Statistical analysis

INTEGRATIONS:
  # Track CI/CD metrics
  br ci run myapp && br metrics record ci_duration $SECONDS

  # Track test results
  br test run && br metrics record tests_passed $PASSED

  # Track deployments
  br deploy quick && br metrics record deployments 1

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    dashboard|dash|d) cmd_dashboard ;;
    record|r) cmd_record "${@:2}" ;;
    history|hist|h) cmd_history "${@:2}" ;;
    stats|stat|s) cmd_stats "${@:2}" ;;
    add-alert|alert|a) cmd_add_alert "${@:2}" ;;
    list-alerts|alerts|la) cmd_list_alerts ;;
    export|e) cmd_export "${@:2}" ;;
    cleanup|clean|c) cmd_cleanup "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
