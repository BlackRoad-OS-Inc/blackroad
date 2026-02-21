#!/bin/bash

echo "╔════════════════════════════════════════════════════╗"
echo "║   🌌 BLACKROAD INFRASTRUCTURE MAP - COMPLETE      ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

echo "🏠 LOCAL NETWORK (192.168.4.0/22 - asdfghjkl)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test local nodes
/sbin/ping -c 1 192.168.4.49 >/dev/null 2>&1 && echo "  ✅ alice      192.168.4.49  (Pi 400, user: alice)" || echo "  ❌ alice      192.168.4.49  OFFLINE"
/sbin/ping -c 1 192.168.4.81 >/dev/null 2>&1 && echo "  ✅ lucidia    192.168.4.81  (Pi 5, user: lucidia) 🧠 BRAIN" || echo "  ❌ lucidia    192.168.4.81  OFFLINE"
/sbin/ping -c 1 192.168.4.38 >/dev/null 2>&1 && echo "  ✅ octavia    192.168.4.38  (Pi 5, user: octavia)" || echo "  ❌ octavia    192.168.4.38  OFFLINE"
/sbin/ping -c 1 192.168.4.82 >/dev/null 2>&1 && echo "  ✅ aria       192.168.4.82  (Pi 5, user: aria)" || echo "  ❌ aria       192.168.4.82  OFFLINE"
/sbin/ping -c 1 192.168.4.89 >/dev/null 2>&1 && echo "  ✅ cecilia    192.168.4.89  (Unknown, user: cecilia) 🆕" || echo "  ⚠️  cecilia    192.168.4.89  Unknown status"

echo ""
echo "  📍 alexandria 192.168.4.28  (This machine - lucidia-operator)"
echo "  📍 Router     192.168.4.1"

echo ""
echo ""
echo "☁️  CLOUD INFRASTRUCTURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🌐 shellfish       174.138.44.45  (DigitalOcean droplet)"
echo "  🌐 codex-infinity  159.65.43.12   (DigitalOcean droplet, user: root)"
echo ""

echo ""
echo "🔐 TAILSCALE VPN MESH (100.x.x.x)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if command -v tailscale >/dev/null 2>&1; then
    if tailscale status >/dev/null 2>&1; then
        echo "  ✅ Tailscale ACTIVE on this machine"
        echo ""
        tailscale status | head -10
    else
        echo "  ⚠️  Tailscale installed but not connected"
    fi
else
    echo "  ⚠️  Tailscale not installed"
fi

echo ""
echo "  Configured nodes:"
echo "    - cecilia-ts   (100.72.180.98)"
echo "    - lucidia-ts   (100.83.149.86)"
echo "    - aria-ts      (100.109.14.17)"
echo ""

echo ""
echo "🔧 SPECIAL DEVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🖥️  olympia  (pikvm.local, user: root) - PiKVM"
echo ""

echo ""
echo "📊 INFRASTRUCTURE SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

LOCAL_COUNT=$(/sbin/ping -c 1 192.168.4.49 >/dev/null 2>&1 && echo -n "1" || echo -n "0")
LOCAL_COUNT=$((LOCAL_COUNT + $(/sbin/ping -c 1 192.168.4.81 >/dev/null 2>&1 && echo "1" || echo "0")))
LOCAL_COUNT=$((LOCAL_COUNT + $(/sbin/ping -c 1 192.168.4.38 >/dev/null 2>&1 && echo "1" || echo "0")))
LOCAL_COUNT=$((LOCAL_COUNT + $(/sbin/ping -c 1 192.168.4.82 >/dev/null 2>&1 && echo "1" || echo "0")))

echo "  Local Network:  $LOCAL_COUNT/4 Pi nodes online + cecilia (unknown)"
echo "  Cloud:          2 DigitalOcean droplets"
echo "  VPN Mesh:       3 Tailscale endpoints configured"
echo "  Control:        1 PiKVM + this operator machine"
echo ""
echo "  Total nodes:    ~10 devices"
echo ""

echo "🧠 LUCIDIA BRAIN STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if nc -z -w 2 192.168.4.81 4222 2>/dev/null; then
    echo "  ✅ NATS (4222):   RUNNING"
else
    echo "  ❌ NATS (4222):   DOWN"
fi

if nc -z -w 2 192.168.4.81 3000 2>/dev/null; then
    echo "  ✅ Port 3000:     ACTIVE"
else
    echo "  ❌ Port 3000:     DOWN"
fi

if nc -z -w 2 192.168.4.81 8080 2>/dev/null; then
    echo "  ✅ Port 8080:     ACTIVE"
else
    echo "  ❌ Port 8080:     DOWN"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "         SSH Access: Use hostnames from ~/.ssh/config"
echo "         Examples: ssh lucidia, ssh alice, ssh shellfish"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

