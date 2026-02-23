#!/bin/bash
# BlackRoad Cloudflare Worker Deploy Script
# NOTE: CF free tier = 500 workers MAX. Account is at limit.
# Strategy: Update EXISTING workers only (no new creates)

set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔥 BlackRoad Worker Deploy"
echo "  Strategy: Update existing workers only"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DEPLOYED=0; FAIL=0

for wdir in workers/*/; do
  worker=$(basename "$wdir")
  if [ -f "$wdir/wrangler.toml" ] && [ -f "$wdir/index.js" ]; then
    result=$(cd "$wdir" && npx wrangler deploy --keep-vars 2>&1)
    if echo "$result" | grep -qiE "Deployed|Published"; then
      echo -e "  ${GREEN}✅${NC} $worker"
      DEPLOYED=$((DEPLOYED+1))
    elif echo "$result" | grep -q "10037"; then
      echo -e "  ${CYAN}ℹ️${NC}  $worker (skipped — 500 worker limit, update only)"
      FAIL=$((FAIL+1))
    else
      echo -e "  ${RED}✘${NC}  $worker: $(echo "$result" | grep -i error | head -1)"
      FAIL=$((FAIL+1))
    fi
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${GREEN}✅ Deployed:${NC} $DEPLOYED | ${RED}Skipped:${NC} $FAIL"
echo ""
echo "  Main gateway: https://blackroad-agents.workers.dev"
echo "  Agent routes: /OCTAVIA /ALICE /GEMATRIA /LUCIDIA /ARIA"
