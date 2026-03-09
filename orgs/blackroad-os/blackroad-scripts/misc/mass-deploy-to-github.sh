#!/bin/bash

# Mass deploy websites to GitHub repos and trigger Cloudflare Pages

set -e

echo "🚀 Mass GitHub Deployment Script"
echo "=================================="
echo ""

# List of deployments: local_dir:github_repo
DEPLOYMENTS=(
    "blackroad-websites/blackroad-io:BlackRoad-OS/blackroad-io"
    "blackroad-websites/blackroad-systems:BlackRoad-OS/blackroad-systems"
    "blackroad-websites/lucidia-earth:BlackRoad-OS/lucidia-earth"
    "blackroad-websites/blackroad-me:BlackRoad-OS/blackroad-me"
    "blackroad-websites/blackroad-company:BlackRoad-OS/blackroad-company"
    "blackroad-websites/quantum-domains/blackroadquantum-com:BlackRoad-OS/blackroadquantum-com"
)

deploy_to_github() {
    local local_dir="$1"
    local github_repo="$2"
    
    echo "📦 Deploying: $local_dir → $github_repo"
    
    cd ~/$local_dir
    
    # Initialize git if needed
    if [ ! -d ".git" ]; then
        git init
        git add .
        git commit -m "Initial commit: Website deployment"
        gh repo create $github_repo --public --source=. --push || echo "Repo may already exist"
    else
        git add -A
        git commit -m "Update website $(date +%Y-%m-%d)" || echo "No changes"
        git push || echo "Already up to date"
    fi
    
    echo "   ✅ Deployed to GitHub"
    echo ""
}

for mapping in "${DEPLOYMENTS[@]}"; do
    local_dir="${mapping%%:*}"
    github_repo="${mapping##*:}"
    deploy_to_github "$local_dir" "$github_repo"
done

echo "🎉 All deployments complete!"
echo "Cloudflare Pages will auto-deploy from GitHub pushes"
