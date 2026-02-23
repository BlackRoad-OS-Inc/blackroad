#!/bin/zsh
# Sync enterprise forks with their upstream sources
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

declare -A UPSTREAMS=(
  ["blackbox-n8n"]="https://github.com/n8n-io/n8n.git"
  ["blackbox-airbyte"]="https://github.com/airbytehq/airbyte.git"
  ["blackbox-prefect"]="https://github.com/PrefectHQ/prefect.git"
  ["blackbox-temporal"]="https://github.com/temporalio/temporal.git"
  ["blackbox-activepieces"]="https://github.com/activepieces/activepieces.git"
  ["blackbox-huginn"]="https://github.com/huginn/huginn.git"
)

ENTERPRISE_DIR="/Users/alexa/blackroad/orgs/enterprise"

echo "${CYAN}🔄 Enterprise Upstream Sync${NC}\n"

for repo in "${(@k)UPSTREAMS}"; do
  dir="$ENTERPRISE_DIR/$repo"
  [ -d "$dir/.git" ] || continue

  upstream="${UPSTREAMS[$repo]}"
  cd "$dir"

  # Add upstream if not present
  git remote add upstream "$upstream" 2>/dev/null || true

  echo "${CYAN}▶ $repo${NC}"
  echo "  Upstream: $upstream"

  # Fetch (shallow to avoid massive downloads)
  git fetch upstream --depth=10 --quiet 2>/dev/null && \
    echo "  ${GREEN}✓ Fetched upstream${NC}" || \
    echo "  ⚠ Could not fetch (network or access)"
done
