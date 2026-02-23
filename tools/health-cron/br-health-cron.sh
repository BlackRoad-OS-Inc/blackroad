#!/bin/zsh
# BR Health Cron — periodic health checks + alerts
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

DB="$HOME/.blackroad/health-cron.db"
mkdir -p "$(dirname $DB)"

init_db() {
  sqlite3 "$DB" "CREATE TABLE IF NOT EXISTS checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts TEXT DEFAULT (datetime('now')),
    endpoint TEXT,
    status INTEGER,
    ok BOOLEAN,
    latency_ms INTEGER
  );"
}

check_endpoint() {
  local name="$1" url="$2"
  local start=$(date +%s%3N)
  local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
  local end=$(date +%s%3N)
  local latency=$((end - start))
  local ok=0
  [[ "$status" -ge 200 && "$status" -lt 400 ]] && ok=1
  
  sqlite3 "$DB" "INSERT INTO checks (endpoint, status, ok, latency_ms) VALUES ('$name', $status, $ok, $latency);"
  
  if [[ $ok -eq 1 ]]; then
    echo "${GREEN}✓${NC} $name → $status (${latency}ms)"
  else
    echo "${RED}✗${NC} $name → $status (${latency}ms)"
  fi
}

case "$1" in
  run)
    init_db
    echo "${CYAN}🔍 Running health checks...${NC}"
    check_endpoint "blackroad.io" "https://blackroad.io"
    check_endpoint "api.blackroad.io" "https://api.blackroad.io/health"
    check_endpoint "app.blackroad.io" "https://app.blackroad.io"
    check_endpoint "alice-tunnel" "http://192.168.4.49:8001/health"
    check_endpoint "memory-api" "http://192.168.4.49:8011/health"
    ;;
  status)
    init_db
    echo "${CYAN}📊 Health check history (last 20):${NC}"
    sqlite3 -column -header "$DB" "SELECT ts, endpoint, status, ok, latency_ms FROM checks ORDER BY ts DESC LIMIT 20;"
    ;;
  install-cron)
    # Install cron to run every 15 min
    SCRIPT_PATH="$(realpath $0)"
    CRON_LINE="*/15 * * * * $SCRIPT_PATH run >> $HOME/.blackroad/health-cron.log 2>&1"
    (crontab -l 2>/dev/null | grep -v "health-cron"; echo "$CRON_LINE") | crontab -
    echo "${GREEN}✓ Cron installed: every 15 minutes${NC}"
    ;;
  *)
    echo "Usage: br health-cron [run|status|install-cron]"
    ;;
esac
