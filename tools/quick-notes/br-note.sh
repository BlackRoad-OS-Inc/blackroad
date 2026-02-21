#!/bin/zsh
# BR Note - Quick Developer Notes
NOTE_HOME="/Users/alexa/blackroad/tools/quick-notes"
NOTES_FILE="${NOTE_HOME}/notes.md"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$NOTE_HOME"
[[ ! -f "$NOTES_FILE" ]] && echo "# Developer Notes\n" > "$NOTES_FILE"

add_note() {
    local note="$*"
    if [[ -z "$note" ]]; then
        echo -e "${YELLOW}Enter note (Ctrl+D when done):${NC}"
        note=$(cat)
    fi
    echo "\n## $(date '+%Y-%m-%d %H:%M')\n$note\n" >> "$NOTES_FILE"
    echo -e "${GREEN}✓ Note added${NC}"
}

list_notes() {
    echo -e "${CYAN}📝 Recent Notes:${NC}\n"
    tail -50 "$NOTES_FILE"
}

search_notes() {
    echo -e "${CYAN}🔍 Searching: $1${NC}\n"
    grep -i "$1" "$NOTES_FILE" --color=always
}

case ${1:-list} in
    add|a) shift; add_note "$@" ;;
    list|l|ls) list_notes ;;
    search|s) search_notes "$2" ;;
    edit|e) ${EDITOR:-nano} "$NOTES_FILE" ;;
    *) echo "Usage: br note {add|list|search|edit}" ;;
esac
