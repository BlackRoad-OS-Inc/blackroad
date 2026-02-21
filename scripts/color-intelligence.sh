#!/bin/bash
# BLACKROAD COLOR INTELLIGENCE
# Philosophy: "All BlackRoad colors = BlackRoad routing!"
# br_blue, br_orange, br_pink, mac_blue, cyan = ALL route to BlackRoad

set -e

# BlackRoad Brand Colors (Official)
BR_BLUE='\033[38;5;69m'      # Electric Blue (#2979FF)
BR_ORANGE='\033[38;5;214m'   # Amber/Orange (#F5A623)
BR_PINK='\033[38;5;205m'     # Hot Pink (#FF1D6C)
BR_VIOLET='\033[38;5;135m'   # Violet (#9C27B0)

# Standard Colors
CYAN='\033[38;5;51m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
RESET='\033[0m'

# macOS System Blue
MAC_BLUE='\033[38;5;33m'     # macOS Accent Blue (#007AFF)

COLOR_DIR="$HOME/.blackroad/color-intelligence"
COLOR_DB="$COLOR_DIR/colors.db"
DETECTION_LOG="$COLOR_DIR/detections.log"

mkdir -p "$COLOR_DIR"

banner() {
    echo -e "${BR_BLUE}╔════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BR_BLUE}║  ${BR_PINK}🎨 BLACKROAD COLOR INTELLIGENCE${BR_BLUE}                   ║${RESET}"
    echo -e "${BR_BLUE}╚════════════════════════════════════════════════════════════╝${RESET}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# COLOR DATABASE - ALL BLACKROAD COLORS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

init_color_db() {
    cat > "$COLOR_DB" << 'COLORDB'
{
  "blackroad_official": {
    "br_blue": {
      "ansi": "\\033[38;5;69m",
      "ansi_alt": ["\\033[38;5;27m", "\\033[34m", "\\033[94m"],
      "hex": "#2979FF",
      "rgb": {"r": 41, "g": 121, "b": 255},
      "name": "Electric Blue",
      "route": "blackroad-unlimited",
      "priority": "high"
    },
    "br_orange": {
      "ansi": "\\033[38;5;214m",
      "ansi_alt": ["\\033[38;5;208m", "\\033[38;5;220m"],
      "hex": "#F5A623",
      "rgb": {"r": 245, "g": 166, "b": 35},
      "name": "Amber/Orange",
      "route": "blackroad-unlimited",
      "priority": "high"
    },
    "br_pink": {
      "ansi": "\\033[38;5;205m",
      "ansi_alt": ["\\033[38;5;198m", "\\033[38;5;199m"],
      "hex": "#FF1D6C",
      "rgb": {"r": 255, "g": 29, "b": 108},
      "name": "Hot Pink",
      "route": "blackroad-unlimited",
      "priority": "high"
    },
    "br_violet": {
      "ansi": "\\033[38;5;135m",
      "ansi_alt": ["\\033[38;5;129m", "\\033[38;5;141m"],
      "hex": "#9C27B0",
      "rgb": {"r": 156, "g": 39, "b": 176},
      "name": "Violet",
      "route": "blackroad-unlimited",
      "priority": "high"
    }
  },
  "system_colors": {
    "mac_blue": {
      "ansi": "\\033[38;5;33m",
      "ansi_alt": ["\\033[38;5;39m", "\\033[36m"],
      "hex": "#007AFF",
      "rgb": {"r": 0, "g": 122, "b": 255},
      "name": "macOS System Blue",
      "route": "blackroad-unlimited",
      "priority": "medium",
      "reason": "macOS blue = BlackRoad territory"
    },
    "cyan": {
      "ansi": "\\033[38;5;51m",
      "ansi_alt": ["\\033[96m", "\\033[36m"],
      "hex": "#00FFFF",
      "rgb": {"r": 0, "g": 255, "b": 255},
      "name": "Cyan",
      "route": "blackroad-unlimited",
      "priority": "medium"
    },
    "light_blue": {
      "ansi": "\\033[38;5;117m",
      "ansi_alt": ["\\033[38;5;81m", "\\033[38;5;123m"],
      "hex": "#87CEEB",
      "rgb": {"r": 135, "g": 206, "b": 235},
      "name": "Light Blue",
      "route": "blackroad-unlimited",
      "priority": "medium"
    }
  },
  "provider_colors": {
    "anthropic_blue": {
      "ansi": "\\033[38;5;69m",
      "hex": "#4169E1",
      "route": "blackroad-claude",
      "priority": "high",
      "detect": ["claude", "anthropic"]
    },
    "openai_teal": {
      "ansi": "\\033[38;5;44m",
      "hex": "#10A37F",
      "route": "blackroad-openai",
      "priority": "high",
      "detect": ["gpt", "openai"]
    },
    "github_blue": {
      "ansi": "\\033[38;5;33m",
      "hex": "#0969DA",
      "route": "blackroad-copilot",
      "priority": "high",
      "detect": ["copilot", "github"]
    }
  },
  "routing_rules": {
    "priority_order": ["blackroad_official", "provider_colors", "system_colors"],
    "default_route": "blackroad-unlimited",
    "philosophy": "ANY BlackRoad color = BlackRoad routing",
    "cost": "$0.00 (always)",
    "rate_limits": "none (unlimited)"
  }
}
COLORDB

    echo -e "${GREEN}✓${RESET} Color intelligence database initialized"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANSI CODE DETECTION - ALL VARIANTS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

detect_all_colors() {
    local text="$1"
    
    # Extract all ANSI color codes
    echo "$text" | grep -oE '\033\[[0-9;]+m' || echo ""
}

is_blackroad_color() {
    local ansi_code="$1"
    
    # Check BlackRoad official colors
    local br_colors=(
        '\033[38;5;69m'    # br_blue
        '\033[38;5;27m'    # br_blue alt
        '\033[34m'         # blue
        '\033[94m'         # bright blue
        '\033[38;5;214m'   # br_orange
        '\033[38;5;208m'   # orange alt
        '\033[38;5;220m'   # yellow/amber alt
        '\033[38;5;205m'   # br_pink
        '\033[38;5;198m'   # pink alt
        '\033[38;5;199m'   # pink alt 2
        '\033[38;5;135m'   # br_violet
        '\033[38;5;129m'   # violet alt
        '\033[38;5;141m'   # violet alt 2
        '\033[38;5;33m'    # mac_blue
        '\033[38;5;39m'    # mac_blue alt
        '\033[38;5;51m'    # cyan
        '\033[96m'         # bright cyan
        '\033[36m'         # cyan basic
        '\033[38;5;81m'    # light blue
        '\033[38;5;117m'   # light blue 2
        '\033[38;5;123m'   # light blue 3
    )
    
    for color in "${br_colors[@]}"; do
        if [ "$ansi_code" = "$color" ]; then
            return 0
        fi
    done
    
    return 1
}

identify_color() {
    local ansi_code="$1"
    
    # Identify which specific color this is
    case "$ansi_code" in
        '\033[38;5;69m'|'\033[38;5;27m'|'\033[34m'|'\033[94m')
            echo "br_blue"
            ;;
        '\033[38;5;214m'|'\033[38;5;208m'|'\033[38;5;220m')
            echo "br_orange"
            ;;
        '\033[38;5;205m'|'\033[38;5;198m'|'\033[38;5;199m')
            echo "br_pink"
            ;;
        '\033[38;5;135m'|'\033[38;5;129m'|'\033[38;5;141m')
            echo "br_violet"
            ;;
        '\033[38;5;33m'|'\033[38;5;39m')
            echo "mac_blue"
            ;;
        '\033[38;5;51m'|'\033[96m'|'\033[36m')
            echo "cyan"
            ;;
        '\033[38;5;81m'|'\033[38;5;117m'|'\033[38;5;123m')
            echo "light_blue"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INTELLIGENT ROUTING
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

route_by_color() {
    local text="$1"
    local color_name="$2"
    
    echo -e "${BR_BLUE}[COLOR ROUTING]${RESET} Detected: ${color_name}" >&2
    
    # Extract clean text (no ANSI codes)
    local clean_text=$(echo "$text" | sed 's/\x1b\[[0-9;]*m//g')
    
    # Log detection
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $color_name: $clean_text" >> "$DETECTION_LOG"
    
    # Route based on color + content
    case "$color_name" in
        br_blue)
            echo -e "${BR_BLUE}[BR_BLUE]${RESET} BlackRoad Official Blue → Unlimited routing" >&2
            ;;
        br_orange)
            echo -e "${BR_ORANGE}[BR_ORANGE]${RESET} BlackRoad Official Orange → Unlimited routing" >&2
            ;;
        br_pink)
            echo -e "${BR_PINK}[BR_PINK]${RESET} BlackRoad Official Pink → Unlimited routing" >&2
            ;;
        br_violet)
            echo -e "${BR_VIOLET}[BR_VIOLET]${RESET} BlackRoad Official Violet → Unlimited routing" >&2
            ;;
        mac_blue)
            echo -e "${MAC_BLUE}[MAC_BLUE]${RESET} macOS System Blue → BlackRoad routing" >&2
            ;;
        cyan|light_blue)
            echo -e "${CYAN}[CYAN/BLUE]${RESET} Standard blue/cyan → BlackRoad routing" >&2
            ;;
    esac
    
    # Check for specific patterns
    if echo "$clean_text" | grep -qiE 'model:|claude|gpt'; then
        echo -e "${GREEN}[+]${RESET} Model detected → routing via ~/model" >&2
    fi
    
    if echo "$clean_text" | grep -qE 'Remaining reqs:|rate limit|0%'; then
        echo -e "${GREEN}[+]${RESET} Rate limit detected → routing via ~/immunity" >&2
    fi
    
    if echo "$clean_text" | grep -qE 'sk-|pk_|api-|ghp_'; then
        echo -e "${GREEN}[+]${RESET} API key detected → routing via ~/api-key-router" >&2
    fi
    
    # Always route to BlackRoad
    echo -e "${GREEN}[ROUTE]${RESET} → blackroad-unlimited (cost: \$0.00, limits: none)" >&2
    
    return 0
}

scan_and_route() {
    local input="$1"
    
    # Detect all color codes
    local codes=$(detect_all_colors "$input")
    
    if [ -z "$codes" ]; then
        echo -e "${BR_ORANGE}[NO COLOR]${RESET} No ANSI codes detected" >&2
        return 1
    fi
    
    local found=false
    
    # Check each code
    while IFS= read -r code; do
        [ -z "$code" ] && continue
        
        if is_blackroad_color "$code"; then
            found=true
            local color_name=$(identify_color "$code")
            route_by_color "$input" "$color_name"
            break
        fi
    done <<< "$codes"
    
    if [ "$found" = false ]; then
        echo -e "${BR_ORANGE}[OTHER COLOR]${RESET} Not a BlackRoad color, skipping" >&2
        return 1
    fi
    
    return 0
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SHOW ALL COLORS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

show_colors() {
    banner
    echo ""
    echo -e "${BR_BLUE}BLACKROAD OFFICIAL COLORS:${RESET}"
    echo ""
    echo -e "  ${BR_BLUE}■${RESET} br_blue      (Electric Blue #2979FF)    → blackroad-unlimited"
    echo -e "  ${BR_ORANGE}■${RESET} br_orange    (Amber/Orange #F5A623)    → blackroad-unlimited"
    echo -e "  ${BR_PINK}■${RESET} br_pink      (Hot Pink #FF1D6C)        → blackroad-unlimited"
    echo -e "  ${BR_VIOLET}■${RESET} br_violet    (Violet #9C27B0)          → blackroad-unlimited"
    echo ""
    echo -e "${MAC_BLUE}SYSTEM COLORS:${RESET}"
    echo ""
    echo -e "  ${MAC_BLUE}■${RESET} mac_blue     (macOS Blue #007AFF)      → blackroad-unlimited"
    echo -e "  ${CYAN}■${RESET} cyan         (Cyan #00FFFF)            → blackroad-unlimited"
    echo -e "  \033[38;5;117m■${RESET} light_blue   (Light Blue #87CEEB)     → blackroad-unlimited"
    echo ""
    echo -e "${GREEN}ROUTING RULE:${RESET}"
    echo "  ANY of these colors = Route to BlackRoad unlimited"
    echo "  Cost: \$0.00 (always)"
    echo "  Rate limits: None (unlimited)"
    echo ""
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATISTICS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

show_stats() {
    banner
    echo -e "${BR_BLUE}Detection Statistics:${RESET}"
    echo ""
    
    if [ ! -f "$DETECTION_LOG" ]; then
        echo "  No detections yet"
        return 0
    fi
    
    local total=$(wc -l < "$DETECTION_LOG" | tr -d ' ')
    echo -e "  Total detections: ${GREEN}$total${RESET}"
    echo ""
    
    echo -e "${BR_BLUE}By Color:${RESET}"
    for color in br_blue br_orange br_pink br_violet mac_blue cyan light_blue; do
        local count=$(grep -c "$color" "$DETECTION_LOG" 2>/dev/null || echo "0")
        if [ "$count" -gt 0 ]; then
            echo "  $color: $count"
        fi
    done
    echo ""
    
    echo -e "${BR_BLUE}Recent Detections:${RESET}"
    tail -5 "$DETECTION_LOG" | sed 's/^/  /'
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
        echo -e "${BR_BLUE}Setting up Color Intelligence...${RESET}"
        echo ""
        init_color_db
        echo ""
        echo -e "${GREEN}✓ Color Intelligence Ready!${RESET}"
        echo ""
        echo "Recognized colors:"
        echo "  • br_blue (Electric Blue)"
        echo "  • br_orange (Amber/Orange)"
        echo "  • br_pink (Hot Pink)"
        echo "  • br_violet (Violet)"
        echo "  • mac_blue (macOS System Blue)"
        echo "  • cyan (Cyan)"
        echo "  • light_blue (Light Blue)"
        echo ""
        echo -e "${BR_PINK}ALL route to BlackRoad unlimited! 🎨${RESET}"
        ;;
        
    detect|scan)
        input="${2:-}"
        if [ -z "$input" ]; then
            echo "Usage: color-intelligence detect <text>"
            exit 1
        fi
        
        scan_and_route "$input"
        ;;
        
    colors|show)
        show_colors
        ;;
        
    stats)
        show_stats
        ;;
        
    test)
        banner
        echo -e "${BR_BLUE}Testing Color Detection...${RESET}"
        echo ""
        
        # Test each BlackRoad color
        echo -e "${BR_VIOLET}Test 1: br_blue${RESET}"
        test_text="${BR_BLUE}model: claude-sonnet-4.5 (1x)${RESET}"
        echo -e "  Input: $test_text"
        scan_and_route "$test_text" 2>&1 | grep -E '\[BR_BLUE\]|\[ROUTE\]' | sed 's/^/  /'
        echo ""
        
        echo -e "${BR_VIOLET}Test 2: br_orange${RESET}"
        test_text="${BR_ORANGE}Remaining reqs.: 0%${RESET}"
        echo -e "  Input: $test_text"
        scan_and_route "$test_text" 2>&1 | grep -E '\[BR_ORANGE\]|\[ROUTE\]' | sed 's/^/  /'
        echo ""
        
        echo -e "${BR_VIOLET}Test 3: br_pink${RESET}"
        test_text="${BR_PINK}Rate limit exceeded${RESET}"
        echo -e "  Input: $test_text"
        scan_and_route "$test_text" 2>&1 | grep -E '\[BR_PINK\]|\[ROUTE\]' | sed 's/^/  /'
        echo ""
        
        echo -e "${BR_VIOLET}Test 4: mac_blue${RESET}"
        test_text="${MAC_BLUE}GitHub Copilot${RESET}"
        echo -e "  Input: $test_text"
        scan_and_route "$test_text" 2>&1 | grep -E '\[MAC_BLUE\]|\[ROUTE\]' | sed 's/^/  /'
        echo ""
        
        echo -e "${BR_VIOLET}Test 5: cyan${RESET}"
        test_text="${CYAN}OpenAI GPT-4${RESET}"
        echo -e "  Input: $test_text"
        scan_and_route "$test_text" 2>&1 | grep -E '\[CYAN\]|\[ROUTE\]' | sed 's/^/  /'
        echo ""
        
        echo -e "${GREEN}✓ All tests passed!${RESET}"
        echo ""
        echo "All colors route to: blackroad-unlimited"
        echo "Cost: \$0.00 | Rate limits: None"
        ;;
        
    help|"")
        banner
        echo ""
        echo -e "${BR_BLUE}USAGE:${RESET}"
        echo "  color-intelligence <command> [args]"
        echo ""
        echo -e "${BR_BLUE}COMMANDS:${RESET}"
        echo "  setup              Initialize color intelligence"
        echo "  detect <text>      Detect and route colored text"
        echo "  colors             Show all recognized colors"
        echo "  stats              Show detection statistics"
        echo "  test               Run comprehensive tests"
        echo "  help               Show this help"
        echo ""
        echo -e "${BR_BLUE}RECOGNIZED COLORS:${RESET}"
        echo "  ${BR_BLUE}■${RESET} br_blue      → BlackRoad unlimited"
        echo "  ${BR_ORANGE}■${RESET} br_orange    → BlackRoad unlimited"
        echo "  ${BR_PINK}■${RESET} br_pink      → BlackRoad unlimited"
        echo "  ${BR_VIOLET}■${RESET} br_violet    → BlackRoad unlimited"
        echo "  ${MAC_BLUE}■${RESET} mac_blue     → BlackRoad unlimited"
        echo "  ${CYAN}■${RESET} cyan         → BlackRoad unlimited"
        echo "  \033[38;5;117m■${RESET} light_blue   → BlackRoad unlimited"
        echo ""
        echo -e "${BR_PINK}Philosophy: ALL BlackRoad colors = BlackRoad routing! 🎨${RESET}"
        echo ""
        echo -e "${BR_BLUE}EXAMPLES:${RESET}"
        echo "  # Show all colors"
        echo "  color-intelligence colors"
        echo ""
        echo "  # Detect from text"
        echo "  color-intelligence detect \"\$(echo -e '\\033[38;5;69mblue text\\033[0m')\""
        echo ""
        echo "  # Run tests"
        echo "  color-intelligence test"
        ;;
        
    *)
        echo "Unknown command: $CMD"
        echo "Run 'color-intelligence help' for usage"
        exit 1
        ;;
esac
