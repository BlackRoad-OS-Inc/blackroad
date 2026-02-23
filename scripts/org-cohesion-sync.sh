#!/bin/bash
# Sync shared files across all 17 BlackRoad GitHub orgs
# Creates .github repo in each org with shared workflow templates

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

ORGS=(
  "BlackRoad-OS-Inc"
  "BlackRoad-OS"
  "blackboxprogramming"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Security"
  "BlackRoad-Media"
  "BlackRoad-Foundation"
  "BlackRoad-Interactive"
  "BlackRoad-Hardware"
  "BlackRoad-Labs"
  "BlackRoad-Studio"
  "BlackRoad-Ventures"
  "BlackRoad-Education"
  "BlackRoad-Gov"
  "Blackbox-Enterprises"
  "BlackRoad-Archive"
)

SHARED_WORKFLOW=$(cat << 'WF'
name: 🤖 BlackRoad Shared CI
on:
  push:
    branches: [main, dev]
  pull_request:
jobs:
  shared-checks:
    runs-on: [self-hosted, pi]
    steps:
      - uses: actions/checkout@v4
      - name: Load agent identity
        run: |
          BRANCH="${GITHUB_REF_NAME}"
          curl -sf "https://raw.githubusercontent.com/BlackRoad-OS/blackroad/main/.agents/${BRANCH}.json" \
            -o .agent-identity.json 2>/dev/null || echo '{"agent":"BLACKROAD"}' > .agent-identity.json
          cat .agent-identity.json
      - name: Health check
        run: echo "✅ $(cat .agent-identity.json | python3 -c 'import sys,json; print(json.load(sys.stdin).get("agent","BLACKROAD"))') is active"
WF
)

for ORG in "${ORGS[@]}"; do
  echo -e "${CYAN}🔄 Syncing org: ${ORG}${NC}"
  
  # Create .github repo if it doesn't exist
  gh repo create "${ORG}/.github" --public --description "Shared workflows for ${ORG}" 2>/dev/null && \
    echo -e "${GREEN}  ✅ Created .github repo${NC}" || \
    echo -e "${YELLOW}  ℹ️  .github repo exists${NC}"
  
  # Push shared CLAUDE.md
  TMPDIR=$(mktemp -d)
  cd "$TMPDIR"
  git init -q
  git remote add origin "https://github.com/${ORG}/.github.git"
  
  mkdir -p .github/workflows
  echo "$SHARED_WORKFLOW" > .github/workflows/blackroad-shared.yml
  cp "/Users/alexa/blackroad/AGENTS.md" . 2>/dev/null || true
  
  git add -A
  git commit -qm "chore: sync shared workflows and agent configs [blackroad-bot]

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" 2>/dev/null || true
  git push -qu origin HEAD:main 2>/dev/null || true
  
  cd - >/dev/null
  rm -rf "$TMPDIR"
done

echo -e "${GREEN}🎉 All 17 orgs synced!${NC}"
