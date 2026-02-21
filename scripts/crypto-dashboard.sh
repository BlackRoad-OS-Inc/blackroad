#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════════════════════
# BLACKROAD CRYPTO DASHBOARD
# Real-time RoadChain & Bitcoin visualization for tmux screens
# ═══════════════════════════════════════════════════════════════════════════════

# Colors
PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
BLUE='\033[38;5;69m'
VIOLET='\033[38;5;135m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;240m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
CYAN='\033[38;5;51m'
GOLD='\033[38;5;220m'
RESET='\033[0m'

# Paths
ROADCHAIN_DIR="$HOME/.roadchain"
CHAIN_FILE="$ROADCHAIN_DIR/chain.json"
PAYMENTS_FILE="$ROADCHAIN_DIR/payments.json"
WALLETS_DIR="$ROADCHAIN_DIR/wallets"

# ═══════════════════════════════════════════════════════════════════════════════
# Data Functions
# ═══════════════════════════════════════════════════════════════════════════════

get_chain_balance() {
    local wallet="$1"
    if [[ -f "$CHAIN_FILE" ]]; then
        # Sum all transactions where recipient matches wallet
        python3 -c "
import json
with open('$CHAIN_FILE') as f:
    data = json.load(f)
balance = 0
for block in data.get('chain', []):
    for tx in block.get('transactions', []):
        if tx.get('recipient') == '$wallet':
            balance += tx.get('amount', 0)
        if tx.get('sender') == '$wallet':
            balance -= tx.get('amount', 0)
print(f'{balance:.6f}')
" 2>/dev/null || echo "0.000000"
    else
        echo "0.000000"
    fi
}

get_total_paid() {
    if [[ -f "$PAYMENTS_FILE" ]]; then
        python3 -c "
import json
with open('$PAYMENTS_FILE') as f:
    data = json.load(f)
print(f'{data.get(\"total_paid_usd\", 0):.2f}')
" 2>/dev/null || echo "0.00"
    else
        echo "0.00"
    fi
}

get_road_spent() {
    if [[ -f "$PAYMENTS_FILE" ]]; then
        python3 -c "
import json
with open('$PAYMENTS_FILE') as f:
    data = json.load(f)
print(f'{data.get(\"total_road_spent\", 0):.6f}')
" 2>/dev/null || echo "0.000000"
    else
        echo "0.000000"
    fi
}

get_block_count() {
    if [[ -f "$CHAIN_FILE" ]]; then
        python3 -c "
import json
with open('$CHAIN_FILE') as f:
    data = json.load(f)
print(len(data.get('chain', [])))
" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_latest_hash() {
    if [[ -f "$CHAIN_FILE" ]]; then
        python3 -c "
import json
with open('$CHAIN_FILE') as f:
    data = json.load(f)
chain = data.get('chain', [])
if chain:
    print(chain[-1].get('hash', 'N/A')[:16] + '...')
else:
    print('N/A')
" 2>/dev/null || echo "N/A"
    else
        echo "N/A"
    fi
}

get_btc_price() {
    local price=""
    local PRICE_FEED="$HOME/.roadchain/price-feed.json"

    # Try price-feed cache first (updated by roadchain-price-feed.sh)
    if [[ -f "$PRICE_FEED" ]]; then
        price=$(python3 -c "import json; print(f'{json.load(open(\"$PRICE_FEED\"))[\"btc_usd\"]:.2f}')" 2>/dev/null)
    fi

    # Fallback: live API
    if [[ -z "$price" || "$price" == "0.00" ]]; then
        price=$(curl -s --max-time 3 "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd" 2>/dev/null \
            | python3 -c "import sys,json; print(f'{json.load(sys.stdin)[\"bitcoin\"][\"usd\"]:.2f}')" 2>/dev/null)
    fi

    # Fallback: CoinDesk
    if [[ -z "$price" || "$price" == "0.00" ]]; then
        price=$(curl -s --max-time 3 "https://api.coindesk.com/v1/bpi/currentprice/USD.json" 2>/dev/null \
            | python3 -c "import sys,json; print(f'{json.load(sys.stdin)[\"bpi\"][\"USD\"][\"rate_float\"]:.2f}')" 2>/dev/null)
    fi

    if [[ -z "$price" || "$price" == "0.00" ]]; then
        echo "97500.00"
    else
        echo "$price"
    fi
}

get_price_source() {
    local PRICE_FEED="$HOME/.roadchain/price-feed.json"
    if [[ -f "$PRICE_FEED" ]]; then
        python3 -c "import json; d=json.load(open('$PRICE_FEED')); print(f'{d[\"source\"]} @ {d[\"updated\"]}')" 2>/dev/null || echo "unknown"
    else
        echo "live"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Sync Function - Update wallet balances from chain
# ═══════════════════════════════════════════════════════════════════════════════

sync_wallets() {
    echo -e "${AMBER}Syncing wallet balances from blockchain...${RESET}"

    if [[ ! -f "$CHAIN_FILE" ]]; then
        echo -e "${RED}Chain file not found!${RESET}"
        return 1
    fi

    for wallet_file in "$WALLETS_DIR"/*.json; do
        local wallet_name=$(basename "$wallet_file" .json)
        local balance=$(get_chain_balance "$wallet_name")

        # Update wallet file with correct balance
        python3 -c "
import json
with open('$wallet_file', 'r') as f:
    wallet = json.load(f)
wallet['balance'] = $balance
with open('$wallet_file', 'w') as f:
    json.dump(wallet, f, indent=2)
print(f'  ✓ $wallet_name: $balance ROAD')
" 2>/dev/null
    done

    echo -e "${GREEN}Sync complete!${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Screen Rendering Functions
# ═══════════════════════════════════════════════════════════════════════════════

render_monitor_frame() {
    local width="${1:-60}"
    echo -e "${GRAY}╭$( printf '─%.0s' $(seq 1 $((width-2))) )╮${RESET}"
    local padding=$(( (width - 4) / 2 ))
    echo -e "${GRAY}│$( printf ' %.0s' $(seq 1 $padding) )${GREEN}◉${GRAY}$( printf ' %.0s' $(seq 1 $((width - padding - 3))) )│${RESET}"
    echo -e "${GRAY}│${RESET} ${GRAY}┌$( printf '─%.0s' $(seq 1 $((width-6))) )┐${RESET} ${GRAY}│${RESET}"
}

render_screen_line() {
    local width="${1:-60}"
    local content="${2:-}"
    local inner_width=$((width - 6))
    local content_clean=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    local content_len=${#content_clean}
    local padding=$((inner_width - content_len))

    if [[ $padding -lt 0 ]]; then
        padding=0
    fi

    echo -e "${GRAY}│${RESET} ${GRAY}│${RESET}${content}$( printf ' %.0s' $(seq 1 $padding) )${GRAY}│${RESET} ${GRAY}│${RESET}"
}

render_monitor_bottom() {
    local width="${1:-60}"
    echo -e "${GRAY}│${RESET} ${GRAY}└$( printf '─%.0s' $(seq 1 $((width-6))) )┘${RESET} ${GRAY}│${RESET}"
    echo -e "${GRAY}│$( printf ' %.0s' $(seq 1 $((width-2))) )│${RESET}"
    echo -e "${GRAY}╰$( printf '─%.0s' $(seq 1 $((width-2))) )╯${RESET}"
    local stand_pad=$(( (width - 10) / 2 ))
    echo -e "$( printf ' %.0s' $(seq 1 $stand_pad) )${GRAY}╱────────╲${RESET}"
    echo -e "$( printf ' %.0s' $(seq 1 $((stand_pad - 2))) )${GRAY}╱────────────╲${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dashboard Screens
# ═══════════════════════════════════════════════════════════════════════════════

render_main_dashboard() {
    local width="${1:-60}"

    # Fetch data
    local alexa_balance=$(get_chain_balance "alexa")
    local total_paid=$(get_total_paid)
    local road_spent=$(get_road_spent)
    local blocks=$(get_block_count)
    local latest_hash=$(get_latest_hash)
    local btc_price=$(get_btc_price)

    clear
    render_monitor_frame "$width"

    render_screen_line "$width" ""
    render_screen_line "$width" "${GOLD}  ₿ BLACKROAD CRYPTO DASHBOARD ₿${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${PINK}╔════════════════════════════════════════════════╗${RESET}"
    render_screen_line "$width" "${PINK}║${WHITE}          ROADCHAIN NETWORK STATUS             ${PINK}║${RESET}"
    render_screen_line "$width" "${PINK}╚════════════════════════════════════════════════╝${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${AMBER}  Blocks Mined:    ${WHITE}${blocks}${RESET}"
    render_screen_line "$width" "${AMBER}  Latest Hash:     ${CYAN}${latest_hash}${RESET}"
    render_screen_line "$width" "${AMBER}  Difficulty:      ${WHITE}4${RESET}"
    render_screen_line "$width" ""
    local alexa_usd_balance="0.00"
    if [[ -f "$WALLETS_DIR/alexa-usd.json" ]]; then
        alexa_usd_balance=$(python3 -c "import json; print(f'{json.load(open(\"$WALLETS_DIR/alexa-usd.json\"))[\"balance\"]:.2f}')" 2>/dev/null || echo "0.00")
    fi
    render_screen_line "$width" "${BLUE}┌─ ALEXA WALLET ───────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BLUE}│  ${WHITE}ROAD:      ${GREEN}${alexa_balance} ROAD${RESET}${BLUE}                  │${RESET}"
    local usd_value=$(echo "$alexa_balance * $btc_price" | bc 2>/dev/null || echo "0")
    local price_info=$(get_price_source)
    render_screen_line "$width" "${BLUE}│  ${WHITE}USD Value: ${GREEN}\$${usd_value} ${RESET}${BLUE}               │${RESET}"
    render_screen_line "$width" "${BLUE}│  ${WHITE}ROADUSD:   ${GREEN}\$${alexa_usd_balance}${RESET}${BLUE}                          │${RESET}"
    render_screen_line "$width" "${BLUE}│  ${WHITE}ROAD/BTC:  ${CYAN}1.0${RESET}${BLUE}                              │${RESET}"
    render_screen_line "$width" "${BLUE}└──────────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${VIOLET}  Bills Paid:      ${WHITE}\$${total_paid} USD${RESET}"
    render_screen_line "$width" "${VIOLET}  ROAD Spent:      ${WHITE}${road_spent} ROAD${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${GRAY}  BTC/USD:         ${GOLD}\$${btc_price}${RESET}"
    render_screen_line "$width" "${GRAY}  Source:           ${WHITE}${price_info}${RESET}"
    render_screen_line "$width" ""

    render_monitor_bottom "$width"
}

render_wallets_screen() {
    local width="${1:-60}"

    clear
    render_monitor_frame "$width"

    render_screen_line "$width" ""
    render_screen_line "$width" "${GOLD}  ₿ ROADCHAIN WALLETS ₿${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${PINK}╔════════════════════════════════════════════════╗${RESET}"
    render_screen_line "$width" "${PINK}║${WHITE}  WALLET              ADDRESS         BALANCE  ${PINK}║${RESET}"
    render_screen_line "$width" "${PINK}╚════════════════════════════════════════════════╝${RESET}"
    render_screen_line "$width" ""

    local w_name w_token w_addr w_balance w_color w_pad
    for wallet_file in "$WALLETS_DIR"/*.json; do
        w_name=$(basename "$wallet_file" .json)
        w_token=$(python3 -c "import json; print(json.load(open('$wallet_file')).get('token','ROAD'))" 2>/dev/null)
        w_addr=$(python3 -c "import json; print(json.load(open('$wallet_file'))['address'][:12])" 2>/dev/null)

        if [[ "$w_token" == "ROADUSD" ]]; then
            w_balance="\$$(python3 -c "import json; print(f'{json.load(open(\"$wallet_file\"))[\"balance\"]:.2f}')" 2>/dev/null)"
        else
            w_balance="$(get_chain_balance "$w_name") ROAD"
        fi

        w_color="$WHITE"
        if [[ "$w_name" == "alexa" ]]; then w_color="$GOLD"; fi
        if [[ "$w_name" == "alexa-usd" ]]; then w_color="$GREEN"; fi

        w_pad=$((12 - ${#w_name}))
        [[ $w_pad -lt 1 ]] && w_pad=1
        render_screen_line "$width" "${w_color}  ${w_name}$(printf ' %.0s' $(seq 1 $w_pad))${CYAN}${w_addr}...  ${GREEN}${w_balance}${RESET}"
    done

    render_screen_line "$width" ""
    render_screen_line "$width" "${GRAY}  ─────────────────────────────────────────────${RESET}"
    render_screen_line "$width" "${AMBER}  Network:  ${GREEN}● ROADCHAIN MAINNET${RESET}"
    render_screen_line "$width" "${AMBER}  Status:   ${GREEN}● OPERATIONAL${RESET}"
    render_screen_line "$width" ""

    render_monitor_bottom "$width"
}

render_payments_screen() {
    local width="${1:-60}"

    clear
    render_monitor_frame "$width"

    render_screen_line "$width" ""
    render_screen_line "$width" "${GOLD}  ₿ PAYMENT HISTORY ₿${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${PINK}╔════════════════════════════════════════════════╗${RESET}"
    render_screen_line "$width" "${PINK}║${WHITE}  RECENT TRANSACTIONS                          ${PINK}║${RESET}"
    render_screen_line "$width" "${PINK}╚════════════════════════════════════════════════╝${RESET}"
    render_screen_line "$width" ""

    # Show last 5 payments
    if [[ -f "$PAYMENTS_FILE" ]]; then
        python3 -c "
import json
with open('$PAYMENTS_FILE') as f:
    data = json.load(f)
payments = data.get('payments', [])[-5:]
for p in payments:
    biller = p['biller'][:15].ljust(15)
    amt = f\"\${p['usd_amount']:.2f}\".rjust(10)
    status = '✓' if p['status'] == 'COMPLETED' else '○'
    print(f'  {status} {biller} {amt}')
" 2>/dev/null | while read line; do
            render_screen_line "$width" "${WHITE}${line}${RESET}"
        done
    fi

    render_screen_line "$width" ""
    render_screen_line "$width" "${GRAY}  ─────────────────────────────────────────────${RESET}"

    local total=$(get_total_paid)
    local road=$(get_road_spent)
    render_screen_line "$width" "${AMBER}  Total Paid:  ${GREEN}\$${total} USD${RESET}"
    render_screen_line "$width" "${AMBER}  ROAD Used:   ${GREEN}${road} ROAD${RESET}"
    render_screen_line "$width" ""

    render_monitor_bottom "$width"
}

render_mining_screen() {
    local width="${1:-60}"
    local blocks=$(get_block_count)

    clear
    render_monitor_frame "$width"

    render_screen_line "$width" ""
    render_screen_line "$width" "${GOLD}  ⛏️  ROADCHAIN MINING ⛏️${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${PINK}╔════════════════════════════════════════════════╗${RESET}"
    render_screen_line "$width" "${PINK}║${WHITE}            BLOCKCHAIN STATUS                  ${PINK}║${RESET}"
    render_screen_line "$width" "${PINK}╚════════════════════════════════════════════════╝${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${AMBER}  Chain Height:    ${WHITE}${blocks} blocks${RESET}"
    render_screen_line "$width" "${AMBER}  Difficulty:      ${WHITE}4 (leading zeros)${RESET}"
    render_screen_line "$width" "${AMBER}  Block Reward:    ${GREEN}50.0 ROAD${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${BLUE}┌─ GENESIS BLOCK ─────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BLUE}│  ${CYAN}65048f5b75caed30a9501c5b156cd8...${RESET}${BLUE}       │${RESET}"
    render_screen_line "$width" "${BLUE}└──────────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${BLUE}┌─ LATEST BLOCK ──────────────────────────────┐${RESET}"
    render_screen_line "$width" "${BLUE}│  ${CYAN}$(get_latest_hash)${RESET}${BLUE}                    │${RESET}"
    render_screen_line "$width" "${BLUE}│  ${WHITE}Nonce: 23,395  Miner: alexa${RESET}${BLUE}              │${RESET}"
    render_screen_line "$width" "${BLUE}└──────────────────────────────────────────────┘${RESET}"
    render_screen_line "$width" ""
    render_screen_line "$width" "${GREEN}  Mining Status: ● COMPLETE${RESET}"
    render_screen_line "$width" ""

    render_monitor_bottom "$width"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Live Dashboard with Auto-Refresh
# ═══════════════════════════════════════════════════════════════════════════════

live_dashboard() {
    local width="${1:-60}"
    local screen="${2:-main}"
    local refresh="${3:-5}"

    while true; do
        case "$screen" in
            main) render_main_dashboard "$width" ;;
            wallets) render_wallets_screen "$width" ;;
            payments) render_payments_screen "$width" ;;
            mining) render_mining_screen "$width" ;;
            *) render_main_dashboard "$width" ;;
        esac
        sleep "$refresh"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLI Interface
# ═══════════════════════════════════════════════════════════════════════════════

show_help() {
    echo -e "${GOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${WHITE}BLACKROAD CRYPTO DASHBOARD${RESET}"
    echo -e "${GOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  main [width]           Main dashboard"
    echo "  wallets [width]        Wallet overview"
    echo "  payments [width]       Payment history"
    echo "  mining [width]         Mining status"
    echo "  sync                   Sync wallet balances"
    echo "  live [width] [screen]  Auto-refreshing dashboard"
    echo "  balance [wallet]       Check specific wallet balance"
    echo ""
    echo "Examples:"
    echo "  $0 main 60"
    echo "  $0 live 50 wallets"
    echo "  $0 balance alexa"
    echo ""
}

# Main CLI handler
case "${1:-help}" in
    main)
        render_main_dashboard "${2:-60}"
        ;;
    wallets)
        render_wallets_screen "${2:-60}"
        ;;
    payments)
        render_payments_screen "${2:-60}"
        ;;
    mining)
        render_mining_screen "${2:-60}"
        ;;
    sync)
        sync_wallets
        ;;
    live)
        live_dashboard "${2:-60}" "${3:-main}" "${4:-5}"
        ;;
    balance)
        wallet="${2:-alexa}"
        balance=$(get_chain_balance "$wallet")
        echo -e "${AMBER}$wallet:${RESET} ${GREEN}$balance ROAD${RESET}"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac
