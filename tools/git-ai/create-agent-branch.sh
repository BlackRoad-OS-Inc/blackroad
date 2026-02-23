#!/bin/zsh
# br git agent-branch <agent> [branch-suffix]
# Creates a branch with agent identity

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

AGENT_NAME="${1:u}"  # uppercase
SUFFIX="${2:-work}"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

declare -A AGENT_ROLES
AGENT_ROLES[ALICE]="DevOps,Salesforce,CI/CD"
AGENT_ROLES[ARIA]="Networking,Cloudflare,Frontend"
AGENT_ROLES[OCTAVIA]="Compute,Railway,Infrastructure"
AGENT_ROLES[CECE]="Planning,Integration,Coordination"
AGENT_ROLES[LUCIDIA]="AI,Research,Vision"
AGENT_ROLES[GEMATRIA]="Cloud,Backup,DigitalOcean"
AGENT_ROLES[OCTAVIA]="Compute,Railway,HuggingFace"

declare -A AGENT_COLORS
AGENT_COLORS[ALICE]="#00FF88"
AGENT_COLORS[ARIA]="#2979FF"
AGENT_COLORS[OCTAVIA]="#9C27B0"
AGENT_COLORS[CECE]="#FF1D6C"
AGENT_COLORS[LUCIDIA]="#00BCD4"
AGENT_COLORS[GEMATRIA]="#F5A623"

declare -A AGENT_HOSTS
AGENT_HOSTS[ALICE]="alice (192.168.4.49)"
AGENT_HOSTS[ARIA]="aria (192.168.4.82)"
AGENT_HOSTS[OCTAVIA]="octavia (192.168.4.38)"
AGENT_HOSTS[GEMATRIA]="gematria (159.65.43.12)"

BRANCH="feature/${(L)AGENT_NAME}-${SUFFIX}"

echo -e "${CYAN}Creating branch: ${BRANCH}${NC}"

git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"

# Write .agent-identity
cat > .agent-identity << JSON
{
  "agent": "${AGENT_NAME}",
  "branch": "${BRANCH}",
  "role": "${AGENT_ROLES[$AGENT_NAME]:-General}",
  "runner_label": "${(L)AGENT_NAME}",
  "pi_host": "${AGENT_HOSTS[$AGENT_NAME]:-unknown}",
  "color": "${AGENT_COLORS[$AGENT_NAME]:-#FFFFFF}",
  "created_at": "${TIMESTAMP}",
  "capabilities": ["${AGENT_ROLES[$AGENT_NAME]//,/\",\"}"],
  "session": "946e3529-60a0-4443-afae-dfc8960c4c3b"
}
JSON

git add .agent-identity
git commit -m "🤖 ${AGENT_NAME} branch identity: ${BRANCH}

Agent: ${AGENT_NAME}
Role: ${AGENT_ROLES[$AGENT_NAME]:-General}
Host: ${AGENT_HOSTS[$AGENT_NAME]:-unknown}
Session: 946e3529

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

echo -e "${GREEN}✓ Branch ${BRANCH} created with ${AGENT_NAME} identity${NC}"
