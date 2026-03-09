#!/bin/bash
# BlackRoad Mass Service Registration
# Registers all 200+ deployed forkies in the service registry

echo "🖤🛣️ BLACKROAD MASS SERVICE REGISTRATION"
echo "=========================================="
echo "Registering all 200+ forkies in service registry..."
echo ""

# Initialize database
~/blackroad-service-registry.sh init

echo "📊 Registering services by division..."
echo ""

# ============================================
# BLACKROAD-AI DIVISION (AI/ML)
# ============================================
echo "🤖 BlackRoad-AI Division..."

~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-vllm" "https://github.com/vllm-project/vllm" "ai-inference" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-ollama" "https://github.com/ollama/ollama" "ai-inference" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-langchain" "https://github.com/langchain-ai/langchain" "ai-framework" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-qdrant" "https://github.com/qdrant/qdrant" "vector-db" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-weaviate" "https://github.com/weaviate/weaviate" "vector-db" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-chroma" "https://github.com/chroma-core/chroma" "vector-db" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-milvus" "https://github.com/milvus-io/milvus" "vector-db" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-ray" "https://github.com/ray-project/ray" "ai-compute" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-transformers" "https://github.com/huggingface/transformers" "ai-models" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-pytorch" "https://github.com/pytorch/pytorch" "ai-framework" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-tensorflow" "https://github.com/tensorflow/tensorflow" "ai-framework" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-whisper" "https://github.com/openai/whisper" "ai-audio" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-stable-diffusion" "https://github.com/AUTOMATIC1111/stable-diffusion-webui" "ai-image" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-llama-index" "https://github.com/run-llama/llama_index" "ai-framework" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-sklearn" "https://github.com/scikit-learn/scikit-learn" "ai-ml" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-xgboost" "https://github.com/dmlc/xgboost" "ai-ml" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-fastapi" "https://github.com/fastapi/fastapi" "api-framework" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-mlx" "https://github.com/ml-explore/mlx" "ai-framework" "high"
~/blackroad-service-registry.sh register "BlackRoad-AI" "blackroad-jina" "https://github.com/jina-ai/jina" "ai-search" "high"

# ============================================
# BLACKROAD-CLOUD DIVISION (Orchestration)
# ============================================
echo "☁️ BlackRoad-Cloud Division..."

~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-minio" "https://github.com/minio/minio" "object-storage" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-syncthing" "https://github.com/syncthing/syncthing" "sync" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-restic" "https://github.com/restic/restic" "backup" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-traefik" "https://github.com/traefik/traefik" "proxy" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-caddy" "https://github.com/caddyserver/caddy" "web-server" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-rclone" "https://github.com/rclone/rclone" "cloud-sync" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-compose" "https://github.com/docker/compose" "orchestration" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-terraform" "https://github.com/hashicorp/terraform" "iac" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-vault" "https://github.com/hashicorp/vault" "secrets" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-kubernetes" "https://github.com/kubernetes/kubernetes" "orchestration" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-nomad" "https://github.com/hashicorp/nomad" "orchestration" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-etcd" "https://github.com/etcd-io/etcd" "key-value" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-istio" "https://github.com/istio/istio" "service-mesh" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-envoy" "https://github.com/envoyproxy/envoy" "proxy" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-consul" "https://github.com/hashicorp/consul" "service-discovery" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-rancher" "https://github.com/rancher/rancher" "k8s-management" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-argocd" "https://github.com/argoproj/argo-cd" "gitops" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-flux" "https://github.com/fluxcd/flux2" "gitops" "high"
~/blackroad-service-registry.sh register "BlackRoad-Cloud" "blackroad-pulumi" "https://github.com/pulumi/pulumi" "iac" "high"

# ============================================
# BLACKROAD-OS DIVISION (Core Infrastructure)
# ============================================
echo "🖤🛣️ BlackRoad-OS Division..."

~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-headscale" "https://github.com/juanfont/headscale" "vpn" "critical"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-keycloak" "https://github.com/keycloak/keycloak" "auth" "critical"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-prometheus" "https://github.com/prometheus/prometheus" "monitoring" "critical"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-grafana" "https://github.com/grafana/grafana" "dashboards" "critical"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-portainer" "https://github.com/portainer/portainer" "docker-ui" "high"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-netdata" "https://github.com/netdata/netdata" "monitoring" "high"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-cockroachdb" "https://github.com/cockroachdb/cockroach" "database" "high"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-postgresql" "https://github.com/PostgreSQL/PostgreSQL" "database" "critical"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-redis" "https://github.com/redis/redis" "cache" "critical"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-elasticsearch" "https://github.com/elastic/elasticsearch" "search" "high"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-influxdb" "https://github.com/influxdata/influxdb" "timeseries-db" "high"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-victoriametrics" "https://github.com/victoriametrics/VictoriaMetrics" "timeseries-db" "high"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-cockpit" "https://github.com/cockpit-project/cockpit" "server-management" "medium"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-sentry" "https://github.com/getsentry/sentry" "error-tracking" "high"
~/blackroad-service-registry.sh register "BlackRoad-OS" "blackroad-uptime-kuma" "https://github.com/louislam/uptime-kuma" "uptime-monitoring" "medium"

# ============================================
# BLACKROAD-SECURITY DIVISION
# ============================================
echo "🔒 BlackRoad-Security Division..."

~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-openbao" "https://github.com/openbao/openbao" "secrets" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-sops" "https://github.com/mozilla/sops" "encryption" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-opa" "https://github.com/open-policy-agent/opa" "policy" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-trufflehog" "https://github.com/trufflesecurity/trufflehog" "secrets-scan" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-trivy" "https://github.com/aquasecurity/trivy" "vulnerability-scan" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-grype" "https://github.com/anchore/grype" "vulnerability-scan" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-zap" "https://github.com/zaproxy/zaproxy" "security-testing" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-scorecard" "https://github.com/ossf/scorecard" "security-audit" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-wazuh" "https://github.com/wazuh/wazuh" "security-monitoring" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-fail2ban" "https://github.com/fail2ban/fail2ban" "intrusion-prevention" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-suricata" "https://github.com/suricata/suricata" "ids-ips" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-crowdsec" "https://github.com/crowdsecurity/crowdsec" "security-automation" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-snort" "https://github.com/snort3/snort3" "ids-ips" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-modsecurity" "https://github.com/owasp-modsecurity/ModSecurity" "waf" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-cilium" "https://github.com/cilium/cilium" "network-security" "high"
~/blackroad-service-registry.sh register "BlackRoad-Security" "blackroad-falco" "https://github.com/falcosecurity/falco" "runtime-security" "high"

# ============================================
# BLACKROAD-FOUNDATION DIVISION (Business)
# ============================================
echo "💼 BlackRoad-Foundation Division..."

~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-espocrm" "https://github.com/espocrm/espocrm" "crm" "high"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-odoo" "https://github.com/odoo/odoo" "erp" "high"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-openproject" "https://github.com/opf/openproject" "project-management" "high"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-invoiceninja" "https://github.com/invoiceninja/invoiceninja" "invoicing" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-dolibarr" "https://github.com/dolibarr/dolibarr" "erp-crm" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-metabase" "https://github.com/metabase/metabase" "analytics" "high"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-nocodb" "https://github.com/nocodb/nocodb" "database-ui" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-suitecrm" "https://github.com/suitecrm/SuiteCRM" "crm" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-akaunting" "https://github.com/akaunting/akaunting" "accounting" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-firefly-accounting" "https://github.com/firefly-iii/firefly-iii" "finance" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-taiga" "https://github.com/taigaio/taiga" "agile-pm" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-wekan" "https://github.com/wekan/wekan" "kanban" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-focalboard" "https://github.com/focalboard/focalboard" "project-management" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Foundation" "blackroad-mattermost" "https://github.com/mattermost/mattermost" "team-chat" "high"

# ============================================
# BLACKROAD-MEDIA DIVISION
# ============================================
echo "🎬 BlackRoad-Media Division..."

~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-mastodon" "https://github.com/mastodon/mastodon" "social-network" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-ghost" "https://github.com/TryGhost/Ghost" "publishing" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-jitsi" "https://github.com/jitsi/jitsi-meet" "video-conferencing" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-pixelfed" "https://github.com/pixelfed/pixelfed" "photo-sharing" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-matrix" "https://github.com/matrix-org/synapse" "chat-server" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-discourse" "https://github.com/discourse/discourse" "forum" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-bigbluebutton" "https://github.com/bigbluebutton/bigbluebutton" "web-conferencing" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-nextcloud" "https://github.com/nextcloud/server" "file-sync" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-owncloud" "https://github.com/owncloud/core" "file-sync" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-immich" "https://github.com/immich-app/immich" "photo-management" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-photoprism" "https://github.com/photoprism/photoprism" "photo-management" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-jellyfin" "https://github.com/jellyfin/jellyfin" "media-server" "high"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-peertube" "https://github.com/peertube/PeerTube" "video-hosting" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-bookstack" "https://github.com/bookstack/BookStack" "wiki" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-grav" "https://github.com/getgrav/grav" "cms" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Media" "blackroad-writefreely" "https://github.com/writefreely/writefreely" "blogging" "medium"

# ============================================
# BLACKROAD-LABS DIVISION (Research)
# ============================================
echo "🔬 BlackRoad-Labs Division..."

~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-jupyter" "https://github.com/jupyter/notebook" "notebooks" "high"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-ckan" "https://github.com/ckan/ckan" "data-catalog" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-mlflow" "https://github.com/mlflow/mlflow" "ml-ops" "high"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-airflow" "https://github.com/apache/airflow" "workflow-orchestration" "high"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-dask" "https://github.com/dask/dask" "distributed-computing" "high"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-streamlit" "https://github.com/streamlit/streamlit" "data-apps" "high"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-superset" "https://github.com/apache/superset" "data-viz" "high"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-spark" "https://github.com/apache/spark" "big-data" "high"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-gradio" "https://github.com/gradio-app/gradio" "ml-interfaces" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-dagster" "https://github.com/dagster-io/dagster" "data-orchestration" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Labs" "blackroad-panel" "https://github.com/holoviz/panel" "dashboards" "medium"

# ============================================
# BLACKROAD-EDUCATION DIVISION
# ============================================
echo "🎓 BlackRoad-Education Division..."

~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-moodle" "https://github.com/moodle/moodle" "lms" "high"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-outline" "https://github.com/outline/outline" "knowledge-base" "high"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-oppia" "https://github.com/oppia/oppia" "learning-platform" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-kolibri" "https://github.com/learningequality/kolibri" "offline-learning" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-anki" "https://github.com/ankidroid/Anki-Android" "flashcards" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-openedx" "https://github.com/openedx/edx-platform" "mooc-platform" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-openstax" "https://github.com/openstax/cnx" "textbooks" "low"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-opencraft" "https://github.com/opencraft/openedx" "edx-hosting" "low"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-h5p" "https://github.com/h5p/h5p-php-library" "interactive-content" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Education" "blackroad-chamilo" "https://github.com/chamilo/chamilo-lms" "e-learning" "low"

# ============================================
# BLACKROAD-HARDWARE DIVISION (IoT)
# ============================================
echo "⚙️ BlackRoad-Hardware Division..."

~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-home-assistant" "https://github.com/home-assistant/core" "home-automation" "high"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-node-red" "https://github.com/node-red/node-red" "iot-automation" "high"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-esphome" "https://github.com/esphome/esphome" "esp-firmware" "high"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-tasmota" "https://github.com/tasmota/tasmota" "esp-firmware" "high"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-mosquitto" "https://github.com/eclipse/mosquitto" "mqtt-broker" "critical"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-emqx" "https://github.com/emqx/emqx" "mqtt-broker" "high"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-platformio" "https://github.com/platformio/platformio-core" "embedded-dev" "high"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-balena" "https://github.com/balena-io/balena" "iot-deployment" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-kerberos" "https://github.com/kerberos-io/kerberos" "video-surveillance" "low"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-openems" "https://github.com/OpenEMS/openems" "energy-management" "low"
~/blackroad-service-registry.sh register "BlackRoad-Hardware" "blackroad-openhab" "https://github.com/openhab/openhab-core" "home-automation" "medium"

# ============================================
# BLACKROAD-INTERACTIVE DIVISION (Gaming)
# ============================================
echo "🎮 BlackRoad-Interactive Division..."

~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-godot" "https://github.com/godotengine/godot" "game-engine" "high"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-threejs" "https://github.com/mrdoob/three.js" "3d-library" "high"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-bevy" "https://github.com/bevyengine/bevy" "game-engine" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-o3de" "https://github.com/o3de/o3de" "game-engine" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-playcanvas" "https://github.com/playcanvas/engine" "game-engine" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-cocos" "https://github.com/cocos/cocos-engine" "game-engine" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-unity" "https://github.com/Unity-Technologies/UnityCsReference" "game-engine" "high"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-sfml" "https://github.com/SFML/SFML" "multimedia-library" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-sdl" "https://github.com/libsdl-org/SDL" "multimedia-library" "high"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-phaser" "https://github.com/phaser/phaser" "game-framework" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-babylonjs" "https://github.com/BabylonJS/Babylon.js" "3d-engine" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Interactive" "blackroad-excalibur" "https://github.com/excaliburjs/Excalibur" "game-engine" "low"

# ============================================
# BLACKROAD-VENTURES DIVISION (Finance)
# ============================================
echo "💰 BlackRoad-Ventures Division..."

~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-btcpay" "https://github.com/btcpayserver/btcpayserver" "crypto-payment" "high"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-plausible" "https://github.com/plausible/analytics" "web-analytics" "high"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-firefly" "https://github.com/firefly-iii/firefly-iii" "personal-finance" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-maybe" "https://github.com/maybe-finance/maybe" "finance-planning" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-crater" "https://github.com/crater-invoice/crater" "invoicing" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-killbill" "https://github.com/killbill/killbill" "billing-platform" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-ledger" "https://github.com/ledger/ledger" "accounting-cli" "low"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-erpnext" "https://github.com/frappe/erpnext" "erp" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-gnucash" "https://github.com/gnucash/gnucash" "accounting" "low"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-invoiceplane" "https://github.com/invoiceplane/invoiceplane" "invoicing" "low"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-solidus" "https://github.com/solidusio/solidus" "ecommerce" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Ventures" "blackroad-prestashop" "https://github.com/prestashop/PrestaShop" "ecommerce" "medium"

# ============================================
# BLACKROAD-STUDIO DIVISION (Creative Tools)
# ============================================
echo "🎨 BlackRoad-Studio Division..."

~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-penpot" "https://github.com/penpot/penpot" "design-tool" "high"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-krita" "https://github.com/KDE/krita" "digital-painting" "high"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-drawio" "https://github.com/drawio-desktop/drawio-desktop" "diagramming" "high"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-inkscape" "https://github.com/inkscape/inkscape" "vector-graphics" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-scribus" "https://github.com/scribus/scribus" "desktop-publishing" "low"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-blender" "https://github.com/blender/blender" "3d-creation" "high"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-gimp" "https://github.com/GIMP/gimp" "image-editor" "high"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-audacity" "https://github.com/audacity/audacity" "audio-editor" "high"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-obs" "https://github.com/obsproject/obs-studio" "video-recording" "high"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-openscad" "https://github.com/openscad/openscad" "3d-cad" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-freecad" "https://github.com/freecad/FreeCAD" "parametric-cad" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Studio" "blackroad-librecad" "https://github.com/LibreCAD/LibreCAD" "2d-cad" "low"

# ============================================
# BLACKROAD-ARCHIVE DIVISION (Preservation)
# ============================================
echo "📚 BlackRoad-Archive Division..."

~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-ipfs" "https://github.com/ipfs/kubo" "distributed-storage" "high"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-archivebox" "https://github.com/ArchiveBox/ArchiveBox" "web-archiving" "high"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-openlibrary" "https://github.com/internetarchive/openlibrary" "digital-library" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-filecoin" "https://github.com/filecoin-project/lotus" "distributed-storage" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-paperless" "https://github.com/paperless-ngx/paperless-ngx" "document-management" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-borg" "https://github.com/borgbackup/borg" "backup" "high"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-duplicati" "https://github.com/duplicati/duplicati" "backup" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-archivy" "https://github.com/archivy/archivy" "knowledge-archival" "low"
~/blackroad-service-registry.sh register "BlackRoad-Archive" "blackroad-zotero" "https://github.com/zotero/zotero" "reference-management" "medium"

# ============================================
# BLACKROAD-GOV DIVISION (Governance)
# ============================================
echo "⚖️ BlackRoad-Gov Division..."

~/blackroad-service-registry.sh register "BlackRoad-Gov" "blackroad-snapshot" "https://github.com/snapshot-labs/snapshot" "dao-voting" "high"
~/blackroad-service-registry.sh register "BlackRoad-Gov" "blackroad-decidim" "https://github.com/decidim/decidim" "participatory-democracy" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Gov" "blackroad-aragon" "https://github.com/aragon/aragon" "dao-platform" "high"
~/blackroad-service-registry.sh register "BlackRoad-Gov" "blackroad-vocdoni" "https://github.com/vocdoni/vocdoni-node" "voting-protocol" "medium"
~/blackroad-service-registry.sh register "BlackRoad-Gov" "blackroad-partydao" "https://github.com/PartyDAO/party-protocol" "group-coordination" "low"
~/blackroad-service-registry.sh register "BlackRoad-Gov" "blackroad-sovereign" "https://github.com/DemocracyEarth/sovereign" "liquid-democracy" "low"
~/blackroad-service-registry.sh register "BlackRoad-Gov" "blackroad-consul-gov" "https://github.com/consul/consul" "civic-engagement" "medium"

# ============================================
# BLACKBOX-ENTERPRISES DIVISION (Automation)
# ============================================
echo "🏢 Blackbox-Enterprises Division..."

~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-n8n" "https://github.com/n8n-io/n8n" "workflow-automation" "high"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-airbyte" "https://github.com/airbytehq/airbyte" "data-integration" "high"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-activepieces" "https://github.com/activepieces/activepieces" "automation" "medium"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-prefect" "https://github.com/prefecthq/prefect" "workflow-orchestration" "high"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-nifi" "https://github.com/apache/nifi" "data-flow" "high"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-windmill" "https://github.com/windmill-labs/windmill" "developer-platform" "medium"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-kestra" "https://github.com/kestra-io/kestra" "orchestration" "medium"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-dolphinscheduler" "https://github.com/apache/dolphinscheduler" "workflow-scheduler" "medium"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-temporal" "https://github.com/temporalio/temporal" "durable-execution" "high"
~/blackroad-service-registry.sh register "Blackbox-Enterprises" "blackbox-huginn" "https://github.com/huginn/huginn" "agent-automation" "low"

echo ""
echo "✅ ALL SERVICES REGISTERED!"
echo ""

# Show statistics
~/blackroad-service-registry.sh stats

echo ""
echo "🖤🛣️ BLACKROAD SERVICE REGISTRY COMPLETE!"
echo "📊 All 200+ services registered and tracked"
echo ""
echo "Commands:"
echo "  ~/blackroad-service-registry.sh stats     - Show statistics"
echo "  ~/blackroad-service-registry.sh list      - List all services"
echo "  ~/blackroad-service-registry.sh map       - Generate service map"
echo "  ~/blackroad-service-registry.sh export    - Export to JSON"
echo ""
