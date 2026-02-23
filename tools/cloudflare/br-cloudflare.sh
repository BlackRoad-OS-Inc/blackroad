#!/usr/bin/env zsh

# Colors
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
NC='\033[0m'

DB_FILE="$HOME/.blackroad/cloudflare.db"
CONFIG_FILE="$HOME/.blackroad/cloudflare.conf"

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS zones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    zone_id TEXT UNIQUE,
    name TEXT,
    status TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS deployments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    project_name TEXT,
    deployment_id TEXT,
    url TEXT,
    status TEXT,
    deployed_at INTEGER
);

CREATE TABLE IF NOT EXISTS dns_records (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    zone_id TEXT,
    record_id TEXT,
    type TEXT,
    name TEXT,
    content TEXT,
    created_at INTEGER
);
EOF
}

check_auth() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}❌ Not configured${NC}"
        echo "Run: br cloudflare auth <api-token>"
        echo ""
        echo "Get token from: https://dash.cloudflare.com/profile/api-tokens"
        exit 1
    fi
    source "$CONFIG_FILE"
    if [[ -z "$CF_API_TOKEN" ]]; then
        echo -e "${RED}❌ API token not found${NC}"
        exit 1
    fi
}

cf_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    
    check_auth
    
    local url="https://api.cloudflare.com/client/v4${endpoint}"
    
    if [[ -n "$data" ]]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CF_API_TOKEN"
    fi
}

cmd_auth() {
    local token="$1"
    
    if [[ -z "$token" ]]; then
        echo -e "${RED}❌ Usage: br cloudflare auth <api-token>${NC}"
        echo ""
        echo "Get your API token:"
        echo "1. Go to: https://dash.cloudflare.com/profile/api-tokens"
        echo "2. Create Token → Use template: Edit zone DNS"
        echo "3. Copy token and run: br cloudflare auth <token>"
        exit 1
    fi
    
    echo -e "${CYAN}🔐 Saving Cloudflare credentials...${NC}"
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << CONFIGEOF
CF_API_TOKEN="$token"
CONFIGEOF
    chmod 600 "$CONFIG_FILE"
    
    # Test the token
    local response=$(cf_api GET "/user/tokens/verify")
    local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    
    if [[ "$status" == "active" ]]; then
        echo -e "${GREEN}✓ Authentication successful${NC}"
        init_db
    else
        echo -e "${RED}✗ Invalid token${NC}"
        rm "$CONFIG_FILE"
        exit 1
    fi
}

cmd_zones() {
    init_db
    check_auth
    
    echo -e "${CYAN}🌐 Fetching zones...${NC}\n"
    
    local response=$(cf_api GET "/zones")
    
    # Parse and display zones
    echo "$response" | grep -o '"id":"[^"]*","name":"[^"]*","status":"[^"]*"' | while read -r line; do
        local zone_id=$(echo "$line" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
        local name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        local status=$(echo "$line" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [[ "$status" == "active" ]]; then
            echo -e "${GREEN}●${NC} $name"
        else
            echo -e "${YELLOW}●${NC} $name ($status)"
        fi
        echo -e "  Zone ID: $zone_id"
        
        # Save to database
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO zones (zone_id, name, status, created_at) VALUES ('$zone_id', '$name', '$status', $(date +%s));"
        echo ""
    done
}

cmd_dns_list() {
    check_auth
    local zone_name="$1"
    
    if [[ -z "$zone_name" ]]; then
        echo -e "${RED}❌ Usage: br cloudflare dns list <zone>${NC}"
        echo "Example: br cloudflare dns list example.com"
        exit 1
    fi
    
    # Get zone ID
    local zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    if [[ -z "$zone_id" ]]; then
        echo -e "${YELLOW}Zone not cached, fetching...${NC}"
        cmd_zones > /dev/null 2>&1
        zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    fi
    
    if [[ -z "$zone_id" ]]; then
        echo -e "${RED}❌ Zone not found: $zone_name${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📋 DNS Records for $zone_name:${NC}\n"
    
    local response=$(cf_api GET "/zones/$zone_id/dns_records")
    
    echo "$response" | grep -o '"type":"[^"]*","name":"[^"]*","content":"[^"]*"' | while read -r line; do
        local type=$(echo "$line" | grep -o '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
        local name=$(echo "$line" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        local content=$(echo "$line" | grep -o '"content":"[^"]*"' | head -1 | cut -d'"' -f4)
        
        echo -e "${BLUE}▸${NC} $type  $name"
        echo -e "  → $content"
        echo ""
    done
}

cmd_dns_add() {
    check_auth
    local zone_name="$1"
    local type="$2"
    local name="$3"
    local content="$4"
    
    if [[ -z "$zone_name" || -z "$type" || -z "$name" || -z "$content" ]]; then
        echo -e "${RED}❌ Usage: br cloudflare dns add <zone> <type> <name> <content>${NC}"
        echo "Example: br cloudflare dns add example.com A www 192.0.2.1"
        exit 1
    fi
    
    # Get zone ID
    local zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    if [[ -z "$zone_id" ]]; then
        cmd_zones > /dev/null 2>&1
        zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    fi
    
    if [[ -z "$zone_id" ]]; then
        echo -e "${RED}❌ Zone not found: $zone_name${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}➕ Adding DNS record...${NC}"
    
    local data="{\"type\":\"$type\",\"name\":\"$name\",\"content\":\"$content\",\"ttl\":1,\"proxied\":false}"
    local response=$(cf_api POST "/zones/$zone_id/dns_records" "$data")
    
    if echo "$response" | grep -q '"success":true'; then
        echo -e "${GREEN}✓ DNS record added${NC}"
        echo -e "  $type $name → $content"
    else
        echo -e "${RED}✗ Failed to add record${NC}"
        echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4
    fi
}

cmd_pages_deploy() {
    check_auth
    local dir="${1:-.}"
    local project_name="$2"
    
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}❌ Directory not found: $dir${NC}"
        exit 1
    fi
    
    if ! command -v wrangler &> /dev/null; then
        echo -e "${YELLOW}⚠️  Wrangler not installed${NC}"
        echo "Install: npm install -g wrangler"
        exit 1
    fi
    
    echo -e "${CYAN}🚀 Deploying to Cloudflare Pages...${NC}\n"
    
    cd "$dir"
    wrangler pages deploy
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Deployed successfully${NC}"
        sqlite3 "$DB_FILE" "INSERT INTO deployments (project_name, deployment_id, url, status, deployed_at) VALUES ('${project_name:-unknown}', 'cf-pages', 'https://pages.dev', 'success', $(date +%s));"
    else
        echo -e "\n${RED}✗ Deployment failed${NC}"
    fi
}

cmd_cache_purge() {
    check_auth
    local zone_name="$1"
    
    if [[ -z "$zone_name" ]]; then
        echo -e "${RED}❌ Usage: br cloudflare cache purge <zone>${NC}"
        exit 1
    fi
    
    local zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    if [[ -z "$zone_id" ]]; then
        cmd_zones > /dev/null 2>&1
        zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    fi
    
    if [[ -z "$zone_id" ]]; then
        echo -e "${RED}❌ Zone not found: $zone_name${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🧹 Purging cache for $zone_name...${NC}"
    
    local response=$(cf_api POST "/zones/$zone_id/purge_cache" '{"purge_everything":true}')
    
    if echo "$response" | grep -q '"success":true'; then
        echo -e "${GREEN}✓ Cache purged${NC}"
    else
        echo -e "${RED}✗ Failed to purge cache${NC}"
    fi
}

cmd_worker_deploy() {
    check_auth
    local script_file="$1"
    local name="$2"
    
    if [[ -z "$script_file" || ! -f "$script_file" ]]; then
        echo -e "${RED}❌ Usage: br cloudflare worker deploy <script.js> <name>${NC}"
        exit 1
    fi
    
    if ! command -v wrangler &> /dev/null; then
        echo -e "${YELLOW}⚠️  Wrangler not installed${NC}"
        echo "Install: npm install -g wrangler"
        exit 1
    fi
    
    echo -e "${CYAN}🚀 Deploying Worker...${NC}\n"
    
    wrangler deploy "$script_file" --name "$name"
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Worker deployed${NC}"
    else
        echo -e "\n${RED}✗ Deployment failed${NC}"
    fi
}

cmd_analytics() {
    check_auth
    local zone_name="$1"
    
    if [[ -z "$zone_name" ]]; then
        echo -e "${RED}❌ Usage: br cloudflare analytics <zone>${NC}"
        exit 1
    fi
    
    local zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    if [[ -z "$zone_id" ]]; then
        cmd_zones > /dev/null 2>&1
        zone_id=$(sqlite3 "$DB_FILE" "SELECT zone_id FROM zones WHERE name='$zone_name';")
    fi
    
    if [[ -z "$zone_id" ]]; then
        echo -e "${RED}❌ Zone not found: $zone_name${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}📊 Analytics for $zone_name:${NC}\n"
    
    local response=$(cf_api GET "/zones/$zone_id/analytics/dashboard?since=-1440")
    
    # Parse basic analytics
    if echo "$response" | grep -q '"success":true'; then
        echo -e "${GREEN}✓ Data retrieved${NC}"
        echo ""
        echo "Note: Use Cloudflare dashboard for detailed analytics"
        echo "https://dash.cloudflare.com"
    else
        echo -e "${RED}✗ Failed to get analytics${NC}"
    fi
}

cmd_help() {
    echo -e "  ${AMBER}${BOLD}◆ BR CLOUDFLARE${NC}  CF manager\n"
    echo -e "  ${AMBER}br cloudflare auth <token>${NC}              set API token\n"
    echo -e "  ${BOLD}zones & dns${NC}"
    echo -e "  ${AMBER}br cloudflare zones${NC}                     list zones"
    echo -e "  ${AMBER}br cloudflare dns list <zone>${NC}           list records"
    echo -e "  ${AMBER}br cloudflare dns add <zone> <type> <name> <content>${NC}"
    echo -e "  ${AMBER}br cloudflare dns remove <zone> <id>${NC}\n"
    echo -e "  ${BOLD}deploy${NC}"
    echo -e "  ${AMBER}br cloudflare pages deploy [dir]${NC}        → Pages"
    echo -e "  ${AMBER}br cloudflare worker deploy <file> <name>${NC} → Worker\n"
    echo -e "  ${BOLD}ops${NC}"
    echo -e "  ${AMBER}br cloudflare cache purge <zone>${NC}"
    echo -e "  ${AMBER}br cloudflare analytics <zone>${NC}\n"
    echo -e "  ${DIM}Get token: dash.cloudflare.com/profile/api-tokens${NC}"
}

# Main dispatch
init_db

case "${1:-help}" in
    auth) cmd_auth "${@:2}" ;;
    zones|zone) cmd_zones ;;
    dns)
        case "${2:-help}" in
            list|ls) cmd_dns_list "${@:3}" ;;
            add) cmd_dns_add "${@:3}" ;;
            *) echo -e "${RED}Unknown dns command: ${2:-help}${NC}"; exit 1 ;;
        esac
        ;;
    pages) cmd_pages_deploy "${@:2}" ;;
    worker) cmd_worker_deploy "${@:2}" ;;
    cache) cmd_cache_purge "${@:2}" ;;
    analytics|stats) cmd_analytics "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
