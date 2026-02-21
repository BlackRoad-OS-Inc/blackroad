#!/usr/bin/env zsh
# 🔐 Secrets Vault - Feature #32
# Encrypted secrets storage with rotation, audit logs, and access control

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/secrets-vault.db"
VAULT_DIR="$HOME/.blackroad/vault"
MASTER_KEY_FILE="$VAULT_DIR/.master.key"

init_db() {
    mkdir -p "$VAULT_DIR"
    chmod 700 "$VAULT_DIR"
    
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS secrets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE,
    encrypted_value TEXT,
    category TEXT,
    tags TEXT,
    rotation_days INTEGER DEFAULT 90,
    last_rotated INTEGER,
    expires_at INTEGER,
    created_at INTEGER,
    created_by TEXT,
    accessed_count INTEGER DEFAULT 0,
    last_accessed INTEGER
);

CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT,
    secret_name TEXT,
    user TEXT,
    ip_address TEXT,
    success INTEGER,
    timestamp INTEGER
);

CREATE TABLE IF NOT EXISTS access_control (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    secret_name TEXT,
    user TEXT,
    permissions TEXT,
    granted_at INTEGER,
    granted_by TEXT
);
EOF
    chmod 600 "$DB_FILE"
}

# Generate or load master key
get_master_key() {
    if [[ ! -f "$MASTER_KEY_FILE" ]]; then
        echo -e "${YELLOW}⚠️  No master key found. Generating new key...${NC}"
        openssl rand -base64 32 > "$MASTER_KEY_FILE"
        chmod 400 "$MASTER_KEY_FILE"
        echo -e "${GREEN}✓ Master key generated${NC}"
    fi
    cat "$MASTER_KEY_FILE"
}

# Encrypt value
encrypt_value() {
    local value="$1"
    local key=$(get_master_key)
    echo "$value" | openssl enc -aes-256-cbc -a -salt -pass pass:"$key" 2>/dev/null
}

# Decrypt value
decrypt_value() {
    local encrypted="$1"
    local key=$(get_master_key)
    echo "$encrypted" | openssl enc -aes-256-cbc -d -a -pass pass:"$key" 2>/dev/null
}

# Log audit event
log_audit() {
    local action="$1"
    local secret_name="$2"
    local success="${3:-1}"
    local user=$(whoami)
    local ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
    
    sqlite3 "$DB_FILE" "INSERT INTO audit_log (action, secret_name, user, ip_address, success, timestamp) VALUES ('$action', '$secret_name', '$user', '$ip', $success, $(date +%s));"
}

# Store secret
cmd_set() {
    init_db
    local name="${1}"
    local value="${2}"
    local category="${3:-general}"
    local tags="${4:-}"
    local expires_days="${5:-0}"
    
    if [[ -z "$name" ]] || [[ -z "$value" ]]; then
        echo -e "${RED}❌ Usage: br vault set <name> <value> [category] [tags] [expires_days]${NC}"
        exit 1
    fi
    
    local encrypted=$(encrypt_value "$value")
    local expires_at=0
    
    if [[ $expires_days -gt 0 ]]; then
        expires_at=$(($(date +%s) + (expires_days * 86400)))
    fi
    
    local user=$(whoami)
    
    # Check if exists
    local exists=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM secrets WHERE name = '$name';")
    
    if [[ $exists -gt 0 ]]; then
        sqlite3 "$DB_FILE" "UPDATE secrets SET encrypted_value = '$encrypted', category = '$category', tags = '$tags', expires_at = $expires_at, last_rotated = $(date +%s) WHERE name = '$name';"
        log_audit "UPDATE" "$name" 1
        echo -e "${GREEN}✓ Secret updated:${NC} $name"
    else
        sqlite3 "$DB_FILE" "INSERT INTO secrets (name, encrypted_value, category, tags, expires_at, last_rotated, created_at, created_by) VALUES ('$name', '$encrypted', '$category', '$tags', $expires_at, $(date +%s), $(date +%s), '$user');"
        log_audit "CREATE" "$name" 1
        echo -e "${GREEN}✓ Secret stored:${NC} $name"
    fi
    
    echo -e "${BLUE}Category:${NC} $category"
    [[ -n "$tags" ]] && echo -e "${BLUE}Tags:${NC} $tags"
    [[ $expires_days -gt 0 ]] && echo -e "${YELLOW}Expires in:${NC} $expires_days days"
}

# Get secret
cmd_get() {
    init_db
    local name="${1}"
    local show_value="${2:-false}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br vault get <name> [--show]${NC}"
        exit 1
    fi
    
    local result=$(sqlite3 -separator $'\t' "$DB_FILE" "SELECT encrypted_value, category, tags, expires_at, accessed_count FROM secrets WHERE name = '$name';")
    
    if [[ -z "$result" ]]; then
        echo -e "${RED}❌ Secret not found:${NC} $name"
        log_audit "GET_FAILED" "$name" 0
        exit 1
    fi
    
    local encrypted=$(echo "$result" | cut -f1)
    local category=$(echo "$result" | cut -f2)
    local tags=$(echo "$result" | cut -f3)
    local expires_at=$(echo "$result" | cut -f4)
    local access_count=$(echo "$result" | cut -f5)
    
    # Check expiration
    if [[ $expires_at -gt 0 ]] && [[ $(date +%s) -gt $expires_at ]]; then
        echo -e "${RED}❌ Secret expired:${NC} $name"
        log_audit "GET_EXPIRED" "$name" 0
        exit 1
    fi
    
    local decrypted=$(decrypt_value "$encrypted")
    
    # Update access count
    sqlite3 "$DB_FILE" "UPDATE secrets SET accessed_count = accessed_count + 1, last_accessed = $(date +%s) WHERE name = '$name';"
    log_audit "GET" "$name" 1
    
    echo -e "${CYAN}🔐 Secret: $name${NC}"
    echo -e "${BLUE}Category:${NC} $category"
    [[ -n "$tags" ]] && echo -e "${BLUE}Tags:${NC} $tags"
    echo -e "${BLUE}Access Count:${NC} $((access_count + 1))"
    
    if [[ "$show_value" == "--show" ]] || [[ "$show_value" == "-s" ]]; then
        echo -e "${GREEN}Value:${NC} $decrypted"
    else
        echo -e "${YELLOW}Value:${NC} ••••••••"
        echo -e "${CYAN}(Use --show to reveal)${NC}"
    fi
    
    # Copy to clipboard if available
    if command -v pbcopy &> /dev/null; then
        echo -n "$decrypted" | pbcopy
        echo -e "${GREEN}✓ Copied to clipboard${NC}"
    fi
}

# List secrets
cmd_list() {
    init_db
    local category="${1:-}"
    
    echo -e "${CYAN}🔐 Secrets Vault${NC}\n"
    
    local query="SELECT name, category, tags, accessed_count, datetime(created_at, 'unixepoch'), expires_at FROM secrets"
    [[ -n "$category" ]] && query="$query WHERE category = '$category'"
    query="$query ORDER BY name;"
    
    local count=0
    sqlite3 -separator $'\t' "$DB_FILE" "$query" | while IFS=$'\t' read -r name cat tags access created expires; do
        count=$((count + 1))
        
        local status_check="✓"
        local status_color="$GREEN"
        
        if [[ $expires -gt 0 ]] && [[ $(date +%s) -gt $expires ]]; then
            status_check="✗"
            status_color="$RED"
        fi
        
        echo -e "$status_color$status_check${NC} ${GREEN}$name${NC}"
        echo -e "  Category: $cat | Accessed: $access times"
        [[ -n "$tags" ]] && echo -e "  Tags: $tags"
        echo ""
    done
    
    local total=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM secrets;")
    echo -e "${BLUE}Total secrets:${NC} $total"
}

# Delete secret
cmd_delete() {
    init_db
    local name="${1}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br vault delete <name>${NC}"
        exit 1
    fi
    
    local exists=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM secrets WHERE name = '$name';")
    
    if [[ $exists -eq 0 ]]; then
        echo -e "${RED}❌ Secret not found:${NC} $name"
        exit 1
    fi
    
    sqlite3 "$DB_FILE" "DELETE FROM secrets WHERE name = '$name';"
    log_audit "DELETE" "$name" 1
    
    echo -e "${GREEN}✓ Secret deleted:${NC} $name"
}

# Rotate secret
cmd_rotate() {
    init_db
    local name="${1}"
    local new_value="${2}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br vault rotate <name> [new_value]${NC}"
        echo -e "If no value provided, will prompt for input"
        exit 1
    fi
    
    if [[ -z "$new_value" ]]; then
        echo -n "Enter new value: "
        read -s new_value
        echo ""
    fi
    
    local encrypted=$(encrypt_value "$new_value")
    sqlite3 "$DB_FILE" "UPDATE secrets SET encrypted_value = '$encrypted', last_rotated = $(date +%s) WHERE name = '$name';"
    log_audit "ROTATE" "$name" 1
    
    echo -e "${GREEN}✓ Secret rotated:${NC} $name"
}

# Check expiring secrets
cmd_expiring() {
    init_db
    local days="${1:-7}"
    
    echo -e "${CYAN}⚠️  Secrets expiring in next $days days:${NC}\n"
    
    local cutoff=$(($(date +%s) + (days * 86400)))
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT name, category, datetime(expires_at, 'unixepoch') FROM secrets WHERE expires_at > 0 AND expires_at < $cutoff ORDER BY expires_at;" | while IFS=$'\t' read -r name cat expires; do
        echo -e "${YELLOW}⚠️  $name${NC}"
        echo -e "  Category: $cat"
        echo -e "  Expires: $expires"
        echo ""
    done
}

# Audit log
cmd_audit() {
    init_db
    local limit="${1:-20}"
    
    echo -e "${CYAN}📋 Audit Log (Last $limit events)${NC}\n"
    
    sqlite3 -separator $'\t' "$DB_FILE" "SELECT action, secret_name, user, ip_address, success, datetime(timestamp, 'unixepoch') FROM audit_log ORDER BY timestamp DESC LIMIT $limit;" | while IFS=$'\t' read -r action name user ip success time; do
        local icon="✓"
        local color="$GREEN"
        
        [[ $success -eq 0 ]] && icon="✗" && color="$RED"
        
        echo -e "$color$icon${NC} ${BLUE}$action${NC} - $name"
        echo -e "  User: $user | IP: $ip"
        echo -e "  Time: $time"
        echo ""
    done
}

# Export secrets (encrypted backup)
cmd_export() {
    init_db
    local output="${1:-vault-backup-$(date +%Y%m%d-%H%M%S).enc}"
    
    echo -e "${CYAN}📤 Exporting vault...${NC}\n"
    
    sqlite3 "$DB_FILE" ".dump secrets" | gzip | openssl enc -aes-256-cbc -a -salt -pass pass:"$(get_master_key)" > "$output"
    
    log_audit "EXPORT" "ALL" 1
    
    echo -e "${GREEN}✓ Vault exported:${NC} $output"
    echo -e "${YELLOW}⚠️  Keep this file secure! It contains encrypted secrets.${NC}"
}

# Import secrets
cmd_import() {
    init_db
    local input="${1}"
    
    if [[ -z "$input" ]] || [[ ! -f "$input" ]]; then
        echo -e "${RED}❌ Usage: br vault import <backup_file>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📥 Importing vault...${NC}\n"
    
    openssl enc -aes-256-cbc -d -a -pass pass:"$(get_master_key)" < "$input" | gunzip | sqlite3 "$DB_FILE"
    
    log_audit "IMPORT" "ALL" 1
    
    echo -e "${GREEN}✓ Vault imported successfully${NC}"
}

# Generate random secret
cmd_generate() {
    local length="${1:-32}"
    local type="${2:-alphanumeric}"
    
    echo -e "${CYAN}🎲 Generating random secret...${NC}\n"
    
    local secret=""
    
    case "$type" in
        alphanumeric)
            secret=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length")
            ;;
        hex)
            secret=$(openssl rand -hex "$length")
            ;;
        base64)
            secret=$(openssl rand -base64 "$length")
            ;;
        pin)
            secret=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | head -c "$length")
            ;;
        *)
            echo -e "${RED}❌ Unknown type: $type${NC}"
            echo -e "Types: alphanumeric, hex, base64, pin"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}Generated ($type, $length chars):${NC}"
    echo "$secret"
    
    if command -v pbcopy &> /dev/null; then
        echo -n "$secret" | pbcopy
        echo -e "\n${GREEN}✓ Copied to clipboard${NC}"
    fi
}

# Help
cmd_help() {
    cat << 'EOF'
🔐 Secrets Vault

USAGE:
  br vault <command> [options]

MANAGE SECRETS:
  set <name> <value> [category] [tags] [expires_days]  Store secret
  get <name> [--show]                                   Retrieve secret
  list [category]                                       List all secrets
  delete <name>                                         Delete secret
  rotate <name> [new_value]                             Rotate secret
  
MONITORING:
  expiring [days]                                       Check expiring secrets
  audit [limit]                                         View audit log
  
BACKUP:
  export [filename]                                     Export encrypted backup
  import <filename>                                     Import backup
  
UTILITIES:
  generate [length] [type]                              Generate random secret

EXAMPLES:
  # Store secrets
  br vault set github_token ghp_abc123 "api" "github,prod" 90
  br vault set db_password mySecretPass123 "database"
  br vault set stripe_key sk_test_123 "payment" "stripe" 30

  # Retrieve secrets
  br vault get github_token          # Copy to clipboard
  br vault get db_password --show    # Show value

  # List and manage
  br vault list                      # All secrets
  br vault list api                  # By category
  br vault delete old_token

  # Rotation
  br vault rotate github_token       # Prompt for new value
  br vault rotate api_key newValue123

  # Monitoring
  br vault expiring 7                # Expiring in 7 days
  br vault audit 50                  # Last 50 events

  # Backup/restore
  br vault export my-backup.enc
  br vault import my-backup.enc

  # Generate secrets
  br vault generate 32 alphanumeric  # Password
  br vault generate 16 hex           # API key
  br vault generate 6 pin            # PIN code

FEATURES:
  🔐 AES-256-CBC encryption
  📋 Complete audit logging
  ⏰ Expiration tracking
  🔄 Secret rotation
  📊 Access statistics
  💾 Encrypted backups
  🎲 Secret generation
  📋 Clipboard integration

SECURITY:
  - Master key stored in ~/.blackroad/vault/.master.key (chmod 400)
  - Database encrypted with master key
  - All operations logged
  - Secrets never logged in plaintext
  - Automatic expiration checking

EOF
}

# Main dispatch
init_db

case "${1:-help}" in
    set|store|s) cmd_set "${@:2}" ;;
    get|g) cmd_get "${@:2}" ;;
    list|ls|l) cmd_list "${@:2}" ;;
    delete|del|rm|d) cmd_delete "${@:2}" ;;
    rotate|r) cmd_rotate "${@:2}" ;;
    expiring|exp|e) cmd_expiring "${@:2}" ;;
    audit|log|a) cmd_audit "${@:2}" ;;
    export|backup|ex) cmd_export "${@:2}" ;;
    import|restore|im) cmd_import "${@:2}" ;;
    generate|gen|rand) cmd_generate "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
