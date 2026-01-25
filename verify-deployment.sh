#!/usr/bin/env bash

# Simple verification of BlackRoad Priority Stack deployment status

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✓${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }
info() { echo -e "${BLUE}ℹ${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }

echo "======================================"
echo "  BlackRoad Deployment Verification  "
echo "======================================"
echo ""

# Check Docker
if ! docker ps &> /dev/null; then
    error "Docker is not running"
    exit 1
fi

# Check for BlackRoad containers
CONTAINERS=$(docker ps --format "{{.Names}}" | grep "^blackroad-" || true)

if [ -z "$CONTAINERS" ]; then
    warn "No BlackRoad containers are running"
    echo ""
    echo "To deploy, run:"
    echo "  cd ~/blackroad-priority-stack"
    echo "  ./deploy-and-test.sh"
    exit 0
fi

echo "Running Containers:"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "blackroad-" || true
echo ""

# Test each service
info "Testing service endpoints..."
echo ""

# Headscale
if docker ps | grep -q "blackroad-headscale"; then
    if curl -s -f -m 2 http://localhost:8080/metrics &> /dev/null; then
        success "Headscale API responding (http://localhost:8080)"
    else
        warn "Headscale container running but API not ready"
    fi

    if curl -s -f -m 2 http://localhost:8081 &> /dev/null; then
        success "Headscale UI responding (http://localhost:8081)"
    else
        warn "Headscale UI not ready"
    fi
else
    info "Headscale not deployed"
fi

# Keycloak
if docker ps | grep -q "blackroad-keycloak"; then
    if curl -s -m 2 http://localhost:8082 | grep -q "Keycloak" 2> /dev/null; then
        success "Keycloak responding (http://localhost:8082)"
    else
        warn "Keycloak container running but not ready (may still be initializing)"
    fi
else
    info "Keycloak not deployed"
fi

# vLLM
if docker ps | grep -q "blackroad-vllm"; then
    if curl -s -f -m 2 http://localhost:8083/health &> /dev/null; then
        success "vLLM (GPU) responding (http://localhost:8083)"
    elif curl -s -f -m 2 http://localhost:8084/health &> /dev/null; then
        success "vLLM (CPU) responding (http://localhost:8084)"
    else
        warn "vLLM container running but not ready (model may still be loading)"
    fi
else
    info "vLLM not deployed"
fi

# EspoCRM
if docker ps | grep -q "blackroad-espocrm"; then
    if curl -s -m 2 http://localhost:8085 | grep -q "EspoCRM" 2> /dev/null; then
        success "EspoCRM responding (http://localhost:8085)"
    else
        warn "EspoCRM container running but not ready"
    fi
else
    info "EspoCRM not deployed"
fi

echo ""
echo "======================================"
echo "  Quick Access                       "
echo "======================================"
echo ""

# Show access URLs for running services
if docker ps | grep -q "blackroad-headscale"; then
    echo "Headscale:"
    echo "  UI:  http://localhost:8081"
    echo "  API: http://localhost:8080"
    echo ""
fi

if docker ps | grep -q "blackroad-keycloak"; then
    echo "Keycloak:"
    echo "  Admin: http://localhost:8082"
    echo "  User: admin / (check keycloak/.env)"
    echo ""
fi

if docker ps | grep -q "blackroad-vllm"; then
    echo "vLLM:"
    if docker ps | grep -q "blackroad-vllm-qwen"; then
        echo "  API: http://localhost:8083/v1"
        echo "  Model: qwen2.5:7b"
    else
        echo "  API: http://localhost:8084/v1"
        echo "  Model: phi-2"
    fi
    echo ""
fi

if docker ps | grep -q "blackroad-espocrm"; then
    echo "EspoCRM:"
    echo "  App: http://localhost:8085"
    echo "  User: admin / (check espocrm/.env)"
    echo ""
fi

echo "Commands:"
echo "  View logs: docker logs -f <container-name>"
echo "  Stop all:  cd ~/blackroad-priority-stack && ./stop-all.sh"
echo ""
