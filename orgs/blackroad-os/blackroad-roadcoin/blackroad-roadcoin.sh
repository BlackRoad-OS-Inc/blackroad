#!/bin/bash
# RoadCoin - Payment & Crypto Integration System
# BlackRoad OS, Inc. © 2026

ROADCOIN_DIR="$HOME/.blackroad/roadcoin"
ROADCOIN_DB="$ROADCOIN_DIR/roadcoin.db"
WALLET_DIR="$ROADCOIN_DIR/wallets"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

init() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     💰 RoadCoin Payment System                ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    mkdir -p "$WALLET_DIR"

    # Create database
    sqlite3 "$ROADCOIN_DB" <<'SQL'
-- Wallets
CREATE TABLE IF NOT EXISTS wallets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    address TEXT UNIQUE NOT NULL,
    currency TEXT NOT NULL,            -- BTC, ETH, SOL, USD
    balance REAL DEFAULT 0,
    label TEXT,
    created_at INTEGER NOT NULL,
    last_updated INTEGER
);

-- Transactions
CREATE TABLE IF NOT EXISTS transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tx_hash TEXT UNIQUE,
    from_address TEXT,
    to_address TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT NOT NULL,
    fee REAL DEFAULT 0,
    status TEXT DEFAULT 'pending',     -- pending, confirmed, failed
    type TEXT NOT NULL,                -- payment, withdrawal, deposit, swap
    metadata TEXT,                     -- JSON
    created_at INTEGER NOT NULL,
    confirmed_at INTEGER
);

-- Payment requests
CREATE TABLE IF NOT EXISTS payment_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id TEXT UNIQUE NOT NULL,
    amount REAL NOT NULL,
    currency TEXT NOT NULL,
    description TEXT,
    recipient_address TEXT,
    status TEXT DEFAULT 'pending',     -- pending, paid, expired, cancelled
    expires_at INTEGER,
    created_at INTEGER NOT NULL,
    paid_at INTEGER
);

-- Subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subscription_id TEXT UNIQUE NOT NULL,
    user_id TEXT NOT NULL,
    plan TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT NOT NULL,
    interval TEXT NOT NULL,            -- monthly, yearly
    status TEXT DEFAULT 'active',      -- active, cancelled, expired
    next_billing INTEGER,
    created_at INTEGER NOT NULL,
    cancelled_at INTEGER
);

CREATE INDEX IF NOT EXISTS idx_transactions_address ON transactions(to_address);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_requests_status ON payment_requests(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);

SQL

    # Create default wallets
    local timestamp=$(date +%s)

    sqlite3 "$ROADCOIN_DB" <<SQL
INSERT OR IGNORE INTO wallets (address, currency, label, created_at)
VALUES
    ('1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ', 'BTC', 'Main BTC Wallet', $timestamp),
    ('0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb', 'ETH', 'Main ETH Wallet', $timestamp),
    ('7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU', 'SOL', 'Main SOL Wallet', $timestamp);
SQL

    echo -e "${GREEN}✓${NC} RoadCoin initialized"
}

# Create payment request
create_payment() {
    local amount="$1"
    local currency="$2"
    local description="$3"

    if [ -z "$amount" ] || [ -z "$currency" ]; then
        echo -e "${RED}Error: Amount and currency required${NC}"
        return 1
    fi

    local request_id="RC-$(date +%s)-$(echo $RANDOM | shasum | cut -c1-8)"
    local timestamp=$(date +%s)
    local expires_at=$((timestamp + 3600))  # 1 hour

    # Get wallet address for currency
    local address=$(sqlite3 "$ROADCOIN_DB" "SELECT address FROM wallets WHERE currency = '$currency' LIMIT 1")

    sqlite3 "$ROADCOIN_DB" <<SQL
INSERT INTO payment_requests (request_id, amount, currency, description, recipient_address, expires_at, created_at)
VALUES ('$request_id', $amount, '$currency', '$description', '$address', $expires_at, $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Payment request created: $request_id"
    echo -e "  ${CYAN}Amount:${NC} $amount $currency"
    echo -e "  ${CYAN}Address:${NC} $address"
    echo -e "  ${CYAN}Expires:${NC} $(date -r $expires_at)"
    echo ""
    echo -e "${YELLOW}Payment URL:${NC} https://roadcoin.blackroad.io/pay/$request_id"
}

# Process payment
process_payment() {
    local request_id="$1"
    local tx_hash="$2"

    if [ -z "$request_id" ]; then
        echo -e "${RED}Error: Request ID required${NC}"
        return 1
    fi

    # Get payment request
    local amount=$(sqlite3 "$ROADCOIN_DB" "SELECT amount FROM payment_requests WHERE request_id = '$request_id'")
    local currency=$(sqlite3 "$ROADCOIN_DB" "SELECT currency FROM payment_requests WHERE request_id = '$request_id'")
    local address=$(sqlite3 "$ROADCOIN_DB" "SELECT recipient_address FROM payment_requests WHERE request_id = '$request_id'")

    if [ -z "$amount" ]; then
        echo -e "${RED}Error: Payment request not found${NC}"
        return 1
    fi

    local timestamp=$(date +%s)
    local tx_hash_generated="TX-$(date +%s)-$(echo $RANDOM | shasum | cut -c1-12)"
    local final_tx_hash="${tx_hash:-$tx_hash_generated}"

    # Create transaction
    sqlite3 "$ROADCOIN_DB" <<SQL
INSERT INTO transactions (tx_hash, to_address, amount, currency, type, status, created_at, confirmed_at)
VALUES ('$final_tx_hash', '$address', $amount, '$currency', 'payment', 'confirmed', $timestamp, $timestamp);

UPDATE payment_requests
SET status = 'paid', paid_at = $timestamp
WHERE request_id = '$request_id';

UPDATE wallets
SET balance = balance + $amount, last_updated = $timestamp
WHERE address = '$address';
SQL

    echo -e "${GREEN}✓${NC} Payment processed"
    echo -e "  ${CYAN}Request:${NC} $request_id"
    echo -e "  ${CYAN}Amount:${NC} $amount $currency"
    echo -e "  ${CYAN}TX Hash:${NC} $final_tx_hash"

    # Log to memory
    ~/memory-system.sh log "payment-received" "$request_id" "RoadCoin payment received: $amount $currency (TX: $final_tx_hash)" "payments,crypto" 2>/dev/null
}

# Create subscription
create_subscription() {
    local user_id="$1"
    local plan="$2"
    local amount="$3"
    local currency="$4"
    local interval="${5:-monthly}"

    if [ -z "$user_id" ] || [ -z "$plan" ] || [ -z "$amount" ]; then
        echo -e "${RED}Error: User ID, plan, and amount required${NC}"
        return 1
    fi

    local sub_id="SUB-$(date +%s)-$(echo $RANDOM | shasum | cut -c1-8)"
    local timestamp=$(date +%s)

    # Calculate next billing
    local next_billing
    if [ "$interval" = "monthly" ]; then
        next_billing=$((timestamp + 2592000))  # 30 days
    else
        next_billing=$((timestamp + 31536000))  # 365 days
    fi

    sqlite3 "$ROADCOIN_DB" <<SQL
INSERT INTO subscriptions (subscription_id, user_id, plan, amount, currency, interval, next_billing, created_at)
VALUES ('$sub_id', '$user_id', '$plan', $amount, '$currency', '$interval', $next_billing, $timestamp);
SQL

    echo -e "${GREEN}✓${NC} Subscription created: $sub_id"
    echo -e "  ${CYAN}Plan:${NC} $plan"
    echo -e "  ${CYAN}Amount:${NC} $amount $currency / $interval"
    echo -e "  ${CYAN}Next billing:${NC} $(date -r $next_billing)"
}

# Show balance
balance() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     💰 Wallet Balances                        ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$ROADCOIN_DB" <<SQL
SELECT
    currency,
    printf('%.8f', balance) as balance,
    label,
    datetime(last_updated, 'unixepoch', 'localtime') as last_updated
FROM wallets
ORDER BY currency;
SQL
}

# Transaction history
history() {
    local limit="${1:-20}"

    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     Transaction History                       ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    sqlite3 -header -column "$ROADCOIN_DB" <<SQL
SELECT
    type,
    printf('%.8f', amount) as amount,
    currency,
    status,
    datetime(created_at, 'unixepoch', 'localtime') as created
FROM transactions
ORDER BY created_at DESC
LIMIT $limit;
SQL
}

# Dashboard
dashboard() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     💰 RoadCoin Dashboard                     ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"

    local total_tx=$(sqlite3 "$ROADCOIN_DB" "SELECT COUNT(*) FROM transactions")
    local confirmed_tx=$(sqlite3 "$ROADCOIN_DB" "SELECT COUNT(*) FROM transactions WHERE status = 'confirmed'")
    local total_payments=$(sqlite3 "$ROADCOIN_DB" "SELECT COUNT(*) FROM payment_requests WHERE status = 'paid'")
    local active_subs=$(sqlite3 "$ROADCOIN_DB" "SELECT COUNT(*) FROM subscriptions WHERE status = 'active'")

    # Calculate total value in USD (simplified)
    local btc_balance=$(sqlite3 "$ROADCOIN_DB" "SELECT balance FROM wallets WHERE currency = 'BTC'" || echo "0")
    local eth_balance=$(sqlite3 "$ROADCOIN_DB" "SELECT balance FROM wallets WHERE currency = 'ETH'" || echo "0")
    local sol_balance=$(sqlite3 "$ROADCOIN_DB" "SELECT balance FROM wallets WHERE currency = 'SOL'" || echo "0")

    echo -e "${CYAN}📊 Statistics${NC}"
    echo -e "  ${GREEN}Total Transactions:${NC} $total_tx"
    echo -e "  ${GREEN}Confirmed:${NC} $confirmed_tx"
    echo -e "  ${GREEN}Payments Received:${NC} $total_payments"
    echo -e "  ${PURPLE}Active Subscriptions:${NC} $active_subs"

    echo -e "\n${CYAN}💎 Balances${NC}"
    echo -e "  ${YELLOW}BTC:${NC} $btc_balance"
    echo -e "  ${YELLOW}ETH:${NC} $eth_balance"
    echo -e "  ${YELLOW}SOL:${NC} $sol_balance"
}

# Main execution
case "${1:-help}" in
    init)
        init
        ;;
    create-payment)
        create_payment "$2" "$3" "$4"
        ;;
    process-payment)
        process_payment "$2" "$3"
        ;;
    create-subscription)
        create_subscription "$2" "$3" "$4" "$5" "$6"
        ;;
    balance)
        balance
        ;;
    history)
        history "$2"
        ;;
    dashboard)
        dashboard
        ;;
    help|*)
        echo -e "${PURPLE}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║     💰 RoadCoin Payment System                ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════╝${NC}\n"
        echo "Crypto payment & subscription management"
        echo ""
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo ""
        echo "Setup:"
        echo "  init                                    - Initialize RoadCoin"
        echo ""
        echo "Payments:"
        echo "  create-payment AMOUNT CURRENCY [DESC]   - Create payment request"
        echo "  process-payment REQUEST_ID [TX_HASH]    - Process payment"
        echo ""
        echo "Subscriptions:"
        echo "  create-subscription USER PLAN AMT CUR [INTERVAL]  - Create subscription"
        echo ""
        echo "Info:"
        echo "  balance                                 - Show wallet balances"
        echo "  history [LIMIT]                         - Transaction history"
        echo "  dashboard                               - Show dashboard"
        echo ""
        echo "Examples:"
        echo "  $0 create-payment 0.001 BTC 'Product License'"
        echo "  $0 create-subscription user@example.com pro 29.99 USD monthly"
        echo "  $0 dashboard"
        ;;
esac
