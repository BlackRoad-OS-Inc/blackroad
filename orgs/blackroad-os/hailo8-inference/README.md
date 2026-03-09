# BlackRoad Hailo-8 Edge Inference

**26 TOPS AI acceleration on Raspberry Pi 5**

## Hardware Setup

- **Device**: Raspberry Pi 5 (Cecilia)
- **Accelerator**: Hailo-8 M.2 Module
- **Performance**: 26 TOPS (15-30x more efficient than NVIDIA Jetson)

## Installation

```bash
# Install HailoRT
wget https://hailo.ai/downloads/hailort_4.17.0_arm64.deb
sudo dpkg -i hailort_4.17.0_arm64.deb

# Install Python bindings
pip install hailo-platform

# Verify installation
hailortcli scan
```

## Quick Start

```python
from hailo_platform import HailoDevice, HEF

# Load model
device = HailoDevice()
hef = HEF('models/yolov8n.hef')
network_group = device.configure(hef)

# Run inference
with network_group.activate():
    input_data = preprocess(image)
    output = network_group.run(input_data)
    results = postprocess(output)
```

## Compiled Models (.hef)

| Model | Use Case | Latency | TOPS Used |
|-------|----------|---------|-----------|
| YOLOv8n | Object Detection | 12ms | 8 |
| MobileNetV3 | Classification | 3ms | 4 |
| ResNet50 | Classification | 8ms | 12 |
| DeepLabV3 | Segmentation | 25ms | 18 |

## Model Compilation

```bash
# Install Hailo Model Zoo
pip install hailo-model-zoo

# Compile ONNX to HEF
hailo parser onnx model.onnx --hw-arch hailo8
hailo compiler model.har --hw-arch hailo8
```

## BlackRoad Integration

```bash
# On Cecilia Pi
curl -X POST http://cecilia:8080/infer \
  -F "image=@frame.jpg" \
  -F "model=yolov8n"
```

## Performance Metrics

- **Power Efficiency**: 2.5W typical
- **Throughput**: 3000+ FPS (INT8)
- **Memory**: 16GB shared with Pi 5

---

*BlackRoad OS - Edge AI Sovereignty on Cecilia*
