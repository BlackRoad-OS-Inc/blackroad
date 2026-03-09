#!/usr/bin/env bash
# Continuous testing and fixing

echo "🖤🛣️  BlackRoad Continuous Test & Build"
echo ""

# Test 1: Install socat on all Pis (needed for webhook receiver)
echo "━━━ Installing socat (HTTP server dependency) ━━━"
ssh pi@192.168.4.74 "sudo apt-get install -y socat 2>/dev/null" && echo "✅ octavia: socat installed" &
ssh pi@192.168.4.64 "sudo apt-get install -y socat 2>/dev/null" && echo "✅ aria: socat installed" &
ssh alice@alice "sudo apt-get install -y socat 2>/dev/null" && echo "✅ alice: socat installed" &
ssh lucidia-pi "sudo apt-get install -y socat 2>/dev/null" && echo "✅ lucidia: socat installed" &
wait
echo ""

# Test 2: Start webhook receivers manually (background)
echo "━━━ Starting webhook receivers ━━━"
ssh pi@192.168.4.74 "cd /opt/blackroad/agent && sudo bash webhook-receiver.sh start > /tmp/webhook.log 2>&1 &" && echo "✅ octavia: webhook starting" &
ssh pi@192.168.4.64 "cd /opt/blackroad/agent && sudo bash webhook-receiver.sh start > /tmp/webhook.log 2>&1 &" && echo "✅ aria: webhook starting" &
ssh alice@alice "cd /opt/blackroad/agent && sudo bash webhook-receiver.sh start > /tmp/webhook.log 2>&1 &" && echo "✅ alice: webhook starting" &
wait
sleep 3
echo ""

# Test 3: Check webhook health endpoints
echo "━━━ Testing webhook health endpoints ━━━"
echo -n "octavia (9004): "
ssh pi@192.168.4.74 "curl -s http://localhost:9004/health 2>/dev/null | jq -r '.status' || echo 'not responding'"

echo -n "aria (9003): "
ssh pi@192.168.4.64 "curl -s http://localhost:9003/health 2>/dev/null | jq -r '.status' || echo 'not responding'"

echo -n "alice (9002): "
ssh alice@alice "curl -s http://localhost:9002/health 2>/dev/null | jq -r '.status' || echo 'not responding'"
echo ""

# Test 4: Check if blackroad-os repo exists locally
echo "━━━ Checking local blackroad-os repo ━━━"
if [[ -d ~/blackroad-os ]]; then
    cd ~/blackroad-os
    echo "✅ Repo exists"
    echo -n "  Branch: "
    git branch --show-current
    echo -n "  Latest commit: "
    git log -1 --oneline
    echo -n "  Status: "
    git status --short | wc -l | xargs echo "files changed"
else
    echo "❌ No local blackroad-os repo"
    echo "   Creating from GitHub..."
    gh repo clone BlackRoad-OS/blackroad-os ~/blackroad-os-test
fi
echo ""

# Test 5: Check infrastructure files
echo "━━━ Infrastructure Files ━━━"
ls -lh ~/*.md 2>/dev/null | grep -i blackroad | awk '{print "  ✅", $9, "-", $5}' || echo "  No files found"
echo ""

# Test 6: Check script tools
echo "━━━ Script Tools ━━━"
for script in blackroad-cli.sh test-devices-simple.sh deploy-everything.sh; do
    if [[ -x ~/$script ]]; then
        echo "  ✅ ~/$script"
    else
        echo "  ❌ ~/$script missing or not executable"
    fi
done
echo ""

# Test 7: Memory system check
echo "━━━ Memory System ━━━"
if [[ -x ~/memory-system.sh ]]; then
    echo "  ✅ Memory system installed"
    ~/memory-system.sh summary | tail -5
else
    echo "  ❌ Memory system not found"
fi
echo ""

# Test 8: Create quick deployment test
echo "━━━ Creating test deployment payload ━━━"
cat > /tmp/test-deploy.json << EOF
{
  "repository": "BlackRoad-OS/test-repo",
  "branch": "main",
  "commit": "test-$(date +%s)",
  "task": "deploy",
  "files": ["frontend/App.jsx", "backend/api.js"]
}
EOF
echo "  ✅ Test payload created: /tmp/test-deploy.json"
cat /tmp/test-deploy.json | jq '.'
echo ""

# Test 9: Try manual webhook POST
echo "━━━ Testing manual webhook POST to octavia ━━━"
ssh pi@192.168.4.74 "curl -X POST http://localhost:9004/deploy \
  -H 'Content-Type: application/json' \
  -H 'X-Webhook-Secret: blackroad2025' \
  -d '{\"repository\":\"test\",\"branch\":\"main\",\"commit\":\"abc123\",\"task\":\"deploy\"}' \
  2>/dev/null" || echo "  Webhook not responding yet"
echo ""

echo "🎉 Test & Build cycle complete!"
echo ""
echo "Next steps:"
echo "  1. Wait 30s for webhook receivers to fully start"
echo "  2. Deploy Cloudflare Worker: wrangler login && wrangler deploy"
echo "  3. Test GitHub webhook integration"
