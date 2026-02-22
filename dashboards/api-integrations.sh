#!/bin/bash

# BlackRoad OS - API Integration Layer
# Real data connections for all dashboards

# API endpoints and keys
export GITHUB_API="https://api.github.com"
export CLOUDFLARE_API="https://api.cloudflare.com/client/v4"
export RAILWAY_API="https://backboard.railway.app/graphql"
export COINGECKO_API="https://api.coingecko.com/api/v3"
export STRIPE_API="https://api.stripe.com/v1"

# GitHub API calls
github_api() {
    local endpoint=$1
    curl -s -H "Accept: application/vnd.github+json" \
         -H "X-GitHub-Api-Version: 2022-11-28" \
         "$GITHUB_API/$endpoint"
}

# Get all BlackRoad organizations
get_github_orgs() {
    local orgs=(
        "BlackRoad-AI" "BlackRoad-Archive" "BlackRoad-Cloud"
        "BlackRoad-Education" "BlackRoad-Foundation" "BlackRoad-Gov"
        "BlackRoad-Hardware" "BlackRoad-Interactive" "BlackRoad-Labs"
        "BlackRoad-Media" "BlackRoad-OS" "BlackRoad-Security"
        "BlackRoad-Studio" "BlackRoad-Ventures" "Blackbox-Enterprises"
    )

    for org in "${orgs[@]}"; do
        echo "$org"
    done
}

# Get repo count for org
get_org_repo_count() {
    local org=$1
    gh repo list "$org" --json name --jq '. | length' 2>/dev/null || echo "0"
}

# Get total commit count across all orgs
get_total_commits() {
    local total=0
    for org in $(get_github_orgs); do
        local repos=$(gh repo list "$org" --limit 100 --json name --jq '.[].name' 2>/dev/null)
        for repo in $repos; do
            local count=$(gh api "repos/$org/$repo/commits" --jq '. | length' 2>/dev/null || echo "0")
            total=$((total + count))
        done
    done
    echo $total
}

# Crypto price APIs (CoinGecko - no key needed)
get_crypto_price() {
    local coin=$1  # bitcoin, ethereum, solana
    curl -s "$COINGECKO_API/simple/price?ids=$coin&vs_currencies=usd" | \
        jq -r ".$coin.usd"
}

# Calculate portfolio value
get_portfolio_value() {
    local eth_price=$(get_crypto_price "ethereum")
    local sol_price=$(get_crypto_price "solana")
    local btc_price=$(get_crypto_price "bitcoin")

    local eth_value=$(echo "2.5 * $eth_price" | bc)
    local sol_value=$(echo "100 * $sol_price" | bc)
    local btc_value=$(echo "0.1 * $btc_price" | bc)

    local total=$(echo "$eth_value + $sol_value + $btc_value" | bc)

    cat <<EOF
{
    "eth": {"amount": 2.5, "price": $eth_price, "value": $eth_value},
    "sol": {"amount": 100, "price": $sol_price, "value": $sol_value},
    "btc": {"amount": 0.1, "price": $btc_price, "value": $btc_value},
    "total": $total
}
EOF
}

# Cloudflare API (requires auth)
cloudflare_api() {
    local endpoint=$1
    # Note: Requires CLOUDFLARE_API_TOKEN env var
    if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
        curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
             -H "Content-Type: application/json" \
             "$CLOUDFLARE_API/$endpoint"
    else
        echo '{"error": "CLOUDFLARE_API_TOKEN not set"}'
    fi
}

# Get Cloudflare zones
get_cloudflare_zones() {
    cloudflare_api "zones" | jq -r '.result[] | .name'
}

# System metrics (real local data)
get_cpu_usage() {
    top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//'
}

get_memory_usage() {
    vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//'
}

get_disk_usage() {
    df -h / | tail -1 | awk '{print $5}' | sed 's/%//'
}

get_network_stats() {
    netstat -ib | awk 'NR>1 {rx+=$7; tx+=$10} END {print rx, tx}'
}

# Docker stats (if Docker running)
get_docker_containers() {
    if command -v docker &> /dev/null; then
        docker ps --format "{{.Names}},{{.Status}},{{.Image}}" 2>/dev/null || echo ""
    fi
}

# Railway API (requires auth)
railway_api() {
    local query=$1
    # Note: Requires RAILWAY_API_TOKEN env var
    if [ -n "$RAILWAY_API_TOKEN" ]; then
        curl -s -X POST "$RAILWAY_API" \
             -H "Authorization: Bearer $RAILWAY_API_TOKEN" \
             -H "Content-Type: application/json" \
             -d "{\"query\": \"$query\"}"
    else
        echo '{"error": "RAILWAY_API_TOKEN not set"}'
    fi
}

# Raspberry Pi network scan
scan_raspberry_pis() {
    local pis=(
        "192.168.4.38:lucidia"
        "192.168.4.64:blackroad-pi"
        "192.168.4.99:lucidia-alt"
        "192.168.4.68:iphone-koder"
    )

    for pi in "${pis[@]}"; do
        IFS=':' read -r ip name <<< "$pi"
        if ping -c 1 -W 1 "$ip" &>/dev/null; then
            echo "$name:online:$ip"
        else
            echo "$name:offline:$ip"
        fi
    done
}

# ISS location (no API key needed)
get_iss_location() {
    curl -s "http://api.open-notify.org/iss-now.json"
}

# Weather data (wttr.in - no key needed)
get_weather() {
    local location=${1:-"Minneapolis"}
    curl -s "wttr.in/${location}?format=j1"
}

# Earthquake data (USGS - no key needed)
get_recent_earthquakes() {
    curl -s "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.geojson"
}

# Satellite tracking (N2YO - requires key)
get_satellite_data() {
    local sat_id=${1:-25544}  # ISS by default
    if [ -n "$N2YO_API_KEY" ]; then
        curl -s "https://api.n2yo.com/rest/v1/satellite/positions/$sat_id/41.702/-76.014/0/1/&apiKey=$N2YO_API_KEY"
    else
        # Fallback to ISS location
        get_iss_location
    fi
}

# System uptime
get_system_uptime() {
    uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}'
}

# Load averages
get_load_average() {
    uptime | awk -F'load average:' '{print $2}' | xargs
}

# Active processes
get_process_count() {
    ps aux | wc -l
}

# Export functions
export -f github_api
export -f get_github_orgs
export -f get_org_repo_count
export -f get_crypto_price
export -f get_portfolio_value
export -f cloudflare_api
export -f get_cloudflare_zones
export -f get_cpu_usage
export -f get_memory_usage
export -f get_disk_usage
export -f get_network_stats
export -f get_docker_containers
export -f railway_api
export -f scan_raspberry_pis
export -f get_iss_location
export -f get_weather
export -f get_recent_earthquakes
export -f get_system_uptime
export -f get_load_average
export -f get_process_count
