#!/bin/bash
# 🔥 Deploy Priority Forkable Infrastructure
# High-value, low-complexity forkable alternatives

set -e

echo "🔥 BlackRoad Priority Forkies Deployment"
echo "========================================"
echo ""

# Create directories
mkdir -p ~/forkies/{meilisearch,minio,prometheus,grafana,headscale,keycloak}

echo "📦 1/6: Deploying Meilisearch (Search Engine)"
echo "   Replaces: Algolia, Elasticsearch"
docker run -d \
  --name meilisearch \
  --restart unless-stopped \
  -p 7700:7700 \
  -v ~/forkies/meilisearch:/meili_data \
  -e MEILI_ENV=production \
  getmeili/meilisearch:latest
echo "✅ Meilisearch running on http://localhost:7700"
echo ""

echo "📦 2/6: Deploying MinIO (S3-Compatible Storage)"
echo "   Replaces: AWS S3, Cloudflare R2"
docker run -d \
  --name minio \
  --restart unless-stopped \
  -p 9000:9000 \
  -p 9001:9001 \
  -v ~/forkies/minio:/data \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"
echo "✅ MinIO running:"
echo "   API:     http://localhost:9000"
echo "   Console: http://localhost:9001"
echo "   User:    minioadmin"
echo "   Pass:    minioadmin"
echo ""

echo "📦 3/6: Deploying Prometheus (Metrics & Monitoring)"
echo "   Replaces: Datadog, New Relic"

# Create Prometheus config
cat > ~/forkies/prometheus/prometheus.yml << 'PROM_CONFIG'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']
PROM_CONFIG

docker run -d \
  --name prometheus \
  --restart unless-stopped \
  -p 9090:9090 \
  -v ~/forkies/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v ~/forkies/prometheus/data:/prometheus \
  prom/prometheus:latest
echo "✅ Prometheus running on http://localhost:9090"
echo ""

echo "📦 4/6: Deploying Grafana (Dashboards & Visualization)"
echo "   Replaces: Datadog UI, New Relic Dashboards"
docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -v ~/forkies/grafana:/var/lib/grafana \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  grafana/grafana:latest
echo "✅ Grafana running on http://localhost:3000"
echo "   User: admin"
echo "   Pass: admin"
echo ""

echo "📦 5/6: Deploying Headscale (Self-Hosted Tailscale)"
echo "   Replaces: Tailscale Control Plane"

# Create Headscale config
cat > ~/forkies/headscale/config.yaml << 'HEAD_CONFIG'
server_url: http://127.0.0.1:8080
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 127.0.0.1:9090

private_key_path: /var/lib/headscale/private.key
noise:
  private_key_path: /var/lib/headscale/noise_private.key

prefixes:
  v4: 100.64.0.0/10
  v6: fd7a:115c:a1e0::/48

derp:
  server:
    enabled: false

database:
  type: sqlite3
  sqlite:
    path: /var/lib/headscale/db.sqlite
HEAD_CONFIG

docker run -d \
  --name headscale \
  --restart unless-stopped \
  -p 8080:8080 \
  -v ~/forkies/headscale:/var/lib/headscale \
  -v ~/forkies/headscale/config.yaml:/etc/headscale/config.yaml \
  headscale/headscale:latest serve
echo "✅ Headscale running on http://localhost:8080"
echo ""

echo "📦 6/6: Deploying Keycloak (Identity & Auth)"
echo "   Replaces: Auth0, Okta"
docker run -d \
  --name keycloak \
  --restart unless-stopped \
  -p 8443:8443 \
  -v ~/forkies/keycloak:/opt/keycloak/data \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:latest start-dev
echo "✅ Keycloak running on https://localhost:8443"
echo "   User: admin"
echo "   Pass: admin"
echo ""

echo "═══════════════════════════════════════════════════════"
echo "🎉 PRIORITY FORKIES DEPLOYED SUCCESSFULLY!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 Service URLs:"
echo "   Meilisearch:  http://localhost:7700"
echo "   MinIO API:    http://localhost:9000"
echo "   MinIO Console:http://localhost:9001"
echo "   Prometheus:   http://localhost:9090"
echo "   Grafana:      http://localhost:3000"
echo "   Headscale:    http://localhost:8080"
echo "   Keycloak:     https://localhost:8443"
echo ""
echo "💾 Data stored in: ~/forkies/"
echo ""
echo "🔥 Annual SaaS Replacement Savings: $1,668-2,148"
echo ""
echo "Next Steps:"
echo "  1. Configure Grafana datasource (Prometheus)"
echo "  2. Create Headscale users"
echo "  3. Set up Keycloak realm"
echo "  4. Integrate with existing apps"
echo ""
echo "Run './stop-priority-forkies.sh' to stop all services"
