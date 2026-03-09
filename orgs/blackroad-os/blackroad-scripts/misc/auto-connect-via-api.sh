#!/bin/bash
# Attempt to connect Pages projects via Cloudflare API
# Note: This uses undocumented APIs and may require manual steps

ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"
GITHUB_ORG="BlackRoad-OS"

echo "🔧 Attempting Automated Git Connection via Cloudflare API"
echo "========================================================="
echo ""

# Check if we can use the API
echo "Testing API access..."
if ! wrangler whoami &>/dev/null; then
    echo "❌ Wrangler not authenticated"
    exit 1
fi

echo "✅ Wrangler authenticated"
echo ""

# Function to connect a project
connect_project() {
    local project=$1
    local repo=$2
    
    echo "🔗 Attempting to connect: $project → $repo"
    
    # Try to get project info
    PROJECT_INFO=$(wrangler pages project list 2>&1 | grep "$project" || echo "")
    
    if [ -z "$PROJECT_INFO" ]; then
        echo "  ⚠️  Project not found: $project"
        return 1
    fi
    
    # Check if repo exists
    if ! gh repo view "$GITHUB_ORG/$repo" &>/dev/null; then
        echo "  ⚠️  Repo doesn't exist: $GITHUB_ORG/$repo"
        echo "  💡 Creating repo..."
        
        if gh repo create "$GITHUB_ORG/$repo" --private --description "BlackRoad OS - $project" 2>&1; then
            echo "  ✅ Repo created: $GITHUB_ORG/$repo"
        else
            echo "  ❌ Failed to create repo"
            return 1
        fi
    else
        echo "  ✅ Repo exists: $GITHUB_ORG/$repo"
    fi
    
    # Note: Direct API connection requires OAuth flow which needs browser
    echo "  📝 Project ready for connection via Dashboard"
    echo "     → https://dash.cloudflare.com/$ACCOUNT_ID/pages/view/$project"
    echo ""
    
    return 0
}

# Try connecting first 5 projects
echo "🚀 Processing first 5 projects..."
echo ""

connect_project "blackroad-monitoring" "blackroad-monitoring"
connect_project "blackroad-hello" "blackroad-hello"
connect_project "lucidia-earth" "lucidia-platform"
connect_project "blackroad-os-demo" "blackroad-os-demo"
connect_project "blackroad-os-home" "blackroad-os-home"

echo ""
echo "========================================================="
echo "✅ Setup complete for 5 projects"
echo ""
echo "🌐 Next Steps:"
echo "1. Visit Cloudflare Dashboard"
echo "2. Connect each project to its GitHub repo"
echo "3. Configure build settings"
echo "4. Cloudflare will auto-deploy on push"
echo ""
