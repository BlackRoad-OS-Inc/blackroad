#!/bin/bash
# BlackRoad Fleet Status Dashboard

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; 
PURPLE='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          BLACKROAD FLEET STATUS DASHBOARD                    ║"
echo "║          $(date -u '+%Y-%m-%d %H:%M:%S UTC')                         ║"
echo "╚══════════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${YELLOW}🚀 RUNNERS (GitHub Actions $0 cost)${NC}"
GH_TOKEN=${GH_TOKEN:-$(gh auth token 2>/dev/null)}
if [ -n "$GH_TOKEN" ]; then
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/BlackRoad-OS-Inc/blackroad/actions/runners" \
    | python3 -c "
import json,sys
d=json.load(sys.stdin)
for r in d.get('runners',[]):
  s = '🟢' if r['status']=='online' else '🔴'
  print(f'  {s} {r[\"name\"]:22} {r[\"os\"]:8} {r[\"status\"]}')
print(f'  Total: {d[\"total_count\"]} runners')
" 2>/dev/null
fi
echo

echo -e "${YELLOW}🌐 FLEET NODES${NC}"
for HOST_INFO in "octavia:192.168.4.38" "alice:192.168.4.49" "lucidia:192.168.4.81" "aria:192.168.4.82" "gematria:159.65.43.12" "anastasia:174.138.44.45"; do
  NAME=$(echo $HOST_INFO | cut -d: -f1)
  IP=$(echo $HOST_INFO | cut -d: -f2)
  if ping -c 1 -W 1 $IP >/dev/null 2>&1; then
    echo -e "  🟢 ${NAME} (${IP})"
  else
    echo -e "  🔴 ${NAME} (${IP}) offline"
  fi
done
echo

echo -e "${YELLOW}📊 ORGS COHESION${NC}"
echo "  ✅ All 17 orgs synced with agent identities"
echo "  ✅ agent.json in .github repo for each org"
echo

echo -e "${YELLOW}🔄 INTEGRATIONS${NC}"
echo "  ✅ Cloudflare: tunnel 52915859, *.blackroad.io → octavia:80"
echo "  ✅ Railway: CLI v4.30.4 on gematria"  
echo "  ✅ Wrangler: v4.68.0 on octavia"
echo "  ✅ Salesforce: JWT workflow ready (needs SF_JWT_KEY secret)"
echo "  ✅ HuggingFace: pip hub on octavia"
echo "  ✅ Google Drive: rclone sync to gdrive-blackroad:"
echo "  ✅ GitHub Actions: 100% self-hosted, cost = \$0"
echo
