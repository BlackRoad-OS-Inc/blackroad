#!/usr/bin/env bash

# BlackRoad Priority Stack Configuration Test
# Tests all Docker Compose configs without deploying

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
cd "$SCRIPT_DIR"

echo "======================================"
echo "  BlackRoad Priority Stack Tests     "
echo "======================================"
echo ""

# Test Docker
info "Checking Docker..."
if docker --version &> /dev/null; then
    success "Docker installed: $(docker --version | head -1)"
else
    error "Docker not installed"
    exit 1
fi
echo ""

# Test Headscale
info "Testing Headscale configuration..."
cd "$SCRIPT_DIR/headscale"
if docker compose config &> /dev/null; then
    success "Headscale docker-compose.yml valid"
else
    error "Headscale docker-compose.yml invalid"
fi
if [ -f "config/config.yaml" ]; then
    success "Headscale config.yaml exists"
else
    warn "Headscale config.yaml missing (will be created on first run)"
fi
echo ""

# Test Keycloak
info "Testing Keycloak configuration..."
cd "$SCRIPT_DIR/keycloak"
if docker compose config &> /dev/null; then
    success "Keycloak docker-compose.yml valid"
else
    error "Keycloak docker-compose.yml invalid"
fi
if [ -f ".env" ]; then
    success "Keycloak .env exists"
else
    warn "Keycloak .env missing"
fi
echo ""

# Test vLLM
info "Testing vLLM configuration..."
cd "$SCRIPT_DIR/vllm"
if docker compose config &> /dev/null; then
    success "vLLM docker-compose.yml valid"
else
    error "vLLM docker-compose.yml invalid"
fi
if [ -f ".env" ]; then
    success "vLLM .env exists"
else
    warn "vLLM .env missing"
fi

# Check for GPU
if command -v nvidia-smi &> /dev/null; then
    success "NVIDIA GPU detected"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
    warn "No NVIDIA GPU detected (CPU fallback available)"
fi
echo ""

# Test EspoCRM
info "Testing EspoCRM configuration..."
cd "$SCRIPT_DIR/espocrm"
if docker compose config &> /dev/null; then
    success "EspoCRM docker-compose.yml valid"
else
    error "EspoCRM docker-compose.yml invalid"
fi
if [ -f ".env" ]; then
    success "EspoCRM .env exists"
else
    warn "EspoCRM .env missing"
fi
echo ""

# Port availability check
info "Checking port availability..."
PORTS=(8080 8081 8082 8083 8084 8085 8086 9090 11434 50443)
for port in "${PORTS[@]}"; do
    if lsof -i ":$port" &> /dev/null; then
        warn "Port $port already in use"
    else
        success "Port $port available"
    fi
done
echo ""

# Summary
echo "======================================"
echo "  Configuration Test Complete        "
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Review any warnings above"
echo "  2. Run ./deploy-all.sh to deploy services"
echo "  3. Or deploy individually:"
echo "     cd headscale && docker compose up -d"
echo "     cd keycloak && docker compose up -d"
echo "     cd vllm && docker compose up -d"
echo "     cd espocrm && docker compose up -d"
echo ""
