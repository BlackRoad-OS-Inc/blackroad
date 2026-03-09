#!/bin/bash

# RAPID DEPLOYMENT: Push all websites to GitHub simultaneously

set -e

echo "🚀 RAPID DEPLOYMENT STARTING"
echo "============================"
echo ""

# Function to deploy a single site
deploy() {
    local dir="$1"
    local repo="$2"

    echo "📦 $repo"

    (
        cd "$dir"

        # Init git if needed
        if [ ! -d ".git" ]; then
            git init
            git add -A
            git commit -m "Automated deployment: $(basename $dir)"
        fi

        # Check if repo exists on GitHub
        if gh repo view "BlackRoad-OS/$repo" &>/dev/null; then
            echo "   ✅ Repo exists, updating..."
            git remote add origin "https://github.com/BlackRoad-OS/$repo.git" 2>/dev/null || true
            git branch -M main
            git push -u origin main --force 2>&1 | tail -1
        else
            echo "   🆕 Creating repo..."
            gh repo create "BlackRoad-OS/$repo" --public --source=. --push 2>&1 | tail -1
        fi

        echo "   ✅ Deployed!"
    ) &
}

echo "Deploying main platforms..."

# Main 5 (already started blackroad-io)
deploy ~/blackroad-websites/blackroad-systems "blackroad-systems"
deploy ~/blackroad-websites/lucidia-earth "lucidia-earth"
deploy ~/blackroad-websites/blackroad-me "blackroad-me"
deploy ~/blackroad-websites/blackroad-company "blackroad-company"

# Wait for batch 1
wait
echo ""
echo "✅ Main platforms deployed!"
echo ""

echo "Deploying quantum suite..."

# Quantum domains
deploy ~/blackroad-websites/quantum-domains/blackroadquantum-com "blackroadquantum-com"

# Generated quantum sites
for site in blackroadquantum-info blackroadquantum-net blackroadquantum-shop blackroadquantum-store; do
    if [ -d ~/blackroad-websites/generated/$site ] || [ -d ~/blackroad-websites/~/blackroad-websites/generated/$site ]; then
        source_dir=$(find ~/blackroad-websites -type d -name "$site" | head -1)
        [ -n "$source_dir" ] && deploy "$source_dir" "$site"
    fi
done

wait
echo ""
echo "✅ Quantum domains deployed!"
echo ""

echo "Deploying AI domains..."

# AI domains
for site in blackroadai-com blackroadqi-com lucidiaqi-com aliceqi-com lucidia-studio; do
    source_dir=$(find ~/blackroad-websites -type d -name "$site" | head -1)
    [ -n "$source_dir" ] && deploy "$source_dir" "$site"
done

wait
echo ""
echo "✅ AI domains deployed!"
echo ""

echo "Deploying blockchain & corporate..."

# Blockchain
for site in roadchain-io roadcoin-io; do
    source_dir=$(find ~/blackroad-websites -type d -name "$site" | head -1)
    [ -n "$source_dir" ] && deploy "$source_dir" "$site"
done

# Corporate
for site in blackboxprogramming-io blackroadinc-us blackroad-network; do
    source_dir=$(find ~/blackroad-websites -type d -name "$site" | head -1)
    [ -n "$source_dir" ] && deploy "$source_dir" "$site"
done

wait
echo ""
echo "✅ All domains deployed!"
echo ""

echo "============================"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "============================"
echo ""
echo "All websites pushed to GitHub"
echo "Cloudflare Pages will auto-deploy"
echo ""
echo "Check status:"
echo "  GitHub: https://github.com/BlackRoad-OS"
echo "  Cloudflare: https://dash.cloudflare.com"
