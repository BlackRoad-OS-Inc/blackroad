#!/bin/zsh
# Deploy all BlackRoad websites to Cloudflare Pages

GREEN=$'\033[0;32m'; CYAN=$'\033[0;36m'; YELLOW=$'\033[1;33m'; NC=$'\033[0m'; BOLD=$'\033[1m'

SITES=(
  "blackroad-io:blackroad-io:blackroad.io"
  "blackroad-ai:blackroad-ai:blackroad.ai"
  "lucidia-earth:lucidia-earth:lucidia.earth"
  "agents:blackroad-agents-page:agents.blackroad.io"
)

deploy_site() {
  local dir="$1" project="$2" domain="$3"
  echo "${CYAN}  Deploying ${domain}...${NC}"
  if wrangler pages deploy "websites/${dir}" --project-name="${project}" 2>&1 | tail -2; then
    echo "${GREEN}  ✓ ${domain} deployed${NC}"
  else
    echo "${YELLOW}  ⚠ ${domain} — create project first: wrangler pages project create ${project}${NC}"
  fi
}

echo ""
echo "${BOLD}  BlackRoad Websites Deploy${NC}"
echo ""

case "${1:-all}" in
  blackroad.io)  deploy_site blackroad-io blackroad-io blackroad.io ;;
  blackroad.ai)  deploy_site blackroad-ai blackroad-ai blackroad.ai ;;
  lucidia.earth) deploy_site lucidia-earth lucidia-earth lucidia.earth ;;
  agents)        deploy_site agents blackroad-agents-page agents.blackroad.io ;;
  all)
    for entry in "${SITES[@]}"; do
      IFS=: read dir project domain <<< "$entry"
      deploy_site "$dir" "$project" "$domain"
    done
    ;;
  list)
    echo "  Sites:"
    for entry in "${SITES[@]}"; do
      IFS=: read dir project domain <<< "$entry"
      echo "    ${CYAN}${domain}${NC}  →  websites/${dir}/"
    done
    echo ""
    ;;
  *)
    echo "  Usage: ./deploy-websites.sh [all|blackroad.io|blackroad.ai|lucidia.earth|agents|list]"
    ;;
esac

echo ""
