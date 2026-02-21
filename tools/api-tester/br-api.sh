#!/bin/zsh
#===============================================================================
# BR API - Smart API Tester
# Quick HTTP requests with history and code generation
#===============================================================================

API_HOME="/Users/alexa/blackroad/tools/api-tester"
API_DB="${API_HOME}/api-history.db"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# Initialize database
init_db() {
    if [[ -f "$API_DB" ]]; then
        return 0
    fi
    
    mkdir -p "$API_HOME"
    
    sqlite3 "$API_DB" <<EOF
CREATE TABLE requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    method TEXT NOT NULL,
    url TEXT NOT NULL,
    headers TEXT,
    body TEXT,
    response_code INTEGER,
    response_time REAL,
    timestamp INTEGER NOT NULL,
    tags TEXT
);

CREATE TABLE saved_endpoints (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    method TEXT NOT NULL,
    url TEXT NOT NULL,
    headers TEXT,
    body TEXT,
    description TEXT,
    created_at INTEGER NOT NULL
);

CREATE INDEX idx_url ON requests(url);
CREATE INDEX idx_timestamp ON requests(timestamp);

-- Add some example endpoints
INSERT INTO saved_endpoints (name, method, url, description, created_at)
VALUES 
    ('github-user', 'GET', 'https://api.github.com/users/{username}', 'Get GitHub user info', $(date +%s)),
    ('httpbin-post', 'POST', 'https://httpbin.org/post', 'Test POST endpoint', $(date +%s));
EOF
    
    echo -e "${GREEN}✓ API database initialized${NC}"
}

# Make HTTP request
make_request() {
    local method=${1:-GET}
    local url=$2
    local body=${3:-""}
    local headers=${4:-""}
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}Error: URL required${NC}"
        echo "Usage: br api get <url>"
        echo "       br api post <url> <body> [headers]"
        return 1
    fi
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🌐 API Request                            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}${method}${NC} ${url}"
    echo ""
    
    # Build curl command
    local curl_cmd="curl -s -w '\n\n%{http_code}|%{time_total}' -X ${method}"
    
    # Add headers
    if [[ -n "$headers" ]]; then
        # Split headers by comma
        local IFS=','
        for header in ${(s:,:)headers}; do
            curl_cmd="$curl_cmd -H '$header'"
        done
    else
        curl_cmd="$curl_cmd -H 'Content-Type: application/json'"
    fi
    
    # Add body for POST/PUT/PATCH
    if [[ "$method" =~ "POST|PUT|PATCH" ]] && [[ -n "$body" ]]; then
        curl_cmd="$curl_cmd -d '$body'"
    fi
    
    curl_cmd="$curl_cmd '$url'"
    
    # Execute request and capture output
    local start_time=$(date +%s.%N)
    local response=$(eval $curl_cmd)
    
    # Parse response (last line has status|time, second to last is blank)
    local total_lines=$(echo "$response" | wc -l | tr -d ' ')
    local body_lines=$((total_lines - 2))
    local response_body=$(echo "$response" | head -n $body_lines)
    local status_line=$(echo "$response" | tail -n 1)
    local status_code=$(echo "$status_line" | cut -d'|' -f1)
    local response_time=$(echo "$status_line" | cut -d'|' -f2)
    
    # Display response
    if [[ $status_code -ge 200 ]] && [[ $status_code -lt 300 ]]; then
        echo -e "${GREEN}✓ ${status_code}${NC} (${response_time}s)"
    elif [[ $status_code -ge 400 ]]; then
        echo -e "${RED}✗ ${status_code}${NC} (${response_time}s)"
    else
        echo -e "${YELLOW}${status_code}${NC} (${response_time}s)"
    fi
    
    echo ""
    echo -e "${CYAN}Response:${NC}"
    
    # Pretty print JSON if possible
    if echo "$response_body" | jq . &>/dev/null; then
        echo "$response_body" | jq .
    else
        echo "$response_body"
    fi
    
    echo ""
    
    # Save to history
    local timestamp=$(date +%s)
    local escaped_body=$(echo "$body" | sed "s/'/''/g")
    local escaped_headers=$(echo "$headers" | sed "s/'/''/g")
    
    sqlite3 "$API_DB" <<EOF
INSERT INTO requests (method, url, headers, body, response_code, response_time, timestamp)
VALUES ('$method', '$url', '$escaped_headers', '$escaped_body', $status_code, $response_time, $timestamp);
EOF
    
    echo -e "${YELLOW}Tip: Save this endpoint with 'br api save <name>'${NC}"
}

# GET request
get_request() {
    make_request "GET" "$1"
}

# POST request
post_request() {
    local url=$1
    local body=${2:-"{}"}
    local headers=$3
    make_request "POST" "$url" "$body" "$headers"
}

# PUT request
put_request() {
    local url=$1
    local body=${2:-"{}"}
    local headers=$3
    make_request "PUT" "$url" "$body" "$headers"
}

# DELETE request
delete_request() {
    make_request "DELETE" "$1"
}

# Save endpoint
save_endpoint() {
    local name=$1
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Name required${NC}"
        echo "Usage: br api save <name>"
        echo "Note: Saves the last request from history"
        return 1
    fi
    
    # Get last request from history
    local last=$(sqlite3 "$API_DB" -separator '|' \
        "SELECT method, url, headers, body FROM requests ORDER BY timestamp DESC LIMIT 1;")
    
    if [[ -z "$last" ]]; then
        echo -e "${RED}No requests in history${NC}"
        return 1
    fi
    
    local method=$(echo "$last" | cut -d'|' -f1)
    local url=$(echo "$last" | cut -d'|' -f2)
    local headers=$(echo "$last" | cut -d'|' -f3)
    local body=$(echo "$last" | cut -d'|' -f4)
    
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     💾 Save Endpoint                          ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Saving:${NC} ${method} ${url}"
    echo ""
    echo -ne "${YELLOW}Description (optional):${NC} "
    read -r description
    
    local escaped_headers=$(echo "$headers" | sed "s/'/''/g")
    local escaped_body=$(echo "$body" | sed "s/'/''/g")
    local escaped_desc=$(echo "$description" | sed "s/'/''/g")
    local timestamp=$(date +%s)
    
    sqlite3 "$API_DB" <<EOF
INSERT INTO saved_endpoints (name, method, url, headers, body, description, created_at)
VALUES ('$name', '$method', '$url', '$escaped_headers', '$escaped_body', '$escaped_desc', $timestamp)
ON CONFLICT(name) DO UPDATE SET
    method = '$method',
    url = '$url',
    headers = '$escaped_headers',
    body = '$escaped_body',
    description = '$escaped_desc';
EOF
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓ Endpoint '$name' saved!${NC}"
        echo ""
        echo -e "${CYAN}Use with:${NC} br api run $name"
    else
        echo -e "${RED}✗ Failed to save endpoint${NC}"
        return 1
    fi
}

# Run saved endpoint
run_saved() {
    local name=$1
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Endpoint name required${NC}"
        echo "Usage: br api run <name>"
        echo ""
        echo "List saved endpoints: br api list"
        return 1
    fi
    
    local endpoint=$(sqlite3 "$API_DB" -separator '|' \
        "SELECT method, url, headers, body FROM saved_endpoints WHERE name='$name';")
    
    if [[ -z "$endpoint" ]]; then
        echo -e "${YELLOW}Endpoint '$name' not found${NC}"
        echo ""
        echo "Available endpoints:"
        list_saved | grep "^[0-9]"
        return 1
    fi
    
    local method=$(echo "$endpoint" | cut -d'|' -f1)
    local url=$(echo "$endpoint" | cut -d'|' -f2)
    local headers=$(echo "$endpoint" | cut -d'|' -f3)
    local body=$(echo "$endpoint" | cut -d'|' -f4)
    
    echo -e "${CYAN}Running saved endpoint:${NC} $name"
    echo ""
    
    make_request "$method" "$url" "$body" "$headers"
}

# List saved endpoints
list_saved() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     📚 Saved Endpoints                        ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    local results=$(sqlite3 "$API_DB" -separator '|' \
        "SELECT name, method, url, description FROM saved_endpoints ORDER BY created_at DESC;")
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No saved endpoints${NC}"
        echo ""
        echo "Make a request and save it: br api save <name>"
        return 0
    fi
    
    local count=0
    while IFS='|' read -r name method url description; do
        ((count++))
        echo -e "${GREEN}${count}. ${name}${NC} ${CYAN}(${method})${NC}"
        echo "   ${url}"
        if [[ -n "$description" ]]; then
            echo "   ${description}"
        fi
        echo ""
    done <<< "$results"
    
    echo -e "${CYAN}Run with:${NC} br api run <name>"
}

# Show history
show_history() {
    local limit=${1:-10}
    
    echo -e "${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     📜 Request History                        ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    
    local results=$(sqlite3 "$API_DB" -separator '|' \
        "SELECT method, url, response_code, response_time, datetime(timestamp, 'unixepoch', 'localtime')
         FROM requests ORDER BY timestamp DESC LIMIT $limit;")
    
    if [[ -z "$results" ]]; then
        echo -e "${YELLOW}No request history${NC}"
        return 0
    fi
    
    while IFS='|' read -r method url code time timestamp; do
        local color=$GREEN
        if [[ $code -ge 400 ]]; then
            color=$RED
        elif [[ $code -ge 300 ]]; then
            color=$YELLOW
        fi
        
        echo -e "${color}${code}${NC} ${CYAN}${method}${NC} ${url}"
        echo "    ${time}s - ${timestamp}"
        echo ""
    done <<< "$results"
}

# Generate code from last request
generate_code() {
    local lang=${1:-curl}
    
    # Get last request
    local last=$(sqlite3 "$API_DB" -separator '|' \
        "SELECT method, url, headers, body FROM requests ORDER BY timestamp DESC LIMIT 1;")
    
    if [[ -z "$last" ]]; then
        echo -e "${RED}No requests in history${NC}"
        return 1
    fi
    
    local method=$(echo "$last" | cut -d'|' -f1)
    local url=$(echo "$last" | cut -d'|' -f2)
    local headers=$(echo "$last" | cut -d'|' -f3)
    local body=$(echo "$last" | cut -d'|' -f4)
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     🔧 Code Generation                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Language:${NC} $lang"
    echo ""
    
    case $lang in
        curl)
            echo "curl -X $method \\"
            if [[ -n "$headers" ]]; then
                echo "  -H 'Content-Type: application/json' \\"
            fi
            if [[ -n "$body" ]]; then
                echo "  -d '$body' \\"
            fi
            echo "  '$url'"
            ;;
        
        javascript|js|node)
            cat <<EOF
fetch('$url', {
  method: '$method',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify($body)
})
  .then(res => res.json())
  .then(data => console.log(data))
  .catch(err => console.error(err));
EOF
            ;;
        
        python|py)
            cat <<EOF
import requests

response = requests.$( echo $method | tr '[:upper:]' '[:lower:]')(
    '$url',
    json=$body,
    headers={'Content-Type': 'application/json'}
)

print(response.json())
EOF
            ;;
        
        go)
            cat <<EOF
package main

import (
    "bytes"
    "encoding/json"
    "net/http"
)

func main() {
    body := []byte(\`$body\`)
    req, _ := http.NewRequest("$method", "$url", bytes.NewBuffer(body))
    req.Header.Set("Content-Type", "application/json")
    
    client := &http.Client{}
    resp, _ := client.Do(req)
    defer resp.Body.Close()
}
EOF
            ;;
        
        *)
            echo -e "${RED}Unknown language: $lang${NC}"
            echo "Supported: curl, javascript, python, go"
            return 1
            ;;
    esac
    
    echo ""
    echo -e "${CYAN}Tip: Copy with 'br api code $lang | pbcopy'${NC}"
}

# Help
show_help() {
    cat <<EOF
BR API - Smart API Tester

Usage: br api {command} [args]

Commands:
  get <url>                - Make GET request
  post <url> <body>        - Make POST request
  put <url> <body>         - Make PUT request
  delete <url>             - Make DELETE request
  
  save <name>              - Save last request as endpoint
  run <name>               - Run saved endpoint
  list                     - List saved endpoints
  
  history [limit]          - Show request history
  code [language]          - Generate code from last request

Examples:
  br api get https://api.github.com/users/octocat
  br api post https://httpbin.org/post '{"key":"value"}'
  br api save github-user
  br api run github-user
  br api code python

Supported languages: curl, javascript, python, go

EOF
}

# Initialize database
init_db

# Main dispatch
case ${1:-help} in
    get|g)
        get_request "$2"
        ;;
    post|p)
        post_request "$2" "$3" "$4"
        ;;
    put)
        put_request "$2" "$3" "$4"
        ;;
    delete|del)
        delete_request "$2"
        ;;
    save|s)
        save_endpoint "$2"
        ;;
    run|r)
        run_saved "$2"
        ;;
    list|ls|l)
        list_saved
        ;;
    history|hist|h)
        show_history "$2"
        ;;
    code|gen)
        generate_code "$2"
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
