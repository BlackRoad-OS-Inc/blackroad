#!/bin/bash

# BlackRoad OS - Automated Domain Deployment Script
# Deploys all generated HTML pages to their respective Cloudflare Pages projects

echo "🚀 BlackRoad OS - Domain Deployment"
echo "===================================="
echo ""

PAGES_DIR="/Users/alexa/blackroad-domains/pages"
OAUTH_TOKEN="R2q-iVO-MihvU5kO-twZXOhy9j5i43CSbwCV6CRLtOk.5AaPL16tW7iy2nh2Q-cTYfF2TFbfcw7Y-Ka9J44Upls"
ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

# Domain to Project mapping
declare -A DEPLOYMENTS
DEPLOYMENTS=(
    ["blackroad-io.html"]="blackroad-io"
    ["earth-blackroad-io.html"]="earth-blackroad-io"
    ["home-blackroad-io.html"]="blackroad-os-home"
    ["demo-blackroad-io.html"]="blackroad-os-demo"
    # Note: universe and pitstop already have custom content, skip them
)

# Deploy a single domain
deploy_domain() {
    local HTML_FILE=$1
    local PROJECT_NAME=$2
    local TEMP_DIR="/tmp/blackroad-deploy-$PROJECT_NAME"

    echo "📦 Deploying $HTML_FILE to $PROJECT_NAME..."

    # Create temp directory
    mkdir -p "$TEMP_DIR"

    # Copy HTML file as index.html
    cp "$PAGES_DIR/$HTML_FILE" "$TEMP_DIR/index.html"

    # Deploy using wrangler
    cd "$TEMP_DIR"

    if wrangler pages deploy . --project-name="$PROJECT_NAME" --commit-dirty=true; then
        echo "   ✅ Successfully deployed $PROJECT_NAME"
    else
        echo "   ❌ Failed to deploy $PROJECT_NAME"
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$TEMP_DIR"

    echo ""
}

# Main deployment loop
echo "Starting deployments..."
echo ""

DEPLOYED=0
FAILED=0

for HTML_FILE in "${!DEPLOYMENTS[@]}"; do
    PROJECT_NAME="${DEPLOYMENTS[$HTML_FILE]}"

    if [ -f "$PAGES_DIR/$HTML_FILE" ]; then
        deploy_domain "$HTML_FILE" "$PROJECT_NAME"
        ((DEPLOYED++))
    else
        echo "⚠️  File not found: $HTML_FILE"
        ((FAILED++))
    fi

    # Rate limiting - wait 2 seconds between deployments
    sleep 2
done

echo "===================================="
echo "📊 Deployment Summary"
echo "===================================="
echo "✅ Deployed: $DEPLOYED"
echo "❌ Failed: $FAILED"
echo ""
echo "🌐 Live URLs:"
echo "   https://blackroad.io"
echo "   https://earth.blackroad.io"
echo "   https://home.blackroad.io"
echo "   https://demo.blackroad.io"
echo ""
echo "🎉 Deployment complete!"
