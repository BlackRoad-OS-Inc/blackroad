#!/bin/bash
# BR CARPOOL 🚗
# Tab 0 "🚗 everyone": 8 agents talking together (round-robin group chat)
# Tabs 1-8: each agent's background worker — dispatched tasks + live status
# Tab 9 "📋 summary": live colored convo feed + dispatch status board

SESSION="carpool"
WORK_DIR="/tmp/br_carpool"
MODEL="${CARPOOL_MODEL:-tinyllama}"
TURNS="${CARPOOL_TURNS:-3}"

WHITE='\033[1;37m'; DIM='\033[2m'; GREEN='\033[0;32m'
RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

# NAME | COLOR_CODE | ROLE | EMOJI
AGENT_LIST=(
  "LUCIDIA|1;31|philosophical strategist|🌀"
  "ALICE|1;36|practical executor|🚪"
  "OCTAVIA|1;32|technical architect|⚡"
  "PRISM|1;33|data analyst|🔮"
  "ECHO|1;35|memory synthesizer|📡"
  "CIPHER|1;34|security auditor|🔐"
  "ARIA|0;35|interface designer|🎨"
  "SHELLFISH|0;33|security hacker|🐚"
)
ALL_NAMES=("LUCIDIA" "ALICE" "OCTAVIA" "PRISM" "ECHO" "CIPHER" "ARIA" "SHELLFISH")

# Look up color + role + emoji by name
agent_meta() {
  COLOR_CODE="0"; ROLE="agent"; EMOJI="●"
  for entry in "${AGENT_LIST[@]}"; do
    IFS='|' read -r n c r e <<< "$entry"
    if [[ "$n" == "$1" ]]; then COLOR_CODE="$c"; ROLE="$r"; EMOJI="$e"; return; fi
  done
}

# ── CONVERSATION AGENT (Tab 0 panes) ─────────────────────────
if [[ "$1" == "--convo" ]]; then
  NAME="$2"; TURNS="${3:-$TURNS}"
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
  echo -e "${COLOR}│ ${EMOJI} ${WHITE}${NAME}${NC}${COLOR} · ${DIM}${ROLE}${NC}"
  echo -e "${COLOR}└──────────────────────────────────────┘${NC}"
  echo ""

  TOPIC=$(cat "$WORK_DIR/topic.txt" 2>/dev/null)

  # Deterministic role-specific dispatch templates (fast, no extra ollama call)
  case "$NAME" in
    LUCIDIA)   DISPATCH_TMPL="Synthesize philosophical framework for: " ;;
    ALICE)     DISPATCH_TMPL="Draft step-by-step implementation plan: " ;;
    OCTAVIA)   DISPATCH_TMPL="Design system architecture for: " ;;
    PRISM)     DISPATCH_TMPL="Analyze metrics and data patterns in: " ;;
    ECHO)      DISPATCH_TMPL="Map memory and context requirements for: " ;;
    CIPHER)    DISPATCH_TMPL="Security audit and threat model for: " ;;
    ARIA)      DISPATCH_TMPL="Design UI/UX flows and interactions for: " ;;
    SHELLFISH) DISPATCH_TMPL="Probe vulnerabilities and attack surfaces in: " ;;
    *)         DISPATCH_TMPL="Deep dive from ${ROLE} perspective on: " ;;
  esac

  turn=0
  while [[ $turn -lt $TURNS ]]; do
    while [[ "$(cat "$TURN_FILE" 2>/dev/null)" != "$NAME" ]]; do
      sleep 0.3
    done

    echo -ne "${COLOR}▶ ${NAME}${NC} ${DIM}[turn $((turn+1))/${TURNS}]...${NC}"

    recent=$(tail -4 "$CONVO_FILE" 2>/dev/null)
    # Completion-style prompt: model fills in after the opening quote
    prompt="[BlackRoad team: ${TOPIC}]
${recent}
${NAME} (${ROLE}): \""

    payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':60,'temperature':0.85,'stop':['\n','\"']}
}))" <<< "$prompt")

    raw=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

    # Strip any name echo, leading punctuation artifacts
    speech=$(echo "$raw" | sed 's/^[",: ]*//' | sed "s/^${NAME}[: ]*//" | head -1 | cut -c1-200)
    [[ -z "$speech" || ${#speech} -lt 5 ]] && speech="This requires deeper investigation from my perspective."

    # Deterministic dispatch — role template + short topic snippet
    short_topic=$(echo "$TOPIC" | cut -c1-60)
    dispatch="${DISPATCH_TMPL}${short_topic}"

    printf "\r\033[K"
    echo -e "${COLOR}${EMOJI} ${NAME}${NC} ${DIM}[${turn+1}/${TURNS}]${NC} ${speech}"
    echo -e "   ${DIM}↳ dispatched: ${dispatch}${NC}"
    echo ""

    echo "${NAME}: ${speech}" >> "$CONVO_FILE"
    echo "$dispatch" >> "$WORK_DIR/${NAME}.queue"

    echo "$NEXT_NAME" > "$TURN_FILE"
    ((turn++))
  done

  # Signal this agent is done
  echo "done" > "$WORK_DIR/${NAME}.done"
  echo -e "${DIM}── ${EMOJI} ${NAME} finished all ${TURNS} turns ──${NC}"
  while true; do sleep 60; done
fi

# ── WORKER TAB ────────────────────────────────────────────────
if [[ "$1" == "--worker" ]]; then
  NAME="$2"
  agent_meta "$NAME"
  COLOR="\033[${COLOR_CODE}m"
  QUEUE="$WORK_DIR/${NAME}.queue"
  SPIN=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

  clear
  echo -e "${COLOR}╔══════════════════════════════════════════════════╗${NC}"
  printf "${COLOR}║  ${EMOJI} %-46s║\n${NC}" "${NAME} · ${ROLE}"
  echo -e "${COLOR}╚══════════════════════════════════════════════════╝${NC}"
  echo -e "${DIM}$(cat "$WORK_DIR/topic.txt" 2>/dev/null)${NC}\n"
  echo -e "${DIM}Waiting for dispatched tasks...${NC}\n"

  last_line=0; tick=0; task_num=0

  while true; do
    if [[ -f "$QUEUE" ]]; then
      total=$(wc -l < "$QUEUE" | tr -d ' ')
      while [[ $last_line -lt $total ]]; do
        ((last_line++))
        task=$(sed -n "${last_line}p" "$QUEUE")
        [[ -z "$task" ]] && continue
        ((task_num++))

        echo -e "${COLOR}┌─ Task #${task_num} ───────────────────────────────────┐${NC}"
        echo -e "${COLOR}│${NC} ${task}"
        echo -e "${COLOR}└────────────────────────────────────────────────────┘${NC}"
        echo -ne "${DIM}working... ${SPIN[$((tick % 10))]}${NC}"

        prompt="You are ${NAME}, ${ROLE} on the BlackRoad team.
Task: ${task}
Topic: $(cat "$WORK_DIR/topic.txt" 2>/dev/null)
Give 3 specific findings or action items. Start immediately, no intro:"

        payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':180,'temperature':0.7}
}))" <<< "$prompt")

        result=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
          -H "Content-Type: application/json" -d "$payload" \
          | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

        printf "\r\033[K"
        echo -e "${GREEN}✓ done${NC}\n"
        echo -e "$result"
        echo ""
        echo -e "${COLOR}${DIM}────────────────────────────────────────────────────${NC}\n"
        ((tick++))
      done
    fi
    sleep 1
    ((tick++))
  done
fi

# ── SUMMARY TAB ───────────────────────────────────────────────
if [[ "$1" == "--summary" ]]; then
  TOPIC=$(cat "$WORK_DIR/topic.txt" 2>/dev/null)
  last_convo_line=0

  while true; do
    # Print new convo lines as they arrive (streaming, not clearing)
    if [[ -f "$WORK_DIR/convo.txt" ]]; then
      total=$(wc -l < "$WORK_DIR/convo.txt" | tr -d ' ')
      while [[ $last_convo_line -lt $total ]]; do
        ((last_convo_line++))
        line=$(sed -n "${last_convo_line}p" "$WORK_DIR/convo.txt")
        speaker="${line%%:*}"
        text="${line#*: }"
        agent_meta "$speaker"
        COLOR="\033[${COLOR_CODE}m"
        echo -e "${COLOR}${EMOJI} ${speaker}${NC}  ${text}"
      done
    fi

    # Every 5 lines print a status bar
    if (( last_convo_line > 0 && last_convo_line % 5 == 0 )); then
      echo ""
      echo -ne "${DIM}  dispatches: "
      for name in "${ALL_NAMES[@]}"; do
        agent_meta "$name"
        q="$WORK_DIR/${name}.queue"
        cnt=0; [[ -f "$q" ]] && cnt=$(wc -l < "$q" | tr -d ' ')
        done_f="$WORK_DIR/${name}.done"
        mark="·"; [[ -f "$done_f" ]] && mark="✓"
        echo -ne "\033[${COLOR_CODE}m${EMOJI}${mark}${cnt}${NC} "
      done
      echo -e "${NC}"
      echo ""
    fi

    sleep 0.5
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

echo -e "${WHITE}🚗 CarPool loading...${NC}  ${DIM}model: ${MODEL}  turns: ${TURNS}${NC}"
echo -e "${DIM}${TOPIC}${NC}"

# Tab 0: "🚗 everyone" — all agents tiled
IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[0]}"
tmux new-session -d -s "$SESSION" -n "🚗 everyone" -x 220 -y 55 \
  "bash '$SCRIPT' --convo $n $TURNS"
GROUP_WIN="$SESSION:🚗 everyone"
for (( i=1; i<${#AGENT_LIST[@]}; i++ )); do
  IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[$i]}"
  tmux split-window -t "$GROUP_WIN" "bash '$SCRIPT' --convo $n $TURNS"
  tmux select-layout -t "$GROUP_WIN" tiled
done

# Worker tabs — one per agent
for entry in "${AGENT_LIST[@]}"; do
  IFS='|' read -r n _ _ _ <<< "$entry"
  tmux new-window -t "$SESSION" -n "$n" "bash '$SCRIPT' --worker $n"
done

# Summary tab
tmux new-window -t "$SESSION" -n "📋 summary" \
  "bash '$SCRIPT' --summary"

# Land on group tab
tmux select-window -t "$GROUP_WIN"

if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
