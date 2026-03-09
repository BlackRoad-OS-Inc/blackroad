#!/bin/bash
# 🚀 Deploy Clerk + Stripe Integration to BlackRoad Apps

set -e

echo "🔗 CLERK + STRIPE INTEGRATION DEPLOYMENT"
echo "========================================"
echo ""

# Configuration
INTEGRATION_DIR="/Users/alexa"
TARGET_REPOS=(
  "BlackRoad-OS/blackroad-io-app"
  "BlackRoad-OS/dashboard-blackroad-io"
  "BlackRoad-OS/blackroad-monitoring-dashboard"
)

echo "📦 Integration files ready:"
echo "  ✅ clerk-stripe-integration.js"
echo "  ✅ clerk-stripe-api-routes.js"
echo "  ✅ CLERK_STRIPE_SETUP_GUIDE.md"
echo ""

# Function to deploy to a repo
deploy_to_repo() {
  local repo=$1
  local repo_name=$(basename $repo)

  echo "🚀 Deploying to $repo_name..."

  # Clone or update repo
  if [ -d "/tmp/$repo_name" ]; then
    echo "  → Updating existing clone..."
    cd "/tmp/$repo_name"
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null
  else
    echo "  → Cloning repo..."
    gh repo clone $repo "/tmp/$repo_name"
    cd "/tmp/$repo_name"
  fi

  # Create directories
  mkdir -p lib
  mkdir -p pages/api/webhooks

  # Copy integration files
  echo "  → Copying integration files..."
  cp "$INTEGRATION_DIR/clerk-stripe-integration.js" lib/
  cp "$INTEGRATION_DIR/CLERK_STRIPE_SETUP_GUIDE.md" ./

  # Extract API routes from the combined file
  echo "  → Setting up API routes..."

  # Create Clerk webhook route
  cat > pages/api/webhooks/clerk.js << 'EOF'
import { handleClerkWebhook } from '@/lib/clerk-stripe-integration';

export const config = {
  api: {
    bodyParser: false,
  },
};

async function getRawBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString('utf8');
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

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
    console.error('Clerk webhook error:', error);
    res.status(400).json({ error: error.message });
  }
}
EOF

  # Create Stripe webhook route
  cat > pages/api/webhooks/stripe.js << 'EOF'
import { handleStripeWebhook } from '@/lib/clerk-stripe-integration';

export const config = {
  api: {
    bodyParser: false,
  },
};

async function getRawBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const payload = await getRawBody(req);
    const signature = req.headers['stripe-signature'];

    await handleStripeWebhook(payload, signature);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Stripe webhook error:', error);
    res.status(400).json({ error: error.message });
  }
}
EOF

  # Check if package.json exists
  if [ -f "package.json" ]; then
    echo "  → Checking dependencies..."

    # Check if deps are already installed
    if ! grep -q '"stripe"' package.json; then
      echo "  → Adding Stripe dependency..."
      npm install --save stripe 2>/dev/null || echo "    (manual install needed)"
    fi

    if ! grep -q '"svix"' package.json; then
      echo "  → Adding Svix dependency..."
      npm install --save svix 2>/dev/null || echo "    (manual install needed)"
    fi
  fi

  # Create/update .env.example
  cat > .env.example << 'EOF'
# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
CLERK_WEBHOOK_SECRET=whsec_...

# Stripe
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
EOF

  echo "  ✅ Deployment complete for $repo_name"
  echo ""
}

# Deploy to all target repos
for repo in "${TARGET_REPOS[@]}"; do
  deploy_to_repo $repo
done

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "📋 Next steps:"
echo "  1. Set up environment variables in each app"
echo "  2. Configure Clerk webhooks (see CLERK_STRIPE_SETUP_GUIDE.md)"
echo "  3. Configure Stripe webhooks (see CLERK_STRIPE_SETUP_GUIDE.md)"
echo "  4. Test the integration"
echo ""
echo "📖 Full guide: CLERK_STRIPE_SETUP_GUIDE.md"
echo ""
