#!/bin/bash

# BlackRoad OS - Dashboard Launcher
# Quick access to all 28 terminal dashboards!

ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GOLD="\033[38;2;255;215;0m"
GREEN="\033[38;2;0;255;100m"
RED="\033[38;2;255;50;50m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;253m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

clear
echo ""
echo -e "${BOLD}${GOLD}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GOLD}║${RESET}  ${GOLD}⚡${RESET} ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D ${ORANGE}D${PINK}A${PURPLE}S${BLUE}H${CYAN}B${ORANGE}O${PINK}A${PURPLE}R${BLUE}D${CYAN}S${RESET} ${GOLD}⚡${RESET}                                 ${BOLD}${GOLD}║${RESET}"
echo -e "${BOLD}${GOLD}║${RESET}     ${TEXT_SECONDARY}28 Terminal Dashboards • Choose Your View${RESET}                      ${BOLD}${GOLD}║${RESET}"
echo -e "${BOLD}${GOLD}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

echo -e "${TEXT_MUTED}╭─ 🆕 SPECIALIZED DASHBOARDS (11) ──────────────────────────────────────╮${RESET}"
echo ""
echo -e "  ${GOLD}1)${RESET}  ${BOLD}Master Control${RESET} ${GOLD}⚡${RESET}          ${TEXT_MUTED}ALL systems unified • Interactive${RESET}"
echo -e "  ${PURPLE}2)${RESET}  ${BOLD}Cosmic Lottery${RESET} ${PURPLE}∞${RESET}          ${TEXT_MUTED}Quantum probability engine${RESET}"
echo -e "  ${ORANGE}3)${RESET}  ${BOLD}Pi Fleet${RESET} ${ORANGE}🥧${RESET}               ${TEXT_MUTED}4 Raspberry Pi devices${RESET}"
echo -e "  ${CYAN}4)${RESET}  ${BOLD}Cloudflare${RESET} ${CYAN}☁️${RESET}              ${TEXT_MUTED}16 zones • 8 Pages • 8 KV • 1 D1${RESET}"
echo -e "  ${PINK}5)${RESET}  ${BOLD}GitHub${RESET} ${PINK}🐙${RESET}                  ${TEXT_MUTED}15 orgs • 66 repos${RESET}"
echo -e "  ${BLUE}6)${RESET}  ${BOLD}Railway${RESET} ${BLUE}🚂${RESET}                 ${TEXT_MUTED}12+ deployments${RESET}"
echo -e "  ${GREEN}7)${RESET}  ${BOLD}Crypto Portfolio${RESET} ${GOLD}₿Ξ◎${RESET}      ${TEXT_MUTED}Live BTC/ETH/SOL tracking${RESET}"
echo -e "  ${PURPLE}8)${RESET}  ${BOLD}Memory System${RESET} ${PURPLE}∞${RESET}          ${TEXT_MUTED}PS-SHA∞ hash chains${RESET}"
echo -e "  ${CYAN}9)${RESET}  ${BOLD}Agent Network${RESET} ${CYAN}🤖${RESET}          ${TEXT_MUTED}104 AI agents map${RESET}"
echo -e "  ${ORANGE}10)${RESET} ${BOLD}Services/Ports${RESET} ${ORANGE}🔌${RESET}        ${TEXT_MUTED}47 endpoints & ports${RESET}"
echo -e "  ${PINK}11)${RESET} ${BOLD}System Metrics${RESET} ${PINK}📊${RESET}         ${TEXT_MUTED}Real-time performance${RESET}"
echo ""

echo -e "${TEXT_MUTED}╭─ 🔥 INFRASTRUCTURE DASHBOARDS (11) ───────────────────────────────────╮${RESET}"
echo ""
echo -e "  ${PURPLE}12)${RESET} ${BOLD}Network Topology${RESET} ${PURPLE}🌐${RESET}      ${TEXT_MUTED}3D network visualization${RESET}"
echo -e "  ${ORANGE}13)${RESET} ${BOLD}Deployment Timeline${RESET} ${ORANGE}📅${RESET}   ${TEXT_MUTED}Gantt chart • 847 deploys${RESET}"
echo -e "  ${CYAN}14)${RESET} ${BOLD}Database Monitor${RESET} ${CYAN}💾${RESET}       ${TEXT_MUTED}D1 + KV stores • 8.2GB${RESET}"
echo -e "  ${GREEN}15)${RESET} ${BOLD}API Health${RESET} ${GREEN}🔌${RESET}             ${TEXT_MUTED}47 endpoints • 99.9% uptime${RESET}"
echo -e "  ${BLUE}16)${RESET} ${BOLD}Docker Fleet${RESET} ${BLUE}🐳${RESET}           ${TEXT_MUTED}24 containers • 4 devices${RESET}"
echo -e "  ${GREEN}17)${RESET} ${BOLD}SSL Certificates${RESET} ${GREEN}🔒${RESET}      ${TEXT_MUTED}16 certs • Auto-renew${RESET}"
echo -e "  ${PURPLE}18)${RESET} ${BOLD}DNS Records${RESET} ${PURPLE}🌐${RESET}          ${TEXT_MUTED}247 records • 16 zones${RESET}"
echo -e "  ${CYAN}19)${RESET} ${BOLD}Log Aggregator${RESET} ${CYAN}📋${RESET}        ${TEXT_MUTED}18K logs/hr • Multi-device${RESET}"
echo -e "  ${GREEN}20)${RESET} ${BOLD}Backup Status${RESET} ${GREEN}💾${RESET}         ${TEXT_MUTED}847GB • 24 backup sets${RESET}"
echo -e "  ${RED}21)${RESET} ${BOLD}Security${RESET} ${RED}🔐${RESET}                ${TEXT_MUTED}Threats • Vulns • Score: 98${RESET}"
echo -e "  ${PURPLE}22)${RESET} ${BOLD}Build Pipeline${RESET} ${PURPLE}⚙️${RESET}        ${TEXT_MUTED}CI/CD • 98.7% success${RESET}"
echo ""

echo -e "${TEXT_MUTED}╭─ CLASSIC DASHBOARDS (6) ──────────────────────────────────────────────╮${RESET}"
echo ""
echo -e "  ${ORANGE}23)${RESET} ${BOLD}Basic Dashboard${RESET}            ${TEXT_MUTED}Simple, clean view${RESET}"
echo -e "  ${PINK}24)${RESET} ${BOLD}Live Monitor${RESET}               ${TEXT_MUTED}Comprehensive real-time${RESET}"
echo -e "  ${PURPLE}25)${RESET} ${BOLD}Full System${RESET}                ${TEXT_MUTED}Enhanced with progress bars${RESET}"
echo -e "  ${CYAN}26)${RESET} ${BOLD}ULTIMATE${RESET}                   ${TEXT_MUTED}SSH + APIs + Sound${RESET}"
echo -e "  ${BLUE}27)${RESET} ${BOLD}Windows 95${RESET} ${BLUE}🪟${RESET}             ${TEXT_MUTED}Retro UI experience${RESET}"
echo -e "  ${GOLD}28)${RESET} ${BOLD}Agent Detail${RESET} ${GOLD}🔍${RESET}            ${TEXT_MUTED}Deep agent inspection${RESET}"
echo ""

echo -e "${GOLD}─────────────────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${TEXT_MUTED}0)${RESET} Exit"
echo ""
echo -ne "${TEXT_PRIMARY}Choose dashboard [1-28]: ${RESET}"
read choice

case $choice in
    1)
        ~/blackroad-dashboards/blackroad-master-control.sh
        ;;
    2)
        ~/blackroad-dashboards/blackroad-cosmic-lottery.sh
        ;;
    3)
        ~/blackroad-dashboards/device-raspberry-pi.sh --watch
        ;;
    4)
        ~/blackroad-dashboards/device-cloudflare.sh --watch
        ;;
    5)
        ~/blackroad-dashboards/device-github.sh --watch
        ;;
    6)
        ~/blackroad-dashboards/device-railway.sh --watch
        ;;
    7)
        ~/blackroad-dashboards/crypto-portfolio-live.sh
        ;;
    8)
        ~/blackroad-dashboards/memory-system-viz.sh --watch
        ;;
    9)
        ~/blackroad-dashboards/agent-network-map.sh --watch
        ;;
    10)
        ~/blackroad-dashboards/services-ports-map.sh --watch
        ;;
    11)
        ~/blackroad-dashboards/system-metrics-live.sh --watch
        ;;
    12)
        ~/blackroad-dashboards/network-topology-3d.sh --watch
        ;;
    13)
        ~/blackroad-dashboards/deployment-timeline.sh --watch
        ;;
    14)
        ~/blackroad-dashboards/database-monitor.sh --watch
        ;;
    15)
        ~/blackroad-dashboards/api-health-check.sh --watch
        ;;
    16)
        ~/blackroad-dashboards/docker-fleet.sh --watch
        ;;
    17)
        ~/blackroad-dashboards/ssl-cert-tracker.sh --watch
        ;;
    18)
        ~/blackroad-dashboards/dns-record-viewer.sh --watch
        ;;
    19)
        ~/blackroad-dashboards/log-aggregator.sh --watch
        ;;
    20)
        ~/blackroad-dashboards/backup-status.sh --watch
        ;;
    21)
        ~/blackroad-dashboards/security-dashboard.sh --watch
        ;;
    22)
        ~/blackroad-dashboards/build-pipeline.sh --watch
        ;;
    23)
        ~/blackroad-dashboards/blackroad-dashboard.sh
        ;;
    24)
        ~/blackroad-dashboards/blackroad-live-dashboard.sh
        ;;
    25)
        ~/blackroad-dashboards/blackroad-full-system.sh --watch
        ;;
    26)
        ~/blackroad-dashboards/blackroad-ultimate.sh --watch
        ;;
    27)
        ~/blackroad-dashboards/blackroad-os95.sh --watch
        ;;
    28)
        ~/blackroad-dashboards/agent-detail.sh --watch
        ;;
    0)
        echo -e "\n${CYAN}See you later! 👋${RESET}\n"
        exit 0
        ;;
    *)
        echo -e "\n${ORANGE}Invalid choice. Please run again.${RESET}\n"
        exit 1
        ;;
esac
