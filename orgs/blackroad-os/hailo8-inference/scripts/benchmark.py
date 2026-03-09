#!/usr/bin/env python3
"""Hailo-8 inference benchmark"""

import time
from hailo_platform import HailoDevice, HEF

def benchmark(hef_path: str, iterations: int = 100):
    device = HailoDevice()
    hef = HEF(hef_path)
    network_group = device.configure(hef)
    
    with network_group.activate():
        # Warmup
        for _ in range(10):
            network_group.run({})
        
        # Benchmark
        start = time.perf_counter()
        for _ in range(iterations):
            network_group.run({})
        elapsed = time.perf_counter() - start
    
    fps = iterations / elapsed
    latency_ms = (elapsed / iterations) * 1000
    print(f"FPS: {fps:.2f}, Latency: {latency_ms:.2f}ms")
    return fps, latency_ms

if __name__ == "__main__":
    benchmark("models/yolov8n.hef")
