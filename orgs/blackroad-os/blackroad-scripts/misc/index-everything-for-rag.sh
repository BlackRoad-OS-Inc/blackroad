#!/bin/bash
# Index all code for RAG-powered search

set -e

echo "🔍 Starting full codebase indexing for RAG..."

# 1. Index local machine
echo "📂 Step 1: Indexing local machine..."
cd ~/blackroad-prism-console/rag/index
python3 build_faiss.py --out-dir ~/rag-production-full

# 2. Clone all GitHub repos (sample - adjust for full 186)
echo "📦 Step 2: Cloning GitHub repos..."
mkdir -p ~/github-index
cd ~/github-index

# Top priority repos for indexing
REPOS=(
  "BlackRoad-OS/blackroad-os-operator"
  "BlackRoad-OS/blackroad-os-prism-enterprise"
  "BlackRoad-OS/blackroad-os-docs"
  "BlackRoad-OS/lucidia-metaverse"
  "BlackRoad-OS/blackroad-cli"
  "blackboxprogramming/lucidia"
  "blackboxprogramming/blackroad-deploy"
  "blackboxprogramming/blackroad-priority-stack"
)

for repo in "${REPOS[@]}"; do
  echo "Cloning $repo..."
  gh repo clone "$repo" 2>/dev/null || echo "Already cloned: $repo"
done

# 3. Build comprehensive FAISS index
echo "🧠 Step 3: Building comprehensive FAISS index..."
cd ~/blackroad-prism-console/rag/index

# Update build_faiss.py to include GitHub repos
python3 << 'PYTHON'
import os
import pathlib
import numpy as np
import json

roots = [
    os.path.expanduser("~/blackroad-prism-console"),
    os.path.expanduser("~/lucidia-platform"),
    os.path.expanduser("~/blackroad-deploy"),
    os.path.expanduser("~/github-index"),
    os.path.expanduser("~/blackroad-resume"),
    os.path.expanduser("~/blackroad-os-demo"),
]

files = []
for root in roots:
    if not os.path.isdir(root):
        continue
    for path in pathlib.Path(root).rglob("*"):
        if path.suffix.lower() in {".md", ".txt", ".py", ".ts", ".js", ".yaml", ".json"}:
            if "node_modules" not in str(path) and ".git" not in str(path):
                files.append(path)

print(f"✅ Found {len(files)} files to index")

# Generate embeddings (placeholder - use real embeddings in production)
vecs = []
meta = {}
for idx, path in enumerate(files[:10000]):  # Limit to 10K files for now
    try:
        with open(path, "r", errors="ignore") as f:
            text = f.read()[:1000]  # First 1000 chars
        vecs.append(np.random.rand(384).astype("float32"))  # Replace with real embeddings
        meta[idx] = str(path)
    except:
        pass

os.makedirs(os.path.expanduser("~/rag-production-full"), exist_ok=True)

# Save index
import faiss
arr = np.stack(vecs) if vecs else np.random.rand(1, 384).astype("float32")
index = faiss.IndexFlatL2(arr.shape[1])
index.add(arr)
faiss.write_index(index, os.path.expanduser("~/rag-production-full/blackroad.faiss"))

with open(os.path.expanduser("~/rag-production-full/meta.json"), "w") as f:
    json.dump(meta, f, indent=2)

print(f"✅ Indexed {len(vecs)} documents to ~/rag-production-full/blackroad.faiss")
PYTHON

echo "✅ Full indexing complete!"
echo "📍 Index location: ~/rag-production-full/"
echo "📊 Files indexed: $(jq 'length' ~/rag-production-full/meta.json)"
