#!/bin/zsh
# BR Model — AI model catalog and selection

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

# ── Model catalog ────────────────────────────────────────────────────────────
# Format: model-name|provider|context|speed|cost|tags
CATALOG=(
  "gpt-4o|openai|128k|fast|\$0.005/1k|coding,reasoning,vision,multimodal"
  "gpt-4-turbo|openai|128k|medium|\$0.01/1k|coding,reasoning,long-context"
  "gpt-3.5-turbo|openai|16k|fast|\$0.0005/1k|fast,chat,summarize"
  "claude-3-5-sonnet|anthropic|200k|fast|\$0.003/1k|coding,reasoning,long-context,analysis"
  "claude-3-haiku|anthropic|200k|fastest|\$0.00025/1k|fast,chat,summarize,cheap"
  "deepseek-chat|deepseek|64k|fast|\$0.0001/1k|chat,reasoning,cheap"
  "deepseek-coder|deepseek|64k|fast|code|coding,code-review,debugging"
  "llama-3.1-70b|groq|128k|ultra-fast|free|fast,coding,reasoning,free"
  "mixtral-8x7b|groq|32k|ultra-fast|free|fast,chat,free,efficient"
  "mistral-large|mistral|128k|fast|\$0.003/1k|coding,reasoning,multilingual"
  "mistral-small|mistral|128k|fast|\$0.001/1k|chat,fast,cheap"
  "codestral|mistral|32k|fast|code|coding,code-review,fill-in-middle"
  "llama3.2:3b|ollama|128k|ultra-fast|local|local,fast,offline,free"
  "qwen2.5:7b|ollama|128k|fast|local|local,coding,reasoning,offline,free"
  "deepseek-r1:7b|ollama|64k|medium|local|local,reasoning,offline,free"
  "gemini-1.5-pro|gemini|1000k|fast|\$0.0035/1k|long-context,vision,multimodal,reasoning"
  "gemini-1.5-flash|gemini|1000k|fastest|\$0.00035/1k|fast,cheap,long-context,multimodal"
)

# ── Task → recommended models ────────────────────────────────────────────────
typeset -A TASK_RECOMMENDATIONS
TASK_RECOMMENDATIONS=(
  [coding]="deepseek-coder codestral claude-3-5-sonnet gpt-4o qwen2.5:7b"
  [reasoning]="claude-3-5-sonnet deepseek-r1:7b gpt-4o mistral-large deepseek-chat"
  [fast]="claude-3-haiku llama-3.1-70b gemini-1.5-flash mixtral-8x7b deepseek-chat"
  [local]="qwen2.5:7b llama3.2:3b deepseek-r1:7b"
  [long-context]="gemini-1.5-pro claude-3-5-sonnet gpt-4o llama-3.1-70b mistral-large"
  [cheap]="claude-3-haiku deepseek-chat gemini-1.5-flash llama-3.1-70b mixtral-8x7b"
  [vision]="gpt-4o gemini-1.5-pro gemini-1.5-flash"
  [chat]="gpt-3.5-turbo claude-3-haiku mistral-small mixtral-8x7b deepseek-chat"
  [free]="llama-3.1-70b mixtral-8x7b llama3.2:3b qwen2.5:7b deepseek-r1:7b"
  [multilingual]="mistral-large gpt-4o claude-3-5-sonnet gemini-1.5-pro"
)

# ── Helpers ──────────────────────────────────────────────────────────────────

speed_color() {
  case "$1" in
    ultra-fast) echo "${GREEN}${BOLD}ultra-fast${NC}" ;;
    fastest)    echo "${GREEN}fastest${NC}" ;;
    fast)       echo "${CYAN}fast${NC}" ;;
    medium)     echo "${YELLOW}medium${NC}" ;;
    slow)       echo "${RED}slow${NC}" ;;
    *)          echo "$1" ;;
  esac
}

cost_color() {
  case "$1" in
    local|free|code) echo "${GREEN}${BOLD}${1}${NC}" ;;
    *\$0.0001*|\
    *\$0.0002*|\
    *\$0.0003*|\
    *\$0.0005*) echo "${GREEN}${1}${NC}" ;;
    *\$0.001*|\
    *\$0.002*|\
    *\$0.003*) echo "${YELLOW}${1}${NC}" ;;
    *)          echo "${RED}${1}${NC}" ;;
  esac
}

provider_icon() {
  case "$1" in
    openai)    echo "🤖" ;;
    anthropic) echo "🔶" ;;
    deepseek)  echo "🔍" ;;
    groq)      echo "⚡" ;;
    mistral)   echo "🌀" ;;
    ollama)    echo "🦙" ;;
    gemini)    echo "💎" ;;
    *)         echo "🔌" ;;
  esac
}

get_field() {
  echo "$1" | cut -d'|' -f"$2"
}

# ── Commands ─────────────────────────────────────────────────────────────────

cmd_list() {
  local entry model provider ctx speed cost icon current_provider=""
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║              BR MODEL — Full AI Model Catalog                        ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  local current_provider=""
  # Sort by provider for grouped display
  for entry in "${CATALOG[@]}"; do
    model=$(get_field "$entry" 1)
    provider=$(get_field "$entry" 2)
    ctx=$(get_field "$entry" 3)
    speed=$(get_field "$entry" 4)
    cost=$(get_field "$entry" 5)
    icon=$(provider_icon "$provider")
    if [[ "$provider" != "$current_provider" ]]; then
      echo -e "  ${BOLD}${icon} ${(U)provider}${NC}"
      current_provider="$provider"
    fi
    printf "    %-26s  ctx:%-7s  speed:%-12s  cost:%s\n" \
      "$(echo -e "${BOLD}${model}${NC}")" \
      "$ctx" \
      "$(echo -e "$(speed_color "$speed")")" \
      "$(echo -e "$(cost_color "$cost")")"
  done
  echo ""
  echo -e "  ${CYAN}Total models: ${#CATALOG[@]}${NC}   ${CYAN}Run:${NC} br model info <name>  |  br model recommend <task>"
  echo ""
}

cmd_search() {
  local term="$1" entry model provider ctx speed cost tags icon found=0
  if [[ -z "$term" ]]; then
    echo -e "${RED}Usage: br model search <term>${NC}"; exit 1
  fi
  echo ""
  echo -e "${BOLD}${CYAN}Model Search:${NC} \"${term}\""
  echo -e "${CYAN}──────────────────────────────────────────────────────${NC}"
  for entry in "${CATALOG[@]}"; do
    if echo "$entry" | grep -qi "$term"; then
      model=$(get_field "$entry" 1)
      provider=$(get_field "$entry" 2)
      ctx=$(get_field "$entry" 3)
      speed=$(get_field "$entry" 4)
      cost=$(get_field "$entry" 5)
      tags=$(get_field "$entry" 6)
      icon=$(provider_icon "$provider")
      echo -e "  ${icon} ${BOLD}${model}${NC}  (${provider})"
      echo -e "      ctx: ${ctx}  speed: $(speed_color "$speed")  cost: $(cost_color "$cost")"
      echo -e "      tags: ${CYAN}${tags}${NC}"
      echo ""
      found=$((found+1))
    fi
  done
  [[ $found -eq 0 ]] && echo -e "  ${YELLOW}No models found for \"${term}\"${NC}"
  echo ""
}

cmd_info() {
  local name="$1" entry model provider ctx speed cost tags icon found=0
  if [[ -z "$name" ]]; then
    echo -e "${RED}Usage: br model info <name>${NC}"; exit 1
  fi
  for entry in "${CATALOG[@]}"; do
    model=$(get_field "$entry" 1)
    if [[ "$model" == "$name" ]]; then
      provider=$(get_field "$entry" 2)
      ctx=$(get_field "$entry" 3)
      speed=$(get_field "$entry" 4)
      cost=$(get_field "$entry" 5)
      tags=$(get_field "$entry" 6)
      icon=$(provider_icon "$provider")
      echo ""
      echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
      echo -e "${BOLD}${CYAN}║  ${icon} Model Info: ${model}${NC}"
      echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
      echo ""
      echo -e "  ${BOLD}Provider:${NC}       ${icon} ${provider}"
      echo -e "  ${BOLD}Context:${NC}        ${ctx} tokens"
      echo -e "  ${BOLD}Speed:${NC}          $(speed_color "$speed")"
      echo -e "  ${BOLD}Cost:${NC}           $(cost_color "$cost")"
      echo -e "  ${BOLD}Tags:${NC}           ${CYAN}${tags}${NC}"
      echo ""
      # Advice
      case "$provider" in
        ollama)    echo -e "  ${YELLOW}→${NC}  Run locally: ollama run ${model}" ;;
        openai)    echo -e "  ${YELLOW}→${NC}  Set key: br provider set openai <key>" ;;
        anthropic) echo -e "  ${YELLOW}→${NC}  Set key: br provider set anthropic <key>" ;;
        groq)      echo -e "  ${YELLOW}→${NC}  Set key: br provider set groq <key>  (free tier available)" ;;
        deepseek)  echo -e "  ${YELLOW}→${NC}  Set key: br provider set deepseek <key>  (very cheap)" ;;
        mistral)   echo -e "  ${YELLOW}→${NC}  Set key: br provider set mistral <key>" ;;
        gemini)    echo -e "  ${YELLOW}→${NC}  Set key: br provider set gemini <key>" ;;
      esac
      echo ""
      found=1
      break
    fi
  done
  [[ $found -eq 0 ]] && echo -e "${RED}Model not found: ${name}${NC}" && exit 1
}

cmd_compare() {
  local a="$1" b="$2" ea="" eb="" entry model va vb ci
  if [[ -z "$a" || -z "$b" ]]; then
    echo -e "${RED}Usage: br model compare <model-a> <model-b>${NC}"; exit 1
  fi
  for entry in "${CATALOG[@]}"; do
    model=$(get_field "$entry" 1)
    [[ "$model" == "$a" ]] && ea="$entry"
    [[ "$model" == "$b" ]] && eb="$entry"
  done
  [[ -z "$ea" ]] && echo -e "${RED}Model not found: ${a}${NC}" && exit 1
  [[ -z "$eb" ]] && echo -e "${RED}Model not found: ${b}${NC}" && exit 1
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║              BR MODEL — Side-by-Side Comparison           ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}$(printf '%-14s  %-26s  %-26s' '' "$a" "$b")${NC}"
  echo -e "  ${CYAN}──────────────────────────────────────────────────────────${NC}"
  local -a cmp_fields=(2 3 4 5 6)
  local -a cmp_labels=("Provider" "Context" "Speed" "Cost" "Tags")
  local ci
  for ci in {1..5}; do
    va=$(get_field "$ea" "${cmp_fields[$ci]}")
    vb=$(get_field "$eb" "${cmp_fields[$ci]}")
    echo -e "  $(printf '%-14s' "${cmp_labels[$ci]}")  $(printf '%-26s' "$va")  ${vb}"
  done
  echo ""
}

cmd_recommend() {
  local task="$1" recs rank=1 model badge entry m provider ctx speed cost icon t
  if [[ -z "$task" ]]; then
    echo ""
    echo -e "${BOLD}${CYAN}Available task types:${NC}"
    for t in "${(@k)TASK_RECOMMENDATIONS}"; do
      echo -e "  ${CYAN}●${NC} ${t}"
    done
    echo ""
    echo -e "  Usage: ${BOLD}br model recommend <task>${NC}"
    echo ""
    return
  fi
  recs="${TASK_RECOMMENDATIONS[$task]}"
  if [[ -z "$recs" ]]; then
    echo ""
    echo -e "${YELLOW}No exact match for \"${task}\" — searching tags...${NC}"
    cmd_search "$task"
    return
  fi
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║  Best models for: ${(U)task}${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  for model in ${=recs}; do
    badge=""
    [[ $rank -eq 1 ]] && badge="${GREEN}${BOLD} ★ TOP PICK${NC}"
    [[ $rank -eq 2 ]] && badge="${CYAN} ★ Runner-up${NC}"
    for entry in "${CATALOG[@]}"; do
      m=$(get_field "$entry" 1)
      if [[ "$m" == "$model" ]]; then
        provider=$(get_field "$entry" 2)
        ctx=$(get_field "$entry" 3)
        speed=$(get_field "$entry" 4)
        cost=$(get_field "$entry" 5)
        icon=$(provider_icon "$provider")
        echo -e "  ${rank}. ${icon} ${BOLD}${model}${NC}${badge}"
        echo -e "     ${provider}  |  ctx: ${ctx}  |  speed: $(speed_color "$speed")  |  cost: $(cost_color "$cost")"
        echo ""
        break
      fi
    done
    rank=$((rank+1))
  done
}

show_help() {
  echo ""
  echo -e "${BOLD}${CYAN}BR Model${NC} — AI model catalog and selection"
  echo ""
  echo -e "  ${BOLD}br model list${NC}               List all models by provider"
  echo -e "  ${BOLD}br model search <term>${NC}      Search models by name or capability"
  echo -e "  ${BOLD}br model info <name>${NC}        Show model details (context, cost, speed)"
  echo -e "  ${BOLD}br model compare <a> <b>${NC}    Side-by-side model comparison"
  echo -e "  ${BOLD}br model recommend <task>${NC}   Best model for a task type"
  echo ""
  echo -e "  ${CYAN}Task types:${NC} coding  reasoning  fast  local  long-context  cheap  vision  free"
  echo ""
}

case "${1:-help}" in
  list)      cmd_list ;;
  search)    cmd_search "$2" ;;
  info)      cmd_info "$2" ;;
  compare)   cmd_compare "$2" "$3" ;;
  recommend) cmd_recommend "$2" ;;
  help|--help|-h) show_help ;;
  *) echo -e "${RED}Unknown command: $1${NC}"; show_help; exit 1 ;;
esac
