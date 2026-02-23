#!/bin/bash
# BR CARPOOL 🚗
# Tab 0 "🚗 everyone": 8 agents talking together (round-robin group chat)
# Tabs 1-8: each agent's background worker — dispatched tasks + live status

SESSION="carpool"
WORK_DIR="/tmp/br_carpool"
MODEL="tinyllama"

WHITE='\033[1;37m'; DIM='\033[2m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

# NAME | COLOR_CODE | ROLE
AGENT_LIST=(
  "LUCIDIA|1;31|philosophical strategist"
  "ALICE|1;36|practical executor"
  "OCTAVIA|1;32|technical architect"
  "PRISM|1;33|data analyst"
  "ECHO|1;35|memory synthesizer"
  "CIPHER|1;34|security auditor"
  "ARIA|0;35|interface designer"
  "SHELLFISH|0;33|security hacker"
)
ALL_NAMES=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER" "ARIA" "SHELLFISH")

# Look up color + role by name
agent_meta() {
  for entry in "${AGENT_LIST[@]}"; do
    IFS='|' read -r n c r <<< "$entry"
    if [[ "$n" == "$1" ]]; then COLOR_CODE="$c"; ROLE="$r"; return; fi
  done
}

# ── CONVERSATION AGENT (Tab 0 panes) ─────────────────────────
if [[ "$1" == "--convo" ]]; then
  NAME="$2"; TURNS="${3:-2}"
  agent_meta "$NAME"
  COLOR="\033[${COLOR_CODE}m"
  TURN_FILE="$WORK_DIR/turn.txt"
  CONVO_FILE="$WORK_DIR/convo.txt"
  MY_IDX=0
  for i in "${!ALL_NAMES[@]}"; do
    [[ "${ALL_NAMES[$i]}" == "$NAME" ]] && MY_IDX=$i && break
  done
  NEXT_NAME="${ALL_NAMES[$(( (MY_IDX + 1) % ${#ALL_NAMES[@]} ))]}"

  clear
  echo -e "${COLOR}┌──────────────────────────────────────┐${NC}"
  echo -e "${COLOR}│ ${WHITE}${NAME}${NC}${COLOR} · ${DIM}${ROLE}${NC}"
  echo -e "${COLOR}└──────────────────────────────────────┘${NC}"
  echo ""

  TOPIC=$(cat "$WORK_DIR/topic.txt" 2>/dev/null)
  turn=0
  while [[ $turn -lt $TURNS ]]; do
    while [[ "$(cat "$TURN_FILE" 2>/dev/null)" != "$NAME" ]]; do
      sleep 0.3
    done

    echo -ne "${COLOR}▶ ${NAME}${NC} ${DIM}...${NC}"

    recent=$(tail -3 "$CONVO_FILE" 2>/dev/null)
    prompt="${NAME} is a ${ROLE} on the BlackRoad team.
Topic: ${TOPIC}
${recent:+Recent discussion:
$recent
}${NAME}'s take (1 sentence): "

    payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':60,'temperature':0.8,'stop':['\n']}
}))" <<< "$prompt")

    raw=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

    speech=$(echo "$raw" | sed "s/^${NAME}[: ]*//" | head -1 | cut -c1-200)

    # Generate a role-specific dispatch task in a second short call
    dp_payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':20,'temperature':0.7,'stop':['\n','.']}
}))" <<< "$dispatch_prompt")
    dispatch=$(curl -s -m 15 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$dp_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null \
      | head -1 | cut -c1-80)
    [[ -z "$dispatch" ]] && dispatch="Analyze ${TOPIC} from ${ROLE} perspective"

    printf "\r\033[K"
    echo -e "${COLOR}▶ ${NAME}${NC} ${speech}"
    echo -e "   ${DIM}↳ dispatched → ${dispatch}${NC}"
    echo ""

    echo "${NAME}: ${speech}" >> "$CONVO_FILE"
    echo "$dispatch" >> "$WORK_DIR/${NAME}.queue"

    echo "$NEXT_NAME" > "$TURN_FILE"
    ((turn++))
  done

  echo -e "${DIM}── ${NAME} done ──${NC}"
  while true; do sleep 60; done
fi

# ── WORKER TAB (Tabs 1-6) ─────────────────────────────────────
if [[ "$1" == "--worker" ]]; then
  NAME="$2"
  agent_meta "$NAME"
  COLOR="\033[${COLOR_CODE}m"
  QUEUE="$WORK_DIR/${NAME}.queue"
  SPIN=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  clear
  echo -e "${COLOR}╔══════════════════════════════════════════════════╗${NC}"
  printf "${COLOR}║  🚗 %-47s║\n${NC}" "${NAME} · ${ROLE}"
  echo -e "${COLOR}╚══════════════════════════════════════════════════╝${NC}"
  echo -e "${DIM}$(cat "$WORK_DIR/topic.txt" 2>/dev/null)${NC}\n"
  echo -e "${DIM}Waiting for dispatched tasks...${NC}\n"

  last_line=0
  tick=0
  task_num=0

  while true; do
    if [[ -f "$QUEUE" ]]; then
      total=$(wc -l < "$QUEUE" | tr -d ' ')
      while [[ $last_line -lt $total ]]; do
        ((last_line++))
        task=$(sed -n "${last_line}p" "$QUEUE")
        [[ -z "$task" ]] && continue
        ((task_num++))

        echo -e "${COLOR}┌─ Task #${task_num} ────────────────────────────────────┐${NC}"
        echo -e "${COLOR}│${NC} ${task}"
        echo -e "${COLOR}└────────────────────────────────────────────────────┘${NC}"
        echo -e "${DIM}status: queued → working...${NC}"
        echo -ne "${YELLOW}${SPIN[$((tick % 10))]} processing...${NC}"

        prompt="You are ${NAME}, ${ROLE}.
Task: ${task}
Topic context: $(cat "$WORK_DIR/topic.txt" 2>/dev/null)
Give exactly 3 specific findings or action items. No intro, start immediately:"

        payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':160,'temperature':0.7}
}))" <<< "$prompt")

        result=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
          -H "Content-Type: application/json" -d "$payload" \
          | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

        printf "\r\033[K"
        echo -e "${DIM}status:${NC} ${GREEN}✓ done${NC}\n"
        echo -e "$result"
        echo ""
        echo -e "${DIM}────────────────────────────────────────────────────${NC}\n"
        ((tick++))
      done
    fi
    sleep 1
    ((tick++))
  done
fi

# ── LAUNCHER ──────────────────────────────────────────────────
TOPIC="${1:-What should BlackRoad build next?}"
rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
echo "$TOPIC" > "$WORK_DIR/topic.txt"
echo "LUCIDIA" > "$WORK_DIR/turn.txt"
> "$WORK_DIR/convo.txt"

SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
tmux kill-session -t "$SESSION" 2>/dev/null

echo -e "${WHITE}🚗 CarPool loading...${NC}"
echo -e "${DIM}${TOPIC}${NC}"

# Tab 0: "🚗 everyone" — all agents in tiled conversation panes
IFS='|' read -r n _ _ <<< "${AGENT_LIST[0]}"
tmux new-session -d -s "$SESSION" -n "🚗 everyone" -x 220 -y 55 \
  "bash '$SCRIPT' --convo $n 2"
# Use window name (not :0) so it works regardless of base-index setting
GROUP_WIN="$SESSION:🚗 everyone"
for (( i=1; i<${#AGENT_LIST[@]}; i++ )); do
  IFS='|' read -r n _ _ <<< "${AGENT_LIST[$i]}"
  tmux split-window -t "$GROUP_WIN" "bash '$SCRIPT' --convo $n 2"
  tmux select-layout -t "$GROUP_WIN" tiled
done

# Tabs 1-6: individual worker tabs (named after each agent)
for entry in "${AGENT_LIST[@]}"; do
  IFS='|' read -r n _ _ <<< "$entry"
  tmux new-window -t "$SESSION" -n "$n" "bash '$SCRIPT' --worker $n"
done

# Land on the group tab
tmux select-window -t "$GROUP_WIN"

# Drop in
if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
