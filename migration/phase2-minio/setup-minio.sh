#!/bin/bash
# Phase 2: Install MinIO on Lucidia (192.168.4.81)
# Run ON Lucidia: bash /tmp/setup-minio.sh
set -euo pipefail

MINIO_ROOT_USER="${MINIO_ROOT_USER:-blackroad-admin}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:?Set MINIO_ROOT_PASSWORD}"
MINIO_DATA="/mnt/nvme/minio-data"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1" >&2; }
info()  { echo -e "${CYAN}[i]${NC} $1"; }

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Phase 2: MinIO on Lucidia"
echo "  Host: $(hostname) ($(hostname -I | awk '{print $1}'))"
echo "  NVMe: $MINIO_DATA"
echo "═══════════════════════════════════════════════════"
echo ""

# Check NVMe is mounted
if ! df -h | grep -q "/mnt/nvme"; then
  error "NVMe not mounted at /mnt/nvme!"
  error "Mount it first: sudo mount /dev/nvme0n1p1 /mnt/nvme"
  exit 1
fi

free_gb=$(df -BG /mnt/nvme | awk 'NR==2{print $4}' | tr -d 'G')
log "NVMe free space: ${free_gb}GB"

if [ "$free_gb" -lt 250 ]; then
  warn "Less than 250GB free. R2 data is ~200GB. Proceed with caution."
fi

# ─── INSTALL MINIO SERVER ───
install_minio() {
  log "Installing MinIO server..."

  if ! command -v minio &>/dev/null; then
    wget -q https://dl.min.io/server/minio/release/linux-arm64/minio -O /tmp/minio
    chmod +x /tmp/minio
    sudo mv /tmp/minio /usr/local/bin/minio
  fi
  log "MinIO server: $(minio --version 2>&1 | head -1)"

  # Create data directory
  sudo mkdir -p "$MINIO_DATA"
  sudo chown "$(whoami):$(whoami)" "$MINIO_DATA"

  # Systemd service
  sudo tee /etc/systemd/system/minio.service > /dev/null << SERVICE
[Unit]
Description=MinIO Object Storage
After=network.target
Documentation=https://min.io/docs

[Service]
Type=simple
User=$(whoami)
Environment="MINIO_ROOT_USER=${MINIO_ROOT_USER}"
Environment="MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}"
Environment="MINIO_VOLUMES=${MINIO_DATA}"
Environment="MINIO_OPTS=--address :9000 --console-address :9001"
ExecStart=/usr/local/bin/minio server \$MINIO_VOLUMES \$MINIO_OPTS
Restart=always
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SERVICE

  sudo systemctl daemon-reload
  sudo systemctl enable minio
  sudo systemctl start minio
  sleep 3
  log "MinIO server running on :9000 (console :9001)"
}

# ─── INSTALL MINIO CLIENT ───
install_mc() {
  log "Installing MinIO client (mc)..."

  if ! command -v mc &>/dev/null; then
    wget -q https://dl.min.io/client/mc/release/linux-arm64/mc -O /tmp/mc
    chmod +x /tmp/mc
    sudo mv /tmp/mc /usr/local/bin/mc
  fi

  # Configure alias
  mc alias set blackroad http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" --api S3v4
  log "mc configured with alias 'blackroad'"
}

# ─── CREATE BUCKETS ───
create_buckets() {
  log "Creating buckets matching R2..."

  local BUCKETS=(
    "blackroad-models"
    "blackroad-assets"
    "blackroad-backups"
    "blackroad-media"
    "blackroad-uploads"
    "blackroad-static"
    "blackroad-logs"
    "blackroad-exports"
    "blackroad-cache"
    "blackroad-temp"
  )

  for bucket in "${BUCKETS[@]}"; do
    if mc mb "blackroad/$bucket" 2>/dev/null; then
      log "  Created: $bucket"
    else
      info "  Exists: $bucket"
    fi
  done
}

# ─── VERIFICATION ───
verify() {
  echo ""
  log "Verifying MinIO..."

  # Check service
  if curl -sf http://localhost:9000/minio/health/live > /dev/null 2>&1; then
    log "  Health: OK"
  else
    error "  Health: FAILED"
  fi

  # List buckets
  info "  Buckets:"
  mc ls blackroad/ 2>/dev/null | while read -r line; do
    info "    $line"
  done

  # Disk usage
  info "  Disk: $(du -sh "$MINIO_DATA" 2>/dev/null | cut -f1) used"
}

# ─── MAIN ───
install_minio
install_mc
create_buckets
verify

echo ""
echo "═══════════════════════════════════════════════════"
log "Phase 2 complete!"
info "MinIO API: http://$(hostname -I | awk '{print $1}'):9000"
info "MinIO Console: http://$(hostname -I | awk '{print $1}'):9001"
info ""
info "Next: Sync R2 data using rclone:"
info "  bash /tmp/sync-r2-to-minio.sh"
echo "═══════════════════════════════════════════════════"
