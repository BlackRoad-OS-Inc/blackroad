#!/bin/bash
# BlackRoad Backup Tier 2: Pi → DigitalOcean (gematria)
# Runs on cecilia, pushes to gematria via rsync

set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

GEMATRIA_IP="159.65.43.12"
GEMATRIA_USER="blackroad"
BACKUP_DIRS=("blackroad-sf" "tools" "scripts" "infra" ".github" "agents" "shared")
DEST_ROOT="/home/blackroad/backups/blackroad-$(date +%Y%m%d)"

echo -e "${CYAN}📦 Backup: Pi → DigitalOcean (gematria)${NC}"

for DIR in "${BACKUP_DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    echo -n "  Syncing $DIR... "
    rsync -az --delete \
      --exclude="node_modules" \
      --exclude=".git" \
      "$DIR" "${GEMATRIA_USER}@${GEMATRIA_IP}:${DEST_ROOT}/" 2>&1 | tail -1 && \
      echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}"
  fi
done
echo -e "${GREEN}✅ Backup to gematria complete${NC}"
