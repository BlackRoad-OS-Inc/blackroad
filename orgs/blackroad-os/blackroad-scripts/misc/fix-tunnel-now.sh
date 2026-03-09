#!/bin/bash
# Quick script to fix the Cloudflare tunnel on Lucidia
# Run with: ./fix-tunnel-now.sh

echo "🔧 Fixing Cloudflare Tunnel on Lucidia..."

# SSH to lucidia and run the commands
ssh lucidia@lucidia << 'EOF'
# Copy the new config to tmp
cat > /tmp/config-new.yml << 'EOCONFIG'
tunnel: 90ad32b8-d87b-42ac-9755-9adb952bb78a
credentials-file: /etc/cloudflared/90ad32b8-d87b-42ac-9755-9adb952bb78a.json

ingress:
  # All BlackRoad Console domains → local Python server
  - hostname: console.blackroad.io
    service: http://localhost:8888
  - hostname: app.blackroad.io
    service: http://localhost:8888
  - hostname: os.blackroad.io
    service: http://localhost:8888
  - hostname: desktop.blackroad.io
    service: http://localhost:8888
  - hostname: console.blackroad.systems
    service: http://localhost:8888
  - hostname: os.blackroad.systems
    service: http://localhost:8888
  - hostname: desktop.blackroad.systems
    service: http://localhost:8888
  - hostname: console.blackroad.me
    service: http://localhost:8888
  - hostname: os.blackroad.me
    service: http://localhost:8888
  - hostname: desktop.blackroad.me
    service: http://localhost:8888
  - hostname: console.blackroad.network
    service: http://localhost:8888
  - hostname: os.blackroad.network
    service: http://localhost:8888
  - hostname: desktop.blackroad.network
    service: http://localhost:8888
  - hostname: console.blackroadai.com
    service: http://localhost:8888
  - hostname: os.blackroadai.com
    service: http://localhost:8888
  - hostname: desktop.blackroadai.com
    service: http://localhost:8888
  - hostname: console.blackroadquantum.com
    service: http://localhost:8888
  - hostname: os.blackroadquantum.com
    service: http://localhost:8888
  - hostname: desktop.blackroadquantum.com
    service: http://localhost:8888
  - hostname: console.lucidia.studio
    service: http://localhost:8888
  - hostname: os.lucidia.studio
    service: http://localhost:8888
  - hostname: desktop.lucidia.studio
    service: http://localhost:8888
  - hostname: console.lucidia.earth
    service: http://localhost:8888
  - hostname: os.lucidia.earth
    service: http://localhost:8888
  - hostname: desktop.lucidia.earth
    service: http://localhost:8888
  - hostname: blackroadinc.us
    service: http://localhost:8888
  - service: http_status:404
EOCONFIG

echo "✅ Config file created at /tmp/config-new.yml"
echo ""
echo "Now run these sudo commands:"
echo "  sudo cp /tmp/config-new.yml /etc/cloudflared/config.yml"
echo "  sudo systemctl restart cloudflared"
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ ALMOST THERE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "SSH to Lucidia and run:"
echo ""
echo "  ssh lucidia@lucidia"
echo "  sudo cp /tmp/config-new.yml /etc/cloudflared/config.yml"
echo "  sudo systemctl restart cloudflared"
echo ""
echo "Then all 26 domains will be LIVE! 🚀"
echo ""
