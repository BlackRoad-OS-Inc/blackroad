#!/bin/bash
# Railway Integration — Pi agents as Railway webhook bridge

RAILWAY_TOKEN="${RAILWAY_TOKEN:-$(cat ~/.blackroad/secrets/railway_token 2>/dev/null)}"

echo "🚂 Setting up Railway integration..."

for NODE in cecilia octavia; do
  ssh -o ConnectTimeout=5 $NODE "
    mkdir -p ~/.blackroad/secrets
    echo '$RAILWAY_TOKEN' > ~/.blackroad/secrets/railway_token
    chmod 600 ~/.blackroad/secrets/railway_token
    
    # Install railway CLI if not present
    if ! command -v railway &>/dev/null; then
      npm install -g @railway/cli --quiet 2>/dev/null && echo '  ✅ Railway CLI installed'
    else
      echo '  ✅ Railway CLI: \$(railway --version 2>/dev/null || echo installed)'
    fi
    echo '  ✅ Railway configured on \$(hostname)'
  " 2>&1 || echo "  ❌ $NODE unreachable"
done

echo "✅ Railway integration complete"
