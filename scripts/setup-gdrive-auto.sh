#!/bin/bash
# Non-interactive Google Drive sync using rclone gdrive-blackroad: remote
LOG="$HOME/.blackroad/logs/gdrive-sync.log"
LOCK="/tmp/gdrive-sync.lock"
mkdir -p "$(dirname "$LOG")"
[ -f "$LOCK" ] && exit 0
touch "$LOCK"
trap "rm -f $LOCK" EXIT

rclone sync /Users/alexa/blackroad gdrive-blackroad:blackroad-backup \
  --exclude ".git/**" \
  --exclude "node_modules/**" \
  --exclude "repos/**" \
  --exclude "*.db" \
  --exclude ".DS_Store" \
  --exclude "cece-logs/**" \
  --transfers 4 \
  --log-file "$LOG" \
  --log-level INFO

echo "[$(date)] sync complete" >> "$LOG"
