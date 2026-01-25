#!/bin/bash

# BlackRoad OS Domain Verification Script
# Run this after adding custom domains in Cloudflare Dashboard

echo "🔍 BlackRoad OS - Domain Verification"
echo "======================================"
echo ""

DOMAINS=(
    "pitstop.blackroad.io"
    "universe.blackroad.io"
)

echo "Testing domains..."
echo ""

for domain in "${DOMAINS[@]}"; do
    echo "🌐 Testing: $domain"
    echo "   DNS lookup..."

    # Check DNS
    if dig +short "$domain" | grep -q "."; then
        echo "   ✅ DNS resolved"

        # Check HTTP
        echo "   HTTP check..."
        status=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain" --max-time 5 || echo "timeout")

        if [ "$status" == "200" ]; then
            echo "   ✅ HTTPS working (200 OK)"
            echo "   🎉 $domain is LIVE!"
        elif [ "$status" == "timeout" ]; then
            echo "   ⏳ Connection timeout (might still be provisioning)"
        else
            echo "   ⚠️  HTTP $status (check SSL provisioning)"
        fi
    else
        echo "   ⏳ DNS not propagated yet (wait 2-3 minutes)"
    fi
    echo ""
done

echo "======================================"
echo "🔗 Quick Links:"
echo ""
echo "Pitstop Portal:"
echo "   https://pitstop.blackroad.io"
echo "   Login: alexa / blackroad2025"
echo ""
echo "Universe Metaverse:"
echo "   https://universe.blackroad.io"
echo ""
echo "======================================"
echo ""
echo "If domains aren't ready yet:"
echo "   • Wait 2-3 more minutes"
echo "   • Re-run this script: bash VERIFY_DOMAINS.sh"
echo ""
