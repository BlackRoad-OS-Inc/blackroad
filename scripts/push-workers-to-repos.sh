#!/bin/zsh
# push-workers-to-repos.sh — Push each worker's code to its individual GitHub repo
# under BlackRoad-OS org for CI/CD to trigger deployment

set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

WORKERS_DIR="/Users/alexa/blackroad/workers"
TMP_DIR="/tmp/br-worker-push"
SUCCESS=0; FAILED=0

echo -e "\n${CYAN}${BOLD}◆ Pushing Workers to Individual GitHub Repos${NC}\n"

# Map worker-dir to repo name
declare -A REPO_MAP
REPO_MAP=(
  "agents-blackroadio" "agents-blackroadio"
  "dashboard-blackroadio" "dashboard-blackroadio"
  "blackroad-io" "blackroad-io"
  "blackroad-ai" "blackroad-ai"
  "blackroad-network" "blackroad-network"
  "blackroad-systems" "blackroad-systems"
  "api-blackroadio" "api-blackroadio"
  "docs-blackroadio" "docs-blackroadio"
  "console-blackroadio" "console-blackroadio"
  "ai-blackroadio" "ai-blackroadio"
  "analytics-blackroadio" "analytics-blackroadio"
  "status-blackroadio" "status-blackroadio"
  "about-blackroadio" "about-blackroadio"
  "admin-blackroadio" "admin-blackroadio"
  "algorithms-blackroadio" "algorithms-blackroadio"
  "alice-blackroadio" "alice-blackroadio"
  "asia-blackroadio" "asia-blackroadio"
  "blockchain-blackroadio" "blockchain-blackroadio"
  "blocks-blackroadio" "blocks-blackroadio"
  "blog-blackroadio" "blog-blackroadio"
  "cdn-blackroadio" "cdn-blackroadio"
  "chain-blackroadio" "chain-blackroadio"
  "circuits-blackroadio" "circuits-blackroadio"
  "cli-blackroadio" "cli-blackroadio"
  "compliance-blackroadio" "compliance-blackroadio"
  "compute-blackroadio" "compute-blackroadio"
  "control-blackroadio" "control-blackroadio"
  "data-blackroadio" "data-blackroadio"
  "demo-blackroadio" "demo-blackroadio"
  "design-blackroadio" "design-blackroadio"
  "dev-blackroadio" "dev-blackroadio"
  "edge-blackroadio" "edge-blackroadio"
  "editor-blackroadio" "editor-blackroadio"
  "engineering-blackroadio" "engineering-blackroadio"
  "eu-blackroadio" "eu-blackroadio"
  "events-blackroadio" "events-blackroadio"
  "explorer-blackroadio" "explorer-blackroadio"
  "features-blackroadio" "features-blackroadio"
  "finance-blackroadio" "finance-blackroadio"
  "global-blackroadio" "global-blackroadio"
  "guide-blackroadio" "guide-blackroadio"
  "hardware-blackroadio" "hardware-blackroadio"
  "help-blackroadio" "help-blackroadio"
  "hr-blackroadio" "hr-blackroadio"
  "ide-blackroadio" "ide-blackroadio"
  "network-blackroadio" "network-blackroadio"
)

rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR"

for WORKER_DIR in "${!REPO_MAP[@]}"; do
  REPO="${REPO_MAP[$WORKER_DIR]}"
  SRC="$WORKERS_DIR/$WORKER_DIR"
  
  if [[ ! -d "$SRC" ]]; then
    echo -e "${RED}✗ Missing worker dir: $WORKER_DIR${NC}"
    ((FAILED++))
    continue
  fi

  echo -ne "${CYAN}→${NC} ${BOLD}BlackRoad-OS/$REPO${NC}... "
  
  WORK="$TMP_DIR/$REPO"
  git clone --depth=1 "https://github.com/BlackRoad-OS/$REPO.git" "$WORK" -q 2>/dev/null || {
    echo -e "${RED}✗ Clone failed${NC}"
    ((FAILED++))
    continue
  }
  
  # Copy worker files into the cloned repo
  cp -r "$SRC/src" "$WORK/" 2>/dev/null || true
  cp "$SRC/wrangler.toml" "$WORK/" 2>/dev/null || true
  cp "$SRC/package.json" "$WORK/" 2>/dev/null || true
  mkdir -p "$WORK/.github/workflows"
  cp "$SRC/.github/workflows/deploy.yml" "$WORK/.github/workflows/deploy.yml" 2>/dev/null || true
  
  cd "$WORK"
  git add -A
  
  if git diff --cached --quiet; then
    echo -e "up to date"
    ((SUCCESS++))
    cd "$WORKERS_DIR"
    continue
  fi
  
  git commit -m "feat: live worker with real-time data

Worker: $REPO
Route: $(grep 'pattern' wrangler.toml | head -1 | sed 's/.*= //')
CI/CD: GitHub Actions → wrangler deploy

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>" -q
  git push origin HEAD -q 2>&1 && echo -e "${GREEN}✓ Pushed${NC}" || echo -e "${RED}✗ Push failed${NC}"
  ((SUCCESS++))
  cd "$WORKERS_DIR"
done

rm -rf "$TMP_DIR"

echo ""
echo -e "${CYAN}${BOLD}═══ Push Summary ═══${NC}"
echo -e "${GREEN}  ✓ $SUCCESS workers pushed${NC}"
echo -e "${RED}  ✗ $FAILED failed${NC}"
