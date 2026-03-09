#!/usr/bin/env bash
# Deploy everything to all devices automatically

set -e

echo "🖤🛣️  BlackRoad Full Deployment"
echo ""

# 1. Deploy webhook receiver to octavia
echo "━━━ Deploying to octavia (192.168.4.74) ━━━"
scp ~/blackroad-webhook-receiver.sh pi@192.168.4.74:~/
scp ~/blackroad-deployment-scripts/deploy-holo.sh pi@192.168.4.74:~/
ssh pi@192.168.4.74 "sudo bash ~/blackroad-webhook-receiver.sh install || true"
ssh pi@192.168.4.74 "sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME=\"octavia-pi\"
NODE_ROLE=\"holo\"
WEBHOOK_PORT=9004
WEBHOOK_SECRET=\"blackroad2025\"
EOF"
ssh pi@192.168.4.74 "sudo mkdir -p /opt/blackroad/scripts && sudo cp ~/deploy-holo.sh /opt/blackroad/scripts/"
ssh pi@192.168.4.74 "sudo apt-get install -y jq || true"
ssh pi@192.168.4.74 "sudo systemctl restart blackroad-webhook || sudo systemctl start blackroad-webhook || true"
echo "✅ octavia deployed"
echo ""

# 2. Deploy to blackroad-pi (aria)
echo "━━━ Deploying to blackroad-pi/aria (192.168.4.64) ━━━"
scp ~/blackroad-webhook-receiver.sh pi@192.168.4.64:~/
scp ~/blackroad-deployment-scripts/deploy-sim.sh pi@192.168.4.64:~/
ssh pi@192.168.4.64 "sudo bash ~/blackroad-webhook-receiver.sh install || true"
ssh pi@192.168.4.64 "sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME=\"aria-pi\"
NODE_ROLE=\"sim\"
WEBHOOK_PORT=9003
WEBHOOK_SECRET=\"blackroad2025\"
EOF"
ssh pi@192.168.4.64 "sudo mkdir -p /opt/blackroad/scripts && sudo cp ~/deploy-sim.sh /opt/blackroad/scripts/"
ssh pi@192.168.4.64 "sudo apt-get install -y jq || true"
ssh pi@192.168.4.64 "sudo systemctl restart blackroad-webhook || sudo systemctl start blackroad-webhook || true"
echo "✅ aria deployed"
echo ""

# 3. Deploy to alice
echo "━━━ Deploying to alice (192.168.4.49) ━━━"
scp ~/blackroad-webhook-receiver.sh alice@alice:~/
scp ~/blackroad-deployment-scripts/deploy-ops.sh alice@alice:~/
ssh alice@alice "sudo bash ~/blackroad-webhook-receiver.sh install || true"
ssh alice@alice "sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME=\"alice-pi\"
NODE_ROLE=\"ops\"
WEBHOOK_PORT=9002
WEBHOOK_SECRET=\"blackroad2025\"
EOF"
ssh alice@alice "sudo mkdir -p /opt/blackroad/scripts && sudo cp ~/deploy-ops.sh /opt/blackroad/scripts/"
ssh alice@alice "sudo apt-get install -y jq || true"
ssh alice@alice "sudo systemctl restart blackroad-webhook || sudo systemctl start blackroad-webhook || true"
echo "✅ alice deployed"
echo ""

# 4. Deploy to lucidia
echo "━━━ Deploying to lucidia-pi (192.168.4.38) ━━━"
scp ~/blackroad-webhook-receiver.sh lucidia-pi:~/
scp ~/blackroad-deployment-scripts/deploy-ops.sh lucidia-pi:~/
ssh lucidia-pi "sudo bash ~/blackroad-webhook-receiver.sh install || true"
ssh lucidia-pi "sudo tee /opt/blackroad/agent/config.env << EOF
NODE_NAME=\"lucidia-pi\"
NODE_ROLE=\"ops\"
WEBHOOK_PORT=9001
WEBHOOK_SECRET=\"blackroad2025\"
EOF"
ssh lucidia-pi "sudo mkdir -p /opt/blackroad/scripts && sudo cp ~/deploy-ops.sh /opt/blackroad/scripts/"
ssh lucidia-pi "sudo apt-get install -y jq || true"
ssh lucidia-pi "sudo systemctl restart blackroad-webhook || sudo systemctl start blackroad-webhook || true"
echo "✅ lucidia deployed"
echo ""

# 5. Test all webhooks
echo "━━━ Testing Webhooks ━━━"
ssh pi@192.168.4.74 "curl -s http://localhost:9004/health | jq -r '.status' | grep -q healthy && echo '✅ octavia webhook OK' || echo '❌ octavia webhook failed'"
ssh pi@192.168.4.64 "curl -s http://localhost:9003/health | jq -r '.status' | grep -q healthy && echo '✅ aria webhook OK' || echo '❌ aria webhook failed'"
ssh alice@alice "curl -s http://localhost:9002/health | jq -r '.status' | grep -q healthy && echo '✅ alice webhook OK' || echo '❌ alice webhook failed'"
ssh lucidia-pi "curl -s http://localhost:9001/health | jq -r '.status' | grep -q healthy && echo '✅ lucidia webhook OK' || echo '❌ lucidia webhook failed'"
echo ""

echo "🎉 Full deployment complete!"
