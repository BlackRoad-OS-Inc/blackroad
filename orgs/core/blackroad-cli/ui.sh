# ===== BLACKROAD UI LIB =====

br_fg() { printf "\033[38;5;%sm" "$1"; }
br_reset() { printf "\033[0m"; }

br_box() {
  local c="$1" title="$2" body="$3"
  local w=${#body}
  (( ${#title} > w )) && w=${#title}
  w=$((w + 2))

  local lp=$(( (w - ${#title}) / 2 ))
  local rp=$(( w - ${#title} - lp ))

  br_fg "$c"
  printf "┌%*s%s%*s┐\n" "$lp" "" "$title" "$rp" ""
  printf "│ %-*s │\n" "$w" "$body"
  printf "└%*s┘\n" "$w" ""
  br_reset
}

br_diamond() {
  br_fg "$1"
  cat <<'EOF2'
      ▲
     ╱ ╲
    ╱   ╲
    ╲   ╱
     ╲ ╱
      ▼
EOF2
  br_reset
}

# ---- AGENTS ----
br_agent_system()   { br_box 252 "SYSTEM"   "$1"; }
br_agent_info()     { br_box 244 "INFO"     "$1"; }
br_agent_pipeline() { br_box 252 "PIPELINE" "$1"; }
br_agent_arbiter()  { br_box 252 "ARBITER"  "$1"; br_diamond 198; }

br_agent_arbiter_typed() {
  br_box 252 "ARBITER" ""
  printf "\033[38;5;198m%s\033[0m\n" "$1"
  br_diamond 198
}
