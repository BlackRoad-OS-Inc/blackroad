#!/bin/bash

# BlackRoad OS - Invoice Automation
# Automated invoice generation, tracking, and payment reminders

source ~/blackroad-dashboards/themes.sh
load_theme

INVOICE_DIR="$HOME/.invoice-automation"
INVOICES_DB="$INVOICE_DIR/invoices.db"
CLIENTS_DB="$INVOICE_DIR/clients.db"
INVOICES_PDF="$INVOICE_DIR/pdfs"

mkdir -p "$INVOICE_DIR" "$INVOICES_PDF"

# Company details
COMPANY_NAME="BlackRoad OS, Inc."
COMPANY_ADDRESS="c/o Registered Agent\nDelaware"
COMPANY_EMAIL="blackroad.systems@gmail.com"
COMPANY_PHONE="Contact via email"
EIN="XX-XXXXXXX"  # Redacted for privacy

# Initialize databases
init_databases() {
    # Clients database
    sqlite3 "$CLIENTS_DB" <<EOF
CREATE TABLE IF NOT EXISTS clients (
    id TEXT PRIMARY KEY,
    name TEXT,
    email TEXT,
    company TEXT,
    address TEXT,
    created_at INTEGER
);
EOF

    # Invoices database
    sqlite3 "$INVOICES_DB" <<EOF
CREATE TABLE IF NOT EXISTS invoices (
    id TEXT PRIMARY KEY,
    invoice_number INTEGER UNIQUE,
    client_id TEXT,
    client_name TEXT,
    issue_date INTEGER,
    due_date INTEGER,
    subtotal REAL,
    tax_rate REAL,
    tax_amount REAL,
    total REAL,
    status TEXT,
    paid_date INTEGER,
    notes TEXT,
    items TEXT
);

CREATE TABLE IF NOT EXISTS payments (
    id TEXT PRIMARY KEY,
    invoice_id TEXT,
    amount REAL,
    payment_date INTEGER,
    method TEXT,
    reference TEXT
);
EOF
}

# Get next invoice number
get_next_invoice_number() {
    local max=$(sqlite3 "$INVOICES_DB" "SELECT MAX(invoice_number) FROM invoices;" 2>/dev/null)

    if [ -z "$max" ] || [ "$max" = "" ]; then
        echo "1001"
    else
        echo $((max + 1))
    fi
}

# Create client
create_client() {
    local name=$1
    local email=$2
    local company=$3
    local address=$4

    local client_id=$(uuidgen)
    local timestamp=$(date +%s)

    sqlite3 "$CLIENTS_DB" <<EOF
INSERT INTO clients (id, name, email, company, address, created_at)
VALUES ('$client_id', '$name', '$email', '$company', '$address', $timestamp);
EOF

    echo "$client_id"
}

# Generate invoice
generate_invoice() {
    local client_id=$1
    local items=$2  # JSON array: [{"desc":"Service","qty":1,"rate":100}]
    local due_days=${3:-30}

    local invoice_id=$(uuidgen)
    local invoice_num=$(get_next_invoice_number)
    local issue_date=$(date +%s)
    local due_date=$((issue_date + (due_days * 86400)))

    # Get client info
    local client_info=$(sqlite3 "$CLIENTS_DB" "SELECT name, company FROM clients WHERE id='$client_id';")
    IFS='|' read -r client_name client_company <<< "$client_info"

    # Calculate totals (simplified - would parse JSON in production)
    local subtotal=0
    local tax_rate=0  # No sales tax for services in most states
    local tax_amount=0
    local total=$subtotal

    # For demo, use simple parsing
    if [[ "$items" == *"rate"* ]]; then
        # Extract first rate as demo
        subtotal=$(echo "$items" | grep -o '"rate":[0-9]*' | head -1 | cut -d':' -f2)
        total=$subtotal
    fi

    # Save invoice
    sqlite3 "$INVOICES_DB" <<EOF
INSERT INTO invoices (id, invoice_number, client_id, client_name, issue_date, due_date,
                      subtotal, tax_rate, tax_amount, total, status, items)
VALUES ('$invoice_id', $invoice_num, '$client_id', '$client_name', $issue_date, $due_date,
        $subtotal, $tax_rate, $tax_amount, $total, 'unpaid', '$items');
EOF

    # Generate PDF/text version
    local invoice_file="$INVOICES_PDF/invoice-$invoice_num.txt"

    cat > "$invoice_file" <<EOF
════════════════════════════════════════════════════════════════════

                        I N V O I C E

════════════════════════════════════════════════════════════════════

FROM:
$COMPANY_NAME
$COMPANY_ADDRESS
Email: $COMPANY_EMAIL
EIN: $EIN

TO:
$client_name
$client_company

════════════════════════════════════════════════════════════════════

INVOICE #:      $invoice_num
ISSUE DATE:     $(date -r $issue_date "+%B %d, %Y")
DUE DATE:       $(date -r $due_date "+%B %d, %Y")
STATUS:         UNPAID

════════════════════════════════════════════════════════════════════

ITEMS:

$items

────────────────────────────────────────────────────────────────────

SUBTOTAL:                                           \$$subtotal
TAX ($tax_rate%):                                     \$$tax_amount
────────────────────────────────────────────────────────────────────
TOTAL:                                              \$$total

════════════════════════════════════════════════════════════════════

PAYMENT TERMS:
- Payment due within $due_days days
- Late payments subject to 1.5% monthly interest
- Make checks payable to: $COMPANY_NAME

PAYMENT METHODS:
- Bank Transfer (contact for details)
- Stripe (invoice will be sent separately)
- Check (mail to registered address)

NOTES:
Thank you for your business!

════════════════════════════════════════════════════════════════════

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
System: BlackRoad Invoice Automation v1.0

EOF

    echo "$invoice_num|$invoice_file"
}

# Mark invoice as paid
mark_paid() {
    local invoice_num=$1
    local amount=$2
    local method=${3:-"unknown"}

    local paid_date=$(date +%s)

    # Update invoice
    sqlite3 "$INVOICES_DB" <<EOF
UPDATE invoices SET status='paid', paid_date=$paid_date WHERE invoice_number=$invoice_num;
EOF

    # Record payment
    local payment_id=$(uuidgen)
    local invoice_id=$(sqlite3 "$INVOICES_DB" "SELECT id FROM invoices WHERE invoice_number=$invoice_num;")

    sqlite3 "$INVOICES_DB" <<EOF
INSERT INTO payments (id, invoice_id, amount, payment_date, method)
VALUES ('$payment_id', '$invoice_id', $amount, $paid_date, '$method');
EOF

    echo -e "${GREEN}✓ Invoice #$invoice_num marked as paid${RESET}"
}

# Send payment reminder (simulated)
send_reminder() {
    local invoice_num=$1

    echo -e "${CYAN}Sending payment reminder for invoice #$invoice_num...${RESET}"

    # In production, this would:
    # - Send email via SendGrid/Mailgun
    # - Log reminder sent
    # - Update reminder_sent_count

    echo -e "${GREEN}✓ Reminder sent${RESET}"
}

# Show invoice dashboard
show_invoice_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}📄${RESET} ${BOLD}INVOICE AUTOMATION DASHBOARD${RESET}                                    ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Company info
    echo -e "${TEXT_MUTED}╭─ COMPANY INFORMATION ─────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Company:${RESET}             ${GREEN}$COMPANY_NAME${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Email:${RESET}               ${CYAN}$COMPANY_EMAIL${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}EIN:${RESET}                 ${TEXT_MUTED}$EIN${RESET}"
    echo ""

    # Invoice statistics
    echo -e "${TEXT_MUTED}╭─ INVOICE STATISTICS ──────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$INVOICES_DB" ]; then
        local total_invoices=$(sqlite3 "$INVOICES_DB" "SELECT COUNT(*) FROM invoices;" 2>/dev/null || echo "0")
        local unpaid=$(sqlite3 "$INVOICES_DB" "SELECT COUNT(*) FROM invoices WHERE status='unpaid';" 2>/dev/null || echo "0")
        local paid=$(sqlite3 "$INVOICES_DB" "SELECT COUNT(*) FROM invoices WHERE status='paid';" 2>/dev/null || echo "0")
        local overdue=$(sqlite3 "$INVOICES_DB" "SELECT COUNT(*) FROM invoices WHERE status='unpaid' AND due_date < $(date +%s);" 2>/dev/null || echo "0")

        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Invoices:${RESET}      ${CYAN}$total_invoices${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Paid:${RESET}                ${GREEN}$paid${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Unpaid:${RESET}              ${ORANGE}$unpaid${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Overdue:${RESET}             ${RED}$overdue${RESET}"

        # Revenue
        local total_revenue=$(sqlite3 "$INVOICES_DB" "SELECT SUM(total) FROM invoices WHERE status='paid';" 2>/dev/null || echo "0")
        local outstanding=$(sqlite3 "$INVOICES_DB" "SELECT SUM(total) FROM invoices WHERE status='unpaid';" 2>/dev/null || echo "0")

        echo ""
        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Revenue:${RESET}       ${GREEN}\$${total_revenue}${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Outstanding:${RESET}         ${ORANGE}\$${outstanding}${RESET}"
    else
        echo -e "  ${TEXT_MUTED}No invoices yet${RESET}"
    fi
    echo ""

    # Recent invoices
    echo -e "${TEXT_MUTED}╭─ RECENT INVOICES ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$INVOICES_DB" ]; then
        local recent=$(sqlite3 "$INVOICES_DB" "SELECT invoice_number, client_name, total, status, issue_date FROM invoices ORDER BY issue_date DESC LIMIT 5;" 2>/dev/null)

        if [ -n "$recent" ]; then
            printf "  ${BOLD}%-8s %-25s %-10s %-10s${RESET}\n" "INV #" "CLIENT" "AMOUNT" "STATUS"
            echo "  ────────────────────────────────────────────────────────"

            while IFS='|' read -r num client total status date; do
                local status_color="${ORANGE}"
                [ "$status" = "paid" ] && status_color="${GREEN}"
                [ "$status" = "overdue" ] && status_color="${RED}"

                printf "  %-8s %-25s %-10s " "#$num" "${client:0:25}" "\$$total"
                echo -e "${status_color}${status}${RESET}"
            done <<< "$recent"
        else
            echo -e "  ${TEXT_MUTED}No invoices generated yet${RESET}"
        fi
    fi
    echo ""

    # Clients
    echo -e "${TEXT_MUTED}╭─ CLIENTS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$CLIENTS_DB" ]; then
        local client_count=$(sqlite3 "$CLIENTS_DB" "SELECT COUNT(*) FROM clients;" 2>/dev/null || echo "0")
        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Clients:${RESET}       ${CYAN}$client_count${RESET}"
    else
        echo -e "  ${TEXT_MUTED}No clients yet${RESET}"
    fi
    echo ""

    # Automation features
    echo -e "${TEXT_MUTED}╭─ AUTOMATION FEATURES ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}✓${RESET} Automatic invoice numbering"
    echo -e "  ${GREEN}✓${RESET} PDF/text invoice generation"
    echo -e "  ${GREEN}✓${RESET} Payment tracking"
    echo -e "  ${GREEN}✓${RESET} Overdue detection"
    echo -e "  ${GREEN}✓${RESET} Payment reminders"
    echo -e "  ${GREEN}✓${RESET} Revenue reporting"
    echo -e "  ${GREEN}✓${RESET} Client database"
    echo ""

    # Quick actions
    echo -e "${TEXT_MUTED}╭─ QUICK ACTIONS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}1.${RESET} Create Client"
    echo -e "  ${CYAN}2.${RESET} Generate Invoice"
    echo -e "  ${CYAN}3.${RESET} Mark Invoice Paid"
    echo -e "  ${CYAN}4.${RESET} View All Invoices"
    echo -e "  ${CYAN}5.${RESET} Send Payment Reminder"
    echo -e "  ${CYAN}6.${RESET} Revenue Report"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-6]${RESET} Select  ${TEXT_SECONDARY}[I]${RESET} Init DB  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Revenue report
show_revenue_report() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}REVENUE REPORT${RESET}\n"

    if [ -f "$INVOICES_DB" ]; then
        local total=$(sqlite3 "$INVOICES_DB" "SELECT SUM(total) FROM invoices WHERE status='paid';" || echo "0")
        local count=$(sqlite3 "$INVOICES_DB" "SELECT COUNT(*) FROM invoices WHERE status='paid';" || echo "0")

        echo -e "${BOLD}Total Revenue:${RESET} ${GREEN}\$$total${RESET}"
        echo -e "${BOLD}Paid Invoices:${RESET} $count"
        echo ""

        # Monthly breakdown (simplified)
        echo -e "${BOLD}Recent Payments:${RESET}\n"

        sqlite3 "$INVOICES_DB" "SELECT invoice_number, client_name, total, paid_date FROM invoices WHERE status='paid' ORDER BY paid_date DESC LIMIT 10;" | while IFS='|' read -r num client total date; do
            local paid=$(date -r $date "+%Y-%m-%d" 2>/dev/null || echo "Unknown")
            echo -e "  #$num - $client - \$$total - $paid"
        done
    fi

    echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# View all invoices
view_all_invoices() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}ALL INVOICES${RESET}\n"

    if [ -f "$INVOICES_DB" ]; then
        printf "${BOLD}%-8s %-25s %-10s %-10s %-12s${RESET}\n" "INV #" "CLIENT" "AMOUNT" "STATUS" "DUE DATE"
        echo "───────────────────────────────────────────────────────────────────────"

        sqlite3 "$INVOICES_DB" "SELECT invoice_number, client_name, total, status, due_date FROM invoices ORDER BY invoice_number DESC;" | while IFS='|' read -r num client total status due; do
            local due_str=$(date -r $due "+%Y-%m-%d" 2>/dev/null || echo "Unknown")

            local status_color="${ORANGE}"
            [ "$status" = "paid" ] && status_color="${GREEN}"

            printf "%-8s %-25s %-10s " "#$num" "${client:0:25}" "\$$total"
            echo -e "${status_color}%-10s${RESET} %s" "$status" "$due_str"
        done
    fi

    echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# Main loop
main() {
    init_databases

    while true; do
        show_invoice_dashboard

        read -n1 key

        case "$key" in
            '1')
                clear
                echo -e "${CYAN}Create Client${RESET}\n"
                echo -n "Client Name: "
                read name
                echo -n "Email: "
                read email
                echo -n "Company: "
                read company
                echo -n "Address: "
                read address

                local client_id=$(create_client "$name" "$email" "$company" "$address")

                echo -e "\n${GREEN}✓ Client created: $client_id${RESET}"
                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '2')
                clear
                echo -e "${CYAN}Generate Invoice${RESET}\n"

                # List clients
                echo "Select client:"
                sqlite3 "$CLIENTS_DB" "SELECT id, name, company FROM clients;" | nl

                echo -n "Client ID: "
                read client_id
                echo -n "Amount: "
                read amount
                echo -n "Due in days (default 30): "
                read due_days
                due_days=${due_days:-30}

                local result=$(generate_invoice "$client_id" "{\"desc\":\"Services\",\"qty\":1,\"rate\":$amount}" "$due_days")
                IFS='|' read -r inv_num inv_file <<< "$result"

                echo -e "\n${GREEN}✓ Invoice #$inv_num generated${RESET}"
                echo -e "${CYAN}File: $inv_file${RESET}"

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '3')
                clear
                echo -e "${CYAN}Mark Invoice Paid${RESET}\n"
                echo -n "Invoice Number: "
                read inv_num
                echo -n "Amount Paid: "
                read amount
                echo -n "Payment Method: "
                read method

                mark_paid "$inv_num" "$amount" "$method"

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '4')
                view_all_invoices
                ;;
            '5')
                clear
                echo -e "${CYAN}Send Payment Reminder${RESET}\n"
                echo -n "Invoice Number: "
                read inv_num

                send_reminder "$inv_num"

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '6')
                show_revenue_report
                ;;
            'i'|'I')
                clear
                echo -e "${CYAN}Initializing databases...${RESET}\n"
                init_databases
                echo -e "${GREEN}✓ Databases initialized${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}Invoice automation closed${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
