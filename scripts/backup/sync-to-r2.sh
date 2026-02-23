#!/bin/bash
# BlackRoad Backup Tier 3: → Cloudflare R2
# Requires: wrangler + CLOUDFLARE_API_TOKEN

set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

BUCKET="blackroad-backup"
DATE=$(date +%Y%m%d)

echo -e "${CYAN}☁️  Backup: → Cloudflare R2 (${BUCKET})${NC}"

# Use wrangler r2 object put
if ! command -v wrangler &>/dev/null; then
  source ~/.nvm/nvm.sh 2>/dev/null || true
  nvm use 20 2>/dev/null || true
fi

for DIR in scripts tools infra .github; do
  if [ -d "$DIR" ]; then
    tar czf /tmp/${DIR//\//-}-${DATE}.tar.gz "$DIR" --exclude="node_modules" 2>/dev/null
    wrangler r2 object put "${BUCKET}/$(hostname)/${DATE}/${DIR}.tar.gz" \
      --file "/tmp/${DIR//\//-}-${DATE}.tar.gz" 2>&1 | tail -1 || true
  fi
done
echo -e "${GREEN}✅ R2 backup complete${NC}"
