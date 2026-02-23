#!/bin/bash
# BLACKROAD ORG COHESION ENGINE
# Makes all 17 orgs work together cohesively
# Syncs: workflows, agent labels, branch protections
# Runs on Pi fleet (self-hosted = $0)

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}▶${NC}  $1"; }

ORGS=(
  "BlackRoad-OS-Inc" "BlackRoad-OS" "blackboxprogramming"
  "BlackRoad-AI" "BlackRoad-Cloud" "BlackRoad-Security"
  "BlackRoad-Media" "BlackRoad-Foundation" "BlackRoad-Interactive"
  "BlackRoad-Hardware" "BlackRoad-Labs" "BlackRoad-Studio"
  "BlackRoad-Ventures" "BlackRoad-Education" "BlackRoad-Gov"
  "Blackbox-Enterprises" "BlackRoad-Archive"
)

declare -A ORG_PRIMARY_REPO=(
  ["BlackRoad-OS-Inc"]="blackroad"
  ["BlackRoad-OS"]="blackroad-os"
  ["blackboxprogramming"]="blackroad-cli"
  ["BlackRoad-AI"]="blackroad-ai-api-gateway"
  ["BlackRoad-Cloud"]=".github"
  ["BlackRoad-Security"]=".github"
  ["BlackRoad-Media"]=".github"
  ["BlackRoad-Foundation"]=".github"
  ["BlackRoad-Interactive"]=".github"
  ["BlackRoad-Hardware"]=".github"
  ["BlackRoad-Labs"]=".github"
  ["BlackRoad-Studio"]=".github"
  ["BlackRoad-Ventures"]=".github"
  ["BlackRoad-Education"]=".github"
  ["BlackRoad-Gov"]=".github"
  ["Blackbox-Enterprises"]="blackbox-n8n"
  ["BlackRoad-Archive"]=".github"
)

AGENT_LABELS=(
  "agent:CECE|9C27B0|💜 Production Guardian"
  "agent:LUCIDIA|00BCD4|🌀 Integration Thinker"
  "agent:ALICE|4CAF50|🚪 Feature Executor"
  "agent:OCTAVIA|FF9800|⚡ Bug Crusher"
  "agent:CIPHER|212121|🔐 Security Guardian"
  "agent:ECHO|673AB7|📡 Knowledge Keeper"
  "agent:PRISM|E91E63|🔮 Data Analyst"
  "agent:ARIA|2196F3|🎵 Release Harmonizer"
  "agent:SHELLFISH|FF5722|🐚 SF Hacker"
)

sync_labels() {
  local org="$1" repo="${ORG_PRIMARY_REPO[$1]:-}"
  [[ -z "$repo" ]] && return
  for ldef in "${AGENT_LABELS[@]}"; do
    IFS='|' read -r name color desc <<< "$ldef"
    gh api -X POST "repos/$org/$repo/labels" \
      --field name="$name" --field color="$color" --field description="$desc" \
      2>/dev/null || gh api -X PATCH "repos/$org/$repo/labels/$name" \
      --field color="$color" 2>/dev/null || true
  done
  echo "  ✅ $org: labels synced"
}

sync_workflow() {
  local org="$1" repo="${ORG_PRIMARY_REPO[$1]:-}"
  [[ -z "$repo" ]] && return
  local content
  content=$(base64 < /Users/alexa/blackroad/.github/workflows/continuous-engine.yml 2>/dev/null) || return
  gh api -X PUT "repos/$org/$repo/contents/.github/workflows/continuous-engine.yml" \
    --field message="chore(cohesion): sync continuous engine [skip ci]" \
    --field content="$content" 2>/dev/null && echo "  ✅ $org: workflow synced" || true
}

case "${1:-status}" in
  sync-labels)
    info "Syncing agent labels..."
    for org in "${!ORG_PRIMARY_REPO[@]}"; do sync_labels "$org" & done; wait
    log "Labels synced!"
    ;;
  sync-workflows)
    info "Syncing core workflows..."
    for org in "${!ORG_PRIMARY_REPO[@]}"; do sync_workflow "$org" & done; wait
    log "Workflows synced!"
    ;;
  full-sync)
    "$0" sync-labels && "$0" sync-workflows
    log "Full cohesion sync complete across ${#ORG_PRIMARY_REPO[@]}/17 orgs!"
    ;;
  status)
    echo "Orgs with primary repos: ${#ORG_PRIMARY_REPO[@]}/17"
    echo "Agent labels: ${#AGENT_LABELS[@]}"
    echo "Run: $0 full-sync"
    ;;
esac
