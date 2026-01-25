#!/usr/bin/env bash

# BlackRoad Priority Stack Deployment Script
# Deploys: Headscale, Keycloak, vLLM, EspoCRM

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    success "Prerequisites check passed"
}

# Deploy Headscale
deploy_headscale() {
    info "Deploying Headscale (Mesh VPN)..."

    cd "$SCRIPT_DIR/headscale"

    # Create directories
    mkdir -p config data

    # Start services
    docker compose up -d

    success "Headscale deployed"
    info "Headscale UI: http://localhost:8081"
    info "Headscale API: http://localhost:8080"

    cd "$SCRIPT_DIR"
}

# Deploy Keycloak
deploy_keycloak() {
    info "Deploying Keycloak (Identity Provider)..."

    cd "$SCRIPT_DIR/keycloak"

    # Create directories
    mkdir -p themes realm-export

    # Start services
    docker compose up -d

    success "Keycloak deployed"
    info "Keycloak Admin: http://localhost:8082"
    info "Username: admin"
    info "Password: Check .env file"

    cd "$SCRIPT_DIR"
}

# Deploy vLLM
deploy_vllm() {
    info "Deploying vLLM (Local AI Inference)..."

    cd "$SCRIPT_DIR/vllm"

    # Check if running on device with GPU
    if command -v nvidia-smi &> /dev/null; then
        info "GPU detected, deploying GPU-accelerated vLLM..."
        docker compose up -d vllm-qwen
        success "vLLM (Qwen2.5-7B) deployed on GPU"
        info "vLLM API: http://localhost:8083/v1/chat/completions"
    else
        warning "No GPU detected, deploying CPU-only fallback..."
        docker compose --profile cpu-fallback up -d vllm-phi
        success "vLLM (Phi-2) deployed on CPU"
        info "vLLM API: http://localhost:8084/v1/chat/completions"
    fi

    cd "$SCRIPT_DIR"
}

# Deploy EspoCRM
deploy_espocrm() {
    info "Deploying EspoCRM (Customer Relationship Management)..."

    cd "$SCRIPT_DIR/espocrm"

    # Start services
    docker compose up -d

    success "EspoCRM deployed"
    info "EspoCRM: http://localhost:8085"
    info "Username: admin"
    info "Password: Check .env file"

    cd "$SCRIPT_DIR"
}

# Show deployment summary
show_summary() {
    echo ""
    echo "======================================"
    echo "  BlackRoad Priority Stack Deployed  "
    echo "======================================"
    echo ""
    echo "Services:"
    echo "  • Headscale (Mesh VPN)"
    echo "    - UI:  http://localhost:8081"
    echo "    - API: http://localhost:8080"
    echo ""
    echo "  • Keycloak (Identity)"
    echo "    - Admin: http://localhost:8082"
    echo "    - User:  admin"
    echo ""
    echo "  • vLLM (AI Inference)"
    echo "    - API: http://localhost:8083/v1"
    echo "    - Model: qwen2.5:7b"
    echo ""
    echo "  • EspoCRM (CRM)"
    echo "    - App: http://localhost:8085"
    echo "    - User: admin"
    echo ""
    echo "Next Steps:"
    echo "  1. Configure Cloudflare Tunnels for public access"
    echo "  2. Set up Keycloak realms and clients"
    echo "  3. Configure Headscale namespaces"
    echo "  4. Customize EspoCRM for your business"
    echo ""
    echo "Documentation:"
    echo "  ~/Desktop/BLACKROAD_FORKIES_CANONICAL_STACK.md"
    echo ""
    echo "======================================"
}

# Main deployment flow
main() {
    info "Starting BlackRoad Priority Stack deployment..."
    echo ""

    check_prerequisites
    echo ""

    # Ask which services to deploy
    read -p "Deploy Headscale? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_headscale
        echo ""
    fi

    read -p "Deploy Keycloak? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_keycloak
        echo ""
    fi

    read -p "Deploy vLLM? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_vllm
        echo ""
    fi

    read -p "Deploy EspoCRM? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_espocrm
        echo ""
    fi

    show_summary
}

# Run main function
main "$@"
