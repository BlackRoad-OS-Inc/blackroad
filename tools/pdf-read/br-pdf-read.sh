#!/bin/zsh
# BR PDF Read — extract text from PDFs using pdftotext or python

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

FILE="$2"
CMD="${1:-help}"

extract_text() {
    local f="$1"
    [[ ! -f "$f" ]] && echo -e "${RED}✗ File not found: $f${NC}" && return 1
    
    # Try pdftotext first (poppler)
    if command -v pdftotext &>/dev/null; then
        pdftotext "$f" - 2>/dev/null && return 0
    fi
    # Try python pdfminer
    if python3 -c "import pdfminer" 2>/dev/null; then
        python3 -c "
from pdfminer.high_level import extract_text
print(extract_text('$f'))
" 2>/dev/null && return 0
    fi
    # Try strings fallback
    echo -e "${YELLOW}⚠ No PDF parser found — using strings fallback${NC}" >&2
    strings "$f" | grep -E '^.{10,}$' | grep -v '^[^a-zA-Z]*$'
}

cmd_read() {
    [[ -z "$FILE" ]] && echo -e "${RED}Usage: br pdf read <file.pdf>${NC}" && return 1
    echo -e "${CYAN}📄 Reading: $FILE${NC}\n"
    extract_text "$FILE"
}

cmd_summary() {
    [[ -z "$FILE" ]] && echo -e "${RED}Usage: br pdf summary <file.pdf>${NC}" && return 1
    local text=$(extract_text "$FILE" 2>/dev/null | head -200)
    local word_count=$(echo "$text" | wc -w | tr -d ' ')
    local pages=$(pdfinfo "$FILE" 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "?")
    echo -e "${CYAN}📄 $FILE${NC}"
    echo -e "  Pages: $pages | Words: ~$word_count"
    echo -e "\n${CYAN}First 500 chars:${NC}"
    echo "$text" | head -c 500
    echo ""
}

cmd_search() {
    local pattern="$FILE"  # reuse FILE arg as pattern
    local target="${3:-$PWD}"
    [[ -z "$pattern" ]] && echo -e "${RED}Usage: br pdf search <pattern> [dir]${NC}" && return 1
    echo -e "${CYAN}🔍 Searching PDFs for: $pattern${NC}\n"
    find "$target" -name "*.pdf" -print0 2>/dev/null | while IFS= read -r -d '' f; do
        local matches=$(extract_text "$f" 2>/dev/null | grep -ic "$pattern" || echo 0)
        [[ "$matches" -gt 0 ]] && echo -e "  ${GREEN}✓${NC} $f ($matches matches)"
    done
}

show_help() {
    echo -e "${CYAN}BR PDF Read${NC}"
    echo "  br pdf read <file>          Extract all text"
    echo "  br pdf summary <file>       Show page count + preview"  
    echo "  br pdf search <pat> [dir]   Search PDFs for pattern"
}

case "$CMD" in
    read)    cmd_read ;;
    summary) cmd_summary ;;
    search)  cmd_search ;;
    *)       show_help ;;
esac
