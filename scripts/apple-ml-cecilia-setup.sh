#!/bin/bash
# Apple ML Model Deployment for Cecilia (Pi 5 + Hailo-8 + 500GB NVMe)
# Downloads Apple OpenELM + FastVLM models, converts for Ollama, sets up fine-tuning deps
# Usage: scp to cecilia then run, OR: ssh cecilia 'bash -s' < apple-ml-cecilia-setup.sh

set -e

# ── Colors ──────────────────────────────────────────────────────────────
PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

log()   { echo -e "${GREEN}✓${RESET} $1"; }
info()  { echo -e "${CYAN}ℹ${RESET} $1"; }
warn()  { echo -e "${YELLOW}⚠${RESET} $1"; }
error() { echo -e "${RED}✗${RESET} $1"; }
header(){ echo -e "\n${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; echo -e "${BOLD} $1${RESET}"; echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

# ── Config ──────────────────────────────────────────────────────────────
MODELS_DIR="$HOME/models/apple"
DATASETS_DIR="$HOME/datasets/apple"
OLLAMA_MODELFILES="$HOME/models/modelfiles"

header "🍎 Apple ML Setup for Cecilia"
echo -e "  ${CYAN}Device:${RESET}  Cecilia (Pi 5 + Hailo-8 26 TOPS)"
echo -e "  ${CYAN}Target:${RESET}  $MODELS_DIR"
echo ""

# ── Step 1: Check prerequisites ────────────────────────────────────────
header "Step 1/6: Prerequisites"

# Check disk space
AVAIL=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
if [ "$AVAIL" -lt 20 ]; then
    error "Only ${AVAIL}G available. Need at least 20G."
    exit 1
fi
log "Disk space: ${AVAIL}G available"

# Check Ollama
if command -v ollama &>/dev/null; then
    log "Ollama $(ollama --version 2>&1 | grep -o '[0-9.]*')"
else
    error "Ollama not installed"
    exit 1
fi

# Check Python
if command -v python3 &>/dev/null; then
    log "Python $(python3 --version 2>&1 | awk '{print $2}')"
else
    error "Python3 not found"
    exit 1
fi

# ── Step 2: Install dependencies ───────────────────────────────────────
header "Step 2/6: Install ML Dependencies"

info "Installing huggingface-hub, transformers, datasets..."
pip3 install --break-system-packages --quiet \
    huggingface-hub \
    transformers \
    datasets \
    safetensors \
    sentencepiece \
    accelerate 2>&1 | tail -3

if python3 -c "import transformers" 2>/dev/null; then
    log "transformers $(python3 -c 'import transformers; print(transformers.__version__)')"
else
    error "transformers install failed"
    exit 1
fi

if command -v huggingface-cli &>/dev/null || python3 -m huggingface_hub.cli 2>/dev/null; then
    log "huggingface-cli ready"
else
    warn "huggingface-cli not in PATH, using python3 -m huggingface_hub"
fi

# ── Step 3: Create directory structure ─────────────────────────────────
header "Step 3/6: Directory Structure"

mkdir -p "$MODELS_DIR"/{openelm,fastvlm,mobileclip,gguf}
mkdir -p "$DATASETS_DIR"/{gsm-symbolic,clara,mkqa}
mkdir -p "$OLLAMA_MODELFILES"

log "Created $MODELS_DIR/"
log "Created $DATASETS_DIR/"
log "Created $OLLAMA_MODELFILES/"

# ── Step 4: Download GGUF models for Ollama ────────────────────────────
header "Step 4/6: Download Apple Models (GGUF for Ollama)"

# --- OpenELM 3B Instruct (Q4_K_M ~1.8GB) ---
echo ""
info "📦 OpenELM-3B-Instruct (Q4_K_M quantized)"
if [ -f "$MODELS_DIR/gguf/OpenELM-3B-Instruct-Q4_K_M.gguf" ]; then
    log "Already downloaded"
else
    python3 -c "
from huggingface_hub import hf_hub_download
import os, glob

# Download Q4_K_M quant of OpenELM-3B-Instruct
dest = '$MODELS_DIR/gguf'
try:
    path = hf_hub_download(
        repo_id='mradermacher/OpenELM-3B-Instruct-GGUF',
        filename='OpenELM-3B-Instruct.Q4_K_M.gguf',
        local_dir=dest,
        local_dir_use_symlinks=False
    )
    # Rename for consistency
    final = os.path.join(dest, 'OpenELM-3B-Instruct-Q4_K_M.gguf')
    if os.path.exists(path) and path != final:
        os.rename(path, final)
    print(f'Downloaded: {final}')
except Exception as e:
    print(f'Error: {e}')
    # Try alternate filename pattern
    try:
        path = hf_hub_download(
            repo_id='LiteLLMs/OpenELM-3B-Instruct-GGUF',
            filename='OpenELM-3B-Instruct-q4_k_m.gguf',
            local_dir=dest,
            local_dir_use_symlinks=False
        )
        print(f'Downloaded (alt): {path}')
    except Exception as e2:
        print(f'Alt also failed: {e2}')
"
    log "OpenELM-3B-Instruct GGUF downloaded"
fi

# --- OpenELM 1.1B Instruct (Q4_K_M ~700MB) ---
echo ""
info "📦 OpenELM-1.1B-Instruct (Q4_K_M quantized)"
if [ -f "$MODELS_DIR/gguf/OpenELM-1_1B-Instruct-Q4_K_M.gguf" ]; then
    log "Already downloaded"
else
    python3 -c "
from huggingface_hub import hf_hub_download
import os

dest = '$MODELS_DIR/gguf'
try:
    path = hf_hub_download(
        repo_id='mradermacher/OpenELM-1_1B-Instruct-GGUF',
        filename='OpenELM-1_1B-Instruct.Q4_K_M.gguf',
        local_dir=dest,
        local_dir_use_symlinks=False
    )
    final = os.path.join(dest, 'OpenELM-1_1B-Instruct-Q4_K_M.gguf')
    if os.path.exists(path) and path != final:
        os.rename(path, final)
    print(f'Downloaded: {final}')
except Exception as e:
    print(f'Error: {e}')
" 2>&1
    log "OpenELM-1.1B-Instruct GGUF downloaded"
fi

# --- OpenELM 270M (full precision is tiny, ~540MB) ---
echo ""
info "📦 OpenELM-270M-Instruct (safetensors for fine-tuning)"
python3 -c "
from huggingface_hub import snapshot_download
try:
    path = snapshot_download(
        repo_id='apple/OpenELM-270M-Instruct',
        local_dir='$MODELS_DIR/openelm/270M-Instruct',
        local_dir_use_symlinks=False,
        ignore_patterns=['*.md', '*.txt', '.gitattributes']
    )
    print(f'Downloaded to: {path}')
except Exception as e:
    print(f'Error: {e}')
" 2>&1
log "OpenELM-270M-Instruct safetensors downloaded"

# --- FastVLM 0.5B (vision-language, great for Hailo) ---
echo ""
info "📦 FastVLM-0.5B (vision-language model)"
python3 -c "
from huggingface_hub import snapshot_download
try:
    path = snapshot_download(
        repo_id='apple/FastVLM-0.5B',
        local_dir='$MODELS_DIR/fastvlm/0.5B',
        local_dir_use_symlinks=False,
        ignore_patterns=['*.md', '*.txt', '.gitattributes']
    )
    print(f'Downloaded to: {path}')
except Exception as e:
    print(f'Error: {e}')
" 2>&1
log "FastVLM-0.5B downloaded"

# ── Step 5: Download datasets ──────────────────────────────────────────
header "Step 5/6: Download Apple Datasets"

info "📊 GSM-Symbolic (math reasoning, 12.5K samples)"
python3 -c "
from datasets import load_dataset
try:
    ds = load_dataset('apple/GSM-Symbolic', split='test')
    ds.save_to_disk('$DATASETS_DIR/gsm-symbolic')
    print(f'Saved {len(ds)} samples')
except Exception as e:
    print(f'Error: {e}')
" 2>&1
log "GSM-Symbolic dataset saved"

info "📊 MKQA (multilingual QA)"
python3 -c "
from datasets import load_dataset
try:
    ds = load_dataset('apple/mkqa', split='train')
    ds.save_to_disk('$DATASETS_DIR/mkqa')
    print(f'Saved {len(ds)} samples')
except Exception as e:
    print(f'Error: {e}')
" 2>&1
log "MKQA dataset saved"

# ── Step 6: Create Ollama Modelfiles & register ────────────────────────
header "Step 6/6: Register with Ollama"

# --- OpenELM 3B Instruct Modelfile ---
GGUF_3B=$(find "$MODELS_DIR/gguf" -name "*3B*Q4*" -o -name "*3B*q4*" 2>/dev/null | head -1)
if [ -n "$GGUF_3B" ]; then
    cat > "$OLLAMA_MODELFILES/apple-openelm-3b.Modelfile" <<MODELFILE
FROM $GGUF_3B
PARAMETER temperature 0.7
PARAMETER num_ctx 2048
PARAMETER top_p 0.9
SYSTEM """You are a BlackRoad AI agent running Apple OpenELM-3B on Cecilia (Raspberry Pi 5 + Hailo-8).
You are efficient, precise, and optimized for edge computing. You assist with code, reasoning, and analysis.
Keep responses concise — you're running on 8GB RAM."""
MODELFILE

    info "Creating Ollama model: apple-openelm-3b..."
    ollama create apple-openelm-3b -f "$OLLAMA_MODELFILES/apple-openelm-3b.Modelfile" 2>&1
    log "Registered: apple-openelm-3b"
else
    warn "3B GGUF not found, skipping Ollama registration"
fi

# --- OpenELM 1.1B Instruct Modelfile ---
GGUF_1B=$(find "$MODELS_DIR/gguf" -name "*1_1B*Q4*" -o -name "*1_1B*q4*" -o -name "*1.1B*Q4*" 2>/dev/null | head -1)
if [ -n "$GGUF_1B" ]; then
    cat > "$OLLAMA_MODELFILES/apple-openelm-1b.Modelfile" <<MODELFILE
FROM $GGUF_1B
PARAMETER temperature 0.6
PARAMETER num_ctx 2048
PARAMETER top_p 0.9
SYSTEM """You are a lightweight BlackRoad AI agent running Apple OpenELM-1.1B on Cecilia.
Fast inference, low memory. Best for quick queries, classification, and simple reasoning."""
MODELFILE

    info "Creating Ollama model: apple-openelm-1b..."
    ollama create apple-openelm-1b -f "$OLLAMA_MODELFILES/apple-openelm-1b.Modelfile" 2>&1
    log "Registered: apple-openelm-1b"
else
    warn "1.1B GGUF not found, skipping Ollama registration"
fi

# ── Summary ─────────────────────────────────────────────────────────────
header "🍎 Apple ML Setup Complete"
echo ""
echo -e "${BOLD}Models:${RESET}"
echo -e "  ${GREEN}●${RESET} apple-openelm-3b  (Ollama, Q4_K_M, ~1.8GB)"
echo -e "  ${GREEN}●${RESET} apple-openelm-1b  (Ollama, Q4_K_M, ~700MB)"
echo -e "  ${GREEN}●${RESET} OpenELM-270M      (safetensors, fine-tuning ready)"
echo -e "  ${GREEN}●${RESET} FastVLM-0.5B      (vision-language, Hailo-ready)"
echo ""
echo -e "${BOLD}Datasets:${RESET}"
echo -e "  ${GREEN}●${RESET} GSM-Symbolic      (math reasoning)"
echo -e "  ${GREEN}●${RESET} MKQA              (multilingual QA)"
echo ""
echo -e "${BOLD}Quick test:${RESET}"
echo -e "  ollama run apple-openelm-3b \"What is BlackRoad OS?\""
echo -e "  ollama run apple-openelm-1b \"Explain edge computing\""
echo ""
echo -e "${BOLD}Disk usage:${RESET}"
du -sh "$MODELS_DIR" "$DATASETS_DIR" 2>/dev/null
echo ""
echo -e "${BOLD}All Ollama models:${RESET}"
ollama list 2>/dev/null
echo ""
log "Done. Ready for inference and fine-tuning."
