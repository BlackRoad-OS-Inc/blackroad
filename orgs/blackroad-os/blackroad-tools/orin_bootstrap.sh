#!/usr/bin/env bash
set -euo pipefail

# ---------- CLI FLAGS ----------
BUILD_TRTLLM=0
BUILD_ORTGPU=0
INSTALL_TRITON=0
TRTLLM_BRANCH="${TRTLLM_BRANCH:-main}"
TRTLLM_REPO="${TRTLLM_REPO:-https://github.com/NVIDIA/TensorRT-LLM.git}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-trtllm) BUILD_TRTLLM=1; shift ;;
    --trtllm-branch) TRTLLM_BRANCH="$2"; shift 2 ;;
    --trtllm-repo) TRTLLM_REPO="$2"; shift 2 ;;
    --build-onnxruntime-gpu) BUILD_ORTGPU=1; shift ;;
    --install-triton) INSTALL_TRITON=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---------- Config (override via env) ----------
SWAP_GB="${SWAP_GB:-8}"
UFW_ALLOW_PORTS="${UFW_ALLOW_PORTS:-22,8000,8001}"
SWAP_GB="${SWAP_GB:-8}"                          # swap size in GB (0 to skip)
UFW_ALLOW_PORTS="${UFW_ALLOW_PORTS:-22,8000}"    # comma-separated list
PY_VENV="${PY_VENV:-$HOME/.venvs/lucidia}"
PY_VERSION="${PY_VERSION:-python3}"
TRT_PORT="${TRT_PORT:-8000}"
SERVICE_USER="${SERVICE_USER:-$USER}"
REPO_ROOT="${REPO_ROOT:-$PWD}"
NONINTERACTIVE="${NONINTERACTIVE:-1}"

# ---------- Helpers ----------
log() { printf "\033[1;34m[+] %s\033[0m\n" "$*"; }
ok()  { printf "\033[1;32m[OK] %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m[!] %s\033[0m\n" "$*"; }
err() { printf "\033[1;31m[ERR] %s\033[0m\n" "$*"; }
require_sudo(){ [[ $EUID -ne 0 ]] && sudo -n true 2>/dev/null || true; }
is_cmd(){ command -v "$1" >/dev/null 2>&1; }

# ---------- 0) Preflight ----------
require_sudo
[[ "${NONINTERACTIVE}" == "1" ]] && export DEBIAN_FRONTEND=noninteractive

# ---------- 1) System packages ----------
log "Installing base packages"
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake ninja-build pkg-config \
  ${PY_VERSION}-dev ${PY_VERSION}-venv python3-pip \
# Bootstraps a Jetson Orin with packages and configuration for Lucidia.
set -euo pipefail

# ---------- CLI FLAGS ----------
BUILD_TRTLLM=0
BUILD_ORTGPU=0
INSTALL_TRITON=0
TRTLLM_BRANCH="${TRTLLM_BRANCH:-main}"
TRTLLM_REPO="${TRTLLM_REPO:-https://github.com/NVIDIA/TensorRT-LLM.git}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-trtllm) BUILD_TRTLLM=1; shift ;;
    --trtllm-branch) TRTLLM_BRANCH="$2"; shift 2 ;;
    --trtllm-repo) TRTLLM_REPO="$2"; shift 2 ;;
    --build-onnxruntime-gpu) BUILD_ORTGPU=1; shift ;;
    --install-triton) INSTALL_TRITON=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---------- Config (override via env) ----------
SWAP_GB="${SWAP_GB:-8}"
UFW_ALLOW_PORTS="${UFW_ALLOW_PORTS:-22,8000,8001}"
PY_VENV="${PY_VENV:-$HOME/.venvs/lucidia}"
PY_VERSION="${PY_VERSION:-python3}"
TRT_PORT="${TRT_PORT:-8000}"
SERVICE_USER="${SERVICE_USER:-$USER}"
REPO_ROOT="${REPO_ROOT:-$PWD}"
NONINTERACTIVE="${NONINTERACTIVE:-1}"

# ---------- Helpers ----------
log() { printf "\033[1;34m[+] %s\033[0m\n" "$*"; }
ok()  { printf "\033[1;32m[OK] %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m[!] %s\033[0m\n" "$*"; }
err() { printf "\033[1;31m[ERR] %s\033[0m\n" "$*"; }
require_sudo(){ [[ $EUID -ne 0 ]] && sudo -n true 2>/dev/null || true; }
is_cmd(){ command -v "$1" >/dev/null 2>&1; }

# ---------- 0) Preflight ----------
require_sudo
[[ "${NONINTERACTIVE}" == "1" ]] && export DEBIAN_FRONTEND=noninteractive

# ---------- 1) System packages ----------
log "Installing base packages"
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake ninja-build pkg-config \
  ${PY_VERSION}-dev ${PY_VERSION}-venv python3-pip \
# Bootstraps a Jetson Orin with packages and configuration for Lucidia.
set -euo pipefail

# ---------- CLI FLAGS ----------
BUILD_TRTLLM=0
BUILD_ORTGPU=0
INSTALL_TRITON=0
TRTLLM_BRANCH="${TRTLLM_BRANCH:-main}"
TRTLLM_REPO="${TRTLLM_REPO:-https://github.com/NVIDIA/TensorRT-LLM.git}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-trtllm) BUILD_TRTLLM=1; shift ;;
    --trtllm-branch) TRTLLM_BRANCH="$2"; shift 2 ;;
    --trtllm-repo) TRTLLM_REPO="$2"; shift 2 ;;
    --build-onnxruntime-gpu) BUILD_ORTGPU=1; shift ;;
    --install-triton) INSTALL_TRITON=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# ---------- Config (override via env) ----------
SWAP_GB="${SWAP_GB:-8}"
UFW_ALLOW_PORTS="${UFW_ALLOW_PORTS:-22,8000,8001}"
PY_VENV="${PY_VENV:-$HOME/.venvs/lucidia}"
PY_VERSION="${PY_VERSION:-python3}"
TRT_PORT="${TRT_PORT:-8000}"
SERVICE_USER="${SERVICE_USER:-$USER}"
REPO_ROOT="${REPO_ROOT:-$PWD}"
NONINTERACTIVE="${NONINTERACTIVE:-1}"

# ---------- Helpers ----------
log() { printf "\033[1;34m[+] %s\033[0m\n" "$*"; }
ok()  { printf "\033[1;32m[OK] %s\033[0m\n" "$*"; }
warn(){ printf "\033[1;33m[!] %s\033[0m\n" "$*"; }
err() { printf "\033[1;31m[ERR] %s\033[0m\n" "$*"; }
require_sudo(){ [[ $EUID -ne 0 ]] && sudo -n true 2>/dev/null || true; }
is_cmd(){ command -v "$1" >/dev/null 2>&1; }

# ---------- 0) Preflight ----------
require_sudo

require_sudo() { if [[ $EUID -ne 0 ]]; then sudo -n true 2>/dev/null || { err "Need sudo."; exit 1; }; fi; }
is_cmd() { command -v "$1" >/dev/null 2>&1; }
tegra_detect() {
  if [[ -f /proc/device-tree/model ]] && grep -qi "nvidia jetson" /proc/device-tree/model; then
    ok "Jetson detected: $(tr -d '\0' </proc/device-tree/model)"
  else warn "Could not positively identify Jetson; continuing."; fi
}

# ---------- 0) Preflight ----------
require_sudo
tegra_detect
[[ "${NONINTERACTIVE}" == "1" ]] && export DEBIAN_FRONTEND=noninteractive

# ---------- 1) System packages ----------
log "Installing base packages"
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake ninja-build pkg-config \
  ${PY_VERSION}-dev ${PY_VERSION}-venv python3-pip \
  git git-lfs curl wget jq unzip \
  libopenblas-dev liblapack-dev \
  libssl-dev zlib1g-dev libffi-dev \
  libprotobuf-dev protobuf-compiler \
  libomp-dev \
  htop iotop iftop nvtop sysstat \
  tmux ripgrep fd-find ufw fail2ban \
  ccache mold docker.io docker-compose-plugin
sudo usermod -aG docker "${SERVICE_USER}" || true
ok "Base packages installed"

# ---------- 2) Sysctl & ulimits ----------
sudo tee /etc/sysctl.d/99-lucidia.conf >/dev/null <<'EOF'
  tmux ripgrep fd-find \
  ufw fail2ban \
  mold ccache

# ---------- 2) Sysctl & ulimits ----------
sudo tee /etc/sysctl.d/99-lucidia.conf >/dev/null <<'EOF'
# install gh if missing
if ! command -v gh >/dev/null 2>&1; then
  sudo apt-get install -y gh
fi

# sysctl tuning
sudo tee /etc/sysctl.d/99-lucidia.conf >/dev/null <<'SYSCTL'

# ---------- 2) Sysctl & ulimits ----------
sudo tee /etc/sysctl.d/99-lucidia.conf >/dev/null <<'EOF'
  ccache mold
ok "Base packages installed"

# ---------- 2) Sysctl & ulimits ----------
log "Applying sysctl tuning"
sudo tee /etc/sysctl.d/99-lucidia.conf >/dev/null <<'EOT'
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1024
vm.max_map_count = 1048576
net.core.somaxconn = 4096
net.ipv4.tcp_fin_timeout = 15
EOF
sudo sysctl --system >/dev/null || true
sudo mkdir -p /etc/systemd/system/lucidia-trt.service.d
sudo tee /etc/systemd/system/lucidia-trt.service.d/limits.conf >/dev/null <<'EOF'
[Service]
LimitNOFILE=1048576
EOF
sudo systemctl daemon-reexec || true

# ---------- 3) Swap (optional) ----------
if [[ "${SWAP_GB}" -gt 0 ]] && ! grep -q "/swapfile" /etc/fstab 2>/dev/null; then
  log "Creating ${SWAP_GB}G swapfile"
  sudo fallocate -l "${SWAP_GB}G" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo swapon -a
fi

# ---------- 4) Python venv ----------
log "Creating Python venv at ${PY_VENV}"
mkdir -p "$(dirname "$PY_VENV")"
${PY_VERSION} -m venv "${PY_VENV}"
# shellcheck disable=SC1090
source "${PY_VENV}/bin/activate"
python -m pip install --upgrade pip wheel setuptools

# ---------- 5) Python DL stack ----------
log "Installing DL stack"
python -m pip install "torch>=2.2,<2.5" --extra-index-url https://download.pytorch.org/whl/cu118
python -m pip install \
  transformers datasets accelerate peft trl \
  sentencepiece tokenizers \
  faiss-cpu sentence-transformers \
  onnx onnxruntime-gpu \
  pydantic fastapi uvicorn \
  numpy scipy \
  polygraphy onnx-graphsurgeon \
  autoawq black ruff isort pre-commit

# ---------- 6) TensorRT-LLM (wheel or source) ----------
if python -m pip install --extra-index-url https://pypi.nvidia.com tensorrt_llm ; then
  ok "tensorrt_llm installed (wheel)"
elif [[ "${BUILD_TRTLLM}" -eq 1 ]]; then
  log "Building TensorRT-LLM from source"
  bash "${REPO_ROOT}/tools/trtllm_build_from_source.sh" "${TRTLLM_REPO}" "${TRTLLM_BRANCH}" "${PY_VENV}"
else
  warn "tensorrt_llm wheel unavailable. Use --build-trtllm to build from source."
fi

# ---------- 7) ONNX Runtime GPU (optional from source) ----------
if [[ "${BUILD_ORTGPU}" -eq 1 ]]; then
  log "Building ONNX Runtime GPU from source"
  bash "${REPO_ROOT}/tools/onnxruntime_build_from_source.sh" || { err "ORT build failed"; exit 3; }
  ok "ONNX Runtime GPU built"
fi

# ---------- 8) UFW & fail2ban ----------
IFS=',' read -ra PORTS <<< "${UFW_ALLOW_PORTS}"
for p in "${PORTS[@]}"; do sudo ufw allow "${p}/tcp" || true; done
sudo ufw --force enable
sudo systemctl enable --now fail2ban || true

# ---------- 9) Triton (optional) ----------
if [[ "${INSTALL_TRITON}" -eq 1 ]]; then
  log "Setting up Triton + OpenAI proxy (docker compose)"
  bash "${REPO_ROOT}/tools/triton_setup.sh" || { err "Triton setup failed"; exit 4; }
  ok "Triton compose prepared (serving/triton)"
  warn "Start with: cd serving/triton && docker compose up -d"
fi

ok "Bootstrap complete."
echo "Tip: re-login for docker group to take effect."
SYSCTL
sudo sysctl --system

# systemd ulimits for TensorRT service
sudo mkdir -p /etc/systemd/system/lucidia-trt.service.d
sudo tee /etc/systemd/system/lucidia-trt.service.d/limits.conf >/dev/null <<'EOF'
[Service]
LimitNOFILE=1048576
EOF
sudo systemctl daemon-reexec || true

# ---------- 3) Swap (optional) ----------
if [[ "${SWAP_GB}" -gt 0 ]] && ! grep -q "/swapfile" /etc/fstab 2>/dev/null; then
  log "Creating ${SWAP_GB}G swapfile"
  sudo fallocate -l "${SWAP_GB}G" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo swapon -a
fi

# ---------- 4) Python venv ----------
EOT
sudo sysctl --system >/dev/null || true
ok "Sysctl applied"

log "Preparing systemd NOFILE drop-in"
sudo mkdir -p /etc/systemd/system/lucidia-trt.service.d
sudo tee /etc/systemd/system/lucidia-trt.service.d/limits.conf >/dev/null <<'EOT'
[Service]
LimitNOFILE=1048576
EOT
sudo systemctl daemon-reexec || true

# ---------- 3) Power & thermals ----------
is_cmd nvpmodel && { log "Max perf mode"; sudo nvpmodel -m 0 || true; }
is_cmd jetson_clocks && { log "Locking clocks"; sudo jetson_clocks || true; }

# ---------- 4) Optional swap ----------
if [[ "${SWAP_GB}" -gt 0 ]]; then
  if ! grep -q "/swapfile" /etc/fstab 2>/dev/null; then
    log "Creating ${SWAP_GB}G swapfile"
    sudo fallocate -l "${SWAP_GB}G" /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
    sudo swapon -a
  else ok "Swap already configured"; fi
else warn "Skipping swap creation (SWAP_GB=${SWAP_GB})"; fi

# ---------- 5) Python venv ----------
log "Creating Python venv at ${PY_VENV}"
mkdir -p "$(dirname "$PY_VENV")"
${PY_VERSION} -m venv "${PY_VENV}"
# shellcheck disable=SC1090
source "${PY_VENV}/bin/activate"
python -m pip install --upgrade pip wheel setuptools

# ---------- 5) Python DL stack ----------
log "Installing DL stack"
ok "Venv ready"

# ---------- 6) Python DL stack ----------
log "Installing Python DL stack"
python -m pip install "torch>=2.2,<2.5" --extra-index-url https://download.pytorch.org/whl/cu118
python -m pip install \
  transformers datasets accelerate peft trl \
  sentencepiece tokenizers \
  faiss-cpu sentence-transformers \
  onnx onnxruntime-gpu \
  pydantic fastapi uvicorn \
  numpy scipy \
  polygraphy onnx-graphsurgeon \
  autoawq black ruff isort pre-commit

# ---------- 6) TensorRT-LLM (wheel or source) ----------
if python -m pip install --extra-index-url https://pypi.nvidia.com tensorrt_llm ; then
  ok "tensorrt_llm installed (wheel)"
elif [[ "${BUILD_TRTLLM}" -eq 1 ]]; then
  log "Building TensorRT-LLM from source"
  bash "${REPO_ROOT}/tools/trtllm_build_from_source.sh" "${TRTLLM_REPO}" "${TRTLLM_BRANCH}" "${PY_VENV}"
else
  warn "tensorrt_llm wheel unavailable. Use --build-trtllm to build from source."
fi

# ---------- 7) ONNX Runtime GPU (optional from source) ----------
if [[ "${BUILD_ORTGPU}" -eq 1 ]]; then
  log "Building ONNX Runtime GPU from source"
  bash "${REPO_ROOT}/tools/onnxruntime_build_from_source.sh" || { err "ORT build failed"; exit 3; }
  ok "ONNX Runtime GPU built"
fi

# ---------- 8) UFW & fail2ban ----------
IFS=',' read -ra PORTS <<< "${UFW_ALLOW_PORTS}"
for p in "${PORTS[@]}"; do sudo ufw allow "${p}/tcp" || true; done
sudo ufw --force enable
sudo systemctl enable --now fail2ban || true

# ---------- 9) Triton (optional) ----------
if [[ "${INSTALL_TRITON}" -eq 1 ]]; then
  log "Setting up Triton + OpenAI proxy (docker compose)"
  bash "${REPO_ROOT}/tools/triton_setup.sh" || { err "Triton setup failed"; exit 4; }
  ok "Triton compose prepared (serving/triton)"
  warn "Start with: cd serving/triton && docker compose up -d"
fi

ok "Bootstrap complete."
echo "Tip: re-login for docker group to take effect."
sudo tee /etc/systemd/system/lucidia-trt.service.d/limits.conf >/dev/null <<'LIMITS'
sudo mkdir -p /etc/systemd/system/lucidia-trt.service.d
sudo tee /etc/systemd/system/lucidia-trt.service.d/limits.conf >/dev/null <<'EOF'
[Service]
LimitNOFILE=1048576
EOF
sudo systemctl daemon-reexec || true

# ---------- 3) Swap (optional) ----------
if [[ "${SWAP_GB}" -gt 0 ]] && ! grep -q "/swapfile" /etc/fstab 2>/dev/null; then
  log "Creating ${SWAP_GB}G swapfile"
  sudo fallocate -l "${SWAP_GB}G" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo swapon -a
fi

# ---------- 4) Python venv ----------
log "Creating Python venv at ${PY_VENV}"
mkdir -p "$(dirname "$PY_VENV")"
${PY_VERSION} -m venv "${PY_VENV}"
# shellcheck disable=SC1090
source "${PY_VENV}/bin/activate"
python -m pip install --upgrade pip wheel setuptools

# ---------- 5) Python DL stack ----------
log "Installing DL stack"
python -m pip install "torch>=2.2,<2.5" --extra-index-url https://download.pytorch.org/whl/cu118
python -m pip install \
  transformers datasets accelerate peft trl \
  sentencepiece tokenizers \
  faiss-cpu sentence-transformers \
  onnx onnxruntime-gpu \
  pydantic fastapi uvicorn \
  numpy scipy \
  polygraphy onnx-graphsurgeon \
  autoawq black ruff isort pre-commit

# ---------- 6) TensorRT-LLM (wheel or source) ----------
if python -m pip install --extra-index-url https://pypi.nvidia.com tensorrt_llm ; then
  ok "tensorrt_llm installed (wheel)"
elif [[ "${BUILD_TRTLLM}" -eq 1 ]]; then
  log "Building TensorRT-LLM from source"
  bash "${REPO_ROOT}/tools/trtllm_build_from_source.sh" "${TRTLLM_REPO}" "${TRTLLM_BRANCH}" "${PY_VENV}"
else
  warn "tensorrt_llm wheel unavailable. Use --build-trtllm to build from source."
fi

# ---------- 7) ONNX Runtime GPU (optional from source) ----------
if [[ "${BUILD_ORTGPU}" -eq 1 ]]; then
  log "Building ONNX Runtime GPU from source"
  bash "${REPO_ROOT}/tools/onnxruntime_build_from_source.sh" || { err "ORT build failed"; exit 3; }
  ok "ONNX Runtime GPU built"
fi

# ---------- 8) UFW & fail2ban ----------
IFS=',' read -ra PORTS <<< "${UFW_ALLOW_PORTS}"
for p in "${PORTS[@]}"; do sudo ufw allow "${p}/tcp" || true; done
sudo ufw --force enable
sudo systemctl enable --now fail2ban || true

# ---------- 9) Triton (optional) ----------
if [[ "${INSTALL_TRITON}" -eq 1 ]]; then
  log "Setting up Triton + OpenAI proxy (docker compose)"
  bash "${REPO_ROOT}/tools/triton_setup.sh" || { err "Triton setup failed"; exit 4; }
  ok "Triton compose prepared (serving/triton)"
  warn "Start with: cd serving/triton && docker compose up -d"
fi

ok "Bootstrap complete."
echo "Tip: re-login for docker group to take effect."
  autoawq \
  black ruff isort pre-commit
ok "DL stack installed"

# ---------- 7) TensorRT-LLM (wheel OR source) ----------
if [[ "${BUILD_TRTLLM}" -eq 0 ]]; then
  log "Attempting TensorRT-LLM wheel install"
  if python -m pip install --extra-index-url https://pypi.nvidia.com tensorrt_llm ; then
    ok "tensorrt_llm installed from wheel"
  else
    warn "Wheel not available. Re-run with --build-trtllm to build from source."
  fi
else
  log "Building TensorRT-LLM from source (branch: ${TRTLLM_BRANCH})"
  bash "${REPO_ROOT}/tools/trtllm_build_from_source.sh" "${TRTLLM_REPO}" "${TRTLLM_BRANCH}" "${PY_VENV}"
  ok "TensorRT-LLM built & installed from source"
fi

# Smoke check
if trtllm-serve --help >/dev/null 2>&1; then ok "trtllm-serve available"; else warn "trtllm-serve not on PATH"; fi

# ---------- 8) Monitoring & ops ----------
log "Installing jetson-stats (jtop)"
sudo -H "${PY_VENV}/bin/pip" install jetson-stats || true
is_cmd jtop && ok "jtop available" || warn "jtop not in PATH yet"

# ---------- 9) Firewall + fail2ban ----------
log "Configuring UFW"
IFS=',' read -ra PORTS <<< "${UFW_ALLOW_PORTS}"
for p in "${PORTS[@]}"; do sudo ufw allow "${p}/tcp" || true; done
sudo ufw --force enable
ok "UFW enabled (${UFW_ALLOW_PORTS})"

log "Enabling fail2ban"
sudo systemctl enable --now fail2ban || true

# ---------- 10) GitHub CLI (optional) ----------
is_cmd gh || { warn "Installing GitHub CLI"; sudo apt-get install -y gh || true; }

# ---------- 11) Pre-commit (if repo) ----------
if [[ -d "${REPO_ROOT}/.git" && -f "${REPO_ROOT}/.pre-commit-config.yaml" ]]; then
  log "Installing pre-commit hook"
  (cd "${REPO_ROOT}" && "${PY_VENV}/bin/pre-commit" install) || true
fi

# ---------- 12) Service template (don’t overwrite existing) ----------
SERVICE_DST="/etc/systemd/system/lucidia-trt.service"
TEMPLATE_SRC="${REPO_ROOT}/tools/lucidia-trt.service.template"
if [[ -f "${TEMPLATE_SRC}" && ! -f "${SERVICE_DST}" ]]; then
  log "Installing lucidia-trt.service template"
  sudo cp "${TEMPLATE_SRC}" "${SERVICE_DST}"
  sudo systemctl daemon-reload
  warn "Edit ${SERVICE_DST} paths/user, then: sudo systemctl enable --now lucidia-trt"
fi

# ---------- Summary ----------
echo
ok "Bootstrap complete."
echo "Next:"
echo "  1) Ensure merged model dir exists (e.g., models/merged/lucidia-neox-1.4b)"
echo "  2) Edit /etc/systemd/system/lucidia-trt.service (paths, user)"
echo "  3) sudo systemctl enable --now lucidia-trt"
echo "  4) Test:"
echo "     curl http://$(hostname -I | awk '{print $1}'):${TRT_PORT}/v1/chat/completions -H 'Content-Type: application/json' -d '{\"model\":\"lucidia-core-neox\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}'"
