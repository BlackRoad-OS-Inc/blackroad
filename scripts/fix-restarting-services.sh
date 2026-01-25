#!/bin/bash
# 🎵 ARIA - Fix Restarting Services

echo "🎵 ARIA - Fixing Restarting Services"
echo "===================================="
echo ""

# Check Meilisearch logs
echo "📋 Checking Meilisearch..."
docker logs meilisearch --tail 20 2>&1 | head -15

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Fix: Remove and recreate with proper config
echo "🔧 Restarting Meilisearch with fresh config..."
docker rm -f meilisearch 2>/dev/null

docker run -d \
  --name meilisearch \
  --restart unless-stopped \
  -p 7700:7700 \
  -v ~/forkies/meilisearch:/meili_data \
  -e MEILI_ENV=production \
  getmeili/meilisearch:latest

echo "✅ Meilisearch restarted"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Headscale logs
echo "📋 Checking Headscale..."
docker logs blackroad-headscale --tail 20 2>&1 | head -15

echo ""
echo "🎵 Services diagnostic complete!"
echo ""

# Show current status
docker ps | grep -E "(meilisearch|headscale|minio)" | head -10

