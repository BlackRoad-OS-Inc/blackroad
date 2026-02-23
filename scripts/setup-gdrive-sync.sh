#!/bin/bash
# BLACKROAD → GOOGLE DRIVE SYNC
# Uses rclone to sync /Users/alexa/blackroad and all Pi data to Google Drive
# Run once to configure, then cron-automated

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}ℹ️ ${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️ ${NC} $1"; }

GDRIVE_REMOTE="gdrive"
GDRIVE_ROOT="blackroad-backup"

show_help() {
  echo "Usage: $0 [init|sync|status|cron|restore]"
  echo ""
  echo "Commands:"
  echo "  init     - Configure rclone Google Drive remote (interactive)"
  echo "  sync     - Run immediate sync to Google Drive"
  echo "  status   - Show sync status"
  echo "  cron     - Install cron job (every 15min)"
  echo "  restore  - Restore from Google Drive"
}

cmd_init() {
  info "Configuring Google Drive remote..."
  
  if rclone listremotes | grep -q "^${GDRIVE_REMOTE}:"; then
    warn "Remote '${GDRIVE_REMOTE}' already exists. Skipping config."
  else
    echo ""
    echo "🔑 Opening rclone config to add Google Drive remote..."
    echo "   Name: $GDRIVE_REMOTE"
    echo "   Type: drive"
    echo "   Scope: drive (full access)"
    echo ""
    rclone config
  fi
  
  log "Google Drive remote configured: $GDRIVE_REMOTE"
  
  # Create top-level folder structure
  rclone mkdir "${GDRIVE_REMOTE}:${GDRIVE_ROOT}" 2>/dev/null || true
  rclone mkdir "${GDRIVE_REMOTE}:${GDRIVE_ROOT}/blackroad-main" 2>/dev/null || true
  rclone mkdir "${GDRIVE_REMOTE}:${GDRIVE_ROOT}/pi-fleet" 2>/dev/null || true
  rclone mkdir "${GDRIVE_REMOTE}:${GDRIVE_ROOT}/logs" 2>/dev/null || true
  log "Google Drive folder structure created"
}

cmd_sync() {
  local mode="${1:-incremental}"
  
  info "Syncing to Google Drive (mode: $mode)..."
  
  # Main blackroad repo (exclude node_modules, .git large objects)
  rclone sync \
    /Users/alexa/blackroad \
    "${GDRIVE_REMOTE}:${GDRIVE_ROOT}/blackroad-main" \
    --exclude ".git/**" \
    --exclude "node_modules/**" \
    --exclude "*.log" \
    --exclude ".DS_Store" \
    --exclude "orgs/**/.git/**" \
    --transfers 8 \
    --checkers 16 \
    --log-level INFO \
    --stats 30s \
    2>&1 | tee -a ~/.blackroad/logs/gdrive-sync.log
  
  log "Sync complete → gdrive:${GDRIVE_ROOT}/blackroad-main"
  
  # Log sync timestamp
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"gdrive-sync\",\"status\":\"ok\"}" \
    >> ~/.blackroad/logs/gdrive-sync-history.jsonl
}

cmd_status() {
  info "Google Drive sync status:"
  echo ""
  echo "Remote:  ${GDRIVE_REMOTE}:${GDRIVE_ROOT}"
  echo "Source:  /Users/alexa/blackroad"
  echo ""
  
  if rclone listremotes | grep -q "^${GDRIVE_REMOTE}:"; then
    rclone size "${GDRIVE_REMOTE}:${GDRIVE_ROOT}" 2>/dev/null || echo "Cannot reach Google Drive"
  else
    warn "Google Drive not configured. Run: $0 init"
  fi
  
  echo ""
  echo "Last sync:"
  tail -3 ~/.blackroad/logs/gdrive-sync-history.jsonl 2>/dev/null || echo "  No sync history"
}

cmd_cron() {
  info "Installing cron jobs..."
  
  CRON_JOB_MAC="*/15 * * * * /Users/alexa/blackroad/scripts/setup-gdrive-sync.sh sync >> ~/.blackroad/logs/gdrive-cron.log 2>&1"
  
  # Add to macOS crontab
  (crontab -l 2>/dev/null | grep -v "gdrive-sync"; echo "$CRON_JOB_MAC") | crontab -
  log "macOS cron installed (every 15 min)"
  
  # Deploy cron to all Pis
  PI_CRON="*/15 * * * * rclone sync ~/blackroad-backup gdrive:blackroad-backup/\$(hostname) --exclude '.git/**' --exclude 'node_modules/**' >> ~/logs/gdrive-sync.log 2>&1"
  
  for pi in cecilia alice aria octavia; do
    ssh -o ConnectTimeout=5 -o BatchMode=yes "$pi" \
      "(crontab -l 2>/dev/null | grep -v gdrive-sync; echo '$PI_CRON') | crontab -" \
      2>/dev/null && echo "  ✅ $pi cron installed" || echo "  ❌ $pi unreachable"
  done
  
  log "All cron jobs installed"
}

mkdir -p ~/.blackroad/logs

case "${1:-help}" in
  init)    cmd_init ;;
  sync)    cmd_sync "$2" ;;
  status)  cmd_status ;;
  cron)    cmd_cron ;;
  *)       show_help ;;
esac
