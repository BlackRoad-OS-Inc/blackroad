#!/bin/bash
# BlackRoad Memory Integration Hub
# Connect memory system to ALL BlackRoad products

MEMORY_DIR="$HOME/.blackroad/memory"
INTEGRATION_DIR="$MEMORY_DIR/integrations"
INTEGRATION_DB="$INTEGRATION_DIR/integrations.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     🔌 Memory Integration Hub                 ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$INTEGRATION_DIR/webhooks"
    mkdir -p "$INTEGRATION_DIR/plugins"

    # Create integration database
    sqlite3 "$INTEGRATION_DB" <<'SQL'
-- Registered integrations
CREATE TABLE IF NOT EXISTS integrations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,              -- 'webhook', 'plugin', 'api', 'stream'
    endpoint TEXT,
    api_key TEXT,
    config TEXT,                     -- JSON configuration
    status TEXT DEFAULT 'active',
    created_at INTEGER NOT NULL,
    last_sync INTEGER
);

-- Integration events
CREATE TABLE IF NOT EXISTS integration_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    integration_id INTEGER NOT NULL,
    event_type TEXT NOT NULL,
    event_data TEXT NOT NULL,
    success INTEGER,
    error TEXT,
    timestamp INTEGER NOT NULL,
    FOREIGN KEY (integration_id) REFERENCES integrations(id)
);

-- Webhooks
CREATE TABLE IF NOT EXISTS webhooks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    integration_id INTEGER NOT NULL,
    url TEXT NOT NULL,
    method TEXT DEFAULT 'POST',
    headers TEXT,                    -- JSON headers
    triggers TEXT,                   -- JSON array of trigger events
    enabled INTEGER DEFAULT 1,
    FOREIGN KEY (integration_id) REFERENCES integrations(id)
);

CREATE INDEX IF NOT EXISTS idx_integration_events_integration ON integration_events(integration_id);
CREATE INDEX IF NOT EXISTS idx_integration_events_timestamp ON integration_events(timestamp);

SQL

    echo -e "${GREEN}✓${NC} Integration Hub initialized"
}

# Register integration
register_integration() {
    local name="$1"
    local type="$2"
    local endpoint="$3"
    local config="${4:-{}}"

    if [ -z "$name" ] || [ -z "$type" ]; then
        echo -e "${RED}Error: Name and type required${NC}"
        return 1
    fi

    local timestamp=$(date +%s)

    sqlite3 "$INTEGRATION_DB" <<SQL
INSERT OR REPLACE INTO integrations (name, type, endpoint, config, created_at)
VALUES ('$name', '$type', '$endpoint', '$config', $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Integration registered: $name ($type)"

    # Log to memory
    ~/memory-system.sh log "integration-registered" "$name" "Registered $type integration: $name at $endpoint" 2>/dev/null
}

# Add webhook
add_webhook() {
    local integration_name="$1"
    local url="$2"
    local triggers="$3"

    if [ -z "$integration_name" ] || [ -z "$url" ]; then
        echo -e "${RED}Error: Integration name and URL required${NC}"
        return 1
    fi

    local integration_id=$(sqlite3 "$INTEGRATION_DB" "SELECT id FROM integrations WHERE name = '$integration_name'")

    if [ -z "$integration_id" ]; then
        echo -e "${RED}Error: Integration not found: $integration_name${NC}"
        return 1
    fi

    local headers='{\"Content-Type\":\"application/json\"}'

    sqlite3 "$INTEGRATION_DB" <<SQL
INSERT INTO webhooks (integration_id, url, headers, triggers)
VALUES ($integration_id, '$url', '$headers', '$triggers');
SQL

    echo -e "${GREEN}✓${NC} Webhook added for $integration_name"
}

# Send webhook
send_webhook() {
    local integration_name="$1"
    local event_type="$2"
    local event_data="$3"

    # Get webhooks for this integration
    local webhooks=$(sqlite3 "$INTEGRATION_DB" "
        SELECT w.url, w.method
        FROM webhooks w
        JOIN integrations i ON w.integration_id = i.id
        WHERE i.name = '$integration_name' AND w.enabled = 1
    ")

    echo "$webhooks" | while IFS='|' read -r url method; do
        [ -z "$url" ] && continue

        echo -e "${CYAN}📤 Sending webhook to $url${NC}"

        # Send webhook (simplified - real impl would use curl)
        local payload="{\"event\":\"$event_type\",\"data\":$event_data,\"timestamp\":$(date +%s)}"

        local result=$(curl -s -X "$method" \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "$url" 2>&1)

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓${NC} Webhook sent successfully"
        else
            echo -e "${RED}✗${NC} Webhook failed: $result"
        fi
    done
}

# List integrations
list_integrations() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Active Integrations                       ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$INTEGRATION_DB" <<SQL
SELECT
    name,
    type,
    endpoint,
    status,
    datetime(created_at, 'unixepoch', 'localtime') as created
FROM integrations
ORDER BY created_at DESC;
SQL
}

# Pre-register common integrations
register_common() {
    echo -e "${CYAN}📦 Registering common integrations...${NC}\n"

    # GitHub
    register_integration "github" "api" "https://api.github.com" '{"org":"BlackRoad-OS"}'

    # Cloudflare
    register_integration "cloudflare" "api" "https://api.cloudflare.com/client/v4" '{}'

    # Slack (if configured)
    register_integration "slack" "webhook" "https://hooks.slack.com/services/..." '{}'

    # Discord (if configured)
    register_integration "discord" "webhook" "https://discord.com/api/webhooks/..." '{}'

    # Stream server
    register_integration "stream-server" "stream" "http://localhost:9998" '{}'

    # API server
    register_integration "api-server" "api" "http://localhost:8888" '{}'

    # Federation
    register_integration "federation" "p2p" "http://localhost:7777" '{}'

    echo -e "\n${GREEN}✓${NC} Common integrations registered"
}

# Watch memory journal and send events
watch_and_send() {
    local journal="$MEMORY_DIR/journals/master-journal.jsonl"
    local integration="$1"

    if [ -z "$integration" ]; then
        echo -e "${RED}Error: Integration name required${NC}"
        return 1
    fi

    echo -e "${CYAN}👁️  Watching journal for integration: $integration${NC}"

    local last_line=$(wc -l < "$journal" 2>/dev/null || echo 0)

    while true; do
        sleep 2

        local current_line=$(wc -l < "$journal" 2>/dev/null || echo 0)

        if [ "$current_line" -gt "$last_line" ]; then
            local new_entries=$((current_line - last_line))

            tail -n "$new_entries" "$journal" | while IFS= read -r entry; do
                # Extract event type and data
                local event_type=$(echo "$entry" | jq -r '.action' 2>/dev/null)

                # Send webhook
                send_webhook "$integration" "$event_type" "$entry"
            done

            last_line=$current_line
        fi
    done
}

# Test integration
test_integration() {
    local integration_name="$1"

    echo -e "${CYAN}🧪 Testing integration: $integration_name${NC}"

    local test_data='{"test":true,"message":"Integration test from Memory Hub"}'

    send_webhook "$integration_name" "test" "$test_data"
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    register)
        register_integration "$2" "$3" "$4" "$5"
        ;;
    webhook)
        add_webhook "$2" "$3" "$4"
        ;;
    list)
        list_integrations
        ;;
    common)
        register_common
        ;;
    watch)
        watch_and_send "$2"
        ;;
    test)
        test_integration "$2"
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     🔌 Memory Integration Hub                 ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Connect memory system to all products"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                    - Initialize hub"
        echo "  common                  - Register common integrations"
        echo ""
        echo "Integrations:"
        echo "  register NAME TYPE URL [CONFIG] - Register integration"
        echo "  webhook NAME URL TRIGGERS       - Add webhook"
        echo "  list                            - List integrations"
        echo ""
        echo "Operations:"
        echo "  watch INTEGRATION       - Watch journal and send events"
        echo "  test INTEGRATION        - Test integration"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 common"
        echo "  $0 register slack webhook 'https://hooks.slack.com/...'"
        echo "  $0 watch slack"
        ;;
esac
