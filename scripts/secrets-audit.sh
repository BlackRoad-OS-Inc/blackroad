#!/bin/bash
# BlackRoad Secrets Audit
# Shows which secrets are set at repo/org level

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔐 BlackRoad Secrets Audit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "📦 BlackRoad-OS-Inc/blackroad:"
gh secret list --repo BlackRoad-OS-Inc/blackroad 2>/dev/null | awk '{print "  "$1}' | head -20

echo ""
echo "📦 BlackRoad-OS-Inc (org secrets):"
gh secret list --org BlackRoad-OS-Inc 2>/dev/null | awk '{print "  "$1}' | head -20

echo ""
echo "🔑 Missing recommended secrets:"
SECRETS=(HUGGINGFACE_TOKEN CLOUDFLARE_API_TOKEN DIGITALOCEAN_ACCESS_TOKEN TAILSCALE_AUTH_KEY NGROK_AUTHTOKEN)
EXISTING=$(gh secret list --repo BlackRoad-OS-Inc/blackroad 2>/dev/null | awk '{print $1}')
for s in "${SECRETS[@]}"; do
  echo "$EXISTING" | grep -q "^$s$" && echo "  ✅ $s" || echo "  ❌ $s (missing)"
done
