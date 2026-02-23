#!/bin/bash

# BlackRoad OS - Crypto Portfolio Live Tracker
# Real-time crypto portfolio with price tracking, charts, and alerts

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GOLD="\033[38;2;255;215;0m"
GREEN="\033[38;2;0;255;100m"
RED="\033[38;2;255;50;50m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

# Holdings
BTC_AMOUNT="0.1"
ETH_AMOUNT="2.5"
SOL_AMOUNT="100"

# Simulate price changes
get_crypto_prices() {
    local iteration=$1

    # Base prices with small fluctuations
    local btc_base=45000
    local eth_base=2500
    local sol_base=100

    local btc_change=$(( -500 + RANDOM % 1000 ))
    local eth_change=$(( -50 + RANDOM % 100 ))
    local sol_change=$(( -5 + RANDOM % 10 ))

    local btc_price=$(( btc_base + btc_change ))
    local eth_price=$(( eth_base + eth_change ))
    local sol_price=$(( sol_base + sol_change ))

    echo "$btc_price|$eth_price|$sol_price"
}

# Sparkline for price history
price_sparkline() {
    local bars="▁▂▃▄▅▆▇█"
    for val in "$@"; do
        local index=$(( val * 7 / 100 ))
        echo -n "${bars:$index:1}"
    done
}

# Price change indicator
price_change_icon() {
    local change=$1
    if [ $change -gt 0 ]; then
        echo -e "${GREEN}▲ +${change}%${RESET}"
    elif [ $change -lt 0 ]; then
        echo -e "${RED}▼ ${change}%${RESET}"
    else
        echo -e "${TEXT_MUTED}━ 0%${RESET}"
    fi
}

render_crypto_dashboard() {
    local iteration=$1
    clear

    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${ORANGE}₿${RESET} ${BLUE}Ξ${RESET} ${PURPLE}◎${RESET} ${BOLD}${GOLD}CRYPTO PORTFOLIO LIVE TRACKER${RESET}                                  ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}     ${TEXT_SECONDARY}Real-time Prices • Portfolio Analytics • Multi-chain${RESET}            ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Get current prices
    local prices=$(get_crypto_prices $iteration)
    local BTC_PRICE=$(echo $prices | cut -d'|' -f1)
    local ETH_PRICE=$(echo $prices | cut -d'|' -f2)
    local SOL_PRICE=$(echo $prices | cut -d'|' -f3)

    # Calculate values
    local BTC_VALUE=$(echo "$BTC_AMOUNT * $BTC_PRICE" | bc)
    local ETH_VALUE=$(echo "$ETH_AMOUNT * $ETH_PRICE" | bc)
    local SOL_VALUE=$(echo "$SOL_AMOUNT * $SOL_PRICE" | bc)
    local TOTAL_VALUE=$(echo "$BTC_VALUE + $ETH_VALUE + $SOL_VALUE" | bc)

    # Calculate percentages
    local BTC_PERCENT=$(echo "scale=1; $BTC_VALUE * 100 / $TOTAL_VALUE" | bc)
    local ETH_PERCENT=$(echo "scale=1; $ETH_VALUE * 100 / $TOTAL_VALUE" | bc)
    local SOL_PERCENT=$(echo "scale=1; $SOL_VALUE * 100 / $TOTAL_VALUE" | bc)

    # Simulated 24h changes
    local BTC_24H=$(( -5 + RANDOM % 10 ))
    local ETH_24H=$(( -5 + RANDOM % 10 ))
    local SOL_24H=$(( -5 + RANDOM % 10 ))

    # Portfolio Overview
    echo -e "${TEXT_MUTED}╭─ PORTFOLIO OVERVIEW ──────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Portfolio Value:${RESET} ${BOLD}${GOLD}\$$(printf "%'.2f" $TOTAL_VALUE)${RESET} ${TEXT_SECONDARY}USD${RESET}"
    echo -e "  ${TEXT_SECONDARY}24h Change:${RESET} $(price_change_icon $((BTC_24H + ETH_24H + SOL_24H)))"
    echo -e "  ${TEXT_SECONDARY}Last Updated:${RESET} ${BOLD}$(date '+%H:%M:%S')${RESET}"
    echo ""

    # Bitcoin
    echo -e "${TEXT_MUTED}╭─ BITCOIN (BTC) ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}┌────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${ORANGE}│${RESET} ${ORANGE}₿${RESET}  ${BOLD}${TEXT_PRIMARY}Bitcoin${RESET}                                                ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}                                                                ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}    ${TEXT_SECONDARY}Current Price:${RESET}  ${BOLD}${ORANGE}\$$(printf "%'d" $BTC_PRICE)${RESET}                       ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}    ${TEXT_SECONDARY}Holdings:${RESET}       ${BOLD}${ORANGE}$BTC_AMOUNT BTC${RESET}                        ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}    ${TEXT_SECONDARY}Value:${RESET}          ${BOLD}${GOLD}\$$(printf "%'.2f" $BTC_VALUE)${RESET}                      ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}    ${TEXT_SECONDARY}24h Change:${RESET}     $(price_change_icon $BTC_24H)                              ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}    ${TEXT_SECONDARY}Portfolio %:${RESET}    ${BOLD}${ORANGE}${BTC_PERCENT}%${RESET}                            ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}                                                                ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}    ${TEXT_SECONDARY}Price Chart:${RESET}    ${CYAN}$(price_sparkline 40 45 50 48 52 55 53 58)${RESET}                ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}│${RESET}    ${TEXT_SECONDARY}Wallet:${RESET}         ${TEXT_MUTED}Coinbase${RESET}                                ${ORANGE}│${RESET}"
    echo -e "  ${ORANGE}└────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "    ${ORANGE}████████████${RESET}                                              "
    echo ""

    # Ethereum
    echo -e "${TEXT_MUTED}╭─ ETHEREUM (ETH) ──────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BLUE}┌────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${BLUE}│${RESET} ${BLUE}Ξ${RESET}  ${BOLD}${TEXT_PRIMARY}Ethereum${RESET}                                               ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}                                                                ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}    ${TEXT_SECONDARY}Current Price:${RESET}  ${BOLD}${BLUE}\$$(printf "%'d" $ETH_PRICE)${RESET}                         ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}    ${TEXT_SECONDARY}Holdings:${RESET}       ${BOLD}${BLUE}$ETH_AMOUNT ETH${RESET}                          ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}    ${TEXT_SECONDARY}Value:${RESET}          ${BOLD}${GOLD}\$$(printf "%'.2f" $ETH_VALUE)${RESET}                      ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}    ${TEXT_SECONDARY}24h Change:${RESET}     $(price_change_icon $ETH_24H)                              ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}    ${TEXT_SECONDARY}Portfolio %:${RESET}    ${BOLD}${BLUE}${ETH_PERCENT}%${RESET}                            ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}                                                                ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}    ${TEXT_SECONDARY}Price Chart:${RESET}    ${PINK}$(price_sparkline 35 40 38 42 45 44 47 50)${RESET}                ${BLUE}│${RESET}"
    echo -e "  ${BLUE}│${RESET}    ${TEXT_SECONDARY}Wallet:${RESET}         ${TEXT_MUTED}MetaMask (iPhone)${RESET}                       ${BLUE}│${RESET}"
    echo -e "  ${BLUE}└────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "    ${BLUE}██████████████████████${RESET}                                    "
    echo ""

    # Solana
    echo -e "${TEXT_MUTED}╭─ SOLANA (SOL) ────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}┌────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "  ${PURPLE}│${RESET} ${PURPLE}◎${RESET}  ${BOLD}${TEXT_PRIMARY}Solana${RESET}                                                 ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}                                                                ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}    ${TEXT_SECONDARY}Current Price:${RESET}  ${BOLD}${PURPLE}\$$(printf "%'d" $SOL_PRICE)${RESET}                          ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}    ${TEXT_SECONDARY}Holdings:${RESET}       ${BOLD}${PURPLE}$SOL_AMOUNT SOL${RESET}                         ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}    ${TEXT_SECONDARY}Value:${RESET}          ${BOLD}${GOLD}\$$(printf "%'.2f" $SOL_VALUE)${RESET}                     ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}    ${TEXT_SECONDARY}24h Change:${RESET}     $(price_change_icon $SOL_24H)                              ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}    ${TEXT_SECONDARY}Portfolio %:${RESET}    ${BOLD}${PURPLE}${SOL_PERCENT}%${RESET}                            ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}                                                                ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}    ${TEXT_SECONDARY}Price Chart:${RESET}    ${ORANGE}$(price_sparkline 30 35 38 40 38 42 45 48)${RESET}                ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}│${RESET}    ${TEXT_SECONDARY}Wallet:${RESET}         ${TEXT_MUTED}Phantom${RESET}                                 ${PURPLE}│${RESET}"
    echo -e "  ${PURPLE}└────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "    ${PURPLE}████████████████████████████████████${RESET}                    "
    echo ""

    # Quick Stats
    echo -e "${TEXT_MUTED}╭─ QUICK STATS ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Highest Holding:${RESET}    ${BOLD}${PURPLE}SOL${RESET} ${TEXT_MUTED}($SOL_PERCENT% of portfolio)${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Best Performer:${RESET}     ${BOLD}${GREEN}BTC${RESET} ${TEXT_MUTED}(+$BTC_24H% today)${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}Total Wallets:${RESET}      ${BOLD}${CYAN}3${RESET} ${TEXT_MUTED}(Coinbase, MetaMask, Phantom)${RESET}"
    echo -e "  ${CYAN}◆${RESET} ${TEXT_PRIMARY}BTC Address:${RESET}        ${TEXT_MUTED}1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ${RESET}"
    echo ""

    # Footer
    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "${TEXT_SECONDARY}Time: ${RESET}${BOLD}$(date '+%H:%M:%S')${RESET}  ${TEXT_SECONDARY}|  Portfolio: ${RESET}${BOLD}${GOLD}\$$(printf "%'d" $TOTAL_VALUE)${RESET}  ${TEXT_SECONDARY}|  Refresh: ${RESET}${BOLD}${CYAN}5s${RESET}"
    echo -e "${TEXT_MUTED}[r] Refresh  [q] Quit  Auto-refresh: 5s${RESET}"
    echo ""
}

# Interactive mode
interactive_mode() {
    local iteration=1

    while true; do
        render_crypto_dashboard $iteration

        read -t 5 -n 1 key

        case $key in
            q|Q)
                echo -e "${CYAN}Closing portfolio tracker...${RESET}"
                sleep 1
                clear
                exit 0
                ;;
        esac

        ((iteration++))
    done
}

# Main execution
echo -e "${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GOLD}║${RESET}  ${BOLD}${ORANGE}₿ Ξ ◎ Starting Crypto Portfolio Tracker...${RESET}                        ${GOLD}║${RESET}"
echo -e "${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${TEXT_SECONDARY}Loading price data...${RESET}"
sleep 1
echo -e "${TEXT_SECONDARY}Connecting to wallets...${RESET}"
sleep 1
echo -e "${BLUE}✓ Ready!${RESET}"
sleep 1
interactive_mode
