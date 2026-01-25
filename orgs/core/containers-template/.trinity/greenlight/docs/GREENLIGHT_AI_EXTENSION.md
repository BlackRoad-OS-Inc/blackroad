# 🤗 GreenLight AI & ML Extension

**Extension to GreenLight for HuggingFace & AI Infrastructure**

---

## 🤖 AI Model Lifecycle States

Add these to the **Lifecycle States** category:

| Emoji | State | Code | Trinary | Description |
|-------|-------|------|---------|-------------|
| 🤗 | MODEL_LOADING | `model_loading` | 0 | Loading model into memory |
| 🧠 | MODEL_READY | `model_ready` | +1 | Model loaded and ready |
| ⚡ | INFERENCE_RUNNING | `inference_running` | +1 | Generating output |
| 🔄 | TOKEN_STREAMING | `token_streaming` | +1 | Streaming tokens |
| 💾 | MODEL_CACHED | `model_cached` | +1 | Model in cache |
| 📥 | MODEL_DOWNLOADING | `model_downloading` | 0 | Downloading weights |
| 🏋️ | MODEL_TRAINING | `model_training` | +1 | Model training |
| 📊 | MODEL_EVAL | `model_eval` | 0 | Evaluating performance |
| 🔧 | MODEL_FINE_TUNING | `model_fine_tuning` | +1 | Fine-tuning model |
| ⏱️ | INFERENCE_TIMEOUT | `inference_timeout` | -1 | Request timed out |

---

## 🎯 AI Task Categories

Add to **Domain Tags**:

| Emoji | Category | Code | Description |
|-------|----------|------|-------------|
| 💬 | TEXT_GEN | `text_gen` | Text generation / completion |
| 🗣️ | CHAT | `chat` | Chat completions |
| 🎨 | IMAGE_GEN | `image_gen` | Image generation |
| 🖼️ | IMAGE_EDIT | `image_edit` | Image editing / inpainting |
| 🔤 | EMBEDDINGS | `embeddings` | Vector embeddings |
| 🔍 | OCR | `ocr` | Optical character recognition |
| 🎙️ | TTS | `tts` | Text to speech |
| 👂 | STT | `stt` | Speech to text |
| 🎥 | VIDEO_GEN | `video_gen` | Video generation |
| 🔬 | CLASSIFICATION | `classification` | Classification tasks |

---

## 🏗️ AI Infrastructure Components

| Emoji | Component | Code | Description |
|-------|-----------|------|-------------|
| 🤗 | HUGGINGFACE | `huggingface` | HuggingFace platform |
| ⚡ | VLLM | `vllm` | vLLM inference server |
| 🦙 | LLAMA_CPP | `llama_cpp` | llama.cpp engine |
| 🔥 | TRANSFORMERS | `transformers` | Transformers library |
| 🌐 | INFERENCE_ENDPOINT | `inference_endpoint` | HF Inference Endpoint |
| 📦 | MODEL_HUB | `model_hub` | Model repository |
| 🚀 | SPACE | `space` | HuggingFace Space |
| 💾 | MODEL_CACHE | `model_cache` | Model caching layer |
| 🖥️ | GPU_INSTANCE | `gpu_instance` | GPU compute instance |

---

## 🎛️ GPU Instance Types

| Emoji | Instance | Code | VRAM | Description |
|-------|----------|------|------|-------------|
| 🟢 | T4 | `t4` | 16GB | Small models / testing |
| 🔵 | L4 | `l4` | 24GB | 7B-13B models |
| 🟡 | A10G | `a10g` | 24GB | Production inference |
| 🟠 | A100 | `a100` | 80GB | Large models (70B+) |
| 🔴 | H100 | `h100` | 80GB | Maximum performance |
| 🟣 | JETSON | `jetson` | 8GB | Edge inference |

---

## 🎨 Composite Patterns for AI

### Model Operations
```
🤗📥👉📌 = Downloading model, micro scale
🧠✅🎢⭐ = Model loaded, macro impact, high priority
⚡🔄💬🌀 = Streaming chat tokens, AI domain
🎨✅👉📌 = Image generated, micro scale
```

### Inference Flows
```
⚡💬🧠✅ = Chat inference running, model ready
⚡🎨🖼️✅ = Image generation complete
🔤💾🎢✅ = Embeddings cached, macro scale
🔍📄👉✅ = OCR completed, micro scale
```

### Infrastructure
```
🚀🤗🌐✅ = HF Space deployed
🌐⚡🟡📌 = Inference endpoint on A10G
💾🧠🎢⭐ = Model cached, high priority
⏱️❌🧠🔥 = Inference timeout, fire priority
```

### Combined AI Flow
```
[⚡📥] [🤗🧠] [⚡💬] [🔄📊] [✅🎉] = Request → Load → Inference → Stream → Complete
[🎨⚡] [🖼️✅] = Image generation → success
[🔤💾] [✅🎢] = Embeddings → cached
```

---

## 📝 NATS Subject Patterns (AI)

### Inference Events
```
greenlight.inference.started.micro.ai.{model_name}
greenlight.inference.completed.micro.ai.{model_name}
greenlight.inference.failed.micro.ai.{model_name}
greenlight.inference.timeout.micro.ai.{model_name}
```

### Model Events
```
greenlight.model.loaded.macro.ai.{model_name}
greenlight.model.cached.micro.ai.{model_name}
greenlight.model.downloading.micro.ai.{model_name}
greenlight.model.uploaded.macro.ai.{model_name}
```

### Endpoint Events
```
greenlight.endpoint.created.macro.ai.{endpoint_name}
greenlight.endpoint.paused.micro.ai.{endpoint_name}
greenlight.endpoint.resumed.micro.ai.{endpoint_name}
greenlight.endpoint.scaled.macro.ai.{endpoint_name}
```

### Task-Specific Events
```
greenlight.chat.completed.micro.ai.{model}
greenlight.image.generated.micro.ai.{model}
greenlight.embeddings.cached.micro.ai.{model}
greenlight.ocr.completed.micro.ai.{file}
```

---

## 🔨 AI Memory Templates

### Model Operations

```bash
# Model loading
gl_model_loading() {
    local model_name="$1"
    local size="${2:-unknown}"

    gl_log "🤗📥👉📌" "model_loading" "$model_name" \
        "Loading model: $size"
}

# Model ready
gl_model_ready() {
    local model_name="$1"
    local vram="${2:-unknown}"

    gl_log "🧠✅🎢⭐" "model_ready" "$model_name" \
        "Model loaded, VRAM: $vram"
}

# Model cached
gl_model_cached() {
    local model_name="$1"
    local cache_key="$2"

    gl_log "💾🧠👉📌" "model_cached" "$model_name" \
        "Model cached: $cache_key"
}

# Model downloading
gl_model_downloading() {
    local model_name="$1"
    local size="${2:-unknown}"

    gl_log "📥🤗👉📌" "model_downloading" "$model_name" \
        "Downloading: $size"
}

# Model uploaded
gl_model_uploaded() {
    local model_name="$1"
    local repo_id="$2"

    gl_log "📤🤗🎢✅" "model_uploaded" "$model_name" \
        "Uploaded to: $repo_id"
}
```

### Inference Operations

```bash
# Inference started
gl_inference_start() {
    local task_type="$1"  # chat, text_gen, image_gen, etc.
    local model="$2"
    local request_id="${3:-$(uuidgen)}"

    local task_emoji=""
    case "$task_type" in
        chat) task_emoji="💬" ;;
        text_gen) task_emoji="💬" ;;
        image_gen) task_emoji="🎨" ;;
        embeddings) task_emoji="🔤" ;;
        ocr) task_emoji="🔍" ;;
        tts) task_emoji="🎙️" ;;
        video_gen) task_emoji="🎥" ;;
        *) task_emoji="🤖" ;;
    esac

    gl_log "⚡${task_emoji}👉📌" "inference_start" "$model" \
        "$task_type inference started: $request_id"
}

# Inference complete
gl_inference_complete() {
    local task_type="$1"
    local model="$2"
    local duration="${3:-unknown}"

    local task_emoji=""
    case "$task_type" in
        chat) task_emoji="💬" ;;
        text_gen) task_emoji="💬" ;;
        image_gen) task_emoji="🎨" ;;
        embeddings) task_emoji="🔤" ;;
        ocr) task_emoji="🔍" ;;
        *) task_emoji="🤖" ;;
    esac

    gl_log "✅${task_emoji}🎢🎉" "inference_complete" "$model" \
        "$task_type complete in $duration"
}

# Inference failed
gl_inference_failed() {
    local task_type="$1"
    local model="$2"
    local error="${3:-unknown error}"

    gl_log "❌⚡🤖🔥" "inference_failed" "$model" \
        "$task_type failed: $error"
}

# Token streaming
gl_token_streaming() {
    local model="$1"
    local tokens_generated="$2"

    gl_log "🔄💬⚡👉" "token_streaming" "$model" \
        "Streaming: $tokens_generated tokens"
}

# Inference timeout
gl_inference_timeout() {
    local model="$1"
    local timeout_seconds="$2"

    gl_log "⏱️❌🤖🔥" "inference_timeout" "$model" \
        "Timed out after ${timeout_seconds}s"
}
```

### Endpoint Management

```bash
# Endpoint created
gl_endpoint_created() {
    local endpoint_name="$1"
    local model="$2"
    local instance_type="${3:-unknown}"

    local instance_emoji=""
    case "$instance_type" in
        *t4*) instance_emoji="🟢" ;;
        *l4*) instance_emoji="🔵" ;;
        *a10g*) instance_emoji="🟡" ;;
        *a100*) instance_emoji="🟠" ;;
        *h100*) instance_emoji="🔴" ;;
        *) instance_emoji="🖥️" ;;
    esac

    gl_log "🚀🌐${instance_emoji}✅" "endpoint_created" "$endpoint_name" \
        "Endpoint created: $model on $instance_type"
}

# Endpoint paused
gl_endpoint_paused() {
    local endpoint_name="$1"

    gl_log "⏸️🌐👉📌" "endpoint_paused" "$endpoint_name" \
        "Endpoint paused (cost savings)"
}

# Endpoint resumed
gl_endpoint_resumed() {
    local endpoint_name="$1"

    gl_log "▶️🌐👉📌" "endpoint_resumed" "$endpoint_name" \
        "Endpoint resumed"
}

# Endpoint scaled
gl_endpoint_scaled() {
    local endpoint_name="$1"
    local replicas="$2"

    gl_log "📈🌐🎢⭐" "endpoint_scaled" "$endpoint_name" \
        "Scaled to $replicas replicas"
}

# Endpoint deleted
gl_endpoint_deleted() {
    local endpoint_name="$1"

    gl_log "🗑️🌐👉📌" "endpoint_deleted" "$endpoint_name" \
        "Endpoint deleted"
}
```

### Space Operations

```bash
# Space deployed
gl_space_deployed() {
    local space_name="$1"
    local url="$2"

    gl_log "🚀🤗🌐✅" "space_deployed" "$space_name" \
        "Space deployed: $url"
}

# Space invoked
gl_space_invoked() {
    local space_id="$1"
    local task_type="$2"

    gl_log "⚡🤗👉📌" "space_invoked" "$space_id" \
        "Space invoked for: $task_type"
}
```

---

## 🎯 Example Integration: Complete Inference Flow

### Scenario: Chat inference with DeepSeek

```bash
# 1. Load model
gl_model_loading "deepseek-ai/DeepSeek-V3.2" "7B"
# [🤗📥👉📌] model_loading: deepseek-ai/DeepSeek-V3.2 — Loading model: 7B

# 2. Model ready
gl_model_ready "deepseek-ai/DeepSeek-V3.2" "16GB"
# [🧠✅🎢⭐] model_ready: deepseek-ai/DeepSeek-V3.2 — Model loaded, VRAM: 16GB

# 3. Start inference
gl_inference_start "chat" "deepseek-ai/DeepSeek-V3.2" "req_abc123"
# [⚡💬👉📌] inference_start: deepseek-ai/DeepSeek-V3.2 — chat inference started: req_abc123

# 4. Token streaming
gl_token_streaming "deepseek-ai/DeepSeek-V3.2" "247"
# [🔄💬⚡👉] token_streaming: deepseek-ai/DeepSeek-V3.2 — Streaming: 247 tokens

# 5. Complete
gl_inference_complete "chat" "deepseek-ai/DeepSeek-V3.2" "3.2s"
# [✅💬🎢🎉] inference_complete: deepseek-ai/DeepSeek-V3.2 — chat complete in 3.2s
```

### Scenario: Image generation with FLUX

```bash
# 1. Space invoked
gl_space_invoked "black-forest-labs/FLUX.1-dev" "image_gen"
# [⚡🤗👉📌] space_invoked: black-forest-labs/FLUX.1-dev — Space invoked for: image_gen

# 2. Start inference
gl_inference_start "image_gen" "FLUX.1-dev" "img_xyz789"
# [⚡🎨👉📌] inference_start: FLUX.1-dev — image_gen inference started: img_xyz789

# 3. Complete
gl_inference_complete "image_gen" "FLUX.1-dev" "12.4s"
# [✅🎨🎢🎉] inference_complete: FLUX.1-dev — image_gen complete in 12.4s
```

### Scenario: Endpoint lifecycle (Lucidia)

```bash
# 1. Create endpoint
gl_endpoint_created "lucidia-inference" "blackroadio/Lucidia" "nvidia-a10g"
# [🚀🌐🟡✅] endpoint_created: lucidia-inference — Endpoint created: blackroadio/Lucidia on nvidia-a10g

# 2. Run inference
gl_inference_start "chat" "lucidia-inference" "req_lucidia_001"
# [⚡💬👉📌] inference_start: lucidia-inference — chat inference started: req_lucidia_001

# 3. Complete
gl_inference_complete "chat" "lucidia-inference" "2.1s"
# [✅💬🎢🎉] inference_complete: lucidia-inference — chat complete in 2.1s

# 4. Pause for cost savings
gl_endpoint_paused "lucidia-inference"
# [⏸️🌐👉📌] endpoint_paused: lucidia-inference — Endpoint paused (cost savings)

# 5. Resume when needed
gl_endpoint_resumed "lucidia-inference"
# [▶️🌐👉📌] endpoint_resumed: lucidia-inference — Endpoint resumed
```

### Scenario: Inference failure and timeout

```bash
# 1. Start inference
gl_inference_start "chat" "large-model" "req_fail"
# [⚡💬👉📌] inference_start: large-model — chat inference started: req_fail

# 2. Timeout
gl_inference_timeout "large-model" "30"
# [⏱️❌🤖🔥] inference_timeout: large-model — Timed out after 30s

# 3. Failed
gl_inference_failed "chat" "large-model" "OOM error"
# [❌⚡🤖🔥] inference_failed: large-model — chat failed: OOM error
```

---

## 📊 AI Analytics Integration

### Performance Tracking
```bash
# Inference latency
gl_log "📊⚡🎢📌" "latency_metric" "ai-metrics" "p95 latency: 3.2s (chat)"

# Token throughput
gl_log "📊💬👉📌" "throughput_metric" "ai-metrics" "Throughput: 45 tokens/sec"

# Cache hit rate
gl_log "📊💾🎢⭐" "cache_metric" "ai-metrics" "Cache hit rate: 78%"
```

### Cost Tracking
```bash
# GPU costs
gl_log "💰🖥️🎢📌" "gpu_cost" "ai-billing" "A10G usage: $2.47/hour"

# Inference costs
gl_log "💰⚡👉📌" "inference_cost" "ai-billing" "1,247 requests: $12.34"
```

---

## 📚 Integration Checklist

- [x] Extended lifecycle states for AI operations
- [x] Added AI task category tags
- [x] Created infrastructure component tags
- [x] Mapped GPU instance types
- [x] Created composite patterns for inference flows
- [x] Extended NATS subjects for AI events
- [x] Built 15+ AI-specific templates
- [x] Integrated with 27-step GreenLight workflow
- [x] Added analytics tracking patterns
- [x] Added cost tracking patterns

---

## 🎯 HuggingFace Account Details

**Username:** blackroadio
**Profile:** https://huggingface.co/blackroadio
**Models:** 2 (Lucidia, qwen3-235b-a22b)
**API Tokens:** https://huggingface.co/settings/tokens
**Endpoints:** https://endpoints.huggingface.co

### Recommended Models
**Text Generation:**
- openai/gpt-oss-20b (7.2M downloads)
- deepseek-ai/DeepSeek-V3.2 (90.9K downloads)
- nvidia/Nemotron-3-Nano-30B-A3B (247.7K downloads)

**Image Generation:**
- black-forest-labs/FLUX.1-dev (809.7K downloads)
- stabilityai/stable-diffusion-xl-base-1.0 (2.1M downloads)

**Embeddings:**
- sentence-transformers/all-MiniLM-L6-v2 (149.3M downloads)
- BAAI/bge-m3 (8.2M downloads)

**OCR:**
- deepseek-ai/DeepSeek-OCR (4.7M downloads)

### Available Spaces (15+)
- evalstate/flux1_schnell - Fast image generation
- mcp-tools/FLUX.1-Krea-dev - High quality images
- not-lain/background-removal - Remove backgrounds
- ResembleAI/Chatterbox - Text to speech
- mcp-tools/DeepSeek-OCR-experimental - OCR

---

**Created:** December 23, 2025
**For:** HuggingFace AI Infrastructure
**Version:** 2.0.0-ai
**Status:** 🔨 IMPLEMENTATION
