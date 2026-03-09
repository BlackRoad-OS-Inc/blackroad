#!/bin/bash
# Pull all BlackRoad-required models

models=(
  "mistral:7b"
  "codellama:34b"
  "llama3:8b"
  "phi3:mini"
)

for model in "${models[@]}"; do
  echo "Pulling $model..."
  ollama pull "$model"
done

echo "All models pulled successfully!"
