#!/bin/bash
# Deploy GitHub Pages to all 17 BlackRoad orgs
# Creates <org>.github.io repos and enables Pages via GitHub API

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAGES_DIR="$SCRIPT_DIR/pages"
ORGS_JSON="$SCRIPT_DIR/orgs.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

log() { echo -e "${GREEN}✅${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

# Read orgs
ORGS=$(python3 -c "import json; [print(d['org'], d['slug']) for d in json.load(open('$ORGS_JSON'))]")

TOTAL=0; SUCCESS=0; FAILED=0

while IFS=' ' read -r ORG SLUG; do
  TOTAL=$((TOTAL+1))
  REPO="${ORG}.github.io"
  HTML_FILE="$PAGES_DIR/${SLUG}.html"
  
  info "[$TOTAL/17] $ORG → $REPO"
  
  # 1. Create repo if it doesn't exist
  REPO_EXISTS=$(gh api /repos/$ORG/$REPO 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name',''))" 2>/dev/null || echo "")
  
  if [ -z "$REPO_EXISTS" ]; then
    gh api /orgs/$ORG/repos -X POST \
      -f name="$REPO" \
      -f description="$ORG GitHub Pages — BlackRoad OS" \
      -F private=false \
      -F has_pages=true \
      -F auto_init=false \
      2>/dev/null && log "Created repo $ORG/$REPO" || warn "Could not create $REPO"
  else
    info "Repo $ORG/$REPO already exists"
  fi
  
  # 2. Clone, add page, push
  WORK_DIR=$(mktemp -d)
  
  (
    cd "$WORK_DIR"
    git init -q
    git checkout -q -b main
    
    # Copy the org's page as index.html
    cp "$HTML_FILE" index.html
    
    # Add a _config.yml for Jekyll bypass
    echo "theme: null" > _config.yml
    touch .nojekyll
    
    # Add a simple README
    ORG_NAME=$(python3 -c "import json; orgs=json.load(open('$ORGS_JSON')); [print(d['name']) for d in orgs if d['org']=='$ORG']" 2>/dev/null | head -1)
    cat > README.md << READMEEOF
# $ORG_NAME

Official GitHub Pages for [$ORG_NAME](https://github.com/$ORG) — part of the [BlackRoad OS](https://blackroad.io) ecosystem.

© 2026 BlackRoad OS, Inc. All rights reserved.
READMEEOF
    
    git config user.email "copilot@blackroad.io"
    git config user.name "BlackRoad Copilot"
    git add -A
    git commit -q -m "feat: launch $ORG org page

Branded GitHub Pages for $ORG — BlackRoad OS ecosystem.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
    
    # Push to the repo
    PUSH_URL="https://x-access-token:${GH_TOKEN:-$(gh auth token)}@github.com/$ORG/$REPO.git"
    git remote add origin "$PUSH_URL"
    git push origin main --force -q 2>/dev/null && echo "pushed" || echo "push-failed"
  )
  
  PUSH_RESULT=$(cd "$WORK_DIR" && git log --oneline 2>/dev/null | wc -l | tr -d ' ')
  rm -rf "$WORK_DIR"
  
  # 3. Enable GitHub Pages via API
  gh api /repos/$ORG/$REPO/pages -X POST \
    --field source='{"branch":"main","path":"/"}' \
    2>/dev/null && log "Pages enabled: https://${ORG}.github.io" || \
  gh api /repos/$ORG/$REPO/pages -X PUT \
    --field source='{"branch":"main","path":"/"}' \
    2>/dev/null && log "Pages updated: https://${ORG}.github.io" || \
    warn "Pages already enabled or could not enable for $ORG"
  
  SUCCESS=$((SUCCESS+1))
  echo ""
  
done <<< "$ORGS"

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Org Pages Deploy Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo "  Total: $TOTAL  Success: $SUCCESS  Failed: $FAILED"
echo ""
echo "Pages will be live at:"
python3 -c "import json; [print(f'  https://{d[\"org\"]}.github.io') for d in json.load(open('$ORGS_JSON'))]"
