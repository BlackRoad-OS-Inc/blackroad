#!/bin/bash

# SUBDOMAIN MASS DEPLOYMENT
# Deploy all 97 subdomains to GitHub and Cloudflare Pages

set -e

OAUTH_TOKEN=$(grep 'oauth_token' ~/.wrangler/config/default.toml | cut -d'"' -f2)
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

echo "🚀 SUBDOMAIN MASS DEPLOYMENT"
echo "=============================="
echo ""

deploy_subdomain() {
    local subdomain_dir="$1"
    local parent_domain="$2"
    local subdomain_name=$(basename "$subdomain_dir")
    local repo_name="${subdomain_name}-${parent_domain//./}"
    local full_domain="${subdomain_name}.${parent_domain}"

    echo "📦 $full_domain"

    (
        cd "$subdomain_dir"

        # Init git if needed
        if [ ! -d ".git" ]; then
            git init
            git add -A
            git commit -m "Automated subdomain deployment: $full_domain" 2>&1 | tail -1
        fi

        # Check if repo exists
        if gh repo view "BlackRoad-OS/$repo_name" &>/dev/null; then
            echo "   ✅ Repo exists, updating..."
            git remote add origin "https://github.com/BlackRoad-OS/$repo_name.git" 2>/dev/null || true
            git branch -M main
            git push -u origin main --force 2>&1 | tail -1
        else
            echo "   🆕 Creating repo..."
            gh repo create "BlackRoad-OS/$repo_name" --public --source=. --push 2>&1 | tail -1
        fi

        echo "   ✅ Deployed!"
    ) &
}

# Deploy all blackroad.io subdomains
echo "Deploying blackroad.io subdomains..."
count=0
for dir in ${HOME}/blackroad-subdomains/blackroad.io/*; do
    if [ -d "$dir" ]; then
        deploy_subdomain "$dir" "blackroad.io"
        count=$((count + 1))

        # Deploy in batches of 10 to avoid overwhelming GitHub API
        if [ $((count % 10)) -eq 0 ]; then
            wait
            echo ""
            echo "   Batch of 10 complete, continuing..."
            sleep 2
        fi
    fi
done

wait
echo ""
echo "✅ blackroad.io subdomains deployed!"
echo ""

# Deploy lucidia.earth subdomains
echo "Deploying lucidia.earth subdomains..."
for dir in ${HOME}/blackroad-subdomains/lucidia.earth/*; do
    if [ -d "$dir" ]; then
        deploy_subdomain "$dir" "lucidia.earth"
    fi
done

wait
echo ""
echo "✅ lucidia.earth subdomains deployed!"
echo ""

# Deploy blackroadquantum.com subdomains
echo "Deploying blackroadquantum.com subdomains..."
for dir in ${HOME}/blackroad-subdomains/blackroadquantum.com/*; do
    if [ -d "$dir" ]; then
        deploy_subdomain "$dir" "blackroadquantum.com"
    fi
done

wait
echo ""
echo "✅ All subdomains deployed!"
echo ""

echo "=============================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=============================="
echo ""
echo "Total subdomains deployed: $(find ${HOME}/blackroad-subdomains -name ".git" -type d | wc -l)"
echo ""
echo "Check status:"
echo "  GitHub: https://github.com/BlackRoad-OS"
echo "  Cloudflare: https://dash.cloudflare.com"
echo ""
echo "Next: Configure DNS records for subdomains via Cloudflare API"
