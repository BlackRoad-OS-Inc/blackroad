#!/bin/bash

# RoadWorld Deployment Script
# Deploys to Cloudflare Pages

set -e

echo "🚀 BlackRoad RoadWorld Deployment"
echo "=================================="

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Wrangler CLI not found. Installing..."
    npm install -g wrangler
fi

# Check authentication
echo "📋 Checking Cloudflare authentication..."
wrangler whoami

# Deploy to Cloudflare Pages
echo "🌍 Deploying to Cloudflare Pages..."
wrangler pages deploy public --project-name=roadworld

echo "✅ Deployment complete!"
echo "🔗 Your site should be available at: https://roadworld.pages.dev"
