#!/usr/bin/env bash
# Simple device connectivity test

echo "🖤🛣️  Device Connectivity Test"
echo ""

# Test with actual working aliases
ssh pi@192.168.4.74 "echo '✅ octavia (192.168.4.74): ' && whoami && hostname" || echo "❌ octavia offline"
echo ""

ssh pi@192.168.4.64 "echo '✅ blackroad-pi (192.168.4.64): ' && whoami && hostname" || echo "❌ blackroad-pi offline"
echo ""

ssh alice@alice "echo '✅ alice: ' && whoami && hostname" || echo "❌ alice offline"
echo ""

ssh lucidia-pi "echo '✅ lucidia-pi: ' && whoami && hostname" || echo "❌ lucidia-pi offline"
echo ""

ssh shellfish "echo '✅ shellfish: ' && whoami && hostname" || echo "❌ shellfish offline"
echo ""

echo "✅ Test complete!"
