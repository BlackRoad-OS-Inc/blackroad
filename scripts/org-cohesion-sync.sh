#!/bin/bash
# BlackRoad Org Cohesion — propagates shared standards to all orgs
# Runs on self-hosted runner. Cost: $0.
set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }

GH_TOKEN="${GH_TOKEN:-$(gh auth token 2>/dev/null)}"
ORGS=(
  "BlackRoad-OS-Inc"
  "BlackRoad-OS"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Security"
)
TARGET_ORG="${1:-BlackRoad-OS-Inc}"
MAX_REPOS="${2:-10}"

# Files to propagate to every repo
SHARED_WORKFLOW='name: 🤖 BlackRoad Agent CI
on: [push, pull_request]
jobs:
  health:
    runs-on: [self-hosted, blackroad-fleet]
    if: github.repository_owner == '"'"'BlackRoad-OS-Inc'"'"' || github.repository_owner == '"'"'BlackRoad-OS'"'"'
    steps:
      - uses: actions/checkout@v4
      - name: 🔋 Health Check
        run: echo "✅ $(hostname) - $(date -u)"'

echo "═══════════════════════════════════════════════"
echo "  BlackRoad Org Cohesion Sync"
echo "  Target: $TARGET_ORG"
echo "═══════════════════════════════════════════════"

# Get repos for org
info "Fetching repos for $TARGET_ORG..."
REPOS=$(curl -s -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/orgs/$TARGET_ORG/repos?per_page=$MAX_REPOS&sort=updated" \
  | python3 -c "import json,sys; [print(r['name']) for r in json.load(sys.stdin) if not r.get('archived')]" 2>/dev/null)

COUNT=0
for REPO in $REPOS; do
  info "Processing $TARGET_ORG/$REPO..."
  
  # Get default branch
  DEFAULT_BRANCH=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$TARGET_ORG/$REPO" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('default_branch','main'))" 2>/dev/null)
  
  # Check if .github/agent.json exists
  AGENT_FILE=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$TARGET_ORG/$REPO/contents/.github/agent.json" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print('exists' if 'sha' in d else 'missing')" 2>/dev/null)
  
  if [ "$AGENT_FILE" = "missing" ]; then
    # Create agent.json for this repo
    AGENT_JSON=$(python3 -c "
import json, base64
data = {
  'repo': '$REPO',
  'org': '$TARGET_ORG',
  'runner': 'blackroad-fleet',
  'branch': '$DEFAULT_BRANCH',
  'created': '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
}
content = base64.b64encode(json.dumps(data, indent=2).encode()).decode()
print(content)
")
    
    curl -s -X PUT \
      -H "Authorization: token $GH_TOKEN" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$TARGET_ORG/$REPO/contents/.github/agent.json" \
      -d "{
        \"message\": \"🤖 Add agent identity\n\nCo-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>\",
        \"content\": \"$AGENT_JSON\",
        \"branch\": \"$DEFAULT_BRANCH\"
      }" > /dev/null 2>&1 && log "Added agent.json to $REPO" || warn "Skipped $REPO"
  else
    log "$REPO already has agent.json"
  fi
  
  COUNT=$((COUNT + 1))
done

echo ""
log "Cohesion sync complete: $COUNT repos processed in $TARGET_ORG"
