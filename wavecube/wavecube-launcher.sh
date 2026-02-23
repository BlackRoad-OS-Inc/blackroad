#!/bin/bash
# wavecube-launcher.sh — Mode switcher for WaveQube DLP projector
#
# Usage: ./wavecube-launcher.sh <mode>
#
# Modes:
#   slideshow  — Rotating image gallery from ~/wavecube/images/
#   waves      — Generative sine wave art (BlackRoad brand colors)
#   audio      — Audio reactive FFT bars (mic or simulated)
#   robot      — Animated robot with emotions and actions
#   logo       — Static logo projection
#   off        — Blank the projector (black screen)
#   menu       — Show this help (default)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_DIR="${SCRIPT_DIR}/images"

# Colors
PINK='\033[38;5;205m'
CYAN='\033[0;36m'
GREEN='\033[38;5;82m'
YELLOW='\033[1;33m'
RESET='\033[0m'

kill_existing() {
    # Kill any running wavecube processes
    pkill -f "wavecube_viz.py" 2>/dev/null || true
    pkill -f "wavecube_audio.py" 2>/dev/null || true
    pkill -f "wavecube_robot.py" 2>/dev/null || true
    pkill -f "fbi.*${IMAGE_DIR}" 2>/dev/null || true
    sleep 0.3
}

case "${1:-menu}" in
    slideshow)
        kill_existing
        echo -e "${GREEN}Starting slideshow mode...${RESET}"
        if command -v fbi &>/dev/null; then
            sudo fbi -T 1 -d /dev/fb0 -noverbose -a -t 10 "${IMAGE_DIR}/"
        else
            echo -e "${YELLOW}fbi not installed. Using pygame fallback...${RESET}"
            python3 "${SCRIPT_DIR}/wavecube_viz.py" "$@"
        fi
        ;;

    waves)
        kill_existing
        echo -e "${PINK}Starting generative waveform mode...${RESET}"
        python3 "${SCRIPT_DIR}/wavecube_viz.py"
        ;;

    audio)
        kill_existing
        echo -e "${CYAN}Starting audio reactive mode...${RESET}"
        python3 "${SCRIPT_DIR}/wavecube_audio.py"
        ;;

    robot)
        kill_existing
        echo -e "${PINK}Starting robot mode...${RESET}"
        python3 "${SCRIPT_DIR}/wavecube_robot.py"
        ;;

    logo)
        kill_existing
        echo -e "${GREEN}Projecting logo...${RESET}"
        if [ -f "${IMAGE_DIR}/blackroad-logo.png" ]; then
            if command -v fbi &>/dev/null; then
                sudo fbi -T 1 -d /dev/fb0 -noverbose "${IMAGE_DIR}/blackroad-logo.png"
            else
                echo -e "${YELLOW}fbi not installed. Place a logo in ${IMAGE_DIR}/blackroad-logo.png${RESET}"
            fi
        else
            echo -e "${YELLOW}Logo not found at ${IMAGE_DIR}/blackroad-logo.png${RESET}"
            echo "Place your logo image there and try again."
        fi
        ;;

    off)
        kill_existing
        echo -e "${CYAN}Blanking projector...${RESET}"
        if [ -e /dev/fb0 ]; then
            sudo dd if=/dev/zero of=/dev/fb0 2>/dev/null
        fi
        echo -e "${GREEN}Projector blanked.${RESET}"
        ;;

    status)
        echo -e "${PINK}WaveQube Status:${RESET}"
        if pgrep -f "wavecube_viz.py" >/dev/null 2>&1; then
            echo -e "  ${GREEN}Running: waves mode${RESET}"
        elif pgrep -f "wavecube_audio.py" >/dev/null 2>&1; then
            echo -e "  ${GREEN}Running: audio mode${RESET}"
        elif pgrep -f "wavecube_robot.py" >/dev/null 2>&1; then
            echo -e "  ${GREEN}Running: robot mode${RESET}"
        elif pgrep -f "fbi" >/dev/null 2>&1; then
            echo -e "  ${GREEN}Running: slideshow/logo mode${RESET}"
        else
            echo -e "  ${YELLOW}Not running${RESET}"
        fi
        ;;

    menu|help|--help|-h|*)
        echo -e "${PINK}"
        echo "  ╔══════════════════════════════════════╗"
        echo "  ║     WaveQube Projector Launcher      ║"
        echo "  ╚══════════════════════════════════════╝"
        echo -e "${RESET}"
        echo "  Usage: $(basename "$0") <mode>"
        echo ""
        echo -e "  ${CYAN}slideshow${RESET}  — Rotating image gallery"
        echo -e "  ${PINK}waves${RESET}      — Generative waveform art"
        echo -e "  ${CYAN}audio${RESET}      — Audio reactive FFT bars"
        echo -e "  ${PINK}robot${RESET}      — Animated robot with emotions"
        echo -e "  ${GREEN}logo${RESET}       — Static logo projection"
        echo -e "  ${YELLOW}off${RESET}        — Blank the projector"
        echo -e "  ${CYAN}status${RESET}     — Check what's running"
        echo ""
        echo "  Tip: Pass --windowed to Python modes for desktop testing"
        echo "  Example: $(basename "$0") robot --windowed"
        ;;
esac
