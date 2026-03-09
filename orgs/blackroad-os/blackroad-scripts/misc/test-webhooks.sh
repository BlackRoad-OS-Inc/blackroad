#!/usr/bin/env bash
# Test webhook endpoints

echo "🧪 Testing webhook health endpoints..."
echo ""

echo -n "octavia (9004): "
ssh pi@192.168.4.74 "curl -s http://localhost:9004/health 2>/dev/null | jq -r '.status' || echo 'not running'"

echo -n "aria (9003): "
ssh pi@192.168.4.64 "curl -s http://localhost:9003/health 2>/dev/null | jq -r '.status' || echo 'not running'"

echo -n "alice (9002): "
ssh alice@alice "curl -s http://localhost:9002/health 2>/dev/null | jq -r '.status' || echo 'not running'"

echo ""
echo "Checking processes..."
ssh pi@192.168.4.74 "ps aux | grep -E '(socat|webhook)' | grep -v grep | wc -l | xargs echo 'octavia processes:'"
ssh pi@192.168.4.64 "ps aux | grep -E '(socat|webhook)' | grep -v grep | wc -l | xargs echo 'aria processes:'"
ssh alice@alice "ps aux | grep -E '(socat|webhook)' | grep -v grep | wc -l | xargs echo 'alice processes:'"

