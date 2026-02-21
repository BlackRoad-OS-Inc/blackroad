#!/bin/bash
# BlackRoad Network Discovery - Find all devices

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🖤 BLACKROAD NETWORK SCAN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Local network
LOCAL_NETWORK="192.168.4"
YOUR_IP="192.168.4.28"

echo "🔍 Scanning Local Network: ${LOCAL_NETWORK}.0/22"
echo ""

# Check ARP cache first
echo "📋 ARP Cache (known devices):"
arp -a | grep "${LOCAL_NETWORK}" | sort -V
echo ""

# Ping sweep
echo "🌐 Ping Sweep (active devices)..."
echo ""
for i in {1..255}; do
  {
    IP="${LOCAL_NETWORK}.$i"
    if ping -c 1 -W 1 "$IP" &> /dev/null; then
      HOSTNAME=$(host "$IP" 2>/dev/null | awk '{print $NF}' | sed 's/\.$//')
      echo "  ✅ $IP - $HOSTNAME"
    fi
  } &
done
wait
echo ""

# Tailscale devices
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 Tailscale Network:"
tailscale status 2>&1
echo ""

# Known infrastructure
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Known BlackRoad Infrastructure:"
echo ""
echo "Raspberry Pis:"
echo "  alice:     192.168.4.49"
echo "  aria:      192.168.4.82"
echo "  lucidia:   192.168.4.38"
echo "  octavia:   192.168.4.74"
echo "  anastasia: (IP unknown)"
echo ""
echo "Other Devices:"
echo "  Your Mac:  192.168.4.28"
echo ""
echo "DigitalOcean:"
echo "  codex-infinity: 159.65.43.12"
echo "  shellfish:      174.138.44.45"
echo ""

# Check if nmap is available
if command -v nmap &> /dev/null; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔎 Deep Scan (nmap):"
  nmap -sn "${LOCAL_NETWORK}.0/22" 2>&1 | grep "Nmap scan report"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Scan complete!"
