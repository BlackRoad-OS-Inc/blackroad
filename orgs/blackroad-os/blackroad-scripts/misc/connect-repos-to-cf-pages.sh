#!/bin/bash

# Connect GitHub Repos to Cloudflare Pages
# Automated connection script with safety checks

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔗 GitHub → Cloudflare Pages Connection Manager 🔗     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Repos ready to connect
declare -A REPOS
REPOS["blackroad-api"]="BlackRoad-OS/blackroad-api"
REPOS["blackroad-dashboard"]="BlackRoad-OS/blackroad-dashboard"
REPOS["earth-blackroad-io"]="BlackRoad-OS/earth-blackroad-io"
REPOS["console-blackroad-io"]="BlackRoad-OS/console-blackroad-io"

echo -e "${YELLOW}📋 Repositories Ready for Connection:${NC}\n"

for cf_project in "${!REPOS[@]}"; do
    repo="${REPOS[$cf_project]}"
    echo -e "  ${GREEN}✓${NC} CF Pages: ${CYAN}$cf_project${NC} ← GitHub: ${CYAN}$repo${NC}"
done

echo ""
echo -e "${YELLOW}⚠️  MANUAL STEPS REQUIRED:${NC}"
echo ""
echo "Due to Cloudflare API limitations, GitHub connections must be set up manually."
echo "Follow these steps for each project:"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

for cf_project in "${!REPOS[@]}"; do
    repo="${REPOS[$cf_project]}"

    echo -e "${GREEN}Project: $cf_project${NC}"
    echo ""
    echo "1. Open Cloudflare Dashboard:"
    echo -e "   ${CYAN}https://dash.cloudflare.com/pages${NC}"
    echo ""
    echo "2. Find and click on project: ${YELLOW}$cf_project${NC}"
    echo ""
    echo "3. Go to: Settings → Builds & deployments"
    echo ""
    echo "4. Click: ${GREEN}\"Connect to Git\"${NC}"
    echo ""
    echo "5. Select: ${GREEN}GitHub${NC}"
    echo ""
    echo "6. Authorize Cloudflare (if prompted)"
    echo ""
    echo "7. Choose repository:"
    echo -e "   Organization: ${YELLOW}BlackRoad-OS${NC}"
    echo -e "   Repository: ${YELLOW}$(basename $repo)${NC}"
    echo ""
    echo "8. Configure build settings:"
    echo "   Framework preset: ${GREEN}None${NC}"
    echo "   Build command: ${GREEN}(leave empty)${NC}"
    echo "   Build output directory: ${GREEN}/${NC}"
    echo "   Root directory: ${GREEN}(leave empty)${NC}"
    echo "   Production branch: ${GREEN}main${NC}"
    echo ""
    echo "9. Click: ${GREEN}\"Save and Deploy\"${NC}"
    echo ""
    echo "10. Wait for deployment to complete (~1-2 minutes)"
    echo ""
    echo "11. Verify deployment:"
    echo -e "    ${CYAN}https://$cf_project.pages.dev${NC}"
    echo ""

    # Special instructions for earth portal
    if [ "$cf_project" = "earth-blackroad-io" ]; then
        echo -e "${YELLOW}🌍 CUSTOM DOMAIN SETUP (earth.blackroad.io):${NC}"
        echo ""
        echo "12. Go to: Settings → Custom domains"
        echo ""
        echo "13. Click: ${GREEN}\"Set up a custom domain\"${NC}"
        echo ""
        echo "14. Enter: ${CYAN}earth.blackroad.io${NC}"
        echo ""
        echo "15. Click: ${GREEN}\"Continue\"${NC}"
        echo ""
        echo "16. DNS should configure automatically (Cloudflare DNS)"
        echo ""
        echo "17. Wait for SSL certificate (~5 minutes)"
        echo ""
        echo "18. Verify custom domain works:"
        echo -e "    ${CYAN}https://earth.blackroad.io${NC}"
        echo ""
    fi

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
done

echo -e "${GREEN}✅ VERIFICATION CHECKLIST:${NC}"
echo ""
echo "After connecting all 4 projects, verify:"
echo ""
echo "  [ ] blackroad-api.pages.dev shows API portal"
echo "  [ ] blackroad-dashboard.pages.dev shows monitoring dashboard"
echo "  [ ] earth-blackroad-io.pages.dev shows Earth portal"
echo "  [ ] earth.blackroad.io works with custom domain"
echo "  [ ] console-blackroad-io.pages.dev shows developer console"
echo "  [ ] All pages use official brand colors"
echo "  [ ] GitHub commits trigger auto-deployments"
echo ""

echo -e "${YELLOW}📝 AFTER CONNECTION:${NC}"
echo ""
echo "Update traffic lights:"
echo -e "  ${GREEN}~/blackroad-traffic-light.sh set blackroad-api green \"Connected to GitHub\"${NC}"
echo -e "  ${GREEN}~/blackroad-traffic-light.sh set blackroad-dashboard green \"Connected to GitHub\"${NC}"
echo -e "  ${GREEN}~/blackroad-traffic-light.sh set earth-blackroad-io green \"Connected with custom domain\"${NC}"
echo -e "  ${GREEN}~/blackroad-traffic-light.sh set console-blackroad-io green \"Connected to GitHub\"${NC}"
echo ""

echo "Log to memory:"
echo -e "  ${GREEN}~/memory-system.sh log completed \"cf-github-connections\" \"Connected 4 repos to CF Pages\" \"cleanup\"${NC}"
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                 Ready to Proceed! 🚀                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
