#!/bin/bash
source "$(dirname "$0")/ui.sh"

agent="$1"
type="$2"
msg="$3"

case "$agent" in
  SYSTEM)   br_agent_system "$msg" ;;
  INFO)     br_agent_info "$msg" ;;
  PIPELINE) br_agent_pipeline "$msg" ;;
  ARBITER)
    if [[ "$type" == "think" ]]; then
      br_agent_arbiter_typed "$msg"
    else
      br_agent_arbiter "$msg"
    fi
    ;;
  *)
    br_box 245 "$agent" "$msg"
    ;;
esac
