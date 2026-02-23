#!/usr/bin/env bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# Fixed br-container with proper escape handling

# Colors using printf instead of echo -e
c_pink() { printf '\033[38;5;205m'; }
c_blue() { printf '\033[38;5;75m'; }
c_purple() { printf '\033[38;5;141m'; }
c_orange() { printf '\033[38;5;208m'; }
c_gray() { printf '\033[38;5;240m'; }
c_white() { printf '\033[38;5;255m'; }
c_reset() { printf '\033[0m'; }
c_clear() { printf '\033[2J\033[H'; }

# Box drawing
TL='╔'
TR='╗'
BL='╚'
BR='╝'
H='═'
V='║'
CROSS='╬'
T_DOWN='╦'
T_UP='╩'
T_RIGHT='╠'
T_LEFT='╣'

grid_layout() {
    local rows="${1:-2}"
    local cols="${2:-2}"
    local width="${3:-80}"
    local height="${4:-24}"
    
    local cell_width=$((width / cols))
    local cell_height=$((height / rows))
    
    c_clear
    c_pink; printf "Grid Layout: ${rows}×${cols}\n\n"; c_reset
    
    # Draw grid
    for ((r=0; r<rows; r++)); do
        # Top border
        if [[ $r -eq 0 ]]; then
            c_purple
            printf "${TL}"
            for ((c=0; c<cols; c++)); do
                printf '%*s' $((cell_width-1)) '' | tr ' ' "${H}"
                [[ $c -lt $((cols-1)) ]] && printf "${T_DOWN}"
            done
            printf "${TR}\n"
            c_reset
        else
            c_purple
            printf "${T_RIGHT}"
            for ((c=0; c<cols; c++)); do
                printf '%*s' $((cell_width-1)) '' | tr ' ' "${H}"
                [[ $c -lt $((cols-1)) ]] && printf "${CROSS}"
            done
            printf "${T_LEFT}\n"
            c_reset
        fi
        
        # Cell content
        for ((line=0; line<cell_height-1; line++)); do
            for ((c=0; c<cols; c++)); do
                c_purple; printf "${V}"; c_reset
                printf '%*s' $((cell_width-1)) ''
            done
            c_purple; printf "${V}\n"; c_reset
        done
    done
    
    # Bottom border
    c_purple
    printf "${BL}"
    for ((c=0; c<cols; c++)); do
        printf '%*s' $((cell_width-1)) '' | tr ' ' "${H}"
        [[ $c -lt $((cols-1)) ]] && printf "${T_UP}"
    done
    printf "${BR}\n"
    c_reset
}

split_horizontal() {
    local width="${1:-80}"
    local height="${2:-24}"
    local half_height=$((height / 2))
    
    c_clear
    
    # Top pane
    c_purple; printf "${TL}"; c_reset
    printf '%*s' $((width-2)) '' | tr ' ' "${H}"
    c_purple; printf "${TR}\n"; c_reset
    
    c_purple; printf "${V}"; c_reset
    c_blue; printf " Top Pane"; c_reset
    printf '%*s' $((width - 12)) ''
    c_purple; printf "${V}\n"; c_reset
    
    for ((i=0; i<half_height-3; i++)); do
        c_purple; printf "${V}"; c_reset
        printf '%*s' $((width-2)) ''
        c_purple; printf "${V}\n"; c_reset
    done
    
    # Middle
    c_purple; printf "${T_RIGHT}"; c_reset
    printf '%*s' $((width-2)) '' | tr ' ' "${H}"
    c_purple; printf "${T_LEFT}\n"; c_reset
    
    # Bottom pane
    c_purple; printf "${V}"; c_reset
    c_orange; printf " Bottom Pane"; c_reset
    printf '%*s' $((width - 15)) ''
    c_purple; printf "${V}\n"; c_reset
    
    for ((i=0; i<half_height-3; i++)); do
        c_purple; printf "${V}"; c_reset
        printf '%*s' $((width-2)) ''
        c_purple; printf "${V}\n"; c_reset
    done
    
    # Bottom border
    c_purple; printf "${BL}"; c_reset
    printf '%*s' $((width-2)) '' | tr ' ' "${H}"
    c_purple; printf "${BR}\n"; c_reset
}

dashboard() {
    local width="${1:-120}"
    local height="${2:-40}"
    
    c_clear
    
    # Header
    c_purple; printf "${TL}"; c_reset
    printf '%*s' $((width-2)) '' | tr ' ' "${H}"
    c_purple; printf "${TR}\n"; c_reset
    
    c_purple; printf "${V}"; c_reset
    c_pink; printf " BlackRoad OS Dashboard"; c_reset
    printf '%*s' $((width - 25)) ''
    c_purple; printf "${V}\n"; c_reset
    
    c_purple; printf "${T_RIGHT}"; c_reset
    printf '%*s' $((width-2)) '' | tr ' ' "${H}"
    c_purple; printf "${T_LEFT}\n"; c_reset
    
    # 3 columns
    local col1_width=$((width / 3))
    local col2_width=$((width / 3))
    local col3_width=$((width - col1_width - col2_width))
    
    for ((row=0; row<height-4; row++)); do
        c_purple; printf "${V}"; c_reset
        if [[ $row -eq 0 ]]; then
            c_blue; printf " Status"; c_reset
            printf '%*s' $((col1_width - 9)) ''
        else
            printf '%*s' $((col1_width - 2)) ''
        fi
        
        c_purple; printf "${V}"; c_reset
        if [[ $row -eq 0 ]]; then
            c_orange; printf " Metrics"; c_reset
            printf '%*s' $((col2_width - 10)) ''
        else
            printf '%*s' $((col2_width - 2)) ''
        fi
        
        c_purple; printf "${V}"; c_reset
        if [[ $row -eq 0 ]]; then
            c_white; printf " Logs"; c_reset
            printf '%*s' $((col3_width - 7)) ''
        else
            printf '%*s' $((col3_width - 2)) ''
        fi
        
        c_purple; printf "${V}\n"; c_reset
    done
    
    # Footer
    c_purple; printf "${BL}"; c_reset
    printf '%*s' $((width-2)) '' | tr ' ' "${H}"
    c_purple; printf "${BR}\n"; c_reset
}

case "${1:-help}" in
    grid)
        grid_layout "${2:-2}" "${3:-2}" "${4:-80}" "${5:-24}"
        ;;
    hsplit|horizontal)
        split_horizontal "${2:-80}" "${3:-24}"
        ;;
    dashboard)
        dashboard "${2:-120}" "${3:-40}"
        ;;
    test)
        printf "Testing colors:\n"
        c_pink; printf "Pink "; c_reset
        c_blue; printf "Blue "; c_reset
        c_purple; printf "Purple "; c_reset
        c_orange; printf "Orange\n"; c_reset
        ;;
    *)
        c_pink; printf "BlackRoad Container System (Fixed)\n\n"; c_reset
        printf "Usage:\n"
        c_blue; printf "  grid"; c_reset; printf " [rows] [cols] [width] [height]\n"
        c_blue; printf "  hsplit"; c_reset; printf " [width] [height]\n"
        c_blue; printf "  dashboard"; c_reset; printf " [width] [height]\n"
        c_blue; printf "  test"; c_reset; printf " - Test escape codes\n"
        ;;
esac
