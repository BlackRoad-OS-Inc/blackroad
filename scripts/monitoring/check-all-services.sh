#!/bin/bash
#
# BlackRoad Services - Health Check Script
# Tests all deployed services
#

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Service mappings (name:url)
SERVICES=(
  "prism:prism-two-ruby.vercel.app"
  "operator:operator-swart.vercel.app"
  "brand:brand-ten-woad.vercel.app"
  "docs:docs-one-wheat.vercel.app"
  "core:core-six-dun.vercel.app"
  "ideas:ideas-five-self.vercel.app"
  "infra:infra-ochre-three.vercel.app"
  "research:research-ten-zeta.vercel.app"
  "demo:demo-psi-hazel-24.vercel.app"
  "api:api-pearl-seven.vercel.app"
)

echo -e "${BLUE}🏥 BlackRoad Services Health Check${NC}"
echo -e "${BLUE}===================================${NC}\n"

HEALTHY=0
UNHEALTHY=0

# Check each service
for item in "${SERVICES[@]}"; do
  service="${item%%:*}"
  url="${item##*:}"
  
  echo -n "Checking $service... "
  
  # Test health endpoint
  status=$(curl -s -o /dev/null -w "%{http_code}" "https://$url/api/health" 2>/dev/null || echo "000")
  
  if [ "$status" = "200" ]; then
    echo -e "${GREEN}✅ OK${NC} (https://$url)"
    ((HEALTHY++))
  else
    echo -e "${RED}❌ FAILED${NC} (Status: $status)"
    ((UNHEALTHY++))
  fi
done

echo -e "\n${BLUE}===================================${NC}"
echo -e "${BLUE}📊 Summary${NC}"
echo -e "${BLUE}===================================${NC}"
echo -e "${GREEN}Healthy: $HEALTHY${NC}"
echo -e "${RED}Unhealthy: $UNHEALTHY${NC}"
echo -e "${BLUE}Total: $((HEALTHY + UNHEALTHY))${NC}\n"

if [ $UNHEALTHY -eq 0 ]; then
  echo -e "${GREEN}🎉 All services are healthy!${NC}\n"
  exit 0
else
  echo -e "${RED}⚠️  Some services are down!${NC}\n"
  exit 1
fi
