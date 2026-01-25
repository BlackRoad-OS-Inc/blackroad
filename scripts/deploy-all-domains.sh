#!/bin/bash

# BlackRoad Deploy - Deploy to ALL Cloudflare Domains
# This script deploys the test app to all major domains

echo "🚀 BlackRoad Deploy - Mass Deployment Script"
echo "=============================================="
echo ""

PI_HOST="192.168.4.64"
IMAGE="blackroad/node-api:latest"

# Array of domains and their ports
declare -A DOMAINS=(
  ["api.blackroad.io"]=3001
  ["demo.blackroad.io"]=3002
  ["home.blackroad.io"]=3003
  ["creator-studio.blackroad.io"]=3004
  ["devops.blackroad.io"]=3005
  ["education.blackroad.io"]=3006
  ["finance.blackroad.io"]=3007
  ["ideas.blackroad.io"]=3008
  ["legal.blackroad.io"]=3009
  ["research-lab.blackroad.io"]=3010
  ["studio.blackroad.io"]=3011
  ["brand.blackroad.io"]=3012
  ["earth.blackroad.io"]=3013
  ["blackroadqi.com"]=3020
  ["blackroadquantum.info"]=3021
  ["blackroadquantum.net"]=3022
  ["blackroadquantum.shop"]=3023
  ["blackroadquantum.store"]=3024
  ["roadcoin.io"]=3030
  ["roadchain.io"]=3031
)

echo "📦 Deploying to ${#DOMAINS[@]} domains..."
echo ""

for domain in "${!DOMAINS[@]}"; do
  port=${DOMAINS[$domain]}
  container_name=$(echo "$domain" | tr '.' '-')
  
  echo "🔄 $domain → Port $port"
  
  ssh aria64 "
    docker stop $container_name 2>/dev/null || true && \
    docker rm $container_name 2>/dev/null || true && \
    docker run -d \
      --name $container_name \
      --restart unless-stopped \
      -p $port:3001 \
      -e DOMAIN=$domain \
      $IMAGE
  " 2>/dev/null && echo "   ✅ Deployed" || echo "   ❌ Failed"
done

echo ""
echo "✅ Mass deployment complete!"
echo ""
echo "📊 Checking running containers..."
ssh aria64 "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'blackroad|roadcoin|roadchain' | wc -l"
echo " containers running"
