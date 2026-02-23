#!/bin/bash
# roadchain-watcher.sh — BTC Address Deposit Watcher
# Monitors bc1qqf4l8mj0cjz6gqvvjdmqmdkez5x2gq4smu5fr4 for new deposits
# Auto-records to RoadChain reserve when detected
#
# Usage:
#   ./roadchain-watcher.sh start       # Start watching (foreground)
#   ./roadchain-watcher.sh daemon      # Start as background daemon
#   ./roadchain-watcher.sh stop        # Stop daemon
#   ./roadchain-watcher.sh status      # Check current address balance
#   ./roadchain-watcher.sh test        # Test API connectivity

set -euo pipefail

ROADCHAIN_DIR="$HOME/.roadchain"
WATCHER_STATE="$ROADCHAIN_DIR/watcher-state.json"
WATCHER_LOG="$ROADCHAIN_DIR/watcher.log"
PID_FILE="$ROADCHAIN_DIR/watcher-daemon.pid"
RESERVE_LEDGER="$ROADCHAIN_DIR/reserve-ledger.json"

# Alexa's receive address
BTC_ADDRESS="bc1qqf4l8mj0cjz6gqvvjdmqmdkez5x2gq4smu5fr4"

# Poll every 60 seconds
POLL_INTERVAL=60

PINK='\033[38;5;205m'
AMBER='\033[38;5;214m'
GREEN='\033[38;5;82m'
BLUE='\033[38;5;69m'
RED='\033[38;5;196m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;240m'
BOLD='\033[1m'
RESET='\033[0m'

mkdir -p "$ROADCHAIN_DIR"

log_watch() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$WATCHER_LOG"
}

# ═══════════════════════════════════════════════════════════
# GET BTC BALANCE FROM MULTIPLE APIs
# ═══════════════════════════════════════════════════════════

get_balance_sats() {
    local address="$1"

    # Try mempool.space first (supports bech32)
    local result
    result=$(curl -s --max-time 15 "https://mempool.space/api/address/$address" 2>/dev/null)
    if [[ -n "$result" ]]; then
        local sats
        sats=$(python3 -c "
import json
try:
    d = json.loads('''$result''')
    funded = d.get('chain_stats', {}).get('funded_txo_sum', 0)
    spent = d.get('chain_stats', {}).get('spent_txo_sum', 0)
    mempool_funded = d.get('mempool_stats', {}).get('funded_txo_sum', 0)
    mempool_spent = d.get('mempool_stats', {}).get('spent_txo_sum', 0)
    total = (funded - spent) + (mempool_funded - mempool_spent)
    print(total)
except:
    print('ERROR')
" 2>/dev/null)
        if [[ "$sats" != "ERROR" && -n "$sats" ]]; then
            echo "$sats"
            return 0
        fi
    fi

    # Fallback: blockstream.info
    result=$(curl -s --max-time 15 "https://blockstream.info/api/address/$address" 2>/dev/null)
    if [[ -n "$result" ]]; then
        local sats
        sats=$(python3 -c "
import json
try:
    d = json.loads('''$result''')
    funded = d.get('chain_stats', {}).get('funded_txo_sum', 0)
    spent = d.get('chain_stats', {}).get('spent_txo_sum', 0)
    print(funded - spent)
except:
    print('ERROR')
" 2>/dev/null)
        if [[ "$sats" != "ERROR" && -n "$sats" ]]; then
            echo "$sats"
            return 0
        fi
    fi

    echo "ERROR"
    return 1
}

# ═══════════════════════════════════════════════════════════
# INIT / LOAD WATCHER STATE
# ═══════════════════════════════════════════════════════════

init_state() {
    if [ ! -f "$WATCHER_STATE" ]; then
        python3 -c "
import json, time
state = {
    'address': '$BTC_ADDRESS',
    'last_known_sats': 0,
    'last_check': 0,
    'total_detected': 0,
    'deposits': []
}
with open('$WATCHER_STATE', 'w') as f:
    json.dump(state, f, indent=2)
print('Watcher state initialized')
"
    fi
}

# ═══════════════════════════════════════════════════════════
# CHECK FOR NEW DEPOSITS
# ═══════════════════════════════════════════════════════════

check_and_record() {
    local current_sats
    current_sats=$(get_balance_sats "$BTC_ADDRESS")

    if [[ "$current_sats" == "ERROR" ]]; then
        log_watch "API ERROR: Could not fetch balance"
        echo -e "${RED}API error — will retry${RESET}"
        return 1
    fi

    python3 - "$WATCHER_STATE" "$current_sats" "$ROADCHAIN_DIR" << 'PYEOF'
import json, sys, time, subprocess, os

state_file = sys.argv[1]
current_sats = int(sys.argv[2])
roadchain_dir = sys.argv[3]

with open(state_file) as f:
    state = json.load(f)

last_sats = state.get('last_known_sats', 0)
diff_sats = current_sats - last_sats

g = '\033[38;5;82m'
a = '\033[38;5;214m'
p = '\033[38;5;205m'
w = '\033[38;5;255m'
d = '\033[38;5;240m'
r = '\033[38;5;196m'
bold = '\033[1m'
x = '\033[0m'

current_btc = current_sats / 100_000_000
diff_btc = diff_sats / 100_000_000

print(f'{d}[{time.strftime("%H:%M:%S")}]{x} Balance: {g}{current_btc:.8f} BTC{x} ({current_sats:,} sats)', flush=True)

if diff_sats > 0 and last_sats > 0:
    # NEW DEPOSIT DETECTED
    print(f'{g}{"═" * 60}{x}')
    print(f'{bold}{p}  NEW DEPOSIT DETECTED{x}')
    print(f'{g}{"═" * 60}{x}')
    print(f'  {w}Amount:  {diff_btc:.8f} BTC ({diff_sats:,} sats){x}')
    print(f'  {w}Address: {state["address"]}{x}')

    # Get BTC price
    price_file = os.path.join(roadchain_dir, 'price-feed.json')
    try:
        with open(price_file) as f:
            btc_price = json.load(f)['btc_usd']
    except:
        btc_price = 66410

    usd_value = diff_btc * btc_price
    print(f'  {g}USD:     ${usd_value:,.2f}{x}')
    print(f'{g}{"═" * 60}{x}')

    # Auto-record to RoadChain
    print(f'{a}Recording to RoadChain reserve...{x}', flush=True)
    result = subprocess.run(
        ['bash', os.path.expanduser('~/roadchain-convert.sh'), 'deposit', f'{diff_btc:.8f}', 'alexa'],
        capture_output=True, text=True
    )
    if result.returncode == 0:
        print(f'{g}Auto-recorded deposit of {diff_btc:.8f} BTC to RoadChain{x}')
        state['deposits'].append({
            'sats': diff_sats,
            'btc': diff_btc,
            'usd': usd_value,
            'timestamp': time.time(),
            'datetime': time.strftime('%Y-%m-%dT%H:%M:%S')
        })
        state['total_detected'] += 1
    else:
        print(f'{r}Failed to record: {result.stderr}{x}')

elif diff_sats == 0:
    print(f'  {d}No change since last check{x}', flush=True)

# Update state
state['last_known_sats'] = current_sats
state['last_check'] = time.time()

with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)
PYEOF
}

# ═══════════════════════════════════════════════════════════
# COMMANDS
# ═══════════════════════════════════════════════════════════

cmd_start() {
    init_state
    echo -e "${BOLD}${PINK}RoadChain Deposit Watcher${RESET}"
    echo -e "${WHITE}Address: ${GREEN}$BTC_ADDRESS${RESET}"
    echo -e "${GRAY}Polling every ${POLL_INTERVAL}s — Ctrl+C to stop${RESET}"
    echo ""

    # Seed initial balance
    check_and_record
    echo ""

    trap 'echo -e "\n${GREEN}Watcher stopped.${RESET}"; exit 0' INT

    while true; do
        sleep "$POLL_INTERVAL"
        check_and_record
    done
}

cmd_daemon() {
    init_state

    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo -e "${AMBER}Watcher daemon already running (PID: $(cat "$PID_FILE"))${RESET}"
        return 1
    fi

    echo -e "${GREEN}Starting deposit watcher daemon${RESET}"
    echo -e "${WHITE}Address: $BTC_ADDRESS${RESET}"
    echo -e "${GRAY}Log: $WATCHER_LOG${RESET}"

    (
        while true; do
            check_and_record >> "$WATCHER_LOG" 2>&1
            sleep "$POLL_INTERVAL"
        done
    ) &

    echo $! > "$PID_FILE"
    echo -e "${GREEN}Watcher daemon started (PID: $!)${RESET}"
}

cmd_stop() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            echo -e "${GREEN}Watcher daemon stopped (PID: $pid)${RESET}"
        else
            rm -f "$PID_FILE"
            echo -e "${AMBER}Daemon was not running${RESET}"
        fi
    else
        echo -e "${GRAY}No daemon running${RESET}"
    fi
}

cmd_status() {
    init_state
    echo -e "${BOLD}${PINK}RoadChain Deposit Watcher — Status${RESET}"
    echo -e "${WHITE}Address: ${GREEN}$BTC_ADDRESS${RESET}"
    echo ""
    check_and_record
}

cmd_test() {
    echo -e "${AMBER}Testing API connectivity...${RESET}"
    echo ""

    echo -n "  mempool.space: "
    if curl -s --max-time 10 "https://mempool.space/api/address/$BTC_ADDRESS" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAIL${RESET}"
    fi

    echo -n "  blockstream:   "
    if curl -s --max-time 10 "https://blockstream.info/api/address/$BTC_ADDRESS" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${RESET}"
    else
        echo -e "${RED}FAIL${RESET}"
    fi

    echo ""
    echo -e "${AMBER}Fetching balance...${RESET}"
    local sats
    sats=$(get_balance_sats "$BTC_ADDRESS")
    if [[ "$sats" != "ERROR" ]]; then
        local btc
        btc=$(python3 -c "print(f'{$sats / 100_000_000:.8f}')")
        echo -e "  ${GREEN}Balance: $btc BTC ($sats sats)${RESET}"
    else
        echo -e "  ${RED}Could not fetch balance${RESET}"
    fi
}

# ═══════════════════════════════════════════════════════════

case "${1:-status}" in
    start)   cmd_start ;;
    daemon)  cmd_daemon ;;
    stop)    cmd_stop ;;
    status)  cmd_status ;;
    test)    cmd_test ;;
    help|--help|-h)
        echo -e "${BOLD}${PINK}RoadChain Deposit Watcher${RESET}"
        echo ""
        echo -e "  ${GREEN}start${RESET}    Watch for deposits (foreground)"
        echo -e "  ${GREEN}daemon${RESET}   Watch in background"
        echo -e "  ${GREEN}stop${RESET}     Stop background watcher"
        echo -e "  ${GREEN}status${RESET}   Check current balance"
        echo -e "  ${GREEN}test${RESET}     Test API connectivity"
        echo ""
        echo -e "  ${GRAY}Address: $BTC_ADDRESS${RESET}"
        echo -e "  ${GRAY}Polls every ${POLL_INTERVAL}s, auto-records deposits to RoadChain${RESET}"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${RESET}"
        exit 1
        ;;
esac
