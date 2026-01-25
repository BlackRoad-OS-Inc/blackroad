#!/bin/bash
# BlackRoad Codex - Index All Repositories
# Systematic indexing of the entire BlackRoad ecosystem

set -e

PROJECTS_DIR="$HOME/projects"
CODEX_PATH="${CODEX_PATH:-$HOME/blackroad-codex}"
COLOR_RESET="\033[0m"
COLOR_CYAN="\033[0;36m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_MAGENTA="\033[0;35m"
COLOR_RED="\033[0;31m"

echo -e "${COLOR_CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      📜 BLACKROAD CODEX - UNIVERSAL INDEXER 📜                  ║
║                                                                  ║
║      Indexing the Entire BlackRoad Ecosystem                    ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${COLOR_RESET}"

# Create log file
LOG_FILE="$HOME/blackroad-codex-indexing-$(date +%Y%m%d-%H%M%S).log"
echo "Logging to: $LOG_FILE"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

section() {
    echo -e "\n${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}" | tee -a "$LOG_FILE"
    echo -e "${COLOR_MAGENTA}$1${COLOR_RESET}" | tee -a "$LOG_FILE"
    echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}" | tee -a "$LOG_FILE"
}

clone_and_index() {
    local repo_full="$1"
    local org=$(echo "$repo_full" | cut -d'/' -f1)
    local repo=$(echo "$repo_full" | cut -d'/' -f2)
    local repo_path="$PROJECTS_DIR/$repo"

    log "${COLOR_CYAN}Processing: $repo_full${COLOR_RESET}"

    # Clone if doesn't exist
    if [ ! -d "$repo_path" ]; then
        log "  Cloning..."
        cd "$PROJECTS_DIR"
        if gh repo clone "$repo_full" 2>&1 | tee -a "$LOG_FILE"; then
            log "  ${COLOR_GREEN}✅ Cloned${COLOR_RESET}"
        else
            log "  ${COLOR_RED}❌ Clone failed${COLOR_RESET}"
            return 1
        fi
    else
        log "  ${COLOR_YELLOW}⚠️  Already exists, pulling latest...${COLOR_RESET}"
        cd "$repo_path"
        git pull 2>&1 | tee -a "$LOG_FILE" || true
    fi

    # Index
    if [ -d "$repo_path" ]; then
        log "  Indexing..."
        local result=$(python3 ~/blackroad-codex-scanner.py --repo "$repo_path" 2>&1)
        echo "$result" >> "$LOG_FILE"

        local count=$(echo "$result" | grep -o "Saved [0-9]* components" | grep -o "[0-9]*" || echo "0")
        if [ "$count" -gt 0 ]; then
            log "  ${COLOR_GREEN}✅ Indexed $count components${COLOR_RESET}"
            return 0
        else
            log "  ${COLOR_YELLOW}⚠️  No components found${COLOR_RESET}"
            return 0
        fi
    else
        log "  ${COLOR_RED}❌ Directory not found${COLOR_RESET}"
        return 1
    fi
}

# BlackRoad-OS repositories
BLACKROAD_OS_REPOS=(
    "BlackRoad-OS/blackroad-os-core"
    "BlackRoad-OS/blackroad-os-api"
    "BlackRoad-OS/blackroad-os-operator"
    "BlackRoad-OS/blackroad-os-agents"
    "BlackRoad-OS/blackroad-os-prism-console"
    "BlackRoad-OS/blackroad-os-web"
    "BlackRoad-OS/blackroad-os-docs"
    "BlackRoad-OS/blackroad-os-infra"
    "BlackRoad-OS/blackroad-os-api-gateway"
    "BlackRoad-OS/blackroad-os-pack-research-lab"
    "BlackRoad-OS/blackroad-os-pack-creator-studio"
    "BlackRoad-OS/blackroad-os-pack-finance"
    "BlackRoad-OS/blackroad-os-pack-legal"
    "BlackRoad-OS/blackroad-os-pack-education"
    "BlackRoad-OS/blackroad-os-pack-infra-devops"
    "BlackRoad-OS/blackroad-os-archive"
    "BlackRoad-OS/blackroad-os-brand"
    "BlackRoad-OS/blackroad-os-beacon"
    "BlackRoad-OS/blackroad-os-demo"
    "BlackRoad-OS/blackroad-os-helper"
    "BlackRoad-OS/blackroad-os-home"
    "BlackRoad-OS/blackroad-os-ideas"
    "BlackRoad-OS/blackroad-os-master"
    "BlackRoad-OS/blackroad-os-mesh"
    "BlackRoad-OS/blackroad-os-research"
    "BlackRoad-OS/lucidia-core"
    "BlackRoad-OS/lucidia-earth"
    "BlackRoad-OS/lucidia-earth-website"
    "BlackRoad-OS/lucidia-math"
    "BlackRoad-OS/lucidia-metaverse"
    "BlackRoad-OS/lucidia-platform"
    "BlackRoad-OS/earth-metaverse"
    "BlackRoad-OS/blackroad-pi-holo"
    "BlackRoad-OS/blackroad-pi-ops"
    "BlackRoad-OS/blackroad-tools"
    "BlackRoad-OS/blackroad-cli"
    "BlackRoad-OS/blackroad-cli-tools"
    "BlackRoad-OS/blackroad-models"
    "BlackRoad-OS/blackroad-domains"
    "BlackRoad-OS/blackroad-deployment-docs"
    "BlackRoad-OS/app-blackroad-io"
    "BlackRoad-OS/blackroad-io-app"
    "BlackRoad-OS/blackroadinc-us"
    "BlackRoad-OS/demo-blackroad-io"
)

# blackboxprogramming repositories (key ones)
BLACKBOX_REPOS=(
    "blackboxprogramming/BlackRoad-Operating-System"
    "blackboxprogramming/blackroad-simple-launch"
    "blackboxprogramming/lucidia"
    "blackboxprogramming/lucidia-lab"
    "blackboxprogramming/quantum-math-lab"
    "blackboxprogramming/codex-infinity"
    "blackboxprogramming/codex-agent-runner"
    "blackboxprogramming/blackroad-operator"
    "blackboxprogramming/blackroad-api"
    "blackboxprogramming/blackroad-metaverse"
    "blackboxprogramming/native-ai-quantum-energy"
    "blackboxprogramming/universal-computer"
)

# Statistics
TOTAL_REPOS=$((${#BLACKROAD_OS_REPOS[@]} + ${#BLACKBOX_REPOS[@]}))
SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_COMPONENTS=0

section "📊 INDEXING BLACKROAD-OS ORGANIZATION (${#BLACKROAD_OS_REPOS[@]} repos)"

for repo in "${BLACKROAD_OS_REPOS[@]}"; do
    if clone_and_index "$repo"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
    echo "" | tee -a "$LOG_FILE"
done

section "📊 INDEXING BLACKBOXPROGRAMMING ORGANIZATION (${#BLACKBOX_REPOS[@]} repos)"

for repo in "${BLACKBOX_REPOS[@]}"; do
    if clone_and_index "$repo"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
    echo "" | tee -a "$LOG_FILE"
done

section "📊 FINAL STATISTICS"

# Get total components from database
TOTAL_COMPONENTS=$(sqlite3 "$CODEX_PATH/index/components.db" "SELECT COUNT(*) FROM components" 2>/dev/null || echo "0")

log ""
log "${COLOR_GREEN}✅ Successfully indexed: $SUCCESS_COUNT repos${COLOR_RESET}"
log "${COLOR_RED}❌ Failed: $FAIL_COUNT repos${COLOR_RESET}"
log "${COLOR_CYAN}📦 Total components in Codex: $TOTAL_COMPONENTS${COLOR_RESET}"
log ""
log "Log file: $LOG_FILE"

# Generate summary
section "📊 COMPONENT BREAKDOWN"

log ""
log "Components by language:"
sqlite3 "$CODEX_PATH/index/components.db" "
  SELECT language, COUNT(*) as count
  FROM components
  GROUP BY language
  ORDER BY count DESC
  LIMIT 15
" | while IFS='|' read -r lang count; do
    log "  $lang: $count"
done

log ""
log "Components by repository (top 20):"
sqlite3 "$CODEX_PATH/index/components.db" "
  SELECT
    SUBSTR(file_path, 1, INSTR(SUBSTR(file_path, LENGTH('$PROJECTS_DIR/') + 1), '/') + LENGTH('$PROJECTS_DIR/')) as repo,
    COUNT(*) as count
  FROM components
  GROUP BY repo
  ORDER BY count DESC
  LIMIT 20
" 2>/dev/null | while IFS='|' read -r repo count; do
    local repo_name=$(basename "$repo" 2>/dev/null || echo "$repo")
    log "  $repo_name: $count"
done

section "✅ INDEXING COMPLETE"

log ""
log "${COLOR_GREEN}The BlackRoad Codex now contains the complete ecosystem!${COLOR_RESET}"
log ""
log "Next steps:"
log "  1. Search the Codex: python3 ~/blackroad-codex-search.py \"your query\""
log "  2. View dashboard: ~/blackroad-codex-scraping-dashboard.py"
log "  3. Deep scrape: ~/blackroad-codex-advanced-scraper.py --scrape-all --limit 100"
log "  4. Verify: ~/blackroad-codex-verification-suite.sh summary"
log ""
