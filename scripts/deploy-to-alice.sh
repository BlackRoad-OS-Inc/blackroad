#!/bin/bash
# 🎵 ARIA - Deploy to Alice (she has space!)

echo "🎵 Deploying Aria website to Alice..."
echo ""

# Copy website to Alice
scp -r /tmp/aria-blackroad-me alice@alice:/tmp/ 2>&1 | head -10

# Set up server on Alice
ssh alice@alice << 'EOF'
cd /tmp/aria-blackroad-me

# Kill existing server
pkill -f "python.*8877" 2>/dev/null

# Start server
nohup python3 -m http.server 8877 > /dev/null 2>&1 &

echo "✅ Aria website deployed on Alice"
echo "   Access: http://alice:8877"
echo "   Or: http://192.168.4.38:8877" 
echo ""
echo "Disk space:"
df -h / | tail -1
EOF

echo ""
echo "🎵 Aria is now live on Alice!"
echo "   http://alice:8877"

