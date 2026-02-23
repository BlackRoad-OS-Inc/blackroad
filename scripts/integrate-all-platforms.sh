#!/bin/bash
# BlackRoad Master Platform Integration Script
# Integrates: Salesforce, Cloudflare, Railway, HuggingFace, Pi fleet
# Run from: /Users/alexa/blackroad

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()  { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${CYAN}ℹ️ ${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️ ${NC} $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  BlackRoad Master Integration — $(date -u)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Check Pi Fleet
info "Checking Pi fleet..."
for host in 192.168.4.38 192.168.4.64 192.168.4.49 159.65.43.12; do
  ping -c1 -W1 "$host" &>/dev/null && log "$host reachable" || warn "$host unreachable"
done

# 2. Publish SSH key to Pis (if reachable)
info "SSH key to distribute:"
echo "  $(cat ~/.ssh/blackroad_agents.pub)"
echo ""
echo "Run on each Pi:"
echo "  echo '$(cat ~/.ssh/blackroad_agents.pub)' >> ~/.ssh/authorized_keys"
echo ""

# 3. Salesforce Integration
info "Salesforce Integration:"
echo "  Org: https://login.salesforce.com"
echo "  Project: blackroad-sf/"
echo "  Pi Webhook URL: http://192.168.4.38:4010/webhooks/salesforce"
if [[ -d "blackroad-sf" ]]; then
  log "blackroad-sf project present"
  ls blackroad-sf/force-app/ 2>/dev/null | head -5
fi

# 4. Railway Integration  
info "Railway Integration (14 projects):"
echo "  Gateway: BLACKROAD_GATEWAY_URL=http://192.168.4.38:8787"
echo "  Set on all Railway projects via:"
echo "  railway variables set BLACKROAD_GATEWAY_URL=http://192.168.4.38:8787"
if command -v railway &>/dev/null; then
  railway status 2>/dev/null || warn "Railway CLI not authenticated"
else
  warn "Railway CLI not installed: npm i -g @railway/cli"
fi

# 5. Cloudflare Workers
info "Cloudflare Workers (75+):"
echo "  Account: 848cf0b18d51e0170e0d1537aec3505a"
echo "  Pi proxy: Set WORKER_BACKEND=http://192.168.4.38:4010 in wrangler vars"
if command -v wrangler &>/dev/null; then
  wrangler whoami 2>/dev/null | head -3 || warn "wrangler not authenticated"
else
  warn "wrangler not installed: npm i -g wrangler"
fi

# 6. HuggingFace Integration
info "HuggingFace Integration:"
echo "  Pi model server: http://192.168.4.38:11434 (Ollama API)"
echo "  HF Inference Endpoint: Configure at hf.co/settings/endpoints"
if [[ -n "$HUGGINGFACE_TOKEN" ]]; then
  curl -sf -H "Authorization: Bearer $HUGGINGFACE_TOKEN" \
    "https://huggingface.co/api/whoami" | python3 -c "import sys,json; d=json.load(sys.stdin); print('HF User:', d.get('name','unknown'))" 2>/dev/null || warn "HF check failed"
else
  warn "Set HUGGINGFACE_TOKEN for HF integration"
fi

# 7. Google Drive
info "Google Drive Sync:"
if command -v rclone &>/dev/null && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
  log "rclone + gdrive configured — run ./scripts/gdrive-sync.sh"
else
  warn "Run: ./scripts/setup-google-drive-sync.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SSH Key:     ~/.ssh/blackroad_agents (distribute pub key to Pis)"
echo "  Pi Runner:   Run scripts/setup-pi-runner.sh on each Pi"
echo "  Domains:     Run scripts/setup-pi-domains.sh"
echo "  GDrive:      Run scripts/setup-google-drive-sync.sh"
echo "  Continuous:  .github/workflows/continuous-24h-orchestrator.yml"
echo "  Agents:      $(ls /Users/alexa/blackroad/agents/registry/ | wc -l | tr -d ' ') identities in agents/registry/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
