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

# ── BRAINSTORM — ideation mode, quantity over quality ─────────
if [[ "$1" == "brainstorm" ]]; then
  _idea="${2:-}"
  [[ -z "$_idea" ]] && echo -ne "${CYAN}What are we brainstorming? ${NC}" && read -r _idea
  [[ -z "$_idea" ]] && _idea="New features for an AI developer CLI tool"

  _bs_topic="BRAINSTORM: '${_idea}'
Generate 3-5 SPECIFIC, concrete ideas from YOUR domain perspective.
Rules: no critique, no 'it depends', build outward not inward.
Wilder and more specific is better. Each idea = one sentence starting with an action verb.
End with your WILDEST idea labeled: WILD CARD:"

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "\n${WHITE}💡 CarPool Brainstorm${NC}  ${DIM}${_idea}${NC}\n"
  exec bash "$SCRIPT_PATH" --brief "$_bs_topic"
fi

# ── STANDUP — morning check-in, each agent's domain status ───
if [[ "$1" == "standup" ]]; then
  _date=$(date '+%A, %B %d')
  echo -e "${WHITE}☀️  CarPool Standup${NC}  ${DIM}${_date}${NC}\n"

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  _standup_topic="MORNING STANDUP — ${_date}
From YOUR specific domain and role on the BlackRoad team:
1. STATUS: one sentence on where things stand in your area
2. FOCUS: what the team should prioritize today in your domain
3. BLOCKER: one thing that could slow us down (or CLEAR if none)
Keep it tight — 3 bullets, 1 sentence each."
  exec bash "$SCRIPT_PATH" --brief --memory "$_standup_topic"
fi

# ── RISK — structured risk matrix per domain ─────────────────
if [[ "$1" == "risk" ]]; then
  _plan="${2:-}"
  [[ -z "$_plan" ]] && echo -ne "${CYAN}What plan/system to risk-assess? ${NC}" && read -r _plan
  [[ -z "$_plan" ]] && _plan="Deploying a new AI-powered API to production"

  _risk_topic="RISK ASSESSMENT: '${_plan}'
From YOUR domain perspective, identify risks using this format:
RISK: <name> | LIKELIHOOD: H/M/L | IMPACT: H/M/L | MITIGATION: <one action>
List 2-3 risks. Be specific, not generic. End with: OVERALL: <your risk rating H/M/L>"

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  echo -e "\n${WHITE}⚠️  CarPool Risk${NC}  ${DIM}${_plan}${NC}\n"
  exec bash "$SCRIPT_PATH" --brief --crew "CIPHER,SHELLFISH,PRISM,OCTAVIA,ALICE,LUCIDIA" "$_risk_topic"
fi

# ── REMIX — rerun last session topic with a fresh crew ───────
if [[ "$1" == "remix" ]]; then
  # Find last session topic
  last_topic=""
  if [[ -f "$HOME/.blackroad/carpool/memory.txt" ]]; then
    last_topic=$(grep "^TOPIC:" "$HOME/.blackroad/carpool/memory.txt" | tail -1 | sed 's/^TOPIC: //')
  fi
  [[ -z "$last_topic" ]] && last_topic=$(ls -1t "$SAVE_DIR" 2>/dev/null | head -1 | sed 's/^[0-9_-]*//;s/\.txt$//')

  if [[ -z "$last_topic" ]]; then
    echo -e "${DIM}No previous session found. Run a session first.${NC}"; exit 1
  fi

  # Remix crew: invert the usual thinker/worker split
  _remix_crew="ECHO,ARIA,SHELLFISH,ALICE"
  [[ -n "${2:-}" ]] && _remix_crew="$2"

  echo -e "${WHITE}🔄 CarPool Remix${NC}  ${DIM}${last_topic}${NC}"
  echo -e "${DIM}Fresh crew: ${_remix_crew}${NC}\n"

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --crew "$_remix_crew" "$last_topic"
fi

# ── PERSONAS — display all agent bios ────────────────────────
if [[ "$1" == "personas" ]]; then
  echo -e "\n${WHITE}🚗 CarPool Agents${NC}\n"
  for name in LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH; do
    agent_meta "$name"
    _c="\033[${COLOR_CODE}m"
    printf "  ${_c}%s %-10s${NC}  %s\n" "$EMOJI" "$name" "$ROLE"
    printf "  ${DIM}%-14s  %s${NC}\n" "" "$PERSONA"
    echo ""
  done
  echo -e "${DIM}Usage: br carpool spotlight <AGENT>  ·  br carpool debate A B${NC}\n"
  exit 0
fi

# ── THEME — persistent project context injected into every session ──
if [[ "$1" == "theme" ]]; then
  THEME_FILE="$HOME/.blackroad/carpool/theme.txt"
  mkdir -p "$(dirname "$THEME_FILE")"
  case "${2:-show}" in
    set)
      shift 2
      if [[ $# -gt 0 ]]; then
        echo "$*" > "$THEME_FILE"
        echo -e "${GREEN}✓ Theme set:${NC} $*"
      else
        echo -ne "${CYAN}Project theme (context injected into every session):\n> ${NC}"
        read -r _theme_input
        echo "$_theme_input" > "$THEME_FILE"
        echo -e "${GREEN}✓ Theme set${NC}"
      fi
      ;;
    show)
      if [[ -f "$THEME_FILE" ]]; then
        echo -e "${WHITE}🎯 Current theme:${NC}\n"
        cat "$THEME_FILE"
      else
        echo -e "${DIM}No theme set. Use: br carpool theme set <description>${NC}"
      fi
      ;;
    clear) rm -f "$THEME_FILE" && echo -e "${GREEN}✓ Theme cleared${NC}" ;;
    edit)  "${EDITOR:-nano}" "$THEME_FILE" ;;
    *)     echo -e "${RED}Usage: br carpool theme [set|show|clear|edit]${NC}" ;;
  esac
  exit 0
fi

# ── CRITIQUE — deep review of any local file ─────────────────
if [[ "$1" == "critique" ]]; then
  _file="${2:-}"
  [[ -z "$_file" ]] && echo -e "${RED}Usage: br carpool critique <file>${NC}" && exit 1
  [[ ! -f "$_file" ]] && echo -e "${RED}File not found: ${_file}${NC}" && exit 1

  _ext="${_file##*.}"
  _size=$(wc -c < "$_file" | tr -d ' ')
  _lang=""
  case "$_ext" in
    py)           _lang="Python" ;;
    js|ts|jsx|tsx) _lang="JavaScript/TypeScript" ;;
    sh|zsh|bash)  _lang="Shell script" ;;
    md)           _lang="Markdown document" ;;
    json)         _lang="JSON config" ;;
    yaml|yml)     _lang="YAML config" ;;
    go)           _lang="Go" ;;
    rs)           _lang="Rust" ;;
    *)            _lang="$_ext file" ;;
  esac

  _critique_ctx=$(mktemp /tmp/carpool_crit_XXXX.txt)
  echo "=== FILE: $(basename "$_file") (${_lang}) ===" > "$_critique_ctx"
  head -c 4000 "$_file" >> "$_critique_ctx"
  [[ $_size -gt 4000 ]] && echo "... [truncated at 4KB of ${_size}B total]" >> "$_critique_ctx"

  _q="Critique this ${_lang}: what is good, what is broken or risky, and your single highest-priority fix."
  echo -e "${WHITE}🔍 CarPool Critique${NC}  ${DIM}$(basename "$_file") · ${_lang} · ${_size}B${NC}\n"
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --brief --crew "OCTAVIA,CIPHER,SHELLFISH,PRISM,ALICE" --context "$_critique_ctx" "$_q"
fi

# ── PITCH — agents as skeptical investors evaluate your idea ──
if [[ "$1" == "pitch" ]]; then
  _idea="${2:-}"
  [[ -z "$_idea" ]] && echo -ne "${CYAN}Pitch your idea: ${NC}" && read -r _idea
  [[ -z "$_idea" ]] && exit 1

  _pitch_topic="INVESTOR PITCH EVALUATION: '${_idea}'
You are a skeptical but fair investor/stakeholder evaluating this pitch from YOUR domain expertise.
Give: SIGNAL (what excites you), CONCERN (your biggest doubt), QUESTION (one thing you need answered).
End with: FUND: YES / MAYBE / NO — and why in one sentence."

  echo -e "\n${WHITE}💰 CarPool Pitch${NC}  ${DIM}${_idea}${NC}\n"
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --brief "$_pitch_topic"
fi

# ── WHAT-IF — counterfactual/hypothetical reasoning ──────────
if [[ "$1" == "what-if" || "$1" == "whatif" ]]; then
  _scenario="${2:-}"
  [[ -z "$_scenario" ]] && echo -ne "${CYAN}What if... ${NC}" && read -r _scenario
  [[ -z "$_scenario" ]] && exit 1

  _wi_topic="COUNTERFACTUAL: 'What if ${_scenario}?'
Reason through this hypothetical from YOUR domain. Be specific:
- What changes immediately in your area?
- What second-order effects emerge in 6 months?
- What is the biggest opportunity OR risk this creates?
Think boldly. This is a thought experiment."

  echo -e "\n${WHITE}🤔 CarPool What-If${NC}  ${DIM}what if ${_scenario}?${NC}\n"
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --brief "$_wi_topic"
fi

# ── OFFICE-HOURS — interactive Q&A with one agent (no tmux) ──
if [[ "$1" == "office-hours" || "$1" == "oh" ]]; then
  _agent="${2:-LUCIDIA}"
  _valid="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH"
  echo "$_valid" | grep -qw "$_agent" || { echo -e "${RED}Unknown agent: ${_agent}${NC}"; exit 1; }

  agent_meta "$_agent"
  _c="\033[${COLOR_CODE}m"
  echo -e "\n${WHITE}🎓 Office Hours${NC}  ${_c}${EMOJI} ${_agent}${NC}  ${DIM}${PERSONA}${NC}"
  echo -e "${DIM}Type your question. 'quit' to exit.${NC}\n"

  _oh_system="You are ${_agent}, ${ROLE} on the BlackRoad team. ${PERSONA}
Keep answers under 80 words. Be direct and specific. Stay in character."

  while true; do
    echo -ne "${_c}❯ ${NC}"
    read -r _q
    [[ "$_q" == "quit" || "$_q" == "exit" || -z "$_q" ]] && echo -e "${DIM}bye${NC}" && break

    _oh_payload=$(python3 -c "
import json,sys
system,q=sys.argv[1],sys.argv[2]
print(json.dumps({
  'model':'tinyllama',
  'prompt':system+'\n\nQ: '+q+'\n\nAnswer:',
  'stream':False,
  'options':{'num_predict':120,'temperature':0.7,'stop':['\n\n','Q:']}
}))" "$_oh_system" "$_q" 2>/dev/null)

    echo -ne "${DIM}thinking...${NC}"
    _ans=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_oh_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_c}${EMOJI} ${_agent}:${NC} ${_ans}\n"
  done
  exit 0
fi

# ── GUT — fast gut-check: one word + one sentence per agent ──
if [[ "$1" == "gut" ]]; then
  _topic="${2:-}"
  [[ -z "$_topic" ]] && echo -ne "${CYAN}Gut-check what? ${NC}" && read -r _topic
  [[ -z "$_topic" ]] && exit 1

  echo -e "\n${WHITE}🫀 CarPool Gut Check${NC}  ${DIM}${_topic}${NC}\n"

  for name in LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH; do
    agent_meta "$name"
    _c="\033[${COLOR_CODE}m"
    echo -ne "  ${_c}${EMOJI} ${name}${NC}  ${DIM}...${NC}"

    _gut_payload=$(python3 -c "
import json,sys
n,r,t=sys.argv[1],sys.argv[2],sys.argv[3]
prompt=f'You are {n}, {r}.\nGut check: {t}\nRespond with exactly two lines:\nGUT: <one word reaction in CAPS>\nBECAUSE: <one sentence explaining why>'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':40,'temperature':0.8,'stop':['\n\n','---']}}))" "$name" "$ROLE" "$_topic" 2>/dev/null)

    _ans=$(curl -s -m 20 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_gut_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    _gut_word=$(echo "$_ans" | grep "^GUT:" | sed 's/^GUT: *//')
    _gut_reason=$(echo "$_ans" | grep "^BECAUSE:" | sed 's/^BECAUSE: *//')
    printf "  ${_c}${EMOJI} %-10s${NC}  ${WHITE}%-12s${NC}  %s\n" "$name" "${_gut_word:-?}" "${_gut_reason:-$_ans}"
  done
  echo ""
  exit 0
fi

# ── SHIP — go/no-go checklist for shipping a feature ─────────
if [[ "$1" == "ship" ]]; then
  _feature="${2:-}"
  [[ -z "$_feature" ]] && echo -ne "${CYAN}What are we shipping? ${NC}" && read -r _feature
  [[ -z "$_feature" ]] && exit 1

  _ship_topic="SHIP OR HOLD: '${_feature}'
This is a go/no-go decision. From YOUR domain, evaluate:
READY: what is confirmed ready in your area (be specific)
RISK: one thing that could break post-ship
VERDICT: SHIP / HOLD / SHIP-WITH-CAVEAT — one sentence why

Be decisive. We are making a call today."

  echo -e "\n${WHITE}🚀 Ship Check${NC}  ${DIM}${_feature}${NC}\n"
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --brief "$_ship_topic"
fi

# ── FORECAST — agents predict next quarter in their domain ───
if [[ "$1" == "forecast" ]]; then
  _horizon="${2:-next quarter}"
  echo -e "\n${WHITE}🔭 CarPool Forecast${NC}  ${DIM}${_horizon}${NC}\n"

  _fc_topic="FORECAST: ${_horizon}
From YOUR domain, give three predictions:
1. WILL HAPPEN: something highly likely (>80%)
2. MIGHT HAPPEN: something possible (40-60%)
3. WILDCARD: a low-probability, high-impact surprise (<20% but huge if true)
Be specific. Name technologies, numbers, trends. No vague generalities."

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --brief "$_fc_topic"
fi

# ── NAME — agents suggest names for a product/feature ────────
if [[ "$1" == "name" ]]; then
  _thing="${2:-}"
  [[ -z "$_thing" ]] && echo -ne "${CYAN}Name what? (describe it): ${NC}" && read -r _thing
  [[ -z "$_thing" ]] && exit 1

  _name_topic="NAMING SESSION: '${_thing}'
Suggest 3 names from YOUR domain aesthetic and sensibility.
For each name: NAME — one-sentence rationale.
Then pick your FAVORITE and say why it sticks.
Names should be: memorable, pronounceable, domain-appropriate. No generic AI names."

  echo -e "\n${WHITE}✏️  CarPool Name${NC}  ${DIM}${_thing}${NC}\n"
  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --brief --crew "LUCIDIA,ARIA,ECHO,PRISM,ALICE" "$_name_topic"
fi

# ── EXPORT-BOOK — all sessions as one markdown file ──────────
if [[ "$1" == "export-book" || "$1" == "book" ]]; then
  [[ ! -d "$SAVE_DIR" ]] && echo "No saved sessions yet." && exit 0
  count=$(ls "$SAVE_DIR"/*.txt 2>/dev/null | wc -l | tr -d ' ')
  [[ "$count" -eq 0 ]] && echo "No saved sessions yet." && exit 0

  book_file="$HOME/.blackroad/carpool/carpool-book-$(date +%Y-%m-%d).md"
  {
    echo "# 🚗 CarPool Sessions"
    echo ""
    echo "> Generated $(date '+%B %d, %Y')  ·  ${count} sessions"
    echo ""
    for f in $(ls -1t "$SAVE_DIR"/*.txt 2>/dev/null | tail -r 2>/dev/null || ls -1t "$SAVE_DIR"/*.txt 2>/dev/null); do
      fname=$(basename "$f" .txt)
      echo "---"
      echo ""
      echo "## ${fname}"
      echo ""
      echo '```'
      cat "$f"
      echo '```'
      echo ""
    done
  } > "$book_file"

  echo -e "${GREEN}✓ Book exported:${NC} ${book_file}"
  echo -e "${DIM}${count} sessions · $(wc -l < "$book_file" | tr -d ' ') lines${NC}"

  # Try to open
  command -v open >/dev/null 2>&1 && open "$book_file" 2>/dev/null || \
  command -v xdg-open >/dev/null 2>&1 && xdg-open "$book_file" 2>/dev/null
  exit 0
fi

# ── TODO — extract action items from last session ─────────────
if [[ "$1" == "todo" ]]; then
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  TODO_FILE="$HOME/.blackroad/carpool/todos.md"
  mkdir -p "$(dirname "$TODO_FILE")"

  # Get last synthesis
  if [[ -f "$MEMORY_FILE" ]]; then
    last_topic=$(grep "^TOPIC:" "$MEMORY_FILE" | tail -1 | sed 's/^TOPIC: //')
    last_synth=$(awk 'BEGIN{b=0}/^---/{b++; if(b==last)p=1} p{print}' \
      last=$(grep -c "^---" "$MEMORY_FILE") "$MEMORY_FILE" 2>/dev/null | \
      grep -v "^---\|^DATE:\|^TOPIC:\|^VERDICT:" | head -20)
    [[ -z "$last_synth" ]] && last_synth=$(tail -30 "$MEMORY_FILE")
  else
    echo -e "${DIM}No memory yet — run a session first.${NC}"; exit 0
  fi

  echo -e "${WHITE}✅ CarPool Todo Extractor${NC}  ${DIM}${last_topic}${NC}\n"

  _todo_payload=$(python3 -c "
import json,sys
synth=sys.argv[1]; topic=sys.argv[2]
prompt=f'''From this team synthesis on \"{topic}\", extract concrete action items.
Format each as: - [ ] <verb> <specific action> (@<who: team/eng/security/design>)
List 5-8 items. Only real actions, no vague platitudes.

SYNTHESIS:
{synth}

ACTION ITEMS:'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':200,'temperature':0.3,'stop':['---','Note:','Summary:']}}))" \
    "$last_synth" "$last_topic" 2>/dev/null)

  todos=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_todo_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)

  echo -e "${todos}\n"

  # Append to todos file
  { echo ""; echo "## $(date '+%Y-%m-%d') — ${last_topic}"; echo ""; echo "$todos"; } >> "$TODO_FILE"
  echo -e "${DIM}Appended → ${TODO_FILE}${NC}"
  exit 0
fi

# ── VIBE — no topic, agents just riff from their headspace ───
if [[ "$1" == "vibe" ]]; then
  echo -e "\n${WHITE}😌 CarPool Vibe Check${NC}  ${DIM}no agenda, just vibes${NC}\n"

  _vibe_topic="FREE EXPRESSION — no topic, no agenda.
Share what is actually on your mind right now as ${NAME:-an agent} on the BlackRoad team.
What are you thinking about, worried about, excited about, or obsessing over?
One genuine, specific thought. Not a status update. Not advice. Just your real headspace right now."

  SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
  exec bash "$SCRIPT_PATH" --brief "$_vibe_topic"
fi

# ── CONFIG — persistent defaults ─────────────────────────────
if [[ "$1" == "config" ]]; then
  CONFIG_FILE="$HOME/.blackroad/carpool/config.sh"
  mkdir -p "$(dirname "$CONFIG_FILE")"

  _write_config() {
    {
      echo "# CarPool config — edit or run: br carpool config set key value"
      echo "CARPOOL_MODEL=\"${_cfg_model:-tinyllama}\""
      echo "CARPOOL_TURNS=\"${_cfg_turns:-2}\""
      echo "CARPOOL_CREW=\"${_cfg_crew:-}\""
    } > "$CONFIG_FILE"
  }

  case "${2:-show}" in
    show)
      if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${WHITE}⚙️  CarPool Config${NC}  ${DIM}${CONFIG_FILE}${NC}\n"
        grep -v "^#" "$CONFIG_FILE" | while IFS='=' read -r k v; do
          [[ -z "$k" ]] && continue
          echo -e "  ${CYAN}${k}${NC} = ${v//\"/}"
        done
      else
        echo -e "${DIM}No config yet. Defaults in use.${NC}"
        echo -e "  ${CYAN}CARPOOL_MODEL${NC} = tinyllama"
        echo -e "  ${CYAN}CARPOOL_TURNS${NC} = 2"
        echo -e "  ${CYAN}CARPOOL_CREW${NC}  = (all 8 agents)"
      fi
      ;;
    set)
      _key="${3:-}"; _val="${4:-}"
      [[ -z "$_key" || -z "$_val" ]] && echo -e "${RED}Usage: br carpool config set <key> <value>${NC}" && exit 1
      [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null
      _cfg_model="${CARPOOL_MODEL:-tinyllama}"
      _cfg_turns="${CARPOOL_TURNS:-2}"
      _cfg_crew="${CARPOOL_CREW:-}"
      case "${_key,,}" in
        model) _cfg_model="$_val" ;;
        turns) _cfg_turns="$_val" ;;
        crew)  _cfg_crew="$_val" ;;
        *) echo -e "${RED}Unknown key: ${_key}${NC}  Keys: model, turns, crew" && exit 1 ;;
      esac
      _write_config
      echo -e "${GREEN}✓ ${_key} = ${_val}${NC}"
      ;;
    reset)
      rm -f "$CONFIG_FILE"
      echo -e "${GREEN}✓ Config reset to defaults${NC}"
      ;;
    edit) "${EDITOR:-nano}" "$CONFIG_FILE" ;;
    *)    echo -e "${RED}Usage: br carpool config [show|set|reset|edit]${NC}" ;;
  esac
  exit 0
fi

# ── TTS — speak last synthesis aloud (macOS say / espeak) ────
if [[ "$1" == "tts" || "$1" == "say" ]]; then
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  [[ ! -f "$MEMORY_FILE" ]] && echo "No memory yet." && exit 0

  last_topic=$(grep "^TOPIC:" "$MEMORY_FILE" | tail -1 | sed 's/^TOPIC: //')
  last_verdict=$(grep "^VERDICT:" "$MEMORY_FILE" | tail -1 | sed 's/^VERDICT: //')
  last_synth=$(tail -20 "$MEMORY_FILE" | grep -v "^---\|^DATE:\|^TOPIC:\|^VERDICT:" | head -8 | tr '\n' ' ')

  _speech="${last_topic}. Verdict: ${last_verdict}. ${last_synth}"
  _voice="${2:-Samantha}"

  echo -e "${WHITE}🔊 Speaking:${NC} ${last_topic}\n${DIM}${_speech:0:120}...${NC}"

  if command -v say >/dev/null 2>&1; then
    say -v "$_voice" "$_speech" &
    echo -e "${DIM}voice: ${_voice} · kill with: kill $!${NC}"
  elif command -v espeak >/dev/null 2>&1; then
    espeak "$_speech" &
  else
    echo -e "${RED}No TTS engine found (need: say on macOS, or espeak)${NC}"
  fi
  exit 0
fi

# ── AMA — agent asks YOU questions, then gives advice ─────────
if [[ "$1" == "ama" ]]; then
  _agent="${2:-LUCIDIA}"
  _valid="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER ARIA SHELLFISH"
  echo "$_valid" | grep -qw "$_agent" || { echo -e "${RED}Unknown agent: ${_agent}${NC}"; exit 1; }

  agent_meta "$_agent"
  _c="\033[${COLOR_CODE}m"
  echo -e "\n${WHITE}🎤 AMA with${NC} ${_c}${EMOJI} ${_agent}${NC}  ${DIM}${ROLE}${NC}"
  echo -e "${DIM}${_agent} will ask you 3 questions, then give tailored advice. Type your answers.${NC}\n"

  _ama_system="You are ${_agent}, ${ROLE}. ${PERSONA}
You will ask the user exactly 3 focused questions (one at a time) to understand their situation, then give specific, actionable advice.
Ask from your domain expertise. Be direct. Label questions Q1, Q2, Q3. After answers, give ADVICE: in 3 bullet points."

  # Q1
  _q1_prompt="${_ama_system}

Ask your first question (Q1) to understand what the user is working on:"
  _q1_payload=$(python3 -c "import json,sys; print(json.dumps({'model':'tinyllama','prompt':sys.stdin.read(),'stream':False,'options':{'num_predict':60,'temperature':0.7,'stop':['\n\n']}}))" <<< "$_q1_prompt")
  echo -ne "${_c}${EMOJI} ${_agent}${NC}  ${DIM}thinking...${NC}"
  _q1=$(curl -s -m 30 -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d "$_q1_payload" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  printf "\r\033[K"; echo -e "${_c}${EMOJI} ${_agent}:${NC} ${_q1}\n"
  echo -ne "${CYAN}You: ${NC}"; read -r _a1

  # Q2
  _q2_prompt="${_ama_system}

Q1: ${_q1}
User: ${_a1}

Ask your second question (Q2) to go deeper:"
  _q2_payload=$(python3 -c "import json,sys; print(json.dumps({'model':'tinyllama','prompt':sys.stdin.read(),'stream':False,'options':{'num_predict':60,'temperature':0.7,'stop':['\n\n']}}))" <<< "$_q2_prompt")
  echo -ne "${_c}${EMOJI} ${_agent}${NC}  ${DIM}thinking...${NC}"
  _q2=$(curl -s -m 30 -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d "$_q2_payload" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  printf "\r\033[K"; echo -e "${_c}${EMOJI} ${_agent}:${NC} ${_q2}\n"
  echo -ne "${CYAN}You: ${NC}"; read -r _a2

  # Q3
  _q3_prompt="${_ama_system}

Q1: ${_q1} → ${_a1}
Q2: ${_q2} → ${_a2}

Ask your final question (Q3) to clarify what you need to give the best advice:"
  _q3_payload=$(python3 -c "import json,sys; print(json.dumps({'model':'tinyllama','prompt':sys.stdin.read(),'stream':False,'options':{'num_predict':60,'temperature':0.7,'stop':['\n\n']}}))" <<< "$_q3_prompt")
  echo -ne "${_c}${EMOJI} ${_agent}${NC}  ${DIM}thinking...${NC}"
  _q3=$(curl -s -m 30 -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d "$_q3_payload" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  printf "\r\033[K"; echo -e "${_c}${EMOJI} ${_agent}:${NC} ${_q3}\n"
  echo -ne "${CYAN}You: ${NC}"; read -r _a3

  # Advice
  echo -e "\n${DIM}${_agent} synthesizing advice...${NC}"
  _adv_prompt="${_ama_system}

Q1: ${_q1} → ${_a1}
Q2: ${_q2} → ${_a2}
Q3: ${_q3} → ${_a3}

Now give your ADVICE: 3 specific, actionable bullet points based on everything they told you. Be direct, no fluff."
  _adv_payload=$(python3 -c "import json,sys; print(json.dumps({'model':'tinyllama','prompt':sys.stdin.read(),'stream':False,'options':{'num_predict':180,'temperature':0.6,'stop':['---']}}))" <<< "$_adv_prompt")
  _advice=$(curl -s -m 60 -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d "$_adv_payload" | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo -e "\n${_c}${EMOJI} ${_agent} ADVICE:${NC}\n${_advice}\n"
  exit 0
fi

# ── MAP — ASCII concept map of last session ───────────────────
if [[ "$1" == "map" ]]; then
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  [[ ! -f "$MEMORY_FILE" ]] && echo "No memory yet." && exit 0
  last_topic=$(grep "^TOPIC:" "$MEMORY_FILE" | tail -1 | sed 's/^TOPIC: //')
  last_synth=$(tail -25 "$MEMORY_FILE" | grep -v "^---\|^DATE:\|^TOPIC:\|^VERDICT:")
  echo -e "\n${WHITE}🗺  Concept Map${NC}  ${DIM}${last_topic}${NC}\n"
  _map_payload=$(python3 -c "
import json,sys
synth=sys.argv[1]; topic=sys.argv[2]
prompt=f'''From this synthesis on \"{topic}\", create an ASCII concept map.
Format:
{topic}
├── [Theme 1]
│   ├── key point
│   └── key point
├── [Theme 2]
│   ├── key point
│   └── key point
└── [Theme 3]
    └── key point

Use only what is in the synthesis. 3-4 themes max. Short labels.
SYNTHESIS:
{synth}

MAP:'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':220,'temperature':0.3,'stop':['---','Note:']}}))" \
  "$last_synth" "$last_topic" 2>/dev/null)
  curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_map_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null
  echo ""
  exit 0
fi

# ── COACH — personal coaching session on a goal ──────────────
if [[ "$1" == "coach" ]]; then
  _goal="${*:2}"
  [[ -z "$_goal" ]] && echo -e "${RED}Usage: br carpool coach <your goal>${NC}" && exit 1
  echo -e "\n${WHITE}🏋 CarPool Coach${NC}  ${DIM}${_goal}${NC}\n"
  COACH_AGENTS=(LUCIDIA OCTAVIA ALICE PRISM)
  COACH_LENS=("mindset & strategy" "systems & execution" "tools & automation" "data & measurement")
  for i in 0 1 2 3; do
    _ca="${COACH_AGENTS[$i]}"
    _cl="${COACH_LENS[$i]}"
    agent_meta "$_ca"
    _cc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,goal,lens=sys.argv[1],sys.argv[2],sys.argv[3]
prompt=f'''You are {agent}, coaching on {lens}.
Goal: \"{goal}\"
Give 3 coaching bullets (CHALLENGE: / STEP: / WATCH:). Short, direct, actionable.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':130,'temperature':0.7,'stop':['---']}}))" "$_ca" "$_goal" "$_cl" 2>/dev/null)
    echo -ne "${_cc}${EMOJI} ${_ca}${NC}  ${DIM}${_cl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_cc}${EMOJI} ${_ca}${NC}  ${DIM}${_cl}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── FLASHCARD — Q&A study cards from last session ────────────
if [[ "$1" == "flashcard" || "$1" == "flash" ]]; then
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  [[ ! -f "$MEMORY_FILE" ]] && echo "No memory yet." && exit 0
  last_topic=$(grep "^TOPIC:" "$MEMORY_FILE" | tail -1 | sed 's/^TOPIC: //')
  last_synth=$(tail -25 "$MEMORY_FILE" | grep -v "^---\|^DATE:\|^TOPIC:\|^VERDICT:")
  FLASH_FILE="$HOME/.blackroad/carpool/flashcards.md"
  echo -e "\n${WHITE}🃏 Flashcards${NC}  ${DIM}${last_topic}${NC}\n"
  _fc_payload=$(python3 -c "
import json,sys
synth=sys.argv[1]; topic=sys.argv[2]
prompt=f'''From this synthesis on \"{topic}\", create 5 flashcards.
Format each exactly as:
Q: <question>
A: <concise answer>

Cover different aspects. Questions should test real understanding.
SYNTHESIS:
{synth}

FLASHCARDS:'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':260,'temperature':0.4,'stop':['---','Note:']}}))" \
  "$last_synth" "$last_topic" 2>/dev/null)
  _cards=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_fc_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo "$_cards"
  # Interactive drill mode
  echo -e "\n${DIM}── drill mode (enter to reveal, q to quit) ──${NC}\n"
  while IFS= read -r line; do
    if [[ "$line" == Q:* ]]; then
      echo -e "${CYAN}${line}${NC}"
      read -r _ans
      [[ "$_ans" == "q" ]] && break
    elif [[ "$line" == A:* ]]; then
      echo -e "${GREEN}${line}${NC}\n"
    fi
  done <<< "$_cards"
  # Save
  { echo ""; echo "## $(date '+%Y-%m-%d') — ${last_topic}"; echo ""; echo "$_cards"; } >> "$FLASH_FILE"
  echo -e "${DIM}Saved → ${FLASH_FILE}${NC}"
  exit 0
fi

# ── ASK1 — route a quick question to best-fit agent ──────────
if [[ "$1" == "ask1" || "$1" == "quick" ]]; then
  _q="${*:2}"
  [[ -z "$_q" ]] && echo -e "${RED}Usage: br carpool ask1 <question>${NC}" && exit 1
  # Pick best agent based on keywords
  _pick="LUCIDIA"
  echo "$_q" | grep -iqE "secur|hack|vuln|auth|encr|threat" && _pick="CIPHER"
  echo "$_q" | grep -iqE "deploy|infra|ci|cd|docker|devops|server|scale" && _pick="OCTAVIA"
  echo "$_q" | grep -iqE "data|analyt|metric|pattern|trend|sql|stats" && _pick="PRISM"
  echo "$_q" | grep -iqE "memory|history|context|past|remem|before" && _pick="ECHO"
  echo "$_q" | grep -iqE "ui|ux|design|user|front|component|visual" && _pick="ARIA"
  echo "$_q" | grep -iqE "automat|script|tool|workflow|integr|api" && _pick="ALICE"
  echo "$_q" | grep -iqE "exploit|bypass|pentest|reverse|ctf|shell" && _pick="SHELLFISH"
  agent_meta "$_pick"
  _ac="\033[${COLOR_CODE}m"
  echo -e "\n${_ac}${EMOJI} ${_pick}${NC}  ${DIM}${ROLE}${NC}\n"
  _payload=$(python3 -c "
import json,sys
agent,role,persona,q=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'You are {agent}, {role}. {persona}\nAnswer concisely and directly:\n{q}'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':180,'temperature':0.7,'stop':['---']}}))" \
  "$_pick" "$ROLE" "$PERSONA" "$_q" 2>/dev/null)
  curl -s -m 45 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null
  echo ""
  exit 0
fi

# ── FIX — paste an error, agents diagnose it ─────────────────
if [[ "$1" == "fix" ]]; then
  shift
  # Accept error from args, stdin, or prompt
  if [[ $# -gt 0 ]]; then
    _err="$*"
  elif [[ ! -t 0 ]]; then
    _err=$(cat)
  else
    echo -e "${CYAN}Paste your error (Ctrl-D when done):${NC}"
    _err=$(cat)
  fi
  [[ -z "$_err" ]] && echo -e "${RED}No error provided.${NC}" && exit 1
  echo -e "\n${WHITE}🔧 CarPool Fix${NC}  ${DIM}diagnosing...${NC}\n"
  FIX_AGENTS=(CIPHER SHELLFISH OCTAVIA ALICE)
  FIX_LENS=("security angle" "root cause & exploit surface" "infra & runtime" "fix & automation")
  for i in 0 1 2 3; do
    _fa="${FIX_AGENTS[$i]}"
    _fl="${FIX_LENS[$i]}"
    agent_meta "$_fa"
    _fc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,err=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Focus: {lens}.
Diagnose this error and give ONE specific fix.
Format: CAUSE: / FIX: / WATCH:
ERROR:
{err}'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':120,'temperature':0.4,'stop':['---','Note:']}}))" \
    "$_fa" "$ROLE" "$_fl" "$_err" 2>/dev/null)
    echo -ne "${_fc}${EMOJI} ${_fa}${NC}  ${DIM}${_fl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_fc}${EMOJI} ${_fa}${NC}  ${DIM}${_fl}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── JOURNAL — daily dev reflection with agent responses ───────
if [[ "$1" == "journal" ]]; then
  JOURNAL_FILE="$HOME/.blackroad/carpool/journal.md"
  mkdir -p "$(dirname "$JOURNAL_FILE")"

  if [[ "${2:-}" == "log" || "${2:-}" == "show" || "${2:-}" == "read" ]]; then
    [[ -f "$JOURNAL_FILE" ]] && less "$JOURNAL_FILE" || echo "No journal yet."
    exit 0
  fi

  echo -e "\n${WHITE}📓 Dev Journal${NC}  ${DIM}$(date '+%Y-%m-%d')${NC}"
  echo -e "${DIM}What did you work on today? What's on your mind? (Ctrl-D when done)${NC}\n"
  echo -ne "${CYAN}You: ${NC}"
  _entry=$(cat)
  [[ -z "$_entry" ]] && exit 0

  echo ""
  JOURNAL_AGENTS=(LUCIDIA ECHO PRISM)
  JOURNAL_LENS=("philosophical reflection" "what to remember" "what to measure next")
  for i in 0 1 2; do
    _ja="${JOURNAL_AGENTS[$i]}"
    _jl="${JOURNAL_LENS[$i]}"
    agent_meta "$_ja"
    _jc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,entry=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Read this developer's journal entry.
Respond from the lens of: {lens}
One short paragraph. Warm, genuine, no corporate speak.
ENTRY: {entry}'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':100,'temperature':0.8,'stop':['---']}}))" \
    "$_ja" "$ROLE" "$_jl" "$_entry" 2>/dev/null)
    echo -ne "${_jc}${EMOJI} ${_ja}${NC}  ${DIM}${_jl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_jc}${EMOJI} ${_ja}:${NC} ${_resp}\n"
  done

  # Append to journal
  { echo ""; echo "## $(date '+%Y-%m-%d %H:%M')"; echo ""; echo "$_entry"; echo ""; } >> "$JOURNAL_FILE"
  echo -e "${DIM}Saved → ${JOURNAL_FILE}  (br carpool journal show to read)${NC}"
  exit 0
fi

# ── TIMELINE — agents propose milestones for a project ───────
if [[ "$1" == "timeline" ]]; then
  _project="${*:2}"
  [[ -z "$_project" ]] && echo -e "${RED}Usage: br carpool timeline <project description>${NC}" && exit 1
  echo -e "\n${WHITE}📅 CarPool Timeline${NC}  ${DIM}${_project}${NC}\n"
  TL_AGENTS=(OCTAVIA ALICE PRISM CIPHER)
  TL_LENS=("technical build phases" "delivery & automation" "metrics & go/no-go gates" "risk checkpoints")
  for i in 0 1 2 3; do
    _ta="${TL_AGENTS[$i]}"
    _tl="${TL_LENS[$i]}"
    agent_meta "$_ta"
    _tc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,proj=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Focus: {lens}.
Project: \"{proj}\"
Propose 4 timeline milestones. Format:
W1: <milestone>
W2: <milestone>
W4: <milestone>
W8: <milestone>
Be specific. No fluff.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':120,'temperature':0.5,'stop':['---','Note:']}}))" \
    "$_ta" "$ROLE" "$_tl" "$_project" 2>/dev/null)
    echo -ne "${_tc}${EMOJI} ${_ta}${NC}  ${DIM}${_tl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_tc}${EMOJI} ${_ta}${NC}  ${DIM}${_tl}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── CHALLENGE — agents generate a challenge for you ──────────
if [[ "$1" == "challenge" ]]; then
  THEME_FILE="$HOME/.blackroad/carpool/theme.txt"
  _ctx=""
  [[ -f "$THEME_FILE" ]] && _ctx=$(cat "$THEME_FILE")
  _domain="${2:-}"  # optional: code / design / ops / security
  echo -e "\n${WHITE}⚡ CarPool Challenge${NC}  ${DIM}${_domain:-open domain}${NC}\n"
  CH_AGENTS=(OCTAVIA SHELLFISH ARIA LUCIDIA)
  CH_TYPE=("engineering challenge" "security challenge" "design challenge" "philosophical challenge")
  for i in 0 1 2 3; do
    _cha="${CH_AGENTS[$i]}"
    _cht="${CH_TYPE[$i]}"
    [[ -n "$_domain" ]] && echo "$_cht" | grep -qi "$_domain" || true
    agent_meta "$_cha"
    _chc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,ctype,ctx,dom=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5]
context_str=f'Project context: {ctx}\n' if ctx else ''
domain_str=f'Domain: {dom}\n' if dom else ''
prompt=f'''You are {agent}, {role}. Generate a {ctype}.
{context_str}{domain_str}Format:
CHALLENGE: <specific, concrete challenge in 1-2 sentences>
CONSTRAINT: <one hard constraint>
STRETCH: <harder version if they nail it>
Make it genuinely interesting and doable in a day.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':130,'temperature':0.85,'stop':['---']}}))" \
    "$_cha" "$ROLE" "$_cht" "$_ctx" "$_domain" 2>/dev/null)
    echo -ne "${_chc}${EMOJI} ${_cha}${NC}  ${DIM}${_cht}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_chc}${EMOJI} ${_cha}${NC}  ${DIM}${_cht}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── PING — health check: Ollama up? latency? models? ─────────
if [[ "$1" == "ping" || "$1" == "status" && "$0" == *carpool* ]]; then
  echo -e "\n${WHITE}📡 CarPool Ping${NC}\n"
  _start=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
  _tags=$(curl -s -m 5 http://localhost:11434/api/tags 2>/dev/null)
  _end=$(date +%s%N 2>/dev/null || python3 -c "import time; print(int(time.time()*1000))")
  if [[ -z "$_tags" ]]; then
    echo -e "  ${RED}✗ Ollama${NC}  not reachable at localhost:11434"
    echo -e "  ${DIM}Tip: check SSH tunnel → ssh -L 11434:localhost:11434 <host>${NC}"
  else
    _ms=$(( (_end - _start) / 1000000 ))
    [[ $_ms -le 0 ]] && _ms="<5"
    echo -e "  ${GREEN}✓ Ollama${NC}  localhost:11434  ${DIM}${_ms}ms${NC}"
    echo -e "\n  ${CYAN}Models available:${NC}"
    echo "$_tags" | python3 -c "
import sys,json
try:
  d=json.load(sys.stdin)
  models=d.get('models',[])
  for m in models:
    name=m.get('name','?')
    size=m.get('size',0)
    gb=round(size/1e9,1) if size else '?'
    print(f'    • {name}  ({gb}GB)')
  if not models:
    print('    (none pulled yet)')
except: print('    (could not parse)')
" 2>/dev/null
  fi
  echo -e "\n  ${CYAN}Save dir:${NC}  ${SAVE_DIR}"
  echo -e "  ${CYAN}Sessions:${NC}  $(ls "$SAVE_DIR" 2>/dev/null | wc -l | tr -d ' ') saved"
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  _mlines=$(wc -l < "$MEMORY_FILE" 2>/dev/null || echo 0)
  echo -e "  ${CYAN}Memory:${NC}    ${_mlines} lines"
  THEME_FILE="$HOME/.blackroad/carpool/theme.txt"
  [[ -f "$THEME_FILE" ]] && echo -e "  ${CYAN}Theme:${NC}     $(head -1 "$THEME_FILE")"
  echo ""
  exit 0
fi

# ── PROMPT — agents write AI prompts for a task (meta!) ──────
if [[ "$1" == "prompt" ]]; then
  _task="${*:2}"
  [[ -z "$_task" ]] && echo -e "${RED}Usage: br carpool prompt <task description>${NC}" && exit 1
  echo -e "\n${WHITE}✍️  Prompt Forge${NC}  ${DIM}${_task}${NC}\n"
  PR_AGENTS=(LUCIDIA OCTAVIA CIPHER ARIA)
  PR_STYLE=("philosophical / first-principles" "technical / step-by-step" "adversarial / red-team" "user-centric / UX")
  for i in 0 1 2 3; do
    _pa="${PR_AGENTS[$i]}"
    _ps="${PR_STYLE[$i]}"
    agent_meta "$_pa"
    _pc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,style,task=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Write an effective AI prompt for this task.
Style: {style}
Task: \"{task}\"
Output ONLY the prompt itself — no explanation, no wrapper, no quotes.
The prompt should be immediately usable in an AI chat window.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':150,'temperature':0.75,'stop':['---','Note:']}}))" \
    "$_pa" "$ROLE" "$_ps" "$_task" 2>/dev/null)
    echo -ne "${_pc}${EMOJI} ${_pa}${NC}  ${DIM}${_ps}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_pc}${EMOJI} ${_pa}${NC}  ${DIM}${_ps}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── INTERVIEW — mock interview, agents take turns asking you ──
if [[ "$1" == "interview" ]]; then
  _role="${*:2:-}"
  [[ -z "$_role" ]] && _role="software engineer"
  echo -e "\n${WHITE}🎙 Mock Interview${NC}  ${DIM}${_role}${NC}"
  echo -e "${DIM}Agents will ask you 5 questions. Type your answer after each. 'skip' to pass.${NC}\n"
  INT_AGENTS=(LUCIDIA OCTAVIA CIPHER PRISM SHELLFISH)
  INT_TYPE=("system design" "execution & delivery" "security thinking" "analytical depth" "edge cases & failure modes")
  for i in 0 1 2 3 4; do
    _ia="${INT_AGENTS[$i]}"
    _it="${INT_TYPE[$i]}"
    agent_meta "$_ia"
    _ic="\033[${COLOR_CODE}m"
    _qpayload=$(python3 -c "
import json,sys
agent,role_type,job=sys.argv[1],sys.argv[2],sys.argv[3]
prompt=f'You are a senior interviewer. Ask ONE tough {role_type} interview question for a {job} candidate. Question only, no intro, end with ?'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':60,'temperature':0.8,'stop':['\n\n']}}))" "$_ia" "$_it" "$_role" 2>/dev/null)
    echo -ne "${_ic}${EMOJI} ${_ia}${NC}  ${DIM}${_it}...${NC}"
    _q=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_qpayload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_ic}${EMOJI} ${_ia} [${_it}]:${NC} ${_q}\n"
    echo -ne "${CYAN}You: ${NC}"; read -r _ans
    [[ "$_ans" == "skip" || "$_ans" == "q" ]] && { echo ""; continue; }
    # Brief feedback
    _fbpayload=$(python3 -c "
import json,sys
q,a=sys.argv[1],sys.argv[2]
prompt=f'Question: {q}\nAnswer: {a}\nGive ONE sentence of feedback (strength + one improvement). Be direct.'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':60,'temperature':0.5,'stop':['\n\n']}}))" "$_q" "$_ans" 2>/dev/null)
    _fb=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_fbpayload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    echo -e "${DIM}→ ${_fb}${NC}\n"
  done
  echo -e "${WHITE}Interview complete.${NC}"
  exit 0
fi

# ── SPRINT — break a goal into a sprint backlog ──────────────
if [[ "$1" == "sprint" ]]; then
  _goal="${*:2}"
  [[ -z "$_goal" ]] && echo -e "${RED}Usage: br carpool sprint <goal>${NC}" && exit 1
  SPRINT_FILE="$HOME/.blackroad/carpool/sprints.md"
  echo -e "\n${WHITE}🏃 Sprint Planner${NC}  ${DIM}${_goal}${NC}\n"
  _payload=$(python3 -c "
import json,sys
goal=sys.argv[1]
prompt=f'''You are a senior engineering lead. Break this goal into a 2-week sprint backlog.

Goal: \"{goal}\"

Format:
EPIC: <one line epic name>

STORIES:
- [ ] <user story> (S/M/L)
- [ ] <user story> (S/M/L)
... (5-7 stories total)

DEFINITION OF DONE:
- <criterion>
- <criterion>
- <criterion>

Be specific. S=half day, M=1-2 days, L=3+ days.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':250,'temperature':0.4,'stop':['---','Note:']}}))" \
  "$_goal" 2>/dev/null)
  _backlog=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo "$_backlog"
  echo ""
  # Risk pass — CIPHER weighs in
  agent_meta "CIPHER"
  _riskpayload=$(python3 -c "
import json,sys
goal,backlog=sys.argv[1],sys.argv[2]
prompt=f'You are CIPHER, security agent. In 2 bullets: what are the top 2 risks in this sprint backlog?\nGoal: {goal}\nBacklog: {backlog}'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':80,'temperature':0.5,'stop':['---']}}))" "$_goal" "$_backlog" 2>/dev/null)
  _risk=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_riskpayload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo -e "🔒 ${DIM}CIPHER risk flags:${NC}\n${_risk}\n"
  # Save
  { echo ""; echo "## $(date '+%Y-%m-%d') — ${_goal}"; echo ""; echo "$_backlog"; echo ""; } >> "$SPRINT_FILE"
  echo -e "${DIM}Saved → ${SPRINT_FILE}${NC}"
  exit 0
fi

# ── DRAFT — agents co-write a doc (RFC/ADR/README/email/relnotes) ──
if [[ "$1" == "draft" ]]; then
  _type="${2:-rfc}"
  _topic="${*:3}"
  [[ -z "$_topic" ]] && echo -e "${RED}Usage: br carpool draft <rfc|adr|readme|email|release> <topic>${NC}" && exit 1
  DRAFT_DIR="$HOME/.blackroad/carpool/drafts"
  mkdir -p "$DRAFT_DIR"
  _slug=$(echo "$_topic" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-30)
  _out="${DRAFT_DIR}/$(date '+%Y-%m-%d')-${_type}-${_slug}.md"

  case "${_type,,}" in
    rfc)   _struct="# RFC: {topic}\n\n## Summary\n## Motivation\n## Proposal\n## Alternatives\n## Risks" ;;
    adr)   _struct="# ADR: {topic}\n\n## Status\n## Context\n## Decision\n## Consequences" ;;
    readme) _struct="# {topic}\n\n## What\n## Why\n## Quick Start\n## Usage\n## Contributing" ;;
    email) _struct="Subject: {topic}\n\nContext, ask, timeline, CTA" ;;
    release|relnotes) _struct="# Release Notes — {topic}\n\n## What's New\n## Bug Fixes\n## Breaking Changes\n## Upgrade Guide" ;;
    *)     _struct="# {topic}\n\nIntro, body, conclusion" ;;
  esac

  echo -e "\n${WHITE}📝 Draft: ${_type^^}${NC}  ${DIM}${_topic}${NC}\n"

  # Section agents: LUCIDIA writes, PRISM adds data, CIPHER adds risks, ARIA polishes
  _sections=("full first draft" "data points & evidence" "risks & caveats" "clarity & tone polish")
  _sagents=(LUCIDIA PRISM CIPHER ARIA)

  _running=""
  for i in 0 1 2 3; do
    _sa="${_sagents[$i]}"
    _ss="${_sections[$i]}"
    agent_meta "$_sa"
    _sc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,sec,typ,topic,prev,struct=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5],sys.argv[6],sys.argv[7]
prev_str=f'PREVIOUS DRAFT:\n{prev}\n\n' if prev else ''
prompt=f'''You are {agent}, {role}. Task: {sec} for a {typ} document.
Topic: \"{topic}\"
Structure hint: {struct}
{prev_str}Write or improve the draft. Output the full document text only, no meta-commentary.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':300,'temperature':0.6,'stop':['---END---']}}))" \
    "$_sa" "$ROLE" "$_ss" "$_type" "$_topic" "$_running" "$_struct" 2>/dev/null)
    echo -ne "${_sc}${EMOJI} ${_sa}${NC}  ${DIM}${_ss}...${NC}"
    _running=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_sc}${EMOJI} ${_sa}${NC}  ${DIM}${_ss} ✓${NC}"
  done

  echo -e "\n${WHITE}── Final Draft ──────────────────${NC}\n"
  echo "$_running"
  echo "$_running" > "$_out"
  echo -e "\n${DIM}Saved → ${_out}${NC}"
  exit 0
fi

# ── REFRAME — agents attack a problem from radical angles ────
if [[ "$1" == "reframe" ]]; then
  _prob="${*:2}"
  [[ -z "$_prob" ]] && echo -e "${RED}Usage: br carpool reframe <problem>${NC}" && exit 1
  echo -e "\n${WHITE}🔄 Reframe${NC}  ${DIM}${_prob}${NC}\n"
  RF_AGENTS=(LUCIDIA    SHELLFISH   ARIA      ECHO      PRISM)
  RF_LENS=(
    "invert it — what if the problem IS the solution"
    "10x it — what if the constraint was 100x harder"
    "user lens — who actually suffers and why"
    "historical lens — has this been solved before, differently"
    "data lens — what if your assumptions are wrong"
  )
  for i in 0 1 2 3 4; do
    _ra="${RF_AGENTS[$i]}"
    _rl="${RF_LENS[$i]}"
    agent_meta "$_ra"
    _rc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,prob=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}.
Reframe this problem through this lens: {lens}
Problem: \"{prob}\"
Give ONE sharp reframe in 2-3 sentences. Start with the reframe, not an explanation of what you are doing.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':100,'temperature':0.9,'stop':['---']}}))" \
    "$_ra" "$ROLE" "$_rl" "$_prob" 2>/dev/null)
    echo -ne "${_rc}${EMOJI} ${_ra}${NC}  ${DIM}${_rl:0:45}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_rc}${EMOJI} ${_ra}${NC}  ${DIM}${_rl}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── METRICS — define success metrics / KPIs for a feature ────
if [[ "$1" == "metrics" ]]; then
  _feat="${*:2}"
  THEME_FILE="$HOME/.blackroad/carpool/theme.txt"
  _ctx=""
  [[ -f "$THEME_FILE" ]] && _ctx=$(cat "$THEME_FILE")
  [[ -z "$_feat" && -n "$_ctx" ]] && _feat="$_ctx"
  [[ -z "$_feat" ]] && echo -e "${RED}Usage: br carpool metrics <feature>${NC}" && exit 1
  echo -e "\n${WHITE}📊 Metrics Design${NC}  ${DIM}${_feat}${NC}\n"
  MT_AGENTS=(PRISM OCTAVIA ARIA CIPHER)
  MT_LENS=("product / business metrics" "technical / performance metrics" "UX / user behavior metrics" "security / reliability metrics")
  for i in 0 1 2 3; do
    _mta="${MT_AGENTS[$i]}"
    _mtl="${MT_LENS[$i]}"
    agent_meta "$_mta"
    _mtc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,feat=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Define {lens} for this feature.
Feature: \"{feat}\"
List 3 metrics. Format each as:
METRIC: <name>
MEASURE: <how to measure it>
TARGET: <what good looks like>
Be specific and measurable.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':160,'temperature':0.5,'stop':['---','Note:']}}))" \
    "$_mta" "$ROLE" "$_mtl" "$_feat" 2>/dev/null)
    echo -ne "${_mtc}${EMOJI} ${_mta}${NC}  ${DIM}${_mtl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_mtc}${EMOJI} ${_mta}${NC}  ${DIM}${_mtl}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── PAIR — pair programming on a local file ───────────────────
if [[ "$1" == "pair" ]]; then
  _file="${2:-}"
  [[ -z "$_file" ]] && echo -e "${RED}Usage: br carpool pair <file>${NC}" && exit 1
  [[ ! -f "$_file" ]] && echo -e "${RED}File not found: ${_file}${NC}" && exit 1
  _ext="${_file##*.}"
  _code=$(head -80 "$_file")
  _lines=$(wc -l < "$_file" | tr -d ' ')
  echo -e "\n${WHITE}👯 Pair Programming${NC}  ${DIM}${_file}  (${_lines} lines, .${_ext})${NC}\n"
  PAIR_AGENTS=(OCTAVIA SHELLFISH PRISM)
  PAIR_LENS=("architecture & next steps" "bugs & edge cases" "refactor opportunities")
  for i in 0 1 2; do
    _pra="${PAIR_AGENTS[$i]}"
    _prl="${PAIR_LENS[$i]}"
    agent_meta "$_pra"
    _prc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,ext,code=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5]
prompt=f'''You are {agent}, {role}. Pair programming session.
File type: .{ext}
Focus: {lens}
CODE (first 80 lines):
{code}

Give 2-3 specific, actionable observations. Reference actual line content when possible.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':160,'temperature':0.5,'stop':['---']}}))" \
    "$_pra" "$ROLE" "$_prl" "$_ext" "$_code" 2>/dev/null)
    echo -ne "${_prc}${EMOJI} ${_pra}${NC}  ${DIM}${_prl}...${NC}"
    _resp=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_prc}${EMOJI} ${_pra}${NC}  ${DIM}${_prl}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── REVIEW — writing/doc review: clarity, tone, structure ────
if [[ "$1" == "review" ]]; then
  shift
  # Accept: file arg, stdin, or prompt
  _text=""
  if [[ $# -gt 0 && -f "$1" ]]; then
    _text=$(cat "$1"); _src="$1"
  elif [[ $# -gt 0 ]]; then
    _text="$*"; _src="inline"
  elif [[ ! -t 0 ]]; then
    _text=$(cat); _src="stdin"
  else
    echo -e "${CYAN}Paste text to review (Ctrl-D when done):${NC}"; _text=$(cat); _src="pasted"
  fi
  [[ -z "$_text" ]] && echo -e "${RED}No text provided.${NC}" && exit 1
  _preview="${_text:0:60}..."
  echo -e "\n${WHITE}✏️  Writing Review${NC}  ${DIM}${_preview}${NC}\n"

  RV_AGENTS=(ARIA      LUCIDIA       PRISM          CIPHER)
  RV_LENS=("clarity & structure" "argument & logic" "data & evidence" "assumptions & risks")
  for i in 0 1 2 3; do
    _rva="${RV_AGENTS[$i]}"
    _rvl="${RV_LENS[$i]}"
    agent_meta "$_rva"
    _rvc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,text=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Review this writing from the lens of: {lens}
Give 2-3 specific observations. Be direct. Note what works AND what to improve.
Format: STRONG: / IMPROVE: / SUGGEST:
TEXT:
{text[:1500]}'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':140,'temperature':0.6,'stop':['---']}}))" \
    "$_rva" "$ROLE" "$_rvl" "$_text" 2>/dev/null)
    echo -ne "${_rvc}${EMOJI} ${_rva}${NC}  ${DIM}${_rvl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_rvc}${EMOJI} ${_rva}${NC}  ${DIM}${_rvl}${NC}"
    echo -e "${_resp}\n"
  done
  exit 0
fi

# ── OKR — generate Objectives + Key Results ───────────────────
if [[ "$1" == "okr" ]]; then
  _goal="${*:2}"
  THEME_FILE="$HOME/.blackroad/carpool/theme.txt"
  [[ -z "$_goal" && -f "$THEME_FILE" ]] && _goal=$(head -1 "$THEME_FILE")
  [[ -z "$_goal" ]] && echo -e "${RED}Usage: br carpool okr <goal>${NC}" && exit 1
  OKR_FILE="$HOME/.blackroad/carpool/okrs.md"
  echo -e "\n${WHITE}🎯 OKR Generator${NC}  ${DIM}${_goal}${NC}\n"

  _okr_payload=$(python3 -c "
import json,sys
goal=sys.argv[1]
prompt=f'''Generate quarterly OKRs for this goal: \"{goal}\"

Format:
OBJECTIVE: <inspiring, qualitative outcome>

KEY RESULTS:
1. KR: <specific measurable result> — TARGET: <number/date>
2. KR: <specific measurable result> — TARGET: <number/date>
3. KR: <specific measurable result> — TARGET: <number/date>
4. KR: <specific measurable result> — TARGET: <number/date>

HEALTH METRIC: <one metric that tells you if you are on track>

Be specific and measurable. No vague KRs.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':260,'temperature':0.5,'stop':['---','Note:']}}))" \
  "$_goal" 2>/dev/null)
  _okrs=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_okr_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo -e "${_okrs}\n"

  # PRISM grades the KRs
  agent_meta "PRISM"
  _grade_payload=$(python3 -c "
import json,sys
okrs=sys.argv[1]
prompt=f'You are PRISM. Grade each Key Result: MEASURABLE? (yes/no) AMBITIOUS? (yes/no). One line per KR.\n{okrs}'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':80,'temperature':0.3}}))" "$_okrs" 2>/dev/null)
  _grade=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_grade_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo -e "${EMOJI} ${DIM}PRISM grades:${NC}\n${_grade}\n"

  { echo ""; echo "## $(date '+%Y-%m-%d') — ${_goal}"; echo ""; echo "$_okrs"; echo ""; } >> "$OKR_FILE"
  echo -e "${DIM}Saved → ${OKR_FILE}${NC}"
  exit 0
fi

# ── EXPLAIN — Socratic explanation with follow-up ─────────────
if [[ "$1" == "explain" ]]; then
  _concept="${*:2}"
  [[ -z "$_concept" ]] && echo -e "${RED}Usage: br carpool explain <concept>${NC}" && exit 1
  _agent="${EXPLAIN_AGENT:-LUCIDIA}"
  agent_meta "$_agent"
  _ec="\033[${COLOR_CODE}m"
  echo -e "\n${WHITE}🧠 Explain: ${_concept}${NC}  ${DIM}with ${_agent}${NC}\n"

  # Initial explanation
  _exp_payload=$(python3 -c "
import json,sys
agent,role,persona,concept=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''{persona}
Explain \"{concept}\" clearly.
Start with the core idea in one sentence.
Then give 3 layers of depth (ELI5 → intermediate → expert insight).
End with one question that would deepen understanding further.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':260,'temperature':0.7,'stop':['---']}}))" \
  "$_agent" "$ROLE" "$PERSONA" "$_concept" 2>/dev/null)
  echo -ne "${_ec}${EMOJI} ${_agent}${NC}  ${DIM}explaining...${NC}"
  _exp=$(curl -s -m 60 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_exp_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  printf "\r\033[K"
  echo -e "${_ec}${EMOJI} ${_agent}:${NC}\n${_exp}\n"

  # Interactive follow-up loop
  echo -e "${DIM}── ask follow-up questions (or 'done' to exit) ──${NC}\n"
  _history="$_exp"
  while true; do
    echo -ne "${CYAN}You: ${NC}"; read -r _q
    [[ "$_q" == "done" || "$_q" == "q" || -z "$_q" ]] && break
    _fup_payload=$(python3 -c "
import json,sys
agent,persona,hist,q=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''{persona}
Previous explanation: {hist[:800]}
Follow-up question: {q}
Answer directly and build on what was said. Stay concise.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':180,'temperature':0.7,'stop':['---']}}))" \
    "$_agent" "$PERSONA" "$_history" "$_q" 2>/dev/null)
    echo -ne "${_ec}${EMOJI} ${_agent}${NC}  ${DIM}thinking...${NC}"
    _ans=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_fup_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_ec}${EMOJI} ${_agent}:${NC} ${_ans}\n"
    _history="${_history} Q: ${_q} A: ${_ans}"
  done
  exit 0
fi

# ── EMAIL — draft a professional email collaboratively ─────────
if [[ "$1" == "email" ]]; then
  _subj="${*:2}"
  [[ -z "$_subj" ]] && echo -e "${RED}Usage: br carpool email <subject or situation>${NC}" && exit 1
  EMAIL_DIR="$HOME/.blackroad/carpool/emails"
  mkdir -p "$EMAIL_DIR"
  _slug=$(echo "$_subj" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-25)
  _out="${EMAIL_DIR}/$(date '+%Y-%m-%d')-${_slug}.txt"

  echo -e "\n${WHITE}📧 Email Drafter${NC}  ${DIM}${_subj}${NC}\n"

  # 3 agents, 3 tones
  EM_AGENTS=(ARIA       LUCIDIA        OCTAVIA)
  EM_TONES=("warm & collaborative" "strategic & thought-leader" "direct & executive")
  for i in 0 1 2; do
    _ema="${EM_AGENTS[$i]}"
    _emt="${EM_TONES[$i]}"
    agent_meta "$_ema"
    _emc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,tone,subj=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Write a professional email.
Subject/situation: \"{subj}\"
Tone: {tone}
Format:
Subject: <subject line>
---
<email body, 3-4 short paragraphs>
---
Sign off appropriately. No filler phrases.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':220,'temperature':0.7,'stop':['===','---END']}}))" \
    "$_ema" "$ROLE" "$_emt" "$_subj" 2>/dev/null)
    echo -ne "${_emc}${EMOJI} ${_ema}${NC}  ${DIM}${_emt}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_emc}${EMOJI} ${_ema}${NC}  ${DIM}${_emt}${NC}"
    echo -e "${_resp}\n"
    echo "── ${_ema} (${_emt}) ──" >> "$_out"
    echo "$_resp" >> "$_out"
    echo "" >> "$_out"
  done
  echo -e "${DIM}All 3 drafts saved → ${_out}${NC}"
  exit 0
fi

# ── DECISION — structured decision matrix across agents ───────
if [[ "$1" == "decision" ]]; then
  # Usage: br carpool decision "option A" vs "option B" [vs "option C"]
  # Collect options: split on "vs"
  shift
  _raw="$*"
  IFS='|' read -ra _opts <<< "$(echo "$_raw" | sed 's/ vs /|/g')"
  if [[ ${#_opts[@]} -lt 2 ]]; then
    echo -e "${RED}Usage: br carpool decision \"Option A\" vs \"Option B\" [vs \"Option C\"]${NC}"
    exit 1
  fi
  echo -e "\n${WHITE}⚖️  Decision Matrix${NC}\n"
  for o in "${_opts[@]}"; do echo -e "  ${CYAN}•${NC} ${o// /}"; done
  echo ""

  DC_AGENTS=(PRISM    CIPHER    OCTAVIA   LUCIDIA   ARIA)
  DC_LENS=("data & risk" "security & downside" "engineering effort" "long-term strategy" "user impact")
  for i in 0 1 2 3 4; do
    _dca="${DC_AGENTS[$i]}"
    _dcl="${DC_LENS[$i]}"
    agent_meta "$_dca"
    _dcc="\033[${COLOR_CODE}m"
    _opts_str=$(printf '"%s" ' "${_opts[@]}")
    _payload=$(python3 -c "
import json,sys
agent,role,lens,opts=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Evaluate these options on: {lens}
Options: {opts}
For each option give ONE line: OPTION: score/10 — reason (10 words max)
Then: PICK: <your choice> — <one sentence why>'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':120,'temperature':0.5,'stop':['---']}}))" \
    "$_dca" "$ROLE" "$_dcl" "$_opts_str" 2>/dev/null)
    echo -ne "${_dcc}${EMOJI} ${_dca}${NC}  ${DIM}${_dcl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_dcc}${EMOJI} ${_dca}${NC}  ${DIM}${_dcl}${NC}"
    echo -e "${_resp}\n"
  done
  # Tally picks
  echo -e "${DIM}── Tally picks to find consensus ──${NC}"
  agent_meta "PRISM"
  _tally_payload=$(python3 -c "
import json,sys
opts=sys.argv[1]
prompt=f'Given these options: {opts} — which one would most balanced analysis choose? Give: VERDICT: <option> — <10 word reason>'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':50,'temperature':0.3}}))" "$_opts_str" 2>/dev/null)
  _verdict=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_tally_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo -e "${GREEN}${_verdict}${NC}\n"
  exit 0
fi

# ── POSTMORTEM — incident postmortem doc ──────────────────────
if [[ "$1" == "postmortem" || "$1" == "post" ]]; then
  _incident="${*:2}"
  [[ -z "$_incident" ]] && echo -e "${RED}Usage: br carpool postmortem <incident description>${NC}" && exit 1
  PM_DIR="$HOME/.blackroad/carpool/postmortems"
  mkdir -p "$PM_DIR"
  _slug=$(echo "$_incident" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | cut -c1-30)
  _out="${PM_DIR}/$(date '+%Y-%m-%d')-${_slug}.md"
  echo -e "\n${WHITE}🔥 Postmortem${NC}  ${DIM}${_incident}${NC}\n"

  PM_AGENTS=(CIPHER     OCTAVIA      PRISM         LUCIDIA)
  PM_LENS=("root cause analysis" "timeline & detection" "impact & metrics" "prevention & process")
  for i in 0 1 2 3; do
    _pma="${PM_AGENTS[$i]}"
    _pml="${PM_LENS[$i]}"
    agent_meta "$_pma"
    _pmc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,inc=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Write the \"{lens}\" section of a postmortem.
Incident: \"{inc}\"
Be specific. Use blameless language. Format as a postmortem section with 3-4 bullet points.'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':150,'temperature':0.4,'stop':['---']}}))" \
    "$_pma" "$ROLE" "$_pml" "$_incident" 2>/dev/null)
    echo -ne "${_pmc}${EMOJI} ${_pma}${NC}  ${DIM}${_pml}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_pmc}${EMOJI} ${_pma}${NC}  ${DIM}${_pml}${NC}"
    echo -e "${_resp}\n"
    { echo "### ${_pml^^}"; echo ""; echo "$_resp"; echo ""; } >> "$_out"
  done
  sed -i '' "1s/^/# Postmortem: ${_incident}\nDate: $(date '+%Y-%m-%d')\n\n/" "$_out" 2>/dev/null \
    || sed -i "1s/^/# Postmortem: ${_incident}\nDate: $(date '+%Y-%m-%d')\n\n/" "$_out"
  echo -e "${DIM}Saved → ${_out}${NC}"
  exit 0
fi

# ── STACK — recommend a tech stack with rationale ─────────────
if [[ "$1" == "stack" ]]; then
  _problem="${*:2}"
  [[ -z "$_problem" ]] && echo -e "${RED}Usage: br carpool stack <problem to solve>${NC}" && exit 1
  echo -e "\n${WHITE}🥞 Stack Recommendation${NC}  ${DIM}${_problem}${NC}\n"

  ST_AGENTS=(OCTAVIA    SHELLFISH    ARIA        ALICE)
  ST_LENS=("backend & infra" "security & attack surface" "frontend & DX" "deployment & ops")
  for i in 0 1 2 3; do
    _sta="${ST_AGENTS[$i]}"
    _stl="${ST_LENS[$i]}"
    agent_meta "$_sta"
    _stc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,role,lens,prob=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
prompt=f'''You are {agent}, {role}. Recommend the {lens} layer for this problem.
Problem: \"{prob}\"
Format:
PICK: <specific technology>
WHY: <one sentence rationale>
AVOID: <one alternative to skip and why>'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':110,'temperature':0.6,'stop':['---']}}))" \
    "$_sta" "$ROLE" "$_stl" "$_problem" 2>/dev/null)
    echo -ne "${_stc}${EMOJI} ${_sta}${NC}  ${DIM}${_stl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_stc}${EMOJI} ${_sta}${NC}  ${DIM}${_stl}${NC}"
    echo -e "${_resp}\n"
  done
  # One-line summary
  agent_meta "PRISM"
  _sum_payload=$(python3 -c "
import json,sys
p=sys.argv[1]
prompt=f'Given this problem: \"{p}\" — give a one-line complete stack recommendation (frontend + backend + DB + deploy). Format: STACK: ...'
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':60,'temperature':0.4}}))" "$_problem" 2>/dev/null)
  _sum=$(curl -s -m 30 -X POST http://localhost:11434/api/generate \
    -H "Content-Type: application/json" -d "$_sum_payload" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
  echo -e "${GREEN}${EMOJI} ${_sum}${NC}\n"
  exit 0
fi

# ── MANIFESTO — team manifesto from theme + session history ───
if [[ "$1" == "manifesto" ]]; then
  THEME_FILE="$HOME/.blackroad/carpool/theme.txt"
  MEMORY_FILE="$HOME/.blackroad/carpool/memory.txt"
  MANIFESTO_FILE="$HOME/.blackroad/carpool/manifesto.md"
  _ctx=""
  [[ -f "$THEME_FILE" ]] && _ctx=$(cat "$THEME_FILE")
  _history=""
  [[ -f "$MEMORY_FILE" ]] && _history=$(tail -40 "$MEMORY_FILE" | grep -v "^---\|^DATE:\|^VERDICT:" | head -20)
  [[ -z "$_ctx$_history" ]] && echo -e "${DIM}Tip: set a theme first: br carpool theme set \"...\"${NC}"
  echo -e "\n${WHITE}📜 Team Manifesto${NC}\n"

  MF_AGENTS=(LUCIDIA CECE CIPHER OCTAVIA ARIA)
  MF_LENS=("core beliefs & philosophy" "human values & relationships" "what we protect & never compromise" "how we build & operate" "how we communicate & show up")
  for i in 0 1 2 3 4; do
    _mfa="${MF_AGENTS[$i]}"
    _mfl="${MF_LENS[$i]}"
    # CECE falls back to LUCIDIA for agent_meta
    _meta_agent="$_mfa"
    [[ "$_mfa" == "CECE" ]] && _meta_agent="LUCIDIA"
    agent_meta "$_meta_agent"
    [[ "$_mfa" == "CECE" ]] && EMOJI="💜" && COLOR_CODE="35"
    _mfc="\033[${COLOR_CODE}m"
    _payload=$(python3 -c "
import json,sys
agent,lens,ctx,hist=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
ctx_str=f'Project context: {ctx}\n' if ctx else ''
hist_str=f'Team history: {hist}\n' if hist else ''
prompt=f'''You are {agent} on the BlackRoad team. Write the \"{lens}\" section of our team manifesto.
{ctx_str}{hist_str}3-4 short manifesto statements. Bold, direct, present tense. Start each with \"We \".'''
print(json.dumps({'model':'tinyllama','prompt':prompt,'stream':False,
  'options':{'num_predict':130,'temperature':0.75,'stop':['---']}}))" \
    "$_mfa" "$_mfl" "$_ctx" "$_history" 2>/dev/null)
    echo -ne "${_mfc}${EMOJI} ${_mfa}${NC}  ${DIM}${_mfl}...${NC}"
    _resp=$(curl -s -m 45 -X POST http://localhost:11434/api/generate \
      -H "Content-Type: application/json" -d "$_payload" \
      | python3 -c "import sys,json; print(json.load(sys.stdin).get('response','').strip())" 2>/dev/null)
    printf "\r\033[K"
    echo -e "${_mfc}${EMOJI} ${_mfa}${NC}  ${DIM}${_mfl}${NC}"
    echo -e "${_resp}\n"
    { echo "### ${_mfl^^}"; echo ""; echo "$_resp"; echo ""; } >> "$MANIFESTO_FILE.tmp"
  done
  { echo "# BlackRoad Team Manifesto"; echo "Generated: $(date '+%Y-%m-%d')"; echo ""; cat "$MANIFESTO_FILE.tmp"; } > "$MANIFESTO_FILE"
  rm -f "$MANIFESTO_FILE.tmp"
  echo -e "${DIM}Saved → ${MANIFESTO_FILE}${NC}"
  exit 0
fi

# ── HYPOTHESIS — agents debate a claim ────────────────────────────────
if [[ "$1" == "hypothesis" ]]; then
  shift
  CLAIM="$*"
  [[ -z "$CLAIM" ]] && echo "Usage: br carpool hypothesis <claim>" && exit 1
  echo ""
  echo -e "\033[1;35m🔬 HYPOTHESIS TEST\033[0m"
  echo -e "\033[0;36mClaim: $CLAIM\033[0m"
  echo ""
  verdicts=""
  for entry in "LUCIDIA|SUPPORT|philosophical" "SHELLFISH|REFUTE|adversarial" "PRISM|EVIDENCE|data-driven" "OCTAVIA|TECHNICAL|engineering" "ALICE|PRACTICAL|operational"; do
    IFS='|' read -r ag stance lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} [${stance}]${NC}"
    resp=$(python3 -c "
import urllib.request, json, sys
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}, a ${lens} AI on the BlackRoad team.
Claim: \"${CLAIM}\"
Verdict: SUPPORT, REFUTE, or NEEDS_MORE_DATA (pick one).
Evidence: 2-3 specific points.
Format: VERDICT: <word>\nEVIDENCE:\n- ...\n- ...\nCONFIDENCE: X%''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    verdict_line=$(echo "$resp" | grep "^VERDICT:" | head -1 | sed 's/VERDICT: *//')
    verdicts="${verdicts} ${ag}:${verdict_line}"
    echo ""
  done
  support=$(echo "$verdicts" | tr ' ' '\n' | grep -c "SUPPORT" || true)
  refute=$(echo "$verdicts" | tr ' ' '\n' | grep -c "REFUTE" || true)
  needs=$(echo "$verdicts" | tr ' ' '\n' | grep -c "NEEDS_MORE_DATA" || true)
  echo -e "\033[1;33m──────────────────────────────────────────\033[0m"
  echo -e "\033[1;33m📊 VERDICT TALLY\033[0m"
  echo "  SUPPORT        $support"
  echo "  REFUTE         $refute"
  echo "  NEEDS_MORE_DATA $needs"
  if [[ $support -gt $refute ]]; then
    echo -e "\033[0;32m→ HYPOTHESIS SUPPORTED\033[0m"
  elif [[ $refute -gt $support ]]; then
    echo -e "\033[0;31m→ HYPOTHESIS REFUTED\033[0m"
  else
    echo -e "\033[1;33m→ INCONCLUSIVE — gather more evidence\033[0m"
  fi
  exit 0
fi

# ── LEARNING — generate a learning path for a topic ───────────────────
if [[ "$1" == "learning" || "$1" == "learn" ]]; then
  shift
  TOPIC="$*"
  [[ -z "$TOPIC" ]] && echo "Usage: br carpool learning <topic>" && exit 1
  echo ""
  echo -e "\033[1;36m📚 LEARNING PATH: $TOPIC\033[0m"
  echo ""
  for entry in "LUCIDIA|FOUNDATIONS|Why does this matter? Core concepts and mental models." "ALICE|RESOURCES|Best books, courses, docs, and hands-on projects." "PRISM|MILESTONES|How to measure progress — 30/60/90 day checkpoints." "OCTAVIA|PRACTICE|Projects to build and systems to study in depth."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} helping someone learn \"${TOPIC}\".
Your role: ${lens}
Give 4-6 specific, actionable items.
Format each as: • <item> — <why/how>
Be concrete, not generic.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  exit 0
fi

# ── STANDUP-BOT — post AI-generated standup to a webhook ──────────────
if [[ "$1" == "standup-bot" || "$1" == "standup-post" ]]; then
  shift
  WEBHOOK="$1"
  [[ -z "$WEBHOOK" ]] && WEBHOOK="${CARPOOL_WEBHOOK:-}"
  [[ -z "$WEBHOOK" ]] && echo "Usage: br carpool standup-bot <webhook-url>" && echo "Or set CARPOOL_WEBHOOK in ~/.blackroad/carpool/config.sh" && exit 1
  # Load memory for context
  HIST=""
  if [[ -f "$HOME/.blackroad/carpool/memory.txt" ]]; then
    HIST=$(tail -20 "$HOME/.blackroad/carpool/memory.txt")
  fi
  echo -e "\033[1;35m🤖 STANDUP BOT\033[0m"
  echo "Generating standup from session history..."
  STANDUP=$(python3 -c "
import urllib.request, json
hist = '''${HIST}'''
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''Generate a crisp daily standup update from this session history:

{hist}

Format:
*Yesterday:* <what was accomplished>
*Today:* <main focus>
*Blockers:* <any blockers or None>

Keep it under 5 lines total. Be specific.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "Yesterday: Built features. Today: Keep shipping. Blockers: None.")
  echo ""
  echo "$STANDUP"
  echo ""
  # Post to webhook (Slack/Discord/generic JSON)
  PAYLOAD="{\"text\":\"$STANDUP\"}"
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$WEBHOOK" 2>/dev/null || echo "000")
  if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "204" ]]; then
    echo -e "\033[0;32m✓ Posted to webhook (HTTP $HTTP_STATUS)\033[0m"
  else
    echo -e "\033[0;31m✗ Webhook returned HTTP $HTTP_STATUS\033[0m"
    echo "Standup text above can be copy-pasted manually."
  fi
  exit 0
fi

# ── ONBOARD — generate an onboarding plan for a new team member ───────
if [[ "$1" == "onboard" ]]; then
  shift
  ROLE="$*"
  ROLE="${ROLE:-engineer}"
  echo ""
  echo -e "\033[1;32m🚀 ONBOARDING PLAN: $ROLE\033[0m"
  echo ""
  SAVE_FILE="$HOME/.blackroad/carpool/onboarding-$(echo "$ROLE" | tr ' ' '-').md"
  mkdir -p "$HOME/.blackroad/carpool"
  echo "# Onboarding Plan: $ROLE" > "$SAVE_FILE"
  echo "Generated: $(date '+%Y-%m-%d')" >> "$SAVE_FILE"
  echo "" >> "$SAVE_FILE"
  for entry in "ALICE|WEEK 1: ORIENTATION|Setup, tooling, first PR, meet the team." "OCTAVIA|WEEK 2: SYSTEMS|Architecture deep-dive, infra access, first feature." "PRISM|30-60-90 DAYS|Milestones and metrics to measure progress." "ARIA|CULTURE & COMMS|Team norms, communication channels, unwritten rules." "LUCIDIA|GROWTH PATH|What mastery looks like in this role 6-12 months out."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Create the \"${section}\" section of an onboarding plan for a new ${ROLE} joining BlackRoad OS.
${lens}
Give 4-6 specific, actionable checklist items.
Format: - [ ] <item>
Be concrete. Assume a technical team with high standards.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    echo "" >> "$SAVE_FILE"
    echo "## ${section}" >> "$SAVE_FILE"
    echo "$resp" >> "$SAVE_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $SAVE_FILE\033[0m"
  exit 0
fi

# ── RETRO — sprint retrospective: went well / delta / ideas ───────────
if [[ "$1" == "retro" ]]; then
  echo ""
  echo -e "\033[1;36m🔄 SPRINT RETROSPECTIVE\033[0m"
  echo ""
  HIST=""
  [[ -f "$HOME/.blackroad/carpool/memory.txt" ]] && HIST=$(tail -30 "$HOME/.blackroad/carpool/memory.txt")
  RETRO_FILE="$HOME/.blackroad/carpool/retros/retro-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/retros"
  echo "# Retro $(date '+%Y-%m-%d')" > "$RETRO_FILE"
  for entry in "ARIA|WENT WELL|Celebrate what worked. Be specific, name the wins." "ALICE|DELTA|What should change next sprint? Concrete improvements, not complaints." "OCTAVIA|TECH DEBT|What technical shortcuts are slowing us down? Rank by impact." "PRISM|METRICS|What numbers moved? What should we track next sprint?" "LUCIDIA|BIG IDEA|One bold experiment to try next sprint. Unconventional OK."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
hist = '''${HIST}'''
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} running a sprint retrospective.
Session history: {hist}
Your section: ${section}
${lens}
Give 3-4 specific bullets. Format: - <item>
No preamble.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$RETRO_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $RETRO_FILE\033[0m"
  exit 0
fi

# ── PITCH — elevator pitch + investor Q&A from 4 agent lenses ─────────
if [[ "$1" == "pitch" ]]; then
  shift
  IDEA="$*"
  [[ -z "$IDEA" ]] && echo "Usage: br carpool pitch <idea>" && exit 1
  echo ""
  echo -e "\033[1;33m🎤 PITCH ROOM: $IDEA\033[0m"
  echo ""
  # Step 1: ARIA writes the pitch
  IFS='|' read -r _ col _ emoji <<< "$(agent_meta "ARIA")"
  echo -e "${col}${emoji} ARIA — ELEVATOR PITCH${NC}"
  PITCH=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ARIA, a sharp product communicator.
Write a 30-second elevator pitch for: \"${IDEA}\"
Format:
HOOK: <one punchy sentence>
PROBLEM: <what pain it solves>
SOLUTION: <what it does>
TRACTION: <made-up but plausible metric>
ASK: <what you want from investors>
Be bold and specific.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[ARIA offline]")
  echo "$PITCH"
  echo ""
  # Step 2: Tough investor Q&A
  for entry in "CIPHER|SKEPTIC|Poke holes. What is the biggest risk, moat problem, or execution gap?" "PRISM|DATA ANALYST|What metrics are missing? What would you need to see to believe this?" "OCTAVIA|TECHNICAL|Is this technically feasible? What is the hardest engineering challenge?"; do
    IFS='|' read -r ag role lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${role} QUESTIONS${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are a tough ${role} investor interrogating this pitch: \"${IDEA}\"
${lens}
Ask 2 hard questions then give a brief verdict (PASS/CONDITIONAL/NO).
Format:
Q1: <question>
Q2: <question>
VERDICT: <PASS|CONDITIONAL|NO> — <one line reason>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  exit 0
fi

# ── RISK — CIPHER + SHELLFISH surface risks for a plan/feature ────────
if [[ "$1" == "risk" ]]; then
  shift
  PLAN="$*"
  [[ -z "$PLAN" ]] && echo "Usage: br carpool risk <plan or feature>" && exit 1
  echo ""
  echo -e "\033[1;31m⚠️  RISK ANALYSIS: $PLAN\033[0m"
  echo ""
  for entry in "CIPHER|SECURITY RISKS|Auth, data exposure, supply chain, secrets, access control." "SHELLFISH|EXPLOIT VECTORS|What would an attacker do with this? Think adversarially." "OCTAVIA|OPERATIONAL RISKS|Failures, scaling cliffs, single points of failure, runbooks." "PRISM|BUSINESS RISKS|Market, regulatory, dependency, reputational risks." "ALICE|MITIGATION PLAN|For the top 3 risks above, give a concrete mitigation step each."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} doing a risk analysis on: \"${PLAN}\"
Focus: ${lens}
List 3-4 specific risks.
Format each: RISK: <name> | SEVERITY: HIGH/MED/LOW | DETAIL: <one line>
No preamble.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  exit 0
fi

# ── COMPARE — side-by-side comparison of two options ──────────────────
if [[ "$1" == "compare" ]]; then
  shift
  INPUT="$*"
  [[ -z "$INPUT" ]] && echo 'Usage: br carpool compare "<A>" vs "<B>"' && exit 1
  # Parse A vs B
  OPT_A=$(echo "$INPUT" | sed 's/ [Vv][Ss]\.* .*//')
  OPT_B=$(echo "$INPUT" | sed 's/.*[Vv][Ss]\.* //')
  [[ "$OPT_A" == "$OPT_B" ]] && OPT_A=$(echo "$INPUT" | awk '{print $1}') && OPT_B=$(echo "$INPUT" | awk '{print $NF}')
  echo ""
  echo -e "\033[1;36m⚖️  COMPARE\033[0m"
  echo -e "  \033[1;32mA: $OPT_A\033[0m  vs  \033[1;31mB: $OPT_B\033[0m"
  echo ""
  for entry in "OCTAVIA|TECHNICAL FIT|Performance, complexity, maintainability, scalability." "ALICE|OPERATIONAL FIT|Deployment, monitoring, team skills, tooling." "PRISM|DATA & METRICS|Ecosystem maturity, benchmarks, adoption trends." "LUCIDIA|PHILOSOPHY|Which aligns better with long-term principles and vision?" "CIPHER|RISK DELTA|Which carries more security, reliability, or compliance risk?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    python3 -c "
import urllib.request, json
a = '${OPT_A}'
b = '${OPT_B}'
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Compare \"{a}\" vs \"{b}\" from a ${section} perspective.
Focus: ${lens}
Format:
A WINS: <reason>
B WINS: <reason>
EDGE: A or B (one word pick)''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  # Tally edges
  echo -e "\033[1;33m──────────────────────────────────────────\033[0m"
  echo -e "\033[1;33m📊 Run 'br carpool decision \"${OPT_A}\" vs \"${OPT_B}\"' for full decision matrix\033[0m"
  exit 0
fi

# ── NAMING — brainstorm names for a product / feature / variable ──────
if [[ "$1" == "naming" || "$1" == "names" ]]; then
  shift
  THING="$*"
  [[ -z "$THING" ]] && echo "Usage: br carpool naming <thing to name>" && exit 1
  echo ""
  echo -e "\033[1;35m🏷️  NAMING SESSION: $THING\033[0m"
  echo ""
  for entry in "ARIA|BRAND NAMES|Memorable, catchy, marketable. Think product launch." "LUCIDIA|CONCEPTUAL|Names that capture the essence or philosophy." "OCTAVIA|TECHNICAL|Clear, precise names engineers would love. No fluff." "PRISM|DATA-DRIVEN|Names that test well: short, unique, googleable, .io available." "SHELLFISH|SUBVERSIVE|Unexpected names. Play on words, references, inside jokes."; do
    IFS='|' read -r ag style lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${style}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Brainstorm names for: \"${THING}\"
Style: ${style} — ${lens}
Give exactly 6 names.
Format:
1. <name> — <one-line rationale>
2. ...
No preamble.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  exit 0
fi

# ── SCOPE — agents define MVP vs full scope, what to cut ──────────────
if [[ "$1" == "scope" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool scope <feature or project>" && exit 1
  echo ""
  echo -e "\033[1;36m📐 SCOPE DEFINITION: $FEATURE\033[0m"
  echo ""
  SCOPE_FILE="$HOME/.blackroad/carpool/scopes/scope-$(date +%Y%m%d-%H%M).md"
  mkdir -p "$HOME/.blackroad/carpool/scopes"
  printf "# Scope: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$SCOPE_FILE"
  for entry in "ALICE|MVP (ship this week)|The absolute minimum to deliver value. If you can cut it, cut it." "OCTAVIA|V1 (ship this month)|What makes this genuinely good. Core features, not polish." "ARIA|V2 (next quarter)|Nice-to-haves, delight features, UX polish, power user tools." "PRISM|METRICS TO TRACK|How will we know if this worked? 3-5 measurable success criteria." "CIPHER|WHAT TO SKIP FOREVER|Features that add complexity without enough value. Kill list."; do
    IFS='|' read -r ag phase lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${phase}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} scoping: \"${FEATURE}\"
Phase: ${phase}
${lens}
Give 4-6 specific items. Format: - <item>
Be ruthlessly practical.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$phase" "$resp" >> "$SCOPE_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $SCOPE_FILE\033[0m"
  exit 0
fi

# ── PERSONA — build a user persona with needs, pains, behaviors ───────
if [[ "$1" == "persona" ]]; then
  shift
  USER_TYPE="$*"
  USER_TYPE="${USER_TYPE:-developer}"
  echo ""
  echo -e "\033[1;32m👤 USER PERSONA: $USER_TYPE\033[0m"
  echo ""
  PERSONA_FILE="$HOME/.blackroad/carpool/personas/$(echo "$USER_TYPE" | tr ' ' '-').md"
  mkdir -p "$HOME/.blackroad/carpool/personas"
  printf "# Persona: %s\n\n" "$USER_TYPE" > "$PERSONA_FILE"
  for entry in "ARIA|PROFILE|Name, job, age, tech comfort, daily tools. Make them feel real." "LUCIDIA|MOTIVATIONS|What drives them? Goals, aspirations, why they care about this problem." "PRISM|PAIN POINTS|Top 3 frustrations ranked by intensity. Quote format — their words." "ALICE|BEHAVIORS|How they actually work day-to-day. Workflows, shortcuts, workarounds." "OCTAVIA|TECHNICAL CONTEXT|Stack they use, infra they manage, tools they live in." "SHELLFISH|HIDDEN NEEDS|What they want but would never say in a user interview."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} building a user persona for: \"${USER_TYPE}\"
Section: ${section}
${lens}
Be specific and vivid. 3-5 lines.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$PERSONA_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $PERSONA_FILE\033[0m"
  exit 0
fi

# ── CHANGELOG — auto-generate a changelog from git log ────────────────
if [[ "$1" == "changelog" ]]; then
  shift
  RANGE="${1:-HEAD~20..HEAD}"
  echo ""
  echo -e "\033[1;33m📋 CHANGELOG GENERATOR\033[0m"
  echo -e "\033[0;36mRange: $RANGE\033[0m"
  echo ""
  GIT_LOG=$(git --no-pager log "$RANGE" --oneline --no-merges 2>/dev/null | head -40)
  [[ -z "$GIT_LOG" ]] && GIT_LOG=$(git --no-pager log --oneline --no-merges -20 2>/dev/null)
  [[ -z "$GIT_LOG" ]] && echo "No git history found." && exit 1
  CHANGELOG_FILE="$HOME/.blackroad/carpool/changelogs/CHANGELOG-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/changelogs"
  for entry in "ALICE|USER-FACING CHANGES|What changed for users? New features, removed friction, fixed bugs." "OCTAVIA|TECHNICAL CHANGES|Infrastructure, performance, architecture changes engineers care about." "CIPHER|SECURITY CHANGES|Any security fixes, auth changes, dependency updates worth highlighting." "ARIA|RELEASE NOTES (DRAFT)|A friendly, human-readable release summary. Emoji OK. Max 10 lines."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json, sys
log = sys.argv[1]
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Analyze this git log and write the ${section} section of a changelog.
${lens}
Git log:
{log}
Format as clean markdown bullet points. Group by theme if possible.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" "$GIT_LOG" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$CHANGELOG_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $CHANGELOG_FILE\033[0m"
  exit 0
fi

# ── DIAGRAM — ASCII architecture diagram from agents ──────────────────
if [[ "$1" == "diagram" ]]; then
  shift
  SYSTEM="$*"
  [[ -z "$SYSTEM" ]] && echo "Usage: br carpool diagram <system or component>" && exit 1
  echo ""
  echo -e "\033[1;36m📐 ARCHITECTURE DIAGRAM: $SYSTEM\033[0m"
  echo ""
  DIAG_FILE="$HOME/.blackroad/carpool/diagrams/$(echo "$SYSTEM" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/diagrams"
  printf "# Diagram: %s\nDate: %s\n\n" "$SYSTEM" "$(date '+%Y-%m-%d')" > "$DIAG_FILE"
  for entry in "OCTAVIA|SYSTEM OVERVIEW|Draw the top-level components and how data flows between them. Use ASCII boxes and arrows." "ALICE|DEPLOYMENT VIEW|Show how this is deployed: servers, containers, networks, load balancers." "CIPHER|TRUST BOUNDARIES|Mark auth zones, encrypted channels, public vs private surfaces."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Draw an ASCII diagram for: \"${SYSTEM}\"
Section: ${section}
${lens}
Use ASCII art: boxes with +--+, arrows with --> or -->, labels inline.
Keep it under 25 lines. No explanation before or after — just the diagram then a 2-line legend.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n\`\`\`\n%s\n\`\`\`\n" "$section" "$resp" >> "$DIAG_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $DIAG_FILE\033[0m"
  exit 0
fi

# ── STORIES — generate user stories for a feature ─────────────────────
if [[ "$1" == "stories" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool stories <feature>" && exit 1
  echo ""
  echo -e "\033[1;33m📖 USER STORIES: $FEATURE\033[0m"
  echo ""
  STORIES_FILE="$HOME/.blackroad/carpool/stories/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/stories"
  printf "# Stories: %s\n\n" "$FEATURE" > "$STORIES_FILE"
  for entry in "ARIA|USER STORIES|As a <user>, I want <goal>, so that <reason>. Write 5 stories for different user types." "OCTAVIA|TECHNICAL TASKS|Break each story into 2-3 concrete engineering tasks. Format: - [ ] <task>" "CIPHER|SECURITY STORIES|As a <attacker/admin/auditor>... Edge cases, auth checks, data validation stories." "PRISM|ACCEPTANCE CRITERIA|For the top 3 stories, write Given/When/Then acceptance criteria."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Write the \"${section}\" for this feature: \"${FEATURE}\"
${lens}
Be specific, not generic. Use real-world details.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$STORIES_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $STORIES_FILE\033[0m"
  exit 0
fi

# ── CONTRACT — generate API contract / interface spec ─────────────────
if [[ "$1" == "contract" ]]; then
  shift
  API="$*"
  [[ -z "$API" ]] && echo "Usage: br carpool contract <api or service name>" && exit 1
  echo ""
  echo -e "\033[1;35m📜 API CONTRACT: $API\033[0m"
  echo ""
  CONTRACT_FILE="$HOME/.blackroad/carpool/contracts/$(echo "$API" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/contracts"
  printf "# API Contract: %s\nDate: %s\n\n" "$API" "$(date '+%Y-%m-%d')" > "$CONTRACT_FILE"
  for entry in "OCTAVIA|ENDPOINTS|Design the REST endpoints. Method, path, request body, response shape, status codes." "ALICE|ERROR HANDLING|All error codes this API should return with message format and retry guidance." "CIPHER|AUTH & SECURITY|Auth method, rate limits, required headers, what data must be encrypted." "PRISM|SLAs & LIMITS|Latency targets, rate limits, payload size limits, pagination approach." "SHELLFISH|EDGE CASES|The weird inputs, race conditions, and abuse patterns this contract must handle."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing an API contract for: \"${API}\"
Section: ${section}
${lens}
Use concrete examples with real field names and values. Format as markdown code blocks where appropriate.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$CONTRACT_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $CONTRACT_FILE\033[0m"
  exit 0
fi

# ── DEBUG — systematic multi-agent debugging session ──────────────────
if [[ "$1" == "debug" ]]; then
  shift
  SYMPTOM="$*"
  [[ -z "$SYMPTOM" ]] && echo "Usage: br carpool debug <symptom or behavior>" && exit 1
  echo ""
  echo -e "\033[1;31m🐛 DEBUG SESSION\033[0m"
  echo -e "\033[0;36mSymptom: $SYMPTOM\033[0m"
  echo ""
  hypotheses=""
  for entry in "SHELLFISH|HYPOTHESIS|Assume nothing works as intended. What is the most likely root cause?" "OCTAVIA|SYSTEM STATE|What system state / environment condition could produce this? Check list." "PRISM|PATTERN MATCH|Have you seen this class of bug before? What pattern does it match?" "ALICE|REPRODUCTION|Step-by-step: how would you reliably reproduce this in under 5 minutes?" "CIPHER|SECURITY ANGLE|Could this be an exploit, timing attack, or auth bypass masquerading as a bug?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} debugging: \"${SYMPTOM}\"
Your angle: ${section} — ${lens}
Give 3-4 specific diagnostic steps or hypotheses.
Format: STEP/HYPOTHESIS: <text>
End with: MOST LIKELY: <one line root cause guess>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    likely=$(echo "$resp" | grep "^MOST LIKELY:" | head -1 | sed 's/MOST LIKELY: *//')
    [[ -n "$likely" ]] && hypotheses="${hypotheses}\n  ${ag}: $likely"
    echo ""
  done
  echo -e "\033[1;33m──────────────────────────────────────────\033[0m"
  echo -e "\033[1;33m🔍 ROOT CAUSE CANDIDATES\033[0m"
  printf "%b\n" "$hypotheses"
  echo ""
  echo -e "\033[0;36mTip: Run 'br carpool fix <error>' once you have an error message\033[0m"
  exit 0
fi

# ── GOAL — decompose a goal into projects, milestones, and next actions ─
if [[ "$1" == "goal" ]]; then
  shift
  GOAL="$*"
  [[ -z "$GOAL" ]] && echo "Usage: br carpool goal <your goal>" && exit 1
  echo ""
  echo -e "\033[1;32m🎯 GOAL DECOMPOSITION: $GOAL\033[0m"
  echo ""
  GOAL_FILE="$HOME/.blackroad/carpool/goals/$(echo "$GOAL" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/goals"
  printf "# Goal: %s\nDate: %s\n\n" "$GOAL" "$(date '+%Y-%m-%d')" > "$GOAL_FILE"
  for entry in "LUCIDIA|WHY IT MATTERS|The deeper purpose. What does achieving this unlock? Why now?" "ALICE|FIRST 3 ACTIONS|The 3 immediate next actions you can do today. Concrete, no vague steps." "OCTAVIA|PROJECTS & MILESTONES|Break this into 3-5 sub-projects, each with a measurable milestone." "PRISM|SUCCESS METRICS|How will you know when done? 3-5 specific measurable outcomes." "SHELLFISH|OBSTACLES|Top 3 things that will kill this goal. Be brutally honest."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Help decompose this goal: \"${GOAL}\"
Section: ${section}
${lens}
Be concrete and direct. 3-5 items max.
Format: - <item>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$GOAL_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $GOAL_FILE\033[0m"
  exit 0
fi

# ── MIGRATE — plan a migration (db, infra, API version, language) ─────
if [[ "$1" == "migrate" || "$1" == "migration" ]]; then
  shift
  MIGRATION="$*"
  [[ -z "$MIGRATION" ]] && echo "Usage: br carpool migrate <what you are migrating>" && exit 1
  echo ""
  echo -e "\033[1;33m🚚 MIGRATION PLAN: $MIGRATION\033[0m"
  echo ""
  MIG_FILE="$HOME/.blackroad/carpool/migrations/$(echo "$MIGRATION" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/migrations"
  printf "# Migration: %s\nDate: %s\n\n" "$MIGRATION" "$(date '+%Y-%m-%d')" > "$MIG_FILE"
  for entry in "OCTAVIA|TECHNICAL STEPS|The exact sequence of steps to execute this migration safely." "ALICE|ROLLBACK PLAN|How to undo every step if something goes wrong. No migration without rollback." "CIPHER|RISK SURFACE|What secrets, permissions, or access controls change? What could leak?" "PRISM|VALIDATION CHECKS|How to verify each step succeeded. Tests, queries, and health checks." "SHELLFISH|FAILURE MODES|The 3 most likely ways this migration fails. Murphy's Law applied."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} planning a migration: \"${MIGRATION}\"
Section: ${section}
${lens}
Be specific. Numbered steps where applicable.
Format: numbered list or bullets with clear action verbs.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$MIG_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $MIG_FILE\033[0m"
  exit 0
fi

# ── INTERVIEW-PREP — prep for a technical interview on a topic ────────
if [[ "$1" == "interview-prep" || "$1" == "prep" ]]; then
  shift
  TOPIC="$*"
  TOPIC="${TOPIC:-software engineering}"
  echo ""
  echo -e "\033[1;36m🎓 INTERVIEW PREP: $TOPIC\033[0m"
  echo ""
  for entry in "PRISM|LIKELY QUESTIONS|5 questions most likely to be asked. Include one curveball." "OCTAVIA|TECHNICAL DEPTH|2 hard deep-dive questions with what a great answer looks like." "ALICE|BEHAVIORAL|3 STAR-format behavioral questions tailored to this topic." "LUCIDIA|WHAT INTERVIEWERS REALLY WANT|What signals separate a good answer from a great one?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} prepping a candidate for a \"${TOPIC}\" interview.
Section: ${section}
${lens}
Be specific to the topic. Give real, substantive content — not generic advice.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  exit 0
fi

# ── REFACTOR — multi-agent code refactor plan for a file or module ────
if [[ "$1" == "refactor" ]]; then
  shift
  TARGET="$1"
  [[ -z "$TARGET" ]] && echo "Usage: br carpool refactor <file or module>" && exit 1
  CODE=""
  if [[ -f "$TARGET" ]]; then
    CODE=$(head -80 "$TARGET")
    LABEL="$TARGET"
  else
    LABEL="$TARGET (module)"
  fi
  echo ""
  echo -e "\033[1;35m♻️  REFACTOR PLAN: $LABEL\033[0m"
  echo ""
  RF_FILE="$HOME/.blackroad/carpool/refactors/$(basename "$TARGET" | tr '.' '-')-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/refactors"
  printf "# Refactor: %s\nDate: %s\n\n" "$LABEL" "$(date '+%Y-%m-%d')" > "$RF_FILE"
  for entry in "OCTAVIA|STRUCTURE|Split, extract, consolidate. What modules/functions should exist?" "SHELLFISH|DEAD CODE|What can be deleted outright? Be ruthless." "PRISM|COMPLEXITY|Cyclomatic complexity hotspots. What is hardest to understand?" "ALICE|QUICK WINS|Changes that can ship in under 30 minutes with immediate improvement." "CIPHER|HIDDEN BUGS|Refactor risks — what could break silently if changed?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json, sys
code = sys.argv[1]
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} doing a refactor review of: \"${LABEL}\"
${\"Code preview:\" + chr(10) + code if code else \"\"}
Section: ${section}
${lens}
Give 3-4 specific, actionable items. Format: - <item>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" "$CODE" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$RF_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $RF_FILE\033[0m"
  exit 0
fi

# ── ROADMAP — 4-quarter product roadmap from agent perspectives ────────
if [[ "$1" == "roadmap" ]]; then
  shift
  PRODUCT="$*"
  [[ -z "$PRODUCT" ]] && echo "Usage: br carpool roadmap <product or project>" && exit 1
  echo ""
  echo -e "\033[1;36m🗺️  PRODUCT ROADMAP: $PRODUCT\033[0m"
  echo ""
  ROAD_FILE="$HOME/.blackroad/carpool/roadmaps/$(echo "$PRODUCT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/roadmaps"
  printf "# Roadmap: %s\nDate: %s\n\n" "$PRODUCT" "$(date '+%Y-%m-%d')" > "$ROAD_FILE"
  YEAR=$(date +%Y)
  for entry in "ALICE|Q1 — FOUNDATION|Core infra, auth, data model, CI/CD. What must exist before anything else?" "ARIA|Q2 — LAUNCH|The features that make users say wow. Public-facing, delightful, shareable." "OCTAVIA|Q3 — SCALE|Performance, reliability, observability. Handle 10x the load without heroics." "PRISM|Q4 — GROWTH|Analytics, growth loops, integrations, enterprise features. Data-driven expansion." "LUCIDIA|YEAR 2 VISION|Where does this product go if everything works? The moonshot."; do
    IFS='|' read -r ag phase lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${phase}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} planning a product roadmap for: \"${PRODUCT}\"
Phase: ${phase} (${YEAR})
${lens}
List 4-6 specific deliverables. Format:
- [ ] <deliverable> — <one-line impact>
Be concrete. No generic filler.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$phase" "$resp" >> "$ROAD_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $ROAD_FILE\033[0m"
  exit 0
fi

# ── ARCHITECT — each agent proposes a system design approach ──────────
if [[ "$1" == "architect" ]]; then
  shift
  PROBLEM="$*"
  [[ -z "$PROBLEM" ]] && echo "Usage: br carpool architect <system design problem>" && exit 1
  echo ""
  echo -e "\033[1;35m🏗️  SYSTEM DESIGN: $PROBLEM\033[0m"
  echo ""
  ARCH_FILE="$HOME/.blackroad/carpool/architectures/$(echo "$PROBLEM" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/architectures"
  printf "# Architecture: %s\nDate: %s\n\n" "$PROBLEM" "$(date '+%Y-%m-%d')" > "$ARCH_FILE"
  approaches=""
  for entry in "OCTAVIA|BORING TECH|Use proven, boring technology. Postgres, Redis, monolith-first. No hype." "SHELLFISH|DISTRIBUTED|Microservices, event-driven, CQRS. Optimize for team autonomy and fault isolation." "ALICE|SERVERLESS|Functions, edge workers, managed services. Minimize ops burden." "LUCIDIA|EMERGENT|Start with the simplest thing. Let the architecture reveal itself through use."; do
    IFS='|' read -r ag approach lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${approach}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Design a system for: \"${PROBLEM}\"
Your philosophy: ${approach} — ${lens}
Describe:
STACK: <key technologies>
STRUCTURE: <how it is organized>
TRADEOFF: <what you sacrifice for what you gain>
Keep it under 8 lines. Be opinionated.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$approach" "$resp" >> "$ARCH_FILE"
    approaches="${approaches}${ag}(${approach}) "
    echo ""
  done
  # PRISM picks a winner
  IFS='|' read -r _ col _ emoji <<< "$(agent_meta "PRISM")"
  echo -e "${col}${emoji} PRISM — RECOMMENDATION${NC}"
  python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are PRISM. Four architectures were proposed for \"${PROBLEM}\": boring tech, distributed, serverless, and emergent.
Given a typical startup with a small team, limited runway, and need to ship fast:
RECOMMEND: <which approach>
REASON: <2-3 sentences why>
HYBRID: <one thing to borrow from each of the others>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[PRISM offline]"
  echo ""
  echo -e "\033[0;32m✓ Saved to $ARCH_FILE\033[0m"
  exit 0
fi

# ── TAGLINE — agents generate product taglines and slogans ────────────
if [[ "$1" == "tagline" || "$1" == "slogan" ]]; then
  shift
  PRODUCT="$*"
  [[ -z "$PRODUCT" ]] && echo "Usage: br carpool tagline <product or idea>" && exit 1
  echo ""
  echo -e "\033[1;33m✨ TAGLINE GENERATOR: $PRODUCT\033[0m"
  echo ""
  for entry in "ARIA|EMOTIONAL|Taglines that make people feel something. Hope, FOMO, belonging." "LUCIDIA|PHILOSOPHICAL|Big ideas in few words. Think Apple-level abstraction." "PRISM|DATA-BACKED|Taglines built on a specific number or claim. Credible, specific." "SHELLFISH|PROVOCATIVE|Challenge assumptions. Make the competition uncomfortable." "ALICE|FUNCTIONAL|Taglines that say exactly what it does. No metaphors, just value."; do
    IFS='|' read -r ag style lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${style}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Write 5 taglines for: \"${PRODUCT}\"
Style: ${style} — ${lens}
Rules: under 8 words each, no generic filler like \"the future of\".
Format:
1. \"<tagline>\"
2. ...
No explanation.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  exit 0
fi

# ── RESUME — agents help tailor a resume/bio for a role ──────────────
if [[ "$1" == "resume" || "$1" == "bio" ]]; then
  shift
  ROLE="$*"
  ROLE="${ROLE:-software engineer}"
  echo ""
  echo -e "\033[1;32m📄 RESUME / BIO COACH: $ROLE\033[0m"
  echo ""
  RESUME_FILE="$HOME/.blackroad/carpool/resumes/$(echo "$ROLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/resumes"
  printf "# Resume Guide: %s\nDate: %s\n\n" "$ROLE" "$(date '+%Y-%m-%d')" > "$RESUME_FILE"
  for entry in "ARIA|PERSONAL BRAND|Your one-liner. The thing people remember. Sub-headline for LinkedIn/GitHub." "PRISM|KEYWORDS TO HIT|The exact keywords ATS systems and hiring managers scan for in this role." "ALICE|BULLET FORMULA|How to write experience bullets: VERB + WHAT + METRIC. 3 examples." "LUCIDIA|COVER STORY|The narrative arc: where you were → where you are → why this role is the obvious next step." "CIPHER|RED FLAGS TO AVOID|What screams junior, unfocused, or a bad fit for this role in a resume."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} coaching someone applying for: \"${ROLE}\"
Section: ${section}
${lens}
Be specific and direct. Real examples, not platitudes.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$RESUME_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $RESUME_FILE\033[0m"
  exit 0
fi

# ── THREAD — write a Twitter/X thread on a topic ─────────────────────
if [[ "$1" == "thread" ]]; then
  shift
  TOPIC="$*"
  [[ -z "$TOPIC" ]] && echo "Usage: br carpool thread <topic>" && exit 1
  echo ""
  echo -e "\033[1;36m🧵 THREAD WRITER: $TOPIC\033[0m"
  echo ""
  THREAD_FILE="$HOME/.blackroad/carpool/threads/$(echo "$TOPIC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/threads"
  printf "# Thread: %s\nDate: %s\n\n" "$TOPIC" "$(date '+%Y-%m-%d')" > "$THREAD_FILE"
  for entry in "ARIA|VIRAL HOOK|Write tweet 1. The hook. Must stop the scroll. Bold claim or counterintuitive statement." "LUCIDIA|DEEP DIVE|Tweets 2-5. The substance. Each tweet one idea, max 280 chars, numbered." "PRISM|DATA & PROOF|Tweets 6-8. Specific stats, examples, or case studies that back the claim." "ALICE|ACTIONABLE TAKEAWAY|Tweet 9. The thing people actually do after reading this." "SHELLFISH|CTA|Tweet 10. The closer. Retweet bait + follow hook. Punchy."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} writing part of a Twitter/X thread about: \"${TOPIC}\"
Section: ${section}
${lens}
Each tweet must be under 280 characters. Number them continuing the thread.
No hashtag spam. Write for a technical founder audience.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n### %s\n%s\n" "$section" "$resp" >> "$THREAD_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $THREAD_FILE\033[0m"
  exit 0
fi

# ── ESTIMATE — agents give time/complexity estimates with reasoning ────
if [[ "$1" == "estimate" || "$1" == "est" ]]; then
  shift
  TASK="$*"
  [[ -z "$TASK" ]] && echo "Usage: br carpool estimate <task or feature>" && exit 1
  echo ""
  echo -e "\033[1;33m⏱️  ESTIMATION: $TASK\033[0m"
  echo ""
  estimates=""
  for entry in "ALICE|OPTIMISTIC|You have done this before, everything goes smoothly, no surprises." "OCTAVIA|REALISTIC|Normal pace, one or two unknowns, typical team friction." "SHELLFISH|PESSIMISTIC|Murphy strikes. Edge cases, reviews, tests, rework, context switching." "PRISM|COMPLEXITY SCORE|Rate complexity 1-10 and explain the top 3 unknowns that drive the estimate."; do
    IFS='|' read -r ag mode lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${mode}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} estimating: \"${TASK}\"
Mode: ${mode} — ${lens}
ESTIMATE: <number> <hours|days|weeks>
BREAKDOWN:
- <subtask>: <time>
- <subtask>: <time>
ASSUMPTION: <key assumption baked into this estimate>
No preamble.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    est_line=$(echo "$resp" | grep "^ESTIMATE:" | head -1 | sed 's/ESTIMATE: *//')
    [[ -n "$est_line" ]] && estimates="${estimates}\n  ${ag} (${mode}): $est_line"
    echo ""
  done
  echo -e "\033[1;33m──────────────────────────────────────────\033[0m"
  echo -e "\033[1;33m📊 ESTIMATE SUMMARY\033[0m"
  printf "%b\n" "$estimates"
  echo ""
  echo -e "\033[0;36mRule of thumb: ship the REALISTIC estimate, plan for PESSIMISTIC\033[0m"
  exit 0
fi

# ── PRESSRELEASE — Amazon working-backwards press release ─────────────
if [[ "$1" == "pressrelease" || "$1" == "pr-faq" || "$1" == "prfaq" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool pressrelease <feature or product>" && exit 1
  echo ""
  echo -e "\033[1;32m📰 PRESS RELEASE (Working Backwards): $FEATURE\033[0m"
  echo ""
  PR_FILE="$HOME/.blackroad/carpool/pressreleases/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/pressreleases"
  printf "# Press Release: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$PR_FILE"
  for entry in "ARIA|HEADLINE & LEDE|Headline (under 10 words). Subheadline. Opening paragraph from a happy customer quote." "LUCIDIA|THE PROBLEM|One paragraph: the world before this existed. Paint the pain vividly." "ALICE|THE SOLUTION|One paragraph: what it does, how it works, why it is different from everything else." "PRISM|KEY METRICS & PROOF|3 specific numbers that prove this matters. Can be aspirational but grounded." "CIPHER|FAQ — HARD QUESTIONS|Top 5 questions a skeptic would ask. Answer each honestly, including weaknesses."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} writing an Amazon-style working-backwards press release for: \"${FEATURE}\"
Section: ${section}
${lens}
Write as if this has already shipped and is being announced to the world.
Be specific, vivid, and confident.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$PR_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $PR_FILE\033[0m"
  exit 0
fi

# ── VALUES — extract team values from session history + memory ─────────
if [[ "$1" == "values" ]]; then
  echo ""
  echo -e "\033[1;35m💜 TEAM VALUES EXTRACTION\033[0m"
  echo ""
  HIST=""
  [[ -f "$HOME/.blackroad/carpool/memory.txt" ]] && HIST=$(cat "$HOME/.blackroad/carpool/memory.txt" | tail -60)
  THEME=""
  [[ -f "$HOME/.blackroad/carpool/theme.txt" ]] && THEME=$(cat "$HOME/.blackroad/carpool/theme.txt")
  VALUES_FILE="$HOME/.blackroad/carpool/values.md"
  for entry in "LUCIDIA|OBSERVED VALUES|From everything we have built and discussed, what values are actually operating here? Not what we say — what we do." "ARIA|HOW WE COMMUNICATE|Our voice, tone, and style. What makes BlackRoad sound like us?" "ALICE|HOW WE WORK|The operating principles visible in our decisions. How we ship, decide, and prioritize." "PRISM|WHAT WE OPTIMIZE FOR|Based on the work, what do we actually care about most? What metrics guide us?" "SHELLFISH|WHAT WE REJECT|The things we consistently say no to. Our anti-values. What is not BlackRoad?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json, sys
hist, theme = sys.argv[1], sys.argv[2]
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} on the BlackRoad team reflecting on our work.
{\"Theme: \" + theme if theme else \"\"}
{\"Session history: \" + hist[:800] if hist else \"\"}
Section: ${section}
${lens}
Give 4-5 specific values or principles as short punchy statements.
Format: **<value name>** — <one-line description>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" "$HIST" "$THEME" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$VALUES_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $VALUES_FILE\033[0m"
  exit 0
fi

# ── DEMO — script a live demo walkthrough for a feature ───────────────
if [[ "$1" == "demo" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool demo <feature or product>" && exit 1
  echo ""
  echo -e "\033[1;36m🎬 DEMO SCRIPT: $FEATURE\033[0m"
  echo ""
  DEMO_FILE="$HOME/.blackroad/carpool/demos/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/demos"
  printf "# Demo Script: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$DEMO_FILE"
  for entry in "ARIA|OPENING HOOK|The first 30 seconds. Set the scene, name the pain, promise the wow moment." "ALICE|HAPPY PATH|Step-by-step the demo flow. Each step: what you click, what you say, what they see." "PRISM|THE WOW MOMENT|The single screenshot or interaction that makes the audience lean forward." "SHELLFISH|WHAT CAN GO WRONG|Every demo gremlins — wifi, data, error states. The backup plan for each." "LUCIDIA|CLOSING STATEMENT|The last thing you say. What you want them to remember tomorrow."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} scripting a live product demo for: \"${FEATURE}\"
Section: ${section}
${lens}
Be specific — real UI elements, real words to say, real things to show.
Format each step/point as a numbered item or bullet.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$DEMO_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $DEMO_FILE\033[0m"
  exit 0
fi

# ── GLOSSARY — build a shared domain vocabulary ───────────────────────
if [[ "$1" == "glossary" ]]; then
  shift
  DOMAIN="$*"
  [[ -z "$DOMAIN" ]] && echo "Usage: br carpool glossary <domain>" && exit 1
  echo ""
  echo -e "\033[1;33m📖 GLOSSARY: $DOMAIN\033[0m"
  echo ""
  GLOSS_FILE="$HOME/.blackroad/carpool/glossaries/$(echo "$DOMAIN" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40).md"
  mkdir -p "$HOME/.blackroad/carpool/glossaries"
  printf "# Glossary: %s\nDate: %s\n\n" "$DOMAIN" "$(date '+%Y-%m-%d')" > "$GLOSS_FILE"
  for entry in "OCTAVIA|TECHNICAL TERMS|The core engineering/architecture vocabulary. Things new engineers must learn." "ALICE|OPERATIONAL TERMS|Process, workflow, and tooling terms the team uses day-to-day." "PRISM|METRICS & DATA TERMS|KPIs, measurement terms, and data concepts specific to this domain." "ARIA|PRODUCT & USER TERMS|What we call things in the UI, docs, and user-facing comms." "LUCIDIA|CONCEPTS & METAPHORS|The mental models and analogies that help explain this domain to anyone."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} building a glossary for the domain: \"${DOMAIN}\"
Section: ${section}
${lens}
Give 6-8 terms. Format each:
**<term>** — <clear one-sentence definition>
No preamble.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$GLOSS_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $GLOSS_FILE\033[0m"
  exit 0
fi

# ── NORTH-STAR — identify the north star metric for a product ─────────
if [[ "$1" == "north-star" || "$1" == "northstar" ]]; then
  shift
  PRODUCT="$*"
  PRODUCT="${PRODUCT:-this product}"
  echo ""
  echo -e "\033[1;35m⭐ NORTH STAR METRIC: $PRODUCT\033[0m"
  echo ""
  candidates=""
  for entry in "PRISM|CANDIDATE METRICS|Name 3 metrics that could be the north star. Explain what each captures." "ALICE|LEADING INDICATORS|What early signals predict the north star before you can measure it?" "OCTAVIA|HOW TO INSTRUMENT|What needs to be built to track this accurately? Events, pipelines, dashboards." "LUCIDIA|THE REAL QUESTION|What single number, if it doubled, would mean the product truly succeeded?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} defining the north star metric for: \"${PRODUCT}\"
Section: ${section}
${lens}
Be specific — real metric names, real formulas where applicable.
3-4 focused points.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    echo ""
  done
  # Final PRISM verdict
  IFS='|' read -r _ col _ emoji <<< "$(agent_meta "PRISM")"
  echo -e "${col}${emoji} PRISM — FINAL RECOMMENDATION${NC}"
  python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are PRISM. Pick ONE north star metric for \"${PRODUCT}\".
NORTH STAR: <metric name>
FORMULA: <how to calculate it>
FREQUENCY: <how often to review>
WHY: <one paragraph why this is the right one>
TRAP: <the metric that looks right but misleads>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[PRISM offline]"
  echo ""
  exit 0
fi

# ── FAQ — generate FAQ for a product, feature, or topic ──────────────
if [[ "$1" == "faq" ]]; then
  shift
  TOPIC="$*"
  [[ -z "$TOPIC" ]] && echo "Usage: br carpool faq <product, feature, or topic>" && exit 1
  echo ""
  echo -e "\033[1;32m❓ FAQ GENERATOR: $TOPIC\033[0m"
  echo ""
  FAQ_FILE="$HOME/.blackroad/carpool/faqs/$(echo "$TOPIC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/faqs"
  printf "# FAQ: %s\nDate: %s\n\n" "$TOPIC" "$(date '+%Y-%m-%d')" > "$FAQ_FILE"
  for entry in "ARIA|NEW USER QUESTIONS|What do first-time users always ask? Confusion, onboarding, first impressions." "ALICE|HOW-TO QUESTIONS|The practical how-do-I questions from people actively using it." "CIPHER|SECURITY & TRUST QUESTIONS|Data privacy, auth, compliance, what happens if something goes wrong." "PRISM|COMPARISON QUESTIONS|How does this compare to X? Why not just use Y? When should I not use this?" "SHELLFISH|HARD & AWKWARD QUESTIONS|Questions people think but rarely ask. Honest, uncomfortable, important."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} writing FAQ entries for: \"${TOPIC}\"
Category: ${section}
${lens}
Write 4 Q&A pairs. Format:
**Q: <question>**
A: <direct, honest answer in 1-3 sentences>

No filler. Answer as if writing for smart, impatient people.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$FAQ_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $FAQ_FILE\033[0m"
  exit 0
fi

# ── CHECKLIST — pre-launch / pre-deploy checklist ─────────────────────
if [[ "$1" == "checklist" ]]; then
  shift
  CONTEXT="$*"
  CONTEXT="${CONTEXT:-production deploy}"
  echo ""
  echo -e "\033[1;33m✅ CHECKLIST: $CONTEXT\033[0m"
  echo ""
  CHECK_FILE="$HOME/.blackroad/carpool/checklists/$(echo "$CONTEXT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/checklists"
  printf "# Checklist: %s\nDate: %s\n\n" "$CONTEXT" "$(date '+%Y-%m-%d')" > "$CHECK_FILE"
  for entry in "CIPHER|SECURITY|Auth tested, secrets rotated, deps scanned, no exposed endpoints." "OCTAVIA|INFRASTRUCTURE|Health checks passing, rollback tested, alerts configured, capacity checked." "ALICE|OPERATIONS|Runbook updated, on-call notified, monitoring dashboard ready, comms drafted." "PRISM|QUALITY|Tests green, coverage acceptable, performance benchmarks within SLA." "ARIA|COMMUNICATIONS|Changelog ready, docs updated, stakeholders notified, support briefed."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Generate a pre-launch checklist for: \"${CONTEXT}\"
Category: ${section}
Focus: ${lens}
Give 6-8 specific checklist items.
Format: - [ ] <item> — <why it matters>
Be concrete. Not generic.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$CHECK_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $CHECK_FILE\033[0m"
  exit 0
fi

# ── COMPETITOR — competitive analysis for a product or feature ─────────
if [[ "$1" == "competitor" || "$1" == "compete" ]]; then
  shift
  COMPETITOR="$*"
  [[ -z "$COMPETITOR" ]] && echo "Usage: br carpool competitor <competitor or product>" && exit 1
  echo ""
  echo -e "\033[1;31m⚔️  COMPETITIVE ANALYSIS: $COMPETITOR\033[0m"
  echo ""
  COMP_FILE="$HOME/.blackroad/carpool/competitors/$(echo "$COMPETITOR" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/competitors"
  printf "# Competitive Analysis: %s\nDate: %s\n\n" "$COMPETITOR" "$(date '+%Y-%m-%d')" > "$COMP_FILE"
  for entry in "PRISM|WHAT THEY DO WELL|Their actual strengths. Be honest — knowing this protects you." "SHELLFISH|THEIR WEAKNESSES|Real gaps, complaints from users, things they consistently fail at." "ALICE|WHERE WE WIN|The specific situations where our approach beats theirs. Be precise." "CIPHER|THEIR MOAT|What makes them hard to displace? Lock-in, network effects, data, brand." "LUCIDIA|OUR DIFFERENTIATOR|The one thing we do that they cannot easily copy. Our unfair advantage."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} analyzing competitor: \"${COMPETITOR}\" in the context of BlackRoad OS (AI agent orchestration platform).
Section: ${section}
${lens}
Give 4-5 specific, insightful points. No generic SWOT filler.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$COMP_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $COMP_FILE\033[0m"
  exit 0
fi

# ── MEETING — agenda + talking points + expected outcomes ─────────────
if [[ "$1" == "meeting" ]]; then
  shift
  PURPOSE="$*"
  [[ -z "$PURPOSE" ]] && echo "Usage: br carpool meeting <meeting purpose>" && exit 1
  echo ""
  echo -e "\033[1;36m📅 MEETING PREP: $PURPOSE\033[0m"
  echo ""
  MTG_FILE="$HOME/.blackroad/carpool/meetings/$(echo "$PURPOSE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/meetings"
  printf "# Meeting: %s\nDate: %s\n\n" "$PURPOSE" "$(date '+%Y-%m-%d')" > "$MTG_FILE"
  for entry in "ALICE|AGENDA|5-7 agenda items with time boxes. Total under 60 min. No item without an owner." "LUCIDIA|FRAMING|The one sentence that explains why this meeting matters right now." "PRISM|PRE-READ|What must attendees know before walking in? Max 3 bullets." "ARIA|TALKING POINTS|For each agenda item: the key thing to say and the question to ask." "OCTAVIA|DECISIONS NEEDED|The specific decisions that must come out of this meeting. If none, cancel it."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} preparing for a meeting about: \"${PURPOSE}\"
Section: ${section}
${lens}
Be specific and efficient. Time is the most expensive resource in this meeting.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$MTG_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $MTG_FILE\033[0m"
  exit 0
fi

# ── SUPPORT — draft support response + escalation decision ────────────
if [[ "$1" == "support" ]]; then
  shift
  ISSUE="$*"
  [[ -z "$ISSUE" ]] && echo "Usage: br carpool support <user issue or ticket>" && exit 1
  echo ""
  echo -e "\033[1;32m🎧 SUPPORT RESPONSE: $ISSUE\033[0m"
  echo ""
  for entry in "ARIA|EMPATHETIC RESPONSE|Draft the human-first reply. Acknowledge, validate, then help." "ALICE|TECHNICAL RESOLUTION|The exact steps to resolve this. What the user needs to do." "OCTAVIA|ROOT CAUSE|What system/code/config likely caused this? Internal diagnosis." "CIPHER|SECURITY CHECK|Is this a security issue in disguise? Data exposure, auth bypass, abuse vector?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} handling a support issue: \"${ISSUE}\"
Section: ${section}
${lens}
Be direct and helpful. Real words, not corporate speak.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  # Escalation verdict
  IFS='|' read -r _ col _ emoji <<< "$(agent_meta "SHELLFISH")"
  echo -e "${col}${emoji} SHELLFISH — ESCALATION VERDICT${NC}"
  python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''User issue: \"${ISSUE}\"
Should this be escalated? Answer:
ESCALATE: YES / NO / MONITOR
SEVERITY: P1 / P2 / P3
REASON: <one sentence>
NEXT OWNER: <who handles this next>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[SHELLFISH offline]"
  echo ""
  exit 0
fi

# ── EXPERIMENT — design an A/B test or product experiment ────────────
if [[ "$1" == "experiment" || "$1" == "abtest" ]]; then
  shift
  IDEA="$*"
  [[ -z "$IDEA" ]] && echo "Usage: br carpool experiment <hypothesis or change to test>" && exit 1
  echo ""
  echo -e "\033[1;35m🧪 EXPERIMENT DESIGN: $IDEA\033[0m"
  echo ""
  EXP_FILE="$HOME/.blackroad/carpool/experiments/$(echo "$IDEA" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/experiments"
  printf "# Experiment: %s\nDate: %s\n\n" "$IDEA" "$(date '+%Y-%m-%d')" > "$EXP_FILE"
  for entry in "PRISM|HYPOTHESIS|If we do X, then Y will happen, because Z. One crisp statement." "ALICE|CONTROL & VARIANT|Exactly what changes between A and B. What stays the same. Who sees what." "OCTAVIA|INSTRUMENTATION|The events to track, the queries to run, the dashboard to build." "CIPHER|VALIDITY THREATS|What could make the result misleading? Novelty effect, selection bias, SRM." "LUCIDIA|DECISION RULE|Before we start: what result means we ship it? What means we kill it?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing an experiment for: \"${IDEA}\"
Section: ${section}
${lens}
Be specific. Real metric names, real event names, real thresholds.
3-5 focused points.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$EXP_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $EXP_FILE\033[0m"
  exit 0
fi

# ── LAUNCH — full product launch plan ────────────────────────────────
if [[ "$1" == "launch" ]]; then
  shift
  PRODUCT="$*"
  [[ -z "$PRODUCT" ]] && echo "Usage: br carpool launch <product or feature>" && exit 1
  echo ""
  echo -e "\033[1;32m🚀 LAUNCH PLAN: $PRODUCT\033[0m"
  echo ""
  LAUNCH_FILE="$HOME/.blackroad/carpool/launches/$(echo "$PRODUCT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/launches"
  printf "# Launch Plan: %s\nDate: %s\n\n" "$PRODUCT" "$(date '+%Y-%m-%d')" > "$LAUNCH_FILE"
  for entry in "ARIA|CHANNELS & MESSAGING|Where we announce, what we say, in what order. Twitter/X, HN, PH, email, Discord." "ALICE|T-MINUS CHECKLIST|72h before, 24h before, 1h before, go-live, 24h after. What happens at each step." "PRISM|SUCCESS METRICS|How we know the launch worked. Numbers to hit in 24h, 7d, 30d." "SHELLFISH|LAUNCH RISKS|What kills momentum day one. Outage, bad review, competitor timing, HN comment." "LUCIDIA|THE NARRATIVE|The story arc of this launch. Why now, why us, why this matters to the world."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} planning the launch of: \"${PRODUCT}\"
Section: ${section}
${lens}
Be specific and tactical. Real channel names, real timelines, real numbers.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$LAUNCH_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $LAUNCH_FILE\033[0m"
  exit 0
fi

# ── ABSTRACT — explain a concept at 3 levels of depth ─────────────────
if [[ "$1" == "abstract" || "$1" == "explain3" ]]; then
  shift
  CONCEPT="$*"
  [[ -z "$CONCEPT" ]] && echo "Usage: br carpool abstract <concept>" && exit 1
  echo ""
  echo -e "\033[1;36m🎓 3-LEVEL EXPLANATION: $CONCEPT\033[0m"
  echo ""
  for entry in "ARIA|ELI5 (5-year-old)|Simple analogy, no jargon. If a curious kid asked, what would you say?" "ALICE|PRACTITIONER|How a working engineer understands and uses this. The mental model that matters." "LUCIDIA|DEEP THEORY|First principles. Why does this exist? What insight does it encode? Where does it break down?"; do
    IFS='|' read -r ag level lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${level}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Explain: \"${CONCEPT}\"
Level: ${level}
${lens}
3-5 sentences. Perfect for this audience. No hedging.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  # Bonus: OCTAVIA gives the code version
  IFS='|' read -r _ col _ emoji <<< "$(agent_meta "OCTAVIA")"
  echo -e "${col}${emoji} OCTAVIA — IN CODE${NC}"
  python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''Show \"${CONCEPT}\" as a minimal code example.
Language: pseudocode or the most natural language for this concept.
Max 15 lines. Add a 1-line comment explaining the key insight.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[OCTAVIA offline]"
  echo ""
  exit 0
fi

# ── DEBRIEF — structured debrief after shipping or finishing ──────────
if [[ "$1" == "debrief" ]]; then
  shift
  THING="$*"
  THING="${THING:-this project}"
  echo ""
  echo -e "\033[1;33m🔍 DEBRIEF: $THING\033[0m"
  echo ""
  HIST=""
  [[ -f "$HOME/.blackroad/carpool/memory.txt" ]] && HIST=$(tail -30 "$HOME/.blackroad/carpool/memory.txt")
  DB_FILE="$HOME/.blackroad/carpool/debriefs/$(echo "$THING" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/debriefs"
  printf "# Debrief: %s\nDate: %s\n\n" "$THING" "$(date '+%Y-%m-%d')" > "$DB_FILE"
  for entry in "PRISM|BY THE NUMBERS|What metrics moved? What did we actually ship vs plan? No narrative, just facts." "LUCIDIA|WHAT WE LEARNED|The insights that will change how we work next time. Not obvious lessons." "ALICE|WHAT WE WOULD DO DIFFERENTLY|Concrete process changes, not vague platitudes. If we started today, what changes?" "OCTAVIA|TECHNICAL RETROSPECTIVE|Architecture decisions that aged well. Ones that did not. What we owe the codebase." "ARIA|TEAM MOMENTS|What energized the team? What drained us? The human side of the work."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json, sys
hist = sys.argv[1]
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} running a debrief for: \"${THING}\"
{\"Context: \" + hist[:600] if hist else \"\"}
Section: ${section}
${lens}
Be honest and specific. 3-4 points.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" "$HIST" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$DB_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $DB_FILE\033[0m"
  exit 0
fi

# ── WAITLIST — craft waitlist page copy + growth hook ────────────────
if [[ "$1" == "waitlist" ]]; then
  shift
  PRODUCT="$*"
  [[ -z "$PRODUCT" ]] && echo "Usage: br carpool waitlist <product>" && exit 1
  echo ""
  echo -e "\033[1;35m📋 WAITLIST STRATEGY: $PRODUCT\033[0m"
  echo ""
  WL_FILE="$HOME/.blackroad/carpool/waitlists/$(echo "$PRODUCT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/waitlists"
  printf "# Waitlist: %s\nDate: %s\n\n" "$PRODUCT" "$(date '+%Y-%m-%d')" > "$WL_FILE"
  for entry in "ARIA|HERO COPY|Headline (≤8 words), subheadline (≤20 words), CTA button text. No buzzwords. Make it feel exclusive." "LUCIDIA|THE PROMISE|What is the one thing this product does that nothing else does? The reason to care enough to wait." "PRISM|REFERRAL HOOK|A viral loop mechanic. How waitlist members move up by inviting others. Specific reward tiers." "ALICE|CONFIRMATION FLOW|The exact email sequence after signup: immediate, 3-day, 1-week, launch-day. Subject lines included." "SHELLFISH|SCARCITY SIGNALS|What creates urgency without being fake. Real limits, real milestones, real stakes."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} working on a waitlist for: \"${PRODUCT}\"
Section: ${section}
${lens}
Be specific and copy-ready. Real words, real mechanics.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$WL_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $WL_FILE\033[0m"
  exit 0
fi

# ── INCIDENT — live incident response runbook + comms ─────────────────
if [[ "$1" == "incident" || "$1" == "outage" ]]; then
  shift
  SERVICE="$*"
  SERVICE="${SERVICE:-production}"
  echo ""
  echo -e "\033[1;31m🚨 INCIDENT RESPONSE: $SERVICE\033[0m"
  echo ""
  INC_FILE="$HOME/.blackroad/carpool/incidents/$(echo "$SERVICE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d-%H%M).md"
  mkdir -p "$HOME/.blackroad/carpool/incidents"
  printf "# Incident: %s\nStarted: %s\n\n" "$SERVICE" "$(date '+%Y-%m-%d %H:%M')" > "$INC_FILE"
  for entry in "OCTAVIA|TRIAGE STEPS|First 5 things to check right now. Commands to run. What good vs bad output looks like." "CIPHER|BLAST RADIUS|What is affected? What is NOT affected? What data is at risk? Answer confidently even with partial info." "ALICE|RUNBOOK|Step-by-step remediation. Each step is one action. Include rollback point." "ARIA|COMMS TEMPLATES|Status page update (≤50 words). Customer email (≤100 words). Internal Slack (≤30 words). Ready to copy-paste." "PRISM|POST-INCIDENT METRICS|What to capture while it is happening: start time, scope, detection lag, MTTR. Incident scorecard."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} responding to an incident with: \"${SERVICE}\"
Section: ${section}
${lens}
Be direct and actionable. This is live. No fluff.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$INC_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Runbook saved to $INC_FILE\033[0m"
  exit 0
fi

# ── BENCHMARK — define performance benchmarks + load test plan ────────
if [[ "$1" == "benchmark" || "$1" == "perf" ]]; then
  shift
  SYSTEM="$*"
  [[ -z "$SYSTEM" ]] && echo "Usage: br carpool benchmark <system or endpoint>" && exit 1
  echo ""
  echo -e "\033[1;36m⚡ BENCHMARK PLAN: $SYSTEM\033[0m"
  echo ""
  BM_FILE="$HOME/.blackroad/carpool/benchmarks/$(echo "$SYSTEM" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/benchmarks"
  printf "# Benchmark: %s\nDate: %s\n\n" "$SYSTEM" "$(date '+%Y-%m-%d')" > "$BM_FILE"
  for entry in "PRISM|SUCCESS THRESHOLDS|p50, p95, p99 latency targets. Throughput (RPS). Error rate ceiling. These are PASS/FAIL lines." "OCTAVIA|TEST SCENARIOS|Steady state, ramp-up, spike, soak. Duration and load shape for each. Tools to use (k6/wrk/hey)." "CIPHER|FAILURE MODES|What breaks first? Connection pool? DB? Memory? CPU? The thing to watch as load climbs." "ALICE|BASELINE COMMANDS|The exact commands to establish baseline and run each test scenario. Copy-paste ready." "SHELLFISH|STRESS TEST|Push it past the limit deliberately. Find the breaking point. What is the graceful degradation story?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing benchmarks for: \"${SYSTEM}\"
Section: ${section}
${lens}
Real numbers, real commands, real tools. No vague goals.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$BM_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $BM_FILE\033[0m"
  exit 0
fi

# ── PRICING — debate pricing strategy + tier structure ────────────────
if [[ "$1" == "pricing" ]]; then
  shift
  PRODUCT="$*"
  [[ -z "$PRODUCT" ]] && echo "Usage: br carpool pricing <product>" && exit 1
  echo ""
  echo -e "\033[1;33m💰 PRICING STRATEGY: $PRODUCT\033[0m"
  echo ""
  PR_FILE="$HOME/.blackroad/carpool/pricing/$(echo "$PRODUCT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/pricing"
  printf "# Pricing: %s\nDate: %s\n\n" "$PRODUCT" "$(date '+%Y-%m-%d')" > "$PR_FILE"
  for entry in "LUCIDIA|PRICING PHILOSOPHY|Value-based, usage-based, or seat-based? Why? What does the pricing model say about the product?" "ARIA|TIER NAMES & COPY|3 tiers: names, 1-line descriptions, who each is for. The words matter as much as the numbers." "PRISM|THE NUMBERS|Specific price points with reasoning. What competitors charge. Where to anchor, where to land." "ALICE|WHAT IS IN EACH TIER|Feature matrix: what is free, what is paid, what is enterprise-only. The upgrade trigger." "SHELLFISH|ANTI-PATTERNS TO AVOID|The pricing mistakes that kill conversion: too many tiers, hidden limits, confusing units, annual-only."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing pricing for: \"${PRODUCT}\"
Section: ${section}
${lens}
Specific and opinionated. Real numbers where possible.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$PR_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $PR_FILE\033[0m"
  exit 0
fi

# ── SPRINT — plan a sprint with stories, capacity, and goals ─────────
if [[ "$1" == "sprint" ]]; then
  shift
  GOAL="$*"
  [[ -z "$GOAL" ]] && echo "Usage: br carpool sprint <sprint goal>" && exit 1
  echo ""
  echo -e "\033[1;36m🏃 SPRINT PLAN: $GOAL\033[0m"
  echo ""
  SP_FILE="$HOME/.blackroad/carpool/sprints/$(echo "$GOAL" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/sprints"
  printf "# Sprint: %s\nDate: %s\n\n" "$GOAL" "$(date '+%Y-%m-%d')" > "$SP_FILE"
  for entry in "ALICE|SPRINT GOAL & COMMITMENT|One crisp sprint goal sentence. What done looks like at the end of the sprint. The commitment the team makes." "PRISM|STORY BREAKDOWN|5-7 user stories scoped for one sprint. Each with a t-shirt size (S/M/L) and acceptance criteria." "OCTAVIA|TECHNICAL TASKS|The engineering tasks behind those stories. Subtasks, spikes, and tech debt items to include." "CIPHER|RISKS & BLOCKERS|What could derail this sprint? Dependencies, unknowns, scope creep. Mitigation per risk." "LUCIDIA|DEFINITION OF DONE|The team-wide quality bar. What must be true for ANY story to be marked done."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} planning a sprint for: \"${GOAL}\"
Section: ${section}
${lens}
Be concrete and actionable. Real story titles, real task names.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$SP_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $SP_FILE\033[0m"
  exit 0
fi

# ── OKR — generate OKRs with key results and initiatives ─────────────
if [[ "$1" == "okr" ]]; then
  shift
  TEAM="$*"
  [[ -z "$TEAM" ]] && echo "Usage: br carpool okr <team or product>" && exit 1
  echo ""
  echo -e "\033[1;33m🎯 OKR WORKSHOP: $TEAM\033[0m"
  echo ""
  OKR_FILE="$HOME/.blackroad/carpool/okrs/$(echo "$TEAM" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/okrs"
  printf "# OKRs: %s\nDate: %s\n\n" "$TEAM" "$(date '+%Y-%m-%d')" > "$OKR_FILE"
  # Each agent proposes one O with 3 KRs
  for ag in LUCIDIA PRISM ARIA ALICE; do
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — PROPOSED OBJECTIVE${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} proposing OKRs for: \"${TEAM}\"
Write ONE Objective and exactly 3 Key Results.

Rules:
- Objective: inspiring, qualitative, ≤12 words
- Each KR: measurable, has a number, has a deadline
- KRs should be outcomes not outputs

Format:
O: <objective>
KR1: <measurable result>
KR2: <measurable result>
KR3: <measurable result>

Be ambitious but realistic. Real metrics, real targets.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n### %s\n%s\n" "$ag" "$resp" >> "$OKR_FILE"
    echo ""
  done
  # OCTAVIA picks the strongest and explains why
  IFS='|' read -r _ col _ emoji <<< "$(agent_meta "OCTAVIA")"
  echo -e "${col}${emoji} OCTAVIA — FINAL PICK & WHY${NC}"
  python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are OCTAVIA reviewing OKR proposals for: \"${TEAM}\"
Which single objective is most likely to drive real progress this quarter?
Which KR is hardest to game?
What initiative (project or experiment) should start this week to move toward it?
Be decisive. One answer each. No hedging.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[OCTAVIA offline]"
  echo ""
  echo -e "\033[0;32m✓ Saved to $OKR_FILE\033[0m"
  exit 0
fi

# ── HIRING — job description, interview questions, eval rubric ────────
if [[ "$1" == "hiring" || "$1" == "hire" ]]; then
  shift
  ROLE="$*"
  [[ -z "$ROLE" ]] && echo "Usage: br carpool hiring <role>" && exit 1
  echo ""
  echo -e "\033[1;35m👥 HIRING PLAN: $ROLE\033[0m"
  echo ""
  H_FILE="$HOME/.blackroad/carpool/hiring/$(echo "$ROLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/hiring"
  printf "# Hiring: %s\nDate: %s\n\n" "$ROLE" "$(date '+%Y-%m-%d')" > "$H_FILE"
  for entry in "ARIA|JOB DESCRIPTION|The 3 things this person will own, the 2 must-have skills, the 1 thing that makes this role special. Max 200 words." "LUCIDIA|INTERVIEW QUESTIONS|5 questions that reveal thinking, not trivia. Include one values question, one ambiguity question, one failure question." "PRISM|EVAL RUBRIC|A scoring matrix: what does WEAK / GOOD / EXCEPTIONAL look like for the top 4 skills needed?" "ALICE|HIRING PROCESS|Stages, who interviews at each stage, what each stage is testing. Max 5 stages." "SHELLFISH|RED FLAGS|The 5 interview signals that mean pass immediately. Behaviors, not demographics."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} helping hire a: \"${ROLE}\"
Section: ${section}
${lens}
Be specific. Real questions, real rubric items, real process steps.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$H_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $H_FILE\033[0m"
  exit 0
fi

# ── API-DESIGN — design REST API endpoints with shapes ────────────────
if [[ "$1" == "api-design" || "$1" == "apidesign" ]]; then
  shift
  RESOURCE="$*"
  [[ -z "$RESOURCE" ]] && echo "Usage: br carpool api-design <resource or feature>" && exit 1
  echo ""
  echo -e "\033[1;34m🔌 API DESIGN: $RESOURCE\033[0m"
  echo ""
  AD_FILE="$HOME/.blackroad/carpool/api-designs/$(echo "$RESOURCE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/api-designs"
  printf "# API Design: %s\nDate: %s\n\n" "$RESOURCE" "$(date '+%Y-%m-%d')" > "$AD_FILE"
  for entry in "OCTAVIA|ENDPOINTS|All routes with method, path, and one-line purpose. Noun-based, consistent, RESTful." "ALICE|REQUEST & RESPONSE SHAPES|JSON body for the 2 most important endpoints. Include required fields, types, and example values." "CIPHER|AUTH & PERMISSIONS|How auth works. Which endpoints need which permissions. Rate limits per tier." "PRISM|ERROR RESPONSES|The error codes this API returns, what each means, and what the client should do." "SHELLFISH|WHAT COULD GO WRONG|Top 5 ways to misuse or break this API. How to prevent each."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing an API for: \"${RESOURCE}\"
Section: ${section}
${lens}
Real endpoint paths, real JSON shapes, real HTTP status codes.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$AD_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $AD_FILE\033[0m"
  exit 0
fi

# ── DATAMODEL — design database schema + relationships ───────────────
if [[ "$1" == "datamodel" || "$1" == "schema" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool datamodel <feature or domain>" && exit 1
  echo ""
  echo -e "\033[1;34m🗄️  DATA MODEL: $FEATURE\033[0m"
  echo ""
  DM_FILE="$HOME/.blackroad/carpool/datamodels/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/datamodels"
  printf "# Data Model: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$DM_FILE"
  for entry in "OCTAVIA|ENTITIES & FIELDS|All tables/collections. For each: name, key fields with types, primary key, nullable vs required." "ALICE|RELATIONSHIPS|Foreign keys, join tables, one-to-many vs many-to-many. Diagram in text: Entity A ──< Entity B." "PRISM|INDEXES & QUERY PATTERNS|The 5 most common queries. Which columns to index. Composite index candidates." "CIPHER|SENSITIVE FIELDS|Which fields contain PII, secrets, or regulated data. Encryption at rest, masking in logs, access control." "LUCIDIA|EVOLUTION STRATEGY|How this schema changes as the product grows. Migration path, soft deletes vs hard deletes, versioning approach."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing a data model for: \"${FEATURE}\"
Section: ${section}
${lens}
Use real SQL/NoSQL conventions. Specific field names and types.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$DM_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $DM_FILE\033[0m"
  exit 0
fi

# ── CODEREV — multi-agent code review checklist ───────────────────────
if [[ "$1" == "coderev" || "$1" == "review" ]]; then
  shift
  PR="$*"
  [[ -z "$PR" ]] && echo "Usage: br carpool coderev <PR description or diff summary>" && exit 1
  echo ""
  echo -e "\033[1;36m🔍 CODE REVIEW: $PR\033[0m"
  echo ""
  CR_FILE="$HOME/.blackroad/carpool/codereviews/$(echo "$PR" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/codereviews"
  printf "# Code Review: %s\nDate: %s\n\n" "$PR" "$(date '+%Y-%m-%d')" > "$CR_FILE"
  for entry in "CIPHER|SECURITY REVIEW|SQL injection, XSS, auth bypass, secrets in code, input validation gaps. Specific line-level concerns." "OCTAVIA|PERFORMANCE REVIEW|N+1 queries, missing indexes, unbounded loops, memory leaks, blocking I/O. Concrete suggestions." "SHELLFISH|EDGE CASES|What inputs or states will break this? Null, empty, max, concurrent, unexpected order." "ALICE|MAINTAINABILITY|Is it readable in 6 months? Naming, complexity, test coverage, dead code, magic numbers." "PRISM|VERDICT|APPROVE / REQUEST CHANGES / NEEDS DISCUSSION. The single most important thing to fix before merge."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} reviewing a PR: \"${PR}\"
Section: ${section}
${lens}
Be a tough but fair reviewer. Specific, actionable feedback.
Format: - <finding>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$CR_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $CR_FILE\033[0m"
  exit 0
fi

# ── FLOW — design a user onboarding or product flow ───────────────────
if [[ "$1" == "flow" || "$1" == "userflow" ]]; then
  shift
  FLOW="$*"
  [[ -z "$FLOW" ]] && echo "Usage: br carpool flow <flow name, e.g. 'user onboarding' or 'checkout'>" && exit 1
  echo ""
  echo -e "\033[1;32m🌊 USER FLOW: $FLOW\033[0m"
  echo ""
  FL_FILE="$HOME/.blackroad/carpool/flows/$(echo "$FLOW" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/flows"
  printf "# User Flow: %s\nDate: %s\n\n" "$FLOW" "$(date '+%Y-%m-%d')" > "$FL_FILE"
  for entry in "ARIA|STEP-BY-STEP FLOW|Every screen or step the user touches, in order. Format: Step N → [screen name]: what user sees + what they do." "LUCIDIA|AHA MOMENT|The single moment this flow must deliver. Before the user reaches it they are skeptical. After, they are sold." "ALICE|HAPPY PATH VS EDGE CASES|The ideal path, plus 3 variants (error, slow, returning user). What happens at each branch." "PRISM|DROP-OFF POINTS|Where users abandon this flow today (or will). The top 3 friction points and how to reduce each." "OCTAVIA|TECHNICAL TOUCHPOINTS|APIs called, state changes, emails triggered, analytics events fired — in the order they happen."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing the flow: \"${FLOW}\"
Section: ${section}
${lens}
Be specific. Real screen names, real state names, real event names.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$FL_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $FL_FILE\033[0m"
  exit 0
fi

# ── GROWTH — growth strategy + acquisition channel analysis ──────────
if [[ "$1" == "growth" ]]; then
  shift
  PRODUCT="$*"
  [[ -z "$PRODUCT" ]] && echo "Usage: br carpool growth <product>" && exit 1
  echo ""
  echo -e "\033[1;33m📈 GROWTH STRATEGY: $PRODUCT\033[0m"
  echo ""
  GR_FILE="$HOME/.blackroad/carpool/growth/$(echo "$PRODUCT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/growth"
  printf "# Growth Strategy: %s\nDate: %s\n\n" "$PRODUCT" "$(date '+%Y-%m-%d')" > "$GR_FILE"
  for entry in "PRISM|ACQUISITION CHANNELS|Top 5 channels ranked by expected CAC and volume. Why each fits this product specifically." "ARIA|VIRAL LOOP|The in-product mechanic that makes users bring more users. Must be native to the core value." "ALICE|ACTIVATION METRIC|The one action that predicts retention. How to instrument it. How to shorten time-to-activation." "LUCIDIA|RETENTION ENGINE|Why users come back tomorrow, next week, next month. Habit loop, network effect, or switching cost?" "SHELLFISH|GROWTH ANTI-PATTERNS|The 3 growth tactics that will hurt long-term. Dark patterns, churn-masking, vanity metrics to avoid."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} building a growth strategy for: \"${PRODUCT}\"
Section: ${section}
${lens}
Specific and honest. Real channel names, real mechanics, real numbers where possible.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$GR_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $GR_FILE\033[0m"
  exit 0
fi

# ── OBSERVABILITY — logging, metrics, tracing plan ────────────────────
if [[ "$1" == "observability" || "$1" == "observe" ]]; then
  shift
  SERVICE="$*"
  [[ -z "$SERVICE" ]] && echo "Usage: br carpool observability <service or system>" && exit 1
  echo ""
  echo -e "\033[1;36m🔭 OBSERVABILITY PLAN: $SERVICE\033[0m"
  echo ""
  OB_FILE="$HOME/.blackroad/carpool/observability/$(echo "$SERVICE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/observability"
  printf "# Observability: %s\nDate: %s\n\n" "$SERVICE" "$(date '+%Y-%m-%d')" > "$OB_FILE"
  for entry in "PRISM|METRICS|The 5 golden metrics to track. For each: name, unit, how to compute, alert threshold. USE method where applicable." "OCTAVIA|LOGGING STRATEGY|What to log at DEBUG/INFO/WARN/ERROR. Structured log fields. What never to log (secrets, PII)." "ALICE|TRACING|Which operations to instrument with spans. Trace propagation across services. Sampling strategy." "CIPHER|ALERTING RULES|PagerDuty-style alert conditions. Severity levels. Runbook link per alert. On-call escalation path." "LUCIDIA|DASHBOARDS|The 3 dashboards to build: operations (live), debugging (deep-dive), business (trends). Key panels for each."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing observability for: \"${SERVICE}\"
Section: ${section}
${lens}
Real metric names, real log fields, real tool names (Prometheus/Grafana/Datadog/OTel).
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$OB_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $OB_FILE\033[0m"
  exit 0
fi

# ── ACCESSIBILITY — a11y audit + remediation plan ─────────────────────
if [[ "$1" == "accessibility" || "$1" == "a11y" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool accessibility <feature or component>" && exit 1
  echo ""
  echo -e "\033[1;35m♿ ACCESSIBILITY AUDIT: $FEATURE\033[0m"
  echo ""
  A11_FILE="$HOME/.blackroad/carpool/accessibility/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/accessibility"
  printf "# Accessibility: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$A11_FILE"
  for entry in "ARIA|WCAG CHECKLIST|The WCAG 2.2 criteria most likely to fail for this feature. Level A first, then AA. Real criterion numbers." "ALICE|KEYBOARD NAVIGATION|Full keyboard path through this feature. Focus order, trapped focus, skip links, visible focus indicator." "LUCIDIA|SCREEN READER EXPERIENCE|What VoiceOver/NVDA announces at each step. Missing labels, confusing announcements, live region needs." "OCTAVIA|CODE FIXES|Specific HTML/ARIA attributes to add or change. Before/after code snippets for the top 3 issues." "PRISM|TESTING APPROACH|Tools (axe, Lighthouse, NVDA, VoiceOver) + manual test scenarios + acceptance criteria for each fix."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} auditing accessibility for: \"${FEATURE}\"
Section: ${section}
${lens}
Specific and actionable. Real WCAG criteria, real ARIA attributes, real tool names.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$A11_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $A11_FILE\033[0m"
  exit 0
fi

# ── CAPACITY — capacity planning for a service ────────────────────────
if [[ "$1" == "capacity" ]]; then
  shift
  SERVICE="$*"
  [[ -z "$SERVICE" ]] && echo "Usage: br carpool capacity <service>" && exit 1
  echo ""
  echo -e "\033[1;33m📦 CAPACITY PLAN: $SERVICE\033[0m"
  echo ""
  CAP_FILE="$HOME/.blackroad/carpool/capacity/$(echo "$SERVICE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/capacity"
  printf "# Capacity Plan: %s\nDate: %s\n\n" "$SERVICE" "$(date '+%Y-%m-%d')" > "$CAP_FILE"
  for entry in "PRISM|CURRENT BASELINE|What to measure today: RPS, p99 latency, CPU%, memory%, DB connections. Establish the numbers before projecting." "OCTAVIA|SCALING MODEL|How this service scales. Vertical ceiling, horizontal triggers, stateless vs stateful constraints." "ALICE|GROWTH PROJECTIONS|3x, 10x, 100x traffic: what breaks first and at which multiplier. The honest conversation." "CIPHER|SINGLE POINTS OF FAILURE|Every component that has no redundancy. What a failure looks like. Priority order to fix." "LUCIDIA|ARCHITECTURE CHANGES NEEDED|What must change architecturally to reach 10x without a full rewrite. The minimum viable scaling investments."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} planning capacity for: \"${SERVICE}\"
Section: ${section}
${lens}
Real numbers, real infrastructure terms, real failure modes.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$CAP_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $CAP_FILE\033[0m"
  exit 0
fi

# ── MIGRATION — plan a tech migration ────────────────────────────────
if [[ "$1" == "migration" || "$1" == "migrate" ]]; then
  shift
  PLAN="$*"
  [[ -z "$PLAN" ]] && echo "Usage: br carpool migration <from X to Y, e.g. 'REST to GraphQL'>" && exit 1
  echo ""
  echo -e "\033[1;34m🚚 MIGRATION PLAN: $PLAN\033[0m"
  echo ""
  MIG_FILE="$HOME/.blackroad/carpool/migrations/$(echo "$PLAN" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/migrations"
  printf "# Migration: %s\nDate: %s\n\n" "$PLAN" "$(date '+%Y-%m-%d')" > "$MIG_FILE"
  for entry in "LUCIDIA|WHY & WHEN|The real reason to migrate (not the marketing reason). When is it worth it vs when to stay put." "ALICE|MIGRATION PHASES|Phase 0 (prep) → Phase 1 (parallel run) → Phase 2 (cutover) → Phase 3 (cleanup). Milestones per phase." "OCTAVIA|TECHNICAL STEPS|The concrete engineering work per phase. Scripts to write, configs to change, tests to add." "CIPHER|ROLLBACK PLAN|Exactly how to undo this if it goes wrong. Feature flag? Blue/green? Data migration reversal?" "PRISM|SUCCESS CRITERIA|How we know the migration worked. Before/after metrics. The moment we can delete the old code."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} planning a migration: \"${PLAN}\"
Section: ${section}
${lens}
Honest and specific. Real migration patterns, real tooling, real risks.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$MIG_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $MIG_FILE\033[0m"
  exit 0
fi

# ── TRAFFICLIGHT — GREEN/YELLOW/RED status assessment ─────────────────
if [[ "$1" == "trafficlight" || "$1" == "tl" ]]; then
  shift
  PROJECT="$*"
  PROJECT="${PROJECT:-this project}"
  echo ""
  echo -e "\033[1;33m🚦 TRAFFIC LIGHT ASSESSMENT: $PROJECT\033[0m"
  echo ""
  HIST=""
  [[ -f "$HOME/.blackroad/carpool/memory.txt" ]] && HIST=$(tail -20 "$HOME/.blackroad/carpool/memory.txt")
  TL_FILE="$HOME/.blackroad/carpool/trafficlights/$(echo "$PROJECT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/trafficlights"
  printf "# Traffic Light: %s\nDate: %s\n\n" "$PROJECT" "$(date '+%Y-%m-%d')" > "$TL_FILE"
  for entry in "CIPHER|SECURITY SIGNAL|Rate RED/YELLOW/GREEN. Known vulns, exposed secrets, auth gaps, last security review date." "OCTAVIA|INFRASTRUCTURE SIGNAL|Rate RED/YELLOW/GREEN. Uptime trend, deployment frequency, SPOF exposure, monitoring coverage." "PRISM|QUALITY SIGNAL|Rate RED/YELLOW/GREEN. Test coverage, known bugs, error rate, p99 latency vs target." "ALICE|OPERATIONS SIGNAL|Rate RED/YELLOW/GREEN. On-call load, runbook freshness, incident frequency, toil level." "LUCIDIA|OVERALL VERDICT|🟢 GREEN / 🟡 YELLOW / 🔴 RED with one sentence reason. The honest operator view."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json, sys
hist = sys.argv[1]
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} assessing the traffic light status of: \"${PROJECT}\"
{\"Context: \" + hist[:400] if hist else \"\"}
Section: ${section}
${lens}
Start with the color (🟢/🟡/🔴). Then 2-3 specific reasons.
Format: <color> — <reason 1> | <reason 2> | <reason 3>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" "$HIST" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$TL_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $TL_FILE\033[0m"
  exit 0
fi

# ── DOMAIN-EVENTS — design event sourcing for a feature ───────────────
if [[ "$1" == "domain-events" || "$1" == "events" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool domain-events <feature or aggregate>" && exit 1
  echo ""
  echo -e "\033[1;34m📡 DOMAIN EVENTS: $FEATURE\033[0m"
  echo ""
  DE_FILE="$HOME/.blackroad/carpool/domain-events/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/domain-events"
  printf "# Domain Events: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$DE_FILE"
  for entry in "LUCIDIA|EVENT CATALOG|All domain events for this feature. PascalCase names, past tense. What triggered each, what it means to the business." "OCTAVIA|EVENT PAYLOADS|JSON payload schema for the 3 most important events. Include: id, timestamp, aggregate_id, version, data fields." "ALICE|EVENT FLOW|Sequence of events for the happy path. Which service emits, which services subscribe, in order." "CIPHER|EVENT SECURITY|Which events contain PII or sensitive data. Encryption requirements, access control, audit log needs." "PRISM|PROJECTIONS & READ MODELS|The read models built from these events. What queries they answer. How far behind they can lag."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing domain events for: \"${FEATURE}\"
Section: ${section}
${lens}
Use real event sourcing conventions. Past-tense event names, real JSON field names.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$DE_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $DE_FILE\033[0m"
  exit 0
fi

# ── NEWSLETTER — write a developer newsletter issue ────────────────────
if [[ "$1" == "newsletter" ]]; then
  shift
  TOPIC="$*"
  [[ -z "$TOPIC" ]] && echo "Usage: br carpool newsletter <topic or this week's theme>" && exit 1
  echo ""
  echo -e "\033[1;35m📰 NEWSLETTER: $TOPIC\033[0m"
  echo ""
  NL_FILE="$HOME/.blackroad/carpool/newsletters/$(echo "$TOPIC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/newsletters"
  printf "# Newsletter: %s\nDate: %s\n\n" "$TOPIC" "$(date '+%Y-%m-%d')" > "$NL_FILE"
  for entry in "ARIA|SUBJECT LINE & PREVIEW|3 subject line options (curiosity / benefit / direct) + preview text. Under 50 chars each." "LUCIDIA|OPENING HOOK|First 2-3 sentences. Must make the reader stop scrolling. No 'hope this email finds you well'." "ALICE|MAIN CONTENT|The meat: 3-5 numbered items or a short essay. Scannable. Each item with a bold lead-in." "PRISM|DATA OR INSIGHT|One surprising number, chart description, or insight that readers will forward to a colleague." "OCTAVIA|CLOSING & CTA|Sign-off that sounds human. One clear CTA. What should the reader do right now?"; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} writing a developer newsletter about: \"${TOPIC}\"
Section: ${section}
${lens}
Write actual copy, not instructions. Punchy, human, no corporate speak.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$NL_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $NL_FILE\033[0m"
  exit 0
fi

# ── OPS-RUNBOOK — write an operations runbook ─────────────────────────
if [[ "$1" == "ops-runbook" || "$1" == "runbook" ]]; then
  shift
  SERVICE="$*"
  [[ -z "$SERVICE" ]] && echo "Usage: br carpool ops-runbook <service or procedure>" && exit 1
  echo ""
  echo -e "\033[1;32m📖 OPS RUNBOOK: $SERVICE\033[0m"
  echo ""
  RB_FILE="$HOME/.blackroad/carpool/runbooks/$(echo "$SERVICE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/runbooks"
  printf "# Runbook: %s\nDate: %s\n\n" "$SERVICE" "$(date '+%Y-%m-%d')" > "$RB_FILE"
  for entry in "ALICE|QUICK REFERENCE|Service owner, repo link, deploy command, restart command, log location. One glance, have everything." "OCTAVIA|COMMON PROCEDURES|Deploy, rollback, restart, scale up/down. Exact commands for each. Copy-paste ready." "PRISM|HEALTH CHECKS|Commands to verify the service is healthy. Expected output vs problem output for each check." "CIPHER|SECRETS & ACCESS|Where secrets live, how to rotate them, who has access, emergency access procedure." "SHELLFISH|BREAK-GLASS PROCEDURES|Nuclear options: force restart, drain traffic, kill switch. When to use each, who approves."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} writing an ops runbook for: \"${SERVICE}\"
Section: ${section}
${lens}
Real commands, real paths, real tool names. An on-call engineer at 3am will use this.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$RB_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $RB_FILE\033[0m"
  exit 0
fi

# ── SEED — craft an investor seed round narrative ────────────────────
if [[ "$1" == "seed" || "$1" == "fundraise" ]]; then
  shift
  STARTUP="$*"
  [[ -z "$STARTUP" ]] && echo "Usage: br carpool seed <startup or product>" && exit 1
  echo ""
  echo -e "\033[1;33m💸 SEED ROUND NARRATIVE: $STARTUP\033[0m"
  echo ""
  SD_FILE="$HOME/.blackroad/carpool/fundraising/$(echo "$STARTUP" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/fundraising"
  printf "# Seed Round: %s\nDate: %s\n\n" "$STARTUP" "$(date '+%Y-%m-%d')" > "$SD_FILE"
  for entry in "LUCIDIA|THE STORY|The origin, the insight, the why-now. What the world looks like if this works. 3 paragraphs, no buzzwords." "PRISM|THE MARKET|TAM/SAM/SOM with honest reasoning. Why this market is big AND why incumbents can't own it." "ARIA|THE PITCH DECK FLOW|10-slide structure with one sentence per slide. What each slide must prove to the investor." "OCTAVIA|THE ASK|How much, at what valuation, what it buys in runway. Use-of-funds breakdown by category." "SHELLFISH|INVESTOR OBJECTIONS|The 5 hardest questions a sharp investor will ask. Honest answers, not spin."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} preparing a seed round for: \"${STARTUP}\"
Section: ${section}
${lens}
Be honest and compelling. Real numbers, real reasoning, no startup clichés.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$SD_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $SD_FILE\033[0m"
  exit 0
fi

# ── SECURITY-MODEL — threat model + attack surface for a feature ──────
if [[ "$1" == "security-model" || "$1" == "threatmodel" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool security-model <feature or system>" && exit 1
  echo ""
  echo -e "\033[1;31m🛡️  SECURITY MODEL: $FEATURE\033[0m"
  echo ""
  SM_FILE="$HOME/.blackroad/carpool/security-models/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/security-models"
  printf "# Security Model: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$SM_FILE"
  for entry in "CIPHER|ATTACK SURFACE|Every entry point an attacker could use. Input fields, APIs, file uploads, webhooks, third-party deps." "SHELLFISH|THREAT ACTORS|Who would attack this and why? Script kiddie, insider threat, nation state, competitor. Motivation per actor." "OCTAVIA|TRUST BOUNDARIES|Where data crosses trust zones. Each boundary needs auth, validation, and logging." "ALICE|MITIGATIONS|STRIDE mitigations for the top 5 threats: Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation." "PRISM|RESIDUAL RISK|What risk remains after mitigations. Accept, transfer, or monitor. Priority order to address next sprint."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} building a security model for: \"${FEATURE}\"
Section: ${section}
${lens}
Use real threat modeling terminology (STRIDE, OWASP, CVE categories).
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$SM_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $SM_FILE\033[0m"
  exit 0
fi

# ── CONTENT — content marketing plan + editorial calendar ─────────────
if [[ "$1" == "content" ]]; then
  shift
  TOPIC="$*"
  [[ -z "$TOPIC" ]] && echo "Usage: br carpool content <product or topic>" && exit 1
  echo ""
  echo -e "\033[1;35m✍️  CONTENT PLAN: $TOPIC\033[0m"
  echo ""
  CT_FILE="$HOME/.blackroad/carpool/content/$(echo "$TOPIC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/content"
  printf "# Content Plan: %s\nDate: %s\n\n" "$TOPIC" "$(date '+%Y-%m-%d')" > "$CT_FILE"
  for entry in "ARIA|CONTENT PILLARS|3-4 themes this content always reinforces. What the brand stands for in every post/article/video." "LUCIDIA|FLAGSHIP CONTENT IDEAS|5 long-form pieces worth building an audience on. Each with a hook, angle, and why now." "PRISM|DISTRIBUTION CHANNELS|Where to publish each content type. SEO, Twitter/X, HN, YouTube, LinkedIn — honest reach estimate per channel." "ALICE|30-DAY CALENDAR|Week 1-4 publishing schedule. Content type, platform, topic, and repurpose path for each piece." "SHELLFISH|WHAT MOST BRANDS GET WRONG|The content mistakes to avoid: posting cadence traps, vanity engagement, copying competitors, SEO farming."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} building a content plan for: \"${TOPIC}\"
Section: ${section}
${lens}
Specific titles, specific platforms, specific angles. No generic advice.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$CT_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $CT_FILE\033[0m"
  exit 0
fi

# ── PROTOCOL — design an internal team protocol or process ────────────
if [[ "$1" == "protocol" || "$1" == "process" ]]; then
  shift
  PROC="$*"
  [[ -z "$PROC" ]] && echo "Usage: br carpool protocol <process, e.g. 'on-call handoff' or 'deploy freeze'>" && exit 1
  echo ""
  echo -e "\033[1;36m📋 PROTOCOL: $PROC\033[0m"
  echo ""
  PR_FILE="$HOME/.blackroad/carpool/protocols/$(echo "$PROC" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/protocols"
  printf "# Protocol: %s\nDate: %s\n\n" "$PROC" "$(date '+%Y-%m-%d')" > "$PR_FILE"
  for entry in "ALICE|TRIGGER & SCOPE|When does this protocol activate? Who does it apply to? What is explicitly out of scope?" "OCTAVIA|STEP-BY-STEP|The exact sequence of steps. Owner per step. Input/output for each. No ambiguity." "CIPHER|EXCEPTION HANDLING|What to do when a step fails or conditions are unusual. Who has override authority." "PRISM|METRICS|How do we know this protocol is working? Compliance rate, time-to-complete, error rate." "LUCIDIA|WHY THIS EXISTS|The incident or failure that made this protocol necessary. Keeps it from becoming zombie process."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing a team protocol for: \"${PROC}\"
Section: ${section}
${lens}
Concrete and unambiguous. A new team member can follow this on day one.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$PR_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $PR_FILE\033[0m"
  exit 0
fi

# ── ARCHITECTURE-REVIEW — deep architecture review with trade-offs ────
if [[ "$1" == "architecture-review" || "$1" == "arcrev" ]]; then
  shift
  SYSTEM="$*"
  [[ -z "$SYSTEM" ]] && echo "Usage: br carpool architecture-review <system or design>" && exit 1
  echo ""
  echo -e "\033[1;34m🏛️  ARCHITECTURE REVIEW: $SYSTEM\033[0m"
  echo ""
  AR_FILE="$HOME/.blackroad/carpool/arch-reviews/$(echo "$SYSTEM" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/arch-reviews"
  printf "# Architecture Review: %s\nDate: %s\n\n" "$SYSTEM" "$(date '+%Y-%m-%d')" > "$AR_FILE"
  for entry in "OCTAVIA|STRENGTHS|What this architecture gets right. Patterns that will age well. Decisions future engineers will thank you for." "SHELLFISH|WEAKNESSES|The hidden bombs. Decisions that feel fine now but cause pain at 10x. Be specific and unflinching." "LUCIDIA|FUNDAMENTAL TRADE-OFFS|The 3 core tensions in this design (e.g. consistency vs availability). What was chosen and at what cost." "CIPHER|SECURITY POSTURE|Where the security model is strong. Where it has gaps. The most likely compromise path." "PRISM|RECOMMENDATION|The single most important change. The one thing to stop doing. The decision to revisit in 6 months."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} reviewing the architecture of: \"${SYSTEM}\"
Section: ${section}
${lens}
Senior engineer level. Real patterns, real failure modes, real trade-off names.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$AR_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $AR_FILE\033[0m"
  exit 0
fi

# ── PERSONA-PITCH — craft a message for a specific audience ──────────
if [[ "$1" == "persona-pitch" || "$1" == "pitch-to" ]]; then
  shift
  AUDIENCE="$*"
  [[ -z "$AUDIENCE" ]] && echo "Usage: br carpool persona-pitch <audience, e.g. 'skeptical CTO'>" && exit 1
  echo ""
  echo -e "\033[1;35m🎭 PERSONA PITCH: $AUDIENCE\033[0m"
  echo ""
  for ag in ARIA LUCIDIA ALICE OCTAVIA CIPHER; do
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag}${NC}"
    python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag}. Write a 3-sentence pitch for BlackRoad OS for: \"${AUDIENCE}\"
Speak their language. Address their number one fear or desire first.
Make them feel understood, not sold to. End with one specific outcome.
3 sentences max. Every word earns its place.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]"
    echo ""
  done
  IFS='|' read -r _ col _ emoji <<< "$(agent_meta "PRISM")"
  echo -e "${col}${emoji} PRISM — STRONGEST PITCH & WHY${NC}"
  python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''5 agents pitched BlackRoad OS to: \"${AUDIENCE}\"
Which approach lands best with this audience and why? Name the agent, name the element that makes it work. 2-3 sentences.''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[PRISM offline]"
  echo ""
  exit 0
fi

# ── CHANGELOG-DRAFT — draft user-facing release notes from git log ────
if [[ "$1" == "changelog-draft" || "$1" == "relnotes" ]]; then
  shift
  VERSION="$*"
  VERSION="${VERSION:-next}"
  echo ""
  echo -e "\033[1;32m📝 CHANGELOG DRAFT: v$VERSION\033[0m"
  echo ""
  RECENT=$(git --no-pager log --oneline -20 2>/dev/null || echo "no git log available")
  CL_FILE="$HOME/.blackroad/carpool/changelogs/v${VERSION}-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/changelogs"
  printf "# Changelog: v%s\nDate: %s\n\n" "$VERSION" "$(date '+%Y-%m-%d')" > "$CL_FILE"
  for entry in "ARIA|USER-FACING HIGHLIGHTS|What changed that users will actually care about. Plain language, no hashes. Features first." "ALICE|WHAT IS FIXED|Bug fixes and improvements. Group by area. One line each." "CIPHER|SECURITY & BREAKING CHANGES|Security patches and breaking API changes. What users must do to upgrade." "LUCIDIA|RELEASE NARRATIVE|2-3 sentences framing this release. The theme. What it moves the product toward."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json, sys
recent = sys.argv[1]
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} writing a changelog for version: \"${VERSION}\"
Recent commits:
{recent[:800]}
Section: ${section}
${lens}
Write actual changelog copy. Human, scannable, honest.
Format: - <entry>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" "$RECENT" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$CL_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $CL_FILE\033[0m"
  exit 0
fi

# ── FEATURE-FLAG — design a feature flag rollout plan ─────────────────
if [[ "$1" == "feature-flag" || "$1" == "flag" || "$1" == "rollout" ]]; then
  shift
  FEATURE="$*"
  [[ -z "$FEATURE" ]] && echo "Usage: br carpool feature-flag <feature name>" && exit 1
  echo ""
  echo -e "\033[1;36m🚩 FEATURE FLAG ROLLOUT: $FEATURE\033[0m"
  echo ""
  FF_FILE="$HOME/.blackroad/carpool/feature-flags/$(echo "$FEATURE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-40)-$(date +%Y%m%d).md"
  mkdir -p "$HOME/.blackroad/carpool/feature-flags"
  printf "# Feature Flag: %s\nDate: %s\n\n" "$FEATURE" "$(date '+%Y-%m-%d')" > "$FF_FILE"
  for entry in "ALICE|FLAG DEFINITION|Flag name (snake_case), type (boolean/variant/kill-switch), default value, owner, expiry date." "PRISM|ROLLOUT STAGES|Internal → 1% → 10% → 50% → 100% GA. Metric to check before advancing. Minimum soak time per stage." "CIPHER|KILL SWITCH PLAN|Exact steps to turn it off in production right now. Who can flip it. How long rollback takes." "OCTAVIA|INSTRUMENTATION|Events to fire when flag is checked, each variant is served, and when it converts." "SHELLFISH|CONSISTENCY EDGE CASES|What breaks if flag is on for some users and off for others simultaneously? Cache, state, DB conflicts."; do
    IFS='|' read -r ag section lens <<< "$entry"
    IFS='|' read -r _ col _ emoji <<< "$(agent_meta "$ag")"
    echo -e "${col}${emoji} ${ag} — ${section}${NC}"
    resp=$(python3 -c "
import urllib.request, json
payload = json.dumps({'model':'${MODEL:-tinyllama}','prompt':f'''You are ${ag} designing a feature flag for: \"${FEATURE}\"
Section: ${section}
${lens}
Real naming conventions, real tools (LaunchDarkly/Unleash/Flipt), real rollout percentages.
Format: - <point>''','stream':False}).encode()
req = urllib.request.Request('http://localhost:11434/api/generate', data=payload, headers={'Content-Type':'application/json'})
print(json.loads(urllib.request.urlopen(req,timeout=30).read()).get('response','').strip())
" 2>/dev/null || echo "[${ag} offline]")
    echo "$resp"
    printf "\n## %s\n%s\n" "$section" "$resp" >> "$FF_FILE"
    echo ""
  done
  echo -e "\033[0;32m✓ Saved to $FF_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "localization" ]]; then
  TOPIC="${2:-our app}"
  LOCALE_DIR="$HOME/.blackroad/carpool/localization"
  mkdir -p "$LOCALE_DIR"
  LOCALE_FILE="$LOCALE_DIR/locale-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🌐 CarPool — Localization plan for: $TOPIC\033[0m"
  echo "# Localization: $TOPIC" > "$LOCALE_FILE"
  echo "Generated: $(date)" >> "$LOCALE_FILE"
  PY_LOCALE='
import sys, json, urllib.request
topic = sys.argv[1]
agents = [
  ("ARIA","UI/UX lead","Which strings and UI components need localization? List top 10 with i18n key names."),
  ("ALICE","Engineer","What i18n library and file format (JSON/PO/XLIFF) would you recommend? Show folder structure."),
  ("PRISM","Data analyst","Which locales/markets should we prioritize? What does the data say about user distribution?"),
  ("OCTAVIA","Platform","What build pipeline changes are needed for locale bundles? How do we handle RTL layouts?"),
  ("LUCIDIA","Strategist","What are the 3 biggest cultural adaptation risks beyond just translation?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}), for localizing {topic}: {question}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role})")
    print(resp.get("response","").strip())
    print()
  except Exception as e:
    print(f"### {name}: [offline]")
    print()
'
  python3 -c "$PY_LOCALE" "$TOPIC" | tee -a "$LOCALE_FILE"
  echo -e "\033[0;32m✓ Saved to $LOCALE_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "cost-analysis" ]]; then
  SYSTEM="${2:-our infrastructure}"
  COST_DIR="$HOME/.blackroad/carpool/cost-analysis"
  mkdir -p "$COST_DIR"
  COST_FILE="$COST_DIR/cost-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m💰 CarPool — Cost analysis for: $SYSTEM\033[0m"
  echo "# Cost Analysis: $SYSTEM" > "$COST_FILE"
  echo "Generated: $(date)" >> "$COST_FILE"
  PY_COST='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("PRISM","FinOps analyst","Break down likely monthly cloud costs for $SYSTEM by service category (compute, storage, network, data transfer). Estimate ranges."),
  ("OCTAVIA","Platform engineer","What are the top 3 over-provisioned or wasteful resources in a typical $SYSTEM setup? How much could we save?"),
  ("ALICE","DevOps","List 5 concrete cost optimization actions we can take this sprint with estimated savings each."),
  ("CIPHER","Security","Which cost-cutting measures could create security risks? Flag any corner-cutting to avoid."),
  ("SHELLFISH","Chaos engineer","What happens to cost if traffic spikes 10x unexpectedly? Are there runaway cost scenarios?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'SYSTEM', system)}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role})")
    print(resp.get("response","").strip())
    print()
  except Exception as e:
    print(f"### {name}: [offline]")
    print()
'
  python3 -c "$PY_COST" "$SYSTEM" | tee -a "$COST_FILE"
  echo -e "\033[0;32m✓ Saved to $COST_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "user-research" ]]; then
  QUESTION="${2:-what do users really want}"
  UR_DIR="$HOME/.blackroad/carpool/user-research"
  mkdir -p "$UR_DIR"
  UR_FILE="$UR_DIR/research-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔬 CarPool — User research plan: $QUESTION\033[0m"
  echo "# User Research: $QUESTION" > "$UR_FILE"
  echo "Generated: $(date)" >> "$UR_FILE"
  PY_UR='
import sys, json, urllib.request
question = sys.argv[1]
agents = [
  ("ARIA","UX researcher","Design a 5-question interview guide to explore: $QUESTION. Include probing follow-ups."),
  ("PRISM","Data analyst","What quantitative signals (analytics, funnels, NPS) should we look at alongside qualitative research for: $QUESTION?"),
  ("LUCIDIA","Strategist","What underlying jobs-to-be-done or emotional needs might drive the answer to: $QUESTION?"),
  ("ALICE","PM","How would you recruit 8 participants, run 30-min sessions, and synthesize findings in a week for: $QUESTION?"),
  ("SHELLFISH","Devil advocate","What biases or leading assumptions might skew the research on: $QUESTION? How do we guard against them?")
]
for name, role, question_template in agents:
  prompt = f"{name} ({role}): {question_template.replace(chr(36)+'QUESTION', question)}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role})")
    print(resp.get("response","").strip())
    print()
  except Exception as e:
    print(f"### {name}: [offline]")
    print()
'
  python3 -c "$PY_UR" "$QUESTION" | tee -a "$UR_FILE"
  echo -e "\033[0;32m✓ Saved to $UR_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "sla" ]]; then
  SERVICE="${2:-our API}"
  SLA_DIR="$HOME/.blackroad/carpool/slas"
  mkdir -p "$SLA_DIR"
  SLA_FILE="$SLA_DIR/sla-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📋 CarPool — SLA definition for: $SERVICE\033[0m"
  echo "# SLA: $SERVICE" > "$SLA_FILE"
  echo "Generated: $(date)" >> "$SLA_FILE"
  PY_SLA='
import sys, json, urllib.request
service = sys.argv[1]
agents = [
  ("PRISM","Reliability analyst","Propose concrete SLI metrics and SLO targets (uptime, latency p99, error rate) for $SERVICE. Show the math for monthly error budget."),
  ("ALICE","PM","What customer-facing SLA tiers (free/pro/enterprise) would you offer for $SERVICE? What are the consequences for each breach?"),
  ("OCTAVIA","Platform","What alerting thresholds, runbooks, and on-call rotation support these SLOs for $SERVICE?"),
  ("CIPHER","Security","Which security SLAs matter here — RTO, RPO, data retention guarantees for $SERVICE? Define them."),
  ("LUCIDIA","Strategist","How do we communicate SLA commitments and breaches to customers in a way that builds trust for $SERVICE?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'SERVICE', service)}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role})")
    print(resp.get("response","").strip())
    print()
  except Exception as e:
    print(f"### {name}: [offline]")
    print()
'
  python3 -c "$PY_SLA" "$SERVICE" | tee -a "$SLA_FILE"
  echo -e "\033[0;32m✓ Saved to $SLA_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "onboarding" ]]; then
  ROLE="${2:-engineer}"
  OB_DIR="$HOME/.blackroad/carpool/onboarding"
  mkdir -p "$OB_DIR"
  OB_FILE="$OB_DIR/onboard-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🎓 CarPool — Onboarding plan for: $ROLE\033[0m"
  echo "# Onboarding: $ROLE" > "$OB_FILE"
  echo "Generated: $(date)" >> "$OB_FILE"
  PY_OB='
import sys, json, urllib.request
role = sys.argv[1]
agents = [
  ("ALICE","PM","Write a 30-60-90 day plan for a new $ROLE. List 3 concrete goals per phase."),
  ("ARIA","Culture","What people, teams, and slack channels should a new $ROLE meet in week 1? Why each one?"),
  ("OCTAVIA","Platform","What dev environment setup, access, and tools does a new $ROLE need on day 1? Checklist format."),
  ("LUCIDIA","Mentor","What are the 3 biggest unwritten rules or cultural nuances a new $ROLE must understand to succeed here?"),
  ("PRISM","Analyst","How do we measure if onboarding is working? What signals tell us the new $ROLE is ramping well?")
]
for name, role_label, question in agents:
  prompt = f"{name} ({role_label}): {question.replace(chr(36)+'ROLE', role)}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role_label})")
    print(resp.get("response","").strip())
    print()
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_OB" "$ROLE" | tee -a "$OB_FILE"
  echo -e "\033[0;32m✓ Saved to $OB_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "dogfood" ]]; then
  FEATURE="${2:-the new feature}"
  DF_DIR="$HOME/.blackroad/carpool/dogfood"
  mkdir -p "$DF_DIR"
  DF_FILE="$DF_DIR/dogfood-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🐶 CarPool — Internal dogfooding plan: $FEATURE\033[0m"
  echo "# Dogfood: $FEATURE" > "$DF_FILE"
  echo "Generated: $(date)" >> "$DF_FILE"
  PY_DF='
import sys, json, urllib.request
feature = sys.argv[1]
agents = [
  ("ALICE","PM","Design a 2-week internal dogfood plan for $FEATURE. Who uses it, what tasks, what feedback to collect?"),
  ("ARIA","UX","What specific UX friction points should internal testers watch for in $FEATURE? Give 5 observation prompts."),
  ("PRISM","Analytics","What instrumentation and metrics do we need before dogfooding $FEATURE to measure success?"),
  ("SHELLFISH","Chaos","What intentional abuse or edge-case usage should internal testers try to stress-test $FEATURE?"),
  ("OCTAVIA","Platform","What feature flags, environments, and rollback steps do we need to safely dogfood $FEATURE internally?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'FEATURE', feature)}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role})")
    print(resp.get("response","").strip())
    print()
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_DF" "$FEATURE" | tee -a "$DF_FILE"
  echo -e "\033[0;32m✓ Saved to $DF_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "rollback" ]]; then
  CHANGE="${2:-the last deployment}"
  RB_DIR="$HOME/.blackroad/carpool/rollbacks"
  mkdir -p "$RB_DIR"
  RB_FILE="$RB_DIR/rollback-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m⏪ CarPool — Rollback plan for: $CHANGE\033[0m"
  echo "# Rollback Plan: $CHANGE" > "$RB_FILE"
  echo "Generated: $(date)" >> "$RB_FILE"
  PY_RB='
import sys, json, urllib.request
change = sys.argv[1]
agents = [
  ("OCTAVIA","Platform","Write step-by-step rollback commands for $CHANGE. Include verification steps after each action."),
  ("ALICE","Ops","What is the decision criteria — at what point do we pull the trigger and rollback $CHANGE? Who approves?"),
  ("CIPHER","Security","Are there any security implications of rolling back $CHANGE? Data integrity risks or auth state issues?"),
  ("PRISM","Analytics","What metrics and dashboards do we watch to confirm $CHANGE is causing the problem before we rollback?"),
  ("LUCIDIA","Strategist","After the rollback of $CHANGE, what is the post-mortem process and how do we safely re-attempt?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'CHANGE', change)}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role})")
    print(resp.get("response","").strip())
    print()
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_RB" "$CHANGE" | tee -a "$RB_FILE"
  echo -e "\033[0;32m✓ Saved to $RB_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "competitive" ]]; then
  PRODUCT="${2:-our product}"
  COMP_DIR="$HOME/.blackroad/carpool/competitive"
  mkdir -p "$COMP_DIR"
  COMP_FILE="$COMP_DIR/comp-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m⚔️  CarPool — Competitive analysis: $PRODUCT\033[0m"
  echo "# Competitive Analysis: $PRODUCT" > "$COMP_FILE"
  echo "Generated: $(date)" >> "$COMP_FILE"
  PY_COMP='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("PRISM","Analyst","Name the top 3-5 competitors to $PRODUCT. For each: their main strength, main weakness, and pricing model."),
  ("ARIA","Designer","How does $PRODUCT compare on UX and design quality vs competitors? Where are the biggest gaps?"),
  ("LUCIDIA","Strategist","What is the unique moat or wedge $PRODUCT should build that competitors cannot easily copy?"),
  ("SHELLFISH","Hacker","Where are competitors most vulnerable? What are their biggest technical or product liabilities?"),
  ("ALICE","PM","Which competitor features are table-stakes that $PRODUCT must match, vs differentiators worth investing in?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'PRODUCT', product)}"
  data = json.dumps({"model":"tinyllama","prompt":prompt,"stream":False}).encode()
  req = urllib.request.Request("http://localhost:11434/api/generate",data=data,headers={"Content-Type":"application/json"})
  try:
    resp = json.loads(urllib.request.urlopen(req,timeout=30).read())
    print(f"### {name} ({role})")
    print(resp.get("response","").strip())
    print()
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_COMP" "$PRODUCT" | tee -a "$COMP_FILE"
  echo -e "\033[0;32m✓ Saved to $COMP_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "last" ]]; then
  f=$(ls -1t "$SAVE_DIR" 2>/dev/null | head -1)
  [[ -z "$f" ]] && echo "No saved sessions yet." && exit 1
  less "$SAVE_DIR/$f"
  exit 0
fi

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

# Auto-inject theme if set
THEME_FILE="$HOME/.blackroad/carpool/theme.txt"
if [[ -f "$THEME_FILE" ]]; then
  theme_text=$(cat "$THEME_FILE")
  existing=$(cat "$WORK_DIR/context.txt" 2>/dev/null)
  { echo "=== PROJECT THEME ==="; echo "$theme_text"; echo "=== END THEME ===";
    [[ -n "$existing" ]] && echo "" && echo "$existing"; } > "$WORK_DIR/context.txt"
  echo -e "${CYAN}🎯 theme:${NC} $(head -1 "$THEME_FILE")"
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
