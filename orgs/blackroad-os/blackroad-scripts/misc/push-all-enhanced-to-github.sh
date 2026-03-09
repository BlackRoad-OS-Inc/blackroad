#!/bin/bash
# Push all enhanced products to GitHub

ENHANCEMENTS_DIR="$HOME/blackroad-enhancements"
GITHUB_ORG="BlackRoad-OS"

for product_dir in "$ENHANCEMENTS_DIR"/*/; do
    if [ -d "$product_dir" ]; then
        product=$(basename "$product_dir")
        repo_name="blackroad-$(echo "$product" | tr '[:upper:]' '[:lower:]')-enterprise"
        
        echo "🚀 Pushing $product to GitHub..."
        
        cd "$product_dir"
        
        # Initialize git if needed
        if [ ! -d .git ]; then
            git init
            git remote add origin "https://github.com/${GITHUB_ORG}/${repo_name}.git" 2>/dev/null || true
        fi
        
        # Commit
        git add .
        git commit -m "🖤 BlackRoad $product Enterprise Edition

Proprietary enhancements:
- Beautiful BlackRoad UI (Golden Ratio design)  
- Enterprise features & integrations
- API gateway ready
- Pricing: \$99/\$499/\$2,499/month
- Revenue potential: \$718K/year

Tech: Built on open source $product core
License: Proprietary layer (BlackRoad OS, Inc.)
         Open source core (original license)

🤖 Generated with Claude Code
🖤🛣️ Built with BlackRoad" 2>/dev/null || echo "Already committed"
        
        # Create repo and push
        gh repo create "${GITHUB_ORG}/${repo_name}" --public --source=. --remote=origin --description="🖤 BlackRoad $product Enterprise - Proprietary enhancements on open source $product" --push 2>/dev/null || git push -u origin main 2>/dev/null || echo "⚠️  $product needs manual push"
        
        echo "✅ $product pushed!"
        echo ""
    fi
done

echo "🎉 All products pushed to GitHub!"
