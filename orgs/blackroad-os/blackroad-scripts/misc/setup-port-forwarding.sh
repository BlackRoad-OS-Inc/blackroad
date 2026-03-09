#!/bin/bash

echo "🖤🛣️ Setting up port forwarding for compliance dashboard..."

# Add port forwarding rule on Alice Pi (80 → 8084)
ssh pi@192.168.4.49 << 'REMOTE'
# Forward incoming port 80 to 8084
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8084

# Save iptables rules
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

echo "✅ Port forwarding enabled: port 80 → 8084"
echo ""
echo "Now accessible at:"
echo "  http://192.168.4.49 (no port needed!)"
echo "  http://192.168.4.49:8084 (direct access still works)"
REMOTE

echo ""
echo "✅ Port forwarding complete!"
