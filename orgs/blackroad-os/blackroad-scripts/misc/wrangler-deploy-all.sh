#!/usr/bin/env bash
# BlackRoad Wrangler-Based Mass Deployment
# Uses wrangler CLI which has proper authentication
# Version: 4.0.0

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
GITHUB_ORG="BlackRoad-OS"
REPOS_DIR="$HOME/projects"

# Repositories to deploy
declare -a REPOS=(
    "blackroad-os-home"
    "blackroad-os-web"
    "blackroad-os-prism-console"
    "blackroad-os-docs"
    "blackroad-os-beacon"
    "blackroad-os-brand"
    "lucidia-earth-website"
    "blackroad-os-pack-finance"
    "blackroad-os-pack-education"
    "blackroad-os-pack-creator-studio"
    "blackroad-os-pack-research-lab"
    "blackroad-os-pack-legal"
    "blackroad-os-pack-infra-devops"
    "blackroad-os-demo"
)

# Stats
TOTAL=0
SUCCESS=0
FAILED=0
SKIPPED=0

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

check_wrangler() {
    if ! command -v wrangler &> /dev/null; then
        echo -e "${RED}Wrangler CLI not found!${NC}"
        echo "Install with: npm install -g wrangler"
        echo "Then login: wrangler login"
        exit 1
    fi

    if ! wrangler whoami &> /dev/null; then
        echo -e "${YELLOW}Wrangler not logged in.${NC}"
        echo "Run: wrangler login"
        exit 1
    fi

    success "Wrangler CLI ready"
}

deploy_repo() {
    local repo="$1"
    local repo_path="$REPOS_DIR/$repo"
    local project_name=$(echo "$repo" | tr '/' '-' | tr '_' '-')

    ((TOTAL++))

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}[$TOTAL/${#REPOS[@]}]${NC} ${YELLOW}$repo${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check if repo exists locally
    if [ ! -d "$repo_path" ]; then
        skip "Repository not found at $repo_path"
        return 0
    fi

    cd "$repo_path"

    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        skip "No package.json found"
        return 0
    fi

    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        log "Installing dependencies..."
        npm install --quiet || { fail "npm install failed"; return 1; }
    fi

    # Build
    log "Building..."
    if ! npm run build &> /tmp/build-$repo.log; then
        fail "Build failed (see /tmp/build-$repo.log)"
        return 1
    fi

    # Deploy with wrangler
    log "Deploying to Cloudflare Pages..."

    # Determine output directory
    local out_dir="out"
    if [ -d ".next" ]; then
        out_dir=".next"
    elif [ -d "dist" ]; then
        out_dir="dist"
    elif [ -d "build" ]; then
        out_dir="build"
    fi

    if wrangler pages deploy "$out_dir" --project-name="$project_name" &> /tmp/deploy-$repo.log; then
        success "Deployed $repo → $project_name"
        return 0
    else
        fail "Deployment failed (see /tmp/deploy-$repo.log)"
        return 1
    fi
}

print_summary() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                   DEPLOYMENT SUMMARY                         ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
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
    echo "  1. Add custom domains via Cloudflare dashboard"
    echo "  2. Test: ~/test-deployments.sh smoke"
    echo "  3. Monitor: ~/status-dashboard.sh"
    echo ""
}

main() {
    clear
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}║      🚀 WRANGLER MASS DEPLOYMENT v4.0 🚀                    ║${NC}"
    echo -e "${PURPLE}║                                                              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Check wrangler
    check_wrangler

    echo -e "  Total repositories: ${YELLOW}${#REPOS[@]}${NC}"
    echo -e "  Repositories directory: ${CYAN}$REPOS_DIR${NC}"
    echo ""

    if [ "${1:-}" != "-y" ] && [ "${1:-}" != "--yes" ]; then
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            exit 1
        fi
    fi

    echo ""
    log "Starting deployments..."

    # Deploy each repo
    for repo in "${REPOS[@]}"; do
        deploy_repo "$repo" || true
    done

    # Summary
    print_summary
}

main "$@"
