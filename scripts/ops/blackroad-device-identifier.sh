#!/bin/bash

echo "🔍 BlackRoad Device Identifier"
echo "=============================="
echo ""

# List of unknown IPs
UNKNOWNS=(192.168.4.22 192.168.4.27 192.168.4.33 192.168.4.44 192.168.4.53 192.168.4.86)

for IP in "${UNKNOWNS[@]}"; do
    echo "🔎 Scanning $IP..."
    
    # Quick ping test
    if ping -c 1 -W 1 "$IP" > /dev/null 2>&1; then
        echo "   ✅ ONLINE"
        
        # Get MAC from ARP
        MAC=$(arp -n "$IP" 2>/dev/null | grep -v incomplete | awk 'NR==2 {print $4}')
        echo "   MAC: $MAC"
        
        # Try nmap OS detection (requires sudo)
        echo "   🔬 Running nmap scan..."
        sudo nmap -O -sV "$IP" 2>/dev/null | grep -E "(OS|Service|PORT|MAC Address)" | head -10
        
    else
        echo "   ❌ OFFLINE or unreachable"
    fi
    
    echo ""
    echo "---"
    echo ""
done

echo "✅ Scan complete!"
