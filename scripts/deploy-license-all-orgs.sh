#!/bin/bash
# Deploy BlackRoad Proprietary LICENSE to ALL repos across ALL orgs
# BlackRoad OS, Inc. — Alexa Louise Amundson
set -euo pipefail

LICENSE_FILE="/Users/alexa/blackroad/LICENSE-BLACKROAD-PROPRIETARY"
LOG_FILE="/Users/alexa/blackroad/scripts/license-deploy.log"
ERRORS_FILE="/Users/alexa/blackroad/scripts/license-deploy-errors.log"

# All 16 orgs + personal account
ORGS=(
  "BlackRoad-OS-Inc"
  "BlackRoad-OS"
  "blackboxprogramming"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Security"
  "BlackRoad-Foundation"
  "BlackRoad-Media"
  "BlackRoad-Hardware"
  "BlackRoad-Education"
  "BlackRoad-Gov"
  "BlackRoad-Labs"
  "BlackRoad-Studio"
  "BlackRoad-Ventures"
  "BlackRoad-Interactive"
  "BlackRoad-Archive"
  "Blackbox-Enterprises"
)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PINK='\033[38;5;205m'
NC='\033[0m'

# Counters
TOTAL=0
CREATED=0
UPDATED=0
SKIPPED=0
FAILED=0

# Base64 encode the license
LICENSE_B64=$(base64 -i "$LICENSE_FILE")

echo -e "${PINK}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${PINK}║  BLACKROAD OS — PROPRIETARY LICENSE DEPLOYMENT       ║${NC}"
echo -e "${PINK}║  Deploying to ALL repos across ALL 17 organizations  ║${NC}"
echo -e "${PINK}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# Timestamp
echo "=== LICENSE DEPLOYMENT STARTED $(date -u '+%Y-%m-%dT%H:%M:%SZ') ===" > "$LOG_FILE"
echo "=== ERRORS ===" > "$ERRORS_FILE"

deploy_to_repo() {
  local org="$1"
  local repo="$2"

  TOTAL=$((TOTAL + 1))

  # Check if LICENSE already exists (get SHA if it does)
  local existing_sha=""
  existing_sha=$(gh api "repos/$org/$repo/contents/LICENSE" --jq '.sha' 2>/dev/null || echo "")

  local msg="BlackRoad OS, Inc. Proprietary License — All Rights Reserved

Deployed by BlackRoad License Automation
© 2024-2026 BlackRoad OS, Inc.
Founder: Alexa Louise Amundson"

  if [ -n "$existing_sha" ]; then
    # Update existing LICENSE
    local result
    result=$(gh api "repos/$org/$repo/contents/LICENSE" \
      -X PUT \
      -f message="$msg" \
      -f content="$LICENSE_B64" \
      -f sha="$existing_sha" \
      --jq '.commit.sha' 2>&1) || true

    if [[ "$result" == *"error"* ]] || [ -z "$result" ]; then
      echo -e "  ${RED}✗${NC} $org/$repo — FAILED (update): $result"
      echo "FAILED UPDATE: $org/$repo — $result" >> "$ERRORS_FILE"
      FAILED=$((FAILED + 1))
    else
      echo -e "  ${YELLOW}↑${NC} $org/$repo — UPDATED (${result:0:7})"
      echo "UPDATED: $org/$repo — $result" >> "$LOG_FILE"
      UPDATED=$((UPDATED + 1))
    fi
  else
    # Create new LICENSE
    local result
    result=$(gh api "repos/$org/$repo/contents/LICENSE" \
      -X PUT \
      -f message="$msg" \
      -f content="$LICENSE_B64" \
      --jq '.commit.sha' 2>&1) || true

    if [[ "$result" == *"error"* ]] || [ -z "$result" ]; then
      echo -e "  ${RED}✗${NC} $org/$repo — FAILED (create): $result"
      echo "FAILED CREATE: $org/$repo — $result" >> "$ERRORS_FILE"
      FAILED=$((FAILED + 1))
    else
      echo -e "  ${GREEN}+${NC} $org/$repo — CREATED (${result:0:7})"
      echo "CREATED: $org/$repo — $result" >> "$LOG_FILE"
      CREATED=$((CREATED + 1))
    fi
  fi
}

for org in "${ORGS[@]}"; do
  echo ""
  echo -e "${CYAN}━━━ $org ━━━${NC}"

  # Get all repos for this org (paginated)
  local_repos=()
  page=1
  while true; do
    batch=$(gh repo list "$org" --limit 100 --json name,isArchived --jq '.[] | select(.isArchived == false) | .name' 2>/dev/null || \
            gh api "users/$org/repos?per_page=100&page=$page" --jq '.[].name' 2>/dev/null || echo "")

    if [ -z "$batch" ]; then
      break
    fi

    while IFS= read -r r; do
      [ -n "$r" ] && local_repos+=("$r")
    done <<< "$batch"

    # If we got fewer than 100, we're done
    count=$(echo "$batch" | wc -l | tr -d ' ')
    if [ "$count" -lt 100 ]; then
      break
    fi
    page=$((page + 1))
  done

  echo -e "  Found ${#local_repos[@]} repos"

  for repo in "${local_repos[@]}"; do
    deploy_to_repo "$org" "$repo"
    # Small delay to avoid rate limiting
    sleep 0.3
  done
done

echo ""
echo -e "${PINK}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${PINK}║  DEPLOYMENT COMPLETE                                 ║${NC}"
echo -e "${PINK}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${PINK}║${NC}  Total repos processed: ${CYAN}$TOTAL${NC}"
echo -e "${PINK}║${NC}  New LICENSE created:   ${GREEN}$CREATED${NC}"
echo -e "${PINK}║${NC}  Existing updated:      ${YELLOW}$UPDATED${NC}"
echo -e "${PINK}║${NC}  Failed:                ${RED}$FAILED${NC}"
echo -e "${PINK}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Log: $LOG_FILE"
echo "Errors: $ERRORS_FILE"
echo ""
echo "=== COMPLETED $(date -u '+%Y-%m-%dT%H:%M:%SZ') ===" >> "$LOG_FILE"
echo "Total: $TOTAL | Created: $CREATED | Updated: $UPDATED | Failed: $FAILED" >> "$LOG_FILE"
