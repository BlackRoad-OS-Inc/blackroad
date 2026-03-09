#!/usr/bin/env bash
# BlackRoad Quick Deploy - Bash 3.2 Compatible
# Deploy all domains to Cloudflare Pages NOW!
# Version: 2.0.0

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CF_TOKEN="${CF_TOKEN:-yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy}"
CF_ACCOUNT_ID="463024cf9efed5e7b40c5fbe7938e256"

# Domain -> Repo mapping (compatible with bash 3.2)
# Format: "domain|repo"
DEPLOYMENTS=(
    # Primary
    "blackroad.io|blackroad-os-home"
    "app.blackroad.io|blackroad-os-web"
    "console.blackroad.io|blackroad-os-prism-console"
    "docs.blackroad.io|blackroad-os-docs"
    "api.blackroad.io|blackroad-os-api"
    "brand.blackroad.io|blackroad-os-brand"
    "status.blackroad.io|blackroad-os-beacon"

    # Lucidia
    "lucidia.earth|lucidia-earth-website"
    "app.lucidia.earth|blackroad-os-web"
    "console.lucidia.earth|blackroad-os-prism-console"

    # Verticals
    "finance.blackroad.io|blackroad-os-pack-finance"
    "edu.blackroad.io|blackroad-os-pack-education"
    "studio.blackroad.io|blackroad-os-pack-creator-studio"
    "lab.blackroad.io|blackroad-os-pack-research-lab"
    "canvas.blackroad.io|blackroad-os-pack-creator-studio"
    "video.blackroad.io|blackroad-os-pack-creator-studio"
    "writing.blackroad.io|blackroad-os-pack-creator-studio"
    "legal.blackroad.io|blackroad-os-pack-legal"
    "devops.blackroad.io|blackroad-os-pack-infra-devops"

    # Demo
    "demo.blackroad.io|blackroad-os-demo"
    "sandbox.blackroad.io|blackroad-os-demo"
)

# Stats
TOTAL=0
SUCCESS=0
FAILED=0
SKIPPED=0

# ============================================================================
# FUNCTIONS
# ============================================================================

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}[✓]${NC} $*"
    ((SUCCESS++))
}

fail() {
    echo -e "${RED}[✗]${NC} $*"
    ((FAILED++))
}

skip() {
    echo -e "${YELLOW}[⊙]${NC} $*"
    ((SKIPPED++))
}

cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" "https://api.cloudflare.com/client/v4${endpoint}" \
            -H "Authorization: Bearer $CF_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "https://api.cloudflare.com/client/v4${endpoint}" \
            -H "Authorization: Bearer $CF_TOKEN" \
            -H "Content-Type: application/json"
    fi
}

project_exists() {
    local project_name="$1"
    cf_api GET "/accounts/$CF_ACCOUNT_ID/pages/projects/$project_name" 2>/dev/null | \
        grep -q '"success":true'
}

create_project() {
    local project_name="$1"

    local payload="{\"name\":\"$project_name\",\"production_branch\":\"main\",\"build_config\":{\"build_command\":\"npm run build\",\"destination_dir\":\"out\"}}"

    local result=$(cf_api POST "/accounts/$CF_ACCOUNT_ID/pages/projects" "$payload")

    if echo "$result" | grep -q '"success":true'; then
        return 0
    else
        return 1
    fi
}

add_domain() {
    local project_name="$1"
    local domain="$2"

    local payload="{\"name\":\"$domain\"}"

    cf_api POST "/accounts/$CF_ACCOUNT_ID/pages/projects/$project_name/domains" "$payload" >/dev/null 2>&1
}

deploy_one() {
    local domain="$1"
    local repo="$2"
    local project_name=$(echo "$domain" | tr '.' '-')

    ((TOTAL++))

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}[$TOTAL/${#DEPLOYMENTS[@]}]${NC} ${YELLOW}$domain${NC} → ${BLUE}$repo${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check if exists
    if project_exists "$project_name"; then
        skip "$project_name already exists"
        add_domain "$project_name" "$domain"
        return 0
    fi

    # Create project
    log "Creating Cloudflare Pages project: $project_name"
    if create_project "$project_name"; then
        success "Created $project_name"
        sleep 1
        add_domain "$project_name" "$domain"
        log "Added domain $domain"
        return 0
    else
        fail "Could not create $project_name"
        return 1
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    clear
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                                ║${NC}"
    echo -e "${PURPLE}║         🚀 BLACKROAD MASS DEPLOYMENT v2.0 🚀                  ║${NC}"
    echo -e "${PURPLE}║                                                                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total domains: ${YELLOW}${#DEPLOYMENTS[@]}${NC}"
    echo -e "  Account ID: ${CYAN}${CF_ACCOUNT_ID:0:20}...${NC}"
    echo ""

    if [ "${1:-}" != "-y" ] && [ "${1:-}" != "--yes" ]; then
        echo -e "${YELLOW}This will create ${#DEPLOYMENTS[@]} Cloudflare Pages projects.${NC}"
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi

    echo ""
    log "Starting deployment..."
    echo ""

    # Deploy each
    for deployment in "${DEPLOYMENTS[@]}"; do
        IFS='|' read -r domain repo <<< "$deployment"
        deploy_one "$domain" "$repo" || true
        sleep 0.5
    done

    # Summary
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                     DEPLOYMENT SUMMARY                         ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BLUE}Total:${NC}    $TOTAL"
    echo -e "  ${GREEN}Success:${NC}  $SUCCESS"
    echo -e "  ${YELLOW}Skipped:${NC}  $SKIPPED"
    echo -e "  ${RED}Failed:${NC}   $FAILED"
    echo ""

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All deployments completed!${NC}"
    else
        echo -e "${YELLOW}⚠️  $FAILED deployment(s) failed${NC}"
    fi

    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Test: ~/test-deployments.sh smoke"
    echo "  2. Status: ~/status-dashboard.sh compact"
    echo "  3. Monitor: ~/status-dashboard.sh watch"
    echo ""
}

main "$@"
