#!/bin/bash

# BlackRoad OS - Theme System
# Switch between different color themes

# Theme storage
THEME_FILE=~/blackroad-dashboards/.current_theme

# Get current theme
get_theme() {
    if [ -f "$THEME_FILE" ]; then
        cat "$THEME_FILE"
    else
        echo "default"
    fi
}

# Set theme
set_theme() {
    echo "$1" > "$THEME_FILE"
}

# Load theme colors
load_theme() {
    local theme=$(get_theme)

    case "$theme" in
        "neon")
            # Neon theme - bright cyberpunk colors
            export ORANGE="\033[38;2;255;100;0m"
            export PINK="\033[38;2;255;0;255m"
            export PURPLE="\033[38;2;200;0;255m"
            export BLUE="\033[38;2;0;200;255m"
            export CYAN="\033[38;2;0;255;255m"
            export GREEN="\033[38;2;0;255;100m"
            export RED="\033[38;2;255;0;100m"
            export YELLOW="\033[38;2;255;255;0m"
            export GOLD="\033[38;2;255;215;0m"
            export TEXT_PRIMARY="\033[38;2;255;255;255m"
            export TEXT_SECONDARY="\033[38;2;200;200;255m"
            export TEXT_MUTED="\033[38;2;100;100;150m"
            ;;
        "retro")
            # Retro theme - amber/green terminal
            export ORANGE="\033[38;2;255;176;0m"
            export PINK="\033[38;2;255;150;100m"
            export PURPLE="\033[38;2;200;150;100m"
            export BLUE="\033[38;2;100;150;200m"
            export CYAN="\033[38;2;100;200;200m"
            export GREEN="\033[38;2;0;255;0m"
            export RED="\033[38;2;255;100;0m"
            export YELLOW="\033[38;2;255;200;0m"
            export GOLD="\033[38;2;255;176;0m"
            export TEXT_PRIMARY="\033[38;2;255;176;0m"
            export TEXT_SECONDARY="\033[38;2;200;140;0m"
            export TEXT_MUTED="\033[38;2;150;100;0m"
            ;;
        "ocean")
            # Ocean theme - blues and teals
            export ORANGE="\033[38;2;100;200;200m"
            export PINK="\033[38;2;150;100;200m"
            export PURPLE="\033[38;2;100;150;255m"
            export BLUE="\033[38;2;0;150;255m"
            export CYAN="\033[38;2;0;200;255m"
            export GREEN="\033[38;2;0;200;150m"
            export RED="\033[38;2;255;100;150m"
            export YELLOW="\033[38;2;200;200;100m"
            export GOLD="\033[38;2;150;200;255m"
            export TEXT_PRIMARY="\033[38;2;200;230;255m"
            export TEXT_SECONDARY="\033[38;2;150;180;200m"
            export TEXT_MUTED="\033[38;2;80;100;120m"
            ;;
        "forest")
            # Forest theme - greens and earthy tones
            export ORANGE="\033[38;2;200;150;50m"
            export PINK="\033[38;2;150;200;100m"
            export PURPLE="\033[38;2;100;150;100m"
            export BLUE="\033[38;2;100;150;150m"
            export CYAN="\033[38;2;100;200;150m"
            export GREEN="\033[38;2;0;200;100m"
            export RED="\033[38;2;200;100;50m"
            export YELLOW="\033[38;2;200;200;50m"
            export GOLD="\033[38;2;180;180;100m"
            export TEXT_PRIMARY="\033[38;2;200;255;200m"
            export TEXT_SECONDARY="\033[38;2;150;200;150m"
            export TEXT_MUTED="\033[38;2;80;100;80m"
            ;;
        "sunset")
            # Sunset theme - warm oranges and purples
            export ORANGE="\033[38;2;255;150;0m"
            export PINK="\033[38;2;255;100;150m"
            export PURPLE="\033[38;2;200;100;255m"
            export BLUE="\033[38;2;150;100;200m"
            export CYAN="\033[38;2;200;150;255m"
            export GREEN="\033[38;2;255;200;100m"
            export RED="\033[38;2;255;50;50m"
            export YELLOW="\033[38;2;255;200;0m"
            export GOLD="\033[38;2;255;180;50m"
            export TEXT_PRIMARY="\033[38;2;255;230;200m"
            export TEXT_SECONDARY="\033[38;2;255;200;150m"
            export TEXT_MUTED="\033[38;2;150;100;80m"
            ;;
        "monochrome")
            # Monochrome theme - shades of gray
            export ORANGE="\033[38;2;200;200;200m"
            export PINK="\033[38;2;180;180;180m"
            export PURPLE="\033[38;2;160;160;160m"
            export BLUE="\033[38;2;140;140;140m"
            export CYAN="\033[38;2;180;180;180m"
            export GREEN="\033[38;2;200;200;200m"
            export RED="\033[38;2;150;150;150m"
            export YELLOW="\033[38;2;190;190;190m"
            export GOLD="\033[38;2;220;220;220m"
            export TEXT_PRIMARY="\033[38;2;255;255;255m"
            export TEXT_SECONDARY="\033[38;2;180;180;180m"
            export TEXT_MUTED="\033[38;2;100;100;100m"
            ;;
        *)
            # Default BlackRoad theme
            export ORANGE="\033[38;2;247;147;26m"
            export PINK="\033[38;2;233;30;140m"
            export PURPLE="\033[38;2;153;69;255m"
            export BLUE="\033[38;2;20;241;149m"
            export CYAN="\033[38;2;0;212;255m"
            export GREEN="\033[38;2;0;255;100m"
            export RED="\033[38;2;255;50;50m"
            export YELLOW="\033[38;2;255;215;0m"
            export GOLD="\033[38;2;255;215;0m"
            export TEXT_PRIMARY="\033[38;2;255;255;255m"
            export TEXT_SECONDARY="\033[38;2;153;153;253m"
            export TEXT_MUTED="\033[38;2;77;77;77m"
            ;;
    esac

    export RESET="\033[0m"
    export BOLD="\033[1m"
    export DIM="\033[2m"
}

# Theme selector
show_theme_selector() {
    clear
    echo ""
    echo -e "\033[38;2;255;215;0m╔════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[38;2;255;215;0m║\033[0m  🎨 \033[1mTHEME SELECTOR\033[0m                                                        \033[38;2;255;215;0m║\033[0m"
    echo -e "\033[38;2;255;215;0m╚════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""

    local current=$(get_theme)

    echo "  Choose a theme:"
    echo ""
    echo "  1) Default BlackRoad     $([ "$current" = "default" ] && echo "✓" || echo " ")"
    echo "  2) Neon Cyberpunk        $([ "$current" = "neon" ] && echo "✓" || echo " ")"
    echo "  3) Retro Terminal        $([ "$current" = "retro" ] && echo "✓" || echo " ")"
    echo "  4) Ocean Blue            $([ "$current" = "ocean" ] && echo "✓" || echo " ")"
    echo "  5) Forest Green          $([ "$current" = "forest" ] && echo "✓" || echo " ")"
    echo "  6) Sunset Warm           $([ "$current" = "sunset" ] && echo "✓" || echo " ")"
    echo "  7) Monochrome            $([ "$current" = "monochrome" ] && echo "✓" || echo " ")"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -n "Select theme [1-7]: "
    read choice

    case $choice in
        1) set_theme "default" ;;
        2) set_theme "neon" ;;
        3) set_theme "retro" ;;
        4) set_theme "ocean" ;;
        5) set_theme "forest" ;;
        6) set_theme "sunset" ;;
        7) set_theme "monochrome" ;;
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac

    echo ""
    echo "Theme set to: $(get_theme)"
    echo "Restart any dashboard to see the new theme!"
    echo ""
}

# If run directly, show selector
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    show_theme_selector
fi
