#!/bin/bash
# BLACKROAD OS, INC. — Push LICENSE to every GitHub repo
# Deploys the 1,308-line proprietary license to ALL repos across ALL orgs

LICENSE_B64="/tmp/LICENSE_B64.txt"
COMMIT_MSG="legal: Deploy BlackRoad OS, Inc. Proprietary License v2 — 21 sections, hardware sovereignty, AI provider tenant obligations"
LOG="/tmp/license-push-log.txt"
ERRORS="/tmp/license-push-errors.txt"

> "$LOG"
> "$ERRORS"

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

push_license() {
  local owner="$1"
  local repo="$2"
  local full="${owner}/${repo}"

  # Check if LICENSE exists (get SHA for update)
  local sha
  sha=$(gh api "repos/${full}/contents/LICENSE" --jq '.sha' 2>/dev/null)

  if [ -n "$sha" ] && [ "$sha" != "null" ]; then
    # Update existing
    gh api "repos/${full}/contents/LICENSE" \
      -X PUT \
      -f message="$COMMIT_MSG" \
      -f content="$(cat $LICENSE_B64)" \
      -f sha="$sha" \
      --jq '.commit.sha' 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "UPDATED: $full" | tee -a "$LOG"
    else
      echo "ERROR: $full (update failed)" | tee -a "$ERRORS"
    fi
  else
    # Create new
    gh api "repos/${full}/contents/LICENSE" \
      -X PUT \
      -f message="$COMMIT_MSG" \
      -f content="$(cat $LICENSE_B64)" \
      --jq '.commit.sha' 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "CREATED: $full" | tee -a "$LOG"
    else
      echo "ERROR: $full (create failed)" | tee -a "$ERRORS"
    fi
  fi
}

for org in "${ORGS[@]}"; do
  echo "=== Processing $org ==="

  # Get all repos (paginated, up to 500)
  page=1
  while true; do
    repos=$(gh api "orgs/${org}/repos?per_page=100&page=${page}&type=all" --jq '.[].name' 2>/dev/null)

    # If empty or error, try user repos (for personal account)
    if [ -z "$repos" ] && [ "$page" -eq 1 ]; then
      repos=$(gh api "users/${org}/repos?per_page=100&page=${page}&type=all" --jq '.[].name' 2>/dev/null)
    fi

    if [ -z "$repos" ]; then
      break
    fi

    for repo in $repos; do
      push_license "$org" "$repo"
    done

    page=$((page + 1))

    # Safety: max 10 pages (1000 repos per org)
    if [ "$page" -gt 10 ]; then
      break
    fi
  done
done

echo ""
echo "=== COMPLETE ==="
echo "Success: $(wc -l < "$LOG" | tr -d ' ')"
echo "Errors: $(wc -l < "$ERRORS" | tr -d ' ')"
