#!/bin/bash
# 🚀 BlackRoad AI - Deploy Qwen to Raspberry Pi
# Usage: ./deploy-to-pi.sh <pi-name>

set -e

PI_NAME=${1:-lucidia}
PI_HOSTS=(
    "lucidia:192.168.4.38"
    "aria:192.168.4.64"
    "alice:192.168.4.49"
    "octavia:192.168.4.74"
)

# Find Pi IP
PI_IP=""
for host in "${PI_HOSTS[@]}"; do
    name="${host%%:*}"
    ip="${host##*:}"
    if [ "$name" = "$PI_NAME" ]; then
        PI_IP="$ip"
        break
    fi
done

if [ -z "$PI_IP" ]; then
    echo "❌ Unknown Pi: $PI_NAME"
    echo "Available Pis: ${PI_HOSTS[@]}"
    exit 1
fi

echo "🚀 Deploying Qwen2.5 to $PI_NAME ($PI_IP)..."

# Log to memory
~/memory-system.sh log started "qwen-deploy-$PI_NAME" "Deploying Qwen2.5 model to $PI_NAME ($PI_IP)" "ai-deployment,qwen,$PI_NAME"

# Build Docker image
echo "📦 Building Docker image..."
docker build -t blackroad-ai-qwen:latest .

# Save and transfer image
echo "💾 Saving Docker image..."
docker save blackroad-ai-qwen:latest | gzip > /tmp/blackroad-ai-qwen.tar.gz

echo "📤 Transferring to $PI_NAME..."
scp /tmp/blackroad-ai-qwen.tar.gz pi@$PI_IP:/tmp/

echo "🔧 Loading image on $PI_NAME..."
ssh pi@$PI_IP "docker load < /tmp/blackroad-ai-qwen.tar.gz && rm /tmp/blackroad-ai-qwen.tar.gz"

# Transfer compose file
echo "📋 Transferring docker-compose.yml..."
scp docker-compose.yml pi@$PI_IP:~/blackroad-ai-qwen/

# Start container
echo "🎬 Starting container on $PI_NAME..."
ssh pi@$PI_IP "cd ~/blackroad-ai-qwen && docker-compose up -d"

# Check health
echo "🏥 Waiting for health check..."
sleep 30
ssh pi@$PI_IP "curl -f http://localhost:8000/health" && echo "✅ Deployment successful!" || echo "❌ Health check failed"

# Log completion
~/memory-system.sh log completed "qwen-deploy-$PI_NAME" "Successfully deployed Qwen2.5 to $PI_NAME ($PI_IP). Container: blackroad-ai-qwen running on port 8000." "ai-deployment,qwen,$PI_NAME"

# Cleanup
rm /tmp/blackroad-ai-qwen.tar.gz

echo "🌌 Deployment complete: http://$PI_IP:8000"
