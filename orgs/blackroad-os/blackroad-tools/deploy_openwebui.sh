#!/usr/bin/env bash
# FILE: /usr/local/bin/deploy_openwebui.sh
# BIN: deploy_openwebui.sh
# Purpose: Deploy Open WebUI behind NGINX with Ollama/OpenAI backends.
# Usage:
#   deploy_openwebui.sh [deploy|update|down|ps|logs|cert]
#     deploy (default): write files, reload NGINX, pull & up -d
#     update:           pull & up -d only
#     down:             stop stack
#     ps:               list containers
#     logs:             tail app logs
#     cert:             obtain/renew Let's Encrypt cert (needs ACME_EMAIL)

set -euo pipefail
IFS=$'\n\t'

# ──[ Configurable defaults via env ]─────────────────────────────────────────────
DOMAIN="${DOMAIN:-openwebui.blackroad.io}"
HOST_PORT="${HOST_PORT:-3000}"

# Backends
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://ollama:11434}"
OPENAI_API_BASE_URL="${OPENAI_API_BASE_URL:-https://api.openai.com/v1}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"

# Image pin (override to a tag or digest as desired)
OPENWEBUI_IMAGE="${OPENWEBUI_IMAGE:-ghcr.io/open-webui/open-webui:main}"

# OIDC / SSO (optional)
ENABLE_LOGIN_FORM="${ENABLE_LOGIN_FORM:-false}"      # hide local form when using SSO
OIDC_CLIENT_ID="${OIDC_CLIENT_ID:-}"
OIDC_CLIENT_SECRET="${OIDC_CLIENT_SECRET:-}"
OIDC_ISSUER="${OIDC_ISSUER:-}"                       # e.g., https://auth.example.com/realms/main
OAUTH_ALLOWED_DOMAINS="${OAUTH_ALLOWED_DOMAINS:-blackroad.io}"
ENABLE_OAUTH_ROLE_MANAGEMENT="${ENABLE_OAUTH_ROLE_MANAGEMENT:-true}"
OPENID_REDIRECT_URI="${OPENID_REDIRECT_URI:-https://${DOMAIN}/oauth/oidc/callback}"

# ACME email for `cert` subcommand
ACME_EMAIL="${ACME_EMAIL:-}"

# ──[ Paths ]────────────────────────────────────────────────────────────────────
APP_DIR="/opt/open-webui"
DC_DIR="$APP_DIR/docker"
DC_FILE="$DC_DIR/open-webui.yml"
ENV_FILE="$DC_DIR/open-webui.env"
NGINX_AVAIL="/etc/nginx/sites-available/openwebui.conf"
NGINX_ENABLED="/etc/nginx/sites-enabled/openwebui.conf"

# ──[ Helpers ]──────────────────────────────────────────────────────────────────
die(){ echo "ERROR: $*" >&2; exit 1; }
need_root(){ [ "${EUID:-$(id -u)}" -eq 0 ] || die "Run as root (sudo)."; }
has(){ command -v "$1" >/dev/null 2>&1; }
dc(){
  if docker compose version >/dev/null 2>&1; then docker compose "$@"
  elif has docker-compose; then docker-compose "$@"
  else die "Docker Compose not found (install Docker Compose plugin or docker-compose)."
  fi
}
reload_nginx(){
  if has nginx; then
    nginx -t
    systemctl reload nginx || systemctl restart nginx || true
  else
    echo "NGINX not installed; skipping reload."
  fi
}

# ──[ Write files ]──────────────────────────────────────────────────────────────
write_env(){
  mkdir -p "$DC_DIR"
  cat > "$ENV_FILE" <<EOF_ENV
# FILE: $ENV_FILE
DOMAIN=${DOMAIN}
HOST_PORT=${HOST_PORT}
OPENWEBUI_IMAGE=${OPENWEBUI_IMAGE}

OLLAMA_BASE_URL=${OLLAMA_BASE_URL}
OPENAI_API_BASE_URL=${OPENAI_API_BASE_URL}
OPENAI_API_KEY=${OPENAI_API_KEY}

ENABLE_LOGIN_FORM=${ENABLE_LOGIN_FORM}
OIDC_CLIENT_ID=${OIDC_CLIENT_ID}
OIDC_CLIENT_SECRET=${OIDC_CLIENT_SECRET}
OIDC_ISSUER=${OIDC_ISSUER}
OAUTH_ALLOWED_DOMAINS=${OAUTH_ALLOWED_DOMAINS}
ENABLE_OAUTH_ROLE_MANAGEMENT=${ENABLE_OAUTH_ROLE_MANAGEMENT}
OPENID_REDIRECT_URI=${OPENID_REDIRECT_URI}
EOF_ENV
}

write_compose(){
  cat > "$DC_FILE" <<'YAML'
# FILE: /opt/open-webui/docker/open-webui.yml
version: "3.8"

services:
  open-webui:
    image: ${OPENWEBUI_IMAGE}
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "${HOST_PORT}:8080"
    environment:
      WEBUI_URL: "https://${DOMAIN}"
      OLLAMA_BASE_URL: "${OLLAMA_BASE_URL}"
      OPENAI_API_BASE_URL: "${OPENAI_API_BASE_URL}"
      OPENAI_API_KEY: "${OPENAI_API_KEY}"

      # OIDC / OAuth
      ENABLE_LOGIN_FORM: "${ENABLE_LOGIN_FORM}"
      OAUTH_CLIENT_ID: "${OIDC_CLIENT_ID}"
      OAUTH_CLIENT_SECRET: "${OIDC_CLIENT_SECRET}"
      OPENID_PROVIDER_URL: "${OIDC_ISSUER}"
      OPENID_REDIRECT_URI: "${OPENID_REDIRECT_URI}"
      OAUTH_ALLOWED_DOMAINS: "${OAUTH_ALLOWED_DOMAINS}"
      ENABLE_OAUTH_ROLE_MANAGEMENT: "${ENABLE_OAUTH_ROLE_MANAGEMENT}"

    volumes:
      - open-webui-data:/app/backend/data
    networks:
      - lucidia-network
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"

volumes:
  open-webui-data:

networks:
  lucidia-network:
    external: true
YAML
}

write_nginx(){
  mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
  cat > "$NGINX_AVAIL" <<EOF_NGX
# FILE: $NGINX_AVAIL
# Open WebUI reverse-proxy
server {
  listen 80;
  server_name ${DOMAIN};

  # ACME (allow HTTP-01)
  location ^~ /.well-known/acme-challenge/ {
    root /var/www/html;
    default_type "text/plain";
  }

  # If certs exist, hand off to 443
  if (-d /etc/letsencrypt/live/${DOMAIN}) {
    return 301 https://\$host\$request_uri;
  }

  location / {
    proxy_pass http://127.0.0.1:${HOST_PORT};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_buffering off;
    client_max_body_size 20M;
    proxy_read_timeout 10m;
  }
}
EOF_NGX

  if [ -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
    cat >> "$NGINX_AVAIL" <<EOF_SSL

server {
  listen 443 ssl http2;
  server_name ${DOMAIN};

  ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

  # Security headers (tweak if you add strict CSP)
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header Referrer-Policy "same-origin" always;

  location / {
    proxy_pass http://127.0.0.1:${HOST_PORT};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_buffering off;
    client_max_body_size 20M;
    proxy_read_timeout 10m;
  }
}
EOF_SSL
  fi

  ln -sf "$NGINX_AVAIL" "$NGINX_ENABLED"
}

preflight(){
  need_root
  has docker || die "Docker is required."
  docker network inspect lucidia-network >/dev/null 2>&1 || docker network create lucidia-network
}

deploy_stack(){
  preflight
  write_env
  write_compose
  write_nginx
  reload_nginx
  dc --env-file "$ENV_FILE" -f "$DC_FILE" pull
  dc --env-file "$ENV_FILE" -f "$DC_FILE" up -d
  echo
  echo "✔ Open WebUI is up on http://${DOMAIN} (and https://${DOMAIN} if certs exist)."
  echo "  - Proxy -> ${HOST_PORT}"
  echo "  - Data volume: open-webui-data"
  echo "  - To change secrets: edit ${ENV_FILE} then run:  docker compose --env-file \"$ENV_FILE\" -f \"$DC_FILE\" up -d"
}

issue_cert(){
  [ -n "$ACME_EMAIL" ] || die "Set ACME_EMAIL for cert issuance."
  has certbot || die "certbot not installed (apt install certbot python3-certbot-nginx)."
  preflight
  # Ensure HTTP server block exists before issuance
  write_nginx
  reload_nginx
  certbot --nginx -d "$DOMAIN" -m "$ACME_EMAIL" --agree-tos --non-interactive --redirect
  # Re-render to include 443 block & reload
  write_nginx
  reload_nginx
  echo "✔ Certificates installed for ${DOMAIN}."
}

# ──[ Main ]─────────────────────────────────────────────────────────────────────
action="${1:-deploy}"
case "$action" in
  deploy) deploy_stack ;;
  update) dc --env-file "$ENV_FILE" -f "$DC_FILE" pull && dc --env-file "$ENV_FILE" -f "$DC_FILE" up -d ;;
  down)   dc --env-file "$ENV_FILE" -f "$DC_FILE" down ;;
  ps)     dc --env-file "$ENV_FILE" -f "$DC_FILE" ps ;;
  logs)   dc --env-file "$ENV_FILE" -f "$DC_FILE" logs -f --tail=100 open-webui ;;
  cert)   issue_cert ;;
  *)      echo "Usage: $0 [deploy|update|down|ps|logs|cert]"; exit 2;;
esac
