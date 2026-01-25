#!/bin/bash

# BlackRoad Metaverse Deployment Script

echo "🌌 Deploying BlackRoad Metaverse to blackroad.io..."
echo ""

# Deploy to Cloudflare Pages
wrangler pages deploy . --project-name=blackroad-metaverse --branch=main

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🔗 Live at: https://blackroad.io"
echo "📊 Dashboard: https://dash.cloudflare.com"
echo ""
echo "🌟 The metaverse awaits!"
