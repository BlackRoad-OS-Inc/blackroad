#!/bin/bash
# BlackRoad OS - Org Cohesion Script
# Ensures all 17 orgs have consistent settings, secrets, and workflows

set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

log() { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}ℹ️${NC} $1"; }

ORGS=(
  "BlackRoad-OS-Inc"
  "BlackRoad-OS"
  "blackboxprogramming"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Security"
  "BlackRoad-Hardware"
  "BlackRoad-Foundation"
  "BlackRoad-Interactive"
  "BlackRoad-Labs"
  "BlackRoad-Studio"
  "BlackRoad-Ventures"
  "BlackRoad-Education"
  "BlackRoad-Gov"
  "BlackRoad-Media"
  "Blackbox-Enterprises"
  "BlackRoad-Archive"
)

RAILWAY_TOKEN="${RAILWAY_TOKEN:-$(cat ~/.blackroad/vault/railway_token 2>/dev/null)}"
CF_TOKEN="${CF_TOKEN:-$(cat ~/.blackroad/vault/cf_api_token 2>/dev/null)}"
CF_ACCOUNT="848cf0b18d51e0170e0d1537aec3505a"

# Set secrets for key repos in each org
set_org_secrets() {
  local org="$1"
  info "Setting secrets for $org..."
  
  # Try to set org-level secrets (requires admin)
  gh secret set CLOUDFLARE_API_TOKEN --org "$org" --visibility all --body "$CF_TOKEN" 2>/dev/null \
    && log "$org: CF token set" \
    || echo "  ⚠️  $org: CF token (no org admin access)"
    
  gh secret set RAILWAY_TOKEN --org "$org" --visibility all --body "$RAILWAY_TOKEN" 2>/dev/null \
    && log "$org: Railway token set" \
    || echo "  ⚠️  $org: Railway token (no org admin access)"
    
  gh secret set CLOUDFLARE_ACCOUNT_ID --org "$org" --visibility all --body "$CF_ACCOUNT" 2>/dev/null \
    && log "$org: CF account ID set" || true
}

# Check org runner registration
check_org_runners() {
  local org="$1"
  count=$(gh api "orgs/$org/actions/runners" --jq '.total_count' 2>/dev/null || echo "0")
  echo "  $org: $count runners"
}

case "${1:-status}" in
  secrets)
    for org in "${ORGS[@]}"; do
      set_org_secrets "$org"
    done
    ;;
  runners)
    for org in "${ORGS[@]}"; do
      check_org_runners "$org"
    done
    ;;
  status)
    info "Org cohesion status:"
    for org in "${ORGS[@]}"; do
      repos=$(gh api "orgs/$org/repos" --jq 'length' 2>/dev/null || echo "?")
      runners=$(gh api "orgs/$org/actions/runners" --jq '.total_count' 2>/dev/null || echo "?")
      echo "  $org: repos=$repos runners=$runners"
    done
    ;;
esac
