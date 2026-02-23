#!/bin/zsh
# BR Logs - Log Parser and Analyzer
AMBER='[38;5;214m'; PINK='[38;5;205m'; VIOLET='[38;5;135m'; BBLUE='[38;5;69m'
GREEN='[0;32m'; RED='[0;31m'; BOLD='[1m'; DIM='[2m'; NC='[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; MAGENTA="$VIOLET"; PURPLE="$VIOLET"

parse_logs() {
    local file=${1:-/dev/stdin}
    echo -e "${CYAN}📊 Parsing logs...${NC}\n"
    
    if [[ -f "$file" ]]; then
        cat "$file" | while read line; do
            if echo "$line" | grep -qi "error"; then
                echo -e "${RED}❌ $line${NC}"
            elif echo "$line" | grep -qi "warn"; then
                echo -e "${YELLOW}⚠️  $line${NC}"
            elif echo "$line" | grep -qi "success\|info"; then
                echo -e "${GREEN}✓ $line${NC}"
            else
                echo "$line"
            fi
        done
    else
        cat | while read line; do
            if echo "$line" | grep -qi "error"; then
                echo -e "${RED}❌ $line${NC}"
            elif echo "$line" | grep -qi "warn"; then
                echo -e "${YELLOW}⚠️  $line${NC}"
            elif echo "$line" | grep -qi "success\|info"; then
                echo -e "${GREEN}✓ $line${NC}"
            else
                echo "$line"
            fi
        done
    fi
}

show_errors() {
    local file=${1:-/dev/stdin}
    echo -e "${RED}🔥 Errors Only:${NC}\n"
    if [[ -f "$file" ]]; then
        grep -i "error" "$file" --color=always
    else
        grep -i "error" --color=always
    fi
}

case ${1:-help} in
    parse|p) parse_logs "$2" ;;
    errors|e) show_errors "$2" ;;
    help|--help|-h)
        echo -e "  ${AMBER}${BOLD}◆ BR LOGS${NC}  log parser\n"
        echo -e "  ${AMBER}br logs parse [file]${NC}   parse + colorize"
        echo -e "  ${AMBER}br logs errors [file]${NC}  errors only"
        echo -e "  ${DIM}pipe: cat app.log | br logs parse${NC}"
        ;;
    *) parse_logs "$1" ;;
esac
