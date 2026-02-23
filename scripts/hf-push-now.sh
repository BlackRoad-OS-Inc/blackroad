#!/bin/bash
# Run this with: HUGGINGFACE_TOKEN=hf_... bash scripts/hf-push-now.sh
# OR set the token in GitHub secrets as HUGGINGFACE_TOKEN

TOKEN="${HUGGINGFACE_TOKEN:-$HF_TOKEN}"
if [ -z "$TOKEN" ]; then
  echo "❌ Set HUGGINGFACE_TOKEN=hf_... then re-run"
  echo "   Get token at: https://huggingface.co/settings/tokens"
  exit 1
fi

echo "🤗 Pushing to HuggingFace..."
python3 - << PYEOF
from huggingface_hub import HfApi, create_repo
import os

token = "$TOKEN"
api = HfApi(token=token)

# Confirm identity
try:
    me = api.whoami()
    print(f"Logged in as: {me.get('name')}")
except:
    print("Auth failed")
    exit(1)

repo_id = "BlackRoad-AI/blackroad-model-registry"
create_repo(repo_id, repo_type="dataset", private=False, exist_ok=True, token=token)
api.upload_folder(
    folder_path="/tmp/hf-blackroad-registry",
    repo_id=repo_id,
    repo_type="dataset",
    token=token
)
print(f"✅ Published: https://huggingface.co/datasets/{repo_id}")
PYEOF
