#!/bin/bash
# Unified deployment command for all BlackRoad domains

set -e

echo "🌐 BlackRoad OS - Unified Deployment System"
echo "==========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPOS_DIR="$HOME/blackroad-repos"
LOG_FILE="$HOME/deployment-$(date +%Y%m%d-%H%M%S).log"

# Deployment targets
declare -A DEPLOYMENTS=(
    ["blackroad-os-brand"]="brand.blackroad.io"
    ["blackroad-os-docs"]="docs.blackroad.io"
    ["blackroad-os-web"]="blackroad.io"
    ["blackroad-os-prism"]="prism.blackroad.io"
    ["blackroad-hello"]="creator.blackroad.io"
    ["lucidia-platform"]="lucidia.earth"
    ["blackroad-os-demo"]="demo.blackroad.io"
    ["blackroad-os-home"]="home.blackroad.io"
)

usage() {
    echo "Usage: $0 [command] [target]"
    echo ""
    echo "Commands:"
    echo "  deploy <repo>   Deploy specific repo"
    echo "  deploy-all      Deploy all repos"
    echo "  status          Check deployment status"
    echo "  list            List all deployment targets"
    echo "  test <repo>     Test deployment for repo"
    echo ""
    echo "Examples:"
    echo "  $0 deploy blackroad-os-brand"
    echo "  $0 deploy-all"
    echo "  $0 status"
}

deploy_repo() {
    local repo=$1
    local domain=${DEPLOYMENTS[$repo]}
    
    if [ -z "$domain" ]; then
        echo -e "${RED}❌ Unknown repo: $repo${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📦 Deploying: $repo → $domain${NC}"
    
    # Check if repo exists locally
    if [ ! -d "$REPOS_DIR/$repo" ]; then
        echo "  📥 Cloning repo..."
        mkdir -p "$REPOS_DIR"
        gh repo clone "BlackRoad-OS/$repo" "$REPOS_DIR/$repo" || return 1
    fi
    
    cd "$REPOS_DIR/$repo"
    
    # Pull latest
    echo "  🔄 Pulling latest changes..."
    git pull origin main || git pull origin master || true
    
    # Check for wrangler.toml
    if [ -f "wrangler.toml" ]; then
        echo "  ☁️ Deploying with wrangler..."
        wrangler pages deploy . --project-name="$repo" --branch=main || return 1
    else
        echo "  ⚠️  No wrangler.toml found, using dashboard connection"
    fi
    
    echo -e "${GREEN}  ✅ Deployed: https://$domain${NC}"
    echo ""
}

deploy_all() {
    echo -e "${YELLOW}🚀 Deploying all projects...${NC}"
    echo ""
    
    local success=0
    local failed=0
    
    for repo in "${!DEPLOYMENTS[@]}"; do
        if deploy_repo "$repo"; then
            ((success++))
        else
            ((failed++))
            echo -e "${RED}❌ Failed: $repo${NC}" | tee -a "$LOG_FILE"
        fi
    done
    
    echo "==========================================="
    echo -e "${GREEN}✅ Successful: $success${NC}"
    echo -e "${RED}❌ Failed: $failed${NC}"
    echo "📝 Log: $LOG_FILE"
}

check_status() {
    echo "📊 Deployment Status"
    echo "==================="
    echo ""
    
    for repo in "${!DEPLOYMENTS[@]}"; do
        local domain=${DEPLOYMENTS[$repo]}
        echo -n "  $repo → $domain: "
        
        if curl -s -o /dev/null -w "%{http_code}" "https://$domain" | grep -q "200\|301\|302"; then
            echo -e "${GREEN}✅ Live${NC}"
        else
            echo -e "${RED}❌ Down${NC}"
        fi
    done
}

list_targets() {
    echo "📋 Deployment Targets"
    echo "===================="
    echo ""
    
    for repo in "${!DEPLOYMENTS[@]}"; do
        echo "  $repo → ${DEPLOYMENTS[$repo]}"
    done
}

# Main command dispatcher
case "$1" in
    deploy)
        if [ -z "$2" ]; then
            echo "Error: Please specify a repo to deploy"
            usage
            exit 1
        fi
        deploy_repo "$2"
        ;;
    deploy-all)
        deploy_all
        ;;
    status)
        check_status
        ;;
    list)
        list_targets
        ;;
    test)
        if [ -z "$2" ]; then
            echo "Error: Please specify a repo to test"
            usage
            exit 1
        fi
        echo "🧪 Testing deployment: $2"
        deploy_repo "$2"
        ;;
    *)
        usage
        exit 0
        ;;
esac
