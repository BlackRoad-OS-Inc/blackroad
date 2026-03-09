#!/usr/bin/env bash
# Clean restart of all webhook receivers

echo "🔄 Restarting all webhook receivers..."
echo ""

# Kill all webhook processes on each Pi
echo "Stopping old processes..."
ssh pi@192.168.4.74 "sudo pkill -f webhook-receiver || true; sudo pkill socat || true" && echo "  ✅ octavia cleaned"
ssh pi@192.168.4.64 "sudo pkill -f webhook-receiver || true; sudo pkill socat || true" && echo "  ✅ aria cleaned"
ssh alice@alice "sudo pkill -f webhook-receiver || true; sudo pkill socat || true" && echo "  ✅ alice cleaned"

sleep 2
echo ""

# Start fresh on each Pi with nohup
echo "Starting fresh..."
ssh pi@192.168.4.74 "cd /opt/blackroad/agent && nohup sudo bash webhook-receiver.sh start > /tmp/webhook.log 2>&1 &" && echo "  ✅ octavia started"
ssh pi@192.168.4.64 "cd /opt/blackroad/agent && nohup sudo bash webhook-receiver.sh start > /tmp/webhook.log 2>&1 &" && echo "  ✅ aria started"
ssh alice@alice "cd /opt/blackroad/agent && nohup sudo bash webhook-receiver.sh start > /tmp/webhook.log 2>&1 &" && echo "  ✅ alice started"

sleep 3
echo ""

# Test health endpoints
echo "Testing health endpoints..."
ssh pi@192.168.4.74 "curl -s http://localhost:9004/health | jq -r '.status' | xargs echo '  octavia (9004):'"
ssh pi@192.168.4.64 "curl -s http://localhost:9003/health | jq -r '.status' | xargs echo '  aria (9003):'"
ssh alice@alice "curl -s http://localhost:9002/health | jq -r '.status' | xargs echo '  alice (9002):'"

echo ""
echo "✅ Restart complete!"
