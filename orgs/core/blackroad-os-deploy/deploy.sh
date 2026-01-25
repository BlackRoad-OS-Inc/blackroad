#!/bin/bash
# BlackRoad Deploy - Railway-like deployment system for Pis and Shellfish
# Usage: ./deploy.sh <app-path> <target> [app-name]

set -e

APP_PATH="${1:-.}"
TARGET="${2:-aria64}"
APP_NAME="${3:-$(basename $(realpath $APP_PATH))}"
DEPLOY_USER="pi"
DEPLOY_HOST=""

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Determine target host
case "$TARGET" in
    aria64|aria|pi)
        DEPLOY_HOST="aria64"
        DEPLOY_USER="pi"
        ;;
    shellfish|sf|droplet)
        DEPLOY_HOST="shellfish"
        DEPLOY_USER="root"
        ;;
    alice)
        DEPLOY_HOST="alice"
        DEPLOY_USER="alice"
        ;;
    lucidia)
        DEPLOY_HOST="lucidia"
        DEPLOY_USER="lucidia"
        ;;
    *)
        log_error "Unknown target: $TARGET"
        echo "Available targets: aria64, shellfish, alice, lucidia"
        exit 1
        ;;
esac

log_info "🚀 BlackRoad Deploy"
log_info "App: $APP_NAME"
log_info "Path: $APP_PATH"
log_info "Target: $DEPLOY_HOST ($DEPLOY_USER)"
echo ""

cd "$APP_PATH"

# Detect app type
detect_app_type() {
    if [ -f "package.json" ]; then
        echo "nodejs"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
        echo "python"
    elif [ -f "go.mod" ]; then
        echo "go"
    elif [ -f "Cargo.toml" ]; then
        echo "rust"
    elif [ -f "Dockerfile" ]; then
        echo "docker"
    else
        echo "unknown"
    fi
}

APP_TYPE=$(detect_app_type)
log_info "Detected app type: $APP_TYPE"

# Generate Dockerfile based on app type
generate_dockerfile() {
    local app_type=$1

    case "$app_type" in
        nodejs)
            cat > Dockerfile << 'EOF'
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE ${PORT:-3000}
CMD ["npm", "start"]
EOF
            ;;
        python)
            cat > Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt* pyproject.toml* poetry.lock* ./
RUN if [ -f requirements.txt ]; then pip install -r requirements.txt; \
    elif [ -f pyproject.toml ]; then pip install poetry && poetry install --no-dev; fi
COPY . .
EXPOSE ${PORT:-8000}
CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "${PORT:-8000}"]
EOF
            ;;
        go)
            cat > Dockerfile << 'EOF'
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/main .

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE ${PORT:-8080}
CMD ["./main"]
EOF
            ;;
        rust)
            cat > Dockerfile << 'EOF'
FROM rust:1.75-slim AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
WORKDIR /app
COPY --from=builder /app/target/release/* ./
EXPOSE ${PORT:-8080}
CMD ["./main"]
EOF
            ;;
        docker)
            log_info "Using existing Dockerfile"
            ;;
        *)
            log_error "Unsupported app type: $app_type"
            exit 1
            ;;
    esac
}

# Generate Dockerfile if needed
if [ "$APP_TYPE" != "docker" ]; then
    log_info "Generating Dockerfile for $APP_TYPE app..."
    generate_dockerfile "$APP_TYPE"
    log_success "Dockerfile generated"
fi

# Build Docker image
IMAGE_NAME="blackroad/${APP_NAME}:latest"
log_info "Building Docker image: $IMAGE_NAME"

docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    log_error "Docker build failed"
    exit 1
fi

log_success "Image built successfully"

# Find available port on target
log_info "Finding available port on $DEPLOY_HOST..."
DEPLOY_PORT=$(ssh $DEPLOY_USER@$DEPLOY_HOST "python3 << 'PYEOF'
import socket
def find_free_port(start=3100, end=3200):
    for port in range(start, end):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('0.0.0.0', port))
                return port
        except OSError:
            continue
    return None
print(find_free_port())
PYEOF
")

if [ -z "$DEPLOY_PORT" ] || [ "$DEPLOY_PORT" == "None" ]; then
    log_error "No available ports on $DEPLOY_HOST"
    exit 1
fi

log_success "Allocated port: $DEPLOY_PORT"

# Save image and transfer to target
log_info "Transferring image to $DEPLOY_HOST..."
docker save "$IMAGE_NAME" | ssh $DEPLOY_USER@$DEPLOY_HOST "docker load"

if [ $? -ne 0 ]; then
    log_error "Image transfer failed"
    exit 1
fi

log_success "Image transferred"

# Deploy container
log_info "Deploying container..."
ssh $DEPLOY_USER@$DEPLOY_HOST << SSHEOF
    # Stop existing container if running
    docker stop $APP_NAME 2>/dev/null || true
    docker rm $APP_NAME 2>/dev/null || true

    # Run new container
    docker run -d \
        --name $APP_NAME \
        --restart unless-stopped \
        -p $DEPLOY_PORT:${PORT:-3000} \
        -e PORT=${PORT:-3000} \
        $IMAGE_NAME

    echo "Container started on port $DEPLOY_PORT"
SSHEOF

if [ $? -ne 0 ]; then
    log_error "Deployment failed"
    exit 1
fi

log_success "Deployment successful!"
echo ""
log_info "📦 App: $APP_NAME"
log_info "🖥  Host: $DEPLOY_HOST"
log_info "🔌 Port: $DEPLOY_PORT"
log_info "🔗 URL: http://$(ssh $DEPLOY_USER@$DEPLOY_HOST 'hostname -I | awk "{print \$1}"'):$DEPLOY_PORT"
echo ""
log_success "Deployment complete! 🎉"

# Clean up generated Dockerfile if it was auto-generated
if [ "$APP_TYPE" != "docker" ]; then
    rm -f Dockerfile
fi
