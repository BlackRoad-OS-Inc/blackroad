#!/bin/bash
# BlackRoad Cloudflare Project Perfection Script
# Applies official BlackRoad design system to any Cloudflare Pages project

PROJECT_NAME="$1"
PROJECT_TITLE="$2"
PROJECT_DESCRIPTION="$3"

if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_TITLE" ]; then
    echo "Usage: $0 <project-name> <project-title> <description>"
    exit 1
fi

WORK_DIR="/tmp/cloudflare-perfect-$PROJECT_NAME"

echo "🌌 PERFECTING CLOUDFLARE PROJECT: $PROJECT_NAME"
echo "=========================================="

# Create work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Create perfect BlackRoad landing page
cat > index.html << 'PERFECT'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PROJECT_TITLE_PLACEHOLDER — BlackRoad OS</title>
    <meta name="description" content="PROJECT_DESCRIPTION_PLACEHOLDER">
    <style>
        :root {
            --black: #000000;
            --white: #FFFFFF;
            --amber: #F5A623;
            --hot-pink: #FF1D6C;
            --electric-blue: #2979FF;
            --violet: #9C27B0;

            --gradient-brand: linear-gradient(135deg, var(--amber) 0%, var(--hot-pink) 38.2%, var(--violet) 61.8%, var(--electric-blue) 100%);

            --space-xs: 8px;
            --space-sm: 13px;
            --space-md: 21px;
            --space-lg: 34px;
            --space-xl: 55px;
            --space-2xl: 89px;
            --space-3xl: 144px;

            --ease: cubic-bezier(0.25, 0.1, 0.25, 1);
            --ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        html { scroll-behavior: smooth; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif;
            background: var(--black);
            color: var(--white);
            overflow-x: hidden;
            line-height: 1.618;
            -webkit-font-smoothing: antialiased;
        }

        /* ========== BACKGROUND GRID ========== */
        .grid-bg {
            position: fixed;
            inset: 0;
            background-image:
                linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
            background-size: 55px 55px;
            animation: grid-move 20s linear infinite;
            z-index: -1;
        }

        @keyframes grid-move {
            0% { transform: translate(0, 0); }
            100% { transform: translate(55px, 55px); }
        }

        /* ========== GLOWING ORBS ========== */
        .orb {
            position: fixed;
            border-radius: 50%;
            filter: blur(100px);
            background: var(--gradient-brand);
            opacity: 0.12;
            z-index: -1;
        }

        .orb-1 {
            width: 500px;
            height: 500px;
            top: -250px;
            right: -250px;
        }

        .orb-2 {
            width: 400px;
            height: 400px;
            bottom: -200px;
            left: -200px;
        }

        /* ========== NAVIGATION ========== */
        nav {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 1000;
            padding: var(--space-md) var(--space-xl);
            display: flex;
            justify-content: space-between;
            align-items: center;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: saturate(180%) blur(20px);
        }

        .nav-logo {
            display: flex;
            align-items: center;
            gap: var(--space-sm);
            text-decoration: none;
            color: var(--white);
            font-size: 20px;
            font-weight: 600;
        }

        .nav-logo-mark {
            width: 36px;
            height: 36px;
        }

        .road-dashes {
            animation: logo-spin 20s linear infinite;
            transform-origin: 18px 18px;
        }

        @keyframes logo-spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }

        .nav-links {
            display: flex;
            gap: var(--space-lg);
        }

        .nav-links a {
            color: rgba(255, 255, 255, 0.7);
            text-decoration: none;
            transition: color 0.3s var(--ease);
        }

        .nav-links a:hover {
            color: var(--white);
        }

        /* ========== HERO SECTION ========== */
        .hero {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            text-align: center;
            padding: var(--space-3xl) var(--space-xl);
        }

        h1 {
            font-size: clamp(40px, 8vw, 89px);
            font-weight: 700;
            margin-bottom: var(--space-lg);
            background: var(--gradient-brand);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .hero p {
            font-size: clamp(18px, 3vw, 24px);
            color: rgba(255, 255, 255, 0.7);
            max-width: 600px;
            margin-bottom: var(--space-2xl);
        }

        /* ========== BUTTONS ========== */
        .btn-primary {
            position: relative;
            display: inline-block;
            padding: var(--space-sm) var(--space-lg);
            background: var(--white);
            color: var(--black);
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            overflow: hidden;
            transition: all 0.4s var(--ease-spring);
        }

        .btn-primary::before {
            content: '';
            position: absolute;
            inset: 0;
            background: var(--gradient-brand);
            opacity: 0;
            transition: opacity 0.4s var(--ease);
        }

        .btn-primary:hover::before {
            opacity: 1;
        }

        .btn-primary:hover {
            color: var(--white);
            transform: translateY(-3px);
            box-shadow: 0 12px 40px rgba(255, 29, 108, 0.4);
        }

        .btn-primary span {
            position: relative;
            z-index: 1;
        }

        /* ========== CARDS ========== */
        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: var(--space-lg);
            padding: var(--space-3xl) var(--space-xl);
            max-width: 1200px;
            margin: 0 auto;
        }

        .card {
            position: relative;
            background: rgba(255, 255, 255, 0.03);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 16px;
            padding: var(--space-lg);
            transition: all 0.4s var(--ease);
        }

        .card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: var(--gradient-brand);
            transform: scaleX(0);
            transition: transform 0.4s var(--ease);
        }

        .card:hover::before {
            transform: scaleX(1);
        }

        .card:hover {
            background: rgba(255, 255, 255, 0.06);
            border-color: rgba(255, 255, 255, 0.15);
            transform: translateY(-4px);
        }

        .card h3 {
            font-size: 24px;
            margin-bottom: var(--space-sm);
            background: var(--gradient-brand);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .card p {
            color: rgba(255, 255, 255, 0.7);
            line-height: 1.618;
        }

        /* ========== FOOTER ========== */
        footer {
            text-align: center;
            padding: var(--space-2xl) var(--space-xl);
            border-top: 1px solid rgba(255, 255, 255, 0.08);
        }

        footer p {
            color: rgba(255, 255, 255, 0.5);
        }

        footer a {
            color: var(--hot-pink);
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="grid-bg"></div>
    <div class="orb orb-1"></div>
    <div class="orb orb-2"></div>

    <nav>
        <a href="https://blackroad.io" class="nav-logo">
            <svg class="nav-logo-mark" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                <g class="road-dashes">
                    <rect x="46" y="5" width="8" height="15" fill="#FF1D6C"/>
                    <rect x="46" y="30" width="8" height="15" fill="#F5A623"/>
                    <rect x="46" y="55" width="8" height="15" fill="#2979FF"/>
                    <rect x="46" y="80" width="8" height="15" fill="#9C27B0"/>
                </g>
            </svg>
            <span>PROJECT_NAME_PLACEHOLDER</span>
        </a>
        <div class="nav-links">
            <a href="https://blackroad.io">BlackRoad OS</a>
            <a href="https://github.com/BlackRoad-OS">GitHub</a>
        </div>
    </nav>

    <section class="hero">
        <h1>PROJECT_TITLE_PLACEHOLDER</h1>
        <p>PROJECT_DESCRIPTION_PLACEHOLDER</p>
        <a href="#features" class="btn-primary"><span>Explore Features</span></a>
    </section>

    <section id="features" class="cards">
        <div class="card">
            <h3>Digital Sovereignty</h3>
            <p>Built for true digital independence with zero vendor lock-in architecture.</p>
        </div>
        <div class="card">
            <h3>Golden Ratio Design</h3>
            <p>Every element follows φ = 1.618 for natural, harmonious proportions.</p>
        </div>
        <div class="card">
            <h3>BlackRoad Infrastructure</h3>
            <p>Seamlessly integrated with the complete BlackRoad OS ecosystem.</p>
        </div>
    </section>

    <footer>
        <p>
            Built with ❤️ for digital sovereignty by <a href="https://blackroad.io">BlackRoad OS, Inc.</a><br>
            Managed by 1 human + AI agent army • Serving 30,000 AI agents + 30,000 humans
        </p>
    </footer>
</body>
</html>
PERFECT

# Replace placeholders
sed -i '' "s/PROJECT_TITLE_PLACEHOLDER/$PROJECT_TITLE/g" index.html
sed -i '' "s/PROJECT_DESCRIPTION_PLACEHOLDER/$PROJECT_DESCRIPTION/g" index.html
sed -i '' "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" index.html

echo "✅ Created perfect BlackRoad landing page"

# Deploy to Cloudflare Pages
echo "🚀 Deploying to Cloudflare Pages..."
wrangler pages deploy . --project-name="$PROJECT_NAME" --branch=main

echo ""
echo "🌌 CLOUDFLARE PROJECT PERFECTED: $PROJECT_NAME"
echo "✨ BlackRoad design system applied"
echo "🔥 Golden Ratio φ = 1.618 spacing"
echo "🎨 Official brand gradient active"
echo "💫 Animated logo deployed"
echo ""
