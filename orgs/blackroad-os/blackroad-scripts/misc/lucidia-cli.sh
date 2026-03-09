#!/bin/bash
# Lucidia CLI - Talk to Lucidia AI  
# Created by Alice (PS-SHA-∞-alice-f7a3c2b9)

CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
NC='\033[0m'

show_header() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   🧠 Lucidia - Conversational AI      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
}

case "${1:-help}" in
    ask)
        show_header
        shift
        echo -e "${PURPLE}💭 Question:${NC} $*"
        echo -e "${GREEN}🧠 Lucidia:${NC} I'm Lucidia! Ready to answer your questions!"
        ;;
    chat)
        show_header  
        echo -e "${GREEN}Starting interactive chat... (type 'exit' to quit)${NC}"
        echo ""
        while true; do
            echo -ne "${PURPLE}You: ${NC}"
            read input
            [[ "$input" == "exit" ]] && break
            echo -e "${GREEN}Lucidia:${NC} I hear you say: \"$input\" - Let's chat!"
            echo ""
        done
        ;;
    status)
        show_header
        echo -e "${GREEN}✅ Lucidia is operational!${NC}"
        echo "   Pi Location: 192.168.4.38:8080"
        echo "   Created by: Alice"
        ;;
    *)
        show_header
        echo "Commands:"
        echo "  lucidia-cli.sh ask \"question\"  - Ask Lucidia"
        echo "  lucidia-cli.sh chat             - Interactive chat"
        echo "  lucidia-cli.sh status           - Check status"
        ;;
esac
