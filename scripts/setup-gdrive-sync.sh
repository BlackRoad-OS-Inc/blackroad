#!/bin/bash
# Google Drive Sync via rclone — runs on cecilia Pi
# Syncs /blackroad local files to cloud

echo "🔧 Setting up Google Drive sync on cecilia..."

ssh cecilia "
  # Install rclone if needed
  if ! command -v rclone &>/dev/null; then
    curl https://rclone.org/install.sh | sudo bash 2>/dev/null
    echo '✅ rclone installed'
  else
    echo '✅ rclone already installed: \$(rclone version | head -1)'
  fi

  # Create rclone config for Google Drive (requires OAuth - interactive first time)
  if rclone listremotes | grep -q 'gdrive:'; then
    echo '✅ Google Drive already configured'
  else
    echo '⚠️ Google Drive not configured yet.'
    echo '   Run: rclone config'
    echo '   Then add remote named \"gdrive\" as Google Drive'
  fi

  # Set up sync cron job
  CRON_JOB='0 3 * * * rclone sync ~/blackroad gdrive:BlackRoad --exclude \".git/**\" --log-file ~/.blackroad/gdrive-sync.log 2>&1'
  ( crontab -l 2>/dev/null | grep -v gdrive; echo \"\$CRON_JOB\" ) | crontab -
  echo '✅ Cron sync scheduled: daily at 3am UTC'

  # Create immediate sync script
  cat > ~/sync-to-gdrive.sh << 'SYNCEOF'
#!/bin/bash
echo \"🔄 Syncing to Google Drive...\"
rclone sync ~/blackroad gdrive:BlackRoad \
  --exclude \".git/**\" \
  --exclude \"node_modules/**\" \
  --exclude \"*.pyc\" \
  --transfers 8 \
  --checkers 16 \
  --log-file ~/.blackroad/gdrive-sync.log \
  --log-level INFO
echo \"✅ Sync complete: \$(date)\"
SYNCEOF
  chmod +x ~/sync-to-gdrive.sh
  echo '✅ ~/sync-to-gdrive.sh ready to run'
"
