#!/bin/bash
# WaveQube DLP Projector — Install Script
#
# Run this on the Raspberry Pi to set up the WaveQube projector software.
# Handles dependencies, DPI config, systemd service, and file deployment.
#
# Usage:
#   ./install.sh              — Full install
#   ./install.sh deps         — Install dependencies only
#   ./install.sh config       — Configure DPI output only
#   ./install.sh service      — Install systemd service only
#   ./install.sh test         — Test that everything works

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/home/pi/wavecube"

# Colors
PINK='\033[38;5;205m'
CYAN='\033[0;36m'
GREEN='\033[38;5;82m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

log()  { echo -e "${GREEN}[+]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err()  { echo -e "${RED}[x]${RESET} $1" >&2; }

header() {
    echo -e "${PINK}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║    WaveQube Projector Installer       ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${RESET}"
}

install_deps() {
    log "Installing system dependencies..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        python3-pip \
        python3-pygame \
        python3-numpy \
        fbi \
        portaudio19-dev \
        python3-pyaudio \
        libsdl2-dev \
        libsdl2-mixer-dev \
        libsdl2-image-dev \
        libsdl2-ttf-dev

    log "Installing Python packages..."
    pip3 install --user --break-system-packages pygame numpy pyaudio 2>/dev/null || \
    pip3 install --user pygame numpy pyaudio 2>/dev/null || \
    pip3 install pygame numpy pyaudio

    log "Dependencies installed."
}

configure_dpi() {
    log "Configuring DPI output for DLP2000..."
    BOOT_CONFIG="/boot/config.txt"
    if [ ! -f "$BOOT_CONFIG" ]; then
        BOOT_CONFIG="/boot/firmware/config.txt"  # Newer Pi OS
    fi

    if [ ! -f "$BOOT_CONFIG" ]; then
        err "Cannot find boot config.txt. Is this a Raspberry Pi?"
        return 1
    fi

    # Check if already configured
    if grep -q "enable_dpi_lcd=1" "$BOOT_CONFIG" 2>/dev/null; then
        warn "DPI already configured in $BOOT_CONFIG"
        echo "  To reconfigure, remove the WaveQube DPI lines and re-run."
        return 0
    fi

    log "Backing up $BOOT_CONFIG..."
    sudo cp "$BOOT_CONFIG" "${BOOT_CONFIG}.wavecube.bak"

    log "Appending DPI configuration..."
    sudo tee -a "$BOOT_CONFIG" > /dev/null << 'DPIEOF'

# --- WaveQube DLP2000 DPI Configuration ---
dtoverlay=dpi18
overscan_left=0
overscan_right=0
overscan_top=0
overscan_bottom=0
framebuffer_width=640
framebuffer_height=360
enable_dpi_lcd=1
display_default_lcd=1
dpi_group=2
dpi_mode=87
dpi_output_format=0x6f016
dpi_timings=640 0 14 4 12 360 0 2 3 9 0 0 0 60 0 32000000 6
gpu_mem=64
# --- End WaveQube Config ---
DPIEOF

    log "DPI configured. Reboot required for changes to take effect."
}

deploy_files() {
    log "Deploying WaveQube files to ${INSTALL_DIR}..."
    mkdir -p "${INSTALL_DIR}/images"
    mkdir -p "${INSTALL_DIR}/config"

    # Copy scripts
    cp "${SCRIPT_DIR}/wavecube_viz.py" "${INSTALL_DIR}/"
    cp "${SCRIPT_DIR}/wavecube_audio.py" "${INSTALL_DIR}/"
    cp "${SCRIPT_DIR}/wavecube_robot.py" "${INSTALL_DIR}/"
    cp "${SCRIPT_DIR}/wavecube-launcher.sh" "${INSTALL_DIR}/"
    cp "${SCRIPT_DIR}/requirements.txt" "${INSTALL_DIR}/"
    cp "${SCRIPT_DIR}/config/boot-config.txt" "${INSTALL_DIR}/config/"

    # Copy images if any exist
    if ls "${SCRIPT_DIR}/images/"* &>/dev/null 2>&1; then
        cp "${SCRIPT_DIR}/images/"* "${INSTALL_DIR}/images/"
    fi

    chmod +x "${INSTALL_DIR}/wavecube-launcher.sh"
    chmod +x "${INSTALL_DIR}/wavecube_viz.py"
    chmod +x "${INSTALL_DIR}/wavecube_audio.py"
    chmod +x "${INSTALL_DIR}/wavecube_robot.py"

    log "Files deployed to ${INSTALL_DIR}"
}

install_service() {
    log "Installing systemd service..."

    sudo cp "${SCRIPT_DIR}/systemd/wavecube.service" /etc/systemd/system/wavecube.service
    sudo systemctl daemon-reload
    sudo systemctl enable wavecube.service

    log "Service installed. Start with: sudo systemctl start wavecube"
    log "Default mode: robot (change ExecStart in /etc/systemd/system/wavecube.service)"
}

run_test() {
    log "Running WaveQube tests..."

    # Check Python
    if python3 -c "import pygame; print(f'  pygame {pygame.ver}')" 2>/dev/null; then
        echo -e "  ${GREEN}pygame: OK${RESET}"
    else
        echo -e "  ${RED}pygame: MISSING${RESET}"
    fi

    if python3 -c "import numpy; print(f'  numpy {numpy.__version__}')" 2>/dev/null; then
        echo -e "  ${GREEN}numpy: OK${RESET}"
    else
        echo -e "  ${RED}numpy: MISSING${RESET}"
    fi

    if python3 -c "import pyaudio; print('  pyaudio OK')" 2>/dev/null; then
        echo -e "  ${GREEN}pyaudio: OK${RESET}"
    else
        echo -e "  ${YELLOW}pyaudio: MISSING (audio mode will use simulation)${RESET}"
    fi

    # Check framebuffer
    if [ -e /dev/fb0 ]; then
        echo -e "  ${GREEN}framebuffer: /dev/fb0 exists${RESET}"
    else
        echo -e "  ${YELLOW}framebuffer: /dev/fb0 not found (normal on desktop)${RESET}"
    fi

    # Check DPI config
    for cfg in /boot/config.txt /boot/firmware/config.txt; do
        if [ -f "$cfg" ] && grep -q "enable_dpi_lcd=1" "$cfg" 2>/dev/null; then
            echo -e "  ${GREEN}DPI config: enabled in $cfg${RESET}"
            break
        fi
    done

    # Check scripts exist
    if [ -f "${INSTALL_DIR}/wavecube_robot.py" ]; then
        echo -e "  ${GREEN}Scripts: deployed to ${INSTALL_DIR}${RESET}"
    elif [ -f "${SCRIPT_DIR}/wavecube_robot.py" ]; then
        echo -e "  ${GREEN}Scripts: found in ${SCRIPT_DIR}${RESET}"
    else
        echo -e "  ${RED}Scripts: not found${RESET}"
    fi

    # Check service
    if systemctl is-enabled wavecube.service &>/dev/null; then
        echo -e "  ${GREEN}Service: enabled${RESET}"
    else
        echo -e "  ${YELLOW}Service: not installed${RESET}"
    fi

    log "Test complete."
}

# --- Main ---
header

case "${1:-full}" in
    deps|dependencies)
        install_deps
        ;;
    config|dpi)
        configure_dpi
        ;;
    deploy|files)
        deploy_files
        ;;
    service|systemd)
        install_service
        ;;
    test|check)
        run_test
        ;;
    full|install|"")
        install_deps
        deploy_files
        configure_dpi
        install_service
        echo ""
        log "Full installation complete!"
        echo ""
        echo -e "  ${CYAN}Next steps:${RESET}"
        echo "  1. Reboot the Pi:  sudo reboot"
        echo "  2. Test manually:  ~/wavecube/wavecube-launcher.sh robot"
        echo "  3. The service auto-starts on boot in robot mode"
        echo ""
        echo -e "  ${PINK}Change default mode:${RESET}"
        echo "  sudo nano /etc/systemd/system/wavecube.service"
        echo "  (change 'robot' to: waves, audio, slideshow)"
        echo ""
        run_test
        ;;
    *)
        echo "Usage: $0 [full|deps|config|deploy|service|test]"
        ;;
esac
