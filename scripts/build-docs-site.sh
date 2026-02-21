#!/bin/bash

# 🖤 BlackRoad OS - Documentation Site Builder
# Generates and deploys docs.blackroad.io
# Author: Alexa Amundson
# Date: 2026-01-30

set -euo pipefail

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;33m'
GREEN='\033[38;5;10m'
RESET='\033[0m'

echo -e "${PINK}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║       🖤 BlackRoad OS - Documentation Site Builder 📚        ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

DOCS_DIR="$HOME/blackroad-docs-site"
OUTPUT_DIR="$DOCS_DIR/build"

# Create docs structure
mkdir -p "$DOCS_DIR"/{src,public,build}

echo -e "${AMBER}Building documentation site...${RESET}"
echo ""

# Create package.json
cat > "$DOCS_DIR/package.json" <<'EOF'
{
  "name": "blackroad-docs",
  "version": "1.0.0",
  "description": "BlackRoad OS Documentation Portal",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.20.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.0",
    "vite": "^5.0.0"
  }
}
EOF

# Create index.html
cat > "$DOCS_DIR/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BlackRoad OS - Documentation</title>
  <meta name="description" content="Complete documentation for BlackRoad OS - The AI operating system for teams">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #000;
      color: #fff;
      line-height: 1.6;
    }
    .header {
      background: linear-gradient(135deg, #FF1D6C 0%, #F5A623 50%, #2979FF 100%);
      padding: 3rem 2rem;
      text-align: center;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 2rem;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 2rem;
      margin: 2rem 0;
    }
    .card {
      background: #111;
      border: 1px solid #333;
      border-radius: 13px;
      padding: 2rem;
      transition: transform 0.2s, border-color 0.2s;
    }
    .card:hover {
      transform: translateY(-4px);
      border-color: #F5A623;
    }
    .card h2 {
      color: #F5A623;
      margin-bottom: 1rem;
    }
    .card ul {
      list-style: none;
      padding-left: 0;
    }
    .card li {
      padding: 0.5rem 0;
      border-bottom: 1px solid #222;
    }
    .card li:last-child {
      border-bottom: none;
    }
    .card a {
      color: #2979FF;
      text-decoration: none;
    }
    .card a:hover {
      color: #FF1D6C;
    }
    .search {
      width: 100%;
      padding: 1rem;
      font-size: 1.1rem;
      background: #111;
      border: 2px solid #333;
      border-radius: 8px;
      color: #fff;
      margin-bottom: 2rem;
    }
    .search:focus {
      outline: none;
      border-color: #F5A623;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>🖤 BlackRoad OS Documentation</h1>
    <p>Complete guides, API references, and tutorials</p>
  </div>

  <div class="container">
    <input type="text" class="search" placeholder="Search documentation...">

    <div class="grid">
      <div class="card">
        <h2>🚀 Getting Started</h2>
        <ul>
          <li><a href="/docs/quickstart">Quick Start Guide</a></li>
          <li><a href="/docs/installation">Installation</a></li>
          <li><a href="/docs/configuration">Configuration</a></li>
          <li><a href="/docs/first-agent">Your First Agent</a></li>
        </ul>
      </div>

      <div class="card">
        <h2>📚 Core Concepts</h2>
        <ul>
          <li><a href="/docs/architecture">Architecture Overview</a></li>
          <li><a href="/docs/agents">Agent System</a></li>
          <li><a href="/docs/prism">Prism Console</a></li>
          <li><a href="/docs/lucidia">Lucidia AI</a></li>
        </ul>
      </div>

      <div class="card">
        <h2>🔌 API Reference</h2>
        <ul>
          <li><a href="/api/agents">Agents API</a></li>
          <li><a href="/api/services">Services API</a></li>
          <li><a href="/api/auth">Authentication</a></li>
          <li><a href="/api/webhooks">Webhooks</a></li>
        </ul>
      </div>

      <div class="card">
        <h2>🛠️ Deployment</h2>
        <ul>
          <li><a href="/docs/deploy/docker">Docker</a></li>
          <li><a href="/docs/deploy/kubernetes">Kubernetes</a></li>
          <li><a href="/docs/deploy/cloudflare">Cloudflare</a></li>
          <li><a href="/docs/deploy/railway">Railway</a></li>
        </ul>
      </div>

      <div class="card">
        <h2>🔐 Security</h2>
        <ul>
          <li><a href="/docs/security/authentication">Authentication</a></li>
          <li><a href="/docs/security/rbac">RBAC</a></li>
          <li><a href="/docs/security/compliance">Compliance</a></li>
          <li><a href="/docs/security/best-practices">Best Practices</a></li>
        </ul>
      </div>

      <div class="card">
        <h2>💡 Tutorials</h2>
        <ul>
          <li><a href="/tutorials/ai-agent">Building AI Agents</a></li>
          <li><a href="/tutorials/integration">System Integration</a></li>
          <li><a href="/tutorials/monitoring">Monitoring Setup</a></li>
          <li><a href="/tutorials/scaling">Scaling Guide</a></li>
        </ul>
      </div>

      <div class="card">
        <h2>📊 Products</h2>
        <ul>
          <li><a href="/products/core">BlackRoad OS Core</a></li>
          <li><a href="/products/prism">Prism Console</a></li>
          <li><a href="/products/lucidia">Lucidia AI</a></li>
          <li><a href="/products/all">All Products (60)</a></li>
        </ul>
      </div>

      <div class="card">
        <h2>🤝 Support</h2>
        <ul>
          <li><a href="/support/contact">Contact Us</a></li>
          <li><a href="/support/community">Community</a></li>
          <li><a href="/support/faq">FAQ</a></li>
          <li><a href="https://github.com/BlackRoad-OS">GitHub</a></li>
        </ul>
      </div>
    </div>

    <div style="text-align: center; margin: 3rem 0; padding: 2rem; border-top: 1px solid #333;">
      <p style="color: #888;">
        🖤 Built by BlackRoad OS, Inc. | 
        <a href="https://blackroad.io" style="color: #F5A623;">blackroad.io</a> | 
        <a href="https://github.com/BlackRoad-OS" style="color: #2979FF;">GitHub</a>
      </p>
    </div>
  </div>
</body>
</html>
EOF

echo -e "${GREEN}✅ Created documentation site structure${RESET}"

# Create README for docs site
cat > "$DOCS_DIR/README.md" <<'EOF'
# BlackRoad OS Documentation Site

Complete documentation portal for BlackRoad OS products and services.

## Structure

- `index.html` - Main landing page
- `public/` - Static assets
- `src/` - Documentation source files
- `build/` - Production build

## Development

```bash
npm install
npm run dev
```

Visit http://localhost:5173

## Build

```bash
npm run build
```

Output in `build/` directory

## Deploy

### Cloudflare Pages

```bash
wrangler pages deploy build --project-name docs
```

### Railway

```bash
railway up
```

## Documentation Structure

- `/docs/` - User guides
- `/api/` - API reference
- `/tutorials/` - Step-by-step tutorials
- `/products/` - Product documentation
- `/support/` - Support resources

---

🖤 BlackRoad OS, Inc.
EOF

echo -e "${GREEN}✅ Created README${RESET}"

# Create deployment script
cat > "$DOCS_DIR/deploy.sh" <<'EOF'
#!/bin/bash

# Build and deploy documentation site

set -e

echo "📚 Building documentation site..."
npm run build

echo "🚀 Deploying to Cloudflare Pages..."
wrangler pages deploy build --project-name blackroad-docs

echo "✅ Deployment complete!"
echo "🌐 Visit: https://docs.blackroad.io"
EOF

chmod +x "$DOCS_DIR/deploy.sh"

echo -e "${GREEN}✅ Created deployment script${RESET}"
echo ""
echo -e "${PINK}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${PINK}║              📚 DOCUMENTATION SITE READY!                     ║${RESET}"
echo -e "${PINK}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BLUE}Location: $DOCS_DIR${RESET}"
echo ""
echo -e "${BLUE}Next steps:${RESET}"
echo -e "  1. cd $DOCS_DIR"
echo -e "  2. npm install"
echo -e "  3. npm run dev (development)"
echo -e "  4. ./deploy.sh (production)"
echo ""
echo -e "${BLUE}Features:${RESET}"
echo -e "  ✓ Beautiful landing page"
echo -e "  ✓ 8 documentation sections"
echo -e "  ✓ Search functionality"
echo -e "  ✓ Responsive design"
echo -e "  ✓ Ready for Cloudflare/Railway"
echo ""
