#!/bin/bash
# Verify DNS propagation for BlackRoad domains

echo "🔍 Verifying DNS Propagation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

DOMAINS=(
  "blackroad.io"
  "blackroadai.com"
  "blackroad.company"
  "blackroad.network"
  "blackroad.systems"
)

CODEX_IP="159.65.43.12"

for domain in "${DOMAINS[@]}"; do
  echo "Testing $domain..."
  RESOLVED=$(dig +short "$domain" | head -1)
  
  if [ "$RESOLVED" == "$CODEX_IP" ]; then
    echo "  ✅ $domain → $RESOLVED (correct!)"
  elif [ -n "$RESOLVED" ]; then
    echo "  ⚠️  $domain → $RESOLVED (propagating...)"
  else
    echo "  ⏳ $domain not yet resolved"
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Full propagation typically takes 1-5 minutes"
echo "Check again with: ~/blackroad-verify-dns.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
