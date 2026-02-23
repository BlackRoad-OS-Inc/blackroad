#!/bin/bash
# BlackRoad Fleet Deploy - push code to all Pi nodes
set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

NODES=(
  "blackroad@192.168.4.89:cecilia"
  "blackroad@192.168.4.38:octavia"
  "blackroad@192.168.4.82:aria"
  "blackroad@192.168.4.49:alice"
  "blackroad@159.65.43.12:gematria"
  "blackroad@174.138.44.45:anastasia"
)

REPO_PATH="/home/blackroad/blackroad"
SCRIPT="${1:-echo 'fleet ok'}"

echo -e "${CYAN}🚀 Fleet Deploy — $(date)${NC}"
for NODE_INFO in "${NODES[@]}"; do
  HOST="${NODE_INFO%%:*}"
  NAME="${NODE_INFO##*:}"
  echo -n "  ${NAME}... "
  ssh -o ConnectTimeout=5 -o BatchMode=yes "$HOST" \
    "cd $REPO_PATH 2>/dev/null && git pull --ff-only origin master 2>&1 | tail -1" 2>/dev/null \
    && echo -e "${GREEN}✅${NC}" || echo "⚠️ skip"
done
echo -e "${GREEN}✅ Fleet deploy complete${NC}"
