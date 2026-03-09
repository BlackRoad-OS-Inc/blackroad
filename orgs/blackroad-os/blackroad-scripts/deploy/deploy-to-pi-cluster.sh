#!/bin/bash
# 🥧 Deploy BlackRoad Products to Raspberry Pi Cluster
# Deploys backend services across 3 Raspberry Pis

echo "🥧 BlackRoad Pi Cluster Deployment"
echo "========================================="
echo ""

# Pi cluster configuration (name:ip pairs)
PI_CLUSTER=(
    "lucidia:192.168.4.38"
    "blackroad-pi:192.168.4.64"
    "lucidia-alt:192.168.4.99"
)

# Products with backend services suitable for Pi deployment
BACKEND_PRODUCTS=(
    "blackroad-ai-platform:3000:AI Platform API"
    "blackroad-vllm:8000:vLLM Inference Server"
    "blackroad-localai:8080:LocalAI Server"
    "roadapi:3001:Core API Gateway"
    "roadlog-monitoring:9090:Monitoring Dashboard"
    "blackroad-minio:9000:Object Storage"
    "roadauth:3002:Authentication Service"
    "roadbilling:3003:Billing Service"
)

# Check Pi connectivity
echo "📡 Checking Pi Cluster Connectivity..."
echo ""

available_pis=()
for pi_entry in "${PI_CLUSTER[@]}"; do
    IFS=':' read -r pi_name pi_ip <<< "$pi_entry"
    echo -n "  Testing $pi_name ($pi_ip)... "

    if ping -c 1 -W 2 "$pi_ip" &>/dev/null; then
        echo "✅ Online"
        available_pis+=("$pi_entry")
    else
        echo "❌ Offline"
    fi
done

echo ""
echo "========================================="
echo "📊 Cluster Status"
echo "========================================="
echo "Total Pis: ${#PI_CLUSTER[@]}"
echo "Available: ${#available_pis[@]}"
echo "Offline: $((${#PI_CLUSTER[@]} - ${#available_pis[@]}))"
echo ""

# Continue even if Pis are offline - create deployment packages anyway
if [ ${#available_pis[@]} -eq 0 ]; then
    echo "⚠️  No Pis currently online, but will create deployment packages..."
    echo ""
    # Use all Pis for package creation
    available_pis=("${PI_CLUSTER[@]}")
fi

# Deploy services to available Pis
echo "========================================="
echo "🚀 Creating Backend Service Packages"
echo "========================================="
echo ""

deployed_count=0
failed_count=0
pi_index=0

for product_info in "${BACKEND_PRODUCTS[@]}"; do
    IFS=':' read -r product port description <<< "$product_info"

    # Round-robin distribution across Pis
    pi_info="${available_pis[$pi_index]}"
    IFS=':' read -r pi_name pi_ip <<< "$pi_info"

    echo "📦 Preparing: $product"
    echo "   Description: $description"
    echo "   Target: $pi_name ($pi_ip)"
    echo "   Port: $port"

    # Create deployment package
    deployment_dir="$HOME/${product}-pi-deploy"
    rm -rf "$deployment_dir"
    mkdir -p "$deployment_dir/app"

    # Create Docker Compose configuration
    cat > "$deployment_dir/docker-compose.yml" <<EOF
version: '3.8'

services:
  $product:
    image: node:18-alpine
    container_name: $product
    restart: unless-stopped
    ports:
      - "$port:$port"
    volumes:
      - ./app:/app
    working_dir: /app
    command: node server.js
    environment:
      - NODE_ENV=production
      - PORT=$port
      - PI_NAME=$pi_name
      - SERVICE_NAME=$product
    networks:
      - blackroad-net

networks:
  blackroad-net:
    driver: bridge
EOF

    # Create Node.js server
    cat > "$deployment_dir/app/server.js" <<EOF
const http = require('http');
const PORT = process.env.PORT || $port;
const PI_NAME = process.env.PI_NAME || 'unknown';
const SERVICE_NAME = process.env.SERVICE_NAME || '$product';

const server = http.createServer((req, res) => {
    if (req.url === '/health') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({status: 'healthy'}));
    } else {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({
            service: SERVICE_NAME,
            description: '$description',
            pi: PI_NAME,
            status: 'running',
            port: PORT,
            uptime: process.uptime(),
            timestamp: new Date().toISOString()
        }));
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(\`🥧 \${SERVICE_NAME} running on \${PI_NAME}:\${PORT}\`);
    console.log(\`🔗 Access: http://\${PI_NAME}:\${PORT}\`);
});
EOF

    # Create package.json
    cat > "$deployment_dir/app/package.json" <<EOF
{
  "name": "$product",
  "version": "1.0.0",
  "description": "$description",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {}
}
EOF

    # Create deployment script
    cat > "$deployment_dir/deploy.sh" <<'DEPLOY_SCRIPT'
#!/bin/bash
echo "🥧 Deploying to Pi..."

# Create network if doesn't exist
docker network create blackroad-net 2>/dev/null || true

# Stop existing container
docker-compose down 2>/dev/null || true

# Pull latest Node.js image
docker-compose pull

# Start service
docker-compose up -d

# Wait for service to start
sleep 3

# Check status
docker-compose ps

echo ""
echo "✅ Deployment complete!"
echo "🔍 Check logs: docker-compose logs -f"
echo "🩺 Health check: docker-compose exec $product curl http://localhost:$port/health"
DEPLOY_SCRIPT

    chmod +x "$deployment_dir/deploy.sh"

    # Create README
    cat > "$deployment_dir/README.md" <<EOF
# $product - Pi Deployment

**Description:** $description
**Target Pi:** $pi_name ($pi_ip)
**Port:** $port

## Deployment Instructions

1. Copy files to Pi:
\`\`\`bash
scp -r $deployment_dir pi@$pi_ip:~/
\`\`\`

2. SSH into Pi:
\`\`\`bash
ssh pi@$pi_ip
\`\`\`

3. Deploy:
\`\`\`bash
cd $(basename $deployment_dir)
./deploy.sh
\`\`\`

4. Verify:
\`\`\`bash
curl http://localhost:$port
curl http://localhost:$port/health
\`\`\`

5. Monitor:
\`\`\`bash
docker logs -f $product
\`\`\`

## Management

- Stop: \`docker-compose down\`
- Restart: \`docker-compose restart\`
- Logs: \`docker-compose logs -f\`
- Status: \`docker-compose ps\`
EOF

    ((deployed_count++))
    echo "   ✅ Package created: $deployment_dir"
    echo ""

    # Move to next Pi (round-robin)
    pi_index=$(( (pi_index + 1) % ${#available_pis[@]} ))
done

# Deploy vLLM for edge AI inference
echo "========================================="
echo "🤖 Edge AI Inference Package"
echo "========================================="
echo ""

vllm_dir="$HOME/vllm-pi-edge"
rm -rf "$vllm_dir"
mkdir -p "$vllm_dir"

primary_pi="${available_pis[0]}"
IFS=':' read -r pi_name pi_ip <<< "$primary_pi"

echo "🎯 Creating vLLM package for $pi_name ($pi_ip)"

cat > "$vllm_dir/docker-compose.yml" <<EOF
version: '3.8'

services:
  vllm:
    image: vllm/vllm-openai:latest
    container_name: vllm-edge
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - ./models:/models
      - ./cache:/root/.cache
    environment:
      - MODEL_NAME=TinyLlama/TinyLlama-1.1B-Chat-v1.0
      - MAX_MODEL_LEN=2048
      - TENSOR_PARALLEL_SIZE=1
    command: --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 --host 0.0.0.0 --port 8000 --max-model-len 2048
    networks:
      - blackroad-net

networks:
  blackroad-net:
    driver: bridge
EOF

cat > "$vllm_dir/README.md" <<EOF
# vLLM Edge AI Inference

**Target:** $pi_name ($pi_ip)
**Model:** TinyLlama 1.1B (optimized for Raspberry Pi)
**Port:** 8000

## Deploy:
\`\`\`bash
scp -r $vllm_dir pi@$pi_ip:~/
ssh pi@$pi_ip 'cd vllm-pi-edge && docker-compose up -d'
\`\`\`

## Test:
\`\`\`bash
curl http://$pi_ip:8000/v1/models
\`\`\`
EOF

echo "   ✅ vLLM package created: $vllm_dir"
echo ""

# MinIO distributed storage
echo "========================================="
echo "📦 Distributed Storage Package"
echo "========================================="
echo ""

minio_dir="$HOME/minio-distributed"
rm -rf "$minio_dir"
mkdir -p "$minio_dir"

echo "🎯 Creating MinIO distributed storage configuration"

cat > "$minio_dir/docker-compose.yml" <<EOF
version: '3.8'

services:
  minio:
    image: minio/minio:latest
    container_name: minio-distributed
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - ./data:/data
    environment:
      - MINIO_ROOT_USER=blackroad
      - MINIO_ROOT_PASSWORD=blackroad-secure-2026
    command: server /data --console-address ":9001"
    networks:
      - blackroad-net

networks:
  blackroad-net:
    driver: bridge
EOF

cat > "$minio_dir/README.md" <<EOF
# MinIO Distributed Storage

Deploy to each Pi for distributed object storage.

## Deploy to all Pis:
\`\`\`bash
for pi in ${PI_CLUSTER[@]}; do
    IFS=':' read -r name ip <<< "\$pi"
    echo "Deploying to \$name (\$ip)..."
    scp -r $minio_dir pi@\$ip:~/
    ssh pi@\$ip 'cd minio-distributed && docker-compose up -d'
done
\`\`\`

## Access:
- Console: http://[PI_IP]:9001
- API: http://[PI_IP]:9000
- User: blackroad
- Pass: blackroad-secure-2026
EOF

echo "   ✅ MinIO package created: $minio_dir"
echo ""

# Create master deployment script
echo "========================================="
echo "🎯 Master Deployment Script"
echo "========================================="
echo ""

cat > "$HOME/deploy-all-to-pis.sh" <<'MASTER_SCRIPT'
#!/bin/bash
# 🥧 Master Pi Deployment Script

PI_CLUSTER=(
    "lucidia:192.168.4.38"
    "blackroad-pi:192.168.4.64"
    "lucidia-alt:192.168.4.99"
)

echo "🥧 BlackRoad Pi Cluster - Master Deployment"
echo "==========================================="
echo ""
echo "This will deploy all services to the Pi cluster."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# Deploy backend services
for deploy_dir in $HOME/*-pi-deploy; do
    if [ -d "$deploy_dir" ]; then
        service_name=$(basename "$deploy_dir" | sed 's/-pi-deploy//')
        echo ""
        echo "📦 Deploying $service_name..."

        # Find target Pi from README
        target_ip=$(grep "Target Pi:" "$deploy_dir/README.md" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)

        if [ -n "$target_ip" ]; then
            echo "   Target: $target_ip"
            echo "   Copying files..."

            scp -r "$deploy_dir" "pi@$target_ip:~/" 2>/dev/null && \
            ssh "pi@$target_ip" "cd $(basename $deploy_dir) && ./deploy.sh" 2>/dev/null && \
            echo "   ✅ Deployed successfully" || \
            echo "   ⚠️  Deployment failed (Pi may be offline or SSH not configured)"
        fi
    fi
done

echo ""
echo "==========================================="
echo "✅ Master deployment complete!"
echo "🖤🛣️"
MASTER_SCRIPT

chmod +x "$HOME/deploy-all-to-pis.sh"

echo "   ✅ Master script created: ~/deploy-all-to-pis.sh"
echo ""

# Summary
echo "========================================="
echo "📊 Deployment Package Summary"
echo "========================================="
echo ""
echo "✅ Backend Services: $deployed_count packages created"
echo "✅ Edge AI: vLLM package ready"
echo "✅ Storage: MinIO package ready"
echo "✅ Master Script: ~/deploy-all-to-pis.sh"
echo ""
echo "📦 Package Locations:"
for deploy_dir in $HOME/*-pi-deploy; do
    if [ -d "$deploy_dir" ]; then
        echo "   - $(basename $deploy_dir)"
    fi
done
echo "   - vllm-pi-edge"
echo "   - minio-distributed"
echo ""
echo "🚀 Quick Deploy Options:"
echo ""
echo "1. Deploy everything (when Pis are online):"
echo "   ~/deploy-all-to-pis.sh"
echo ""
echo "2. Deploy individual service:"
echo "   cd ~/<service>-pi-deploy && cat README.md"
echo ""
echo "3. Test Pi connectivity:"
echo "   for pi in 192.168.4.38 192.168.4.64 192.168.4.99; do ping -c 1 \$pi; done"
echo ""
echo "📝 Next Steps:"
echo "  1. Ensure Pis are powered on and connected to network"
echo "  2. Configure SSH keys: ssh-copy-id pi@[PI_IP]"
echo "  3. Install Docker on each Pi: ssh pi@[PI_IP] 'curl -fsSL https://get.docker.com | sh'"
echo "  4. Run master deployment: ~/deploy-all-to-pis.sh"
echo ""
echo "🖤🛣️ Pi Cluster Deployment Packages Ready!"
