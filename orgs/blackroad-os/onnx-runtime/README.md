# BlackRoad ONNX Runtime

**High-performance AI model inference using ONNX Runtime**

## Overview

ONNX Runtime provides cross-platform, high-performance ML inferencing and training.

## Quick Start

```bash
# Install ONNX Runtime
pip install onnxruntime onnxruntime-gpu

# Or using conda
conda install -c conda-forge onnxruntime
```

## Configuration

```python
import onnxruntime as ort

# Create inference session
session = ort.InferenceSession(
    "model.onnx",
    providers=['CUDAExecutionProvider', 'CPUExecutionProvider']
)

# Run inference
outputs = session.run(None, {"input": input_data})
```

## Supported Execution Providers

| Provider | Hardware | Status |
|----------|----------|--------|
| CPU | Intel/AMD/ARM | ✅ Active |
| CUDA | NVIDIA GPU | ✅ Active |
| TensorRT | NVIDIA GPU | ✅ Active |
| DirectML | Windows GPU | ✅ Active |
| OpenVINO | Intel | ✅ Active |
| CoreML | Apple Silicon | ✅ Active |

## Model Conversion

```bash
# Convert PyTorch to ONNX
python -c "
import torch
model = torch.load('model.pt')
torch.onnx.export(model, dummy_input, 'model.onnx')
"

# Convert TensorFlow to ONNX
python -m tf2onnx.convert --saved-model model_dir --output model.onnx
```

## Performance Optimization

- Graph optimization (constant folding, node fusion)
- Quantization (INT8, FP16)
- Threading configuration
- Memory optimization

## BlackRoad Integration

- Deployed on Pi cluster via Hailo-8 acceleration
- Integrated with roadcommand-ai-ops
- Supports all BlackRoad AI agent models

---

*BlackRoad OS - Sovereign AI Infrastructure*
