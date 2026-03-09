#!/bin/bash

# Complete Cloudflare DNS Setup for blackroad.io (br-apps)
# Sets up all subdomains for the br-apps Railway project

set -e

CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
CF_ZONE='848cf0b18d51e0170e0d1537aec3505a'

echo "☁️  Complete Cloudflare DNS Setup for blackroad.io"
echo "=================================================="
echo ""
echo "This will set up DNS for br-apps services:"
echo "  • www.blackroad.io → web service"
echo "  • blackroad.io (@) → web service"
echo "  • api.blackroad.io → api service"
echo "  • app.blackroad.io → prism console service"
echo "  • agents.blackroad.io → agents service (optional)"
echo "  • ops.blackroad.io → operator service (locked)"
echo ""

# Function to create or update DNS record
upsert_dns_record() {
  local name="$1"
  local target="$2"
  local proxy="${3:-true}"
  local record_type="CNAME"

  echo "📝 ${name} → $target"

  # Handle root domain
  local lookup_name="${name}.blackroad.io"
  if [ "$name" = "@" ]; then
    lookup_name="blackroad.io"
  fi

  # Check if record exists
  EXISTING=$(curl -s -X GET \
    "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records?name=${lookup_name}&type=${record_type}" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    -H "Content-Type: application/json")

  RECORD_ID=$(echo "$EXISTING" | jq -r '.result[0].id // empty')
  SUCCESS=$(echo "$EXISTING" | jq -r '.success')

  if [ "$SUCCESS" != "true" ]; then
    echo "   ❌ Error fetching record"
    return 1
  fi

  if [ -n "$RECORD_ID" ] && [ "$RECORD_ID" != "null" ]; then
    # Update existing
    RESPONSE=$(curl -s -X PATCH \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"type\": \"${record_type}\",
        \"name\": \"${name}\",
        \"content\": \"${target}\",
        \"proxied\": ${proxy},
        \"ttl\": 1
      }")
  else
    # Create new
    RESPONSE=$(curl -s -X POST \
      "https://api.cloudflare.com/client/v4/zones/${CF_ZONE}/dns_records" \
      -H "Authorization: Bearer ${CF_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"type\": \"${record_type}\",
        \"name\": \"${name}\",
        \"content\": \"${target}\",
        \"proxied\": ${proxy},
        \"ttl\": 1
      }")
  fi

  RESPONSE_SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
  if [ "$RESPONSE_SUCCESS" = "true" ]; then
    echo "   ✅ Done"
  else
    echo "   ❌ Failed"
    echo "$RESPONSE" | jq '.errors'
  fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Get your Railway domains from the br-apps project:"
echo "  1. Open https://railway.app/dashboard"
echo "  2. Go to br-apps project"
echo "  3. For each service: Settings → Networking → Public Domain"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Collect Railway domains
read -p "Railway domain for WEB (e.g., web-production.up.railway.app): " WEB_DOMAIN
read -p "Railway domain for API (e.g., api-production.up.railway.app): " API_DOMAIN
read -p "Railway domain for APP/Prism (e.g., app-production.up.railway.app): " APP_DOMAIN

# Optional services
read -p "Railway domain for AGENTS (optional, press Enter to skip): " AGENTS_DOMAIN
read -p "Railway domain for OPS (optional, press Enter to skip): " OPS_DOMAIN

# Validate required inputs
if [ -z "$WEB_DOMAIN" ] || [ -z "$API_DOMAIN" ] || [ -z "$APP_DOMAIN" ]; then
  echo ""
  echo "❌ Error: WEB, API, and APP domains are required!"
  exit 1
fi

# Show plan
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Ready to create these DNS records:"
echo ""
echo "  www.blackroad.io     → $WEB_DOMAIN"
echo "  blackroad.io (@)     → $WEB_DOMAIN"
echo "  api.blackroad.io     → $API_DOMAIN"
echo "  app.blackroad.io     → $APP_DOMAIN"

if [ -n "$AGENTS_DOMAIN" ]; then
  echo "  agents.blackroad.io  → $AGENTS_DOMAIN"
fi

if [ -n "$OPS_DOMAIN" ]; then
  echo "  ops.blackroad.io     → $OPS_DOMAIN"
fi

echo ""
read -p "Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "🚀 Creating DNS records..."
echo ""

# Create core records
upsert_dns_record "www" "$WEB_DOMAIN" "true"
upsert_dns_record "@" "$WEB_DOMAIN" "true"
upsert_dns_record "api" "$API_DOMAIN" "true"
upsert_dns_record "app" "$APP_DOMAIN" "true"

# Optional records
if [ -n "$AGENTS_DOMAIN" ]; then
  upsert_dns_record "agents" "$AGENTS_DOMAIN" "true"
fi

if [ -n "$OPS_DOMAIN" ]; then
  upsert_dns_record "ops" "$OPS_DOMAIN" "true"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ DNS setup complete for blackroad.io!"
echo ""
echo "🔗 Your live domains:"
echo "   https://www.blackroad.io"
echo "   https://blackroad.io"
echo "   https://api.blackroad.io"
echo "   https://app.blackroad.io"

if [ -n "$AGENTS_DOMAIN" ]; then
  echo "   https://agents.blackroad.io"
fi

if [ -n "$OPS_DOMAIN" ]; then
  echo "   https://ops.blackroad.io (should be locked via Cloudflare Access)"
fi

echo ""
echo "⏱  DNS propagation: 5-10 minutes"
echo "🔒 SSL: Auto-generated by Railway"
echo ""
echo "🧪 Test with:"
echo "   curl -I https://www.blackroad.io"
echo "   curl -I https://api.blackroad.io/health"
echo "   curl -I https://app.blackroad.io"
echo ""
echo "📊 Verify DNS: https://dash.cloudflare.com/${CF_ZONE}/dns"
echo ""
echo "🔐 Next: Set up Cloudflare Access for ops.blackroad.io"
echo "   https://dash.cloudflare.com/${CF_ZONE}/access/apps"
echo ""
