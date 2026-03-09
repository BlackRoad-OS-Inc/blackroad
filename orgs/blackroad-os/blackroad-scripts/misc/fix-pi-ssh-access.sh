#!/bin/bash
# 🔐 Fix Raspberry Pi SSH Access
# Manual steps to enable SSH access to all Pis

echo "🔐 BlackRoad Pi SSH Access Fix Guide"
echo "========================================="
echo ""

echo "📊 Current Status:"
echo "  ✅ Alice (192.168.4.49) - SSH Working"
echo "  ⚠️  Lucidia (192.168.4.38) - SSH Blocked (publickey only)"
echo "  ❌ Aria (192.168.4.64) - Offline"
echo "  ❌ Octavia (192.168.4.74) - Offline"
echo ""

echo "========================================="
echo "🔧 FIX 1: Lucidia SSH Access"
echo "========================================="
echo ""
echo "Lucidia only accepts public key authentication."
echo "You need to manually add your SSH key."
echo ""
echo "Option A: Physical Access (Keyboard/Monitor)"
echo "--------------------------------------------"
echo "1. Connect keyboard and monitor to lucidia Pi"
echo "2. Login as pi user (with password)"
echo "3. Run these commands:"
echo ""
cat << 'LUCIDIA_COMMANDS'
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   cat >> ~/.ssh/authorized_keys << 'EOF'
LUCIDIA_COMMANDS

# Output the public key
cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub

cat << 'LUCIDIA_COMMANDS2'
EOF
   chmod 600 ~/.ssh/authorized_keys
LUCIDIA_COMMANDS2

echo ""
echo "Option B: Via Alice Pi (Network Access)"
echo "----------------------------------------"
echo "If alice can reach lucidia on the local network:"
echo ""
echo "1. SSH into alice:"
echo "   ssh pi@192.168.4.49"
echo ""
echo "2. From alice, try to SSH into lucidia:"
echo "   ssh pi@192.168.4.38"
echo ""
echo "3. If that works, add your key from alice to lucidia"
echo ""

echo "========================================="
echo "🔧 FIX 2: Aria & Octavia (Currently Offline)"
echo "========================================="
echo ""
echo "These Pis are not responding to network pings."
echo ""
echo "Troubleshooting steps:"
echo ""
echo "1. Check Physical Power"
echo "   - Are the Pis plugged in?"
echo "   - Do they have power LEDs on?"
echo "   - Are they booting (activity LED blinking)?"
echo ""
echo "2. Check Network Connection"
echo "   - Are ethernet cables connected?"
echo "   - Is your router/switch showing them connected?"
echo "   - Try: ping 192.168.4.64 (aria)"
echo "   - Try: ping 192.168.4.74 (octavia)"
echo ""
echo "3. Check IP Addresses"
echo "   - IPs might have changed if DHCP"
echo "   - Check your router's DHCP leases"
echo "   - Look for devices named 'aria' or 'octavia'"
echo ""
echo "4. Direct Connection Test"
echo "   - Connect monitor + keyboard directly"
echo "   - Check if Pi is actually on"
echo "   - Run: ip addr"
echo ""

echo "========================================="
echo "✅ VERIFICATION"
echo "========================================="
echo ""
echo "After fixing, test with:"
echo ""
echo "Test Lucidia:"
echo "  ssh pi@192.168.4.38 'hostname'"
echo ""
echo "Test Aria:"
echo "  ping 192.168.4.64"
echo "  ssh pi@192.168.4.64 'hostname'"
echo ""
echo "Test Octavia:"
echo "  ping 192.168.4.74"
echo "  ssh pi@192.168.4.74 'hostname'"
echo ""

echo "========================================="
echo "📝 Your SSH Public Key"
echo "========================================="
echo ""
echo "Copy this key to add to other Pis:"
echo ""
cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub
echo ""

echo "========================================="
echo "🚀 Once Fixed, Deploy Services!"
echo "========================================="
echo ""
echo "When all Pis are accessible, run:"
echo "  ~/deploy-all-to-pis.sh"
echo ""
echo "Or deploy to specific Pi:"
echo "  cd ~/roadapi-pi-deploy"
echo "  cat README.md"
echo ""
echo "🖤🛣️ BlackRoad Pi Cluster!"
