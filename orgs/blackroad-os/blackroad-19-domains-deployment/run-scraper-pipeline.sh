#!/bin/bash

# BlackRoad Scraper + Generator Pipeline
# Complete automation: scrape → categorize → map → generate → validate → export → log

set -e

# Colors
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${MAGENTA}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║         🤖 BlackRoad Auto-Scraper Pipeline 🤖                 ║
║                                                                ║
║  scrape → categorize → map → generate → validate → export     ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check requirements
echo -e "${CYAN}[0/5] Checking requirements...${NC}"

if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) not found${NC}"
    echo "Install: brew install gh"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 not found${NC}"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not authenticated${NC}"
    echo "Run: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ Requirements met${NC}"

# Step 1: Scrape GitHub projects
echo ""
echo -e "${CYAN}[1/5] 🔍 Scraping GitHub organizations...${NC}"
python3 scrape-github-projects.py

if [ ! -f "github-projects-scraped.json" ]; then
    echo -e "${RED}❌ Scraping failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Scraping complete${NC}"

# Step 2: Generate website features
echo ""
echo -e "${CYAN}[2/5] 🎨 Generating website features...${NC}"
python3 generate-website-features.py

if [ ! -f "website-features-generated.json" ]; then
    echo -e "${RED}❌ Feature generation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Feature generation complete${NC}"

# Step 3: Validate and export
echo ""
echo -e "${CYAN}[3/5] ✅ Validating and exporting...${NC}"
python3 validate-and-export.py

VALIDATION_EXIT=$?

if [ ! -f "validation-report.json" ]; then
    echo -e "${RED}❌ Validation failed${NC}"
    exit 1
fi

if [ $VALIDATION_EXIT -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Validation passed with warnings${NC}"
else
    echo -e "${GREEN}✅ Validation passed${NC}"
fi

# Step 4: Update HTML templates
echo ""
echo -e "${CYAN}[4/5] 🔧 Updating HTML templates...${NC}"
python3 update-html-templates.py

echo -e "${GREEN}✅ HTML templates updated${NC}"

# Step 5: Generate summary
echo ""
echo -e "${CYAN}[5/5] 📊 Generating summary report...${NC}"

# Count projects
TOTAL_PROJECTS=$(cat github-projects-scraped.json | grep -o '"name"' | wc -l | tr -d ' ')
TOTAL_DOMAINS=$(cat website-features-generated.json | grep -o '"domain"' | wc -l | tr -d ' ')
EXPORTED_SITES=$(find sites -name "features.json" | wc -l | tr -d ' ')

# Read validation summary
PASSED=$(cat validation-report.json | grep -o '"passed": [0-9]*' | grep -o '[0-9]*')
WARNINGS=$(cat validation-report.json | grep -o '"warnings": [0-9]*' | grep -o '[0-9]*')
ERRORS=$(cat validation-report.json | grep -o '"errors": [0-9]*' | grep -o '[0-9]*')

echo -e "${MAGENTA}"
cat << EOF
╔════════════════════════════════════════════════════════════════╗
║                  📊 PIPELINE SUMMARY 📊                       ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}Scraping Results:${NC}"
echo "  Total GitHub projects: $TOTAL_PROJECTS"
echo "  Organizations scraped: 15"
echo ""

echo -e "${CYAN}Feature Generation:${NC}"
echo "  Domains mapped: $TOTAL_DOMAINS"
echo "  Features exported: $EXPORTED_SITES sites"
echo ""

echo -e "${CYAN}Validation Results:${NC}"
echo -e "  ${GREEN}✅ Passed: $PASSED${NC}"
echo -e "  ${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
echo -e "  ${RED}❌ Errors: $ERRORS${NC}"
echo ""

echo -e "${CYAN}Generated Files:${NC}"
echo "  📄 github-projects-scraped.json"
echo "  📄 website-features-generated.json"
echo "  📄 validation-report.json"
echo "  📁 sites/*/features.json (${EXPORTED_SITES} files)"
echo ""

if [ $VALIDATION_EXIT -eq 0 ]; then
    echo -e "${GREEN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║              ✨ PIPELINE COMPLETE! ✨                          ║
║                                                                ║
║  Your websites now have real GitHub project data!             ║
║                                                                ║
║  Next steps:                                                   ║
║    1. Review validation-report.json                            ║
║    2. Check sites/[domain]/features.json                       ║
║    3. Deploy: ./deploy-all-domains.sh                          ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
else
    echo -e "${YELLOW}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║          ⚠️  PIPELINE COMPLETE WITH WARNINGS ⚠️               ║
║                                                                ║
║  Review validation-report.json before deploying                ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
fi

# Offer to view reports
echo ""
read -p "View validation report? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat validation-report.json | python3 -m json.tool | less
fi

exit 0
