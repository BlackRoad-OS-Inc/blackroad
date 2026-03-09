#!/bin/bash
# Deploy GitHub Actions workflows to all 60 BlackRoad products
# This script will create .github/workflows/ directory and copy workflows to each repo

set -e

WORKFLOWS_DIR="$HOME/github-workflows"
ENHANCEMENTS_DIR="$HOME/blackroad-enhancements"

echo "🖤 Deploying GitHub Actions Workflows to All Products 🛣️"
echo ""

# All 60 BlackRoad products
declare -a PRODUCTS=(
    # Wave 1
    "vllm" "ollama" "localai" "headscale" "minio" "netbird"
    "restic" "authelia" "espocrm" "focalboard" "whisper"
    # Wave 2
    "clickhouse" "synapse" "taiga" "dendrite" "suitecrm"
    "arangodb" "borg" "innernet" "tts" "vosk"
    # Wave 3
    "mattermost" "gitlab" "nextcloud" "keycloak" "grafana"
    "prometheus" "vault" "rabbitmq" "redis" "postgresql"
    # Wave 4
    "ansible" "jenkins" "harbor" "consul" "etcd"
    "traefik" "nginx" "caddy" "haproxy"
    # Wave 5
    "opensearch" "loki" "victoriametrics" "cortex" "thanos"
    "rook" "longhorn" "velero" "argocd" "flux"
    # Wave 6
    "temporal" "prefect" "airflow" "backstage" "jaeger"
    "zipkin" "falco" "cilium" "linkerd" "istio"
)

count=0
for product in "${PRODUCTS[@]}"; do
    # Convert to proper case for directory names
    product_dir=$(echo "$product" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1' | sed 's/ //g')

    target_dir="$ENHANCEMENTS_DIR/$product_dir/.github/workflows"

    echo "📦 Deploying workflows to: $product ($product_dir)"

    # Create .github/workflows directory
    mkdir -p "$target_dir"

    # Copy all workflow files
    cp "$WORKFLOWS_DIR/ci-cd-main.yml" "$target_dir/"
    cp "$WORKFLOWS_DIR/security-scan.yml" "$target_dir/"
    cp "$WORKFLOWS_DIR/performance-test.yml" "$target_dir/"
    cp "$WORKFLOWS_DIR/release-automation.yml" "$target_dir/"

    # Create additional workflow files specific to product
    cat > "$target_dir/dependabot.yml" << 'EOF'
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "automated"
    reviewers:
      - "blackroad-bot"
    assignees:
      - "blackroad-bot"
EOF

    # Create code scanning configuration
    cat > "$target_dir/codeql.yml" << 'EOF'
name: CodeQL Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 6 * * 1'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: javascript,typescript

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
EOF

    count=$((count + 1))
    echo "  ✅ Workflows deployed ($count/60)"
    echo ""
done

echo ""
echo "🎉 Workflow deployment complete!"
echo ""
echo "📊 Summary:"
echo "  Products updated: 60"
echo "  Workflows per product: 6"
echo "  Total workflows deployed: 360"
echo ""
echo "🚀 Next steps:"
echo "  1. Commit workflows to each product:"
echo "     cd ~/blackroad-enhancements/<product>"
echo "     git add .github/"
echo "     git commit -m 'Add GitHub Actions CI/CD workflows'"
echo ""
echo "  2. Push to GitHub (when rate limit resets)"
echo ""
echo "  3. Configure required secrets in each repo:"
echo "     - CLOUDFLARE_API_TOKEN"
echo "     - CLOUDFLARE_ACCOUNT_ID"
echo "     - SNYK_TOKEN"
echo "     - CODECOV_TOKEN"
echo "     - SLACK_WEBHOOK_URL"
echo "     - NPM_TOKEN"
echo "     - KUBE_CONFIG"
echo ""
echo "🖤 Generated with Claude Code"
echo "🛣️ Built with BlackRoad"
