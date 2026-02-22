# ══════════════════════════════════════════════════════════════════════════════
# BlackRoad λ-Prompt v0.5 "Next Level"
# An OS within the OS – Neon-branded shell prompt for BlackRoad OS
# ══════════════════════════════════════════════════════════════════════════════

# ── Brand Palette (official BlackRoad OS, Inc.) ──
BR_AMBER="#F5A623"        # amber
BR_HOT_PINK="#FF1D6C"     # hot-pink (primary)
BR_ELECTRIC_BLUE="#2979FF"
BR_VIOLET="#9C27B0"
BR_WHITE="#FFFFFF"
BR_RESET="\e[0m"

# ── Helper: 24-bit RGB color ──
_br_rgb() {
  printf '\e[38;2;%d;%d;%dm' "$(($1>>16))" "$((($1>>8)&255))" "$(($1&255))"
}

# ── Exit Code Indicator (💚 success / 🔥 failure) ──
_br_prompt_status() {
  local code="$?"
  if [[ $code -eq 0 ]]; then
    printf "%s💚%s" "$(_br_rgb 0x${BR_ELECTRIC_BLUE#\#})" "$BR_RESET"
  else
    printf "%s🔥%s" "$(_br_rgb 0x${BR_HOT_PINK#\#})" "$BR_RESET"
  fi
}

# ── Git Branch + dirty state + ahead/behind ──
_br_git_branch() {
  command -v git >/dev/null || return
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return

  # Dirty state
  local dirty=""
  git diff --quiet 2>/dev/null || dirty=" ${BR_RESET}\e[38;2;255;100;50m✗${BR_RESET}"

  # Ahead / behind (only if remote tracking exists)
  local ab=""
  local counts
  counts=$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null) && {
    local behind=${counts%$'\t'*}
    local ahead=${counts##*$'\t'}
    [[ "$ahead" -gt 0 ]]  && ab+=" \e[38;2;80;200;80m↑${ahead}${BR_RESET}"
    [[ "$behind" -gt 0 ]] && ab+=" \e[38;2;255;100;50m↓${behind}${BR_RESET}"
  }

  printf " %s🌿 %s%s%s%s" "$(_br_rgb 0x${BR_VIOLET#\#})" "$branch" "$dirty" "$ab" "$BR_RESET"
}

# ── Timestamp (🕒 HH:MM) ──
_br_timestamp() {
  printf "%s🕒 %s%s" "\e[2m" "$(date +%H:%M)" "$BR_RESET"
}

# ── Current Directory (with ~ shortening) ──
_br_cwd() {
  local cwd="${PWD/#$HOME/\~}"
  printf "%s%s%s" "$(_br_rgb 0x${BR_AMBER#\#})" "$cwd" "$BR_RESET"
}

# ── Python Virtual Env ──
_br_venv() {
  [[ -n "$VIRTUAL_ENV" ]] || return
  local venv_name=$(basename "$VIRTUAL_ENV")
  printf " %s(venv:%s)%s" "$(_br_rgb 0x${BR_VIOLET#\#})" "$venv_name" "$BR_RESET"
}

# ── Trinary Sigil ──
_br_trinary() {
  printf "%sλ%s" "$(_br_rgb 0x${BR_AMBER#\#})" "$BR_RESET"
}

# ── Build PS1 ──
_blackroad_ps1() {
  # Top line: status | trinary | time | git | venv | cwd
  local line1="$(_br_prompt_status)  $(_br_trinary) $(_br_timestamp)$(_br_git_branch)$(_br_venv) $(_br_cwd)"

  # Bottom line: bold prompt
  local line2="\e[1m❯%s" "$BR_RESET"

  PS1="\n${line1}\n${line2} "
}

# ── Hook into Zsh prompt ──
precmd_functions+=(_blackroad_ps1)

# ── Welcome Message ──
echo ""
echo "$(_br_rgb 0x${BR_AMBER#\#})╔════════════════════════════════════════════╗${BR_RESET}"
echo "$(_br_rgb 0x${BR_AMBER#\#})║${BR_RESET}  🚗 BlackRoad Terminal OS v0.5          $(_br_rgb 0x${BR_AMBER#\#})║${BR_RESET}"
echo "$(_br_rgb 0x${BR_AMBER#\#})║${BR_RESET}  OS within the OS — Next Level          $(_br_rgb 0x${BR_AMBER#\#})║${BR_RESET}"
echo "$(_br_rgb 0x${BR_AMBER#\#})╚════════════════════════════════════════════╝${BR_RESET}"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# End BlackRoad λ-Prompt v0.4
# ══════════════════════════════════════════════════════════════════════════════
