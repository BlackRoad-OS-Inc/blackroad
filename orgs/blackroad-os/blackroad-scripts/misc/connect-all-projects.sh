#!/bin/bash
# Connect all 87 Cloudflare Pages projects to GitHub

set -e

echo "🔗 Connecting 87 Cloudflare Pages Projects to GitHub"
echo "===================================================="
echo ""

# Get all Pages projects that are NOT connected
echo "📊 Finding projects without Git connection..."
UNCONNECTED=$(wrangler pages project list 2>&1 | grep "No" | awk '{print $2}' | head -20)

if [ -z "$UNCONNECTED" ]; then
    echo "✅ All projects already connected!"
    exit 0
fi

echo "Found unconnected projects. Let me map them to GitHub repos..."
echo ""

# Create comprehensive mapping
cat > ~/complete-pages-mapping.json << 'EOFMAPPING'
{
  "mappings": [
    {"page": "blackroad-hello", "repo": "blackroad-hello", "build_cmd": "npm run build", "output": "dist"},
    {"page": "lucidia-earth", "repo": "lucidia-platform", "build_cmd": "npm run build", "output": "dist"},
    {"page": "blackroad-os-demo", "repo": "blackroad-os-demo", "build_cmd": "npm run build", "output": "dist"},
    {"page": "blackroad-os-home", "repo": "blackroad-os-home", "build_cmd": "npm run build", "output": "dist"},
    {"page": "blackroad-console", "repo": "blackroad-os-console", "build_cmd": "npm run build", "output": "dist"},
    {"page": "analytics-blackroad-io", "repo": "blackroad-os-analytics", "build_cmd": "npm run build", "output": "dist"},
    {"page": "creator-studio-blackroad-io", "repo": "blackroad-os-pack-creator-studio", "build_cmd": "npm run build", "output": "dist"},
    {"page": "research-lab-blackroad-io", "repo": "blackroad-os-pack-research-lab", "build_cmd": "npm run build", "output": "dist"},
    {"page": "finance-blackroad-io", "repo": "blackroad-os-pack-finance", "build_cmd": "npm run build", "output": "dist"},
    {"page": "legal-blackroad-io", "repo": "blackroad-os-pack-legal", "build_cmd": "npm run build", "output": "dist"},
    {"page": "education-blackroad-io", "repo": "blackroad-os-pack-education", "build_cmd": "npm run build", "output": "dist"},
    {"page": "engineering-blackroad-io", "repo": "blackroad-os-pack-engineering", "build_cmd": "npm run build", "output": "dist"},
    {"page": "blackroad-monitoring", "repo": "blackroad-monitoring", "build_cmd": "", "output": "."}
  ]
}
EOFMAPPING

echo "✅ Created mapping file: ~/complete-pages-mapping.json"
echo ""

# Display connection instructions
echo "📋 CONNECTION INSTRUCTIONS"
echo "=========================="
echo ""
echo "Unfortunately, Cloudflare Pages Git connection requires using the Dashboard"
echo "as the API doesn't support direct Git repo linking yet."
echo ""
echo "Here's how to connect each project:"
echo ""
echo "1. Go to: https://dash.cloudflare.com/pages"
echo "2. For each project below:"
echo "   - Click project name"
echo "   - Go to Settings → Builds & deployments"
echo "   - Click 'Connect to Git'"
echo "   - Select GitHub"
echo "   - Choose the repository"
echo "   - Set build command and output directory"
echo "   - Save"
echo ""
echo "📦 PRIORITY PROJECTS TO CONNECT (First 10):"
echo "-------------------------------------------"

jq -r '.mappings[0:10] | .[] | "- \(.page) → BlackRoad-OS/\(.repo) (build: \(.build_cmd), output: \(.output))"' ~/complete-pages-mapping.json

echo ""
echo "💡 ALTERNATIVE: Automated GitHub Repo Creation"
echo "----------------------------------------------"
echo "I can create GitHub repos for projects that don't have them yet."
echo ""

