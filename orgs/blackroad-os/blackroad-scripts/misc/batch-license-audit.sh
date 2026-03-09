#!/bin/bash

# ═══════════════════════════════════════════════════════════
# ⚖️ BATCH LICENSE AUDIT - ALL BLACKROAD REPOS
# ═══════════════════════════════════════════════════════════
# Systematically audit all 199 repositories
# Agent: cecilia-production-enhancer-3ce313b2
# ═══════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}⚖️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }

# Get all repos from BlackRoad-OS
REPOS=$(gh repo list BlackRoad-OS --limit 200 --json name --jq '.[].name')

TOTAL=$(echo "$REPOS" | wc -l | tr -d ' ')
CURRENT=0
SUCCESS=0
FAILED=0

log_info "Starting batch LICENSE audit across $TOTAL repositories"

# Log to memory
~/memory-system.sh log started "batch-license-audit-all" "Auditing LICENSE files across all $TOTAL BlackRoad repos" "cecilia,license,batch" 2>/dev/null || true

while IFS= read -r repo; do
    CURRENT=$((CURRENT + 1))
    log_info "[$CURRENT/$TOTAL] Processing: $repo"

    if ~/blackroad-license-auditor.sh "$repo" 2>&1 | tee /tmp/license-audit-$repo.log; then
        SUCCESS=$((SUCCESS + 1))
        log_success "[$CURRENT/$TOTAL] ✅ $repo"
    else
        FAILED=$((FAILED + 1))
        echo "❌ [$CURRENT/$TOTAL] Failed: $repo" | tee -a /tmp/license-audit-failures.log
    fi

    # Progress logging every 10 repos
    if [ $((CURRENT % 10)) -eq 0 ]; then
        ~/memory-system.sh log progress "license-audit-progress-$CURRENT" "Audited $CURRENT/$TOTAL repos ($SUCCESS success, $FAILED failed)" "cecilia,license" 2>/dev/null || true
    fi

    # Rate limiting to avoid overwhelming GitHub
    sleep 2
done <<< "$REPOS"

# Final summary
log_success "Batch LICENSE Audit Complete!"
echo ""
echo "═══════════════════════════════════════"
echo "Total Repositories: $TOTAL"
echo "Successfully Audited: $SUCCESS"
echo "Failed: $FAILED"
echo "Success Rate: $(( SUCCESS * 100 / TOTAL ))%"
echo "═══════════════════════════════════════"

# Log completion
~/memory-system.sh log completed "batch-license-audit-complete" "Audited $TOTAL repos: $SUCCESS success, $FAILED failed" "cecilia,license,complete" 2>/dev/null || true

# Broadcast
MY_CLAUDE=cecilia-production-enhancer-3ce313b2 ~/memory-til-broadcast.sh broadcast complete "⚖️ LICENSE AUDIT COMPLETE! Audited all $TOTAL BlackRoad repos. $SUCCESS successfully updated with BlackRoad OS, Inc. proprietary licensing. CEO: Alexa Amundson. Non-commercial, testing only. All legally protected!" 2>/dev/null || true
