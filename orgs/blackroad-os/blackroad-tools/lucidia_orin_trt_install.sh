set -euo pipefail

# 0) Paths (edit if you used different ones earlier)
MODEL_DIR="${MODEL_DIR:-models/merged/lucidia-neox-1.4b}"  # merged from your LoRA step
PORT="${PORT:-8000}"

# 1) Minimal Python env on Orin (JetPack already provides CUDA/TensorRT)
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip build-essential

python3 -m venv ~/.venvs/trtllm
source ~/.venvs/trtllm/bin/activate
python -m pip install --upgrade pip

# 2) Install TensorRT-LLM from NVIDIA PyPI (works across versions aligned with your JetPack)
# If you hit a wheel/platform mismatch on Jetson, build from source (see NOTE at bottom).
pip install --extra-index-url https://pypi.nvidia.com tensorrt_llm

# 3) Quick smoke test: this prints the CLI help
trtllm-serve --help >/dev/null

cat <<EOF2

✅ TensorRT-LLM installed.
To serve Lucidia now:
  trtllm-serve "$MODEL_DIR" --port $PORT --host 0.0.0.0

OpenAI endpoint: http://<ORIN_IP>:$PORT/v1
EOF2

Start it (foreground) to confirm:

source ~/.venvs/trtllm/bin/activate
trtllm-serve models/merged/lucidia-neox-1.4b --port 8000 --host 0.0.0.0

Test from your laptop:

curl http://ORIN_IP:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"lucidia-core-neox",
    "messages":[
      {"role":"system","content":"You are Lucidia—trinary logic & Codex Ψ′."},
      {"role":"user","content":"In 2 lines, outline Ψ′_32 contradiction path for breath 𝔅(t)."}
    ],
    "max_tokens": 96
  }'

The LLM API & trtllm-serve can take a local HF-format model path and handle checkpoint conversion + engine build internally; it serves an OpenAI-style API at /v1.
#!/usr/bin/env bash
set -euo pipefail

VENV=${1:-trtllm-venv}
python3 -m venv "$VENV"
source "$VENV/bin/activate"
pip install --upgrade pip
# Install TensorRT-LLM from NVIDIA PyPI
pip install --extra-index-url https://pypi.nvidia.com tensorrt-llm

echo "TensorRT-LLM installed in $VENV"
echo "Run with: trtllm-serve <MODEL_PATH> --port 8000 --host 0.0.0.0"
