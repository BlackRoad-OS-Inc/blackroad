#!/bin/zsh
# BR Note - Quick Developer Notes
NOTE_HOME="/Users/alexa/blackroad/tools/quick-notes"
NOTES_FILE="${NOTE_HOME}/notes.md"
AMBER='\033[38;5;214m'; PINK='\033[38;5;205m'; VIOLET='\033[38;5;135m'; BBLUE='\033[38;5;69m'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
CYAN="$AMBER"; YELLOW="$PINK"; BLUE="$BBLUE"; PURPLE="$VIOLET"; MAGENTA="$VIOLET"

mkdir -p "$NOTE_HOME"
[[ ! -f "$NOTES_FILE" ]] && echo "# Developer Notes\n" > "$NOTES_FILE"

add_note() {
    local note="$*"
    if [[ -z "$note" ]]; then
        echo -e "  ${AMBER}${BOLD}◆ BR NOTE${NC}  ${DIM}add${NC}\n  ${DIM}──────────────────────────────${NC}"
        echo -e "  ${DIM}Enter note (Ctrl+D when done):${NC}"
        note=$(cat)
    fi
    echo "\n## $(date '+%Y-%m-%d %H:%M')\n$note\n" >> "$NOTES_FILE"
    echo -e "  ${GREEN}✓${NC} note saved"
}

list_notes() {
    echo -e "  ${AMBER}${BOLD}◆ BR NOTE${NC}  ${DIM}recent${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    tail -50 "$NOTES_FILE"
}

search_notes() {
    echo -e "  ${AMBER}${BOLD}◆ BR NOTE${NC}  ${DIM}search: $1${NC}"
    echo -e "  ${DIM}──────────────────────────────${NC}\n"
    grep -i "$1" "$NOTES_FILE" --color=always
}

show_help() {
    echo -e "  ${AMBER}${BOLD}◆ BR NOTE${NC}  quick developer notes\n"
    echo -e "  ${AMBER}br note add <text>${NC}     add a note"
    echo -e "  ${AMBER}br note list${NC}           recent notes"
    echo -e "  ${AMBER}br note search <term>${NC}  search notes"
    echo -e "  ${AMBER}br note edit${NC}           open in editor"
}

case ${1:-list} in
    add|a) shift; add_note "$@" ;;
    list|l|ls|"") list_notes ;;
    search|s) search_notes "$2" ;;
    edit|e) ${EDITOR:-nano} "$NOTES_FILE" ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
