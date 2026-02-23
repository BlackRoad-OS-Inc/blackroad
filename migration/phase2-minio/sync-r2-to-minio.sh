#!/bin/bash
# Sync R2 data to MinIO using rclone
# Run ON Lucidia: bash sync-r2-to-minio.sh
# Run in tmux/screen - this transfers 200+GB
set -euo pipefail

R2_ACCESS_KEY="${R2_ACCESS_KEY:?Set R2_ACCESS_KEY}"
R2_SECRET_KEY="${R2_SECRET_KEY:?Set R2_SECRET_KEY}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-blackroad-admin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:?Set MINIO_ROOT_PASSWORD}"
CF_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# Install rclone if needed
if ! command -v rclone &>/dev/null; then
  log "Installing rclone..."
  curl https://rclone.org/install.sh | sudo bash
fi

# Configure rclone
mkdir -p ~/.config/rclone
cat > ~/.config/rclone/rclone.conf << CONF
[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY}
secret_access_key = ${R2_SECRET_KEY}
endpoint = https://${CF_ACCOUNT_ID}.r2.cloudflarestorage.com
acl = private

[minio]
type = s3
provider = Minio
access_key_id = ${MINIO_ROOT_USER}
secret_access_key = ${MINIO_ROOT_PASSWORD}
endpoint = http://localhost:9000
CONF

log "rclone configured"

# Buckets to sync
BUCKETS=(
  "blackroad-models"    # ~135GB (largest)
  "blackroad-assets"
  "blackroad-backups"
  "blackroad-media"
)

echo ""
echo "═══════════════════════════════════════════════════"
echo "  R2 → MinIO Sync"
echo "  This will transfer ~200GB. Run in tmux!"
echo "═══════════════════════════════════════════════════"
echo ""

for bucket in "${BUCKETS[@]}"; do
  log "Syncing: $bucket"
  info "  Listing objects..."

  # Count objects in R2
  r2_count=$(rclone ls "r2:$bucket" 2>/dev/null | wc -l)
  info "  R2 objects: $r2_count"

  # Sync with progress
  rclone sync "r2:$bucket" "minio:$bucket" \
    --progress \
    --transfers 4 \
    --checkers 8 \
    --buffer-size 64M \
    --stats 30s \
    --log-file="/tmp/rclone-${bucket}.log" \
    --log-level INFO

  # Verify
  minio_count=$(rclone ls "minio:$bucket" 2>/dev/null | wc -l)
  log "  Synced: $minio_count objects (R2 had $r2_count)"

  if [ "$r2_count" -eq "$minio_count" ]; then
    log "  VERIFIED: counts match"
  else
    echo -e "\033[1;33m[!]\033[0m  WARNING: count mismatch ($r2_count vs $minio_count)"
  fi
  echo ""
done

log "R2 → MinIO sync complete!"
info "Verify with: mc ls --recursive blackroad/ | wc -l"
