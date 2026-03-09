#!/bin/bash
# Deploy proprietary enhanced products to Cloudflare Pages

set -e

ENHANCEMENTS_DIR="$HOME/blackroad-enhancements"
HOT_PINK='\033[38;2;255;29;108m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${HOT_PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${HOT_PINK}║                                                            ║${NC}"
    echo -e "${HOT_PINK}║     🖤 BlackRoad Product Deployment to Cloudflare 🖤      ║${NC}"
    echo -e "${HOT_PINK}║                                                            ║${NC}"
    echo -e "${HOT_PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

deploy_to_cloudflare() {
    local product_name="$1"
    local product_dir="$ENHANCEMENTS_DIR/$product_name/ui"

    if [ ! -d "$product_dir" ]; then
        echo -e "${RED}❌ Product directory not found: $product_dir${NC}"
        return 1
    fi

    echo -e "${CYAN}🚀 Deploying $product_name...${NC}"

    local project_name="blackroad-$(echo $product_name | tr '[:upper:]' '[:lower:]')"

    # Create a temporary build directory
    local build_dir=$(mktemp -d)
    cp -r "$product_dir"/* "$build_dir/"

    # Deploy to Cloudflare Pages
    cd "$build_dir"

    if wrangler pages project list | grep -q "$project_name"; then
        echo -e "${CYAN}📦 Project exists, deploying update...${NC}"
        wrangler pages deploy . --project-name="$project_name"
    else
        echo -e "${CYAN}📦 Creating new project...${NC}"
        wrangler pages project create "$project_name" --production-branch=main || true
        wrangler pages deploy . --project-name="$project_name"
    fi

    # Clean up
    rm -rf "$build_dir"

    echo -e "${GREEN}✅ Deployed: https://$project_name.pages.dev${NC}"
    echo ""
}

create_product_catalog() {
    local catalog_dir="$HOME/blackroad-product-catalog"
    mkdir -p "$catalog_dir"

    cat > "$catalog_dir/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad Enterprise Products</title>
    <style>
        :root {
            --hot-pink: #FF1D6C;
            --amber: #F5A623;
            --electric-blue: #2979FF;
            --violet: #9C27B0;
            --black: #000000;
            --white: #FFFFFF;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
            background: linear-gradient(135deg, var(--black) 0%, #1a1a1a 100%);
            color: var(--white);
            line-height: 1.618;
        }

        header {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(21px);
            border-bottom: 2px solid var(--hot-pink);
            padding: 34px;
            text-align: center;
        }

        h1 {
            font-size: 55px;
            background: linear-gradient(135deg, var(--hot-pink) 38.2%, var(--amber) 61.8%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 13px;
        }

        .tagline {
            font-size: 21px;
            color: rgba(255, 255, 255, 0.7);
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 55px 34px;
        }

        .category {
            margin-bottom: 89px;
        }

        .category-title {
            font-size: 34px;
            color: var(--hot-pink);
            margin-bottom: 34px;
            padding-bottom: 13px;
            border-bottom: 2px solid rgba(255, 29, 108, 0.3);
        }

        .products-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 34px;
        }

        .product-card {
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(13px);
            padding: 34px;
            border-radius: 21px;
            border: 2px solid transparent;
            transition: all 0.3s;
            cursor: pointer;
        }

        .product-card:hover {
            border-color: var(--hot-pink);
            transform: translateY(-8px);
        }

        .product-icon {
            font-size: 55px;
            margin-bottom: 21px;
        }

        .product-name {
            font-size: 21px;
            font-weight: 700;
            color: var(--hot-pink);
            margin-bottom: 13px;
        }

        .product-description {
            color: rgba(255, 255, 255, 0.7);
            font-size: 13px;
            margin-bottom: 21px;
        }

        .product-status {
            display: inline-block;
            padding: 8px 13px;
            border-radius: 8px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-live {
            background: linear-gradient(135deg, #00C853 0%, #64DD17 100%);
        }

        .status-beta {
            background: linear-gradient(135deg, var(--amber) 0%, #FFB74D 100%);
        }

        .status-coming {
            background: linear-gradient(135deg, var(--violet) 0%, var(--electric-blue) 100%);
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 21px;
            margin-bottom: 55px;
            padding: 34px;
            background: rgba(255, 29, 108, 0.1);
            border-radius: 21px;
            border: 2px solid var(--hot-pink);
        }

        .stat {
            text-align: center;
        }

        .stat-value {
            font-size: 34px;
            font-weight: 700;
            color: var(--hot-pink);
        }

        .stat-label {
            font-size: 13px;
            color: rgba(255, 255, 255, 0.7);
            margin-top: 8px;
        }
    </style>
</head>
<body>
    <header>
        <h1>🖤 BlackRoad Enterprise Products</h1>
        <p class="tagline">Open source cores, proprietary enhancements</p>
    </header>

    <div class="container">
        <div class="stats">
            <div class="stat">
                <div class="stat-value">20+</div>
                <div class="stat-label">Enterprise Products</div>
            </div>
            <div class="stat">
                <div class="stat-value">$1M+</div>
                <div class="stat-label">Annual Revenue Potential</div>
            </div>
            <div class="stat">
                <div class="stat-value">4</div>
                <div class="stat-label">Product Categories</div>
            </div>
            <div class="stat">
                <div class="stat-value">100%</div>
                <div class="stat-label">License Compliant</div>
            </div>
        </div>

        <!-- AI Platform -->
        <div class="category">
            <h2 class="category-title">🤖 BlackRoad AI Platform</h2>
            <div class="products-grid">
                <div class="product-card" onclick="window.open('https://blackroad-vllm.pages.dev', '_blank')">
                    <div class="product-icon">🚀</div>
                    <div class="product-name">BlackRoad vLLM</div>
                    <div class="product-description">
                        Enterprise LLM inference with beautiful UI, monitoring, and orchestration
                    </div>
                    <span class="product-status status-beta">Beta</span>
                </div>

                <div class="product-card">
                    <div class="product-icon">🧠</div>
                    <div class="product-name">BlackRoad LocalAI</div>
                    <div class="product-description">
                        Run AI models locally with enterprise management & security
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>

                <div class="product-card">
                    <div class="product-icon">🔗</div>
                    <div class="product-name">BlackRoad LangChain</div>
                    <div class="product-description">
                        Build LLM applications with visual workflow builder
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>

                <div class="product-card">
                    <div class="product-icon">🤝</div>
                    <div class="product-name">BlackRoad CrewAI</div>
                    <div class="product-description">
                        Orchestrate AI agent teams with enterprise controls
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>
            </div>
        </div>

        <!-- Identity & Access -->
        <div class="category">
            <h2 class="category-title">🔒 BlackRoad Identity & Access</h2>
            <div class="products-grid">
                <div class="product-card">
                    <div class="product-icon">🔑</div>
                    <div class="product-name">BlackRoad Keycloak</div>
                    <div class="product-description">
                        Enterprise identity management with modern UI & passwordless auth
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>

                <div class="product-card">
                    <div class="product-icon">🛡️</div>
                    <div class="product-name">BlackRoad Authelia</div>
                    <div class="product-description">
                        SSO and 2FA with beautiful interface & advanced security
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>

                <div class="product-card">
                    <div class="product-icon">🌐</div>
                    <div class="product-name">BlackRoad Headscale</div>
                    <div class="product-description">
                        Self-hosted VPN management with enterprise features
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>
            </div>
        </div>

        <!-- Cloud Storage -->
        <div class="category">
            <h2 class="category-title">☁️ BlackRoad Cloud Storage</h2>
            <div class="products-grid">
                <div class="product-card">
                    <div class="product-icon">📦</div>
                    <div class="product-name">BlackRoad MinIO</div>
                    <div class="product-description">
                        S3-compatible storage with beautiful file browser & analytics
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>

                <div class="product-card">
                    <div class="product-icon">🗄️</div>
                    <div class="product-name">BlackRoad Ceph</div>
                    <div class="product-description">
                        Distributed storage with unified management console
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>
            </div>
        </div>

        <!-- Collaboration -->
        <div class="category">
            <h2 class="category-title">💬 BlackRoad Collaboration</h2>
            <div class="products-grid">
                <div class="product-card">
                    <div class="product-icon">📹</div>
                    <div class="product-name">BlackRoad Meet</div>
                    <div class="product-description">
                        Video conferencing with AI transcription & meeting summaries
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>

                <div class="product-card">
                    <div class="product-icon">🎓</div>
                    <div class="product-name">BlackRoad BigBlueButton</div>
                    <div class="product-description">
                        Enterprise webinar platform with analytics & integrations
                    </div>
                    <span class="product-status status-coming">Coming Soon</span>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
EOF

    echo -e "${GREEN}✅ Product catalog created at: $catalog_dir/index.html${NC}"

    # Deploy catalog
    echo -e "${CYAN}🚀 Deploying product catalog to Cloudflare...${NC}"
    cd "$catalog_dir"

    if wrangler pages project list | grep -q "blackroad-products"; then
        wrangler pages deploy . --project-name="blackroad-products"
    else
        wrangler pages project create "blackroad-products" --production-branch=main || true
        wrangler pages deploy . --project-name="blackroad-products"
    fi

    echo -e "${GREEN}✅ Catalog deployed: https://blackroad-products.pages.dev${NC}"
}

# Main execution
main() {
    print_header

    # Check for enhancements directory
    if [ ! -d "$ENHANCEMENTS_DIR" ]; then
        echo -e "${RED}❌ No enhancements found at: $ENHANCEMENTS_DIR${NC}"
        echo -e "${CYAN}Run ~/blackroad-proprietary-enhancer.sh first${NC}"
        exit 1
    fi

    # Create and deploy product catalog first
    echo -e "${CYAN}📋 Creating product catalog...${NC}"
    create_product_catalog
    echo ""

    # Deploy each enhanced product
    echo -e "${CYAN}🚀 Deploying enhanced products...${NC}"
    echo ""

    deployed_count=0
    for product_dir in "$ENHANCEMENTS_DIR"/*; do
        if [ -d "$product_dir" ]; then
            product_name=$(basename "$product_dir")
            if deploy_to_cloudflare "$product_name"; then
                deployed_count=$((deployed_count + 1))
            fi
        fi
    done

    echo ""
    echo -e "${HOT_PINK}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${HOT_PINK}║                  DEPLOYMENT COMPLETE! 🚀                   ║${NC}"
    echo -e "${HOT_PINK}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Deployed $deployed_count products to Cloudflare Pages${NC}"
    echo ""
    echo -e "${CYAN}🌐 Product Catalog:${NC} https://blackroad-products.pages.dev"
    echo ""
    echo -e "${CYAN}Individual Products:${NC}"
    for product_dir in "$ENHANCEMENTS_DIR"/*; do
        if [ -d "$product_dir" ]; then
            product_name=$(basename "$product_dir")
            project_name="blackroad-$(echo $product_name | tr '[:upper:]' '[:lower:]')"
            echo "   • $product_name: https://$project_name.pages.dev"
        fi
    done
    echo ""
}

main "$@"
