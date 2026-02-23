#!/bin/bash
# BR CARPOOL 🚗 — parallel multi-agent AI roundtable
# Tab 0: all 8 agents active simultaneously, synced per round
# Tabs 1-8: per-agent worker tabs (background investigation)
# Tab 9: live summary feed → synthesis → vote tally
# Tab 10: vote tab — 8 agents cast YES/NO simultaneously

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
    topic=$(grep "^Topic:" "$SAVE_DIR/$f" 2>/dev/null | sed 's/^Topic: //')
    size=$(wc -l < "$SAVE_DIR/$f" | tr -d ' ')
    echo -e "  ${CYAN}${f}${NC}  ${DIM}${size} lines${NC}"
    [[ -n "$topic" ]] && echo -e "  ${DIM}  ↳ ${topic}${NC}"
  done
  exit 0
fi

# ── ATTACH TO RUNNING SESSION ─────────────────────────────────
if [[ "$1" == "attach" || "$1" == "--attach" ]]; then
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$SESSION"
    else
      tmux attach -t "$SESSION"
    fi
  else
    echo -e "${RED}No running CarPool session.${NC} Start one with: br carpool <topic>"
    exit 1
  fi
  exit 0
fi

# ── LIVE FOLLOW-UP INJECTION ──────────────────────────────────
if [[ "$1" == "ask" || "$1" == "--ask" ]]; then
  question="${*:2}"
  [[ -z "$question" ]] && echo -ne "${CYAN}Follow-up question: ${NC}" && read -r question
  [[ -z "$question" ]] && exit 1
  if [[ ! -d "$WORK_DIR" ]]; then
    echo -e "${RED}No active CarPool session.${NC} Start one with: br carpool <topic>"
    exit 1
  fi
  echo "$question" > "$WORK_DIR/followup.txt"
  echo -e "${GREEN}✓${NC} Follow-up queued — agents will pick it up next round"
  echo -e "${DIM}  ❝ ${question} ❞${NC}"
  exit 0
fi

# ── EXPORT SESSION AS MARKDOWN ────────────────────────────────
if [[ "$1" == "export" || "$1" == "--export" ]]; then
  file="$2"
  if [[ -z "$file" ]]; then
    file=$(ls -1t "$SAVE_DIR" 2>/dev/null | head -1)
    [[ -z "$file" ]] && echo "No sessions found." && exit 1
    file="$SAVE_DIR/$file"
  elif [[ ! -f "$file" ]]; then
    file="$SAVE_DIR/$file"
  fi
  [[ ! -f "$file" ]] && echo "Session not found: $2" && exit 1

  topic=$(grep "^Topic:" "$file" | sed 's/^Topic: //')
  meta=$(grep "^Model:" "$file" | sed 's/^Model: //')
  date_str=$(grep "^Date:" "$file" | sed 's/^Date:  //')
  out="${file%.txt}.md"

  {
    echo "# 🚗 CarPool: ${topic}"
    echo ""
    echo "*${date_str}*  "
    echo "*${meta}*"
    echo ""
    echo "---"
    echo ""
    echo "## Discussion"
    echo ""

    in_section="convo"; skip=0
    while IFS= read -r line; do
      [[ $skip -lt 5 ]] && ((skip++)) && continue
      if [[ "$line" =~ ^═+ || "$line" =~ ^─+ ]]; then continue; fi
      if [[ "$line" == "SYNTHESIS" ]]; then in_section="synthesis"; echo "---"; echo ""; echo "## Synthesis"; echo ""; continue; fi
      if [[ "$line" == "DISPATCHES" ]]; then in_section="dispatches"; echo ""; echo "---"; echo ""; echo "## Dispatches"; echo ""; continue; fi
      if [[ "$line" =~ ^VOTE:\ (.+) ]]; then
        verdict="${line#VOTE: }"
        echo ""; echo "---"; echo ""; echo "## Vote: ${verdict}"; echo ""
        echo "| Agent | Vote |"; echo "|-------|------|"
        in_section="vote"; continue
      fi
      [[ -z "$line" ]] && echo "" && continue

      if [[ "$in_section" == "convo" ]]; then
        speaker="${line%%:*}"; text="${line#*: }"
        agent_meta "$speaker"
        if [[ "$EMOJI" != "●" ]]; then
          echo "**${EMOJI} ${speaker}** *(${ROLE})*  "
          echo "${text}"; echo ""
        fi
      elif [[ "$in_section" == "synthesis" ]]; then
        echo "${line}  "
      elif [[ "$in_section" == "vote" ]]; then
        if [[ "$line" =~ ^\ +([A-Z]+):\ (YES|NO|ABSTAIN) ]]; then
          name="${BASH_REMATCH[1]}"; v="${BASH_REMATCH[2]}"
          agent_meta "$name"
          [[ "$v" == "YES" ]] && mark="✅" || mark="❌"
          echo "| ${EMOJI} ${name} | ${mark} ${v} |"
        fi
      elif [[ "$in_section" == "dispatches" ]]; then
        if [[ "$line" =~ ^\[([A-Z]+)\] ]]; then
          name="${BASH_REMATCH[1]}"; agent_meta "$name"
          echo "### ${EMOJI} ${name}"
        else
          echo "- ${line}"
        fi
      fi
    done < "$file"
  } > "$out"

  echo -e "${GREEN}✓${NC} Exported → ${CYAN}${out}${NC}"
  exit 0
fi

# ── CLEAN OLD SESSIONS ────────────────────────────────────────
if [[ "$1" == "clean" || "$1" == "--clean" ]]; then
  keep="${2:-10}"
  total=$(ls -1t "$SAVE_DIR" 2>/dev/null | wc -l | tr -d ' ')
  if [[ $total -le $keep ]]; then
    echo -e "${DIM}${total} sessions — nothing to clean (keeping last ${keep})${NC}"
    exit 0
  fi
  delete=$((total - keep))
  echo -e "${YELLOW}Removing ${delete} old sessions (keeping last ${keep})...${NC}"
  ls -1t "$SAVE_DIR" 2>/dev/null | tail -n "$delete" | while read -r f; do
    rm -f "$SAVE_DIR/$f" "$SAVE_DIR/${f%.txt}.md" 2>/dev/null
    echo -e "  ${DIM}removed: ${f}${NC}"
  done
  echo -e "${GREEN}✓ Done${NC}"
  exit 0
fi

# ── AVAILABLE OLLAMA MODELS ───────────────────────────────────
if [[ "$1" == "models" || "$1" == "--models" ]]; then
  echo -e "${WHITE}🚗 CarPool — Available Models on cecilia${NC}\n"
  raw=$(curl -s -m 6 http://localhost:11434/api/tags 2>/dev/null)
  if [[ -z "$raw" ]]; then
    echo -e "${RED}Cannot reach ollama (localhost:11434). Is the SSH tunnel up?${NC}"
    exit 1
  fi
  echo "$raw" | python3 -c "
import sys, json
data = json.load(sys.stdin)
models = sorted(data.get('models', []), key=lambda x: x.get('size', 0))
ratings = {
  'tinyllama': ('⚡ fastest', '★★☆☆☆'),
  'llama3.2:1b': ('🔥 fast', '★★★☆☆'),
  'llama3.2': ('🧠 smart', '★★★★☆'),
  'qwen2.5-coder:3b': ('💻 coder', '★★★☆☆'),
  'qwen3:8b': ('🔬 best', '★★★★★'),
  'cece': ('💜 custom', '★★★☆☆'),
}
for m in models:
    name = m['name']
    size = m.get('size', 0) / 1e9
    base = name.split(':')[0] if ':' in name else name
    speed, stars = ratings.get(name, ratings.get(base, ('', '★★★☆☆')))
    print(f'  {stars}  {speed:<12}  {name:<30}  {size:.1f}GB')
print()
print('  Usage:  br carpool --model <name> \"topic\"')
print('  Presets: --fast (tinyllama) | --smart (llama3.2:1b) | --turbo')
"
  exit 0
fi

# ── STREAM LIVE CONVO (outside tmux) ─────────────────────────
if [[ "$1" == "log" || "$1" == "--log" ]]; then
  if [[ ! -d "$WORK_DIR" ]]; then
    echo -e "${RED}No active CarPool session.${NC}"
    exit 1
  fi
  echo -e "${WHITE}🚗 CarPool Live Log${NC}  ${DIM}Ctrl+C to exit${NC}\n"
  topic=$(cat "$WORK_DIR/topic.txt" 2>/dev/null)
  echo -e "${DIM}❝ ${topic} ❞${NC}\n"
  tail -f "$WORK_DIR/convo.txt" 2>/dev/null | while IFS= read -r line; do
    speaker="${line%%:*}"; text="${line#*: }"
    agent_meta "$speaker"
    if [[ "$EMOJI" != "●" ]]; then
      COLOR="\033[${COLOR_CODE}m"
      echo -e "${COLOR}${EMOJI} ${speaker}${NC}  ${text}"
    else
      echo -e "${DIM}${line}${NC}"
    fi
  done
  exit 0
fi

# ── SEARCH SAVED SESSIONS ─────────────────────────────────────
if [[ "$1" == "search" || "$1" == "--search" ]]; then
  query="${*:2}"
  [[ -z "$query" ]] && echo "Usage: br carpool search <keyword>" && exit 1
  echo -e "${WHITE}🔍 Searching: ${CYAN}${query}${NC}\n"
  found=0
  for f in $(ls -1t "$SAVE_DIR" 2>/dev/null); do
    matches=$(grep -i "$query" "$SAVE_DIR/$f" 2>/dev/null | grep -v "^Topic:\|^Date:\|^Model:\|^═\|^─\|^VOTE\|^\[" | head -3)
    [[ -z "$matches" ]] && continue
    ((found++))
    topic=$(grep "^Topic:" "$SAVE_DIR/$f" | sed 's/^Topic: //')
    echo -e "  ${CYAN}${f}${NC}"
    echo -e "  ${DIM}↳ ${topic}${NC}"
    echo "$matches" | while IFS= read -r m; do
      echo -e "    ${DIM}${m:0:120}${NC}"
    done
    echo ""
  done
  [[ $found -eq 0 ]] && echo -e "${DIM}No matches found.${NC}"
  exit 0
fi

# ── TOPIC HISTORY ─────────────────────────────────────────────
if [[ "$1" == "history" || "$1" == "--history" ]]; then
  echo -e "${WHITE}🚗 CarPool — Topic History${NC}\n"
  grep -h "^Topic:" "$SAVE_DIR"/*.txt 2>/dev/null \
    | sed 's/^Topic: //' | sort -u \
    | while IFS= read -r t; do
        count=$(grep -rl "^Topic: ${t}$" "$SAVE_DIR" 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  ${CYAN}${t}${NC}  ${DIM}(×${count})${NC}"
      done
  exit 0
fi

# ── SESSION STATS ─────────────────────────────────────────────
if [[ "$1" == "stats" || "$1" == "--stats" ]]; then
  echo -e "${WHITE}🚗 CarPool — Stats${NC}\n"
  total=$(ls -1 "$SAVE_DIR"/*.txt 2>/dev/null | wc -l | tr -d ' ')
  turns=$(grep -h "^[A-Z]*: " "$SAVE_DIR"/*.txt 2>/dev/null | grep -c "." || echo 0)
  words=$(grep -h "^[A-Z]*: " "$SAVE_DIR"/*.txt 2>/dev/null | wc -w | tr -d ' ')
  approved=$(grep -h "^VOTE: APPROVED" "$SAVE_DIR"/*.txt 2>/dev/null | wc -l | tr -d ' ')
  rejected=$(grep -h "^VOTE: REJECTED" "$SAVE_DIR"/*.txt 2>/dev/null | wc -l | tr -d ' ')
  echo -e "  Sessions     ${WHITE}${total}${NC}"
  echo -e "  Agent turns  ${WHITE}${turns}${NC}"
  echo -e "  Words spoken ${WHITE}${words}${NC}"
  echo -e "  Votes:       ${GREEN}${approved} approved${NC}  ${RED}${rejected} rejected${NC}\n"
  echo -e "  ${DIM}Most vocal agents:${NC}"
  for name in "${ALL_NAMES[@]}"; do
    agent_meta "$name"; C="\033[${COLOR_CODE}m"
    cnt=$(grep -h "^${name}: " "$SAVE_DIR"/*.txt 2>/dev/null | wc -l | tr -d ' ')
    bar=$(python3 -c "print('▓' * min(int(${cnt:-0}/2), 30))" 2>/dev/null)
    printf "    ${C}${EMOJI} %-10s${NC}  ${DIM}%3s turns  %s${NC}\n" "$name" "$cnt" "$bar"
  done
  exit 0
fi

# ── PIN NOTE TO RUNNING SESSION ───────────────────────────────
if [[ "$1" == "pin" || "$1" == "--pin" ]]; then
  note="${*:2}"
  [[ -z "$note" ]] && echo -ne "${CYAN}Note to pin: ${NC}" && read -r note
  [[ -z "$note" ]] && exit 1
  if [[ ! -d "$WORK_DIR" ]]; then
    echo -e "${RED}No active session.${NC}"; exit 1
  fi
  ts=$(date "+%H:%M")
  echo "[${ts}] 📌 ${note}" >> "$WORK_DIR/convo.txt"
  echo -e "${GREEN}✓ Pinned at ${ts}:${NC} ${note}"
  exit 0
fi

# ── SHARE — COPY EXPORT TO CLIPBOARD ─────────────────────────
if [[ "$1" == "share" || "$1" == "--share" ]]; then
  # Auto-export if no .md exists
  md=$(ls -1t "$SAVE_DIR"/*.md 2>/dev/null | head -1)
  if [[ -z "$md" ]]; then
    txt=$(ls -1t "$SAVE_DIR"/*.txt 2>/dev/null | head -1)
    [[ -z "$txt" ]] && echo "No sessions found." && exit 1
    bash "$0" export "$txt" >/dev/null
    md="${txt%.txt}.md"
  fi
  if command -v pbcopy &>/dev/null; then
    pbcopy < "$md"
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard < "$md"
  else
    echo -e "${YELLOW}No clipboard command found (pbcopy/xclip).${NC}"; exit 1
  fi
  echo -e "${GREEN}✓ Copied to clipboard:${NC} $(basename "$md")"
  exit 0
fi

# ── REPLAY SAVED SESSION ──────────────────────────────────────
if [[ "$1" == "replay" || "$1" == "--replay" ]]; then
  file="$2"
  if [[ -z "$file" ]]; then
    file=$(ls -1t "$SAVE_DIR" 2>/dev/null | head -1)
    [[ -z "$file" ]] && echo "No sessions found." && exit 1
    file="$SAVE_DIR/$file"
  elif [[ ! -f "$file" ]]; then
    file="$SAVE_DIR/$file"
  fi
  [[ ! -f "$file" ]] && echo "Session not found: $2" && exit 1

  # Print header lines
  head -5 "$file" | while IFS= read -r line; do
    echo -e "${DIM}${line}${NC}"
  done
  echo ""

  in_section="header"; skip=0
  while IFS= read -r line; do
    [[ $skip -lt 5 ]] && ((skip++)) && continue
    if [[ "$line" =~ ^═+ ]]; then continue; fi
    if [[ "$line" == "SYNTHESIS" ]]; then in_section="synthesis"; continue; fi
    if [[ "$line" == "DISPATCHES" ]]; then in_section="dispatches"; continue; fi
    if [[ "$line" =~ ^─+ ]]; then continue; fi
    if [[ -z "$line" ]]; then echo ""; continue; fi

    if [[ "$in_section" != "dispatches" ]]; then
      speaker="${line%%:*}"
      text="${line#*: }"
      agent_meta "$speaker"
      if [[ "$EMOJI" != "●" ]]; then
        COLOR="\033[${COLOR_CODE}m"
        if [[ "$in_section" == "synthesis" ]]; then
          echo -e "${YELLOW}${line}${NC}"; sleep 0.04
        else
          echo -e "${COLOR}${EMOJI} ${speaker}${NC}  ${text}"; sleep 0.05
        fi
      elif [[ "$in_section" == "synthesis" ]]; then
        echo -e "${YELLOW}${line}${NC}"
      fi
    else
      if [[ "$line" =~ ^\[ ]]; then
        name="${line//[\[\]]/}"
        agent_meta "$name"; COLOR="\033[${COLOR_CODE}m"
        echo -e "\n${COLOR}${EMOJI} ${name}${NC}"
      else
        echo -e "  ${DIM}${line}${NC}"
      fi
    fi
  done < "$file"
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
  CONTEXT=$(cat "$WORK_DIR/context.txt" 2>/dev/null | head -c 2000)

  # Per-agent model override (from --split or --models)
  _agent_model=$(cat "$WORK_DIR/${NAME}.model" 2>/dev/null)
  [[ -n "$_agent_model" ]] && MODEL="$_agent_model"

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

    # Check for live follow-up injected via `br carpool ask`
    followup=""
    if [[ -f "$WORK_DIR/followup.txt" ]]; then
      followup=$(cat "$WORK_DIR/followup.txt")
    fi

    # Final round = challenge mode: push back on something
    if [[ $((turn+1)) -eq $TURNS && $TURNS -gt 1 ]]; then
      challenge_hint="Challenge or find a flaw in the team's thinking so far. Be specific. "
    else
      challenge_hint=""
    fi

    # Round 2+: pick one other agent's last line to react to
    if [[ $turn -gt 0 && -n "$recent" ]]; then
      other_line=$(grep -v "^${NAME}:" "$CONVO_FILE" 2>/dev/null | tail -1)
      other_name="${other_line%%:*}"
      other_text="${other_line#*: }"
      reaction="Reacting to ${other_name}: \"${other_text:0:80}\" — "
    else
      reaction=""
    fi

    followup_line=""
    [[ -n "$followup" ]] && followup_line="NEW QUESTION from user: ${followup}"

    context_block=""
    if [[ -n "$CONTEXT" ]]; then
      ctx_label=$(cat "$WORK_DIR/context.label" 2>/dev/null || echo "Reference material")
      context_block="[${ctx_label}]
${CONTEXT}
---
"
    fi

    prompt="${context_block}[BlackRoad team on: ${TOPIC}]
${recent}
${followup_line}
${NAME} is ${PERSONA}.
${challenge_hint}${reaction}${NAME}: \""

    payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':True,
  'options':{'num_predict':70,'temperature':0.85,'stop':['\n','\"']}
}))" <<< "$prompt")

    STREAM_RAW="$WORK_DIR/${NAME}.raw"
    printf "\r\033[K"
    printf "${COLOR}${EMOJI} ${NAME}${NC} ${DIM}[r$((turn+1))]${NC} "
    curl -s -m 40 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$payload" \
      | env STREAM_RAW="$STREAM_RAW" python3 -c "
import sys,json,os
out=[]; f=open(os.environ['STREAM_RAW'],'w')
for line in sys.stdin:
    line=line.strip()
    if not line: continue
    try:
        d=json.loads(line)
        t=d.get('response','')
        if t: print(t,end='',flush=True); out.append(t)
        if d.get('done'): break
    except: pass
f.write(''.join(out)); f.close()
" 2>/dev/null
    echo ""
    raw=$(cat "$STREAM_RAW" 2>/dev/null)

    speech=$(echo "$raw" | sed 's/^[",: ]*//' | sed "s/^${NAME}[: ]*//" | tr -d '"' | head -1 | cut -c1-200)
    [[ -z "$speech" || ${#speech} -lt 5 ]] && speech="Need more context before committing to a position."

    short_topic=$(echo "$TOPIC" | cut -c1-55)
    dispatch="${DISPATCH_TMPL}${short_topic}"

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

    # Update shared progress for tmux status bar
    fin_done=$(ls "$WORK_DIR/"*.r${turn}.done 2>/dev/null | wc -l | tr -d ' ')
    echo "r$((turn+1))/${TURNS} · ${fin_done}/${TOTAL} done" > "$WORK_DIR/progress.txt"
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

        prompt="You are ${NAME}, ${ROLE} on the BlackRoad team.
Task: ${task}
Topic context: $(cat "$WORK_DIR/topic.txt" 2>/dev/null)
Provide 3 specific findings or action items. Start immediately:"

        payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'$MODEL','prompt':sys.stdin.read(),'stream':True,
  'options':{'num_predict':180,'temperature':0.7}
}))" <<< "$prompt")

        STREAM_RAW="$WORK_DIR/${NAME}.worker.raw"
        curl -s -m 50 -X POST http://localhost:11434/api/generate \
          -H "Content-Type: application/json" -d "$payload" \
          | env STREAM_RAW="$STREAM_RAW" python3 -c "
import sys,json,os
f=open(os.environ['STREAM_RAW'],'w'); out=[]
for line in sys.stdin:
    line=line.strip()
    if not line: continue
    try:
        d=json.loads(line)
        t=d.get('response','')
        if t: print(t,end='',flush=True); out.append(t)
        if d.get('done'): break
    except: pass
f.write(''.join(out)); f.close()
" 2>/dev/null
        echo ""
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
  name_part="${SESSION_NAME:+${SESSION_NAME}-}"
  session_file="${SAVE_DIR}/$(date +%Y-%m-%d_%H-%M)_${name_part}${slug}.txt"
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
  } > "$session_file"
  # (dispatches + vote tally appended below)

  echo -e "${DIM}Session saved → ${GREEN}${session_file}${NC}"
  echo -e "${DIM}tip: br carpool list | br carpool replay${NC}\n"

  # Auto-jump to vote tab
  sleep 1
  tmux select-window -t "$SESSION:🗳️ vote" 2>/dev/null

  # ── VOTE TALLY ─────────────────────────────────────────────
  echo -e "${WHITE}${BOLD}$(printf '%.0s━' {1..60})${NC}"
  echo -e "${WHITE}${BOLD}  🗳️  VOTE TALLY — waiting for agents...${NC}"
  echo -e "${WHITE}${BOLD}$(printf '%.0s━' {1..60})${NC}\n"

  while true; do
    vcount=$(ls "$WORK_DIR/"*.voted 2>/dev/null | wc -l | tr -d ' ')
    [[ $vcount -ge $TOTAL ]] && break
    echo -ne "\r${DIM}  ${vcount}/${TOTAL} votes in...${NC}"
    sleep 0.6
  done
  printf "\r\033[K"

  yes_count=0; no_count=0; yes_names=""; no_names=""
  for name in "${ALL_NAMES[@]}"; do
    v=$(cat "$WORK_DIR/${name}.voted" 2>/dev/null | tr -d '[:space:]')
    agent_meta "$name"; C="\033[${COLOR_CODE}m"
    if [[ "$v" == "YES" ]]; then
      ((yes_count++)); yes_names="${yes_names}${C}${EMOJI}${name}${NC} "
    else
      ((no_count++)); no_names="${no_names}${C}${EMOJI}${name}${NC} "
    fi
  done

  yes_bar=$(python3 -c "print('█' * $((yes_count * 4)))")
  no_bar=$(python3 -c "print('█' * $((no_count * 4)))")

  echo -e "  ${GREEN}${BOLD}YES  ${yes_count}  ${yes_bar}${NC}"
  echo -e "  ${DIM}       ${yes_names}${NC}\n"
  echo -e "  ${RED}${BOLD}NO   ${no_count}  ${no_bar}${NC}"
  echo -e "  ${DIM}       ${no_names}${NC}\n"

  if [[ $yes_count -gt $no_count ]]; then
    echo -e "${GREEN}${BOLD}  ✓  APPROVED  ${yes_count}–${no_count}${NC}\n"
    verdict="APPROVED ${yes_count}–${no_count}"
  elif [[ $no_count -gt $yes_count ]]; then
    echo -e "${RED}${BOLD}  ✗  REJECTED  ${no_count}–${yes_count}${NC}\n"
    verdict="REJECTED ${no_count}–${yes_count}"
  else
    echo -e "${YELLOW}${BOLD}  ~  SPLIT VOTE  ${yes_count}–${no_count}${NC}\n"
    verdict="SPLIT ${yes_count}–${no_count}"
  fi

  # Append dispatches + vote tally to session file
  {
    echo "$(printf '%.0s═' {1..60})"
    echo "VOTE: ${verdict}"
    echo "$(printf '%.0s─' {1..60})"
    for name in "${ALL_NAMES[@]}"; do
      v=$(cat "$WORK_DIR/${name}.voted" 2>/dev/null | tr -d '[:space:]')
      echo "  ${name}: ${v:-ABSTAIN}"
    done
    echo ""
    echo "$(printf '%.0s═' {1..60})"
    echo "DISPATCHES"
    echo "$(printf '%.0s─' {1..60})"
    for name in "${ALL_NAMES[@]}"; do
      echo "[$name]"
      cat "$WORK_DIR/${name}.queue" 2>/dev/null
      echo ""
    done
  } >> "$session_file"

  # ── PERSIST TO MEMORY ─────────────────────────────────────
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  mkdir -p "$(dirname "$MEMORY_FILE")"
  {
    echo "---"
    echo "DATE: $(date '+%Y-%m-%d %H:%M')"
    echo "TOPIC: $TOPIC"
    echo "VERDICT: $verdict"
    echo "$synthesis"
  } >> "$MEMORY_FILE"

  # Signal chain/headless waiters
  echo "$verdict" > "$WORK_DIR/session.complete"

  # Webhook notification (--notify or persistent ~/.blackroad/carpool/webhook.url)
  _wh=""; 
  [[ -f "$WORK_DIR/notify.url" ]] && _wh=$(cat "$WORK_DIR/notify.url")
  [[ -z "$_wh" && -f "$HOME/.blackroad/carpool/webhook.url" ]] && _wh=$(cat "$HOME/.blackroad/carpool/webhook.url")
  if [[ -n "$_wh" ]]; then
    _v="$verdict"; _t="$TOPIC"; _s="${synthesis:0:500}"
    _payload="{\"text\":\"🚗 *CarPool* — ${_t}\n*${_v}*\n\n${_s}\"}"
    curl -s -m 10 -X POST "$_wh" -H "Content-Type: application/json" -d "$_payload" >/dev/null 2>&1 && \
      echo -e "${DIM}📣 webhook sent${NC}"
  fi

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
    echo "NO" > "$WORK_DIR/${NAME}.voted"
  else
    VOTE_COLOR="\033[1;32m"; VOTE_WORD="✓  YES"
    echo "YES" > "$WORK_DIR/${NAME}.voted"
  fi

  echo -e "${COLOR}${BOLD}${EMOJI} ${NAME}${NC}\n"
  echo -e "${VOTE_COLOR}${BOLD}  ┌──────────┐${NC}"
  echo -e "${VOTE_COLOR}${BOLD}  │ ${VOTE_WORD} │${NC}"
  echo -e "${VOTE_COLOR}${BOLD}  └──────────┘${NC}\n"
  echo -e "${DIM}  ${vote}${NC}"
  while true; do sleep 60; done
fi

# ── DIFF TWO SESSIONS ─────────────────────────────────────────
if [[ "$1" == "diff" ]]; then
  f1="${2:-}"; f2="${3:-}"
  if [[ -z "$f1" || -z "$f2" ]]; then
    # Default: last two sessions
    files=($(ls -1t "$SAVE_DIR" 2>/dev/null | head -2))
    f1="${SAVE_DIR}/${files[0]}"; f2="${SAVE_DIR}/${files[1]}"
    [[ ! -f "$f1" || ! -f "$f2" ]] && echo -e "${RED}Need two saved sessions. Usage: br carpool diff <s1> <s2>${NC}" && exit 1
  fi
  [[ ! -f "$f1" ]] && f1="$SAVE_DIR/$f1"
  [[ ! -f "$f2" ]] && f2="$SAVE_DIR/$f2"
  [[ ! -f "$f1" ]] && echo "Not found: $f1" && exit 1
  [[ ! -f "$f2" ]] && echo "Not found: $f2" && exit 1

  _topic1=$(grep "^Topic:" "$f1" | sed 's/^Topic: //'); _topic2=$(grep "^Topic:" "$f2" | sed 's/^Topic: //')
  _model1=$(grep "^Model:" "$f1" | sed 's/^Model: //');  _model2=$(grep "^Model:" "$f2" | sed 's/^Model: //')
  _date1=$(grep "^Date:" "$f1" | sed 's/^Date:  //');   _date2=$(grep "^Date:" "$f2" | sed 's/^Date:  //')
  _verdict1=$(grep "^VERDICT:" "$f1" | sed 's/^VERDICT: //'); _verdict2=$(grep "^VERDICT:" "$f2" | sed 's/^VERDICT: //')

  W=38
  _pad() { printf "%-${W}s" "${1:0:$W}"; }

  echo -e "\n${WHITE}🚗 CarPool — Session Diff${NC}\n"
  printf "${DIM}%-${W}s  %-${W}s${NC}\n" "$(basename "$f1")" "$(basename "$f2")"
  printf "%-${W}s  %-${W}s\n" "$(printf '─%.0s' {1..38})" "$(printf '─%.0s' {1..38})"
  printf "${CYAN}%-${W}s${NC}  ${CYAN}%-${W}s${NC}\n" "$(_pad "$_topic1")" "$(_pad "$_topic2")"
  printf "${DIM}%-${W}s  %-${W}s${NC}\n" "$(_pad "$_model1")" "$(_pad "$_model2")"
  printf "${DIM}%-${W}s  %-${W}s${NC}\n" "$(_pad "$_date1")" "$(_pad "$_date2")"

  # Verdict coloring
  _vcolor1="\033[1;32m"; echo "$_verdict1" | grep -qi "reject\|split" && _vcolor1="\033[1;31m"
  _vcolor2="\033[1;32m"; echo "$_verdict2" | grep -qi "reject\|split" && _vcolor2="\033[1;31m"
  printf "${_vcolor1}%-${W}s${NC}  ${_vcolor2}%-${W}s${NC}\n\n" "$(_pad "$_verdict1")" "$(_pad "$_verdict2")"

  # Per-agent last statement
  echo -e "${DIM}Agent statements:${NC}"
  for entry in "${AGENT_LIST[@]}"; do
    IFS='|' read -r n _e _r _ <<< "$entry"
    agent_meta "$n"; C="\033[${COLOR_CODE}m"
    _s1=$(grep "^${n}:" "$f1" | tail -1 | sed "s/^${n}: //" | cut -c1-36)
    _s2=$(grep "^${n}:" "$f2" | tail -1 | sed "s/^${n}: //" | cut -c1-36)
    printf "${C}${EMOJI} %-10s${NC}  %-${W}s  %-${W}s\n" "$n" "${_s1:---}" "${_s2:---}"
  done

  # Synthesis snippets
  echo -e "\n${DIM}Synthesis snippets:${NC}"
  _syn1=$(awk '/^SYNTHESIS/,/^DISPATCHES/' "$f1" 2>/dev/null | grep -v "^SYNTHESIS\|^DISPATCHES\|^[═─]" | head -3 | tr '\n' ' ')
  _syn2=$(awk '/^SYNTHESIS/,/^DISPATCHES/' "$f2" 2>/dev/null | grep -v "^SYNTHESIS\|^DISPATCHES\|^[═─]" | head -3 | tr '\n' ' ')
  printf "${YELLOW}%-${W}s${NC}\n${YELLOW}%-${W}s${NC}\n" "${_syn1:0:$W}" "${_syn2:0:$W}"
  echo ""
  exit 0
fi

# ── WEB EXPORT ────────────────────────────────────────────────
if [[ "$1" == "web" ]]; then
  file="$2"
  if [[ -z "$file" ]]; then
    file=$(ls -1t "$SAVE_DIR" 2>/dev/null | head -1)
    [[ -z "$file" ]] && echo "No sessions found." && exit 1
    file="$SAVE_DIR/$file"
  elif [[ ! -f "$file" ]]; then
    file="$SAVE_DIR/$file"
  fi
  [[ ! -f "$file" ]] && echo "Not found: $2" && exit 1

  topic=$(grep "^Topic:" "$file" | sed 's/^Topic: //')
  meta=$(grep "^Model:" "$file" | sed 's/^Model: //')
  date_str=$(grep "^Date:" "$file" | sed 's/^Date:  //')
  verdict=$(grep "^VERDICT:" "$file" | sed 's/^VERDICT: //')
  out="${file%.txt}.html"

  _vclass="approved"; echo "$verdict" | grep -qi "reject" && _vclass="rejected"
  echo "$verdict" | grep -qi "split" && _vclass="split"

  {
cat <<'HTMLEOF'
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
HTMLEOF
    echo "<title>🚗 CarPool: ${topic}</title>"
cat <<'HTMLEOF'
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#0a0a0a;color:#e0e0e0;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text',sans-serif;font-size:14px;line-height:1.6;padding:24px}
.header{border-bottom:1px solid #222;padding-bottom:16px;margin-bottom:24px}
h1{font-size:22px;font-weight:700;color:#fff;margin-bottom:6px}
.meta{color:#555;font-size:12px}
.verdict{display:inline-block;padding:4px 14px;border-radius:20px;font-weight:700;font-size:13px;margin:12px 0}
.approved{background:#0d2e0d;color:#4caf50;border:1px solid #4caf50}
.rejected{background:#2e0d0d;color:#f44336;border:1px solid #f44336}
.split{background:#2e2a0d;color:#ffc107;border:1px solid #ffc107}
.section{margin:24px 0}
.section h2{font-size:13px;font-weight:600;color:#555;text-transform:uppercase;letter-spacing:.08em;margin-bottom:12px}
.agent-card{background:#111;border:1px solid #1e1e1e;border-radius:8px;padding:14px 16px;margin:10px 0}
.agent-header{display:flex;align-items:center;gap:8px;margin-bottom:8px}
.agent-name{font-weight:700;font-size:13px}
.agent-role{color:#555;font-size:11px}
.agent-text{color:#ccc;font-size:13px;line-height:1.55}
.synthesis{background:#111820;border:1px solid #1a2a3a;border-radius:8px;padding:16px;color:#9ec5e8;font-size:13px;line-height:1.6}
.vote-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:8px}
.vote-card{background:#111;border:1px solid #1e1e1e;border-radius:6px;padding:10px;display:flex;align-items:center;gap:8px}
.vote-yes{color:#4caf50;font-weight:700}.vote-no{color:#f44336;font-weight:700}
.dispatch-list{list-style:none}
.dispatch-list li{padding:4px 0;border-bottom:1px solid #111;color:#888;font-size:12px}
footer{margin-top:32px;text-align:center;color:#333;font-size:11px}
</style></head><body>
HTMLEOF

    echo "<div class='header'><h1>🚗 ${topic}</h1>"
    echo "<div class='meta'>${date_str} · ${meta}</div>"
    echo "<div class='verdict ${_vclass}'>${verdict}</div></div>"

    # Conversation section
    echo "<div class='section'><h2>Discussion</h2>"
    while IFS= read -r line; do
      speaker="${line%%:*}"; text="${line#*: }"
      agent_meta "$speaker" 2>/dev/null
      [[ -z "$ROLE" || "$ROLE" == "" ]] && continue
      echo "<div class='agent-card'><div class='agent-header'>"
      echo "<span class='agent-name'>${EMOJI} ${speaker}</span>"
      echo "<span class='agent-role'>${ROLE}</span></div>"
      echo "<div class='agent-text'>$(echo "$text" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g')</div></div>"
    done < <(grep -E "^[A-Z]+: " "$file" | grep -v "^Topic:\|^Model:\|^Date:\|^VERDICT:")

    echo "</div>"

    # Synthesis
    _syn=$(awk '/^SYNTHESIS/,/^(DISPATCHES|VOTE:)/' "$file" | grep -v "^SYNTHESIS\|^DISPATCHES\|^[═─]" | grep -v "^$" | head -20)
    if [[ -n "$_syn" ]]; then
      echo "<div class='section'><h2>Synthesis</h2><div class='synthesis'>"
      echo "$_syn" | sed 's/&/\&amp;/g;s/</\&lt;/g;s/>/\&gt;/g;s/$/<br>/'
      echo "</div></div>"
    fi

    # Votes
    echo "<div class='section'><h2>Vote</h2><div class='vote-grid'>"
    for entry in "${AGENT_LIST[@]}"; do
      IFS='|' read -r n _e _r _ <<< "$entry"; agent_meta "$n"
      _v=$(grep "^  ${n}: " "$file" | grep -oE "YES|NO" | head -1)
      [[ -z "$_v" ]] && continue
      _vc="vote-yes"; [[ "$_v" == "NO" ]] && _vc="vote-no"
      echo "<div class='vote-card'><span>${EMOJI}</span><span>${n}</span><span class='${_vc}'>${_v}</span></div>"
    done
    echo "</div></div>"

    echo "<footer>Generated by 🚗 CarPool · BlackRoad OS</footer></body></html>"
  } > "$out"

  echo -e "${GREEN}✓${NC} Web export → ${CYAN}${out}${NC}"
  open "$out" 2>/dev/null || xdg-open "$out" 2>/dev/null || echo "Open in browser: file://${out}"
  exit 0
fi

# ── REACT (quick-reaction shorthand) ─────────────────────────
if [[ "$1" == "react" ]]; then
  target="${2:-}"
  question="${3:-What are the key issues, risks, and recommended actions?}"
  [[ -z "$target" ]] && echo -e "${RED}Usage: br carpool react <file|url> [question]${NC}" && exit 1
  if echo "$target" | grep -q "^https\?://"; then
    exec bash "$0" --brief --url "$target" "$question"
  else
    exec bash "$0" --brief --context "$target" "$question"
  fi
fi

# ── MEMORY management ────────────────────────────────────────
if [[ "$1" == "memory" ]]; then
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  case "${2:-show}" in
    show|list)
      if [[ ! -f "$MEMORY_FILE" ]]; then
        echo -e "${DIM}No memory yet. Run sessions to build memory.${NC}"; exit 0
      fi
      echo -e "${WHITE}🧠 CarPool Memory${NC}  ${DIM}(last sessions)${NC}\n"
      count=0
      while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
          ((count++)); echo -e "\n${DIM}── #${count} ──────────────────────────────────────${NC}"
        elif [[ "$line" =~ ^DATE: ]]; then
          echo -e "${DIM}${line}${NC}"
        elif [[ "$line" =~ ^TOPIC: ]]; then
          echo -e "${CYAN}${line}${NC}"
        elif [[ "$line" =~ ^VERDICT: ]]; then
          v="${line#VERDICT: }"
          c="${GREEN}"; echo "$v" | grep -qi "reject\|split" && c="${YELLOW}"
          echo -e "${c}${line}${NC}"
        else
          echo -e "${DIM}${line}${NC}"
        fi
      done < "$MEMORY_FILE"
      echo ""
      ;;
    clear)
      rm -f "$MEMORY_FILE"
      echo -e "${GREEN}✓${NC} Memory cleared."
      ;;
    stats)
      [[ ! -f "$MEMORY_FILE" ]] && echo "No memory yet." && exit 0
      total=$(grep -c "^---" "$MEMORY_FILE" 2>/dev/null || echo 0)
      approved=$(grep -c "^VERDICT: APPROVED" "$MEMORY_FILE" 2>/dev/null || echo 0)
      rejected=$(grep -c "^VERDICT: REJECTED" "$MEMORY_FILE" 2>/dev/null || echo 0)
      echo -e "${WHITE}🧠 Memory Stats${NC}"
      echo -e "  sessions: ${CYAN}${total}${NC}"
      echo -e "  approved: ${GREEN}${approved}${NC}  rejected: ${RED}${rejected}${NC}"
      ;;
    *)
      echo -e "${RED}Usage: br carpool memory [show|clear|stats]${NC}" ;;
  esac
  exit 0
fi

# ── CHAIN — sequential topic pipeline ────────────────────────
if [[ "$1" == "chain" ]]; then
  shift
  CHAIN_TOPICS=("$@")
  [[ ${#CHAIN_TOPICS[@]} -lt 2 ]] && echo -e "${RED}Usage: br carpool chain \"topic1\" \"topic2\" ...${NC}" && exit 1

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "${WHITE}🔗 CarPool Chain${NC}  ${DIM}${#CHAIN_TOPICS[@]} topics${NC}\n"
  for i in "${!CHAIN_TOPICS[@]}"; do
    echo -e "  ${CYAN}$((i+1))${NC}  ${CHAIN_TOPICS[$i]}"
  done
  echo ""

  prev_synthesis=""
  for i in "${!CHAIN_TOPICS[@]}"; do
    topic="${CHAIN_TOPICS[$i]}"
    step=$((i+1)); total_steps=${#CHAIN_TOPICS[@]}
    echo -e "${WHITE}$(printf '%.0s━' {1..60})${NC}"
    echo -e "${WHITE}🔗 Step ${step}/${total_steps}:${NC} ${CYAN}${topic}${NC}"
    echo -e "${WHITE}$(printf '%.0s━' {1..60})${NC}\n"

    # Build args: inject previous synthesis as context
    extra_args=("--brief")
    if [[ -n "$prev_synthesis" ]]; then
      _ctx_tmp=$(mktemp /tmp/carpool_chain_XXXX.txt)
      echo "=== PREVIOUS SYNTHESIS ===" > "$_ctx_tmp"
      echo "$prev_synthesis" >> "$_ctx_tmp"
      echo "=== BUILD ON THIS ===" >> "$_ctx_tmp"
      extra_args+=("--context" "$_ctx_tmp")
    fi

    # Launch and wait for session.complete
    bash "$SCRIPT_PATH" "${extra_args[@]}" "$topic" &
    _chain_pid=$!

    # Attach to tmux to watch, then background-wait for completion
    sleep 2
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$SESSION" 2>/dev/null
    else
      tmux attach -t "$SESSION" 2>/dev/null &
    fi

    # Poll for session completion (synthesis written)
    echo -ne "${DIM}waiting for step ${step} to complete...${NC}"
    waited=0
    while [[ ! -f "$WORK_DIR/session.complete" && $waited -lt 300 ]]; do
      sleep 2; ((waited+=2))
    done
    printf "\r\033[K"

    prev_synthesis=$(cat "$WORK_DIR/synthesis.txt" 2>/dev/null)
    [[ -n "$_ctx_tmp" ]] && rm -f "$_ctx_tmp" 2>/dev/null; _ctx_tmp=""

    verdict=$(cat "$WORK_DIR/session.complete" 2>/dev/null)
    echo -e "${GREEN}✓ Step ${step} complete:${NC} ${verdict}\n"

    # Kill tmux session between steps
    tmux kill-session -t "$SESSION" 2>/dev/null
    sleep 1
  done

  echo -e "${WHITE}🔗 Chain complete — ${#CHAIN_TOPICS[@]} topics processed${NC}"
  echo -e "${DIM}tip: br carpool memory show${NC}"
  exit 0
fi

# ── PR CODE REVIEW ────────────────────────────────────────────
if [[ "$1" == "pr" ]]; then
  pr_ref="${2:-}"
  question="${3:-Review this PR: what's good, what's risky, what needs changing in one sentence each?}"
  [[ -z "$pr_ref" ]] && echo -e "${RED}Usage: br carpool pr <owner/repo#N> [question]${NC}" && exit 1

  if echo "$pr_ref" | grep -q "#"; then
    _repo="${pr_ref%#*}"; _num="${pr_ref##*#}"
    echo -e "${CYAN}🔍 fetching PR #${_num} from ${_repo}...${NC}"
    diff_text=$(gh pr diff "$_num" --repo "$_repo" 2>/dev/null | head -c 5000)
    pr_title=$(gh pr view "$_num" --repo "$_repo" --json title -q '.title' 2>/dev/null)
  else
    _num="$pr_ref"
    echo -e "${CYAN}🔍 fetching PR #${_num} from current repo...${NC}"
    diff_text=$(gh pr diff "$_num" 2>/dev/null | head -c 5000)
    pr_title=$(gh pr view "$_num" --json title -q '.title' 2>/dev/null)
  fi

  if [[ -z "$diff_text" ]]; then
    echo -e "${RED}Could not fetch PR diff. Is gh authenticated? Is this a valid PR?${NC}"; exit 1
  fi

  _pr_ctx=$(mktemp /tmp/carpool_pr_XXXX.txt)
  echo "=== PR: ${pr_title} ===" > "$_pr_ctx"
  echo "$diff_text" >> "$_pr_ctx"

  echo -e "${GREEN}✓ ${pr_title:-PR #${_num}}${NC}  ${DIM}$(echo "$diff_text" | wc -l) diff lines${NC}\n"
  _q="${pr_title:+Review: ${pr_title} — }${question}"
  exec bash "$0" --brief --crew "OCTAVIA,CIPHER,SHELLFISH,PRISM,ALICE" --context "$_pr_ctx" "$_q"
fi

# ── TEMPLATES — preset crew+topic combos ─────────────────────
if [[ "$1" == "template" || "$1" == "t" ]]; then
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  case "${2:-list}" in
    list)
      echo -e "${WHITE}🚗 CarPool Templates${NC}\n"
      echo -e "  ${CYAN}sprint${NC}     ALICE,OCTAVIA,PRISM,LUCIDIA   Sprint planning & prioritization"
      echo -e "  ${CYAN}security${NC}   CIPHER,SHELLFISH,PRISM,OCTAVIA  Security audit & threat model"
      echo -e "  ${CYAN}ux${NC}         ARIA,LUCIDIA,ECHO,PRISM        UX & user experience review"
      echo -e "  ${CYAN}arch${NC}       OCTAVIA,LUCIDIA,PRISM,ALICE    Architecture decision record"
      echo -e "  ${CYAN}risk${NC}       CIPHER,PRISM,ECHO,LUCIDIA      Risk assessment"
      echo -e "  ${CYAN}retro${NC}      ECHO,PRISM,ALICE,LUCIDIA       Sprint retrospective"
      echo -e "  ${CYAN}ship${NC}       all 8 agents                    Ship/no-ship decision\n"
      echo -e "${DIM}Usage: br carpool template <name> [\"custom topic\"]${NC}"
      ;;
    sprint)   exec bash "$SCRIPT_PATH" --crew "ALICE,OCTAVIA,PRISM,LUCIDIA"      "${3:-What should we prioritize and build this sprint?}" ;;
    security) exec bash "$SCRIPT_PATH" --crew "CIPHER,SHELLFISH,PRISM,OCTAVIA"   "${3:-Security audit — threats, vulnerabilities, mitigations}" ;;
    ux)       exec bash "$SCRIPT_PATH" --crew "ARIA,LUCIDIA,ECHO,PRISM"          "${3:-UX review — what works, what hurts, what users need}" ;;
    arch)     exec bash "$SCRIPT_PATH" --crew "OCTAVIA,LUCIDIA,PRISM,ALICE"      "${3:-Architecture decision — options, tradeoffs, recommendation}" ;;
    risk)     exec bash "$SCRIPT_PATH" --crew "CIPHER,PRISM,ECHO,LUCIDIA"        "${3:-Risk assessment — likelihood, impact, mitigations}" ;;
    retro)    exec bash "$SCRIPT_PATH" --crew "ECHO,PRISM,ALICE,LUCIDIA"         "${3:-Retrospective — what worked, what did not, what to change}" ;;
    ship)     exec bash "$SCRIPT_PATH"                                            "${3:-Ship or no-ship — is it ready to release?}" ;;
    *)        echo -e "${RED}Unknown template: $2${NC}  Run: br carpool template list" ;;
  esac
  exit 0
fi

# ── DEBATE — structured 1v1 head-to-head ─────────────────────
if [[ "$1" == "debate" ]]; then
  _a1="${2:-LUCIDIA}"; _a2="${3:-CIPHER}"; _topic="${4:-}"
  if [[ -z "$_topic" ]]; then
    echo -ne "${CYAN}Debate topic (${_a1} vs ${_a2}): ${NC}"
    read -r _topic
    [[ -z "$_topic" ]] && _topic="Is decentralization always the right answer?"
  fi

  # Validate agents
  _valid="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH"
  for _check in "$_a1" "$_a2"; do
    echo "$_valid" | grep -qw "$_check" || { echo -e "${RED}Unknown agent: ${_check}${NC}"; exit 1; }
  done

  agent_meta "$_a1"; _c1="\033[${COLOR_CODE}m"; _e1="$EMOJI"
  agent_meta "$_a2"; _c2="\033[${COLOR_CODE}m"; _e2="$EMOJI"

  echo -e "\n${WHITE}⚔️  CarPool Debate${NC}"
  echo -e "  ${_c1}${_e1} ${_a1}${NC}  vs  ${_c2}${_e2} ${_a2}${NC}"
  echo -e "  ${DIM}${_topic}${NC}\n"

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --crew "${_a1},${_a2}" --turns 4 "$_topic"
fi

# ── DIGEST — AI summary of memory ────────────────────────────
if [[ "$1" == "digest" ]]; then
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  if [[ ! -f "$MEMORY_FILE" ]]; then
    echo -e "${DIM}No memory yet — run some sessions first.${NC}"; exit 0
  fi

  session_count=$(grep -c "^---" "$MEMORY_FILE" 2>/dev/null || echo 0)
  echo -e "${WHITE}🧠 CarPool Digest${NC}  ${DIM}${session_count} sessions${NC}\n"

  mem_sample=$(tail -300 "$MEMORY_FILE")
  prompt="Here are summaries of recent AI team sessions:
${mem_sample}

Write a concise digest (under 100 words) with:
THEMES: 2-3 recurring themes across sessions
MOMENTUM: what direction the team is trending  
OPEN: biggest unresolved question
Keep it sharp and actionable."

  payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'tinyllama','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':180,'temperature':0.5,'stop':['---']}
}))" <<< "$prompt")

  digest=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

  echo -e "${YELLOW}${digest}${NC}\n"

  # Save digest
  digest_file="$HOME/.blackroad/carpool/digest-$(date +%Y-%m-%d).txt"
  { echo "CarPool Digest — $(date)"; echo ""; echo "$digest"; } > "$digest_file"
  echo -e "${DIM}Saved → ${digest_file}${NC}"
  exit 0
fi

# ── SCORE — agent leaderboard across all saved sessions ──────
if [[ "$1" == "score" ]]; then
  [[ ! -d "$SAVE_DIR" ]] && echo "No saved sessions yet." && exit 0
  echo -e "${WHITE}🏆 CarPool Leaderboard${NC}\n"

  declare -A _wins _apps _dispatches _mentions
  ALL_AGENT_NAMES="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH"

  for f in "$SAVE_DIR"/*.txt; do
    [[ -f "$f" ]] || continue
    for name in $ALL_AGENT_NAMES; do
      # Count approvals/rejections where this agent voted
      _vote=$(grep -c "^${name} votes YES" "$f" 2>/dev/null || echo 0)
      _apps[$name]=$(( ${_apps[$name]:-0} + _vote ))
      # Count dispatches
      _d=$(grep -c "\[dispatch\].*${name}\|${name}.*dispatch" "$f" 2>/dev/null || echo 0)
      _dispatches[$name]=$(( ${_dispatches[$name]:-0} + _d ))
      # Count total lines mentioning the agent
      _m=$(grep -c "^${name}:" "$f" 2>/dev/null || echo 0)
      _mentions[$name]=$(( ${_mentions[$name]:-0} + _m ))
    done
    # Award "win" to agents in winning-side sessions
    v=$(grep "^VERDICT:" "$f" 2>/dev/null | tail -1)
    if echo "$v" | grep -qi "approved\|yes\|ship"; then
      for name in $ALL_AGENT_NAMES; do
        if grep -q "^${name} votes YES" "$f" 2>/dev/null; then
          _wins[$name]=$(( ${_wins[$name]:-0} + 1 ))
        fi
      done
    fi
  done

  # Print table
  printf "  %-12s %6s %6s %6s %6s\n" "AGENT" "LINES" "YES" "DISPATCH" "WINS"
  printf "  %-12s %6s %6s %6s %6s\n" "────────────" "─────" "─────" "────────" "────"
  for name in $ALL_AGENT_NAMES; do
    agent_meta "$name"
    _c="\033[${COLOR_CODE}m"
    printf "  ${_c}%-12s${NC} %6d %6d %8d %6d\n" \
      "${EMOJI} ${name}" \
      "${_mentions[$name]:-0}" \
      "${_apps[$name]:-0}" \
      "${_dispatches[$name]:-0}" \
      "${_wins[$name]:-0}"
  done

  session_total=$(ls "$SAVE_DIR"/*.txt 2>/dev/null | wc -l | tr -d ' ')
  echo -e "\n${DIM}across ${session_total} sessions  ·  br carpool history for full list${NC}"
  exit 0
fi

# ── AGENDA — run topics from a file as a chain ───────────────
if [[ "$1" == "agenda" ]]; then
  agenda_file="${2:-}"
  [[ -z "$agenda_file" ]] && echo -e "${RED}Usage: br carpool agenda <file>${NC}" && exit 1
  [[ ! -f "$agenda_file" ]] && echo -e "${RED}File not found: ${agenda_file}${NC}" && exit 1

  # Read non-empty, non-comment lines
  mapfile_topics=()
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"  # ltrim
    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    mapfile_topics+=("$line")
  done < "$agenda_file"

  count="${#mapfile_topics[@]}"
  [[ $count -eq 0 ]] && echo "No topics found in ${agenda_file}" && exit 1

  echo -e "${WHITE}📋 CarPool Agenda${NC}  ${DIM}${agenda_file} · ${count} topics${NC}\n"
  for i in "${!mapfile_topics[@]}"; do
    echo -e "  ${CYAN}$((i+1)).${NC} ${mapfile_topics[$i]}"
  done
  echo ""

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" chain "${mapfile_topics[@]}"
fi

# ── SPOTLIGHT — one-agent deep dive, 3 focused turns ─────────
if [[ "$1" == "spotlight" ]]; then
  _agent="${2:-}"
  _topic="${3:-}"
  if [[ -z "$_agent" ]]; then
    echo -e "${CYAN}Spotlight which agent? (LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH): ${NC}"
    read -r _agent
  fi
  _valid="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH"
  echo "$_valid" | grep -qw "$_agent" || { echo -e "${RED}Unknown agent: ${_agent}${NC}"; exit 1; }

  if [[ -z "$_topic" ]]; then
    agent_meta "$_agent"
    echo -ne "${CYAN}Topic for ${EMOJI} ${_agent}: ${NC}"
    read -r _topic
    [[ -z "$_topic" ]] && _topic="What is your honest take on the current state of AI development?"
  fi

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "\n${WHITE}🔦 Spotlight:${NC} ${_agent}  ${DIM}${_topic}${NC}\n"
  exec bash "$SCRIPT_PATH" --crew "$_agent" --turns 3 --smart "$_topic"
fi

# ── POLL — structured multi-choice vote ──────────────────────
if [[ "$1" == "poll" ]]; then
  _question="${2:-}"
  shift 2 2>/dev/null || shift "$#" 2>/dev/null
  _options=("$@")

  if [[ -z "$_question" ]]; then
    echo -ne "${CYAN}Poll question: ${NC}"; read -r _question
  fi
  if [[ ${#_options[@]} -eq 0 ]]; then
    echo -ne "${CYAN}Option A: ${NC}"; read -r _oa
    echo -ne "${CYAN}Option B: ${NC}"; read -r _ob
    echo -ne "${CYAN}Option C (blank to skip): ${NC}"; read -r _oc
    _options=("$_oa" "$_ob")
    [[ -n "$_oc" ]] && _options+=("$_oc")
  fi

  # Build option list string
  _opts_str=""
  _letter=A
  for _o in "${_options[@]}"; do
    _opts_str="${_opts_str}${_letter}) ${_o}  "
    _letter=$(echo "$_letter" | tr 'A-Y' 'B-Z')
  done

  _poll_topic="${_question} | Options: ${_opts_str}Each agent: pick one option (A/B/C...) and explain why in 1-2 sentences. End your turn with: VOTE: <letter>"

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "\n${WHITE}🗳️  CarPool Poll${NC}"
  echo -e "  ${_question}"
  _i=1; _letter=A
  for _o in "${_options[@]}"; do
    echo -e "  ${CYAN}${_letter})${NC} ${_o}"; _letter=$(echo "$_letter" | tr 'A-Y' 'B-Z')
  done
  echo ""
  exec bash "$SCRIPT_PATH" --brief "$_poll_topic"
fi

# ── ROAST — devil's advocate: agents poke holes ──────────────
if [[ "$1" == "roast" ]]; then
  _idea="${2:-}"
  [[ -z "$_idea" ]] && echo -ne "${CYAN}What idea should we roast? ${NC}" && read -r _idea
  [[ -z "$_idea" ]] && echo "Need an idea to roast." && exit 1

  _roast_topic="DEVIL'S ADVOCATE SESSION: '${_idea}'
Your job is to be skeptical, critical, and contrarian — from YOUR specific domain lens.
Find the fatal flaws, hidden assumptions, worst-case scenarios, and things everyone is ignoring.
Be direct, specific, and unflinching. No cheerleading. End with your single biggest concern."

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "\n${RED}🔥 CarPool Roast${NC}  ${DIM}${_idea}${NC}\n"
  exec bash "$SCRIPT_PATH" --brief --crew "CIPHER,SHELLFISH,PRISM,LUCIDIA,OCTAVIA" "$_roast_topic"
fi

# ── TWEET — each agent's hot take on last synthesis ──────────
if [[ "$1" == "tweet" ]]; then
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  # Get last synthesis block
  if [[ -f "$MEMORY_FILE" ]]; then
    last_block=$(awk '/^---/{block=""} {block=block"\n"$0} END{print block}' "$MEMORY_FILE")
    last_topic=$(echo "$last_block" | grep "^TOPIC:" | head -1 | sed 's/^TOPIC: //')
    last_verdict=$(echo "$last_block" | grep "^VERDICT:" | head -1 | sed 's/^VERDICT: //')
    last_synth=$(echo "$last_block" | grep -v "^---\|^DATE:\|^TOPIC:\|^VERDICT:" | head -10)
  else
    last_topic="AI and the future of software development"
    last_verdict="APPROVED"
    last_synth="Teams should lean into AI tooling while preserving human judgment."
  fi

  echo -e "${WHITE}🐦 CarPool Tweets${NC}  ${DIM}${last_topic}${NC}\n"

  for name in LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER; do
    agent_meta "$name"
    _c="\033[${COLOR_CODE}m"
    echo -ne "  ${_c}${EMOJI} ${name}${NC}  ${DIM}thinking...${NC}"

    _tw_prompt="You are ${name}, ${ROLE}.
Recent team verdict on '${last_topic}': ${last_verdict}
Key insight: ${last_synth}

Write ONE tweet (max 240 chars) — your hot take, from your ${ROLE} perspective.
Be bold, sharp, specific. No hashtags. No fluff. Just the take."

    _tw_payload=$(python3 -c "
import json,sys
print(json.dumps({
  'model':'tinyllama','prompt':sys.stdin.read(),'stream':False,
  'options':{'num_predict':60,'temperature':0.8,'stop':['\n\n']}
}))" <<< "$_tw_prompt")

    _tw=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_tw_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

    printf "\r\033[K"
    echo -e "  ${_c}${EMOJI} ${name}${NC}\n  ${_tw}\n"
  done
  exit 0
fi

# ── TEACH — agents explain a concept from their lens ─────────
if [[ "$1" == "teach" ]]; then
  _concept="${2:-}"
  [[ -z "$_concept" ]] && echo -ne "${CYAN}What concept to explain? ${NC}" && read -r _concept
  [[ -z "$_concept" ]] && _concept="How the internet actually works"

  _teach_topic="TEACHING SESSION: '${_concept}'
Explain this concept clearly from YOUR specific domain and perspective.
Give the most important insight a non-expert would miss.
Use one concrete example or analogy. Keep it under 80 words. No jargon."

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "\n${WHITE}📚 CarPool Teach${NC}  ${DIM}${_concept}${NC}\n"
  exec bash "$SCRIPT_PATH" --brief --crew "LUCIDIA,ALICE,OCTAVIA,CIPHER,PRISM,ECHO" "$_teach_topic"
fi

# ── COMPARE — structured A vs B analysis ─────────────────────
if [[ "$1" == "compare" ]]; then
  _a="${2:-}"; _b="${3:-}"
  if [[ -z "$_a" || -z "$_b" ]]; then
    echo -ne "${CYAN}Compare A: ${NC}"; read -r _a
    echo -ne "${CYAN}    vs B: ${NC}"; read -r _b
  fi

  _cmp_topic="STRUCTURED COMPARISON: '${_a}' vs '${_b}'
Analyze BOTH from YOUR domain perspective. Be specific about:
- Where '${_a}' wins  
- Where '${_b}' wins  
- Which you would choose and why (one sentence)
No fence-sitting. Pick a side."

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "\n${WHITE}⚖️  CarPool Compare${NC}"
  echo -e "  ${CYAN}${_a}${NC}  vs  ${CYAN}${_b}${NC}\n"
  exec bash "$SCRIPT_PATH" --brief "$_cmp_topic"
fi

# ── SCHEDULE — cron-based recurring sessions ─────────────────
if [[ "$1" == "schedule" ]]; then
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  case "${2:-list}" in
    list)
      echo -e "${WHITE}⏰ CarPool Schedule${NC}\n"
      existing=$(crontab -l 2>/dev/null | grep "br carpool\|carpool.sh")
      if [[ -z "$existing" ]]; then
        echo -e "  ${DIM}No scheduled sessions. Add one:${NC}"
        echo -e "  ${CYAN}br carpool schedule daily \"topic\"${NC}"
        echo -e "  ${CYAN}br carpool schedule weekly \"topic\"${NC}"
        echo -e "  ${CYAN}br carpool schedule remove${NC}"
      else
        echo "$existing" | while IFS= read -r line; do
          echo -e "  ${CYAN}•${NC} $line"
        done
      fi
      ;;
    daily)
      _t="${3:-What should the team focus on today?}"
      _cron="0 9 * * 1-5 bash '${SCRIPT_PATH}' --brief --memory '${_t}' >> \$HOME/.blackroad/carpool/cron.log 2>&1"
      (crontab -l 2>/dev/null; echo "$_cron") | crontab -
      echo -e "${GREEN}✓ Daily 9am Mon-Fri:${NC} ${_t}"
      ;;
    weekly)
      _t="${3:-Weekly team sync: what went well, what to change, what to ship?}"
      _cron="0 9 * * 1 bash '${SCRIPT_PATH}' --brief --memory '${_t}' >> \$HOME/.blackroad/carpool/cron.log 2>&1"
      (crontab -l 2>/dev/null; echo "$_cron") | crontab -
      echo -e "${GREEN}✓ Weekly Monday 9am:${NC} ${_t}"
      ;;
    remove)
      crontab -l 2>/dev/null | grep -v "carpool.sh\|br carpool" | crontab -
      echo -e "${GREEN}✓ Removed all CarPool cron jobs${NC}"
      ;;
    log)
      _log="$HOME/.blackroad/carpool/cron.log"
      [[ -f "$_log" ]] && tail -50 "$_log" || echo "No cron log yet."
      ;;
    *)
      echo -e "${RED}Usage: br carpool schedule [list|daily|weekly|remove|log]${NC}"
      ;;
  esac
  exit 0
fi
if [[ "$1" == "last" ]]; then
  f=$(ls -1t "$SAVE_DIR" 2>/dev/null | head -1)
  [[ -z "$f" ]] && echo "No saved sessions yet." && exit 1
  less "$SAVE_DIR/$f"
  exit 0
fi

# ── PARSE SPEED FLAGS ──────────────────────────────────────────
SESSION_NAME=""
BRIEF=0
CONTEXT_FILE=""
CONTEXT_URL=""
SPLIT_MODELS=0
MODELS_MAP=""
CREW=""
USE_MEMORY=0
NOTIFY_WEBHOOK=""
while [[ "${1:0:2}" == "--" ]]; do
  case "$1" in
    --fast)      MODEL="tinyllama"; TURNS=2; shift ;;
    --smart)     MODEL="llama3.2:1b"; TURNS=3; shift ;;
    --turbo)     MODEL="llama3.2:1b"; TURNS=2; shift ;;
    --brief)     TURNS=1; BRIEF=1; shift ;;
    --model|-m)  MODEL="$2"; shift 2 ;;
    --turns|-t)  TURNS="$2"; shift 2 ;;
    --name|-n)   SESSION_NAME="$2"; shift 2 ;;
    --context|-c) CONTEXT_FILE="$2"; shift 2 ;;
    --url)       CONTEXT_URL="$2"; shift 2 ;;
    --split)     SPLIT_MODELS=1; shift ;;
    --models)    MODELS_MAP="$2"; shift 2 ;;
    --crew)      CREW="$2"; shift 2 ;;
    --memory)    USE_MEMORY=1; shift ;;
    --notify)    NOTIFY_WEBHOOK="$2"; shift 2 ;;
    *) break ;;
  esac
done

TOPIC="${1:-}"

# ── TOPIC SUGGESTIONS when none given ────────────────────────
if [[ -z "$TOPIC" ]]; then
  SUGGESTIONS=(
    "Should BlackRoad rebuild the CLI in Rust?"
    "How do we scale CarPool to 30,000 agents?"
    "What would make BlackRoad OS enterprise-ready?"
    "How should we handle AI model failures gracefully?"
    "Should we open-source part of BlackRoad?"
    "What's the fastest path to a paid product?"
  )
  echo -e "${WHITE}🚗 CarPool${NC}  ${DIM}model:${NC} ${MODEL}  ${DIM}turns:${NC} ${TURNS}\n"
  echo -e "${DIM}Suggested topics:${NC}"
  for i in "${!SUGGESTIONS[@]}"; do
    echo -e "  ${CYAN}$((i+1))${NC}  ${SUGGESTIONS[$i]}"
  done
  echo -e "  ${CYAN}?${NC}  ${DIM}or type your own${NC}\n"
  echo -ne "${WHITE}Topic [1-6 or text]: ${NC}"
  read -r topic_input
  if [[ "$topic_input" =~ ^[1-6]$ ]]; then
    TOPIC="${SUGGESTIONS[$((topic_input-1))]}"
  elif [[ -n "$topic_input" ]]; then
    TOPIC="$topic_input"
  else
    TOPIC="What should BlackRoad build next?"
  fi
fi

# ── MODEL AUTO-DETECT ─────────────────────────────────────────
_model_available() {
  curl -s -m 5 http://localhost:11434/api/tags 2>/dev/null \
    | python3 -c "
import sys,json
data=json.load(sys.stdin)
names=[m['name'] for m in data.get('models',[])]
t=sys.argv[1]
print('yes' if any(n==t or n.startswith(t+':') for n in names) else 'no')
" "$1" 2>/dev/null
}

if [[ $(_model_available "$MODEL") != "yes" ]]; then
  echo -e "${YELLOW}⚠ Model '${MODEL}' not found on cecilia. Checking alternatives...${NC}"
  for fallback in tinyllama llama3.2:1b llama3.2 cece qwen2.5-coder:3b; do
    if [[ $(_model_available "$fallback") == "yes" ]]; then
      echo -e "${GREEN}✓ Using: ${fallback}${NC}\n"
      MODEL="$fallback"; break
    fi
  done
fi

# ── CREW FILTER ───────────────────────────────────────────────
if [[ -n "$CREW" ]]; then
  IFS=',' read -ra CREW_LIST <<< "$CREW"
  NEW_AGENT_LIST=(); NEW_ALL_NAMES=()
  for entry in "${AGENT_LIST[@]}"; do
    IFS='|' read -r n _ _ _ <<< "$entry"
    for cn in "${CREW_LIST[@]}"; do
      if [[ "$n" == "${cn^^}" ]]; then
        NEW_AGENT_LIST+=("$entry"); NEW_ALL_NAMES+=("$n"); break
      fi
    done
  done
  if [[ ${#NEW_AGENT_LIST[@]} -eq 0 ]]; then
    echo -e "${RED}No valid agents in crew: ${CREW}${NC}"
    echo -e "${DIM}Valid: LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH${NC}"; exit 1
  fi
  AGENT_LIST=("${NEW_AGENT_LIST[@]}"); ALL_NAMES=("${NEW_ALL_NAMES[@]}")
  TOTAL=${#ALL_NAMES[@]}
  echo -e "${CYAN}👥 crew:${NC} ${CREW^^}"
fi

rm -rf "$WORK_DIR" && mkdir -p "$WORK_DIR"
echo "$TOPIC" > "$WORK_DIR/topic.txt"
> "$WORK_DIR/convo.txt"
[[ -n "$NOTIFY_WEBHOOK" ]] && echo "$NOTIFY_WEBHOOK" > "$WORK_DIR/notify.url"

# ── CONTEXT INJECTION ─────────────────────────────────────────
if [[ -n "$CONTEXT_FILE" ]]; then
  if [[ -f "$CONTEXT_FILE" ]]; then
    cp "$CONTEXT_FILE" "$WORK_DIR/context.txt"
    echo "📎 $(basename "$CONTEXT_FILE")" > "$WORK_DIR/context.label"
    echo -e "${CYAN}📎 context:${NC} ${CONTEXT_FILE}"
  else
    echo -e "${RED}Context file not found: ${CONTEXT_FILE}${NC}"; exit 1
  fi
elif [[ -n "$CONTEXT_URL" ]]; then
  echo -e "${DIM}fetching context from ${CONTEXT_URL}...${NC}"
  curl -sL -m 10 "$CONTEXT_URL" | sed 's/<[^>]*>//g' | head -c 3000 > "$WORK_DIR/context.txt"
  echo "🌐 ${CONTEXT_URL}" > "$WORK_DIR/context.label"
  echo -e "${CYAN}🌐 context:${NC} ${CONTEXT_URL}"
elif [[ ! -t 0 ]]; then
  # stdin pipe: cat file.md | br carpool "topic"
  cat > "$WORK_DIR/context.txt"
  echo "📋 stdin" > "$WORK_DIR/context.label"
  echo -e "${CYAN}📋 context:${NC} piped from stdin"
fi

# ── MEMORY INJECTION ──────────────────────────────────────────
MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
if [[ $USE_MEMORY -eq 1 && -f "$MEMORY_FILE" ]]; then
  mem_ctx=$(tail -80 "$MEMORY_FILE")  # last ~5 sessions
  existing=$(cat "$WORK_DIR/context.txt" 2>/dev/null)
  { echo "=== PAST SESSION MEMORY ==="; echo "$mem_ctx"; echo "=== END MEMORY ===";
    [[ -n "$existing" ]] && echo "" && echo "$existing"; } > "$WORK_DIR/context.txt"
  echo "🧠 memory" > "$WORK_DIR/context.label"
  echo -e "${CYAN}🧠 memory:${NC} last $(grep -c "^---" "$MEMORY_FILE" 2>/dev/null) sessions injected"
fi

# ── PER-AGENT MODEL ASSIGNMENT ────────────────────────────────
if [[ $SPLIT_MODELS -eq 1 ]]; then
  THINKER_MODEL="${MODEL}"
  WORKER_MODEL="tinyllama"
  # If main model IS tinyllama, thinkers get llama3.2:1b
  [[ "$MODEL" == "tinyllama" ]] && THINKER_MODEL="llama3.2:1b"
  for n in LUCIDIA PRISM OCTAVIA; do echo "$THINKER_MODEL" > "$WORK_DIR/${n}.model"; done
  for n in ALICE ECHO CIPHER ARIA SHELLFISH; do echo "$WORKER_MODEL" > "$WORK_DIR/${n}.model"; done
  echo -e "${CYAN}🔀 split:${NC} thinkers→${THINKER_MODEL}  workers→${WORKER_MODEL}"
fi
if [[ -n "$MODELS_MAP" ]]; then
  IFS=',' read -ra _entries <<< "$MODELS_MAP"
  for _entry in "${_entries[@]}"; do
    _n="${_entry%%:*}"; _m="${_entry#*:}"
    echo "$_m" > "$WORK_DIR/${_n}.model"
    echo -e "${CYAN}🎯${NC} ${_n} → ${_m}"
  done
fi
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
[[ -f "$WORK_DIR/context.txt" ]] && echo -e "${CYAN}📎 with context${NC}"
[[ $SPLIT_MODELS -eq 1 ]] && echo -e "${CYAN}🔀 split-model mode${NC}"
[[ -n "$CREW" ]] && echo -e "${CYAN}👥 crew: ${CREW^^}${NC}"
[[ $USE_MEMORY -eq 1 ]] && echo -e "${CYAN}🧠 memory active${NC}"
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

# Status bar: model + topic + live round counter
tmux set-option -t "$SESSION" status on
tmux set-option -t "$SESSION" status-interval 2
tmux set-option -t "$SESSION" status-style "bg=black,fg=white"
tmux set-option -t "$SESSION" status-left "#[fg=yellow,bold] 🚗 CarPool #[fg=white,dim] ${MODEL} · ${TURNS}t · #(cat /tmp/br_carpool/progress.txt 2>/dev/null || echo 'starting') "
tmux set-option -t "$SESSION" status-right "#[fg=cyan,dim] ${TOPIC:0:50} "
tmux set-option -t "$SESSION" status-left-length 50
tmux set-option -t "$SESSION" status-right-length 55

# Worker tabs (skip in brief mode)
if [[ $BRIEF -eq 0 ]]; then
  for entry in "${AGENT_LIST[@]}"; do
    IFS='|' read -r n _ _ _ <<< "$entry"
    tmux new-window -t "$SESSION" -n "$n" "bash '$SCRIPT_PATH' --worker $n"
  done
fi

# Summary tab
tmux new-window -t "$SESSION" -n "📋 summary" "bash '$SCRIPT_PATH' --summary"

# Vote tab — skip in brief mode
if [[ $BRIEF -eq 0 ]]; then
  IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[0]}"
  tmux new-window -t "$SESSION" -n "🗳️ vote" "bash '$SCRIPT_PATH' --vote $n"
  VOTE_WIN="$SESSION:🗳️ vote"
  for (( i=1; i<${#AGENT_LIST[@]}; i++ )); do
    IFS='|' read -r n _ _ _ <<< "${AGENT_LIST[$i]}"
    tmux split-window -t "$VOTE_WIN" "bash '$SCRIPT_PATH' --vote $n"
    tmux select-layout -t "$VOTE_WIN" tiled
  done
fi

tmux select-window -t "$GROUP_WIN"

if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach -t "$SESSION"
fi
