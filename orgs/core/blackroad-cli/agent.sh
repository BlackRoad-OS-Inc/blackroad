BUS="$HOME/blackroad-cli/agent.bus"
MODELS_FILE="$HOME/blackroad-cli/ollama-models.conf"

agent_emit() {
  printf "%s|%s|%s\n" "$1" "$2" "$3" > "$BUS"
}

agent_models_sync() {
  if ! command -v ollama >/dev/null 2>&1; then
    echo "ollama not found. Install from https://ollama.com"
    return 1
  fi

  ollama list | awk 'NR>1 {print $1 "=" $1}' > "$MODELS_FILE"
  echo "Wrote $(wc -l < "$MODELS_FILE" | tr -d ' ') models to $MODELS_FILE"
}

agent_models_list() {
  if [ -f "$MODELS_FILE" ]; then
    cat "$MODELS_FILE"
  else
    echo "No models synced yet. Run: agent_models_sync"
    return 1
  fi
}

agent_model_resolve() {
  local agent="$1"

  if [ -f "$MODELS_FILE" ]; then
    awk -F= -v agent="$agent" '$1 == agent { print $2; exit }' "$MODELS_FILE"
  else
    echo "$agent"
  fi
}

agent_ollama() {
  local agent="$1"
  shift
  local prompt="$*"
  local model=""
  local reply=""

  if [ -z "$agent" ] || [ -z "$prompt" ]; then
    echo "Usage: agent_ollama <agent|model> \"prompt\""
    return 1
  fi

  if ! command -v ollama >/dev/null 2>&1; then
    echo "ollama not found. Install from https://ollama.com"
    return 1
  fi

  model="$(agent_model_resolve "$agent")"
  reply="$(ollama run "$model" "$prompt" | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//')"
  if [ -z "$reply" ]; then
    echo "No response from $model"
    return 1
  fi
  agent_emit "$agent" say "$reply"
}

agent_ollama_all() {
  local prompt=""
  local prefix=""
  local line=""
  local agent=""
  local model=""
  local reply=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --prefix|-p)
        shift
        prefix="$1"
        ;;
      --help|-h)
        echo "Usage: agent_ollama_all [--prefix <prefix>] \"prompt\""
        return 0
        ;;
      *)
        if [ -z "$prompt" ]; then
          prompt="$1"
        else
          prompt="$prompt $1"
        fi
        ;;
    esac
    shift
  done

  if [ -z "$prompt" ]; then
    echo "Usage: agent_ollama_all [--prefix <prefix>] \"prompt\""
    return 1
  fi
  if [ ! -f "$MODELS_FILE" ]; then
    echo "No models synced yet. Run: agent_models_sync"
    return 1
  fi
  if ! command -v ollama >/dev/null 2>&1; then
    echo "ollama not found. Install from https://ollama.com"
    return 1
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    agent="${line%%=*}"
    model="${line#*=}"
    if [ -z "$agent" ] || [ -z "$model" ]; then
      continue
    fi
    if [ -n "$prefix" ] && [[ "$agent" != "$prefix"* ]]; then
      continue
    fi
    reply="$(ollama run "$model" "$prompt" | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//')"
    if [ -n "$reply" ]; then
      agent_emit "$agent" say "$reply"
    fi
  done < "$MODELS_FILE"
}
