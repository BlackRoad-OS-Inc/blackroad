#!/bin/bash
#===============================================================================
# lib/errors.sh — Error handling for BR CLI scripts
#===============================================================================

# Resolve lib directory (works in both bash and zsh)
_ERRORS_LIB="${BR_LIB:-/Users/alexa/blackroad/lib}"
[[ -z "$_BR_COLORS_LOADED" ]] && source "${_ERRORS_LIB}/colors.sh" && _BR_COLORS_LOADED=1

# Error handler: prints file, line number, and command that failed
br_on_error() {
    local exit_code=$?
    local line_no=$1
    local script="${BASH_SOURCE[1]:-unknown}"
    script=$(basename "$script")
    echo -e "\n${BRED}ERROR${NC} in ${WHITE}${script}${NC} line ${BYELLOW}${line_no}${NC} (exit code ${exit_code})" >&2
}

# Set up ERR + EXIT traps for better error reporting
br_setup_traps() {
    # Only set traps if running in bash (not zsh which handles differently)
    if [[ -n "$BASH_VERSION" ]]; then
        trap 'br_on_error $LINENO' ERR
    fi
}

# Check that a command exists, with install hint
br_require() {
    local cmd="$1"
    local hint="${2:-}"
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${BRED}✗${NC} Required command not found: ${WHITE}${cmd}${NC}" >&2
        if [[ -n "$hint" ]]; then
            echo -e "  ${DIM}Install with: ${hint}${NC}" >&2
        fi
        return 1
    fi
}

# Require multiple commands
br_require_all() {
    local failed=0
    while [[ $# -ge 1 ]]; do
        local cmd="$1"
        local hint="${2:-}"
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${BRED}✗${NC} Missing: ${WHITE}${cmd}${NC}${hint:+ (${hint})}" >&2
            failed=1
        fi
        shift
        [[ $# -ge 1 && "$1" != "-"* ]] && shift  # skip hint if present
    done
    return $failed
}
