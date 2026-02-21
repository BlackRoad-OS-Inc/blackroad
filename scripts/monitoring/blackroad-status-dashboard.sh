#!/bin/bash
# Live status dashboard for all BlackRoad infrastructure

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🖤 BLACKROAD INFRASTRUCTURE STATUS"
echo "  $(date)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Platform Authentication
echo "🔐 Platform Authentication:"
gh auth status 2>&1 | grep -q "Logged in" && echo "  ✅ GitHub" || echo "  ❌ GitHub"
wrangler whoami 2>&1 | grep -q "logged in" && echo "  ✅ Cloudflare" || echo "  ❌ Cloudflare"
vercel whoami 2>&1 | grep -q "blackboxprogramming" && echo "  ✅ Vercel" || echo "  ⚠️  Vercel"
railway whoami 2>&1 | grep -q "Unauthorized" && echo "  ❌ Railway (run: railway login)" || echo "  ✅ Railway"

echo ""
echo "🌐 Active Websites:"
echo "  • 19 domains on Cloudflare"
echo "  • 7 Pages projects deployed"
echo "  • 17 GitHub organizations"

echo ""
echo "🖥️  Infrastructure Nodes:"
ssh -o ConnectTimeout=2 alice "echo '  ✅ alice - '\$(uptime | cut -d',' -f1)" 2>/dev/null || echo "  ❌ alice"
ssh -o ConnectTimeout=2 lucidia "echo '  ✅ lucidia - '\$(uptime | cut -d',' -f1)" 2>/dev/null || echo "  ❌ lucidia"
ssh -o ConnectTimeout=2 codex-infinity "echo '  ✅ codex-infinity - '\$(uptime | cut -d',' -f1)" 2>/dev/null || echo "  ⚠️  codex-infinity"
ssh -o ConnectTimeout=2 shellfish "echo '  ✅ shellfish - '\$(uptime | cut -d',' -f1)" 2>/dev/null || echo "  ⚠️  shellfish"

echo ""
echo "�� Website Status:"
curl -s -m 2 http://192.168.4.49 > /dev/null 2>&1 && echo "  ✅ alice:49 responding" || echo "  ⚠️  alice:49 not responding"
curl -s -m 2 http://192.168.4.38 > /dev/null 2>&1 && echo "  ✅ lucidia:38 responding" || echo "  ⚠️  lucidia:38 not responding"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Quick Commands:"
echo "  Deploy:    ~/blackroad-pi-web-deploy.sh"
echo "  Automate:  ~/blackroad-automation-cron.sh"
echo "  Test Web:  curl http://192.168.4.49"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
