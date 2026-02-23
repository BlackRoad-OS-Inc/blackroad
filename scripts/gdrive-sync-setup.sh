#!/bin/bash
# Google Drive Sync for BlackRoad local files
# Uses rclone with service account (no OAuth prompt)
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
BLACKROAD_DIR="/Users/alexa/blackroad"
GDRIVE_REMOTE="gdrive-blackroad"
GDRIVE_FOLDER="BlackRoad-OS-Backup"

install_rclone() {
    which rclone || curl -s https://rclone.org/install.sh | sudo bash
    echo "rclone version: $(rclone --version | head -1)"
}

setup_gdrive() {
    echo -e "${CYAN}Setting up Google Drive remote...${NC}"
    mkdir -p "$(dirname $RCLONE_CONFIG)"
    
    # Check if already configured
    if rclone listremotes | grep -q "$GDRIVE_REMOTE:"; then
        echo "✅ Remote already configured"
        return
    fi
    
    cat << EOF
To set up Google Drive sync:

1. Create a service account at: https://console.cloud.google.com/iam-admin/serviceaccounts
2. Enable Google Drive API
3. Download the JSON key
4. Run: rclone config
   - Name: $GDRIVE_REMOTE
   - Storage: drive
   - Auth: service_account_file
   - service_account_file: /path/to/key.json
   - scope: drive

OR run interactively:
  rclone config create $GDRIVE_REMOTE drive scope drive

For headless Pi setup, use service account JSON.
EOF
}

sync_to_gdrive() {
    local DRY_RUN=${1:-"--dry-run"}
    echo -e "${CYAN}Syncing $BLACKROAD_DIR → $GDRIVE_REMOTE:$GDRIVE_FOLDER${NC}"
    
    rclone sync "$BLACKROAD_DIR" "$GDRIVE_REMOTE:$GDRIVE_FOLDER" \
        $DRY_RUN \
        --exclude ".git/**" \
        --exclude "node_modules/**" \
        --exclude "*.save" \
        --exclude "orgs/**" \
        --exclude "repos/**" \
        --exclude "cece-logs/**" \
        --exclude "*.log" \
        --progress \
        --transfers 8 \
        --checkers 16
}

create_cron() {
    # Run sync every hour
    (crontab -l 2>/dev/null; echo "0 * * * * $0 sync >> /tmp/gdrive-sync.log 2>&1") | crontab -
    echo "✅ Hourly sync cron installed"
}

case "${1:-help}" in
    install) install_rclone ;;
    setup)   setup_gdrive ;;
    sync)    sync_to_gdrive "--progress" ;;
    dry-run) sync_to_gdrive "--dry-run" ;;
    cron)    create_cron ;;
    *)
        echo "Usage: $0 {install|setup|sync|dry-run|cron}"
        echo "Google Drive sync for BlackRoad files"
        ;;
esac
