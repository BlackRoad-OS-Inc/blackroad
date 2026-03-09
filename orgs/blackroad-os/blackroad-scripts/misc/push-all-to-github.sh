#!/bin/bash

# Push all websites to their GitHub repos

set -e

OAUTH_TOKEN=$(grep 'oauth_token' ~/.wrangler/config/default.toml | cut -d'"' -f2)
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

echo "🚀 Pushing ALL websites to GitHub"
echo "==================================="
echo ""

# Function to deploy a website
deploy_site() {
    local site_dir="$1"
    local repo_name="$2"

    echo "📦 $repo_name"

    cd "$site_dir"

    # Check if repo exists
    if gh repo view "BlackRoad-OS/$repo_name" &>/dev/null; then
        echo "   📁 Repo exists, updating..."

        if [ ! -d ".git" ]; then
            git init
            git remote add origin "https://github.com/BlackRoad-OS/$repo_name.git"
        fi

        git add -A
        git commit -m "Website update $(date +%Y-%m-%d)" || echo "   ℹ️  No changes"
        git branch -M main
        git push -u origin main --force

    else
        echo "   🆕 Creating new repo..."
        git init
        git add -A
        git commit -m "Initial commit: Automated website deployment"
        gh repo create "BlackRoad-OS/$repo_name" --public --source=. --push
    fi

    echo "   ✅ Pushed to GitHub"

    # Trigger Cloudflare Pages deployment by updating the project
    echo "   🌐 Triggering Cloudflare Pages..."
    curl -s -X POST \
        "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${repo_name}/deployments" \
        -H "Authorization: Bearer ${OAUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"branch":"main"}' > /dev/null || echo "   ℹ️  CF Pages will auto-deploy"

    echo ""
}

# Deploy all generated sites
for dir in ~/blackroad-websites/generated/*; do
    if [ -d "$dir" ]; then
        repo_name=$(basename "$dir")
        deploy_site "$dir" "$repo_name"
    fi
done

# Also update the main 5 sites
for site in blackroad-io blackroad-systems lucidia-earth blackroad-me blackroad-company; do
    if [ -d ~/blackroad-websites/$site ]; then
        deploy_site ~/blackroad-websites/$site "$site"
    fi
done

# And the quantum main site
if [ -d ~/blackroad-websites/quantum-domains/blackroadquantum-com ]; then
    deploy_site ~/blackroad-websites/quantum-domains/blackroadquantum-com "blackroadquantum-com"
fi

echo "========================================="
echo "🎉 ALL SITES PUSHED TO GITHUB!"
echo "========================================="
echo ""
echo "Cloudflare Pages will auto-deploy from GitHub"
echo "Check: https://dash.cloudflare.com → Pages"
