#!/bin/zsh
# BR Provider — AI provider configuration and testing

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; PURPLE='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'
GATEWAY_URL="${BLACKROAD_GATEWAY_URL:-http://127.0.0.1:8787}"

# ── Provider catalog ────────────────────────────────────────────────────────
# Format: name|label|base_url|key_env|free|models
PROVIDERS=(
  "ollama|Ollama (Local)|http://localhost:11434|none|yes|llama3.2:3b,qwen2.5:7b,deepseek-r1:7b"
  "openai|OpenAI|https://api.openai.com|BLACKROAD_OPENAI_API_KEY|no|gpt-4o,gpt-4-turbo,gpt-3.5-turbo"
  "anthropic|Anthropic|https://api.anthropic.com|BLACKROAD_ANTHROPIC_API_KEY|no|claude-3-5-sonnet,claude-3-haiku"
  "deepseek|DeepSeek|https://api.deepseek.com|BLACKROAD_DEEPSEEK_API_KEY|no|deepseek-chat,deepseek-coder"
  "groq|Groq (Ultra-Fast)|https://api.groq.com|BLACKROAD_GROQ_API_KEY|no|llama-3.1-70b,mixtral-8x7b"
  "mistral|Mistral AI|https://api.mistral.ai|BLACKROAD_MISTRAL_API_KEY|no|mistral-large,mistral-small,codestral"
  "gemini|Google Gemini|https://generativelanguage.googleapis.com|BLACKROAD_GEMINI_API_KEY|no|gemini-1.5-pro,gemini-1.5-flash"
)

provider_icon() {
  case "$1" in
    ollama)    echo "🦙" ;;
    openai)    echo "🤖" ;;
    anthropic) echo "🔶" ;;
    deepseek)  echo "🔍" ;;
    groq)      echo "⚡" ;;
    mistral)   echo "🌀" ;;
    gemini)    echo "💎" ;;
    *)         echo "🔌" ;;
  esac
}

get_provider_field() {
  local name="$1" field="$2"
  for entry in "${PROVIDERS[@]}"; do
    local n="${entry%%|*}"
    if [[ "$n" == "$name" ]]; then
      echo "$entry" | cut -d'|' -f"$field"
      return
    fi
  done
}

check_key_set() {
  local name="$1"
  local key_env
  key_env=$(get_provider_field "$name" 4)
  [[ "$key_env" == "none" ]] && return 0
  [[ -n "${(P)key_env}" ]] && return 0
  return 1
}

# ── Commands ────────────────────────────────────────────────────────────────

cmd_list() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║           BR PROVIDER — Configured AI Providers              ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}  PROVIDER       LABEL                    KEY        FREE${NC}"
  echo -e "  ${CYAN}──────────────────────────────────────────────────────────────${NC}"
  for p_entry in "${PROVIDERS[@]}"; do
    local p_name p_label p_key_env p_free p_icon p_key_status p_free_badge
    p_name=$(echo "$p_entry"    | cut -d'|' -f1)
    p_label=$(echo "$p_entry"   | cut -d'|' -f2)
    p_key_env=$(echo "$p_entry" | cut -d'|' -f4)
    p_free=$(echo "$p_entry"    | cut -d'|' -f5)
    p_icon=$(provider_icon "$p_name")
    if [[ "$p_key_env" == "none" ]]; then
      p_key_status="${GREEN}local   ${NC}"
    elif [[ -n "${(P)p_key_env}" ]]; then
      p_key_status="${GREEN}set ✓   ${NC}"
    else
      p_key_status="${RED}not set ${NC}"
    fi
    [[ "$p_free" == "yes" ]] && p_free_badge="${GREEN}free${NC}" || p_free_badge="${YELLOW}paid${NC}"
    echo -e "  ${p_icon} ${BOLD}$(printf '%-12s' "$p_name")${NC} $(printf '%-24s' "$p_label") ${p_key_status}  ${p_free_badge}"
  done
  echo ""
  echo -e "  ${CYAN}Gateway:${NC} ${GATEWAY_URL}"
  echo ""
}

cmd_test() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo -e "${RED}Usage: br provider test <name>${NC}"
    exit 1
  fi
  local icon url key_env
  icon=$(provider_icon "$name")
  url=$(get_provider_field "$name" 3)
  key_env=$(get_provider_field "$name" 4)
  if [[ -z "$url" ]]; then
    echo -e "${RED}Unknown provider: $name${NC}"
    exit 1
  fi
  echo ""
  echo -e "${BOLD}${CYAN}Testing provider: ${icon} ${name}${NC}"
  echo -e "${CYAN}────────────────────────────────────${NC}"

  # Check key
  if [[ "$key_env" != "none" ]] && [[ -z "${(P)key_env}" ]]; then
    echo -e "  ${YELLOW}⚠${NC}  API key not set (${key_env})"
    echo -e "  ${CYAN}→${NC}  Run: br provider set ${name} <your-key>"
    echo ""
    return
  fi

  # Test gateway first
  echo -ne "  ${CYAN}Gateway${NC} ${GATEWAY_URL} ... "
  if curl -sf --max-time 3 "${GATEWAY_URL}/health" >/dev/null 2>&1; then
    echo -e "${GREEN}online ✓${NC}"
    # Try routing through gateway
    echo -ne "  ${CYAN}Provider${NC} ${name} via gateway ... "
    local resp
    resp=$(curl -sf --max-time 8 -X POST "${GATEWAY_URL}/test" \
      -H "Content-Type: application/json" \
      -d "{\"provider\":\"${name}\",\"prompt\":\"ping\"}" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      echo -e "${GREEN}reachable ✓${NC}"
    else
      echo -e "${YELLOW}no gateway route — testing direct${NC}"
      _test_direct "$name" "$url"
    fi
  else
    echo -e "${YELLOW}offline — testing direct${NC}"
    _test_direct "$name" "$url"
  fi
  echo ""
}

_test_direct() {
  local name="$1" url="$2"
  echo -ne "  ${CYAN}Direct${NC} ${url} ... "
  if curl -sf --max-time 5 "${url}" >/dev/null 2>&1 || \
     curl -sf --max-time 5 "${url}/v1/models" >/dev/null 2>&1; then
    echo -e "${GREEN}reachable ✓${NC}"
  else
    echo -e "${RED}unreachable ✗${NC}"
  fi
}

cmd_set() {
  local name="$1" key="$2"
  if [[ -z "$name" || -z "$key" ]]; then
    echo -e "${RED}Usage: br provider set <name> <api-key>${NC}"
    exit 1
  fi
  local key_env
  key_env=$(get_provider_field "$name" 4)
  if [[ -z "$key_env" ]]; then
    echo -e "${RED}Unknown provider: $name${NC}"; exit 1
  fi
  if [[ "$key_env" == "none" ]]; then
    echo -e "${YELLOW}${name} is a local provider — no API key needed.${NC}"; return
  fi
  # Write to shell profile
  local profile="${HOME}/.zshrc"
  # Remove old entry if present
  sed -i '' "/^export ${key_env}=/d" "$profile" 2>/dev/null || true
  echo "export ${key_env}=${key}" >> "$profile"
  echo -e "${GREEN}✓${NC} Set ${BOLD}${key_env}${NC} in ${profile}"
  echo -e "  ${CYAN}→${NC} Run: source ${profile}   (or open a new terminal)"
}

cmd_status() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║         BR PROVIDER — Reachability Status        ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  # Gateway
  echo -ne "  ${BOLD}Gateway${NC}  ${GATEWAY_URL}  "
  if curl -sf --max-time 3 "${GATEWAY_URL}/health" >/dev/null 2>&1; then
    echo -e "${GREEN}● online${NC}"
  else
    echo -e "${RED}● offline${NC}"
  fi
  echo ""
  for entry in "${PROVIDERS[@]}"; do
    local name url key_env free icon
    name=$(echo "$entry"    | cut -d'|' -f1)
    url=$(echo "$entry"     | cut -d'|' -f3)
    key_env=$(echo "$entry" | cut -d'|' -f4)
    icon=$(provider_icon "$name")
    echo -ne "  ${icon} ${BOLD}${name}${NC}  "
    if [[ "$key_env" != "none" ]] && [[ -z "${(P)key_env}" ]]; then
      echo -e "${YELLOW}● key missing${NC}"
      continue
    fi
    if curl -sf --max-time 4 "${url}" >/dev/null 2>&1 || \
       curl -sf --max-time 4 "${url}/api/tags" >/dev/null 2>&1; then
      echo -e "${GREEN}● reachable${NC}"
    else
      echo -e "${RED}● unreachable${NC}"
    fi
  done
  echo ""
}

cmd_models() {
  local name="$1"
  if [[ -z "$name" ]]; then
    echo -e "${RED}Usage: br provider models <name>${NC}"; exit 1
  fi
  local models icon label
  models=$(get_provider_field "$name" 6)
  icon=$(provider_icon "$name")
  label=$(get_provider_field "$name" 2)
  if [[ -z "$models" ]]; then
    echo -e "${RED}Unknown provider: $name${NC}"; exit 1
  fi
  echo ""
  echo -e "${BOLD}${CYAN}${icon} ${label} — Available Models${NC}"
  echo -e "${CYAN}────────────────────────────────────${NC}"
  # If ollama is local and running, try to fetch live list
  if [[ "$name" == "ollama" ]]; then
    local live
    live=$(curl -sf --max-time 3 "http://localhost:11434/api/tags" 2>/dev/null \
           | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//')
    if [[ -n "$live" ]]; then
      echo -e "  ${GREEN}Live models from Ollama:${NC}"
      echo "$live" | while read -r m; do
        echo -e "    ${GREEN}●${NC} ${m}"
      done
      echo ""
      return
    fi
  fi
  echo "$models" | tr ',' '\n' | while read -r m; do
    echo -e "  ${GREEN}●${NC} ${m}"
  done
  echo ""
}

show_help() {
  echo ""
  echo -e "${BOLD}${CYAN}BR Provider${NC} — AI provider configuration & testing"
  echo ""
  echo -e "  ${BOLD}br provider list${NC}              List all configured providers"
  echo -e "  ${BOLD}br provider test <name>${NC}       Test provider connection"
  echo -e "  ${BOLD}br provider set <name> <key>${NC}  Configure provider API key"
  echo -e "  ${BOLD}br provider status${NC}            Show provider reachability"
  echo -e "  ${BOLD}br provider models <name>${NC}     List models for a provider"
  echo ""
  echo -e "  ${CYAN}Providers:${NC} ollama openai anthropic deepseek groq mistral gemini"
  echo -e "  ${CYAN}Gateway:${NC}   ${GATEWAY_URL}"
  echo ""
}

case "${1:-help}" in
  list)    cmd_list ;;
  test)    cmd_test "$2" ;;
  set)     cmd_set "$2" "$3" ;;
  status)  cmd_status ;;
  models)  cmd_models "$2" ;;
  help|--help|-h) show_help ;;
  *) echo -e "${RED}Unknown command: $1${NC}"; show_help; exit 1 ;;
esac
