#!/usr/bin/env zsh
# BR Cache — local TTL key-value cache

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'
BOLD='\033[1m'

DB="$HOME/.blackroad/cache.db"

init_db() {
  mkdir -p "$(dirname "$DB")"
  sqlite3 "$DB" <<'SQL'
CREATE TABLE IF NOT EXISTS cache (
  key TEXT NOT NULL,
  ns TEXT NOT NULL DEFAULT 'default',
  value TEXT,
  type TEXT DEFAULT 'string',
  ttl_sec INTEGER DEFAULT 3600,
  hits INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  expires_at TEXT,
  PRIMARY KEY (key, ns)
);
CREATE TABLE IF NOT EXISTS namespaces (
  name TEXT PRIMARY KEY,
  description TEXT,
  default_ttl INTEGER DEFAULT 3600,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  op TEXT NOT NULL,
  key TEXT,
  ns TEXT DEFAULT 'default',
  hit INTEGER DEFAULT 0,
  ts TEXT DEFAULT (datetime('now'))
);
INSERT OR IGNORE INTO namespaces (name, description, default_ttl) VALUES
  ('default', 'General purpose cache', 3600),
  ('api', 'API response cache', 300),
  ('session', 'Session data cache', 86400),
  ('config', 'Configuration cache', 3600),
  ('tokens', 'Auth token cache', 900);
SQL
}

_ttl_for_ns() {
  local ns="${1:-default}"
  sqlite3 "$DB" "SELECT default_ttl FROM namespaces WHERE name='$ns';" 2>/dev/null || echo "3600"
}

_is_expired() {
  local key="$1" ns="${2:-default}"
  local expired
  expired=$(sqlite3 "$DB" "SELECT CASE WHEN expires_at IS NULL THEN 0 WHEN expires_at < datetime('now') THEN 1 ELSE 0 END FROM cache WHERE key='$key' AND ns='$ns';")
  [[ "$expired" == "1" ]]
}

# Set a key
cmd_set() {
  local key="$1" value="$2" ns="${3:-default}" ttl="${4:-}"
  [[ -z "$key" ]] && { echo "Usage: br cache set <key> <value> [ns] [ttl_sec]"; exit 1; }
  [[ -z "$ttl" ]] && ttl=$(_ttl_for_ns "$ns")
  local type="string"
  # Auto-detect JSON
  [[ "${value:0:1}" == "{" || "${value:0:1}" == "[" ]] && type="json"
  local expires="datetime('now', '+${ttl} seconds')"
  [[ "$ttl" -eq 0 ]] && expires="NULL"
  sqlite3 "$DB" "INSERT OR REPLACE INTO cache (key, ns, value, type, ttl_sec, created_at, expires_at) VALUES ('$key', '$ns', '$value', '$type', $ttl, datetime('now'), $expires);"
  sqlite3 "$DB" "INSERT INTO stats (op, key, ns) VALUES ('set', '$key', '$ns');"
  echo -e "${GREEN}✓ Cached: ${BOLD}$ns/$key${NC}${GREEN} (ttl=${ttl}s)${NC}"
}

# Get a key
cmd_get() {
  local key="$1" ns="${2:-default}"
  [[ -z "$key" ]] && { echo "Usage: br cache get <key> [ns]"; exit 1; }
  if _is_expired "$key" "$ns"; then
    sqlite3 "$DB" "DELETE FROM cache WHERE key='$key' AND ns='$ns';"
    sqlite3 "$DB" "INSERT INTO stats (op, key, ns, hit) VALUES ('miss_expired', '$key', '$ns', 0);"
    echo -e "${YELLOW}⚠ Cache miss: $ns/$key (expired)${NC}" >&2
    return 1
  fi
  local val
  val=$(sqlite3 "$DB" "SELECT value FROM cache WHERE key='$key' AND ns='$ns';")
  if [[ -z "$val" ]]; then
    sqlite3 "$DB" "INSERT INTO stats (op, key, ns, hit) VALUES ('miss', '$key', '$ns', 0);"
    echo -e "${YELLOW}⚠ Cache miss: $ns/$key${NC}" >&2
    return 1
  fi
  sqlite3 "$DB" "UPDATE cache SET hits=hits+1 WHERE key='$key' AND ns='$ns';"
  sqlite3 "$DB" "INSERT INTO stats (op, key, ns, hit) VALUES ('get', '$key', '$ns', 1);"
  echo "$val"
}

# Check existence
cmd_has() {
  local key="$1" ns="${2:-default}"
  [[ -z "$key" ]] && { echo "Usage: br cache has <key> [ns]"; exit 1; }
  if _is_expired "$key" "$ns"; then
    echo "expired"
    return 1
  fi
  local cnt
  cnt=$(sqlite3 "$DB" "SELECT COUNT(*) FROM cache WHERE key='$key' AND ns='$ns';")
  if [[ "$cnt" -gt 0 ]]; then
    echo "hit"
    return 0
  else
    echo "miss"
    return 1
  fi
}

# Delete a key
cmd_del() {
  local key="$1" ns="${2:-default}"
  [[ -z "$key" ]] && { echo "Usage: br cache del <key> [ns]"; exit 1; }
  local deleted
  deleted=$(sqlite3 "$DB" "SELECT COUNT(*) FROM cache WHERE key='$key' AND ns='$ns';")
  sqlite3 "$DB" "DELETE FROM cache WHERE key='$key' AND ns='$ns';"
  [[ "$deleted" -gt 0 ]] && echo -e "${GREEN}✓ Deleted: $ns/$key${NC}" || echo -e "${YELLOW}⚠ Key not found: $ns/$key${NC}"
}

# List keys
cmd_list() {
  local ns="${1:-}"
  echo ""
  echo -e "${CYAN}${BOLD}🗄️  Cache Contents${NC}"
  echo ""
  local where=""
  [[ -n "$ns" ]] && where="WHERE c.ns='$ns'"
  printf "  ${BOLD}%-8s %-25s %-8s %8s %8s %20s${NC}\n" "NS" "Key" "Type" "Hits" "TTL" "Expires"
  printf "  %-8s %-25s %-8s %8s %8s %20s\n" "──────" "───────────────────────" "──────" "──────" "──────" "──────────────────"
  sqlite3 -separator "|" "$DB" "SELECT ns, key, type, hits, ttl_sec, expires_at, CASE WHEN expires_at IS NULL THEN 'never' WHEN expires_at < datetime('now') THEN 'EXPIRED' ELSE round((julianday(expires_at)-julianday('now'))*86400) END as rem FROM cache $where ORDER BY ns, key;" | while IFS="|" read -r cns key typ hits ttl exp rem; do
    local color="$GREEN"
    [[ "$rem" == "EXPIRED" ]] && color="$RED"
    [[ "$rem" == "never" ]] && rem="∞"
    [[ "$rem" != "EXPIRED" && "$rem" != "∞" ]] && rem="${rem%.*}s"
    printf "  ${color}%-8s %-25s %-8s %8s %8s %20s${NC}\n" "$cns" "${key:0:25}" "$typ" "$hits" "${ttl}s" "$rem"
  done
  echo ""
  local total live expired
  total=$(sqlite3 "$DB" "SELECT COUNT(*) FROM cache;")
  expired=$(sqlite3 "$DB" "SELECT COUNT(*) FROM cache WHERE expires_at < datetime('now');")
  live=$(( total - expired ))
  echo -e "  Total: ${BOLD}$total${NC}  Live: ${GREEN}$live${NC}  Expired: ${RED}$expired${NC}"
  echo ""
}

# Flush expired entries
cmd_flush() {
  local ns="${1:-}"
  if [[ "$ns" == "all" || -z "$ns" ]]; then
    local n
    n=$(sqlite3 "$DB" "SELECT COUNT(*) FROM cache WHERE expires_at < datetime('now');")
    sqlite3 "$DB" "DELETE FROM cache WHERE expires_at < datetime('now');"
    echo -e "${GREEN}✓ Flushed $n expired entries${NC}"
  else
    local n
    n=$(sqlite3 "$DB" "SELECT COUNT(*) FROM cache WHERE ns='$ns';")
    sqlite3 "$DB" "DELETE FROM cache WHERE ns='$ns';"
    echo -e "${GREEN}✓ Flushed namespace '$ns' ($n entries)${NC}"
  fi
}

# Cache stats / hit rate
cmd_stats() {
  echo ""
  echo -e "${CYAN}📊 Cache Statistics${NC}"
  echo ""
  local total_gets hits misses
  total_gets=$(sqlite3 "$DB" "SELECT COUNT(*) FROM stats WHERE op IN ('get', 'miss', 'miss_expired');")
  hits=$(sqlite3 "$DB" "SELECT COUNT(*) FROM stats WHERE op='get' AND hit=1;")
  misses=$(sqlite3 "$DB" "SELECT COUNT(*) FROM stats WHERE hit=0;")
  local hit_rate=0
  [[ "$total_gets" -gt 0 ]] && hit_rate=$(( hits * 100 / total_gets ))
  echo -e "  Hit rate: ${BOLD}${hit_rate}%${NC}  (${hits} hits / ${misses} misses / ${total_gets} total)"
  echo ""
  echo -e "  ${BOLD}By namespace:${NC}"
  sqlite3 -separator "|" "$DB" "SELECT ns, COUNT(*), SUM(hits) FROM cache GROUP BY ns ORDER BY COUNT(*) DESC;" | while IFS="|" read -r cns cnt tot_hits; do
    printf "    %-12s  %s keys  %s total hits\n" "$cns" "$cnt" "${tot_hits:-0}"
  done
  echo ""
  echo -e "  ${BOLD}Top keys by hits:${NC}"
  sqlite3 -separator "|" "$DB" "SELECT key, ns, hits FROM cache ORDER BY hits DESC LIMIT 10;" | while IFS="|" read -r key cns hits; do
    printf "    %-25s %-12s  %s hits\n" "$key" "$cns" "$hits"
  done
  echo ""
}

# Namespace management
cmd_ns() {
  local sub="${1:-list}"
  case "$sub" in
    list)
      echo ""
      echo -e "${CYAN}Namespaces${NC}"
      sqlite3 -separator "|" "$DB" "SELECT name, description, default_ttl, created_at FROM namespaces;" | while IFS="|" read -r n d t c; do
        printf "  ${GREEN}%-14s${NC}  ttl=${t}s  %s\n" "$n" "$d"
      done
      echo ""
      ;;
    add)
      local name="$2" desc="${3:-}" ttl="${4:-3600}"
      [[ -z "$name" ]] && { echo "Usage: br cache ns add <name> [description] [ttl]"; exit 1; }
      sqlite3 "$DB" "INSERT OR REPLACE INTO namespaces (name, description, default_ttl) VALUES ('$name', '$desc', $ttl);"
      echo -e "${GREEN}✓ Namespace '$name' created (ttl=${ttl}s)${NC}"
      ;;
    del|rm)
      local name="$2"
      [[ -z "$name" ]] && { echo "Usage: br cache ns del <name>"; exit 1; }
      sqlite3 "$DB" "DELETE FROM namespaces WHERE name='$name'; DELETE FROM cache WHERE ns='$name';"
      echo -e "${GREEN}✓ Namespace '$name' removed${NC}"
      ;;
  esac
}

show_help() {
  echo ""
  echo -e "${CYAN}${BOLD}br cache${NC} — local TTL key-value cache"
  echo ""
  echo -e "  ${GREEN}br cache set <key> <value> [ns] [ttl]${NC}  Set a value"
  echo -e "  ${GREEN}br cache get <key> [ns]${NC}               Get a value"
  echo -e "  ${GREEN}br cache has <key> [ns]${NC}               Check existence"
  echo -e "  ${GREEN}br cache del <key> [ns]${NC}               Delete a key"
  echo -e "  ${GREEN}br cache list [ns]${NC}                    List all keys"
  echo -e "  ${GREEN}br cache flush [ns|all]${NC}               Remove expired/flush ns"
  echo -e "  ${GREEN}br cache stats${NC}                        Hit rate & statistics"
  echo -e "  ${GREEN}br cache ns list${NC}                      List namespaces"
  echo -e "  ${GREEN}br cache ns add <name> [desc] [ttl]${NC}   Add namespace"
  echo -e "  ${GREEN}br cache ns del <name>${NC}                Remove namespace"
  echo ""
  echo -e "  ${YELLOW}Namespaces:${NC} default (1h), api (5m), session (24h), config (1h), tokens (15m)"
  echo -e "  ${YELLOW}JSON auto-detected${NC} when value starts with { or ["
  echo ""
}

init_db
case "${1:-list}" in
  set|put)         shift; cmd_set "$@" ;;
  get|fetch)       shift; cmd_get "$@" ;;
  has|exists)      shift; cmd_has "$@" ;;
  del|rm|delete)   shift; cmd_del "$@" ;;
  list|ls)         shift; cmd_list "$@" ;;
  flush|clean)     shift; cmd_flush "$@" ;;
  stats)           cmd_stats ;;
  ns|namespace)    shift; cmd_ns "$@" ;;
  help|-h|--help)  show_help ;;
  *)               show_help ;;
esac
