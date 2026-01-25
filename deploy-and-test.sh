#!/usr/bin/env bash

# BlackRoad Priority Stack Deploy & Test
# Deploys each service and verifies it's working

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }
info() { echo -e "${BLUE}ℹ${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "  BlackRoad Priority Stack Deploy    "
echo "======================================"
echo ""

# Deploy Headscale
deploy_headscale() {
    info "Deploying Headscale..."
    cd "$SCRIPT_DIR/headscale"

    docker compose up -d 2>&1 | grep -v "version.*obsolete" || true

    echo "  Waiting for Headscale to start..."
    sleep 8

    if docker ps | grep -q blackroad-headscale; then
        success "Headscale container running"

        # Test API
        if curl -s -f http://localhost:8080/health &> /dev/null || curl -s -f http://localhost:8080/metrics &> /dev/null; then
            success "Headscale API responding"
        else
            warn "Headscale API not responding yet (may take longer to initialize)"
        fi

        # Test UI
        if curl -s -f http://localhost:8081 &> /dev/null; then
            success "Headscale UI responding"
        else
            warn "Headscale UI not responding yet"
        fi
    else
        error "Headscale container failed to start"
        docker logs blackroad-headscale --tail 20
    fi
    echo ""
}

# Deploy Keycloak
deploy_keycloak() {
    info "Deploying Keycloak..."
    cd "$SCRIPT_DIR/keycloak"

    docker compose up -d 2>&1 | grep -v "version.*obsolete" || true

    echo "  Waiting for PostgreSQL to start..."
    sleep 10
    echo "  Waiting for Keycloak to start (this takes ~30 seconds)..."
    sleep 30

    if docker ps | grep -q blackroad-keycloak; then
        success "Keycloak container running"

        # Test health
        if curl -s -f http://localhost:8082/health &> /dev/null; then
            success "Keycloak health endpoint responding"
        else
            warn "Keycloak still initializing (this is normal)"
        fi

        # Test UI
        if curl -s http://localhost:8082 | grep -q "Keycloak" 2> /dev/null; then
            success "Keycloak UI responding"
        else
            warn "Keycloak UI not ready yet"
        fi
    else
        error "Keycloak container failed to start"
        docker logs blackroad-keycloak --tail 20
    fi
    echo ""
}

# Deploy vLLM
deploy_vllm() {
    info "Deploying vLLM..."
    cd "$SCRIPT_DIR/vllm"

    if command -v nvidia-smi &> /dev/null; then
        info "GPU detected, deploying Qwen2.5-7B..."
        docker compose up -d vllm-qwen 2>&1 | grep -v "version.*obsolete" || true
        PORT=8083
        MODEL="qwen2.5:7b"
    else
        info "No GPU, deploying Phi-2 (CPU)..."
        docker compose --profile cpu-fallback up -d vllm-phi 2>&1 | grep -v "version.*obsolete" || true
        PORT=8084
        MODEL="phi-2"
    fi

    echo "  Downloading model and starting vLLM (this may take 5-10 minutes)..."
    sleep 15

    if docker ps | grep -q blackroad-vllm; then
        success "vLLM container running"

        # Check logs for model loading
        if docker logs blackroad-vllm-qwen 2>&1 | grep -q "Uvicorn running" || docker logs blackroad-vllm-phi 2>&1 | grep -q "Uvicorn running"; then
            success "vLLM API server started"

            # Test API
            if curl -s -f http://localhost:$PORT/health &> /dev/null; then
                success "vLLM health endpoint responding"
            else
                warn "vLLM still loading model..."
            fi
        else
            warn "vLLM still loading model (check logs: docker logs blackroad-vllm-qwen)"
        fi
    else
        error "vLLM container failed to start"
    fi
    echo ""
}

# Deploy EspoCRM
deploy_espocrm() {
    info "Deploying EspoCRM..."
    cd "$SCRIPT_DIR/espocrm"

    docker compose up -d 2>&1 | grep -v "version.*obsolete" || true

    echo "  Waiting for MySQL to start..."
    sleep 10
    echo "  Waiting for EspoCRM to initialize (this takes ~20 seconds)..."
    sleep 20

    if docker ps | grep -q blackroad-espocrm; then
        success "EspoCRM container running"

        # Test UI
        if curl -s http://localhost:8085 | grep -q "EspoCRM" 2> /dev/null; then
            success "EspoCRM UI responding"
        else
            warn "EspoCRM still initializing"
        fi
    else
        error "EspoCRM container failed to start"
        docker logs blackroad-espocrm --tail 20
    fi
    echo ""
}

# Show status
show_status() {
    echo "======================================"
    echo "  Deployment Status                  "
    echo "======================================"
    echo ""
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep blackroad || echo "No BlackRoad containers running"
    echo ""
}

# Show summary
show_summary() {
    echo "======================================"
    echo "  BlackRoad Priority Stack Summary   "
    echo "======================================"
    echo ""
    echo "Access URLs:"
    echo ""
    echo "  Headscale:"
    echo "    - UI:  http://localhost:8081"
    echo "    - API: http://localhost:8080"
    echo ""
    echo "  Keycloak:"
    echo "    - Admin: http://localhost:8082"
    echo "    - Username: admin"
    echo "    - Password: (check keycloak/.env)"
    echo ""
    echo "  vLLM:"
    if command -v nvidia-smi &> /dev/null; then
        echo "    - API: http://localhost:8083/v1"
        echo "    - Model: qwen2.5:7b"
    else
        echo "    - API: http://localhost:8084/v1"
        echo "    - Model: phi-2"
    fi
    echo ""
    echo "  EspoCRM:"
    echo "    - App: http://localhost:8085"
    echo "    - Username: admin"
    echo "    - Password: (check espocrm/.env)"
    echo ""
    echo "Logs:"
    echo "  docker logs -f blackroad-headscale"
    echo "  docker logs -f blackroad-keycloak"
    echo "  docker logs -f blackroad-vllm-qwen (or blackroad-vllm-phi)"
    echo "  docker logs -f blackroad-espocrm"
    echo ""
    echo "Stop all:"
    echo "  cd ~/blackroad-priority-stack"
    echo "  cd headscale && docker compose down"
    echo "  cd ../keycloak && docker compose down"
    echo "  cd ../vllm && docker compose down"
    echo "  cd ../espocrm && docker compose down"
    echo ""
}

# Main
main() {
    # Ask which to deploy
    echo "Select services to deploy:"
    echo ""

    read -p "Deploy Headscale (Mesh VPN)? [Y/n] " -n 1 -r
    echo
    DEPLOY_HEADSCALE=${REPLY:-Y}

    read -p "Deploy Keycloak (Identity)? [Y/n] " -n 1 -r
    echo
    DEPLOY_KEYCLOAK=${REPLY:-Y}

    read -p "Deploy vLLM (AI Inference)? [Y/n] " -n 1 -r
    echo
    DEPLOY_VLLM=${REPLY:-Y}

    read -p "Deploy EspoCRM (CRM)? [Y/n] " -n 1 -r
    echo
    DEPLOY_ESPOCRM=${REPLY:-Y}

    echo ""

    # Deploy
    [[ $DEPLOY_HEADSCALE =~ ^[Yy]$ ]] && deploy_headscale
    [[ $DEPLOY_KEYCLOAK =~ ^[Yy]$ ]] && deploy_keycloak
    [[ $DEPLOY_VLLM =~ ^[Yy]$ ]] && deploy_vllm
    [[ $DEPLOY_ESPOCRM =~ ^[Yy]$ ]] && deploy_espocrm

    # Status
    show_status
    show_summary
}

main "$@"
