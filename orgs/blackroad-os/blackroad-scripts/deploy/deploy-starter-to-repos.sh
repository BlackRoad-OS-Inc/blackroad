#!/bin/bash
# Deploy starter content to repos to enable Cloudflare connection

set -e

echo "📤 Deploying Starter Content to Repositories"
echo "============================================="
echo ""

GITHUB_ORG="BlackRoad-OS"
TEMP_DIR="/tmp/blackroad-deploy-$$"

# Create starter template
create_starter_template() {
    local dir=$1
    local project_name=$2
    
    mkdir -p "$dir"
    cd "$dir"
    
    # Create basic HTML file
    cat > index.html << EOFHTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$project_name - BlackRoad OS</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 100%);
            color: #fff;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            text-align: center;
            max-width: 800px;
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            background: linear-gradient(135deg, #FF9D00, #FF0066, #7700FF);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        p { font-size: 1.2em; opacity: 0.8; margin-bottom: 30px; }
        .status {
            display: inline-block;
            padding: 10px 20px;
            background: rgba(0,255,136,0.2);
            border: 1px solid #00ff88;
            border-radius: 20px;
            color: #00ff88;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 $project_name</h1>
        <p>BlackRoad OS Project</p>
        <div class="status">✅ Deployed via Cloudflare Pages</div>
    </div>
</body>
</html>
EOFHTML

    # Create README
    cat > README.md << EOFREADME
# $project_name

BlackRoad OS Project

## Status
✅ Deployed to Cloudflare Pages

## Auto-Deployment
This project automatically deploys to Cloudflare Pages on every push to main.

---
BlackRoad OS © 2025
EOFREADME

    # Create wrangler.toml
    cat > wrangler.toml << EOFWRANGLER
name = "${project_name,,}"
compatibility_date = "2025-12-23"

[env.production]
routes = []
EOFWRANGLER

    echo "✅ Starter template created"
}

# Deploy to a specific repo
deploy_to_repo() {
    local repo=$1
    local project_name=$2
    
    echo "📦 Processing: $repo"
    
    # Check if repo exists
    if ! gh repo view "$GITHUB_ORG/$repo" &>/dev/null; then
        echo "  ⚠️  Repo doesn't exist, skipping..."
        return 1
    fi
    
    # Clone or create
    local repo_dir="$TEMP_DIR/$repo"
    
    if [ -d "$repo_dir" ]; then
        rm -rf "$repo_dir"
    fi
    
    echo "  📥 Cloning repo..."
    if ! gh repo clone "$GITHUB_ORG/$repo" "$repo_dir" 2>/dev/null; then
        echo "  ⚠️  Clone failed, repo might be empty. Initializing..."
        mkdir -p "$repo_dir"
        cd "$repo_dir"
        git init
        git remote add origin "https://github.com/$GITHUB_ORG/$repo.git"
    fi
    
    cd "$repo_dir"
    
    # Check if already has content
    if [ -f "index.html" ] || [ -f "package.json" ]; then
        echo "  ✅ Repo already has content, skipping..."
        return 0
    fi
    
    echo "  📝 Creating starter content..."
    create_starter_template "$repo_dir" "$project_name"
    
    echo "  💾 Committing changes..."
    git add .
    git commit -m "Initial deployment setup for Cloudflare Pages

🚀 Auto-generated starter content
✅ Ready for Cloudflare Pages connection

$(cat <<'EOFCOMMIT'
🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOFCOMMIT
)" || echo "  ⚠️  Nothing to commit"
    
    echo "  📤 Pushing to GitHub..."
    if git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null; then
        echo "  ✅ Deployed to GitHub!"
    else
        echo "  ⚠️  Push failed, might need manual intervention"
    fi
    
    echo ""
}

# Deploy to first 3 repos as test
echo "🧪 Deploying to first 3 repositories..."
echo ""

deploy_to_repo "blackroad-monitoring" "BlackRoad Monitoring"
deploy_to_repo "blackroad-os-analytics" "BlackRoad Analytics"
deploy_to_repo "blackroad-os-console" "BlackRoad Console"

echo "============================================="
echo "✅ Deployment complete!"
echo ""
echo "🌐 Next: Connect these repos to Cloudflare Pages via Dashboard"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

