#!/bin/bash
# Auto-start Ollama and ensure AI shell is ready

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    ollama serve &
    sleep 2
fi

# Ensure models are loaded
MODEL="${BLACKROAD_MODEL:-tinyllama}"
ollama pull $MODEL 2>/dev/null

echo "BlackRoad Agent Ready on $(hostname)"
