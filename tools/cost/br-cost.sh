#!/bin/zsh
# BR COST - Get billable costs to $0
# Audits all paid services and provides migration path to free tier

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BLUE='\033[0;34m'; NC='\033[0m'

show_help() {
  echo "${CYAN}br cost${NC} - Cost optimizer"
  echo ""
  echo "Commands:"
  echo "  audit      - Audit all service costs"
  echo "  zero       - Show path to $0 for each service"
  echo "  report     - Full cost report"
  echo "  github     - GitHub/Copilot cost analysis"
  echo "  cloudflare - Cloudflare plan analysis"
  echo "  railway    - Railway cost analysis"
}

cmd_audit() {
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}  💰 BLACKROAD COST AUDIT — TARGET: \$0/month${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
  echo ""
  
  echo -e "${YELLOW}▸ GitHub${NC}"
  echo "  Free: 2,000 Actions min/month (public repos: unlimited)"
  echo "  Copilot Individual: \$10/month"
  echo "  ${GREEN}→ ZERO: Use public repos for Actions, OSS Copilot access${NC}"
  echo ""
  
  echo -e "${YELLOW}▸ Cloudflare${NC}"
  echo "  Free: Workers 100k req/day, Pages unlimited, R2 10GB"
  echo "  Pro: \$20/month"
  echo "  ${GREEN}→ ZERO: Stay on Free tier (sufficient for current usage)${NC}"
  echo ""
  
  echo -e "${YELLOW}▸ Railway${NC}"
  echo "  Hobby: \$5/month credit"
  echo "  Usage last 30d: check 'railway usage'"
  echo "  ${GREEN}→ ZERO: Move compute to Pi fleet, use Railway only for DB${NC}"
  echo ""
  
  echo -e "${YELLOW}▸ DigitalOcean${NC}"
  echo "  gematria (159.65.43.12): ~\$6/month"
  echo "  anastasia (174.138.44.45): ~\$6/month"
  echo "  ${YELLOW}→ REDUCE: Keep 1 DO node for external IP, self-host rest on Pis${NC}"
  echo ""
  
  echo -e "${YELLOW}▸ Pi Fleet (owned hardware)${NC}"
  echo "  cecilia, alice, aria, octavia, lucidia: \$0 (electricity ~\$2/month)"
  echo "  ${GREEN}→ MOVE ALL COMPUTE HERE${NC}"
  echo ""
  
  echo -e "${BLUE}───────────────────────────────────────────────────${NC}"
  echo -e "  Total current estimate: ~\$25-40/month"
  echo -e "  ${GREEN}Target after optimization: ~\$2-6/month (DO only)${NC}"
  echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
}

cmd_zero() {
  echo -e "${CYAN}🎯 PATH TO \$0 BILLABLE COST${NC}"
  echo ""
  echo "1. ${GREEN}GitHub Copilot${NC}: Apply for OSS maintainer access → \$0"
  echo "   → https://github.com/github/copilot-oss-program"
  echo ""
  echo "2. ${GREEN}GitHub Actions${NC}: Make repos public → unlimited free minutes"
  echo "   → br org-audit public-check"
  echo ""
  echo "3. ${GREEN}Cloudflare${NC}: Free tier is sufficient → \$0"
  echo "   → Already on free tier for most services"
  echo ""
  echo "4. ${GREEN}Railway${NC}: Migrate services to Pi fleet → \$0"
  echo "   → br pi deploy --all-railway-services"
  echo ""
  echo "5. ${GREEN}DigitalOcean${NC}: Consolidate to 1 node (\$6/mo) or use Pis only"
  echo "   → Pi fleet has external access via Cloudflare Tunnel"
  echo ""
  echo "6. ${GREEN}HuggingFace${NC}: Free tier (private models: \$9/mo)"
  echo "   → Self-host models on octavia (AI compute Pi)"
  echo ""
  echo "Net result: \$0 with Pi fleet + CF tunnel + free tiers"
}

case "${1:-help}" in
  audit)     cmd_audit ;;
  zero)      cmd_zero ;;
  report)    cmd_audit; echo ""; cmd_zero ;;
  github)    echo "GitHub cost: br cost audit | grep -A3 GitHub" ;;
  cloudflare) echo "CF cost: see br cost audit" ;;
  railway)   command -v railway &>/dev/null && railway status || echo "Railway CLI not installed" ;;
  *)         show_help ;;
esac
