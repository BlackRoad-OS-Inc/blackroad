#!/usr/bin/env bash
set -euo pipefail

# Creates a Triton model repo skeleton + docker compose + OpenAI proxy.
REPO_ROOT="${REPO_ROOT:-$PWD}"
SERVE_DIR="${REPO_ROOT}/serving/triton"
MODEL_REPO="${SERVE_DIR}/model_repository"
PROXY_DIR="${SERVE_DIR}/proxy"
PORT_HTTP="${PORT_HTTP:-8001}"   # Triton HTTP
PORT_PROXY="${PORT_PROXY:-8000}" # OpenAI proxy

mkdir -p "${MODEL_REPO}/lucidia_trt/1" "${PROXY_DIR}"

# Minimal TRT-LLM backend model (expects an engine or HF dir at runtime; adjust path if you prebuild)
cat > "${MODEL_REPO}/lucidia_trt/config.pbtxt" <<'EOF'
name: "lucidia_trt"
platform: "tensorrt_llm"
max_batch_size: 1
dynamic_batching { preferred_batch_size: [ 1 ] max_queue_delay_microseconds: 1000 }
instance_group [{ kind: KIND_GPU, count: 1 }]
# NOTE: Point parameters to your engine/checkpoint via model config or environment.
EOF

# Docker Compose for Triton + proxy
cat > "${SERVE_DIR}/docker-compose.yml" <<'EOF'
version: "3.8"
services:
  triton:
    image: nvcr.io/nvidia/tritonserver:23.10-py3
    command: [
      "tritonserver",
      "--model-repository=/models",
      "--exit-on-error=false",
      "--allow-http=true",
      "--http-port=${PORT_HTTP}",
      "--http-thread-count=4"
    ]
    network_mode: host
    restart: unless-stopped
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=all
    volumes:
      - ./model_repository:/models:ro

  openai-proxy:
    build: ./proxy
    network_mode: host
    restart: unless-stopped
    environment:
      - TRITON_HTTP_URL=http://127.0.0.1:${PORT_HTTP}
      - OPENAI_MODEL=lucidia-core-neox
      - PORT=${PORT_PROXY}
EOF

# Tiny OpenAI-compatible proxy → calls Triton HTTP v2
cat > "${PROXY_DIR}/openai_proxy.py" <<'EOF'
import os, time, json, requests
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

TRITON = os.getenv("TRITON_HTTP_URL", "http://127.0.0.1:8001")
MODEL  = os.getenv("OPENAI_MODEL", "lucidia-core-neox")
PORT   = int(os.getenv("PORT", "8000"))

class Msg(BaseModel):
    role: str
    content: str

class ChatReq(BaseModel):
    model: Optional[str] = MODEL
    messages: List[Msg]
    max_tokens: int = 128
    temperature: float = 0.7
    top_p: float = 0.9

app = FastAPI(title="Lucidia OpenAI Proxy")

@app.post("/v1/chat/completions")
def chat(req: ChatReq):
    prompt = "\n".join([f"{m.role.upper()}: {m.content}" for m in req.messages])
    # Minimalistic: send prompt as input to Triton huggingface-like backend if configured
    # Here we just echo to show wiring; replace with real Triton text generation call.
    text = f"[lucidia@triton echo] {prompt[:200]}"
    return {
        "id":"chatcmpl-lucidia",
        "object":"chat.completion",
        "choices":[{"index":0,"message":{"role":"assistant","content":text},"finish_reason":"stop"}],
        "created": int(time.time())
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT)
EOF

# Proxy Dockerfile
cat > "${PROXY_DIR}/Dockerfile" <<'EOF'
FROM python:3.11-slim
RUN pip install fastapi uvicorn requests pydantic
WORKDIR /app
COPY openai_proxy.py /app/openai_proxy.py
EXPOSE 8000
CMD ["uvicorn","openai_proxy:app","--host","0.0.0.0","--port","8000"]
EOF

echo "Prepared Triton model repo at: ${MODEL_REPO}"
echo "Edit config.pbtxt and mount your TRT-LLM engine/checkpoint as needed."
echo "Start with:  cd ${SERVE_DIR} && docker compose up -d"
