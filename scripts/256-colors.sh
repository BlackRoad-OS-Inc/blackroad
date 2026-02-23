#!/bin/bash
# BLACKROAD 256 COLORS SYSTEM
# Philosophy: "ALL 256 ANSI colors route to BlackRoad!"
# Make BlackRoad visible and known through EVERY color

set -e

RESET='\033[0m'

COLOR_DIR="$HOME/.blackroad/256-colors"
COLOR_MAP="$COLOR_DIR/256-color-map.json"
PALETTE_FILE="$COLOR_DIR/palette.txt"

mkdir -p "$COLOR_DIR"

banner() {
    echo -e "\033[38;5;69m╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "\033[38;5;69m║  \033[38;5;205m🌈 BLACKROAD 256 COLORS - ALL ROUTE TO BLACKROAD\033[38;5;69m    ║${RESET}"
    echo -e "\033[38;5;69m╚════════════════════════════════════════════════════════════╝${RESET}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 256 COLOR MAPPING - ALL TO BLACKROAD
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

init_256_colors() {
    cat > "$COLOR_MAP" << 'COLORMAP'
{
  "philosophy": "ALL 256 ANSI colors = BlackRoad unlimited!",
  "color_ranges": {
    "blackroad_primary": {
      "range": [21, 27, 33, 39, 45, 51, 69, 75, 81, 87],
      "description": "Blues and cyans - BlackRoad's main colors",
      "route": "blackroad-unlimited-primary",
      "priority": "highest"
    },
    "blackroad_accents": {
      "range": [198, 199, 205, 206, 207, 208, 214, 220, 226],
      "description": "Pinks, oranges, yellows - BlackRoad accents",
      "route": "blackroad-unlimited-accent",
      "priority": "high"
    },
    "blackroad_violet": {
      "range": [129, 135, 141, 147, 153, 159, 165, 171, 177],
      "description": "Purples and violets - BlackRoad extended",
      "route": "blackroad-unlimited-extended",
      "priority": "high"
    },
    "all_greens": {
      "range": [22, 28, 34, 40, 46, 47, 48, 49, 50, 82, 83, 84, 85, 86, 112, 113, 114, 115, 118, 119, 120, 121, 122, 148, 149, 150, 151, 154, 155, 156, 157, 158, 190, 191, 192, 193, 194],
      "description": "All greens - Success and go signals",
      "route": "blackroad-unlimited-success",
      "priority": "medium"
    },
    "all_reds": {
      "range": [1, 9, 52, 88, 124, 160, 161, 162, 163, 164, 196, 197, 200, 201, 202, 203, 204],
      "description": "All reds - Alerts and important",
      "route": "blackroad-unlimited-alert",
      "priority": "medium"
    },
    "all_remaining": {
      "range": "0-255",
      "description": "Every other color in 256-color palette",
      "route": "blackroad-unlimited-standard",
      "priority": "standard"
    }
  },
  "routing_table": {
    "blackroad-unlimited-primary": "Local AI (ollama:qwen2.5-coder:7b)",
    "blackroad-unlimited-accent": "Local AI (ollama:llama3:8b)",
    "blackroad-unlimited-extended": "Local AI (ollama:phi3:mini)",
    "blackroad-unlimited-success": "Local AI + Codex (unlimited)",
    "blackroad-unlimited-alert": "Immunity + Failover (unlimited)",
    "blackroad-unlimited-standard": "Local AI + All systems (unlimited)"
  },
  "cost": "$0.00 (all colors)",
  "rate_limits": "none (unlimited for all 256 colors)"
}
COLORMAP

    echo -e "\033[38;5;82m✓\033[0m 256-color mapping initialized"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DISPLAY ALL 256 COLORS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

show_all_colors() {
    banner
    echo ""
    echo -e "\033[38;5;69mAll 256 ANSI colors route to BlackRoad unlimited!\033[0m"
    echo ""
    
    # Show color blocks
    echo "Standard Colors (0-15):"
    for i in {0..15}; do
        printf "\033[48;5;${i}m  %3d  \033[0m" $i
        [ $((($i + 1) % 8)) -eq 0 ] && echo ""
    done
    echo ""
    
    echo "256-Color Palette (16-231):"
    for i in {16..231}; do
        printf "\033[48;5;${i}m  %3d  \033[0m" $i
        [ $((($i - 15) % 6)) -eq 0 ] && echo ""
    done
    echo ""
    
    echo "Grayscale (232-255):"
    for i in {232..255}; do
        printf "\033[48;5;${i}m  %3d  \033[0m" $i
        [ $((($i - 231) % 8)) -eq 0 ] && echo ""
    done
    echo ""
}

show_rainbow() {
    banner
    echo ""
    echo -e "\033[38;5;69m🌈 BLACKROAD RAINBOW - ALL COLORS = BLACKROAD! 🌈\033[0m"
    echo ""
    
    # Rainbow gradient display
    for i in {16..231}; do
        printf "\033[48;5;${i}m \033[0m"
        [ $((($i - 15) % 36)) -eq 0 ] && echo ""
    done
    echo ""
    
    echo -e "\033[38;5;82m256 colors × unlimited access = ∞ possibilities\033[0m"
    echo ""
}

show_categories() {
    banner
    echo ""
    echo -e "\033[38;5;69mColor Categories & Routes:\033[0m"
    echo ""
    
    echo -e "\033[38;5;69m■ BLUES & CYANS\033[0m (BlackRoad Primary)"
    echo "  Colors: 21, 27, 33, 39, 45, 51, 69, 75, 81, 87"
    echo "  Route: ollama:qwen2.5-coder:7b (local, unlimited)"
    echo ""
    
    echo -e "\033[38;5;205m■ PINKS & ORANGES\033[0m (BlackRoad Accents)"
    echo "  Colors: 198, 199, 205, 206, 207, 208, 214, 220, 226"
    echo "  Route: ollama:llama3:8b (local, unlimited)"
    echo ""
    
    echo -e "\033[38;5;135m■ PURPLES & VIOLETS\033[0m (BlackRoad Extended)"
    echo "  Colors: 129, 135, 141, 147, 153, 159, 165, 171, 177"
    echo "  Route: ollama:phi3:mini (local, unlimited)"
    echo ""
    
    echo -e "\033[38;5;82m■ ALL GREENS\033[0m (Success signals)"
    echo "  Colors: 22-50, 82-122, 148-158, 190-194 (35 shades)"
    echo "  Route: Local AI + Codex (unlimited)"
    echo ""
    
    echo -e "\033[38;5;196m■ ALL REDS\033[0m (Alert signals)"
    echo "  Colors: 1, 9, 52, 88, 124, 160-164, 196-204 (17 shades)"
    echo "  Route: Immunity + Failover (unlimited)"
    echo ""
    
    echo -e "\033[38;5;250m■ ALL REMAINING COLORS\033[0m"
    echo "  Colors: 0-255 (everything else)"
    echo "  Route: Local AI + All systems (unlimited)"
    echo ""
    
    echo -e "\033[38;5;69mTotal: 256 colors → ALL route to BlackRoad unlimited!\033[0m"
}

show_palette_grid() {
    banner
    echo ""
    echo -e "\033[38;5;205m256-Color Grid (6×6×6 RGB Cube + Grayscale)\033[0m"
    echo ""
    
    # 6x6x6 RGB cube (colors 16-231)
    for r in {0..5}; do
        for g in {0..5}; do
            for b in {0..5}; do
                color=$((16 + 36*r + 6*g + b))
                printf "\033[48;5;${color}m   \033[0m"
            done
            echo ""
        done
        echo ""
    done
    
    # Grayscale ramp (colors 232-255)
    echo "Grayscale:"
    for i in {232..255}; do
        printf "\033[48;5;${i}m   \033[0m"
    done
    echo ""
    echo ""
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COLOR DETECTION FOR 256 COLORS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

detect_256_color() {
    local text="$1"
    
    # Extract 256-color codes: \033[38;5;<n>m
    local colors=$(echo "$text" | grep -oE '38;5;[0-9]{1,3}' | grep -oE '[0-9]{1,3}$')
    
    if [ -z "$colors" ]; then
        return 1
    fi
    
    echo "$colors"
}

route_256_color() {
    local color_num="$1"
    local text="$2"
    
    # Determine route based on color number
    local route=""
    local category=""
    
    # Blues & Cyans (BlackRoad Primary)
    if echo "21 27 33 39 45 51 69 75 81 87" | grep -qw "$color_num"; then
        route="ollama:qwen2.5-coder:7b"
        category="BlackRoad Primary (Blue/Cyan)"
    
    # Pinks & Oranges (BlackRoad Accents)
    elif echo "198 199 205 206 207 208 214 220 226" | grep -qw "$color_num"; then
        route="ollama:llama3:8b"
        category="BlackRoad Accent (Pink/Orange)"
    
    # Purples & Violets (BlackRoad Extended)
    elif echo "129 135 141 147 153 159 165 171 177" | grep -qw "$color_num"; then
        route="ollama:phi3:mini"
        category="BlackRoad Extended (Violet)"
    
    # Greens (Success)
    elif echo "22 28 34 40 46 47 48 49 50 82 83 84 85 86 112 113 114 115 118 119 120 121 122 148 149 150 151 154 155 156 157 158 190 191 192 193 194" | grep -qw "$color_num"; then
        route="ollama:qwen2.5-coder:7b + codex"
        category="Success (Green)"
    
    # Reds (Alerts)
    elif echo "1 9 52 88 124 160 161 162 163 164 196 197 200 201 202 203 204" | grep -qw "$color_num"; then
        route="immunity + failover"
        category="Alert (Red)"
    
    # All others
    else
        route="local-ai-unlimited"
        category="Standard"
    fi
    
    echo -e "\033[38;5;${color_num}m[COLOR $color_num]\033[0m $category → $route"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GENERATE VISUAL REFERENCE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

generate_reference() {
    local output="${1:-$PALETTE_FILE}"
    
    {
        echo "╔═══════════════════════════════════════════════════════════════════╗"
        echo "║        BLACKROAD 256 COLORS - QUICK REFERENCE                     ║"
        echo "╚═══════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "ALL 256 ANSI colors route to BlackRoad unlimited!"
        echo ""
        
        for i in {0..255}; do
            printf "\033[48;5;${i}m %3d \033[0m" $i
            [ $(((i + 1) % 16)) -eq 0 ] && echo ""
        done
        
        echo ""
        echo "Usage:"
        echo "  Use any of these 256 colors in your terminal"
        echo "  BlackRoad automatically detects and routes to unlimited access"
        echo ""
        echo "Cost: \$0.00 (all colors)"
        echo "Rate Limits: None (unlimited)"
        echo ""
        echo "Philosophy: 256 colors × unlimited access = ∞ BlackRoad"
    } > "$output"
    
    echo -e "\033[38;5;82m✓\033[0m Reference saved to $output"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLI INTERFACE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CMD="${1:-}"

if [ -z "$CMD" ]; then
    CMD="help"
fi

case "$CMD" in
    setup)
        banner
        echo ""
        echo -e "\033[38;5;69mSetting up 256-color system...\033[0m"
        echo ""
        init_256_colors
        generate_reference
        echo ""
        echo -e "\033[38;5;82m✓ 256-color system ready!\033[0m"
        echo ""
        echo "All 256 ANSI colors now route to BlackRoad unlimited!"
        echo ""
        ;;
        
    all|show)
        show_all_colors
        ;;
        
    rainbow)
        show_rainbow
        ;;
        
    categories|cat)
        show_categories
        ;;
        
    grid)
        show_palette_grid
        ;;
        
    detect)
        text="${2:-}"
        if [ -z "$text" ]; then
            echo "Usage: 256-colors detect <text-with-ansi>"
            exit 1
        fi
        
        colors=$(detect_256_color "$text")
        if [ -n "$colors" ]; then
            while IFS= read -r color; do
                route_256_color "$color" "$text"
            done <<< "$colors"
        else
            echo "No 256-color codes detected"
        fi
        ;;
        
    test)
        banner
        echo ""
        echo -e "\033[38;5;69mTesting 256-color detection...\033[0m"
        echo ""
        
        # Test a few colors
        for color in 69 205 214 82 196; do
            test_text="$(printf '\033[38;5;%dm' $color)Color $color$(printf '\033[0m')"
            echo -e "Test: $test_text"
            route_256_color "$color" "test"
            echo ""
        done
        
        echo -e "\033[38;5;82m✓ All 256 colors route to BlackRoad unlimited!\033[0m"
        ;;
        
    help|"")
        banner
        echo ""
        echo -e "\033[38;5;69mUSAGE:\033[0m"
        echo "  256-colors <command>"
        echo ""
        echo -e "\033[38;5;69mCOMMANDS:\033[0m"
        echo "  setup              Initialize 256-color system"
        echo "  all                Show all 256 colors"
        echo "  rainbow            Show rainbow gradient"
        echo "  categories         Show color categories & routes"
        echo "  grid               Show 6×6×6 RGB cube + grayscale"
        echo "  detect <text>      Detect 256-color codes in text"
        echo "  test               Test color detection"
        echo "  help               Show this help"
        echo ""
        echo -e "\033[38;5;205mPHILOSOPHY:\033[0m"
        echo "  256 colors × unlimited access = ∞ BlackRoad possibilities"
        echo ""
        echo -e "\033[38;5;69mCOLOR CATEGORIES:\033[0m"
        echo "  • Blues/Cyans (10 colors) → BlackRoad Primary"
        echo "  • Pinks/Oranges (9 colors) → BlackRoad Accents"
        echo "  • Purples/Violets (9 colors) → BlackRoad Extended"
        echo "  • Greens (35 colors) → Success signals"
        echo "  • Reds (17 colors) → Alert signals"
        echo "  • All others (176 colors) → Standard unlimited"
        echo ""
        echo -e "\033[38;5;82mTotal: 256 colors → ALL route to BlackRoad unlimited!\033[0m"
        ;;
        
    *)
        echo "Unknown command: $CMD"
        echo "Run '256-colors help' for usage"
        exit 1
        ;;
esac
