#!/usr/bin/env bash
# BLACKROAD MASTER DEPLOYMENT SCRIPT
# Deploys all infrastructure across Cloudflare, Raspberry Pis, and Cloud VPS
# Owner: Alexa Louise Amundson
# Last Updated: 2025-12-22

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis
ROCKET="🚀"
PACKAGE="📦"
ZAP="⚡"
PI="🥧"
CLOUD="☁️"
CHECK="✅"
CROSS="❌"

echo -e "${PURPLE}${ROCKET} BLACKROAD MASTER DEPLOYMENT${NC}"
echo "================================"
echo "Started: $(date)"
echo ""

# ─────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────

log_success() {
  echo -e "${GREEN}${CHECK} $1${NC}"
}

log_error() {
  echo -e "${RED}${CROSS} $1${NC}"
}

log_info() {
  echo -e "${CYAN}$1${NC}"
}

log_section() {
  echo ""
  echo -e "${YELLOW}─────────────────────────────────────────────────────${NC}"
  echo -e "${YELLOW}$1${NC}"
  echo -e "${YELLOW}─────────────────────────────────────────────────────${NC}"
}

# ─────────────────────────────────────────────────────
# Frontend Deployments (Cloudflare Pages)
# ─────────────────────────────────────────────────────

deploy_frontend() {
  local project=$1
  local path=$2

  if [ ! -d "$path" ]; then
    log_error "Directory not found: $path"
    return 1
  fi

  log_info "${PACKAGE} Deploying $project..."

  cd "$path"

  # Install dependencies
  if [ -f "package.json" ]; then
    npm install --silent > /dev/null 2>&1 || {
      log_error "npm install failed for $project"
      return 1
    }
  fi

  # Build
  if grep -q '"build"' package.json 2>/dev/null; then
    npm run build > /dev/null 2>&1 || {
      log_error "Build failed for $project"
      return 1
    }
  fi

  # Deploy
  wrangler pages deploy dist --project-name="$project" > /dev/null 2>&1 || {
    log_error "Deployment failed for $project"
    return 1
  }

  log_success "Deployed $project → https://$project.pages.dev"
}

# ─────────────────────────────────────────────────────
# Worker Deployments
# ─────────────────────────────────────────────────────

deploy_worker() {
  local name=$1
  local path=$2

  if [ ! -d "$path" ]; then
    log_error "Directory not found: $path"
    return 1
  fi

  log_info "${ZAP} Deploying worker: $name..."

  cd "$path"

  wrangler deploy > /dev/null 2>&1 || {
    log_error "Worker deployment failed for $name"
    return 1
  }

  log_success "Deployed worker: $name"
}

# ─────────────────────────────────────────────────────
# Backend Deployments (Raspberry Pi)
# ─────────────────────────────────────────────────────

deploy_pi_backend() {
  local name=$1
  local host=$2
  local path=$3

  log_info "${PI} Deploying to $name ($host)..."

  # Test SSH connectivity
  if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "pi@$host" exit 2>/dev/null; then
    log_error "Cannot connect to $name ($host)"
    return 1
  fi

  ssh "pi@$host" << EOF
    set -e
    cd $path || exit 1
    git pull origin main > /dev/null 2>&1 || exit 1
    docker-compose pull > /dev/null 2>&1 || exit 1
    docker-compose up -d --build > /dev/null 2>&1 || exit 1
EOF

  if [ $? -eq 0 ]; then
    log_success "Deployed to $name"
  else
    log_error "Deployment to $name failed"
    return 1
  fi
}

# ─────────────────────────────────────────────────────
# Cloud VPS Deployments
# ─────────────────────────────────────────────────────

deploy_vps() {
  local name=$1
  local host=$2
  local path=$3

  log_info "${CLOUD} Deploying to $name ($host)..."

  # Test SSH connectivity
  if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "root@$host" exit 2>/dev/null; then
    log_error "Cannot connect to $name ($host)"
    return 1
  fi

  ssh "root@$host" << EOF
    set -e
    cd $path || exit 1
    git pull origin main > /dev/null 2>&1 || exit 1
    docker-compose up -d --build > /dev/null 2>&1 || exit 1
EOF

  if [ $? -eq 0 ]; then
    log_success "Deployed to $name"
  else
    log_error "Deployment to $name failed"
    return 1
  fi
}

# ─────────────────────────────────────────────────────
# DEPLOYMENT EXECUTION
# ─────────────────────────────────────────────────────

DEPLOY_FRONTENDS=${DEPLOY_FRONTENDS:-true}
DEPLOY_WORKERS=${DEPLOY_WORKERS:-true}
DEPLOY_PI=${DEPLOY_PI:-true}
DEPLOY_VPS=${DEPLOY_VPS:-true}

# Frontend Deployments
if [ "$DEPLOY_FRONTENDS" = true ]; then
  log_section "${PACKAGE} CLOUDFLARE PAGES DEPLOYMENTS"

  deploy_frontend "lucidia-earth" ~/lucidia-metaverse
  deploy_frontend "blackroad-io" ~/blackroad-io
  deploy_frontend "blackroad-os-web" ~/blackroad-os-web
  deploy_frontend "roadworld" ~/roadworld
fi

# Worker Deployments
if [ "$DEPLOY_WORKERS" = true ]; then
  log_section "${ZAP} CLOUDFLARE WORKERS DEPLOYMENTS"

  deploy_worker "lucidia-earth-router" ~/lucidia-earth-router
  deploy_worker "blackroad-landing-worker" ~/blackroad-landing-worker
fi

# Raspberry Pi Deployments
if [ "$DEPLOY_PI" = true ]; then
  log_section "${PI} RASPBERRY PI DEPLOYMENTS"

  deploy_pi_backend "lucidia-pi" "192.168.4.38" "~/lucidia-backend"
  deploy_pi_backend "blackroad-pi" "192.168.4.64" "~/blackroad-services"
fi

# Cloud VPS Deployments
if [ "$DEPLOY_VPS" = true ]; then
  log_section "${CLOUD} CLOUD VPS DEPLOYMENTS"

  deploy_vps "codex-infinity" "159.65.43.12" "/opt/blackroad-api"
fi

# ─────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────

echo ""
log_section "${CHECK} DEPLOYMENT COMPLETE"
echo "Finished: $(date)"
echo ""
echo "Access your deployments:"
echo "  ${CYAN}Lucidia Metaverse:${NC} https://lucidia.earth"
echo "  ${CYAN}BlackRoad Main:${NC} https://blackroad.io"
echo "  ${CYAN}Quantum Platform:${NC} https://blackroadqi.com"
echo "  ${CYAN}RoadWorld:${NC} https://roadworld.pages.dev"
echo ""
