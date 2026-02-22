#!/bin/bash
# 🚀 BlackRoad AI - Ollama Entrypoint
set -e

echo "🌌 Starting BlackRoad AI Ollama Runtime..."

# Start Ollama server in background
echo "🔧 Starting Ollama server..."
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to start..."
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is ready!"
        break
    fi
    sleep 1
done

# Pull default models
echo "📥 Pulling default models..."
MODELS_TO_PULL=(
    "qwen2.5:7b"
    "deepseek-r1:7b"
    "llama3.2:3b"
    "mistral:7b"
)

for model in "${MODELS_TO_PULL[@]}"; do
    echo "Pulling $model..."
    ollama pull "$model" &
done

# Wait for pulls to complete
wait

echo "✅ All models pulled successfully!"

# Start BlackRoad wrapper
if [ "$BLACKROAD_MEMORY_ENABLED" = "true" ]; then
    echo "🧠 Starting BlackRoad [MEMORY] wrapper..."
    python3 /app/blackroad-wrapper/server.py &
fi

# Log to memory
if [ -f "/host-home/memory-system.sh" ]; then
    /host-home/memory-system.sh log started "ollama-runtime" \
        "Ollama runtime started with models: ${MODELS_TO_PULL[*]}" \
        "ai-runtime,ollama"
fi

# Keep container running
echo "🎯 BlackRoad AI Ollama Runtime is online!"
wait $OLLAMA_PID
