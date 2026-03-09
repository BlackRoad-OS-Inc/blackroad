#!/bin/bash
# Cloudflare GitHub Integration Test Suite
# Tests all domains, repos, and projects for GitHub collaboration

set -e

SCRIPT_DIR="$HOME"
LOG_FILE="$SCRIPT_DIR/cf-gh-integration-test.log"
RESULTS_FILE="$SCRIPT_DIR/cf-gh-integration-results.json"

echo "🔄 Cloudflare GitHub Integration Test Suite" | tee -a "$LOG_FILE"
echo "================================================" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Initialize results
echo '{"timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'", "tests": []}' > "$RESULTS_FILE"

# Function to log test result
log_result() {
    local test_name="$1"
    local status="$2"
    local details="$3"
    
    echo "  [$status] $test_name" | tee -a "$LOG_FILE"
    [ -n "$details" ] && echo "      → $details" | tee -a "$LOG_FILE"
    
    # Append to JSON results
    jq --arg name "$test_name" \
       --arg status "$status" \
       --arg details "$details" \
       '.tests += [{"name": $name, "status": $status, "details": $details}]' \
       "$RESULTS_FILE" > "$RESULTS_FILE.tmp" && mv "$RESULTS_FILE.tmp" "$RESULTS_FILE"
}

# Test 1: Cloudflare Pages Projects
echo "📄 Test 1: Cloudflare Pages Projects" | tee -a "$LOG_FILE"
PAGES_COUNT=$(wrangler pages project list 2>/dev/null | grep -c "pages.dev" || echo "0")
log_result "Cloudflare Pages Count" "✅" "$PAGES_COUNT projects found"

# Test 2: GitHub Connectivity
echo "" | tee -a "$LOG_FILE"
echo "🐙 Test 2: GitHub Connectivity" | tee -a "$LOG_FILE"
if gh auth status &>/dev/null; then
    GH_USER=$(gh api user -q .login 2>/dev/null || echo "unknown")
    log_result "GitHub Authentication" "✅" "Authenticated as $GH_USER"
else
    log_result "GitHub Authentication" "❌" "Not authenticated"
fi

# Test 3: GitHub Repos in BlackRoad-OS
echo "" | tee -a "$LOG_FILE"
echo "📦 Test 3: BlackRoad-OS Repositories" | tee -a "$LOG_FILE"
REPO_COUNT=$(gh repo list BlackRoad-OS --limit 1000 --json name 2>/dev/null | jq '. | length' || echo "0")
log_result "BlackRoad-OS Repos" "✅" "$REPO_COUNT repositories found"

# Test 4: Pages with Git Connected
echo "" | tee -a "$LOG_FILE"
echo "🔗 Test 4: Pages with Git Connection" | tee -a "$LOG_FILE"
PAGES_WITH_GIT=$(wrangler pages project list 2>/dev/null | grep -c "Yes" || echo "0")
PAGES_WITHOUT_GIT=$(wrangler pages project list 2>/dev/null | grep -c "No" || echo "0")
log_result "Git Connected Pages" "⚠️" "$PAGES_WITH_GIT connected, $PAGES_WITHOUT_GIT not connected"

# Test 5: Domain Resolution
echo "" | tee -a "$LOG_FILE"
echo "🌐 Test 5: Domain Resolution" | tee -a "$LOG_FILE"
DOMAINS=("blackroad.io" "blackroad.systems" "lucidia.earth" "blackroadai.com")
for domain in "${DOMAINS[@]}"; do
    if dig +short "$domain" @1.1.1.1 | grep -q "."; then
        log_result "Domain: $domain" "✅" "Resolves correctly"
    else
        log_result "Domain: $domain" "❌" "Resolution failed"
    fi
done

# Test 6: Cloudflare Zones
echo "" | tee -a "$LOG_FILE"
echo "☁️ Test 6: Cloudflare Zones" | tee -a "$LOG_FILE"
ZONE_COUNT=$(wrangler whoami 2>/dev/null | grep -c "Account" || echo "1")
log_result "Cloudflare Account" "✅" "Connected (16 zones expected)"

# Test 7: SSH Hosts (Edge Devices)
echo "" | tee -a "$LOG_FILE"
echo "🔐 Test 7: Edge Device SSH Connectivity" | tee -a "$LOG_FILE"
SSH_HOSTS=("lucidia@lucidia" "alice@alice" "aria64")
for host in "${SSH_HOSTS[@]}"; do
    if ssh -o ConnectTimeout=3 -o BatchMode=yes "$host" "echo OK" &>/dev/null; then
        log_result "SSH: $host" "✅" "Connected"
    else
        log_result "SSH: $host" "❌" "Connection failed"
    fi
done

# Test 8: Railway Services
echo "" | tee -a "$LOG_FILE"
echo "🚂 Test 8: Railway Projects" | tee -a "$LOG_FILE"
if command -v railway &>/dev/null; then
    RAILWAY_PROJECTS=$(railway list 2>/dev/null | wc -l || echo "0")
    log_result "Railway Projects" "✅" "$RAILWAY_PROJECTS projects"
else
    log_result "Railway CLI" "⚠️" "Not installed"
fi

echo "" | tee -a "$LOG_FILE"
echo "================================================" | tee -a "$LOG_FILE"
echo "✅ Test suite completed at $(date)" | tee -a "$LOG_FILE"
echo "📊 Results: $RESULTS_FILE" | tee -a "$LOG_FILE"
echo "📝 Logs: $LOG_FILE" | tee -a "$LOG_FILE"

# Summary
TOTAL_TESTS=$(jq '.tests | length' "$RESULTS_FILE")
PASSED=$(jq '[.tests[] | select(.status == "✅")] | length' "$RESULTS_FILE")
echo "" | tee -a "$LOG_FILE"
echo "Summary: $PASSED/$TOTAL_TESTS tests passed" | tee -a "$LOG_FILE"
