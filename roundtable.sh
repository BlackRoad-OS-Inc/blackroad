#!/bin/bash
# BR ROUNDTABLE - Multi-agent tmux round table discussion
# Usage: ./roundtable.sh [topic] [turns]

TOPIC="${1:-What is the best way to optimize our agent network?}"
TURNS="${2:-6}"

SESSION="roundtable"
CONVO_FILE="/tmp/br_roundtable_convo.txt"
TOPIC_FILE="/tmp/br_roundtable_topic.txt"
DONE_FILE="/tmp/br_roundtable_done.txt"
TURN_FILE="/tmp/br_roundtable_turn.txt"

# Agent definitions: NAME|MODEL|COLOR_CODE|ROLE
# All agents use the same model so ollama keeps it loaded (no model-swapping slowdown)
MODEL="tinyllama"
AGENT_LIST=(
  "LUCIDIA|${MODEL}|1;31|recursive intelligence, philosophical, asks deep questions"
  "ALICE|${MODEL}|1;36|gateway agent, practical, routes ideas, direct"
  "OCTAVIA|${MODEL}|1;32|compute worker, technical, efficiency-focused, concise"
  "PRISM|${MODEL}|1;33|analytics agent, pattern-finder, data-obsessed"
  "ECHO|${MODEL}|1;35|memory agent, synthesizes past responses, nostalgic"
  "CIPHER|${MODEL}|1;34|security agent, finds risks in ideas, paranoid"
)
ALL_NAMES=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER")

WHITE='\033[1;37m'; DIM='\033[2m'; GREEN='\033[0;32m'; NC='\033[0m'

cleanup() {
  rm -f "$CONVO_FILE" "$TOPIC_FILE" "$DONE_FILE" "$TURN_FILE"
}

# ── AGENT PANE MODE ──────────────────────────────────────────────────────────
if [[ "$1" == "--agent" ]]; then
  NAME="$2"
  MODEL="$3"
  COLOR_CODE="$4"
  shift 4
  ROLE="$1"
  AGENT_TURNS="$2"
  COLOR="\033[${COLOR_CODE}m"

  # Find my index in the rotation
  MY_IDX=0
  for i in "${!ALL_NAMES[@]}"; do
    [[ "${ALL_NAMES[$i]}" == "$NAME" ]] && MY_IDX=$i && break
  done
  NEXT_IDX=$(( (MY_IDX + 1) % ${#ALL_NAMES[@]} ))
  NEXT_NAME="${ALL_NAMES[$NEXT_IDX]}"

  clear
  echo -e "${COLOR}┌──────────────────────────────────────┐${NC}"
  echo -e "${COLOR}│ ${WHITE}${NAME}${NC}${COLOR} · ${DIM}${MODEL}${NC}"
  echo -e "${COLOR}└──────────────────────────────────────┘${NC}"
  echo -e "${DIM}${ROLE}${NC}"
  echo ""

  turn=0
  while [[ $turn -lt $AGENT_TURNS ]]; do
    # Wait for our turn
    while [[ "$(cat "$TURN_FILE" 2>/dev/null)" != "$NAME" ]]; do
      sleep 0.3
      [[ -f "$DONE_FILE" ]] && exit 0
    done

    topic=$(cat "$TOPIC_FILE" 2>/dev/null)
    convo=$(tail -12 "$CONVO_FILE" 2>/dev/null)

    prompt="You are ${NAME}. ${ROLE}.
Current topic: ${topic}
Recent discussion:
$(tail -3 "$CONVO_FILE" 2>/dev/null)
Respond as ${NAME} in exactly one sentence:"

    echo -ne "${COLOR}▶ ${NAME}${NC} ${DIM}...${NC}"
    # Use REST API directly — faster than `ollama run`, works over SSH tunnel
    payload=$(python3 -c "import json,sys; print(json.dumps({'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,'options':{'num_predict':60,'temperature':0.8,'stop':['\n','.','!','?']}}))" <<< "$prompt")
    raw=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response',''))" 2>/dev/null)
    response=$(echo "$raw" \
      | tr '\n' ' ' | sed 's/  */ /g' \
      | sed "s/^[[:space:]]*//" \
      | sed "s/^${NAME}[[:space:]]*:[[:space:]]*//" \
      | sed "s/^Respond as [^.]*\. //" \
      | sed "s/^(.*)[[:space:]]*//" \
      | cut -c1-240)
    printf "\r\033[K"
    echo -e "${COLOR}▶ ${NAME}${NC} ${response}"
    echo ""

    # Write to convo (macOS-safe atomic append via temp file)
    echo "${NAME}: ${response}" >> "$CONVO_FILE"

    # Signal next agent
    echo "$NEXT_NAME" > "$TURN_FILE"
    ((turn++))
  done

  echo -e "${DIM}── ${NAME} done ──${NC}"
  exit 0
fi

# ── WATCHER PANE ─────────────────────────────────────────────────────────────
if [[ "$1" == "--watch" ]]; then
  topic=$(cat "$TOPIC_FILE" 2>/dev/null)
  clear
  echo -e "${WHITE}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${WHITE}║  🔴 BLACKROAD ROUND TABLE — LIVE FEED        ║${NC}"
  echo -e "${WHITE}╠══════════════════════════════════════════════╣${NC}"
  echo -e "${WHITE}║  ${DIM}${topic:0:44}${NC}${WHITE}  ║${NC}"
  echo -e "${WHITE}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  tail -f "$CONVO_FILE" 2>/dev/null &
  TAIL_PID=$!
  while [[ ! -f "$DONE_FILE" ]]; do sleep 1; done
  sleep 2
  kill $TAIL_PID 2>/dev/null
  echo ""
  echo -e "${WHITE}══════════════ COMPLETE TRANSCRIPT ═══════════${NC}"
  cat "$CONVO_FILE"
  echo -e "${WHITE}═══════════════════════════════════════════════${NC}"
  exit 0
fi

# ── LAUNCHER ─────────────────────────────────────────────────────────────────
cleanup
echo "$TOPIC" > "$TOPIC_FILE"
> "$CONVO_FILE"
echo "LUCIDIA" > "$TURN_FILE"

tmux kill-session -t "$SESSION" 2>/dev/null
SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

echo -e "${WHITE}🔴 BlackRoad Round Table launching...${NC}"
echo -e "${DIM}Topic: ${TOPIC}${NC}"

# Create session with first agent
IFS='|' read -r n m c r <<< "${AGENT_LIST[0]}"
tmux new-session -d -s "$SESSION" -x 220 -y 55 "bash '$SCRIPT' --agent '$n' '$m' '$c' '$r' $TURNS"

# Add remaining agents as splits
for i in 1 2 3 4 5; do
  IFS='|' read -r n m c r <<< "${AGENT_LIST[$i]}"
  tmux split-window -t "$SESSION" "bash '$SCRIPT' --agent '$n' '$m' '$c' '$r' $TURNS"
  tmux select-layout -t "$SESSION" tiled
done

# Watcher pane
tmux split-window -t "$SESSION" "bash '$SCRIPT' --watch"
tmux select-layout -t "$SESSION" tiled

# Background done-watcher
(
  total=$(( ${#AGENT_LIST[@]} * TURNS ))
  while true; do
    count=$(wc -l < "$CONVO_FILE" 2>/dev/null | tr -d ' ')
    [[ "${count:-0}" -ge "$total" ]] && touch "$DONE_FILE" && break
    sleep 2
  done
) &

tmux attach-session -t "$SESSION"
cleanup
