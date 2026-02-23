#!/bin/bash
# Import KV namespace exports into Redis on Cecilia
# Run from Mac: bash import-kv-to-redis.sh
set -euo pipefail

EXPORT_DIR="${HOME}/cloudflare-export/kv"
REDIS_HOST="${REDIS_HOST:-192.168.4.89}"
REDIS_PASSWORD="${REDIS_PASSWORD:?Set REDIS_PASSWORD}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[+]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Namespaces to import (skip RATE_LIMIT - ephemeral)
NAMESPACES=(
  "CACHE"
  "IDENTITIES"
  "API_KEYS"
  "TOOLS_KV"
  "TEMPLATES"
  "CONTENT"
  "SUBSCRIPTIONS_KV"
  "USERS_KV"
  "JOBS"
  "APPLICATIONS"
)

log "Importing KV data into Redis at $REDIS_HOST..."

total_imported=0

for ns in "${NAMESPACES[@]}"; do
  ns_dir="$EXPORT_DIR/$ns"

  if [ ! -d "$ns_dir" ]; then
    warn "No export directory for $ns"
    continue
  fi

  info "Importing namespace: $ns"
  ns_count=0

  # Read each exported key file
  for datfile in "$ns_dir"/*.dat; do
    [ -f "$datfile" ] || continue

    # Reconstruct key name from filename
    local_key=$(basename "$datfile" .dat)
    # Reverse the safe encoding
    key=$(echo "$local_key" | sed 's/__SLASH__/\//g; s/__COLON__/:/g')

    # Read value
    value=$(cat "$datfile")

    # Store in Redis with namespace prefix
    redis-cli -h "$REDIS_HOST" -a "$REDIS_PASSWORD" --no-auth-warning \
      SET "${ns}:${key}" "$value" > /dev/null 2>&1

    ns_count=$((ns_count + 1))
  done

  log "  $ns: $ns_count keys imported"
  total_imported=$((total_imported + ns_count))
done

echo ""
log "Import complete: $total_imported total keys"

# Verify
info "Redis stats:"
redis-cli -h "$REDIS_HOST" -a "$REDIS_PASSWORD" --no-auth-warning INFO keyspace 2>/dev/null
