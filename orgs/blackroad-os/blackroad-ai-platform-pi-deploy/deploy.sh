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
