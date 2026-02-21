#!/usr/bin/env zsh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/web-monitor.db"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS sites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    url TEXT,
    check_interval INTEGER DEFAULT 300,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    site_name TEXT,
    status_code INTEGER,
    response_time REAL,
    is_up INTEGER,
    checked_at INTEGER
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    site_name TEXT,
    alert_type TEXT,
    message TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS ssl_certs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    site_name TEXT,
    issuer TEXT,
    expires_at INTEGER,
    days_remaining INTEGER,
    checked_at INTEGER
);
EOF
}

cmd_add() {
    init_db
    local name="$1"
    local url="$2"
    local interval="${3:-300}"
    
    if [[ -z "$name" || -z "$url" ]]; then
        echo -e "${RED}❌ Usage: br monitor add <name> <url> [interval]${NC}"
        echo "Example: br monitor add mysite https://example.com 300"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO sites (name, url, check_interval, created_at) VALUES ('$name', '$url', $interval, $(date +%s));"
    
    echo -e "${GREEN}✓ Added site: $name${NC}"
    echo -e "  URL: $url"
    echo -e "  Check interval: ${interval}s"
}

cmd_list() {
    init_db
    echo -e "${CYAN}🔍 Monitored Sites:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, url FROM sites ORDER BY name;" | while IFS=$'\t' read -r name url; do
        # Get latest check
        local latest=$(sqlite3 "$DB_FILE" "SELECT status_code, is_up FROM checks WHERE site_name='$name' ORDER BY checked_at DESC LIMIT 1;")
        
        if [[ -n "$latest" ]]; then
            local status=$(echo "$latest" | cut -d'|' -f1)
            local is_up=$(echo "$latest" | cut -d'|' -f2)
            
            if [[ "$is_up" == "1" ]]; then
                echo -e "${GREEN}●${NC} $name ($status)"
            else
                echo -e "${RED}●${NC} $name (DOWN)"
            fi
        else
            echo -e "${YELLOW}●${NC} $name (not checked yet)"
        fi
        echo -e "  $url"
        echo ""
    done
}

cmd_check() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br monitor check <name>${NC}"
        exit 1
    fi
    
    local url=$(sqlite3 "$DB_FILE" "SELECT url FROM sites WHERE name='$name';")
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}❌ Site not found: $name${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🔍 Checking $name...${NC}"
    echo -e "  URL: $url\n"
    
    local start=$(date +%s.%N)
    local response=$(curl -sS -w "\n%{http_code}|%{time_total}" -o /dev/null "$url" 2>&1)
    local end=$(date +%s.%N)
    
    local status_code=$(echo "$response" | tail -1 | cut -d'|' -f1)
    local response_time=$(echo "$response" | tail -1 | cut -d'|' -f2)
    
    local is_up=0
    if [[ "$status_code" =~ ^[2-3][0-9][0-9]$ ]]; then
        is_up=1
        echo -e "${GREEN}✓ Site is UP${NC}"
    else
        echo -e "${RED}✗ Site is DOWN${NC}"
    fi
    
    echo -e "  Status: $status_code"
    echo -e "  Response time: ${response_time}s"
    
    sqlite3 "$DB_FILE" "INSERT INTO checks (site_name, status_code, response_time, is_up, checked_at) VALUES ('$name', $status_code, $response_time, $is_up, $(date +%s));"
}

cmd_check_all() {
    init_db
    echo -e "${CYAN}🔍 Checking all sites...${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name FROM sites;" | while IFS=$'\t' read -r name; do
        cmd_check "$name"
        echo ""
    done
}

cmd_status() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br monitor status <name>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📊 Status for $name:${NC}\n"
    
    # Get recent checks
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT status_code, response_time, is_up, datetime(checked_at, 'unixepoch') FROM checks WHERE site_name='$name' ORDER BY checked_at DESC LIMIT 10;" | while IFS=$'\t' read -r status time is_up checked; do
        if [[ "$is_up" == "1" ]]; then
            echo -e "${GREEN}✓${NC} $checked - ${status} (${time}s)"
        else
            echo -e "${RED}✗${NC} $checked - ${status}"
        fi
    done
    
    # Calculate uptime
    local total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM checks WHERE site_name='$name';")
    local up=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM checks WHERE site_name='$name' AND is_up=1;")
    
    if [[ "$total" -gt 0 ]]; then
        local uptime=$(echo "scale=2; ($up * 100) / $total" | bc)
        echo -e "\n${BLUE}Uptime:${NC} ${uptime}% ($up/$total checks)"
    fi
}

cmd_ssl() {
    init_db
    local name="$1"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br monitor ssl <name>${NC}"
        exit 1
    fi
    
    local url=$(sqlite3 "$DB_FILE" "SELECT url FROM sites WHERE name='$name';")
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}❌ Site not found: $name${NC}"
        exit 1
    fi
    
    # Extract domain
    local domain=$(echo "$url" | sed 's|https\?://||' | cut -d'/' -f1)
    
    echo -e "${CYAN}🔐 Checking SSL certificate...${NC}"
    echo -e "  Domain: $domain\n"
    
    # Get SSL info
    local cert_info=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | openssl x509 -noout -dates -issuer 2>/dev/null)
    
    if [[ -z "$cert_info" ]]; then
        echo -e "${RED}✗ Could not retrieve certificate${NC}"
        exit 1
    fi
    
    local not_after=$(echo "$cert_info" | grep "notAfter" | cut -d'=' -f2-)
    local issuer=$(echo "$cert_info" | grep "issuer" | cut -d'=' -f2-)
    
    # Calculate days remaining
    local expires_epoch=$(date -j -f "%b %d %T %Y %Z" "$not_after" "+%s" 2>/dev/null)
    local now_epoch=$(date +%s)
    local days_remaining=$(( (expires_epoch - now_epoch) / 86400 ))
    
    echo -e "${BLUE}Issuer:${NC} $issuer"
    echo -e "${BLUE}Expires:${NC} $not_after"
    echo -e "${BLUE}Days remaining:${NC} $days_remaining"
    
    if [[ $days_remaining -lt 30 ]]; then
        echo -e "\n${YELLOW}⚠️  Certificate expires soon!${NC}"
    else
        echo -e "\n${GREEN}✓ Certificate is valid${NC}"
    fi
    
    sqlite3 "$DB_FILE" "INSERT INTO ssl_certs (site_name, issuer, expires_at, days_remaining, checked_at) VALUES ('$name', '$(echo "$issuer" | sed "s/'/''/g")', $expires_epoch, $days_remaining, $(date +%s));"
}

cmd_watch() {
    init_db
    local interval="${1:-60}"
    
    echo -e "${CYAN}👁️  Watching all sites (interval: ${interval}s)${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"
    
    while true; do
        cmd_check_all
        echo -e "${BLUE}Next check in ${interval}s...${NC}\n"
        sleep "$interval"
    done
}

cmd_alerts() {
    init_db
    echo -e "${CYAN}🔔 Recent Alerts:${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT site_name, alert_type, message, datetime(created_at, 'unixepoch') FROM alerts ORDER BY created_at DESC LIMIT 20;" | while IFS=$'\t' read -r site type msg time; do
        echo -e "${YELLOW}⚠${NC} $site - $time"
        echo -e "  $type: $msg"
        echo ""
    done
}

cmd_help() {
    cat << 'EOF'
🔍 Website Monitoring

USAGE:
  br monitor <command> [options]

SITE MANAGEMENT:
  add <name> <url> [interval]   Add site to monitor
  list                          List monitored sites
  remove <name>                 Remove site

CHECKING:
  check <name>                  Check site now
  check-all                     Check all sites
  status <name>                 Show status history
  watch [interval]              Continuously watch (default: 60s)

SSL:
  ssl <name>                    Check SSL certificate

ALERTS:
  alerts                        Show recent alerts

EXAMPLES:
  # Add sites
  br monitor add mysite https://example.com 300
  br monitor add api https://api.example.com 60

  # Check sites
  br monitor check mysite
  br monitor check-all
  br monitor status mysite

  # SSL monitoring
  br monitor ssl mysite

  # Continuous monitoring
  br monitor watch 60

NOTES:
  - Interval in seconds (default: 300 = 5 minutes)
  - Status codes 2xx/3xx = UP, others = DOWN
  - Uptime percentage calculated from checks
  - SSL expiry warnings at < 30 days

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    add) cmd_add "${@:2}" ;;
    list|ls) cmd_list ;;
    check) cmd_check "${@:2}" ;;
    check-all|all) cmd_check_all ;;
    status|history) cmd_status "${@:2}" ;;
    ssl|cert|certificate) cmd_ssl "${@:2}" ;;
    watch|monitor) cmd_watch "${@:2}" ;;
    alerts) cmd_alerts ;;
    remove|rm)
        init_db
        sqlite3 "$DB_FILE" "DELETE FROM sites WHERE name='${2}';"
        echo -e "${GREEN}✓ Removed${NC}"
        ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
