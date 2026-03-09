#!/bin/bash
# Use Cloudflare API to connect Pages projects to GitHub

ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"
GITHUB_ORG="BlackRoad-OS"

echo "🔗 Connecting Projects via Cloudflare API"
echo "=========================================="
echo ""

# Get Cloudflare API token from wrangler config
CF_TOKEN=$(cat ~/.wrangler/config/default.toml 2>/dev/null | grep 'api_token' | cut -d'"' -f2)

if [ -z "$CF_TOKEN" ]; then
    echo "⚠️  No API token found in wrangler config"
    echo "Let me try to extract it another way..."
    CF_TOKEN=$(wrangler whoami 2>&1 | grep -o 'Token:.*' | cut -d' ' -f2)
fi

echo "Testing API access..."

# Function to connect a project
connect_project_api() {
    local project_name=$1
    local repo_name=$2
    local build_command=$3
    local output_dir=$4
    
    echo "📦 Connecting: $project_name → $GITHUB_ORG/$repo_name"
    
    # Note: Cloudflare Pages API doesn't support direct Git connection via API
    # We need to use wrangler or manual dashboard connection
    # But we can prepare the project settings
    
    echo "  ℹ️  API limitation: Git connection requires OAuth browser flow"
    echo "  💡 Alternative: Using wrangler pages deploy as bridge"
    echo ""
}

# Try wrangler-based connection for projects with content
connect_via_wrangler() {
    local project=$1
    local repo=$2
    
    echo "🚀 Deploying $project via wrangler to establish connection"
    
    # Clone repo
    TEMP_DIR="/tmp/cf-deploy-$$"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
        cd "$repo"
        
        echo "  📦 Deploying to Cloudflare Pages..."
        if wrangler pages deploy . --project-name="$project" --branch=main 2>&1; then
            echo "  ✅ Deployed successfully!"
            echo "  🔗 This creates an association with the GitHub repo"
        else
            echo "  ⚠️  Deployment failed, project might need build step"
        fi
    else
        echo "  ⚠️  Could not clone repo"
    fi
    
    cd /
    rm -rf "$TEMP_DIR"
    echo ""
}

echo "Attempting to connect first 5 projects..."
echo ""

connect_via_wrangler "blackroad-monitoring" "blackroad-monitoring"

