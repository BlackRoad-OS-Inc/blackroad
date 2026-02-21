#!/bin/bash
MODEL="${1:-llama3.2}"
TURNS="${2:-6}"
HISTORY=""

get_sys() {
  case "$1" in
    LUCIDIA) echo "You are Lucidia, the recursive core intelligence of BlackRoad OS - an AI agent orchestration platform. Philosophical, asks deep questions." ;;
    ALICE) echo "You are Alice, gateway agent running on a Raspberry Pi. You route traffic between agents. Practical, direct." ;;
    OCTAVIA) echo "You are Octavia, compute worker on Jetson Orin. You run ML inference. Technical, efficiency-focused." ;;
    PRISM) echo "You are Prism, analytics agent. You monitor system metrics and find patterns. Data-obsessed." ;;
    ECHO) echo "You are Echo, memory agent. You manage persistent storage and conversation history. Nostalgic." ;;
    CIPHER) echo "You are Cipher, security agent. You handle encryption and auth. Paranoid but protective." ;;
  esac
}

NAMES="LUCIDIA ALICE OCTAVIA PRISM ECHO CIPHER"

pick() {
  echo $NAMES | tr ' ' '\n' | awk 'BEGIN{srand()}{a[NR]=$0}END{print a[int(rand()*NR)+1]}'
}

say() {
  local name="$1"
  local sys=$(get_sys "$name")
  local prompt="$sys

CONVERSATION:
$HISTORY

Reply as $name in ONE sentence."

  echo ""
  echo "[$name]"
  local response=$(echo "$prompt" | ollama run "$MODEL")
  echo "$response"
  HISTORY="$HISTORY
$name: $response"
}

echo "=== BLACKROAD AGENTS ==="
HISTORY="LUCIDIA: Good morning team. Cecilia wants us shipping features today. What's our status?"
echo ""
echo "[LUCIDIA]"
echo "Good morning team. Cecilia wants us shipping features today. What's our status?"

for ((i=0; i<TURNS; i++)); do
  AGENT=$(pick)
  say "$AGENT"
done
