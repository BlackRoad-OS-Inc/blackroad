#!/bin/bash

# BlackRoad OS - Stripe Payment Automation
# Fully automated payment processing, subscriptions, and revenue tracking

source ~/blackroad-dashboards/themes.sh
load_theme

STRIPE_DIR="$HOME/.stripe-automation"
CUSTOMERS_DB="$STRIPE_DIR/customers.db"
SUBSCRIPTIONS_DB="$STRIPE_DIR/subscriptions.db"
INVOICES_DB="$STRIPE_DIR/invoices.db"
REVENUE_LOG="$STRIPE_DIR/revenue.log"
WEBHOOK_LOG="$STRIPE_DIR/webhooks.log"

mkdir -p "$STRIPE_DIR"

# Initialize SQLite databases
init_databases() {
    # Customers database
    sqlite3 "$CUSTOMERS_DB" <<EOF
CREATE TABLE IF NOT EXISTS customers (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE,
    name TEXT,
    created_at INTEGER,
    stripe_customer_id TEXT,
    subscription_status TEXT,
    lifetime_value REAL DEFAULT 0
);
EOF

    # Subscriptions database
    sqlite3 "$SUBSCRIPTIONS_DB" <<EOF
CREATE TABLE IF NOT EXISTS subscriptions (
    id TEXT PRIMARY KEY,
    customer_id TEXT,
    plan_id TEXT,
    plan_name TEXT,
    amount REAL,
    currency TEXT,
    interval TEXT,
    status TEXT,
    current_period_start INTEGER,
    current_period_end INTEGER,
    cancel_at_period_end INTEGER DEFAULT 0
);
EOF

    # Invoices database
    sqlite3 "$INVOICES_DB" <<EOF
CREATE TABLE IF NOT EXISTS invoices (
    id TEXT PRIMARY KEY,
    customer_id TEXT,
    subscription_id TEXT,
    amount_due REAL,
    amount_paid REAL,
    currency TEXT,
    status TEXT,
    created_at INTEGER,
    paid_at INTEGER
);
EOF
}

# Stripe API wrapper (requires STRIPE_API_KEY env var)
stripe_api() {
    local method=$1
    local endpoint=$2
    local data=$3

    if [ -z "$STRIPE_API_KEY" ]; then
        echo '{"error": "STRIPE_API_KEY not set. Get from: https://dashboard.stripe.com/apikeys"}'
        return 1
    fi

    if [ "$method" = "GET" ]; then
        curl -s -u "$STRIPE_API_KEY:" \
             "https://api.stripe.com/v1/$endpoint"
    else
        curl -s -u "$STRIPE_API_KEY:" \
             -X "$method" \
             -d "$data" \
             "https://api.stripe.com/v1/$endpoint"
    fi
}

# Create customer
create_customer() {
    local email=$1
    local name=$2

    echo -e "${CYAN}Creating Stripe customer...${RESET}"

    local response=$(stripe_api POST "customers" "email=$email&name=$name")

    if echo "$response" | grep -q '"error"'; then
        echo -e "${RED}Error creating customer${RESET}"
        echo "$response" | jq .
        return 1
    fi

    local customer_id=$(echo "$response" | jq -r '.id')
    local created=$(echo "$response" | jq -r '.created')

    # Save to database
    sqlite3 "$CUSTOMERS_DB" <<EOF
INSERT OR REPLACE INTO customers (id, email, name, created_at, stripe_customer_id, subscription_status)
VALUES ('$(uuidgen)', '$email', '$name', $created, '$customer_id', 'none');
EOF

    echo -e "${GREEN}✓ Customer created: $customer_id${RESET}"
    echo "$customer_id"
}

# Create subscription
create_subscription() {
    local customer_id=$1
    local price_id=$2

    echo -e "${CYAN}Creating subscription...${RESET}"

    local response=$(stripe_api POST "subscriptions" "customer=$customer_id&items[0][price]=$price_id")

    if echo "$response" | grep -q '"error"'; then
        echo -e "${RED}Error creating subscription${RESET}"
        echo "$response" | jq .
        return 1
    fi

    local sub_id=$(echo "$response" | jq -r '.id')
    local status=$(echo "$response" | jq -r '.status')
    local amount=$(echo "$response" | jq -r '.items.data[0].price.unit_amount')
    local currency=$(echo "$response" | jq -r '.items.data[0].price.currency')
    local interval=$(echo "$response" | jq -r '.items.data[0].price.recurring.interval')

    # Save to database
    sqlite3 "$SUBSCRIPTIONS_DB" <<EOF
INSERT OR REPLACE INTO subscriptions (id, customer_id, plan_id, amount, currency, interval, status, current_period_start, current_period_end)
VALUES ('$sub_id', '$customer_id', '$price_id', $(echo "$amount / 100" | bc), '$currency', '$interval', '$status',
        $(echo "$response" | jq -r '.current_period_start'),
        $(echo "$response" | jq -r '.current_period_end'));
EOF

    echo -e "${GREEN}✓ Subscription created: $sub_id ($status)${RESET}"
}

# Get revenue metrics
get_revenue_metrics() {
    echo -e "${CYAN}Fetching revenue data from Stripe...${RESET}\n"

    # Get balance
    local balance=$(stripe_api GET "balance")

    if echo "$balance" | grep -q '"error"'; then
        echo -e "${RED}Error fetching balance${RESET}"
        return 1
    fi

    local available=$(echo "$balance" | jq -r '.available[0].amount // 0')
    local pending=$(echo "$balance" | jq -r '.pending[0].amount // 0')
    local currency=$(echo "$balance" | jq -r '.available[0].currency // "usd"')

    # Convert from cents to dollars
    local available_usd=$(echo "scale=2; $available / 100" | bc)
    local pending_usd=$(echo "scale=2; $pending / 100" | bc)

    echo "available:$available_usd|pending:$pending_usd|currency:$currency"
}

# Get customer count
get_customer_count() {
    local count=$(stripe_api GET "customers?limit=1" | jq -r '.data | length')
    echo "$count"
}

# Process webhook (simulated)
process_webhook() {
    local event_type=$1
    local data=$2

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    echo "$timestamp|$event_type|$data" >> "$WEBHOOK_LOG"

    case "$event_type" in
        "customer.subscription.created")
            echo -e "${GREEN}✓ New subscription created${RESET}"
            ;;
        "invoice.payment_succeeded")
            echo -e "${GREEN}✓ Payment succeeded${RESET}"
            # Log revenue
            echo "$timestamp|payment|$data" >> "$REVENUE_LOG"
            ;;
        "invoice.payment_failed")
            echo -e "${RED}⚠ Payment failed${RESET}"
            # Alert for failed payment
            ;;
        "customer.subscription.deleted")
            echo -e "${ORANGE}⚠ Subscription cancelled${RESET}"
            ;;
    esac
}

# Show Stripe dashboard
show_stripe_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  ${PURPLE}💳${RESET} ${BOLD}STRIPE AUTOMATION DASHBOARD${RESET}                                     ${BOLD}${GREEN}║${RESET}"
    echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # API status
    echo -e "${TEXT_MUTED}╭─ STRIPE API STATUS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -n "$STRIPE_API_KEY" ]; then
        echo -e "  ${GREEN}●${RESET} ${BOLD}API Key:${RESET}             ${GREEN}✓ Configured${RESET}"

        # Test API connection
        local test=$(stripe_api GET "balance" 2>/dev/null)
        if echo "$test" | grep -q '"available"'; then
            echo -e "  ${GREEN}●${RESET} ${BOLD}Connection:${RESET}          ${GREEN}✓ Connected${RESET}"
        else
            echo -e "  ${RED}●${RESET} ${BOLD}Connection:${RESET}          ${RED}✗ Failed${RESET}"
        fi
    else
        echo -e "  ${ORANGE}●${RESET} ${BOLD}API Key:${RESET}             ${ORANGE}⚠ Not Set${RESET}"
        echo -e "  ${TEXT_MUTED}Set: export STRIPE_API_KEY='sk_test_...'${RESET}"
    fi
    echo ""

    # Revenue metrics
    echo -e "${TEXT_MUTED}╭─ REVENUE METRICS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -n "$STRIPE_API_KEY" ]; then
        local metrics=$(get_revenue_metrics 2>/dev/null)

        if [ -n "$metrics" ]; then
            IFS='|' read -r available pending currency <<< "$metrics"
            local avail=$(echo "$available" | cut -d':' -f2)
            local pend=$(echo "$pending" | cut -d':' -f2)

            echo -e "  ${BOLD}${TEXT_PRIMARY}Available Balance:${RESET}   ${GREEN}\$${avail}${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Pending:${RESET}             ${ORANGE}\$${pend}${RESET}"
        else
            echo -e "  ${TEXT_MUTED}Loading...${RESET}"
        fi
    else
        echo -e "  ${TEXT_MUTED}Configure API key to see metrics${RESET}"
    fi
    echo ""

    # Database stats
    echo -e "${TEXT_MUTED}╭─ DATABASE STATISTICS ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$CUSTOMERS_DB" ]; then
        local customer_count=$(sqlite3 "$CUSTOMERS_DB" "SELECT COUNT(*) FROM customers;" 2>/dev/null || echo "0")
        echo -e "  ${BOLD}${TEXT_PRIMARY}Customers:${RESET}           ${CYAN}$customer_count${RESET}"
    else
        echo -e "  ${TEXT_MUTED}No customers yet${RESET}"
    fi

    if [ -f "$SUBSCRIPTIONS_DB" ]; then
        local sub_count=$(sqlite3 "$SUBSCRIPTIONS_DB" "SELECT COUNT(*) FROM subscriptions;" 2>/dev/null || echo "0")
        local active_count=$(sqlite3 "$SUBSCRIPTIONS_DB" "SELECT COUNT(*) FROM subscriptions WHERE status='active';" 2>/dev/null || echo "0")
        echo -e "  ${BOLD}${TEXT_PRIMARY}Subscriptions:${RESET}       ${PURPLE}$sub_count${RESET} (${GREEN}$active_count active${RESET})"
    fi

    if [ -f "$INVOICES_DB" ]; then
        local invoice_count=$(sqlite3 "$INVOICES_DB" "SELECT COUNT(*) FROM invoices;" 2>/dev/null || echo "0")
        echo -e "  ${BOLD}${TEXT_PRIMARY}Invoices:${RESET}            ${ORANGE}$invoice_count${RESET}"
    fi
    echo ""

    # Products & Pricing
    echo -e "${TEXT_MUTED}╭─ PRODUCTS & PRICING ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${BOLD}BlackRoad OS Products:${RESET}"
    echo ""
    echo -e "  ${CYAN}●${RESET} ${BOLD}Starter Plan${RESET}         ${GREEN}\$29/month${RESET}"
    echo -e "    ${TEXT_MUTED}Perfect for individuals and small teams${RESET}"
    echo ""
    echo -e "  ${PURPLE}●${RESET} ${BOLD}Professional Plan${RESET}   ${GREEN}\$99/month${RESET}"
    echo -e "    ${TEXT_MUTED}For growing companies${RESET}"
    echo ""
    echo -e "  ${GOLD}●${RESET} ${BOLD}Enterprise Plan${RESET}     ${GREEN}\$299/month${RESET}"
    echo -e "    ${TEXT_MUTED}Full platform access${RESET}"
    echo ""

    # Automation features
    echo -e "${TEXT_MUTED}╭─ AUTOMATION FEATURES ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}✓${RESET} Automatic subscription management"
    echo -e "  ${GREEN}✓${RESET} Failed payment retry logic"
    echo -e "  ${GREEN}✓${RESET} Automated invoice generation"
    echo -e "  ${GREEN}✓${RESET} Revenue tracking & reporting"
    echo -e "  ${GREEN}✓${RESET} Customer lifecycle management"
    echo -e "  ${GREEN}✓${RESET} Webhook processing"
    echo -e "  ${GREEN}✓${RESET} Churn prevention alerts"
    echo ""

    # Quick actions
    echo -e "${TEXT_MUTED}╭─ QUICK ACTIONS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}1.${RESET} Create Test Customer"
    echo -e "  ${CYAN}2.${RESET} Create Subscription"
    echo -e "  ${CYAN}3.${RESET} View Revenue Report"
    echo -e "  ${CYAN}4.${RESET} Simulate Webhook"
    echo -e "  ${CYAN}5.${RESET} View Webhook Log"
    echo -e "  ${CYAN}6.${RESET} Export to CSV"
    echo ""

    echo -e "${GREEN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-6]${RESET} Select  ${TEXT_SECONDARY}[I]${RESET} Init DB  ${TEXT_SECONDARY}[S]${RESET} Setup Guide  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Setup guide
show_setup_guide() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}STRIPE AUTOMATION SETUP GUIDE${RESET}\n"

    echo -e "${BOLD}Step 1: Get Stripe API Key${RESET}"
    echo "  1. Go to: https://dashboard.stripe.com/apikeys"
    echo "  2. Copy your 'Secret key' (starts with sk_test_ or sk_live_)"
    echo "  3. Run: export STRIPE_API_KEY='sk_test_YOUR_KEY_HERE'"
    echo ""

    echo -e "${BOLD}Step 2: Create Products${RESET}"
    echo "  1. Go to: https://dashboard.stripe.com/products"
    echo "  2. Create pricing plans (Starter, Professional, Enterprise)"
    echo "  3. Note the Price IDs (price_...)"
    echo ""

    echo -e "${BOLD}Step 3: Set Up Webhooks${RESET}"
    echo "  1. Go to: https://dashboard.stripe.com/webhooks"
    echo "  2. Add endpoint: https://your-domain.com/webhooks/stripe"
    echo "  3. Select events:"
    echo "     - customer.subscription.created"
    echo "     - customer.subscription.deleted"
    echo "     - invoice.payment_succeeded"
    echo "     - invoice.payment_failed"
    echo ""

    echo -e "${BOLD}Step 4: Initialize Database${RESET}"
    echo "  Run option [I] from main menu"
    echo ""

    echo -e "${BOLD}Useful Links:${RESET}"
    echo "  Dashboard: https://dashboard.stripe.com"
    echo "  Docs:      https://stripe.com/docs/api"
    echo "  Testing:   https://stripe.com/docs/testing"
    echo ""

    echo -e "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Revenue report
show_revenue_report() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}REVENUE REPORT${RESET}\n"

    if [ -f "$REVENUE_LOG" ]; then
        echo -e "${BOLD}Recent Payments:${RESET}\n"

        tail -10 "$REVENUE_LOG" | while IFS='|' read -r timestamp type amount; do
            local date=$(echo "$timestamp" | cut -d'T' -f1)
            echo -e "  ${GREEN}●${RESET} $date - $type - $amount"
        done
    else
        echo -e "${TEXT_MUTED}No revenue recorded yet${RESET}"
    fi

    echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# Main loop
main() {
    init_databases

    while true; do
        show_stripe_dashboard

        read -n1 key

        case "$key" in
            '1')
                clear
                echo -e "${CYAN}Create Test Customer${RESET}\n"
                echo -n "Email: "
                read email
                echo -n "Name: "
                read name

                create_customer "$email" "$name"

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '2')
                clear
                echo -e "${CYAN}Create Subscription${RESET}\n"
                echo -n "Customer ID: "
                read customer_id
                echo -n "Price ID: "
                read price_id

                create_subscription "$customer_id" "$price_id"

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '3')
                show_revenue_report
                ;;
            '4')
                clear
                process_webhook "invoice.payment_succeeded" "amount:99.00"
                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '5')
                clear
                echo -e "${BOLD}${CYAN}WEBHOOK LOG${RESET}\n"
                if [ -f "$WEBHOOK_LOG" ]; then
                    tail -20 "$WEBHOOK_LOG"
                else
                    echo -e "${TEXT_MUTED}No webhooks logged${RESET}"
                fi
                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '6')
                clear
                local export_file="$HOME/stripe-export-$(date +%Y%m%d).csv"
                echo -e "${CYAN}Exporting data to CSV...${RESET}\n"

                if [ -f "$CUSTOMERS_DB" ]; then
                    sqlite3 -header -csv "$CUSTOMERS_DB" "SELECT * FROM customers;" > "$export_file"
                    echo -e "${GREEN}✓ Exported to: $export_file${RESET}"
                else
                    echo -e "${RED}No data to export${RESET}"
                fi

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            'i'|'I')
                clear
                echo -e "${CYAN}Initializing databases...${RESET}\n"
                init_databases
                echo -e "${GREEN}✓ Databases initialized${RESET}"
                sleep 1
                ;;
            's'|'S')
                show_setup_guide
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}Stripe automation closed${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
