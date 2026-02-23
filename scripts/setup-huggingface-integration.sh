#!/bin/bash
# BlackRoad HuggingFace Integration
# Pushes gematria model registry to HF Hub under BlackRoad-AI org

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤗 BlackRoad HuggingFace Integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOKEN="${HUGGINGFACE_TOKEN:-$(cat ~/.huggingface/token 2>/dev/null)}"
if [ -z "$TOKEN" ]; then
  echo -e "${RED}❌ Set HUGGINGFACE_TOKEN first:${NC}"
  echo "   export HUGGINGFACE_TOKEN=hf_..."
  echo "   Or: python3 -c \"from huggingface_hub import login; login()\""
  exit 1
fi

echo -e "${CYAN}Token: ${TOKEN:0:8}...${NC}"

# Create model card for gematria fleet
python3 - << PYEOF
import json, os
from huggingface_hub import HfApi, create_repo, upload_file
from pathlib import Path

token = "$TOKEN"
api = HfApi(token=token)
org = "BlackRoad-AI"

# Load model registry
with open("agents/registry/GEMATRIA-models.json") as f:
    registry = json.load(f)

print(f"Pushing registry: {registry['total']} models")

# Create/update model repo
repo_id = f"{org}/blackroad-model-registry"
try:
    create_repo(repo_id, repo_type="model", private=False, token=token, exist_ok=True)
    print(f"✅ Repo: {repo_id}")
except Exception as e:
    print(f"Repo exists or error: {e}")

# Build README/model card
readme = f"""---
tags:
- blackroad
- multi-modal
- edge-inference
license: proprietary
---

# BlackRoad AI Model Registry

**108 custom models** running on BlackRoad's edge inference fleet.

## Infrastructure
- **gematria** (DigitalOcean): 108 models, 20 live
- **octavia-pi** (Raspberry Pi 5): Ollama, qwen2.5, lucidia
- **alice-pi** (Raspberry Pi): Qdrant vector DB, task queue

## Model Categories
| Category | Count | Live |
|----------|-------|------|
"""
for cat, info in json.load(open("/tmp/gematria-models.json"))["categories"].items():
    readme += f"| {cat} | {info['count']} | {info['live']} |\n"

readme += f"""
## API
```bash
# Via Cloudflare Worker
curl https://blackroad-agents.workers.dev/GEMATRIA/models

# Direct (via tunnel)
curl https://api.blackroad.io/models
```

*© BlackRoad OS, Inc. All rights reserved.*
"""

# Write locally
Path("/tmp/hf-model-card").mkdir(exist_ok=True)
with open("/tmp/hf-model-card/README.md", "w") as f:
    f.write(readme)
with open("/tmp/hf-model-card/registry.json", "w") as f:
    json.dump(registry, f, indent=2)

# Push
try:
    api.upload_folder(
        folder_path="/tmp/hf-model-card",
        repo_id=repo_id,
        repo_type="model",
        token=token
    )
    print(f"✅ Pushed to https://huggingface.co/{repo_id}")
except Exception as e:
    print(f"Push error: {e}")
PYEOF

echo -e "\n${GREEN}✅ HuggingFace integration complete${NC}"
