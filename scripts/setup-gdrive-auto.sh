#!/bin/bash
# BLACKROAD → GOOGLE DRIVE AUTOMATED SYNC
# Uses rclone with existing token or headless setup

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

REMOTE="gdrive"
DEST="blackroad-backup"
SRC="/Users/alexa/blackroad"

# Check if already configured
if rclone listremotes 2>/dev/null | grep -q "^${REMOTE}:"; then
  echo -e "${GREEN}✅ Google Drive remote exists${NC}"
  
  # Run sync now
  echo -e "${CYAN}🔄 Syncing to Google Drive...${NC}"
  rclone sync "$SRC" "${REMOTE}:${DEST}" \
    --exclude ".git/**" \
    --exclude "node_modules/**" \
    --exclude "orgs/**/.git/**" \
    --exclude "repos/**" \
    --exclude "*.log" \
    --exclude ".DS_Store" \
    --exclude "cece-logs/**" \
    --fast-list \
    --transfers 8 \
    --progress \
    2>&1 | tail -5
  
  echo -e "${GREEN}✅ Sync complete${NC}"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"gdrive-sync\",\"status\":\"ok\",\"src\":\"$SRC\"}" \
    >> ~/.blackroad/logs/gdrive-sync.jsonl
else
  echo -e "${YELLOW}⚠️  Google Drive not configured yet.${NC}"
  echo ""
  echo "Run this to set up (needs browser once):"
  echo "  rclone config"
  echo ""
  echo "Then select: n (new), name=gdrive, type=drive, scope=drive"
  echo "Or paste an existing rclone.conf from another machine"
  echo ""
  echo "Existing rclone config path: ~/.config/rclone/rclone.conf"
  echo "Copy from another machine: scp other-machine:~/.config/rclone/rclone.conf ~/.config/rclone/"
fi
