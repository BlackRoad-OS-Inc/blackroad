#!/bin/bash

# BlackRoad OS - Blockchain & Crypto Integration
# Track crypto wallets and blockchain data

source ~/blackroad-dashboards/themes.sh
load_theme

WALLET_FILE=~/blackroad-dashboards/.wallets
TRANSACTIONS_FILE=~/blackroad-dashboards/.transactions

touch "$WALLET_FILE" "$TRANSACTIONS_FILE"

# Crypto prices (simulated)
declare -A CRYPTO_PRICES=(
    ["BTC"]="67,234.50"
    ["ETH"]="3,842.75"
    ["SOL"]="142.38"
    ["MATIC"]="0.87"
    ["AVAX"]="38.92"
)

# Wallet balances
declare -A WALLETS=(
    ["BTC"]="0.1"
    ["ETH"]="2.5"
    ["SOL"]="100"
    ["MATIC"]="1000"
    ["AVAX"]="50"
)

# Calculate USD value
calculate_value() {
    local crypto=$1
    local balance=${WALLETS[$crypto]}
    local price=${CRYPTO_PRICES[$crypto]}

    # Remove commas from price
    price=$(echo "$price" | tr -d ',')

    # Calculate
    local value=$(echo "$balance * $price" | bc -l)
    printf "%.2f" "$value"
}

# Show blockchain dashboard
show_blockchain_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GOLD}║${RESET}  ${ORANGE}₿${RESET} ${BOLD}BLOCKCHAIN & CRYPTO DASHBOARD${RESET}                                    ${BOLD}${GOLD}║${RESET}"
    echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Portfolio overview
    echo -e "${TEXT_MUTED}╭─ PORTFOLIO OVERVIEW ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    local total_value=0
    for crypto in "${!WALLETS[@]}"; do
        local value=$(calculate_value "$crypto")
        total_value=$(echo "$total_value + $value" | bc -l)
    done

    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Value:${RESET}         ${BOLD}${GREEN}\$$(printf "%.2f" "$total_value")${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}24h Change:${RESET}          ${GREEN}+\$4,237.50${RESET} ${GREEN}(+3.2%)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}All-Time High:${RESET}       ${CYAN}\$142,847.00${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}All-Time Low:${RESET}        ${ORANGE}\$12,450.00${RESET}"
    echo ""

    # Holdings
    echo -e "${TEXT_MUTED}╭─ HOLDINGS ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    for crypto in BTC ETH SOL MATIC AVAX; do
        local balance=${WALLETS[$crypto]}
        local price=${CRYPTO_PRICES[$crypto]}
        local value=$(calculate_value "$crypto")

        # Color based on crypto
        local color
        case "$crypto" in
            BTC) color="${GOLD}" ;;
            ETH) color="${PURPLE}" ;;
            SOL) color="${CYAN}" ;;
            MATIC) color="${BLUE}" ;;
            AVAX) color="${RED}" ;;
        esac

        echo -e "  ${color}●${RESET} ${BOLD}$crypto${RESET}"
        echo -e "     ${TEXT_SECONDARY}Balance:${RESET} ${BOLD}$balance${RESET} $crypto"
        echo -e "     ${TEXT_SECONDARY}Price:${RESET} ${GREEN}\$$price${RESET}  ${TEXT_SECONDARY}Value:${RESET} ${BOLD}${GREEN}\$$value${RESET}"
        echo ""
    done

    # Live prices
    echo -e "${TEXT_MUTED}╭─ LIVE PRICES ─────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GOLD}BTC${RESET}   ${GREEN}▁▂▃▄▅▆▇█▇▆▅▄▃▂▁${RESET}  ${BOLD}\$${CRYPTO_PRICES[BTC]}${RESET}  ${GREEN}↑ 2.4%${RESET}"
    echo -e "  ${PURPLE}ETH${RESET}   ${GREEN}▁▂▃▄▅▆▇█▇▆▅▄▃${RESET}    ${BOLD}\$${CRYPTO_PRICES[ETH]}${RESET}   ${GREEN}↑ 3.1%${RESET}"
    echo -e "  ${CYAN}SOL${RESET}   ${ORANGE}▁▂▃▄▅▆▇█${RESET}          ${BOLD}\$${CRYPTO_PRICES[SOL]}${RESET}    ${ORANGE}↑ 5.7%${RESET}"
    echo -e "  ${BLUE}MATIC${RESET} ${RED}▁▂▃▄▅${RESET}              ${BOLD}\$${CRYPTO_PRICES[MATIC]}${RESET}      ${RED}↓ 1.2%${RESET}"
    echo -e "  ${RED}AVAX${RESET}  ${GREEN}▁▂▃▄▅▆▇${RESET}           ${BOLD}\$${CRYPTO_PRICES[AVAX]}${RESET}     ${GREEN}↑ 4.3%${RESET}"
    echo ""

    # Recent transactions
    echo -e "${TEXT_MUTED}╭─ RECENT TRANSACTIONS ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}●${RESET} ${TEXT_MUTED}[2 hours ago]${RESET} ${BOLD}Received${RESET} ${CYAN}10 SOL${RESET}"
    echo -e "     ${TEXT_SECONDARY}From:${RESET} ${TEXT_MUTED}0x742d...9a1f${RESET}  ${TEXT_SECONDARY}Tx:${RESET} ${TEXT_MUTED}0x8f2a...${RESET}"
    echo ""
    echo -e "  ${ORANGE}●${RESET} ${TEXT_MUTED}[5 hours ago]${RESET} ${BOLD}Sent${RESET} ${PURPLE}0.5 ETH${RESET}"
    echo -e "     ${TEXT_SECONDARY}To:${RESET} ${TEXT_MUTED}0x1a2b...3c4d${RESET}  ${TEXT_SECONDARY}Fee:${RESET} ${TEXT_MUTED}\$12.34${RESET}"
    echo ""
    echo -e "  ${GREEN}●${RESET} ${TEXT_MUTED}[1 day ago]${RESET} ${BOLD}Swap${RESET} ${BLUE}100 MATIC${RESET} → ${RED}1.2 AVAX${RESET}"
    echo -e "     ${TEXT_SECONDARY}DEX:${RESET} ${TEXT_MUTED}Uniswap${RESET}  ${TEXT_SECONDARY}Slippage:${RESET} ${TEXT_MUTED}0.5%${RESET}"
    echo ""

    # NFT Collection
    echo -e "${TEXT_MUTED}╭─ NFT COLLECTION ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${PURPLE}🖼${RESET}  ${BOLD}Bored Ape #8472${RESET}  ${GREEN}\$85,000${RESET}  ${TEXT_MUTED}Floor: \$82K${RESET}"
    echo -e "  ${PINK}🖼${RESET}  ${BOLD}CryptoPunk #3842${RESET}  ${GREEN}\$142,000${RESET}  ${TEXT_MUTED}Floor: \$138K${RESET}"
    echo -e "  ${CYAN}🖼${RESET}  ${BOLD}Azuki #2847${RESET}      ${GREEN}\$28,000${RESET}  ${TEXT_MUTED}Floor: \$26K${RESET}"
    echo ""

    # DeFi Positions
    echo -e "${TEXT_MUTED}╭─ DEFI POSITIONS ──────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${PURPLE}◉${RESET} ${BOLD}Aave ETH Lending${RESET}"
    echo -e "     ${TEXT_SECONDARY}Supplied:${RESET} ${BOLD}1.5 ETH${RESET}  ${TEXT_SECONDARY}APY:${RESET} ${GREEN}4.2%${RESET}  ${TEXT_SECONDARY}Earned:${RESET} ${GREEN}\$234${RESET}"
    echo ""
    echo -e "  ${CYAN}◉${RESET} ${BOLD}Uniswap SOL/USDC LP${RESET}"
    echo -e "     ${TEXT_SECONDARY}Liquidity:${RESET} ${BOLD}\$8,420${RESET}  ${TEXT_SECONDARY}APR:${RESET} ${GREEN}23.7%${RESET}  ${TEXT_SECONDARY}Fees:${RESET} ${GREEN}\$147${RESET}"
    echo ""

    # Blockchain stats
    echo -e "${TEXT_MUTED}╭─ BLOCKCHAIN STATS ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}${TEXT_PRIMARY}Gas (ETH):${RESET}           ${ORANGE}42 gwei${RESET} ${TEXT_MUTED}(normal)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Block Height:${RESET}        ${CYAN}18,234,567${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Network:${RESET}             ${GREEN}Healthy${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Mempool:${RESET}             ${ORANGE}12,847 txs${RESET}"
    echo ""

    echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[W]${RESET} Wallets  ${TEXT_SECONDARY}[T]${RESET} Transactions  ${TEXT_SECONDARY}[N]${RESET} NFTs  ${TEXT_SECONDARY}[D]${RESET} DeFi  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Show wallet details
show_wallet_details() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}WALLET DETAILS${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ETH WALLET ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Address:${RESET}"
    echo -e "    ${CYAN}0x742d35Cc6634C0532925a3b844Bc9e7595f9a1f${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Balance:${RESET}         ${BOLD}2.5 ETH${RESET} ${TEXT_MUTED}(\$9,606.88)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Tokens:${RESET}          ${BOLD}4${RESET} ${TEXT_MUTED}different tokens${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}NFTs:${RESET}            ${BOLD}12${RESET} ${TEXT_MUTED}items${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Transactions:${RESET}    ${BOLD}847${RESET} ${TEXT_MUTED}total${RESET}"
    echo ""

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Main loop
main() {
    while true; do
        show_blockchain_dashboard

        read -n1 key

        case "$key" in
            'w'|'W')
                show_wallet_details
                ;;
            't'|'T')
                echo -e "\n${CYAN}Transaction history...${RESET}"
                sleep 1
                ;;
            'n'|'N')
                echo -e "\n${PURPLE}NFT collection...${RESET}"
                sleep 1
                ;;
            'd'|'D')
                echo -e "\n${GREEN}DeFi positions...${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye!${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
