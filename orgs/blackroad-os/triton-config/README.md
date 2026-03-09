# BlackRoad Triton Inference Server

**NVIDIA Triton for production AI model serving**

## Overview

Triton Inference Server provides a cloud and edge inferencing solution optimized for CPUs and GPUs.

## Quick Start

```bash
# Pull Triton container
docker pull nvcr.io/nvidia/tritonserver:24.01-py3

# Run server
docker run --gpus all -d \
  -v $(pwd)/model_repository:/models \
  -p 8000:8000 -p 8001:8001 -p 8002:8002 \
  nvcr.io/nvidia/tritonserver:24.01-py3 \
  tritonserver --model-repository=/models
```

## Model Repository Structure

```
model_repository/
└── my_model/
    ├── config.pbtxt
    └── 1/
        └── model.onnx
```

## Supported Backends

| Backend | Framework | Status |
|---------|-----------|--------|
| ONNX Runtime | ONNX | ✅ |
| TensorRT | TensorRT | ✅ |
| PyTorch | LibTorch | ✅ |
| TensorFlow | SavedModel | ✅ |
| OpenVINO | OpenVINO IR | ✅ |
| Python | Custom | ✅ |

## Model Configuration

```protobuf
name: "my_model"
platform: "onnxruntime_onnx"
max_batch_size: 8
input [
  { name: "input" dims: [3, 224, 224] data_type: TYPE_FP32 }
]
output [
  { name: "output" dims: [1000] data_type: TYPE_FP32 }
]
instance_group [
  { count: 2 kind: KIND_GPU }
]
```

## API Endpoints

- `http://localhost:8000/v2/health/ready` - Health check
- `http://localhost:8000/v2/models/{model}/infer` - Inference
- `http://localhost:8001` - gRPC endpoint
- `http://localhost:8002/metrics` - Prometheus metrics

## Features

- Dynamic batching
- Model ensemble
- Model versioning
- GPU/CPU scheduling
- Prometheus metrics
- gRPC and HTTP/REST APIs

## BlackRoad Integration

Integrated with BlackRoad AI infrastructure for scalable model serving.

---

*BlackRoad OS - Sovereign AI Infrastructure*
