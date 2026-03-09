#!/bin/bash
# BlackRoad Infrastructure - Cloudflare Tunnel Setup
# Sets up tunnels for: alice (Pi), shellfish (DigitalOcean), lucidia (Pi)

set -e

echo "🌐 BlackRoad Cloudflare Tunnel Setup"
echo "======================================"
echo ""

# Host configuration
declare -A HOSTS
HOSTS[alice]="192.168.4.49"
HOSTS[shellfish]="174.138.44.45"
HOSTS[lucidia]="192.168.4.38"

echo "📋 Configured Hosts:"
for host in "${!HOSTS[@]}"; do
    echo "  • $host: ${HOSTS[$host]}"
done
echo ""

# Check if wrangler is authenticated
echo "🔐 Checking Cloudflare authentication..."
if ! wrangler whoami &>/dev/null; then
    echo "❌ Not authenticated with Cloudflare. Run: wrangler login"
    exit 1
fi
echo "✅ Authenticated"
echo ""

# Create tunnel configuration
echo "📝 Creating tunnel configuration..."

cat > /tmp/blackroad-tunnel-config.yml <<'EOF'
# BlackRoad Infrastructure Tunnels
tunnel: blackroad-infrastructure
credentials-file: /Users/alexa/.cloudflared/blackroad-infrastructure.json

ingress:
  # Alice - Raspberry Pi (192.168.4.49)
  - hostname: alice.blackroad.io
    service: http://192.168.4.49:80
  - hostname: alice-api.blackroad.io
    service: http://192.168.4.49:3000

  # Shellfish - DigitalOcean (174.138.44.45)
  - hostname: shellfish.blackroad.io
    service: http://174.138.44.45:80
  - hostname: api.blackroad.io
    service: http://174.138.44.45:3000

  # Lucidia - Raspberry Pi (192.168.4.38)
  - hostname: lucidia.blackroad.io
    service: http://192.168.4.38:80
  - hostname: lucidia-api.blackroad.io
    service: http://192.168.4.38:3000

  # Catch-all
  - service: http_status:404
EOF

echo "✅ Tunnel configuration created"
echo ""

# Instructions for tunnel setup
cat <<'INSTRUCTIONS'
🚀 Next Steps:
==============

1. Install cloudflared on each host:

   Alice & Lucidia (Raspberry Pi):
   $ ssh alice
   $ wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
   $ sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared
   $ sudo chmod +x /usr/local/bin/cloudflared

   Shellfish (DigitalOcean):
   $ ssh shellfish
   $ wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
   $ sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
   $ sudo chmod +x /usr/local/bin/cloudflared

2. Create tunnel (run locally):
   $ cloudflared tunnel create blackroad-infrastructure

3. Copy credentials to each host:
   $ scp ~/.cloudflared/blackroad-infrastructure.json alice:/home/pi/.cloudflared/
   $ scp ~/.cloudflared/blackroad-infrastructure.json shellfish:/root/.cloudflared/
   $ scp ~/.cloudflared/blackroad-infrastructure.json lucidia:/home/pi/.cloudflared/

4. Copy config to each host:
   $ scp /tmp/blackroad-tunnel-config.yml alice:/home/pi/.cloudflared/config.yml
   $ scp /tmp/blackroad-tunnel-config.yml shellfish:/root/.cloudflared/config.yml
   $ scp /tmp/blackroad-tunnel-config.yml lucidia:/home/pi/.cloudflared/config.yml

5. Configure DNS (run locally):
   $ cloudflared tunnel route dns blackroad-infrastructure alice.blackroad.io
   $ cloudflared tunnel route dns blackroad-infrastructure shellfish.blackroad.io
   $ cloudflared tunnel route dns blackroad-infrastructure lucidia.blackroad.io
   $ cloudflared tunnel route dns blackroad-infrastructure api.blackroad.io

6. Start tunnel as service on each host:
   $ ssh alice "sudo cloudflared service install && sudo systemctl start cloudflared"
   $ ssh shellfish "sudo cloudflared service install && sudo systemctl start cloudflared"
   $ ssh lucidia "sudo cloudflared service install && sudo systemctl start cloudflared"

📊 Host Summary:
- Alice: 192.168.4.49 (Raspberry Pi) → alice.blackroad.io
- Shellfish: 174.138.44.45 (DigitalOcean) → shellfish.blackroad.io, api.blackroad.io
- Lucidia: 192.168.4.38 (Raspberry Pi) → lucidia.blackroad.io

INSTRUCTIONS

echo ""
echo "✅ Setup script complete!"
echo "   Config saved to: /tmp/blackroad-tunnel-config.yml"
