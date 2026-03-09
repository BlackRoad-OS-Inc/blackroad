#!/usr/bin/env bash
# Deploy Cloudflare Worker for BlackRoad

echo "🚀 Deploying BlackRoad Cloudflare Worker"
echo ""

# Check if wrangler is installed
if ! command -v wrangler &>/dev/null; then
    echo "📦 Installing wrangler..."
    npm install -g wrangler
fi

# Check auth
echo "🔐 Checking Cloudflare authentication..."
if ! wrangler whoami &>/dev/null; then
    echo "⚠️  Not logged in. Running: wrangler login"
    wrangler login
fi

# Deploy worker
echo "📤 Deploying worker..."
cd ~

if wrangler deploy blackroad-deploy-worker.js --name blackroad-deploy-dispatcher; then
    echo ""
    echo "✅ Worker deployed successfully!"
    echo ""
    echo "🌐 Your worker URL will be shown above"
    echo ""
    echo "Next steps:"
    echo "  1. Copy the worker URL"
    echo "  2. Go to GitHub repo settings → Webhooks"
    echo "  3. Add webhook with URL: https://blackroad-deploy-dispatcher.YOUR_SUBDOMAIN.workers.dev/webhook/github"
    echo "  4. Set Content type: application/json"
    echo "  5. Select: Just the push event"
else
    echo "❌ Deployment failed"
    echo ""
    echo "Manual deployment:"
    echo "  1. wrangler login"
    echo "  2. wrangler deploy ~/blackroad-deploy-worker.js --name blackroad-deploy-dispatcher"
fi
