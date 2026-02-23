#!/bin/bash

# BlackRoad OS Dashboard Launcher
# Quick launcher menu for all dashboards

# Colors
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
RESET="\033[0m"
BOLD="\033[1m"

clear

echo ""
echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}👻${RESET}  ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET} ${TEXT_MUTED}Dashboard Launcher${RESET}                        ${BOLD}${ORANGE}║${RESET}"
echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${TEXT_MUTED}Select a dashboard to launch:${RESET}"
echo ""
echo -e "  ${ORANGE}1)${RESET} ${BOLD}Basic Dashboard${RESET}"
echo -e "     ${TEXT_MUTED}Quick status overview with agent grid${RESET}"
echo ""
echo -e "  ${PINK}2)${RESET} ${BOLD}Live Monitor${RESET}"
echo -e "     ${TEXT_MUTED}Full infrastructure monitoring with device checks${RESET}"
echo ""
echo -e "  ${PURPLE}3)${RESET} ${BOLD}Full System Monitor${RESET}"
echo -e "     ${TEXT_MUTED}Enhanced dashboard with progress bars (auto-refresh)${RESET}"
echo ""
echo -e "  ${BLUE}4)${RESET} ${BOLD}ULTIMATE Edition${RESET} ${ORANGE}⚡${RESET}"
echo -e "     ${TEXT_MUTED}Sound effects • APIs • SSH menu • Interactive${RESET}"
echo ""
echo -e "  ${CYAN}5)${RESET} ${BOLD}Windows 95 Edition${RESET} ${PURPLE}🪟${RESET}"
echo -e "     ${TEXT_MUTED}Retro Win95 UI with boot sequence${RESET}"
echo ""
echo -e "  ${ORANGE}6)${RESET} ${BOLD}Agent Detail Viewer${RESET} ${BLUE}🔍${RESET}"
echo -e "     ${TEXT_MUTED}Inspect individual agents with live logs & resources${RESET}"
echo ""
echo -e "  ${PURPLE}7)${RESET} ${BOLD}Beautiful OS Edition${RESET} ${PINK}✨${RESET}"
echo -e "     ${TEXT_MUTED}Cards • Buttons • Modern UI design${RESET}"
echo ""
echo -e "${PINK}─────────────────────────────────────────────────────────────────────────${RESET}"
echo ""
echo -e "  ${TEXT_MUTED}0)${RESET} Exit"
echo ""
echo -ne "${TEXT_PRIMARY}Choice: ${RESET}"

read choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}Launching Basic Dashboard...${RESET}"
        sleep 1
        ./blackroad-dashboard.sh
        ;;
    2)
        echo ""
        echo -e "${BLUE}Launching Live Monitor...${RESET}"
        sleep 1
        ./blackroad-live-dashboard.sh
        ;;
    3)
        echo ""
        echo -e "${BLUE}Launching Full System Monitor...${RESET}"
        echo -e "${TEXT_MUTED}Press Ctrl+C to exit${RESET}"
        sleep 1
        ./blackroad-full-system.sh --watch
        ;;
    4)
        echo ""
        echo -e "${BLUE}Launching ULTIMATE Edition...${RESET}"
        echo -e "${TEXT_MUTED}Controls: [s] SSH Menu  [r] Refresh  [q] Quit${RESET}"
        sleep 1
        ./blackroad-ultimate.sh --watch
        ;;
    5)
        echo ""
        echo -e "${BLUE}Select Windows 95 mode:${RESET}"
        echo ""
        echo -e "  ${ORANGE}a)${RESET} With boot sequence"
        echo -e "  ${PINK}b)${RESET} Interactive mode"
        echo -e "  ${PURPLE}c)${RESET} Static view"
        echo ""
        echo -ne "${TEXT_PRIMARY}Choice: ${RESET}"
        read win95_choice

        case $win95_choice in
            a)
                echo ""
                echo -e "${BLUE}Booting BlackRoad OS 95...${RESET}"
                sleep 1
                ./blackroad-os95.sh --boot
                ;;
            b)
                echo ""
                echo -e "${BLUE}Launching interactive mode...${RESET}"
                echo -e "${TEXT_MUTED}Controls: [s] Start Menu  [p] Properties  [q] Shutdown${RESET}"
                sleep 1
                ./blackroad-os95.sh --watch
                ;;
            c)
                echo ""
                echo -e "${BLUE}Launching static view...${RESET}"
                sleep 1
                ./blackroad-os95.sh
                ;;
            *)
                echo ""
                echo -e "${PINK}Invalid choice. Exiting.${RESET}"
                exit 1
                ;;
        esac
        ;;
    6)
        echo ""
        echo -e "${BLUE}Select agent to inspect:${RESET}"
        echo ""
        echo -e "  ${ORANGE}a)${RESET} Lucidia Prime (192.168.4.38)"
        echo -e "  ${PINK}b)${RESET} Oracle (192.168.4.64)"
        echo -e "  ${PURPLE}c)${RESET} Sentinel (192.168.4.99)"
        echo -e "  ${BLUE}d)${RESET} Custom agent..."
        echo ""
        echo -ne "${TEXT_PRIMARY}Choice: ${RESET}"
        read agent_choice

        case $agent_choice in
            a)
                echo ""
                echo -e "${BLUE}Loading Lucidia Prime details...${RESET}"
                echo -e "${TEXT_MUTED}Controls: [1-6] Switch Tab  [s] SSH  [r] Refresh  [q] Back${RESET}"
                sleep 1
                ./agent-detail.sh "Lucidia Prime" "192.168.4.38" "online" "sonnet-4.5" "overview" --watch
                ;;
            b)
                echo ""
                echo -e "${BLUE}Loading Oracle details...${RESET}"
                echo -e "${TEXT_MUTED}Controls: [1-6] Switch Tab  [s] SSH  [r] Refresh  [q] Back${RESET}"
                sleep 1
                ./agent-detail.sh "Oracle" "192.168.4.64" "online" "sonnet-4" "overview" --watch
                ;;
            c)
                echo ""
                echo -e "${BLUE}Loading Sentinel details...${RESET}"
                echo -e "${TEXT_MUTED}Controls: [1-6] Switch Tab  [s] SSH  [r] Refresh  [q] Back${RESET}"
                sleep 1
                ./agent-detail.sh "Sentinel" "192.168.4.99" "online" "sonnet-4.5" "overview" --watch
                ;;
            d)
                echo ""
                echo -ne "${TEXT_PRIMARY}Agent name: ${RESET}"
                read custom_name
                echo -ne "${TEXT_PRIMARY}Host IP: ${RESET}"
                read custom_host
                echo ""
                echo -e "${BLUE}Loading ${custom_name} details...${RESET}"
                echo -e "${TEXT_MUTED}Controls: [1-6] Switch Tab  [s] SSH  [r] Refresh  [q] Back${RESET}"
                sleep 1
                ./agent-detail.sh "$custom_name" "$custom_host" "online" "sonnet-4.5" "overview" --watch
                ;;
            *)
                echo ""
                echo -e "${PINK}Invalid choice. Exiting.${RESET}"
                exit 1
                ;;
        esac
        ;;
    7)
        echo ""
        echo -e "${BLUE}Select Beautiful OS mode:${RESET}"
        echo ""
        echo -e "  ${ORANGE}a)${RESET} With boot sequence"
        echo -e "  ${PINK}b)${RESET} Interactive mode"
        echo -e "  ${PURPLE}c)${RESET} Static view"
        echo ""
        echo -ne "${TEXT_PRIMARY}Choice: ${RESET}"
        read beautiful_choice

        case $beautiful_choice in
            a)
                echo ""
                echo -e "${BLUE}Booting Beautiful OS...${RESET}"
                sleep 1
                ./blackroad-beautiful-os.sh --boot
                ;;
            b)
                echo ""
                echo -e "${BLUE}Launching interactive mode...${RESET}"
                echo -e "${TEXT_MUTED}Controls: [1-9] Launch App  [m] Menu  [q] Shutdown${RESET}"
                sleep 1
                ./blackroad-beautiful-os.sh --watch
                ;;
            c)
                echo ""
                echo -e "${BLUE}Launching static view...${RESET}"
                sleep 1
                ./blackroad-beautiful-os.sh
                ;;
            *)
                echo ""
                echo -e "${PINK}Invalid choice. Exiting.${RESET}"
                exit 1
                ;;
        esac
        ;;
    0)
        echo ""
        echo -e "${BLUE}Goodbye!${RESET}"
        echo ""
        exit 0
        ;;
    *)
        echo ""
        echo -e "${PINK}Invalid choice. Exiting.${RESET}"
        exit 1
        ;;
esac

echo ""
echo -e "${TEXT_MUTED}Dashboard closed. Run ${RESET}${BOLD}./launch.sh${RESET}${TEXT_MUTED} to launch again.${RESET}"
echo ""
