#!/usr/bin/env zsh

# BlackRoad Stripe Manager
# Manage Stripe products, subscriptions, revenue, and webhooks
# Pattern: mirrors br-cloudflare.sh

# Colors (BlackRoad brand)
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"
PINK='\033[38;5;205m'
NC='\033[0m'

DB_FILE="$HOME/.blackroad/stripe.db"
CONFIG_FILE="$HOME/.blackroad/stripe.conf"

# Canonical pricing (must match pricing.ts)
TIER_PRO_MONTHLY=2900        # $29.00 in cents
TIER_PRO_YEARLY=29000        # $290.00 in cents
TIER_ENT_MONTHLY=19900       # $199.00 in cents
TIER_ENT_YEARLY=199000       # $1,990.00 in cents

init_db() {
    mkdir -p "$(dirname "$DB_FILE")"
    sqlite3 "$DB_FILE" <<'DBEOF'
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stripe_product_id TEXT UNIQUE,
    name TEXT,
    tier_id TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS prices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stripe_price_id TEXT UNIQUE,
    product_id TEXT,
    tier_id TEXT,
    interval TEXT,
    amount INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS customers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stripe_customer_id TEXT UNIQUE,
    email TEXT,
    name TEXT,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS subscriptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    stripe_subscription_id TEXT UNIQUE,
    customer_id TEXT,
    price_id TEXT,
    status TEXT,
    current_period_end INTEGER,
    created_at INTEGER
);

CREATE TABLE IF NOT EXISTS sync_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity TEXT,
    count INTEGER,
    synced_at INTEGER
);
DBEOF
}

check_auth() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Not configured${NC}"
        echo "Run: br stripe auth <secret-key>"
        echo ""
        echo "Get your key from: https://dashboard.stripe.com/apikeys"
        exit 1
    fi
    source "$CONFIG_FILE"
    if [[ -z "$STRIPE_SECRET_KEY" ]]; then
        echo -e "${RED}API key not found${NC}"
        exit 1
    fi
}

stripe_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    check_auth

    local url="https://api.stripe.com/v1${endpoint}"

    if [[ -n "$data" ]]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $STRIPE_SECRET_KEY" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $STRIPE_SECRET_KEY"
    fi
}

# Format cents to dollars
fmt_cents() {
    local cents="$1"
    local dollars=$((cents / 100))
    local remainder=$((cents % 100))
    printf "\$%d.%02d" "$dollars" "$remainder"
}

# Parse JSON value (simple grep-based, no jq dependency)
json_val() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:.*"\(.*\)"/\1/'
}

json_num() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[0-9]*" | head -1 | grep -o '[0-9]*$'
}

json_bool() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[a-z]*" | head -1 | grep -o '[a-z]*$'
}

# ============================================================================
# Commands
# ============================================================================

cmd_auth() {
    local key="$1"

    if [[ -z "$key" ]]; then
        echo -e "${RED}Usage: br stripe auth <secret-key>${NC}"
        echo ""
        echo "Get your API key:"
        echo "1. Go to: https://dashboard.stripe.com/apikeys"
        echo "2. Copy your Secret key (sk_live_... or sk_test_...)"
        echo "3. Run: br stripe auth sk_live_xxx"
        exit 1
    fi

    echo -e "${CYAN}Saving Stripe credentials...${NC}"

    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << CONFIGEOF
STRIPE_SECRET_KEY="$key"
CONFIGEOF
    chmod 600 "$CONFIG_FILE"

    # Verify the key
    local response=$(stripe_api GET "/balance")
    local available=$(json_val "$response" "object")

    if [[ "$available" == "balance" ]]; then
        echo -e "${GREEN}Authentication successful${NC}"
        local mode="LIVE"
        if [[ "$key" == sk_test_* ]]; then
            mode="TEST"
        fi
        echo -e "  Mode: ${YELLOW}$mode${NC}"
        init_db
    else
        echo -e "${RED}Invalid API key${NC}"
        rm -f "$CONFIG_FILE"
        exit 1
    fi
}

cmd_products_list() {
    init_db
    echo -e "${CYAN}Stripe Products${NC}\n"

    local response=$(stripe_api GET "/products?active=true&limit=20")

    echo "$response" | grep -o '"id":"prod_[^"]*"' | while read -r line; do
        local prod_id=$(echo "$line" | cut -d'"' -f4)
        # Fetch individual product for full details
        local prod=$(stripe_api GET "/products/$prod_id")
        local name=$(json_val "$prod" "name")
        local desc=$(json_val "$prod" "description")
        local active=$(json_bool "$prod" "active")

        if [[ "$active" == "true" ]]; then
            echo -e "${GREEN}●${NC} ${PINK}$name${NC}"
        else
            echo -e "${YELLOW}●${NC} $name (inactive)"
        fi
        echo -e "  ID: $prod_id"
        [[ -n "$desc" ]] && echo -e "  $desc"

        # Cache
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO products (stripe_product_id, name, created_at) VALUES ('$prod_id', '$(echo $name | sed "s/'/''/g")', $(date +%s));"
        echo ""
    done
}

cmd_products_create() {
    init_db
    echo -e "${PINK}Creating BlackRoad OS canonical pricing in Stripe...${NC}\n"

    # --- Pro product ---
    echo -e "${CYAN}Creating Pro product...${NC}"
    local pro_prod=$(stripe_api POST "/products" "name=BlackRoad+OS+Pro&description=100+AI+Agents,+10K+tasks/mo,+priority+support&metadata[tier_id]=pro")
    local pro_prod_id=$(json_val "$pro_prod" "id")

    if [[ -z "$pro_prod_id" ]]; then
        echo -e "${RED}Failed to create Pro product${NC}"
        echo "$pro_prod"
        exit 1
    fi
    echo -e "  ${GREEN}Product: $pro_prod_id${NC}"

    # Pro monthly price
    local pro_m=$(stripe_api POST "/prices" "product=$pro_prod_id&unit_amount=$TIER_PRO_MONTHLY&currency=usd&recurring[interval]=month&metadata[tier_id]=pro&metadata[period]=monthly")
    local pro_m_id=$(json_val "$pro_m" "id")
    echo -e "  ${GREEN}Monthly: $pro_m_id${NC} (\$29/mo)"

    # Pro yearly price
    local pro_y=$(stripe_api POST "/prices" "product=$pro_prod_id&unit_amount=$TIER_PRO_YEARLY&currency=usd&recurring[interval]=year&metadata[tier_id]=pro&metadata[period]=yearly")
    local pro_y_id=$(json_val "$pro_y" "id")
    echo -e "  ${GREEN}Yearly:  $pro_y_id${NC} (\$290/yr)"
    echo ""

    # --- Enterprise product ---
    echo -e "${CYAN}Creating Enterprise product...${NC}"
    local ent_prod=$(stripe_api POST "/products" "name=BlackRoad+OS+Enterprise&description=Unlimited+agents,+SSO,+SLA,+dedicated+support&metadata[tier_id]=enterprise")
    local ent_prod_id=$(json_val "$ent_prod" "id")

    if [[ -z "$ent_prod_id" ]]; then
        echo -e "${RED}Failed to create Enterprise product${NC}"
        echo "$ent_prod"
        exit 1
    fi
    echo -e "  ${GREEN}Product: $ent_prod_id${NC}"

    # Enterprise monthly price
    local ent_m=$(stripe_api POST "/prices" "product=$ent_prod_id&unit_amount=$TIER_ENT_MONTHLY&currency=usd&recurring[interval]=month&metadata[tier_id]=enterprise&metadata[period]=monthly")
    local ent_m_id=$(json_val "$ent_m" "id")
    echo -e "  ${GREEN}Monthly: $ent_m_id${NC} (\$199/mo)"

    # Enterprise yearly price
    local ent_y=$(stripe_api POST "/prices" "product=$ent_prod_id&unit_amount=$TIER_ENT_YEARLY&currency=usd&recurring[interval]=year&metadata[tier_id]=enterprise&metadata[period]=yearly")
    local ent_y_id=$(json_val "$ent_y" "id")
    echo -e "  ${GREEN}Yearly:  $ent_y_id${NC} (\$1,990/yr)"
    echo ""

    # Cache in DB
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO products (stripe_product_id, name, tier_id, created_at) VALUES ('$pro_prod_id', 'BlackRoad OS Pro', 'pro', $(date +%s));"
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO products (stripe_product_id, name, tier_id, created_at) VALUES ('$ent_prod_id', 'BlackRoad OS Enterprise', 'enterprise', $(date +%s));"
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO prices (stripe_price_id, product_id, tier_id, interval, amount, created_at) VALUES ('$pro_m_id', '$pro_prod_id', 'pro', 'month', $TIER_PRO_MONTHLY, $(date +%s));"
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO prices (stripe_price_id, product_id, tier_id, interval, amount, created_at) VALUES ('$pro_y_id', '$pro_prod_id', 'pro', 'year', $TIER_PRO_YEARLY, $(date +%s));"
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO prices (stripe_price_id, product_id, tier_id, interval, amount, created_at) VALUES ('$ent_m_id', '$ent_prod_id', 'enterprise', 'month', $TIER_ENT_MONTHLY, $(date +%s));"
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO prices (stripe_price_id, product_id, tier_id, interval, amount, created_at) VALUES ('$ent_y_id', '$ent_prod_id', 'enterprise', 'year', $TIER_ENT_YEARLY, $(date +%s));"

    # Print wrangler commands
    echo -e "${PINK}=== Set Worker Secrets ===${NC}"
    echo ""
    echo "Run these commands in the payment-gateway directory:"
    echo ""
    echo "  wrangler secret put STRIPE_PRICE_PRO_MONTHLY"
    echo "    Value: $pro_m_id"
    echo ""
    echo "  wrangler secret put STRIPE_PRICE_PRO_YEARLY"
    echo "    Value: $pro_y_id"
    echo ""
    echo "  wrangler secret put STRIPE_PRICE_ENT_MONTHLY"
    echo "    Value: $ent_m_id"
    echo ""
    echo "  wrangler secret put STRIPE_PRICE_ENT_YEARLY"
    echo "    Value: $ent_y_id"
    echo ""
    echo -e "${GREEN}Products and prices created successfully${NC}"
}

cmd_customers_list() {
    init_db
    echo -e "${CYAN}Recent Customers${NC}\n"

    local response=$(stripe_api GET "/customers?limit=20")

    echo "$response" | grep -o '"id":"cus_[^"]*"' | while read -r line; do
        local cust_id=$(echo "$line" | cut -d'"' -f4)
        local cust=$(stripe_api GET "/customers/$cust_id")
        local email=$(json_val "$cust" "email")
        local name=$(json_val "$cust" "name")

        echo -e "${BLUE}●${NC} ${name:-Anonymous}"
        echo -e "  Email: $email"
        echo -e "  ID: $cust_id"

        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO customers (stripe_customer_id, email, name, created_at) VALUES ('$cust_id', '$email', '$(echo ${name:-} | sed "s/'/''/g")', $(date +%s));"
        echo ""
    done
}

cmd_customers_search() {
    local email="$1"
    if [[ -z "$email" ]]; then
        echo -e "${RED}Usage: br stripe customers search <email>${NC}"
        exit 1
    fi

    echo -e "${CYAN}Searching for: $email${NC}\n"

    local response=$(stripe_api GET "/customers/search?query=email:'$email'")
    local total=$(json_num "$response" "total_count")

    if [[ "${total:-0}" -eq 0 ]]; then
        echo -e "${YELLOW}No customers found${NC}"
        return
    fi

    echo "$response" | grep -o '"id":"cus_[^"]*"' | while read -r line; do
        local cust_id=$(echo "$line" | cut -d'"' -f4)
        local cust=$(stripe_api GET "/customers/$cust_id")
        local name=$(json_val "$cust" "name")

        echo -e "${GREEN}●${NC} $cust_id"
        echo -e "  Name: ${name:-N/A}"
        echo -e "  Email: $email"
        echo ""
    done
}

cmd_subscriptions_list() {
    init_db
    echo -e "${CYAN}Active Subscriptions${NC}\n"

    local response=$(stripe_api GET "/subscriptions?status=active&limit=25")
    local total_mrr=0

    echo "$response" | grep -o '"id":"sub_[^"]*"' | while read -r line; do
        local sub_id=$(echo "$line" | cut -d'"' -f4)
        local sub=$(stripe_api GET "/subscriptions/$sub_id")
        local status=$(json_val "$sub" "status")
        local customer=$(json_val "$sub" "customer")
        local cancel=$(json_bool "$sub" "cancel_at_period_end")

        # Get amount from plan
        local amount=$(echo "$sub" | grep -o '"amount":[0-9]*' | head -1 | grep -o '[0-9]*')
        local interval=$(echo "$sub" | grep -o '"interval":"[^"]*"' | head -1 | cut -d'"' -f4)

        local status_color="${GREEN}"
        [[ "$cancel" == "true" ]] && status_color="${YELLOW}"

        echo -e "${status_color}●${NC} $sub_id"
        echo -e "  Customer: $customer"
        echo -e "  Amount: $(fmt_cents ${amount:-0})/$interval"
        echo -e "  Status: $status"
        [[ "$cancel" == "true" ]] && echo -e "  ${YELLOW}Cancels at period end${NC}"

        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO subscriptions (stripe_subscription_id, customer_id, status, created_at) VALUES ('$sub_id', '$customer', '$status', $(date +%s));"
        echo ""
    done
}

cmd_subscriptions_cancel() {
    local sub_id="$1"
    if [[ -z "$sub_id" ]]; then
        echo -e "${RED}Usage: br stripe subscriptions cancel <subscription-id>${NC}"
        echo "Example: br stripe subscriptions cancel sub_1Abc..."
        exit 1
    fi

    echo -e "${YELLOW}Canceling subscription at period end: $sub_id${NC}"

    local response=$(stripe_api POST "/subscriptions/$sub_id" "cancel_at_period_end=true")
    local status=$(json_val "$response" "status")
    local cancel=$(json_bool "$response" "cancel_at_period_end")

    if [[ "$cancel" == "true" ]]; then
        echo -e "${GREEN}Subscription will cancel at period end${NC}"
    else
        echo -e "${RED}Failed to cancel subscription${NC}"
        echo "$response" | grep -o '"message":"[^"]*"' | head -1
    fi
}

cmd_revenue() {
    echo -e "${PINK}=== BlackRoad Revenue Dashboard ===${NC}\n"

    # Balance
    local balance=$(stripe_api GET "/balance")
    local available=$(echo "$balance" | grep -o '"available":\[{[^]]*}' | head -1)
    local avail_amount=$(echo "$available" | grep -o '"amount":[0-9-]*' | head -1 | grep -o '[0-9-]*')
    local pending=$(echo "$balance" | grep -o '"pending":\[{[^]]*}' | head -1)
    local pend_amount=$(echo "$pending" | grep -o '"amount":[0-9-]*' | head -1 | grep -o '[0-9-]*')

    echo -e "${GREEN}Available Balance:${NC} $(fmt_cents ${avail_amount:-0})"
    echo -e "${YELLOW}Pending Balance:${NC}  $(fmt_cents ${pend_amount:-0})"
    echo ""

    # MRR calculation from active subscriptions
    echo -e "${CYAN}Calculating MRR...${NC}"
    local subs=$(stripe_api GET "/subscriptions?status=active&limit=100")
    local mrr=0

    # Count subscriptions and sum amounts
    local sub_count=0
    while read -r amount_line; do
        local amt=$(echo "$amount_line" | grep -o '[0-9]*')
        if [[ -n "$amt" && "$amt" -gt 0 ]]; then
            # Check if yearly and normalize to monthly
            mrr=$((mrr + amt))
            sub_count=$((sub_count + 1))
        fi
    done <<< "$(echo "$subs" | grep -o '"amount":[0-9]*' | grep -o '[0-9]*')"

    echo -e "${PINK}Monthly Recurring Revenue (MRR):${NC} $(fmt_cents $mrr)"
    echo -e "${PINK}Annual Run Rate (ARR):${NC}          $(fmt_cents $((mrr * 12)))"
    echo -e "Active Subscriptions: $sub_count"
    echo ""

    # Recent charges
    echo -e "${CYAN}Recent Charges (last 10):${NC}\n"
    local charges=$(stripe_api GET "/charges?limit=10")

    echo "$charges" | grep -o '"id":"ch_[^"]*"' | while read -r line; do
        local ch_id=$(echo "$line" | cut -d'"' -f4)
        local ch=$(stripe_api GET "/charges/$ch_id")
        local amount=$(json_num "$ch" "amount")
        local status=$(json_val "$ch" "status")
        local email=$(echo "$ch" | grep -o '"email":"[^"]*"' | head -1 | cut -d'"' -f4)

        local status_icon="${GREEN}●${NC}"
        [[ "$status" != "succeeded" ]] && status_icon="${RED}●${NC}"

        echo -e "  $status_icon $(fmt_cents ${amount:-0})  $email  ($status)"
    done
    echo ""
}

cmd_webhook_test() {
    local event_type="${1:-checkout.session.completed}"

    if ! command -v stripe &> /dev/null; then
        echo -e "${YELLOW}Stripe CLI not installed${NC}"
        echo "Install: brew install stripe/stripe-cli/stripe"
        echo "Then: stripe login"
        exit 1
    fi

    echo -e "${CYAN}Triggering test event: $event_type${NC}"
    stripe trigger "$event_type"
}

cmd_sync() {
    init_db
    echo -e "${CYAN}Syncing Stripe data to local cache...${NC}\n"

    # Sync products
    echo -e "Products..."
    local prods=$(stripe_api GET "/products?active=true&limit=100")
    local prod_count=0
    echo "$prods" | grep -o '"id":"prod_[^"]*"' | while read -r line; do
        local pid=$(echo "$line" | cut -d'"' -f4)
        local p=$(stripe_api GET "/products/$pid")
        local name=$(json_val "$p" "name")
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO products (stripe_product_id, name, created_at) VALUES ('$pid', '$(echo $name | sed "s/'/''/g")', $(date +%s));"
        prod_count=$((prod_count + 1))
    done
    echo -e "  ${GREEN}Synced products${NC}"

    # Sync customers
    echo -e "Customers..."
    local custs=$(stripe_api GET "/customers?limit=100")
    echo "$custs" | grep -o '"id":"cus_[^"]*"' | while read -r line; do
        local cid=$(echo "$line" | cut -d'"' -f4)
        local c=$(stripe_api GET "/customers/$cid")
        local email=$(json_val "$c" "email")
        local name=$(json_val "$c" "name")
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO customers (stripe_customer_id, email, name, created_at) VALUES ('$cid', '$email', '$(echo ${name:-} | sed "s/'/''/g")', $(date +%s));"
    done
    echo -e "  ${GREEN}Synced customers${NC}"

    # Sync subscriptions
    echo -e "Subscriptions..."
    local subs=$(stripe_api GET "/subscriptions?limit=100")
    echo "$subs" | grep -o '"id":"sub_[^"]*"' | while read -r line; do
        local sid=$(echo "$line" | cut -d'"' -f4)
        local s=$(stripe_api GET "/subscriptions/$sid")
        local status=$(json_val "$s" "status")
        local customer=$(json_val "$s" "customer")
        sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO subscriptions (stripe_subscription_id, customer_id, status, created_at) VALUES ('$sid', '$customer', '$status', $(date +%s));"
    done
    echo -e "  ${GREEN}Synced subscriptions${NC}"

    sqlite3 "$DB_FILE" "INSERT INTO sync_log (entity, count, synced_at) VALUES ('full', 0, $(date +%s));"
    echo -e "\n${GREEN}Sync complete${NC}"
}

cmd_portal() {
    local customer_id="$1"
    if [[ -z "$customer_id" ]]; then
        echo -e "${RED}Usage: br stripe portal <customer-id>${NC}"
        echo "Example: br stripe portal cus_1Abc..."
        exit 1
    fi

    echo -e "${CYAN}Generating billing portal URL...${NC}"

    local response=$(stripe_api POST "/billing_portal/sessions" "customer=$customer_id&return_url=https://pay.blackroad.io/")
    local url=$(json_val "$response" "url")

    if [[ -n "$url" ]]; then
        echo -e "${GREEN}Portal URL:${NC}"
        echo "$url"
    else
        echo -e "${RED}Failed to create portal session${NC}"
        echo "$response" | grep -o '"message":"[^"]*"' | head -1
    fi
}

cmd_help() {
  echo -e ""
  echo -e "  ${AMBER}${BOLD}◆ BR STRIPE${NC}  ${DIM}Stripe billing from your terminal.${NC}"
  echo -e "  ${DIM}Payments without the portal. MRR · ARR · Customers.${NC}"
  echo -e "  ${DIM}────────────────────────────────────────────────${NC}"
  echo -e "  ${BOLD}USAGE${NC}  br ${DIM}<command> [args]${NC}"
  echo -e ""
  echo -e "  ${BOLD}COMMANDS${NC}"
  echo -e "  ${AMBER}  auth <key>                      ${NC} Save Stripe API key"
  echo -e "  ${AMBER}  revenue                         ${NC} Revenue dashboard (MRR · ARR · balance)"
  echo -e "  ${AMBER}  customers list                  ${NC} List customers"
  echo -e "  ${AMBER}  customers search <email>        ${NC} Search by email"
  echo -e "  ${AMBER}  subscriptions list              ${NC} Active subscriptions with MRR"
  echo -e "  ${AMBER}  subscriptions cancel <id>       ${NC} Cancel subscription"
  echo -e "  ${AMBER}  products list                   ${NC} List products & prices"
  echo -e "  ${AMBER}  products create                 ${NC} Create canonical BlackRoad pricing"
  echo -e "  ${AMBER}  sync                            ${NC} Pull Stripe data to local SQLite cache"
  echo -e "  ${AMBER}  webhook-test [event]            ${NC} Fire test webhook via Stripe CLI"
  echo -e ""
  echo -e "  ${BOLD}EXAMPLES${NC}"
  echo -e "  ${DIM}  br stripe revenue${NC}"
  echo -e "  ${DIM}  br stripe customers search hello@blackroad.io${NC}"
  echo -e "  ${DIM}  br stripe subscriptions list${NC}"
  echo -e "  ${DIM}  br stripe auth sk_live_xxx${NC}"
  echo -e ""
}
# ============================================================================
# Main dispatch
# ============================================================================

init_db

case "${1:-help}" in
    auth) cmd_auth "${@:2}" ;;
    products|product)
        case "${2:-list}" in
            list|ls) cmd_products_list ;;
            create|setup) cmd_products_create ;;
            *) echo -e "${RED}Unknown products command: ${2}${NC}"; exit 1 ;;
        esac
        ;;
    customers|customer)
        case "${2:-list}" in
            list|ls) cmd_customers_list ;;
            search|find) cmd_customers_search "${@:3}" ;;
            *) echo -e "${RED}Unknown customers command: ${2}${NC}"; exit 1 ;;
        esac
        ;;
    subscriptions|subscription|subs)
        case "${2:-list}" in
            list|ls) cmd_subscriptions_list ;;
            cancel) cmd_subscriptions_cancel "${@:3}" ;;
            *) echo -e "${RED}Unknown subscriptions command: ${2}${NC}"; exit 1 ;;
        esac
        ;;
    revenue|rev|mrr) cmd_revenue ;;
    webhook-test|webhook|test) cmd_webhook_test "${@:2}" ;;
    sync) cmd_sync ;;
    portal) cmd_portal "${@:2}" ;;
    help|--help|-h) cmd_help ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
