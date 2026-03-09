#!/bin/bash

# BlackRoad 19 Domains - Testing Script
# Tests all deployed domains

LUCIDIA_HOST="192.168.4.38"

declare -A DOMAINS_PORTS=(
    ["blackboxprogramming.io"]="3000"
    ["blackroad.company"]="3001"
    ["blackroad.me"]="3003"
    ["blackroad.network"]="3004"
    ["blackroad.systems"]="3005"
    ["blackroadai.com"]="3006"
    ["blackroadinc.us"]="3007"
    ["blackroadqi.com"]="3008"
    ["blackroadquantum.com"]="3009"
    ["blackroadquantum.info"]="3010"
    ["blackroadquantum.net"]="3011"
    ["blackroadquantum.shop"]="3012"
    ["blackroadquantum.store"]="3013"
    ["lucidia.earth"]="3109"
    ["lucidia.studio"]="3014"
    ["lucidiaqi.com"]="3015"
    ["roadchain.io"]="3016"
    ["roadcoin.io"]="3017"
)

echo "🧪 Testing BlackRoad 19 Domains"
echo "================================"
echo ""

PASSING=0
FAILING=0

for domain in "${!DOMAINS_PORTS[@]}"; do
    port=${DOMAINS_PORTS[$domain]}
    printf "%-30s (port %s) ... " "$domain" "$port"

    if curl -s -o /dev/null -w "%{http_code}" http://$LUCIDIA_HOST:$port | grep -q "200\|301\|302"; then
        echo "✅ PASS"
        PASSING=$((PASSING + 1))
    else
        echo "❌ FAIL"
        FAILING=$((FAILING + 1))
    fi
done

echo ""
echo "================================"
echo "Results: ✅ $PASSING passing, ❌ $FAILING failing"
echo ""
