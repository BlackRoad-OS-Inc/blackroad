#!/bin/bash
# BlackRoad Fleet Status Dashboard
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🚀 BLACKROAD FLEET STATUS           ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"

NODES=(
  "cecilia:192.168.4.89:Pi5+Hailo"
  "octavia:192.168.4.38:Pi5"
  "aria:192.168.4.82:Pi5"
  "alice:192.168.4.49:Pi4"
  "gematria:159.65.43.12:DO"
  "anastasia:174.138.44.45:DO"
)

echo ""
echo -e "${YELLOW}Nodes:${NC}"
for NODE_INFO in "${NODES[@]}"; do
  NAME="${NODE_INFO%%:*}"
  REST="${NODE_INFO#*:}"
  IP="${REST%%:*}"
  TYPE="${REST##*:}"
  
  STATUS=$(ssh -o ConnectTimeout=3 -o BatchMode=yes blackroad@$IP \
    'echo "$(hostname) $(uptime -p 2>/dev/null || uptime)"' 2>/dev/null)
  
  if [ -n "$STATUS" ]; then
    echo -e "  ${GREEN}✅ ${NAME}${NC} (${IP}) [${TYPE}] - ${STATUS}"
  else
    echo -e "  ${RED}❌ ${NAME}${NC} (${IP}) [${TYPE}] - offline"
  fi
done

echo ""
echo -e "${YELLOW}Runners:${NC}"
gh api /repos/BlackRoad-OS-Inc/blackroad/actions/runners \
  --jq '.runners[] | "  \(if .status == "online" then "✅" else "❌" end) \(.name) [\(.status)]"' 2>/dev/null | sort -u

echo ""
echo -e "${YELLOW}Recent Workflows:${NC}"
gh run list --limit 5 2>/dev/null | head -6
