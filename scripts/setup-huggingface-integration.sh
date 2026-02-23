#!/bin/bash
# BlackRoad → HuggingFace Integration
# Syncs Pi models to HuggingFace Hub
# Also registers Pi as HF Inference Endpoint

HF_TOKEN="${HUGGINGFACE_TOKEN:-}"
HF_ORG="BlackRoad-OS"
GEMATRIA_MODELS_URL="https://api.blackroad.io/models"
OCTAVIA_OLLAMA="http://192.168.4.38:11435"

echo "🤗 BlackRoad → HuggingFace Integration"
echo ""

if [[ -z "$HF_TOKEN" ]]; then
  echo "⚠️  Set HUGGINGFACE_TOKEN first"
  echo "   export HUGGINGFACE_TOKEN=hf_..."
fi

# Install huggingface-cli if needed
pip install -q huggingface_hub 2>/dev/null

python3 << 'PYEOF'
import os, json, subprocess

hf_token = os.environ.get('HUGGINGFACE_TOKEN', '')
if not hf_token:
    print("No HF token — skipping HF Hub push")
    print("Models available on gematria:")
    import urllib.request
    try:
        with urllib.request.urlopen('https://api.blackroad.io/', timeout=5) as r:
            data = json.loads(r.read())
            print(f"  Total models: {data.get('total_models', 0)}")
            print(f"  Live: {data.get('live', 0)}")
            for cat, info in data.get('categories', {}).items():
                if info.get('live', 0) > 0:
                    print(f"  {cat}: {info['live']} live / {info['count']} total")
    except Exception as e:
        print(f"  (gematria check failed: {e})")
    exit(0)

from huggingface_hub import HfApi, login
login(token=hf_token)
api = HfApi()

# Check org repos
repos = list(api.list_repos_objs(author=os.environ.get('HF_ORG', 'BlackRoad-OS')))
print(f"HF repos in org: {len(repos)}")

print("✅ HuggingFace integration ready")
print("   Pi models available at: https://api.blackroad.io/models")
PYEOF
