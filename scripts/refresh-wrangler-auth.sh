#!/bin/bash
# Run this once to refresh Cloudflare wrangler authentication
# Then re-copy tokens to Pi runners

echo "🔑 Refreshing Cloudflare wrangler auth..."
wrangler login

echo ""
echo "📦 Copying new auth to Pi runners..."
for PI in 192.168.4.38 192.168.4.82 192.168.4.89 192.168.4.81 192.168.4.49; do
  mkdir -p /tmp/wrangler-backup
  scp -o StrictHostKeyChecking=no \
    ~/.wrangler/config/default.toml \
    blackroad@$PI:~/.wrangler/config/default.toml 2>/dev/null && \
    echo "  ✅ $PI" || echo "  ❌ $PI"
done
echo "Done! CF workers can now deploy from Pi runners."
