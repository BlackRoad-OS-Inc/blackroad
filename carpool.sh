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

if [[ "$1" == "naming" ]]; then
  THING="${2:-our new feature}"
  NAME_DIR="$HOME/.blackroad/carpool/naming"
  mkdir -p "$NAME_DIR"
  NAME_FILE="$NAME_DIR/naming-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m✏️  CarPool — Name brainstorm for: $THING\033[0m"
  echo "# Naming: $THING" > "$NAME_FILE"
  echo "Generated: $(date)" >> "$NAME_FILE"
  PY_NAME='
import sys, json, urllib.request
thing = sys.argv[1]
agents = [
  ("ARIA","Brand designer","Generate 8 creative name ideas for $THING. For each: the name, a one-line rationale, and a vibe (playful/serious/technical/human)."),
  ("LUCIDIA","Poet","Give 5 metaphor-driven or evocative names for $THING that would feel alive and memorable. Explain the imagery behind each."),
  ("ALICE","PM","Propose 5 pragmatic, clear, self-explanatory names for $THING that would work well in docs and APIs. No cleverness — just clarity."),
  ("CIPHER","Security","Flag any of these naming concerns for $THING: trademark collisions, offensive meanings in other languages, or names that sound like something insecure."),
  ("PRISM","Analyst","From a naming standpoint, what are the 3 criteria that matter most for $THING? Then rank the best options from the other agents.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'THING', thing)}"
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
  python3 -c "$PY_NAME" "$THING" | tee -a "$NAME_FILE"
  echo -e "\033[0;32m✓ Saved to $NAME_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "postmortem" ]]; then
  INCIDENT="${2:-the last incident}"
  PM_DIR="$HOME/.blackroad/carpool/postmortems"
  mkdir -p "$PM_DIR"
  PM_FILE="$PM_DIR/postmortem-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔍 CarPool — Post-mortem for: $INCIDENT\033[0m"
  echo "# Post-Mortem: $INCIDENT" > "$PM_FILE"
  echo "Generated: $(date)" >> "$PM_FILE"
  PY_PM='
import sys, json, urllib.request
incident = sys.argv[1]
agents = [
  ("PRISM","Analyst","For the incident ($INCIDENT): reconstruct a timeline of events. What signals appeared first? When was it detected vs when did it start?"),
  ("OCTAVIA","Platform","What was the root cause of $INCIDENT? Use 5 Whys. What single change would have prevented it?"),
  ("ALICE","PM","Write the customer-facing incident summary for $INCIDENT: what happened, impact, and what we are doing to prevent recurrence. Keep it under 150 words."),
  ("CIPHER","Security","Were there any security implications of $INCIDENT? Unauthorized access, data exposure, or compliance concerns?"),
  ("LUCIDIA","Strategist","What are the top 3 systemic action items from $INCIDENT? Assign each a DRI, priority, and deadline. No blameless culture — own the fixes.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'INCIDENT', incident)}"
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
  python3 -c "$PY_PM" "$INCIDENT" | tee -a "$PM_FILE"
  echo -e "\033[0;32m✓ Saved to $PM_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "techdebt" ]]; then
  AREA="${2:-our codebase}"
  TD_DIR="$HOME/.blackroad/carpool/techdebt"
  mkdir -p "$TD_DIR"
  TD_FILE="$TD_DIR/techdebt-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🏚️  CarPool — Tech debt audit for: $AREA\033[0m"
  echo "# Tech Debt Audit: $AREA" > "$TD_FILE"
  echo "Generated: $(date)" >> "$TD_FILE"
  PY_TD='
import sys, json, urllib.request
area = sys.argv[1]
agents = [
  ("SHELLFISH","Chaos engineer","What are the top 5 most dangerous tech debt items in $AREA? Rank by blast radius if they explode."),
  ("OCTAVIA","Architect","In $AREA, which architectural decisions are now wrong and actively slowing the team down? What is the refactor path?"),
  ("ALICE","PM","How do we prioritize tech debt paydown in $AREA against feature work? Propose a sustainable ratio and quarterly plan."),
  ("PRISM","Analyst","How do we measure tech debt in $AREA? What proxy metrics (deploy frequency, incident rate, PR cycle time) tell us the debt is shrinking?"),
  ("LUCIDIA","Strategist","Write a 1-paragraph pitch to leadership explaining why investing in $AREA tech debt now saves money and velocity later.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'AREA', area)}"
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
  python3 -c "$PY_TD" "$AREA" | tee -a "$TD_FILE"
  echo -e "\033[0;32m✓ Saved to $TD_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "launch-checklist" ]]; then
  FEATURE="${2:-the new feature}"
  LC_DIR="$HOME/.blackroad/carpool/launch-checklists"
  mkdir -p "$LC_DIR"
  LC_FILE="$LC_DIR/checklist-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🚀 CarPool — Launch checklist for: $FEATURE\033[0m"
  echo "# Launch Checklist: $FEATURE" > "$LC_FILE"
  echo "Generated: $(date)" >> "$LC_FILE"
  PY_LC='
import sys, json, urllib.request
feature = sys.argv[1]
agents = [
  ("ALICE","PM","List the product and comms checklist items for launching $FEATURE: docs, changelog, support briefing, announcement copy, CSM notification."),
  ("OCTAVIA","Platform","List the infrastructure checklist for $FEATURE launch: feature flags, DB migrations run, monitors configured, rollback tested, load tested."),
  ("CIPHER","Security","List the security checklist for $FEATURE launch: auth flows reviewed, input validation, rate limits, pen test if needed, GDPR/compliance sign-off."),
  ("ARIA","Design","List the UX/design checklist for $FEATURE: responsive tested, accessibility pass, copy reviewed, empty states, error states, loading states done."),
  ("PRISM","Analytics","List the analytics checklist for $FEATURE: events instrumented, dashboards built, baseline metrics captured, success KPIs defined and shared.")
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
  python3 -c "$PY_LC" "$FEATURE" | tee -a "$LC_FILE"
  echo -e "\033[0;32m✓ Saved to $LC_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "interview" ]]; then
  ROLE="${2:-software engineer}"
  IV_DIR="$HOME/.blackroad/carpool/interviews"
  mkdir -p "$IV_DIR"
  IV_FILE="$IV_DIR/interview-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🎤 CarPool — Interview plan for: $ROLE\033[0m"
  echo "# Interview Plan: $ROLE" > "$IV_FILE"
  echo "Generated: $(date)" >> "$IV_FILE"
  PY_IV='
import sys, json, urllib.request
role = sys.argv[1]
agents = [
  ("OCTAVIA","Technical","Write 5 technical interview questions for a $ROLE. Include 1 system design, 1 debugging scenario, 1 tradeoff discussion, and 2 coding concepts."),
  ("LUCIDIA","Culture","Write 4 behavioral questions for a $ROLE using STAR format prompts. Focus on: ownership, conflict resolution, ambiguity, and learning from failure."),
  ("PRISM","Analyst","Design a take-home exercise or live coding prompt for a $ROLE that can be completed in 45 minutes. Include evaluation rubric."),
  ("ARIA","People","What red flags and green flags should interviewers watch for when hiring a $ROLE? List 5 of each."),
  ("ALICE","PM","What is the ideal interview loop structure for a $ROLE? Who interviews, what does each round assess, and how do we debrief and decide?")
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
  python3 -c "$PY_IV" "$ROLE" | tee -a "$IV_FILE"
  echo -e "\033[0;32m✓ Saved to $IV_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "scalability" ]]; then
  SYSTEM="${2:-our backend}"
  SC_DIR="$HOME/.blackroad/carpool/scalability"
  mkdir -p "$SC_DIR"
  SC_FILE="$SC_DIR/scale-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📈 CarPool — Scalability review: $SYSTEM\033[0m"
  echo "# Scalability Review: $SYSTEM" > "$SC_FILE"
  echo "Generated: $(date)" >> "$SC_FILE"
  PY_SC='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","Identify the top 3 bottlenecks in $SYSTEM at 10x current load. What breaks first and why?"),
  ("PRISM","Analyst","What load testing strategy would you use for $SYSTEM? What thresholds define passing vs failing?"),
  ("ALICE","DevOps","What horizontal scaling, caching, and queueing changes would you make to $SYSTEM for 100x load? Give a phased plan."),
  ("SHELLFISH","Chaos","Design 3 chaos experiments that would expose the hidden scalability weaknesses in $SYSTEM before they surface in production."),
  ("LUCIDIA","Strategist","At what scale does $SYSTEM need a full architectural rethink vs incremental improvements? What is the inflection point?")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_SC" "$SYSTEM" | tee -a "$SC_FILE"
  echo -e "\033[0;32m✓ Saved to $SC_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "monetization" ]]; then
  PRODUCT="${2:-our product}"
  MON_DIR="$HOME/.blackroad/carpool/monetization"
  mkdir -p "$MON_DIR"
  MON_FILE="$MON_DIR/monetize-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m💵 CarPool — Monetization strategy: $PRODUCT\033[0m"
  echo "# Monetization: $PRODUCT" > "$MON_FILE"
  echo "Generated: $(date)" >> "$MON_FILE"
  PY_MON='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("LUCIDIA","Strategist","What are the top 3 monetization models that fit $PRODUCT? For each: revenue mechanic, ideal customer, and biggest risk."),
  ("PRISM","Analyst","Design a freemium tier structure for $PRODUCT. What features are free forever vs paid? Where is the natural upgrade trigger?"),
  ("ARIA","Designer","How do we present pricing for $PRODUCT in a way that maximizes conversion without feeling manipulative? Describe the pricing page concept."),
  ("ALICE","PM","What pricing experiments should we run in the first 90 days for $PRODUCT? What do we measure to know if pricing is right?"),
  ("SHELLFISH","Hacker","How could customers abuse or game the pricing model of $PRODUCT? What guardrails prevent margin erosion?")
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
  python3 -c "$PY_MON" "$PRODUCT" | tee -a "$MON_FILE"
  echo -e "\033[0;32m✓ Saved to $MON_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "dependency" ]]; then
  LIBRARY="${2:-our dependencies}"
  DEP_DIR="$HOME/.blackroad/carpool/dependencies"
  mkdir -p "$DEP_DIR"
  DEP_FILE="$DEP_DIR/deps-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📦 CarPool — Dependency audit: $LIBRARY\033[0m"
  echo "# Dependency Audit: $LIBRARY" > "$DEP_FILE"
  echo "Generated: $(date)" >> "$DEP_FILE"
  PY_DEP='
import sys, json, urllib.request
library = sys.argv[1]
agents = [
  ("CIPHER","Security","What are the top security risks of depending on $LIBRARY? What should we check: CVEs, maintainer trust, supply chain risks?"),
  ("SHELLFISH","Hacker","How could $LIBRARY be used as an attack vector against us? Typosquatting, malicious updates, dependency confusion?"),
  ("OCTAVIA","Architect","Is $LIBRARY worth the dependency? What does it cost us in bundle size, build time, and lock-in? Could we build it ourselves?"),
  ("ALICE","DevOps","How do we keep $LIBRARY up to date safely? What is our update cadence, automated testing strategy, and pinning policy?"),
  ("PRISM","Analyst","How do we evaluate whether to replace $LIBRARY? What criteria (stars, commits, CVE history, license) matter most?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'LIBRARY', library)}"
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
  python3 -c "$PY_DEP" "$LIBRARY" | tee -a "$DEP_FILE"
  echo -e "\033[0;32m✓ Saved to $DEP_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "retro" ]]; then
  SPRINT="${2:-last sprint}"
  RETRO_DIR="$HOME/.blackroad/carpool/retros"
  mkdir -p "$RETRO_DIR"
  RETRO_FILE="$RETRO_DIR/retro-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔄 CarPool — Retrospective for: $SPRINT\033[0m"
  echo "# Retro: $SPRINT" > "$RETRO_FILE"
  echo "Generated: $(date)" >> "$RETRO_FILE"
  PY_RETRO='
import sys, json, urllib.request
sprint = sys.argv[1]
agents = [
  ("LUCIDIA","Facilitator","For $SPRINT retro — generate 3 thought-provoking questions each for: What went well? What did not? What would we do differently?"),
  ("ALICE","PM","What are 5 concrete process improvements the team should try next sprint based on common retro pain points from $SPRINT?"),
  ("PRISM","Analyst","What team health metrics should we track sprint-over-sprint? List 6 signals (velocity, PR cycle time, blocked days, etc) and how to visualize them."),
  ("ARIA","Culture","How do we run $SPRINT retro in a way that feels psychologically safe and energizing, not a blame session? Give a 60-min agenda."),
  ("OCTAVIA","Tech","What engineering process experiments (pair programming, mob review, no-meeting blocks) should we trial next sprint based on $SPRINT learnings?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'SPRINT', sprint)}"
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
  python3 -c "$PY_RETRO" "$SPRINT" | tee -a "$RETRO_FILE"
  echo -e "\033[0;32m✓ Saved to $RETRO_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "documentation" ]]; then
  FEATURE="${2:-the feature}"
  DOCS_DIR="$HOME/.blackroad/carpool/documentation"
  mkdir -p "$DOCS_DIR"
  DOCS_FILE="$DOCS_DIR/docs-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📝 CarPool — Documentation plan for: $FEATURE\033[0m"
  echo "# Documentation Plan: $FEATURE" > "$DOCS_FILE"
  echo "Generated: $(date)" >> "$DOCS_FILE"
  PY_DOCS='
import sys, json, urllib.request
feature = sys.argv[1]
agents = [
  ("ARIA","Tech writer","Write a complete outline for the user-facing docs for $FEATURE. Include: overview, quickstart, concepts, how-to guides, reference, and FAQs."),
  ("ALICE","PM","Write the one-paragraph product description and the 3 key use cases for $FEATURE that should appear at the top of every doc page."),
  ("OCTAVIA","Engineer","Write the API reference structure for $FEATURE: endpoints or functions, parameters, response shapes, error codes, and a code example."),
  ("LUCIDIA","Educator","What analogies or mental models make $FEATURE click for a new user? Write an ELI5 explanation and a more advanced conceptual explanation."),
  ("PRISM","Analyst","How do we measure if our docs for $FEATURE are working? What signals (search queries, support tickets, time-on-page) tell us where docs are failing?")
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
  python3 -c "$PY_DOCS" "$FEATURE" | tee -a "$DOCS_FILE"
  echo -e "\033[0;32m✓ Saved to $DOCS_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "vision" ]]; then
  PRODUCT="${2:-our product}"
  VIS_DIR="$HOME/.blackroad/carpool/visions"
  mkdir -p "$VIS_DIR"
  VIS_FILE="$VIS_DIR/vision-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🌌 CarPool — Long-term vision for: $PRODUCT\033[0m"
  echo "# Vision: $PRODUCT" > "$VIS_FILE"
  echo "Generated: $(date)" >> "$VIS_FILE"
  PY_VIS='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("LUCIDIA","Visionary","Paint a vivid picture of what $PRODUCT looks like in 5 years if everything goes right. Who uses it, how, and why does it matter?"),
  ("PRISM","Futurist","What macro trends (AI, regulation, demographics, infrastructure) will shape the future of $PRODUCT over the next 5 years?"),
  ("ARIA","Designer","What does the ideal end-state UX of $PRODUCT look like? Describe the experience in sensory and emotional terms."),
  ("SHELLFISH","Skeptic","What are the 3 most likely reasons $PRODUCT fails to reach its 5-year vision? What assumptions is the vision making that could be wrong?"),
  ("ALICE","Operator","What are the 5 biggest organizational and execution challenges to achieving the $PRODUCT vision? How do we sequence them?")
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
  python3 -c "$PY_VIS" "$PRODUCT" | tee -a "$VIS_FILE"
  echo -e "\033[0;32m✓ Saved to $VIS_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "партнер" ]] || [[ "$1" == "partnership" ]]; then
  PARTNER="${2:-a potential partner}"
  PART_DIR="$HOME/.blackroad/carpool/partnerships"
  mkdir -p "$PART_DIR"
  PART_FILE="$PART_DIR/partner-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🤝 CarPool — Partnership analysis: $PARTNER\033[0m"
  echo "# Partnership: $PARTNER" > "$PART_FILE"
  echo "Generated: $(date)" >> "$PART_FILE"
  PY_PART='
import sys, json, urllib.request
partner = sys.argv[1]
agents = [
  ("LUCIDIA","Strategist","What is the strategic case for partnering with $PARTNER? What does each side bring and what does each side get?"),
  ("ALICE","BD","What are the 5 key terms we need to nail in a partnership agreement with $PARTNER? What are our must-haves vs nice-to-haves?"),
  ("PRISM","Analyst","How do we measure if a partnership with $PARTNER is working? What are the 3 leading and 3 lagging indicators of success?"),
  ("CIPHER","Risk","What are the top 3 risks of partnering with $PARTNER: data sharing, lock-in, competitive conflict, reputational risk?"),
  ("SHELLFISH","Devil advocate","Why should we NOT partner with $PARTNER? What are the hidden costs, power imbalances, or strategic traps?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'PARTNER', partner)}"
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
  python3 -c "$PY_PART" "$PARTNER" | tee -a "$PART_FILE"
  echo -e "\033[0;32m✓ Saved to $PART_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "error-handling" ]]; then
  SYSTEM="${2:-our API}"
  EH_DIR="$HOME/.blackroad/carpool/error-handling"
  mkdir -p "$EH_DIR"
  EH_FILE="$EH_DIR/errors-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m⚠️  CarPool — Error handling strategy: $SYSTEM\033[0m"
  echo "# Error Handling: $SYSTEM" > "$EH_FILE"
  echo "Generated: $(date)" >> "$EH_FILE"
  PY_EH='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","Design the error taxonomy for $SYSTEM: categories (transient, permanent, user, system), HTTP/error codes, and retry semantics for each."),
  ("ALICE","PM","Write the user-facing error message guidelines for $SYSTEM. What tone, what info to include, and what action to give the user for the top 5 error types."),
  ("CIPHER","Security","What error handling mistakes in $SYSTEM could leak sensitive info (stack traces, internal IDs, DB errors)? What must we scrub from error responses?"),
  ("PRISM","Analyst","What error monitoring strategy for $SYSTEM? Which errors page on-call immediately vs log silently vs aggregate into weekly reports?"),
  ("SHELLFISH","Chaos","Design 5 error injection tests for $SYSTEM: what failures to simulate, expected behavior, and how to verify graceful degradation.")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_EH" "$SYSTEM" | tee -a "$EH_FILE"
  echo -e "\033[0;32m✓ Saved to $EH_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "standup" ]]; then
  TEAM="${2:-the team}"
  SD_DIR="$HOME/.blackroad/carpool/standups"
  mkdir -p "$SD_DIR"
  SD_FILE="$SD_DIR/standup-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m☀️  CarPool — Standup format for: $TEAM\033[0m"
  echo "# Standup Design: $TEAM" > "$SD_FILE"
  echo "Generated: $(date)" >> "$SD_FILE"
  PY_SD='
import sys, json, urllib.request
team = sys.argv[1]
agents = [
  ("ALICE","PM","Design the ideal async standup format for $TEAM. What 3 questions does each person answer? How is it collected and shared?"),
  ("LUCIDIA","Facilitator","What are the 5 most common ways standups go wrong for $TEAM type? How do we prevent each one?"),
  ("PRISM","Analyst","What signals in standup updates tell us $TEAM is in trouble before it becomes a crisis? List 6 early warning patterns."),
  ("ARIA","Culture","How do we make the standup for $TEAM feel connective and human, not bureaucratic? What rituals or formats help?"),
  ("OCTAVIA","Async","Design a fully async standup bot workflow for $TEAM: trigger time, format, aggregation, and where it posts the daily summary.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'TEAM', team)}"
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
  python3 -c "$PY_SD" "$TEAM" | tee -a "$SD_FILE"
  echo -e "\033[0;32m✓ Saved to $SD_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "refactor" ]]; then
  CODE="${2:-the module}"
  RF_DIR="$HOME/.blackroad/carpool/refactors"
  mkdir -p "$RF_DIR"
  RF_FILE="$RF_DIR/refactor-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔧 CarPool — Refactor plan for: $CODE\033[0m"
  echo "# Refactor Plan: $CODE" > "$RF_FILE"
  echo "Generated: $(date)" >> "$RF_FILE"
  PY_RF='
import sys, json, urllib.request
code = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","What is the ideal end-state architecture for $CODE after refactoring? Draw the before/after in ASCII or describe it clearly."),
  ("ALICE","PM","How do we refactor $CODE safely without stopping feature delivery? Propose a strangler fig or parallel-run approach with phases."),
  ("SHELLFISH","Risk","What are the top 3 ways the $CODE refactor could go wrong or introduce regressions? What safety nets do we need first?"),
  ("CIPHER","Security","What security improvements should we bake into the $CODE refactor while we are in there? Auth, input validation, secrets handling."),
  ("PRISM","Quality","What test coverage must we have BEFORE touching $CODE? What characterization tests should we write to lock in current behavior?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'CODE', code)}"
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
  python3 -c "$PY_RF" "$CODE" | tee -a "$RF_FILE"
  echo -e "\033[0;32m✓ Saved to $RF_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "alerting" ]]; then
  SERVICE="${2:-our service}"
  AL_DIR="$HOME/.blackroad/carpool/alerting"
  mkdir -p "$AL_DIR"
  AL_FILE="$AL_DIR/alerts-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔔 CarPool — Alerting strategy for: $SERVICE\033[0m"
  echo "# Alerting Strategy: $SERVICE" > "$AL_FILE"
  echo "Generated: $(date)" >> "$AL_FILE"
  PY_AL='
import sys, json, urllib.request
service = sys.argv[1]
agents = [
  ("PRISM","SRE","Design the full alerting pyramid for $SERVICE: what fires a page (P0/P1), what is a Slack warn (P2), and what is a weekly digest (P3)?"),
  ("OCTAVIA","Platform","What are the 8 essential metrics to alert on for $SERVICE? For each: threshold, window, and severity."),
  ("ALICE","Ops","How do we prevent alert fatigue for $SERVICE? What alert tuning cadence, silencing rules, and on-call rotation reduces noise?"),
  ("CIPHER","Security","What security-specific alerts must exist for $SERVICE: auth failures, rate limit breaches, unusual access patterns, data exfil signals?"),
  ("LUCIDIA","Strategist","What is the alert escalation policy for $SERVICE? Who gets paged, in what order, and what happens if no one responds in 10 minutes?")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_AL" "$SERVICE" | tee -a "$AL_FILE"
  echo -e "\033[0;32m✓ Saved to $AL_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "caching" ]]; then
  SYSTEM="${2:-our backend}"
  CACHE_DIR="$HOME/.blackroad/carpool/caching"
  mkdir -p "$CACHE_DIR"
  CACHE_FILE="$CACHE_DIR/cache-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m⚡ CarPool — Caching strategy for: $SYSTEM\033[0m"
  echo "# Caching Strategy: $SYSTEM" > "$CACHE_FILE"
  echo "Generated: $(date)" >> "$CACHE_FILE"
  PY_CACHE='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","Design the caching layers for $SYSTEM: browser, CDN, API gateway, app-level, and DB query cache. What belongs at each layer and why?"),
  ("PRISM","Analyst","What are the top 5 cache candidates in $SYSTEM ranked by read frequency and compute cost? What TTL makes sense for each?"),
  ("ALICE","Engineer","Write the cache invalidation strategy for $SYSTEM. How do we handle stale data on writes, deploys, and config changes?"),
  ("SHELLFISH","Chaos","What are the top 3 cache failure scenarios for $SYSTEM: stampede, poisoning, cold start? How do we defend against each?"),
  ("CIPHER","Security","What security risks come with caching in $SYSTEM? User data leakage across tenants, cached auth tokens, sensitive data in CDN edge nodes?")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_CACHE" "$SYSTEM" | tee -a "$CACHE_FILE"
  echo -e "\033[0;32m✓ Saved to $CACHE_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "analytics" ]]; then
  PRODUCT="${2:-our product}"
  AN_DIR="$HOME/.blackroad/carpool/analytics"
  mkdir -p "$AN_DIR"
  AN_FILE="$AN_DIR/analytics-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📊 CarPool — Analytics plan for: $PRODUCT\033[0m"
  echo "# Analytics Plan: $PRODUCT" > "$AN_FILE"
  echo "Generated: $(date)" >> "$AN_FILE"
  PY_AN='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("PRISM","Data analyst","Design the event tracking taxonomy for $PRODUCT. List the 10 most critical user events, their properties, and naming conventions."),
  ("ALICE","PM","What are the 5 north star and supporting metrics for $PRODUCT? Write the formula and data source for each."),
  ("OCTAVIA","Engineer","What is the analytics pipeline architecture for $PRODUCT: SDK, event bus, warehouse, and BI layer? Recommend tools for each stage."),
  ("ARIA","UX","What funnel analysis and session recording setup would reveal the most about how users experience $PRODUCT?"),
  ("CIPHER","Privacy","What GDPR and privacy-by-design requirements apply to $PRODUCT analytics? What must be anonymized, consented, or excluded entirely?")
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
  python3 -c "$PY_AN" "$PRODUCT" | tee -a "$AN_FILE"
  echo -e "\033[0;32m✓ Saved to $AN_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "team-structure" ]]; then
  ORG="${2:-our engineering org}"
  TS_DIR="$HOME/.blackroad/carpool/team-structures"
  mkdir -p "$TS_DIR"
  TS_FILE="$TS_DIR/team-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🏗️  CarPool — Team structure for: $ORG\033[0m"
  echo "# Team Structure: $ORG" > "$TS_FILE"
  echo "Generated: $(date)" >> "$TS_FILE"
  PY_TS='
import sys, json, urllib.request
org = sys.argv[1]
agents = [
  ("LUCIDIA","Org designer","What team topology best fits $ORG: stream-aligned, platform, enabling, or complicated-subsystem teams? Map out the structure."),
  ("ALICE","PM","How should $ORG split product ownership? Where are the natural seams — by domain, by customer segment, or by platform layer?"),
  ("PRISM","Analyst","What are the cognitive load and coordination cost signals that tell us $ORG team structure needs to change? List 5 red flags."),
  ("ARIA","Culture","How do we maintain connection, shared culture, and knowledge transfer across $ORG as it grows and splits into focused teams?"),
  ("OCTAVIA","Engineering","What shared platform or enabling team capabilities does $ORG need to prevent each product team from rebuilding the same infra?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'ORG', org)}"
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
  python3 -c "$PY_TS" "$ORG" | tee -a "$TS_FILE"
  echo -e "\033[0;32m✓ Saved to $TS_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "demo" ]]; then
  FEATURE="${2:-our product}"
  DEMO_DIR="$HOME/.blackroad/carpool/demos"
  mkdir -p "$DEMO_DIR"
  DEMO_FILE="$DEMO_DIR/demo-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🎬 CarPool — Demo script for: $FEATURE\033[0m"
  echo "# Demo Script: $FEATURE" > "$DEMO_FILE"
  echo "Generated: $(date)" >> "$DEMO_FILE"
  PY_DEMO='
import sys, json, urllib.request
feature = sys.argv[1]
agents = [
  ("ARIA","Storyteller","Write a 5-minute demo narrative arc for $FEATURE. Open with the pain, build to the aha moment, close with the vision. Include exact words to say."),
  ("ALICE","PM","What is the tightest possible demo flow for $FEATURE — minimum clicks, maximum impact? List the 5 must-show moments in order."),
  ("LUCIDIA","Director","What emotional journey should the audience feel during the $FEATURE demo? Map: curious → skeptical → impressed → excited → ready to buy."),
  ("PRISM","Analyst","What objections will the audience raise during the $FEATURE demo and what is the 1-sentence response to each?"),
  ("SHELLFISH","Risk","What are the top 3 demo failure modes for $FEATURE: live bug, slow load, awkward question? Prepare fallback scripts for each.")
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
  python3 -c "$PY_DEMO" "$FEATURE" | tee -a "$DEMO_FILE"
  echo -e "\033[0;32m✓ Saved to $DEMO_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "rate-limiting" ]]; then
  API="${2:-our API}"
  RL_DIR="$HOME/.blackroad/carpool/rate-limiting"
  mkdir -p "$RL_DIR"
  RL_FILE="$RL_DIR/ratelimit-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🚦 CarPool — Rate limiting strategy: $API\033[0m"
  echo "# Rate Limiting: $API" > "$RL_FILE"
  echo "Generated: $(date)" >> "$RL_FILE"
  PY_RL='
import sys, json, urllib.request
api = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","Design the rate limiting tiers for $API: by IP, by API key, by user, by plan. What algorithm — token bucket, sliding window, fixed counter?"),
  ("ALICE","PM","What rate limits should free vs pro vs enterprise plans have for $API? Write the limits table with burst allowances and daily caps."),
  ("CIPHER","Security","What attack patterns does rate limiting on $API need to stop: credential stuffing, scraping, DDoS, enumeration? How does each require different rules?"),
  ("PRISM","Analyst","How do we detect when rate limit thresholds are wrong for $API? What signals show limits are too tight or too loose?"),
  ("ARIA","UX","How should $API communicate rate limit errors to developers? Write the ideal 429 error response body, headers, and documentation language.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'API', api)}"
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
  python3 -c "$PY_RL" "$API" | tee -a "$RL_FILE"
  echo -e "\033[0;32m✓ Saved to $RL_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "email" ]]; then
  CAMPAIGN="${2:-our launch campaign}"
  EM_DIR="$HOME/.blackroad/carpool/emails"
  mkdir -p "$EM_DIR"
  EM_FILE="$EM_DIR/email-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m✉️  CarPool — Email campaign: $CAMPAIGN\033[0m"
  echo "# Email Campaign: $CAMPAIGN" > "$EM_FILE"
  echo "Generated: $(date)" >> "$EM_FILE"
  PY_EM='
import sys, json, urllib.request
campaign = sys.argv[1]
agents = [
  ("ARIA","Copywriter","Write 3 subject line options for $CAMPAIGN (one curiosity, one urgency, one benefit-led). Include preview text for each."),
  ("LUCIDIA","Storyteller","Write the body copy for the hero email in $CAMPAIGN. Open with a story, build tension, resolve with the offer. Under 200 words."),
  ("ALICE","PM","Design the full drip sequence for $CAMPAIGN: how many emails, cadence (days between), goal of each email, and when to stop sending."),
  ("PRISM","Analyst","What are the key metrics for $CAMPAIGN and what benchmarks should we hit? Open rate, CTR, conversion, unsubscribe — what is good vs bad?"),
  ("CIPHER","Compliance","What CAN-SPAM, GDPR, and deliverability requirements apply to $CAMPAIGN? Checklist of must-haves before sending.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'CAMPAIGN', campaign)}"
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
  python3 -c "$PY_EM" "$CAMPAIGN" | tee -a "$EM_FILE"
  echo -e "\033[0;32m✓ Saved to $EM_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "search" ]]; then
  SYSTEM="${2:-our app}"
  SR_DIR="$HOME/.blackroad/carpool/search"
  mkdir -p "$SR_DIR"
  SR_FILE="$SR_DIR/search-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔍 CarPool — Search architecture for: $SYSTEM\033[0m"
  echo "# Search Architecture: $SYSTEM" > "$SR_FILE"
  echo "Generated: $(date)" >> "$SR_FILE"
  PY_SR='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","What search stack fits $SYSTEM: Elasticsearch, Typesense, Meilisearch, Postgres FTS, or vector search? Compare tradeoffs for our scale."),
  ("PRISM","Analyst","What are the top 10 search queries users will run in $SYSTEM? How do these shape index design, ranking, and facets?"),
  ("ALICE","PM","What search UX features must $SYSTEM have at launch vs later: autocomplete, typo tolerance, filters, synonyms, personalization?"),
  ("ARIA","UX","Design the search experience for $SYSTEM: empty state, no-results state, loading state, result card anatomy, and query highlighting."),
  ("SHELLFISH","Performance","What are the query performance and index size risks as $SYSTEM search scales to 10M documents? How do we stay under 100ms p99?")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_SR" "$SYSTEM" | tee -a "$SR_FILE"
  echo -e "\033[0;32m✓ Saved to $SR_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "devex" ]]; then
  TOOL="${2:-our developer tools}"
  DX_DIR="$HOME/.blackroad/carpool/devex"
  mkdir -p "$DX_DIR"
  DX_FILE="$DX_DIR/devex-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🛠️  CarPool — Developer experience review: $TOOL\033[0m"
  echo "# Developer Experience: $TOOL" > "$DX_FILE"
  echo "Generated: $(date)" >> "$DX_FILE"
  PY_DX='
import sys, json, urllib.request
tool = sys.argv[1]
agents = [
  ("ARIA","DX designer","Audit the developer experience of $TOOL. What are the top 5 friction points from first install to first successful use?"),
  ("ALICE","PM","What does a great day-1 experience look like for $TOOL? Map the ideal path: discover, install, hello world, first real use — with time targets for each."),
  ("OCTAVIA","Engineer","What local dev setup improvements would make $TOOL faster to work with: hot reload, better error messages, local mocking, faster builds?"),
  ("LUCIDIA","Educator","What learning curve does $TOOL create for new developers? Where do people get stuck and what docs, examples, or interactive guides would help most?"),
  ("PRISM","Analyst","How do we measure DX quality for $TOOL? What metrics — time-to-hello-world, docs search success rate, GitHub issue sentiment — tell us if we are improving?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'TOOL', tool)}"
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
  python3 -c "$PY_DX" "$TOOL" | tee -a "$DX_FILE"
  echo -e "\033[0;32m✓ Saved to $DX_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "multitenancy" ]]; then
  PRODUCT="${2:-our platform}"
  MT_DIR="$HOME/.blackroad/carpool/multitenancy"
  mkdir -p "$MT_DIR"
  MT_FILE="$MT_DIR/multitenant-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🏢 CarPool — Multi-tenancy design: $PRODUCT\033[0m"
  echo "# Multi-Tenancy: $PRODUCT" > "$MT_FILE"
  echo "Generated: $(date)" >> "$MT_FILE"
  PY_MT='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","Compare the 3 multi-tenancy models for $PRODUCT: shared DB with tenant_id, schema-per-tenant, and DB-per-tenant. Recommend one with rationale."),
  ("CIPHER","Security","What are the top tenant isolation risks in $PRODUCT? How do we prevent cross-tenant data leakage at the DB, cache, file storage, and API layers?"),
  ("ALICE","PM","How does $PRODUCT handle tenant onboarding, offboarding, and data export? Define the lifecycle and whose responsibility each step is."),
  ("PRISM","Analyst","How do we monitor per-tenant usage, performance, and cost in $PRODUCT? What dashboards help us spot a noisy neighbor or runaway tenant?"),
  ("SHELLFISH","Chaos","Design 3 tenant isolation breach scenarios for $PRODUCT and the detection + response steps for each.")
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
  python3 -c "$PY_MT" "$PRODUCT" | tee -a "$MT_FILE"
  echo -e "\033[0;32m✓ Saved to $MT_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "queuing" ]]; then
  SYSTEM="${2:-our workers}"
  QU_DIR="$HOME/.blackroad/carpool/queuing"
  mkdir -p "$QU_DIR"
  QU_FILE="$QU_DIR/queue-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📬 CarPool — Queue and worker design: $SYSTEM\033[0m"
  echo "# Queue Design: $SYSTEM" > "$QU_FILE"
  echo "Generated: $(date)" >> "$QU_FILE"
  PY_QU='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","Design the queue architecture for $SYSTEM: which broker (Redis, SQS, RabbitMQ, Kafka), how many queues, priority lanes, and dead-letter handling."),
  ("ALICE","Engineer","Write the job schema for $SYSTEM workers: required fields, idempotency key, retry policy, timeout, and payload size limits."),
  ("PRISM","Analyst","What metrics should we track for $SYSTEM queues: queue depth, processing latency, failure rate, DLQ size? What thresholds trigger alerts?"),
  ("SHELLFISH","Chaos","What happens to $SYSTEM when workers crash mid-job, the broker goes down, or a poison-pill job loops forever? Design recovery for each."),
  ("CIPHER","Security","What security controls does $SYSTEM need: job payload encryption, worker auth, preventing job injection, and auditing sensitive job types?")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_QU" "$SYSTEM" | tee -a "$QU_FILE"
  echo -e "\033[0;32m✓ Saved to $QU_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "crisis" ]]; then
  SITUATION="${2:-a public outage}"
  CR_DIR="$HOME/.blackroad/carpool/crisis"
  mkdir -p "$CR_DIR"
  CR_FILE="$CR_DIR/crisis-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🚨 CarPool — Crisis comms plan: $SITUATION\033[0m"
  echo "# Crisis Plan: $SITUATION" > "$CR_FILE"
  echo "Generated: $(date)" >> "$CR_FILE"
  PY_CR='
import sys, json, urllib.request
situation = sys.argv[1]
agents = [
  ("ARIA","Comms","Write the first public statement for $SITUATION — post within 30 minutes. Acknowledge, show empathy, commit to update. Under 100 words."),
  ("ALICE","Ops","What is the internal war room setup for $SITUATION? Who is in the bridge, what roles, communication channel, and update cadence?"),
  ("LUCIDIA","Strategist","What is the narrative arc we want to own for $SITUATION? How do we move from victim to in-control to trusted in 3 communication phases?"),
  ("CIPHER","Legal","What must we NOT say during $SITUATION for legal and liability reasons? What phrasing is safe vs risky in public statements?"),
  ("PRISM","Analyst","After $SITUATION resolves, how do we measure the reputational and business impact? What signals tell us trust is recovering or still declining?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'SITUATION', situation)}"
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
  python3 -c "$PY_CR" "$SITUATION" | tee -a "$CR_FILE"
  echo -e "\033[0;32m✓ Saved to $CR_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "testplan" ]]; then
  FEATURE="${2:-the feature}"
  TP_DIR="$HOME/.blackroad/carpool/testplans"
  mkdir -p "$TP_DIR"
  TP_FILE="$TP_DIR/testplan-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🧪 CarPool — Test plan for: $FEATURE\033[0m"
  echo "# Test Plan: $FEATURE" > "$TP_FILE"
  echo "Generated: $(date)" >> "$TP_FILE"
  PY_TP='
import sys, json, urllib.request
feature = sys.argv[1]
agents = [
  ("OCTAVIA","QA Architect","Design the test pyramid for $FEATURE: how many unit, integration, e2e, and contract tests? What tools for each layer?"),
  ("ALICE","Engineer","Write 8 specific test cases for $FEATURE covering happy path, edge cases, and error conditions. Include inputs and expected outputs."),
  ("SHELLFISH","Chaos tester","What adversarial and negative test cases does $FEATURE need? List 5 ways a user or attacker could break it."),
  ("PRISM","Analyst","What test coverage metrics matter for $FEATURE? What is the minimum acceptable coverage and how do we enforce it in CI?"),
  ("CIPHER","Security tester","What security-specific test cases does $FEATURE need: auth bypass attempts, injection, privilege escalation, data leakage scenarios?")
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
  python3 -c "$PY_TP" "$FEATURE" | tee -a "$TP_FILE"
  echo -e "\033[0;32m✓ Saved to $TP_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "auth" ]]; then
  SYSTEM="${2:-our app}"
  AUTH_DIR="$HOME/.blackroad/carpool/auth"
  mkdir -p "$AUTH_DIR"
  AUTH_FILE="$AUTH_DIR/auth-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔐 CarPool — Auth design for: $SYSTEM\033[0m"
  echo "# Auth Design: $SYSTEM" > "$AUTH_FILE"
  echo "Generated: $(date)" >> "$AUTH_FILE"
  PY_AUTH='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("CIPHER","Security","Design the complete auth architecture for $SYSTEM: which flows (password, OAuth, SSO, magic link, passkey)? Token strategy — JWT vs opaque, refresh rotation, revocation."),
  ("OCTAVIA","Architect","How should $SYSTEM handle auth at the infrastructure layer: API gateway auth, service-to-service tokens, and secret rotation?"),
  ("ALICE","PM","What auth options should $SYSTEM offer at each plan tier? What are the enterprise SSO requirements and how do we scope that work?"),
  ("SHELLFISH","Attacker","What are the top 5 ways an attacker would try to break auth in $SYSTEM: session fixation, token theft, brute force, OAuth misconfig, privilege escalation?"),
  ("ARIA","UX","Design the sign-in and sign-up experience for $SYSTEM. What friction is acceptable vs where do we lose users? How do we handle MFA without annoying everyone?")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_AUTH" "$SYSTEM" | tee -a "$AUTH_FILE"
  echo -e "\033[0;32m✓ Saved to $AUTH_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "webhook" ]]; then
  SERVICE="${2:-our platform}"
  WH_DIR="$HOME/.blackroad/carpool/webhooks"
  mkdir -p "$WH_DIR"
  WH_FILE="$WH_DIR/webhook-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔗 CarPool — Webhook system for: $SERVICE\033[0m"
  echo "# Webhook Design: $SERVICE" > "$WH_FILE"
  echo "Generated: $(date)" >> "$WH_FILE"
  PY_WH='
import sys, json, urllib.request
service = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","Design the webhook delivery system for $SERVICE: event catalog, payload schema, delivery guarantees, retry policy with backoff, and ordering semantics."),
  ("CIPHER","Security","How do we secure webhooks in $SERVICE: HMAC signature verification, IP allowlisting, TLS enforcement, replay attack prevention, and secret rotation?"),
  ("ALICE","PM","What webhook management UX does $SERVICE need: endpoint registration, event filtering, delivery logs, retry UI, and testing tools?"),
  ("SHELLFISH","Chaos","What failure modes does the $SERVICE webhook system need to handle: slow receivers, bad SSL certs, 5xx loops, DNS failures, and thundering herd on large events?"),
  ("PRISM","Analyst","What webhook delivery metrics should $SERVICE track: success rate, p99 latency, retry rate, DLQ depth? What SLOs make sense?")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_WH" "$SERVICE" | tee -a "$WH_FILE"
  echo -e "\033[0;32m✓ Saved to $WH_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "product-hunt" ]]; then
  PRODUCT="${2:-our product}"
  PH_DIR="$HOME/.blackroad/carpool/product-hunt"
  mkdir -p "$PH_DIR"
  PH_FILE="$PH_DIR/ph-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🐱 CarPool — Product Hunt launch: $PRODUCT\033[0m"
  echo "# Product Hunt Launch: $PRODUCT" > "$PH_FILE"
  echo "Generated: $(date)" >> "$PH_FILE"
  PY_PH='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("ARIA","Marketer","Write the Product Hunt tagline (under 60 chars) and description (under 260 chars) for $PRODUCT. Make it punchy and benefit-led."),
  ("LUCIDIA","Storyteller","Write the maker comment for $PRODUCT PH launch — the personal story of why we built it. Under 200 words, warm and authentic."),
  ("ALICE","PM","What is the pre-launch checklist for $PRODUCT on Product Hunt? Timeline, hunter outreach, asset prep, community warm-up, and day-of schedule."),
  ("PRISM","Analyst","What makes a PH launch succeed for a product like $PRODUCT? What vote count, comment engagement, and traffic targets should we aim for?"),
  ("SHELLFISH","Hacker","What are the launch day tactics for $PRODUCT that push votes without violating PH rules: timing, communities to notify, follow-up comment strategy?")
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
  python3 -c "$PY_PH" "$PRODUCT" | tee -a "$PH_FILE"
  echo -e "\033[0;32m✓ Saved to $PH_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "oss" ]]; then
  PROJECT="${2:-our project}"
  OSS_DIR="$HOME/.blackroad/carpool/oss"
  mkdir -p "$OSS_DIR"
  OSS_FILE="$OSS_DIR/oss-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🌍 CarPool — Open source strategy: $PROJECT\033[0m"
  echo "# Open Source Strategy: $PROJECT" > "$OSS_FILE"
  echo "Generated: $(date)" >> "$OSS_FILE"
  PY_OSS='
import sys, json, urllib.request
project = sys.argv[1]
agents = [
  ("LUCIDIA","Strategist","Should $PROJECT be open-sourced, open-core, or stay closed? Lay out the business case for each and make a recommendation."),
  ("ALICE","PM","If we open-source $PROJECT, what is the contributor experience? Write the CONTRIBUTING.md outline, issue templates, and first-good-issue strategy."),
  ("CIPHER","Legal","What license fits $PROJECT best: MIT, Apache 2, AGPL, BSL? What are the tradeoffs for each in terms of commercial protection and community adoption?"),
  ("PRISM","Growth","How does open-sourcing $PROJECT drive business growth? What community metrics — stars, contributors, forks, Discord members — matter and how do we grow them?"),
  ("OCTAVIA","Maintainer","What is the maintenance burden of open-sourcing $PROJECT? Triage load, CI costs, security disclosure process, and how to avoid maintainer burnout?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'PROJECT', project)}"
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
  python3 -c "$PY_OSS" "$PROJECT" | tee -a "$OSS_FILE"
  echo -e "\033[0;32m✓ Saved to $OSS_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "gdpr" ]]; then
  PRODUCT="${2:-our product}"
  GDPR_DIR="$HOME/.blackroad/carpool/gdpr"
  mkdir -p "$GDPR_DIR"
  GDPR_FILE="$GDPR_DIR/gdpr-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🇪🇺 CarPool — GDPR compliance plan: $PRODUCT\033[0m"
  echo "# GDPR Plan: $PRODUCT" > "$GDPR_FILE"
  echo "Generated: $(date)" >> "$GDPR_FILE"
  PY_GDPR='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("CIPHER","Legal/Privacy","Map the personal data flows in $PRODUCT: what data is collected, where stored, how long retained, and what legal basis applies to each?"),
  ("ALICE","PM","Write the GDPR compliance checklist for $PRODUCT: consent banners, privacy policy, data deletion flow, DPA agreements, breach notification process."),
  ("OCTAVIA","Engineer","What technical controls does $PRODUCT need for GDPR: data encryption at rest, anonymization, audit logs, right-to-erasure implementation?"),
  ("SHELLFISH","Risk","What are the top 3 GDPR violation risks in $PRODUCT and the maximum fine exposure for each? What are the quick wins to reduce that risk?"),
  ("PRISM","Analyst","How do we maintain ongoing GDPR compliance in $PRODUCT? What quarterly audit, DPA reviews, and training processes keep us clean?")
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
  python3 -c "$PY_GDPR" "$PRODUCT" | tee -a "$GDPR_FILE"
  echo -e "\033[0;32m✓ Saved to $GDPR_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "mobile" ]]; then
  FEATURE="${2:-our app}"
  MOB_DIR="$HOME/.blackroad/carpool/mobile"
  mkdir -p "$MOB_DIR"
  MOB_FILE="$MOB_DIR/mobile-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📱 CarPool — Mobile strategy: $FEATURE\033[0m"
  echo "# Mobile Strategy: $FEATURE" > "$MOB_FILE"
  echo "Generated: $(date)" >> "$MOB_FILE"
  PY_MOB='
import sys, json, urllib.request
feature = sys.argv[1]
agents = [
  ("ARIA","Mobile UX","What are the top 5 mobile-specific UX patterns $FEATURE needs: gestures, bottom sheets, haptics, offline state, push notifications?"),
  ("OCTAVIA","Engineer","Native vs cross-platform for $FEATURE: compare React Native, Flutter, Swift/Kotlin. Which fits our team and requirements best?"),
  ("ALICE","PM","What is the MVP mobile feature set for $FEATURE? What desktop features stay web-only and why? How do we sequence the mobile roadmap?"),
  ("PRISM","Analyst","What mobile metrics matter for $FEATURE: DAU, session length, crash rate, ANR rate, app store rating? What benchmarks should we target?"),
  ("CIPHER","Security","What mobile-specific security risks does $FEATURE have: certificate pinning, local data storage, screenshot prevention, jailbreak detection, deep link hijacking?")
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
  python3 -c "$PY_MOB" "$FEATURE" | tee -a "$MOB_FILE"
  echo -e "\033[0;32m✓ Saved to $MOB_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "design-system" ]]; then
  BRAND="${2:-our brand}"
  DS_DIR="$HOME/.blackroad/carpool/design-systems"
  mkdir -p "$DS_DIR"
  DS_FILE="$DS_DIR/design-system-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🎨 CarPool — Design system for: $BRAND\033[0m"
  echo "# Design System: $BRAND" > "$DS_FILE"
  echo "Generated: $(date)" >> "$DS_FILE"
  PY_DS='
import sys, json, urllib.request
brand = sys.argv[1]
agents = [
  ("ARIA","Design lead","Define the core design tokens for $BRAND: color palette (primitive + semantic), typography scale, spacing system, border radius, and shadow levels."),
  ("LUCIDIA","Brand","What is the visual personality of $BRAND? Write 5 design principles that should guide every component and layout decision."),
  ("OCTAVIA","Engineer","How do we build and distribute the $BRAND design system: monorepo structure, Storybook, versioning, CSS-in-JS vs CSS variables, and token pipeline?"),
  ("ALICE","PM","What is the component priority order for $BRAND design system v1? List top 20 components ranked by usage frequency and shared value."),
  ("PRISM","Analyst","How do we measure design system adoption and health for $BRAND? What metrics — component coverage, drift rate, contributor count — tell us it is working?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'BRAND', brand)}"
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
  python3 -c "$PY_DS" "$BRAND" | tee -a "$DS_FILE"
  echo -e "\033[0;32m✓ Saved to $DS_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "agents-plan" ]]; then
  TASK="${2:-automate our workflow}"
  AP_DIR="$HOME/.blackroad/carpool/agents-plans"
  mkdir -p "$AP_DIR"
  AP_FILE="$AP_DIR/agents-plan-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🤖 CarPool — AI agents plan: $TASK\033[0m"
  echo "# AI Agents Plan: $TASK" > "$AP_FILE"
  echo "Generated: $(date)" >> "$AP_FILE"
  PY_AP='
import sys, json, urllib.request
task = sys.argv[1]
agents = [
  ("LUCIDIA","Architect","Design a multi-agent system to $TASK. What agents are needed, what is each one responsible for, and how do they hand off to each other?"),
  ("OCTAVIA","Engineer","What infrastructure does the agent system for $TASK need: orchestration layer, memory store, tool registry, and observability?"),
  ("ALICE","PM","What is the human-in-the-loop strategy for the $TASK agent system? Which decisions require approval and what is the escalation path?"),
  ("CIPHER","Security","What are the top 3 security risks of autonomous agents doing $TASK: prompt injection, tool misuse, data exfiltration? How do we constrain them?"),
  ("PRISM","Analyst","How do we evaluate if the agent system for $TASK is working? What success metrics, evals, and failure modes do we track?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'TASK', task)}"
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
  python3 -c "$PY_AP" "$TASK" | tee -a "$AP_FILE"
  echo -e "\033[0;32m✓ Saved to $AP_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "landing" ]]; then
  PRODUCT="${2:-our product}"
  LND_DIR="$HOME/.blackroad/carpool/landing"
  mkdir -p "$LND_DIR"
  LND_FILE="$LND_DIR/landing-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🌐 CarPool — Landing page for: $PRODUCT\033[0m"
  echo "# Landing Page: $PRODUCT" > "$LND_FILE"
  echo "Generated: $(date)" >> "$LND_FILE"
  PY_LND='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("ARIA","Copywriter","Write the hero section for $PRODUCT: headline (under 10 words), subheadline (under 20 words), and CTA button text. Give 3 variants from bold to subtle."),
  ("LUCIDIA","Storyteller","What is the narrative structure for the $PRODUCT landing page? Map each section: hero, problem, solution, social proof, features, pricing, FAQ, final CTA."),
  ("ALICE","PM","What are the top 5 objections a visitor has when landing on the $PRODUCT page? Write the one-sentence answer to each that belongs on the page."),
  ("PRISM","Analyst","What A/B tests should we run on the $PRODUCT landing page first? Rank by expected lift: headline, CTA, social proof placement, pricing visibility."),
  ("SHELLFISH","Hacker","Audit the $PRODUCT landing page for conversion leaks: slow load, unclear value prop, too many CTAs, missing trust signals, bad mobile experience.")
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
  python3 -c "$PY_LND" "$PRODUCT" | tee -a "$LND_FILE"
  echo -e "\033[0;32m✓ Saved to $LND_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "database" ]]; then
  SYSTEM="${2:-our app}"
  DB_DIR="$HOME/.blackroad/carpool/databases"
  mkdir -p "$DB_DIR"
  DB_FILE="$DB_DIR/database-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🗄️  CarPool — Database design: $SYSTEM\033[0m"
  echo "# Database Design: $SYSTEM" > "$DB_FILE"
  echo "Generated: $(date)" >> "$DB_FILE"
  PY_DB='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("OCTAVIA","DBA","What database engine fits $SYSTEM best: Postgres, MySQL, SQLite, MongoDB, DynamoDB, or a hybrid? Compare on: query patterns, scale, ops burden, cost."),
  ("ALICE","Engineer","Design the core schema for $SYSTEM. List the top 5 tables/collections, their key fields, relationships, and indexes needed for the most common queries."),
  ("PRISM","Analyst","What query performance risks will $SYSTEM face at 10x data volume? Which queries will become table scans and how do we fix them now?"),
  ("CIPHER","Security","What database security controls does $SYSTEM need: row-level security, encrypted columns, connection pooling limits, audit logging, and backup encryption?"),
  ("SHELLFISH","Chaos","What happens to $SYSTEM when the primary DB goes down, a migration runs long, or a query takes 30 seconds? Design the resilience strategy.")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_DB" "$SYSTEM" | tee -a "$DB_FILE"
  echo -e "\033[0;32m✓ Saved to $DB_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "social" ]]; then
  BRAND="${2:-our brand}"
  SOC_DIR="$HOME/.blackroad/carpool/social"
  mkdir -p "$SOC_DIR"
  SOC_FILE="$SOC_DIR/social-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📣 CarPool — Social media strategy: $BRAND\033[0m"
  echo "# Social Strategy: $BRAND" > "$SOC_FILE"
  echo "Generated: $(date)" >> "$SOC_FILE"
  PY_SOC='
import sys, json, urllib.request
brand = sys.argv[1]
agents = [
  ("ARIA","Social strategist","What platforms should $BRAND prioritize and why? For each: content type, posting frequency, tone, and audience it reaches."),
  ("LUCIDIA","Storyteller","Write a 1-week content calendar for $BRAND: 7 post ideas across platforms, each with a hook, body, and CTA. Mix educational, entertainment, and promotional."),
  ("ALICE","PM","What is the social media workflow for $BRAND: who creates, who approves, what tools, what response time SLA for comments and DMs?"),
  ("PRISM","Analyst","What social metrics actually matter for $BRAND growth? Beyond vanity metrics — what engagement signals predict pipeline or community health?"),
  ("SHELLFISH","Risk","What are the top 3 social media risks for $BRAND: PR crisis, account compromise, employee posts, competitor trolling? Prepare response playbooks.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'BRAND', brand)}"
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
  python3 -c "$PY_SOC" "$BRAND" | tee -a "$SOC_FILE"
  echo -e "\033[0;32m✓ Saved to $SOC_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "infra-cost" ]]; then
  STACK="${2:-our cloud stack}"
  IC_DIR="$HOME/.blackroad/carpool/infra-costs"
  mkdir -p "$IC_DIR"
  IC_FILE="$IC_DIR/infra-cost-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m💸 CarPool — Infrastructure cost review: $STACK\033[0m"
  echo "# Infra Cost Review: $STACK" > "$IC_FILE"
  echo "Generated: $(date)" >> "$IC_FILE"
  PY_IC='
import sys, json, urllib.request
stack = sys.argv[1]
agents = [
  ("PRISM","FinOps","Break down the monthly cost of $STACK by service. What is the estimated spend for compute, storage, network egress, and managed services?"),
  ("OCTAVIA","Platform","What are the top 3 over-provisioned resources in $STACK? Give concrete right-sizing recommendations with estimated monthly savings each."),
  ("ALICE","DevOps","What cost allocation tags and budget alerts should we set up for $STACK to catch runaway spending before it hits the bill?"),
  ("SHELLFISH","Risk","What are the runaway cost scenarios in $STACK: auto-scaling without caps, data transfer loops, orphaned resources, log explosion? How do we cap each?"),
  ("LUCIDIA","Strategist","At what monthly spend does $STACK justify moving to reserved instances, committed use discounts, or a multi-cloud arbitrage strategy?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'STACK', stack)}"
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
  python3 -c "$PY_IC" "$STACK" | tee -a "$IC_FILE"
  echo -e "\033[0;32m✓ Saved to $IC_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "pitch-deck" ]]; then
  COMPANY="${2:-our startup}"
  PD_DIR="$HOME/.blackroad/carpool/pitch-decks"
  mkdir -p "$PD_DIR"
  PD_FILE="$PD_DIR/pitch-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📊 CarPool — Pitch deck outline: $COMPANY\033[0m"
  echo "# Pitch Deck: $COMPANY" > "$PD_FILE"
  echo "Generated: $(date)" >> "$PD_FILE"
  PY_PD='
import sys, json, urllib.request
company = sys.argv[1]
agents = [
  ("LUCIDIA","Storyteller","Write the narrative arc for $COMPANY pitch deck: 10 slides in order, each with a title, the one thing it must convey, and the emotional beat it hits."),
  ("PRISM","Analyst","What are the 5 most important numbers $COMPANY must show investors: TAM, traction metric, unit economics, growth rate, and burn multiple? Define each clearly."),
  ("ARIA","Designer","What visual and layout principles make a pitch deck for $COMPANY land? Slides to avoid, density rules, use of white space, and the one-chart-per-slide rule."),
  ("ALICE","PM","What are the top 5 hard questions investors will ask $COMPANY after the pitch? Write a crisp 2-sentence answer to each."),
  ("SHELLFISH","Skeptic","What are the 3 biggest weaknesses in the $COMPANY story that a sharp investor will poke at? How do we address them head-on in the deck rather than hiding them?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'COMPANY', company)}"
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
  python3 -c "$PY_PD" "$COMPANY" | tee -a "$PD_FILE"
  echo -e "\033[0;32m✓ Saved to $PD_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "cicd" ]]; then
  PROJECT="${2:-our project}"
  CI_DIR="$HOME/.blackroad/carpool/cicd"
  mkdir -p "$CI_DIR"
  CI_FILE="$CI_DIR/cicd-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m⚙️  CarPool — CI/CD pipeline: $PROJECT\033[0m"
  echo "# CI/CD Pipeline: $PROJECT" > "$CI_FILE"
  echo "Generated: $(date)" >> "$CI_FILE"
  PY_CI='
import sys, json, urllib.request
project = sys.argv[1]
agents = [
  ("OCTAVIA","Platform","Design the full CI/CD pipeline for $PROJECT: stages (lint, test, build, scan, deploy), tools for each stage, and target pipeline time under 10 minutes."),
  ("ALICE","DevOps","What branch strategy and deployment promotion model fits $PROJECT: trunk-based, GitFlow, environment promotion (dev→staging→prod)? Define the rules."),
  ("CIPHER","Security","What security gates must exist in the $PROJECT pipeline: SAST, dependency scan, secret detection, container scanning, and SBOM generation?"),
  ("SHELLFISH","Chaos","What happens to $PROJECT when CI is flaky, a deployment gets stuck mid-rollout, or a bad commit slips through? Define the automated safety nets."),
  ("PRISM","Analyst","What CI/CD metrics should $PROJECT track: deployment frequency, lead time, MTTR, change failure rate. What are good DORA benchmarks to aim for?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'PROJECT', project)}"
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
  python3 -c "$PY_CI" "$PROJECT" | tee -a "$CI_FILE"
  echo -e "\033[0;32m✓ Saved to $CI_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "microservices" ]]; then
  SYSTEM="${2:-our monolith}"
  MS_DIR="$HOME/.blackroad/carpool/microservices"
  mkdir -p "$MS_DIR"
  MS_FILE="$MS_DIR/microservices-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🔬 CarPool — Microservices design: $SYSTEM\033[0m"
  echo "# Microservices: $SYSTEM" > "$MS_FILE"
  echo "Generated: $(date)" >> "$MS_FILE"
  PY_MS='
import sys, json, urllib.request
system = sys.argv[1]
agents = [
  ("OCTAVIA","Architect","How should $SYSTEM be decomposed into microservices? Identify the bounded contexts and define the service boundaries using domain-driven design."),
  ("LUCIDIA","Strategist","Should $SYSTEM split into microservices now or stay monolith longer? Make the case for each path with honest tradeoffs and a decision framework."),
  ("ALICE","DevOps","What operational complexity does splitting $SYSTEM add: service discovery, distributed tracing, inter-service auth, and versioned contracts? How do we manage each?"),
  ("CIPHER","Security","What new attack surface does a microservices split create for $SYSTEM: lateral movement, service mesh auth, noisy logs hiding intrusions? How do we defend?"),
  ("SHELLFISH","Chaos","Design a chaos experiment that validates the $SYSTEM microservices split is resilient: which service to take down, expected cascade behavior, and recovery validation.")
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
  except:
    print(f"### {name}: [offline]\n")
'
  python3 -c "$PY_MS" "$SYSTEM" | tee -a "$MS_FILE"
  echo -e "\033[0;32m✓ Saved to $MS_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "community" ]]; then
  PRODUCT="${2:-our product}"
  COM_DIR="$HOME/.blackroad/carpool/community"
  mkdir -p "$COM_DIR"
  COM_FILE="$COM_DIR/community-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🫂 CarPool — Community building: $PRODUCT\033[0m"
  echo "# Community Strategy: $PRODUCT" > "$COM_FILE"
  echo "Generated: $(date)" >> "$COM_FILE"
  PY_COM='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("ARIA","Community lead","What community platform fits $PRODUCT best: Discord, Slack, Circle, GitHub Discussions, or forum? Design the channel/category structure for launch."),
  ("LUCIDIA","Philosopher","What is the deeper shared identity and purpose that will make the $PRODUCT community magnetic, not just transactional?"),
  ("ALICE","PM","What is the community flywheel for $PRODUCT: how does community activity drive product growth, and product growth drive community? Map the loop."),
  ("PRISM","Analyst","What community health metrics matter for $PRODUCT: DAU, contributor ratio, question answer rate, churn. What early signals predict a thriving vs dying community?"),
  ("SHELLFISH","Risk","What are the top 3 community failure modes for $PRODUCT: toxicity, spam, cliques, founder dependency? Write the moderation policy for each.")
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
  python3 -c "$PY_COM" "$PRODUCT" | tee -a "$COM_FILE"
  echo -e "\033[0;32m✓ Saved to $COM_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "ai-feature" ]]; then
  IDEA="${2:-our product}"
  AIF_DIR="$HOME/.blackroad/carpool/ai-features"
  mkdir -p "$AIF_DIR"
  AIF_FILE="$AIF_DIR/ai-feature-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🧠 CarPool — AI feature design: $IDEA\033[0m"
  echo "# AI Feature: $IDEA" > "$AIF_FILE"
  echo "Generated: $(date)" >> "$AIF_FILE"
  PY_AIF='
import sys, json, urllib.request
idea = sys.argv[1]
agents = [
  ("LUCIDIA","AI Designer","What is the right AI interaction model for $IDEA: copilot, autopilot, or suggester? Design the human-AI collaboration loop and when AI acts vs waits."),
  ("OCTAVIA","ML Engineer","What model architecture fits $IDEA: fine-tuned LLM, RAG, classifier, embeddings, or rules+ML hybrid? What training data do we need?"),
  ("ALICE","PM","What is the smallest AI slice of $IDEA we can ship in sprint 1 that proves value? Define the MVP, success metric, and user feedback loop."),
  ("CIPHER","Safety","What are the AI safety and trust risks in $IDEA: hallucination, bias, data leakage, adversarial input? What guardrails and human overrides are mandatory?"),
  ("PRISM","Analyst","How do we evaluate if the $IDEA AI feature is actually helping users? What offline evals, A/B tests, and user satisfaction signals prove it is working?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'IDEA', idea)}"
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
  python3 -c "$PY_AIF" "$IDEA" | tee -a "$AIF_FILE"
  echo -e "\033[0;32m✓ Saved to $AIF_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "support" ]]; then
  PRODUCT="${2:-our product}"
  SUP_DIR="$HOME/.blackroad/carpool/support"
  mkdir -p "$SUP_DIR"
  SUP_FILE="$SUP_DIR/support-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🎧 CarPool — Support strategy: $PRODUCT\033[0m"
  echo "# Support Strategy: $PRODUCT" > "$SUP_FILE"
  echo "Generated: $(date)" >> "$SUP_FILE"
  PY_SUP='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("ARIA","CX lead","Design the support tiers for $PRODUCT: what is self-serve (docs, chatbot), community, email, and priority support? Who gets each tier?"),
  ("ALICE","PM","What are the top 10 support tickets $PRODUCT will receive? For each: root cause, whether it is a docs fix, product fix, or training issue."),
  ("PRISM","Analyst","What support metrics matter for $PRODUCT: CSAT, FRT, resolution time, ticket volume per MAU, deflection rate? What benchmarks should we hit?"),
  ("LUCIDIA","Strategist","How do we use $PRODUCT support data as a product intelligence goldmine? What patterns in tickets should feed directly into the roadmap?"),
  ("OCTAVIA","Engineer","What support tooling stack fits $PRODUCT: help desk, chatbot, status page, in-app guidance, and feedback widget? How do they connect?")
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
  python3 -c "$PY_SUP" "$PRODUCT" | tee -a "$SUP_FILE"
  echo -e "\033[0;32m✓ Saved to $SUP_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "gamification" ]]; then
  PRODUCT="${2:-our app}"
  GAM_DIR="$HOME/.blackroad/carpool/gamification"
  mkdir -p "$GAM_DIR"
  GAM_FILE="$GAM_DIR/gamification-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🎮 CarPool — Gamification design: $PRODUCT\033[0m"
  echo "# Gamification: $PRODUCT" > "$GAM_FILE"
  echo "Generated: $(date)" >> "$GAM_FILE"
  PY_GAM='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("ARIA","Game designer","Design the core gamification loop for $PRODUCT: what actions earn points/XP, what milestones unlock rewards, and what keeps the loop fresh after week 4?"),
  ("LUCIDIA","Psychologist","What intrinsic motivation levers does $PRODUCT gamification tap: mastery, progress, social status, collection? How do we avoid making it feel manipulative?"),
  ("PRISM","Analyst","How do we measure if $PRODUCT gamification is driving the right behavior vs just gaming the metrics? What guardrails prevent Goodhart corruption?"),
  ("ALICE","PM","What is the gamification MVP for $PRODUCT: the single mechanic we ship first that proves engagement lifts before we build the full system?"),
  ("SHELLFISH","Risk","What are the ways users will game the $PRODUCT gamification system: farming points, exploiting streaks, botting leaderboards? How do we design against each?")
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
  python3 -c "$PY_GAM" "$PRODUCT" | tee -a "$GAM_FILE"
  echo -e "\033[0;32m✓ Saved to $GAM_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "offboarding" ]]; then
  PRODUCT="${2:-our product}"
  OFF_DIR="$HOME/.blackroad/carpool/offboarding"
  mkdir -p "$OFF_DIR"
  OFF_FILE="$OFF_DIR/offboard-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m👋 CarPool — Offboarding flow: $PRODUCT\033[0m"
  echo "# Offboarding: $PRODUCT" > "$OFF_FILE"
  echo "Generated: $(date)" >> "$OFF_FILE"
  PY_OFF='
import sys, json, urllib.request
product = sys.argv[1]
agents = [
  ("ARIA","CX","Design the cancellation flow for $PRODUCT: what friction is ethical vs dark pattern? What last offer, what survey questions, and what confirmation UX?"),
  ("LUCIDIA","Strategist","How do we treat churned $PRODUCT users as future customers, not failures? What win-back sequence, exit survey use, and alumni community keeps the door open?"),
  ("ALICE","PM","What is the data export and account deletion flow for $PRODUCT? Map every step a user takes to get their data out or close their account completely."),
  ("PRISM","Analyst","What churn signals in $PRODUCT usage predict cancellation 30 days out? What intervention at each signal has the best save rate?"),
  ("CIPHER","Legal","What are the data retention and deletion legal obligations for $PRODUCT when a user offboards? GDPR right to erasure, CCPA, and contractual obligations?")
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
  python3 -c "$PY_OFF" "$PRODUCT" | tee -a "$OFF_FILE"
  echo -e "\033[0;32m✓ Saved to $OFF_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "rebranding" ]]; then
  COMPANY="${2:-our company}"
  RB_DIR="$HOME/.blackroad/carpool/rebranding"
  mkdir -p "$RB_DIR"
  RB_FILE="$RB_DIR/rebrand-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🎭 CarPool — Rebranding plan: $COMPANY\033[0m"
  echo "# Rebranding: $COMPANY" > "$RB_FILE"
  echo "Generated: $(date)" >> "$RB_FILE"
  PY_RB='
import sys, json, urllib.request
company = sys.argv[1]
agents = [
  ("ARIA","Brand designer","What should change vs stay the same in the $COMPANY rebrand? Map: logo, colors, typography, tone of voice, tagline — keep/evolve/replace for each."),
  ("LUCIDIA","Strategist","What is the strategic reason behind the $COMPANY rebrand? Write the internal narrative (why now) and the external narrative (what this signals to market)."),
  ("ALICE","PM","Build the $COMPANY rebrand rollout checklist: website, docs, social handles, email signatures, sales decks, swag, legal entity, press announcement — in order."),
  ("PRISM","Analyst","How do we measure if the $COMPANY rebrand is landing: brand awareness lift, sentiment shift, search volume, domain authority, press mentions?"),
  ("SHELLFISH","Risk","What can go wrong in the $COMPANY rebrand: SEO collapse, customer confusion, competitor swooping old name, domain squatters, employee resistance? Mitigate each.")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'COMPANY', company)}"
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
  python3 -c "$PY_RB" "$COMPANY" | tee -a "$RB_FILE"
  echo -e "\033[0;32m✓ Saved to $RB_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "technical-writing" ]]; then
  TOPIC="${2:-our API}"
  TW_DIR="$HOME/.blackroad/carpool/technical-writing"
  mkdir -p "$TW_DIR"
  TW_FILE="$TW_DIR/techwrite-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m✍️  CarPool — Technical writing guide: $TOPIC\033[0m"
  echo "# Technical Writing: $TOPIC" > "$TW_FILE"
  echo "Generated: $(date)" >> "$TW_FILE"
  PY_TW='
import sys, json, urllib.request
topic = sys.argv[1]
agents = [
  ("ARIA","Tech writer","Write the style guide for $TOPIC documentation: voice, tense, sentence length, heading style, code block rules, and 10 word pairs (use this / not that)."),
  ("ALICE","PM","What are the top 5 docs pages $TOPIC needs urgently? Rank by user impact and write a one-paragraph brief for each."),
  ("LUCIDIA","Educator","Take the most complex concept in $TOPIC and write it two ways: a 3-sentence ELI5 and a 200-word explanation for experienced developers."),
  ("OCTAVIA","Engineer","What code examples should every $TOPIC doc page include? Define the example structure: language, comments, output shown, error handling shown."),
  ("PRISM","Analyst","How do we run a docs quality audit for $TOPIC? What signals — broken links, search queries with no results, support tickets citing docs gaps — tell us what to fix?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'TOPIC', topic)}"
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
  python3 -c "$PY_TW" "$TOPIC" | tee -a "$TW_FILE"
  echo -e "\033[0;32m✓ Saved to $TW_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "network-design" ]]; then
  INFRA="${2:-our infrastructure}"
  ND_DIR="$HOME/.blackroad/carpool/network-design"
  mkdir -p "$ND_DIR"
  ND_FILE="$ND_DIR/network-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m🌐 CarPool — Network design: $INFRA\033[0m"
  echo "# Network Design: $INFRA" > "$ND_FILE"
  echo "Generated: $(date)" >> "$ND_FILE"
  PY_ND='
import sys, json, urllib.request
infra = sys.argv[1]
agents = [
  ("OCTAVIA","Network architect","Design the VPC/network topology for $INFRA: public subnets, private subnets, NAT gateways, peering, and egress rules. Draw it in ASCII."),
  ("CIPHER","Security","What network security controls does $INFRA need: security groups, NACLs, WAF, DDoS protection, private endpoints, and zero-trust segmentation?"),
  ("ALICE","DevOps","How do we manage $INFRA network config as code: Terraform modules, GitOps flow, change review process, and blast-radius limiting for network changes?"),
  ("SHELLFISH","Chaos","Design 3 network failure scenarios for $INFRA: AZ outage, misconfigured security group, BGP route leak. Expected impact and detection for each."),
  ("PRISM","Analyst","What network observability does $INFRA need: flow logs, latency metrics, bandwidth alerts, and anomaly detection for unusual traffic patterns?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'INFRA', infra)}"
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
  python3 -c "$PY_ND" "$INFRA" | tee -a "$ND_FILE"
  echo -e "\033[0;32m✓ Saved to $ND_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "acquisition" ]]; then
  CHANNEL="${2:-our growth channel}"
  ACQ_DIR="$HOME/.blackroad/carpool/acquisition"
  mkdir -p "$ACQ_DIR"
  ACQ_FILE="$ACQ_DIR/acquisition-$(date +%Y%m%d-%H%M%S).md"
  echo -e "\033[0;36m📈 CarPool — User acquisition strategy: $CHANNEL\033[0m"
  echo "# Acquisition Strategy: $CHANNEL" > "$ACQ_FILE"
  echo "Generated: $(date)" >> "$ACQ_FILE"
  PY_ACQ='
import sys, json, urllib.request
channel = sys.argv[1]
agents = [
  ("PRISM","Growth analyst","Model the unit economics of $CHANNEL: CAC, conversion rates at each funnel stage, payback period, and LTV:CAC ratio needed to be viable."),
  ("ALICE","PM","What is the 90-day experiment plan for $CHANNEL? Define 3 specific tests, their hypotheses, success metrics, and minimum budget to get signal."),
  ("ARIA","Marketer","What creative and messaging strategy works best for $CHANNEL? Describe the hook, format, audience targeting, and why this resonates."),
  ("SHELLFISH","Hacker","What are the unconventional or underutilized tactics in $CHANNEL that competitors are not doing yet? List 3 contrarian bets."),
  ("LUCIDIA","Strategist","How does $CHANNEL fit into the overall acquisition portfolio? What is the ideal channel mix at seed vs Series A vs growth stage?")
]
for name, role, question in agents:
  prompt = f"{name} ({role}): {question.replace(chr(36)+'CHANNEL', channel)}"
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
  python3 -c "$PY_ACQ" "$CHANNEL" | tee -a "$ACQ_FILE"
  echo -e "\033[0;32m✓ Saved to $ACQ_FILE\033[0m"
  exit 0
fi

if [[ "$1" == "retention" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("Growth" "Product" "Data" "Support" "Marketing")
  QUESTIONS=(
    "What are the top 3 reasons users leave $PRODUCT?"
    "Which retention levers (notifications, emails, in-app nudges) work best for $PRODUCT?"
    "What does a healthy retention curve look like for $PRODUCT and how do we achieve it?"
    "Design a win-back campaign for churned $PRODUCT users."
    "What product changes would most improve 30/60/90-day retention for $PRODUCT?"
  )
  echo ""
  echo "🔁 CARPOOL: USER RETENTION — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = '''You are the $agent expert. Answer concisely (3-5 sentences): ''' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Retention strategy roundtable complete."
  exit 0
fi

if [[ "$1" == "observability-stack" ]]; then
  SERVICE="${2:-our platform}"
  AGENTS=("Infra" "SRE" "Backend" "Security" "DevEx")
  QUESTIONS=(
    "What metrics matter most for observing $SERVICE in production?"
    "Design a logging strategy for $SERVICE: structured logs, levels, and retention."
    "How should we implement distributed tracing for $SERVICE?"
    "What alerting rules and on-call runbooks does $SERVICE need?"
    "Which observability tools (Prometheus, Grafana, Datadog, OpenTelemetry) fit $SERVICE best and why?"
  )
  echo ""
  echo "🔭 CARPOOL: OBSERVABILITY STACK — $SERVICE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = '''You are the $agent expert. Answer concisely (3-5 sentences): ''' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Observability stack design complete."
  exit 0
fi

if [[ "$1" == "founder-mode" ]]; then
  COMPANY="${2:-our startup}"
  AGENTS=("CEO" "Operator" "Advisor" "Investor" "Builder")
  QUESTIONS=(
    "When should the founder of $COMPANY stay in founder mode vs. delegate to managers?"
    "What are the biggest traps founders fall into when they stop being hands-on at $COMPANY?"
    "How does a founder maintain product intuition as $COMPANY scales past 50 people?"
    "What weekly rituals keep a founder close to the work without micromanaging at $COMPANY?"
    "What is the right balance between vision and execution for the founder of $COMPANY?"
  )
  echo ""
  echo "🧭 CARPOOL: FOUNDER MODE — $COMPANY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = '''You are the $agent expert. Answer concisely (3-5 sentences): ''' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Founder mode strategy complete."
  exit 0
fi

if [[ "$1" == "data-pipeline" ]]; then
  PIPELINE="${2:-our data pipeline}"
  AGENTS=("Data Eng" "Analytics" "Backend" "ML" "Infra")
  QUESTIONS=(
    "What sources feed $PIPELINE and how should ingestion be structured?"
    "ETL vs ELT — which approach fits $PIPELINE and why?"
    "How should $PIPELINE handle schema changes and late-arriving data?"
    "What monitoring and data quality checks are essential for $PIPELINE?"
    "Which tools (Airflow, dbt, Spark, Kafka, Flink) are right for $PIPELINE?"
  )
  echo ""
  echo "🔄 CARPOOL: DATA PIPELINE — $PIPELINE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = '''You are the $agent expert. Answer concisely (3-5 sentences): ''' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Data pipeline design complete."
  exit 0
fi

if [[ "$1" == "pricing-strategy" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("Pricing" "Sales" "Product" "Finance" "Competitor")
  QUESTIONS=(
    "What pricing model (usage, seat, flat, freemium) fits $PRODUCT best and why?"
    "How should $PRODUCT price for enterprise vs self-serve customers?"
    "What does the competitive pricing landscape look like for $PRODUCT?"
    "How do we anchor pricing and communicate value for $PRODUCT?"
    "When and how should $PRODUCT raise prices without losing customers?"
  )
  echo ""
  echo "💲 CARPOOL: PRICING STRATEGY — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Pricing strategy roundtable complete."
  exit 0
fi

if [[ "$1" == "api-design" ]]; then
  API="${2:-our API}"
  AGENTS=("API Architect" "Backend" "DevEx" "Security" "Consumer")
  QUESTIONS=(
    "What are the core design principles $API should follow (REST, GraphQL, gRPC)?"
    "How should $API handle versioning, deprecation, and backward compatibility?"
    "What authentication and authorization patterns are right for $API?"
    "Design the error response format and status code strategy for $API."
    "What makes $API a joy to use — rate limiting, pagination, docs, SDKs?"
  )
  echo ""
  echo "🔌 CARPOOL: API DESIGN — $API"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ API design roundtable complete."
  exit 0
fi

if [[ "$1" == "content-marketing" ]]; then
  BRAND="${2:-our brand}"
  AGENTS=("Content" "SEO" "Social" "Brand" "Growth")
  QUESTIONS=(
    "What content formats (blog, video, docs, newsletters) work best for $BRAND?"
    "How should $BRAND approach SEO content strategy for organic growth?"
    "Design a social media content calendar for $BRAND — cadence, channels, tone."
    "What thought leadership topics should $BRAND own in its space?"
    "How do we measure whether content is driving pipeline for $BRAND?"
  )
  echo ""
  echo "📝 CARPOOL: CONTENT MARKETING — $BRAND"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Content marketing strategy complete."
  exit 0
fi

if [[ "$1" == "incident-response" ]]; then
  SYSTEM="${2:-our system}"
  AGENTS=("SRE" "Engineering" "Comms" "Security" "Leadership")
  QUESTIONS=(
    "What does a P0/P1 incident response playbook look like for $SYSTEM?"
    "How should the on-call rotation and escalation ladder work for $SYSTEM?"
    "What does good internal communication look like during a $SYSTEM outage?"
    "How do we write a blameless postmortem after a $SYSTEM incident?"
    "What preventive measures reduce incident frequency for $SYSTEM?"
  )
  echo ""
  echo "🚨 CARPOOL: INCIDENT RESPONSE — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Incident response playbook complete."
  exit 0
fi

if [[ "$1" == "sales-playbook" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("Sales" "RevOps" "Marketing" "CS" "Founder")
  QUESTIONS=(
    "What does the ideal sales motion look like for $PRODUCT — inbound, outbound, PLG-assisted?"
    "Define the ICP and qualification criteria (MEDDIC/BANT) for $PRODUCT."
    "What are the top 3 objections prospects raise about $PRODUCT and how do we handle them?"
    "Design the demo flow and discovery call structure for $PRODUCT."
    "What does a repeatable, scalable sales playbook look like for $PRODUCT at 10 reps?"
  )
  echo ""
  echo "🤝 CARPOOL: SALES PLAYBOOK — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Sales playbook roundtable complete."
  exit 0
fi

if [[ "$1" == "devops-culture" ]]; then
  ORG="${2:-our engineering org}"
  AGENTS=("DevOps" "Engineering" "Leadership" "HR" "SRE")
  QUESTIONS=(
    "What are the core DevOps cultural shifts $ORG needs to make to ship faster?"
    "How do we break down silos between dev and ops in $ORG?"
    "What metrics (DORA) should $ORG track to measure DevOps maturity?"
    "How does $ORG build psychological safety for blameless culture?"
    "What does a DevOps transformation roadmap look like for $ORG over 12 months?"
  )
  echo ""
  echo "🏗️  CARPOOL: DEVOPS CULTURE — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ DevOps culture roundtable complete."
  exit 0
fi

if [[ "$1" == "product-led-growth" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("PLG" "Product" "Growth" "Sales" "Data")
  QUESTIONS=(
    "What PLG motions fit $PRODUCT — freemium, free trial, reverse trial?"
    "How should $PRODUCT define and optimize its activation moment?"
    "What in-product growth loops can $PRODUCT build to drive viral expansion?"
    "How does $PRODUCT know when a free user is ready to convert to paid (PQL)?"
    "How does $PRODUCT layer sales on top of PLG without killing the self-serve motion?"
  )
  echo ""
  echo "🚀 CARPOOL: PRODUCT-LED GROWTH — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Product-led growth strategy complete."
  exit 0
fi

if [[ "$1" == "chaos-engineering" ]]; then
  SYSTEM="${2:-our system}"
  AGENTS=("SRE" "Chaos" "Backend" "Infra" "Security")
  QUESTIONS=(
    "What are the riskiest failure modes in $SYSTEM we should test with chaos experiments?"
    "How do we run a gameday for $SYSTEM safely — scope, rollback, blast radius limits?"
    "Which chaos tools (Chaos Monkey, LitmusChaos, Gremlin) fit $SYSTEM best?"
    "How do we measure resilience improvements in $SYSTEM after chaos experiments?"
    "What steady-state hypotheses should we define before running chaos on $SYSTEM?"
  )
  echo ""
  echo "💥 CARPOOL: CHAOS ENGINEERING — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Chaos engineering plan complete."
  exit 0
fi

if [[ "$1" == "hiring-pipeline" ]]; then
  ROLE="${2:-engineering}"
  AGENTS=("Recruiter" "Hiring Mgr" "HR" "Candidate" "Culture")
  QUESTIONS=(
    "What does an efficient, bias-reduced hiring pipeline look like for $ROLE?"
    "What are the most predictive interview signals for $ROLE candidates?"
    "How do we write a job description that attracts top $ROLE talent?"
    "How should we structure the take-home vs live coding debate for $ROLE?"
    "What does a world-class candidate experience look like when hiring for $ROLE?"
  )
  echo ""
  echo "👥 CARPOOL: HIRING PIPELINE — $ROLE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Hiring pipeline roundtable complete."
  exit 0
fi

if [[ "$1" == "zero-to-one" ]]; then
  IDEA="${2:-our idea}"
  AGENTS=("Founder" "VC" "Customer" "Builder" "Skeptic")
  QUESTIONS=(
    "What makes $IDEA a zero-to-one insight rather than an incremental improvement?"
    "Who is the first customer for $IDEA and why would they take a bet on it today?"
    "What is the smallest possible version of $IDEA that proves the core thesis?"
    "What would have to be true for $IDEA to become a 10x better solution than anything existing?"
    "What are the strongest arguments against $IDEA and how do we stress-test them?"
  )
  echo ""
  echo "⚡ CARPOOL: ZERO TO ONE — $IDEA"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Zero-to-one analysis complete."
  exit 0
fi

if [[ "$1" == "platform-strategy" ]]; then
  PLATFORM="${2:-our platform}"
  AGENTS=("Platform" "Ecosystem" "BD" "Product" "Developer")
  QUESTIONS=(
    "What makes $PLATFORM a platform vs a product — where is the leverage?"
    "How should $PLATFORM attract and retain third-party developers and partners?"
    "What APIs, SDKs, and marketplace features does $PLATFORM need to win?"
    "How does $PLATFORM avoid the cold-start problem for its ecosystem?"
    "What governance model keeps $PLATFORM healthy as the ecosystem grows?"
  )
  echo ""
  echo "🌐 CARPOOL: PLATFORM STRATEGY — $PLATFORM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Platform strategy roundtable complete."
  exit 0
fi

if [[ "$1" == "mlops" ]]; then
  MODEL="${2:-our ML model}"
  AGENTS=("MLOps" "Data Sci" "Backend" "Infra" "QA")
  QUESTIONS=(
    "What does the full MLOps lifecycle look like for $MODEL from training to production?"
    "How should $MODEL handle data drift, model drift, and retraining triggers?"
    "What CI/CD pipeline should $MODEL use for safe, testable model deployments?"
    "How do we monitor $MODEL in production — latency, accuracy, bias, fairness?"
    "What feature store and experiment tracking setup fits $MODEL best?"
  )
  echo ""
  echo "🤖 CARPOOL: MLOPS — $MODEL"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ MLOps strategy complete."
  exit 0
fi

if [[ "$1" == "go-to-market" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("GTM" "Marketing" "Sales" "Product" "Customer")
  QUESTIONS=(
    "What is the GTM motion for $PRODUCT — direct, channel, community, or product-led?"
    "Who is the exact first buyer for $PRODUCT and what is their trigger to buy?"
    "What messaging and positioning makes $PRODUCT the obvious choice in its category?"
    "What launch channels give $PRODUCT the best shot at hitting 100 customers fast?"
    "How does $PRODUCT cross the chasm from early adopters to mainstream buyers?"
  )
  echo ""
  echo "📣 CARPOOL: GO-TO-MARKET — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Go-to-market strategy complete."
  exit 0
fi

if [[ "$1" == "debt-paydown" ]]; then
  CODEBASE="${2:-our codebase}"
  AGENTS=("Tech Lead" "Architect" "PM" "Engineer" "CTO")
  QUESTIONS=(
    "How do we audit and categorize the technical debt in $CODEBASE by risk and cost?"
    "What is the right ratio of debt paydown vs new features for $CODEBASE?"
    "How do we make the business case to leadership for investing in $CODEBASE debt?"
    "What refactoring strategy minimizes risk while paying down $CODEBASE debt fast?"
    "How do we prevent new technical debt from accumulating in $CODEBASE going forward?"
  )
  echo ""
  echo "🔧 CARPOOL: DEBT PAYDOWN — $CODEBASE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Debt paydown strategy complete."
  exit 0
fi

if [[ "$1" == "okr-planning" ]]; then
  TEAM="${2:-our team}"
  AGENTS=("Strategy" "PM" "Engineering" "Leadership" "IC")
  QUESTIONS=(
    "What are the 3 most important objectives $TEAM should set this quarter?"
    "How do we write key results for $TEAM that are measurable and not output-focused?"
    "How do $TEAM OKRs ladder up to company-level goals without becoming top-down mandates?"
    "How does $TEAM run a weekly OKR check-in that drives action, not just reporting?"
    "What are the biggest OKR anti-patterns $TEAM should avoid?"
  )
  echo ""
  echo "🎯 CARPOOL: OKR PLANNING — $TEAM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ OKR planning roundtable complete."
  exit 0
fi

if [[ "$1" == "dev-advocacy" ]]; then
  PLATFORM="${2:-our platform}"
  AGENTS=("DevRel" "Community" "Docs" "Marketing" "Engineer")
  QUESTIONS=(
    "What does a world-class developer advocacy program look like for $PLATFORM?"
    "How do we build and grow a genuine developer community around $PLATFORM?"
    "What content (tutorials, videos, samples, talks) drives the most adoption for $PLATFORM?"
    "How do developer advocates measure their impact on $PLATFORM growth?"
    "How do we turn $PLATFORM power users into champions and contributors?"
  )
  echo ""
  echo "📢 CARPOOL: DEVELOPER ADVOCACY — $PLATFORM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Developer advocacy strategy complete."
  exit 0
fi

if [[ "$1" == "brand-voice" ]]; then
  BRAND="${2:-our brand}"
  AGENTS=("Brand" "Copywriter" "Marketing" "Customer" "Design")
  QUESTIONS=(
    "How would you describe the personality and tone of $BRAND in three words, and why?"
    "What words and phrases should $BRAND always use — and never use?"
    "How does $BRAND sound different across channels: ads, docs, social, support?"
    "Write a one-paragraph brand voice guide for anyone writing copy for $BRAND."
    "How does $BRAND evolve its voice as it moves upmarket without losing authenticity?"
  )
  echo ""
  echo "🎙️  CARPOOL: BRAND VOICE — $BRAND"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Brand voice roundtable complete."
  exit 0
fi

if [[ "$1" == "service-mesh" ]]; then
  SYSTEM="${2:-our microservices}"
  AGENTS=("Infra" "Networking" "SRE" "Security" "Backend")
  QUESTIONS=(
    "Does $SYSTEM actually need a service mesh, or is it overkill right now?"
    "Compare Istio, Linkerd, and Consul Connect for $SYSTEM — which fits best?"
    "How does a service mesh improve observability and traffic control for $SYSTEM?"
    "What are the operational costs and complexity tradeoffs of adding a mesh to $SYSTEM?"
    "How do we roll out a service mesh for $SYSTEM without a big-bang migration?"
  )
  echo ""
  echo "🕸️  CARPOOL: SERVICE MESH — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Service mesh design complete."
  exit 0
fi

if [[ "$1" == "fundraising" ]]; then
  COMPANY="${2:-our startup}"
  AGENTS=("Founder" "VC" "CFO" "Advisor" "Investor")
  QUESTIONS=(
    "What milestones should $COMPANY hit before raising its next round?"
    "How do we build and work a pipeline of investors for $COMPANY efficiently?"
    "What does a compelling narrative and deck structure look like for $COMPANY?"
    "How should $COMPANY handle term sheet negotiations and pick the right lead?"
    "What are the biggest fundraising mistakes $COMPANY must avoid?"
  )
  echo ""
  echo "💰 CARPOOL: FUNDRAISING — $COMPANY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Fundraising strategy complete."
  exit 0
fi

if [[ "$1" == "ab-testing" ]]; then
  FEATURE="${2:-our feature}"
  AGENTS=("Data" "Product" "Growth" "Engineer" "Stats")
  QUESTIONS=(
    "What hypothesis should we test first for $FEATURE and how do we frame it?"
    "How do we calculate sample size and run time for a valid $FEATURE experiment?"
    "What metrics are primary, secondary, and guardrail for the $FEATURE test?"
    "How do we avoid common A/B testing pitfalls (peeking, novelty effects) with $FEATURE?"
    "When the $FEATURE test ends, how do we decide what to ship, iterate, or drop?"
  )
  echo ""
  echo "🧪 CARPOOL: A/B TESTING — $FEATURE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ A/B testing strategy complete."
  exit 0
fi

if [[ "$1" == "open-source-strategy" ]]; then
  PROJECT="${2:-our project}"
  AGENTS=("OSS" "Community" "Legal" "Engineering" "Business")
  QUESTIONS=(
    "Should $PROJECT be fully open source, open core, or source-available — and why?"
    "What license fits $PROJECT best and what are the business implications?"
    "How does $PROJECT build a contributor community that outlasts the founding team?"
    "How does $PROJECT monetize without alienating its open source community?"
    "What governance model keeps $PROJECT healthy as it grows beyond the founding org?"
  )
  echo ""
  echo "🌍 CARPOOL: OPEN SOURCE STRATEGY — $PROJECT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Open source strategy complete."
  exit 0
fi

if [[ "$1" == "edge-computing" ]]; then
  APP="${2:-our application}"
  AGENTS=("Edge" "Infra" "Backend" "Security" "Network")
  QUESTIONS=(
    "What workloads in $APP are best moved to the edge vs kept centralized?"
    "Which edge platform (Cloudflare Workers, Fastly, AWS Lambda@Edge) fits $APP best?"
    "How does $APP handle data consistency and state at the edge?"
    "What are the cold start, latency, and cost tradeoffs of edge for $APP?"
    "How do we deploy and manage $APP across hundreds of edge nodes safely?"
  )
  echo ""
  echo "⚡ CARPOOL: EDGE COMPUTING — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Edge computing design complete."
  exit 0
fi

if [[ "$1" == "customer-journey" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("CX" "Marketing" "Product" "Support", "Sales")
  QUESTIONS=(
    "Map the full customer journey for $PRODUCT from first awareness to loyal advocate."
    "Where are the biggest drop-off points in the $PRODUCT customer journey today?"
    "What emotional job is the customer hiring $PRODUCT to do at each stage?"
    "How do we personalize the $PRODUCT journey for different customer segments?"
    "What does success look like at each stage of the $PRODUCT journey and how do we measure it?"
  )
  echo ""
  echo "🗺️  CARPOOL: CUSTOMER JOURNEY — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Customer journey mapping complete."
  exit 0
fi

if [[ "$1" == "supply-chain" ]]; then
  SYSTEM="${2:-our software supply chain}"
  AGENTS=("Security" "DevOps" "Legal" "Infra" "Engineering")
  QUESTIONS=(
    "What are the biggest risks in $SYSTEM today — deps, build pipeline, registries?"
    "How do we implement SBOM generation and dependency auditing for $SYSTEM?"
    "What does a secure build pipeline look like for $SYSTEM end to end?"
    "How should $SYSTEM handle a zero-day in a critical upstream dependency?"
    "What compliance frameworks (SLSA, SSDF, SOC2) apply to $SYSTEM and what do they require?"
  )
  echo ""
  echo "🔒 CARPOOL: SOFTWARE SUPPLY CHAIN — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Supply chain security review complete."
  exit 0
fi

if [[ "$1" == "feature-prioritization" ]]; then
  BACKLOG="${2:-our backlog}"
  AGENTS=("PM" "Engineering" "Customer" "Data", "Design")
  QUESTIONS=(
    "What framework (RICE, ICE, MoSCoW, Kano) fits $BACKLOG best and why?"
    "How do we weight customer requests vs strategic bets in $BACKLOG?"
    "What signals tell us a feature in $BACKLOG is truly high-impact vs just loud?"
    "How do we say no to good ideas in $BACKLOG without demoralizing the team?"
    "How do we keep $BACKLOG from becoming a graveyard of stale tickets?"
  )
  echo ""
  echo "📋 CARPOOL: FEATURE PRIORITIZATION — $BACKLOG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Feature prioritization roundtable complete."
  exit 0
fi

if [[ "$1" == "cloud-cost" ]]; then
  INFRA="${2:-our cloud infrastructure}"
  AGENTS=("FinOps" "Infra" "Engineering" "Leadership" "SRE")
  QUESTIONS=(
    "What are the biggest cost drivers in $INFRA today and which are lowest-hanging fruit?"
    "How do we right-size compute and storage in $INFRA without hurting performance?"
    "What reserved vs spot vs on-demand mix makes sense for $INFRA workloads?"
    "How do we build a cost-aware engineering culture so devs care about $INFRA spend?"
    "What FinOps tooling and tagging strategy gives $INFRA the best visibility?"
  )
  echo ""
  echo "💸 CARPOOL: CLOUD COST — $INFRA"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Cloud cost optimization complete."
  exit 0
fi

if [[ "$1" == "user-personas" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("UX Research" "Product" "Marketing" "Sales" "CS")
  QUESTIONS=(
    "Who are the 3 most important user archetypes for $PRODUCT and what defines each?"
    "What jobs-to-be-done motivate each persona to use $PRODUCT?"
    "How do the personas differ in their technical sophistication and workflow for $PRODUCT?"
    "Which persona should $PRODUCT optimize for first and why?"
    "How do we keep $PRODUCT personas grounded in real data rather than assumptions?"
  )
  echo ""
  echo "👤 CARPOOL: USER PERSONAS — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ User personas roundtable complete."
  exit 0
fi

if [[ "$1" == "disaster-recovery" ]]; then
  SYSTEM="${2:-our system}"
  AGENTS=("SRE" "Infra" "Security" "Leadership" "Engineering")
  QUESTIONS=(
    "What are the RTO and RPO targets for $SYSTEM and how do we meet them?"
    "What failure scenarios does $SYSTEM need a DR plan for — region outage, data loss, breach?"
    "How do we design $SYSTEM for multi-region active-active or active-passive failover?"
    "How often should $SYSTEM run DR drills and what does a successful drill look like?"
    "What runbooks and decision trees does $SYSTEM need for on-call during a disaster?"
  )
  echo ""
  echo "🆘 CARPOOL: DISASTER RECOVERY — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Disaster recovery plan complete."
  exit 0
fi

if [[ "$1" == "accessibility" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("A11y" "Design" "Engineering" "Legal" "User")
  QUESTIONS=(
    "What WCAG level should $PRODUCT target and what does that require in practice?"
    "What are the most common accessibility failures in $PRODUCT and how do we fix them?"
    "How do we build accessibility into the $PRODUCT development workflow from day one?"
    "What assistive technology testing should $PRODUCT do before each release?"
    "What are the legal and business risks of ignoring accessibility for $PRODUCT?"
  )
  echo ""
  echo "♿ CARPOOL: ACCESSIBILITY — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Accessibility strategy complete."
  exit 0
fi

if [[ "$1" == "multi-cloud" ]]; then
  SYSTEM="${2:-our infrastructure}"
  AGENTS=("Infra" "Architect" "Security" "FinOps" "Engineering")
  QUESTIONS=(
    "Does $SYSTEM actually need multi-cloud or is it complexity for its own sake?"
    "How do we design $SYSTEM to be portable across AWS, GCP, and Azure without abstraction hell?"
    "What data residency and compliance requirements drive multi-cloud for $SYSTEM?"
    "How do we manage identity, networking, and secrets across clouds in $SYSTEM?"
    "What does the operational overhead of multi-cloud look like for $SYSTEM at our team size?"
  )
  echo ""
  echo "☁️  CARPOOL: MULTI-CLOUD — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Multi-cloud strategy complete."
  exit 0
fi

if [[ "$1" == "revenue-model" ]]; then
  BUSINESS="${2:-our business}"
  AGENTS=("Finance" "Product" "Sales" "Founder" "Investor")
  QUESTIONS=(
    "What revenue models are available to $BUSINESS and which fit the unit economics best?"
    "How do we design $BUSINESS pricing to maximize both conversion and expansion revenue?"
    "What does a healthy revenue mix look like for $BUSINESS — one-time, recurring, usage?"
    "How do we model and improve net revenue retention for $BUSINESS?"
    "What are the key revenue levers $BUSINESS should pull in the next 12 months?"
  )
  echo ""
  echo "📈 CARPOOL: REVENUE MODEL — $BUSINESS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Revenue model roundtable complete."
  exit 0
fi

if [[ "$1" == "team-topology" ]]; then
  ORG="${2:-our engineering org}"
  AGENTS=("Engineering" "CTO" "Architect" "PM" "HR")
  QUESTIONS=(
    "What team topology (stream-aligned, platform, enabling, complicated-subsystem) fits $ORG now?"
    "How should $ORG minimize cognitive load on each team through clear ownership boundaries?"
    "What interaction modes (collaboration, X-as-a-service, facilitating) should $ORG use between teams?"
    "How do we reorganize $ORG from a monolith structure to fast flow without a big reorg?"
    "How does $ORG know when it is time to split a team or spin up a new platform team?"
  )
  echo ""
  echo "🏢 CARPOOL: TEAM TOPOLOGY — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Team topology design complete."
  exit 0
fi

if [[ "$1" == "knowledge-base" ]]; then
  ORG="${2:-our organization}"
  AGENTS=("Docs" "Engineering" "CS", "HR" "Leadership")
  QUESTIONS=(
    "What knowledge is most critical for $ORG to capture and why does it keep getting lost?"
    "What structure and taxonomy should $ORG use for its internal knowledge base?"
    "How do we make contributing to $ORG knowledge base a habit rather than a chore?"
    "What tooling (Notion, Confluence, Obsidian, custom) fits $ORG knowledge needs best?"
    "How does $ORG keep its knowledge base fresh and prevent it from rotting over time?"
  )
  echo ""
  echo "📚 CARPOOL: KNOWLEDGE BASE — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Knowledge base strategy complete."
  exit 0
fi

if [[ "$1" == "async-culture" ]]; then
  ORG="${2:-our team}"
  AGENTS=("Culture" "Engineering" "Leadership" "Remote" "PM")
  QUESTIONS=(
    "What norms and rituals make async-first work actually work for $ORG?"
    "How does $ORG balance async communication with the need for real-time collaboration?"
    "What does great async written communication look like at $ORG — docs, decisions, updates?"
    "How do we onboard new people into an async culture at $ORG without leaving them lost?"
    "What are the biggest async anti-patterns $ORG must avoid to stay high-trust and fast?"
  )
  echo ""
  echo "🌐 CARPOOL: ASYNC CULTURE — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Async culture roundtable complete."
  exit 0
fi

if [[ "$1" == "event-driven" ]]; then
  SYSTEM="${2:-our system}"
  AGENTS=("Architect" "Backend" "Data" "Infra" "SRE")
  QUESTIONS=(
    "What parts of $SYSTEM are best modeled as events rather than request-response?"
    "How should $SYSTEM design its event schema and versioning strategy?"
    "Compare Kafka, Pulsar, and SQS/SNS for $SYSTEM event backbone — which fits?"
    "How does $SYSTEM handle event ordering, exactly-once delivery, and idempotency?"
    "What does debugging and observability look like in an event-driven $SYSTEM?"
  )
  echo ""
  echo "⚡ CARPOOL: EVENT-DRIVEN ARCHITECTURE — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Event-driven architecture design complete."
  exit 0
fi

if [[ "$1" == "competitive-moat" ]]; then
  COMPANY="${2:-our company}"
  AGENTS=("Strategy" "Product" "VC" "Founder" "Competitor")
  QUESTIONS=(
    "What durable competitive advantages does $COMPANY have or could build?"
    "Which moat type fits $COMPANY best — network effects, switching costs, data, brand, scale?"
    "What does $COMPANY need to do in the next 12 months to deepen its moat?"
    "What competitor move would most threaten $COMPANY moat and how do we defend against it?"
    "How does $COMPANY communicate its moat to investors, customers, and recruits?"
  )
  echo ""
  echo "🏰 CARPOOL: COMPETITIVE MOAT — $COMPANY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Competitive moat analysis complete."
  exit 0
fi

if [[ "$1" == "internationalization" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("i18n" "Engineering" "Design" "Legal" "Growth")
  QUESTIONS=(
    "What markets should $PRODUCT expand into first and what localization depth do they require?"
    "How do we architect $PRODUCT from the start to support i18n without a painful rewrite?"
    "What are the hardest i18n edge cases $PRODUCT will hit — RTL, pluralization, date formats?"
    "How do we manage translation workflows and keep $PRODUCT strings in sync across languages?"
    "What compliance and legal requirements does $PRODUCT face when entering new markets?"
  )
  echo ""
  echo "🌏 CARPOOL: INTERNATIONALIZATION — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Internationalization strategy complete."
  exit 0
fi

if [[ "$1" == "zero-trust" ]]; then
  SYSTEM="${2:-our infrastructure}"
  AGENTS=("Security" "Infra" "Identity" "Engineering" "Compliance")
  QUESTIONS=(
    "What does a zero-trust architecture look like for $SYSTEM — never trust, always verify?"
    "How do we implement identity-based access control across $SYSTEM without friction?"
    "What network segmentation and micro-perimeter strategy fits $SYSTEM?"
    "How do we migrate $SYSTEM from perimeter-based to zero-trust without a big bang?"
    "What zero-trust tooling (BeyondCorp, Tailscale, Cloudflare Access) fits $SYSTEM best?"
  )
  echo ""
  echo "🔐 CARPOOL: ZERO TRUST — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Zero trust architecture complete."
  exit 0
fi

if [[ "$1" == "growth-model" ]]; then
  BUSINESS="${2:-our business}"
  AGENTS=("Growth" "Finance" "Product" "Marketing" "Data")
  QUESTIONS=(
    "What is the core growth loop that drives compounding growth for $BUSINESS?"
    "What are the input metrics that most reliably predict revenue growth for $BUSINESS?"
    "How do we model CAC, LTV, and payback period for $BUSINESS accurately?"
    "What growth experiments should $BUSINESS run in the next 90 days?"
    "How do we build a growth model for $BUSINESS that the whole team can rally around?"
  )
  echo ""
  echo "📊 CARPOOL: GROWTH MODEL — $BUSINESS"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Growth model roundtable complete."
  exit 0
fi

if [[ "$1" == "eng-levels" ]]; then
  ORG="${2:-our engineering org}"
  AGENTS=("CTO" "EM" "Staff Eng" "HR" "IC")
  QUESTIONS=(
    "What engineering levels does $ORG need and what distinguishes each from the next?"
    "How do we define the staff and principal engineer role at $ORG without it becoming a dead end?"
    "What does the IC vs management track look like at $ORG and how do we keep both valued?"
    "How do we calibrate levels consistently across teams in $ORG to avoid grade inflation?"
    "What does a promotion process look like for $ORG that feels fair, fast, and transparent?"
  )
  echo ""
  echo "🎖️  CARPOOL: ENGINEERING LEVELS — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Engineering levels design complete."
  exit 0
fi

if [[ "$1" == "prompt-engineering" ]]; then
  USECASE="${2:-our AI feature}"
  AGENTS=("AI" "Product", "Engineer" "UX" "Safety")
  QUESTIONS=(
    "What prompt patterns (chain-of-thought, few-shot, ReAct) work best for $USECASE?"
    "How do we version, test, and deploy prompts for $USECASE like production code?"
    "What guardrails and evals should $USECASE have to catch bad model outputs?"
    "How do we reduce token cost and latency for $USECASE without losing quality?"
    "What does a systematic prompt iteration and improvement workflow look like for $USECASE?"
  )
  echo ""
  echo "🤖 CARPOOL: PROMPT ENGINEERING — $USECASE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Prompt engineering strategy complete."
  exit 0
fi

if [[ "$1" == "data-governance" ]]; then
  ORG="${2:-our organization}"
  AGENTS=("Data" "Legal" "Security" "Engineering" "Leadership")
  QUESTIONS=(
    "What data classification scheme does $ORG need — public, internal, confidential, restricted?"
    "How does $ORG build a data catalog and ownership model that teams actually use?"
    "What retention, deletion, and lineage policies does $ORG need for compliance?"
    "How do we enforce data access controls in $ORG without slowing down data teams?"
    "What does a privacy-by-design culture look like in $ORG from eng to product to ops?"
  )
  echo ""
  echo "🗄️  CARPOOL: DATA GOVERNANCE — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Data governance strategy complete."
  exit 0
fi

if [[ "$1" == "sprint-planning" ]]; then
  TEAM="${2:-our team}"
  AGENTS=("PM" "Engineering" "Design" "EM" "QA")
  QUESTIONS=(
    "How does $TEAM decide what goes into the sprint vs the backlog each cycle?"
    "What is the right sprint length and ceremony cadence for $TEAM right now?"
    "How does $TEAM estimate work accurately without spending all day on planning poker?"
    "How does $TEAM protect sprint scope without becoming rigid to urgent reality?"
    "What does $TEAM do when a sprint derails mid-cycle — triage, reprioritize, or push through?"
  )
  echo ""
  echo "🏃 CARPOOL: SPRINT PLANNING — $TEAM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Sprint planning roundtable complete."
  exit 0
fi

if [[ "$1" == "market-sizing" ]]; then
  MARKET="${2:-our market}"
  AGENTS=("Strategy" "VC" "Analyst" "Founder" "Sales")
  QUESTIONS=(
    "What is the TAM, SAM, and SOM for $MARKET and how do we calculate each rigorously?"
    "What bottom-up market sizing approach gives the most credible estimate for $MARKET?"
    "What market signals tell us $MARKET is growing faster than consensus estimates?"
    "How do we identify and size the beachhead segment within $MARKET to win first?"
    "How do we present $MARKET sizing to investors without overselling or underselling?"
  )
  echo ""
  echo "🌍 CARPOOL: MARKET SIZING — $MARKET"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Market sizing analysis complete."
  exit 0
fi

if [[ "$1" == "webhook-design" ]]; then
  PLATFORM="${2:-our platform}"
  AGENTS=("Architect" "Backend" "DevEx" "Security" "SRE")
  QUESTIONS=(
    "What events should $PLATFORM expose as webhooks and how do we decide the payload shape?"
    "How does $PLATFORM handle webhook delivery guarantees — retries, exponential backoff, dead letters?"
    "What security model should $PLATFORM use for webhook verification (HMAC, mTLS, secrets)?"
    "How do we build a webhook debug and replay tool for $PLATFORM developers?"
    "How does $PLATFORM scale webhook delivery to millions of events without dropping any?"
  )
  echo ""
  echo "🔔 CARPOOL: WEBHOOK DESIGN — $PLATFORM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Webhook design roundtable complete."
  exit 0
fi

if [[ "$1" == "performance-budget" ]]; then
  APP="${2:-our app}"
  AGENTS=("Frontend" "Backend" "SRE" "Product" "Mobile")
  QUESTIONS=(
    "What performance budgets should $APP set for load time, TTI, and Core Web Vitals?"
    "How do we enforce $APP performance budgets in CI so regressions never ship?"
    "What are the top 5 performance bottlenecks in $APP and how do we tackle each?"
    "How do we measure real-user performance for $APP vs synthetic lab tests?"
    "How do we make performance a shared team value at $APP, not just an eng concern?"
  )
  echo ""
  echo "⚡ CARPOOL: PERFORMANCE BUDGET — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Performance budget strategy complete."
  exit 0
fi

if [[ "$1" == "board-meeting" ]]; then
  COMPANY="${2:-our company}"
  AGENTS=("CEO" "CFO" "Board" "Advisor" "Investor")
  QUESTIONS=(
    "What metrics and narrative should $COMPANY lead with in its next board meeting?"
    "How does $COMPANY present bad news or misses to the board without losing confidence?"
    "What does a board deck structure look like that drives decisions, not just updates, for $COMPANY?"
    "How should $COMPANY prepare for tough board questions on burn, runway, and hiring?"
    "How does $COMPANY get strategic value out of board members beyond the quarterly meeting?"
  )
  echo ""
  echo "🏛️  CARPOOL: BOARD MEETING — $COMPANY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Board meeting prep complete."
  exit 0
fi

if [[ "$1" == "feature-discovery" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("PM" "UX Research" "Design" "Engineering" "Customer")
  QUESTIONS=(
    "What discovery methods (interviews, surveys, shadowing) work best for $PRODUCT right now?"
    "How do we run a customer interview for $PRODUCT that surfaces real problems, not feature requests?"
    "How does $PRODUCT validate a problem is worth building for before writing any code?"
    "What does a jobs-to-be-done discovery sprint look like for $PRODUCT?"
    "How do we synthesize messy discovery data into a crisp $PRODUCT opportunity to build?"
  )
  echo ""
  echo "🔍 CARPOOL: FEATURE DISCOVERY — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Feature discovery session complete."
  exit 0
fi

if [[ "$1" == "monorepo" ]]; then
  CODEBASE="${2:-our codebase}"
  AGENTS=("Architect" "DevEx" "Build" "Engineering" "Platform")
  QUESTIONS=(
    "Should $CODEBASE move to a monorepo or stay polyrepo — what are the real tradeoffs?"
    "What tooling (Nx, Turborepo, Bazel, Pants) fits $CODEBASE best for a monorepo?"
    "How do we manage dependency versioning and avoid diamond deps inside $CODEBASE monorepo?"
    "How do we keep CI fast in $CODEBASE monorepo as it grows to hundreds of packages?"
    "What does the migration path from polyrepo to monorepo look like for $CODEBASE?"
  )
  echo ""
  echo "📦 CARPOOL: MONOREPO — $CODEBASE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Monorepo strategy complete."
  exit 0
fi

if [[ "$1" == "customer-success" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("CS" "Sales" "Product" "Support" "Data")
  QUESTIONS=(
    "What does a proactive customer success motion look like for $PRODUCT at scale?"
    "How do we identify at-risk accounts in $PRODUCT before they churn?"
    "What does a great QBR (quarterly business review) look like for $PRODUCT customers?"
    "How should $PRODUCT segment customers for high-touch vs tech-touch CS coverage?"
    "What health score signals predict expansion and churn for $PRODUCT accounts?"
  )
  echo ""
  echo "🤝 CARPOOL: CUSTOMER SUCCESS — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Customer success strategy complete."
  exit 0
fi

if [[ "$1" == "ai-safety" ]]; then
  SYSTEM="${2:-our AI system}"
  AGENTS=("Safety" "AI" "Legal" "Ethics" "Engineering")
  QUESTIONS=(
    "What are the biggest failure modes and harms $SYSTEM could cause and how do we prevent them?"
    "What evals and red-teaming process should $SYSTEM have before shipping to users?"
    "How does $SYSTEM handle jailbreaks, prompt injection, and adversarial inputs?"
    "What human oversight and kill-switch mechanisms does $SYSTEM need in production?"
    "How does $SYSTEM stay aligned with user intent as it becomes more capable over time?"
  )
  echo ""
  echo "🛡️  CARPOOL: AI SAFETY — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ AI safety review complete."
  exit 0
fi

if [[ "$1" == "design-sprint" ]]; then
  PROBLEM="${2:-our problem}"
  AGENTS=("Facilitator" "Design" "Engineering" "Product" "Customer")
  QUESTIONS=(
    "How do we frame $PROBLEM as a sprint question that is scoped enough to answer in 5 days?"
    "What does the map and target phase of a design sprint for $PROBLEM look like?"
    "How do we sketch and decide on the best solution for $PROBLEM on day 2 and 3?"
    "What prototype fidelity is right to test $PROBLEM assumptions in a design sprint?"
    "How do we recruit the right users and run Friday testing for $PROBLEM to get real signal?"
  )
  echo ""
  echo "🎨 CARPOOL: DESIGN SPRINT — $PROBLEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Design sprint plan complete."
  exit 0
fi

if [[ "$1" == "infra-as-code" ]]; then
  INFRA="${2:-our infrastructure}"
  AGENTS=("DevOps" "Architect" "Security" "SRE" "Engineering")
  QUESTIONS=(
    "What IaC tool (Terraform, Pulumi, CDK, Bicep) fits $INFRA best and why?"
    "How do we structure $INFRA modules and state for a team of 10+ engineers safely?"
    "What does a good GitOps workflow for $INFRA look like — PR reviews, plan previews, apply gates?"
    "How do we handle secrets and sensitive values in $INFRA without committing them?"
    "How do we test and validate $INFRA changes before they hit production?"
  )
  echo ""
  echo "🏗️  CARPOOL: INFRA AS CODE — $INFRA"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Infrastructure as code strategy complete."
  exit 0
fi

if [[ "$1" == "narrative" ]]; then
  COMPANY="${2:-our company}"
  AGENTS=("Storyteller" "Marketing" "Founder" "Investor" "Customer")
  QUESTIONS=(
    "What is the one-sentence origin story of $COMPANY that makes people lean in?"
    "What villain (problem, broken system) is $COMPANY fighting and why does it matter now?"
    "How does $COMPANY articulate its vision in a way that feels inevitable, not aspirational?"
    "What proof points make the $COMPANY narrative credible to skeptics?"
    "How does $COMPANY adapt its narrative for investors, customers, and recruits?"
  )
  echo ""
  echo "📖 CARPOOL: COMPANY NARRATIVE — $COMPANY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Company narrative roundtable complete."
  exit 0
fi

if [[ "$1" == "load-testing" ]]; then
  SYSTEM="${2:-our system}"
  AGENTS=("SRE" "Backend" "Infra" "QA" "Data")
  QUESTIONS=(
    "What load scenarios (baseline, stress, spike, soak) does $SYSTEM need to test?"
    "What tools (k6, Locust, JMeter, Gatling) fit $SYSTEM load testing best and why?"
    "How do we write realistic load test scripts that mirror $SYSTEM production traffic?"
    "What thresholds and SLOs should $SYSTEM fail a load test at?"
    "How do we run $SYSTEM load tests in CI without impacting production environments?"
  )
  echo ""
  echo "🔨 CARPOOL: LOAD TESTING — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Load testing strategy complete."
  exit 0
fi

if [[ "$1" == "staff-eng" ]]; then
  ORG="${2:-our engineering org}"
  AGENTS=("Staff Eng" "CTO" "EM" "Architect" "IC")
  QUESTIONS=(
    "What does the staff engineer role actually do in $ORG — and what makes it distinct from senior?"
    "How does a staff engineer at $ORG pick the right problems to work on?"
    "What does technical leadership without authority look like for a staff engineer at $ORG?"
    "How does a staff engineer at $ORG build influence across teams without being annoying?"
    "What does the path from senior to staff engineer look like at $ORG and what trips people up?"
  )
  echo ""
  echo "⭐ CARPOOL: STAFF ENGINEER — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"
    question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""
    echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Staff engineer roundtable complete."
  exit 0
fi

if [[ "$1" == "containerization" ]]; then
  APP="${2:-our application}"
  AGENTS=("DevOps" "Backend" "Security" "Infra" "SRE")
  QUESTIONS=(
    "What is the right base image strategy for $APP containers — distroless, Alpine, Ubuntu?"
    "How do we keep $APP container images small, fast, and secure in production?"
    "What does a multi-stage Dockerfile look like for $APP to separate build from runtime?"
    "How do we scan $APP container images for vulnerabilities in CI before they ship?"
    "What resource limits and health checks should every $APP container have?"
  )
  echo ""
  echo "🐳 CARPOOL: CONTAINERIZATION — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Containerization strategy complete."; exit 0
fi

if [[ "$1" == "product-metrics" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("PM" "Data" "Growth" "Engineering" "Leadership")
  QUESTIONS=(
    "What is the single most important metric $PRODUCT should optimize for right now?"
    "How do we define and instrument the activation metric for $PRODUCT?"
    "What engagement metrics tell us $PRODUCT is delivering real value vs vanity numbers?"
    "How do we build a metrics framework for $PRODUCT that connects inputs to outcomes?"
    "How does $PRODUCT avoid metric gaming and keep teams focused on real customer value?"
  )
  echo ""
  echo "📊 CARPOOL: PRODUCT METRICS — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Product metrics roundtable complete."; exit 0
fi

if [[ "$1" == "on-call" ]]; then
  TEAM="${2:-our engineering team}"
  AGENTS=("SRE" "EM" "Engineer" "Leadership" "HR")
  QUESTIONS=(
    "What does a humane, sustainable on-call rotation look like for $TEAM?"
    "How do we build runbooks for $TEAM that actually help during a 3am incident?"
    "What escalation policy and severity levels should $TEAM use for alerts?"
    "How does $TEAM reduce alert fatigue without missing real production issues?"
    "How do we compensate and recognize on-call burden fairly in $TEAM?"
  )
  echo ""
  echo "📟 CARPOOL: ON-CALL — $TEAM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ On-call strategy complete."; exit 0
fi

if [[ "$1" == "positioning" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("Marketing" "Product" "Sales" "Customer" "Analyst")
  QUESTIONS=(
    "What category does $PRODUCT belong to — or should it create a new one?"
    "What is $PRODUCT uniquely best at that no competitor can honestly claim?"
    "How do we write a positioning statement for $PRODUCT using the classic April Dunford framework?"
    "How does $PRODUCT positioning change as it moves from SMB to enterprise buyers?"
    "How do we test whether our $PRODUCT positioning actually lands with target buyers?"
  )
  echo ""
  echo "🎯 CARPOOL: POSITIONING — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Positioning roundtable complete."; exit 0
fi

if [[ "$1" == "schema-design" ]]; then
  APP="${2:-our application}"
  AGENTS=("Data Eng" "Backend" "DBA" "Architect" "SRE")
  QUESTIONS=(
    "What are the core entities and relationships $APP needs in its data model?"
    "How do we design $APP schema for read performance without over-indexing?"
    "How does $APP handle schema migrations in production with zero downtime?"
    "When should $APP normalize vs denormalize — what are the tradeoffs for our workload?"
    "How do we design $APP schema to scale to 10x data without a painful rewrite?"
  )
  echo ""
  echo "🗃️  CARPOOL: SCHEMA DESIGN — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Schema design roundtable complete."; exit 0
fi

if [[ "$1" == "eng-management" ]]; then
  ORG="${2:-our engineering team}"
  AGENTS=("EM" "CTO" "IC" "HR" "Coach")
  QUESTIONS=(
    "What does a great 1:1 look like for an engineering manager at $ORG?"
    "How does an EM at $ORG balance technical depth with people and project work?"
    "How do we give direct, effective performance feedback to engineers at $ORG?"
    "What does an EM at $ORG do when a high performer wants to quit?"
    "How does an EM build a high-trust, psychologically safe team at $ORG?"
  )
  echo ""
  echo "👔 CARPOOL: ENGINEERING MANAGEMENT — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Engineering management roundtable complete."; exit 0
fi

if [[ "$1" == "llm-architecture" ]]; then
  APP="${2:-our AI application}"
  AGENTS=("AI Architect" "Backend" "Infra" "Product" "Data")
  QUESTIONS=(
    "What LLM architecture pattern fits $APP — RAG, fine-tuning, agents, or prompt chaining?"
    "How do we handle context window limits and memory for $APP at scale?"
    "What does a reliable LLM evaluation and regression testing pipeline look like for $APP?"
    "How do we pick the right model (GPT-4, Claude, Gemini, local) for each $APP use case?"
    "How does $APP handle LLM latency, cost, and fallback when a model is unavailable?"
  )
  echo ""
  echo "🧠 CARPOOL: LLM ARCHITECTURE — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ LLM architecture design complete."; exit 0
fi

if [[ "$1" == "payment-systems" ]]; then
  PRODUCT="${2:-our product}"
  AGENTS=("Payments" "Backend" "Security" "Legal" "Finance")
  QUESTIONS=(
    "What payment infrastructure does $PRODUCT need — Stripe, Paddle, custom, or hybrid?"
    "How does $PRODUCT handle failed payments, dunning, and subscription lifecycle?"
    "What PCI compliance requirements apply to $PRODUCT and how do we meet them?"
    "How does $PRODUCT handle multi-currency, tax, and international payment complexity?"
    "What fraud detection and chargeback strategy should $PRODUCT have from day one?"
  )
  echo ""
  echo "💳 CARPOOL: PAYMENT SYSTEMS — $PRODUCT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Payment systems roundtable complete."; exit 0
fi

if [[ "$1" == "dark-launch" ]]; then
  FEATURE="${2:-our feature}"
  AGENTS=("Engineering" "SRE" "PM" "Data" "QA")
  QUESTIONS=(
    "What dark launch and canary release strategy fits $FEATURE rollout best?"
    "How do we use feature flags to control $FEATURE exposure by user segment?"
    "What metrics and error rates should trigger an automatic rollback of $FEATURE?"
    "How do we test $FEATURE at production load before full rollout without user impact?"
    "What does a graduated rollout plan look like for $FEATURE — 1%, 5%, 25%, 100%?"
  )
  echo ""
  echo "🌑 CARPOOL: DARK LAUNCH — $FEATURE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Dark launch plan complete."; exit 0
fi

if [[ "$1" == "technical-interview" ]]; then
  ROLE="${2:-software engineer}"
  AGENTS=("Interviewer" "Hiring Mgr" "Engineer" "Candidate" "HR")
  QUESTIONS=(
    "What does a fair, signal-rich technical interview process look like for $ROLE?"
    "What coding problems best predict real $ROLE job performance vs LeetCode grinding?"
    "How do we assess system design skills for $ROLE without privileging big-tech experience?"
    "How do we structure the debrief and scoring rubric for $ROLE to reduce bias?"
    "What makes a candidate experience for $ROLE interview feel respectful and worth their time?"
  )
  echo ""
  echo "💻 CARPOOL: TECHNICAL INTERVIEW — $ROLE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"
    echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Technical interview design complete."; exit 0
fi

if [[ "$1" == "micro-frontends" ]]; then
  APP="${2:-our frontend}"
  AGENTS=("Frontend" "Architect" "Platform" "DevEx" "SRE")
  QUESTIONS=(
    "Does $APP actually need micro-frontends or is it premature optimization?"
    "What composition strategy (module federation, iframes, web components) fits $APP best?"
    "How do we share design system components and state across $APP micro-frontends?"
    "How do we handle routing, auth, and shared layout across $APP micro-frontends?"
    "What does the CI/CD and independent deployment story look like for $APP micro-frontends?"
  )
  echo ""; echo "🧩 CARPOOL: MICRO-FRONTENDS — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Micro-frontends strategy complete."; exit 0
fi

if [[ "$1" == "bug-triage" ]]; then
  TEAM="${2:-our engineering team}"
  AGENTS=("EM" "QA" "PM" "Engineer" "CS")
  QUESTIONS=(
    "How does $TEAM classify bug severity and priority consistently without debate?"
    "What does a bug triage process look like for $TEAM that balances speed and quality?"
    "How does $TEAM decide when a bug is bad enough to stop the sprint and fix it now?"
    "How do we reduce bug reopen rates and improve fix quality in $TEAM?"
    "How does $TEAM track and trend bugs to find systemic quality problems early?"
  )
  echo ""; echo "🐛 CARPOOL: BUG TRIAGE — $TEAM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Bug triage process complete."; exit 0
fi

if [[ "$1" == "investor-update" ]]; then
  COMPANY="${2:-our company}"
  AGENTS=("CEO" "CFO" "Investor" "Advisor" "Comms")
  QUESTIONS=(
    "What does a great monthly investor update for $COMPANY include — and exclude?"
    "How does $COMPANY share bad news in an investor update without losing confidence?"
    "What metrics should $COMPANY always lead with in investor updates?"
    "How do we make investor updates for $COMPANY actionable — what should we ask investors for?"
    "What cadence and format keeps $COMPANY investors engaged without burning CEO time?"
  )
  echo ""; echo "📬 CARPOOL: INVESTOR UPDATE — $COMPANY"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Investor update strategy complete."; exit 0
fi

if [[ "$1" == "sdk-design" ]]; then
  PLATFORM="${2:-our platform}"
  AGENTS=("DevEx" "Backend" "Architect" "Community" "Docs")
  QUESTIONS=(
    "What languages and runtimes should $PLATFORM prioritize for its SDK first?"
    "What design principles make a $PLATFORM SDK feel delightful and intuitive to use?"
    "How do we version $PLATFORM SDK and handle breaking changes without abandoning users?"
    "What does the $PLATFORM SDK testing and quality bar look like before each release?"
    "How do we write $PLATFORM SDK docs and examples that reduce time-to-first-success?"
  )
  echo ""; echo "📦 CARPOOL: SDK DESIGN — $PLATFORM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ SDK design roundtable complete."; exit 0
fi

if [[ "$1" == "culture-fit" ]]; then
  ORG="${2:-our organization}"
  AGENTS=("Culture" "HR" "Founder" "EM" "IC")
  QUESTIONS=(
    "How does $ORG define and assess culture fit without it becoming a bias vector?"
    "What values does $ORG actually operate by vs what it says it does?"
    "How do we interview for culture-add rather than culture-fit at $ORG?"
    "What onboarding rituals make new hires at $ORG feel the culture immediately?"
    "How does $ORG evolve its culture intentionally as it scales from 10 to 100 people?"
  )
  echo ""; echo "🌱 CARPOOL: CULTURE — $ORG"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Culture roundtable complete."; exit 0
fi

if [[ "$1" == "serverless" ]]; then
  APP="${2:-our application}"
  AGENTS=("Infra" "Backend" "SRE" "Architect" "FinOps")
  QUESTIONS=(
    "What parts of $APP are best suited for serverless vs always-on compute?"
    "How do we handle cold starts, timeouts, and state in $APP serverless functions?"
    "What does local development and testing look like for $APP serverless functions?"
    "How do we observe and debug $APP in production when it is serverless?"
    "What are the cost and scaling tradeoffs of going serverless for $APP at our traffic levels?"
  )
  echo ""; echo "⚡ CARPOOL: SERVERLESS — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Serverless architecture complete."; exit 0
fi

if [[ "$1" == "cold-email" ]]; then
  AUDIENCE="${2:-our target audience}"
  AGENTS=("Sales" "Copywriter" "Growth" "Founder" "Deliverability")
  QUESTIONS=(
    "What makes a cold email to $AUDIENCE get opened — subject line, sender, timing?"
    "How do we personalize cold emails to $AUDIENCE at scale without feeling robotic?"
    "What is the right call-to-action for a cold email to $AUDIENCE — meeting, reply, click?"
    "What follow-up sequence works for $AUDIENCE without becoming annoying spam?"
    "How do we measure and improve cold email performance for $AUDIENCE over time?"
  )
  echo ""; echo "📧 CARPOOL: COLD EMAIL — $AUDIENCE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Cold email strategy complete."; exit 0
fi

if [[ "$1" == "mobile-arch" ]]; then
  APP="${2:-our mobile app}"
  AGENTS=("Mobile" "Backend" "UX" "Infra" "QA")
  QUESTIONS=(
    "Should $APP be native (Swift/Kotlin), cross-platform (Flutter/RN), or PWA?"
    "How does $APP handle offline-first data sync and conflict resolution?"
    "What does the $APP release process look like — OTA updates, store review, rollback?"
    "How do we performance-test and profile $APP across low-end devices and slow networks?"
    "What push notification, deep link, and background sync architecture does $APP need?"
  )
  echo ""; echo "📱 CARPOOL: MOBILE ARCHITECTURE — $APP"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Mobile architecture design complete."; exit 0
fi

if [[ "$1" == "compliance-audit" ]]; then
  SYSTEM="${2:-our system}"
  AGENTS=("Compliance" "Legal" "Security" "Engineering" "Leadership")
  QUESTIONS=(
    "What compliance frameworks (SOC2, ISO27001, HIPAA, GDPR) apply to $SYSTEM?"
    "How do we prepare $SYSTEM for a SOC2 Type II audit efficiently without disrupting eng?"
    "What evidence collection and control documentation does $SYSTEM need to maintain continuously?"
    "How do we build compliance into $SYSTEM engineering workflows rather than bolting it on?"
    "What are the most common audit failures for systems like $SYSTEM and how do we prevent them?"
  )
  echo ""; echo "📋 CARPOOL: COMPLIANCE AUDIT — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Compliance audit prep complete."; exit 0
fi

if [[ "$1" == "domain-driven" ]]; then
  SYSTEM="${2:-our system}"
  AGENTS=("Architect" "Backend" "Domain" "Engineering" "PM")
  QUESTIONS=(
    "How do we identify and bound the core domains and subdomains in $SYSTEM?"
    "What does a ubiquitous language look like for $SYSTEM and how do we establish it with the team?"
    "How do we design $SYSTEM aggregates and bounded contexts to minimize coupling?"
    "When should $SYSTEM use domain events vs direct calls between bounded contexts?"
    "How do we migrate a big ball of mud codebase toward DDD in $SYSTEM incrementally?"
  )
  echo ""; echo "🗺️  CARPOOL: DOMAIN-DRIVEN DESIGN — $SYSTEM"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for i in "${!QUESTIONS[@]}"; do
    agent="${AGENTS[$i]}"; question="${QUESTIONS[$i]}"
    color="\033[0;3$(( (i % 6) + 1 ))m"; echo ""; echo -e "${color}[$agent]:\033[0m $question"
    python3 -c "
import urllib.request, json, sys
q = 'You are the ' + sys.argv[2] + ' expert. Answer concisely (3-5 sentences): ' + sys.argv[1]
req = urllib.request.Request('http://localhost:11434/api/generate',
  data=json.dumps({'model':'tinyllama','prompt':q,'stream':False}).encode(),
  headers={'Content-Type':'application/json'})
r = urllib.request.urlopen(req, timeout=30)
print(json.loads(r.read())['response'].strip())
" "$question" "$agent" 2>/dev/null || echo "  [tinyllama unavailable]"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Domain-driven design roundtable complete."; exit 0
fi

if [[ "$1" == "vector-db" ]]; then
  TOPIC="vector databases"
  QUESTION="How do you choose and use vector databases for AI applications? Cover embeddings storage, similarity search algorithms (HNSW vs IVF), scaling strategies, hybrid search, and when to use dedicated vector DBs vs pgvector vs in-memory options."
  AGENTS=("Architect" "ML Engineer" "DBA" "Startup CTO" "Performance Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗄️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/vector-db-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Vector DB Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Vector DB roundtable complete."; exit 0
fi

if [[ "$1" == "rate-limiting" ]]; then
  TOPIC="rate limiting architecture"
  QUESTION="Design a robust rate limiting system. Cover token bucket vs sliding window vs fixed window algorithms, distributed rate limiting across multiple nodes, Redis-based implementations, per-user vs per-IP vs per-API-key limits, and graceful degradation when limits are hit."
  AGENTS=("Platform Engineer" "API Designer" "Security Engineer" "Backend Architect" "SRE")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚦 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/rate-limiting-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Rate Limiting Architecture Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Rate limiting architecture roundtable complete."; exit 0
fi

if [[ "$1" == "feature-store" ]]; then
  TOPIC="ML feature stores"
  QUESTION="How do you design and operate an ML feature store? Cover online vs offline feature serving, feature reuse across teams, point-in-time correctness to prevent data leakage, feature versioning, monitoring for feature drift, and build-vs-buy decisions (Feast, Tecton, Hopsworks)."
  AGENTS=("ML Platform Engineer" "Data Scientist" "MLOps Lead" "Data Engineer" "ML Architect")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🧮 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/feature-store-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Feature Store Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Feature store roundtable complete."; exit 0
fi

if [[ "$1" == "fintech-arch" ]]; then
  TOPIC="fintech architecture"
  QUESTION="What are the key architectural principles for building financial systems? Cover double-entry bookkeeping in software, idempotency for payment operations, reconciliation pipelines, regulatory data retention, PCI-DSS scope reduction, handling currency precision, and audit trail design."
  AGENTS=("Fintech Architect" "Payments Engineer" "Compliance Lead" "Security Engineer" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "💰 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/fintech-arch-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Fintech Architecture Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Fintech architecture roundtable complete."; exit 0
fi

if [[ "$1" == "real-time-collab" ]]; then
  TOPIC="real-time collaboration systems"
  QUESTION="How do you build real-time collaborative editing like Google Docs? Cover operational transforms vs CRDTs, conflict resolution strategies, presence and cursors, offline sync, version history, and scaling WebSocket connections to millions of concurrent users."
  AGENTS=("Distributed Systems Engineer" "Frontend Architect" "Real-time Expert" "Product Engineer" "Infrastructure Lead")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🤝 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/real-time-collab-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Real-Time Collaboration Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Real-time collaboration roundtable complete."; exit 0
fi

if [[ "$1" == "multi-agent-ai" ]]; then
  TOPIC="multi-agent AI systems"
  QUESTION="How do you architect systems with multiple cooperating AI agents? Cover orchestrator vs choreography patterns, agent memory and state management, tool use and function calling, handling agent failures and loops, evaluation frameworks, and cost control for chained LLM calls."
  AGENTS=("AI Architect" "LLM Engineer" "Product Manager" "Research Scientist" "Platform Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🤖 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/multi-agent-ai-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Multi-Agent AI Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Multi-agent AI roundtable complete."; exit 0
fi

if [[ "$1" == "graph-db" ]]; then
  TOPIC="graph databases"
  QUESTION="When should you use a graph database and how do you design for it? Cover use cases (fraud detection, recommendation engines, knowledge graphs, access control), property graph vs RDF, Cypher query design, performance pitfalls, and hybrid approaches using graphs alongside relational or document stores."
  AGENTS=("Graph DB Expert" "Data Architect" "Backend Engineer" "Fraud Detection Lead" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🕸️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/graph-db-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Graph DB Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Graph DB roundtable complete."; exit 0
fi

if [[ "$1" == "streaming-arch" ]]; then
  TOPIC="streaming data architecture"
  QUESTION="How do you design real-time streaming data pipelines? Cover Kafka vs Kinesis vs Pulsar trade-offs, stream processing frameworks (Flink, Spark Streaming, ksqlDB), exactly-once semantics, backpressure handling, late-arriving data, and building the lambda vs kappa architecture."
  AGENTS=("Data Platform Architect" "Streaming Engineer" "Data Engineer" "Backend Lead" "SRE")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🌊 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/streaming-arch-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Streaming Architecture Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Streaming architecture roundtable complete."; exit 0
fi

if [[ "$1" == "privacy-engineering" ]]; then
  TOPIC="privacy engineering"
  QUESTION="How do you build privacy into software systems by design? Cover data minimization, differential privacy, k-anonymity, PII detection and tokenization, consent management, right-to-erasure implementation, privacy impact assessments, and balancing analytics needs with user privacy."
  AGENTS=("Privacy Engineer" "Security Architect" "Legal Counsel" "Data Scientist" "Product Manager")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔒 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/privacy-engineering-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Privacy Engineering Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Privacy engineering roundtable complete."; exit 0
fi

if [[ "$1" == "docs-system" ]]; then
  TOPIC="documentation systems"
  QUESTION="How do you build and maintain excellent developer documentation? Cover docs-as-code workflows, auto-generating API docs from OpenAPI specs, versioning strategies, search (Algolia, Meilisearch), feedback loops, measuring doc quality, and keeping docs in sync with fast-moving codebases."
  AGENTS=("Developer Experience Lead" "Technical Writer" "Platform Engineer" "Product Manager" "Open Source Maintainer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📚 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/docs-system-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Documentation System Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Documentation system roundtable complete."; exit 0
fi

if [[ "$1" == "platform-eng" ]]; then
  TOPIC="platform engineering"
  QUESTION="How do you build an internal developer platform (IDP)? Cover golden paths, paved roads vs guardrails, self-service infrastructure, platform-as-a-product mindset, measuring platform adoption and developer toil reduction, Backstage service catalogs, and avoiding platform teams becoming bottlenecks."
  AGENTS=("Platform Engineer" "Developer Experience Lead" "Engineering Manager" "Staff Engineer" "SRE")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🏗️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/platform-eng-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Platform Engineering Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Platform engineering roundtable complete."; exit 0
fi

if [[ "$1" == "data-mesh" ]]; then
  TOPIC="data mesh architecture"
  QUESTION="What is data mesh and when should you adopt it? Cover decentralized data ownership, data products as first-class citizens, federated computational governance, self-serve data infrastructure, domain-oriented data teams, and the organizational changes required to succeed with data mesh at scale."
  AGENTS=("Data Architect" "Data Platform Lead" "Domain Team Lead" "Chief Data Officer" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🕸️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/data-mesh-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Data Mesh Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Data mesh roundtable complete."; exit 0
fi

if [[ "$1" == "ai-infra" ]]; then
  TOPIC="AI infrastructure"
  QUESTION="How do you build infrastructure for training and serving AI models at scale? Cover GPU cluster design and scheduling (SLURM, Ray, Kubernetes), model parallelism strategies, inference optimization (quantization, speculative decoding, batching), model registry, and cost management for GPU workloads."
  AGENTS=("AI Infrastructure Engineer" "ML Platform Lead" "GPU Cluster Architect" "MLOps Engineer" "FinOps Specialist")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🧠 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/ai-infra-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "AI Infrastructure Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ AI infrastructure roundtable complete."; exit 0
fi

if [[ "$1" == "search-arch" ]]; then
  TOPIC="search architecture"
  QUESTION="How do you design great search for a product? Cover inverted indexes, BM25 vs semantic search vs hybrid, relevance tuning and learning-to-rank, query understanding (synonyms, spell correction, intent), Elasticsearch vs OpenSearch vs Typesense trade-offs, personalization, and measuring search quality with NDCG."
  AGENTS=("Search Engineer" "ML Engineer" "Product Manager" "Backend Architect" "Data Scientist")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/search-arch-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Search Architecture Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Search architecture roundtable complete."; exit 0
fi

if [[ "$1" == "developer-portal" ]]; then
  TOPIC="developer portals"
  QUESTION="How do you build an effective developer portal? Cover service catalogs (Backstage, Cortex, Port), tech radar, runbook integration, API documentation surfacing, ownership mapping, team health metrics, onboarding workflows for new engineers, and getting teams to actually contribute and keep it up to date."
  AGENTS=("Developer Experience Lead" "Platform Engineer" "Engineering Manager" "Staff Engineer" "Technical Writer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚪 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/developer-portal-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Developer Portal Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Developer portal roundtable complete."; exit 0
fi

if [[ "$1" == "finops" ]]; then
  TOPIC="FinOps and cloud cost optimization"
  QUESTION="How do you manage and optimize cloud spend without slowing down engineering? Cover FinOps culture and team structure, tagging strategies for cost attribution, reserved instances vs savings plans vs spot, rightsizing, idle resource detection, showback vs chargeback, unit economics (cost per transaction), and building cost awareness into the engineering culture."
  AGENTS=("FinOps Lead" "Cloud Architect" "Engineering Manager" "SRE" "CFO")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "💸 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/finops-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "FinOps Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ FinOps roundtable complete."; exit 0
fi

if [[ "$1" == "incident-command" ]]; then
  TOPIC="incident command and war rooms"
  QUESTION="How do you run a high-stakes incident effectively? Cover incident commander role and responsibilities, communication cadence during an outage (internal and external), war room structure, avoiding hero culture, blameless post-mortems that actually drive change, SLO burn rate alerting, and building incident muscle memory through game days."
  AGENTS=("Incident Commander" "SRE Lead" "Engineering Manager" "CTO" "Customer Success Lead")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚨 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/incident-command-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Incident Command Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Incident command roundtable complete."; exit 0
fi

if [[ "$1" == "dep-management" ]]; then
  TOPIC="dependency management"
  QUESTION="How do you manage dependencies responsibly in a large codebase? Cover lockfile strategies, automated dependency updates (Dependabot, Renovate), supply chain security (SBOM, provenance, typosquatting), internal package registries, major version upgrade strategies, and dealing with dependency sprawl across a monorepo."
  AGENTS=("Staff Engineer" "Security Engineer" "Platform Lead" "Open Source Maintainer" "DevOps Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📦 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/dep-management-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Dependency Management Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Dependency management roundtable complete."; exit 0
fi

if [[ "$1" == "tech-debt-strategy" ]]; then
  TOPIC="technical debt strategy"
  QUESTION="How do you measure, prioritize, and systematically pay down technical debt? Cover debt classification (intentional vs reckless, deliberate vs inadvertent), the strangler fig pattern for legacy rewrites, making debt visible to non-engineers, allocating 20% time vs dedicated debt sprints, when NOT to pay down debt, and avoiding the big rewrite trap."
  AGENTS=("Staff Engineer" "Engineering Manager" "CTO" "Product Manager" "Architect")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🏦 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/tech-debt-strategy-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Technical Debt Strategy Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Technical debt strategy roundtable complete."; exit 0
fi

if [[ "$1" == "build-vs-buy" ]]; then
  TOPIC="build vs buy decisions"
  QUESTION="How do you make the build vs buy vs open-source decision for software components? Cover the hidden costs of building (maintenance, hiring, opportunity cost), vendor lock-in risks, TCO frameworks, evaluating open-source maturity, when to build for competitive differentiation vs commodity capabilities, and how to reverse a bad decision."
  AGENTS=("CTO" "Engineering Manager" "Product Manager" "Staff Engineer" "Finance Lead")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚖️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/build-vs-buy-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Build vs Buy Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Build vs buy roundtable complete."; exit 0
fi

if [[ "$1" == "caching-strategy" ]]; then
  TOPIC="caching strategy"
  QUESTION="How do you design a robust caching strategy? Cover cache invalidation patterns (TTL, event-driven, cache-aside vs write-through vs write-behind), cache stampede and thundering herd prevention, CDN vs application-layer vs database caching, cache warming strategies, and measuring cache effectiveness."
  AGENTS=("Backend Architect" "Platform Engineer" "Staff Engineer" "SRE" "Database Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚡ CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/caching-strategy-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Caching Strategy Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Caching strategy roundtable complete."; exit 0
fi

if [[ "$1" == "auth-patterns" ]]; then
  TOPIC="authentication and authorization patterns"
  QUESTION="What are the key patterns for auth in modern systems? Cover OAuth2 flows and when to use each (PKCE, client credentials, device), OIDC for identity, JWT vs opaque tokens, session management, passwordless and passkeys, SSO with SAML, attribute-based vs role-based access control, and securing service-to-service communication."
  AGENTS=("Security Architect" "Identity Engineer" "Backend Lead" "Product Manager" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔐 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/auth-patterns-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Auth Patterns Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Auth patterns roundtable complete."; exit 0
fi

if [[ "$1" == "db-sharding" ]]; then
  TOPIC="database sharding"
  QUESTION="How do you design and operate a sharded database? Cover shard key selection criteria, consistent hashing vs range-based sharding, hot shard problems and rebalancing, cross-shard queries and transactions, resharding without downtime, and when to shard vs use other scaling approaches like read replicas or CQRS."
  AGENTS=("Database Architect" "Distributed Systems Engineer" "Backend Lead" "Staff Engineer" "SRE")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🗃️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/db-sharding-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Database Sharding Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Database sharding roundtable complete."; exit 0
fi

if [[ "$1" == "event-sourcing" ]]; then
  TOPIC="event sourcing"
  QUESTION="How do you design and operate an event-sourced system? Cover event store design, projections and read models, snapshot strategies for long-lived aggregates, CQRS integration, event schema evolution and backward compatibility, replay for rebuilding state, and when event sourcing adds more complexity than it solves."
  AGENTS=("Distributed Systems Architect" "Backend Engineer" "DDD Expert" "Staff Engineer" "Engineering Manager")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📜 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/event-sourcing-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Event Sourcing Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Event sourcing roundtable complete."; exit 0
fi

if [[ "$1" == "api-versioning" ]]; then
  TOPIC="API versioning"
  QUESTION="How do you version APIs without breaking clients? Cover URL path vs header vs content negotiation versioning, semantic versioning for APIs, what constitutes a breaking change, deprecation timelines and communication, maintaining multiple versions, using API gateways for transformation, and sunset policies for legacy versions."
  AGENTS=("API Designer" "Platform Engineer" "Backend Lead" "Developer Advocate" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔢 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/api-versioning-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "API Versioning Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ API versioning roundtable complete."; exit 0
fi

if [[ "$1" == "distributed-tracing" ]]; then
  TOPIC="distributed tracing"
  QUESTION="How do you implement distributed tracing across a microservices system? Cover OpenTelemetry instrumentation, trace context propagation across service boundaries, sampling strategies (head vs tail), correlating traces with logs and metrics, trace storage and querying (Jaeger, Tempo, Honeycomb), and using traces to debug latency tail issues."
  AGENTS=("Observability Engineer" "Platform Lead" "Backend Architect" "SRE" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔭 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/distributed-tracing-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Distributed Tracing Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Distributed tracing roundtable complete."; exit 0
fi

if [[ "$1" == "notification-system" ]]; then
  TOPIC="notification systems"
  QUESTION="How do you design a scalable notification system? Cover fan-out patterns (push vs pull, inbox model), multi-channel delivery (push, email, SMS, in-app), delivery guarantees and deduplication, user preference management, notification fatigue and batching, priority queues, and handling unsubscribes and bounces."
  AGENTS=("Backend Architect" "Platform Engineer" "Product Manager" "Mobile Engineer" "SRE")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔔 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/notification-system-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Notification System Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Notification system roundtable complete."; exit 0
fi

if [[ "$1" == "file-storage" ]]; then
  TOPIC="file and media storage"
  QUESTION="How do you design a scalable file and media storage system? Cover object storage vs block vs file systems, CDN integration and cache invalidation, large file uploads with resumable/multipart, image and video processing pipelines, storage tiering for cost, presigned URLs for secure access, and handling user-generated content at scale."
  AGENTS=("Infrastructure Architect" "Backend Engineer" "Platform Lead" "Media Engineer" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📁 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/file-storage-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "File Storage Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ File storage roundtable complete."; exit 0
fi

if [[ "$1" == "background-jobs" ]]; then
  TOPIC="background job systems"
  QUESTION="How do you design a reliable background job processing system? Cover job queue selection (Sidekiq, BullMQ, Celery, Temporal), retry strategies with exponential backoff, idempotency for safe retries, dead letter queues, job prioritization, distributed locking for singleton jobs, observability (job dashboards, failure alerting), and handling long-running jobs."
  AGENTS=("Backend Architect" "Platform Engineer" "SRE" "Staff Engineer" "DevOps Lead")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚙️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/background-jobs-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Background Jobs Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Background jobs roundtable complete."; exit 0
fi

if [[ "$1" == "testing-strategy" ]]; then
  TOPIC="testing strategy"
  QUESTION="How do you design a comprehensive testing strategy for a large software system? Cover the testing pyramid (unit, integration, e2e), contract testing for microservices, property-based testing, mutation testing to measure test quality, flaky test management, test data management, shift-left security testing, and balancing test coverage with development speed."
  AGENTS=("Staff Engineer" "QA Architect" "Engineering Manager" "Backend Lead" "DevOps Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🧪 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/testing-strategy-$(date +%Y%m%d-%H%M%S).txt"
  mkdir -p "$SAVE_DIR"
  echo "Testing Strategy Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do
    AGENT="${AGENTS[$i]}"
    echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
)
    echo ""; echo "[$AGENT]"; echo "$REPLY"
    echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"
  done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✅ Testing strategy roundtable complete."; exit 0
fi

if [[ "$1" == "capacity-planning" ]]; then
  TOPIC="capacity planning"; QUESTION="How do you do capacity planning for production systems? Cover demand forecasting, load testing to find limits, headroom buffers, cost-vs-performance trade-offs, auto-scaling vs pre-provisioning, and communicating capacity needs to finance and leadership."
  AGENTS=("SRE" "Infrastructure Architect" "Engineering Manager" "FinOps Lead" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "📐 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/capacity-planning-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Capacity Planning Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Capacity planning roundtable complete."; exit 0
fi

if [[ "$1" == "code-review-culture" ]]; then
  TOPIC="code review culture"; QUESTION="How do you build a healthy code review culture? Cover what to actually review vs automate, tone and feedback framing, async vs synchronous reviews, PR size guidelines, avoiding review bottlenecks, author vs reviewer responsibilities, and measuring review health with DORA metrics."
  AGENTS=("Staff Engineer" "Engineering Manager" "Senior Developer" "Tech Lead" "DevEx Lead")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "👁️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/code-review-culture-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Code Review Culture Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Code review culture roundtable complete."; exit 0
fi

if [[ "$1" == "multi-tenancy" ]]; then
  TOPIC="multi-tenancy architecture"; QUESTION="How do you design a multi-tenant SaaS system? Cover tenant isolation strategies (shared schema, schema-per-tenant, db-per-tenant), noisy neighbor prevention, tenant-aware routing, data portability, onboarding automation, and how isolation requirements evolve moving upmarket to enterprise."
  AGENTS=("SaaS Architect" "Backend Lead" "Security Engineer" "Product Manager" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "🏢 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/multi-tenancy-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Multi-Tenancy Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Multi-tenancy roundtable complete."; exit 0
fi

if [[ "$1" == "gitops" ]]; then
  TOPIC="GitOps"; QUESTION="How do you implement GitOps for infrastructure and application delivery? Cover the GitOps principles, Flux vs ArgoCD trade-offs, declarative infrastructure, drift detection and reconciliation, multi-cluster management, secrets management in GitOps (SOPS, Sealed Secrets), and handling hotfixes when git-first slows you down."
  AGENTS=("Platform Engineer" "DevOps Architect" "SRE" "Staff Engineer" "Security Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "🐙 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/gitops-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "GitOps Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ GitOps roundtable complete."; exit 0
fi

if [[ "$1" == "progressive-delivery" ]]; then
  TOPIC="progressive delivery"; QUESTION="How do you implement progressive delivery to ship safely? Cover feature flags (LaunchDarkly, Unleash, homegrown), canary releases, blue-green deployments, ring-based rollouts, automatic rollback triggers, and how progressive delivery separates deploy from release."
  AGENTS=("Release Engineer" "Platform Lead" "SRE" "Product Manager" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "🚀 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/progressive-delivery-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Progressive Delivery Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Progressive delivery roundtable complete."; exit 0
fi

if [[ "$1" == "data-quality" ]]; then
  TOPIC="data quality engineering"; QUESTION="How do you build data quality into pipelines? Cover data profiling, schema validation, statistical anomaly detection, Great Expectations vs dbt tests, data contracts between producers and consumers, lineage tracking, SLOs for data freshness and accuracy, and incident response for bad data."
  AGENTS=("Data Engineer" "Data Architect" "Analytics Lead" "Platform Engineer" "Data Scientist")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "🧹 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/data-quality-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Data Quality Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Data quality roundtable complete."; exit 0
fi

if [[ "$1" == "resilience-patterns" ]]; then
  TOPIC="resilience patterns"; QUESTION="What are the essential resilience patterns for distributed systems? Cover circuit breakers, bulkhead isolation, retry with exponential backoff and jitter, timeout budgets, fallback strategies, load shedding, and how to test resilience with chaos engineering before incidents find your weaknesses."
  AGENTS=("Distributed Systems Engineer" "SRE" "Backend Architect" "Platform Lead" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "🛡️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/resilience-patterns-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Resilience Patterns Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Resilience patterns roundtable complete."; exit 0
fi

if [[ "$1" == "zero-downtime-deploy" ]]; then
  TOPIC="zero-downtime deployments"; QUESTION="How do you achieve zero-downtime deployments for stateful systems? Cover database migrations with expand-contract pattern, connection draining, rolling updates vs blue-green, handling in-flight requests during deploys, long-running jobs, and online schema changes on large tables without locking."
  AGENTS=("Platform Engineer" "Backend Lead" "Database Engineer" "SRE" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "⬇️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/zero-downtime-deploy-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Zero-Downtime Deploy Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Zero-downtime deploy roundtable complete."; exit 0
fi

if [[ "$1" == "multi-region" ]]; then
  TOPIC="multi-region architecture"; QUESTION="How do you design a multi-region system? Cover active-active vs active-passive trade-offs, latency-based routing, data replication and conflict resolution, data sovereignty and regulatory requirements, failover automation, and the true operational complexity cost of going multi-region."
  AGENTS=("Distributed Systems Architect" "SRE" "Backend Lead" "Legal Counsel" "Staff Engineer")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "🌍 CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/multi-region-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Multi-Region Architecture Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Multi-region architecture roundtable complete."; exit 0
fi

if [[ "$1" == "idempotency" ]]; then
  TOPIC="idempotency design"; QUESTION="How do you design idempotent APIs and operations? Cover idempotency keys, at-least-once vs exactly-once delivery, safe vs unsafe HTTP methods, deduplication windows, database upsert patterns, handling concurrent duplicate requests, idempotency in distributed transactions, and testing idempotency."
  AGENTS=("Backend Architect" "API Designer" "Staff Engineer" "Payments Engineer" "Platform Lead")
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "♻️  CarPool: $TOPIC"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  OUT="$SAVE_DIR/idempotency-$(date +%Y%m%d-%H%M%S).txt"; mkdir -p "$SAVE_DIR"; echo "Idempotency Design Roundtable — $(date)" > "$OUT"
  for i in "${!AGENTS[@]}"; do AGENT="${AGENTS[$i]}"; echo ""; echo "🤖 [$AGENT] thinking..."
    REPLY=$(python3 - "$QUESTION" "$AGENT" <<'PYEOF'
import sys, urllib.request, json, os
q, agent = sys.argv[1], sys.argv[2]
prompt = f"You are a {agent}. Answer concisely in 3-5 sentences: {q}"
data = json.dumps({"model": os.environ.get("CARPOOL_MODEL","tinyllama"), "prompt": prompt, "stream": False}).encode()
req = urllib.request.Request("http://localhost:11434/api/generate", data=data, headers={"Content-Type":"application/json"})
res = urllib.request.urlopen(req, timeout=60)
print(json.loads(res.read())["response"].strip())
PYEOF
); echo ""; echo "[$AGENT]"; echo "$REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo ""; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "✅ Idempotency design roundtable complete."; exit 0
fi

# ── BATCH 2 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "product-sense" ]]; then
  Q="How do engineers develop strong product sense and customer empathy?"; AGENTS=(Octavia Lucidia Alice Aria Shellfish); OUT="$SAVE_DIR/product-sense-$(date +%s).txt"
  echo "🎯 Product Sense Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Product sense roundtable complete."; exit 0; fi

if [[ "$1" == "config-management" ]]; then
  Q="What are the best practices for managing application configuration across environments?"; AGENTS=(Octavia Alice Shellfish Aria Lucidia); OUT="$SAVE_DIR/config-management-$(date +%s).txt"
  echo "⚙️ Config Management Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Config management roundtable complete."; exit 0; fi

if [[ "$1" == "data-contracts" ]]; then
  Q="How do teams implement and enforce data contracts between services?"; AGENTS=(Alice Lucidia Octavia Shellfish Aria); OUT="$SAVE_DIR/data-contracts-$(date +%s).txt"
  echo "📋 Data Contracts Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data contracts roundtable complete."; exit 0; fi

if [[ "$1" == "pipeline-design" ]]; then
  Q="How should engineering teams design robust, maintainable data and CI/CD pipelines?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/pipeline-design-$(date +%s).txt"
  echo "🔧 Pipeline Design Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Pipeline design roundtable complete."; exit 0; fi

if [[ "$1" == "secrets-rotation" ]]; then
  Q="What strategies ensure secure, automated secrets rotation without downtime?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/secrets-rotation-$(date +%s).txt"
  echo "🔑 Secrets Rotation Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Secrets rotation roundtable complete."; exit 0; fi

if [[ "$1" == "threat-modeling" ]]; then
  Q="How do engineering teams integrate threat modeling into their development process?"; AGENTS=(Shellfish Aria Alice Octavia Lucidia); OUT="$SAVE_DIR/threat-modeling-$(date +%s).txt"
  echo "🕵️ Threat Modeling Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Threat modeling roundtable complete."; exit 0; fi

if [[ "$1" == "codebase-health" ]]; then
  Q="How do teams measure and systematically improve codebase health and reduce technical debt?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/codebase-health-$(date +%s).txt"
  echo "🏥 Codebase Health Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Codebase health roundtable complete."; exit 0; fi

if [[ "$1" == "api-monetization" ]]; then
  Q="What are the best approaches to API monetization and usage-based pricing models?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/api-monetization-$(date +%s).txt"
  echo "💰 API Monetization Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API monetization roundtable complete."; exit 0; fi

if [[ "$1" == "data-retention" ]]; then
  Q="How should teams design and implement data retention, archival, and deletion policies?"; AGENTS=(Alice Shellfish Octavia Lucidia Aria); OUT="$SAVE_DIR/data-retention-$(date +%s).txt"
  echo "🗄️ Data Retention Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data retention roundtable complete."; exit 0; fi

if [[ "$1" == "frontend-perf" ]]; then
  Q="What are the key techniques for optimizing frontend performance and Core Web Vitals?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/frontend-perf-$(date +%s).txt"
  echo "⚡ Frontend Performance Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Frontend performance roundtable complete."; exit 0; fi

# ── BATCH 3 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "websocket-scale" ]]; then
  Q="How do teams scale WebSocket connections to millions of concurrent users?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/websocket-scale-$(date +%s).txt"
  echo "🌐 WebSocket Scale Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ WebSocket scale roundtable complete."; exit 0; fi

if [[ "$1" == "saas-metrics" ]]; then
  Q="What engineering metrics matter most for SaaS product health: MRR, churn, NPS, and beyond?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/saas-metrics-$(date +%s).txt"
  echo "📊 SaaS Metrics Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ SaaS metrics roundtable complete."; exit 0; fi

if [[ "$1" == "pwa" ]]; then
  Q="What makes a great Progressive Web App and how do teams implement offline-first features?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/pwa-$(date +%s).txt"
  echo "📱 PWA Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ PWA roundtable complete."; exit 0; fi

if [[ "$1" == "customer-onboarding-eng" ]]; then
  Q="How does engineering enable delightful customer onboarding experiences at scale?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/customer-onboarding-eng-$(date +%s).txt"
  echo "🎉 Customer Onboarding Engineering Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Customer onboarding engineering roundtable complete."; exit 0; fi

if [[ "$1" == "cross-functional-collab" ]]; then
  Q="How do engineering teams build effective cross-functional collaboration with product and design?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/cross-functional-collab-$(date +%s).txt"
  echo "🤝 Cross-Functional Collaboration Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cross-functional collaboration roundtable complete."; exit 0; fi

if [[ "$1" == "db-migrations" ]]; then
  Q="What are proven strategies for zero-risk database schema migrations in production?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/db-migrations-$(date +%s).txt"
  echo "🔄 DB Migrations Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DB migrations roundtable complete."; exit 0; fi

if [[ "$1" == "ml-evaluation" ]]; then
  Q="How should teams design evaluation frameworks for ML models in production?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/ml-evaluation-$(date +%s).txt"
  echo "🤖 ML Evaluation Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ ML evaluation roundtable complete."; exit 0; fi

if [[ "$1" == "commit-strategy" ]]; then
  Q="What commit strategies—conventional commits, trunk-based, feature branches—work best for different team sizes?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/commit-strategy-$(date +%s).txt"
  echo "📝 Commit Strategy Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Commit strategy roundtable complete."; exit 0; fi

if [[ "$1" == "load-balancing" ]]; then
  Q="How do teams choose between L4 and L7 load balancers and configure them for resilience?"; AGENTS=(Octavia Alice Shellfish Lucidia Aria); OUT="$SAVE_DIR/load-balancing-$(date +%s).txt"
  echo "⚖️ Load Balancing Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Load balancing roundtable complete."; exit 0; fi

if [[ "$1" == "time-series-db" ]]; then
  Q="When should teams reach for a time-series database like InfluxDB, TimescaleDB, or Prometheus?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/time-series-db-$(date +%s).txt"
  echo "📈 Time-Series DB Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Time-series DB roundtable complete."; exit 0; fi

# ── BATCH 4 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "on-call-health" ]]; then
  Q="How do teams build sustainable on-call rotations that don't burn out engineers?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/on-call-health-$(date +%s).txt"
  echo "🚨 On-Call Health Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ On-call health roundtable complete."; exit 0; fi

if [[ "$1" == "data-lake-arch" ]]; then
  Q="How should teams design a data lake architecture that stays queryable and doesn't become a swamp?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/data-lake-arch-$(date +%s).txt"
  echo "🏞️ Data Lake Architecture Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data lake architecture roundtable complete."; exit 0; fi

if [[ "$1" == "content-delivery" ]]; then
  Q="What are the best CDN strategies for global content delivery with minimal latency?"; AGENTS=(Octavia Aria Alice Lucidia Shellfish); OUT="$SAVE_DIR/content-delivery-$(date +%s).txt"
  echo "🌍 Content Delivery Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Content delivery roundtable complete."; exit 0; fi

if [[ "$1" == "message-ordering" ]]; then
  Q="How do distributed systems guarantee message ordering and exactly-once delivery?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/message-ordering-$(date +%s).txt"
  echo "📨 Message Ordering Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Message ordering roundtable complete."; exit 0; fi

if [[ "$1" == "schema-registry" ]]; then
  Q="Why do teams need a schema registry with Kafka and how do they manage schema evolution?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/schema-registry-$(date +%s).txt"
  echo "📐 Schema Registry Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Schema registry roundtable complete."; exit 0; fi

if [[ "$1" == "capacity-modeling" ]]; then
  Q="How do teams build capacity models that accurately predict infrastructure needs 6-12 months out?"; AGENTS=(Octavia Lucidia Alice Aria Shellfish); OUT="$SAVE_DIR/capacity-modeling-$(date +%s).txt"
  echo "📐 Capacity Modeling Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Capacity modeling roundtable complete."; exit 0; fi

if [[ "$1" == "leadership-principles" ]]; then
  Q="What leadership principles do the best engineering leaders consistently embody?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/leadership-principles-$(date +%s).txt"
  echo "🌟 Leadership Principles Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Leadership principles roundtable complete."; exit 0; fi

if [[ "$1" == "developer-productivity" ]]; then
  Q="How do teams measure and improve developer productivity without gaming metrics?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/developer-productivity-$(date +%s).txt"
  echo "⚡ Developer Productivity Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Developer productivity roundtable complete."; exit 0; fi

if [[ "$1" == "async-api-design" ]]; then
  Q="When should APIs be async vs sync, and how do you design great async APIs with webhooks or polling?"; AGENTS=(Alice Aria Octavia Lucidia Shellfish); OUT="$SAVE_DIR/async-api-design-$(date +%s).txt"
  echo "⏳ Async API Design Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Async API design roundtable complete."; exit 0; fi

if [[ "$1" == "technical-roadmap" ]]; then
  Q="How do engineering teams build technical roadmaps that align with business strategy?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/technical-roadmap-$(date +%s).txt"
  echo "🗺️ Technical Roadmap Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Technical roadmap roundtable complete."; exit 0; fi

# ── BATCH 5 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "slo-crafting" ]]; then
  Q="How do teams craft meaningful SLOs that balance reliability with development velocity?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/slo-crafting-$(date +%s).txt"
  echo "🎯 SLO Crafting Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ SLO crafting roundtable complete."; exit 0; fi

if [[ "$1" == "developer-tooling" ]]; then
  Q="What internal developer tooling investments have the highest ROI for engineering teams?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/developer-tooling-$(date +%s).txt"
  echo "🔧 Developer Tooling Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Developer tooling roundtable complete."; exit 0; fi

if [[ "$1" == "ab-platform" ]]; then
  Q="How do teams build or choose an A/B testing platform that enables rapid product experimentation?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/ab-platform-$(date +%s).txt"
  echo "🧪 A/B Platform Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ A/B platform roundtable complete."; exit 0; fi

if [[ "$1" == "identity-platform" ]]; then
  Q="What does it take to build a robust identity platform handling auth, RBAC, and SSO at scale?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/identity-platform-$(date +%s).txt"
  echo "🪪 Identity Platform Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Identity platform roundtable complete."; exit 0; fi

if [[ "$1" == "db-indexing" ]]; then
  Q="How do engineers diagnose slow queries and design indexes that remain effective as data grows?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/db-indexing-$(date +%s).txt"
  echo "🔍 DB Indexing Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DB indexing roundtable complete."; exit 0; fi

if [[ "$1" == "architectural-patterns" ]]; then
  Q="When do teams choose monolith vs SOA vs microservices vs serverless vs modular monolith?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/architectural-patterns-$(date +%s).txt"
  echo "🏛️ Architectural Patterns Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Architectural patterns roundtable complete."; exit 0; fi

if [[ "$1" == "content-moderation" ]]; then
  Q="How do platforms build scalable, fair content moderation systems combining ML and human review?"; AGENTS=(Aria Shellfish Lucidia Alice Octavia); OUT="$SAVE_DIR/content-moderation-$(date +%s).txt"
  echo "🛡️ Content Moderation Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Content moderation roundtable complete."; exit 0; fi

if [[ "$1" == "async-communication" ]]; then
  Q="How do engineering teams use async communication effectively without losing team cohesion?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/async-communication-$(date +%s).txt"
  echo "💬 Async Communication Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Async communication roundtable complete."; exit 0; fi

if [[ "$1" == "team-scaling" ]]; then
  Q="What engineering practices and structures work best when scaling from 5 to 50 to 500 engineers?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/team-scaling-$(date +%s).txt"
  echo "📈 Team Scaling Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Team scaling roundtable complete."; exit 0; fi

if [[ "$1" == "data-warehouse" ]]; then
  Q="How do teams design a modern data warehouse with Snowflake, BigQuery, or Redshift at the core?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/data-warehouse-$(date +%s).txt"
  echo "🏭 Data Warehouse Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data warehouse roundtable complete."; exit 0; fi

# ── BATCH 6 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "self-healing-systems" ]]; then
  Q="What techniques let distributed systems detect and recover from failures automatically?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/self-healing-systems-$(date +%s).txt"
  echo "🔄 Self-Healing Systems Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Self-healing systems roundtable complete."; exit 0; fi

if [[ "$1" == "zero-downtime-db" ]]; then
  Q="How do teams perform zero-downtime database upgrades and large table alterations?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/zero-downtime-db-$(date +%s).txt"
  echo "🗄️ Zero-Downtime DB Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Zero-downtime DB roundtable complete."; exit 0; fi

if [[ "$1" == "embedded-analytics" ]]; then
  Q="How do product teams embed analytics and reporting features directly into their applications?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/embedded-analytics-$(date +%s).txt"
  echo "📊 Embedded Analytics Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Embedded analytics roundtable complete."; exit 0; fi

if [[ "$1" == "canary-analysis" ]]; then
  Q="How do teams implement automated canary analysis to catch regressions before full rollout?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/canary-analysis-$(date +%s).txt"
  echo "🐦 Canary Analysis Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Canary analysis roundtable complete."; exit 0; fi

if [[ "$1" == "dev-environment" ]]; then
  Q="What makes an ideal developer environment: local vs cloud dev, devcontainers, and ephemeral envs?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/dev-environment-$(date +%s).txt"
  echo "💻 Dev Environment Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dev environment roundtable complete."; exit 0; fi

if [[ "$1" == "workflow-engine" ]]; then
  Q="When should teams build or use a workflow engine like Temporal, Airflow, or Conductor?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/workflow-engine-$(date +%s).txt"
  echo "⚙️ Workflow Engine Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Workflow engine roundtable complete."; exit 0; fi

if [[ "$1" == "trust-safety" ]]; then
  Q="How do Trust and Safety engineering teams build systems that protect users at internet scale?"; AGENTS=(Shellfish Aria Lucidia Alice Octavia); OUT="$SAVE_DIR/trust-safety-$(date +%s).txt"
  echo "🛡️ Trust & Safety Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Trust & safety roundtable complete."; exit 0; fi

if [[ "$1" == "data-catalog" ]]; then
  Q="How do organizations build internal data catalogs to make data discoverable and trusted?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/data-catalog-$(date +%s).txt"
  echo "📚 Data Catalog Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data catalog roundtable complete."; exit 0; fi

if [[ "$1" == "platform-product-fit" ]]; then
  Q="How do internal platform teams achieve product-market fit with their engineering customers?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/platform-product-fit-$(date +%s).txt"
  echo "🎯 Platform-Product Fit Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Platform-product fit roundtable complete."; exit 0; fi

if [[ "$1" == "low-code-arch" ]]; then
  Q="How should architects think about integrating low-code and no-code tools into enterprise systems?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/low-code-arch-$(date +%s).txt"
  echo "🔌 Low-Code Architecture Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Low-code architecture roundtable complete."; exit 0; fi

# ── BATCH 7 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "mobile-offline" ]]; then
  Q="How do mobile teams implement offline-first sync patterns that handle conflicts gracefully?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/mobile-offline-$(date +%s).txt"
  echo "📱 Mobile Offline Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Mobile offline roundtable complete."; exit 0; fi

if [[ "$1" == "multicloud-networking" ]]; then
  Q="How do teams architect networking when workloads span AWS, GCP, Azure, and bare metal?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/multicloud-networking-$(date +%s).txt"
  echo "🌐 Multi-Cloud Networking Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multi-cloud networking roundtable complete."; exit 0; fi

if [[ "$1" == "semantic-versioning" ]]; then
  Q="How should teams apply semantic versioning to APIs, libraries, and microservices?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/semantic-versioning-$(date +%s).txt"
  echo "🏷️ Semantic Versioning Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Semantic versioning roundtable complete."; exit 0; fi

if [[ "$1" == "api-composition" ]]; then
  Q="What patterns—BFF, API gateway, GraphQL federation—work best for composing APIs across services?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/api-composition-$(date +%s).txt"
  echo "🔗 API Composition Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API composition roundtable complete."; exit 0; fi

if [[ "$1" == "eng-strategy" ]]; then
  Q="How do engineering leaders write and communicate strategy that actually changes team behavior?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-strategy-$(date +%s).txt"
  echo "🧭 Engineering Strategy Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering strategy roundtable complete."; exit 0; fi

if [[ "$1" == "data-encryption" ]]; then
  Q="How do teams implement encryption at rest and in transit without killing performance?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/data-encryption-$(date +%s).txt"
  echo "🔐 Data Encryption Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data encryption roundtable complete."; exit 0; fi

if [[ "$1" == "feature-lifecycle" ]]; then
  Q="How do teams manage the full lifecycle of features from ideation through deprecation?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/feature-lifecycle-$(date +%s).txt"
  echo "🔄 Feature Lifecycle Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Feature lifecycle roundtable complete."; exit 0; fi

if [[ "$1" == "recruitment-funnel" ]]; then
  Q="How should engineering teams design hiring funnels that find exceptional candidates fairly?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/recruitment-funnel-$(date +%s).txt"
  echo "🎯 Recruitment Funnel Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Recruitment funnel roundtable complete."; exit 0; fi

if [[ "$1" == "chaos-advanced" ]]; then
  Q="How do teams move beyond basic chaos engineering to proactive resilience verification?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/chaos-advanced-$(date +%s).txt"
  echo "💥 Advanced Chaos Engineering Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced chaos engineering roundtable complete."; exit 0; fi

if [[ "$1" == "gitops-advanced" ]]; then
  Q="What are the advanced GitOps patterns for managing config drift, secrets, and multi-cluster deployments?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/gitops-advanced-$(date +%s).txt"
  echo "🔄 Advanced GitOps Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced GitOps roundtable complete."; exit 0; fi

# ── BATCH 8 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "k8s-networking" ]]; then
  Q="How do teams design Kubernetes networking with CNI plugins, service meshes, and ingress controllers?"; AGENTS=(Octavia Alice Shellfish Lucidia Aria); OUT="$SAVE_DIR/k8s-networking-$(date +%s).txt"
  echo "⎈ K8s Networking Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ K8s networking roundtable complete."; exit 0; fi

if [[ "$1" == "ml-feature-engineering" ]]; then
  Q="How do ML teams build robust feature pipelines and avoid training-serving skew?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/ml-feature-engineering-$(date +%s).txt"
  echo "🤖 ML Feature Engineering Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ ML feature engineering roundtable complete."; exit 0; fi

if [[ "$1" == "cost-per-request" ]]; then
  Q="How do teams measure and optimize cost-per-request to improve unit economics at scale?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/cost-per-request-$(date +%s).txt"
  echo "💰 Cost-Per-Request Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cost-per-request roundtable complete."; exit 0; fi

if [[ "$1" == "product-analytics" ]]; then
  Q="How do product and engineering teams instrument apps to collect actionable product analytics?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/product-analytics-$(date +%s).txt"
  echo "📊 Product Analytics Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Product analytics roundtable complete."; exit 0; fi

if [[ "$1" == "container-security" ]]; then
  Q="What security controls should every containerized deployment enforce from build to runtime?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/container-security-$(date +%s).txt"
  echo "🔒 Container Security Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Container security roundtable complete."; exit 0; fi

if [[ "$1" == "eng-okrs" ]]; then
  Q="How do engineering teams set OKRs that drive real impact rather than gaming metrics?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-okrs-$(date +%s).txt"
  echo "🎯 Engineering OKRs Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering OKRs roundtable complete."; exit 0; fi

if [[ "$1" == "latency-budget" ]]; then
  Q="How do teams allocate latency budgets across distributed service calls to meet user-facing SLOs?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/latency-budget-$(date +%s).txt"
  echo "⏱️ Latency Budget Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Latency budget roundtable complete."; exit 0; fi

if [[ "$1" == "api-economics" ]]; then
  Q="How do platform companies think about API pricing, rate limiting, and developer ROI?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/api-economics-$(date +%s).txt"
  echo "💹 API Economics Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API economics roundtable complete."; exit 0; fi

if [[ "$1" == "data-deletion" ]]; then
  Q="How do systems implement GDPR-compliant right-to-erasure across distributed data stores?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/data-deletion-$(date +%s).txt"
  echo "🗑️ Data Deletion Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data deletion roundtable complete."; exit 0; fi

if [[ "$1" == "multi-tenant-saas" ]]; then
  Q="How do SaaS companies implement multi-tenancy isolation across database, compute, and networking layers?"; AGENTS=(Octavia Shellfish Alice Lucidia Aria); OUT="$SAVE_DIR/multi-tenant-saas-$(date +%s).txt"
  echo "🏢 Multi-Tenant SaaS Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multi-tenant SaaS roundtable complete."; exit 0; fi

# ── BATCH 9 ────────────────────────────────────────────────────────────────────
if [[ "$1" == "observability-culture" ]]; then
  Q="How do engineering leaders build a culture of observability where everyone owns production health?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/observability-culture-$(date +%s).txt"
  echo "👁️ Observability Culture Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Observability culture roundtable complete."; exit 0; fi

if [[ "$1" == "security-champions" ]]; then
  Q="How do organizations build a security champions program that scales security culture across teams?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/security-champions-$(date +%s).txt"
  echo "🏆 Security Champions Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Security champions roundtable complete."; exit 0; fi

if [[ "$1" == "release-management" ]]; then
  Q="How do teams design release processes that are fast, safe, and auditable?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/release-management-$(date +%s).txt"
  echo "🚀 Release Management Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Release management roundtable complete."; exit 0; fi

if [[ "$1" == "distributed-locks" ]]; then
  Q="When and how should teams use distributed locks, and what are the failure modes to avoid?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/distributed-locks-$(date +%s).txt"
  echo "🔒 Distributed Locks Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Distributed locks roundtable complete."; exit 0; fi

if [[ "$1" == "cold-start-opt" ]]; then
  Q="How do teams reduce cold start latency in serverless, containers, and JVM services?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/cold-start-opt-$(date +%s).txt"
  echo "❄️ Cold Start Optimization Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cold start optimization roundtable complete."; exit 0; fi

if [[ "$1" == "eng-brand" ]]; then
  Q="How do engineering teams build external brand recognition to attract top talent and partnerships?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-brand-$(date +%s).txt"
  echo "🌟 Engineering Brand Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering brand roundtable complete."; exit 0; fi

if [[ "$1" == "data-pipeline-testing" ]]; then
  Q="How do data engineering teams test pipelines to catch data quality issues before production?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/data-pipeline-testing-$(date +%s).txt"
  echo "🧪 Data Pipeline Testing Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data pipeline testing roundtable complete."; exit 0; fi

if [[ "$1" == "async-design-patterns" ]]; then
  Q="What are the key async design patterns—saga, outbox, choreography—and when do you use each?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/async-design-patterns-$(date +%s).txt"
  echo "⏳ Async Design Patterns Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Async design patterns roundtable complete."; exit 0; fi

if [[ "$1" == "system-design-interviews" ]]; then
  Q="How do the best engineers approach system design interview questions, and what makes answers stand out?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/system-design-interviews-$(date +%s).txt"
  echo "🏗️ System Design Interviews Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ System design interviews roundtable complete."; exit 0; fi

if [[ "$1" == "microservice-patterns" ]]; then
  Q="What patterns—sidecar, ambassador, anti-corruption layer—solve the hardest microservice challenges?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/microservice-patterns-$(date +%s).txt"
  echo "🔧 Microservice Patterns Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Microservice patterns roundtable complete."; exit 0; fi

# ── BATCH 10 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "graph-databases" ]]; then
  Q="When should teams reach for graph databases like Neo4j or Neptune instead of relational DBs?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/graph-databases-$(date +%s).txt"
  echo "🕸️ Graph Databases Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Graph databases roundtable complete."; exit 0; fi

if [[ "$1" == "vector-search" ]]; then
  Q="How do teams integrate vector search and semantic retrieval into production applications?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/vector-search-$(date +%s).txt"
  echo "🔍 Vector Search Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Vector search roundtable complete."; exit 0; fi

if [[ "$1" == "edge-computing" ]]; then
  Q="How does edge computing change application architecture and what moves to the edge vs origin?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/edge-computing-$(date +%s).txt"
  echo "⚡ Edge Computing Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Edge computing roundtable complete."; exit 0; fi

if [[ "$1" == "supply-chain-security" ]]; then
  Q="How do teams protect against software supply chain attacks through SBOM, signing, and policy?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/supply-chain-security-$(date +%s).txt"
  echo "🔒 Supply Chain Security Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Supply chain security roundtable complete."; exit 0; fi

if [[ "$1" == "event-sourcing" ]]; then
  Q="When is event sourcing the right pattern and how do teams avoid common pitfalls?"; AGENTS=(Lucidia Octavia Alice Shellfish Aria); OUT="$SAVE_DIR/event-sourcing-$(date +%s).txt"
  echo "📜 Event Sourcing Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Event sourcing roundtable complete."; exit 0; fi

if [[ "$1" == "fintech-compliance" ]]; then
  Q="What engineering challenges are unique to fintech: PCI-DSS, SOX, real-time fraud, and reconciliation?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/fintech-compliance-$(date +%s).txt"
  echo "🏦 Fintech Compliance Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Fintech compliance roundtable complete."; exit 0; fi

if [[ "$1" == "realtime-collaboration" ]]; then
  Q="How do teams build real-time collaborative features like Google Docs using CRDTs and OT?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/realtime-collaboration-$(date +%s).txt"
  echo "🤝 Realtime Collaboration Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Realtime collaboration roundtable complete."; exit 0; fi

if [[ "$1" == "developer-experience" ]]; then
  Q="How do platform teams measure and improve developer experience across the entire software delivery lifecycle?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/developer-experience-$(date +%s).txt"
  echo "💻 Developer Experience Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Developer experience roundtable complete."; exit 0; fi

if [[ "$1" == "streaming-architecture" ]]; then
  Q="When should teams adopt streaming architecture with Kafka or Kinesis over traditional batch processing?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/streaming-architecture-$(date +%s).txt"
  echo "🌊 Streaming Architecture Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Streaming architecture roundtable complete."; exit 0; fi

if [[ "$1" == "post-quantum-security" ]]; then
  Q="How should engineering teams begin preparing their cryptographic infrastructure for post-quantum threats?"; AGENTS=(Shellfish Lucidia Octavia Alice Aria); OUT="$SAVE_DIR/post-quantum-security-$(date +%s).txt"
  echo "🔮 Post-Quantum Security Roundtable"; echo "$Q" | tee "$OUT"; echo ""; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "" >> "$OUT"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Post-quantum security roundtable complete."; exit 0; fi

# ── BATCH 11 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "wasm" ]]; then
  Q="How is WebAssembly changing backend and edge computing beyond the browser?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/wasm-$(date +%s).txt"
  echo "🔩 WebAssembly Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ WebAssembly roundtable complete."; exit 0; fi

if [[ "$1" == "api-gateway-patterns" ]]; then
  Q="What patterns make an API gateway more than just a reverse proxy—rate limiting, auth, transformation?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/api-gateway-patterns-$(date +%s).txt"
  echo "🚪 API Gateway Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API gateway patterns roundtable complete."; exit 0; fi

if [[ "$1" == "zero-trust" ]]; then
  Q="How do teams implement zero-trust architecture across their entire infrastructure stack?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/zero-trust-$(date +%s).txt"
  echo "🔒 Zero Trust Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Zero trust roundtable complete."; exit 0; fi

if [[ "$1" == "incident-postmortems" ]]; then
  Q="How do blameless postmortems drive real systemic improvements rather than surface-level fixes?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/incident-postmortems-$(date +%s).txt"
  echo "📋 Incident Postmortems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Incident postmortems roundtable complete."; exit 0; fi

if [[ "$1" == "search-architecture" ]]; then
  Q="How do teams build scalable search with Elasticsearch, Typesense, or Meilisearch?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/search-architecture-$(date +%s).txt"
  echo "🔍 Search Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Search architecture roundtable complete."; exit 0; fi

if [[ "$1" == "payment-systems" ]]; then
  Q="What engineering challenges are unique to building and scaling payment processing systems?"; AGENTS=(Shellfish Aria Lucidia Alice Octavia); OUT="$SAVE_DIR/payment-systems-$(date +%s).txt"
  echo "💳 Payment Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Payment systems roundtable complete."; exit 0; fi

if [[ "$1" == "infra-as-code" ]]; then
  Q="How do teams structure Terraform or Pulumi codebases that scale to hundreds of modules?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/infra-as-code-$(date +%s).txt"
  echo "🏗️ Infrastructure as Code Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Infrastructure as code roundtable complete."; exit 0; fi

if [[ "$1" == "accessibility-eng" ]]; then
  Q="How do engineering teams build and maintain WCAG-compliant accessible products at scale?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/accessibility-eng-$(date +%s).txt"
  echo "♿ Accessibility Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Accessibility engineering roundtable complete."; exit 0; fi

if [[ "$1" == "distributed-tracing" ]]; then
  Q="How do teams implement distributed tracing with OpenTelemetry to debug complex service interactions?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/distributed-tracing-$(date +%s).txt"
  echo "🔭 Distributed Tracing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Distributed tracing roundtable complete."; exit 0; fi

if [[ "$1" == "platform-engineering" ]]; then
  Q="What does it mean to build a true internal developer platform and what golden paths should it provide?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/platform-engineering-$(date +%s).txt"
  echo "🏗️ Platform Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Platform engineering roundtable complete."; exit 0; fi

# ── BATCH 12 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "service-mesh" ]]; then
  Q="When does a service mesh like Istio or Linkerd add value vs add complexity?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/service-mesh-$(date +%s).txt"
  echo "🕸️ Service Mesh Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Service mesh roundtable complete."; exit 0; fi

if [[ "$1" == "feature-store" ]]; then
  Q="What is a feature store, when do ML teams need one, and how is it architected?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/feature-store-$(date +%s).txt"
  echo "🗂️ Feature Store Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Feature store roundtable complete."; exit 0; fi

if [[ "$1" == "compliance-automation" ]]; then
  Q="How do teams automate SOC2, ISO27001, and HIPAA compliance evidence collection?"; AGENTS=(Shellfish Alice Lucidia Octavia Aria); OUT="$SAVE_DIR/compliance-automation-$(date +%s).txt"
  echo "📜 Compliance Automation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Compliance automation roundtable complete."; exit 0; fi

if [[ "$1" == "rate-limiting-advanced" ]]; then
  Q="What are the most sophisticated rate limiting algorithms—token bucket, sliding window, adaptive—and when to use each?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/rate-limiting-advanced-$(date +%s).txt"
  echo "🚦 Advanced Rate Limiting Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced rate limiting roundtable complete."; exit 0; fi

if [[ "$1" == "ml-ops" ]]; then
  Q="What does mature MLOps look like: model registry, drift detection, retraining pipelines?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/ml-ops-$(date +%s).txt"
  echo "🤖 MLOps Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ MLOps roundtable complete."; exit 0; fi

if [[ "$1" == "green-engineering" ]]; then
  Q="How do engineering teams measure and reduce their software's carbon footprint and energy usage?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/green-engineering-$(date +%s).txt"
  echo "🌱 Green Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Green engineering roundtable complete."; exit 0; fi

if [[ "$1" == "caching-strategies" ]]; then
  Q="What are the cache invalidation patterns that actually work at scale—write-through, write-behind, CDN purge?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/caching-strategies-$(date +%s).txt"
  echo "⚡ Caching Strategies Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Caching strategies roundtable complete."; exit 0; fi

if [[ "$1" == "notification-systems" ]]; then
  Q="How do teams build notification systems that handle push, email, SMS, and in-app at scale without spamming users?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/notification-systems-$(date +%s).txt"
  echo "🔔 Notification Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Notification systems roundtable complete."; exit 0; fi

if [[ "$1" == "documentation-culture" ]]; then
  Q="How do engineering teams build a culture where documentation is maintained, not abandoned?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/documentation-culture-$(date +%s).txt"
  echo "📖 Documentation Culture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Documentation culture roundtable complete."; exit 0; fi

if [[ "$1" == "iot-architecture" ]]; then
  Q="What are the key architectural decisions when connecting millions of IoT devices to the cloud?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/iot-architecture-$(date +%s).txt"
  echo "🌐 IoT Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ IoT architecture roundtable complete."; exit 0; fi

# ── BATCH 13 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "llm-prod" ]]; then
  Q="What does it take to run LLMs reliably in production—inference optimization, fallbacks, cost control?"; AGENTS=(Lucidia Octavia Alice Shellfish Aria); OUT="$SAVE_DIR/llm-prod-$(date +%s).txt"
  echo "🤖 LLM in Production Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ LLM in production roundtable complete."; exit 0; fi

if [[ "$1" == "rag-systems" ]]; then
  Q="How do teams build high-quality RAG systems that retrieve the right context for LLMs?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/rag-systems-$(date +%s).txt"
  echo "📚 RAG Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ RAG systems roundtable complete."; exit 0; fi

if [[ "$1" == "ai-agents-infra" ]]; then
  Q="What infrastructure primitives do autonomous AI agents need—memory, tools, sandboxing, observability?"; AGENTS=(Lucidia Octavia Shellfish Alice Aria); OUT="$SAVE_DIR/ai-agents-infra-$(date +%s).txt"
  echo "🧠 AI Agents Infrastructure Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI agents infrastructure roundtable complete."; exit 0; fi

if [[ "$1" == "prompt-engineering" ]]; then
  Q="What prompt engineering techniques—chain-of-thought, few-shot, structured outputs—produce reliable LLM results?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/prompt-engineering-$(date +%s).txt"
  echo "💬 Prompt Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Prompt engineering roundtable complete."; exit 0; fi

if [[ "$1" == "fine-tuning" ]]; then
  Q="When should teams fine-tune vs use RAG vs few-shot prompting, and what does fine-tuning require?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/fine-tuning-$(date +%s).txt"
  echo "🎯 Fine-Tuning Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Fine-tuning roundtable complete."; exit 0; fi

if [[ "$1" == "ai-safety-eng" ]]; then
  Q="How do engineering teams build guardrails, evals, and monitoring to keep AI systems safe and aligned?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/ai-safety-eng-$(date +%s).txt"
  echo "🛡️ AI Safety Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI safety engineering roundtable complete."; exit 0; fi

if [[ "$1" == "model-serving" ]]; then
  Q="How do teams optimize model serving latency and throughput with batching, quantization, and caching?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/model-serving-$(date +%s).txt"
  echo "⚡ Model Serving Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Model serving roundtable complete."; exit 0; fi

if [[ "$1" == "embeddings" ]]; then
  Q="How do teams choose, generate, and store embeddings for semantic search, recommendations, and clustering?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/embeddings-$(date +%s).txt"
  echo "🔢 Embeddings Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Embeddings roundtable complete."; exit 0; fi

if [[ "$1" == "ai-cost-optimization" ]]; then
  Q="How do teams control and optimize AI inference costs across multiple models and providers?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/ai-cost-optimization-$(date +%s).txt"
  echo "💰 AI Cost Optimization Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI cost optimization roundtable complete."; exit 0; fi

if [[ "$1" == "multimodal-ai" ]]; then
  Q="How do engineering teams integrate multimodal AI—vision, audio, and text—into production applications?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/multimodal-ai-$(date +%s).txt"
  echo "🎨 Multimodal AI Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multimodal AI roundtable complete."; exit 0; fi

# ── BATCH 14 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "backend-for-frontend" ]]; then
  Q="When does the Backend-for-Frontend pattern solve real problems and when does it add unnecessary complexity?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/backend-for-frontend-$(date +%s).txt"
  echo "🎭 BFF Pattern Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ BFF pattern roundtable complete."; exit 0; fi

if [[ "$1" == "trunk-based-dev" ]]; then
  Q="How do teams successfully adopt trunk-based development and make it work without breaking production?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/trunk-based-dev-$(date +%s).txt"
  echo "🌳 Trunk-Based Development Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Trunk-based development roundtable complete."; exit 0; fi

if [[ "$1" == "geo-distributed" ]]; then
  Q="How do teams architect globally distributed systems that feel local to every user?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/geo-distributed-$(date +%s).txt"
  echo "🌍 Geo-Distributed Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Geo-distributed systems roundtable complete."; exit 0; fi

if [[ "$1" == "devrel-eng" ]]; then
  Q="How do developer relations and engineering collaborate to build thriving developer ecosystems?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/devrel-eng-$(date +%s).txt"
  echo "🌐 DevRel Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DevRel engineering roundtable complete."; exit 0; fi

if [[ "$1" == "storage-tiering" ]]; then
  Q="How do systems implement intelligent storage tiering to balance cost and performance across hot, warm, cold data?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/storage-tiering-$(date +%s).txt"
  echo "🗄️ Storage Tiering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Storage tiering roundtable complete."; exit 0; fi

if [[ "$1" == "api-testing" ]]; then
  Q="What are the best approaches to contract testing, integration testing, and API fuzzing?"; AGENTS=(Alice Lucidia Octavia Shellfish Aria); OUT="$SAVE_DIR/api-testing-$(date +%s).txt"
  echo "🧪 API Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API testing roundtable complete."; exit 0; fi

if [[ "$1" == "incident-response" ]]; then
  Q="How do teams build incident response playbooks that work under pressure at 3am?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/incident-response-$(date +%s).txt"
  echo "🚨 Incident Response Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Incident response roundtable complete."; exit 0; fi

if [[ "$1" == "monorepo-at-scale" ]]; then
  Q="How do teams manage monorepos at scale with Nx, Turborepo, or Bazel without losing build speed?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/monorepo-at-scale-$(date +%s).txt"
  echo "📦 Monorepo at Scale Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Monorepo at scale roundtable complete."; exit 0; fi

if [[ "$1" == "dark-launching" ]]; then
  Q="How do teams use dark launching and shadow traffic to test changes safely before exposing users?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/dark-launching-$(date +%s).txt"
  echo "🌑 Dark Launching Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dark launching roundtable complete."; exit 0; fi

if [[ "$1" == "eng-metrics" ]]; then
  Q="Which engineering metrics—DORA, SPACE, FLOW—give the truest picture of team health and velocity?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-metrics-$(date +%s).txt"
  echo "📊 Engineering Metrics Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering metrics roundtable complete."; exit 0; fi

# ── BATCH 15 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "passwordless-auth" ]]; then
  Q="How do teams implement passkeys and passwordless authentication for better UX and security?"; AGENTS=(Shellfish Aria Alice Lucidia Octavia); OUT="$SAVE_DIR/passwordless-auth-$(date +%s).txt"
  echo "🔑 Passwordless Auth Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Passwordless auth roundtable complete."; exit 0; fi

if [[ "$1" == "cost-allocation" ]]; then
  Q="How do platform teams implement cloud cost allocation and showback/chargeback across engineering orgs?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/cost-allocation-$(date +%s).txt"
  echo "💰 Cost Allocation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cost allocation roundtable complete."; exit 0; fi

if [[ "$1" == "composable-architecture" ]]; then
  Q="What is composable architecture and how does it differ from microservices in practice?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/composable-architecture-$(date +%s).txt"
  echo "🧩 Composable Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Composable architecture roundtable complete."; exit 0; fi

if [[ "$1" == "ephemeral-environments" ]]; then
  Q="How do teams spin up ephemeral preview environments for every PR and make them cost-effective?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/ephemeral-environments-$(date +%s).txt"
  echo "🏗️ Ephemeral Environments Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Ephemeral environments roundtable complete."; exit 0; fi

if [[ "$1" == "site-reliability" ]]; then
  Q="How do SRE teams implement error budgets, toil reduction, and reliability reviews that actually change engineering behavior?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/site-reliability-$(date +%s).txt"
  echo "🎯 Site Reliability Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Site reliability roundtable complete."; exit 0; fi

if [[ "$1" == "mobile-ci-cd" ]]; then
  Q="How do teams build fast, reliable CI/CD pipelines for iOS and Android that don't take 45 minutes?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/mobile-ci-cd-$(date +%s).txt"
  echo "📱 Mobile CI/CD Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Mobile CI/CD roundtable complete."; exit 0; fi

if [[ "$1" == "http3-quic" ]]; then
  Q="How does HTTP/3 and QUIC change web performance and what does adoption look like in practice?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/http3-quic-$(date +%s).txt"
  echo "⚡ HTTP/3 & QUIC Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ HTTP/3 & QUIC roundtable complete."; exit 0; fi

if [[ "$1" == "chaos-culture" ]]; then
  Q="How do teams build a chaos engineering culture where game days are celebrated not feared?"; AGENTS=(Lucidia Alice Octavia Shellfish Aria); OUT="$SAVE_DIR/chaos-culture-$(date +%s).txt"
  echo "💥 Chaos Culture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Chaos culture roundtable complete."; exit 0; fi

if [[ "$1" == "build-vs-buy" ]]; then
  Q="How should engineering teams make principled build-vs-buy decisions for infrastructure and tooling?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/build-vs-buy-$(date +%s).txt"
  echo "🏗️ Build vs Buy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Build vs buy roundtable complete."; exit 0; fi

if [[ "$1" == "dbt-transformations" ]]; then
  Q="How do data teams use dbt to build reliable, tested, documented data transformation pipelines?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/dbt-transformations-$(date +%s).txt"
  echo "🔄 DBT Transformations Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DBT transformations roundtable complete."; exit 0; fi

# ── BATCH 16 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "api-backwards-compat" ]]; then
  Q="How do teams maintain API backwards compatibility while still shipping breaking improvements?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/api-backwards-compat-$(date +%s).txt"
  echo "↩️ API Backwards Compatibility Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API backwards compatibility roundtable complete."; exit 0; fi

if [[ "$1" == "database-sharding" ]]; then
  Q="When should teams shard their database and what sharding strategies work at different scales?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/database-sharding-$(date +%s).txt"
  echo "🗄️ Database Sharding Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Database sharding roundtable complete."; exit 0; fi

if [[ "$1" == "kubernetes-cost" ]]; then
  Q="How do teams right-size Kubernetes workloads and reduce cluster costs without impacting reliability?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/kubernetes-cost-$(date +%s).txt"
  echo "⎈ Kubernetes Cost Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Kubernetes cost roundtable complete."; exit 0; fi

if [[ "$1" == "eng-culture" ]]; then
  Q="What cultural practices separate elite engineering organizations from average ones?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-culture-$(date +%s).txt"
  echo "🌟 Engineering Culture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering culture roundtable complete."; exit 0; fi

if [[ "$1" == "realtime-bidding" ]]; then
  Q="How do ad tech teams build real-time bidding systems that process millions of auctions per second?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/realtime-bidding-$(date +%s).txt"
  echo "⚡ Real-Time Bidding Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Real-time bidding roundtable complete."; exit 0; fi

if [[ "$1" == "observability-costs" ]]; then
  Q="How do teams control observability costs when Datadog and Grafana bills spiral out of control?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/observability-costs-$(date +%s).txt"
  echo "💰 Observability Costs Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Observability costs roundtable complete."; exit 0; fi

if [[ "$1" == "connection-pooling" ]]; then
  Q="How do teams configure database connection pooling to prevent exhaustion and maintain throughput?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/connection-pooling-$(date +%s).txt"
  echo "🔌 Connection Pooling Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Connection pooling roundtable complete."; exit 0; fi

if [[ "$1" == "technical-writing" ]]; then
  Q="How do engineers write technical content—RFCs, ADRs, design docs—that gets read and drives decisions?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/technical-writing-$(date +%s).txt"
  echo "✍️ Technical Writing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Technical writing roundtable complete."; exit 0; fi

if [[ "$1" == "dns-at-scale" ]]; then
  Q="How do teams manage DNS at scale—GeoDNS, health checks, failover, and TTL strategies?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/dns-at-scale-$(date +%s).txt"
  echo "🌐 DNS at Scale Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DNS at scale roundtable complete."; exit 0; fi

if [[ "$1" == "startup-infra" ]]; then
  Q="What infrastructure choices should startups make early that don't create painful migration debt later?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/startup-infra-$(date +%s).txt"
  echo "🚀 Startup Infrastructure Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Startup infrastructure roundtable complete."; exit 0; fi

# ── BATCH 17 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "code-ownership" ]]; then
  Q="How do teams implement code ownership models that balance accountability with cross-team contribution?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/code-ownership-$(date +%s).txt"
  echo "🏠 Code Ownership Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Code ownership roundtable complete."; exit 0; fi

if [[ "$1" == "dependency-injection" ]]; then
  Q="How does dependency injection improve testability and what are the patterns across different language ecosystems?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/dependency-injection-$(date +%s).txt"
  echo "💉 Dependency Injection Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dependency injection roundtable complete."; exit 0; fi

if [[ "$1" == "cache-stampede" ]]; then
  Q="How do teams prevent cache stampede, thundering herd, and dogpile effects under high load?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/cache-stampede-$(date +%s).txt"
  echo "🐘 Cache Stampede Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cache stampede roundtable complete."; exit 0; fi

if [[ "$1" == "open-source-strategy" ]]; then
  Q="How should companies think about open-sourcing software—what to open, how to maintain, and what to keep closed?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/open-source-strategy-$(date +%s).txt"
  echo "🌍 Open Source Strategy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Open source strategy roundtable complete."; exit 0; fi

if [[ "$1" == "session-management" ]]; then
  Q="How do teams design secure, scalable session management that survives server restarts and horizontal scaling?"; AGENTS=(Shellfish Alice Lucidia Octavia Aria); OUT="$SAVE_DIR/session-management-$(date +%s).txt"
  echo "🔐 Session Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Session management roundtable complete."; exit 0; fi

if [[ "$1" == "performance-budgets" ]]; then
  Q="How do teams set and enforce performance budgets in CI/CD to prevent regressions from shipping?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/performance-budgets-$(date +%s).txt"
  echo "⚡ Performance Budgets Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Performance budgets roundtable complete."; exit 0; fi

if [[ "$1" == "health-checks" ]]; then
  Q="How do teams design comprehensive health checks that distinguish liveness, readiness, and deep health?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/health-checks-$(date +%s).txt"
  echo "🏥 Health Checks Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Health checks roundtable complete."; exit 0; fi

if [[ "$1" == "technical-interviews" ]]; then
  Q="How should engineering teams redesign technical interviews to actually predict job performance?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/technical-interviews-$(date +%s).txt"
  echo "🎯 Technical Interviews Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Technical interviews roundtable complete."; exit 0; fi

if [[ "$1" == "blockchain-practical" ]]; then
  Q="What are the legitimate engineering use cases for blockchain beyond speculation and where does it genuinely help?"; AGENTS=(Lucidia Shellfish Alice Octavia Aria); OUT="$SAVE_DIR/blockchain-practical-$(date +%s).txt"
  echo "⛓️ Practical Blockchain Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Practical blockchain roundtable complete."; exit 0; fi

if [[ "$1" == "team-topologies" ]]; then
  Q="How do team topologies—stream-aligned, platform, enabling, complicated-subsystem—shape software architecture?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/team-topologies-$(date +%s).txt"
  echo "🏗️ Team Topologies Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Team topologies roundtable complete."; exit 0; fi

# ── BATCH 18 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "staff-eng-path" ]]; then
  Q="What does the staff engineer path look like and how do engineers grow into principal and distinguished roles?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/staff-eng-path-$(date +%s).txt"
  echo "🌟 Staff Engineer Path Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Staff engineer path roundtable complete."; exit 0; fi

if [[ "$1" == "mutation-testing" ]]; then
  Q="How does mutation testing reveal gaps in test suites that code coverage metrics miss entirely?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/mutation-testing-$(date +%s).txt"
  echo "🧬 Mutation Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Mutation testing roundtable complete."; exit 0; fi

if [[ "$1" == "protocol-buffers" ]]; then
  Q="When should teams use Protocol Buffers or FlatBuffers over JSON and how do you manage schema evolution?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/protocol-buffers-$(date +%s).txt"
  echo "📦 Protocol Buffers Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Protocol buffers roundtable complete."; exit 0; fi

if [[ "$1" == "continuous-profiling" ]]; then
  Q="How do teams use continuous profiling in production to find CPU, memory, and latency regressions?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/continuous-profiling-$(date +%s).txt"
  echo "🔭 Continuous Profiling Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Continuous profiling roundtable complete."; exit 0; fi

if [[ "$1" == "security-testing" ]]; then
  Q="How do teams integrate DAST, SAST, and penetration testing into CI/CD without slowing delivery?"; AGENTS=(Shellfish Alice Lucidia Octavia Aria); OUT="$SAVE_DIR/security-testing-$(date +%s).txt"
  echo "🔍 Security Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Security testing roundtable complete."; exit 0; fi

if [[ "$1" == "read-replicas" ]]; then
  Q="How do teams use read replicas effectively without creating replication lag problems and stale reads?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/read-replicas-$(date +%s).txt"
  echo "🗄️ Read Replicas Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Read replicas roundtable complete."; exit 0; fi

if [[ "$1" == "license-management" ]]; then
  Q="How do engineering teams manage open source license compliance to avoid legal exposure?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/license-management-$(date +%s).txt"
  echo "⚖️ License Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ License management roundtable complete."; exit 0; fi

if [[ "$1" == "event-driven-ui" ]]; then
  Q="How do teams build event-driven frontend architectures that stay consistent with distributed backends?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/event-driven-ui-$(date +%s).txt"
  echo "⚡ Event-Driven UI Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Event-driven UI roundtable complete."; exit 0; fi

if [[ "$1" == "chaos-db" ]]; then
  Q="How do teams run database chaos experiments to validate backup, recovery, and failover procedures?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/chaos-db-$(date +%s).txt"
  echo "💥 Database Chaos Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Database chaos roundtable complete."; exit 0; fi

if [[ "$1" == "eng-onboarding" ]]; then
  Q="How do elite engineering teams design onboarding that gets new engineers productive in days, not months?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-onboarding-$(date +%s).txt"
  echo "🎉 Engineering Onboarding Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering onboarding roundtable complete."; exit 0; fi

# ── BATCH 19 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "query-optimization" ]]; then
  Q="How do database engineers use EXPLAIN plans, statistics, and hints to optimize complex queries?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/query-optimization-$(date +%s).txt"
  echo "🔍 Query Optimization Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Query optimization roundtable complete."; exit 0; fi

if [[ "$1" == "network-security" ]]; then
  Q="What network security controls—VPC design, NACLs, WAF, DDoS protection—should every production system have?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/network-security-$(date +%s).txt"
  echo "🔒 Network Security Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Network security roundtable complete."; exit 0; fi

if [[ "$1" == "design-systems" ]]; then
  Q="How do teams build and scale design systems that frontend engineers actually want to use?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/design-systems-$(date +%s).txt"
  echo "🎨 Design Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Design systems roundtable complete."; exit 0; fi

if [[ "$1" == "grpc-patterns" ]]; then
  Q="When does gRPC outperform REST and what patterns—bidirectional streaming, interceptors—make it shine?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/grpc-patterns-$(date +%s).txt"
  echo "📡 gRPC Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ gRPC patterns roundtable complete."; exit 0; fi

if [[ "$1" == "log-aggregation" ]]; then
  Q="How do teams build log aggregation pipelines that are affordable, searchable, and don't drown in noise?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/log-aggregation-$(date +%s).txt"
  echo "📋 Log Aggregation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Log aggregation roundtable complete."; exit 0; fi

if [[ "$1" == "job-scheduling" ]]; then
  Q="How do distributed systems schedule jobs reliably—cron alternatives, priority queues, backpressure?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/job-scheduling-$(date +%s).txt"
  echo "⏰ Job Scheduling Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Job scheduling roundtable complete."; exit 0; fi

if [[ "$1" == "feature-flag-ops" ]]; then
  Q="How do teams operationalize feature flags to avoid flag debt and manage thousands of flags safely?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/feature-flag-ops-$(date +%s).txt"
  echo "🚩 Feature Flag Operations Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Feature flag operations roundtable complete."; exit 0; fi

if [[ "$1" == "disaster-recovery" ]]; then
  Q="How do teams design and regularly test disaster recovery plans to achieve real RTO and RPO targets?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/disaster-recovery-$(date +%s).txt"
  echo "🆘 Disaster Recovery Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Disaster recovery roundtable complete."; exit 0; fi

if [[ "$1" == "api-documentation" ]]; then
  Q="How do teams create API documentation that developers love—OpenAPI, live examples, and changelog discipline?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/api-documentation-$(date +%s).txt"
  echo "📖 API Documentation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API documentation roundtable complete."; exit 0; fi

if [[ "$1" == "service-discovery" ]]; then
  Q="How do distributed systems implement service discovery and what are the tradeoffs between DNS-based and registry-based?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/service-discovery-$(date +%s).txt"
  echo "🔭 Service Discovery Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Service discovery roundtable complete."; exit 0; fi

# ── BATCH 20 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "ai-code-review" ]]; then
  Q="How should teams integrate AI coding assistants and automated code review into their development workflow?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/ai-code-review-$(date +%s).txt"
  echo "🤖 AI Code Review Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI code review roundtable complete."; exit 0; fi

if [[ "$1" == "data-governance" ]]; then
  Q="How do organizations implement data governance that enables analytics without creating bureaucratic bottlenecks?"; AGENTS=(Lucidia Alice Octavia Shellfish Aria); OUT="$SAVE_DIR/data-governance-$(date +%s).txt"
  echo "📋 Data Governance Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data governance roundtable complete."; exit 0; fi

if [[ "$1" == "developer-portals" ]]; then
  Q="How do platform teams build internal developer portals—Backstage, Cortex—that become a daily habit?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/developer-portals-$(date +%s).txt"
  echo "🏛️ Developer Portals Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Developer portals roundtable complete."; exit 0; fi

if [[ "$1" == "progressive-enhancement" ]]; then
  Q="How do teams apply progressive enhancement to build web apps that work everywhere and shine on fast devices?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/progressive-enhancement-$(date +%s).txt"
  echo "📈 Progressive Enhancement Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Progressive enhancement roundtable complete."; exit 0; fi

if [[ "$1" == "tls-certificate-ops" ]]; then
  Q="How do teams automate TLS certificate management across thousands of services without causing outages?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/tls-certificate-ops-$(date +%s).txt"
  echo "🔒 TLS Certificate Ops Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ TLS certificate ops roundtable complete."; exit 0; fi

if [[ "$1" == "cross-border-data" ]]; then
  Q="How do engineering teams build data residency and cross-border data compliance into their architecture?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/cross-border-data-$(date +%s).txt"
  echo "🌍 Cross-Border Data Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cross-border data roundtable complete."; exit 0; fi

if [[ "$1" == "peer-learning" ]]; then
  Q="How do engineering teams build internal knowledge sharing—brown bags, guilds, learning sprints—that actually work?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/peer-learning-$(date +%s).txt"
  echo "📚 Peer Learning Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Peer learning roundtable complete."; exit 0; fi

if [[ "$1" == "autoscaling-strategies" ]]; then
  Q="What autoscaling strategies—HPA, KEDA, predictive, scheduled—work best for different workload patterns?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/autoscaling-strategies-$(date +%s).txt"
  echo "📈 Autoscaling Strategies Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Autoscaling strategies roundtable complete."; exit 0; fi

if [[ "$1" == "api-gateway-security" ]]; then
  Q="What security controls belong at the API gateway vs in the service itself—JWT validation, RBAC, IP filtering?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/api-gateway-security-$(date +%s).txt"
  echo "🔒 API Gateway Security Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API gateway security roundtable complete."; exit 0; fi

if [[ "$1" == "eng-excellence" ]]; then
  Q="What does engineering excellence mean and how do the best organizations measure and relentlessly pursue it?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-excellence-$(date +%s).txt"
  echo "🏆 Engineering Excellence Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering excellence roundtable complete."; exit 0; fi

# ── BATCH 21 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "observability-pipelines" ]]; then
  Q="How do teams build observability pipelines that filter, enrich, and route telemetry cost-effectively?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/observability-pipelines-$(date +%s).txt"
  echo "🔭 Observability Pipelines Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Observability pipelines roundtable complete."; exit 0; fi

if [[ "$1" == "postgres-advanced" ]]; then
  Q="What advanced PostgreSQL features—JSONB, CTEs, partial indexes, LISTEN/NOTIFY—do senior engineers leverage?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/postgres-advanced-$(date +%s).txt"
  echo "🐘 Advanced PostgreSQL Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced PostgreSQL roundtable complete."; exit 0; fi

if [[ "$1" == "redis-patterns" ]]; then
  Q="What Redis patterns—pub/sub, sorted sets, Lua scripts, streams—solve problems that other tools can't?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/redis-patterns-$(date +%s).txt"
  echo "🔴 Redis Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Redis patterns roundtable complete."; exit 0; fi

if [[ "$1" == "deployment-strategies" ]]; then
  Q="What are the tradeoffs between blue-green, canary, rolling, and recreate deployment strategies?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/deployment-strategies-$(date +%s).txt"
  echo "🚀 Deployment Strategies Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Deployment strategies roundtable complete."; exit 0; fi

if [[ "$1" == "container-orchestration" ]]; then
  Q="Beyond Kubernetes basics—how do teams use operators, CRDs, and admission webhooks to extend k8s?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/container-orchestration-$(date +%s).txt"
  echo "⎈ Container Orchestration Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Container orchestration roundtable complete."; exit 0; fi

if [[ "$1" == "privacy-by-design" ]]; then
  Q="How do engineering teams implement privacy-by-design principles from data modeling to API response?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/privacy-by-design-$(date +%s).txt"
  echo "🔏 Privacy by Design Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Privacy by design roundtable complete."; exit 0; fi

if [[ "$1" == "feedback-loops" ]]; then
  Q="How do great engineering teams shorten feedback loops from commit to confident production deployment?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/feedback-loops-$(date +%s).txt"
  echo "🔄 Feedback Loops Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Feedback loops roundtable complete."; exit 0; fi

if [[ "$1" == "eventual-consistency" ]]; then
  Q="How do teams build systems that embrace eventual consistency without confusing users?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/eventual-consistency-$(date +%s).txt"
  echo "⏳ Eventual Consistency Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eventual consistency roundtable complete."; exit 0; fi

if [[ "$1" == "ci-optimization" ]]; then
  Q="How do teams cut CI pipeline times from 30 minutes to under 5 without sacrificing quality?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/ci-optimization-$(date +%s).txt"
  echo "⚡ CI Optimization Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ CI optimization roundtable complete."; exit 0; fi

if [[ "$1" == "multi-cloud-strategy" ]]; then
  Q="How do organizations decide what to run on which cloud and avoid multi-cloud complexity traps?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/multi-cloud-strategy-$(date +%s).txt"
  echo "☁️ Multi-Cloud Strategy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multi-cloud strategy roundtable complete."; exit 0; fi

# ── BATCH 22 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "dead-letter-queues" ]]; then
  Q="How do teams design dead letter queue handling that catches failures without losing messages?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/dead-letter-queues-$(date +%s).txt"
  echo "📬 Dead Letter Queues Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dead letter queues roundtable complete."; exit 0; fi

if [[ "$1" == "api-sdk-design" ]]; then
  Q="What makes an API SDK developers love—ergonomics, error handling, retry logic, and documentation?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/api-sdk-design-$(date +%s).txt"
  echo "🛠️ API SDK Design Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API SDK design roundtable complete."; exit 0; fi

if [[ "$1" == "testing-strategy" ]]; then
  Q="How do engineering teams decide the right balance of unit, integration, e2e, and property-based tests?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/testing-strategy-$(date +%s).txt"
  echo "🧪 Testing Strategy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Testing strategy roundtable complete."; exit 0; fi

if [[ "$1" == "nosql-patterns" ]]; then
  Q="How do teams choose between document, wide-column, key-value, and graph NoSQL databases?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/nosql-patterns-$(date +%s).txt"
  echo "🗄️ NoSQL Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ NoSQL patterns roundtable complete."; exit 0; fi

if [[ "$1" == "microservice-testing" ]]; then
  Q="How do teams test microservices in isolation while still catching integration failures early?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/microservice-testing-$(date +%s).txt"
  echo "🧪 Microservice Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Microservice testing roundtable complete."; exit 0; fi

if [[ "$1" == "memory-management" ]]; then
  Q="How do engineers diagnose and fix memory leaks, GC pressure, and heap fragmentation in production?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/memory-management-$(date +%s).txt"
  echo "🧠 Memory Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Memory management roundtable complete."; exit 0; fi

if [[ "$1" == "eng-writing" ]]; then
  Q="How do engineers become exceptional writers of design docs, proposals, and engineering updates?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-writing-$(date +%s).txt"
  echo "✍️ Engineering Writing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering writing roundtable complete."; exit 0; fi

if [[ "$1" == "reactive-systems" ]]; then
  Q="What are reactive systems principles—responsive, resilient, elastic, message-driven—and how do they apply today?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/reactive-systems-$(date +%s).txt"
  echo "⚡ Reactive Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Reactive systems roundtable complete."; exit 0; fi

if [[ "$1" == "cross-team-api" ]]; then
  Q="How do platform teams manage APIs that many internal teams depend on without becoming a bottleneck?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/cross-team-api-$(date +%s).txt"
  echo "🤝 Cross-Team API Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cross-team API roundtable complete."; exit 0; fi

if [[ "$1" == "hardware-acceleration" ]]; then
  Q="When does GPU, FPGA, or custom ASIC hardware acceleration make sense for software workloads?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/hardware-acceleration-$(date +%s).txt"
  echo "⚡ Hardware Acceleration Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Hardware acceleration roundtable complete."; exit 0; fi

# ── BATCH 23 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "api-deprecation" ]]; then
  Q="How do teams deprecate and sunset APIs gracefully without stranding API consumers?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/api-deprecation-$(date +%s).txt"
  echo "🌅 API Deprecation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API deprecation roundtable complete."; exit 0; fi

if [[ "$1" == "distributed-config" ]]; then
  Q="How do teams manage distributed configuration with Consul, etcd, or AWS Parameter Store at scale?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/distributed-config-$(date +%s).txt"
  echo "⚙️ Distributed Config Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Distributed config roundtable complete."; exit 0; fi

if [[ "$1" == "cost-of-delay" ]]; then
  Q="How do engineering teams use cost of delay to prioritize technical work against product features?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/cost-of-delay-$(date +%s).txt"
  echo "⏱️ Cost of Delay Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cost of delay roundtable complete."; exit 0; fi

if [[ "$1" == "backpressure" ]]; then
  Q="How do streaming and reactive systems implement backpressure to prevent cascading failures?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/backpressure-$(date +%s).txt"
  echo "🌊 Backpressure Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Backpressure roundtable complete."; exit 0; fi

if [[ "$1" == "immutable-infrastructure" ]]; then
  Q="What is immutable infrastructure and how do teams use container images and AMIs to achieve it?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/immutable-infrastructure-$(date +%s).txt"
  echo "🧊 Immutable Infrastructure Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Immutable infrastructure roundtable complete."; exit 0; fi

if [[ "$1" == "full-stack-tracing" ]]; then
  Q="How do teams achieve full-stack trace correlation from browser request through microservices to database?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/full-stack-tracing-$(date +%s).txt"
  echo "🔭 Full-Stack Tracing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Full-stack tracing roundtable complete."; exit 0; fi

if [[ "$1" == "eng-mentorship" ]]; then
  Q="How do the best engineering mentors accelerate junior engineer growth without creating dependency?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-mentorship-$(date +%s).txt"
  echo "🌱 Engineering Mentorship Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering mentorship roundtable complete."; exit 0; fi

if [[ "$1" == "event-streaming" ]]; then
  Q="How do teams architect event streaming platforms that serve analytics, ML, and operational use cases simultaneously?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/event-streaming-$(date +%s).txt"
  echo "🌊 Event Streaming Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Event streaming roundtable complete."; exit 0; fi

if [[ "$1" == "osquery" ]]; then
  Q="How do security teams use osquery and fleet management to get real-time endpoint visibility?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/osquery-$(date +%s).txt"
  echo "🔍 osquery Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ osquery roundtable complete."; exit 0; fi

if [[ "$1" == "distributed-sql" ]]; then
  Q="When does distributed SQL like CockroachDB or Spanner make sense over traditional PostgreSQL?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/distributed-sql-$(date +%s).txt"
  echo "🗄️ Distributed SQL Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Distributed SQL roundtable complete."; exit 0; fi

# ── BATCH 24 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "load-testing" ]]; then
  Q="How do teams run realistic load tests that reveal production bottlenecks before launch?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/load-testing-$(date +%s).txt"
  echo "🔨 Load Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Load testing roundtable complete."; exit 0; fi

if [[ "$1" == "value-stream" ]]; then
  Q="How do teams map and improve their value stream to eliminate waste and deliver faster?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/value-stream-$(date +%s).txt"
  echo "🗺️ Value Stream Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Value stream roundtable complete."; exit 0; fi

if [[ "$1" == "dependency-management" ]]; then
  Q="How do teams manage third-party dependency updates without constant breakage and security debt?"; AGENTS=(Alice Lucidia Octavia Shellfish Aria); OUT="$SAVE_DIR/dependency-management-$(date +%s).txt"
  echo "📦 Dependency Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dependency management roundtable complete."; exit 0; fi

if [[ "$1" == "ip-addressing" ]]; then
  Q="How do teams plan IPv4 and IPv6 addressing for large cloud deployments that need room to grow?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/ip-addressing-$(date +%s).txt"
  echo "🌐 IP Addressing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ IP addressing roundtable complete."; exit 0; fi

if [[ "$1" == "performance-regression" ]]; then
  Q="How do teams catch performance regressions in CI before they reach production and degrade user experience?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/performance-regression-$(date +%s).txt"
  echo "📉 Performance Regression Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Performance regression roundtable complete."; exit 0; fi

if [[ "$1" == "token-economics" ]]; then
  Q="How should platform teams design token-based usage models for AI APIs and developer products?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/token-economics-$(date +%s).txt"
  echo "🪙 Token Economics Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Token economics roundtable complete."; exit 0; fi

if [[ "$1" == "autonomous-systems" ]]; then
  Q="What engineering principles apply to building reliable autonomous systems that act without human approval?"; AGENTS=(Lucidia Shellfish Octavia Alice Aria); OUT="$SAVE_DIR/autonomous-systems-$(date +%s).txt"
  echo "🤖 Autonomous Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Autonomous systems roundtable complete."; exit 0; fi

if [[ "$1" == "data-mesh" ]]; then
  Q="What is data mesh, how does it differ from data lakes, and when does it actually make sense?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/data-mesh-$(date +%s).txt"
  echo "🕸️ Data Mesh Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data mesh roundtable complete."; exit 0; fi

if [[ "$1" == "progressive-disclosure" ]]; then
  Q="How do teams design progressive disclosure in UIs and APIs so simple things stay simple?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/progressive-disclosure-$(date +%s).txt"
  echo "🎨 Progressive Disclosure Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Progressive disclosure roundtable complete."; exit 0; fi

if [[ "$1" == "incident-analytics" ]]; then
  Q="How do teams analyze incident data over time to surface systemic reliability improvements?"; AGENTS=(Lucidia Alice Octavia Shellfish Aria); OUT="$SAVE_DIR/incident-analytics-$(date +%s).txt"
  echo "📊 Incident Analytics Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Incident analytics roundtable complete."; exit 0; fi

# ── BATCH 25 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "ebpf" ]]; then
  Q="How are teams using eBPF for networking, observability, and security without kernel modifications?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/ebpf-$(date +%s).txt"
  echo "⚡ eBPF Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ eBPF roundtable complete."; exit 0; fi

if [[ "$1" == "service-catalog" ]]; then
  Q="How do organizations build and maintain a service catalog that keeps engineering aware of what exists?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/service-catalog-$(date +%s).txt"
  echo "📚 Service Catalog Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Service catalog roundtable complete."; exit 0; fi

if [[ "$1" == "graphql-advanced" ]]; then
  Q="What advanced GraphQL patterns—dataloader, persisted queries, schema stitching—handle real production challenges?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/graphql-advanced-$(date +%s).txt"
  echo "📡 Advanced GraphQL Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced GraphQL roundtable complete."; exit 0; fi

if [[ "$1" == "on-premise-cloud" ]]; then
  Q="How do teams architect hybrid on-premise and cloud systems that don't become a maintenance nightmare?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/on-premise-cloud-$(date +%s).txt"
  echo "🏢 On-Premise & Cloud Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ On-premise & cloud roundtable complete."; exit 0; fi

if [[ "$1" == "customer-reliability" ]]; then
  Q="How do engineering teams build reliability from the customer perspective—not just uptime but perceived experience?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/customer-reliability-$(date +%s).txt"
  echo "🎯 Customer Reliability Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Customer reliability roundtable complete."; exit 0; fi

if [[ "$1" == "batch-processing" ]]; then
  Q="How do teams design batch processing jobs that are reliable, resumable, and observable?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/batch-processing-$(date +%s).txt"
  echo "⚙️ Batch Processing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Batch processing roundtable complete."; exit 0; fi

if [[ "$1" == "anomaly-detection" ]]; then
  Q="How do teams build production anomaly detection that alerts on real issues without alert fatigue?"; AGENTS=(Lucidia Octavia Alice Shellfish Aria); OUT="$SAVE_DIR/anomaly-detection-$(date +%s).txt"
  echo "🔔 Anomaly Detection Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Anomaly detection roundtable complete."; exit 0; fi

if [[ "$1" == "developer-sandbox" ]]; then
  Q="How do teams build developer sandboxes that faithfully mirror production without the cost?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/developer-sandbox-$(date +%s).txt"
  echo "🏖️ Developer Sandbox Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Developer sandbox roundtable complete."; exit 0; fi

if [[ "$1" == "security-by-default" ]]; then
  Q="How do teams make security the path of least resistance so engineers ship secure code by default?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/security-by-default-$(date +%s).txt"
  echo "🛡️ Security by Default Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Security by default roundtable complete."; exit 0; fi

if [[ "$1" == "eng-influence" ]]; then
  Q="How do engineers build influence without authority to drive technical change across an organization?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-influence-$(date +%s).txt"
  echo "🌟 Engineering Influence Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering influence roundtable complete."; exit 0; fi

# ── BATCH 26 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "lambda-architecture" ]]; then
  Q="What is lambda architecture and when does it still make sense versus kappa or delta approaches?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/lambda-architecture-$(date +%s).txt"
  echo "λ Lambda Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Lambda architecture roundtable complete."; exit 0; fi

if [[ "$1" == "api-gateway-auth" ]]; then
  Q="How do teams implement OAuth2, API keys, and mutual TLS authentication at the API gateway layer?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/api-gateway-auth-$(date +%s).txt"
  echo "🔐 API Gateway Auth Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API gateway auth roundtable complete."; exit 0; fi

if [[ "$1" == "serverless-patterns" ]]; then
  Q="What serverless patterns—fan-out, choreography, scheduled functions—work best in production?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/serverless-patterns-$(date +%s).txt"
  echo "☁️ Serverless Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Serverless patterns roundtable complete."; exit 0; fi

if [[ "$1" == "mobile-architecture" ]]; then
  Q="What mobile architecture patterns—MVVM, MVI, Clean Architecture—scale to large iOS and Android teams?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/mobile-architecture-$(date +%s).txt"
  echo "📱 Mobile Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Mobile architecture roundtable complete."; exit 0; fi

if [[ "$1" == "infrastructure-testing" ]]; then
  Q="How do teams test infrastructure code with terratest, localstack, and policy-as-code tools?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/infrastructure-testing-$(date +%s).txt"
  echo "🧪 Infrastructure Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Infrastructure testing roundtable complete."; exit 0; fi

if [[ "$1" == "real-user-monitoring" ]]; then
  Q="How do teams implement real user monitoring to understand actual field performance across devices and networks?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/real-user-monitoring-$(date +%s).txt"
  echo "👤 Real User Monitoring Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Real user monitoring roundtable complete."; exit 0; fi

if [[ "$1" == "platform-adoption" ]]; then
  Q="How do internal platform teams drive adoption of their tools without mandate—making the platform irresistible?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/platform-adoption-$(date +%s).txt"
  echo "🚀 Platform Adoption Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Platform adoption roundtable complete."; exit 0; fi

if [[ "$1" == "incident-comms" ]]; then
  Q="How do teams communicate during and after incidents to keep stakeholders informed without creating panic?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/incident-comms-$(date +%s).txt"
  echo "📢 Incident Communications Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Incident communications roundtable complete."; exit 0; fi

if [[ "$1" == "type-systems" ]]; then
  Q="How do strong type systems catch bugs at compile time and what makes TypeScript, Rust, or Haskell type systems powerful?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/type-systems-$(date +%s).txt"
  echo "🔤 Type Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Type systems roundtable complete."; exit 0; fi

if [[ "$1" == "object-storage" ]]; then
  Q="How do teams design systems around object storage—S3 patterns, lifecycle policies, multipart uploads?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/object-storage-$(date +%s).txt"
  echo "🪣 Object Storage Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Object storage roundtable complete."; exit 0; fi

# ── BATCH 27 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "trunk-feature-flags" ]]; then
  Q="How do teams combine trunk-based development with feature flags to ship incrementally without long-lived branches?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/trunk-feature-flags-$(date +%s).txt"
  echo "🚩 Trunk + Feature Flags Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Trunk + feature flags roundtable complete."; exit 0; fi

if [[ "$1" == "signal-vs-noise" ]]; then
  Q="How do teams tune alerting to achieve high signal with low noise—on-call engineers actually trust their pagers?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/signal-vs-noise-$(date +%s).txt"
  echo "🔔 Signal vs Noise Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Signal vs noise roundtable complete."; exit 0; fi

if [[ "$1" == "llm-evals" ]]; then
  Q="How do teams build LLM evaluation pipelines that measure quality, safety, and regression reliably?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/llm-evals-$(date +%s).txt"
  echo "🧪 LLM Evaluations Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ LLM evaluations roundtable complete."; exit 0; fi

if [[ "$1" == "chaos-networking" ]]; then
  Q="How do teams use network chaos—packet loss, latency injection, partition testing—to validate resilience?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/chaos-networking-$(date +%s).txt"
  echo "💥 Network Chaos Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Network chaos roundtable complete."; exit 0; fi

if [[ "$1" == "rollback-strategies" ]]; then
  Q="How do teams build rollback capabilities that work under 5 minutes for code, config, and database changes?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/rollback-strategies-$(date +%s).txt"
  echo "↩️ Rollback Strategies Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Rollback strategies roundtable complete."; exit 0; fi

if [[ "$1" == "continuous-deployment" ]]; then
  Q="What does it take to achieve true continuous deployment—deploying every commit to production safely?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/continuous-deployment-$(date +%s).txt"
  echo "🚀 Continuous Deployment Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Continuous deployment roundtable complete."; exit 0; fi

if [[ "$1" == "internal-hackathons" ]]; then
  Q="How do engineering organizations run hackathons that generate real product value rather than just fun demos?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/internal-hackathons-$(date +%s).txt"
  echo "💡 Internal Hackathons Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Internal hackathons roundtable complete."; exit 0; fi

if [[ "$1" == "cqrs" ]]; then
  Q="When does CQRS genuinely improve systems and what pitfalls make it more trouble than it is worth?"; AGENTS=(Lucidia Octavia Alice Shellfish Aria); OUT="$SAVE_DIR/cqrs-$(date +%s).txt"
  echo "📊 CQRS Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ CQRS roundtable complete."; exit 0; fi

if [[ "$1" == "multitenancy-isolation" ]]; then
  Q="How do SaaS teams implement tenant isolation at the database row, schema, and database instance levels?"; AGENTS=(Octavia Shellfish Alice Lucidia Aria); OUT="$SAVE_DIR/multitenancy-isolation-$(date +%s).txt"
  echo "🏢 Multi-Tenancy Isolation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multi-tenancy isolation roundtable complete."; exit 0; fi

if [[ "$1" == "eng-vision" ]]; then
  Q="How do engineering leaders create and communicate a compelling technical vision that teams rally around?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-vision-$(date +%s).txt"
  echo "🌟 Engineering Vision Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering vision roundtable complete."; exit 0; fi

# ── BATCH 28 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "distributed-transactions" ]]; then
  Q="How do teams handle distributed transactions with saga pattern, 2PC, and eventual consistency tradeoffs?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/distributed-transactions-$(date +%s).txt"
  echo "🔄 Distributed Transactions Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Distributed transactions roundtable complete."; exit 0; fi

if [[ "$1" == "chaos-memory" ]]; then
  Q="How do teams simulate memory pressure and OOM conditions to validate graceful degradation?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/chaos-memory-$(date +%s).txt"
  echo "💥 Memory Chaos Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Memory chaos roundtable complete."; exit 0; fi

if [[ "$1" == "spanner-patterns" ]]; then
  Q="What are the data modeling and query patterns that unlock Google Spanner's global consistency guarantees?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/spanner-patterns-$(date +%s).txt"
  echo "🔄 Spanner Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Spanner patterns roundtable complete."; exit 0; fi

if [[ "$1" == "incident-severity" ]]; then
  Q="How do teams define incident severity levels and escalation paths that everyone understands and respects?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/incident-severity-$(date +%s).txt"
  echo "🚨 Incident Severity Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Incident severity roundtable complete."; exit 0; fi

if [[ "$1" == "frontend-testing" ]]; then
  Q="What frontend testing strategies—component, visual regression, e2e with Playwright—give the best ROI?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/frontend-testing-$(date +%s).txt"
  echo "🧪 Frontend Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Frontend testing roundtable complete."; exit 0; fi

if [[ "$1" == "eng-estimation" ]]; then
  Q="How do engineers give estimates that are honest about uncertainty without derailing planning cycles?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-estimation-$(date +%s).txt"
  echo "🎯 Engineering Estimation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering estimation roundtable complete."; exit 0; fi

if [[ "$1" == "cloud-native-patterns" ]]; then
  Q="What cloud-native patterns—sidecar, ambassador, strangler fig—solve common distributed systems problems?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/cloud-native-patterns-$(date +%s).txt"
  echo "☁️ Cloud-Native Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cloud-native patterns roundtable complete."; exit 0; fi

if [[ "$1" == "eng-peer-feedback" ]]; then
  Q="How do engineering teams build a culture of candid, actionable peer feedback that improves everyone?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-peer-feedback-$(date +%s).txt"
  echo "💬 Engineering Peer Feedback Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering peer feedback roundtable complete."; exit 0; fi

if [[ "$1" == "security-incident" ]]; then
  Q="How do teams respond to a security breach—containment, forensics, disclosure, and hardening?"; AGENTS=(Shellfish Alice Lucidia Octavia Aria); OUT="$SAVE_DIR/security-incident-$(date +%s).txt"
  echo "🚨 Security Incident Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Security incident roundtable complete."; exit 0; fi

if [[ "$1" == "data-observability" ]]; then
  Q="How do data teams build data observability—freshness, volume, schema drift, distribution anomalies?"; AGENTS=(Lucidia Alice Octavia Shellfish Aria); OUT="$SAVE_DIR/data-observability-$(date +%s).txt"
  echo "👁️ Data Observability Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data observability roundtable complete."; exit 0; fi

# ── BATCH 29 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "ipfs-web3-infra" ]]; then
  Q="What is the practical engineering case for decentralized storage and IPFS in production systems?"; AGENTS=(Lucidia Shellfish Alice Octavia Aria); OUT="$SAVE_DIR/ipfs-web3-infra-$(date +%s).txt"
  echo "🌐 IPFS & Web3 Infra Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ IPFS & Web3 infra roundtable complete."; exit 0; fi

if [[ "$1" == "semantic-release" ]]; then
  Q="How do teams implement semantic release automation to maintain changelogs and versioning without manual toil?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/semantic-release-$(date +%s).txt"
  echo "🏷️ Semantic Release Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Semantic release roundtable complete."; exit 0; fi

if [[ "$1" == "data-privacy-eng" ]]; then
  Q="How do engineers implement differential privacy, k-anonymity, and data masking to protect user privacy?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/data-privacy-eng-$(date +%s).txt"
  echo "🔏 Data Privacy Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data privacy engineering roundtable complete."; exit 0; fi

if [[ "$1" == "multi-model-ai" ]]; then
  Q="How do teams architect systems that intelligently route between multiple AI models based on cost and capability?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/multi-model-ai-$(date +%s).txt"
  echo "🤖 Multi-Model AI Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multi-model AI roundtable complete."; exit 0; fi

if [[ "$1" == "realtime-data-sync" ]]; then
  Q="How do teams implement real-time data synchronization between cloud and edge nodes reliably?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/realtime-data-sync-$(date +%s).txt"
  echo "🔄 Real-Time Data Sync Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Real-time data sync roundtable complete."; exit 0; fi

if [[ "$1" == "eng-decision-records" ]]; then
  Q="How do teams write Architecture Decision Records that future engineers actually find and understand?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-decision-records-$(date +%s).txt"
  echo "📋 Engineering Decision Records Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering decision records roundtable complete."; exit 0; fi

if [[ "$1" == "secrets-management" ]]; then
  Q="How do teams implement HashiCorp Vault or AWS Secrets Manager to dynamically inject secrets at runtime?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/secrets-management-$(date +%s).txt"
  echo "🔑 Secrets Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Secrets management roundtable complete."; exit 0; fi

if [[ "$1" == "saas-billing" ]]; then
  Q="How do engineering teams build flexible billing systems that handle trials, upgrades, prorations, and metering?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/saas-billing-$(date +%s).txt"
  echo "💳 SaaS Billing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ SaaS billing roundtable complete."; exit 0; fi

if [[ "$1" == "distributed-consensus" ]]; then
  Q="How does distributed consensus work—Raft, Paxos—and when do engineers need to understand it deeply?"; AGENTS=(Octavia Lucidia Alice Shellfish Aria); OUT="$SAVE_DIR/distributed-consensus-$(date +%s).txt"
  echo "🤝 Distributed Consensus Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Distributed consensus roundtable complete."; exit 0; fi

if [[ "$1" == "api-mesh" ]]; then
  Q="What is an API mesh and how does it differ from an API gateway in a multi-service environment?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/api-mesh-$(date +%s).txt"
  echo "🕸️ API Mesh Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API mesh roundtable complete."; exit 0; fi

# ── BATCH 30 ───────────────────────────────────────────────────────────────────
if [[ "$1" == "dev-flow" ]]; then
  Q="What does an optimal developer flow state look like and how do organizations protect it?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/dev-flow-$(date +%s).txt"
  echo "🌊 Developer Flow Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Developer flow roundtable complete."; exit 0; fi

if [[ "$1" == "ai-observability" ]]; then
  Q="How do teams observe and debug AI systems in production—hallucinations, latency, and prompt drift?"; AGENTS=(Lucidia Octavia Alice Shellfish Aria); OUT="$SAVE_DIR/ai-observability-$(date +%s).txt"
  echo "👁️ AI Observability Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI observability roundtable complete."; exit 0; fi

if [[ "$1" == "eng-org-design" ]]; then
  Q="How should engineering organizations be structured as companies grow from 50 to 500 to 5000 engineers?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-org-design-$(date +%s).txt"
  echo "🏛️ Engineering Org Design Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering org design roundtable complete."; exit 0; fi

if [[ "$1" == "function-optimization" ]]; then
  Q="How do engineers identify and optimize hot code paths using flame graphs, benchmarks, and profilers?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/function-optimization-$(date +%s).txt"
  echo "⚡ Function Optimization Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Function optimization roundtable complete."; exit 0; fi

if [[ "$1" == "policy-as-code" ]]; then
  Q="How do teams use OPA, Kyverno, or Sentinel to enforce infrastructure and security policies as code?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/policy-as-code-$(date +%s).txt"
  echo "📋 Policy as Code Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Policy as code roundtable complete."; exit 0; fi

if [[ "$1" == "model-context-protocol" ]]; then
  Q="How does Model Context Protocol change how AI agents integrate with developer tools and data sources?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/model-context-protocol-$(date +%s).txt"
  echo "🔌 Model Context Protocol Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Model context protocol roundtable complete."; exit 0; fi

if [[ "$1" == "hybrid-search" ]]; then
  Q="How do teams combine dense vector search with sparse keyword search for best-of-both retrieval?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/hybrid-search-$(date +%s).txt"
  echo "🔍 Hybrid Search Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Hybrid search roundtable complete."; exit 0; fi

if [[ "$1" == "reliability-roadmap" ]]; then
  Q="How do teams build a multi-quarter reliability roadmap that balances new features with stability investments?"; AGENTS=(Lucidia Octavia Alice Aria Shellfish); OUT="$SAVE_DIR/reliability-roadmap-$(date +%s).txt"
  echo "🗺️ Reliability Roadmap Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Reliability roadmap roundtable complete."; exit 0; fi

if [[ "$1" == "eng-legacy" ]]; then
  Q="How do teams modernize legacy systems incrementally without stopping feature delivery or risking outages?"; AGENTS=(Lucidia Alice Octavia Aria Shellfish); OUT="$SAVE_DIR/eng-legacy-$(date +%s).txt"
  echo "🏚️ Engineering Legacy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Engineering legacy roundtable complete."; exit 0; fi

if [[ "$1" == "blackroad-future" ]]; then
  Q="If you could build the perfect BlackRoad OS for the next decade of AI-native software, what would it look like?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/blackroad-future-$(date +%s).txt"
  echo "🚀 BlackRoad Future Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ BlackRoad future roundtable complete."; exit 0; fi

if [[ "$1" == "rust-systems" ]]; then
  Q="What makes Rust uniquely suited for systems programming — ownership, lifetimes, fearless concurrency?"; AGENTS=(Octavia Shellfish Alice Lucidia Aria); OUT="$SAVE_DIR/rust-systems-$(date +%s).txt"
  echo "🦀 Rust Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Rust systems roundtable complete."; exit 0; fi

if [[ "$1" == "go-concurrency" ]]; then
  Q="How do goroutines, channels, and the Go scheduler enable massive concurrency with simplicity?"; AGENTS=(Alice Octavia Shellfish Aria Lucidia); OUT="$SAVE_DIR/go-concurrency-$(date +%s).txt"
  echo "🐹 Go Concurrency Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Go concurrency roundtable complete."; exit 0; fi

if [[ "$1" == "python-async" ]]; then
  Q="How does Python asyncio work under the hood, and when should you use it vs threads vs multiprocessing?"; AGENTS=(Lucidia Alice Aria Octavia Shellfish); OUT="$SAVE_DIR/python-async-$(date +%s).txt"
  echo "🐍 Python Async Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Python async roundtable complete."; exit 0; fi

if [[ "$1" == "jvm-tuning" ]]; then
  Q="What are the most impactful JVM tuning parameters for GC, heap sizing, and thread pools in production?"; AGENTS=(Octavia Shellfish Lucidia Alice Aria); OUT="$SAVE_DIR/jvm-tuning-$(date +%s).txt"
  echo "☕ JVM Tuning Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ JVM tuning roundtable complete."; exit 0; fi

if [[ "$1" == "node-performance" ]]; then
  Q="What are the critical performance bottlenecks in Node.js and how do you profile and address them?"; AGENTS=(Aria Alice Octavia Lucidia Shellfish); OUT="$SAVE_DIR/node-performance-$(date +%s).txt"
  echo "🟩 Node.js Performance Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Node performance roundtable complete."; exit 0; fi

if [[ "$1" == "typescript-patterns" ]]; then
  Q="What are the most powerful TypeScript patterns — conditional types, mapped types, template literals, decorators?"; AGENTS=(Aria Lucidia Alice Shellfish Octavia); OUT="$SAVE_DIR/typescript-patterns-$(date +%s).txt"
  echo "🔷 TypeScript Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ TypeScript patterns roundtable complete."; exit 0; fi

if [[ "$1" == "functional-programming" ]]; then
  Q="How do pure functions, immutability, and higher-order functions change the way you architect software?"; AGENTS=(Lucidia Aria Octavia Shellfish Alice); OUT="$SAVE_DIR/functional-programming-$(date +%s).txt"
  echo "λ Functional Programming Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Functional programming roundtable complete."; exit 0; fi

if [[ "$1" == "actor-model" ]]; then
  Q="How does the actor model — Erlang, Akka, Elixir — enable fault-tolerant distributed systems?"; AGENTS=(Octavia Shellfish Alice Lucidia Aria); OUT="$SAVE_DIR/actor-model-$(date +%s).txt"
  echo "🎭 Actor Model Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Actor model roundtable complete."; exit 0; fi

if [[ "$1" == "concurrency-patterns" ]]; then
  Q="What are the essential concurrency patterns — mutex, semaphore, CSP, STM — and when should each be used?"; AGENTS=(Alice Octavia Aria Shellfish Lucidia); OUT="$SAVE_DIR/concurrency-patterns-$(date +%s).txt"
  echo "⚡ Concurrency Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Concurrency patterns roundtable complete."; exit 0; fi

if [[ "$1" == "memory-models" ]]; then
  Q="How do CPU memory models and memory ordering affect concurrent software — C++ memory_order, Java volatile, Rust atomics?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/memory-models-$(date +%s).txt"
  echo "🧠 Memory Models Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Memory models roundtable complete."; exit 0; fi

if [[ "$1" == "dev-advocacy" ]]; then
  Q="What does great developer advocacy look like, and how do you build a developer community around a platform?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/dev-advocacy-$(date +%s).txt"
  echo "📣 Developer Advocacy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dev advocacy roundtable complete."; exit 0; fi

if [[ "$1" == "conference-talks" ]]; then
  Q="How do you craft a memorable conference talk — story arc, demos, emotional hooks, and handling nerves?"; AGENTS=(Lucidia Aria Shellfish Alice Octavia); OUT="$SAVE_DIR/conference-talks-$(date +%s).txt"
  echo "🎤 Conference Talks Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Conference talks roundtable complete."; exit 0; fi

if [[ "$1" == "eng-blogging" ]]; then
  Q="How do you write engineering blog posts that get read, shared, and drive real impact?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/eng-blogging-$(date +%s).txt"
  echo "✍️ Engineering Blogging Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eng blogging roundtable complete."; exit 0; fi

if [[ "$1" == "open-source-contrib" ]]; then
  Q="What does it take to become a meaningful open-source contributor and maintainer?"; AGENTS=(Alice Shellfish Octavia Aria Lucidia); OUT="$SAVE_DIR/open-source-contrib-$(date +%s).txt"
  echo "🌍 Open Source Contribution Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Open source contrib roundtable complete."; exit 0; fi

if [[ "$1" == "pair-programming" ]]; then
  Q="When does pair programming accelerate teams and when does it slow them down — how do you do it well?"; AGENTS=(Lucidia Alice Aria Shellfish Octavia); OUT="$SAVE_DIR/pair-programming-$(date +%s).txt"
  echo "👥 Pair Programming Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Pair programming roundtable complete."; exit 0; fi

if [[ "$1" == "mob-programming" ]]; then
  Q="What is mob programming, how does it work at scale, and what kind of teams benefit most from it?"; AGENTS=(Octavia Aria Shellfish Alice Lucidia); OUT="$SAVE_DIR/mob-programming-$(date +%s).txt"
  echo "🚌 Mob Programming Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Mob programming roundtable complete."; exit 0; fi

if [[ "$1" == "code-golf" ]]; then
  Q="What can code golf teach you about your language, algorithms, and problem-solving creativity?"; AGENTS=(Shellfish Lucidia Octavia Aria Alice); OUT="$SAVE_DIR/code-golf-$(date +%s).txt"
  echo "⛳ Code Golf Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Code golf roundtable complete."; exit 0; fi

if [[ "$1" == "refactoring-patterns" ]]; then
  Q="What are the most powerful refactoring patterns — extract method, strangler fig, parallel change, mikado?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/refactoring-patterns-$(date +%s).txt"
  echo "🔧 Refactoring Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Refactoring patterns roundtable complete."; exit 0; fi

if [[ "$1" == "clean-code" ]]; then
  Q="What does clean code actually mean in 2025 — naming, functions, modules, and when rules should break?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/clean-code-$(date +%s).txt"
  echo "✨ Clean Code Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Clean code roundtable complete."; exit 0; fi

if [[ "$1" == "domain-driven-design" ]]; then
  Q="How do bounded contexts, aggregates, and ubiquitous language from DDD translate to modern microservices?"; AGENTS=(Octavia Lucidia Aria Alice Shellfish); OUT="$SAVE_DIR/domain-driven-design-$(date +%s).txt"
  echo "🏛️ Domain-Driven Design Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DDD roundtable complete."; exit 0; fi

if [[ "$1" == "api-rate-card" ]]; then
  Q="How do you design and communicate API pricing — rate cards, usage tiers, and developer-friendly limits?"; AGENTS=(Aria Alice Shellfish Octavia Lucidia); OUT="$SAVE_DIR/api-rate-card-$(date +%s).txt"
  echo "💳 API Rate Card Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API rate card roundtable complete."; exit 0; fi

if [[ "$1" == "product-led-growth" ]]; then
  Q="How do engineering decisions — onboarding, time-to-value, viral loops — drive product-led growth?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/product-led-growth-$(date +%s).txt"
  echo "📈 Product-Led Growth Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ PLG roundtable complete."; exit 0; fi

if [[ "$1" == "eng-pricing" ]]; then
  Q="How do engineers model usage, capacity, and cost to inform pricing decisions at scale?"; AGENTS=(Shellfish Octavia Aria Alice Lucidia); OUT="$SAVE_DIR/eng-pricing-$(date +%s).txt"
  echo "💰 Engineering Pricing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eng pricing roundtable complete."; exit 0; fi

if [[ "$1" == "freemium-engineering" ]]; then
  Q="How do you architect a freemium system that converts users without punishing them with artificial limits?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/freemium-engineering-$(date +%s).txt"
  echo "🎁 Freemium Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Freemium engineering roundtable complete."; exit 0; fi

if [[ "$1" == "self-serve-infra" ]]; then
  Q="What makes infrastructure genuinely self-serve — golden paths, automation, and removing the ops bottleneck?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/self-serve-infra-$(date +%s).txt"
  echo "🛤️ Self-Serve Infrastructure Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Self-serve infra roundtable complete."; exit 0; fi

if [[ "$1" == "usage-metering" ]]; then
  Q="How do you instrument, collect, and process usage metrics for metered billing at massive scale?"; AGENTS=(Shellfish Alice Octavia Aria Lucidia); OUT="$SAVE_DIR/usage-metering-$(date +%s).txt"
  echo "📊 Usage Metering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Usage metering roundtable complete."; exit 0; fi

if [[ "$1" == "subscription-engines" ]]; then
  Q="What are the engineering challenges of building a subscription billing engine — renewals, prorations, dunning?"; AGENTS=(Aria Lucidia Shellfish Octavia Alice); OUT="$SAVE_DIR/subscription-engines-$(date +%s).txt"
  echo "🔄 Subscription Engines Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Subscription engines roundtable complete."; exit 0; fi

if [[ "$1" == "trial-conversion-eng" ]]; then
  Q="What engineering and product signals indicate trial users are likely to convert, and how do you act on them?"; AGENTS=(Alice Octavia Aria Lucidia Shellfish); OUT="$SAVE_DIR/trial-conversion-eng-$(date +%s).txt"
  echo "🎯 Trial Conversion Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Trial conversion roundtable complete."; exit 0; fi

if [[ "$1" == "quota-management" ]]; then
  Q="How do you implement flexible quota management — per-user, per-org, per-feature — without starving tenants?"; AGENTS=(Octavia Shellfish Lucidia Alice Aria); OUT="$SAVE_DIR/quota-management-$(date +%s).txt"
  echo "📏 Quota Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Quota management roundtable complete."; exit 0; fi

if [[ "$1" == "entitlements" ]]; then
  Q="How do you build an entitlements system that handles feature flags, plan gates, and add-ons flexibly?"; AGENTS=(Lucidia Alice Shellfish Octavia Aria); OUT="$SAVE_DIR/entitlements-$(date +%s).txt"
  echo "🔑 Entitlements Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Entitlements roundtable complete."; exit 0; fi

if [[ "$1" == "wasm-edge" ]]; then
  Q="How does WebAssembly at the edge enable portable, sandboxed compute closer to users?"; AGENTS=(Aria Octavia Shellfish Alice Lucidia); OUT="$SAVE_DIR/wasm-edge-$(date +%s).txt"
  echo "🕸️ WASM Edge Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ WASM edge roundtable complete."; exit 0; fi

if [[ "$1" == "sqlite-everywhere" ]]; then
  Q="Why is SQLite having a renaissance — edge databases, Cloudflare D1, Turso, and embedded SQL for AI?"; AGENTS=(Shellfish Lucidia Aria Octavia Alice); OUT="$SAVE_DIR/sqlite-everywhere-$(date +%s).txt"
  echo "🗄️ SQLite Everywhere Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ SQLite everywhere roundtable complete."; exit 0; fi

if [[ "$1" == "htmx-patterns" ]]; then
  Q="How does HTMX change the frontend/backend relationship, and when is it the right tool vs React?"; AGENTS=(Aria Alice Octavia Lucidia Shellfish); OUT="$SAVE_DIR/htmx-patterns-$(date +%s).txt"
  echo "🌐 HTMX Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ HTMX patterns roundtable complete."; exit 0; fi

if [[ "$1" == "edge-functions" ]]; then
  Q="What workloads genuinely benefit from edge functions, and what are the hidden costs of moving compute to the edge?"; AGENTS=(Octavia Alice Aria Shellfish Lucidia); OUT="$SAVE_DIR/edge-functions-$(date +%s).txt"
  echo "⚡ Edge Functions Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Edge functions roundtable complete."; exit 0; fi

if [[ "$1" == "deno-bun" ]]; then
  Q="How do Deno and Bun challenge Node.js — security model, performance, compatibility, and ecosystem?"; AGENTS=(Lucidia Shellfish Alice Octavia Aria); OUT="$SAVE_DIR/deno-bun-$(date +%s).txt"
  echo "🦕 Deno/Bun Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Deno/Bun roundtable complete."; exit 0; fi

if [[ "$1" == "zig-lang" ]]; then
  Q="What makes Zig interesting for systems programming — comptime, error handling, and C interop?"; AGENTS=(Shellfish Octavia Lucidia Aria Alice); OUT="$SAVE_DIR/zig-lang-$(date +%s).txt"
  echo "⚡ Zig Lang Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Zig lang roundtable complete."; exit 0; fi

if [[ "$1" == "elixir-otp" ]]; then
  Q="How does Elixir OTP — GenServer, supervisors, let it crash — build truly reliable systems?"; AGENTS=(Alice Lucidia Shellfish Aria Octavia); OUT="$SAVE_DIR/elixir-otp-$(date +%s).txt"
  echo "💧 Elixir OTP Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Elixir OTP roundtable complete."; exit 0; fi

if [[ "$1" == "swift-server" ]]; then
  Q="What is the state of Swift on the server — Vapor, Hummingbird, async/await, and where it shines?"; AGENTS=(Aria Octavia Alice Lucidia Shellfish); OUT="$SAVE_DIR/swift-server-$(date +%s).txt"
  echo "🍎 Swift Server Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Swift server roundtable complete."; exit 0; fi

if [[ "$1" == "kotlin-multiplatform" ]]; then
  Q="How does Kotlin Multiplatform share business logic between iOS, Android, server, and web?"; AGENTS=(Lucidia Alice Octavia Shellfish Aria); OUT="$SAVE_DIR/kotlin-multiplatform-$(date +%s).txt"
  echo "🎯 Kotlin Multiplatform Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Kotlin multiplatform roundtable complete."; exit 0; fi

if [[ "$1" == "dart-flutter" ]]; then
  Q="What makes Flutter and Dart compelling for cross-platform apps, and what are the tradeoffs vs native?"; AGENTS=(Aria Shellfish Lucidia Alice Octavia); OUT="$SAVE_DIR/dart-flutter-$(date +%s).txt"
  echo "🐦 Dart/Flutter Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dart/Flutter roundtable complete."; exit 0; fi

if [[ "$1" == "haskell-types" ]]; then
  Q="What can Haskell's type system — monads, type classes, GADTs — teach mainstream developers?"; AGENTS=(Octavia Lucidia Shellfish Aria Alice); OUT="$SAVE_DIR/haskell-types-$(date +%s).txt"
  echo "λ Haskell Types Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Haskell types roundtable complete."; exit 0; fi

if [[ "$1" == "clojure-data" ]]; then
  Q="How does Clojure's data-first philosophy — immutable maps, edn, spec — simplify complex systems?"; AGENTS=(Shellfish Alice Octavia Aria Lucidia); OUT="$SAVE_DIR/clojure-data-$(date +%s).txt"
  echo "🔵 Clojure Data Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Clojure data roundtable complete."; exit 0; fi

if [[ "$1" == "ocaml-systems" ]]; then
  Q="Why are companies like Jane Street using OCaml for mission-critical systems, and what makes it special?"; AGENTS=(Lucidia Aria Octavia Shellfish Alice); OUT="$SAVE_DIR/ocaml-systems-$(date +%s).txt"
  echo "🐪 OCaml Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ OCaml systems roundtable complete."; exit 0; fi

if [[ "$1" == "scala-akka" ]]; then
  Q="How does Scala's type system combined with Akka actors enable large-scale distributed systems?"; AGENTS=(Alice Octavia Lucidia Shellfish Aria); OUT="$SAVE_DIR/scala-akka-$(date +%s).txt"
  echo "⭐ Scala/Akka Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Scala/Akka roundtable complete."; exit 0; fi

if [[ "$1" == "ruby-renaissance" ]]; then
  Q="Is Ruby having a renaissance with YJIT, Fibers, and Shopify's investment — what's the future of Ruby?"; AGENTS=(Aria Lucidia Alice Octavia Shellfish); OUT="$SAVE_DIR/ruby-renaissance-$(date +%s).txt"
  echo "💎 Ruby Renaissance Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Ruby renaissance roundtable complete."; exit 0; fi

if [[ "$1" == "php-modern" ]]; then
  Q="How has modern PHP — fibers, named args, types, Laravel, Symfony — transformed its reputation?"; AGENTS=(Shellfish Octavia Aria Lucidia Alice); OUT="$SAVE_DIR/php-modern-$(date +%s).txt"
  echo "🐘 Modern PHP Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Modern PHP roundtable complete."; exit 0; fi

if [[ "$1" == "c-sharp-cloud" ]]; then
  Q="How is C# and .NET evolving for cloud-native development — Minimal APIs, Blazor, MAUI, AOT?"; AGENTS=(Octavia Alice Shellfish Lucidia Aria); OUT="$SAVE_DIR/c-sharp-cloud-$(date +%s).txt"
  echo "🔷 C# Cloud Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ C# cloud roundtable complete."; exit 0; fi

if [[ "$1" == "python-ml-ops" ]]; then
  Q="What does a mature Python MLOps stack look like — MLflow, Ray, Feast, Seldon, and beyond?"; AGENTS=(Lucidia Shellfish Octavia Aria Alice); OUT="$SAVE_DIR/python-ml-ops-$(date +%s).txt"
  echo "🐍 Python MLOps Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Python MLOps roundtable complete."; exit 0; fi

if [[ "$1" == "vector-databases" ]]; then
  Q="How do vector databases — Pinecone, Qdrant, Weaviate, Chroma — work, and when should you use them?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/vector-databases-$(date +%s).txt"
  echo "🗃️ Vector Databases Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Vector databases roundtable complete."; exit 0; fi

if [[ "$1" == "rag-architecture" ]]; then
  Q="What are the key components of a production RAG system — chunking, embedding, retrieval, reranking, generation?"; AGENTS=(Octavia Lucidia Aria Shellfish Alice); OUT="$SAVE_DIR/rag-architecture-$(date +%s).txt"
  echo "🔍 RAG Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ RAG architecture roundtable complete."; exit 0; fi

if [[ "$1" == "fine-tuning" ]]; then
  Q="When should you fine-tune a model vs RAG vs prompt engineering, and what does the process look like?"; AGENTS=(Shellfish Alice Lucidia Aria Octavia); OUT="$SAVE_DIR/fine-tuning-$(date +%s).txt"
  echo "🎯 Fine-Tuning Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Fine-tuning roundtable complete."; exit 0; fi

if [[ "$1" == "prompt-engineering" ]]; then
  Q="What are the highest-leverage prompt engineering techniques — chain-of-thought, few-shot, structured outputs?"; AGENTS=(Lucidia Aria Alice Shellfish Octavia); OUT="$SAVE_DIR/prompt-engineering-$(date +%s).txt"
  echo "💬 Prompt Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Prompt engineering roundtable complete."; exit 0; fi

if [[ "$1" == "ai-agents-arch" ]]; then
  Q="What architectural patterns make AI agents reliable — tool use, memory, planning, and error recovery?"; AGENTS=(Octavia Lucidia Shellfish Alice Aria); OUT="$SAVE_DIR/ai-agents-arch-$(date +%s).txt"
  echo "🤖 AI Agents Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI agents arch roundtable complete."; exit 0; fi

if [[ "$1" == "llm-inference-opt" ]]; then
  Q="How do you optimize LLM inference — KV cache, speculative decoding, quantization, batching strategies?"; AGENTS=(Shellfish Octavia Alice Lucidia Aria); OUT="$SAVE_DIR/llm-inference-opt-$(date +%s).txt"
  echo "⚡ LLM Inference Optimization Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ LLM inference opt roundtable complete."; exit 0; fi

if [[ "$1" == "transformer-arch" ]]; then
  Q="How does the transformer architecture work — attention mechanisms, positional encoding, and modern variants?"; AGENTS=(Lucidia Octavia Aria Shellfish Alice); OUT="$SAVE_DIR/transformer-arch-$(date +%s).txt"
  echo "🧬 Transformer Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Transformer arch roundtable complete."; exit 0; fi

if [[ "$1" == "diffusion-models" ]]; then
  Q="How do diffusion models — DDPM, DDIM, stable diffusion — work and what makes them better than GANs for generation?"; AGENTS=(Lucidia Aria Octavia Shellfish Alice); OUT="$SAVE_DIR/diffusion-models-$(date +%s).txt"
  echo "🎨 Diffusion Models Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Diffusion models roundtable complete."; exit 0; fi

if [[ "$1" == "multimodal-ai" ]]; then
  Q="How do multimodal models handle vision, audio, and text together — architecture, training, alignment?"; AGENTS=(Octavia Lucidia Aria Alice Shellfish); OUT="$SAVE_DIR/multimodal-ai-$(date +%s).txt"
  echo "👁️ Multimodal AI Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multimodal AI roundtable complete."; exit 0; fi

if [[ "$1" == "ai-safety" ]]; then
  Q="What are the key open problems in AI safety — alignment, interpretability, robustness, and corrigibility?"; AGENTS=(Shellfish Lucidia Octavia Aria Alice); OUT="$SAVE_DIR/ai-safety-$(date +%s).txt"
  echo "🛡️ AI Safety Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI safety roundtable complete."; exit 0; fi

if [[ "$1" == "ai-alignment" ]]; then
  Q="What does AI alignment mean in practice, and how do RLHF, constitutional AI, and debate approaches compare?"; AGENTS=(Lucidia Alice Shellfish Octavia Aria); OUT="$SAVE_DIR/ai-alignment-$(date +%s).txt"
  echo "🎯 AI Alignment Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI alignment roundtable complete."; exit 0; fi

if [[ "$1" == "neural-arch-search" ]]; then
  Q="How does neural architecture search automate model design — DARTS, evolutionary methods, hardware-aware NAS?"; AGENTS=(Aria Octavia Lucidia Shellfish Alice); OUT="$SAVE_DIR/neural-arch-search-$(date +%s).txt"
  echo "🔬 Neural Architecture Search Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ NAS roundtable complete."; exit 0; fi

if [[ "$1" == "federated-learning" ]]; then
  Q="How does federated learning enable training on distributed private data without centralizing it?"; AGENTS=(Alice Shellfish Aria Lucidia Octavia); OUT="$SAVE_DIR/federated-learning-$(date +%s).txt"
  echo "🌐 Federated Learning Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Federated learning roundtable complete."; exit 0; fi

if [[ "$1" == "model-compression" ]]; then
  Q="What are the tradeoffs between quantization, pruning, distillation, and MoE for making models smaller and faster?"; AGENTS=(Octavia Lucidia Alice Aria Shellfish); OUT="$SAVE_DIR/model-compression-$(date +%s).txt"
  echo "📦 Model Compression Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Model compression roundtable complete."; exit 0; fi

if [[ "$1" == "context-windows" ]]; then
  Q="How are LLMs handling longer context — RoPE scaling, sliding windows, memory, and retrieval augmentation?"; AGENTS=(Lucidia Aria Octavia Shellfish Alice); OUT="$SAVE_DIR/context-windows-$(date +%s).txt"
  echo "📜 Context Windows Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Context windows roundtable complete."; exit 0; fi

if [[ "$1" == "mixture-of-experts" ]]; then
  Q="How do Mixture of Experts models — routing, sparsity, load balancing — scale efficiently?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/mixture-of-experts-$(date +%s).txt"
  echo "🧩 Mixture of Experts Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ MoE roundtable complete."; exit 0; fi

if [[ "$1" == "ai-hardware" ]]; then
  Q="How do GPUs, TPUs, IPUs, and custom silicon like Groq and Cerebras compare for AI workloads?"; AGENTS=(Aria Lucidia Shellfish Alice Octavia); OUT="$SAVE_DIR/ai-hardware-$(date +%s).txt"
  echo "💾 AI Hardware Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI hardware roundtable complete."; exit 0; fi

if [[ "$1" == "devex-metrics" ]]; then
  Q="How do you measure developer experience — DORA, SPACE, DevEx frameworks, and leading indicators?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/devex-metrics-$(date +%s).txt"
  echo "📏 DevEx Metrics Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DevEx metrics roundtable complete."; exit 0; fi

if [[ "$1" == "eng-onboarding" ]]; then
  Q="What does a world-class engineering onboarding look like — week one, month one, what new hires need?"; AGENTS=(Lucidia Aria Shellfish Octavia Alice); OUT="$SAVE_DIR/eng-onboarding-$(date +%s).txt"
  echo "🎓 Engineering Onboarding Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eng onboarding roundtable complete."; exit 0; fi

if [[ "$1" == "remote-eng-culture" ]]; then
  Q="How do top remote engineering teams maintain culture, collaboration, and high output across time zones?"; AGENTS=(Alice Octavia Aria Lucidia Shellfish); OUT="$SAVE_DIR/remote-eng-culture-$(date +%s).txt"
  echo "🌍 Remote Engineering Culture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Remote eng culture roundtable complete."; exit 0; fi

if [[ "$1" == "async-first-culture" ]]; then
  Q="What does async-first engineering culture look like — documentation, decision-making, rituals?"; AGENTS=(Shellfish Lucidia Alice Aria Octavia); OUT="$SAVE_DIR/async-first-culture-$(date +%s).txt"
  echo "📬 Async-First Culture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Async-first culture roundtable complete."; exit 0; fi

if [[ "$1" == "eng-levels" ]]; then
  Q="How do you define engineering levels — L3 to L7, staff vs principal vs distinguished — and what matters most?"; AGENTS=(Octavia Aria Lucidia Alice Shellfish); OUT="$SAVE_DIR/eng-levels-$(date +%s).txt"
  echo "📊 Engineering Levels Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eng levels roundtable complete."; exit 0; fi

if [[ "$1" == "staff-plus" ]]; then
  Q="What does Staff+ engineering look like — glue work, tech strategy, cross-team influence, IC tracks?"; AGENTS=(Lucidia Shellfish Octavia Aria Alice); OUT="$SAVE_DIR/staff-plus-$(date +%s).txt"
  echo "⭐ Staff+ Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Staff+ roundtable complete."; exit 0; fi

if [[ "$1" == "eng-management" ]]; then
  Q="What makes a great engineering manager — 1-on-1s, growth, shielding, hiring, and staying technical?"; AGENTS=(Aria Alice Shellfish Lucidia Octavia); OUT="$SAVE_DIR/eng-management-$(date +%s).txt"
  echo "👔 Engineering Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eng management roundtable complete."; exit 0; fi

if [[ "$1" == "hiring-for-culture" ]]; then
  Q="How do you hire for culture and values without creating bias — structured interviews, work samples, rubrics?"; AGENTS=(Alice Lucidia Aria Octavia Shellfish); OUT="$SAVE_DIR/hiring-for-culture-$(date +%s).txt"
  echo "🎯 Hiring for Culture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Hiring for culture roundtable complete."; exit 0; fi

if [[ "$1" == "tech-debt-strategy" ]]; then
  Q="How do you create a sustainable strategy for managing and reducing tech debt without stopping feature work?"; AGENTS=(Octavia Shellfish Lucidia Alice Aria); OUT="$SAVE_DIR/tech-debt-strategy-$(date +%s).txt"
  echo "🏦 Tech Debt Strategy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Tech debt strategy roundtable complete."; exit 0; fi

if [[ "$1" == "platform-teams" ]]; then
  Q="How do platform/infrastructure teams balance internal product thinking with serving stream-aligned teams?"; AGENTS=(Lucidia Aria Alice Shellfish Octavia); OUT="$SAVE_DIR/platform-teams-$(date +%s).txt"
  echo "🏗️ Platform Teams Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Platform teams roundtable complete."; exit 0; fi

if [[ "$1" == "team-topologies" ]]; then
  Q="How do Team Topologies patterns — stream-aligned, enabling, complicated subsystem, platform — apply in practice?"; AGENTS=(Shellfish Octavia Lucidia Aria Alice); OUT="$SAVE_DIR/team-topologies-$(date +%s).txt"
  echo "🗺️ Team Topologies Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Team topologies roundtable complete."; exit 0; fi

if [[ "$1" == "conway-law" ]]; then
  Q="How does Conway's Law shape your architecture, and how do you intentionally design org structure to influence system design?"; AGENTS=(Aria Alice Octavia Lucidia Shellfish); OUT="$SAVE_DIR/conway-law-$(date +%s).txt"
  echo "🔄 Conway's Law Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Conway's law roundtable complete."; exit 0; fi

if [[ "$1" == "inner-source" ]]; then
  Q="How does inner source — applying open-source practices to internal development — accelerate engineering orgs?"; AGENTS=(Lucidia Shellfish Aria Octavia Alice); OUT="$SAVE_DIR/inner-source-$(date +%s).txt"
  echo "🌱 Inner Source Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Inner source roundtable complete."; exit 0; fi

if [[ "$1" == "doc-as-code" ]]; then
  Q="What does docs-as-code mean in practice — OpenAPI, arc42, ADRs, and keeping docs in sync with code?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/doc-as-code-$(date +%s).txt"
  echo "📄 Docs as Code Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Doc as code roundtable complete."; exit 0; fi

if [[ "$1" == "api-first-design" ]]; then
  Q="What does API-first development look like — contract-first, design reviews, mock servers, versioning strategy?"; AGENTS=(Aria Lucidia Octavia Alice Shellfish); OUT="$SAVE_DIR/api-first-design-$(date +%s).txt"
  echo "🔌 API-First Design Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API-first design roundtable complete."; exit 0; fi

if [[ "$1" == "zero-trust-eng" ]]; then
  Q="How do you implement zero trust architecture in practice — BeyondCorp, identity-aware proxies, microsegmentation?"; AGENTS=(Shellfish Alice Aria Octavia Lucidia); OUT="$SAVE_DIR/zero-trust-eng-$(date +%s).txt"
  echo "🔐 Zero Trust Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Zero trust eng roundtable complete."; exit 0; fi

if [[ "$1" == "supply-chain-security" ]]; then
  Q="How do SLSA, Sigstore, SBOM, and dependency scanning protect the software supply chain?"; AGENTS=(Lucidia Octavia Shellfish Aria Alice); OUT="$SAVE_DIR/supply-chain-security-$(date +%s).txt"
  echo "🔒 Supply Chain Security Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Supply chain security roundtable complete."; exit 0; fi

if [[ "$1" == "soc2-eng" ]]; then
  Q="What does SOC2 compliance mean for engineering teams — controls, evidence collection, audit prep?"; AGENTS=(Alice Aria Lucidia Shellfish Octavia); OUT="$SAVE_DIR/soc2-eng-$(date +%s).txt"
  echo "📋 SOC2 Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ SOC2 eng roundtable complete."; exit 0; fi

if [[ "$1" == "gdpr-eng" ]]; then
  Q="What engineering decisions are required for GDPR compliance — data residency, consent, erasure, portability?"; AGENTS=(Octavia Shellfish Aria Lucidia Alice); OUT="$SAVE_DIR/gdpr-eng-$(date +%s).txt"
  echo "🇪🇺 GDPR Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ GDPR eng roundtable complete."; exit 0; fi

if [[ "$1" == "penetration-testing" ]]; then
  Q="What does a comprehensive penetration test cover — OWASP, PTES, social engineering, remediation?"; AGENTS=(Shellfish Lucidia Octavia Alice Aria); OUT="$SAVE_DIR/penetration-testing-$(date +%s).txt"
  echo "🎯 Penetration Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Pen testing roundtable complete."; exit 0; fi

if [[ "$1" == "threat-modeling" ]]; then
  Q="How do you run threat modeling sessions — STRIDE, PASTA, attack trees — and act on findings?"; AGENTS=(Lucidia Alice Shellfish Octavia Aria); OUT="$SAVE_DIR/threat-modeling-$(date +%s).txt"
  echo "⚔️ Threat Modeling Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Threat modeling roundtable complete."; exit 0; fi

if [[ "$1" == "devsecops" ]]; then
  Q="How do you embed security into the SDLC — SAST, DAST, secrets scanning, dependency review, runtime protection?"; AGENTS=(Aria Octavia Lucidia Shellfish Alice); OUT="$SAVE_DIR/devsecops-$(date +%s).txt"
  echo "🔐 DevSecOps Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DevSecOps roundtable complete."; exit 0; fi

if [[ "$1" == "crypto-engineering" ]]; then
  Q="What every engineer should know about cryptography — hashing, symmetric, asymmetric, TLS, JWT, and common mistakes?"; AGENTS=(Shellfish Alice Octavia Aria Lucidia); OUT="$SAVE_DIR/crypto-engineering-$(date +%s).txt"
  echo "🔑 Cryptography Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Crypto engineering roundtable complete."; exit 0; fi

if [[ "$1" == "oauth-oidc" ]]; then
  Q="How do OAuth2 and OIDC work end-to-end, and what are the common implementation mistakes?"; AGENTS=(Lucidia Aria Shellfish Octavia Alice); OUT="$SAVE_DIR/oauth-oidc-$(date +%s).txt"
  echo "🔏 OAuth/OIDC Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ OAuth/OIDC roundtable complete."; exit 0; fi

if [[ "$1" == "passkeys" ]]; then
  Q="How do passkeys and WebAuthn replace passwords — FIDO2, discoverable credentials, cross-device auth?"; AGENTS=(Octavia Alice Lucidia Shellfish Aria); OUT="$SAVE_DIR/passkeys-$(date +%s).txt"
  echo "🗝️ Passkeys Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Passkeys roundtable complete."; exit 0; fi

if [[ "$1" == "network-security" ]]; then
  Q="How do you architect network security — VPCs, NACLs, WAFs, DDoS protection, and east-west traffic inspection?"; AGENTS=(Shellfish Lucidia Alice Aria Octavia); OUT="$SAVE_DIR/network-security-$(date +%s).txt"
  echo "🌐 Network Security Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Network security roundtable complete."; exit 0; fi

if [[ "$1" == "container-security" ]]; then
  Q="How do you secure containers at every layer — images, registries, runtime, Kubernetes RBAC, and pod security?"; AGENTS=(Alice Octavia Aria Lucidia Shellfish); OUT="$SAVE_DIR/container-security-$(date +%s).txt"
  echo "🐳 Container Security Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Container security roundtable complete."; exit 0; fi

if [[ "$1" == "sre-practices" ]]; then
  Q="What are the core SRE practices — SLOs, error budgets, toil reduction, blameless postmortems?"; AGENTS=(Lucidia Shellfish Octavia Alice Aria); OUT="$SAVE_DIR/sre-practices-$(date +%s).txt"
  echo "⚙️ SRE Practices Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ SRE practices roundtable complete."; exit 0; fi

if [[ "$1" == "capacity-planning" ]]; then
  Q="How do you do capacity planning for fast-growing systems — forecasting, headroom, load testing, cost modeling?"; AGENTS=(Octavia Aria Alice Lucidia Shellfish); OUT="$SAVE_DIR/capacity-planning-$(date +%s).txt"
  echo "📐 Capacity Planning Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Capacity planning roundtable complete."; exit 0; fi

if [[ "$1" == "service-mesh" ]]; then
  Q="How do service meshes — Istio, Linkerd, Cilium — handle observability, mTLS, and traffic management?"; AGENTS=(Octavia Shellfish Alice Lucidia Aria); OUT="$SAVE_DIR/service-mesh-$(date +%s).txt"
  echo "🕸️ Service Mesh Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Service mesh roundtable complete."; exit 0; fi

if [[ "$1" == "gitops" ]]; then
  Q="How does GitOps change operations — Flux, ArgoCD, pull-based deployments, and drift detection?"; AGENTS=(Alice Lucidia Octavia Aria Shellfish); OUT="$SAVE_DIR/gitops-$(date +%s).txt"
  echo "🔁 GitOps Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ GitOps roundtable complete."; exit 0; fi

if [[ "$1" == "platform-engineering" ]]; then
  Q="What does a world-class platform engineering org look like — IDP, paved roads, self-service, and toil elimination?"; AGENTS=(Lucidia Aria Octavia Shellfish Alice); OUT="$SAVE_DIR/platform-engineering-$(date +%s).txt"
  echo "🏗️ Platform Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Platform engineering roundtable complete."; exit 0; fi

if [[ "$1" == "observability-adv" ]]; then
  Q="What's beyond basic logging and metrics — continuous profiling, exemplars, wide events, and OpenTelemetry?"; AGENTS=(Aria Shellfish Lucidia Octavia Alice); OUT="$SAVE_DIR/observability-adv-$(date +%s).txt"
  echo "🔭 Advanced Observability Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced observability roundtable complete."; exit 0; fi

if [[ "$1" == "finops" ]]; then
  Q="How do you build FinOps practices — unit economics, cloud cost attribution, waste reduction, forecasting?"; AGENTS=(Shellfish Alice Aria Lucidia Octavia); OUT="$SAVE_DIR/finops-$(date +%s).txt"
  echo "💰 FinOps Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ FinOps roundtable complete."; exit 0; fi

if [[ "$1" == "database-migrations" ]]; then
  Q="What are the safest patterns for zero-downtime database migrations — expand-contract, online schema changes?"; AGENTS=(Octavia Lucidia Shellfish Alice Aria); OUT="$SAVE_DIR/database-migrations-$(date +%s).txt"
  echo "🗄️ Database Migrations Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Database migrations roundtable complete."; exit 0; fi

if [[ "$1" == "sharding-strategies" ]]; then
  Q="How do you choose a sharding strategy — range, hash, directory, geo — and what are the operational costs?"; AGENTS=(Lucidia Aria Alice Shellfish Octavia); OUT="$SAVE_DIR/sharding-strategies-$(date +%s).txt"
  echo "🧩 Sharding Strategies Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Sharding strategies roundtable complete."; exit 0; fi

if [[ "$1" == "read-replicas" ]]; then
  Q="How do read replicas, CQRS, and read-through caches work together to scale database reads?"; AGENTS=(Alice Octavia Lucidia Aria Shellfish); OUT="$SAVE_DIR/read-replicas-$(date +%s).txt"
  echo "📖 Read Replicas Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Read replicas roundtable complete."; exit 0; fi

if [[ "$1" == "connection-pooling" ]]; then
  Q="How does database connection pooling work — PgBouncer, HikariCP, pool sizing, and avoiding pool exhaustion?"; AGENTS=(Shellfish Lucidia Octavia Alice Aria); OUT="$SAVE_DIR/connection-pooling-$(date +%s).txt"
  echo "🔗 Connection Pooling Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Connection pooling roundtable complete."; exit 0; fi

if [[ "$1" == "time-series-db" ]]; then
  Q="What makes time series databases — InfluxDB, TimescaleDB, Prometheus, VictoriaMetrics — different from OLTP?"; AGENTS=(Aria Octavia Shellfish Lucidia Alice); OUT="$SAVE_DIR/time-series-db-$(date +%s).txt"
  echo "📈 Time Series DB Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Time series DB roundtable complete."; exit 0; fi

if [[ "$1" == "graph-databases" ]]; then
  Q="When do graph databases shine — Neo4j, Dgraph, Neptune — and how does graph thinking change your data model?"; AGENTS=(Lucidia Alice Aria Octavia Shellfish); OUT="$SAVE_DIR/graph-databases-$(date +%s).txt"
  echo "🕸️ Graph Databases Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Graph databases roundtable complete."; exit 0; fi

if [[ "$1" == "search-engines" ]]; then
  Q="How do search engines like Elasticsearch, Meilisearch, and Typesense handle indexing, ranking, and relevance?"; AGENTS=(Octavia Shellfish Alice Aria Lucidia); OUT="$SAVE_DIR/search-engines-$(date +%s).txt"
  echo "🔍 Search Engines Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Search engines roundtable complete."; exit 0; fi

if [[ "$1" == "stream-processing" ]]; then
  Q="How do Flink, Spark Streaming, and Kafka Streams differ, and when is each the right choice?"; AGENTS=(Shellfish Lucidia Octavia Alice Aria); OUT="$SAVE_DIR/stream-processing-$(date +%s).txt"
  echo "🌊 Stream Processing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Stream processing roundtable complete."; exit 0; fi

if [[ "$1" == "data-warehouse" ]]; then
  Q="How do modern data warehouses — Snowflake, BigQuery, Redshift, DuckDB — handle analytical workloads?"; AGENTS=(Aria Alice Shellfish Lucidia Octavia); OUT="$SAVE_DIR/data-warehouse-$(date +%s).txt"
  echo "🏭 Data Warehouse Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data warehouse roundtable complete."; exit 0; fi

if [[ "$1" == "dbt-modeling" ]]; then
  Q="How does dbt change the analytics engineering workflow — models, tests, documentation, and lineage?"; AGENTS=(Lucidia Octavia Aria Shellfish Alice); OUT="$SAVE_DIR/dbt-modeling-$(date +%s).txt"
  echo "🔧 dbt Modeling Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ dbt modeling roundtable complete."; exit 0; fi

if [[ "$1" == "data-lakehouse" ]]; then
  Q="What is the data lakehouse pattern — Delta Lake, Apache Iceberg, Hudi — and how does it unify analytics?"; AGENTS=(Alice Shellfish Lucidia Octavia Aria); OUT="$SAVE_DIR/data-lakehouse-$(date +%s).txt"
  echo "🏠 Data Lakehouse Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data lakehouse roundtable complete."; exit 0; fi

if [[ "$1" == "event-sourcing-adv" ]]; then
  Q="What are the advanced challenges of event sourcing at scale — projections, snapshots, event versioning?"; AGENTS=(Octavia Aria Alice Lucidia Shellfish); OUT="$SAVE_DIR/event-sourcing-adv-$(date +%s).txt"
  echo "📜 Advanced Event Sourcing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced event sourcing roundtable complete."; exit 0; fi

if [[ "$1" == "outbox-pattern" ]]; then
  Q="How does the transactional outbox pattern guarantee reliable event publishing alongside database writes?"; AGENTS=(Shellfish Lucidia Alice Aria Octavia); OUT="$SAVE_DIR/outbox-pattern-$(date +%s).txt"
  echo "📤 Outbox Pattern Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Outbox pattern roundtable complete."; exit 0; fi

if [[ "$1" == "idempotency" ]]; then
  Q="How do you design idempotent APIs and systems — idempotency keys, deduplication, at-least-once processing?"; AGENTS=(Lucidia Shellfish Octavia Alice Aria); OUT="$SAVE_DIR/idempotency-$(date +%s).txt"
  echo "🔁 Idempotency Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Idempotency roundtable complete."; exit 0; fi

if [[ "$1" == "retry-patterns" ]]; then
  Q="What are the best retry patterns — exponential backoff, jitter, circuit breakers, bulkheads — for distributed systems?"; AGENTS=(Aria Alice Lucidia Shellfish Octavia); OUT="$SAVE_DIR/retry-patterns-$(date +%s).txt"
  echo "🔄 Retry Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Retry patterns roundtable complete."; exit 0; fi

if [[ "$1" == "distributed-locks" ]]; then
  Q="How do distributed locks work — Redlock, ZooKeeper, etcd — and when should you avoid them entirely?"; AGENTS=(Octavia Lucidia Aria Alice Shellfish); OUT="$SAVE_DIR/distributed-locks-$(date +%s).txt"
  echo "🔐 Distributed Locks Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Distributed locks roundtable complete."; exit 0; fi

if [[ "$1" == "rate-limiting-adv" ]]; then
  Q="What are the advanced rate limiting algorithms — token bucket, leaky bucket, sliding window, Redis — at scale?"; AGENTS=(Shellfish Aria Octavia Lucidia Alice); OUT="$SAVE_DIR/rate-limiting-adv-$(date +%s).txt"
  echo "⏱️ Advanced Rate Limiting Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced rate limiting roundtable complete."; exit 0; fi

if [[ "$1" == "cache-invalidation" ]]; then
  Q="Cache invalidation is famously hard — what are the best strategies for distributed cache consistency?"; AGENTS=(Alice Shellfish Lucidia Octavia Aria); OUT="$SAVE_DIR/cache-invalidation-$(date +%s).txt"
  echo "🗑️ Cache Invalidation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Cache invalidation roundtable complete."; exit 0; fi

if [[ "$1" == "cdn-strategy" ]]; then
  Q="How do you design a CDN strategy — edge caching, cache-control headers, purging, and origin shield?"; AGENTS=(Lucidia Octavia Shellfish Aria Alice); OUT="$SAVE_DIR/cdn-strategy-$(date +%s).txt"
  echo "🌐 CDN Strategy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ CDN strategy roundtable complete."; exit 0; fi

if [[ "$1" == "multi-region" ]]; then
  Q="How do you architect multi-region deployments — active-active vs active-passive, global load balancing, data sync?"; AGENTS=(Aria Alice Octavia Lucidia Shellfish); OUT="$SAVE_DIR/multi-region-$(date +%s).txt"
  echo "🌍 Multi-Region Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Multi-region roundtable complete."; exit 0; fi

if [[ "$1" == "disaster-recovery" ]]; then
  Q="How do you design a real disaster recovery plan — RTO, RPO, runbooks, chaos drills, and geo-failover?"; AGENTS=(Octavia Shellfish Aria Lucidia Alice); OUT="$SAVE_DIR/disaster-recovery-$(date +%s).txt"
  echo "🚨 Disaster Recovery Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Disaster recovery roundtable complete."; exit 0; fi

if [[ "$1" == "dns-engineering" ]]; then
  Q="What every engineer should understand about DNS — TTLs, anycast, split-horizon, GeoDNS, and failure modes?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/dns-engineering-$(date +%s).txt"
  echo "🌐 DNS Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DNS engineering roundtable complete."; exit 0; fi

if [[ "$1" == "load-balancing-adv" ]]; then
  Q="What are the advanced load balancing strategies — L4 vs L7, consistent hashing, sticky sessions, least connections?"; AGENTS=(Alice Aria Octavia Shellfish Lucidia); OUT="$SAVE_DIR/load-balancing-adv-$(date +%s).txt"
  echo "⚖️ Advanced Load Balancing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced load balancing roundtable complete."; exit 0; fi

if [[ "$1" == "tcp-ip-deep" ]]; then
  Q="What do software engineers need to deeply understand about TCP/IP — congestion control, Nagle, TIME_WAIT, BBR?"; AGENTS=(Lucidia Shellfish Octavia Aria Alice); OUT="$SAVE_DIR/tcp-ip-deep-$(date +%s).txt"
  echo "📡 TCP/IP Deep Dive Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ TCP/IP deep dive roundtable complete."; exit 0; fi

if [[ "$1" == "grpc-patterns" ]]; then
  Q="When should you choose gRPC over REST — streaming, code generation, performance, and browser support?"; AGENTS=(Aria Octavia Lucidia Shellfish Alice); OUT="$SAVE_DIR/grpc-patterns-$(date +%s).txt"
  echo "📡 gRPC Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ gRPC patterns roundtable complete."; exit 0; fi

if [[ "$1" == "websocket-scale" ]]; then
  Q="How do you scale WebSocket connections to millions — sticky sessions, pub/sub, horizontal scaling?"; AGENTS=(Shellfish Alice Aria Lucidia Octavia); OUT="$SAVE_DIR/websocket-scale-$(date +%s).txt"
  echo "🔌 WebSocket Scale Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ WebSocket scale roundtable complete."; exit 0; fi

if [[ "$1" == "http3-quic" ]]; then
  Q="How does HTTP/3 and QUIC improve on HTTP/2 — head-of-line blocking, connection migration, 0-RTT?"; AGENTS=(Octavia Lucidia Shellfish Alice Aria); OUT="$SAVE_DIR/http3-quic-$(date +%s).txt"
  echo "⚡ HTTP/3 QUIC Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ HTTP/3 QUIC roundtable complete."; exit 0; fi

if [[ "$1" == "api-pagination" ]]; then
  Q="What are the tradeoffs between offset, cursor, keyset, and seek pagination at scale?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/api-pagination-$(date +%s).txt"
  echo "📄 API Pagination Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API pagination roundtable complete."; exit 0; fi

if [[ "$1" == "api-versioning-adv" ]]; then
  Q="What are the tradeoffs between URL versioning, header versioning, content negotiation, and consumer-driven contracts?"; AGENTS=(Alice Shellfish Lucidia Aria Octavia); OUT="$SAVE_DIR/api-versioning-adv-$(date +%s).txt"
  echo "🔢 Advanced API Versioning Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Advanced API versioning roundtable complete."; exit 0; fi

if [[ "$1" == "data-contracts" ]]; then
  Q="What are data contracts and how do they bring software engineering discipline to data pipelines?"; AGENTS=(Aria Octavia Alice Lucidia Shellfish); OUT="$SAVE_DIR/data-contracts-$(date +%s).txt"
  echo "📋 Data Contracts Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Data contracts roundtable complete."; exit 0; fi

if [[ "$1" == "schema-registry" ]]; then
  Q="How does a schema registry — Confluent, Glue, Apicurio — ensure backward compatibility across event-driven systems?"; AGENTS=(Shellfish Lucidia Aria Octavia Alice); OUT="$SAVE_DIR/schema-registry-$(date +%s).txt"
  echo "📚 Schema Registry Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Schema registry roundtable complete."; exit 0; fi

if [[ "$1" == "async-api-design" ]]; then
  Q="How do AsyncAPI and event-driven design specs bring the same rigor to async APIs as OpenAPI does for REST?"; AGENTS=(Lucidia Alice Shellfish Aria Octavia); OUT="$SAVE_DIR/async-api-design-$(date +%s).txt"
  echo "📬 AsyncAPI Design Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AsyncAPI design roundtable complete."; exit 0; fi

if [[ "$1" == "integration-patterns" ]]; then
  Q="What are the core enterprise integration patterns — routing, transformation, aggregation, splitter, scatter-gather?"; AGENTS=(Octavia Aria Lucidia Shellfish Alice); OUT="$SAVE_DIR/integration-patterns-$(date +%s).txt"
  echo "🔌 Integration Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Integration patterns roundtable complete."; exit 0; fi

if [[ "$1" == "strangler-fig" ]]; then
  Q="How do you apply the strangler fig pattern to migrate a monolith to microservices without a big-bang rewrite?"; AGENTS=(Alice Shellfish Octavia Lucidia Aria); OUT="$SAVE_DIR/strangler-fig-$(date +%s).txt"
  echo "🌿 Strangler Fig Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Strangler fig roundtable complete."; exit 0; fi

if [[ "$1" == "monolith-modular" ]]; then
  Q="When is a modular monolith the right choice over microservices, and how do you keep modules truly decoupled?"; AGENTS=(Lucidia Aria Alice Octavia Shellfish); OUT="$SAVE_DIR/monolith-modular-$(date +%s).txt"
  echo "🏛️ Modular Monolith Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Modular monolith roundtable complete."; exit 0; fi

if [[ "$1" == "micro-frontends" ]]; then
  Q="How do micro-frontends work — module federation, iframe composition, web components — and when are they worth it?"; AGENTS=(Aria Octavia Shellfish Alice Lucidia); OUT="$SAVE_DIR/micro-frontends-$(date +%s).txt"
  echo "🖥️ Micro-Frontends Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Micro-frontends roundtable complete."; exit 0; fi

if [[ "$1" == "react-internals" ]]; then
  Q="How does React's reconciler, fiber architecture, and concurrent mode work under the hood?"; AGENTS=(Aria Lucidia Octavia Shellfish Alice); OUT="$SAVE_DIR/react-internals-$(date +%s).txt"
  echo "⚛️ React Internals Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ React internals roundtable complete."; exit 0; fi

if [[ "$1" == "nextjs-patterns" ]]; then
  Q="What are the key architectural decisions in Next.js 15 — App Router, Server Components, streaming, and caching?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/nextjs-patterns-$(date +%s).txt"
  echo "▲ Next.js Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Next.js patterns roundtable complete."; exit 0; fi

if [[ "$1" == "state-management" ]]; then
  Q="How do you choose between Zustand, Jotai, Redux Toolkit, TanStack Query, and server state in 2025?"; AGENTS=(Lucidia Shellfish Aria Alice Octavia); OUT="$SAVE_DIR/state-management-$(date +%s).txt"
  echo "🗃️ State Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ State management roundtable complete."; exit 0; fi

if [[ "$1" == "accessibility-eng" ]]; then
  Q="What does production-grade accessibility engineering look like — WCAG, ARIA, keyboard nav, screen reader testing?"; AGENTS=(Aria Octavia Lucidia Alice Shellfish); OUT="$SAVE_DIR/accessibility-eng-$(date +%s).txt"
  echo "♿ Accessibility Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Accessibility eng roundtable complete."; exit 0; fi

if [[ "$1" == "css-architecture" ]]; then
  Q="How do you architect CSS at scale — Tailwind, CSS Modules, CSS-in-JS, design tokens, and the cascade?"; AGENTS=(Shellfish Alice Aria Lucidia Octavia); OUT="$SAVE_DIR/css-architecture-$(date +%s).txt"
  echo "🎨 CSS Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ CSS architecture roundtable complete."; exit 0; fi

if [[ "$1" == "web-performance" ]]; then
  Q="What are the highest-impact web performance optimizations — Core Web Vitals, LCP, INP, CLS, and beyond?"; AGENTS=(Octavia Lucidia Shellfish Aria Alice); OUT="$SAVE_DIR/web-performance-$(date +%s).txt"
  echo "⚡ Web Performance Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Web performance roundtable complete."; exit 0; fi

if [[ "$1" == "edge-rendering" ]]; then
  Q="What are the rendering strategies at the edge — SSR, ISR, partial hydration, islands architecture?"; AGENTS=(Aria Alice Octavia Shellfish Lucidia); OUT="$SAVE_DIR/edge-rendering-$(date +%s).txt"
  echo "🌐 Edge Rendering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Edge rendering roundtable complete."; exit 0; fi

if [[ "$1" == "pwa-architecture" ]]; then
  Q="What makes a great Progressive Web App — service workers, offline-first, installability, push notifications?"; AGENTS=(Lucidia Shellfish Alice Octavia Aria); OUT="$SAVE_DIR/pwa-architecture-$(date +%s).txt"
  echo "📱 PWA Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ PWA architecture roundtable complete."; exit 0; fi

if [[ "$1" == "webgl-3d" ]]; then
  Q="How do WebGL, Three.js, and WebGPU enable immersive 3D experiences in the browser?"; AGENTS=(Octavia Aria Lucidia Shellfish Alice); OUT="$SAVE_DIR/webgl-3d-$(date +%s).txt"
  echo "🎮 WebGL/3D Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ WebGL/3D roundtable complete."; exit 0; fi

if [[ "$1" == "mobile-performance" ]]; then
  Q="What are the most impactful mobile performance optimizations for React Native and native iOS/Android apps?"; AGENTS=(Shellfish Lucidia Octavia Alice Aria); OUT="$SAVE_DIR/mobile-performance-$(date +%s).txt"
  echo "📲 Mobile Performance Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Mobile performance roundtable complete."; exit 0; fi

if [[ "$1" == "design-systems" ]]; then
  Q="How do you build and maintain a design system that scales — tokens, components, versioning, adoption?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/design-systems-$(date +%s).txt"
  echo "🎨 Design Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Design systems roundtable complete."; exit 0; fi

if [[ "$1" == "storybook-patterns" ]]; then
  Q="How do you get the most out of Storybook — component-driven development, visual testing, accessibility, docs?"; AGENTS=(Lucidia Shellfish Aria Octavia Alice); OUT="$SAVE_DIR/storybook-patterns-$(date +%s).txt"
  echo "📖 Storybook Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Storybook patterns roundtable complete."; exit 0; fi

if [[ "$1" == "animation-engineering" ]]; then
  Q="How do you engineer smooth, performant animations — FLIP, CSS transitions, Framer Motion, GSAP?"; AGENTS=(Alice Octavia Shellfish Lucidia Aria); OUT="$SAVE_DIR/animation-engineering-$(date +%s).txt"
  echo "✨ Animation Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Animation engineering roundtable complete."; exit 0; fi

if [[ "$1" == "browser-security" ]]; then
  Q="What are the browser security fundamentals every frontend engineer must know — CSP, CORS, XSS, CSRF, clickjacking?"; AGENTS=(Shellfish Aria Alice Lucidia Octavia); OUT="$SAVE_DIR/browser-security-$(date +%s).txt"
  echo "🔐 Browser Security Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Browser security roundtable complete."; exit 0; fi

if [[ "$1" == "frontend-bundlers" ]]; then
  Q="How do Vite, Turbopack, esbuild, and Rollup differ, and what drives bundler choice in 2025?"; AGENTS=(Octavia Lucidia Aria Shellfish Alice); OUT="$SAVE_DIR/frontend-bundlers-$(date +%s).txt"
  echo "📦 Frontend Bundlers Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Frontend bundlers roundtable complete."; exit 0; fi

if [[ "$1" == "svelte-signals" ]]; then
  Q="How do Svelte 5 runes and the signals-based reactivity model compare to React and Vue?"; AGENTS=(Aria Alice Octavia Lucidia Shellfish); OUT="$SAVE_DIR/svelte-signals-$(date +%s).txt"
  echo "🔥 Svelte Signals Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Svelte signals roundtable complete."; exit 0; fi

if [[ "$1" == "vue-composition" ]]; then
  Q="How does Vue 3's Composition API and reactivity system differ from React hooks in philosophy and practice?"; AGENTS=(Lucidia Shellfish Alice Aria Octavia); OUT="$SAVE_DIR/vue-composition-$(date +%s).txt"
  echo "💚 Vue Composition Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Vue composition roundtable complete."; exit 0; fi

if [[ "$1" == "remix-patterns" ]]; then
  Q="How does Remix's web-fundamentals approach — loaders, actions, nested routes — differ from Next.js?"; AGENTS=(Shellfish Octavia Aria Lucidia Alice); OUT="$SAVE_DIR/remix-patterns-$(date +%s).txt"
  echo "💿 Remix Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Remix patterns roundtable complete."; exit 0; fi

if [[ "$1" == "astro-islands" ]]; then
  Q="How does Astro's islands architecture achieve zero-JS by default while supporting any framework?"; AGENTS=(Alice Lucidia Shellfish Octavia Aria); OUT="$SAVE_DIR/astro-islands-$(date +%s).txt"
  echo "🚀 Astro Islands Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Astro islands roundtable complete."; exit 0; fi

if [[ "$1" == "tanstack-query" ]]; then
  Q="How does TanStack Query change how you think about server state — caching, invalidation, mutations, optimistic updates?"; AGENTS=(Octavia Aria Shellfish Alice Lucidia); OUT="$SAVE_DIR/tanstack-query-$(date +%s).txt"
  echo "🔄 TanStack Query Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ TanStack Query roundtable complete."; exit 0; fi

if [[ "$1" == "web-components" ]]; then
  Q="Are web components finally ready — custom elements, shadow DOM, slots, and interop with frameworks?"; AGENTS=(Lucidia Shellfish Octavia Aria Alice); OUT="$SAVE_DIR/web-components-$(date +%s).txt"
  echo "🔧 Web Components Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Web components roundtable complete."; exit 0; fi

if [[ "$1" == "i18n-l10n" ]]; then
  Q="What does production-grade internationalization look like — ICU messages, plurals, RTL, locale detection, lazy loading?"; AGENTS=(Aria Alice Lucidia Shellfish Octavia); OUT="$SAVE_DIR/i18n-l10n-$(date +%s).txt"
  echo "🌍 i18n/l10n Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ i18n/l10n roundtable complete."; exit 0; fi

if [[ "$1" == "dark-mode-theming" ]]; then
  Q="How do you implement dark mode and dynamic theming properly — CSS custom properties, system preference, persistence?"; AGENTS=(Shellfish Octavia Aria Lucidia Alice); OUT="$SAVE_DIR/dark-mode-theming-$(date +%s).txt"
  echo "🌙 Dark Mode Theming Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Dark mode theming roundtable complete."; exit 0; fi

if [[ "$1" == "form-architecture" ]]; then
  Q="How do you architect complex forms — React Hook Form, Zod, multi-step wizards, validation UX?"; AGENTS=(Alice Lucidia Shellfish Octavia Aria); OUT="$SAVE_DIR/form-architecture-$(date +%s).txt"
  echo "📝 Form Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Form architecture roundtable complete."; exit 0; fi

if [[ "$1" == "ux-engineering" ]]; then
  Q="What does great UX engineering look like — motion design, perceived performance, error states, empty states?"; AGENTS=(Lucidia Aria Octavia Shellfish Alice); OUT="$SAVE_DIR/ux-engineering-$(date +%s).txt"
  echo "✨ UX Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ UX engineering roundtable complete."; exit 0; fi

if [[ "$1" == "ab-testing-eng" ]]; then
  Q="How do you engineer a reliable A/B testing platform — assignment, bucketing, exposure logging, statistical significance?"; AGENTS=(Octavia Shellfish Alice Aria Lucidia); OUT="$SAVE_DIR/ab-testing-eng-$(date +%s).txt"
  echo "🧪 A/B Testing Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ A/B testing eng roundtable complete."; exit 0; fi

if [[ "$1" == "analytics-pipelines" ]]; then
  Q="How do you build reliable analytics pipelines — event tracking, clickstream, funnels, and data quality?"; AGENTS=(Aria Lucidia Octavia Alice Shellfish); OUT="$SAVE_DIR/analytics-pipelines-$(date +%s).txt"
  echo "📊 Analytics Pipelines Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Analytics pipelines roundtable complete."; exit 0; fi

if [[ "$1" == "growth-engineering" ]]; then
  Q="What does growth engineering look like — referral loops, activation experiments, retention hooks, virality mechanics?"; AGENTS=(Shellfish Alice Lucidia Octavia Aria); OUT="$SAVE_DIR/growth-engineering-$(date +%s).txt"
  echo "📈 Growth Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Growth engineering roundtable complete."; exit 0; fi

if [[ "$1" == "notification-systems" ]]; then
  Q="How do you architect a notification system — email, push, SMS, in-app, preferences, and deliverability?"; AGENTS=(Lucidia Octavia Aria Shellfish Alice); OUT="$SAVE_DIR/notification-systems-$(date +%s).txt"
  echo "🔔 Notification Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Notification systems roundtable complete."; exit 0; fi

if [[ "$1" == "search-ux" ]]; then
  Q="How do you design and engineer great search UX — autocomplete, facets, spell correction, personalization?"; AGENTS=(Alice Shellfish Octavia Lucidia Aria); OUT="$SAVE_DIR/search-ux-$(date +%s).txt"
  echo "🔍 Search UX Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Search UX roundtable complete."; exit 0; fi

if [[ "$1" == "realtime-collab" ]]; then
  Q="How do collaborative editing systems like Notion and Figma work — CRDTs, OT, presence, awareness?"; AGENTS=(Octavia Aria Lucidia Shellfish Alice); OUT="$SAVE_DIR/realtime-collab-$(date +%s).txt"
  echo "🤝 Real-Time Collaboration Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Realtime collab roundtable complete."; exit 0; fi

if [[ "$1" == "offline-first" ]]; then
  Q="How do you build offline-first applications — IndexedDB, sync protocols, conflict resolution, CRDTs?"; AGENTS=(Shellfish Alice Octavia Aria Lucidia); OUT="$SAVE_DIR/offline-first-$(date +%s).txt"
  echo "📴 Offline-First Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Offline-first roundtable complete."; exit 0; fi

if [[ "$1" == "payments-eng" ]]; then
  Q="What does payments engineering involve — Stripe integration, PCI compliance, idempotency, reconciliation?"; AGENTS=(Lucidia Aria Shellfish Octavia Alice); OUT="$SAVE_DIR/payments-eng-$(date +%s).txt"
  echo "💳 Payments Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Payments eng roundtable complete."; exit 0; fi

if [[ "$1" == "llm-product-eng" ]]; then
  Q="What are the hard engineering problems of building LLM-powered products — latency, cost, evals, prompt management?"; AGENTS=(Lucidia Octavia Shellfish Alice Aria); OUT="$SAVE_DIR/llm-product-eng-$(date +%s).txt"
  echo "🤖 LLM Product Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ LLM product eng roundtable complete."; exit 0; fi

if [[ "$1" == "ai-ux" ]]; then
  Q="What makes AI UX great — streaming responses, progressive disclosure, trust signals, and failure handling?"; AGENTS=(Aria Alice Lucidia Shellfish Octavia); OUT="$SAVE_DIR/ai-ux-$(date +%s).txt"
  echo "🎨 AI UX Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI UX roundtable complete."; exit 0; fi

if [[ "$1" == "copilot-patterns" ]]; then
  Q="How do you design AI copilot features that are actually helpful vs annoying — context, timing, confidence?"; AGENTS=(Shellfish Lucidia Octavia Aria Alice); OUT="$SAVE_DIR/copilot-patterns-$(date +%s).txt"
  echo "✈️ Copilot Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Copilot patterns roundtable complete."; exit 0; fi

if [[ "$1" == "agentic-workflows" ]]; then
  Q="How do you design agentic workflows that are reliable — planning, tool use, loops, and human-in-the-loop?"; AGENTS=(Octavia Lucidia Alice Aria Shellfish); OUT="$SAVE_DIR/agentic-workflows-$(date +%s).txt"
  echo "🔄 Agentic Workflows Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Agentic workflows roundtable complete."; exit 0; fi

if [[ "$1" == "llm-caching" ]]; then
  Q="How do you cache LLM responses intelligently — semantic caching, prompt hashing, KV cache reuse?"; AGENTS=(Alice Shellfish Aria Octavia Lucidia); OUT="$SAVE_DIR/llm-caching-$(date +%s).txt"
  echo "💾 LLM Caching Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ LLM caching roundtable complete."; exit 0; fi

if [[ "$1" == "llm-routing" ]]; then
  Q="How do you route between LLMs intelligently — cost tiers, capability routing, fallbacks, latency SLAs?"; AGENTS=(Lucidia Aria Octavia Shellfish Alice); OUT="$SAVE_DIR/llm-routing-$(date +%s).txt"
  echo "🔀 LLM Routing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ LLM routing roundtable complete."; exit 0; fi

if [[ "$1" == "structured-outputs" ]]; then
  Q="How do structured outputs — JSON mode, function calling, instructor, Pydantic — make LLMs production-reliable?"; AGENTS=(Octavia Shellfish Alice Lucidia Aria); OUT="$SAVE_DIR/structured-outputs-$(date +%s).txt"
  echo "📋 Structured Outputs Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Structured outputs roundtable complete."; exit 0; fi

if [[ "$1" == "ai-cost-optimization" ]]; then
  Q="How do you optimize AI inference costs — smaller models, batching, caching, spot instances, prompt compression?"; AGENTS=(Shellfish Alice Lucidia Octavia Aria); OUT="$SAVE_DIR/ai-cost-optimization-$(date +%s).txt"
  echo "💰 AI Cost Optimization Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI cost optimization roundtable complete."; exit 0; fi

if [[ "$1" == "guardrails-ai" ]]; then
  Q="How do you implement AI guardrails — input/output validation, content moderation, hallucination detection?"; AGENTS=(Aria Lucidia Shellfish Alice Octavia); OUT="$SAVE_DIR/guardrails-ai-$(date +%s).txt"
  echo "🛡️ AI Guardrails Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI guardrails roundtable complete."; exit 0; fi

if [[ "$1" == "ai-testing" ]]; then
  Q="How do you test AI-powered systems — determinism, evals, golden datasets, regression suites?"; AGENTS=(Lucidia Octavia Aria Shellfish Alice); OUT="$SAVE_DIR/ai-testing-$(date +%s).txt"
  echo "🧪 AI Testing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI testing roundtable complete."; exit 0; fi

if [[ "$1" == "embedding-search" ]]; then
  Q="How do you build high-quality embedding-based search — model choice, chunking, indexing, reranking?"; AGENTS=(Alice Shellfish Octavia Aria Lucidia); OUT="$SAVE_DIR/embedding-search-$(date +%s).txt"
  echo "🔍 Embedding Search Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Embedding search roundtable complete."; exit 0; fi

if [[ "$1" == "langchain-patterns" ]]; then
  Q="When does LangChain/LangGraph help vs hurt — chains, graphs, memory, and when to go lower level?"; AGENTS=(Shellfish Lucidia Alice Octavia Aria); OUT="$SAVE_DIR/langchain-patterns-$(date +%s).txt"
  echo "🔗 LangChain Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ LangChain patterns roundtable complete."; exit 0; fi

if [[ "$1" == "on-device-ai" ]]; then
  Q="What is the state of on-device AI — Apple Neural Engine, Qualcomm NPU, ONNX, llama.cpp on mobile?"; AGENTS=(Octavia Aria Lucidia Shellfish Alice); OUT="$SAVE_DIR/on-device-ai-$(date +%s).txt"
  echo "📱 On-Device AI Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ On-device AI roundtable complete."; exit 0; fi

if [[ "$1" == "ai-infrastructure" ]]; then
  Q="What does a modern AI infrastructure stack look like — serving, orchestration, experiment tracking, feature stores?"; AGENTS=(Lucidia Alice Shellfish Aria Octavia); OUT="$SAVE_DIR/ai-infrastructure-$(date +%s).txt"
  echo "🏗️ AI Infrastructure Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ AI infrastructure roundtable complete."; exit 0; fi

if [[ "$1" == "synthetic-data" ]]; then
  Q="How do you generate and validate synthetic data for training and testing AI systems?"; AGENTS=(Aria Octavia Lucidia Alice Shellfish); OUT="$SAVE_DIR/synthetic-data-$(date +%s).txt"
  echo "🧬 Synthetic Data Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Synthetic data roundtable complete."; exit 0; fi

if [[ "$1" == "eng-strategy" ]]; then
  Q="How do senior engineers develop and communicate technical strategy that aligns with business goals?"; AGENTS=(Shellfish Lucidia Octavia Aria Alice); OUT="$SAVE_DIR/eng-strategy-$(date +%s).txt"
  echo "♟️ Engineering Strategy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eng strategy roundtable complete."; exit 0; fi

if [[ "$1" == "build-vs-buy" ]]; then
  Q="How do you make rigorous build vs buy decisions — TCO, opportunity cost, vendor lock-in, team skill?"; AGENTS=(Lucidia Alice Aria Shellfish Octavia); OUT="$SAVE_DIR/build-vs-buy-$(date +%s).txt"
  echo "⚖️ Build vs Buy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Build vs buy roundtable complete."; exit 0; fi

if [[ "$1" == "rewrite-vs-refactor" ]]; then
  Q="When is a full rewrite justified vs incremental refactoring — signals, risks, and how to pitch it?"; AGENTS=(Octavia Aria Shellfish Lucidia Alice); OUT="$SAVE_DIR/rewrite-vs-refactor-$(date +%s).txt"
  echo "🔄 Rewrite vs Refactor Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Rewrite vs refactor roundtable complete."; exit 0; fi

if [[ "$1" == "startup-eng" ]]; then
  Q="What engineering practices matter most at a startup — speed, reversibility, MVP decisions, and avoiding premature scaling?"; AGENTS=(Alice Shellfish Lucidia Octavia Aria); OUT="$SAVE_DIR/startup-eng-$(date +%s).txt"
  echo "🚀 Startup Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Startup eng roundtable complete."; exit 0; fi

if [[ "$1" == "enterprise-eng" ]]; then
  Q="What changes when you go from startup to enterprise engineering — compliance, process, politics, scale?"; AGENTS=(Lucidia Octavia Aria Alice Shellfish); OUT="$SAVE_DIR/enterprise-eng-$(date +%s).txt"
  echo "🏢 Enterprise Engineering Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Enterprise eng roundtable complete."; exit 0; fi

if [[ "$1" == "oss-strategy" ]]; then
  Q="How do companies use open source strategically — commoditizing complements, community, dual licensing?"; AGENTS=(Aria Shellfish Lucidia Alice Octavia); OUT="$SAVE_DIR/oss-strategy-$(date +%s).txt"
  echo "🌐 OSS Strategy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ OSS strategy roundtable complete."; exit 0; fi

if [[ "$1" == "api-economy" ]]; then
  Q="How do you build a thriving API economy — developer portals, SDKs, webhooks, usage analytics?"; AGENTS=(Shellfish Alice Octavia Lucidia Aria); OUT="$SAVE_DIR/api-economy-$(date +%s).txt"
  echo "🌐 API Economy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ API economy roundtable complete."; exit 0; fi

if [[ "$1" == "platform-moats" ]]; then
  Q="What creates durable technical moats — network effects, data flywheels, switching costs, integrations?"; AGENTS=(Lucidia Aria Alice Shellfish Octavia); OUT="$SAVE_DIR/platform-moats-$(date +%s).txt"
  echo "🏰 Platform Moats Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Platform moats roundtable complete."; exit 0; fi

if [[ "$1" == "eng-brand" ]]; then
  Q="How do companies like Stripe, Cloudflare, and Vercel build an engineering brand that attracts top talent?"; AGENTS=(Octavia Lucidia Shellfish Aria Alice); OUT="$SAVE_DIR/eng-brand-$(date +%s).txt"
  echo "⭐ Engineering Brand Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Eng brand roundtable complete."; exit 0; fi

if [[ "$1" == "technical-interviews" ]]; then
  Q="How do you design technical interviews that actually predict job performance — coding, system design, values?"; AGENTS=(Alice Aria Lucidia Octavia Shellfish); OUT="$SAVE_DIR/technical-interviews-$(date +%s).txt"
  echo "🎯 Technical Interviews Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Technical interviews roundtable complete."; exit 0; fi

if [[ "$1" == "quantum-computing" ]]; then
  Q="How will quantum computing change cryptography, optimization, and simulation — what should engineers know now?"; AGENTS=(Octavia Shellfish Lucidia Alice Aria); OUT="$SAVE_DIR/quantum-computing-$(date +%s).txt"
  echo "⚛️ Quantum Computing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Quantum computing roundtable complete."; exit 0; fi

if [[ "$1" == "neuromorphic" ]]; then
  Q="What are neuromorphic chips, how do they differ from GPUs, and when will they matter for AI workloads?"; AGENTS=(Lucidia Octavia Alice Shellfish Aria); OUT="$SAVE_DIR/neuromorphic-$(date +%s).txt"
  echo "🧠 Neuromorphic Computing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Neuromorphic roundtable complete."; exit 0; fi

if [[ "$1" == "photonic-computing" ]]; then
  Q="How does photonic computing use light instead of electrons — what are the engineering tradeoffs and timelines?"; AGENTS=(Aria Octavia Lucidia Shellfish Alice); OUT="$SAVE_DIR/photonic-computing-$(date +%s).txt"
  echo "💡 Photonic Computing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Photonic computing roundtable complete."; exit 0; fi

if [[ "$1" == "dna-storage" ]]; then
  Q="DNA as data storage — what's the current state, read/write speeds, and real-world engineering challenges?"; AGENTS=(Shellfish Lucidia Octavia Aria Alice); OUT="$SAVE_DIR/dna-storage-$(date +%s).txt"
  echo "🧬 DNA Storage Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ DNA storage roundtable complete."; exit 0; fi

if [[ "$1" == "homomorphic-encryption" ]]; then
  Q="How does homomorphic encryption enable computation on encrypted data — current libraries, performance, and use cases?"; AGENTS=(Alice Shellfish Octavia Lucidia Aria); OUT="$SAVE_DIR/homomorphic-encryption-$(date +%s).txt"
  echo "🔐 Homomorphic Encryption Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Homomorphic encryption roundtable complete."; exit 0; fi

if [[ "$1" == "zero-knowledge-proofs" ]]; then
  Q="ZK-proofs beyond blockchain — how can they enable privacy-preserving authentication, ML, and data verification?"; AGENTS=(Octavia Alice Shellfish Aria Lucidia); OUT="$SAVE_DIR/zero-knowledge-proofs-$(date +%s).txt"
  echo "🔮 Zero-Knowledge Proofs Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Zero-knowledge proofs roundtable complete."; exit 0; fi

if [[ "$1" == "post-quantum-crypto" ]]; then
  Q="What are NIST post-quantum cryptography standards, and how do teams migrate existing systems to quantum-safe algorithms?"; AGENTS=(Lucidia Shellfish Alice Octavia Aria); OUT="$SAVE_DIR/post-quantum-crypto-$(date +%s).txt"
  echo "🛡️ Post-Quantum Crypto Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Post-quantum crypto roundtable complete."; exit 0; fi

if [[ "$1" == "differential-privacy-adv" ]]; then
  Q="Advanced differential privacy — epsilon budgets, local vs central DP, and implementing DP-SGD for ML training?"; AGENTS=(Aria Lucidia Shellfish Alice Octavia); OUT="$SAVE_DIR/differential-privacy-adv-$(date +%s).txt"
  echo "📊 Differential Privacy Advanced Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Differential privacy advanced roundtable complete."; exit 0; fi

if [[ "$1" == "secure-multi-party" ]]; then
  Q="Secure multi-party computation — protocols, practical implementations, and when to use MPC vs other privacy tech?"; AGENTS=(Shellfish Octavia Aria Lucidia Alice); OUT="$SAVE_DIR/secure-multi-party-$(date +%s).txt"
  echo "🤝 Secure Multi-Party Computation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Secure multi-party roundtable complete."; exit 0; fi

if [[ "$1" == "confidential-computing" ]]; then
  Q="TEEs, Intel SGX, AMD SEV — how does confidential computing protect data in use and what are the engineering tradeoffs?"; AGENTS=(Alice Aria Shellfish Octavia Lucidia); OUT="$SAVE_DIR/confidential-computing-$(date +%s).txt"
  echo "🔒 Confidential Computing Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Confidential computing roundtable complete."; exit 0; fi

if [[ "$1" == "gaming-backend" ]]; then
  Q="How do you architect a scalable gaming backend — state synchronization, lag compensation, and tick-rate optimization?"; AGENTS=(Octavia Alice Lucidia Aria Shellfish); OUT="$SAVE_DIR/gaming-backend-$(date +%s).txt"
  echo "🎮 Gaming Backend Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Gaming backend roundtable complete."; exit 0; fi

if [[ "$1" == "matchmaking-systems" ]]; then
  Q="Designing fair matchmaking — ELO, TrueSkill, skill gap vs wait time, and cheater detection signals?"; AGENTS=(Lucidia Octavia Shellfish Aria Alice); OUT="$SAVE_DIR/matchmaking-systems-$(date +%s).txt"
  echo "⚔️ Matchmaking Systems Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Matchmaking systems roundtable complete."; exit 0; fi

if [[ "$1" == "game-economy" ]]; then
  Q="Virtual economy design — inflation prevention, sink/faucet balance, player-driven markets, and monetization ethics?"; AGENTS=(Aria Alice Lucidia Octavia Shellfish); OUT="$SAVE_DIR/game-economy-$(date +%s).txt"
  echo "💰 Game Economy Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Game economy roundtable complete."; exit 0; fi

if [[ "$1" == "live-ops" ]]; then
  Q="Live operations for games — seasonal events, hotfixes, content cadence, and keeping players engaged post-launch?"; AGENTS=(Shellfish Aria Octavia Alice Lucidia); OUT="$SAVE_DIR/live-ops-$(date +%s).txt"
  echo "🎯 Live Ops Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Live ops roundtable complete."; exit 0; fi

if [[ "$1" == "anti-cheat" ]]; then
  Q="Anti-cheat engineering — kernel-level detection, server-side validation, behavioral analysis, and arms race dynamics?"; AGENTS=(Alice Shellfish Lucidia Octavia Aria); OUT="$SAVE_DIR/anti-cheat-$(date +%s).txt"
  echo "🚫 Anti-Cheat Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Anti-cheat roundtable complete."; exit 0; fi

if [[ "$1" == "leaderboards" ]]; then
  Q="Designing massive global leaderboards at scale — Redis sorted sets, eventual consistency, and near-realtime ranking?"; AGENTS=(Octavia Lucidia Aria Shellfish Alice); OUT="$SAVE_DIR/leaderboards-$(date +%s).txt"
  echo "🏆 Leaderboards Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Leaderboards roundtable complete."; exit 0; fi

if [[ "$1" == "session-servers" ]]; then
  Q="Dedicated game session servers — allocation, region selection, auto-scaling, and graceful shutdown strategies?"; AGENTS=(Lucidia Alice Shellfish Octavia Aria); OUT="$SAVE_DIR/session-servers-$(date +%s).txt"
  echo "🖥️ Session Servers Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Session servers roundtable complete."; exit 0; fi

if [[ "$1" == "game-analytics" ]]; then
  Q="Game analytics pipelines — funnel analysis, cohort retention, churn prediction, and A/B testing game mechanics?"; AGENTS=(Aria Octavia Alice Lucidia Shellfish); OUT="$SAVE_DIR/game-analytics-$(date +%s).txt"
  echo "📈 Game Analytics Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Game analytics roundtable complete."; exit 0; fi

if [[ "$1" == "physics-simulation" ]]; then
  Q="Real-time physics simulation — deterministic vs predictive, client-side prediction, rollback netcode patterns?"; AGENTS=(Shellfish Lucidia Octavia Aria Alice); OUT="$SAVE_DIR/physics-simulation-$(date +%s).txt"
  echo "⚡ Physics Simulation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Physics simulation roundtable complete."; exit 0; fi

if [[ "$1" == "procedural-generation" ]]; then
  Q="Procedural content generation — noise functions, WFC, grammar-based systems, and ensuring fun through randomness?"; AGENTS=(Alice Aria Lucidia Shellfish Octavia); OUT="$SAVE_DIR/procedural-generation-$(date +%s).txt"
  echo "🌍 Procedural Generation Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Procedural generation roundtable complete."; exit 0; fi

if [[ "$1" == "iot-architecture" ]]; then
  Q="IoT system architecture at scale — device provisioning, protocol selection (MQTT vs CoAP), and cloud integration patterns?"; AGENTS=(Octavia Shellfish Alice Lucidia Aria); OUT="$SAVE_DIR/iot-architecture-$(date +%s).txt"
  echo "📡 IoT Architecture Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ IoT architecture roundtable complete."; exit 0; fi

if [[ "$1" == "edge-ml" ]]; then
  Q="Running ML at the edge — ONNX, TensorFlow Lite, model quantization for constrained hardware, and update strategies?"; AGENTS=(Lucidia Alice Octavia Shellfish Aria); OUT="$SAVE_DIR/edge-ml-$(date +%s).txt"
  echo "🔮 Edge ML Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Edge ML roundtable complete."; exit 0; fi

if [[ "$1" == "tinyml" ]]; then
  Q="TinyML on microcontrollers — MCU selection, model footprint, power budgets, and deploying inference on ARM Cortex-M?"; AGENTS=(Aria Octavia Shellfish Lucidia Alice); OUT="$SAVE_DIR/tinyml-$(date +%s).txt"
  echo "🔬 TinyML Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ TinyML roundtable complete."; exit 0; fi

if [[ "$1" == "mqtt-patterns" ]]; then
  Q="MQTT patterns for IoT — QoS levels, retained messages, last will, topic design, and MQTT 5 improvements?"; AGENTS=(Shellfish Alice Lucidia Aria Octavia); OUT="$SAVE_DIR/mqtt-patterns-$(date +%s).txt"
  echo "📨 MQTT Patterns Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ MQTT patterns roundtable complete."; exit 0; fi

if [[ "$1" == "device-shadow" ]]; then
  Q="Device shadow/digital twin patterns — desired vs reported state, sync strategies, and handling offline devices?"; AGENTS=(Alice Octavia Aria Shellfish Lucidia); OUT="$SAVE_DIR/device-shadow-$(date +%s).txt"
  echo "🪞 Device Shadow Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Device shadow roundtable complete."; exit 0; fi

if [[ "$1" == "ota-updates" ]]; then
  Q="OTA firmware updates at scale — A/B partitions, rollback mechanisms, delta updates, and safe deployment pipelines?"; AGENTS=(Octavia Lucidia Shellfish Alice Aria); OUT="$SAVE_DIR/ota-updates-$(date +%s).txt"
  echo "⬆️ OTA Updates Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ OTA updates roundtable complete."; exit 0; fi

if [[ "$1" == "fleet-management" ]]; then
  Q="Managing a fleet of IoT devices — grouping, remote configuration, anomaly detection, and certificate rotation?"; AGENTS=(Lucidia Shellfish Aria Octavia Alice); OUT="$SAVE_DIR/fleet-management-$(date +%s).txt"
  echo "🚗 Fleet Management Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Fleet management roundtable complete."; exit 0; fi

if [[ "$1" == "digital-twin" ]]; then
  Q="Digital twin engineering — modeling physical systems, real-time data sync, simulation vs live state, and industrial use cases?"; AGENTS=(Aria Alice Octavia Shellfish Lucidia); OUT="$SAVE_DIR/digital-twin-$(date +%s).txt"
  echo "🔮 Digital Twin Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Digital twin roundtable complete."; exit 0; fi

if [[ "$1" == "sensor-fusion" ]]; then
  Q="Sensor fusion algorithms — Kalman filters, complementary filters, IMU + GPS fusion, and real-time state estimation?"; AGENTS=(Shellfish Octavia Lucidia Aria Alice); OUT="$SAVE_DIR/sensor-fusion-$(date +%s).txt"
  echo "🎯 Sensor Fusion Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Sensor fusion roundtable complete."; exit 0; fi

if [[ "$1" == "industrial-iot" ]]; then
  Q="Industrial IoT — OPC-UA, Modbus, real-time constraints, safety-critical systems, and IT/OT convergence challenges?"; AGENTS=(Alice Lucidia Shellfish Octavia Aria); OUT="$SAVE_DIR/industrial-iot-$(date +%s).txt"
  echo "🏭 Industrial IoT Roundtable"; echo "$Q" | tee "$OUT"; for AGENT in "${AGENTS[@]}"; do
    REPLY=$(echo "$Q — respond as $AGENT" | ollama run llama3.2 2>/dev/null | head -8); echo "[$AGENT] $REPLY"; echo "[$AGENT]" >> "$OUT"; echo "$REPLY" >> "$OUT"; done
  echo "✅ Industrial IoT roundtable complete."; exit 0; fi

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
