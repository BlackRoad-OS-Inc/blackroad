set -euo pipefail
SRC="${1:-models/merged/lucidia-neox-1.4b}"     # or the AWQ dir
OUT="${2:-models/merged/trt_engine}"
MAX_SEQ="${MAX_SEQ:-2048}"

mkdir -p "$OUT"
# Build with defaults; tune flags later (tokens_per_block, plugins, etc.)
trtllm-build \
  --checkpoint_dir "$SRC" \
  --output_dir "$OUT" \
  --max_seq_len "$MAX_SEQ" \
  --remove_input_padding enable \
  --gpt_attention_plugin auto

echo "Engine built at: $OUT"
echo "Serve it with: trtllm-serve \"$OUT\" --tokenizer \"$SRC\" --port 8000 --host 0.0.0.0"
#!/usr/bin/env bash
set -euo pipefail

MODEL_DIR=${1:-models/merged/lucidia-neox-1.4b}
OUT_DIR=${2:-${MODEL_DIR}-trt}

echo "Building TensorRT engine from $MODEL_DIR"
trtllm-build --checkpoint "$MODEL_DIR" --build-dir "$OUT_DIR" "$@"
