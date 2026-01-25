#!/bin/bash
# Test the BlackRoad Deploy system

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }

echo "🧪 Testing BlackRoad Deploy System"
echo ""

# Test 1: Check if scripts exist
log_info "Checking files..."
if [ -f ~/blackroad-deploy/br-deploy ]; then
    log_success "br-deploy exists"
else
    echo "✗ br-deploy missing"
    exit 1
fi

if [ -f ~/blackroad-deploy/scripts/dns-manager.sh ]; then
    log_success "dns-manager.sh exists"
else
    echo "✗ dns-manager.sh missing"
    exit 1
fi

if [ -f ~/blackroad-deploy/scripts/webhook-server.py ]; then
    log_success "webhook-server.py exists"
else
    echo "✗ webhook-server.py missing"
    exit 1
fi

# Test 2: Check Dockerfiles
log_info "Checking Dockerfiles..."
for lang in nodejs python go rust; do
    if [ -f ~/blackroad-deploy/dockerfiles/Dockerfile.$lang ]; then
        log_success "Dockerfile.$lang exists"
    else
        echo "✗ Dockerfile.$lang missing"
        exit 1
    fi
done

# Test 3: Check connectivity to targets
log_info "Testing connectivity..."
if ssh aria64 "echo 'Connected to aria64'" 2>/dev/null; then
    log_success "aria64 reachable"
else
    echo "⚠ aria64 not reachable"
fi

if ssh shellfish "echo 'Connected to shellfish'" 2>/dev/null; then
    log_success "shellfish reachable"
else
    echo "⚠ shellfish not reachable"
fi

# Test 4: Test help command
log_info "Testing br-deploy help..."
if ~/blackroad-deploy/br-deploy --help > /dev/null 2>&1; then
    log_success "br-deploy help works"
else
    echo "✗ br-deploy help failed"
    exit 1
fi

# Test 5: Test deployment list
log_info "Testing deployment list..."
if ~/blackroad-deploy/br-deploy list aria64 2>/dev/null; then
    log_success "br-deploy list works"
else
    echo "⚠ br-deploy list needs troubleshooting"
fi

echo ""
log_success "All basic tests passed! 🎉"
echo ""
echo "Next steps:"
echo "  1. Deploy a test app: ./br-deploy deploy <path> aria64"
echo "  2. Set up DNS: ./scripts/dns-manager.sh set test.blackroad.io aria64"
echo "  3. Configure webhooks: ./scripts/webhook-manager.sh add <repo> aria64"
