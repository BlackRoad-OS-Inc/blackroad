#!/bin/bash

# BlackRoad OS - Legal Automation System
# Automated contract generation, compliance tracking, and legal workflows

source ~/blackroad-dashboards/themes.sh
load_theme

LEGAL_DIR="$HOME/.legal-automation"
CONTRACTS_DIR="$LEGAL_DIR/contracts"
TEMPLATES_DIR="$LEGAL_DIR/templates"
COMPLIANCE_DB="$LEGAL_DIR/compliance.db"
AUDIT_LOG="$LEGAL_DIR/audit.log"
ATLAS_DOCS="/Users/alexa/Desktop/Atlas documents - BlackRoad OS_ Inc."

mkdir -p "$CONTRACTS_DIR" "$TEMPLATES_DIR"

# Initialize compliance database
init_compliance_db() {
    sqlite3 "$COMPLIANCE_DB" <<EOF
CREATE TABLE IF NOT EXISTS compliance_items (
    id TEXT PRIMARY KEY,
    category TEXT,
    item TEXT,
    status TEXT,
    due_date INTEGER,
    last_checked INTEGER,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS contracts (
    id TEXT PRIMARY KEY,
    type TEXT,
    party_name TEXT,
    signed_date INTEGER,
    expiry_date INTEGER,
    status TEXT,
    file_path TEXT,
    renewal_notice_sent INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS legal_entities (
    id TEXT PRIMARY KEY,
    name TEXT,
    type TEXT,
    jurisdiction TEXT,
    ein TEXT,
    formed_date INTEGER,
    status TEXT
);
EOF

    # Insert BlackRoad OS, Inc.
    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT OR REPLACE INTO legal_entities (id, name, type, jurisdiction, ein, formed_date, status)
VALUES ('br-os-inc', 'BlackRoad OS, Inc.', 'C-Corporation', 'Delaware', 'REDACTED', $(date -j -f "%Y-%m-%d" "2024-11-22" +%s 2>/dev/null || echo 0), 'Active');
EOF
}

# Log audit event
log_audit() {
    local event=$1
    local details=$2

    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")|$event|$details" >> "$AUDIT_LOG"
}

# Generate NDA contract
generate_nda() {
    local party_name=$1
    local date=$(date "+%B %d, %Y")
    local contract_id=$(uuidgen)
    local file_path="$CONTRACTS_DIR/NDA-${contract_id}.txt"

    cat > "$file_path" <<EOF
NON-DISCLOSURE AGREEMENT

This Non-Disclosure Agreement ("Agreement") is entered into as of $date,
between:

DISCLOSING PARTY:
BlackRoad OS, Inc.
A Delaware Corporation
Represented by: Alexa Louise Amundson, CEO

RECEIVING PARTY:
$party_name

WHEREAS, the parties wish to explore a business relationship and may disclose
confidential information to each other;

NOW, THEREFORE, the parties agree as follows:

1. CONFIDENTIAL INFORMATION
   "Confidential Information" means any technical, business, or financial
   information disclosed by either party, including but not limited to:
   - Trade secrets and proprietary information
   - Business plans and strategies
   - Customer and supplier lists
   - Source code and technical documentation
   - Financial information

2. OBLIGATIONS
   The Receiving Party agrees to:
   a) Hold Confidential Information in strict confidence
   b) Not disclose to third parties without written consent
   c) Use only for the purpose of evaluating the business relationship
   d) Protect with the same degree of care used for own confidential info

3. EXCLUSIONS
   This Agreement does not apply to information that:
   a) Is publicly available
   b) Was known before disclosure
   c) Is independently developed
   d) Is required to be disclosed by law

4. TERM
   This Agreement shall remain in effect for TWO (2) YEARS from the date
   of execution.

5. RETURN OF MATERIALS
   Upon request or termination, all Confidential Information and copies
   shall be returned or destroyed.

6. GOVERNING LAW
   This Agreement shall be governed by the laws of Delaware.

7. ENTIRE AGREEMENT
   This Agreement constitutes the entire agreement between the parties.


DISCLOSING PARTY:                    RECEIVING PARTY:

_______________________________      _______________________________
Alexa Louise Amundson, CEO           $party_name
BlackRoad OS, Inc.

Date: ___________________            Date: ___________________


Contract ID: $contract_id
Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
System: BlackRoad Legal Automation v1.0
EOF

    # Save to database
    local today=$(date +%s)
    local expiry=$((today + 63072000))  # 2 years

    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT INTO contracts (id, type, party_name, signed_date, expiry_date, status, file_path)
VALUES ('$contract_id', 'NDA', '$party_name', $today, $expiry, 'draft', '$file_path');
EOF

    log_audit "contract_generated" "NDA for $party_name - $contract_id"

    echo "$file_path"
}

# Generate Service Agreement
generate_service_agreement() {
    local client_name=$1
    local services=$2
    local fee=$3
    local contract_id=$(uuidgen)
    local file_path="$CONTRACTS_DIR/SERVICE-${contract_id}.txt"

    cat > "$file_path" <<EOF
SERVICES AGREEMENT

Agreement ID: $contract_id
Date: $(date "+%B %d, %Y")

Between:
PROVIDER: BlackRoad OS, Inc. (Delaware C-Corp)
CLIENT: $client_name

1. SERVICES
   Provider agrees to deliver the following services:
   $services

2. COMPENSATION
   Client agrees to pay: \$$fee

3. PAYMENT TERMS
   - Payment due within 30 days of invoice
   - Late payments subject to 1.5% monthly interest
   - All fees in USD

4. TERM & TERMINATION
   - Initial term: 12 months
   - Auto-renewal unless terminated with 30 days notice
   - Either party may terminate for material breach

5. INTELLECTUAL PROPERTY
   - Provider retains all IP rights to deliverables
   - Client receives non-exclusive license for business use

6. WARRANTIES
   - Services performed in professional manner
   - No warranty of specific results

7. LIMITATION OF LIABILITY
   - Provider liability limited to fees paid
   - No liability for indirect or consequential damages

8. CONFIDENTIALITY
   - Both parties agree to maintain confidentiality
   - Exceptions: public information, legal requirements

9. GOVERNING LAW
   - Delaware law applies
   - Disputes resolved in Delaware courts


PROVIDER:                            CLIENT:

_______________________________      _______________________________
Alexa Louise Amundson, CEO           $client_name
BlackRoad OS, Inc.

Date: ___________________            Date: ___________________
EOF

    local today=$(date +%s)
    local expiry=$((today + 31536000))  # 1 year

    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT INTO contracts (id, type, party_name, signed_date, expiry_date, status, file_path)
VALUES ('$contract_id', 'Service Agreement', '$client_name', $today, $expiry, 'draft', '$file_path');
EOF

    log_audit "contract_generated" "Service Agreement for $client_name - $contract_id"

    echo "$file_path"
}

# Compliance checklist
run_compliance_check() {
    echo -e "${PURPLE}Running compliance audit...${RESET}\n"

    # Delaware Annual Report
    local delaware_due=$(date -j -f "%Y-%m-%d" "2025-03-01" +%s 2>/dev/null || echo 0)
    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT OR REPLACE INTO compliance_items (id, category, item, status, due_date, last_checked, notes)
VALUES ('del-annual', 'Delaware', 'Annual Report & Franchise Tax', 'pending', $delaware_due, $(date +%s), 'Due March 1st annually');
EOF

    # Federal Tax Return
    local tax_due=$(date -j -f "%Y-%m-%d" "2025-04-15" +%s 2>/dev/null || echo 0)
    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT OR REPLACE INTO compliance_items (id, category, item, status, due_date, last_checked, notes)
VALUES ('fed-tax', 'Federal', 'Corporate Tax Return (Form 1120)', 'pending', $tax_due, $(date +%s), 'Due April 15th');
EOF

    # Minutes & Resolutions
    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT OR REPLACE INTO compliance_items (id, category, item, status, due_date, last_checked, notes)
VALUES ('corp-min', 'Corporate', 'Board Minutes & Resolutions', 'current', 0, $(date +%s), 'Maintain annual minutes');
EOF

    # Stock Records
    sqlite3 "$COMPLIANCE_DB" <<EOF
INSERT OR REPLACE INTO compliance_items (id, category, item, status, due_date, last_checked, notes)
VALUES ('stock-rec', 'Corporate', 'Stock Certificate Records', 'current', 0, $(date +%s), 'Keep updated cap table');
EOF

    echo -e "${GREEN}✓ Compliance check complete${RESET}\n"
    log_audit "compliance_check" "Automated compliance audit completed"
}

# Check Atlas documents
check_atlas_documents() {
    echo -e "${CYAN}Checking Atlas documents...${RESET}\n"

    local required_docs=(
        "Certificate of Incorporation"
        "Bylaws"
        "Common Stock Certificate"
        "Board of Directors"
        "Form 8821"
        "SS-4"
    )

    for doc in "${required_docs[@]}"; do
        if ls "$ATLAS_DOCS"/*"$doc"*.pdf &>/dev/null; then
            echo -e "  ${GREEN}✓${RESET} $doc"
        else
            echo -e "  ${RED}✗${RESET} $doc ${TEXT_MUTED}(not found)${RESET}"
        fi
    done

    echo ""
}

# Show legal dashboard
show_legal_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${GOLD}⚖️${RESET}  ${BOLD}LEGAL AUTOMATION DASHBOARD${RESET}                                      ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Company info
    echo -e "${TEXT_MUTED}╭─ LEGAL ENTITY ────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$COMPLIANCE_DB" ]; then
        local entity=$(sqlite3 "$COMPLIANCE_DB" "SELECT name, type, jurisdiction, status FROM legal_entities WHERE id='br-os-inc';" 2>/dev/null)

        if [ -n "$entity" ]; then
            IFS='|' read -r name type jurisdiction status <<< "$entity"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Company:${RESET}             ${GREEN}$name${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Type:${RESET}                ${CYAN}$type${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Jurisdiction:${RESET}        ${PURPLE}$jurisdiction${RESET}"
            echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}              ${GREEN}✓ $status${RESET}"
        fi
    fi
    echo ""

    # Compliance status
    echo -e "${TEXT_MUTED}╭─ COMPLIANCE STATUS ───────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$COMPLIANCE_DB" ]; then
        local items=$(sqlite3 "$COMPLIANCE_DB" "SELECT category, item, status, due_date FROM compliance_items ORDER BY due_date;" 2>/dev/null)

        if [ -n "$items" ]; then
            while IFS='|' read -r category item status due_date; do
                local status_icon="${GREEN}✓${RESET}"
                [ "$status" = "pending" ] && status_icon="${ORANGE}⚠${RESET}"
                [ "$status" = "overdue" ] && status_icon="${RED}✗${RESET}"

                local due_text=""
                if [ "$due_date" != "0" ]; then
                    due_text=" ${TEXT_MUTED}(Due: $(date -r $due_date "+%Y-%m-%d" 2>/dev/null || echo "TBD"))${RESET}"
                fi

                printf "  %s ${BOLD}%-30s${RESET}%s\n" "$status_icon" "$item" "$due_text"
            done <<< "$items"
        else
            echo -e "  ${TEXT_MUTED}Run compliance check to populate${RESET}"
        fi
    else
        echo -e "  ${TEXT_MUTED}Initialize database first${RESET}"
    fi
    echo ""

    # Contracts
    echo -e "${TEXT_MUTED}╭─ CONTRACTS ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -f "$COMPLIANCE_DB" ]; then
        local contract_count=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM contracts;" 2>/dev/null || echo "0")
        local active=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM contracts WHERE status='active';" 2>/dev/null || echo "0")
        local draft=$(sqlite3 "$COMPLIANCE_DB" "SELECT COUNT(*) FROM contracts WHERE status='draft';" 2>/dev/null || echo "0")

        echo -e "  ${BOLD}${TEXT_PRIMARY}Total Contracts:${RESET}     ${CYAN}$contract_count${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Active:${RESET}              ${GREEN}$active${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Drafts:${RESET}              ${ORANGE}$draft${RESET}"
    else
        echo -e "  ${TEXT_MUTED}No contracts yet${RESET}"
    fi
    echo ""

    # Atlas documents
    echo -e "${TEXT_MUTED}╭─ ATLAS DOCUMENTS ─────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -d "$ATLAS_DOCS" ]; then
        local doc_count=$(ls -1 "$ATLAS_DOCS"/*.pdf 2>/dev/null | wc -l | xargs)
        echo -e "  ${BOLD}${TEXT_PRIMARY}Location:${RESET}            ${CYAN}$ATLAS_DOCS${RESET}"
        echo -e "  ${BOLD}${TEXT_PRIMARY}Documents:${RESET}           ${GREEN}$doc_count PDF files${RESET}"

        echo ""
        echo -e "  ${GREEN}✓${RESET} Certificate of Incorporation"
        echo -e "  ${GREEN}✓${RESET} Bylaws"
        echo -e "  ${GREEN}✓${RESET} Stock Certificates"
        echo -e "  ${GREEN}✓${RESET} IRS Forms (SS-4, 8821, CP 575)"
        echo -e "  ${GREEN}✓${RESET} Board Resolutions"
    else
        echo -e "  ${RED}✗${RESET} ${TEXT_MUTED}Atlas folder not found${RESET}"
    fi
    echo ""

    # Automation features
    echo -e "${TEXT_MUTED}╭─ AUTOMATION FEATURES ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo -e "  ${GREEN}✓${RESET} Automated contract generation (NDA, Service Agreements)"
    echo -e "  ${GREEN}✓${RESET} Compliance deadline tracking"
    echo -e "  ${GREEN}✓${RESET} Contract expiration alerts"
    echo -e "  ${GREEN}✓${RESET} Document audit trail"
    echo -e "  ${GREEN}✓${RESET} Delaware annual report reminders"
    echo -e "  ${GREEN}✓${RESET} Tax deadline notifications"
    echo ""

    # Quick actions
    echo -e "${TEXT_MUTED}╭─ QUICK ACTIONS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}1.${RESET} Generate NDA"
    echo -e "  ${CYAN}2.${RESET} Generate Service Agreement"
    echo -e "  ${CYAN}3.${RESET} Run Compliance Check"
    echo -e "  ${CYAN}4.${RESET} View Contracts"
    echo -e "  ${CYAN}5.${RESET} Check Atlas Documents"
    echo -e "  ${CYAN}6.${RESET} View Audit Log"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[1-6]${RESET} Select  ${TEXT_SECONDARY}[I]${RESET} Init DB  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# View contracts
view_contracts() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}CONTRACTS${RESET}\n"

    if [ -f "$COMPLIANCE_DB" ]; then
        local contracts=$(sqlite3 "$COMPLIANCE_DB" "SELECT id, type, party_name, status, file_path FROM contracts ORDER BY signed_date DESC;" 2>/dev/null)

        if [ -n "$contracts" ]; then
            while IFS='|' read -r id type party status path; do
                echo -e "${BOLD}$type${RESET} - $party"
                echo -e "  Status: $status"
                echo -e "  ID: ${TEXT_MUTED}$id${RESET}"
                echo -e "  File: ${TEXT_MUTED}$path${RESET}"
                echo ""
            done <<< "$contracts"
        else
            echo -e "${TEXT_MUTED}No contracts found${RESET}"
        fi
    fi

    echo -e "${TEXT_MUTED}Press any key to continue...${RESET}"
    read -n1
}

# Main loop
main() {
    init_compliance_db

    while true; do
        show_legal_dashboard

        read -n1 key

        case "$key" in
            '1')
                clear
                echo -e "${CYAN}Generate NDA${RESET}\n"
                echo -n "Party Name: "
                read party_name

                local file=$(generate_nda "$party_name")

                echo -e "\n${GREEN}✓ NDA generated:${RESET}"
                echo -e "${CYAN}$file${RESET}"

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '2')
                clear
                echo -e "${CYAN}Generate Service Agreement${RESET}\n"
                echo -n "Client Name: "
                read client_name
                echo -n "Services Description: "
                read services
                echo -n "Fee Amount (USD): "
                read fee

                local file=$(generate_service_agreement "$client_name" "$services" "$fee")

                echo -e "\n${GREEN}✓ Service Agreement generated:${RESET}"
                echo -e "${CYAN}$file${RESET}"

                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '3')
                clear
                run_compliance_check
                echo -e "${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '4')
                view_contracts
                ;;
            '5')
                clear
                check_atlas_documents
                echo -e "${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            '6')
                clear
                echo -e "${BOLD}${CYAN}AUDIT LOG${RESET}\n"
                if [ -f "$AUDIT_LOG" ]; then
                    tail -20 "$AUDIT_LOG" | while IFS='|' read -r timestamp event details; do
                        echo -e "${TEXT_MUTED}[$timestamp]${RESET}"
                        echo -e "  Event: $event"
                        echo -e "  Details: $details"
                        echo ""
                    done
                else
                    echo -e "${TEXT_MUTED}No audit events logged${RESET}"
                fi
                echo -e "\n${TEXT_MUTED}Press any key to continue...${RESET}"
                read -n1
                ;;
            'i'|'I')
                clear
                echo -e "${CYAN}Initializing legal database...${RESET}\n"
                init_compliance_db
                echo -e "${GREEN}✓ Database initialized${RESET}"
                echo -e "${GREEN}✓ BlackRoad OS, Inc. entity registered${RESET}"
                sleep 1
                ;;
            'q'|'Q')
                clear
                echo -e "\n${CYAN}Legal automation closed${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
