#!/bin/bash
# BlackRoad → Google Drive Auto Sync
LOG="$HOME/.blackroad/gdrive-sync.log"
mkdir -p "$(dirname "$LOG")"

echo "[$(date -u)] GDrive sync starting..." >> "$LOG"

# Sync key directories (exclude large binary dirs)
rclone sync /Users/alexa/blackroad "gdrive-blackroad:blackroad-backup" \
  --exclude ".git/**" \
  --exclude "node_modules/**" \
  --exclude "*.sqlite3" \
  --exclude "*.db" \
  --filter "+ *.sh" \
  --filter "+ *.json" \
  --filter "+ *.md" \
  --filter "+ *.yml" \
  --filter "+ *.yaml" \
  --filter "- *" \
  --transfers 4 \
  --log-file "$LOG" \
  --log-level INFO 2>&1 | tail -3

echo "[$(date -u)] GDrive sync done" >> "$LOG"
