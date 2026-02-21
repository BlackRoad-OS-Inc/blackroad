#!/bin/zsh
# BR Logs - Log Parser and Analyzer
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

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

case ${1:-parse} in
    parse|p) parse_logs "$2" ;;
    errors|e) show_errors "$2" ;;
    *) parse_logs "$1" ;;
esac
