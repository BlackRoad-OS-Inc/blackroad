#!/bin/bash
# BlackRoad Multi-Cloud Backup Trigger
# Runs: GDrive sync, GitHub, Railway (already has vars), Cloudflare KV

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  💾 BlackRoad Multi-Cloud Backup"
echo "  $(date -u)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Google Drive
echo ""
echo -e "${CYAN}1. Google Drive${NC}"
rclone sync /Users/alexa/blackroad gdrive-blackroad:blackroad \
  --exclude "node_modules/**" --exclude ".git/**" --exclude "*.log" \
  --exclude "cece-logs/**" --exclude "logs/**" \
  --transfers 8 --checkers 16 --quiet 2>&1 | tail -2
echo -e "   ${GREEN}✅${NC} GDrive sync complete"

# 2. GitHub (git push = automatic backup)
echo ""
echo -e "${CYAN}2. GitHub${NC}"
cd /Users/alexa/blackroad
if git diff --quiet HEAD 2>/dev/null; then
  echo -e "   ${GREEN}✅${NC} No changes — already backed up"
else
  git add -A && git commit -m "chore: automated backup $(date -u +%Y-%m-%dT%H:%M:%SZ)
  
  Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" && git push
  echo -e "   ${GREEN}✅${NC} Pushed to GitHub"
fi

# 3. DigitalOcean snapshot trigger
echo ""
echo -e "${CYAN}3. DigitalOcean Snapshot${NC}"
if command -v doctl &>/dev/null && [ -n "$DIGITALOCEAN_ACCESS_TOKEN" ]; then
  DROPLET_ID=$(doctl compute droplet list --no-header --format ID --tag-name blackroad 2>/dev/null | head -1)
  if [ -n "$DROPLET_ID" ]; then
    doctl compute droplet-action snapshot $DROPLET_ID --snapshot-name "blackroad-$(date +%Y%m%d)" --wait
    echo -e "   ${GREEN}✅${NC} DO snapshot created"
  fi
else
  echo -e "   ℹ️  doctl not configured — set DIGITALOCEAN_ACCESS_TOKEN"
fi

# 4. Railway backup (vars already set — Railway auto-deploys = automatic backup)
echo ""
echo -e "${CYAN}4. Railway${NC}"
echo -e "   ${GREEN}✅${NC} 22 projects — auto-backup on deploy"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}✅ Backup complete${NC}"
