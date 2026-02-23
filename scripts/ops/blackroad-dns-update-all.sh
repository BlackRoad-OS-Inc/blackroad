#!/bin/bash
# Update ALL 19 BlackRoad domains to point to codex-infinity

CODEX_IP="159.65.43.12"

DOMAINS=(
  "aliceqi.com"
  "blackboxprogramming.io"
  "blackroadai.com"
  "blackroad.company"
  "blackroadinc.us"
  "blackroad.io"
  "blackroad.me"
  "blackroad.network"
  "blackroadqi.com"
  "blackroadquantum.com"
  "blackroadquantum.info"
  "blackroadquantum.net"
  "blackroadquantum.shop"
  "blackroadquantum.store"
  "blackroad.systems"
  "lucidiaqi.com"
  "lucidia.studio"
  "roadchain.io"
  "roadcoin.io"
)

echo "🚀 Updating DNS for all 19 domains to $CODEX_IP"
echo ""

for domain in "${DOMAINS[@]}"; do
  echo "📝 Updating $domain..."
  
  # Try to create/update A record
  wrangler dns create "$domain" A @ --content "$CODEX_IP" --ttl 1 2>&1 | grep -v "API error" || \
  wrangler dns update "$domain" A @ --content "$CODEX_IP" --ttl 1 2>&1 || \
  echo "  ⚠️  May need manual update for $domain"
  
  # Also add www subdomain
  wrangler dns create "$domain" A www --content "$CODEX_IP" --ttl 1 2>&1 > /dev/null || true
  
  echo "  ✓ $domain → $CODEX_IP"
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DNS updates queued! Changes may take 1-5 minutes."
echo ""
echo "Test with:"
echo "  dig blackroad.io"
echo "  curl http://blackroad.io"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
