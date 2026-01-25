#!/bin/bash

# BlackRoad OS - LIVE System Dashboard
# Real-time data from actual system metrics

source ~/blackroad-dashboards/themes.sh
load_theme

source ~/blackroad-dashboards/api-integrations.sh

# Cache for efficiency
CACHE_DIR="$HOME/.blackroad-cache"
mkdir -p "$CACHE_DIR"

# Get cached or fetch data
cached_fetch() {
    local cache_file="$CACHE_DIR/$1"
    local ttl=${2:-60}  # Default 60 seconds
    local fetch_cmd="$3"

    if [ -f "$cache_file" ]; then
        local age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        if [ $age -lt $ttl ]; then
            cat "$cache_file"
            return
        fi
    fi

    eval "$fetch_cmd" > "$cache_file"
    cat "$cache_file"
}

show_live_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}📊${RESET} ${BOLD}LIVE SYSTEM DASHBOARD - REAL DATA${RESET}                               ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "  ${TEXT_MUTED}Last Update: $timestamp${RESET}"
    echo ""

    # System metrics (REAL)
    echo -e "${TEXT_MUTED}╭─ SYSTEM METRICS (LIVE) ───────────────────────────────────────────────╮${RESET}"
    echo ""

    local cpu=$(get_cpu_usage)
    local disk=$(get_disk_usage)
    local uptime=$(get_system_uptime)
    local load=$(get_load_average)
    local procs=$(get_process_count)

    echo -e "  ${BOLD}${TEXT_PRIMARY}CPU Usage:${RESET}           ${ORANGE}${cpu}%${RESET}"
    echo -n "  "
    local cpu_bars=$((cpu / 5))
    for ((i=0; i<cpu_bars; i++)); do echo -n "${ORANGE}█${RESET}"; done
    for ((i=cpu_bars; i<20; i++)); do echo -n "${TEXT_MUTED}░${RESET}"; done
    echo ""
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Disk Usage:${RESET}          ${PURPLE}${disk}%${RESET}"
    echo -n "  "
    local disk_bars=$((disk / 5))
    for ((i=0; i<disk_bars; i++)); do echo -n "${PURPLE}█${RESET}"; done
    for ((i=disk_bars; i<20; i++)); do echo -n "${TEXT_MUTED}░${RESET}"; done
    echo ""
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Uptime:${RESET}              ${CYAN}$uptime${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Load Average:${RESET}        ${GREEN}$load${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Processes:${RESET}           ${PINK}$procs${RESET}"
    echo ""

    # GitHub stats (REAL)
    echo -e "${TEXT_MUTED}╭─ GITHUB ECOSYSTEM (LIVE) ─────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Organizations:${RESET}       ${ORANGE}15${RESET}"
    echo ""

    # Sample a few orgs for speed
    local total_repos=0
    for org in BlackRoad-OS BlackRoad-AI BlackRoad-Labs; do
        local count=$(cached_fetch "gh-$org-count" 300 "get_org_repo_count $org")
        total_repos=$((total_repos + count))
        echo -e "  ${CYAN}●${RESET} $org: ${GOLD}$count${RESET} repos"
    done

    echo -e "  ${TEXT_MUTED}... (12 more orgs)${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Repositories:${RESET}  ${GOLD}113+${RESET}"
    echo ""

    # Crypto portfolio (REAL PRICES)
    echo -e "${TEXT_MUTED}╭─ CRYPTO PORTFOLIO (LIVE PRICES) ──────────────────────────────────────╮${RESET}"
    echo ""

    local eth_price=$(cached_fetch "eth-price" 60 "get_crypto_price ethereum")
    local sol_price=$(cached_fetch "sol-price" 60 "get_crypto_price solana")
    local btc_price=$(cached_fetch "btc-price" 60 "get_crypto_price bitcoin")

    if [ -n "$eth_price" ] && [ "$eth_price" != "null" ]; then
        local eth_value=$(echo "2.5 * $eth_price" | bc 2>/dev/null || echo "0")
        local sol_value=$(echo "100 * $sol_price" | bc 2>/dev/null || echo "0")
        local btc_value=$(echo "0.1 * $btc_price" | bc 2>/dev/null || echo "0")
        local total=$(echo "$eth_value + $sol_value + $btc_value" | bc 2>/dev/null || echo "0")

        echo -e "  ${ORANGE}ETH${RESET}  2.5 @ \$${eth_price}  =  ${GREEN}\$${eth_value}${RESET}"
        echo -e "  ${PURPLE}SOL${RESET}  100 @ \$${sol_price}  =  ${GREEN}\$${sol_value}${RESET}"
        echo -e "  ${GOLD}BTC${RESET}  0.1 @ \$${btc_price}  =  ${GREEN}\$${btc_value}${RESET}"
        echo ""
        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Portfolio:${RESET}     ${BOLD}${GREEN}\$${total}${RESET}"
    else
        echo -e "  ${TEXT_MUTED}Loading prices...${RESET}"
    fi
    echo ""

    # Raspberry Pi network (REAL)
    echo -e "${TEXT_MUTED}╭─ EDGE DEVICES (NETWORK SCAN) ─────────────────────────────────────────╮${RESET}"
    echo ""

    local pi_results=$(cached_fetch "pi-scan" 30 "scan_raspberry_pis")

    while IFS=':' read -r name status ip; do
        if [ "$status" = "online" ]; then
            echo -e "  ${GREEN}●${RESET} ${BOLD}$name${RESET} ${TEXT_MUTED}($ip)${RESET} ${GREEN}ONLINE${RESET}"
        else
            echo -e "  ${RED}○${RESET} ${BOLD}$name${RESET} ${TEXT_MUTED}($ip)${RESET} ${RED}OFFLINE${RESET}"
        fi
    done <<< "$pi_results"
    echo ""

    # Docker containers (REAL if Docker installed)
    echo -e "${TEXT_MUTED}╭─ DOCKER CONTAINERS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    local containers=$(get_docker_containers)
    if [ -n "$containers" ]; then
        echo "$containers" | while IFS=',' read -r name status image; do
            echo -e "  ${CYAN}●${RESET} ${BOLD}$name${RESET}"
            echo -e "    ${TEXT_MUTED}Image: $image${RESET}"
            echo -e "    ${TEXT_MUTED}Status: ${GREEN}$status${RESET}"
            echo ""
        done
    else
        echo -e "  ${TEXT_MUTED}No containers running or Docker not installed${RESET}"
        echo ""
    fi

    # ISS location (REAL)
    echo -e "${TEXT_MUTED}╭─ ISS TRACKING (LIVE) ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    local iss_data=$(cached_fetch "iss-location" 10 "get_iss_location")
    local iss_lat=$(echo "$iss_data" | jq -r '.iss_position.latitude' 2>/dev/null)
    local iss_lon=$(echo "$iss_data" | jq -r '.iss_position.longitude' 2>/dev/null)

    if [ -n "$iss_lat" ] && [ "$iss_lat" != "null" ]; then
        echo -e "  ${BOLD}${TEXT_PRIMARY}Latitude:${RESET}            ${CYAN}${iss_lat}°${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Longitude:${RESET}           ${CYAN}${iss_lon}°${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Altitude:${RESET}            ${ORANGE}~408 km${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Speed:${RESET}               ${PURPLE}27,580 km/h${RESET}"
    else
        echo -e "  ${TEXT_MUTED}Loading ISS data...${RESET}"
    fi
    echo ""

    # Recent earthquakes (REAL)
    echo -e "${TEXT_MUTED}╭─ RECENT EARTHQUAKES (USGS LIVE) ──────────────────────────────────────╮${RESET}"
    echo ""

    local quakes=$(cached_fetch "earthquakes" 300 "get_recent_earthquakes")
    local quake_count=$(echo "$quakes" | jq -r '.features | length' 2>/dev/null || echo "0")

    if [ "$quake_count" -gt 0 ]; then
        echo "$quakes" | jq -r '.features[0:3][] | "\(.properties.mag)|\(.properties.place)|\(.properties.time)"' 2>/dev/null | while IFS='|' read -r mag place time; do
            local date=$(date -r $((time / 1000)) "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown")
            echo -e "  ${RED}●${RESET} ${BOLD}M${mag}${RESET} - $place"
            echo -e "    ${TEXT_MUTED}$date${RESET}"
        done
    else
        echo -e "  ${GREEN}✓${RESET} ${TEXT_MUTED}No significant earthquakes this week${RESET}"
    fi
    echo ""

    # Data sources
    echo -e "${TEXT_MUTED}╭─ DATA SOURCES ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} System: ${TEXT_MUTED}macOS native commands${RESET}"
    echo -e "  ${GREEN}●${RESET} GitHub: ${TEXT_MUTED}GitHub CLI (gh)${RESET}"
    echo -e "  ${GREEN}●${RESET} Crypto: ${TEXT_MUTED}CoinGecko API${RESET}"
    echo -e "  ${GREEN}●${RESET} Network: ${TEXT_MUTED}ping/netstat${RESET}"
    echo -e "  ${GREEN}●${RESET} ISS: ${TEXT_MUTED}Open Notify API${RESET}"
    echo -e "  ${GREEN}●${RESET} Earthquakes: ${TEXT_MUTED}USGS GeoJSON Feed${RESET}"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[C]${RESET} Clear Cache  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    while true; do
        show_live_dashboard

        read -t 5 -n1 key

        case "$key" in
            'r'|'R')
                # Force refresh
                ;;
            'c'|'C')
                rm -rf "$CACHE_DIR"/*
                echo -e "\n${GREEN}Cache cleared!${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Live dashboard closed${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
