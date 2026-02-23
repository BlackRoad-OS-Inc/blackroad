#!/bin/bash
# Phase 0: Export All Cloudflare Data
# Safe, read-only. Run from Mac where wrangler is authenticated.
set -euo pipefail

EXPORT_DIR="${HOME}/cloudflare-export"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1" >&2; }
info()  { echo -e "${CYAN}[i]${NC} $1"; }

# Check wrangler is available
if ! command -v wrangler &>/dev/null; then
  error "wrangler not found. Install: npm i -g wrangler"
  exit 1
fi

mkdir -p "$EXPORT_DIR"/{kv,d1,r2,dns,secrets,tunnels}
log "Export directory: $EXPORT_DIR"

# ─── KV NAMESPACES ───
export_kv() {
  log "Exporting KV namespaces..."

  declare -A KV_NAMESPACES=(
    ["CACHE"]="c878fbcc1faf4eddbc98dcfd7485048d"
    ["IDENTITIES"]="10bf69b8bc664a5a832e348f1d0745cf"
    ["API_KEYS"]="57e48a017d4248a39df32661c3377908"
    ["RATE_LIMIT"]="245a00ee1ffe417fbcf519b2dbb141c6"
    ["TOOLS_KV"]="f7b2b20d1e1447b2917b781e6ab7e45c"
    ["TEMPLATES"]="8df3dcbf63d94069975a6fa8ab17f313"
    ["CONTENT"]="119ac3af15724b1b93731202f2968117"
    ["SUBSCRIPTIONS_KV"]="0cf493d5d19141df8912e3dc2df10464"
    ["USERS_KV"]="67a82ad7824d4b89809e7ae2221aba66"
    ["JOBS"]="2557a2b503654590ab7b1da84c7e8b20"
    ["APPLICATIONS"]="90407b533ddc44508f1ce0841c77082d"
  )

  for ns in "${!KV_NAMESPACES[@]}"; do
    local ns_id="${KV_NAMESPACES[$ns]}"
    local out_dir="$EXPORT_DIR/kv/$ns"
    mkdir -p "$out_dir"

    info "  Exporting KV: $ns ($ns_id)"

    # List all keys
    if wrangler kv key list --namespace-id="$ns_id" > "$out_dir/keys.json" 2>/dev/null; then
      local count
      count=$(python3 -c "import json; print(len(json.load(open('$out_dir/keys.json'))))" 2>/dev/null || echo "?")
      log "    Listed $count keys in $ns"

      # Export each key's value
      python3 -c "
import json, subprocess, os, sys
keys = json.load(open('$out_dir/keys.json'))
for i, entry in enumerate(keys):
    key = entry['name']
    safe = key.replace('/', '__SLASH__').replace(':', '__COLON__')
    outfile = '$out_dir/' + safe + '.dat'
    try:
        result = subprocess.run(
            ['wrangler', 'kv', 'key', 'get', '--namespace-id=$ns_id', key],
            capture_output=True, timeout=30
        )
        with open(outfile, 'wb') as f:
            f.write(result.stdout)
        if (i + 1) % 50 == 0:
            print(f'    Exported {i+1}/{len(keys)} keys...', file=sys.stderr)
    except Exception as e:
        print(f'    Failed: {key}: {e}', file=sys.stderr)
print(f'    Done: {len(keys)} keys exported', file=sys.stderr)
" 2>&1
    else
      warn "    Failed to list keys for $ns"
    fi
  done

  # Skip RATE_LIMIT (ephemeral data, will regenerate)
  warn "  Skipping RATE_LIMIT (ephemeral data)"
}

# ─── D1 DATABASES ───
export_d1() {
  log "Exporting D1 databases..."

  local DBS=(
    "blackroad-os-main"
    "blackroad-continuity"
    "blackroad-saas"
    "apollo-agent-registry"
    "blackroad_revenue"
  )

  for db in "${DBS[@]}"; do
    info "  Exporting D1: $db"

    # SQL dump
    if wrangler d1 export "$db" --output="$EXPORT_DIR/d1/${db}.sql" 2>/dev/null; then
      local size
      size=$(wc -c < "$EXPORT_DIR/d1/${db}.sql" 2>/dev/null || echo "0")
      log "    Exported ${db}.sql (${size} bytes)"
    else
      warn "    Failed SQL export for $db, trying execute method..."
      # Fallback: dump tables manually
      wrangler d1 execute "$db" --command=".dump" --json > "$EXPORT_DIR/d1/${db}-dump.json" 2>/dev/null || true
    fi

    # Get table list
    wrangler d1 execute "$db" \
      --command="SELECT name, type FROM sqlite_master WHERE type='table' ORDER BY name" \
      --json > "$EXPORT_DIR/d1/${db}-tables.json" 2>/dev/null || true
  done
}

# ─── R2 BUCKETS ───
export_r2_inventory() {
  log "Exporting R2 bucket inventory (NOT downloading 200GB+ data)..."

  # List all buckets
  wrangler r2 bucket list > "$EXPORT_DIR/r2/all-buckets.json" 2>/dev/null || warn "Failed to list R2 buckets"

  # List objects in each known bucket (inventory only)
  local BUCKETS=(
    "blackroad-models"
    "blackroad-assets"
    "blackroad-backups"
    "blackroad-media"
  )

  for bucket in "${BUCKETS[@]}"; do
    info "  Inventorying R2: $bucket"
    wrangler r2 object list "$bucket" > "$EXPORT_DIR/r2/${bucket}-inventory.json" 2>/dev/null || warn "    Failed: $bucket"
  done

  warn "R2 data sync (200GB+) should use rclone - see phase2-minio/sync-r2-to-minio.sh"
}

# ─── DNS RECORDS ───
export_dns() {
  log "Exporting DNS records..."

  local ZONE_ID="d6566eba4500b460ffec6650d3b4baf6"

  if [ -n "${CLOUDFLARE_API_TOKEN:-}" ]; then
    curl -s -X GET \
      "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?per_page=500" \
      -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
      -H "Content-Type: application/json" \
      > "$EXPORT_DIR/dns/blackroad-io-records.json"

    local count
    count=$(python3 -c "import json; d=json.load(open('$EXPORT_DIR/dns/blackroad-io-records.json')); print(len(d.get('result',[])))" 2>/dev/null || echo "?")
    log "  Exported $count DNS records"
  else
    warn "  CLOUDFLARE_API_TOKEN not set. Export DNS manually:"
    warn "  export CLOUDFLARE_API_TOKEN=your_token && $0"
  fi
}

# ─── WORKER SECRETS (names only) ───
export_secrets() {
  log "Documenting worker secrets (names only, values not retrievable)..."

  local WORKERS=(
    "blackroad-api-gateway"
    "blackroad-payment-gateway"
    "blackroad-subdomain-router"
    "blackroad-command-center"
    "blackroad-tools"
    "blackroad-agents-api"
  )

  for worker in "${WORKERS[@]}"; do
    info "  Listing secrets for: $worker"
    wrangler secret list --name="$worker" > "$EXPORT_DIR/secrets/${worker}.json" 2>/dev/null || true
  done

  # Document known secrets that need re-setting
  cat > "$EXPORT_DIR/secrets/SECRETS_NEEDED.md" << 'EOF'
# Secrets That Must Be Set in Self-Hosted Environment

## API Gateway
- ANTHROPIC_API_KEY
- OPENAI_API_KEY
- TUNNEL_URL (no longer needed - services are direct)

## Payment Gateway (CRITICAL - Stripe)
- STRIPE_SECRET_KEY (sk_live_...)
- STRIPE_PUBLISHABLE_KEY (pk_live_...)
- STRIPE_WEBHOOK_SECRET (whsec_...)
- STRIPE_PRICE_PRO_MONTHLY
- STRIPE_PRICE_PRO_YEARLY
- STRIPE_PRICE_ENT_MONTHLY
- STRIPE_PRICE_ENT_YEARLY

## Command Center
- GITHUB_TOKEN
- HF_TOKEN
- CLOUDFLARE_API_TOKEN (keep for DNS management)

## Database Credentials (new)
- PG_PASSWORD
- REDIS_PASSWORD
- MINIO_ROOT_PASSWORD

Get these from Alexa's password manager before proceeding.
EOF
  log "  Documented required secrets in SECRETS_NEEDED.md"
}

# ─── TUNNEL CONFIGS ───
export_tunnels() {
  log "Exporting tunnel configs..."

  if [ -d "${HOME}/.cloudflared" ]; then
    cp -r "${HOME}/.cloudflared" "$EXPORT_DIR/tunnels/"
    log "  Copied ~/.cloudflared/"
  else
    warn "  No ~/.cloudflared/ found on this machine"
  fi

  # Document tunnel routes
  cat > "$EXPORT_DIR/tunnels/tunnel-routes.md" << 'EOF'
# Cloudflare Tunnel Routes (to be replaced by WireGuard)

Tunnel ID: 52915859-da18-4aa6-add5-7bd9fcac2e0b
Tunnel Name: blackroad
Running On: blackroad-pi (192.168.4.64)
Edge: dfw08 (Dallas)

## Routes
- agent.blackroad.ai → localhost:8080
- api.blackroad.ai → localhost:3000
EOF
}

# ─── MAIN ───
main() {
  echo ""
  echo "═══════════════════════════════════════════════════"
  echo "  Phase 0: Cloudflare Data Export"
  echo "  Target: $EXPORT_DIR"
  echo "  Time: $(date)"
  echo "═══════════════════════════════════════════════════"
  echo ""

  export_kv
  echo ""
  export_d1
  echo ""
  export_r2_inventory
  echo ""
  export_dns
  echo ""
  export_secrets
  echo ""
  export_tunnels

  echo ""
  echo "═══════════════════════════════════════════════════"
  log "Export complete!"
  info "Total size: $(du -sh "$EXPORT_DIR" 2>/dev/null | cut -f1)"
  info "Next: Back up to Lucidia NVMe:"
  info "  scp -r $EXPORT_DIR pi@192.168.4.81:/home/pi/cloudflare-export-backup/"
  echo "═══════════════════════════════════════════════════"
}

case "${1:-all}" in
  kv)       export_kv ;;
  d1)       export_d1 ;;
  r2)       export_r2_inventory ;;
  dns)      export_dns ;;
  secrets)  export_secrets ;;
  tunnels)  export_tunnels ;;
  all)      main ;;
  *)        echo "Usage: $0 [kv|d1|r2|dns|secrets|tunnels|all]" ;;
esac
