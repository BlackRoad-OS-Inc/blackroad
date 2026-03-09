#!/bin/bash

# Railway API Setup Script for br-apps
# This creates the br-apps project and sets up services for blackroad.io

set -e

RAILWAY_TOKEN='rw_Fe26.2**4886aa7f30312f2b5175d740b004556007d92320a2d5d2501815a66a9bb86ae4*iVNo1MLhUpC8uZez5Bu43A*q8GfxbzT1NdUBKxPn5CMAA-bg0uucscc3_vYxVqQAm4j2n9JY8BBR873wpQz2Mr1mnxNYLarT4YHAM6zi6dskQ*1768349176306*1fca5dccd2a52158711982a114fe07f9d0fd7873b1a498d5f29b6852b50f92b5*82uj-X1WnJ50-e4u2W4MflsCi4bdhq3b_EqDnEYcP-g'
CF_TOKEN='yP5h0HvsXX0BpHLs01tLmgtTbQurIKPL4YnQfIwy'
CF_ZONE='848cf0b18d51e0170e0d1537aec3505a'

echo "🚂 Setting up br-apps Railway project..."

# Function to make Railway API calls
railway_api() {
  local query="$1"
  curl -s -X POST https://backboard.railway.app/graphql/v2 \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${RAILWAY_TOKEN}" \
    -d "{\"query\": $(echo "$query" | jq -Rs .)}"
}

# Step 1: Create Project
echo "📦 Creating br-apps project..."
PROJECT_RESPONSE=$(railway_api 'mutation { projectCreate(input: { name: "br-apps", description: "blackroad.io - Public apps and APIs" }) { id name } }')
PROJECT_ID=$(echo "$PROJECT_RESPONSE" | jq -r '.data.projectCreate.id')

if [ "$PROJECT_ID" = "null" ]; then
  echo "❌ Failed to create project. Response:"
  echo "$PROJECT_RESPONSE" | jq '.'
  exit 1
fi

echo "✅ Created project: $PROJECT_ID"

# Step 2: Create Environments
echo "🌍 Creating environments..."

for env in "dev" "staging" "prod"; do
  ENV_RESPONSE=$(railway_api "mutation { environmentCreate(input: { projectId: \"${PROJECT_ID}\", name: \"${env}\" }) { id name } }")
  ENV_ID=$(echo "$ENV_RESPONSE" | jq -r '.data.environmentCreate.id')
  echo "  ✅ Created environment: $env ($ENV_ID)"
done

# Step 3: Link GitHub Repos (manual step - requires OAuth)
echo ""
echo "📋 Next Steps (Manual):"
echo "1. Go to https://railway.app/project/${PROJECT_ID}"
echo "2. Click '+ New' → 'GitHub Repo'"
echo "3. Add these services:"
echo "   - blackroad-os-web → rename to 'web'"
echo "   - blackroad-os-api → rename to 'api'"
echo "   - blackroad-os-api-gateway → rename to 'gateway'"
echo "   - blackroad-os-agents → rename to 'worker'"
echo ""
echo "4. For each service, add custom domains:"
echo "   web: www.blackroad.io"
echo "   api: api.blackroad.io"
echo ""
echo "🌐 Railway will provide domains like:"
echo "   web-production.up.railway.app"
echo "   api-production.up.railway.app"
echo ""
echo "5. Then run the Cloudflare DNS setup:"
echo "   ./setup-cloudflare-dns.sh"
echo ""
echo "✅ br-apps project created successfully!"
echo "   Project ID: $PROJECT_ID"
echo "   URL: https://railway.app/project/${PROJECT_ID}"
