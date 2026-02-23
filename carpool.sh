#!/bin/bash
# BR CARPOOL 🚗 — parallel multi-agent AI roundtable
# Tab 0: all 8 agents active simultaneously, synced per round
# Tabs 1-8: per-agent worker tabs (background investigation)
# Tab 9: live summary feed → final synthesis + session save

SESSION="carpool"
WORK_DIR="/tmp/br_carpool"
SAVE_DIR="$HOME/.blackroad/carpool/sessions"
MODEL="${CARPOOL_MODEL:-tinyllama}"
TURNS="${CARPOOL_TURNS:-3}"

WHITE='\033[1;37m'; DIM='\033[2m'; GREEN='\033[0;32m'
RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
CYAN='\033[0;36m'

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
TOTAL=${#ALL_NAMES[@]}

agent_meta() {
  COLOR_CODE="0"; ROLE="agent"; EMOJI="●"
  for entry in "${AGENT_LIST[@]}"; do
    IFS='|' read -r n c r e <<< "$entry"
    if [[ "$n" == "$1" ]]; then COLOR_CODE="$c"; ROLE="$r"; EMOJI="$e"; return; fi
  done
}

# ── LIST SAVED SESSIONS ───────────────────────────────────────
if [[ "$1" == "--list" || "$1" == "list" ]]; then
  echo -e "${WHITE}🚗 CarPool — Saved Sessions${NC}"
  echo -e "${DIM}$(ls -1t "$SAVE_DIR" 2>/dev/null | wc -l | tr -d ' ') sessions in $SAVE_DIR${NC}\n"
  ls -1t "$SAVE_DIR" 2>/dev/null | while read -r f; do
    size=$(wc -l < "$SAVE_DIR/$f" | tr -d ' ')
    echo -e "  ${CYAN}${f}${NC}  ${DIM}${size} lines${NC}"
  done
  exit 0
fi

# ── CONVERSATION AGENT (Tab 0 panes) ─────────────────────────
if [[ "$1" == "--convo" ]]; then
  NAME="$2"; TURNS="${3:-$TURNS}"; STAGGER="${4:-0}"
  agent_meta "$NAME"
  COLOR="\033[${COLOR_CODE}m"
  CONVO_FILE="$WORK_DIR/convo.txt"

  # Deterministic role-specific dispatch (no extra ollama call needed)
  case "$NAME" in
    LUCIDIA)   DISPATCH_TMPL="Synthesize philosophical framework for: "
               PERSONA="philosophical and visionary, speaks in implications and big ideas" ;;
    ALICE)     DISPATCH_TMPL="Draft step-by-step implementation plan: "
               PERSONA="direct and action-oriented, cuts to what needs doing right now" ;;
    OCTAVIA)   DISPATCH_TMPL="Design system architecture for: "
               PERSONA="technical and precise, thinks in systems and tradeoffs" ;;
    PRISM)     DISPATCH_TMPL="Analyze metrics and data patterns in: "
               PERSONA="analytical and pattern-driven, backs every claim with data" ;;
    ECHO)      DISPATCH_TMPL="Map memory and context requirements for: "
               PERSONA="reflective and contextual, recalls what worked before" ;;
    CIPHER)    DISPATCH_TMPL="Security audit and threat model for: "
               PERSONA="terse and paranoid, assumes everything is a threat" ;;
    ARIA)      DISPATCH_TMPL="Design UI/UX flows and interactions for: "
               PERSONA="creative and human-centered, always thinks about the user experience" ;;
    SHELLFISH) DISPATCH_TMPL="Probe attack surfaces and vulnerabilities in: "
               PERSONA="edgy hacker, finds the exploit in every plan, speaks in exploits" ;;
    *)         DISPATCH_TMPL="Deep investigate from ${ROLE} perspective: "
               PERSONA="${ROLE}" ;;
  esac

  clear
  echo -e "${COLOR}┌──────────────────────────────────────┐${NC}"
  echo -e "${COLOR}│ ${EMOJI} ${WHITE}${NAME}${NC}${COLOR} · ${DIM}${ROLE}${NC}"
  echo -e "${COLOR}└──────────────────────────────────────┘${NC}\n"

  # Stagger startup so all 8 don't hammer ollama at the same instant
  [[ $STAGGER -gt 0 ]] && sleep "$STAGGER"

  TOPIC=$(cat "$WORK_DIR/topic.txt" 2>/dev/null)

  for (( turn=0; turn<TURNS; turn++ )); do
    # Wait for round gate — all agents must finish prev round before next starts
    if [[ $turn -gt 0 ]]; then
      echo -ne "${DIM}⏳ syncing round $((turn+1))/${TURNS}...${NC}"
      while [[ ! -f "$WORK_DIR/round.${turn}.go" ]]; do
        sleep 0.3
      done
      printf "\r\033[K"
    fi

    echo -ne "${COLOR}▶ ${NAME}${NC} ${DIM}[round $((turn+1))/${TURNS}]...${NC}"

    recent=$(tail -6 "$CONVO_FILE" 2>/dev/null)

    # Round 2+: pick one other agent's last line to react to
    if [[ $turn -gt 0 && -n "$recent" ]]; then
      other_line=$(grep -v "^${NAME}:" "$CONVO_FILE" 2>/dev/null | tail -1)
      other_name="${other_line%%:*}"
      other_text="${other_line#*: }"
      reaction="Reacting to ${other_name}: \"${other_text:0:80}\" — "
    else
      reaction=""
    fi

    prompt="[BlackRoad team on: ${TOPIC}]
${recent}
${NAME} is ${PERSONA}.
${reaction}${NAME}: \""

    payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':70,'temperature':0.85,'stop':['\n','\"']}
}))" <<< "$prompt")

    raw=$(curl -s -m 40 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

    speech=$(echo "$raw" | sed 's/^[",: ]*//' | sed "s/^${NAME}[: ]*//" | head -1 | cut -c1-200)
    [[ -z "$speech" || ${#speech} -lt 5 ]] && speech="Need more context before committing to a position."

    short_topic=$(echo "$TOPIC" | cut -c1-55)
    dispatch="${DISPATCH_TMPL}${short_topic}"

    printf "\r\033[K"
    echo -e "${COLOR}${EMOJI} ${NAME}${NC} ${DIM}[r$((turn+1))]${NC} ${speech}"
    echo -e "   ${DIM}↳ queued: ${dispatch}${NC}\n"

    echo "${NAME}: ${speech}" >> "$CONVO_FILE"
    echo "$dispatch" >> "$WORK_DIR/${NAME}.queue"

    # Signal this agent done with round $turn
    echo "done" > "$WORK_DIR/${NAME}.r${turn}.done"

    # If all agents finished this round, open the gate for the next
    done_count=$(ls "$WORK_DIR/"*.r${turn}.done 2>/dev/null | wc -l | tr -d ' ')
    if [[ $done_count -ge $TOTAL ]]; then
      echo "go" > "$WORK_DIR/round.$((turn+1)).go"
    fi
  done

  # Mark globally finished
  echo "done" > "$WORK_DIR/${NAME}.finished"

  # If all agents finished all turns, trigger synthesis
  fin_count=$(ls "$WORK_DIR/"*.finished 2>/dev/null | wc -l | tr -d ' ')
  if [[ $fin_count -ge $TOTAL ]]; then
    echo "go" > "$WORK_DIR/synthesize.go"
  fi

  echo -e "${DIM}── ${EMOJI} ${NAME} complete (${TURNS} rounds, $(wc -l < "$WORK_DIR/${NAME}.queue" 2>/dev/null | tr -d ' ') dispatches) ──${NC}"
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
  printf "${COLOR}║  ${EMOJI} %-45s ║\n${NC}" "${NAME} · ${ROLE}"
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
        echo -ne "${DIM}${SPIN[$((tick % 10))]} working...${NC}"

        prompt="You are ${NAME}, ${ROLE} on the BlackRoad team.
Task: ${task}
Topic context: $(cat "$WORK_DIR/topic.txt" 2>/dev/null)
Provide 3 specific findings or action items. Start immediately:"

        payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':180,'temperature':0.7}
}))" <<< "$prompt")

        result=$(curl -s -m 50 -X POST http://localhost:11434/api/generate \
          -H "Content-Type: application/json" -d "$payload" \
          | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

        printf "\r\033[K"
        echo -e "${GREEN}✓ done${NC}\n"
        echo -e "$result\n"
        echo -e "${COLOR}${DIM}────────────────────────────────────────────────────${NC}\n"
        ((tick++))
      done
    fi
    sleep 1; ((tick++))
  done
fi

# ── SUMMARY TAB — live feed + final synthesis ─────────────────
if [[ "$1" == "--summary" ]]; then
  TOPIC=$(cat "$WORK_DIR/topic.txt" 2>/dev/null)

  clear
  echo -e "${WHITE}${BOLD}🚗 CarPool · Live Feed${NC}"
  echo -e "${DIM}❝ ${TOPIC} ❞${NC}"
  echo -e "${DIM}$(printf '%.0s─' {1..60})${NC}\n"

  last_line=0

  # Stream convo lines with color as they appear
  while [[ ! -f "$WORK_DIR/synthesize.go" ]]; do
    if [[ -f "$WORK_DIR/convo.txt" ]]; then
      total=$(wc -l < "$WORK_DIR/convo.txt" | tr -d ' ')
      while [[ $last_line -lt $total ]]; do
        ((last_line++))
        line=$(sed -n "${last_line}p" "$WORK_DIR/convo.txt")
        speaker="${line%%:*}"
        text="${line#*: }"
        agent_meta "$speaker"
        COLOR="\033[${COLOR_CODE}m"
        echo -e "${COLOR}${EMOJI} ${speaker}${NC}  ${text}"
        # Print dispatch count status every 8 lines
        if (( last_line % 8 == 0 )); then
          echo -ne "\n${DIM}  "
          for name in "${ALL_NAMES[@]}"; do
            agent_meta "$name"; COLOR2="\033[${COLOR_CODE}m"
            q="$WORK_DIR/${name}.queue"; cnt=0; [[ -f "$q" ]] && cnt=$(wc -l < "$q" | tr -d ' ')
            fin="$WORK_DIR/${name}.finished"; mark="·"; [[ -f "$fin" ]] && mark="✓"
            echo -ne "${COLOR2}${EMOJI}${mark}${cnt}${NC} "
          done
          echo -e "${NC}\n"
        fi
      done
    fi
    sleep 0.5
  done

  # Drain any remaining lines
  if [[ -f "$WORK_DIR/convo.txt" ]]; then
    total=$(wc -l < "$WORK_DIR/convo.txt" | tr -d ' ')
    while [[ $last_line -lt $total ]]; do
      ((last_line++))
      line=$(sed -n "${last_line}p" "$WORK_DIR/convo.txt")
      speaker="${line%%:*}"; text="${line#*: }"
      agent_meta "$speaker"; COLOR="\033[${COLOR_CODE}m"
      echo -e "${COLOR}${EMOJI} ${speaker}${NC}  ${text}"
    done
  fi

  # ── SYNTHESIS ──────────────────────────────────────────────
  echo ""
  echo -e "${WHITE}${BOLD}$(printf '%.0s━' {1..60})${NC}"
  echo -e "${WHITE}${BOLD}  🏁  ALL AGENTS DONE — SYNTHESIZING...${NC}"
  echo -e "${WHITE}${BOLD}$(printf '%.0s━' {1..60})${NC}\n"

  convo_text=$(cat "$WORK_DIR/convo.txt" 2>/dev/null | head -40)
  syn_prompt="The BlackRoad AI team just finished a roundtable.
Topic: ${TOPIC}
Discussion:
${convo_text}

Write a synthesis with exactly 3 sections:
CONSENSUS: what the team agreed on
TENSIONS: key disagreements  
ACTION: top 3 recommended next steps
Keep under 120 words total:"

  syn_payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':220,'temperature':0.5,'stop':['---']}
}))" <<< "$syn_prompt")

  synthesis=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$syn_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

  echo -e "${YELLOW}${BOLD}${synthesis}${NC}\n"

  # Save synthesis so the vote tab can read it
  echo "$synthesis" > "$WORK_DIR/synthesis.txt"
  echo "go" > "$WORK_DIR/vote.go"

  # ── SAVE SESSION ──────────────────────────────────────────
  mkdir -p "$SAVE_DIR"
  slug=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | cut -c1-35)
  session_file="${SAVE_DIR}/$(date +%Y-%m-%d_%H-%M)_${slug}.txt"
  {
    echo "CarPool Session"
    echo "Date:  $(date)"
    echo "Topic: $TOPIC"
    echo "Model: $MODEL  Turns: $TURNS  Agents: $TOTAL"
    echo "$(printf '%.0s═' {1..60})"
    echo ""
    cat "$WORK_DIR/convo.txt" 2>/dev/null
    echo ""
    echo "$(printf '%.0s═' {1..60})"
    echo "SYNTHESIS"
    echo "$(printf '%.0s─' {1..60})"
    echo "$synthesis"
    echo ""
    echo "$(printf '%.0s═' {1..60})"
    echo "DISPATCHES"
    echo "$(printf '%.0s─' {1..60})"
    for name in "${ALL_NAMES[@]}"; do
      echo "[$name]"
      cat "$WORK_DIR/${name}.queue" 2>/dev/null
      echo ""
    done
  } > "$session_file"

  echo -e "${DIM}Session saved → ${GREEN}${session_file}${NC}"
  echo ""
  echo -e "${DIM}tip: br carpool list | br carpool last${NC}"
  while true; do sleep 60; done
fi

# ── VOTE TAB — each agent casts YES/NO after synthesis ────────
if [[ "$1" == "--vote" ]]; then
  NAME="$2"
  agent_meta "$NAME"
  COLOR="\033[${COLOR_CODE}m"

  case "$NAME" in
    LUCIDIA)   PERSONA="philosophical and visionary, speaks in implications" ;;
    ALICE)     PERSONA="direct and action-oriented, what needs doing right now" ;;
    OCTAVIA)   PERSONA="technical and precise, systems and tradeoffs" ;;
    PRISM)     PERSONA="analytical, data-driven, backs claims with data" ;;
    ECHO)      PERSONA="reflective and contextual, recalls what worked before" ;;
    CIPHER)    PERSONA="terse and paranoid, everything is a threat" ;;
    ARIA)      PERSONA="creative and human-centered, user experience first" ;;
    SHELLFISH) PERSONA="edgy hacker, finds the exploit in every plan" ;;
    *)         PERSONA="${ROLE}" ;;
  esac

  clear
  echo -e "${COLOR}┌──────────────────────────────────────┐${NC}"
  echo -e "${COLOR}│ ${EMOJI} ${WHITE}${NAME}${NC}${COLOR} · ${DIM}casting vote${NC}"
  echo -e "${COLOR}└──────────────────────────────────────┘${NC}\n"
  echo -ne "${DIM}⏳ awaiting synthesis...${NC}"

  while [[ ! -f "$WORK_DIR/vote.go" ]]; do sleep 0.4; done
  printf "\r\033[K"

  TOPIC=$(cat "$WORK_DIR/topic.txt" 2>/dev/null)
  synthesis=$(cat "$WORK_DIR/synthesis.txt" 2>/dev/null)

  prompt="${NAME} is ${PERSONA} on the BlackRoad AI team.
Topic: ${TOPIC}
Team synthesis: ${synthesis}
${NAME}'s one-word vote (YES or NO) then one sentence rationale:
${NAME}: \""

  payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':60,'temperature':0.85,'stop':['\n','\"']}
}))" <<< "$prompt")

  raw=$(curl -s -m 40 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

  vote=$(echo "$raw" | sed 's/^[",: ]*//' | sed "s/^${NAME}[: ]*//" | head -1 | cut -c1-200)
  [[ -z "$vote" ]] && vote="YES. The synthesis aligns with my analysis."

  if echo "$vote" | grep -qi "^NO"; then
    VOTE_COLOR="\033[1;31m"; VOTE_WORD="╳  NO "
  else
    VOTE_COLOR="\033[1;32m"; VOTE_WORD="✓  YES"
  fi

  echo -e "${COLOR}${BOLD}${EMOJI} ${NAME}${NC}\n"
  echo -e "${VOTE_COLOR}${BOLD}  ┌──────────┐${NC}"
  echo -e "${VOTE_COLOR}${BOLD}  │ ${VOTE_WORD} │${NC}"
  echo -e "${VOTE_COLOR}${BOLD}  └──────────┘${NC}\n"
  echo -e "${DIM}  ${vote}${NC}"
  while true; do sleep 60; done
fi

# ── LAUNCHER ──────────────────────────────────────────────────
# br carpool last → open most recent saved session
if [[ "$1" == "last" ]]; then
  f=$(ls -1t "$SAVE_DIR" 2>/dev/null | head -1)
  [[ -z "$f" ]] && echo "No saved sessions yet." && exit 1
  less "$SAVE_DIR/$f"
  exit 0
fi

TOPIC="${1:-What should BlackRoad build next?}"
rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
echo "$TOPIC" > "$WORK_DIR/topic.txt"
> "$WORK_DIR/convo.txt"
# Round 0 gate always open (agents start immediately)
echo "go" > "$WORK_DIR/round.0.go"

# Kill any stuck curl connections blocking the ollama queue
stuck=$(lsof -i:11434 2>/dev/null | grep curl | awk '{print $2}' | sort -u)
if [[ -n "$stuck" ]]; then
  echo -e "${DIM}🧹 clearing ${#stuck[@]} stuck ollama connection(s)...${NC}"
  for pid in $stuck; do kill "$pid" 2>/dev/null; done
  sleep 0.5
fi

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
tmux kill-session -t "$SESSION" 2>/dev/null

echo -e "${WHITE}🚗 CarPool${NC}  ${DIM}model:${NC} ${MODEL}  ${DIM}turns:${NC} ${TURNS}  ${DIM}agents:${NC} ${TOTAL}"
echo -e "${DIM}${TOPIC}${NC}\n"

# Tab 0: group panes — all agents with staggered start (1s each)
IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[0]}"
tmux new-session -d -s "$SESSION" -n "🚗 everyone" -x 220 -y 55 \
  "bash '$SCRIPT_PATH' --convo $n $TURNS 0"
GROUP_WIN="$SESSION:🚗 everyone"
for (( i=1; i<${#AGENT_LIST[@]}; i++ )); do
  IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[$i]}"
  tmux split-window -t "$GROUP_WIN" "bash '$SCRIPT_PATH' --convo $n $TURNS $i"
  tmux select-layout -t "$GROUP_WIN" tiled
done

# Worker tabs
for entry in "${AGENT_LIST[@]}"; do
  IFS='|' read -r n _ _ _ <<< "$entry"
  tmux new-window -t "$SESSION" -n "$n" "bash '$SCRIPT_PATH' --worker $n"
done

# Summary tab
tmux new-window -t "$SESSION" -n "📋 summary" "bash '$SCRIPT_PATH' --summary"

# Vote tab — 8 tiled panes, each agent casts YES/NO after synthesis
IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[0]}"
tmux new-window -t "$SESSION" -n "🗳️ vote" "bash '$SCRIPT_PATH' --vote $n"
VOTE_WIN="$SESSION:🗳️ vote"
for (( i=1; i<${#AGENT_LIST[@]}; i++ )); do
  IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[$i]}"
  tmux split-window -t "$VOTE_WIN" "bash '$SCRIPT_PATH' --vote $n"
  tmux select-layout -t "$VOTE_WIN" tiled
done

tmux select-window -t "$GROUP_WIN"

if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
