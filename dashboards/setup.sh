#!/bin/bash

# BlackRoad OS Setup Wizard
# Interactive terminal-based configuration matching the web UI

# Colors
ORANGE="\033[38;2;247;147;26m"
PINK="\033[38;2;233;30;140m"
PURPLE="\033[38;2;153;69;255m"
BLUE="\033[38;2;20;241;149m"
CYAN="\033[38;2;0;212;255m"
GREEN="\033[38;2;34;197;94m"
TEXT_PRIMARY="\033[38;2;255;255;255m"
TEXT_SECONDARY="\033[38;2;153;153;153m"
TEXT_MUTED="\033[38;2;77;77;77m"
BG_CARD="\033[48;2;22;22;31m"
RESET="\033[0m"
BOLD="\033[1m"

# Configuration storage
CONFIG_FILE="$HOME/.blackroad-config"

# Default values
DEPLOYMENT_MODE="hybrid"
MAX_AGENTS=100
DEFAULT_MODEL="sonnet-4.5"
MEMORY_PER_AGENT="256MB"
EVENT_BUS=true
PS_SHA=true
Z_FRAMEWORK=true
AUTO_SCALE=true

# Progress step
show_progress() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}👻${RESET}  ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET} ${TEXT_MUTED}Setup Wizard${RESET}                             ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Progress bar
    echo -e "  ${GREEN}◉ Account${RESET}    ${GREEN}━━━${RESET}    ${GREEN}◉ Connect${RESET}    ${GREEN}━━━${RESET}    ${ORANGE}◉ Configure${RESET}"
    echo ""
}

# Header function
show_header() {
    local icon=$1
    local title=$2
    local subtitle=$3

    echo -e "${BG_CARD}                                                                        ${RESET}"
    echo -e "${BG_CARD}                              ${icon}                                ${RESET}"
    echo -e "${BG_CARD}                                                                        ${RESET}"
    echo -e "${BG_CARD}                    ${BOLD}${TEXT_PRIMARY}${title}${RESET}${BG_CARD}                           ${RESET}"
    echo -e "${BG_CARD}           ${TEXT_SECONDARY}${subtitle}${RESET}${BG_CARD}         ${RESET}"
    echo -e "${BG_CARD}                                                                        ${RESET}"
    echo ""
}

# Connected services
show_connected_services() {
    show_progress

    echo -e "${PINK}┌────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${PINK}│${RESET} ${CYAN}🔗${RESET} ${BOLD}Connected Services${RESET}                                                ${PINK}│${RESET}"
    echo -e "${PINK}├────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET}   ${TEXT_SECONDARY}Your linked accounts and integrations${RESET}                           ${PINK}│${RESET}"
    echo -e "${PINK}└────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""

    echo -e "  ${BLUE}◆${RESET} ${BOLD}Google${RESET}       ${TEXT_SECONDARY}alexa@blackroad.io${RESET}              ${GREEN}✓ Connected${RESET}"
    echo -e "  ${TEXT_MUTED}◆${RESET} ${BOLD}GitHub${RESET}       ${TEXT_SECONDARY}blackroad-os${RESET}                    ${GREEN}✓ Connected${RESET}"
    echo -e "  ${ORANGE}◆${RESET} ${BOLD}Cloudflare${RESET}   ${TEXT_SECONDARY}blackroad.io${RESET}                    ${GREEN}✓ Connected${RESET}"
    echo -e "  ${PURPLE}◆${RESET} ${BOLD}Anthropic${RESET}    ${TEXT_SECONDARY}sk-ant-...8f2k${RESET}                  ${GREEN}✓ Connected${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}Press Enter to continue...${RESET}"
    read
}

# Deployment mode selection
select_deployment_mode() {
    show_progress
    show_header "🚀" "Deployment Mode" "Choose how you want to run your agents"

    echo -e "${PINK}┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐${RESET}"
    echo -e "${PINK}│${RESET}                  ${PINK}│${RESET}    ${PINK}│${RESET}                  ${PINK}│${RESET}    ${PINK}│${RESET}                  ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}       💻        ${PINK}│${RESET}    ${PINK}│${RESET}       ☁️         ${PINK}│${RESET}    ${PINK}│${RESET}       🌐        ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}                  ${PINK}│${RESET}    ${PINK}│${RESET}                  ${PINK}│${RESET}    ${PINK}│${RESET}                  ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}   ${BOLD}Local${RESET}          ${PINK}│${RESET}    ${PINK}│${RESET}   ${BOLD}Hybrid${RESET}         ${PINK}│${RESET}    ${PINK}│${RESET}   ${BOLD}Cloud${RESET}          ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}   ${TEXT_MUTED}Your machine${RESET}   ${PINK}│${RESET}    ${PINK}│${RESET}   ${TEXT_MUTED}Local + CF${RESET}     ${PINK}│${RESET}    ${PINK}│${RESET}   ${TEXT_MUTED}Distributed${RESET}    ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}                  ${PINK}│${RESET}    ${PINK}│${RESET}                  ${PINK}│${RESET}    ${PINK}│${RESET}                  ${PINK}│${RESET}"
    echo -e "${PINK}└──────────────────┘    └──────────────────┘    └──────────────────┘${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} Local      ${TEXT_MUTED}Run agents on your local machine${RESET}"
    echo -e "  ${PINK}2)${RESET} Hybrid     ${TEXT_MUTED}Local compute + Cloudflare edge (Recommended)${RESET}"
    echo -e "  ${PURPLE}3)${RESET} Cloud      ${TEXT_MUTED}Fully distributed across infrastructure${RESET}"
    echo ""
    echo -ne "${TEXT_PRIMARY}Select deployment mode [2]: ${RESET}"

    read mode
    case ${mode:-2} in
        1) DEPLOYMENT_MODE="local" ;;
        2) DEPLOYMENT_MODE="hybrid" ;;
        3) DEPLOYMENT_MODE="cloud" ;;
        *) DEPLOYMENT_MODE="hybrid" ;;
    esac

    afplay /System/Library/Sounds/Tink.aiff &>/dev/null &
}

# Agent configuration
configure_agents() {
    show_progress
    show_header "🤖" "Agent Defaults" "Configure default settings for new agents"

    echo -e "${PINK}┌────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${PINK}│${RESET} ${BOLD}Default Model${RESET}                                                          ${PINK}│${RESET}"
    echo -e "${PINK}├────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET}   ${ORANGE}1)${RESET} Claude Sonnet 4.5 ${TEXT_MUTED}(Recommended)${RESET}                              ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}   ${ORANGE}2)${RESET} Claude Opus 4                                                   ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}   ${ORANGE}3)${RESET} Claude Haiku 3.5                                                ${PINK}│${RESET}"
    echo -e "${PINK}└────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -ne "${TEXT_PRIMARY}Select model [1]: ${RESET}"

    read model_choice
    case ${model_choice:-1} in
        1) DEFAULT_MODEL="sonnet-4.5" ;;
        2) DEFAULT_MODEL="opus-4" ;;
        3) DEFAULT_MODEL="haiku-3.5" ;;
        *) DEFAULT_MODEL="sonnet-4.5" ;;
    esac

    echo ""
    echo -e "${PINK}┌────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${PINK}│${RESET} ${BOLD}Max Concurrent Agents${RESET}                                                  ${PINK}│${RESET}"
    echo -e "${PINK}└────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${TEXT_SECONDARY}10${RESET}  ${TEXT_MUTED}────────────────────────────────────────────────${RESET}  ${TEXT_SECONDARY}1000${RESET}"
    echo -e "        ${PINK}█${ORANGE}█████${RESET}${TEXT_MUTED}───────────────────────────────────────${RESET}"
    echo ""
    echo -ne "${TEXT_PRIMARY}Enter max agents (10-1000) [100]: ${RESET}"

    read agents
    MAX_AGENTS=${agents:-100}

    echo ""
    echo -e "${PINK}┌────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${PINK}│${RESET} ${BOLD}Memory Allocation${RESET}                                                      ${PINK}│${RESET}"
    echo -e "${PINK}├────────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET}   ${ORANGE}1)${RESET} 128 MB                                                          ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}   ${ORANGE}2)${RESET} 256 MB ${TEXT_MUTED}(Recommended)${RESET}                                       ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}   ${ORANGE}3)${RESET} 512 MB                                                          ${PINK}│${RESET}"
    echo -e "${PINK}│${RESET}   ${ORANGE}4)${RESET} 1 GB                                                            ${PINK}│${RESET}"
    echo -e "${PINK}└────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -ne "${TEXT_PRIMARY}Select memory per agent [2]: ${RESET}"

    read mem_choice
    case ${mem_choice:-2} in
        1) MEMORY_PER_AGENT="128MB" ;;
        2) MEMORY_PER_AGENT="256MB" ;;
        3) MEMORY_PER_AGENT="512MB" ;;
        4) MEMORY_PER_AGENT="1GB" ;;
        *) MEMORY_PER_AGENT="256MB" ;;
    esac

    afplay /System/Library/Sounds/Tink.aiff &>/dev/null &
}

# System settings
configure_system() {
    show_progress
    show_header "🔧" "System Settings" "Infrastructure and security preferences"

    echo -e "${PINK}┌────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${PINK}│${RESET} ${BOLD}Feature Toggles${RESET}                                                        ${PINK}│${RESET}"
    echo -e "${PINK}└────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""

    # Event Bus
    echo -e "  ${BLUE}◆${RESET} ${BOLD}Enable Event Bus${RESET}"
    echo -e "    ${TEXT_MUTED}Allow agents to communicate via pub/sub messaging${RESET}"
    echo -ne "    ${TEXT_PRIMARY}Enable? (Y/n): ${RESET}"
    read event_bus
    EVENT_BUS=$([ "${event_bus,,}" != "n" ] && echo true || echo false)
    echo ""

    # PS-SHA∞
    echo -e "  ${PURPLE}◆${RESET} ${BOLD}PS-SHA∞ Memory Persistence${RESET}"
    echo -e "    ${TEXT_MUTED}Cryptographic hashing for agent memory storage${RESET}"
    echo -ne "    ${TEXT_PRIMARY}Enable? (Y/n): ${RESET}"
    read ps_sha
    PS_SHA=$([ "${ps_sha,,}" != "n" ] && echo true || echo false)
    echo ""

    # Z-Framework
    echo -e "  ${ORANGE}◆${RESET} ${BOLD}Z-Framework Integration${RESET}"
    echo -e "    ${TEXT_MUTED}Enable Z:=yx-w universal feedback systems${RESET}"
    echo -ne "    ${TEXT_PRIMARY}Enable? (Y/n): ${RESET}"
    read z_framework
    Z_FRAMEWORK=$([ "${z_framework,,}" != "n" ] && echo true || echo false)
    echo ""

    # Auto-scaling
    echo -e "  ${CYAN}◆${RESET} ${BOLD}Auto-scaling${RESET}"
    echo -e "    ${TEXT_MUTED}Automatically spawn agents based on workload${RESET}"
    echo -ne "    ${TEXT_PRIMARY}Enable? (Y/n): ${RESET}"
    read auto_scale
    AUTO_SCALE=$([ "${auto_scale,,}" != "n" ] && echo true || echo false)

    afplay /System/Library/Sounds/Tink.aiff &>/dev/null &
}

# Configuration summary
show_summary() {
    show_progress

    echo -e "${BG_CARD}                                                                        ${RESET}"
    echo -e "${BG_CARD}                    ${BOLD}${ORANGE}📋 Configuration Summary${RESET}${BG_CARD}                     ${RESET}"
    echo -e "${BG_CARD}                                                                        ${RESET}"
    echo ""

    echo -e "${PINK}┌───────────────────────────────┬────────────────────────────────────────┐${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Deployment${RESET}                    ${PINK}│${RESET} ${BOLD}${DEPLOYMENT_MODE^} Mode${RESET}                        ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Max Agents${RESET}                    ${PINK}│${RESET} ${BOLD}${ORANGE}${MAX_AGENTS}${RESET}                                   ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Model${RESET}                         ${PINK}│${RESET} ${BOLD}${PURPLE}${DEFAULT_MODEL}${RESET}                             ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Memory/Agent${RESET}                  ${PINK}│${RESET} ${BOLD}${CYAN}${MEMORY_PER_AGENT}${RESET}                                ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Event Bus${RESET}                     ${PINK}│${RESET} ${BOLD}$([ "$EVENT_BUS" = true ] && echo -e "${GREEN}Enabled${RESET}" || echo -e "${TEXT_MUTED}Disabled${RESET}")                             ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}PS-SHA∞ Persistence${RESET}           ${PINK}│${RESET} ${BOLD}$([ "$PS_SHA" = true ] && echo -e "${GREEN}Enabled${RESET}" || echo -e "${TEXT_MUTED}Disabled${RESET}")                             ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Z-Framework${RESET}                   ${PINK}│${RESET} ${BOLD}$([ "$Z_FRAMEWORK" = true ] && echo -e "${GREEN}Enabled${RESET}" || echo -e "${TEXT_MUTED}Disabled${RESET}")                             ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Auto-scaling${RESET}                  ${PINK}│${RESET} ${BOLD}$([ "$AUTO_SCALE" = true ] && echo -e "${GREEN}Enabled${RESET}" || echo -e "${TEXT_MUTED}Disabled${RESET}")                             ${PINK}│${RESET}"
    echo -e "${PINK}├───────────────────────────────┼────────────────────────────────────────┤${RESET}"
    echo -e "${PINK}│${RESET} ${TEXT_MUTED}Network${RESET}                       ${PINK}│${RESET} ${BOLD}${BLUE}192.168.4.x${RESET}                            ${PINK}│${RESET}"
    echo -e "${PINK}└───────────────────────────────┴────────────────────────────────────────┘${RESET}"
    echo ""

    echo -e "${TEXT_SECONDARY}Is this configuration correct?${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} Yes, save and launch"
    echo -e "  ${PINK}2)${RESET} No, start over"
    echo ""
    echo -ne "${TEXT_PRIMARY}Choice: ${RESET}"

    read confirm

    if [ "${confirm:-1}" = "1" ]; then
        save_config
        launch_system
    else
        main
    fi
}

# Save configuration
save_config() {
    cat > "$CONFIG_FILE" <<EOF
# BlackRoad OS Configuration
# Generated: $(date)

DEPLOYMENT_MODE="$DEPLOYMENT_MODE"
MAX_AGENTS=$MAX_AGENTS
DEFAULT_MODEL="$DEFAULT_MODEL"
MEMORY_PER_AGENT="$MEMORY_PER_AGENT"
EVENT_BUS=$EVENT_BUS
PS_SHA=$PS_SHA
Z_FRAMEWORK=$Z_FRAMEWORK
AUTO_SCALE=$AUTO_SCALE
EOF

    echo ""
    echo -e "${GREEN}✓ Configuration saved to ${CONFIG_FILE}${RESET}"
}

# Launch system
launch_system() {
    clear
    echo ""
    echo -e "${BOLD}${ORANGE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${ORANGE}║${RESET}  ${BOLD}${ORANGE}👻${RESET}  ${BOLD}${ORANGE}B${PINK}L${PURPLE}A${BLUE}C${CYAN}K${ORANGE}R${PINK}O${PURPLE}A${BLUE}D${RESET} ${TEXT_SECONDARY}OS${RESET} ${TEXT_MUTED}Launching...${RESET}                              ${BOLD}${ORANGE}║${RESET}"
    echo -e "${BOLD}${ORANGE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    afplay /System/Library/Sounds/Glass.aiff &>/dev/null &

    echo -e "${TEXT_SECONDARY}Initializing BlackRoad OS...${RESET}"
    sleep 1

    echo -e "${BLUE}▸${RESET} Loading configuration..."
    sleep 0.5

    echo -e "${PURPLE}▸${RESET} Connecting to services..."
    sleep 0.5

    echo -e "${ORANGE}▸${RESET} Spawning ${MAX_AGENTS} agent slots..."
    sleep 0.5

    echo -e "${CYAN}▸${RESET} Initializing event bus..."
    sleep 0.5

    echo -e "${GREEN}▸${RESET} PS-SHA∞ memory system ready..."
    sleep 0.5

    echo -e "${PINK}▸${RESET} Z-Framework loaded..."
    sleep 0.5

    echo ""
    echo -e "${GREEN}✓ BlackRoad OS is online!${RESET}"
    echo ""

    afplay /System/Library/Sounds/Tink.aiff &>/dev/null &

    echo -e "${TEXT_SECONDARY}Launch a dashboard to monitor your system:${RESET}"
    echo ""
    echo -e "  ${ORANGE}•${RESET} ${BOLD}./launch.sh${RESET} ${TEXT_MUTED}Interactive dashboard launcher${RESET}"
    echo -e "  ${PINK}•${RESET} ${BOLD}./blackroad-ultimate.sh --watch${RESET} ${TEXT_MUTED}Full featured monitor${RESET}"
    echo -e "  ${PURPLE}•${RESET} ${BOLD}./blackroad-os95.sh --boot${RESET} ${TEXT_MUTED}Windows 95 edition${RESET}"
    echo ""
}

# Main flow
main() {
    show_connected_services
    select_deployment_mode
    configure_agents
    configure_system
    show_summary
}

# Run
main
