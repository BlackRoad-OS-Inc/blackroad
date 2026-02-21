#!/bin/bash
clear
cat <<'MENU'

  🚀🚀🚀 DEPLOY 🚀🚀🚀

  🌊 1  Vercel Status
  ☁️  2  Cloudflare Workers
  🚂 3  Railway Apps
  🐙 4  GitHub Actions
  📦 5  Build & Push Image
  🔄 6  Rolling Restart
  📋 7  Deploy Log
  🔙 0  ← Main Menu

MENU
read -p "  ⌨️  > " c
case $c in
  1) echo "  🌊 Checking Vercel..."; curl -s https://api.vercel.com/v2/now/deployments 2>/dev/null | head -5 || echo "  ⚠️  No token set"; read -p "  ↩ ";;
  2) echo "  ☁️  Workers:"; wrangler deployments list 2>/dev/null || echo "  ⚠️  wrangler not configured"; read -p "  ↩ ";;
  3) echo "  🚂 Railway:"; railway status 2>/dev/null || echo "  ⚠️  railway CLI not found"; read -p "  ↩ ";;
  4) echo "  🐙 Last 5 workflow runs:"; gh run list -L 5 2>/dev/null || echo "  ⚠️  gh not authed"; read -p "  ↩ ";;
  5) read -p "  📦 Image tag: " tag; docker build -t "blackroad/$tag" . && echo "  ✅ Built" || echo "  ❌ Failed"; read -p "  ↩ ";;
  6) read -p "  🔄 Service name: " svc; kubectl rollout restart deployment/"$svc" 2>/dev/null || echo "  ⚠️  kubectl not available"; read -p "  ↩ ";;
  7) echo "  📋 Last 20 deploys:"; cat ~/.blackroad/deploy.log 2>/dev/null | tail -20 || echo "  (empty)"; read -p "  ↩ ";;
  0) exec ./menu.sh;;
  *) echo "  ❌"; sleep 1;;
esac
exec ./deploy.sh
