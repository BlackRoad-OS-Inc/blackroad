#!/bin/bash
set -e

# Credentials
export RAILWAY_TOKEN='c76cf62a-dbe7-469f-a105-bd0d35cf323e'
export CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
export CF_ZONE='848cf0b18d51e0170e0d1537aec3505a'

echo "🚀 DEPLOYING blackroad.io NOW"
echo "=============================="
echo ""

# Test Cloudflare
echo "Testing Cloudflare API..."
CF_RESULT=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}" \
  -H "Authorization: Bearer ${CF_TOKEN}")

if echo "$CF_RESULT" | grep -q "blackroad.io"; then
  echo "✅ Cloudflare authenticated: blackroad.io zone found"
else
  echo "❌ Cloudflare auth failed"
  echo "$CF_RESULT"
  exit 1
fi

echo ""
echo "Cloudflare is READY. Now let's get Railway domains from the existing project."
echo ""
echo "Railway Project ID: 03ce1e43-5086-4255-b2bc-0146c8916f4c"
echo ""
echo "You need to get the Railway domains from the dashboard:"
echo "1. Go to: https://railway.app/project/03ce1e43-5086-4255-b2bc-0146c8916f4c"
echo "2. For each service (web, app, ops), get the Railway domain"
echo ""
read -p "Enter WEB Railway domain (e.g., web-production.up.railway.app): " WEB_DOMAIN
read -p "Enter APP Railway domain (e.g., app-production.up.railway.app): " APP_DOMAIN
read -p "Enter OPS Railway domain (e.g., ops-production.up.railway.app): " OPS_DOMAIN

echo ""
echo "Creating DNS records..."
echo ""

# Function to create DNS
create_dns() {
  local name=$1
  local target=$2

  echo "Creating ${name}.blackroad.io → ${target}"

  # Check if exists
  EXISTING=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${name}.blackroad.io" \
    -H "Authorization: Bearer ${CF_TOKEN}")

  RECORD_ID=$(echo "$EXISTING" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'] if d.get('result') else '')" 2>/dev/null || echo "")

  if [ -n "$RECORD_ID" ]; then
    # Update
    curl -s -X PATCH \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${target}\",\"proxied\":true,\"ttl\":1}" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Updated' if d.get('success') else '  ❌ Failed')"
  else
    # Create
    curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"type\":\"CNAME\",\"name\":\"${name}\",\"content\":\"${target}\",\"proxied\":true,\"ttl\":1}" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Created' if d.get('success') else '  ❌ Failed')"
  fi
}

# Create DNS records
create_dns "www" "$WEB_DOMAIN"
create_dns "@" "$WEB_DOMAIN"
create_dns "api" "$APP_DOMAIN"
create_dns "app" "$APP_DOMAIN"
create_dns "ops" "$OPS_DOMAIN"

echo ""
echo "=============================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=============================="
echo ""
echo "Live domains:"
echo "  https://www.blackroad.io"
echo "  https://blackroad.io"
echo "  https://app.blackroad.io"
echo "  https://ops.blackroad.io"
echo ""
echo "Wait 5-10 minutes for DNS propagation, then test:"
echo "  curl -I https://www.blackroad.io"
echo ""
