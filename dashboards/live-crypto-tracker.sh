#!/bin/bash

# BlackRoad OS - LIVE Crypto Portfolio Tracker
# Real-time prices from CoinGecko API

source ~/blackroad-dashboards/themes.sh
load_theme

source ~/blackroad-dashboards/api-integrations.sh

CACHE_DIR="$HOME/.blackroad-cache"
mkdir -p "$CACHE_DIR"

# Portfolio holdings
ETH_AMOUNT=2.5
SOL_AMOUNT=100
BTC_AMOUNT=0.1

# Historical prices (for 24h change calculation)
declare -A PREV_PRICES

show_crypto_tracker() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${ORANGE}💰${RESET} ${BOLD}LIVE CRYPTO PORTFOLIO TRACKER${RESET}                                   ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S UTC")
    echo -e "  ${TEXT_MUTED}Last Update: $timestamp${RESET}"
    echo ""

    # Fetch current prices
    echo -e "${TEXT_MUTED}Fetching live prices from CoinGecko...${RESET}\n"

    local eth_price=$(get_crypto_price "ethereum")
    local sol_price=$(get_crypto_price "solana")
    local btc_price=$(get_crypto_price "bitcoin")

    # Check if API calls succeeded
    if [ -z "$eth_price" ] || [ "$eth_price" = "null" ]; then
        echo -e "${RED}Error: Unable to fetch crypto prices${RESET}"
        echo -e "${TEXT_MUTED}Check your internet connection or API availability${RESET}\n"
        echo -e "${TEXT_MUTED}Press Q to quit, R to retry...${RESET}"
        return
    fi

    # Calculate portfolio values
    local eth_value=$(echo "$ETH_AMOUNT * $eth_price" | bc)
    local sol_value=$(echo "$SOL_AMOUNT * $sol_price" | bc)
    local btc_value=$(echo "$BTC_AMOUNT * $btc_price" | bc)
    local total_value=$(echo "$eth_value + $sol_value + $btc_value" | bc)

    # Portfolio breakdown
    echo -e "${TEXT_MUTED}╭─ PORTFOLIO HOLDINGS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Ethereum
    echo -e "  ${ORANGE}◆${RESET} ${BOLD}ETHEREUM (ETH)${RESET}"
    echo -e "    Holdings:  ${CYAN}$ETH_AMOUNT ETH${RESET}"
    echo -e "    Price:     ${GREEN}\$${eth_price}${RESET}"
    echo -e "    Value:     ${BOLD}${GREEN}\$${eth_value}${RESET}"
    echo -e "    Wallet:    ${TEXT_MUTED}MetaMask (iPhone)${RESET}"
    echo ""

    # Solana
    echo -e "  ${PURPLE}◆${RESET} ${BOLD}SOLANA (SOL)${RESET}"
    echo -e "    Holdings:  ${CYAN}$SOL_AMOUNT SOL${RESET}"
    echo -e "    Price:     ${GREEN}\$${sol_price}${RESET}"
    echo -e "    Value:     ${BOLD}${GREEN}\$${sol_value}${RESET}"
    echo -e "    Wallet:    ${TEXT_MUTED}Phantom${RESET}"
    echo ""

    # Bitcoin
    echo -e "  ${GOLD}◆${RESET} ${BOLD}BITCOIN (BTC)${RESET}"
    echo -e "    Holdings:  ${CYAN}$BTC_AMOUNT BTC${RESET}"
    echo -e "    Price:     ${GREEN}\$${btc_price}${RESET}"
    echo -e "    Value:     ${BOLD}${GREEN}\$${btc_value}${RESET}"
    echo -e "    Wallet:    ${TEXT_MUTED}Coinbase${RESET}"
    echo -e "    Address:   ${TEXT_MUTED}1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ${RESET}"
    echo ""

    # Total portfolio
    echo -e "${TEXT_MUTED}╭─ PORTFOLIO SUMMARY ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Value:${RESET}         ${BOLD}${GREEN}\$${total_value}${RESET}"
    echo ""

    # Allocation breakdown
    local eth_pct=$(echo "scale=1; $eth_value / $total_value * 100" | bc)
    local sol_pct=$(echo "scale=1; $sol_value / $total_value * 100" | bc)
    local btc_pct=$(echo "scale=1; $btc_value / $total_value * 100" | bc)

    echo -e "  ${BOLD}Allocation:${RESET}"
    echo -n "  "
    echo -e "${ORANGE}█${RESET}" | tr -d '\n'
    printf "%.0f%% ETH  " "$eth_pct"
    echo -e "${PURPLE}█${RESET}" | tr -d '\n'
    printf "%.0f%% SOL  " "$sol_pct"
    echo -e "${GOLD}█${RESET}" | tr -d '\n'
    printf "%.0f%% BTC\n" "$btc_pct"
    echo ""

    # Visual allocation bar
    local eth_bars=$(echo "$eth_pct / 5" | bc)
    local sol_bars=$(echo "$sol_pct / 5" | bc)
    local btc_bars=$(echo "$btc_pct / 5" | bc)

    echo -n "  "
    for ((i=0; i<eth_bars; i++)); do echo -n "${ORANGE}█${RESET}"; done
    for ((i=0; i<sol_bars; i++)); do echo -n "${PURPLE}█${RESET}"; done
    for ((i=0; i<btc_bars; i++)); do echo -n "${GOLD}█${RESET}"; done
    echo ""
    echo ""

    # Market data
    echo -e "${TEXT_MUTED}╭─ MARKET DATA (24H) ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Get 24h change data
    local market_data=$(curl -s "$COINGECKO_API/simple/price?ids=ethereum,solana,bitcoin&vs_currencies=usd&include_24hr_change=true")

    local eth_change=$(echo "$market_data" | jq -r '.ethereum.usd_24h_change' 2>/dev/null)
    local sol_change=$(echo "$market_data" | jq -r '.solana.usd_24h_change' 2>/dev/null)
    local btc_change=$(echo "$market_data" | jq -r '.bitcoin.usd_24h_change' 2>/dev/null)

    # Format changes with color
    if [ -n "$eth_change" ] && [ "$eth_change" != "null" ]; then
        local eth_color="${GREEN}"
        local eth_arrow="▲"
        if (( $(echo "$eth_change < 0" | bc -l) )); then
            eth_color="${RED}"
            eth_arrow="▼"
        fi
        printf "  ETH: %s%s %.2f%%${RESET}\n" "$eth_color" "$eth_arrow" "${eth_change#-}"
    fi

    if [ -n "$sol_change" ] && [ "$sol_change" != "null" ]; then
        local sol_color="${GREEN}"
        local sol_arrow="▲"
        if (( $(echo "$sol_change < 0" | bc -l) )); then
            sol_color="${RED}"
            sol_arrow="▼"
        fi
        printf "  SOL: %s%s %.2f%%${RESET}\n" "$sol_color" "$sol_arrow" "${sol_change#-}"
    fi

    if [ -n "$btc_change" ] && [ "$btc_change" != "null" ]; then
        local btc_color="${GREEN}"
        local btc_arrow="▲"
        if (( $(echo "$btc_change < 0" | bc -l) )); then
            btc_color="${RED}"
            btc_arrow="▼"
        fi
        printf "  BTC: %s%s %.2f%%${RESET}\n" "$btc_color" "$btc_arrow" "${btc_change#-}"
    fi
    echo ""

    # Price history sparkline (simulated)
    echo -e "${TEXT_MUTED}╭─ PRICE TRENDS ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}ETH${RESET}  ${TEXT_MUTED}▁▂▃▅▆▇█▇▆▅▄▃▂▃▄▅▆▇${RESET}"
    echo -e "  ${PURPLE}SOL${RESET}  ${TEXT_MUTED}▃▄▅▆▅▄▃▂▃▄▅▆▇█▇▆▅${RESET}"
    echo -e "  ${GOLD}BTC${RESET}  ${TEXT_MUTED}▄▅▆▅▄▃▂▁▂▃▄▅▆▇█▇▆${RESET}"
    echo ""

    # Data source
    echo -e "${TEXT_MUTED}╭─ DATA SOURCE ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${TEXT_MUTED}CoinGecko API (Free, No Key Required)${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_MUTED}Updated every 5 seconds${RESET}"
    echo -e "  ${GREEN}●${RESET} ${TEXT_MUTED}USD prices${RESET}"
    echo ""

    # Wallet info
    echo -e "${TEXT_MUTED}╭─ WALLETS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}MetaMask${RESET}  ${TEXT_MUTED}ETH wallet on iPhone${RESET}"
    echo -e "  ${PURPLE}Phantom${RESET}   ${TEXT_MUTED}SOL wallet${RESET}"
    echo -e "  ${GOLD}Coinbase${RESET}  ${TEXT_MUTED}BTC exchange${RESET}"
    echo ""

    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[R]${RESET} Refresh  ${TEXT_SECONDARY}[E]${RESET} Export  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Export portfolio to JSON
export_portfolio() {
    local output_file="$HOME/crypto-portfolio-$(date +%Y%m%d-%H%M%S).json"

    local eth_price=$(get_crypto_price "ethereum")
    local sol_price=$(get_crypto_price "solana")
    local btc_price=$(get_crypto_price "bitcoin")

    local eth_value=$(echo "$ETH_AMOUNT * $eth_price" | bc)
    local sol_value=$(echo "$SOL_AMOUNT * $sol_price" | bc)
    local btc_value=$(echo "$BTC_AMOUNT * $btc_price" | bc)
    local total_value=$(echo "$eth_value + $sol_value + $btc_value" | bc)

    cat > "$output_file" <<EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "holdings": {
        "eth": {
            "amount": $ETH_AMOUNT,
            "price_usd": $eth_price,
            "value_usd": $eth_value,
            "wallet": "MetaMask"
        },
        "sol": {
            "amount": $SOL_AMOUNT,
            "price_usd": $sol_price,
            "value_usd": $sol_value,
            "wallet": "Phantom"
        },
        "btc": {
            "amount": $BTC_AMOUNT,
            "price_usd": $btc_price,
            "value_usd": $btc_value,
            "wallet": "Coinbase",
            "address": "1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ"
        }
    },
    "total_value_usd": $total_value
}
EOF

    echo -e "\n${GREEN}✓ Portfolio exported to:${RESET}"
    echo -e "${CYAN}$output_file${RESET}\n"
    sleep 2
}

# Main loop
main() {
    while true; do
        show_crypto_tracker

        read -t 5 -n1 key

        case "$key" in
            'r'|'R')
                # Force refresh
                ;;
            'e'|'E')
                export_portfolio
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Crypto tracker closed${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
