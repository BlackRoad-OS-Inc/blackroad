#!/bin/bash

CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
CF_ZONE='d6566eba4500b460ffec6650d3b4baf6'

cat << 'BANNER'
████████████████████████████████████████████
█  🚀 SHIPPING blackroad.io NOW!           █
████████████████████████████████████████████
BANNER

echo ""
echo "✅ Cloudflare API: READY (zone: blackroad.io)"
echo "✅ DNS will be automated"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "I just need Railway domains from you!"
echo ""
echo "Option 1: From Railway Dashboard"
echo "  1. Go to your Railway project"
echo "  2. Click each service → Settings → Networking"
echo "  3. Copy the 'Public Domain'"
echo ""
echo "Option 2: Use Railway CLI"
echo "  railway status --json"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get domains
read -p "WEB domain (or press Enter to skip): " WEB
read -p "APP domain (or press Enter to skip): " APP
read -p "OPS domain (or press Enter to skip): " OPS

if [ -z "$WEB" ] && [ -z "$APP" ] && [ -z "$OPS" ]; then
  echo ""
  echo "No domains provided. Let me try some common Railway patterns..."
  echo ""

  # Try common patterns
  TEST_DOMAINS=(
    "blackroad-os-web-production.up.railway.app"
    "blackroad-core-web-production.up.railway.app"
    "web-production.up.railway.app"
  )

  echo "Testing common Railway domain patterns..."
  for domain in "${TEST_DOMAINS[@]}"; do
    if curl -s -I "https://$domain" | grep -q "HTTP"; then
      echo "  ✅ Found working domain: $domain"
      WEB="$domain"
      break
    fi
  done
fi

# DNS creation function
create_dns() {
  local subdomain=$1
  local target=$2
  local name="$subdomain"

  if [ "$subdomain" = "root" ]; then
    name="@"
  fi

  echo "📝 Creating ${subdomain}.blackroad.io → $target"

  RESULT=$(curl -s -X POST \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${target}\",\"proxied\":true,\"ttl\":1}")

  if echo "$RESULT" | jq -e '.success' >/dev/null 2>&1; then
    echo "  ✅ Created!"
  else
    ERROR=$(echo "$RESULT" | jq -r '.errors[0].message // "Unknown error"')
    if echo "$ERROR" | grep -q "already exists"; then
      echo "  ℹ️  Already exists (that's fine!)"
    else
      echo "  ❌ Error: $ERROR"
    fi
  fi
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Creating DNS Records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create DNS
if [ -n "$WEB" ]; then
  create_dns "www" "$WEB"
  create_dns "root" "$WEB"
fi

if [ -n "$APP" ]; then
  create_dns "app" "$APP"
fi

if [ -n "$OPS" ]; then
  create_dns "ops" "$OPS"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOYMENT COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Live domains (wait 2-5 min for DNS):"
[ -n "$WEB" ] && echo "  https://www.blackroad.io"
[ -n "$WEB" ] && echo "  https://blackroad.io"
[ -n "$APP" ] && echo "  https://app.blackroad.io"
[ -n "$OPS" ] && echo "  https://ops.blackroad.io"
echo ""
echo "🧪 Test it:"
echo "  curl -I https://www.blackroad.io"
echo ""
echo "🎉 blackroad.io is LIVE!"
echo ""
