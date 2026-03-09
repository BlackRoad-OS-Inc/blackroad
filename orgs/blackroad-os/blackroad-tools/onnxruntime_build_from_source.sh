#!/usr/bin/env bash
set -euo pipefail
# Builds ONNX Runtime GPU for aarch64 Jetson (CUDA/TensorRT via JetPack)
ROOT="${HOME}/src"
VENV_BIN="${VENV_BIN:-$HOME/.venvs/lucidia/bin}"
THREADS="${THREADS:-$(nproc)}"

log(){ printf "\033[1;34m[ort] %s\033[0m\n" "$*"; }
ok(){  printf "\033[1;32m[ort] %s\033[0m\n" "$*"; }
err(){ printf "\033[1;31m[ort] %s\033[0m\n" "$*"; }

command -v cmake >/dev/null || { err "cmake missing"; exit 2; }
command -v git >/dev/null || { err "git missing"; exit 2; }

mkdir -p "$ROOT"; cd "$ROOT"
if [[ ! -d onnxruntime ]]; then
  log "Cloning ONNX Runtime"
  git clone --recursive https://github.com/microsoft/onnxruntime.git
fi
cd onnxruntime
git submodule update --init --recursive

# Jetson-friendly minimal GPU build (TensorRT EP optional; CUDA EP primary)
log "Configuring build (CUDA EP)"
PY_BIN="${VENV_BIN}/python"
${PY_BIN} -m pip install --upgrade pip
${PY_BIN} -m pip install numpy wheel

./build.sh --parallel --config Release \
  --build_shared_lib --enable_pybind --skip_submodule_sync \
  --use_cuda --cuda_home /usr/local/cuda --cudnn_home /usr/lib/aarch64-linux-gnu \
  --update --build --compile_no_warning_as_error \
  --cmake_generator Ninja \
  --build_wheel

WHEEL=$(ls -1 build/Linux/Release/dist/onnxruntime_gpu-*.whl | head -n1)
[[ -f "$WHEEL" ]] || { err "Wheel not found"; exit 3; }
${PY_BIN} -m pip install "$WHEEL"
ok "Installed $WHEEL"
