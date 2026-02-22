#!/bin/bash

# BlackRoad OS - 3D Terminal Graphics Engine
# Render 3D objects in ASCII art

source ~/blackroad-dashboards/themes.sh
load_theme

# 3D point rotation
rotate_x() {
    local x=$1 y=$2 z=$3 angle=$4
    local cos=$(echo "c($angle)" | bc -l)
    local sin=$(echo "s($angle)" | bc -l)

    local new_y=$(echo "$y * $cos - $z * $sin" | bc -l)
    local new_z=$(echo "$y * $sin + $z * $cos" | bc -l)

    echo "$x $new_y $new_z"
}

rotate_y() {
    local x=$1 y=$2 z=$3 angle=$4
    local cos=$(echo "c($angle)" | bc -l)
    local sin=$(echo "s($angle)" | bc -l)

    local new_x=$(echo "$x * $cos + $z * $sin" | bc -l)
    local new_z=$(echo "-$x * $sin + $z * $cos" | bc -l)

    echo "$new_x $y $new_z"
}

# Project 3D to 2D
project() {
    local x=$1 y=$2 z=$3
    local distance=5
    local scale=20

    local factor=$(echo "$distance / ($distance + $z)" | bc -l)
    local screen_x=$(echo "$x * $factor * $scale" | bc -l)
    local screen_y=$(echo "$y * $factor * $scale" | bc -l)

    echo "$screen_x $screen_y"
}

# Render rotating cube
render_cube() {
    local angle=$1

    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}🎮${RESET} ${BOLD}3D GRAPHICS ENGINE${RESET}                                                ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ROTATING CUBE ───────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # ASCII art cube (simplified)
    local frame=$((angle % 8))

    case $frame in
        0|1)
            echo "              ${CYAN}+--------+${RESET}"
            echo "             ${CYAN}/|       /|${RESET}"
            echo "            ${CYAN}/ |      / |${RESET}"
            echo "           ${CYAN}+--------+  |${RESET}"
            echo "           ${CYAN}|  +-----|--+${RESET}"
            echo "           ${CYAN}| /      | /${RESET}"
            echo "           ${CYAN}|/       |/${RESET}"
            echo "           ${CYAN}+--------+${RESET}"
            ;;
        2|3)
            echo "              ${ORANGE}+--------+${RESET}"
            echo "             ${ORANGE}/        /|${RESET}"
            echo "            ${ORANGE}/        / |${RESET}"
            echo "           ${ORANGE}+--------+  |${RESET}"
            echo "           ${ORANGE}|        |  +${RESET}"
            echo "           ${ORANGE}|        | /${RESET}"
            echo "           ${ORANGE}|        |/${RESET}"
            echo "           ${ORANGE}+--------+${RESET}"
            ;;
        4|5)
            echo "              ${PINK}+--------+${RESET}"
            echo "             ${PINK}/|       /|${RESET}"
            echo "            ${PINK}+ |      + |${RESET}"
            echo "           ${PINK}/  +----/--+${RESET}"
            echo "          ${PINK}/  /    /  /${RESET}"
            echo "         ${PINK}+--------+ /${RESET}"
            echo "         ${PINK}|        |/${RESET}"
            echo "         ${PINK}+--------+${RESET}"
            ;;
        *)
            echo "              ${PURPLE}+--------+${RESET}"
            echo "             ${PURPLE}/|       /|${RESET}"
            echo "            ${PURPLE}/ |      / |${RESET}"
            echo "           ${PURPLE}+--------+  |${RESET}"
            echo "           ${PURPLE}|  |     |  |${RESET}"
            echo "           ${PURPLE}|  +-----|--+${RESET}"
            echo "           ${PURPLE}| /      | /${RESET}"
            echo "           ${PURPLE}+--------+${RESET}"
            ;;
    esac

    echo ""
    echo -e "${TEXT_MUTED}Angle: ${BOLD}${angle}°${RESET}  ${TEXT_MUTED}Frame: ${BOLD}${frame}/8${RESET}"
    echo ""
}

# Render pyramid
render_pyramid() {
    echo ""
    echo -e "${TEXT_MUTED}╭─ 3D PYRAMID ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                      ${GOLD}*${RESET}"
    echo "                     ${GOLD}/ \\${RESET}"
    echo "                    ${GOLD}/   \\${RESET}"
    echo "                   ${GOLD}/     \\${RESET}"
    echo "                  ${GOLD}/_______\\${RESET}"
    echo "                 ${GOLD}/|       |\\${RESET}"
    echo "                ${GOLD}/ |       | \\${RESET}"
    echo "               ${GOLD}/  |       |  \\${RESET}"
    echo "              ${GOLD}/   |       |   \\${RESET}"
    echo "             ${GOLD}/    +-------+    \\${RESET}"
    echo "            ${GOLD}/___________________\\${RESET}"

    echo ""
}

# Render sphere (ASCII approximation)
render_sphere() {
    echo ""
    echo -e "${TEXT_MUTED}╭─ 3D SPHERE ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    echo "                  ${BLUE},-~~~-.${RESET}"
    echo "                ${BLUE},'       \`.${RESET}"
    echo "               ${BLUE}/           \\${RESET}"
    echo "              ${BLUE}|             |${RESET}"
    echo "              ${BLUE}|             |${RESET}"
    echo "              ${BLUE}|             |${RESET}"
    echo "               ${BLUE}\\           /${RESET}"
    echo "                ${BLUE}\`.       ,'${RESET}"
    echo "                  ${BLUE}\`-,,,-'${RESET}"

    echo ""
}

# Render torus
render_torus() {
    local angle=$1
    local frame=$((angle % 12))

    echo ""
    echo -e "${TEXT_MUTED}╭─ 3D TORUS (Donut) ────────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Simplified spinning donut
    case $((frame / 3)) in
        0)
            echo "              ${PURPLE}___________${RESET}"
            echo "            ${PURPLE}/             \\${RESET}"
            echo "           ${PURPLE}|    _______    |${RESET}"
            echo "           ${PURPLE}|  ,'       \`.  |${RESET}"
            echo "           ${PURPLE}| |           | |${RESET}"
            echo "           ${PURPLE}|  \`.       ,'  |${RESET}"
            echo "           ${PURPLE}|    \`-----'    |${RESET}"
            echo "            ${PURPLE}\\             /${RESET}"
            echo "              ${PURPLE}\`---------'${RESET}"
            ;;
        1)
            echo "              ${PINK}___________${RESET}"
            echo "            ${PINK}/             \\${RESET}"
            echo "          ${PINK}/    _________    \\${RESET}"
            echo "         ${PINK}|   ,'         \`.   |${RESET}"
            echo "         ${PINK}|  |             |  |${RESET}"
            echo "         ${PINK}|   \`.         ,'   |${RESET}"
            echo "          ${PINK}\\    \`-------'    /${RESET}"
            echo "            ${PINK}\\             /${RESET}"
            echo "              ${PINK}\`---------'${RESET}"
            ;;
        *)
            echo "              ${ORANGE}___________${RESET}"
            echo "            ${ORANGE}/             \\${RESET}"
            echo "           ${ORANGE}|   _________   |${RESET}"
            echo "           ${ORANGE}| ,'         \`. |${RESET}"
            echo "           ${ORANGE}||             ||${RESET}"
            echo "           ${ORANGE}| \`.         ,' |${RESET}"
            echo "           ${ORANGE}|   \`-------'   |${RESET}"
            echo "            ${ORANGE}\\             /${RESET}"
            echo "              ${ORANGE}\`---------'${RESET}"
            ;;
    esac

    echo ""
}

# 3D Dashboard with metrics
show_3d_dashboard() {
    local angle=0

    while true; do
        render_cube "$angle"

        # Metrics visualization in 3D style
        echo -e "${TEXT_MUTED}╭─ 3D METRICS VISUALIZATION ────────────────────────────────────────────╮${RESET}"
        echo ""

        # CPU bar in 3D
        echo -e "  ${ORANGE}CPU Usage (42%)${RESET}"
        echo "     ${ORANGE}████████${TEXT_MUTED}░░░░░░░░░░░░${RESET}  ┃"
        echo "    ${ORANGE}████████${TEXT_MUTED}░░░░░░░░░░░░${RESET}   ┃"
        echo "   ${ORANGE}████████${TEXT_MUTED}░░░░░░░░░░░░${RESET}    ┃"
        echo ""

        # Memory sphere
        echo -e "  ${PINK}Memory (5.8 GB)${RESET}"
        echo "        ${PINK}.-~~~-.${RESET}"
        echo "      ${PINK},'  58%  \`.${RESET}"
        echo "     ${PINK}/           \\${RESET}"
        echo "     ${PINK}\`.         ,'${RESET}"
        echo "       ${PINK}\`-,,,-'${RESET}"
        echo ""

        render_pyramid
        render_sphere
        render_torus "$angle"

        echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${TEXT_SECONDARY}[SPACE]${RESET} Pause  ${TEXT_SECONDARY}[+/-]${RESET} Speed  ${TEXT_SECONDARY}[O]${RESET} Objects  ${TEXT_SECONDARY}[Q]${RESET} Quit"
        echo -e "  ${TEXT_MUTED}Rendering at ${BOLD}10 FPS${RESET}"
        echo ""

        read -n1 -t 0.1 key

        case "$key" in
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye!${RESET}\n"
                exit 0
                ;;
            ' ')
                echo -e "\n${YELLOW}Paused. Press any key to continue...${RESET}"
                read -n1
                ;;
        esac

        angle=$((angle + 15))
        [ "$angle" -ge 360 ] && angle=0
    done
}

# Main
main() {
    show_3d_dashboard
}

# Run
main
