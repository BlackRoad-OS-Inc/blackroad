#!/usr/bin/env zsh

# Colors
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
NC='\033[0m'

DB_FILE="$HOME/.blackroad/digitalocean.db"
CONFIG_FILE="$HOME/.blackroad/digitalocean.conf"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS droplets (
    id INTEGER PRIMARY KEY,
    name TEXT,
    region TEXT,
    size TEXT,
    ip_address TEXT,
    status TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS snapshots (
    id INTEGER PRIMARY KEY,
    droplet_id INTEGER,
    name TEXT,
    created_at INTEGER
);
EOF
}

check_auth() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Not configured${NC}"
        echo "Run: br ocean auth <api-token>"
        echo ""
        echo "Get token from: https://cloud.digitalocean.com/account/api/tokens"
        exit 1
    fi
    source "$CONFIG_FILE"
    if [[ -z "$DO_API_TOKEN" ]]; then
        echo -e "${RED}❌ API token not found${NC}"
        exit 1
    fi
}

do_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    check_auth
    
    local url="https://api.digitalocean.com/v2${endpoint}"
    
    if [[ -n "$data" ]]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $DO_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $DO_API_TOKEN"
    fi
}

cmd_auth() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        echo -e "${RED}❌ Usage: br ocean auth <api-token>${NC}"
        echo ""
        echo "Get your API token:"
        echo "1. Go to: https://cloud.digitalocean.com/account/api/tokens"
        echo "2. Generate New Token"
        echo "3. Copy token and run: br ocean auth <token>"
        exit 1
    fi
    
    echo -e "${CYAN}🔐 Saving DigitalOcean credentials...${NC}"
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << CONFIGEOF
DO_API_TOKEN="$token"
CONFIGEOF
    chmod 600 "$CONFIG_FILE"
    
    # Test the token
    local response=$(do_api GET "/account")
    
    if echo "$response" | grep -q '"account"'; then
        echo -e "${GREEN}✓ Authentication successful${NC}"
        init_db
    else
        echo -e "${RED}✗ Invalid token${NC}"
        rm "$CONFIG_FILE"
        exit 1
    fi
}

cmd_list() {
    init_db
    check_auth
    
    echo -e "${CYAN}💧 Fetching droplets...${NC}\n"
    
    local response=$(do_api GET "/droplets")
    
    # Parse droplets
    echo "$response" | grep -o '"id":[0-9]*,"name":"[^"]*"' | while read -r line; do
        local id=$(echo "$line" | grep -o '"id":[0-9]*' | cut -d: -f2)
        local name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        
        # Get more details for this droplet
        local details=$(echo "$response" | grep -A 50 "\"id\":$id")
        local status=$(echo "$details" | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4)
        local ip=$(echo "$details" | grep -o '"ip_address":"[^"]*"' | head -1 | cut -d'"' -f4)
        local size=$(echo "$details" | grep -o '"slug":"[^"]*"' | head -1 | cut -d'"' -f4)
        local region=$(echo "$details" | grep -o '"slug":"[^"]*"' | sed -n '2p' | cut -d'"' -f4)
        
        if [[ "$status" == "active" ]]; then
            echo -e "${GREEN}●${NC} $name (ID: $id)"
        else
            echo -e "${YELLOW}●${NC} $name (ID: $id) - $status"
        fi
        [[ -n "$ip" ]] && echo -e "  IP: $ip"
        [[ -n "$size" ]] && echo -e "  Size: $size"
        [[ -n "$region" ]] && echo -e "  Region: $region"
        echo ""
        
        # Save to database
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO droplets (id, name, region, size, ip_address, status, created_at) VALUES ($id, '$name', '$region', '$size', '$ip', '$status', $(date +%s));"
    done
}

cmd_create() {
    check_auth
    local name="$1"
    local size="${2:-s-1vcpu-1gb}"
    local region="${3:-nyc1}"
    local image="${4:-ubuntu-22-04-x64}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}❌ Usage: br ocean create <name> [size] [region] [image]${NC}"
        echo ""
        echo "Examples:"
        echo "  br ocean create my-server"
        echo "  br ocean create my-server s-2vcpu-2gb sfo3"
        echo ""
        echo "Common sizes: s-1vcpu-1gb, s-2vcpu-2gb, s-4vcpu-8gb"
        echo "Common regions: nyc1, sfo3, lon1, fra1"
        exit 1
    fi
    
    echo -e "${CYAN}🚀 Creating droplet: $name${NC}"
    echo -e "  Size: $size"
    echo -e "  Region: $region"
    echo -e "  Image: $image"
    echo ""
    
    # Get SSH keys
    local keys=$(do_api GET "/account/keys" | grep -o '"id":[0-9]*' | cut -d: -f2 | tr '\n' ',' | sed 's/,$//')
    
    local data="{\"name\":\"$name\",\"region\":\"$region\",\"size\":\"$size\",\"image\":\"$image\",\"ssh_keys\":[$keys],\"backups\":false,\"ipv6\":true,\"monitoring\":true}"
    
    local response=$(do_api POST "/droplets" "$data")
    
    if echo "$response" | grep -q '"droplet"'; then
        echo -e "${GREEN}✓ Droplet created${NC}"
        local droplet_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
        echo -e "  ID: $droplet_id"
        echo -e "\n${CYAN}⏳ Droplet is being created... Check status with: br ocean list${NC}"
    else
        echo -e "${RED}✗ Failed to create droplet${NC}"
        echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4
    fi
}

cmd_delete() {
    check_auth
    local droplet_id="$1"
    
    if [[ -z "$droplet_id" ]]; then
        echo -e "${RED}❌ Usage: br ocean delete <droplet-id>${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}⚠️  About to delete droplet ID: $droplet_id${NC}"
    read "confirm?Are you sure? (y/N): "
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 0
    fi
    
    echo -e "${CYAN}🗑️  Deleting droplet...${NC}"
    
    local response=$(do_api DELETE "/droplets/$droplet_id")
    
    if [[ -z "$response" ]] || echo "$response" | grep -q '"no_content"'; then
        echo -e "${GREEN}✓ Droplet deleted${NC}"
        sqlite3 "$DB_FILE" "DELETE FROM droplets WHERE id=$droplet_id;"
    else
        echo -e "${RED}✗ Failed to delete droplet${NC}"
    fi
}

cmd_ssh() {
    init_db
    local droplet_id="$1"
    local user="${2:-root}"
    
    if [[ -z "$droplet_id" ]]; then
        echo -e "${RED}❌ Usage: br ocean ssh <droplet-id> [user]${NC}"
        exit 1
    fi
    
    local ip=$(sqlite3 "$DB_FILE" "SELECT ip_address FROM droplets WHERE id=$droplet_id;")
    
    if [[ -z "$ip" ]]; then
        echo -e "${YELLOW}Droplet not cached, fetching...${NC}"
        cmd_list > /dev/null 2>&1
        ip=$(sqlite3 "$DB_FILE" "SELECT ip_address FROM droplets WHERE id=$droplet_id;")
    fi
    
    if [[ -z "$ip" ]]; then
        echo -e "${RED}❌ Droplet not found or no IP assigned yet${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🔌 Connecting to $ip as $user...${NC}\n"
    ssh "$user@$ip"
}

cmd_snapshot() {
    check_auth
    local droplet_id="$1"
    local snapshot_name="$2"
    
    if [[ -z "$droplet_id" || -z "$snapshot_name" ]]; then
        echo -e "${RED}❌ Usage: br ocean snapshot <droplet-id> <name>${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📸 Creating snapshot: $snapshot_name${NC}"
    
    local data="{\"type\":\"snapshot\",\"name\":\"$snapshot_name\"}"
    local response=$(do_api POST "/droplets/$droplet_id/actions" "$data")
    
    if echo "$response" | grep -q '"action"'; then
        echo -e "${GREEN}✓ Snapshot initiated${NC}"
        echo -e "${CYAN}This may take a few minutes...${NC}"
    else
        echo -e "${RED}✗ Failed to create snapshot${NC}"
    fi
}

cmd_resize() {
    check_auth
    local droplet_id="$1"
    local new_size="$2"
    
    if [[ -z "$droplet_id" || -z "$new_size" ]]; then
        echo -e "${RED}❌ Usage: br ocean resize <droplet-id> <size>${NC}"
        echo "Example: br ocean resize 12345 s-2vcpu-2gb"
        exit 1
    fi
    
    echo -e "${CYAN}📏 Resizing droplet to $new_size...${NC}"
    echo -e "${YELLOW}⚠️  Droplet will be powered off${NC}"
    
    local data="{\"type\":\"resize\",\"size\":\"$new_size\",\"disk\":true}"
    local response=$(do_api POST "/droplets/$droplet_id/actions" "$data")
    
    if echo "$response" | grep -q '"action"'; then
        echo -e "${GREEN}✓ Resize initiated${NC}"
    else
        echo -e "${RED}✗ Failed to resize${NC}"
    fi
}

cmd_sizes() {
    check_auth
    echo -e "${CYAN}💰 Available Droplet Sizes:${NC}\n"
    
    local response=$(do_api GET "/sizes")
    
    echo "$response" | grep -o '"slug":"[^"]*","memory":[0-9]*,"vcpus":[0-9]*,"disk":[0-9]*,"price_monthly":[0-9.]*' | while read -r line; do
        local slug=$(echo "$line" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
        local mem=$(echo "$line" | grep -o '"memory":[0-9]*' | cut -d: -f2)
        local cpu=$(echo "$line" | grep -o '"vcpus":[0-9]*' | cut -d: -f2)
        local disk=$(echo "$line" | grep -o '"disk":[0-9]*' | cut -d: -f2)
        local price=$(echo "$line" | grep -o '"price_monthly":[0-9.]*' | cut -d: -f2)
        
        echo -e "${BLUE}▸${NC} $slug"
        echo -e "  CPU: ${cpu}  Memory: ${mem}MB  Disk: ${disk}GB  Price: \$${price}/mo"
        echo ""
    done | head -30
}

cmd_regions() {
    check_auth
    echo -e "${CYAN}🌍 Available Regions:${NC}\n"
    
    local response=$(do_api GET "/regions")
    
    echo "$response" | grep -o '"slug":"[^"]*","name":"[^"]*","available":true' | while read -r line; do
        local slug=$(echo "$line" | grep -o '"slug":"[^"]*"' | cut -d'"' -f4)
        local name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}●${NC} $slug - $name"
    done
}

cmd_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR OCEAN${NC}  ${DIM}DigitalOcean from your terminal.${NC}"
  echo -e "  ${DIM}Spin up. Scale out. Shut down.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  list                            ${NC} List all droplets"
  echo -e "  ${AMBER}  create <name> <region> <size>   ${NC} Create a new droplet"
  echo -e "  ${AMBER}  destroy <id>                    ${NC} Destroy a droplet"
  echo -e "  ${AMBER}  ssh <name>                      ${NC} SSH into a droplet"
  echo -e "  ${AMBER}  snapshot <id> <name>            ${NC} Create droplet snapshot"
  echo -e "  ${AMBER}  status                          ${NC} Droplet status overview"
  echo -e "  ${AMBER}  auth <token>                    ${NC} Set DigitalOcean API token"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br ocean list${NC}"
  echo -e "  ${DIM}  br ocean create my-server nyc3 s-1vcpu-1gb${NC}"
  echo -e "  ${DIM}  br ocean ssh blackroad-infinity${NC}"
  echo -e "  ${DIM}  br ocean snapshot 12345 pre-deploy${NC}"
  echo -e ""
}
# Main dispatch
init_db

case "${1:-help}" in
    auth) cmd_auth "${@:2}" ;;
    list|ls) cmd_list ;;
    create|new) cmd_create "${@:2}" ;;
    delete|rm|destroy) cmd_delete "${@:2}" ;;
    ssh|connect) cmd_ssh "${@:2}" ;;
    snapshot|backup) cmd_snapshot "${@:2}" ;;
    resize) cmd_resize "${@:2}" ;;
    sizes) cmd_sizes ;;
    regions) cmd_regions ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
