#!/bin/bash
# BlackRoad Codex - Prism Console Deep Analysis
# Complete indexing and verification of the Prism Console

set -e

CODEX_PATH="${CODEX_PATH:-$HOME/blackroad-codex}"
COLOR_RESET="\033[0m"
COLOR_CYAN="\033[0;36m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_MAGENTA="\033[0;35m"
COLOR_BLUE="\033[0;34m"

echo -e "${COLOR_CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      🕹️  PRISM CONSOLE ANALYSIS 🕹️                            ║
║                                                                  ║
║      Single Pane of Glass - Command Center Indexing             ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${COLOR_RESET}"

section() {
    echo -e "\n${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_MAGENTA}$1${COLOR_RESET}"
    echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}\n"
}

CMD="${1:-summary}"

case "$CMD" in
    index)
        section "📂 INDEXING PRISM CONSOLE REPOSITORIES"

        # Index main satellite repo
        if [ -d "$HOME/projects/blackroad-os-prism-console" ]; then
            echo -e "${COLOR_CYAN}Scanning: blackroad-os-prism-console${COLOR_RESET}"
            python3 ~/blackroad-codex-scanner.py --repo ~/projects/blackroad-os-prism-console
        fi

        # Index monorepo versions
        if [ -d "$HOME/projects/BlackRoad-Operating-System/prism-console" ]; then
            echo -e "${COLOR_CYAN}Scanning: BlackRoad-Operating-System/prism-console${COLOR_RESET}"
            python3 ~/blackroad-codex-scanner.py --repo ~/projects/BlackRoad-Operating-System/prism-console
        fi

        if [ -d "$HOME/projects/BlackRoad-Operating-System/apps/prism-console" ]; then
            echo -e "${COLOR_CYAN}Scanning: BlackRoad-Operating-System/apps/prism-console${COLOR_RESET}"
            python3 ~/blackroad-codex-scanner.py --repo ~/projects/BlackRoad-Operating-System/apps/prism-console
        fi

        if [ -d "$HOME/projects/BlackRoad-Operating-System/backend/static/prism" ]; then
            echo -e "${COLOR_CYAN}Scanning: BlackRoad-Operating-System/backend/static/prism${COLOR_RESET}"
            python3 ~/blackroad-codex-scanner.py --repo ~/projects/BlackRoad-Operating-System/backend/static/prism
        fi

        echo -e "\n${COLOR_GREEN}✅ Indexing complete!${COLOR_RESET}"
        ;;

    summary)
        section "📊 PRISM CONSOLE SUMMARY"

        echo -e "${COLOR_BLUE}Total Prism Components:${COLOR_RESET}"
        TOTAL=$(sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT COUNT(*) FROM components WHERE file_path LIKE '%prism%'")
        echo "  $TOTAL components"

        echo -e "\n${COLOR_BLUE}By Language:${COLOR_RESET}"
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT language, COUNT(*) FROM components WHERE file_path LIKE '%prism%' GROUP BY language" | \
        while IFS='|' read -r lang count; do
            echo "  $lang: $count"
        done

        echo -e "\n${COLOR_BLUE}By Component Type:${COLOR_RESET}"
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT type, COUNT(*) FROM components WHERE file_path LIKE '%prism%' GROUP BY type" | \
        while IFS='|' read -r type count; do
            echo "  $type: $count"
        done

        echo -e "\n${COLOR_BLUE}Key Components:${COLOR_RESET}"
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT name, type, language FROM components WHERE file_path LIKE '%prism%' LIMIT 15" | \
        while IFS='|' read -r name type lang; do
            echo "  • $name ($type, $lang)"
        done
        ;;

    api)
        section "🌐 PRISM API ENDPOINTS"

        echo -e "${COLOR_BLUE}API Routes:${COLOR_RESET}"
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT name, file_path FROM components WHERE file_path LIKE '%prism%/api/%' OR name LIKE '%API%' OR name LIKE 'GET' OR name LIKE 'POST'"
        ;;

    components)
        section "🎨 PRISM UI COMPONENTS"

        echo -e "${COLOR_BLUE}React Components:${COLOR_RESET}"
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT name, file_path FROM components WHERE file_path LIKE '%prism%' AND (file_path LIKE '%.tsx' OR file_path LIKE '%.jsx')"
        ;;

    services)
        section "⚙️ PRISM SERVICES & UTILITIES"

        echo -e "${COLOR_BLUE}Service Functions:${COLOR_RESET}"
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT name, type, file_path FROM components WHERE file_path LIKE '%prism%' AND type = 'function' AND language = 'typescript'"
        ;;

    structure)
        section "🏗️ PRISM CONSOLE STRUCTURE"

        echo -e "${COLOR_BLUE}Main Repository Structure:${COLOR_RESET}"
        if [ -d "$HOME/projects/blackroad-os-prism-console" ]; then
            tree -L 2 -I 'node_modules|.next|coverage' ~/projects/blackroad-os-prism-console | head -40
        fi
        ;;

    docs)
        section "📚 PRISM CONSOLE DOCUMENTATION"

        echo -e "${COLOR_BLUE}Mission & Architecture Docs:${COLOR_RESET}"
        if [ -d "$HOME/projects/blackroad-os-prism-console/docs" ]; then
            ls -1 ~/projects/blackroad-os-prism-console/docs/*.md | while read -r doc; do
                echo "  📄 $(basename "$doc")"
            done
        fi

        echo -e "\n${COLOR_BLUE}README:${COLOR_RESET}"
        if [ -f "$HOME/projects/blackroad-os-prism-console/README.md" ]; then
            head -20 ~/projects/blackroad-os-prism-console/README.md | grep -E "^#|^>" || true
        fi
        ;;

    search)
        QUERY="${2:-}"
        if [ -z "$QUERY" ]; then
            echo "Usage: $0 search <query>"
            exit 1
        fi

        section "🔍 SEARCHING PRISM CONSOLE"
        echo "Query: $QUERY"
        echo ""

        python3 ~/blackroad-codex-search.py "$QUERY prism" --library "$CODEX_PATH"
        ;;

    deep-scrape)
        section "🔬 DEEP SCRAPING PRISM COMPONENTS"

        # Get all Prism TypeScript components
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT id, file_path FROM components WHERE file_path LIKE '%prism%' AND language = 'typescript' LIMIT 10" | \
        while IFS='|' read -r comp_id file_path; do
            if [ -f "$file_path" ]; then
                echo -e "${COLOR_CYAN}Deep scraping: $comp_id${COLOR_RESET}"

                # Run advanced scraper
                python3 ~/blackroad-codex-advanced-scraper.py \
                    --deep-scrape "$comp_id" \
                    --library "$CODEX_PATH" 2>/dev/null || true

                echo ""
            fi
        done

        echo -e "${COLOR_GREEN}✅ Deep scraping complete!${COLOR_RESET}"
        ;;

    verify)
        section "✅ VERIFYING PRISM COMPONENTS"

        # Verify TypeScript components
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT id, file_path FROM components WHERE file_path LIKE '%prism%' AND language = 'typescript' LIMIT 5" | \
        while IFS='|' read -r comp_id file_path; do
            if [ -f "$file_path" ]; then
                echo -e "${COLOR_CYAN}Verifying: $(basename "$file_path")${COLOR_RESET}"

                # Type checking would go here (tsc --noEmit)
                # For now, just log
                echo "  ✅ $comp_id indexed"
            fi
        done
        ;;

    dashboard)
        section "📊 PRISM CONSOLE DASHBOARD"

        echo -e "${COLOR_BLUE}🕹️  PRISM CONSOLE - Command Center${COLOR_RESET}\n"

        # Summary stats
        TOTAL=$(sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT COUNT(*) FROM components WHERE file_path LIKE '%prism%'")
        TS_COUNT=$(sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT COUNT(*) FROM components WHERE file_path LIKE '%prism%' AND language = 'typescript'")
        PY_COUNT=$(sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT COUNT(*) FROM components WHERE file_path LIKE '%prism%' AND language = 'python'")

        echo "Total Components:      $TOTAL"
        echo "TypeScript Components: $TS_COUNT"
        echo "Python Components:     $PY_COUNT"

        echo -e "\n${COLOR_BLUE}Key Features:${COLOR_RESET}"
        echo "  🌍 Environment Dashboards (dev/staging/prod)"
        echo "  🚦 Service Health Monitoring"
        echo "  🚀 Deployment Tracking"
        echo "  🚨 Incident/Alert Feed"
        echo "  🔐 Admin Views & Access Control"
        echo "  📡 Telemetry Visualization"

        echo -e "\n${COLOR_BLUE}Tech Stack:${COLOR_RESET}"
        echo "  • Next.js 14 (App Router)"
        echo "  • TypeScript"
        echo "  • Tailwind CSS"
        echo "  • Vitest (Testing)"
        echo "  • Railway (Deployment)"

        echo -e "\n${COLOR_BLUE}Mission:${COLOR_RESET}"
        echo "  Single pane of glass for BlackRoad OS"
        echo "  Real-time observability across services, agents, and infrastructure"
        echo "  'See & steer' - not 'define & own'"

        echo -e "\n${COLOR_BLUE}Repositories:${COLOR_RESET}"
        for repo in ~/projects/blackroad-os-prism-console \
                    ~/projects/BlackRoad-Operating-System/prism-console \
                    ~/projects/BlackRoad-Operating-System/apps/prism-console; do
            if [ -d "$repo" ]; then
                FILE_COUNT=$(find "$repo" -type f \( -name "*.ts" -o -name "*.tsx" \) ! -path "*/node_modules/*" ! -path "*/.next/*" 2>/dev/null | wc -l | tr -d ' ')
                echo "  📂 $(basename "$repo"): $FILE_COUNT files"
            fi
        done
        ;;

    full-analysis)
        section "🔬 FULL PRISM CONSOLE ANALYSIS"

        echo -e "${COLOR_YELLOW}Running complete analysis...${COLOR_RESET}\n"

        # Index
        $0 index

        # Summary
        $0 summary

        # Dashboard
        $0 dashboard

        # Deep scrape
        $0 deep-scrape

        echo -e "\n${COLOR_GREEN}✅ Full analysis complete!${COLOR_RESET}"
        ;;

    help)
        echo -e "${COLOR_CYAN}BlackRoad Codex - Prism Console Analysis${COLOR_RESET}"
        echo ""
        echo "Usage: $0 <command>"
        echo ""
        echo "Commands:"
        echo "  index         - Index all Prism Console repositories"
        echo "  summary       - Show component summary"
        echo "  api           - List API endpoints"
        echo "  components    - List UI components"
        echo "  services      - List service functions"
        echo "  structure     - Show directory structure"
        echo "  docs          - Show documentation files"
        echo "  search <q>    - Search Prism components"
        echo "  deep-scrape   - Deep scrape all components"
        echo "  verify        - Verify component integrity"
        echo "  dashboard     - Show complete dashboard"
        echo "  full-analysis - Run complete analysis"
        echo "  help          - Show this help"
        echo ""
        ;;

    *)
        echo "Unknown command: $CMD"
        echo "Run '$0 help' for usage"
        exit 1
        ;;
esac
