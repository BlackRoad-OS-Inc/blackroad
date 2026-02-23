#!/bin/bash
# Deploy Cloudflare Workers from Pi fleet using wrangler
# Runs on cecilia (primary) with octavia as backup

NODE="${1:-cecilia}"
WORKER_DIR="${2:-}"

echo "☁️  Deploying Cloudflare Workers from $NODE..."

ssh -o ControlMaster=no $NODE "
  # Install wrangler if needed
  if ! command -v wrangler &>/dev/null; then
    npm install -g wrangler --quiet 2>/dev/null && echo '✅ wrangler installed'
  else
    echo '✅ wrangler: '\$(wrangler --version 2>/dev/null | head -1)
  fi
  
  # Load CF credentials from vault
  CF_TOKEN=\$(cat ~/.blackroad/secrets/cf_api_token 2>/dev/null || echo '')
  if [ -z \"\$CF_TOKEN\" ]; then
    echo '⚠️  Set CF token: echo YOUR_TOKEN > ~/.blackroad/secrets/cf_api_token'
  else
    export CLOUDFLARE_API_TOKEN=\"\$CF_TOKEN\"
    echo '✅ CF credentials loaded'
    ${WORKER_DIR:+cd $WORKER_DIR && wrangler deploy}
  fi
" 2>&1
