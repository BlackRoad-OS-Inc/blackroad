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
