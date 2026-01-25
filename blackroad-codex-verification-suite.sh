#!/bin/bash
# BlackRoad Codex - Verification & Calculation Suite
# Complete mechanical verification and symbolic computation framework

set -e

CODEX_PATH="${CODEX_PATH:-$HOME/blackroad-codex}"
COLOR_RESET="\033[0m"
COLOR_CYAN="\033[0;36m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_MAGENTA="\033[0;35m"

echo -e "${COLOR_CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║      📐 BLACKROAD CODEX VERIFICATION SUITE 📐                   ║
║                                                                  ║
║      Mechanical Calculation & Formal Verification                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${COLOR_RESET}"

# Function to print section headers
section() {
    echo -e "\n${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_MAGENTA}$1${COLOR_RESET}"
    echo -e "${COLOR_MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}\n"
}

# Parse arguments
CMD="${1:-help}"
COMPONENT_ID="${2:-}"
FILE_PATH="${3:-}"

case "$CMD" in
    verify)
        if [ -z "$COMPONENT_ID" ] || [ -z "$FILE_PATH" ]; then
            echo "Usage: $0 verify <component_id> <file_path>"
            exit 1
        fi

        section "🔍 VERIFICATION ANALYSIS"
        echo "Component: $COMPONENT_ID"
        echo "File: $FILE_PATH"
        echo ""

        # Run verification framework
        python3 ~/blackroad-codex-verification.py \
            --codex "$CODEX_PATH" \
            --analyze "$COMPONENT_ID" \
            --file "$FILE_PATH"

        echo ""
        section "🔬 SYMBOLIC COMPUTATION"

        # Run symbolic analysis
        python3 ~/blackroad-codex-symbolic.py \
            --codex "$CODEX_PATH" \
            --analyze "$COMPONENT_ID" \
            --file "$FILE_PATH"

        echo -e "\n${COLOR_GREEN}✅ Verification complete!${COLOR_RESET}"
        ;;

    summary)
        section "📊 VERIFICATION SUMMARY"
        python3 ~/blackroad-codex-verification.py \
            --codex "$CODEX_PATH" \
            --summary

        echo ""
        section "🔬 SYMBOLIC SUMMARY"
        python3 ~/blackroad-codex-symbolic.py \
            --codex "$CODEX_PATH" \
            --summary
        ;;

    identities)
        section "📐 MATHEMATICAL IDENTITIES"
        python3 ~/blackroad-codex-symbolic.py \
            --codex "$CODEX_PATH" \
            --identities
        ;;

    dashboard)
        section "📊 SCRAPING DASHBOARD"
        python3 ~/blackroad-codex-scraping-dashboard.py \
            --codex "$CODEX_PATH"

        echo ""
        section "📊 VERIFICATION SUMMARY"
        python3 ~/blackroad-codex-verification.py \
            --codex "$CODEX_PATH" \
            --summary

        echo ""
        section "🔬 SYMBOLIC SUMMARY"
        python3 ~/blackroad-codex-symbolic.py \
            --codex "$CODEX_PATH" \
            --summary
        ;;

    analyze-all-math)
        section "🔬 ANALYZING ALL MATHEMATICAL COMPONENTS"

        # Get all components from math directories
        sqlite3 "$CODEX_PATH/index/components.db" \
            "SELECT id, file_path FROM components WHERE file_path LIKE '%/math/%' LIMIT 20" | \
        while IFS='|' read -r comp_id file_path; do
            if [ -f "$file_path" ]; then
                echo -e "${COLOR_CYAN}Analyzing: $comp_id${COLOR_RESET}"

                # Verification
                python3 ~/blackroad-codex-verification.py \
                    --codex "$CODEX_PATH" \
                    --analyze "$comp_id" \
                    --file "$file_path" 2>/dev/null || true

                # Symbolic
                python3 ~/blackroad-codex-symbolic.py \
                    --codex "$CODEX_PATH" \
                    --analyze "$comp_id" \
                    --file "$file_path" 2>/dev/null || true

                echo ""
            fi
        done

        echo -e "${COLOR_GREEN}✅ Analysis complete!${COLOR_RESET}"
        ;;

    test)
        section "🧪 TESTING VERIFICATION FRAMEWORK"

        # Test with hyper_equation
        MATH_FILE="$HOME/projects/BlackRoad-Operating-System/packs/research-lab/math/lucidia_math_forge/dimensions.py"

        if [ -f "$MATH_FILE" ]; then
            echo "Testing with: dimensions.py"
            echo ""

            python3 ~/blackroad-codex-verification.py \
                --codex "$CODEX_PATH" \
                --analyze "test_component" \
                --file "$MATH_FILE"

            echo ""

            python3 ~/blackroad-codex-symbolic.py \
                --codex "$CODEX_PATH" \
                --analyze "test_component" \
                --file "$MATH_FILE"

            echo -e "\n${COLOR_GREEN}✅ Test complete!${COLOR_RESET}"
        else
            echo "Test file not found: $MATH_FILE"
        fi
        ;;

    help)
        echo -e "${COLOR_CYAN}BlackRoad Codex Verification Suite${COLOR_RESET}"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  verify <component_id> <file>  - Verify a specific component"
        echo "  summary                        - Show verification summary"
        echo "  identities                     - List mathematical identities"
        echo "  dashboard                      - Show complete dashboard"
        echo "  analyze-all-math               - Analyze all math components"
        echo "  test                           - Test framework with sample file"
        echo "  help                           - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 verify bd1a64466d166910 ~/projects/my-project/math.py"
        echo "  $0 summary"
        echo "  $0 dashboard"
        echo "  $0 analyze-all-math"
        echo ""
        ;;

    *)
        echo "Unknown command: $CMD"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
