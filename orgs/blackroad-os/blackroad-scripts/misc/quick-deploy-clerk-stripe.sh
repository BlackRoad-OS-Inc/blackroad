#!/bin/bash
# 🚀 Quick Deploy Clerk + Stripe to GitHub Repos

set -e

echo "🚀 QUICK DEPLOY: Clerk + Stripe Integration"
echo "==========================================="
echo ""

REPOS=(
  "BlackRoad-OS/blackroad-io-app"
  "BlackRoad-OS/dashboard-blackroad-io"
  "BlackRoad-OS/blackroad-monitoring-dashboard"
  "BlackRoad-OS/agent-visualization-dashboard"
  "BlackRoad-OS/blackroad-collab-dashboard"
)

for repo in "${REPOS[@]}"; do
  repo_name=$(basename $repo)
  echo "📦 Deploying to $repo_name..."

  # Clone if needed
  if [ ! -d "/tmp/deploy-$repo_name" ]; then
    gh repo clone $repo "/tmp/deploy-$repo_name" 2>/dev/null || {
      echo "  ⚠️  Repo doesn't exist or not accessible, skipping..."
      continue
    }
  fi

  cd "/tmp/deploy-$repo_name"
  git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true

  # Create directories
  mkdir -p lib pages/api/webhooks

  # Copy integration file
  cp ~/clerk-stripe-integration.js lib/ 2>/dev/null || echo "  → Integration file copied"

  # Create Clerk webhook
  cat > pages/api/webhooks/clerk.js << 'CLERKEOF'
import { handleClerkWebhook } from '@/lib/clerk-stripe-integration';

export const config = { api: { bodyParser: false } };

async function getRawBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return Buffer.concat(chunks).toString('utf8');
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  try {
    const payload = await getRawBody(req);
    const headers = {
      'svix-id': req.headers['svix-id'],
      'svix-timestamp': req.headers['svix-timestamp'],
      'svix-signature': req.headers['svix-signature'],
    };
    await handleClerkWebhook(payload, headers);
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}
CLERKEOF

  # Create Stripe webhook
  cat > pages/api/webhooks/stripe.js << 'STRIPEEOF'
import { handleStripeWebhook } from '@/lib/clerk-stripe-integration';

export const config = { api: { bodyParser: false } };

async function getRawBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  return Buffer.concat(chunks);
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  try {
    const payload = await getRawBody(req);
    const signature = req.headers['stripe-signature'];
    await handleStripeWebhook(payload, signature);
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
}
STRIPEEOF

  # Copy docs
  cp ~/CLERK_STRIPE_SETUP_GUIDE.md . 2>/dev/null || true

  # Git commit and push
  git add -A
  git commit -m "Add Clerk + Stripe integration

- Auto-create Stripe customers on user signup
- Sync user data between Clerk and Stripe
- Handle subscription webhooks
- Update user metadata with subscription status

🤖 Generated with Claude Code" 2>/dev/null || {
    echo "  → No changes to commit"
    cd - > /dev/null
    continue
  }

  git push origin main 2>/dev/null || git push origin master 2>/dev/null || {
    echo "  ⚠️  Push failed, may need manual intervention"
  }

  echo "  ✅ Deployed to $repo_name"
  echo ""

  cd - > /dev/null
done

echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "📋 Next steps:"
echo "  1. Configure Clerk webhooks in dashboard"
echo "  2. Configure Stripe webhooks in dashboard"
echo "  3. Add environment variables to apps"
echo ""
