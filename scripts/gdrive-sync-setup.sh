#!/bin/bash
# Google Drive sync via rclone
# Run once interactively to auth, then sets up automated sync

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}📁 Setting up Google Drive sync${NC}"

# Install rclone
which rclone >/dev/null 2>&1 || curl https://rclone.org/install.sh | sudo bash

# Configure remote (interactive - opens browser)
if ! rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
  echo -e "${CYAN}🔐 Configuring Google Drive remote (browser auth required)...${NC}"
  rclone config create gdrive drive scope=drive
fi

# Create sync script
cat > ~/blackroad-gdrive-sync.sh << 'SYNC'
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M)
echo "[${DATE}] Starting BlackRoad → Google Drive sync..."

# Sync main repo (exclude large dirs)
rclone sync /Users/alexa/blackroad gdrive:blackroad-backup/main \
  --exclude ".git/**" \
  --exclude "node_modules/**" \
  --exclude "*.log" \
  --exclude ".blackroad/backups/**" \
  --filter "+ *.sh" \
  --filter "+ *.json" \
  --filter "+ *.md" \
  --filter "+ *.ts" \
  --filter "+ *.js" \
  --filter "- **" \
  --transfers 8 \
  --checkers 16 \
  --log-level INFO \
  --log-file ~/.blackroad/logs/gdrive-sync.log

echo "[${DATE}] Sync complete"
SYNC
chmod +x ~/blackroad-gdrive-sync.sh

# macOS: launchd agent for daily sync
PLIST="$HOME/Library/LaunchAgents/io.blackroad.gdrive-sync.plist"
cat > "$PLIST" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>io.blackroad.gdrive-sync</string>
  <key>ProgramArguments</key>
  <array><string>$HOME/blackroad-gdrive-sync.sh</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>2</integer><key>Minute</key><integer>0</integer></dict>
  <key>RunAtLoad</key><false/>
  <key>StandardOutPath</key><string>$HOME/.blackroad/logs/gdrive-sync.log</string>
  <key>StandardErrorPath</key><string>$HOME/.blackroad/logs/gdrive-sync-err.log</string>
</dict>
</plist>
PLIST

mkdir -p ~/.blackroad/logs
launchctl load "$PLIST" 2>/dev/null || launchctl bootstrap gui/$(id -u) "$PLIST" 2>/dev/null || true
echo -e "${GREEN}✅ Google Drive sync scheduled daily at 2am${NC}"
echo -e "${CYAN}Run manually: ~/blackroad-gdrive-sync.sh${NC}"
