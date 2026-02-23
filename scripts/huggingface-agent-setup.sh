#!/bin/bash
# Register each Pi agent with HuggingFace
# Creates a Space per agent for model hosting / inference

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
HF_TOKEN="${HF_TOKEN:-$1}"

[ -z "$HF_TOKEN" ] && { echo "Usage: HF_TOKEN=xxx $0"; exit 1; }

AGENTS=("gematria" "octavia" "alice" "aria" "lucidia" "cecilia")
ORG="BlackRoad-OS"

for AGENT in "${AGENTS[@]}"; do
  NAME_UPPER=$(echo "$AGENT" | tr '[:lower:]' '[:upper:]')
  echo -e "${CYAN}🤗 Setting up HuggingFace Space for ${NAME_UPPER}...${NC}"
  
  # Create Space
  curl -s -X POST "https://huggingface.co/api/repos/create" \
    -H "Authorization: Bearer ${HF_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"space\",
      \"name\": \"${ORG}/${AGENT}-agent\",
      \"sdk\": \"static\",
      \"private\": false
    }" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if 'id' in d or 'url' in d:
    print('  ✅ Created: ${NAME_UPPER} space')
elif 'error' in d and 'exist' in d.get('error',''):
    print('  ℹ️  ${NAME_UPPER} space already exists')
else:
    print('  ⚠️  ${NAME_UPPER}:', d.get('error','unknown'))
" 2>/dev/null || echo "  ⚠️ Failed (check token)"
done

echo -e "${GREEN}✅ HuggingFace agent spaces configured${NC}"
