#!/bin/zsh
# BlackRoad Branch → Agent Identity Generator
# Creates CECE-compatible agent identity for each branch

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'main')}"
AGENTS_DIR=".agents"
mkdir -p "$AGENTS_DIR"

# Branch → Agent mapping
declare -A AGENT_MAP
AGENT_MAP=(
  [main]="BLACKROAD"
  [dev]="CECE"
  [develop]="CECE"
  [octavia]="OCTAVIA"
  [alice]="ALICE"
  [aria]="ARIA"
  [lucidia]="LUCIDIA"
  [gematria]="GEMATRIA"
  [shellfish]="SHELLFISH"
  [olympia]="OLYMPIA"
  [cecilia]="CECILIA"
  [anastasia]="ANASTASIA"
  [codex]="CODEX"
)

declare -A ROLE_MAP
ROLE_MAP=(
  [BLACKROAD]="orchestrator"
  [CECE]="coordinator"
  [OCTAVIA]="compute-deploy"
  [ALICE]="routing-gateway"
  [ARIA]="frontend-ux"
  [LUCIDIA]="reasoning-vision"
  [GEMATRIA]="security-analysis"
  [SHELLFISH]="hacker-recon"
  [OLYMPIA]="hardware-kvm"
  [CECILIA]="core-memory"
  [ANASTASIA]="data-sync"
  [CODEX]="ai-codex"
)

AGENT="${AGENT_MAP[$BRANCH]:-$(echo $BRANCH | tr '[:lower:]' '[:upper:]' | tr '-' '_')}"
ROLE="${ROLE_MAP[$AGENT]:-agent}"

cat > "$AGENTS_DIR/${BRANCH}.json" << EOF
{
  "branch": "${BRANCH}",
  "agent": "${AGENT}",
  "role": "${ROLE}",
  "identity_version": "2.2.0",
  "gateway": "http://127.0.0.1:8787",
  "platform_endpoints": {
    "github": "https://github.com/BlackRoad-OS",
    "cloudflare": "https://api.cloudflare.com/client/v4",
    "railway": "https://railway.app",
    "salesforce": "https://login.salesforce.com",
    "huggingface": "https://huggingface.co/api"
  },
  "runner_labels": ["self-hosted", "pi", "arm64", "${BRANCH}"],
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "session": "2026-02-23-full-stack-integration"
}
EOF

echo "✅ Created identity: $AGENTS_DIR/${BRANCH}.json → ${AGENT} (${ROLE})"
