#!/bin/bash

# Bulk Subdomain Repository Automation
# Creates and deploys content to all 56 subdomain repos

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🚀 Bulk Subdomain Repository Automation 🚀           ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Template file location
TEMPLATE="/tmp/subdomain-template.html"

# Define all subdomain repositories with metadata
declare -A SUBDOMAINS

# Business Functions
SUBDOMAINS["marketing-blackroadio"]="📊 Marketing|Marketing automation and campaigns|marketing,automation,campaigns"
SUBDOMAINS["sales-blackroadio"]="💼 Sales|Sales pipeline and CRM|sales,crm,pipeline"
SUBDOMAINS["hr-blackroadio"]="👥 HR|Human resources and talent|hr,recruiting,talent"
SUBDOMAINS["finance-blackroadio"]="💰 Finance|Financial management and reporting|finance,accounting,reporting"
SUBDOMAINS["legal-blackroadio"]="⚖️ Legal|Legal documentation and compliance|legal,compliance,contracts"

# Developer/Technical
SUBDOMAINS["api-blackroadio"]="🔌 API|API documentation and reference|api,documentation,reference"
SUBDOMAINS["dev-blackroadio"]="💻 Dev|Developer resources and tools|dev,tools,resources"
SUBDOMAINS["cli-blackroadio"]="⌨️ CLI|Command-line interface tools|cli,terminal,tools"
SUBDOMAINS["sdk-blackroadio"]="🛠️ SDK|Software development kits|sdk,libraries,development"

# Product/Features
SUBDOMAINS["models-blackroadio"]="🧠 Models|AI models and datasets|ai,models,ml"
SUBDOMAINS["agents-blackroad-io"]="🤖 Agents|AI agent marketplace|agents,ai,automation"
SUBDOMAINS["quantum-blackroad-io"]="⚛️ Quantum|Quantum computing platform|quantum,computing,qiskit"
SUBDOMAINS["circuits-blackroadio"]="🔌 Circuits|Quantum circuit builder|circuits,quantum,builder"

# Community/Content
SUBDOMAINS["blog-blackroad-io"]="📝 Blog|Company blog and updates|blog,news,updates"
SUBDOMAINS["community-blackroad-io"]="🌍 Community|Developer community hub|community,forum,discussion"
SUBDOMAINS["learn-blackroadio"]="📚 Learn|Learning resources and tutorials|learn,tutorials,education"

echo -e "${YELLOW}📋 Subdomain Repositories to Process: ${#SUBDOMAINS[@]}${NC}\n"

process_repo() {
    local repo=$1
    local metadata=$2

    IFS='|' read -r icon_title description tags <<< "$metadata"
    local domain="${repo//-/.}"

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Processing: $repo${NC}"
    echo -e "  Title: $icon_title"
    echo -e "  Domain: $domain"

    # Check if repo exists
    if ! gh repo view "BlackRoad-OS/$repo" &>/dev/null; then
        echo -e "  ${RED}❌ Repo doesn't exist - skipping${NC}"
        return 1
    fi

    echo -e "  ${GREEN}✅ Repo exists${NC}"

    # Clone repo
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    if ! gh repo clone "BlackRoad-OS/$repo" . &>/dev/null; then
        echo -e "  ${RED}❌ Failed to clone - skipping${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    echo -e "  ${GREEN}✅ Cloned successfully${NC}"

    # Check if index.html already exists
    if [ -f "index.html" ]; then
        local size=$(wc -c < "index.html")
        if [ "$size" -gt 1000 ]; then
            echo -e "  ${YELLOW}⚠️  Has content ($size bytes) - skipping${NC}"
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 0
        fi
    fi

    # Generate features based on tags
    local features=""
    IFS=',' read -ra TAG_ARRAY <<< "$tags"
    for tag in "${TAG_ARRAY[@]}"; do
        features+="
            <div class=\"feature\">
                <div class=\"feature-icon\">✨</div>
                <div class=\"feature-title\">$(echo $tag | tr '[:lower:]' '[:upper:]')</div>
                <div class=\"feature-desc\">Advanced $(echo $tag) capabilities</div>
            </div>"
    done

    # Create index.html from template
    cp "$TEMPLATE" index.html
    sed -i '' "s|{{TITLE}}|$icon_title|g" index.html
    sed -i '' "s|{{ICON}}||g" index.html
    sed -i '' "s|{{DESCRIPTION}}|$description|g" index.html
    sed -i '' "s|{{DOMAIN}}|$domain|g" index.html
    sed -i '' "s|{{FEATURES}}|$features|g" index.html

    echo -e "  ${GREEN}✅ Generated index.html${NC}"

    # Commit and push
    git add index.html
    git commit -m "Add brand-compliant landing page

- $description
- Official BlackRoad brand colors
- Golden ratio spacing
- Coming soon status

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>" &>/dev/null

    if git push &>/dev/null; then
        echo -e "  ${GREEN}✅ Pushed successfully${NC}"
    else
        echo -e "  ${RED}❌ Failed to push${NC}"
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"

    echo -e "  ${GREEN}✅ Complete!${NC}"

    # Log to memory
    if [ -n "$MY_CLAUDE" ]; then
        ~/memory-system.sh log updated "subdomain-$repo" "Added brand-compliant landing page" "cleanup,subdomain" &>/dev/null || true
    fi
}

# Process repos
count=0
success=0
skipped=0
failed=0

for repo in "${!SUBDOMAINS[@]}"; do
    ((count++))
    echo ""
    echo -e "${YELLOW}[$count/${#SUBDOMAINS[@]}] Processing $repo...${NC}"

    if process_repo "$repo" "${SUBDOMAINS[$repo]}"; then
        ((success++))
    else
        if [ $? -eq 0 ]; then
            ((skipped++))
        else
            ((failed++))
        fi
    fi

    # Rate limiting
    sleep 2
done

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    📊 SUMMARY 📊                          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}✅ Successful: $success${NC}"
echo -e "${YELLOW}⚠️  Skipped (has content): $skipped${NC}"
echo -e "${RED}❌ Failed: $failed${NC}"
echo -e "${CYAN}📋 Total: ${#SUBDOMAINS[@]}${NC}"
echo ""

echo -e "${GREEN}Next steps:${NC}"
echo "1. Connect updated repos to Cloudflare Pages"
echo "2. Verify deployments"
echo "3. Update traffic lights"
echo ""
