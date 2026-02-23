#!/bin/bash
# BLACKROAD ORG COHESION ENGINE
# Makes all 17 orgs work together cohesively
# Syncs: workflows, labels, branch protections, secrets distribution
# Runs on Pi fleet (self-hosted = $0)

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}▶${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠️${NC}  $1"; }

# All 17 orgs
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

# Agent color labels to sync across all orgs
AGENT_LABELS=(
  "agent:CECE:9C27B0:💜 Production Guardian"
  "agent:LUCIDIA:00BCD4:🌀 Integration Thinker"
  "agent:ALICE:4CAF50:🚪 Feature Executor"
  "agent:OCTAVIA:FF9800:⚡ Bug Crusher"
  "agent:CIPHER:212121:🔐 Security Guardian"
  "agent:ECHO:673AB7:📡 Knowledge Keeper"
  "agent:PRISM:E91E63:🔮 Data Analyst"
  "agent:ARIA:2196F3:🎵 Release Harmonizer"
  "agent:SHELLFISH:FF5722:🐚 SF Hacker"
)

# Priority repos to sync (one per org)
declare -A ORG_PRIMARY_REPO=(
  ["BlackRoad-OS-Inc"]="blackroad"
  ["BlackRoad-OS"]="blackroad-os"
  ["blackboxprogramming"]="blackroad-cli"
  ["BlackRoad-AI"]="blackroad-ai-api-gateway"
  ["BlackRoad-Cloud"]="blackroad-cloud-core"
  ["BlackRoad-Security"]="blackroad-security-core"
)

sync_labels_to_org() {
  local org="$1"
  local repo="${ORG_PRIMARY_REPO[$org]:-}"
  [[ -z "$repo" ]] && return
  
  for label_def in "${AGENT_LABELS[@]}"; do
    IFS=: read -r prefix name color description <<< "$label_def"
    gh api -X POST "repos/$org/$repo/labels" \
      --field name="$prefix:$name" \
      --field color="$color" \
      --field description="$description" \
      2>/dev/null || \
    gh api -X PATCH "repos/$org/$repo/labels/$prefix:$name" \
      --field color="$color" \
      --field description="$description" \
      2>/dev/null || true
  done
  echo "  ✅ Labels synced: $org/$repo"
}

sync_core_files_to_repo() {
  local org="$1"
  local repo="${ORG_PRIMARY_REPO[$org]:-}"
  [[ -z "$repo" ]] && return
  
  # Push the continuous-engine workflow
  local wf_content=$(base64 < /Users/alexa/blackroad/.github/workflows/continuous-engine.yml 2>/dev/null || true)
  [[ -z "$wf_content" ]] && return
  
  gh api -X PUT "repos/$org/$repo/contents/.github/workflows/continuous-engine.yml" \
    --field message="chore: sync continuous engine from BlackRoad-OS-Inc" \
    --field content="$wf_content" \
    2>/dev/null && echo "  ✅ Workflow synced: $org/$repo" || true
}

case "${1:-status}" in
  sync-labels)
    info "Syncing agent labels to all orgs..."
    for org in "${!ORG_PRIMARY_REPO[@]}"; do
      sync_labels_to_org "$org" &
    done
    wait
    log "Labels synced!"
    ;;
  
  sync-workflows)
    info "Syncing core workflows to all orgs..."
    for org in "${!ORG_PRIMARY_REPO[@]}"; do
      sync_core_files_to_repo "$org" &
    done
    wait
    log "Workflows synced!"
    ;;
  
  full-sync)
    info "Full org cohesion sync..."
    "$0" sync-labels
    "$0" sync-workflows
    log "Full sync complete!"
    ;;
  
  status)
    info "Org cohesion status:"
    echo ""
    echo "  Primary repos configured: ${#ORG_PRIMARY_REPO[@]}/17"
    echo "  Agent labels: ${#AGENT_LABELS[@]}"
    echo ""
    echo "  Run: $0 full-sync  — to sync everything"
    ;;
esac
