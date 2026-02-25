#!/bin/bash

agent="$1"
msg="$2"

# ---------- PURE BASH LOCK (macOS SAFE) ----------
LOCKDIR="/tmp/br-voice.lockdir"
while ! mkdir "$LOCKDIR" 2>/dev/null; do
  sleep 0.05
done
trap 'rmdir "$LOCKDIR"' EXIT

# ---------- GLOBAL MUTE ----------
if [ "${BR_VOICE_MUTE:-}" = "1" ] || [ "${BR_VOICE_MUTE:-}" = "true" ]; then
  exit 0
fi

# ---------- FALLBACK VOICE SELECTION ----------
default_voice_for_agent() {
  local agent_name="$1"
  local voices=(Samantha Daniel Karen Moira Tessa Fred Fiona Alex)
  local checksum
  local idx

  checksum="$(printf '%s' "$agent_name" | cksum | awk '{print $1}')"
  idx=$((checksum % ${#voices[@]}))
  printf '%s' "${voices[$idx]}"
}

# ---------- AGENT → VOICE MAP (SAFE VOICES ONLY) ----------
case "$agent" in
  SYSTEM)     voice="Samantha" ;;  # calm
  INFO)       voice="Samantha" ;;
  PLANNER)    voice="Daniel" ;;    # analytical
  PIPELINE)   voice="Daniel" ;;
  SYNTH)      voice="Moira" ;;     # creative
  MEMORY)     voice="Karen" ;;     # archival
  ARBITER)    voice="Fred" ;;      # authoritative
  RISK)       voice="Tessa" ;;     # sharp
  ALERT)      voice="Tessa" ;;
  WATCHDOG)   voice="Tessa" ;;
  *)          voice="$(default_voice_for_agent "$agent")" ;;
esac

# ---------- SPEAK ----------
/usr/bin/say -v "$voice" "$msg"
