#!/bin/zsh
# generate-all-workers.sh — Generate all BlackRoad subdomain workers
# Run from: /Users/alexa/blackroad

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

BASE="/Users/alexa/blackroad/workers"
CF_ACCOUNT="848cf0b18d51e0170e0d1537aec3505a"

# Worker definitions: "worker-name|subdomain|zone|description|live-data-url|color"
declare -a WORKERS=(
  "api-blackroadio|api.blackroad.io|blackroad.io|API Explorer & Documentation|https://blackroad-os-api.amundsonalexa.workers.dev/health|#2979FF"
  "docs-blackroadio|docs.blackroad.io|blackroad.io|Documentation Hub|https://api.github.com/repos/BlackRoad-OS-Inc/blackroad-docs/readme|#F5A623"
  "console-blackroadio|console.blackroad.io|blackroad.io|Admin Console|https://blackroad-os-api.amundsonalexa.workers.dev/health|#9C27B0"
  "ai-blackroadio|ai.blackroad.io|blackroad.io|AI Platform|https://blackroad-os-api.amundsonalexa.workers.dev/agents|#FF1D6C"
  "analytics-blackroadio|analytics.blackroad.io|blackroad.io|Analytics Dashboard|https://api.github.com/orgs/BlackRoad-OS-Inc|#00BCD4"
  "status-blackroadio|status.blackroad.io|blackroad.io|System Status Page|https://blackroad-os-api.amundsonalexa.workers.dev/health|#4ade80"
  "admin-blackroadio|admin.blackroad.io|blackroad.io|Admin Portal|https://blackroad-os-api.amundsonalexa.workers.dev/health|#F5A623"
  "about-blackroadio|about.blackroad.io|blackroad.io|About BlackRoad OS|https://api.github.com/orgs/BlackRoad-OS-Inc|#FF1D6C"
  "algorithms-blackroadio|algorithms.blackroad.io|blackroad.io|AI Algorithms|https://blackroad-os-api.amundsonalexa.workers.dev/agents|#9C27B0"
  "alice-blackroadio|alice.blackroad.io|blackroad.io|Alice Agent Interface|https://blackroad-os-api.amundsonalexa.workers.dev/agents|#2979FF"
  "asia-blackroadio|asia.blackroad.io|blackroad.io|Asia Region|https://api.github.com/orgs/BlackRoad-OS-Inc|#F5A623"
  "blockchain-blackroadio|blockchain.blackroad.io|blackroad.io|Blockchain & Crypto|https://api.github.com/orgs/BlackRoad-OS-Inc|#FF1D6C"
  "blocks-blackroadio|blocks.blackroad.io|blackroad.io|Block Storage|https://blackroad-os-api.amundsonalexa.workers.dev/health|#2979FF"
  "blog-blackroadio|blog.blackroad.io|blackroad.io|BlackRoad Blog|https://api.github.com/orgs/BlackRoad-OS-Inc|#FF1D6C"
  "cdn-blackroadio|cdn.blackroad.io|blackroad.io|CDN & Edge Storage|https://blackroad-os-api.amundsonalexa.workers.dev/health|#00BCD4"
  "chain-blackroadio|chain.blackroad.io|blackroad.io|Chain Network|https://api.github.com/orgs/BlackRoad-OS-Inc|#9C27B0"
  "circuits-blackroadio|circuits.blackroad.io|blackroad.io|Hardware Circuits|https://api.github.com/orgs/BlackRoad-Hardware|#F5A623"
  "cli-blackroadio|cli.blackroad.io|blackroad.io|CLI Tools|https://api.github.com/repos/BlackRoad-OS-Inc/blackroad-cli|#2979FF"
  "compliance-blackroadio|compliance.blackroad.io|blackroad.io|Compliance Scanner|https://blackroad-os-api.amundsonalexa.workers.dev/health|#4ade80"
  "compute-blackroadio|compute.blackroad.io|blackroad.io|Compute Platform|https://blackroad-os-api.amundsonalexa.workers.dev/health|#FF1D6C"
  "control-blackroadio|control.blackroad.io|blackroad.io|Control Plane|https://blackroad-os-api.amundsonalexa.workers.dev/health|#9C27B0"
  "data-blackroadio|data.blackroad.io|blackroad.io|Data Platform|https://api.github.com/orgs/BlackRoad-Labs|#2979FF"
  "demo-blackroadio|demo.blackroad.io|blackroad.io|Live Demos|https://blackroad-os-api.amundsonalexa.workers.dev/health|#FF1D6C"
  "design-blackroadio|design.blackroad.io|blackroad.io|Design System|https://api.github.com/repos/BlackRoad-OS-Inc/blackroad-brand-kit|#9C27B0"
  "dev-blackroadio|dev.blackroad.io|blackroad.io|Developer Portal|https://api.github.com/orgs/BlackRoad-OS-Inc|#F5A623"
  "edge-blackroadio|edge.blackroad.io|blackroad.io|Edge Computing|https://blackroad-os-api.amundsonalexa.workers.dev/health|#2979FF"
  "editor-blackroadio|editor.blackroad.io|blackroad.io|Online Editor|https://blackroad-os-api.amundsonalexa.workers.dev/health|#FF1D6C"
  "engineering-blackroadio|engineering.blackroad.io|blackroad.io|Engineering|https://api.github.com/orgs/BlackRoad-OS-Inc|#00BCD4"
  "eu-blackroadio|eu.blackroad.io|blackroad.io|EU Region|https://api.github.com/orgs/BlackRoad-OS-Inc|#F5A623"
  "events-blackroadio|events.blackroad.io|blackroad.io|Events & Webhooks|https://blackroad-os-api.amundsonalexa.workers.dev/health|#9C27B0"
  "explorer-blackroadio|explorer.blackroad.io|blackroad.io|Repo Explorer|https://api.github.com/orgs/BlackRoad-OS-Inc/repos?per_page=10|#2979FF"
  "features-blackroadio|features.blackroad.io|blackroad.io|Feature Flags|https://blackroad-os-api.amundsonalexa.workers.dev/health|#FF1D6C"
  "finance-blackroadio|finance.blackroad.io|blackroad.io|Finance Dashboard|https://blackroad-os-api.amundsonalexa.workers.dev/health|#4ade80"
  "global-blackroadio|global.blackroad.io|blackroad.io|Global Operations|https://api.github.com/orgs/BlackRoad-OS-Inc|#FF1D6C"
  "guide-blackroadio|guide.blackroad.io|blackroad.io|Getting Started Guide|https://api.github.com/repos/BlackRoad-OS-Inc/blackroad-docs/readme|#F5A623"
  "hardware-blackroadio|hardware.blackroad.io|blackroad.io|Hardware & IoT|https://api.github.com/repos/BlackRoad-OS-Inc/blackroad-hardware|#9C27B0"
  "help-blackroadio|help.blackroad.io|blackroad.io|Help & Support|https://api.github.com/orgs/BlackRoad-OS-Inc|#2979FF"
  "hr-blackroadio|hr.blackroad.io|blackroad.io|HR Portal|https://blackroad-os-api.amundsonalexa.workers.dev/health|#FF1D6C"
  "ide-blackroadio|ide.blackroad.io|blackroad.io|Online IDE|https://blackroad-os-api.amundsonalexa.workers.dev/health|#F5A623"
  "network-blackroadio|network.blackroad.io|blackroad.io|Network Dashboard|https://blackroad-os-api.amundsonalexa.workers.dev/health|#00BCD4"
  "blackroad-ai|blackroad.ai|blackroad.ai|AI Platform Portal|https://blackroad-os-api.amundsonalexa.workers.dev/agents|#FF1D6C"
  "blackroad-network|blackroad.network|blackroad.network|Network Platform|https://blackroad-os-api.amundsonalexa.workers.dev/health|#2979FF"
  "blackroad-systems|blackroad.systems|blackroad.systems|Systems Dashboard|https://blackroad-os-api.amundsonalexa.workers.dev/health|#9C27B0"
)

CI_YML='name: Deploy Worker
on:
  push:
    branches: [main]
  workflow_dispatch:
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '"'"'20'"'"' }
      - run: npm install
      - name: Deploy to Cloudflare Workers
        run: npx wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          CLOUDFLARE_ACCOUNT_ID: 848cf0b18d51e0170e0d1537aec3505a'

for entry in "${WORKERS[@]}"; do
  IFS='|' read -r NAME SUBDOMAIN ZONE DESCRIPTION DATA_URL COLOR <<< "$entry"
  
  # Skip if already fully built (has src/index.js already)
  if [[ -f "$BASE/$NAME/src/index.js" ]]; then
    echo -e "${YELLOW}⏭ Skip (exists): $NAME${NC}"
    continue
  fi
  
  mkdir -p "$BASE/$NAME/src" "$BASE/$NAME/.github/workflows"
  
  # Create worker JS
  cat > "$BASE/$NAME/src/index.js" << JSEOF
// ${SUBDOMAIN} — ${DESCRIPTION}
// BlackRoad OS, Inc. — All Rights Reserved

const DATA_URL = '${DATA_URL}';
const AGENTS_API = 'https://blackroad-os-api.amundsonalexa.workers.dev';

async function fetchLiveData() {
  try {
    const r = await fetch(DATA_URL, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0', 'Accept': 'application/json' },
      cf: { cacheTtl: 60 },
    });
    if (r.ok) return await r.json();
  } catch (_) {}
  return {};
}

async function getHealth() {
  try {
    const r = await fetch(\`\${AGENTS_API}/health\`, {
      headers: { 'User-Agent': 'BlackRoad-OS/2.0' },
      cf: { cacheTtl: 30 },
    });
    if (r.ok) return await r.json();
  } catch (_) {}
  return { status: 'ok', agents: 6 };
}

function renderHTML(data, health, now) {
  const repoCount = data.public_repos || data.total_count || '—';
  const agentCount = health.agents || 6;

  return \`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="refresh" content="30">
  <title>${DESCRIPTION} — BlackRoad OS</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif; background: #000; color: #fff; min-height: 100vh; }
    nav { display: flex; align-items: center; gap: 2rem; padding: 1rem 2rem; border-bottom: 1px solid #111; position: sticky; top: 0; background: #000; z-index: 100; }
    .logo { font-weight: 700; font-size: 1.1rem; background: linear-gradient(135deg, #F5A623, #FF1D6C, #9C27B0, #2979FF); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    nav a { color: #888; text-decoration: none; font-size: 0.85rem; }
    nav a:hover { color: #fff; }
    .hero { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; text-align: center; padding: 4rem 2rem; }
    .live-badge { display: inline-flex; align-items: center; gap: 0.4rem; background: #0f2010; color: #4ade80; font-size: 0.75rem; padding: 0.25rem 0.75rem; border-radius: 20px; margin-bottom: 1.5rem; }
    .live-badge::before { content: ''; width: 6px; height: 6px; background: #4ade80; border-radius: 50%; animation: pulse 2s infinite; }
    @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
    h1 { font-size: clamp(2.5rem, 6vw, 5rem); font-weight: 800; background: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 1rem; }
    .subtitle { color: #888; font-size: 1.2rem; margin-bottom: 3rem; max-width: 600px; line-height: 1.618; }
    .subdomain { font-family: 'Courier New', monospace; font-size: 1rem; color: ${COLOR}; margin-bottom: 2rem; }
    .stats { display: flex; gap: 3rem; justify-content: center; flex-wrap: wrap; }
    .stat { text-align: center; }
    .stat .val { font-size: 2.5rem; font-weight: 800; color: ${COLOR}; }
    .stat .lbl { font-size: 0.75rem; color: #666; text-transform: uppercase; letter-spacing: 0.1em; }
    .data-section { max-width: 800px; margin: 3rem auto; padding: 0 2rem; }
    .data-card { background: #0a0a0a; border: 1px solid #1a1a1a; border-radius: 12px; padding: 1.5rem; margin-bottom: 1rem; }
    .data-card h3 { color: ${COLOR}; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 0.75rem; }
    pre { color: #888; font-size: 0.85rem; overflow-x: auto; white-space: pre-wrap; word-break: break-all; }
    .footer { text-align: center; padding: 2rem; color: #333; font-size: 0.8rem; border-top: 1px solid #111; margin-top: 4rem; }
    .cta { display: inline-flex; gap: 1rem; margin-top: 2rem; flex-wrap: wrap; justify-content: center; }
    .btn { padding: 0.75rem 1.5rem; border-radius: 8px; font-size: 0.9rem; font-weight: 600; text-decoration: none; transition: opacity 0.2s; }
    .btn-primary { background: ${COLOR}; color: #000; }
    .btn-secondary { border: 1px solid #333; color: #fff; }
    .btn:hover { opacity: 0.8; }
  </style>
</head>
<body>
  <nav>
    <span class="logo">◆ BlackRoad OS</span>
    <a href="https://blackroad.io">Home</a>
    <a href="https://dashboard.blackroad.io">Dashboard</a>
    <a href="https://agents.blackroad.io">Agents</a>
    <a href="https://docs.blackroad.io">Docs</a>
    <a href="https://status.blackroad.io">Status</a>
  </nav>
  <div class="hero">
    <div class="live-badge">LIVE</div>
    <div class="subdomain">${SUBDOMAIN}</div>
    <h1>${DESCRIPTION}</h1>
    <p class="subtitle">Part of the BlackRoad OS platform — AI-native, edge-deployed, production-ready.</p>
    <div class="stats">
      <div class="stat"><div class="val">\${agentCount}</div><div class="lbl">Agents Online</div></div>
      <div class="stat"><div class="val">30K</div><div class="lbl">Agent Capacity</div></div>
      <div class="stat"><div class="val">1,825+</div><div class="lbl">Repositories</div></div>
      <div class="stat"><div class="val">17</div><div class="lbl">Orgs</div></div>
    </div>
    <div class="cta">
      <a href="https://github.com/BlackRoad-OS-Inc" class="btn btn-primary">GitHub</a>
      <a href="https://blackroad.io" class="btn btn-secondary">Platform</a>
    </div>
  </div>
  <div class="data-section">
    <div class="data-card">
      <h3>Live Data — \${new Date().toLocaleTimeString()}</h3>
      <pre>\${JSON.stringify({ subdomain: '${SUBDOMAIN}', description: '${DESCRIPTION}', health: health.status || 'ok', agents_online: agentCount, timestamp: now }, null, 2)}</pre>
    </div>
  </div>
  <div class="footer">BlackRoad OS, Inc. © \${new Date().getFullYear()} — \${now} — Auto-refreshes every 30s</div>
</body>
</html>\`;
}

export default {
  async fetch(request, env, ctx) {
    const now = new Date().toUTCString();
    const [data, health] = await Promise.all([fetchLiveData(), getHealth()]);
    const html = renderHTML(data, health, now);
    return new Response(html, {
      headers: {
        'Content-Type': 'text/html;charset=UTF-8',
        'Cache-Control': 'public, max-age=30',
        'X-BlackRoad-Worker': '${NAME}',
        'X-BlackRoad-Version': '2.0.0',
      },
    });
  },
};
JSEOF

  # Create wrangler.toml
  cat > "$BASE/$NAME/wrangler.toml" << TOMLEOF
name = "${NAME}"
main = "src/index.js"
compatibility_date = "2024-12-01"
account_id = "${CF_ACCOUNT}"

[vars]
ENVIRONMENT = "production"

[[routes]]
pattern = "${SUBDOMAIN}/*"
zone_name = "${ZONE}"
TOMLEOF

  # Create package.json
  cat > "$BASE/$NAME/package.json" << PKGEOF
{
  "name": "@blackroad/${NAME}",
  "version": "2.0.0",
  "private": true,
  "description": "${DESCRIPTION}",
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "tail": "wrangler tail"
  },
  "devDependencies": {
    "wrangler": "^3.0.0"
  }
}
PKGEOF

  # Create CI/CD
  mkdir -p "$BASE/$NAME/.github/workflows"
  echo "$CI_YML" > "$BASE/$NAME/.github/workflows/deploy.yml"

  echo -e "${GREEN}✓${NC} Created: ${CYAN}$NAME${NC} → $SUBDOMAIN"
done

echo ""
echo -e "${GREEN}✅ All workers generated!${NC}"
echo -e "${CYAN}Workers in: $BASE/${NC}"
ls "$BASE" | wc -l
echo "worker directories"
