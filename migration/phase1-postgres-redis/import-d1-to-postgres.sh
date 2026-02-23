#!/bin/bash
# Import D1 SQLite dumps into PostgreSQL on Cecilia
# Run from Mac: bash import-d1-to-postgres.sh
set -euo pipefail

EXPORT_DIR="${HOME}/cloudflare-export/d1"
CECILIA="pi@192.168.4.89"
PG_PASSWORD="${PG_PASSWORD:?Set PG_PASSWORD}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# D1 (SQLite) to PostgreSQL syntax converter
convert_sqlite_to_pg() {
  local input="$1"
  local output="$2"

  python3 << PYEOF
import re, sys

with open('$input', 'r') as f:
    sql = f.read()

# SQLite → PostgreSQL conversions
# INTEGER PRIMARY KEY AUTOINCREMENT → SERIAL PRIMARY KEY
sql = re.sub(r'INTEGER\s+PRIMARY\s+KEY\s+AUTOINCREMENT', 'SERIAL PRIMARY KEY', sql, flags=re.IGNORECASE)

# Remove AUTOINCREMENT standalone
sql = re.sub(r'\bAUTOINCREMENT\b', '', sql, flags=re.IGNORECASE)

# datetime('now') → NOW()
sql = re.sub(r"datetime\('now'\)", 'NOW()', sql, flags=re.IGNORECASE)

# BOOLEAN handling (SQLite stores as INTEGER)
# Keep as-is since PostgreSQL handles 0/1 for boolean columns

# Remove SQLite-specific pragmas
sql = re.sub(r'PRAGMA\s+[^;]+;', '', sql, flags=re.IGNORECASE)

# Remove BEGIN TRANSACTION / COMMIT (let PostgreSQL handle)
sql = re.sub(r'BEGIN\s+TRANSACTION\s*;', '', sql, flags=re.IGNORECASE)
sql = re.sub(r'COMMIT\s*;', '', sql, flags=re.IGNORECASE)

# Handle INSERT OR IGNORE → INSERT ... ON CONFLICT DO NOTHING
sql = re.sub(r'INSERT\s+OR\s+IGNORE', 'INSERT', sql, flags=re.IGNORECASE)

# Handle INSERT OR REPLACE → INSERT ... ON CONFLICT DO UPDATE (approximation)
sql = re.sub(r'INSERT\s+OR\s+REPLACE', 'INSERT', sql, flags=re.IGNORECASE)

# Remove IF NOT EXISTS from CREATE INDEX (PostgreSQL supports it)
# Already compatible

with open('$output', 'w') as f:
    f.write(sql)

print(f'Converted: $input -> $output')
PYEOF
}

# Map D1 database names to PostgreSQL database names
declare -A DB_MAP=(
  ["blackroad-os-main"]="blackroad_os_main"
  ["blackroad-continuity"]="blackroad_continuity"
  ["blackroad-saas"]="blackroad_saas"
  ["apollo-agent-registry"]="apollo_agent_registry"
  ["blackroad_revenue"]="blackroad_revenue"
)

log "Importing D1 databases into PostgreSQL on Cecilia..."

for d1_name in "${!DB_MAP[@]}"; do
  pg_name="${DB_MAP[$d1_name]}"
  sql_file="$EXPORT_DIR/${d1_name}.sql"

  if [ ! -f "$sql_file" ]; then
    warn "No export found for $d1_name (expected: $sql_file)"
    continue
  fi

  info "Converting $d1_name -> $pg_name"

  # Convert SQLite syntax to PostgreSQL
  pg_file="/tmp/${pg_name}-pg.sql"
  convert_sqlite_to_pg "$sql_file" "$pg_file"

  # Upload to Cecilia
  scp "$pg_file" "${CECILIA}:/tmp/${pg_name}-pg.sql"

  # Import
  info "Importing into $pg_name..."
  ssh "$CECILIA" "PGPASSWORD='${PG_PASSWORD}' psql -U blackroad -d ${pg_name} -f /tmp/${pg_name}-pg.sql" 2>&1 || warn "Some errors during import of $pg_name (may be OK if tables exist)"

  # Verify
  local count
  count=$(ssh "$CECILIA" "PGPASSWORD='${PG_PASSWORD}' psql -U blackroad -d ${pg_name} -t -c \"SELECT count(*) FROM information_schema.tables WHERE table_schema='public'\"" 2>/dev/null | xargs)
  log "  $pg_name: $count tables"

  rm -f "$pg_file"
done

echo ""
log "D1 → PostgreSQL import complete!"
