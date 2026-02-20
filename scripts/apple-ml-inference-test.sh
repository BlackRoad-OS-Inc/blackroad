#!/bin/bash
# Apple ML Inference Test for Cecilia
# Tests all Apple models are working correctly
# Usage: ssh cecilia 'bash -s' < apple-ml-inference-test.sh

PINK='\033[38;5;205m'
GREEN='\033[38;5;82m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

log()   { echo -e "${GREEN}✓${RESET} $1"; }
error() { echo -e "${RED}✗${RESET} $1"; }
header(){ echo -e "\n${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; echo -e "${BOLD} $1${RESET}"; echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

header "🍎 Apple ML Inference Tests"

# ── Test 1: Ollama OpenELM 3B ──────────────────────────────────────────
header "Test 1: OpenELM-3B via Ollama"
MODEL_3B="hf.co/mradermacher/OpenELM-3B-Instruct-GGUF:Q4_K_M"
echo -e "${CYAN}Model:${RESET} $MODEL_3B"
echo -e "${CYAN}Prompt:${RESET} 'What is 2+2? Answer in one word.'"

START=$(date +%s%N)
RESPONSE=$(ollama run "$MODEL_3B" "What is 2+2? Answer in one word." 2>&1)
END=$(date +%s%N)
ELAPSED=$(( (END - START) / 1000000 ))

if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    log "Response (${ELAPSED}ms): $RESPONSE"
else
    error "Failed: $RESPONSE"
fi

# ── Test 2: Ollama OpenELM 1.1B ───────────────────────────────────────
header "Test 2: OpenELM-1.1B via Ollama"
MODEL_1B="hf.co/mradermacher/OpenELM-1_1B-Instruct-GGUF:Q4_K_M"
echo -e "${CYAN}Model:${RESET} $MODEL_1B"

START=$(date +%s%N)
RESPONSE=$(ollama run "$MODEL_1B" "What is 2+2? Answer in one word." 2>&1)
END=$(date +%s%N)
ELAPSED=$(( (END - START) / 1000000 ))

if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    log "Response (${ELAPSED}ms): $RESPONSE"
else
    error "Failed: $RESPONSE"
fi

# ── Test 3: Transformers OpenELM 270M ─────────────────────────────────
header "Test 3: OpenELM-270M via Transformers"
python3 -c "
import time
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

model_path = '$HOME/models/apple/openelm/270M-Instruct'
print(f'Loading from: {model_path}')

start = time.time()
try:
    tokenizer = AutoTokenizer.from_pretrained('meta-llama/Llama-2-7b-hf', trust_remote_code=True)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    model = AutoModelForCausalLM.from_pretrained(model_path, trust_remote_code=True, torch_dtype=torch.float32)
    model.eval()
    load_time = time.time() - start
    print(f'Model loaded in {load_time:.1f}s')

    prompt = 'What is machine learning?'
    inputs = tokenizer(prompt, return_tensors='pt')
    start = time.time()
    with torch.no_grad():
        outputs = model.generate(**inputs, max_new_tokens=50, do_sample=False)
    gen_time = time.time() - start
    response = tokenizer.decode(outputs[0], skip_special_tokens=True)
    print(f'Response ({gen_time:.1f}s): {response[:200]}')
except Exception as e:
    print(f'Error: {e}')
" 2>&1

# ── Test 4: Dataset Verification ──────────────────────────────────────
header "Test 4: Dataset Verification"
python3 -c "
from datasets import load_from_disk

# GSM-Symbolic
try:
    ds = load_from_disk('$HOME/datasets/apple/gsm-symbolic')
    print(f'GSM-Symbolic: {len(ds)} samples')
    sample = ds[0]
    print(f'  Keys: {list(sample.keys())}')
    print(f'  Sample question: {str(sample.get(\"question\", str(list(sample.values())[0])))[:100]}...')
except Exception as e:
    print(f'GSM-Symbolic error: {e}')
" 2>&1

# ── Test 5: FastVLM Check ─────────────────────────────────────────────
header "Test 5: FastVLM-0.5B File Check"
FASTVLM="$HOME/models/apple/fastvlm/0.5B"
if [ -f "$FASTVLM/model.safetensors" ]; then
    SIZE=$(du -sh "$FASTVLM/model.safetensors" | awk '{print $1}')
    log "FastVLM safetensors present ($SIZE)"
    if [ -f "$FASTVLM/config.json" ]; then
        log "Config present"
        python3 -c "import json; c=json.load(open('$FASTVLM/config.json')); print(f'  Architecture: {c.get(\"model_type\", \"unknown\")}'); print(f'  Hidden size: {c.get(\"hidden_size\", \"unknown\")}')" 2>&1
    fi
else
    error "FastVLM safetensors missing"
fi

# ── Test 6: Hailo-8 Readiness ─────────────────────────────────────────
header "Test 6: Hailo-8 Status"
if [ -e /dev/hailo0 ]; then
    log "Hailo-8 device present at /dev/hailo0"
    hailortcli fw-control identify 2>&1 | grep -E "Board Name|Serial|Part Number" | while read line; do echo "  $line"; done
    echo -e "  ${CYAN}Note:${RESET} FastVLM Hailo compilation requires Dataflow Compiler (separate step)"
else
    error "No Hailo device found"
fi

# ── Summary ────────────────────────────────────────────────────────────
header "Summary"
echo -e "${BOLD}Ollama models:${RESET}"
ollama list 2>/dev/null | grep -i "openelm\|apple\|hf.co" || echo "  (check ollama list)"
echo ""
echo -e "${BOLD}Disk usage:${RESET}"
du -sh ~/models/apple/ ~/datasets/apple/ 2>/dev/null
echo ""
log "All tests complete."
