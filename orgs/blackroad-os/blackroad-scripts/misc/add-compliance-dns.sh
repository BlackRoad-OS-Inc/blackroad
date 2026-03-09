#!/bin/bash

echo "🖤🛣️ Adding compliance.blackroad.io DNS record..."

# Add DNS A record via PowerDNS API
curl -X POST http://192.168.4.38:8090/domains/blackroad.io/records \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "compliance.blackroad.io",
    "type": "A",
    "content": "192.168.4.49",
    "ttl": 3600
  }'

echo ""
echo "✅ DNS record added!"
echo ""
echo "You can now access the compliance dashboard at:"
echo "  http://compliance.blackroad.io:8084"
echo ""
echo "To verify DNS:"
echo "  dig @192.168.4.38 compliance.blackroad.io"
echo ""
