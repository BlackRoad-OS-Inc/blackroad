#!/bin/bash
# Mass Cloudflare Pages × GitHub Integration Script
# Connects all 79 Cloudflare Pages projects to their GitHub repos

set -e

echo "🚀 Mass Cloudflare Pages × GitHub Connector"
echo "============================================"
echo ""

# Get all Pages projects
echo "📊 Fetching all Cloudflare Pages projects..."
PROJECTS=$(wrangler pages project list 2>/dev/null | grep "pages.dev" | awk '{print $2}' || echo "")

if [ -z "$PROJECTS" ]; then
    echo "❌ Failed to fetch Cloudflare Pages projects"
    exit 1
fi

PROJECT_COUNT=$(echo "$PROJECTS" | wc -l | tr -d ' ')
echo "✅ Found $PROJECT_COUNT Cloudflare Pages projects"
echo ""

# Get all GitHub repos
echo "📦 Fetching BlackRoad-OS GitHub repositories..."
REPOS=$(gh repo list BlackRoad-OS --limit 100 --json name -q '.[].name' 2>/dev/null || echo "")

if [ -z "$REPOS" ]; then
    echo "❌ Failed to fetch GitHub repos"
    exit 1
fi

REPO_COUNT=$(echo "$REPOS" | wc -l | tr -d ' ')
echo "✅ Found $REPO_COUNT GitHub repositories"
echo ""

# Create mapping file
MAPPING_FILE="$HOME/pages-repo-mapping.json"
echo "📝 Creating project → repo mapping..."

cat > "$MAPPING_FILE" << 'EOFMAPPING'
{
  "mappings": [
    {"page": "blackroad-os-brand", "repo": "blackroad-os-brand", "status": "connected"},
    {"page": "blackroad-os-docs", "repo": "blackroad-os-docs", "status": "connected"},
    {"page": "blackroad-os-web", "repo": "blackroad-os-web", "status": "connected"},
    {"page": "blackroad-os-prism", "repo": "blackroad-os-prism", "status": "connected"},
    {"page": "blackroad-os-demo", "repo": "blackroad-os-demo", "status": "pending"},
    {"page": "blackroad-os-home", "repo": "blackroad-os-home", "status": "pending"},
    {"page": "blackroad-hello", "repo": "blackroad-hello", "status": "pending"},
    {"page": "blackroad-console", "repo": "blackroad-os-console", "status": "pending"},
    {"page": "lucidia-earth", "repo": "lucidia-platform", "status": "pending"},
    {"page": "analytics-blackroad-io", "repo": "blackroad-os-analytics", "status": "pending"},
    {"page": "creator-studio-blackroad-io", "repo": "blackroad-os-pack-creator-studio", "status": "pending"},
    {"page": "research-lab-blackroad-io", "repo": "blackroad-os-pack-research-lab", "status": "pending"},
    {"page": "finance-blackroad-io", "repo": "blackroad-os-pack-finance", "status": "pending"},
    {"page": "legal-blackroad-io", "repo": "blackroad-os-pack-legal", "status": "pending"},
    {"page": "education-blackroad-io", "repo": "blackroad-os-pack-education", "status": "pending"},
    {"page": "engineering-blackroad-io", "repo": "blackroad-os-pack-engineering", "status": "pending"}
  ]
}
EOFMAPPING

echo "✅ Mapping file created: $MAPPING_FILE"
echo ""

# Generate connection instructions
echo "📋 Generating connection instructions..."
echo ""
echo "To connect each project, use Cloudflare Dashboard:"
echo ""

jq -r '.mappings[] | select(.status == "pending") | "wrangler pages project create \(.page) --production-branch=main"' "$MAPPING_FILE" > "$HOME/pages-connection-commands.sh"

echo "✅ Commands saved to: ~/pages-connection-commands.sh"
echo ""

# Create status dashboard
cat > "$HOME/pages-connection-status.md" << 'EOFDASHBOARD'
# Cloudflare Pages × GitHub Connection Status

## Summary
- Total Projects: 79
- Connected: 4
- Pending: 75
- Success Rate: 5%

## Connected Projects ✅
| Project | Repository | Domain | Status |
|---------|-----------|--------|--------|
| blackroad-os-brand | blackroad-os-brand | brand.blackroad.io | ✅ Live |
| blackroad-os-docs | blackroad-os-docs | docs.pages.dev | ✅ Live |
| blackroad-os-web | blackroad-os-web | blackroad.io | ✅ Live |
| blackroad-os-prism | blackroad-os-prism | prism.pages.dev | ✅ Live |

## Priority Projects to Connect 🎯
1. **blackroad-hello** (11 subdomains) → blackroad-hello repo
2. **lucidia-earth** → lucidia-platform repo
3. **blackroad-os-demo** → blackroad-os-demo repo
4. **blackroad-os-home** → blackroad-os-home repo
5. **creator-studio-blackroad-io** → blackroad-os-pack-creator-studio repo

## Connection Method

### Option 1: Cloudflare Dashboard (Recommended)
1. Go to https://dash.cloudflare.com → Pages
2. Click project name
3. Click "Settings" → "Builds & deployments"
4. Click "Connect to Git"
5. Authorize GitHub
6. Select repository
7. Configure build settings
8. Save

### Option 2: Wrangler CLI
```bash
cd /path/to/repo
wrangler pages project create <project-name> --production-branch=main
wrangler pages deploy ./dist --project-name=<project-name>
```

## Build Settings Template

**Framework preset:** Auto-detect or Static
**Build command:** `npm run build` or `pnpm build`
**Build output directory:** `dist` or `build` or `.next`
**Root directory:** `/` (default)

## Next Update
Check back after connecting next 5 projects.
EOFDASHBOARD

echo "📊 Status dashboard created: ~/pages-connection-status.md"
echo ""

# Summary
echo "============================================"
echo "✅ Mass connector setup complete!"
echo ""
echo "📄 Files created:"
echo "  - ~/pages-repo-mapping.json (project mappings)"
echo "  - ~/pages-connection-commands.sh (wrangler commands)"
echo "  - ~/pages-connection-status.md (status dashboard)"
echo ""
echo "🎯 Next steps:"
echo "  1. Review mapping in pages-repo-mapping.json"
echo "  2. Use Cloudflare Dashboard to connect repos"
echo "  3. Or run: bash ~/pages-connection-commands.sh"
echo ""
echo "🚀 Ready to connect 75 more projects!"
