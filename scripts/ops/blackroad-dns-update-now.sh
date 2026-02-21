#!/bin/bash
# Quick DNS update for key BlackRoad domains

CODEX_IP="159.65.43.12"

echo "🚀 Updating DNS via Cloudflare API..."
echo ""

# Key domains to update
wrangler dns create blackroad.io A @ --content "$CODEX_IP" --ttl 1 2>&1 || echo "Record may exist"
wrangler dns create blackroadai.com A @ --content "$CODEX_IP" --ttl 1 2>&1 || echo "Record may exist"
wrangler dns create blackroad.company A @ --content "$CODEX_IP" --ttl 1 2>&1 || echo "Record may exist"
wrangler dns create blackroad.network A @ --content "$CODEX_IP" --ttl 1 2>&1 || echo "Record may exist"
wrangler dns create blackroad.systems A @ --content "$CODEX_IP" --ttl 1 2>&1 || echo "Record may exist"

echo ""
echo "✅ DNS updates submitted!"
