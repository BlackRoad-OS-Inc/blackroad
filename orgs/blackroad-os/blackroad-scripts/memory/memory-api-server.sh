#!/bin/bash
# BlackRoad Memory API Server
# REST + GraphQL API for memory system

MEMORY_DIR="$HOME/.blackroad/memory"
API_DIR="$MEMORY_DIR/api"
API_DB="$API_DIR/api.db"
API_PORT="${API_PORT:-8888}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║       🔌 Memory API Server                    ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$API_DIR"

    # Create API database
    sqlite3 "$API_DB" <<'SQL'
-- API keys
CREATE TABLE IF NOT EXISTS api_keys (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    permissions TEXT NOT NULL,  -- JSON permissions
    created_at INTEGER NOT NULL,
    last_used INTEGER,
    requests_count INTEGER DEFAULT 0,
    rate_limit INTEGER DEFAULT 1000,
    status TEXT DEFAULT 'active'
);

-- API requests log
CREATE TABLE IF NOT EXISTS api_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    api_key TEXT,
    endpoint TEXT NOT NULL,
    method TEXT NOT NULL,
    status_code INTEGER,
    response_time INTEGER,    -- milliseconds
    timestamp INTEGER NOT NULL
);

-- Rate limiting
CREATE TABLE IF NOT EXISTS rate_limits (
    api_key TEXT NOT NULL,
    window_start INTEGER NOT NULL,
    request_count INTEGER DEFAULT 0,
    PRIMARY KEY (api_key, window_start)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_api_requests_timestamp ON api_requests(timestamp);
CREATE INDEX IF NOT EXISTS idx_api_requests_api_key ON api_requests(api_key);
CREATE INDEX IF NOT EXISTS idx_rate_limits_window ON rate_limits(window_start);

SQL

    # Create default admin API key
    local admin_key="blackroad_$(openssl rand -hex 16)"
    local timestamp=$(date +%s)

    sqlite3 "$API_DB" <<SQL
INSERT OR IGNORE INTO api_keys (key, name, permissions, created_at, rate_limit)
VALUES ('$admin_key', 'Admin Key', '{"read":true,"write":true,"admin":true}', $timestamp, 10000);
SQL

    echo -e "${GREEN}✓${NC} API server initialized"
    echo -e "  ${CYAN}API DB:${NC} $API_DB"
    echo -e "  ${CYAN}Port:${NC} $API_PORT"
    echo -e "\n${YELLOW}🔑 Admin API Key:${NC} $admin_key"
    echo -e "${YELLOW}💾 Save this key - it won't be shown again!${NC}"
}

# Validate API key
validate_key() {
    local key="$1"

    local valid=$(sqlite3 "$API_DB" "SELECT COUNT(*) FROM api_keys WHERE key = '$key' AND status = 'active'")

    if [ "$valid" -eq 1 ]; then
        # Update last used
        local timestamp=$(date +%s)
        sqlite3 "$API_DB" <<SQL
UPDATE api_keys SET last_used = $timestamp, requests_count = requests_count + 1 WHERE key = '$key';
SQL
        return 0
    else
        return 1
    fi
}

# Check rate limit
check_rate_limit() {
    local key="$1"
    local timestamp=$(date +%s)
    local window_start=$((timestamp - timestamp % 3600)) # 1-hour window

    # Get rate limit for this key
    local limit=$(sqlite3 "$API_DB" "SELECT rate_limit FROM api_keys WHERE key = '$key'")

    # Get current count
    local count=$(sqlite3 "$API_DB" "SELECT COALESCE(request_count, 0) FROM rate_limits WHERE api_key = '$key' AND window_start = $window_start")

    if [ -z "$count" ]; then
        count=0
    fi

    if [ "$count" -ge "$limit" ]; then
        echo "RATE_LIMIT_EXCEEDED"
        return 1
    fi

    # Increment counter
    sqlite3 "$API_DB" <<SQL
INSERT INTO rate_limits (api_key, window_start, request_count)
VALUES ('$key', $window_start, 1)
ON CONFLICT (api_key, window_start) DO UPDATE SET request_count = request_count + 1;
SQL

    echo "$((limit - count - 1))"
    return 0
}

# Log API request
log_request() {
    local key="$1"
    local endpoint="$2"
    local method="$3"
    local status="$4"
    local response_time="$5"
    local timestamp=$(date +%s)

    sqlite3 "$API_DB" <<SQL
INSERT INTO api_requests (api_key, endpoint, method, status_code, response_time, timestamp)
VALUES ('$key', '$endpoint', '$method', $status, $response_time, $timestamp);
SQL
}

# Handle REST API request
handle_rest() {
    local method="$1"
    local endpoint="$2"
    local api_key="$3"
    local data="$4"

    local start_time=$(date +%s%3N)

    # Validate API key
    if ! validate_key "$api_key"; then
        echo "HTTP/1.1 401 Unauthorized"
        echo "Content-Type: application/json"
        echo ""
        echo '{"error":"Invalid API key"}'
        log_request "$api_key" "$endpoint" "$method" 401 0
        return 1
    fi

    # Check rate limit
    local remaining=$(check_rate_limit "$api_key")
    if [ "$remaining" == "RATE_LIMIT_EXCEEDED" ]; then
        echo "HTTP/1.1 429 Too Many Requests"
        echo "Content-Type: application/json"
        echo ""
        echo '{"error":"Rate limit exceeded"}'
        log_request "$api_key" "$endpoint" "$method" 429 0
        return 1
    fi

    # Route endpoint
    case "$endpoint" in
        /api/memory/recent)
            local limit="${data:-10}"
            local result=$(~/memory-query.sh recent "$limit" 2>/dev/null)

            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "X-RateLimit-Remaining: $remaining"
            echo ""
            echo "$result"

            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            log_request "$api_key" "$endpoint" "$method" 200 "$duration"
            ;;

        /api/memory/search)
            local query="$data"
            if [ -z "$query" ]; then
                echo "HTTP/1.1 400 Bad Request"
                echo "Content-Type: application/json"
                echo ""
                echo '{"error":"Query required"}'
                log_request "$api_key" "$endpoint" "$method" 400 0
                return 1
            fi

            local result=$(~/memory-query.sh search "$query" 2>/dev/null)

            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "X-RateLimit-Remaining: $remaining"
            echo ""
            echo "$result"

            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            log_request "$api_key" "$endpoint" "$method" 200 "$duration"
            ;;

        /api/memory/stats)
            local result=$(~/memory-query.sh stats 2>/dev/null | tail -n +2) # Skip header

            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "X-RateLimit-Remaining: $remaining"
            echo ""
            echo "{\"stats\":\"$result\"}"

            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            log_request "$api_key" "$endpoint" "$method" 200 "$duration"
            ;;

        /api/codex/search)
            local query="$data"
            if [ -z "$query" ]; then
                echo "HTTP/1.1 400 Bad Request"
                echo "Content-Type: application/json"
                echo ""
                echo '{"error":"Query required"}'
                log_request "$api_key" "$endpoint" "$method" 400 0
                return 1
            fi

            local result=$(~/memory-codex.sh search "$query" 2>/dev/null)

            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "X-RateLimit-Remaining: $remaining"
            echo ""
            echo "$result"

            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            log_request "$api_key" "$endpoint" "$method" 200 "$duration"
            ;;

        /api/codex/recommend)
            local problem="$data"
            if [ -z "$problem" ]; then
                echo "HTTP/1.1 400 Bad Request"
                echo "Content-Type: application/json"
                echo ""
                echo '{"error":"Problem description required"}'
                log_request "$api_key" "$endpoint" "$method" 400 0
                return 1
            fi

            local result=$(~/memory-codex.sh recommend "$problem" 2>/dev/null)

            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "X-RateLimit-Remaining: $remaining"
            echo ""
            echo "$result"

            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            log_request "$api_key" "$endpoint" "$method" 200 "$duration"
            ;;

        /api/predict/success)
            local entity="$data"
            if [ -z "$entity" ]; then
                echo "HTTP/1.1 400 Bad Request"
                echo "Content-Type: application/json"
                echo ""
                echo '{"error":"Entity required"}'
                log_request "$api_key" "$endpoint" "$method" 400 0
                return 1
            fi

            local result=$(~/memory-predictor.sh predict "$entity" 2>/dev/null)

            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "X-RateLimit-Remaining: $remaining"
            echo ""
            echo "{\"prediction\":\"$result\"}"

            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            log_request "$api_key" "$endpoint" "$method" 200 "$duration"
            ;;

        /api/health)
            echo "HTTP/1.1 200 OK"
            echo "Content-Type: application/json"
            echo "X-RateLimit-Remaining: $remaining"
            echo ""
            echo '{"status":"healthy","timestamp":'$(date +%s)'}'

            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            log_request "$api_key" "$endpoint" "$method" 200 "$duration"
            ;;

        *)
            echo "HTTP/1.1 404 Not Found"
            echo "Content-Type: application/json"
            echo ""
            echo "{\"error\":\"Endpoint not found: $endpoint\"}"
            log_request "$api_key" "$endpoint" "$method" 404 0
            ;;
    esac
}

# Start API server
start_server() {
    echo -e "${CYAN}🔌 Starting API server on port $API_PORT...${NC}"
    echo -e "${YELLOW}💡 Test with: curl -H 'X-API-Key: YOUR_KEY' http://localhost:$API_PORT/api/health${NC}\n"

    while true; do
        {
            # Read HTTP request
            read -r request_line
            method=$(echo "$request_line" | awk '{print $1}')
            endpoint=$(echo "$request_line" | awk '{print $2}')

            # Read headers
            api_key=""
            content_length=0

            while read -r header; do
                header=$(echo "$header" | tr -d '\r\n')
                [ -z "$header" ] && break

                # Extract API key
                if echo "$header" | grep -qi "^X-API-Key:"; then
                    api_key=$(echo "$header" | cut -d: -f2- | sed 's/^ *//')
                fi

                # Extract content length
                if echo "$header" | grep -qi "^Content-Length:"; then
                    content_length=$(echo "$header" | cut -d: -f2- | sed 's/^ *//')
                fi
            done

            # Read body if present
            data=""
            if [ "$content_length" -gt 0 ]; then
                data=$(head -c "$content_length")
            fi

            # Handle request
            handle_rest "$method" "$endpoint" "$api_key" "$data"

        } | nc -l "$API_PORT" 2>/dev/null

        sleep 0.1
    done
}

# Show API statistics
show_stats() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║         API Server Statistics                 ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    # Total requests
    local total=$(sqlite3 "$API_DB" "SELECT COUNT(*) FROM api_requests")
    echo -e "${CYAN}Total Requests:${NC} $total"

    # Requests by endpoint
    echo -e "\n${PURPLE}Top Endpoints:${NC}"
    sqlite3 -header -column "$API_DB" <<SQL
SELECT
    endpoint,
    COUNT(*) as requests,
    AVG(response_time) as avg_ms
FROM api_requests
GROUP BY endpoint
ORDER BY requests DESC
LIMIT 10;
SQL

    # Requests by status code
    echo -e "\n${PURPLE}Status Codes:${NC}"
    sqlite3 -header -column "$API_DB" <<SQL
SELECT
    status_code,
    COUNT(*) as count
FROM api_requests
GROUP BY status_code
ORDER BY count DESC;
SQL

    # Active API keys
    echo -e "\n${PURPLE}Active API Keys:${NC}"
    sqlite3 -header -column "$API_DB" <<SQL
SELECT
    name,
    requests_count,
    datetime(last_used, 'unixepoch', 'localtime') as last_used
FROM api_keys
WHERE status = 'active'
ORDER BY requests_count DESC;
SQL
}

# List API keys
list_keys() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           API Keys                            ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$API_DB" <<SQL
SELECT
    SUBSTR(key, 1, 20) || '...' as key,
    name,
    rate_limit,
    requests_count,
    status
FROM api_keys
ORDER BY created_at DESC;
SQL
}

# Create new API key
create_key() {
    local name="$1"
    local permissions="${2:-{\"read\":true}}"
    local rate_limit="${3:-1000}"

    if [ -z "$name" ]; then
        echo -e "${RED}Error: Name required${NC}"
        return 1
    fi

    local key="blackroad_$(openssl rand -hex 16)"
    local timestamp=$(date +%s)

    sqlite3 "$API_DB" <<SQL
INSERT INTO api_keys (key, name, permissions, created_at, rate_limit)
VALUES ('$key', '$name', '$permissions', $timestamp, $rate_limit);
SQL

    echo -e "${GREEN}✓${NC} API key created"
    echo -e "  ${CYAN}Name:${NC} $name"
    echo -e "  ${CYAN}Key:${NC} $key"
    echo -e "  ${CYAN}Rate Limit:${NC} $rate_limit requests/hour"
    echo -e "\n${YELLOW}💾 Save this key - it won't be shown again!${NC}"
}

# Revoke API key
revoke_key() {
    local key="$1"

    if [ -z "$key" ]; then
        echo -e "${RED}Error: Key required${NC}"
        return 1
    fi

    sqlite3 "$API_DB" <<SQL
UPDATE api_keys SET status = 'revoked' WHERE key = '$key';
SQL

    echo -e "${GREEN}✓${NC} API key revoked: $key"
}

# Create API documentation
create_docs() {
    local docs_file="$API_DIR/API_DOCUMENTATION.md"

    cat > "$docs_file" <<'DOCS'
# BlackRoad Memory API Documentation

## Base URL
```
http://localhost:8888
```

## Authentication
All requests require an API key in the `X-API-Key` header:

```bash
curl -H "X-API-Key: YOUR_API_KEY" http://localhost:8888/api/health
```

## Rate Limits
- Default: 1,000 requests/hour
- Admin keys: 10,000 requests/hour
- Rate limit info in `X-RateLimit-Remaining` header

## Endpoints

### Health Check
```
GET /api/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": 1234567890
}
```

### Recent Memory Entries
```
GET /api/memory/recent?limit=10
```

**Parameters:**
- `limit` (optional): Number of entries (default: 10)

**Response:**
```json
[
  {
    "action": "enhanced",
    "entity": "blackroad-os-web",
    "timestamp": 1234567890
  }
]
```

### Search Memory
```
POST /api/memory/search
Content-Type: text/plain

cloudflare deployment
```

**Response:**
```json
[
  {
    "action": "deployed",
    "entity": "blackroad-os-dashboard",
    "details": "Deployed to Cloudflare Pages"
  }
]
```

### Memory Statistics
```
GET /api/memory/stats
```

**Response:**
```json
{
  "stats": "Total Entries: 2588\nActions: 45 types\n..."
}
```

### Search Codex
```
POST /api/codex/search
Content-Type: text/plain

retry logic
```

**Response:**
```json
{
  "solutions": [...],
  "patterns": [...],
  "best_practices": [...]
}
```

### Get Recommendations
```
POST /api/codex/recommend
Content-Type: text/plain

high failure rate
```

**Response:**
```json
{
  "recommendations": [
    {
      "type": "solution",
      "name": "Exponential Backoff",
      "success_rate": 95
    }
  ]
}
```

### Predict Success
```
POST /api/predict/success
Content-Type: text/plain

blackroad-cloud
```

**Response:**
```json
{
  "prediction": "MEDIUM probability - Consider pre-checks (45% historical success)"
}
```

## Error Codes

- `200 OK` - Success
- `400 Bad Request` - Invalid request
- `401 Unauthorized` - Invalid API key
- `404 Not Found` - Endpoint not found
- `429 Too Many Requests` - Rate limit exceeded

## Examples

### Bash
```bash
# Health check
curl -H "X-API-Key: YOUR_KEY" http://localhost:8888/api/health

# Recent entries
curl -H "X-API-Key: YOUR_KEY" http://localhost:8888/api/memory/recent?limit=5

# Search memory
curl -X POST -H "X-API-Key: YOUR_KEY" -d "cloudflare" http://localhost:8888/api/memory/search

# Get recommendations
curl -X POST -H "X-API-Key: YOUR_KEY" -d "deployment failing" http://localhost:8888/api/codex/recommend
```

### JavaScript
```javascript
const API_KEY = 'YOUR_KEY';
const BASE_URL = 'http://localhost:8888';

// Fetch recent entries
fetch(`${BASE_URL}/api/memory/recent?limit=10`, {
  headers: { 'X-API-Key': API_KEY }
})
  .then(res => res.json())
  .then(data => console.log(data));

// Search memory
fetch(`${BASE_URL}/api/memory/search`, {
  method: 'POST',
  headers: { 'X-API-Key': API_KEY },
  body: 'cloudflare'
})
  .then(res => res.json())
  .then(data => console.log(data));
```

### Python
```python
import requests

API_KEY = 'YOUR_KEY'
BASE_URL = 'http://localhost:8888'

# Health check
response = requests.get(
    f'{BASE_URL}/api/health',
    headers={'X-API-Key': API_KEY}
)
print(response.json())

# Search memory
response = requests.post(
    f'{BASE_URL}/api/memory/search',
    headers={'X-API-Key': API_KEY},
    data='cloudflare'
)
print(response.json())
```

## Rate Limit Headers

Every response includes rate limit information:

```
X-RateLimit-Remaining: 995
```

When rate limit is exceeded, you'll receive a `429` response:

```json
{
  "error": "Rate limit exceeded"
}
```

Wait until the next hour window to resume requests.

---

**BlackRoad Memory API Server**
*Real-time access to memory, codex, and predictions*
DOCS

    echo -e "${GREEN}✓${NC} API documentation created: $docs_file"
}

# Main execution
case "${1:-help}" in
    init)
        init
        create_docs
        ;;
    start)
        start_server
        ;;
    stats)
        show_stats
        ;;
    keys)
        list_keys
        ;;
    create-key)
        create_key "$2" "$3" "$4"
        ;;
    revoke-key)
        revoke_key "$2"
        ;;
    docs)
        create_docs
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║       🔌 Memory API Server                    ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "REST API for BlackRoad Memory System"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                    - Initialize API server"
        echo ""
        echo "Server:"
        echo "  start                   - Start API server"
        echo ""
        echo "API Keys:"
        echo "  keys                    - List all API keys"
        echo "  create-key NAME [PERMS] [LIMIT] - Create new API key"
        echo "  revoke-key KEY          - Revoke API key"
        echo ""
        echo "Monitoring:"
        echo "  stats                   - Show API statistics"
        echo ""
        echo "Documentation:"
        echo "  docs                    - Create API documentation"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 start"
        echo "  $0 create-key 'My App' '{\"read\":true}' 5000"
        echo "  $0 stats"
        echo ""
        echo "Test API:"
        echo "  curl -H 'X-API-Key: YOUR_KEY' http://localhost:$API_PORT/api/health"
        ;;
esac
