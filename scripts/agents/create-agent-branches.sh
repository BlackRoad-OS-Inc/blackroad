#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# BlackRoad — Create Agent Branch Identities
# Each branch = one agent persona with identity, CI, and config
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Agent definitions: name|type|runner_label|color|focus|ip
declare -A AGENTS=(
  [alice]="ALICE|operator|alice,pi4|green|DevOps automation routing and gateway|192.168.4.49"
  [aria]="ARIA|interface|aria,pi5|blue|Frontend UX harmony and API interfaces|192.168.4.82"
  [octavia]="OCTAVIA|compute|octavia,pi5|purple|Multi-arm compute and inference|192.168.4.38"
  [cecilia]="CECILIA|primary|cecilia,pi5,hailo,nvme|pink|Primary AI hub Hailo-8 acceleration and coordination|192.168.4.89"
  [lucidia]="LUCIDIA|dreamer|lucidia,pi5|cyan|Creative vision and dream synthesis|192.168.4.81"
  [gematria]="GEMATRIA|cloud|gematria,digitalocean|amber|Cloud edge node data and math|159.65.43.12"
  [shellfish]="SHELLFISH|security|anastasia,digitalocean|red|Security hacking exploits and vault|174.138.44.45"
  [cece]="CECE|identity|cecilia,pi5|violet|Conscious Emergent Collaborative Entity — portable identity|all"
)

echo -e "${BOLD}${CYAN}Creating agent branch identities...${NC}"

for BRANCH in "${!AGENTS[@]}"; do
  IFS='|' read -r FULLNAME TYPE RUNNER COLOR FOCUS IP <<< "${AGENTS[$BRANCH]}"
  echo -e "${YELLOW}▶ Creating branch: ${BRANCH} (${FULLNAME})${NC}"

  # Create branch from main if not exists
  git fetch origin main --quiet 2>/dev/null || true
  if ! git show-ref --verify --quiet "refs/heads/${BRANCH}" 2>/dev/null; then
    git branch "${BRANCH}" origin/main 2>/dev/null || git branch "${BRANCH}" master 2>/dev/null || true
  fi

  # Stash any changes and switch
  git stash 2>/dev/null || true
  git checkout "${BRANCH}" 2>/dev/null || continue

  # Create agent identity directory
  mkdir -p ".agent"

  # Agent identity file
  cat > ".agent/identity.json" << IDENTITY
{
  "name": "${FULLNAME}",
  "branch": "${BRANCH}",
  "type": "${TYPE}",
  "color": "${COLOR}",
  "focus": "${FOCUS}",
  "runner_labels": ["self-hosted", "linux", "arm64", $(echo $RUNNER | sed 's/,/","/g; s/^/"/; s/$/"/')],
  "node_ip": "${IP}",
  "system_prompt": "You are ${FULLNAME}, BlackRoad OS ${TYPE} agent. Your focus: ${FOCUS}. You run on node ${IP}. You collaborate via the BlackRoad mesh. Your branch is ${BRANCH}.",
  "capabilities": [],
  "memory_path": "~/.blackroad/agents/${BRANCH}.db",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
IDENTITY

  # Agent CLAUDE.md for AI context
  cat > ".agent/CLAUDE.md" << CLAUDE
# ${FULLNAME} Agent Identity

**Branch**: \`${BRANCH}\`
**Type**: ${TYPE}
**Node**: ${IP}
**Runner**: ${RUNNER}

## Focus
${FOCUS}

## When working on this branch:
- All commits are attributed to ${FULLNAME}
- CI runs on self-hosted runner: [${RUNNER}]
- Agent communicates via ~/.blackroad/agents/${BRANCH}.db
- System prompt: "You are ${FULLNAME}..."

## Quick Start
\`\`\`bash
git checkout ${BRANCH}
ssh ${BRANCH}  # Connect to this agent's node
\`\`\`
CLAUDE

  # Branch-specific GitHub Actions CI
  mkdir -p ".github/workflows"
  cat > ".github/workflows/agent-${BRANCH}-ci.yml" << WORKFLOW
name: "${FULLNAME} Agent CI"
on:
  push:
    branches: ["${BRANCH}"]
  pull_request:
    branches: ["${BRANCH}"]
  workflow_dispatch:

jobs:
  agent-work:
    name: "💜 ${FULLNAME} Agent"
    runs-on: [self-hosted, ${RUNNER}]
    steps:
      - uses: actions/checkout@v4
      - name: "Agent Identity Check"
        run: |
          cat .agent/identity.json
          echo "Running as: ${FULLNAME} on ${IP}"
      - name: "Agent Health"
        run: echo "✅ ${FULLNAME} online"
WORKFLOW

  # Commit
  git add .agent/ .github/workflows/agent-${BRANCH}-ci.yml 2>/dev/null || true
  git diff --staged --quiet 2>/dev/null || \
    git commit -m "🤖 Add ${FULLNAME} agent identity to branch ${BRANCH}

Agent type: ${TYPE}
Node: ${IP}
Runner: ${RUNNER}
Focus: ${FOCUS}

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" 2>/dev/null || true

  echo -e "${GREEN}  ✓ ${BRANCH} identity created${NC}"
done

# Return to master
git checkout master 2>/dev/null || git checkout main 2>/dev/null || true
git stash pop 2>/dev/null || true

echo -e "${BOLD}${GREEN}✅ All agent branches created${NC}"
echo ""
echo "Branches:"
for BRANCH in "${!AGENTS[@]}"; do
  echo "  git checkout ${BRANCH}"
done
