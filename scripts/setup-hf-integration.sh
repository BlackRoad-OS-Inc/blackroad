#!/bin/bash
# HuggingFace Pi Agent Integration
# Registers Pi fleet as HF inference endpoints + deploys HF_TOKEN

HF_TOKEN="${HF_TOKEN:-$(cat ~/.blackroad/secrets/hf_token 2>/dev/null)}"

echo "🤗 Setting up HuggingFace integration on Pi fleet..."

for NODE in octavia cecilia aria; do
  echo ""
  echo "→ $NODE:"
  ssh -o ConnectTimeout=5 $NODE "
    # Deploy HF token
    mkdir -p ~/.blackroad/secrets
    echo '$HF_TOKEN' > ~/.blackroad/secrets/hf_token
    chmod 600 ~/.blackroad/secrets/hf_token
    
    # Install huggingface_hub if Python available
    if command -v pip3 &>/dev/null; then
      pip3 install huggingface_hub --quiet 2>/dev/null && echo '  ✅ huggingface_hub installed'
    fi
    
    # Register as inference endpoint
    cat > ~/.blackroad/hf-endpoint.json << HFEOF
{
  \"node\": \"\$(hostname)\",
  \"ip\": \"\$(hostname -I | awk '{print \$1}')\",
  \"role\": \"inference-endpoint\",
  \"models\": [\"qwen2.5:7b\", \"deepseek-r1:7b\", \"llama3.2:3b\"],
  \"ollama_url\": \"http://localhost:11434\",
  \"registered\": \"\$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
}
HFEOF
    echo '  ✅ HF endpoint registered on \$(hostname)'
  " 2>&1 || echo "  ❌ $NODE unreachable"
done

echo ""
echo "✅ HuggingFace integration complete"
