#!/bin/bash
# BlackRoad Universal Deployment System
# Works with Cloudflare Pages, Tunnels, and Direct IP deployments
# No DNS API permissions required!

set -e

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ARIA64_IP="192.168.4.64"
ARIA64_USER="pi"
TUNNEL_ID="72f1d60c-dcf2-4499-b02d-d7a063018b33"
CF_ACCOUNT_ID="848cf0b18d51e0170e0d1537aec3505a"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
BlackRoad Universal Deployment System v${VERSION}

USAGE:
    ./blackroad-deploy-system.sh <command> [options]

COMMANDS:
    pages <domain> <project-dir>    Deploy to Cloudflare Pages
    docker <domain> <project-dir>   Deploy to aria64 with Docker
    tunnel <domain> <port>          Route domain through Cloudflare Tunnel
    status <domain>                 Check deployment status
    list                           List all deployments
    help                           Show this help message

EXAMPLES:
    # Deploy new site to Cloudflare Pages
    ./blackroad-deploy-system.sh pages myapp.blackroad.io ~/projects/myapp

    # Deploy to aria64 Docker
    ./blackroad-deploy-system.sh docker api.blackroad.io ~/projects/api

    # Route existing port through tunnel
    ./blackroad-deploy-system.sh tunnel newsite.blackroad.io 3060

    # Check if domain is accessible
    ./blackroad-deploy-system.sh status lucidia.earth

DEPLOYMENT METHODS:

1. CLOUDFLARE PAGES (Recommended for static sites)
   - Automatic builds from GitHub
   - Free SSL, CDN, unlimited bandwidth
   - No DNS configuration needed
   - Works: Next.js, React, Vue, static HTML

2. DOCKER ON ARIA64 (For custom backends)
   - Full control, any tech stack
   - Deployed to Raspberry Pi
   - Routed via Cloudflare Tunnel
   - Free SSL through Cloudflare

3. CLOUDFLARE TUNNEL (For existing services)
   - Route any local port to public domain
   - No port forwarding needed
   - Automatic DNS configuration
   - Works with current permissions

EOF
}

deploy_to_pages() {
    local domain="$1"
    local project_dir="$2"

    if [[ -z "$domain" ]] || [[ -z "$project_dir" ]]; then
        log_error "Usage: pages <domain> <project-dir>"
        exit 1
    fi

    log_info "Deploying $domain to Cloudflare Pages from $project_dir"

    # Extract project name from domain
    local project_name="${domain//./-}"

    cd "$project_dir"

    # Check if it's a git repo
    if [[ ! -d .git ]]; then
        log_warning "Not a git repository. Initializing..."
        git init
        git add .
        git commit -m "Initial commit for Pages deployment"
    fi

    # Create GitHub repo if needed
    log_info "Checking GitHub repository..."
    if ! gh repo view BlackRoad-OS/"$project_name" &>/dev/null; then
        log_info "Creating GitHub repository: BlackRoad-OS/$project_name"
        gh repo create BlackRoad-OS/"$project_name" --public --source=. --remote=origin --push
    else
        log_info "GitHub repository exists, pushing updates..."
        git push origin main 2>/dev/null || git push origin master 2>/dev/null || true
    fi

    # Deploy to Pages
    log_info "Deploying to Cloudflare Pages..."
    wrangler pages deploy . --project-name="$project_name" --branch=main

    # Get the Pages URL
    local pages_url="${project_name}.pages.dev"

    log_success "Deployed to Cloudflare Pages!"
    log_info "Pages URL: https://$pages_url"
    log_info "Custom domain: $domain"

    # Add custom domain
    log_info "Adding custom domain $domain..."
    wrangler pages domain add "$domain" --project-name="$project_name" || {
        log_warning "Could not automatically add custom domain"
        log_info "Manual step: Go to Pages dashboard and add $domain as custom domain"
    }

    log_success "Deployment complete!"
    echo ""
    echo "Next steps:"
    echo "1. Visit https://$pages_url to verify deployment"
    echo "2. DNS will be automatically configured for $domain"
    echo "3. Wait 5-10 minutes for SSL certificate provisioning"
}

deploy_to_docker() {
    local domain="$1"
    local project_dir="$2"

    if [[ -z "$domain" ]] || [[ -z "$project_dir" ]]; then
        log_error "Usage: docker <domain> <project-dir>"
        exit 1
    fi

    log_info "Deploying $domain to aria64 Docker from $project_dir"

    # Extract container name from domain
    local container_name="${domain//./-}"

    # Find next available port
    local next_port=$(ssh ${ARIA64_USER}@${ARIA64_IP} "docker ps --format '{{.Ports}}' | grep -oP '0\.0\.0\.0:\K\d+' | sort -n | tail -1")
    next_port=$((next_port + 1))

    log_info "Assigning port: $next_port"

    cd "$project_dir"

    # Ensure Dockerfile exists
    if [[ ! -f Dockerfile ]]; then
        log_error "No Dockerfile found in $project_dir"
        log_info "Creating a basic Next.js Dockerfile..."
        cat > Dockerfile << 'DOCKERFILE_END'
FROM node:20-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile

FROM node:20-alpine AS builder
WORKDIR /app
RUN npm install -g pnpm
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
RUN mkdir .next && chown nextjs:nodejs .next
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
DOCKERFILE_END
    fi

    # Check if it's a git repo and push
    if [[ ! -d .git ]]; then
        git init
        git add .
        git commit -m "Initial commit for Docker deployment"
    fi

    if ! gh repo view BlackRoad-OS/"$container_name" &>/dev/null; then
        gh repo create BlackRoad-OS/"$container_name" --public --source=. --remote=origin --push
    else
        git push origin main 2>/dev/null || git push origin master 2>/dev/null || true
    fi

    # Deploy to aria64
    log_info "Cloning to aria64..."
    ssh ${ARIA64_USER}@${ARIA64_IP} "cd ~/blackroad && rm -rf $container_name && git clone https://github.com/BlackRoad-OS/$container_name.git"

    log_info "Building Docker image on aria64..."
    ssh ${ARIA64_USER}@${ARIA64_IP} "cd ~/blackroad/$container_name && docker build -t $container_name:latest ."

    log_info "Stopping old container (if exists)..."
    ssh ${ARIA64_USER}@${ARIA64_IP} "docker stop $container_name 2>/dev/null || true && docker rm $container_name 2>/dev/null || true"

    log_info "Starting new container on port $next_port..."
    ssh ${ARIA64_USER}@${ARIA64_IP} "docker run -d --name $container_name --restart unless-stopped -p $next_port:3000 $container_name:latest"

    # Add to Caddy
    log_info "Updating Caddy configuration..."
    ssh ${ARIA64_USER}@${ARIA64_IP} "docker exec caddy sh -c 'cat >> /etc/caddy/Caddyfile << EOF

# $domain
$domain {
    reverse_proxy localhost:$next_port
}
EOF
' && docker exec caddy caddy reload --config /etc/caddy/Caddyfile"

    # Add DNS via tunnel
    log_info "Configuring DNS via Cloudflare Tunnel..."
    cloudflared tunnel route dns "$TUNNEL_ID" "$domain"

    log_success "Deployment complete!"
    echo ""
    echo "Container: $container_name"
    echo "Port: $next_port"
    echo "Domain: https://$domain"
    echo ""
    echo "Wait 1-2 minutes for DNS propagation, then visit https://$domain"
}

route_through_tunnel() {
    local domain="$1"
    local port="$2"

    if [[ -z "$domain" ]] || [[ -z "$port" ]]; then
        log_error "Usage: tunnel <domain> <port>"
        exit 1
    fi

    log_info "Routing $domain through Cloudflare Tunnel to localhost:$port"

    # Add to Caddy if not already there
    log_info "Checking Caddy configuration..."
    if ! ssh ${ARIA64_USER}@${ARIA64_IP} "docker exec caddy grep -q '$domain' /etc/caddy/Caddyfile"; then
        log_info "Adding to Caddy..."
        ssh ${ARIA64_USER}@${ARIA64_IP} "docker exec caddy sh -c 'cat >> /etc/caddy/Caddyfile << EOF

# $domain
$domain {
    reverse_proxy localhost:$port
}
EOF
' && docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
    fi

    # Add DNS
    log_info "Configuring DNS..."
    cloudflared tunnel route dns "$TUNNEL_ID" "$domain"

    log_success "Route configured!"
    echo ""
    echo "Domain: https://$domain"
    echo "Backend: localhost:$port on aria64"
    echo ""
    echo "Wait 1-2 minutes for DNS propagation"
}

check_status() {
    local domain="$1"

    if [[ -z "$domain" ]]; then
        log_error "Usage: status <domain>"
        exit 1
    fi

    log_info "Checking status of $domain"
    echo ""

    # DNS check
    echo "DNS Resolution:"
    dig "$domain" @1.1.1.1 || echo "  No DNS records found"
    echo ""

    # HTTP check
    echo "HTTP Status:"
    local http_code=$(curl -sI -o /dev/null -w "%{http_code}" "https://$domain" 2>/dev/null || echo "000")
    if [[ "$http_code" == "200" ]]; then
        log_success "Site is UP (HTTP $http_code)"
    elif [[ "$http_code" == "000" ]]; then
        log_error "Site is DOWN (Cannot connect)"
    else
        log_warning "Site returned HTTP $http_code"
    fi
    echo ""

    # Docker check
    echo "Docker Container:"
    local container_name="${domain//./-}"
    if ssh ${ARIA64_USER}@${ARIA64_IP} "docker ps | grep -q $container_name"; then
        local port=$(ssh ${ARIA64_USER}@${ARIA64_IP} "docker ps | grep $container_name | grep -oP '0\.0\.0\.0:\K\d+'")
        log_success "Container running on port $port"
    else
        log_info "No Docker container found for $domain"
    fi
}

list_deployments() {
    log_info "BlackRoad Deployments"
    echo ""

    echo "=== Docker Containers on aria64 ==="
    ssh ${ARIA64_USER}@${ARIA64_IP} "docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}' | grep -E 'blackroad|lucidia|docs'"
    echo ""

    echo "=== Cloudflare Pages Projects ==="
    wrangler pages project list 2>/dev/null || echo "No Pages projects found or not logged in"
    echo ""

    echo "=== Cloudflare Tunnel Routes ==="
    cloudflared tunnel route dns "$TUNNEL_ID" 2>&1 | tail -20 || echo "Could not fetch tunnel routes"
}

# Main script
case "${1:-help}" in
    pages)
        deploy_to_pages "$2" "$3"
        ;;
    docker)
        deploy_to_docker "$2" "$3"
        ;;
    tunnel)
        route_through_tunnel "$2" "$3"
        ;;
    status)
        check_status "$2"
        ;;
    list)
        list_deployments
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
