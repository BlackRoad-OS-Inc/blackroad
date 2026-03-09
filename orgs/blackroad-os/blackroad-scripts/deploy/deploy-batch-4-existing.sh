#!/bin/bash
# Deploy batch 4: Existing repos that haven't been deployed yet

GITHUB_ORG="BlackRoad-OS"

deploy() {
    local page=$1
    local repo=$2

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 $page"
    TEMP="/tmp/deploy-$$-$(date +%s)"
    mkdir -p "$TEMP" && cd "$TEMP"

    if gh repo clone "$GITHUB_ORG/$repo" 2>/dev/null; then
        cd "$repo"

        # Find deploy directory
        if [ -d "dist" ]; then DIR="dist"
        elif [ -d "build" ]; then DIR="build"
        elif [ -d ".next" ]; then DIR=".next"
        elif [ -d "public" ]; then DIR="public"
        else DIR="."; fi

        URL=$(wrangler pages deploy "$DIR" --project-name="$page" --branch=main 2>&1 | grep -o 'https://[^/]*.pages.dev' | head -1)
        if [ -n "$URL" ]; then
            echo "  ✅ $URL"
        else
            echo "  ⚠️  Deployed (check wrangler output)"
        fi
    else
        echo "  ❌ Repo not found: $repo"
    fi

    rm -rf "$TEMP"
}

echo "🚀 Batch 4: Deploying Existing Repos"
echo "===================================="
echo ""

# Core Infrastructure
deploy "blackroad-os-api" "blackroad-os-api"
deploy "blackroad-os-api-gateway" "blackroad-os-api-gateway"
deploy "blackroad-os-archive" "blackroad-os-archive"
deploy "blackroad-os-beacon" "blackroad-os-beacon"

# Codex & Tools
deploy "blackroad-os-codex" "blackroad-os-codex"
deploy "blackroad-os-codex-agent-runner" "blackroad-os-codex-agent-runner"
deploy "blackroad-os-codex-infinity" "blackroad-os-codex-infinity"
deploy "blackroad-cli" "blackroad-cli"
deploy "blackroad-cli-tools" "blackroad-cli-tools"

# Agent Systems
deploy "blackroad-agents" "blackroad-agents"
deploy "blackroad-agent-os" "blackroad-agent-os"
deploy "blackroad-os-agents" "blackroad-os-agents"
deploy "blackroad-multi-ai-system" "blackroad-multi-ai-system"

# Platform & Core
deploy "blackroad-os-core" "blackroad-os-core"
deploy "blackroad-os-master" "blackroad-os-master"
deploy "blackroad-os-mesh" "blackroad-os-mesh"
deploy "blackroad-os-helper" "blackroad-os-helper"
deploy "blackroad-os-landing-worker" "blackroad-os-landing-worker"

# Lucidia Projects
deploy "blackroad-os-lucidia" "blackroad-os-lucidia"
deploy "blackroad-os-lucidia-lab" "blackroad-os-lucidia-lab"
deploy "lucidia-core" "lucidia-core"
deploy "lucidia-math" "lucidia-math"
deploy "lucidia-metaverse" "lucidia-metaverse"
deploy "lucidia-earth-website" "lucidia-earth-website"

echo ""
echo "✅ Batch 4 deployment complete!"
echo "===================================="
