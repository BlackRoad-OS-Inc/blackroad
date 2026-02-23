#!/bin/bash
# SALESFORCE CI AUTH SETUP
# Generates SFDX auth URL for headless CI (no browser needed after first run)
# Run once locally: ./setup-sf-auth.sh
# Then secrets are stored in GitHub + Pi vault forever

set -euo pipefail
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log()  { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

VAULT_DIR="$HOME/.blackroad/vault"
mkdir -p "$VAULT_DIR"

check_sf_cli() {
  if ! which sf &>/dev/null && ! which sfdx &>/dev/null; then
    info "Installing Salesforce CLI..."
    npm install -g @salesforce/cli
  fi
  SF_CMD=$(which sf 2>/dev/null || which sfdx)
  log "SF CLI: $($SF_CMD --version | head -1)"
}

login_interactive() {
  local alias="${1:-sandbox}"
  local instance="${2:-https://test.salesforce.com}"
  info "Opening Salesforce browser login for: $alias ($instance)"
  info "After login, auth URL will be captured and stored"
  
  $SF_CMD org login web \
    --instance-url "$instance" \
    --alias "$alias" \
    --set-default 2>&1
  log "Logged in as: $alias"
}

export_auth_url() {
  local alias="${1:-sandbox}"
  local secret_name="${2:-SF_AUTH_URL_SANDBOX}"
  
  info "Exporting auth URL for: $alias"
  local auth_url
  auth_url=$(sf org display --target-org "$alias" --verbose --json 2>/dev/null | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['result']['sfdxAuthUrl'])" 2>/dev/null || \
    sfdx force:org:display --target-org "$alias" --verbose --json 2>/dev/null | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['result']['sfdxAuthUrl'])" 2>/dev/null)
  
  if [[ -z "$auth_url" ]]; then
    warn "Could not get sfdxAuthUrl. Try: sf org display --target-org $alias --verbose"
    return 1
  fi
  
  # Store in local vault
  echo "$auth_url" > "$VAULT_DIR/sf-auth-${alias}.txt"
  chmod 600 "$VAULT_DIR/sf-auth-${alias}.txt"
  log "Auth URL saved: $VAULT_DIR/sf-auth-${alias}.txt"
  
  # Store as GitHub secret
  if which gh &>/dev/null; then
    echo "$auth_url" | gh secret set "$secret_name" \
      --repo BlackRoad-OS-Inc/blackroad 2>/dev/null && \
      log "GitHub secret set: $secret_name" || \
      warn "Could not set GitHub secret (check gh auth)"
  fi
  
  # Store on alice Pi
  if ssh -o ConnectTimeout=5 alice "echo ok" &>/dev/null; then
    echo "$auth_url" | ssh alice "
      mkdir -p ~/.blackroad/vault
      cat > ~/.blackroad/vault/sf-auth-${alias}.txt
      chmod 600 ~/.blackroad/vault/sf-auth-${alias}.txt
      echo 'saved on alice'
    " && log "Auth URL stored on alice Pi"
  fi
  
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}  SECRET: $secret_name${NC}"
  echo -e "${GREEN}  VAULT:  $VAULT_DIR/sf-auth-${alias}.txt${NC}"
  echo -e "${GREEN}  ALICE:  ~/.blackroad/vault/sf-auth-${alias}.txt${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

setup_jwt() {
  local alias="${1:-sandbox}"
  local consumer_key="${2:?Need consumer key from Connected App}"
  local username="${3:?Need SF username}"
  local jwt_key="${VAULT_DIR}/sf-jwt-server.key"
  local cert="${VAULT_DIR}/sf-jwt-server.crt"
  
  if [[ ! -f "$jwt_key" ]]; then
    info "Generating JWT key pair..."
    openssl genrsa -out "$jwt_key" 2048
    openssl req -x509 -new -nodes -key "$jwt_key" \
      -sha256 -days 3650 -out "$cert" \
      -subj "/C=US/ST=MN/O=BlackRoad OS Inc/CN=blackroad-ci"
    chmod 600 "$jwt_key"
    log "JWT key pair generated"
    echo ""
    warn "Upload $cert to your Salesforce Connected App"
    echo "Connected App → Edit → Use Digital Signatures → Upload $cert"
    echo ""
  fi
  
  # Store private key as GitHub secret
  if which gh &>/dev/null; then
    gh secret set SF_JWT_PRIVATE_KEY < "$jwt_key" \
      --repo BlackRoad-OS-Inc/blackroad 2>/dev/null && \
      log "GitHub secret set: SF_JWT_PRIVATE_KEY"
    echo "$consumer_key" | gh secret set SF_CONSUMER_KEY \
      --repo BlackRoad-OS-Inc/blackroad 2>/dev/null && \
      log "GitHub secret set: SF_CONSUMER_KEY"
    echo "$username" | gh secret set SF_USERNAME \
      --repo BlackRoad-OS-Inc/blackroad 2>/dev/null && \
      log "GitHub secret set: SF_USERNAME"
  fi
  
  # Test JWT auth
  info "Testing JWT auth..."
  sf org login jwt \
    --instance-url "https://test.salesforce.com" \
    --client-id "$consumer_key" \
    --jwt-key-file "$jwt_key" \
    --username "$username" \
    --alias "$alias" 2>&1 && log "JWT auth successful!" || warn "JWT auth test failed"
}

case "${1:-help}" in
  login)    check_sf_cli; login_interactive "${2:-sandbox}" "${3:-https://test.salesforce.com}" ;;
  export)   check_sf_cli; export_auth_url "${2:-sandbox}" "${3:-SF_AUTH_URL_SANDBOX}" ;;
  jwt)      setup_jwt "${2:-sandbox}" "${3:?consumer_key}" "${4:?username}" ;;
  setup)    # Full interactive setup
    check_sf_cli
    echo ""
    info "Step 1: Login to sandbox"
    login_interactive "sandbox" "https://test.salesforce.com"
    export_auth_url "sandbox" "SF_AUTH_URL_SANDBOX"
    echo ""
    info "Step 2: Login to production (optional)"
    read -rp "Setup production org too? (y/N): " setup_prod
    if [[ "${setup_prod:-n}" == "y" ]]; then
      login_interactive "production" "https://login.salesforce.com"
      export_auth_url "production" "SF_AUTH_URL_PRODUCTION"
    fi
    log "Salesforce CI auth setup complete!"
    ;;
  *)
    echo "Usage: $0 [login|export|jwt|setup] [args]"
    echo "  setup              - Interactive full setup (login + export)"
    echo "  login [alias] [url]- Browser login"
    echo "  export [alias] [secret] - Export auth URL to GitHub secrets"
    echo "  jwt [alias] [key] [user] - JWT Connected App auth"
    ;;
esac
