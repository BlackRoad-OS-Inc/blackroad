#!/usr/bin/env bash
set -euo pipefail
REPO_URL="${1:-https://github.com/NVIDIA/TensorRT-LLM.git}"
BRANCH="${2:-main}"
VENV_PATH="${3:-$HOME/.venvs/lucidia}"

log(){ printf "\033[1;34m[trtllm] %s\033[0m\n" "$*"; }
ok(){  printf "\033[1;32m[trtllm] %s\033[0m\n" "$*"; }
warn(){printf "\033[1;33m[trtllm] %s\033[0m\n" "$*"; }
err(){ printf "\033[1;31m[trtllm] %s\033[0m\n" "$*"; }

# Preconditions
command -v nvcc >/dev/null 2>&1 || warn "nvcc not found; ensure JetPack/CUDA toolchain present."
command -v cmake >/dev/null 2>&1 || { err "cmake missing"; exit 2; }
command -v ninja >/dev/null 2>&1 || { err "ninja missing"; exit 2; }

# Activate venv if present
if [[ -d "$VENV_PATH" ]]; then
  # shellcheck disable=SC1090
  source "$VENV_PATH/bin/activate"
fi

# Clone
WORKDIR="${HOME}/src"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"
if [[ ! -d TensorRT-LLM ]]; then
  log "Cloning ${REPO_URL}"
  git clone "${REPO_URL}" TensorRT-LLM
fi
cd TensorRT-LLM
git fetch origin "${BRANCH}"
git checkout "${BRANCH}"
git submodule update --init --recursive

# Python deps
log "Installing Python requirements"
pip install --upgrade pip wheel setuptools
pip install -r requirements.txt

# Build wheel
log "Building TensorRT-LLM wheel"
python setup.py bdist_wheel
WHEEL=$(ls -1 dist/tensorrt_llm-*.whl | tail -n1)
[[ -f "${WHEEL}" ]] || { err "Wheel not built"; exit 3; }

# Install
log "Installing ${WHEEL}"
pip install "${WHEEL}"
ok "Installed TensorRT-LLM from source"

# Sanity
if trtllm-serve --help >/dev/null 2>&1; then ok "trtllm-serve OK"; else warn "trtllm-serve not found in PATH"; fi
