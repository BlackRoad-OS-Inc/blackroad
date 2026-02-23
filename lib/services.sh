#!/bin/bash
#===============================================================================
# lib/services.sh — Service connectivity checks for all BlackRoad platforms
#===============================================================================

_SVC_LIB="${BR_LIB:-/Users/alexa/blackroad/lib}"
[[ -z "$_BR_COLORS_LOADED" ]] && source "${_SVC_LIB}/colors.sh" && _BR_COLORS_LOADED=1
[[ -z "$_BR_SYSTEM_LOADED" ]] && source "${_SVC_LIB}/system.sh" && _BR_SYSTEM_LOADED=1

#-------------------------------------------------------------------------------
# Ollama
#-------------------------------------------------------------------------------
svc_ollama_status() {
    if check_ollama; then
        local count
        count=$(curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null | jq '.models | length' 2>/dev/null)
        echo "up:${count:-0} models"
    else
        echo "down:not running"
    fi
}

svc_ollama_models() {
    curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' 2>/dev/null
}

#-------------------------------------------------------------------------------
# Claude Code
#-------------------------------------------------------------------------------
svc_claude_status() {
    if command -v claude &>/dev/null; then
        local ver
        ver=$(claude --version 2>/dev/null | head -1)
        echo "up:${ver}"
    else
        echo "down:not installed"
    fi
}

#-------------------------------------------------------------------------------
# GitHub
#-------------------------------------------------------------------------------
svc_github_status() {
    if command -v gh &>/dev/null; then
        if gh auth status &>/dev/null; then
            local org_count
            org_count=$(gh api user/orgs --jq 'length' 2>/dev/null)
            echo "up:${org_count:-0} orgs"
        else
            echo "warn:not authenticated"
        fi
    else
        echo "down:gh not installed"
    fi
}

svc_github_orgs() {
    gh api user/orgs --jq '.[].login' 2>/dev/null
}

#-------------------------------------------------------------------------------
# GitHub Copilot
#-------------------------------------------------------------------------------
svc_copilot_status() {
    if command -v gh &>/dev/null && gh copilot --version &>/dev/null 2>&1; then
        echo "up:active"
    else
        echo "down:not installed"
    fi
}

#-------------------------------------------------------------------------------
# Hugging Face
#-------------------------------------------------------------------------------
svc_huggingface_status() {
    local hf_ver
    hf_ver=$(python3 -c "import huggingface_hub; print(huggingface_hub.__version__)" 2>/dev/null)
    if [[ -n "$hf_ver" ]]; then
        local user
        user=$(python3 -c "from huggingface_hub import HfApi; print(HfApi().whoami()['name'])" 2>/dev/null)
        if [[ -n "$user" ]]; then
            echo "up:${user} (${hf_ver})"
        else
            echo "warn:v${hf_ver} (no auth)"
        fi
    else
        echo "down:not installed"
    fi
}

#-------------------------------------------------------------------------------
# Cloudflare
#-------------------------------------------------------------------------------
svc_cloudflare_status() {
    if command -v wrangler &>/dev/null; then
        local ver
        ver=$(wrangler --version 2>/dev/null | awk '{print $NF}')
        echo "up:wrangler ${ver}"
    else
        echo "down:wrangler not installed"
    fi
}

#-------------------------------------------------------------------------------
# Railway
#-------------------------------------------------------------------------------
svc_railway_status() {
    if command -v railway &>/dev/null; then
        echo "up:CLI installed"
    else
        echo "down:not installed"
    fi
}

#-------------------------------------------------------------------------------
# Vercel
#-------------------------------------------------------------------------------
svc_vercel_status() {
    if command -v vercel &>/dev/null; then
        echo "up:CLI installed"
    else
        echo "down:not installed"
    fi
}

#-------------------------------------------------------------------------------
# Codex (local component index)
#-------------------------------------------------------------------------------
svc_codex_status() {
    local db="${HOME}/blackroad-codex/index/components.db"
    if [[ -f "$db" ]]; then
        local total
        total=$(sqlite3 "$db" "SELECT COUNT(*) FROM components;" 2>/dev/null)
        echo "up:${total:-0} components"
    else
        echo "down:not indexed"
    fi
}

svc_codex_breakdown() {
    local db="${HOME}/blackroad-codex/index/components.db"
    if [[ -f "$db" ]]; then
        sqlite3 "$db" "SELECT type, COUNT(*) FROM components GROUP BY type ORDER BY COUNT(*) DESC;" 2>/dev/null
    fi
}

#-------------------------------------------------------------------------------
# Memory system
#-------------------------------------------------------------------------------
svc_memory_status() {
    local journal="${HOME}/.blackroad/memory/journals/master-journal.jsonl"
    if [[ -f "$journal" ]]; then
        local count
        count=$(wc -l < "$journal" 2>/dev/null | tr -d ' ')
        echo "up:${count} entries"
    else
        echo "down:no journal"
    fi
}

svc_memory_tasks() {
    local completed available
    completed=$(ls "${HOME}/.blackroad/memory/tasks/completed/" 2>/dev/null | wc -l | tr -d ' ')
    available=$(ls "${HOME}/.blackroad/memory/tasks/available/" 2>/dev/null | wc -l | tr -d ' ')
    echo "${completed}:${available}"
}

#-------------------------------------------------------------------------------
# Traffic lights
#-------------------------------------------------------------------------------
svc_traffic_lights() {
    local db="${HOME}/.blackroad-traffic-light.db"
    if [[ -f "$db" ]]; then
        local green yellow red
        green=$(sqlite3 "$db" "SELECT COUNT(*) FROM projects WHERE status='green';" 2>/dev/null)
        yellow=$(sqlite3 "$db" "SELECT COUNT(*) FROM projects WHERE status='yellow';" 2>/dev/null)
        red=$(sqlite3 "$db" "SELECT COUNT(*) FROM projects WHERE status='red';" 2>/dev/null)
        echo "${green:-0}:${yellow:-0}:${red:-0}"
    else
        echo "0:0:0"
    fi
}

#-------------------------------------------------------------------------------
# Format helpers
#-------------------------------------------------------------------------------
# Parse "status:detail" format and return icon + colored text
svc_format() {
    local result="$1"
    local max_detail_len="${2:-30}"
    local svc_st="${result%%:*}"
    local detail="${result#*:}"

    # Truncate detail if needed
    if (( ${#detail} > max_detail_len )); then
        detail="${detail:0:$((max_detail_len-2))}.."
    fi

    case "$svc_st" in
        up)   echo -e "${BGREEN}✓${NC} ${detail}" ;;
        warn) echo -e "${BYELLOW}○${NC} ${detail}" ;;
        down) echo -e "${DIM}✗ ${detail}${NC}" ;;
        *)    echo -e "${DIM}? ${detail}${NC}" ;;
    esac
}

# Format a number with commas (K/M abbreviation)
fmt_num() {
    local n=$1
    if (( n >= 1000000 )); then
        printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc)"
    elif (( n >= 1000 )); then
        printf "%.1fK" "$(echo "scale=1; $n/1000" | bc)"
    else
        echo "$n"
    fi
}
