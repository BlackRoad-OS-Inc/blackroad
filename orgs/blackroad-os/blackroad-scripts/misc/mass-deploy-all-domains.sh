#!/bin/bash
# BlackRoad Mass Deployment Script
# Deploy ALL domains to Cloudflare Pages in one go!
# Version: 1.0.0

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
GITHUB_ORG="BlackRoad-OS"

# All domains to deploy
declare -A DOMAINS=(
    # Primary blackroad.io domains
    ["blackroad.io"]="blackroad-os-home"
    ["app.blackroad.io"]="blackroad-os-web"
    ["console.blackroad.io"]="blackroad-os-prism-console"
    ["docs.blackroad.io"]="blackroad-os-docs"
    ["api.blackroad.io"]="blackroad-os-api"
    ["brand.blackroad.io"]="blackroad-os-brand"
    ["status.blackroad.io"]="blackroad-os-beacon"

    # Lucidia domains
    ["lucidia.earth"]="lucidia-earth-website"
    ["app.lucidia.earth"]="blackroad-os-web"
    ["console.lucidia.earth"]="blackroad-os-prism-console"

    # Vertical packs
    ["finance.blackroad.io"]="blackroad-os-pack-finance"
    ["edu.blackroad.io"]="blackroad-os-pack-education"
    ["studio.blackroad.io"]="blackroad-os-pack-creator-studio"
    ["lab.blackroad.io"]="blackroad-os-pack-research-lab"
    ["canvas.blackroad.io"]="blackroad-os-pack-creator-studio"
    ["video.blackroad.io"]="blackroad-os-pack-creator-studio"
    ["writing.blackroad.io"]="blackroad-os-pack-creator-studio"
    ["legal.blackroad.io"]="blackroad-os-pack-legal"
    ["devops.blackroad.io"]="blackroad-os-pack-infra-devops"

    # Demo/sandbox
    ["demo.blackroad.io"]="blackroad-os-demo"
    ["sandbox.blackroad.io"]="blackroad-os-demo"
)

# Stats
TOTAL=0
SUCCESS=0
FAILED=0
SKIPPED=0

# ============================================================================
# CLOUDFLARE API FUNCTIONS
# ============================================================================

cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local url="https://api.cloudflare.com/client/v4${endpoint}"

    if [ -n "$data" ]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CF_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CF_TOKEN" \
            -H "Content-Type: application/json"
    fi
}

project_exists() {
    local project_name="$1"

    cf_api GET "/accounts/$CF_ACCOUNT_ID/pages/projects" | \
        python3 -c "import sys,json; data=json.load(sys.stdin); print('yes' if '$project_name' in [p['name'] for p in data.get('result', [])] else 'no')"
}

create_pages_project() {
    local project_name="$1"

    echo -e "${BLUE}[CREATE]${NC} Creating Cloudflare Pages project: $project_name"

    local payload=$(cat <<EOF
{
  "name": "$project_name",
  "production_branch": "main",
  "build_config": {
    "build_command": "npm run build",
    "destination_dir": "out",
    "root_dir": ""
  }
}
EOF
)

    local result=$(cf_api POST "/accounts/$CF_ACCOUNT_ID/pages/projects" "$payload")

    if echo "$result" | grep -q '"success":true'; then
        echo -e "${GREEN}[SUCCESS]${NC} Created $project_name"
        return 0
    else
        echo -e "${RED}[FAILED]${NC} Could not create $project_name"
        echo "$result" | python3 -c "import sys,json; data=json.load(sys.stdin); print(data.get('errors', []))" 2>/dev/null || true
        return 1
    fi
}

add_custom_domain() {
    local project_name="$1"
    local domain="$2"

    echo -e "${BLUE}[DOMAIN]${NC} Adding custom domain $domain to $project_name"

    local payload=$(cat <<EOF
{
  "name": "$domain"
}
EOF
)

    local result=$(cf_api POST "/accounts/$CF_ACCOUNT_ID/pages/projects/$project_name/domains" "$payload")

    if echo "$result" | grep -q '"success":true'; then
        echo -e "${GREEN}[SUCCESS]${NC} Added domain $domain"
        return 0
    else
        echo -e "${YELLOW}[WARN]${NC} Domain may already exist or have an issue"
        return 0  # Don't fail on domain errors
    fi
}

# ============================================================================
# GITHUB FUNCTIONS
# ============================================================================

setup_github_secrets() {
    local repo="$1"
    local project_name="$2"
    local domain="$3"

    echo -e "${BLUE}[GITHUB]${NC} Setting up secrets for $repo"

    # Check if repo exists
    if ! gh repo view "$GITHUB_ORG/$repo" >/dev/null 2>&1; then
        echo -e "${YELLOW}[SKIP]${NC} Repository $repo does not exist"
        return 1
    fi

    # Set secrets
    gh secret set CLOUDFLARE_API_TOKEN -b"$CF_TOKEN" -R "$GITHUB_ORG/$repo" 2>/dev/null || true
    gh secret set CLOUDFLARE_ACCOUNT_ID -b"$CF_ACCOUNT_ID" -R "$GITHUB_ORG/$repo" 2>/dev/null || true
    gh secret set CLOUDFLARE_PROJECT_NAME -b"$project_name" -R "$GITHUB_ORG/$repo" 2>/dev/null || true
    gh secret set PRODUCTION_DOMAIN -b"$domain" -R "$GITHUB_ORG/$repo" 2>/dev/null || true

    echo -e "${GREEN}[SUCCESS]${NC} Secrets configured for $repo"
    return 0
}

# ============================================================================
# DEPLOYMENT FUNCTION
# ============================================================================

deploy_domain() {
    local domain="$1"
    local repo="$2"
    local project_name="${domain//\./-}"

    ((TOTAL++))

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} [$TOTAL/${#DOMAINS[@]}] Deploying: ${PURPLE}$domain${NC}"
    echo -e "${CYAN}║${NC} Repository: ${YELLOW}$repo${NC}"
    echo -e "${CYAN}║${NC} Project: ${YELLOW}$project_name${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"

    # Check if project exists
    if [ "$(project_exists "$project_name")" = "yes" ]; then
        echo -e "${YELLOW}[SKIP]${NC} Project $project_name already exists"
        ((SKIPPED++))
    else
        if create_pages_project "$project_name"; then
            ((SUCCESS++))
        else
            ((FAILED++))
            return 1
        fi
    fi

    # Add custom domain
    add_custom_domain "$project_name" "$domain"

    # Set up GitHub secrets
    setup_github_secrets "$repo" "$project_name" "$domain" || true

    echo -e "${GREEN}✓${NC} Completed $domain"
    sleep 1
}

# ============================================================================
# MAIN DEPLOYMENT LOOP
# ============================================================================

main() {
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                                ║${NC}"
    echo -e "${PURPLE}║     🚀 BLACKROAD MASS DEPLOYMENT - ALL DOMAINS 🚀             ║${NC}"
    echo -e "${PURPLE}║                                                                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "Total domains to deploy: ${YELLOW}${#DOMAINS[@]}${NC}"
    echo -e "Cloudflare Account: ${CYAN}$CF_ACCOUNT_ID${NC}"
    echo -e "GitHub Organization: ${CYAN}$GITHUB_ORG${NC}"
    echo ""

    # Confirmation
    if [ "${1:-}" != "--yes" ] && [ "${1:-}" != "-y" ]; then
        echo -e "${YELLOW}This will create ${#DOMAINS[@]} Cloudflare Pages projects.${NC}"
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi

    echo ""
    echo -e "${GREEN}Starting mass deployment...${NC}"
    echo ""

    # Deploy each domain
    for domain in "${!DOMAINS[@]}"; do
        repo="${DOMAINS[$domain]}"
        deploy_domain "$domain" "$repo" || true
    done

    # Summary
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                   DEPLOYMENT SUMMARY                           ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Total domains:    ${YELLOW}$TOTAL${NC}"
    echo -e "  ${GREEN}✓${NC} Success:        ${GREEN}$SUCCESS${NC}"
    echo -e "  ${YELLOW}⊙${NC} Skipped:        ${YELLOW}$SKIPPED${NC}"
    echo -e "  ${RED}✗${NC} Failed:         ${RED}$FAILED${NC}"
    echo ""

    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All deployments completed successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some deployments had issues. Check output above.${NC}"
    fi

    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Add GitHub workflow to each repository"
    echo "  2. Configure DNS records for domains"
    echo "  3. Test deployments: ~/test-deployments.sh smoke"
    echo "  4. Monitor status: ~/status-dashboard.sh"
    echo ""
}

# ============================================================================
# RUN
# ============================================================================

main "$@"
