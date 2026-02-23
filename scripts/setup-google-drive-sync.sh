#!/bin/bash
# BlackRoad → Google Drive Sync via rclone
# Syncs entire /Users/alexa/blackroad to Google Drive daily

set -e
SOURCE="/Users/alexa/blackroad"
DEST="gdrive:BlackRoad-Backup"

echo "☁️  BlackRoad → Google Drive Sync Setup"

# Install rclone if needed
if ! command -v rclone &>/dev/null; then
  echo "📥 Installing rclone..."
  brew install rclone 2>/dev/null || curl -sL https://rclone.org/install.sh | sudo bash
fi

# Check if gdrive remote configured
if rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
  echo "✅ Google Drive remote already configured"
else
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Configure Google Drive remote:"
  echo "   rclone config"
  echo "   → New remote → Name: gdrive → Google Drive"
  echo "   → Follow OAuth flow"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Or run: rclone config (interactive setup)"
  exit 1
fi

# Create sync script
cat > /Users/alexa/blackroad/scripts/gdrive-sync.sh << 'SYNCEOF'
#!/bin/bash
SOURCE="/Users/alexa/blackroad"
DEST="gdrive:BlackRoad-Backup"
LOG="/Users/alexa/.blackroad/gdrive-sync.log"

echo "[$(date -u)] Starting GDrive sync..." | tee -a "$LOG"
rclone sync "$SOURCE" "$DEST" \
  --exclude ".git/**" \
  --exclude "node_modules/**" \
  --exclude "*.pyc" \
  --exclude "__pycache__/**" \
  --exclude ".DS_Store" \
  --progress \
  --log-file="$LOG" \
  --log-level INFO

echo "[$(date -u)] GDrive sync complete" | tee -a "$LOG"
SYNCEOF
chmod +x /Users/alexa/blackroad/scripts/gdrive-sync.sh

# Set up daily cron (macOS launchd or crontab)
CRON_ENTRY="0 3 * * * /Users/alexa/blackroad/scripts/gdrive-sync.sh"
(crontab -l 2>/dev/null | grep -v gdrive-sync; echo "$CRON_ENTRY") | crontab -
echo "✅ Daily 3AM sync scheduled via cron"
echo "📂 Run now: ./scripts/gdrive-sync.sh"
