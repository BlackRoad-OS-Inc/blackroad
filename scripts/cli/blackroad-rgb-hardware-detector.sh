#!/bin/bash
# ============================================================================
# BLACKROAD OS, INC. - PROPRIETARY AND CONFIDENTIAL
# Copyright (c) 2024-2026 BlackRoad OS, Inc. All Rights Reserved.
# 
# This code is the intellectual property of BlackRoad OS, Inc.
# AI-assisted development does not transfer ownership to AI providers.
# Unauthorized use, copying, or distribution is prohibited.
# NOT licensed for AI training or data extraction.
# ============================================================================
# blackroad-rgb-hardware-detector.sh
# Detect RGB LEDs, GPIO, and lighting hardware on Raspberry Pis

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PINK='\033[38;5;205m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${PINK}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║              💡 BLACKROAD RGB HARDWARE DETECTOR 💡                      ║
║                                                                          ║
║          Finding Real Physical Lights & LEDs on Your Cluster            ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

detect_pi_hardware() {
    local name=$1
    local user=$2
    local key=$3
    local ip=$4

    echo -e "\n${BOLD}${YELLOW}━━━ $name ($ip) ━━━${NC}\n"

    # Build SSH command
    if [[ -n "$key" && -f "$HOME/.ssh/$key" ]]; then
        SSH_CMD="ssh -i $HOME/.ssh/$key -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${user}@${ip}"
    else
        SSH_CMD="ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no ${user}@${ip}"
    fi

    # 1. Check Pi model
    echo -e "${PINK}Hardware Info:${NC}"
    $SSH_CMD "cat /proc/device-tree/model 2>/dev/null || echo 'Unknown Pi model'"

    # 2. Check GPIO availability
    echo -e "\n${PINK}GPIO Status:${NC}"
    $SSH_CMD "ls -la /sys/class/gpio/ 2>/dev/null | head -5 || echo 'GPIO not accessible'"

    # 3. Check for GPIO libraries
    echo -e "\n${PINK}GPIO Libraries:${NC}"
    $SSH_CMD "which gpio 2>/dev/null && echo '✓ WiringPi installed' || echo '✗ WiringPi not found'"
    $SSH_CMD "python3 -c 'import RPi.GPIO' 2>/dev/null && echo '✓ RPi.GPIO available' || echo '✗ RPi.GPIO not found'"
    $SSH_CMD "python3 -c 'import gpiod' 2>/dev/null && echo '✓ gpiod available' || echo '✗ gpiod not found'"
    $SSH_CMD "python3 -c 'import lgpio' 2>/dev/null && echo '✓ lgpio available' || echo '✗ lgpio not found'"

    # 4. Check for LED devices
    echo -e "\n${PINK}LED Devices:${NC}"
    $SSH_CMD "ls /sys/class/leds/ 2>/dev/null || echo 'No LED devices found'"

    # 5. Check for I2C (for addressable LEDs)
    echo -e "\n${PINK}I2C Devices:${NC}"
    $SSH_CMD "ls -la /dev/i2c-* 2>/dev/null || echo 'No I2C devices'"

    # 6. Check for SPI (for LED strips)
    echo -e "\n${PINK}SPI Devices:${NC}"
    $SSH_CMD "ls -la /dev/spidev* 2>/dev/null || echo 'No SPI devices'"

    # 7. Check for NeoPixel/WS2812 libraries
    echo -e "\n${PINK}LED Strip Libraries:${NC}"
    $SSH_CMD "python3 -c 'import rpi_ws281x' 2>/dev/null && echo '✓ rpi_ws281x available' || echo '✗ rpi_ws281x not found'"
    $SSH_CMD "python3 -c 'import neopixel' 2>/dev/null && echo '✓ neopixel available' || echo '✗ neopixel not found'"

    # 8. Check for Pironman case (has RGB LEDs!)
    echo -e "\n${PINK}Pironman RGB Case:${NC}"
    $SSH_CMD "ls -la /dev/oled* 2>/dev/null && echo '✓ Pironman OLED detected' || echo '✗ No Pironman hardware'"
    $SSH_CMD "i2cdetect -y 1 2>/dev/null | grep -E '(48|4a)' && echo '✓ RGB controller detected' || echo '✗ No RGB controller'"

    # 9. Test GPIO pin access
    echo -e "\n${PINK}GPIO Pin Test:${NC}"
    $SSH_CMD "cat /sys/kernel/debug/gpio 2>/dev/null | head -10 || echo 'Debug GPIO not accessible (need root?)'"

    # 10. Check user permissions
    echo -e "\n${PINK}User Permissions:${NC}"
    $SSH_CMD "groups | grep -E '(gpio|spi|i2c)' || echo 'User not in GPIO groups'"
    $SSH_CMD "ls -la /dev/gpiomem 2>/dev/null || echo 'gpiomem not accessible'"

    echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Detect all Pis
detect_pi_hardware "Octavia" "pi" "id_octavia" "192.168.4.81"
detect_pi_hardware "Alice" "pi" "" "192.168.4.49"
detect_pi_hardware "Lucidia" "pi" "br_mesh_ed25519" "192.168.4.38"
detect_pi_hardware "Aria" "pi" "br_mesh_ed25519" "192.168.4.82"

echo -e "\n${BOLD}${GREEN}Hardware detection complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Install GPIO libraries if needed"
echo "  2. Add user to gpio group: sudo usermod -a -G gpio pi"
echo "  3. Test LED control"
