#!/bin/bash
# 💰 Complete Cost Audit for BlackRoad Infrastructure

echo "💰 BLACKROAD INFRASTRUCTURE COST AUDIT"
echo "======================================"
echo ""

echo "🔍 Checking Railway..."
if command -v railway &> /dev/null; then
    echo "   ⚠️  Railway CLI found - checking projects..."
    railway status 2>&1 || echo "   Not logged in or no projects"
else
    echo "   ✅ Railway CLI not installed (not using)"
fi
echo ""

echo "🔍 Checking Vercel..."
if command -v vercel &> /dev/null; then
    echo "   ⚠️  Vercel CLI found - checking projects..."
    vercel ls 2>&1 || echo "   Not logged in or no projects"
else
    echo "   ✅ Vercel CLI not installed (not using)"
fi
echo ""

echo "🔍 Checking DigitalOcean..."
if command -v doctl &> /dev/null; then
    echo "   Droplets:"
    doctl compute droplet list --format Name,Status,PublicIPv4,Memory,Disk,VCPUs 2>&1
    echo ""
    echo "   Monthly cost estimate: ~$6/droplet"
else
    echo "   ⚠️  Install: brew install doctl"
    echo "   Or visit: https://cloud.digitalocean.com/droplets"
fi
echo ""

echo "🔍 Checking Cloudflare (should be FREE tier)..."
if command -v wrangler &> /dev/null; then
    echo "   Workers:"
    wrangler deployments list 2>&1 | head -10 || echo "   Not logged in"
    echo ""
    echo "   ✅ Cloudflare should be $0/month on free tier"
else
    echo "   ✅ Wrangler installed, Cloudflare should be free"
fi
echo ""

echo "🔍 Checking local Docker containers..."
echo "   Running containers (using electricity):"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "   Docker not running"
echo ""

echo "🔍 Checking for API key usage..."
echo ""
echo "   OpenAI API keys in env:"
env | grep -i openai || echo "   ✅ No OpenAI keys in environment"
echo ""
echo "   Anthropic API keys in env:"
env | grep -i anthropic || echo "   ✅ No Anthropic keys in environment"
echo ""

echo "📊 COST SUMMARY"
echo "==============="
echo ""
echo "FREE Services:"
echo "  ✅ GitHub (15 orgs, unlimited public repos)"
echo "  ✅ Cloudflare (19 Pages, Workers, KV, DNS)"
echo "  ✅ All Forkable Services (Meilisearch, MinIO, etc.)"
echo ""
echo "PAID Services:"
echo "  💰 Domains: ~$17/month (essential)"
echo "  💰 DigitalOcean: ~$6/month (failover - can eliminate)"
echo "  💰 Electricity: ~$10/month (can optimize to $6)"
echo "  ⚠️  Railway: CHECK DASHBOARD"
echo "  ⚠️  Vercel: CHECK DASHBOARD"
echo "  ⚠️  AI APIs: CHECK USAGE"
echo ""
echo "🎯 TARGET: $17/month (domains only)"
echo "   Action: Migrate to Oracle Cloud Free Tier"
echo "   Action: Optimize power consumption"
echo "   Action: Migrate all Railway/Vercel to own hardware"
echo ""
