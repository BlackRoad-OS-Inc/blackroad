#!/bin/bash

# BlackRoad OS - Voice Control System
# Control dashboards with voice commands

source ~/blackroad-dashboards/themes.sh
load_theme

VOICE_LOG=~/blackroad-dashboards/.voice_commands
VOICE_ENABLED=true

touch "$VOICE_LOG"

# Simulated voice recognition
recognize_voice() {
    local timeout=${1:-5}

    echo -e "\n${PURPLE}🎤${RESET} ${BOLD}Listening...${RESET}\n"

    # Simulate listening animation
    for ((i=0; i<timeout; i++)); do
        echo -ne "\r  ${CYAN}"
        for ((j=0; j<$((i + 1)); j++)); do
            echo -n "●"
        done
        echo -ne "${RESET}  "
        sleep 1
    done

    echo -e "\n\n${GREEN}✓ Command recognized!${RESET}\n"
    sleep 1
}

# Process voice command
process_command() {
    local command=$1

    echo "$(date '+%Y-%m-%d %H:%M:%S')|$command|executed" >> "$VOICE_LOG"

    case "$command" in
        "show metrics"|"metrics")
            show_metrics_view
            ;;
        "show alerts"|"alerts")
            show_alerts_view
            ;;
        "increase cpu"|"cpu up")
            echo -e "${GREEN}Simulating CPU increase...${RESET}"
            sleep 1
            ;;
        "help"|"commands")
            show_voice_commands
            ;;
        *)
            echo -e "${YELLOW}Command not recognized: $command${RESET}"
            ;;
    esac
}

# Show metrics view
show_metrics_view() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}METRICS VIEW${RESET} ${TEXT_MUTED}(Voice activated)${RESET}"
    echo ""

    echo -e "  ${ORANGE}CPU${RESET}      ${ORANGE}████████████${RESET}    ${BOLD}42%${RESET}"
    echo -e "  ${PINK}Memory${RESET}   ${PINK}████████████████${RESET}${BOLD}5.8 GB${RESET}"
    echo -e "  ${PURPLE}Disk${RESET}     ${PURPLE}██████${RESET}          ${BOLD}847 MB/s${RESET}"
    echo ""

    sleep 3
}

# Show alerts view
show_alerts_view() {
    clear
    echo ""
    echo -e "${BOLD}${RED}ALERTS VIEW${RESET} ${TEXT_MUTED}(Voice activated)${RESET}"
    echo ""

    echo -e "  ${RED}🚨${RESET} ${BOLD}API Response Time Spike${RESET}"
    echo -e "     ${TEXT_MUTED}234ms (baseline: 23ms)${RESET}"
    echo ""
    echo -e "  ${YELLOW}⚠️${RESET}  ${BOLD}Memory Growing${RESET}"
    echo -e "     ${TEXT_MUTED}50MB/hour trend${RESET}"
    echo ""

    sleep 3
}

# Show available voice commands
show_voice_commands() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}VOICE COMMANDS REFERENCE${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ NAVIGATION ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}\"show metrics\"${RESET}       Display system metrics"
    echo -e "  ${CYAN}\"show alerts\"${RESET}        Display active alerts"
    echo -e "  ${CYAN}\"show dashboard\"${RESET}     Open main dashboard"
    echo -e "  ${CYAN}\"go back\"${RESET}            Return to previous view"
    echo ""

    echo -e "${TEXT_MUTED}╭─ ACTIONS ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}\"restart service\"${RESET}   Restart a service"
    echo -e "  ${ORANGE}\"scale up\"${RESET}          Increase replicas"
    echo -e "  ${ORANGE}\"scale down\"${RESET}        Decrease replicas"
    echo -e "  ${ORANGE}\"clear alerts\"${RESET}      Clear all alerts"
    echo ""

    echo -e "${TEXT_MUTED}╭─ QUERIES ─────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}\"what's the CPU\"${RESET}    Get CPU usage"
    echo -e "  ${GREEN}\"how many containers\"${RESET} Get container count"
    echo -e "  ${GREEN}\"system status\"${RESET}     Get overall status"
    echo -e "  ${GREEN}\"latest error\"${RESET}      Get most recent error"
    echo ""

    echo -e "${TEXT_MUTED}╭─ SETTINGS ────────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${PURPLE}\"enable notifications\"${RESET}  Turn on alerts"
    echo -e "  ${PURPLE}\"disable notifications\"${RESET} Turn off alerts"
    echo -e "  ${PURPLE}\"change theme\"${RESET}          Switch color theme"
    echo ""

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Voice control dashboard
show_voice_dashboard() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${PURPLE}║${RESET}  ${CYAN}🎤${RESET} ${BOLD}VOICE CONTROL SYSTEM${RESET}                                             ${BOLD}${PURPLE}║${RESET}"
    echo -e "${BOLD}${PURPLE}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Status
    echo -e "${TEXT_MUTED}╭─ VOICE RECOGNITION STATUS ────────────────────────────────────────────╮${RESET}"
    echo ""

    local status_color
    if [ "$VOICE_ENABLED" = true ]; then
        status_color="${GREEN}"
    else
        status_color="${RED}"
    fi

    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}           $status_color${BOLD}$([ "$VOICE_ENABLED" = true ] && echo "ACTIVE" || echo "DISABLED")${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Microphone:${RESET}       ${GREEN}Connected${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Language:${RESET}         ${CYAN}English (US)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Confidence:${RESET}       ${BOLD}${GREEN}94.7%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Wake Word:${RESET}        ${PURPLE}\"Hey BlackRoad\"${RESET}"
    echo ""

    # Voice visualization
    echo -e "${TEXT_MUTED}╭─ AUDIO VISUALIZATION ─────────────────────────────────────────────────╮${RESET}"
    echo ""

    # Animated waveform
    local chars="▁▂▃▄▅▆▇█"
    echo -n "  "
    for ((i=0; i<50; i++)); do
        local height=$((RANDOM % 8))
        echo -n "${CYAN}${chars:$height:1}${RESET}"
    done
    echo ""
    echo ""

    # Recent commands
    echo -e "${TEXT_MUTED}╭─ RECENT VOICE COMMANDS ───────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -s "$VOICE_LOG" ]; then
        tail -5 "$VOICE_LOG" | while IFS='|' read -r timestamp command status; do
            echo -e "  ${GREEN}●${RESET} ${TEXT_MUTED}[$timestamp]${RESET} \"${BOLD}$command${RESET}\""
        done
    else
        echo -e "  ${TEXT_MUTED}No commands yet${RESET}"
    fi
    echo ""

    # Quick actions
    echo -e "${TEXT_MUTED}╭─ QUICK ACTIONS ───────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}1)${RESET} Test Voice Recognition"
    echo -e "  ${PINK}2)${RESET} View All Commands"
    echo -e "  ${PURPLE}3)${RESET} Voice Settings"
    echo -e "  ${CYAN}4)${RESET} Voice Training"
    echo ""

    # Sample commands
    echo -e "${TEXT_MUTED}╭─ TRY SAYING ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${CYAN}💬${RESET} ${TEXT_SECONDARY}\"Hey BlackRoad, show me the metrics\"${RESET}"
    echo -e "  ${CYAN}💬${RESET} ${TEXT_SECONDARY}\"What's the CPU usage?\"${RESET}"
    echo -e "  ${CYAN}💬${RESET} ${TEXT_SECONDARY}\"Show active alerts\"${RESET}"
    echo -e "  ${CYAN}💬${RESET} ${TEXT_SECONDARY}\"Restart the API service\"${RESET}"
    echo ""

    # Stats
    echo -e "${TEXT_MUTED}╭─ STATISTICS ──────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    local total_commands=$(wc -l < "$VOICE_LOG" 2>/dev/null || echo 0)
    echo -e "  ${BOLD}${TEXT_PRIMARY}Total Commands:${RESET}      ${BOLD}${ORANGE}${total_commands}${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Success Rate:${RESET}        ${BOLD}${GREEN}94.7%${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Avg Response Time:${RESET}   ${BOLD}${CYAN}1.2s${RESET}"
    echo ""

    echo -e "${PURPLE}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[V]${RESET} Voice test  ${TEXT_SECONDARY}[C]${RESET} Commands  ${TEXT_SECONDARY}[T]${RESET} Toggle  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Main loop
main() {
    # Add sample commands
    if [ ! -s "$VOICE_LOG" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S')|show metrics|executed" >> "$VOICE_LOG"
        echo "$(date '+%Y-%m-%d %H:%M:%S')|what's the CPU|executed" >> "$VOICE_LOG"
    fi

    while true; do
        show_voice_dashboard

        read -n1 key

        case "$key" in
            'v'|'V')
                recognize_voice 3
                process_command "show metrics"
                ;;
            'c'|'C')
                show_voice_commands
                ;;
            't'|'T')
                if [ "$VOICE_ENABLED" = true ]; then
                    VOICE_ENABLED=false
                    echo -e "\n${RED}Voice control disabled${RESET}"
                else
                    VOICE_ENABLED=true
                    echo -e "\n${GREEN}Voice control enabled${RESET}"
                fi
                sleep 1
                ;;
            'q'|'Q')
                echo -e "\n${CYAN}Goodbye!${RESET}\n"
                exit 0
                ;;
        esac
    done
}

# Run
main
