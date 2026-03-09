#!/bin/bash
set -e

CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
CF_ZONE='d6566eba4500b460ffec6650d3b4baf6'  # blackroad.io - THE CORRECT ONE!

echo "🚀 DEPLOYING blackroad.io FOR REAL"
echo "===================================="
echo ""

# Get Railway domains from user
echo "Go to: https://railway.app/project/03ce1e43-5086-4255-b2bc-0146c8916f4c"
echo ""
echo "For each service, get Settings → Networking → Public Domain"
echo ""
read -p "WEB Railway domain (e.g., blackroad-os-web-production.up.railway.app): " WEB_DOMAIN
read -p "APP Railway domain (e.g., blackroad-os-prism-console-production.up.railway.app): " APP_DOMAIN
read -p "OPS Railway domain (if deployed, or press Enter to skip): " OPS_DOMAIN

if [ -z "$WEB_DOMAIN" ]; then
  echo "❌ Need at least WEB domain!"
  exit 1
fi

echo ""
echo "Creating DNS records..."
echo ""

# Function to create/update DNS
create_dns() {
  local name=$1
  local target=$2
  local lookup_name="${name}.blackroad.io"

  if [ "$name" = "@" ]; then
    lookup_name="blackroad.io"
  fi

  echo "📝 ${lookup_name} → ${target}"

  # Check existing
  EXISTING=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${lookup_name}" \
    -H "Authorization: Bearer ${CF_TOKEN}")

  RECORD_ID=$(echo "$EXISTING" | jq -r '.result[0].id // ""' 2>/dev/null)

  if [ -n "$RECORD_ID" ] && [ "$RECORD_ID" != "null" ]; then
    # Update
    RESULT=$(curl -s -X PATCH \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H 'Content-Type: application/json' \
      -d "{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${target}\",\"proxied\":true,\"ttl\":1}")

    if echo "$RESULT" | jq -e '.success' >/dev/null 2>&1; then
      echo "  ✅ Updated"
    else
      echo "  ❌ Failed: $(echo $RESULT | jq -r '.errors[0].message // "Unknown"')"
    fi
  else
    # Create
    RESULT=$(curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H 'Content-Type: application/json' \
      -d "{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${target}\",\"proxied\":true,\"ttl\":1}")

    if echo "$RESULT" | jq -e '.success' >/dev/null 2>&1; then
      echo "  ✅ Created"
    else
      echo "  ❌ Failed: $(echo $RESULT | jq -r '.errors[0].message // "Unknown"')"
    fi
  fi
}

# Create DNS for web
create_dns "www" "$WEB_DOMAIN"
create_dns "@" "$WEB_DOMAIN"

# Create DNS for app
if [ -n "$APP_DOMAIN" ]; then
  create_dns "app" "$APP_DOMAIN"
fi

# Create DNS for ops
if [ -n "$OPS_DOMAIN" ]; then
  create_dns "ops" "$OPS_DOMAIN"
fi

echo ""
echo "===================================="
echo "✅ DNS CONFIGURED!"
echo "===================================="
echo ""
echo "🌐 Live domains (wait 5-10 min for DNS):"
echo "  https://www.blackroad.io"
echo "  https://blackroad.io"
if [ -n "$APP_DOMAIN" ]; then
  echo "  https://app.blackroad.io"
fi
if [ -n "$OPS_DOMAIN" ]; then
  echo "  https://ops.blackroad.io"
fi
echo ""
echo "🧪 Test with:"
echo "  curl -I https://www.blackroad.io"
echo ""
