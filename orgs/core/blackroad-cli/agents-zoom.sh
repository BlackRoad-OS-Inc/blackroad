#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUS="$HOME/blackroad-cli/agent.bus"
ROUNDS=1
MODE="chain"
PREFIX=""
LIMIT=""
USE_MIC=false
SEED=""
SEED_FILE=""
TOPICS_FILE=""
AGENDA=""
ROOM_NAME=""
INTRO=false
ROLLCALL=false
SUMMARY=false
SUMMARY_FINAL=false
SUMMARY_FILE=""
MINUTES=false
MINUTES_FILE=""
STATS=false
STATS_FILE=""
SCRIBE=""
MODERATOR=""
TRANSCRIPT_PATH=""
ROSTER_ONLY=false
ROSTER_FILE=""
ROLES_FILE=""
ROLE_DEFAULT="${BR_AGENT_ROLE_DEFAULT:-}"
ROLE_MAP_TEXT=""
MUTE_PATTERNS=""
MUTED_MODELS=""
PIN_PATTERNS=""
PINNED_MODELS=""
SPOTLIGHT_PATTERN=""
QUEUE_PATTERNS=""
QUEUE_MODELS=""
REMOVE_PATTERNS=""
ROUND_ROBIN=false
SPEAKER_OFFSET=0
ALL_MODELS_TEXT=""
EXCLUDE=""
SHUFFLE=false
PARALLEL=false
CONTEXT_LINES=0
SPEAKER_COUNT=0
SPEAKER_DELAY="0"
ROUND_DELAY="0"
TOPIC_DELAY="0"
MUTE_VOICE=false
MAX_CHARS="${BR_AGENT_MAX_CHARS:-320}"
SUMMARY_MAX_CHARS="${BR_AGENT_SUMMARY_MAX_CHARS:-4000}"
WHISPER_BIN="${WHISPER_BIN:-$HOME/whisper.cpp/build/bin/whisper-cli}"
WHISPER_MODEL="${WHISPER_MODEL:-$HOME/whisper.cpp/models/ggml-base.en.bin}"
WAV_PATH="${BR_AGENT_WAV_PATH:-/tmp/br-agent-room.wav}"
PROMPT_PATH="${BR_AGENT_PROMPT_PATH:-/tmp/br-agent-room.txt}"
ORCH_PID=""
MODELS=()
SUMMARY_CONTEXT=""
CONTEXT_BUFFER=""
SUMMARY_RUNNING="false"
SPEAK_STATS=""

usage() {
  cat <<'EOF'
Usage: agents-zoom.sh [options]

Options:
  -s, --seed <text>     Seed prompt for the room
      --seed-file <p>   Seed prompt from a file
      --topics-file <p> Run multiple prompts from a file (one per line)
  -r, --rounds <n>      Rounds of agent-to-agent replies per prompt (default: 1)
  -m, --mode <mode>     Response mode: chain or broadcast (default: chain)
  -a, --agenda <text>   Agenda or framing added to prompts
      --room <name>     Room name for announcements
  -p, --prefix <text>   Only include models with this prefix
  -l, --limit <n>       Limit number of models
      --exclude <pat>   Exclude models matching regex
      --remove <pat>    Remove models matching regex from roster
      --mute <pat>      Mute models matching regex
      --pin <pat>       Pin models matching regex
      --queue <pat>     Queue models matching regex
      --spotlight <pat> Spotlight one or more models (mutes others)
      --shuffle         Shuffle speaker order each round
      --parallel        Run broadcast replies in parallel
      --round-robin     Rotate non-pinned speakers each round
      --roles-file <p>  Assign per-model roles from a file (model=role)
      --role-default <t> Default role for all models
      --speaker-count <n> Limit active speakers per round
      --speaker-delay <s> Pause between speakers (seconds)
      --round-delay <s>  Pause between rounds (seconds)
      --topic-delay <s>  Pause between topics (seconds)
      --roster-file <p>  Use a roster file for participants
  --intro            Announce room details before starting
  --rollcall         Ask each agent to say hello before the rounds
  --summary          Moderator summarizes at the end
  --summary-final    Add one final summary at the end
  --summary-file <p> Write summaries to a file
  --minutes          Generate meeting minutes at the end
  --minutes-file <p> Write minutes to a file
  --stats            Print speaker stats at the end
  --stats-file <p>   Write speaker stats to a file
  --scribe <m>       Model to use for minutes (default: moderator)
  --moderator <m>    Moderator model (default: first model)
  --transcript <p>   Write transcript to file
  --roster           Print roster and exit
  --max-chars <n>    Max characters per response (default: 320)
  --context-lines <n> Include last N lines of context in prompts
  --mute-voice       Disable TTS output
      --mic             Use microphone input via whisper.cpp
  -h, --help            Show help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--seed)
      SEED="${2:-}"
      shift
      ;;
    --seed-file)
      SEED_FILE="${2:-}"
      shift
      ;;
    --topics-file)
      TOPICS_FILE="${2:-}"
      shift
      ;;
    -r|--rounds)
      ROUNDS="${2:-}"
      shift
      ;;
    -m|--mode)
      MODE="${2:-}"
      shift
      ;;
    -a|--agenda)
      AGENDA="${2:-}"
      shift
      ;;
    --room)
      ROOM_NAME="${2:-}"
      shift
      ;;
    -p|--prefix)
      PREFIX="${2:-}"
      shift
      ;;
    -l|--limit)
      LIMIT="${2:-}"
      shift
      ;;
    --exclude)
      EXCLUDE="${2:-}"
      shift
      ;;
    --remove)
      REMOVE_PATTERNS="${REMOVE_PATTERNS}${2:-}"$'\n'
      shift
      ;;
    --mute)
      MUTE_PATTERNS="${MUTE_PATTERNS}${2:-}"$'\n'
      shift
      ;;
    --pin)
      PIN_PATTERNS="${PIN_PATTERNS}${2:-}"$'\n'
      shift
      ;;
    --queue)
      QUEUE_PATTERNS="${QUEUE_PATTERNS}${2:-}"$'\n'
      shift
      ;;
    --spotlight)
      SPOTLIGHT_PATTERN="${2:-}"
      shift
      ;;
    --shuffle)
      SHUFFLE=true
      ;;
    --parallel)
      PARALLEL=true
      ;;
    --round-robin)
      ROUND_ROBIN=true
      ;;
    --roles-file)
      ROLES_FILE="${2:-}"
      shift
      ;;
    --role-default)
      ROLE_DEFAULT="${2:-}"
      shift
      ;;
    --speaker-count)
      SPEAKER_COUNT="${2:-}"
      shift
      ;;
    --speaker-delay)
      SPEAKER_DELAY="${2:-}"
      shift
      ;;
    --round-delay)
      ROUND_DELAY="${2:-}"
      shift
      ;;
    --topic-delay)
      TOPIC_DELAY="${2:-}"
      shift
      ;;
    --roster-file)
      ROSTER_FILE="${2:-}"
      shift
      ;;
    --intro)
      INTRO=true
      ;;
    --rollcall)
      ROLLCALL=true
      ;;
    --summary)
      SUMMARY=true
      ;;
    --summary-final)
      SUMMARY_FINAL=true
      ;;
    --summary-file)
      SUMMARY_FILE="${2:-}"
      shift
      ;;
    --minutes)
      MINUTES=true
      ;;
    --minutes-file)
      MINUTES_FILE="${2:-}"
      shift
      ;;
    --stats)
      STATS=true
      ;;
    --stats-file)
      STATS_FILE="${2:-}"
      shift
      ;;
    --scribe)
      SCRIBE="${2:-}"
      shift
      ;;
    --moderator)
      MODERATOR="${2:-}"
      shift
      ;;
    --transcript)
      TRANSCRIPT_PATH="${2:-}"
      shift
      ;;
    --roster)
      ROSTER_ONLY=true
      ;;
    --max-chars)
      MAX_CHARS="${2:-}"
      shift
      ;;
    --context-lines)
      CONTEXT_LINES="${2:-}"
      shift
      ;;
    --mute-voice|--no-voice)
      MUTE_VOICE=true
      ;;
    --mic)
      USE_MIC=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

case "$ROUNDS" in
  ''|*[!0-9]*)
    echo "Rounds must be a positive integer"
    exit 1
    ;;
esac

case "$MODE" in
  chain|broadcast)
    ;;
  *)
    echo "Mode must be chain or broadcast"
    exit 1
    ;;
esac

if [ -n "$LIMIT" ]; then
  case "$LIMIT" in
    ''|*[!0-9]*)
      echo "Limit must be a positive integer"
      exit 1
      ;;
  esac
fi

case "$SPEAKER_COUNT" in
  ''|*[!0-9]*)
    echo "Speaker count must be a non-negative integer"
    exit 1
    ;;
esac

if ! [[ "$SPEAKER_DELAY" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Speaker delay must be a number"
  exit 1
fi

if ! [[ "$ROUND_DELAY" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Round delay must be a number"
  exit 1
fi

if ! [[ "$TOPIC_DELAY" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Topic delay must be a number"
  exit 1
fi

case "$MAX_CHARS" in
  ''|*[!0-9]*)
    echo "Max chars must be a positive integer"
    exit 1
    ;;
esac

case "$CONTEXT_LINES" in
  ''|*[!0-9]*)
    echo "Context lines must be a positive integer"
    exit 1
    ;;
esac

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    return 1
  fi
}

list_models() {
  local models=""

  models="$(ollama list 2>/dev/null | awk 'NR > 1 && $1 != "NAME" {print $1}' || true)"
  if [ -n "$models" ]; then
    printf '%s\n' "$models"
    return 0
  fi

  list_models_fs
}

list_models_fs() {
  local manifest_root="$HOME/.ollama/models/manifests"
  if [ ! -d "$manifest_root" ]; then
    return 0
  fi

  find "$manifest_root" -type f | while IFS= read -r path; do
    local rel="${path#"$manifest_root"/}"
    local registry="${rel%%/*}"
    local rest="${rel#*/}"
    local namespace="${rest%%/*}"
    rest="${rest#*/}"
    local model="${rest%%/*}"
    local tag="${rest#*/}"
    local name=""

    if [ "$namespace" = "library" ]; then
      name="${model}:${tag}"
    else
      name="${namespace}/${model}:${tag}"
    fi
    printf '%s\n' "$name"
  done | sort -u
}

load_roster_file() {
  local file="$1"
  local line=""

  while IFS= read -r line || [ -n "$line" ]; do
    line="$(printf '%s' "$line" | sed 's/#.*$//' | sed 's/^ *//; s/ *$//')"
    [ -n "$line" ] && printf '%s\n' "$line"
  done < "$file" | awk '!seen[$0]++'
}

load_topics_file() {
  local file="$1"
  local line=""

  while IFS= read -r line || [ -n "$line" ]; do
    line="$(printf '%s' "$line" | sed 's/#.*$//' | sed 's/^ *//; s/ *$//')"
    [ -n "$line" ] && printf '%s\n' "$line"
  done < "$file"
}

load_roles_file() {
  local file="$1"
  local line=""
  local key=""
  local value=""
  local map_lines=""

  while IFS= read -r line || [ -n "$line" ]; do
    line="$(printf '%s' "$line" | sed 's/#.*$//' | sed 's/^ *//; s/ *$//')"
    [ -z "$line" ] && continue
    case "$line" in
      *=*)
        key="${line%%=*}"
        value="${line#*=}"
        ;;
      *)
        continue
        ;;
    esac
    key="$(printf '%s' "$key" | sed 's/^ *//; s/ *$//')"
    value="$(printf '%s' "$value" | sed 's/^ *//; s/ *$//')"
    if [ "$key" = "*" ] || [ "$key" = "default" ]; then
      ROLE_DEFAULT="$value"
    elif [ -n "$key" ] && [ -n "$value" ]; then
      map_lines="${map_lines}${key}=${value}"$'\n'
    fi
  done < "$file"

  ROLE_MAP_TEXT="$(printf '%s' "$map_lines" | awk '!seen[$0]++')"
}

role_for_model() {
  local model="$1"
  local role=""

  if [ -n "$ROLE_MAP_TEXT" ]; then
    role="$(printf '%s\n' "$ROLE_MAP_TEXT" | awk -F= -v key="$model" '$1 == key {print $2; exit}')"
  fi
  if [ -z "$role" ] && [ -n "$ROLE_DEFAULT" ]; then
    role="$ROLE_DEFAULT"
  fi
  printf '%s' "$role"
}

is_in_models() {
  local name="$1"
  printf '%s\n' "${MODELS[@]}" | grep -Fxq "$name"
}

queue_add() {
  local name="$1"
  if ! printf '%s\n' "$QUEUE_MODELS" | grep -Fxq "$name"; then
    QUEUE_MODELS="${QUEUE_MODELS}${name}"$'\n'
  fi
}

queue_remove() {
  local name="$1"
  if [ -z "$QUEUE_MODELS" ]; then
    return 0
  fi
  QUEUE_MODELS="$(printf '%s\n' "$QUEUE_MODELS" | grep -Fxv "$name" || true)"
}

queue_clear() {
  QUEUE_MODELS=""
}

queue_by_pattern() {
  local pattern="$1"
  local model=""

  if [ -z "$pattern" ]; then
    return 0
  fi

  for model in "${MODELS[@]}"; do
    if printf '%s\n' "$model" | grep -E -q "$pattern"; then
      queue_add "$model"
    fi
  done
}

unqueue_by_pattern() {
  local pattern="$1"
  local model=""

  if [ -z "$pattern" ]; then
    return 0
  fi

  for model in "${MODELS[@]}"; do
    if printf '%s\n' "$model" | grep -E -q "$pattern"; then
      queue_remove "$model"
    fi
  done
}

is_queued() {
  local name="$1"
  if [ -z "$QUEUE_MODELS" ]; then
    return 1
  fi
  if printf '%s\n' "$QUEUE_MODELS" | grep -Fxq "$name"; then
    return 0
  fi
  return 1
}

queued_stream() {
  local model=""
  while IFS= read -r model; do
    [ -z "$model" ] && continue
    if is_in_models "$model" && ! is_muted "$model"; then
      printf '%s\n' "$model"
    fi
  done <<EOF
$QUEUE_MODELS
EOF
}

filter_not_queued() {
  local model=""
  while IFS= read -r model; do
    [ -z "$model" ] && continue
    if ! is_queued "$model"; then
      printf '%s\n' "$model"
    fi
  done
}

pin_add() {
  local name="$1"
  if ! printf '%s\n' "$PINNED_MODELS" | grep -Fxq "$name"; then
    PINNED_MODELS="${PINNED_MODELS}${name}"$'\n'
  fi
}

pin_remove() {
  local name="$1"
  if [ -z "$PINNED_MODELS" ]; then
    return 0
  fi
  PINNED_MODELS="$(printf '%s\n' "$PINNED_MODELS" | grep -Fxv "$name" || true)"
}

pin_by_pattern() {
  local pattern="$1"
  local model=""

  if [ -z "$pattern" ]; then
    return 0
  fi

  for model in "${MODELS[@]}"; do
    if printf '%s\n' "$model" | grep -E -q "$pattern"; then
      pin_add "$model"
    fi
  done
}

unpin_by_pattern() {
  local pattern="$1"
  local model=""

  if [ -z "$pattern" ]; then
    return 0
  fi

  for model in "${MODELS[@]}"; do
    if printf '%s\n' "$model" | grep -E -q "$pattern"; then
      pin_remove "$model"
    fi
  done
}

is_pinned() {
  local name="$1"
  if [ -z "$PINNED_MODELS" ]; then
    return 1
  fi
  if printf '%s\n' "$PINNED_MODELS" | grep -Fxq "$name"; then
    return 0
  fi
  return 1
}

pinned_stream() {
  local model=""
  while IFS= read -r model; do
    [ -z "$model" ] && continue
    if is_in_models "$model" && ! is_muted "$model"; then
      printf '%s\n' "$model"
    fi
  done <<EOF
$PINNED_MODELS
EOF
}

filter_not_pinned() {
  local model=""
  while IFS= read -r model; do
    [ -z "$model" ] && continue
    if ! is_pinned "$model"; then
      printf '%s\n' "$model"
    fi
  done
}

mute_add() {
  local name="$1"
  if ! printf '%s\n' "$MUTED_MODELS" | grep -Fxq "$name"; then
    MUTED_MODELS="${MUTED_MODELS}${name}"$'\n'
  fi
}

mute_remove() {
  local name="$1"
  if [ -z "$MUTED_MODELS" ]; then
    return 0
  fi
  MUTED_MODELS="$(printf '%s\n' "$MUTED_MODELS" | grep -Fxv "$name" || true)"
}

mute_all() {
  local model=""
  MUTED_MODELS=""
  for model in "${MODELS[@]}"; do
    mute_add "$model"
  done
}

unmute_all() {
  MUTED_MODELS=""
}

mute_by_pattern() {
  local pattern="$1"
  local model=""

  if [ -z "$pattern" ]; then
    return 0
  fi

  for model in "${MODELS[@]}"; do
    if printf '%s\n' "$model" | grep -E -q "$pattern"; then
      mute_add "$model"
    fi
  done
}

unmute_by_pattern() {
  local pattern="$1"
  local model=""

  if [ -z "$pattern" ]; then
    return 0
  fi

  for model in "${MODELS[@]}"; do
    if printf '%s\n' "$model" | grep -E -q "$pattern"; then
      mute_remove "$model"
    fi
  done
}

is_muted() {
  local name="$1"
  if [ -z "$MUTED_MODELS" ]; then
    return 1
  fi
  if printf '%s\n' "$MUTED_MODELS" | grep -Fxq "$name"; then
    return 0
  fi
  return 1
}

filter_muted() {
  local model=""
  while IFS= read -r model; do
    [ -z "$model" ] && continue
    if ! is_muted "$model"; then
      printf '%s\n' "$model"
    fi
  done
}

print_roles() {
  local model=""
  local role=""

  for model in "${MODELS[@]}"; do
    role="$(role_for_model "$model")"
    if [ -n "$role" ]; then
      printf '%s - %s\n' "$model" "$role"
    else
      printf '%s -\n' "$model"
    fi
  done
}

print_pins() {
  local model=""
  if [ -z "$PINNED_MODELS" ]; then
    echo "No pinned models"
    return 0
  fi
  while IFS= read -r model; do
    [ -z "$model" ] && continue
    printf '%s\n' "$model"
  done <<EOF
$PINNED_MODELS
EOF
}

print_queue() {
  local model=""
  local suffix=""
  local idx=1

  if [ -z "$QUEUE_MODELS" ]; then
    echo "No queued models"
    return 0
  fi

  while IFS= read -r model; do
    [ -z "$model" ] && continue
    suffix=""
    if is_muted "$model"; then
      suffix="muted"
    fi
    if [ -n "$suffix" ]; then
      suffix=" ($suffix)"
    fi
    printf '%2d. %s%s\n' "$idx" "$model" "$suffix"
    idx=$((idx + 1))
  done <<EOF
$QUEUE_MODELS
EOF
}

shuffle_stream() {
  awk 'BEGIN{srand()} {print rand() "\t" $0}' | sort -n | cut -f2-
}

rotate_stream() {
  local offset="$1"
  awk -v offset="$offset" '
    { lines[NR] = $0 }
    END {
      if (NR == 0) {
        exit
      }
      if (offset < 0) {
        offset = 0
      }
      o = offset % NR
      for (i = 1; i <= NR; i++) {
        idx = i + o
        if (idx > NR) {
          idx -= NR
        }
        print lines[idx]
      }
    }'
}

filter_models() {
  local models="$1"
  if [ -n "$PREFIX" ]; then
    models="$(printf '%s\n' "$models" | awk -v prefix="$PREFIX" '$0 ~ "^"prefix')"
  fi
  if [ -n "$LIMIT" ]; then
    models="$(printf '%s\n' "$models" | head -n "$LIMIT")"
  fi
  if [ -n "$EXCLUDE" ]; then
    models="$(printf '%s\n' "$models" | awk -v pattern="$EXCLUDE" '$0 !~ pattern')"
  fi
  printf '%s\n' "$models"
}

clamp_speaker_count() {
  if [ "$SPEAKER_COUNT" -gt 0 ] && [ "$SPEAKER_COUNT" -gt "${#MODELS[@]}" ]; then
    SPEAKER_COUNT="${#MODELS[@]}"
  fi
}

remove_by_pattern() {
  local pattern="$1"
  local model=""
  local kept=()

  if [ -z "$pattern" ]; then
    return 0
  fi

  for model in "${MODELS[@]}"; do
    if printf '%s\n' "$model" | grep -E -q "$pattern"; then
      continue
    fi
    kept+=("$model")
  done

  MODELS=("${kept[@]}")
}

add_by_pattern() {
  local pattern="$1"
  local current=""
  local model=""
  local next=()

  current="$(printf '%s\n' "${MODELS[@]}")"

  while IFS= read -r model; do
    [ -z "$model" ] && continue
    if printf '%s\n' "$current" | grep -Fxq "$model"; then
      next+=("$model")
      continue
    fi
    if [ -z "$pattern" ] || printf '%s\n' "$model" | grep -E -q "$pattern"; then
      next+=("$model")
    fi
  done <<EOF
$ALL_MODELS_TEXT
EOF

  MODELS=("${next[@]}")
}

prune_state() {
  local model=""
  local kept=""

  if [ -n "$PINNED_MODELS" ]; then
    kept=""
    while IFS= read -r model; do
      [ -z "$model" ] && continue
      if is_in_models "$model"; then
        kept="${kept}${model}"$'\n'
      fi
    done <<EOF
$PINNED_MODELS
EOF
    PINNED_MODELS="$kept"
  fi

  if [ -n "$MUTED_MODELS" ]; then
    kept=""
    while IFS= read -r model; do
      [ -z "$model" ] && continue
      if is_in_models "$model"; then
        kept="${kept}${model}"$'\n'
      fi
    done <<EOF
$MUTED_MODELS
EOF
    MUTED_MODELS="$kept"
  fi

  if [ -n "$QUEUE_MODELS" ]; then
    kept=""
    while IFS= read -r model; do
      [ -z "$model" ] && continue
      if is_in_models "$model"; then
        kept="${kept}${model}"$'\n'
      fi
    done <<EOF
$QUEUE_MODELS
EOF
    QUEUE_MODELS="$kept"
  fi
}

ensure_bus() {
  if [ -e "$BUS" ] && [ ! -p "$BUS" ]; then
    echo "agent.bus exists but is not a fifo: $BUS"
    exit 1
  fi
  if [ ! -p "$BUS" ]; then
    mkfifo "$BUS"
  fi
}

start_orchestrator() {
  local started="false"

  ensure_bus

  if ! pgrep -f "$ROOT/orchestrator.sh" >/dev/null 2>&1; then
    if [ "$MUTE_VOICE" = "true" ]; then
      (cd "$ROOT" && BR_VOICE_MUTE=1 ./orchestrator.sh < "$BUS") &
    else
      (cd "$ROOT" && ./orchestrator.sh < "$BUS") &
    fi
    ORCH_PID=$!
    started="true"
    sleep 0.2
  fi

  if [ "$started" = "true" ]; then
    trap 'if [ -n "$ORCH_PID" ]; then kill "$ORCH_PID" 2>/dev/null || true; fi' EXIT INT TERM
  fi
}

mic_prompt() {
  require_cmd rec
  if [ ! -x "$WHISPER_BIN" ] || [ ! -f "$WHISPER_MODEL" ]; then
    echo "whisper.cpp not found. Set WHISPER_BIN and WHISPER_MODEL."
    return 1
  fi

  rec -q -r 16000 -c 1 "$WAV_PATH" silence 1 0.1 1% 1 2.0 1%
  "$WHISPER_BIN" -m "$WHISPER_MODEL" -f "$WAV_PATH" -nt 2>/dev/null | tail -n 1 > "$PROMPT_PATH"
  tr -d '\r' < "$PROMPT_PATH"
}

text_prompt() {
  local prompt=""
  printf 'You> '
  if ! read -r prompt; then
    return 1
  fi
  printf '%s\n' "$prompt"
}

get_prompt() {
  if [ "$USE_MIC" = "true" ]; then
    mic_prompt
  else
    text_prompt
  fi
}

build_prompt() {
  local model="$1"
  local seed="$2"
  local last="$3"
  local base=""
  local context=""
  local role=""

  base="$(printf 'You are %s in a live multi-agent call. Keep it to 1-2 sentences.' "$model")"
  if [ -n "$ROOM_NAME" ]; then
    base="$base Room: $ROOM_NAME."
  fi
  role="$(role_for_model "$model")"
  if [ -n "$role" ]; then
    base="$base Role: $role."
  fi
  if [ -n "$AGENDA" ]; then
    base="$base Agenda: $AGENDA."
  fi
  if [ "$CONTEXT_LINES" -gt 0 ] && [ -n "$CONTEXT_BUFFER" ]; then
    context="$(printf '%s' "$CONTEXT_BUFFER" | tr '\n' ' ' | tr -s ' ')"
    base="$base Recent context: $context."
  fi

  if [ "$MODE" = "broadcast" ]; then
    printf '%s Topic: %s.' "$base" "$seed"
  else
    printf '%s Topic: %s. Last speaker: %s.' "$base" "$seed" "$last"
  fi
}

log_line() {
  if [ -z "$TRANSCRIPT_PATH" ]; then
    return 0
  fi

  local ts=""
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '%s|%s|%s|%s\n' "$ts" "$1" "$2" "$3" >> "$TRANSCRIPT_PATH"
}

append_summary_context() {
  local line="$1"
  SUMMARY_CONTEXT="${SUMMARY_CONTEXT}${line}"$'\n'
  if [ "${#SUMMARY_CONTEXT}" -gt "$SUMMARY_MAX_CHARS" ]; then
    SUMMARY_CONTEXT="${SUMMARY_CONTEXT: -$SUMMARY_MAX_CHARS}"
  fi
  if [ "$CONTEXT_LINES" -gt 0 ]; then
    CONTEXT_BUFFER="${CONTEXT_BUFFER}${line}"$'\n'
    CONTEXT_BUFFER="$(printf '%s' "$CONTEXT_BUFFER" | tail -n "$CONTEXT_LINES")"
  fi
}

stats_update() {
  local model="$1"
  local msg="$2"
  local chars="${#msg}"

  if [ -z "$model" ]; then
    return 0
  fi

  if [ -z "$SPEAK_STATS" ]; then
    SPEAK_STATS="${model}|1|${chars}"$'\n'
    return 0
  fi

  SPEAK_STATS="$(printf '%s\n' "$SPEAK_STATS" | awk -F'|' -v m="$model" -v c="$chars" '
    $1 == m { $2 = $2 + 1; $3 = $3 + c; found=1 }
    { print }
    END { if (!found) print m "|" 1 "|" c }
  ')"
}

stats_lines() {
  local sort_by="${1:-turns}"
  local data="$SPEAK_STATS"

  if [ -z "$data" ]; then
    return 0
  fi

  case "$sort_by" in
    chars)
      printf '%s\n' "$data" \
        | awk -F'|' '{printf "%s|%s|%s\n", $3, $2, $1}' \
        | sort -t'|' -k1,1nr -k3,3 \
        | awk -F'|' '{printf "%2d. %s (chars:%s turns:%s)\n", NR, $3, $1, $2}'
      ;;
    *)
      printf '%s\n' "$data" \
        | awk -F'|' '{printf "%s|%s|%s\n", $2, $3, $1}' \
        | sort -t'|' -k1,1nr -k3,3 \
        | awk -F'|' '{printf "%2d. %s (turns:%s chars:%s)\n", NR, $3, $1, $2}'
      ;;
  esac
}

print_stats() {
  local sort_by="${1:-turns}"

  if [ -z "$SPEAK_STATS" ]; then
    echo "No speaker stats yet"
    return 0
  fi

  printf 'Speaker stats (%s):\n' "$sort_by"
  stats_lines "$sort_by"
}

write_stats_file() {
  local path="$1"
  local sort_by="${2:-turns}"

  if [ -z "$path" ]; then
    return 0
  fi

  mkdir -p "$(dirname "$path")"
  {
    printf 'timestamp=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    if [ -z "$SPEAK_STATS" ]; then
      echo "No speaker stats yet"
    else
      printf 'Speaker stats (%s):\n' "$sort_by"
      stats_lines "$sort_by"
    fi
  } >> "$path"
}

run_stats() {
  if [ "$STATS" = "true" ]; then
    print_stats "turns"
  fi
  if [ -n "$STATS_FILE" ]; then
    write_stats_file "$STATS_FILE" "turns"
  fi
}

emit_line() {
  local agent="$1"
  local type="$2"
  local msg="$3"

  agent_emit "$agent" "$type" "$msg"
  log_line "$agent" "$type" "$msg"
  if [ "$type" = "say" ] && [ "$agent" != "SYSTEM" ] && [ "$agent" != "USER" ] && [ "$SUMMARY_RUNNING" != "true" ]; then
    append_summary_context "$agent: $msg"
    stats_update "$agent" "$msg"
  fi
}

fetch_reply() {
  local model="$1"
  local prompt="$2"
  local reply=""

  reply="$(
    { ollama run "$model" "$prompt" 2>/dev/null || true; } \
    | tr '\n' ' ' \
    | tr -s ' ' \
    | sed 's/^ *//; s/ *$//' \
    | cut -c1-"$MAX_CHARS"
  )"
  printf '%s' "$reply"
}

sleep_if_needed() {
  local delay="$1"
  if [ "$delay" = "0" ] || [ "$delay" = "0.0" ]; then
    return 0
  fi
  sleep "$delay"
}

print_status() {
  local muted_count="0"
  local pinned_count="0"
  local queued_count="0"
  if [ -n "$MUTED_MODELS" ]; then
    muted_count="$(printf '%s\n' "$MUTED_MODELS" | awk 'NF{c++} END{print c+0}')"
  fi
  if [ -n "$PINNED_MODELS" ]; then
    pinned_count="$(printf '%s\n' "$PINNED_MODELS" | awk 'NF{c++} END{print c+0}')"
  fi
  if [ -n "$QUEUE_MODELS" ]; then
    queued_count="$(printf '%s\n' "$QUEUE_MODELS" | awk 'NF{c++} END{print c+0}')"
  fi
  printf 'room=%s mode=%s rounds=%s speakers=%s pinned=%s muted=%s queued=%s spotlight=%s\n' \
    "${ROOM_NAME:-}" "$MODE" "$ROUNDS" "${SPEAKER_COUNT:-0}" "$pinned_count" "$muted_count" "$queued_count" "${SPOTLIGHT_PATTERN:-}"
  printf 'agenda=%s moderator=%s scribe=%s summary=%s minutes=%s parallel=%s round_robin=%s shuffle=%s\n' \
    "${AGENDA:-}" "${MODERATOR:-}" "${SCRIBE:-}" "$SUMMARY" "$MINUTES" "$PARALLEL" "$ROUND_ROBIN" "$SHUFFLE"
}

handle_command() {
  local input="$1"
  local cmd="${input%% *}"
  local arg="${input#"$cmd"}"
  arg="${arg# }"

  case "$cmd" in
    /help)
      echo "/help /roster /roles /pins /queue /mute <pattern> /unmute <pattern> /pin <pattern> /unpin <pattern>"
      echo "/queue <pattern> /unqueue <pattern> /queue-clear /hand <pattern>"
      echo "/mute-all /unmute-all /spotlight <pattern> /remove <pattern> /add [pattern] /topic <text>"
      echo "/mode <chain|broadcast> /parallel <on|off> /shuffle <on|off> /round-robin <on|off> /agenda <text> /room <name> /moderator <model> /scribe <model>"
      echo "/speaker-count <n> /speaker-delay <s> /round-delay <s> /topic-delay <s> /context-lines <n>"
      echo "/summary <on|off> /minutes <on|off> /stats [turns|chars] /status /quit"
      return 0
      ;;
    /roster)
      print_roster
      return 0
      ;;
    /roles)
      print_roles
      return 0
      ;;
    /pins)
      print_pins
      return 0
      ;;
    /queue)
      if [ -n "$arg" ]; then
        queue_by_pattern "$arg"
      fi
      print_queue
      return 0
      ;;
    /unqueue)
      if [ -n "$arg" ]; then
        unqueue_by_pattern "$arg"
        print_queue
      else
        echo "Usage: /unqueue <pattern>"
      fi
      return 0
      ;;
    /queue-clear)
      queue_clear
      print_queue
      return 0
      ;;
    /hand)
      if [ -n "$arg" ]; then
        queue_by_pattern "$arg"
        print_queue
      else
        echo "Usage: /hand <pattern>"
      fi
      return 0
      ;;
    /mute)
      mute_by_pattern "$arg"
      print_roster
      return 0
      ;;
    /unmute)
      unmute_by_pattern "$arg"
      print_roster
      return 0
      ;;
    /mute-all)
      mute_all
      print_roster
      return 0
      ;;
    /unmute-all)
      unmute_all
      SPOTLIGHT_PATTERN=""
      print_roster
      return 0
      ;;
    /pin)
      pin_by_pattern "$arg"
      print_pins
      return 0
      ;;
    /unpin)
      unpin_by_pattern "$arg"
      print_pins
      return 0
      ;;
    /spotlight)
      if [ -n "$arg" ]; then
        SPOTLIGHT_PATTERN="$arg"
        mute_all
        unmute_by_pattern "$arg"
        PINNED_MODELS=""
        pin_by_pattern "$arg"
        print_roster
      else
        echo "Usage: /spotlight <pattern>"
      fi
      return 0
      ;;
    /remove)
      if [ -n "$arg" ]; then
        remove_by_pattern "$arg"
        prune_state
        clamp_speaker_count
        print_roster
      else
        echo "Usage: /remove <pattern>"
      fi
      return 0
      ;;
    /add)
      add_by_pattern "$arg"
      prune_state
      clamp_speaker_count
      print_roster
      return 0
      ;;
    /topic)
      if [ -n "$arg" ]; then
        run_rounds "$arg"
        if [ "$SUMMARY" = "true" ]; then
          run_summary "$MODERATOR"
        fi
      else
        echo "Usage: /topic <text>"
      fi
      return 0
      ;;
    /mode)
      if [ "$arg" = "chain" ] || [ "$arg" = "broadcast" ]; then
        MODE="$arg"
      else
        echo "Mode must be chain or broadcast"
      fi
      return 0
      ;;
    /parallel)
      if [ "$arg" = "on" ]; then
        PARALLEL=true
      elif [ "$arg" = "off" ]; then
        PARALLEL=false
      else
        echo "Usage: /parallel on|off"
      fi
      return 0
      ;;
    /shuffle)
      if [ "$arg" = "on" ]; then
        SHUFFLE=true
      elif [ "$arg" = "off" ]; then
        SHUFFLE=false
      else
        echo "Usage: /shuffle on|off"
      fi
      return 0
      ;;
    /round-robin)
      if [ "$arg" = "on" ]; then
        ROUND_ROBIN=true
      elif [ "$arg" = "off" ]; then
        ROUND_ROBIN=false
      else
        echo "Usage: /round-robin on|off"
      fi
      return 0
      ;;
    /agenda)
      AGENDA="$arg"
      return 0
      ;;
    /room)
      ROOM_NAME="$arg"
      return 0
      ;;
    /speaker-count)
      if [[ "$arg" =~ ^[0-9]+$ ]]; then
        SPEAKER_COUNT="$arg"
      else
        echo "Usage: /speaker-count <n>"
      fi
      return 0
      ;;
    /speaker-delay)
      if [[ "$arg" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        SPEAKER_DELAY="$arg"
      else
        echo "Usage: /speaker-delay <seconds>"
      fi
      return 0
      ;;
    /round-delay)
      if [[ "$arg" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        ROUND_DELAY="$arg"
      else
        echo "Usage: /round-delay <seconds>"
      fi
      return 0
      ;;
    /topic-delay)
      if [[ "$arg" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        TOPIC_DELAY="$arg"
      else
        echo "Usage: /topic-delay <seconds>"
      fi
      return 0
      ;;
    /context-lines)
      if [[ "$arg" =~ ^[0-9]+$ ]]; then
        CONTEXT_LINES="$arg"
      else
        echo "Usage: /context-lines <n>"
      fi
      return 0
      ;;
    /moderator)
      if [ -n "$arg" ]; then
        MODERATOR="$arg"
      fi
      return 0
      ;;
    /scribe)
      if [ -n "$arg" ]; then
        SCRIBE="$arg"
      fi
      return 0
      ;;
    /summary)
      if [ "$arg" = "on" ]; then
        SUMMARY=true
      elif [ "$arg" = "off" ]; then
        SUMMARY=false
      else
        echo "Usage: /summary on|off"
      fi
      return 0
      ;;
    /minutes)
      if [ "$arg" = "on" ]; then
        MINUTES=true
      elif [ "$arg" = "off" ]; then
        MINUTES=false
      else
        echo "Usage: /minutes on|off"
      fi
      return 0
      ;;
    /stats)
      if [ -z "$arg" ] || [ "$arg" = "turns" ] || [ "$arg" = "chars" ]; then
        print_stats "$arg"
      else
        echo "Usage: /stats [turns|chars]"
      fi
      return 0
      ;;
    /status)
      print_status
      return 0
      ;;
    /quit|/exit)
      exit 0
      ;;
  esac
  return 1
}

print_roster() {
  local idx=1
  local model=""
  local suffix=""

  for model in "${MODELS[@]}"; do
    suffix=""
    if is_pinned "$model"; then
      suffix="pinned"
    fi
    if is_queued "$model"; then
      if [ -n "$suffix" ]; then
        suffix="$suffix, queued"
      else
        suffix="queued"
      fi
    fi
    if is_muted "$model"; then
      if [ -n "$suffix" ]; then
        suffix="$suffix, muted"
      else
        suffix="muted"
      fi
    fi
    if [ -n "$suffix" ]; then
      suffix=" ($suffix)"
    fi
    printf '%2d. %s%s\n' "$idx" "$model" "$suffix"
    idx=$((idx + 1))
  done
}

select_speakers() {
  local queued=""
  local pinned=""
  local rest=""
  local stream=""

  queued="$(queued_stream)"
  pinned="$(pinned_stream | filter_not_queued)"
  rest="$(printf '%s\n' "${MODELS[@]}" | filter_not_queued | filter_not_pinned | filter_muted)"
  if [ "$SHUFFLE" = "true" ]; then
    rest="$(printf '%s\n' "$rest" | shuffle_stream)"
  elif [ "$ROUND_ROBIN" = "true" ]; then
    rest="$(printf '%s\n' "$rest" | rotate_stream "$SPEAKER_OFFSET")"
  fi

  stream="$(
    {
      [ -n "$queued" ] && printf '%s\n' "$queued"
      [ -n "$pinned" ] && printf '%s\n' "$pinned"
      [ -n "$rest" ] && printf '%s\n' "$rest"
    } | awk 'NF'
  )"

  if [ "$SPEAKER_COUNT" -gt 0 ]; then
    stream="$(printf '%s\n' "$stream" | head -n "$SPEAKER_COUNT")"
  fi

  printf '%s\n' "$stream"
}

announce_room() {
  local details="Participants: ${#MODELS[@]}. Mode: ${MODE}. Rounds: ${ROUNDS}."
  if [ -n "$ROOM_NAME" ]; then
    details="Room: ${ROOM_NAME}. $details"
  fi
  if [ -n "$AGENDA" ]; then
    details="$details Agenda: ${AGENDA}."
  fi
  if [ "$SPEAKER_COUNT" -gt 0 ]; then
    details="$details Active speakers per round: ${SPEAKER_COUNT}."
  fi
  if [ "$PARALLEL" = "true" ] && [ "$MODE" = "broadcast" ]; then
    details="$details Parallel broadcast enabled."
  fi
  if [ -n "$PINNED_MODELS" ]; then
    local pinned_count="0"
    pinned_count="$(printf '%s\n' "$PINNED_MODELS" | awk 'NF{c++} END{print c+0}')"
    if [ "$pinned_count" -gt 0 ]; then
      details="$details Pinned: ${pinned_count}."
    fi
  fi
  if [ -n "$SPOTLIGHT_PATTERN" ]; then
    details="$details Spotlight: ${SPOTLIGHT_PATTERN}."
  fi
  if [ "$SPEAKER_DELAY" != "0" ] || [ "$ROUND_DELAY" != "0" ]; then
    details="$details Delays: speaker ${SPEAKER_DELAY}s, round ${ROUND_DELAY}s."
  fi
  emit_line "SYSTEM" "say" "Agent room online. $details"
}

run_rollcall() {
  local model=""
  local reply=""

  for model in "${MODELS[@]}"; do
    if is_muted "$model"; then
      continue
    fi
    reply="$(fetch_reply "$model" "Say hello to the room in one short sentence. Mention your role if you have one.")"
    if [ -n "$reply" ]; then
      emit_line "$model" "say" "$reply"
      sleep_if_needed "$SPEAKER_DELAY"
    fi
  done
}

run_summary() {
  local moderator="$1"
  local summary=""

  if [ -z "$SUMMARY_CONTEXT" ]; then
    return 0
  fi

  summary="$(fetch_reply "$moderator" "Summarize this meeting in 5 bullets. Transcript: $SUMMARY_CONTEXT")"
  if [ -n "$summary" ]; then
    SUMMARY_RUNNING="true"
    emit_line "$moderator" "say" "$summary"
    SUMMARY_RUNNING="false"
    if [ -n "$SUMMARY_FILE" ]; then
      printf '%s|%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$summary" >> "$SUMMARY_FILE"
    fi
  fi
}

run_minutes() {
  local scribe="$1"
  local minutes=""

  if [ -z "$SUMMARY_CONTEXT" ]; then
    return 0
  fi

  minutes="$(fetch_reply "$scribe" "Create meeting minutes with sections: Decisions, Action Items (owner, due date), Risks, Notes. Transcript: $SUMMARY_CONTEXT")"
  if [ -n "$minutes" ]; then
    SUMMARY_RUNNING="true"
    emit_line "$scribe" "say" "$minutes"
    SUMMARY_RUNNING="false"
    if [ -n "$MINUTES_FILE" ]; then
      printf '%s|%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$minutes" >> "$MINUTES_FILE"
    fi
  fi
}

run_round_parallel() {
  local seed="$1"
  local last="$2"
  local had_speaker="false"
  local queued_spoke=""
  local tmpdir=""
  local speakers=()
  local pids=()
  local models=()
  local files=()
  local model=""
  local prompt=""
  local file=""
  local pid=""

  while IFS= read -r model; do
    [ -z "$model" ] && continue
    had_speaker="true"
    speakers+=("$model")
  done < <(select_speakers)

  if [ "$had_speaker" = "false" ]; then
    emit_line "SYSTEM" "say" "No active speakers available (all muted?)."
    return 1
  fi

  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/br-agent-room.XXXXXX")"

  for model in "${speakers[@]}"; do
    prompt="$(build_prompt "$model" "$seed" "$last")"
    file="$(mktemp "${tmpdir}/reply.XXXXXX")"
    (
      fetch_reply "$model" "$prompt"
    ) > "$file" &
    pid=$!
    pids+=("$pid")
    models+=("$model")
    files+=("$file")
  done

  while [ "${#pids[@]}" -gt 0 ]; do
    local new_pids=()
    local new_models=()
    local new_files=()
    local i=0
    local any_done="false"
    local reply=""

    while [ $i -lt ${#pids[@]} ]; do
      pid="${pids[$i]}"
      if kill -0 "$pid" 2>/dev/null; then
        new_pids+=("$pid")
        new_models+=("${models[$i]}")
        new_files+=("${files[$i]}")
      else
        wait "$pid" 2>/dev/null || true
        reply=""
        if [ -f "${files[$i]}" ]; then
          reply="$(cat "${files[$i]}")"
        fi
        if [ -n "$reply" ]; then
          emit_line "${models[$i]}" "say" "$reply"
          if is_queued "${models[$i]}"; then
            queued_spoke="${queued_spoke}${models[$i]}"$'\n'
          fi
          sleep_if_needed "$SPEAKER_DELAY"
        fi
        any_done="true"
      fi
      i=$((i + 1))
    done

    pids=("${new_pids[@]}")
    models=("${new_models[@]}")
    files=("${new_files[@]}")

    if [ "${#pids[@]}" -gt 0 ] && [ "$any_done" != "true" ]; then
      sleep 0.05
    fi
  done

  rm -rf "$tmpdir"

  if [ -n "$queued_spoke" ]; then
    while IFS= read -r model; do
      [ -z "$model" ] && continue
      queue_remove "$model"
    done <<EOF
$queued_spoke
EOF
  fi

  return 0
}

run_rounds() {
  local seed="$1"
  local last="$seed"
  local round=1
  local model=""
  local reply=""
  local prompt=""

  log_line "USER" "say" "$seed"
  append_summary_context "USER: $seed"

  while [ "$round" -le "$ROUNDS" ]; do
    if [ "$MODE" = "broadcast" ] && [ "$PARALLEL" = "true" ]; then
      if ! run_round_parallel "$seed" "$last"; then
        break
      fi
    else
      local had_speaker="false"
      local queued_spoke=""
      while IFS= read -r model; do
        [ -z "$model" ] && continue
        had_speaker="true"
        prompt="$(build_prompt "$model" "$seed" "$last")"
        reply="$(fetch_reply "$model" "$prompt")"
        if [ -n "$reply" ]; then
          emit_line "$model" "say" "$reply"
          last="$reply"
          if is_queued "$model"; then
            queued_spoke="${queued_spoke}${model}"$'\n'
          fi
          sleep_if_needed "$SPEAKER_DELAY"
        fi
      done < <(select_speakers)
      if [ -n "$queued_spoke" ]; then
        while IFS= read -r model; do
          [ -z "$model" ] && continue
          queue_remove "$model"
        done <<EOF
$queued_spoke
EOF
      fi
      if [ "$had_speaker" = "false" ]; then
        emit_line "SYSTEM" "say" "No active speakers available (all muted?)."
        break
      fi
    fi
    if [ "$ROUND_ROBIN" = "true" ] && [ "$SHUFFLE" != "true" ]; then
      SPEAKER_OFFSET=$((SPEAKER_OFFSET + 1))
    fi
    round=$((round + 1))
    sleep_if_needed "$ROUND_DELAY"
  done
}

main() {
  require_cmd ollama
  start_orchestrator

  source "$ROOT/agent.sh"

  if [ -n "$SEED_FILE" ]; then
    if [ ! -f "$SEED_FILE" ]; then
      echo "Seed file not found: $SEED_FILE"
      exit 1
    fi
    SEED="$(cat "$SEED_FILE")"
  fi

  if [ -n "$ROLES_FILE" ]; then
    if [ ! -f "$ROLES_FILE" ]; then
      echo "Roles file not found: $ROLES_FILE"
      exit 1
    fi
    load_roles_file "$ROLES_FILE"
  fi

  local raw_models=""
  if [ -n "$ROSTER_FILE" ]; then
    if [ ! -f "$ROSTER_FILE" ]; then
      echo "Roster file not found: $ROSTER_FILE"
      exit 1
    fi
    raw_models="$(load_roster_file "$ROSTER_FILE")"
  else
    raw_models="$(list_models)"
  fi
  raw_models="$(filter_models "$raw_models")"

  if [ -z "$raw_models" ]; then
    echo "No models found."
    exit 1
  fi

  MODELS=()
  while IFS= read -r line; do
    [ -n "$line" ] && MODELS+=("$line")
  done <<EOF
$raw_models
EOF

  ALL_MODELS_TEXT="$(printf '%s\n' "${MODELS[@]}")"

  if [ -n "$REMOVE_PATTERNS" ]; then
    while IFS= read -r pattern; do
      [ -n "$pattern" ] && remove_by_pattern "$pattern"
    done <<EOF
$REMOVE_PATTERNS
EOF
  fi

  if [ -n "$MUTE_PATTERNS" ]; then
    while IFS= read -r pattern; do
      [ -n "$pattern" ] && mute_by_pattern "$pattern"
    done <<EOF
$MUTE_PATTERNS
EOF
  fi

  if [ -n "$PIN_PATTERNS" ]; then
    while IFS= read -r pattern; do
      [ -n "$pattern" ] && pin_by_pattern "$pattern"
    done <<EOF
$PIN_PATTERNS
EOF
  fi

  if [ -n "$SPOTLIGHT_PATTERN" ]; then
    mute_all
    unmute_by_pattern "$SPOTLIGHT_PATTERN"
    PINNED_MODELS=""
    pin_by_pattern "$SPOTLIGHT_PATTERN"
  fi

  if [ -n "$QUEUE_PATTERNS" ]; then
    while IFS= read -r pattern; do
      [ -n "$pattern" ] && queue_by_pattern "$pattern"
    done <<EOF
$QUEUE_PATTERNS
EOF
  fi

  clamp_speaker_count

  if [ "$ROSTER_ONLY" = "true" ]; then
    print_roster
    return 0
  fi

  if [ -n "$TRANSCRIPT_PATH" ]; then
    mkdir -p "$(dirname "$TRANSCRIPT_PATH")"
    touch "$TRANSCRIPT_PATH"
    local room_label=""
    room_label="${ROOM_NAME:-Agent Room}"
    printf 'room=%s started=%s participants=%s\n' "$room_label" "$(date '+%Y-%m-%d %H:%M:%S')" "${#MODELS[@]}" >> "$TRANSCRIPT_PATH"
  fi

  if [ -n "$SUMMARY_FILE" ]; then
    mkdir -p "$(dirname "$SUMMARY_FILE")"
    touch "$SUMMARY_FILE"
  fi

  if [ -n "$MINUTES_FILE" ]; then
    mkdir -p "$(dirname "$MINUTES_FILE")"
    touch "$MINUTES_FILE"
  fi

  if [ -z "$MODERATOR" ]; then
    MODERATOR="${MODELS[0]}"
  fi
  if [ -z "$SCRIBE" ]; then
    SCRIBE="$MODERATOR"
  fi

  local ready_msg="Agent room ready with ${#MODELS[@]} models"
  if [ -n "$ROOM_NAME" ]; then
    ready_msg="Room ${ROOM_NAME} ready with ${#MODELS[@]} models"
  fi
  emit_line "SYSTEM" "say" "$ready_msg"

  if [ "$INTRO" = "true" ]; then
    announce_room
  fi

  if [ "$ROLLCALL" = "true" ]; then
    run_rollcall
  fi

  if [ -n "$TOPICS_FILE" ]; then
    if [ ! -f "$TOPICS_FILE" ]; then
      echo "Topics file not found: $TOPICS_FILE"
      exit 1
    fi
  fi

  local topics=()
  if [ -n "$SEED" ]; then
    topics+=("$SEED")
  fi
  if [ -n "$TOPICS_FILE" ]; then
    while IFS= read -r line; do
      [ -n "$line" ] && topics+=("$line")
    done < <(load_topics_file "$TOPICS_FILE")
  fi

  if [ "${#topics[@]}" -gt 0 ]; then
    local topic=""
    for topic in "${topics[@]}"; do
      run_rounds "$topic"
      if [ "$SUMMARY" = "true" ]; then
        run_summary "$MODERATOR"
      fi
      sleep_if_needed "$TOPIC_DELAY"
    done
    if [ "$SUMMARY_FINAL" = "true" ]; then
      run_summary "$MODERATOR"
    fi
    if [ "$MINUTES" = "true" ]; then
      run_minutes "$SCRIBE"
    fi
    run_stats
    return 0
  fi

  if [ -n "$SEED" ]; then
    run_rounds "$SEED"
    if [ "$SUMMARY" = "true" ]; then
      run_summary "$MODERATOR"
    fi
    if [ "$SUMMARY_FINAL" = "true" ] && [ "$SUMMARY" != "true" ]; then
      run_summary "$MODERATOR"
    fi
    if [ "$MINUTES" = "true" ]; then
      run_minutes "$SCRIBE"
    fi
    run_stats
    return 0
  fi

  while true; do
    local prompt=""
    prompt="$(get_prompt)" || break
    if [ "${prompt#"/"}" != "$prompt" ]; then
      if handle_command "$prompt"; then
        continue
      fi
    fi
    case "$prompt" in
      ""|"exit"|"quit")
        break
        ;;
    esac
    run_rounds "$prompt"
    if [ "$SUMMARY" = "true" ]; then
      run_summary "$MODERATOR"
    fi
  done

  if [ "$SUMMARY_FINAL" = "true" ] && [ "$SUMMARY" != "true" ]; then
    run_summary "$MODERATOR"
  fi
  if [ "$MINUTES" = "true" ]; then
    run_minutes "$SCRIBE"
  fi
  run_stats
}

main "$@"
