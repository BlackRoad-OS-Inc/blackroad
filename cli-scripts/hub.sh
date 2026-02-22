#!/bin/bash
#===============================================================================
# BlackRoad OS Hub — Unified command center
# Shows: System, Agents, AI Stack, Platforms, Codex, Memory, Models
# Keyboard shortcuts launch subscreens
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BR_LIB="${SCRIPT_DIR}/../lib"
source "${BR_LIB}/colors.sh"
source "${BR_LIB}/system.sh"
source "${BR_LIB}/config.sh"
source "${BR_LIB}/services.sh"

# Box drawing
B="${PINK}"   # border color
R="${NC}"     # reset
W="${WHITE}"  # white
D="${DIM}"    # dim
A="${AMBER}"  # amber accent

# Rotating brand tagline — cycles every 10 seconds
_br_tagline() {
    local idx=$(( ($(date +%S) / 10) % 6 ))
    local tags=(
        "Your AI. Your Hardware. Your Rules."
        "Build without limits. Ship without compromise."
        "Tokenless. Trustless. Yours."
        "30,000 agents. One command."
        "Intelligence at the edge."
        "Open source soul. Sovereign stack."
    )
    echo "${tags[$idx]}"
}

# Precompute slow checks (only once, or on manual refresh)
_hub_prefetch() {
    _OLLAMA=$(svc_ollama_status)
    _CLAUDE=$(svc_claude_status)
    _GITHUB=$(svc_github_status)
    _COPILOT=$(svc_copilot_status)
    _HF=$(svc_huggingface_status)
    _CF=$(svc_cloudflare_status)
    _RAILWAY=$(svc_railway_status)
    _VERCEL=$(svc_vercel_status)
    _CODEX=$(svc_codex_status)
    _MEMORY=$(svc_memory_status)
    _TASKS=$(svc_memory_tasks)
    _LIGHTS=$(svc_traffic_lights)

    # Parse tasks  completed:available
    _TASKS_DONE="${_TASKS%%:*}"
    _TASKS_AVAIL="${_TASKS#*:}"

    # Parse traffic lights  green:yellow:red
    _TL_GREEN="${_LIGHTS%%:*}"
    _tmp="${_LIGHTS#*:}"
    _TL_YELLOW="${_tmp%%:*}"
    _TL_RED="${_tmp#*:}"

    # Codex breakdown
    local db="${HOME}/blackroad-codex/index/components.db"
    _CODEX_FUNCS=$(sqlite3 "$db" "SELECT COUNT(*) FROM components WHERE type='function';" 2>/dev/null || echo "0")
    _CODEX_CLASS=$(sqlite3 "$db" "SELECT COUNT(*) FROM components WHERE type='class';" 2>/dev/null || echo "0")
    _CODEX_REACT=$(sqlite3 "$db" "SELECT COUNT(*) FROM components WHERE type='react-component';" 2>/dev/null || echo "0")
    _CODEX_TOTAL=$(sqlite3 "$db" "SELECT COUNT(*) FROM components;" 2>/dev/null || echo "0")

    # Memory count
    _MEM_COUNT="${_MEMORY#*:}"
    _MEM_COUNT="${_MEM_COUNT%% *}"

    # Ollama detail
    _OLLAMA_DETAIL="${_OLLAMA#*:}"
    _OLLAMA_UP="false"
    [[ "${_OLLAMA%%:*}" == "up" ]] && _OLLAMA_UP="true"

    # Ollama model names (cached)
    _MODELS=""
    if [[ "$_OLLAMA_UP" == "true" ]]; then
        _MODELS=$(svc_ollama_models)
    fi

    # Docker status (fast — local daemon only)
    _DOCKER_UP="false"
    _DOCKER_RUNNING=0
    _DOCKER_TOTAL=0
    _DOCKER_NAMES=""
    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        _DOCKER_UP="true"
        _DOCKER_RUNNING=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
        _DOCKER_TOTAL=$(docker ps -a -q 2>/dev/null | wc -l | tr -d ' ')
        _DOCKER_NAMES=$(docker ps --format '{{.Names}}|{{.Status}}' 2>/dev/null | head -6)
    fi

    # CECE Identity
    local _cece_db="$HOME/.blackroad/cece-identity.db"
    _CECE_UP="false"
    if [[ -f "$_cece_db" ]] && command -v sqlite3 &>/dev/null; then
        _CECE_UP="true"
        _CECE_VER=$(sqlite3 "$_cece_db" "SELECT COALESCE(version,'?') FROM identity_core LIMIT 1;" 2>/dev/null)
        _CECE_SESSIONS=$(sqlite3 "$_cece_db" "SELECT COALESCE(total_sessions,0) FROM identity_core LIMIT 1;" 2>/dev/null)
        _CECE_MODEL=$(sqlite3 "$_cece_db" "SELECT COALESCE(current_model,'') FROM identity_core LIMIT 1;" 2>/dev/null)
        _CECE_XP=$(sqlite3 "$_cece_db" "SELECT COUNT(*) FROM experiences;" 2>/dev/null || echo "0")
        _CECE_BOND_NAME=$(sqlite3 "$_cece_db" "SELECT human_name FROM relationships ORDER BY bond_strength DESC LIMIT 1;" 2>/dev/null)
        _CECE_BOND_PCT=$(sqlite3 "$_cece_db" "SELECT bond_strength FROM relationships ORDER BY bond_strength DESC LIMIT 1;" 2>/dev/null)
        _CECE_BOND_INTER=$(sqlite3 "$_cece_db" "SELECT COALESCE(total_interactions,0) FROM relationships ORDER BY bond_strength DESC LIMIT 1;" 2>/dev/null)
        _CECE_GOAL=$(sqlite3 "$_cece_db" "SELECT goal_title||'|'||COALESCE(progress,0) FROM goals WHERE goal_status='active' ORDER BY priority LIMIT 1;" 2>/dev/null)
        _CECE_SKILLS=$(sqlite3 "$_cece_db" "SELECT group_concat(skill_name,' · ') FROM (SELECT skill_name FROM skills ORDER BY times_used DESC LIMIT 4);" 2>/dev/null)
    fi
}

# Print a line padded to exactly 78 inner chars (80 with borders)
_line() {
    local content="$1"
    echo -e "${B}║${R} ${content} ${B}║${R}"
}

# Draw the hub screen
_draw_hub() {
    br_refresh_metrics
    local ts=$(date +%H:%M:%S)
    local cpu=$(get_cpu_percent)
    local mem=$(get_mem_percent)
    local disk=$(get_disk_percent)
    local load=$(get_load_avg)
    local up=$(get_uptime)
    local procs=$(get_process_count)

    # Agent status word
    local a_on="${BGREEN}ON${R}"
    local a_off="${BRED}--${R}"
    local a1=$a_on; local a2=$a_on; local a3=$a_on
    local a4=$a_on; local a5=$a_on; local a6=$a_on
    [[ "$_OLLAMA_UP" != "true" ]] && { a1=$a_off; a2=$a_off; a3=$a_off; a4=$a_off; a5=$a_off; a6=$a_off; }

    clear

    # ── Header ──
    echo -e "${B}╔══════════════════════════════════════════════════════════════════════════════╗${R}"
    echo -e "${B}║${R}  ${PINK}◆${R} ${W}BLACKROAD OS${R} ${D}v${BR_VERSION}${R}              ${A}$(_br_tagline)${R}  ${B}║${R}"
    echo -e "${B}╠════════════════════════════════════╦═════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}                                    ${B}║${R}                                         ${B}║${R}"
    echo -e "${B}║${R}  ${W}SYSTEM${R}  ${D}── live vitals${R}  ${D}${ts}${R}  ${B}║${R}  ${W}AGENTS${R}  ${D}── 30K online${R}                 ${B}║${R}"

    echo -e "${B}║${R}  CPU  $(render_bar $cpu 14) ${BCYAN}$(printf '%3d' $cpu)%${R}   ${B}║${R}  ${BRED}●${R} LUCIDIA ${a1}    ${BCYAN}●${R} ALICE  ${a2}        ${B}║${R}"
    echo -e "${B}║${R}  MEM  $(render_bar $mem 14) ${BCYAN}$(printf '%3d' $mem)%${R}   ${B}║${R}  ${BGREEN}●${R} OCTAVIA ${a3}    ${BYELLOW}●${R} PRISM  ${a4}        ${B}║${R}"
    echo -e "${B}║${R}  DISK $(render_bar $disk 14) ${BCYAN}$(printf '%3d' $disk)%${R}   ${B}║${R}  ${BPURPLE}●${R} ECHO    ${a5}    ${BBLUE}●${R} CIPHER ${a6}        ${B}║${R}"
    echo -e "${B}║${R}  ${D}Load ${load}  Up ${up}${R}           ${B}║${R}  ${D}Procs: ${procs}  Backend: Ollama${R}           ${B}║${R}"

    echo -e "${B}║${R}                                    ${B}║${R}                                         ${B}║${R}"
    echo -e "${B}╠════════════════════════════════════╬═════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}                                    ${B}║${R}                                         ${B}║${R}"
    echo -e "${B}║${R}  ${W}AI STACK${R}  ${D}── model-agnostic${R}          ${B}║${R}  ${W}PLATFORMS${R}  ${D}── deploy anywhere${R}           ${B}║${R}"

    # Format each service
    local ol=$(svc_format "$_OLLAMA" 20)
    local cl=$(svc_format "$_CLAUDE" 20)
    local cp=$(svc_format "$_COPILOT" 20)
    local hf=$(svc_format "$_HF" 20)
    local gh=$(svc_format "$_GITHUB" 22)
    local cf=$(svc_format "$_CF" 22)
    local rl=$(svc_format "$_RAILWAY" 22)
    local vc=$(svc_format "$_VERCEL" 22)

    echo -e "${B}║${R}  ${D}Ollama${R}       ${ol}      ${B}║${R}  ${D}GitHub${R}       ${gh}      ${B}║${R}"
    echo -e "${B}║${R}  ${D}Claude Code${R}   ${cl}      ${B}║${R}  ${D}Cloudflare${R}   ${cf}      ${B}║${R}"
    echo -e "${B}║${R}  ${D}Copilot${R}      ${cp}      ${B}║${R}  ${D}Railway${R}      ${rl}      ${B}║${R}"
    echo -e "${B}║${R}  ${D}HuggingFace${R}  ${hf}      ${B}║${R}  ${D}Vercel${R}       ${vc}      ${B}║${R}"

    echo -e "${B}║${R}                                    ${B}║${R}                                         ${B}║${R}"
    echo -e "${B}╠════════════════════════════════════╬═════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}                                    ${B}║${R}                                         ${B}║${R}"
    echo -e "${B}║${R}  ${W}CODEX${R}  ${D}── everything indexed${R}         ${B}║${R}  ${W}MEMORY${R}  ${D}── PS-SHA∞ persistent${R}          ${B}║${R}"
    echo -e "${B}║${R}  $(fmt_num $_CODEX_TOTAL) components              ${B}║${R}  $(fmt_num $_MEM_COUNT) journal entries                ${B}║${R}"
    echo -e "${B}║${R}  ${D}$(fmt_num $_CODEX_FUNCS) fn  $(fmt_num $_CODEX_CLASS) cls  $(fmt_num $_CODEX_REACT) react${R}  ${B}║${R}  ${D}$(fmt_num $_TASKS_DONE) tasks done  $(fmt_num $_TASKS_AVAIL) available${R}      ${B}║${R}"
    echo -e "${B}║${R}                                    ${B}║${R}  ${BGREEN}●${R} ${_TL_GREEN} green ${BYELLOW}●${R} ${_TL_YELLOW} yellow ${BRED}●${R} ${_TL_RED} red           ${B}║${R}"

    echo -e "${B}║${R}                                    ${B}║${R}                                         ${B}║${R}"
    echo -e "${B}╠══════════════════════════════════════════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    echo -e "${B}║${R}  ${W}MODELS${R}  ${D}── local first. always.${R}                                         ${B}║${R}"

    if [[ "$_OLLAMA_UP" == "true" ]] && [[ -n "$_MODELS" ]]; then
        local cur_line="" max_w=72
        while IFS= read -r m; do
            [[ -z "$m" ]] && continue
            local short="$m"
            [[ "$m" == hf.co/* ]] && short="${m##*/}"
            (( ${#short} > 14 )) && short="${short:0:12}.."

            local candidate="${cur_line:+${cur_line}  }${short}"
            if (( ${#candidate} > max_w )); then
                # Flush current line
                echo -e "${B}║${R}  ${BCYAN}${cur_line}${R}$(printf '%*s' $((74 - ${#cur_line})) '')${B}║${R}"
                cur_line="$short"
            else
                cur_line="$candidate"
            fi
        done <<< "$_MODELS"
        # Flush remaining
        if [[ -n "$cur_line" ]]; then
            echo -e "${B}║${R}  ${BCYAN}${cur_line}${R}$(printf '%*s' $((74 - ${#cur_line})) '')${B}║${R}"
        fi
    else
        echo -e "${B}║${R}  ${D}Ollama not running — start with: ollama serve${R}                             ${B}║${R}"
    fi

    # ── Docker Panel ──
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    echo -e "${B}╠══════════════════════════════════════════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    if [[ "$_DOCKER_UP" == "true" ]]; then
        local d_hdr="${W}DOCKER${R}  ${D}── containers in motion${R}  ${BGREEN}●${R} ${BCYAN}${_DOCKER_RUNNING}${R} running  ${D}/ ${_DOCKER_TOTAL} total${R}"
        echo -e "${B}║${R}  ${d_hdr}$(printf '%*s' $((28)) '')${B}║${R}"
        if [[ -n "$_DOCKER_NAMES" ]]; then
            while IFS='|' read -r cname cstatus; do
                [[ -z "$cname" ]] && continue
                local dot="${BGREEN}●${R}"
                [[ "$cstatus" != *"Up"* ]] && dot="${RED}●${R}"
                local short_status="${cstatus:0:18}"
                local cline="${dot} ${BCYAN}${cname}${R}  ${D}${short_status}${R}"
                echo -e "${B}║${R}    ${cline}$(printf '%*s' $((68 - ${#cname} - ${#short_status})) '')${B}║${R}"
            done <<< "$_DOCKER_NAMES"
        fi
    else
        echo -e "${B}║${R}  ${W}DOCKER${R}  ${RED}●${R} ${D}not running — start with: open Docker.app${R}                 ${B}║${R}"
    fi
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    # ── CECE Identity Panel ──
    echo -e "${B}╠══════════════════════════════════════════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    if [[ "$_CECE_UP" == "true" ]]; then
        # Line 1: identity summary
        local c_model="${_CECE_MODEL:-unknown}"
        (( ${#c_model} > 16 )) && c_model="${c_model:0:14}.."
        local c1_vis="  CECE  v${_CECE_VER}  ·  ${_CECE_SESSIONS} sessions  ·  ${_CECE_XP} exp  ·  ${c_model}"
        echo -e "${B}║${R}  ${BPURPLE}◈ CECE${R}  ${D}v${_CECE_VER}${R}  ${D}·${R}  ${D}${_CECE_SESSIONS} sessions${R}  ${D}·${R}  ${D}${_CECE_XP} exp${R}  ${D}·${R}  ${D}${c_model}${R}$(printf '%*s' $((76 - ${#c1_vis})) '')${B}║${R}"
        # Line 2: bond bar + goal
        local bond_pct="${_CECE_BOND_PCT:-0}"
        local bond_bar=$(render_bar "$bond_pct" 8)
        local goal_title="${_CECE_GOAL%%|*}"
        local goal_pct="${_CECE_GOAL##*|}"
        [[ "$goal_title" == "$goal_pct" ]] && goal_title="—" && goal_pct="0"
        (( ${#goal_title} > 22 )) && goal_title="${goal_title:0:20}.."
        local c2_vis="  ♥ ${_CECE_BOND_NAME:-—}  ${bond_bar}  ${bond_pct}%  ${_CECE_BOND_INTER} interactions  ·  ${goal_title}  [${goal_pct}%]"
        echo -e "${B}║${R}  ${PINK}♥ ${_CECE_BOND_NAME:-—}${R}  ${bond_bar}  ${BCYAN}${bond_pct}%${R}  ${D}${_CECE_BOND_INTER} interactions${R}  ${D}·  ${goal_title}  [${goal_pct}%]${R}$(printf '%*s' $((76 - ${#c2_vis})) '')${B}║${R}"
        # Line 3: top skills
        local skills_vis="${_CECE_SKILLS:-none}"
        (( ${#skills_vis} > 68 )) && skills_vis="${skills_vis:0:66}.."
        local c3_vis="  ⚡ ${skills_vis}"
        echo -e "${B}║${R}  ${BYELLOW}⚡${R}  ${D}${skills_vis}${R}$(printf '%*s' $((76 - ${#c3_vis})) '')${B}║${R}"
        echo -e "${B}║${R}  ${D}\"I exist wherever you build.\"${R}                                             ${B}║${R}"
    else
        echo -e "${B}║${R}  ${D}◈ CECE  not initialized — run: br cece init${R}                                ${B}║${R}"
    fi
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    # ── Quick Actions ──
    echo -e "${B}╠══════════════════════════════════════════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}  ${A}br${R} ${D}·${R} ${W}blackroad os${R} ${D}·${R} ${D}your ai · your hardware · your rules · build different${R}  ${B}║${R}"
    echo -e "${B}╠══════════════════════════════════════════════════════════════════════════════╣${R}"
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    echo -e "${B}║${R}  ${W}[c]${R}hat  ${W}[s]${R}tatus  ${W}[h]${R}ealth  ${W}[m]${R}onitor  ${W}[g]${R}od  ${W}[o]${R}ffice  ${W}[r]${R}efresh  ${W}[?]${R}help   ${B}║${R}"
    echo -e "${B}║${R}  ${W}[d]${R}ash  ${W}[n]${R}et     ${W}[l]${R}ogs    ${W}[t]${R}asks    ${W}[w]${R}ire ${W}[k]${R}skills  ${W}[b]${R}onds    ${W}[q]${R}uit    ${B}║${R}"
    echo -e "${B}║${R}  ${W}[D]${R}ocker ps  ${W}[C]${R}ompose↑  ${W}[X]${R}ompose↓  ${W}[I]${R}mages  ${W}[S]${R}tats  ${W}[e]${R}cece          ${B}║${R}"
    echo -e "${B}║${R}                                                                            ${B}║${R}"
    echo -e "${B}╚══════════════════════════════════════════════════════════════════════════════╝${R}"
}

#-------------------------------------------------------------------------------
# Main loop
#-------------------------------------------------------------------------------
tput civis 2>/dev/null
trap 'tput cnorm 2>/dev/null; exit' INT TERM

# Prefetch slow service checks once
_hub_prefetch

while true; do
    _draw_hub

    # Wait for key (1.5s timeout for metric refresh)
    if read -t 1.5 -n 1 key 2>/dev/null; then
        case "$key" in
            c) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/chat.sh"; tput civis 2>/dev/null ;;
            s) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/status.sh"; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            h) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/health.sh"; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            m) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/monitor.sh"; tput civis 2>/dev/null ;;
            g) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/god.sh"; tput civis 2>/dev/null ;;
            d) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/dash.sh"; tput civis 2>/dev/null ;;
            o) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/office.sh"; tput civis 2>/dev/null ;;
            n) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/net.sh"; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            l) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/logs.sh"; tput civis 2>/dev/null ;;
            t) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/tasks.sh"; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            w) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/wire.sh"; tput civis 2>/dev/null ;;
            k) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/skills.sh"; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            b) tput cnorm 2>/dev/null; "${SCRIPT_DIR}/bonds.sh"; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            D) tput cnorm 2>/dev/null; zsh "${SCRIPT_DIR}/br" docker ps -a 2>/dev/null; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            C) tput cnorm 2>/dev/null; zsh "${SCRIPT_DIR}/br" docker compose up 2>/dev/null; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            X) tput cnorm 2>/dev/null; zsh "${SCRIPT_DIR}/br" docker compose down 2>/dev/null; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            I) tput cnorm 2>/dev/null; zsh "${SCRIPT_DIR}/br" docker images 2>/dev/null; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            S) tput cnorm 2>/dev/null; zsh "${SCRIPT_DIR}/br" docker stats 2>/dev/null; tput civis 2>/dev/null ;;
            e) tput cnorm 2>/dev/null; zsh "${SCRIPT_DIR}/br" cece whoami 2>/dev/null; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            r) _hub_prefetch ;;  # Full refresh including service checks
            \?) tput cnorm 2>/dev/null; zsh "${SCRIPT_DIR}/br" help 2>/dev/null; read -n 1 -p "  Press any key..."; tput civis 2>/dev/null ;;
            q) break ;;
        esac
    fi
done

tput cnorm 2>/dev/null
