#!/bin/bash
# Quick SSH Reference for BlackRoad Infrastructure
# Last verified: 2025-12-26

echo "🖤🛣️  BlackRoad SSH Quick Access"
echo "================================"
echo ""
echo "Raspberry Pi Mesh:"
echo "  ssh alice@alice         # 192.168.4.49 - Kubernetes master"
echo "  ssh lucidia@lucidia     # 192.168.4.38 - Tailscale node"
echo "  ssh aria64              # 192.168.4.64 - BlackRoad node"
echo "  ssh pi@192.168.4.74     # 192.168.4.74 - Octavia (Pironman)"
echo ""
echo "DigitalOcean:"
echo "  ssh shellfish           # 174.138.44.45 - Production droplet"
echo ""
echo "Test all connections:"
echo '  for host in "alice@alice" "lucidia@lucidia" "aria64" "pi@192.168.4.74" "shellfish"; do'
echo '    echo "=== $host ===" && ssh $host "hostname && whoami"'
echo '  done'
