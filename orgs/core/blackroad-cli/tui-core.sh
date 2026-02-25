#!/usr/bin/env zsh
# Minimal TUI core for agent output and streaming.

tui_init() {
  local use_alt=0
  local out=''

  if [ "${TUI_INIT:-0}" -eq 1 ]; then
    return 0
  fi

  if [ "$1" = "--alt" ]; then
    use_alt=1
  fi

  if [ "$use_alt" -eq 1 ]; then
    TUI_ALT=1
    out="${out}\033[?1049h"
  else
    TUI_ALT=0
  fi

  TUI_INIT=1
  TUI_STREAM_ACTIVE=0
  TUI_STREAM_ID=''
  TUI_STREAM_PREFIX=''
  TUI_STREAM_TEXT=''

  out="${out}\033[?25l"
  printf '%s' "$out"
  trap 'tui_reset' INT TERM EXIT
}

tui_reset() {
  local out=''

  if [ "${TUI_ALT:-0}" -eq 1 ]; then
    out="${out}\033[?1049l"
  fi

  out="${out}\033[0m\033[?25h"

  TUI_INIT=0
  TUI_ALT=0
  TUI_STREAM_ACTIVE=0
  TUI_STREAM_ID=''
  TUI_STREAM_PREFIX=''
  TUI_STREAM_TEXT=''

  printf '%s' "$out"
}

tui_color() {
  local fg="$1"
  local bg="$2"

  if [ -n "$bg" ]; then
    printf '\033[38;5;%sm\033[48;5;%sm' "$fg" "$bg"
    return 0
  fi

  printf '\033[38;5;%sm' "$fg"
}

tui_color_reset() {
  printf '\033[0m'
}

tui_agent() {
  local id="$1"
  local msg="$2"
  local out=''

  if [ -z "$id" ]; then
    return 1
  fi

  if [ "${TUI_STREAM_ACTIVE:-0}" -eq 1 ]; then
    tui_stream_end
  fi

  out="[$id]"
  if [ -n "$msg" ]; then
    out="${out} ${msg}"
  fi
  out="${out}\n"

  printf '%s' "$out"
}

tui_type() {
  local id="$1"
  local text="$2"
  local delay="${TUI_TYPE_DELAY:-0.02}"
  local prefix=''
  local i=1
  local char=''

  if [ -z "$id" ]; then
    return 1
  fi

  if [ "${TUI_STREAM_ACTIVE:-0}" -eq 1 ]; then
    tui_stream_end
  fi

  prefix="[$id] "
  printf '%s' "$prefix"

  while :; do
    char="$(printf '%s' "$text" | cut -c "$i")"
    if [ -z "$char" ]; then
      break
    fi
    printf '%s' "$char"
    sleep "$delay"
    i=$((i + 1))
  done
}

tui_stream_begin() {
  local id="$1"
  local out=''

  if [ -z "$id" ]; then
    return 1
  fi

  if [ "${TUI_STREAM_ACTIVE:-0}" -eq 1 ]; then
    return 1
  fi

  TUI_STREAM_ACTIVE=1
  TUI_STREAM_ID="$id"
  TUI_STREAM_PREFIX="[$id] "
  TUI_STREAM_TEXT=''

  out="${TUI_STREAM_PREFIX}"
  printf '%s' "$out"
}

tui_stream_chunk() {
  local text="$1"
  local out=''

  if [ "${TUI_STREAM_ACTIVE:-0}" -ne 1 ]; then
    return 1
  fi

  TUI_STREAM_TEXT="$text"
  out="\r${TUI_STREAM_PREFIX}${TUI_STREAM_TEXT}\033[K"
  printf '%s' "$out"
}

tui_stream_end() {
  local out=''

  if [ "${TUI_STREAM_ACTIVE:-0}" -ne 1 ]; then
    return 1
  fi

  out="\r${TUI_STREAM_PREFIX}${TUI_STREAM_TEXT}\033[K\033[0m\n"

  TUI_STREAM_ACTIVE=0
  TUI_STREAM_ID=''
  TUI_STREAM_PREFIX=''
  TUI_STREAM_TEXT=''

  printf '%s' "$out"
}
