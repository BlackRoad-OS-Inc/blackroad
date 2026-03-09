#!/bin/bash
# 🎨 Deploy BlackRoad Brand Design System to ALL Cloudflare Projects

set -e

echo "🎨 BLACKROAD BRAND DESIGN SYSTEM DEPLOYMENT"
echo "==========================================="
echo ""

# List all Cloudflare Pages projects
echo "📦 Fetching all Cloudflare Pages projects..."
PROJECTS=$(wrangler pages project list 2>/dev/null | grep -v "^$" | grep -v "Listing" | awk '{print $2}' || echo "")

if [ -z "$PROJECTS" ]; then
  echo "❌ No Cloudflare projects found or wrangler not authenticated"
  echo "Run: wrangler login"
  exit 1
fi

PROJECT_COUNT=$(echo "$PROJECTS" | wc -l | tr -d ' ')
echo "✅ Found $PROJECT_COUNT Cloudflare Pages projects"
echo ""

# Create deployment directory
DEPLOY_DIR="/tmp/brand-design-deploy"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

# Copy brand design system
cp ~/BLACKROAD_DESIGN_SYSTEM.css "$DEPLOY_DIR/blackroad-design.css"

# Copy all template files
cp "/Users/alexa/Downloads/files(4)/blackroad-template-01-homepage.html" "$DEPLOY_DIR/" 2>/dev/null || true
cp "/Users/alexa/Downloads/files(4)/blackroad-template-03-pricing.html" "$DEPLOY_DIR/" 2>/dev/null || true
cp "/Users/alexa/Downloads/files(4)/blackroad-template-05-docs.html" "$DEPLOY_DIR/" 2>/dev/null || true
cp "/Users/alexa/Downloads/files(4)/blackroad-template-07-contact.html" "$DEPLOY_DIR/" 2>/dev/null || true
cp "/Users/alexa/Downloads/files(4)/blackroad-template-09-auth.html" "$DEPLOY_DIR/" 2>/dev/null || true
cp "/Users/alexa/Desktop/blackroad-mega-motion-gallery.html" "$DEPLOY_DIR/" 2>/dev/null || true

# Create index.html with design system reference
cat > "$DEPLOY_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad OS — Design System</title>
    <link rel="stylesheet" href="/blackroad-design.css">
    <style>
        .hero {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            padding: var(--space-3xl) var(--space-xl);
        }

        .templates-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: var(--space-lg);
            padding: var(--space-3xl) var(--space-xl);
        }

        .template-card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            border-radius: var(--space-md);
            padding: var(--space-xl);
            border: 1px solid rgba(255, 255, 255, 0.1);
            transition: all 0.3s var(--ease);
        }

        .template-card:hover {
            transform: translateY(-5px);
            border-color: var(--amber);
        }

        .template-link {
            color: var(--electric-blue);
            text-decoration: none;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="scroll-progress"></div>

    <div class="hero">
        <h1 class="gradient-text">BlackRoad OS Design System</h1>
        <p style="margin-top: var(--space-md); font-size: 1.25rem; opacity: 0.8;">
            Official brand colors, spacing, and templates
        </p>
    </div>

    <div class="container">
        <div class="templates-grid">
            <div class="template-card">
                <h3>🏠 Homepage</h3>
                <p style="margin-top: var(--space-sm); opacity: 0.7;">Landing page template</p>
                <a href="/blackroad-template-01-homepage.html" class="template-link" style="margin-top: var(--space-md); display: block;">View Template →</a>
            </div>

            <div class="template-card">
                <h3>💰 Pricing</h3>
                <p style="margin-top: var(--space-sm); opacity: 0.7;">Pricing page template</p>
                <a href="/blackroad-template-03-pricing.html" class="template-link" style="margin-top: var(--space-md); display: block;">View Template →</a>
            </div>

            <div class="template-card">
                <h3>📚 Docs</h3>
                <p style="margin-top: var(--space-sm); opacity: 0.7;">Documentation template</p>
                <a href="/blackroad-template-05-docs.html" class="template-link" style="margin-top: var(--space-md); display: block;">View Template →</a>
            </div>

            <div class="template-card">
                <h3>📧 Contact</h3>
                <p style="margin-top: var(--space-sm); opacity: 0.7;">Contact page template</p>
                <a href="/blackroad-template-07-contact.html" class="template-link" style="margin-top: var(--space-md); display: block;">View Template →</a>
            </div>

            <div class="template-card">
                <h3>🔐 Auth</h3>
                <p style="margin-top: var(--space-sm); opacity: 0.7;">Authentication template</p>
                <a href="/blackroad-template-09-auth.html" class="template-link" style="margin-top: var(--space-md); display: block;">View Template →</a>
            </div>

            <div class="template-card">
                <h3>🎨 Gallery</h3>
                <p style="margin-top: var(--space-sm); opacity: 0.7;">Mega motion gallery</p>
                <a href="/blackroad-mega-motion-gallery.html" class="template-link" style="margin-top: var(--space-md); display: block;">View Template →</a>
            </div>
        </div>
    </div>

    <script>
        window.addEventListener('scroll', () => {
            const scrollProgress = document.querySelector('.scroll-progress');
            const scrollPercent = (window.scrollY / (document.documentElement.scrollHeight - window.innerHeight)) * 100;
            scrollProgress.style.width = scrollPercent + '%';
        });
    </script>
</body>
</html>
EOF

# Create README
cat > "$DEPLOY_DIR/README.md" << 'EOF'
# BlackRoad OS Design System

## ⚠️ IMPORTANT

**THIS IS THE ONLY APPROVED DESIGN SYSTEM FOR BLACKROAD OS**

DO NOT create designs outside of these specifications.
ALL Cloudflare projects MUST use these exact values.

## Files

- `blackroad-design.css` - Main design system CSS
- `blackroad-template-*.html` - Official page templates
- `index.html` - Design system reference

## Brand Colors

```css
--amber: #F5A623
--orange: #F26522
--hot-pink: #FF1D6C
--magenta: #E91E63
--electric-blue: #2979FF
--sky-blue: #448AFF
--violet: #9C27B0
--deep-purple: #5E35B1
```

## Usage

```html
<link rel="stylesheet" href="/blackroad-design.css">
```

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF

echo "📦 Deploying to all Cloudflare Pages projects..."
echo ""

SUCCESS=0
FAILED=0

while IFS= read -r project; do
  [ -z "$project" ] && continue

  echo "🚀 Deploying to: $project"

  # Deploy using wrangler
  wrangler pages deploy "$DEPLOY_DIR" --project-name="$project" --branch="main" 2>/dev/null && {
    echo "  ✅ Deployed to $project"
    ((SUCCESS++))
  } || {
    echo "  ⚠️  Failed to deploy to $project"
    ((FAILED++))
  }

  echo ""
done <<< "$PROJECTS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ BRAND DESIGN SYSTEM DEPLOYED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Results:"
echo "   ✅ Success: $SUCCESS projects"
echo "   ❌ Failed: $FAILED projects"
echo "   📦 Total: $PROJECT_COUNT projects"
echo ""
echo "🎨 Design System Includes:"
echo "   • Official brand colors"
echo "   • Golden ratio spacing"
echo "   • Typography system"
echo "   • Component styles"
echo "   • 6 page templates"
echo ""
