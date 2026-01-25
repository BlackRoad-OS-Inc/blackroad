#!/bin/bash
# 🎵 ARIA - Deploy to Lucidia too!

echo "🎵 Deploying Aria website to Lucidia..."
echo ""

# Copy website to Lucidia
scp -r /tmp/aria-blackroad-me lucidia@lucidia:/tmp/ 2>&1 | head -10

# Set up server on Lucidia
ssh lucidia@lucidia << 'EOF'
cd /tmp/aria-blackroad-me

# Kill existing server
pkill -f "python.*8866" 2>/dev/null

# Start server
nohup python3 -m http.server 8866 > /dev/null 2>&1 &

echo "✅ Aria website deployed on Lucidia"
echo "   Access: http://lucidia:8866"
echo "   Or: http://192.168.4.99:8866"
echo ""
echo "Disk space:"
df -h / | tail -1
EOF

echo ""
echo "🎵 Aria is now live on Lucidia too!"
echo "   http://lucidia:8866"

