#!/bin/zsh
# BR Worlds Watch — Live terminal feed for world generation
# Usage: br worlds watch [--interval N] [--reset]

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

PI_ARIA="alexa@192.168.4.38"
PI_ALICE="blackroad@192.168.4.49"
ARIA_WORLDS="/home/alexa/blackroad-repos/blackroad-agents/worlds"
ALICE_WORLDS="/home/blackroad/.blackroad/worlds"

SEEN_FILE="/tmp/br-worlds-seen.txt"
POLL_INTERVAL=5

# ── Parse arguments ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval|-i) POLL_INTERVAL="${2:-5}"; shift 2 ;;
    --reset|-r)    rm -f "$SEEN_FILE"; shift ;;
    --seen)        SEEN_FILE="${2}"; shift 2 ;;
    *) shift ;;
  esac
done

# ── State ─────────────────────────────────────────────────────────────────
ARIA_COUNT=0
ALICE_COUNT=0
TOTAL_SEEN=0
START_TIME=$(date +%s)

# ── Helpers ────────────────────────────────────────────────────────────────

world_emoji() {
  local name="$1"
  case "$name" in
    *lore*)  echo "📜" ;;
    *world*) echo "🌍" ;;
    *code*)  echo "💻" ;;
    *story*) echo "✨" ;;
    *tech*)  echo "🔧" ;;
    *)       echo "🌐" ;;
  esac
}

cleanup() {
  echo ""
  echo "${DIM}  Stopped. Tracked ${TOTAL_SEEN} new worlds this session.${NC}"
  tput cnorm 2>/dev/null
  exit 0
}
trap cleanup INT TERM

touch "$SEEN_FILE" 2>/dev/null || SEEN_FILE="/tmp/br-worlds-seen-$$.txt" && touch "$SEEN_FILE"

# Fetch world basenames from a node. Prints __FAIL__ on SSH error.
fetch_worlds() {
  local user_host="$1"
  local dir="$2"
  local out
  out=$(ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no \
    "$user_host" \
    "ls '${dir}'/*.md 2>/dev/null | xargs -I{} basename {}" 2>/dev/null)
  if [[ $? -ne 0 || -z "$out" ]]; then
    echo "__FAIL__"
  else
    echo "$out"
  fi
}

print_header() {
  local aria_disp="$ARIA_COUNT"
  local alice_disp="$ALICE_COUNT"
  [[ $ARIA_COUNT -lt 0 ]]  && aria_disp="?"
  [[ $ALICE_COUNT -lt 0 ]] && alice_disp="?"
  local total=$(( (ARIA_COUNT > 0 ? ARIA_COUNT : 0) + (ALICE_COUNT > 0 ? ALICE_COUNT : 0) ))
  printf "${CYAN}${BOLD}🌍 WORLDS LIVE FEED — ${YELLOW}aria64${CYAN}:${aria_disp}  ${YELLOW}alice${CYAN}:${alice_disp}  ${CYAN}total:${GREEN}${total}${NC}          \n"
}

print_footer() {
  local elapsed=$(( $(date +%s) - START_TIME ))
  local rate="~2/min"
  if [[ $elapsed -gt 30 && $TOTAL_SEEN -gt 0 ]]; then
    local per_min=$(( TOTAL_SEEN * 60 / elapsed ))
    rate="${per_min}/min"
  fi
  printf "${DIM}  Generating ${rate} | Poll every ${POLL_INTERVAL}s | Ctrl-C to stop | ${TOTAL_SEEN} new worlds seen${NC}                    "
}

# ── Seed: mark all current worlds as already-seen ─────────────────────────
seed_seen() {
  printf "${DIM}  Seeding seen-worlds list from aria64...${NC}"
  local aria_out
  aria_out=$(fetch_worlds "$PI_ARIA" "$ARIA_WORLDS")
  if [[ "$aria_out" != "__FAIL__" ]]; then
    while IFS= read -r w; do
      [[ -n "$w" ]] && echo "aria64:$w"
    done <<< "$aria_out" >> "$SEEN_FILE"
    ARIA_COUNT=$(grep -c '\.md' <<< "$aria_out" 2>/dev/null || echo 0)
    printf "\r${DIM}  Seeded aria64 (${ARIA_COUNT} worlds)${NC}             \n"
  else
    ARIA_COUNT=-1
    printf "\r${YELLOW}  aria64 unreachable — will retry${NC}             \n"
  fi

  printf "${DIM}  Seeding seen-worlds list from alice...${NC}"
  local alice_out
  alice_out=$(fetch_worlds "$PI_ALICE" "$ALICE_WORLDS")
  if [[ "$alice_out" != "__FAIL__" ]]; then
    while IFS= read -r w; do
      [[ -n "$w" ]] && echo "alice:$w"
    done <<< "$alice_out" >> "$SEEN_FILE"
    ALICE_COUNT=$(grep -c '\.md' <<< "$alice_out" 2>/dev/null || echo 0)
    printf "\r${DIM}  Seeded alice (${ALICE_COUNT} worlds)${NC}              \n"
  else
    ALICE_COUNT=-1
    printf "\r${YELLOW}  alice unreachable — will retry${NC}              \n"
  fi

  sort -u "$SEEN_FILE" -o "$SEEN_FILE" 2>/dev/null
}

# Poll one node; print new-world lines to stdout
# Prints: NEW:<node>:<file>  or  COUNT:<node>:<n>  or  FAIL:<node>
poll_node() {
  local node="$1"
  local user_host="$2"
  local dir="$3"

  local out
  out=$(fetch_worlds "$user_host" "$dir")
  if [[ "$out" == "__FAIL__" ]]; then
    echo "FAIL:${node}"
    return
  fi

  local n=0
  while IFS= read -r w; do
    [[ -z "$w" ]] && continue
    (( n++ ))
    local key="${node}:${w}"
    if ! grep -qF "$key" "$SEEN_FILE" 2>/dev/null; then
      echo "NEW:${node}:${w}"
      echo "$key" >> "$SEEN_FILE"
    fi
  done <<< "$out"
  echo "COUNT:${node}:${n}"
}

# ── Banner ─────────────────────────────────────────────────────────────────
tput civis 2>/dev/null
clear

printf "${CYAN}${BOLD}"
printf "  ██╗    ██╗ ██████╗ ██████╗ ██╗     ██████╗ ███████╗\n"
printf "  ██║    ██║██╔═══██╗██╔══██╗██║     ██╔══██╗██╔════╝\n"
printf "  ██║ █╗ ██║██║   ██║██████╔╝██║     ██║  ██║███████╗\n"
printf "  ██║███╗██║██║   ██║██╔══██╗██║     ██║  ██║╚════██║\n"
printf "  ╚███╔███╔╝╚██████╔╝██║  ██║███████╗██████╔╝███████║\n"
printf "   ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝\n"
printf "${NC}${DIM}  Live Feed — polling aria64 + alice every ${POLL_INTERVAL}s\n\n${NC}"

seed_seen
echo ""
print_header
printf "${DIM}──────────────────────────────────────────────────────────────────${NC}\n"
printf "${DIM}  TIMESTAMP    NODE        TYPE  WORLD${NC}\n"
printf "${DIM}──────────────────────────────────────────────────────────────────${NC}\n"

# Initial footer
print_footer
printf "\n"

# ── Poll loop ──────────────────────────────────────────────────────────────
while true; do
  sleep "$POLL_INTERVAL"

  local aria_results
  aria_results=$(poll_node "aria64" "$PI_ARIA" "$ARIA_WORLDS")
  local alice_results
  alice_results=$(poll_node "alice" "$PI_ALICE" "$ALICE_WORLDS")

  # Move cursor up 1 to overwrite the footer line
  printf "\033[1A\r"

  # Process aria64 results (process substitution keeps loop in current shell)
  while IFS= read -r line; do
    case "$line" in
      NEW:aria64:*)
        local wf="${line#NEW:aria64:}"
        local wb="${wf%.md}"
        local emoji
        emoji=$(world_emoji "$wb")
        local ts
        ts=$(date '+%H:%M:%S')
        printf "  ${DIM}%s${NC}  ${YELLOW}%-10s${NC}  %s  ${GREEN}%s${NC}\n" \
          "$ts" "aria64" "$emoji" "$wb"
        (( TOTAL_SEEN++ ))
        ;;
      COUNT:aria64:*)
        ARIA_COUNT="${line#COUNT:aria64:}"
        ;;
      FAIL:aria64)
        ARIA_COUNT=-1
        ;;
    esac
  done < <(echo "$aria_results")

  # Process alice results
  while IFS= read -r line; do
    case "$line" in
      NEW:alice:*)
        local wf="${line#NEW:alice:}"
        local wb="${wf%.md}"
        local emoji
        emoji=$(world_emoji "$wb")
        local ts
        ts=$(date '+%H:%M:%S')
        printf "  ${DIM}%s${NC}  ${BLUE}%-10s${NC}  %s  ${GREEN}%s${NC}\n" \
          "$ts" "alice" "$emoji" "$wb"
        (( TOTAL_SEEN++ ))
        ;;
      COUNT:alice:*)
        ALICE_COUNT="${line#COUNT:alice:}"
        ;;
      FAIL:alice)
        ALICE_COUNT=-1
        ;;
    esac
  done < <(echo "$alice_results")

  # Reprint footer
  print_footer
  printf "\n"
done
