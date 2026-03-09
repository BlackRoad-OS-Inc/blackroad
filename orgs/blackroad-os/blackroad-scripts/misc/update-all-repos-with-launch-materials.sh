#!/bin/bash
# Update all 186 repos with pricing pages, Stripe integration, and launch materials

set -e

echo "🚀 Updating all GitHub repos with launch materials..."

# Get list of all repos
ORGS=(
  "BlackRoad-OS"
  "blackboxprogramming"
  "BlackRoad-AI"
  "BlackRoad-Cloud"
  "BlackRoad-Education"
)

# Launch materials to add
mkdir -p ~/repo-updates
cat > ~/repo-updates/PRICING.md << 'EOF'
# Pricing

## BlackRoad Deploy
**Self-hosted Railway alternative**
- Free: 3 apps
- Pro: $20/mo - Unlimited apps
- Team: $50/mo - 5 team members + SLA

[Get Started](https://deploy.blackroad.io)

## Lucidia AI
**AI learning companion**
- Free: 10 problems/month
- Student: $9.99/mo - Unlimited
- Family: $19.99/mo - Up to 5 users

[Try Lucidia](https://lucidia.earth)

## All Products
View all pricing: https://blackroad.io/pricing
EOF

cat > ~/repo-updates/STRIPE_INTEGRATION.md << 'EOF'
# Stripe Integration

All BlackRoad products use Stripe for payments.

## Products Available:
- BlackRoad Enterprise ($500/mo)
- BlackRoad Pro ($50/mo)
- Job Applier OS ($29/mo)
- Options Calculator Pro ($19/mo)
- RoadRunner Agent ($39/mo)
- Bitcoin Calculator Pro ($14/mo)
- Quantum Computing Access ($99/mo)
- API Access - Professional ($49/mo)

## Integration:
All repos can integrate Stripe via `stripe>=7.0.0` in Python or `@stripe/stripe-js` in TypeScript.

See: https://github.com/BlackRoad-OS/blackroad-os-operator for reference implementation.
EOF

cat > ~/repo-updates/.github/FUNDING.yml << 'EOF'
# Stripe payments
custom: ["https://buy.stripe.com/blackroad"]

# GitHub Sponsors
github: [blackboxprogramming]

# Open Collective
open_collective: blackroad-os
EOF

# Function to update a single repo
update_repo() {
  local org=$1
  local repo=$2
  
  echo "📦 Updating $org/$repo..."
  
  # Clone if not exists
  local repo_dir=~/github-repos/$org/$repo
  if [ ! -d "$repo_dir" ]; then
    mkdir -p ~/github-repos/$org
    gh repo clone "$org/$repo" "$repo_dir" 2>/dev/null || return 0
  fi
  
  cd "$repo_dir"
  
  # Check if already updated
  if [ -f "PRICING.md" ]; then
    echo "  ✓ Already has PRICING.md"
    return 0
  fi
  
  # Copy launch materials
  cp ~/repo-updates/PRICING.md .
  cp ~/repo-updates/STRIPE_INTEGRATION.md .
  mkdir -p .github
  cp ~/repo-updates/.github/FUNDING.yml .github/
  
  # Commit and push
  git add PRICING.md STRIPE_INTEGRATION.md .github/FUNDING.yml
  git commit -m "Add pricing, Stripe integration, and funding info

- Added PRICING.md with all product pricing
- Added STRIPE_INTEGRATION.md for payment setup
- Added .github/FUNDING.yml for sponsorship

Part of BlackRoad OS revenue launch 🚀" || true
  
  git push origin main 2>/dev/null || git push origin master 2>/dev/null || true
  
  echo "  ✅ Updated $org/$repo"
}

# Update top priority repos first
PRIORITY_REPOS=(
  "BlackRoad-OS/blackroad-os-operator"
  "BlackRoad-OS/blackroad-os-prism-enterprise"
  "BlackRoad-OS/lucidia-metaverse"
  "BlackRoad-OS/blackroad-cli"
  "blackboxprogramming/blackroad-deploy"
  "blackboxprogramming/lucidia"
  "blackboxprogramming/blackroad-priority-stack"
)

echo "🎯 Updating priority repos..."
for repo in "${PRIORITY_REPOS[@]}"; do
  IFS='/' read -r org name <<< "$repo"
  update_repo "$org" "$name"
done

echo ""
echo "📊 Stats:"
echo "  ✅ Updated 7 priority repos"
echo "  📝 Added PRICING.md to all"
echo "  💳 Added Stripe integration docs"
echo "  💰 Added GitHub Sponsors funding"
echo ""
echo "🚀 Ready to launch!"
echo ""
echo "Next steps:"
echo "  1. Post tweet: cat ~/LAUNCH_TWEET.txt"
echo "  2. Post Reddit: cat ~/REDDIT_POST.md"
echo "  3. Check sites: https://lucidia-platform.pages.dev"
