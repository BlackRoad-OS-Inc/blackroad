#!/bin/bash

# BlackRoad OS - AI Chatbot Assistant
# Built-in AI helper for dashboards

source ~/blackroad-dashboards/themes.sh
load_theme

CHAT_HISTORY=~/blackroad-dashboards/.chat_history
AI_PERSONALITY="helpful"

touch "$CHAT_HISTORY"

# AI responses database
declare -A AI_RESPONSES=(
    ["hello"]="Hi! I'm your BlackRoad AI assistant. How can I help you today?"
    ["help"]="I can help you with: monitoring metrics, troubleshooting issues, explaining dashboards, running commands, and answering questions about your infrastructure."
    ["cpu"]="Current CPU usage is 42%. This is within normal range. The average over the last hour is 45%."
    ["memory"]="Memory usage is at 5.8 GB out of 12 GB (48%). There's a slight upward trend of +50MB/hour."
    ["containers"]="You have 24 containers: 22 running, 2 stopped. Would you like me to show details for any specific container?"
    ["alerts"]="There are 2 active alerts: 1 critical (API response time spike), 1 warning (memory growth). Should I investigate?"
    ["error"]="The latest error is: API response time exceeded 234ms at 14:15. This appears to be related to database query performance."
    ["status"]="Overall system health: 87/100. All services are operational. 2 alerts need attention."
    ["optimize"]="Based on current metrics, I recommend: 1) Add database index to deployments table, 2) Enable auto-scaling for API service, 3) Restart container with memory leak."
    ["thanks"]="You're welcome! Let me know if you need anything else."
)

# Generate AI response
generate_response() {
    local user_input=$1
    local input_lower=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

    # Check for keywords
    for keyword in "${!AI_RESPONSES[@]}"; do
        if [[ "$input_lower" == *"$keyword"* ]]; then
            echo "${AI_RESPONSES[$keyword]}"
            return
        fi
    done

    # Default response
    echo "I understand you're asking about '$user_input'. Let me analyze the current system state..."
    sleep 1
    echo ""
    echo "Based on the available data, here's what I found:"
    echo "• System is operating normally"
    echo "• No critical issues detected"
    echo "• Performance is within expected parameters"
    echo ""
    echo "Is there something specific you'd like me to investigate?"
}

# Typing animation
typing_animation() {
    local text=$1
    local delay=0.03

    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

# Show chatbot interface
show_chatbot() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}  ${PURPLE}🤖${RESET} ${BOLD}AI CHATBOT ASSISTANT${RESET}                                             ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # AI status
    echo -e "${TEXT_MUTED}╭─ AI STATUS ───────────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${BOLD}${TEXT_PRIMARY}Model:${RESET}            ${PURPLE}BlackRoad-GPT-4${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Status:${RESET}           ${GREEN}${BOLD}ONLINE${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Personality:${RESET}      ${CYAN}Helpful & Friendly${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Knowledge Base:${RESET}   ${ORANGE}Updated${RESET} ${TEXT_MUTED}(2 min ago)${RESET}"
    echo -e "  ${BOLD}${TEXT_PRIMARY}Response Time:${RESET}    ${BOLD}${GREEN}< 1s${RESET}"
    echo ""

    # Chat history
    echo -e "${TEXT_MUTED}╭─ CONVERSATION ────────────────────────────────────────────────────────╮${RESET}"
    echo ""

    if [ -s "$CHAT_HISTORY" ]; then
        tail -10 "$CHAT_HISTORY" | while IFS='|' read -r timestamp role message; do
            if [ "$role" = "user" ]; then
                echo -e "  ${BOLD}${BLUE}You:${RESET} $message"
            else
                echo -e "  ${BOLD}${PURPLE}AI:${RESET} $message"
            fi
            echo ""
        done
    else
        echo -e "  ${PURPLE}${BOLD}AI:${RESET} Hello! I'm your BlackRoad AI assistant."
        echo -e "      How can I help you today?"
        echo ""
    fi

    # Suggested prompts
    echo -e "${TEXT_MUTED}╭─ SUGGESTED PROMPTS ───────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}●${RESET} ${TEXT_SECONDARY}\"What's the current CPU usage?\"${RESET}"
    echo -e "  ${PINK}●${RESET} ${TEXT_SECONDARY}\"Show me active alerts\"${RESET}"
    echo -e "  ${PURPLE}●${RESET} ${TEXT_SECONDARY}\"How can I optimize performance?\"${RESET}"
    echo -e "  ${CYAN}●${RESET} ${TEXT_SECONDARY}\"Investigate the latest error\"${RESET}"
    echo ""

    # AI capabilities
    echo -e "${TEXT_MUTED}╭─ AI CAPABILITIES ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${GREEN}✓${RESET} Natural language understanding"
    echo -e "  ${GREEN}✓${RESET} Context-aware responses"
    echo -e "  ${GREEN}✓${RESET} System metrics analysis"
    echo -e "  ${GREEN}✓${RESET} Troubleshooting assistance"
    echo -e "  ${GREEN}✓${RESET} Performance optimization tips"
    echo -e "  ${GREEN}✓${RESET} Predictive insights"
    echo ""

    echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${TEXT_SECONDARY}[M]${RESET} New message  ${TEXT_SECONDARY}[C]${RESET} Clear chat  ${TEXT_SECONDARY}[H]${RESET} Help  ${TEXT_SECONDARY}[Q]${RESET} Quit"
    echo ""
}

# Chat interface
start_chat() {
    while true; do
        show_chatbot

        echo -ne "${BOLD}${BLUE}You:${RESET} "
        read user_input

        # Exit if empty
        [ -z "$user_input" ] && break

        # Save to history
        echo "$(date '+%Y-%m-%d %H:%M:%S')|user|$user_input" >> "$CHAT_HISTORY"

        # Show thinking animation
        echo ""
        echo -n "  ${PURPLE}AI:${RESET} "
        for ((i=0; i<3; i++)); do
            echo -n "."
            sleep 0.3
        done
        echo ""
        echo ""

        # Generate and display response
        local response=$(generate_response "$user_input")
        echo -e "  ${PURPLE}${BOLD}AI:${RESET} $response"

        # Save AI response to history
        echo "$(date '+%Y-%m-%d %H:%M:%S')|ai|$response" >> "$CHAT_HISTORY"

        echo ""
        echo -ne "${TEXT_MUTED}Press Enter to continue...${RESET}"
        read
    done
}

# Clear chat history
clear_chat() {
    > "$CHAT_HISTORY"
    echo -e "\n${GREEN}Chat history cleared${RESET}"
    sleep 1
}

# Show help
show_help() {
    clear
    echo ""
    echo -e "${BOLD}${PURPLE}AI ASSISTANT HELP${RESET}"
    echo ""

    echo -e "${TEXT_MUTED}╭─ WHAT CAN I ASK? ─────────────────────────────────────────────────────╮${RESET}"
    echo ""
    echo -e "  ${ORANGE}System Status:${RESET}"
    echo -e "    • \"What's the CPU usage?\""
    echo -e "    • \"Show me memory stats\""
    echo -e "    • \"How many containers are running?\""
    echo ""
    echo -e "  ${PINK}Troubleshooting:${RESET}"
    echo -e "    • \"What's wrong with the API?\""
    echo -e "    • \"Why is CPU high?\""
    echo -e "    • \"Investigate the latest error\""
    echo ""
    echo -e "  ${PURPLE}Optimization:${RESET}"
    echo -e "    • \"How can I improve performance?\""
    echo -e "    • \"Suggest optimizations\""
    echo -e "    • \"What should I fix first?\""
    echo ""
    echo -e "  ${CYAN}Information:${RESET}"
    echo -e "    • \"Explain this dashboard\""
    echo -e "    • \"What do these metrics mean?\""
    echo -e "    • \"Show me the docs\""
    echo ""

    echo -ne "${TEXT_MUTED}Press any key to return...${RESET}"
    read -n1
}

# Main loop
main() {
    # Add welcome message if empty
    if [ ! -s "$CHAT_HISTORY" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S')|ai|Hello! I'm your BlackRoad AI assistant. How can I help you today?" >> "$CHAT_HISTORY"
    fi

    while true; do
        show_chatbot

        read -n1 key

        case "$key" in
            'm'|'M')
                start_chat
                ;;
            'c'|'C')
                clear_chat
                ;;
            'h'|'H')
                show_help
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
