#!/bin/bash
# BlackRoad Octavia E2E Benchmark Suite
# Tests BEFORE (baseline) vs AFTER (optimized) configurations

HOST="pi@192.168.4.74"
RESULTS_DIR="/tmp/blackroad-benchmarks"

echo "🖤🛣️ BlackRoad Octavia E2E Benchmark Suite"
echo "=========================================="
echo ""

# Create results directory
ssh $HOST "mkdir -p $RESULTS_DIR"

# Get current configuration
echo "📊 Current Configuration:"
echo "------------------------"
ssh $HOST "vcgencmd get_config int | grep -E 'gpu_mem|arm_freq|over_voltage'"
ssh $HOST "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
ssh $HOST "vcgencmd measure_temp"
echo ""

# Test 1: CPU Performance
echo "⚡ Test 1: CPU Performance (sysbench)"
echo "------------------------------------"
ssh $HOST "sysbench cpu --threads=1 --time=15 run 2>&1 | grep -E 'events per second|total time|total number of events'"
echo ""
ssh $HOST "sysbench cpu --threads=4 --time=15 run 2>&1 | grep -E 'events per second|total time|total number of events'"
echo ""

# Test 2: Memory Performance
echo "💾 Test 2: Memory Throughput"
echo "-----------------------------"
ssh $HOST "sysbench memory --threads=4 --memory-total-size=2G run 2>&1 | grep -E 'Total operations|transferred|MiB/sec'"
echo ""

# Test 3: Disk I/O
echo "💿 Test 3: Disk I/O Performance"
echo "--------------------------------"
ssh $HOST "dd if=/dev/zero of=/tmp/testfile bs=1M count=1024 oflag=direct 2>&1 | tail -1"
ssh $HOST "rm -f /tmp/testfile"
echo ""

# Test 4: Multi-core stress test
echo "🔥 Test 4: Multi-Core Stress (stress-ng)"
echo "-----------------------------------------"
ssh $HOST "stress-ng --cpu 4 --cpu-method fft --metrics-brief --timeout 15s 2>&1 | grep -A 5 'bogo ops'"
echo ""

# Test 5: Python/NumPy matrix operations
echo "🐍 Test 5: Python/NumPy Performance"
echo "------------------------------------"
ssh $HOST "python3 << 'PYEOF'
import numpy as np
import time

# Matrix multiplication
sizes = [500, 1000, 2000]
for size in sizes:
    a = np.random.rand(size, size)
    b = np.random.rand(size, size)
    start = time.time()
    c = np.dot(a, b)
    elapsed = time.time() - start
    print(f'  Matrix {size}x{size}: {elapsed:.4f}s ({size*size*size*2/elapsed/1e9:.2f} GFLOPS)')
PYEOF
"
echo ""

# Test 6: FFT Performance
echo "📈 Test 6: FFT Performance (NumPy)"
echo "-----------------------------------"
ssh $HOST "python3 << 'PYEOF'
import numpy as np
import time

sizes = [2**16, 2**18, 2**20]
for size in sizes:
    data = np.random.rand(size)
    start = time.time()
    fft_result = np.fft.fft(data)
    elapsed = time.time() - start
    print(f'  FFT size {size}: {elapsed:.4f}s')
PYEOF
"
echo ""

# Test 7: OpenCV image processing
echo "🎨 Test 7: OpenCV Image Processing"
echo "------------------------------------"
ssh $HOST "python3 << 'PYEOF'
import cv2
import numpy as np
import time

# Create test images
sizes = [(640, 480), (1920, 1080), (3840, 2160)]

for size in sizes:
    img = np.random.randint(0, 255, (*size, 3), dtype=np.uint8)

    # Gaussian blur
    start = time.time()
    blurred = cv2.GaussianBlur(img, (15, 15), 0)
    elapsed = time.time() - start
    print(f'  Gaussian Blur {size[0]}x{size[1]}: {elapsed:.4f}s')

    # Edge detection
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    start = time.time()
    edges = cv2.Canny(gray, 100, 200)
    elapsed = time.time() - start
    print(f'  Canny Edge {size[0]}x{size[1]}: {elapsed:.4f}s')
PYEOF
"
echo ""

# Test 8: Vulkan info
echo "🎮 Test 8: GPU/Vulkan Capabilities"
echo "------------------------------------"
ssh $HOST "vulkaninfo --summary 2>/dev/null | grep -A 3 'deviceName'"
echo ""

# Test 9: Thermal performance
echo "🌡️  Test 9: Thermal Performance"
echo "--------------------------------"
echo "Initial temp: $(ssh $HOST 'vcgencmd measure_temp')"
echo "Running 30s CPU stress test..."
ssh $HOST "stress-ng --cpu 4 --timeout 30s > /dev/null 2>&1"
echo "Post-stress temp: $(ssh $HOST 'vcgencmd measure_temp')"
sleep 5
echo "5s cool-down temp: $(ssh $HOST 'vcgencmd measure_temp')"
echo ""

# Test 10: Concurrent workload
echo "🔄 Test 10: Concurrent Mixed Workload"
echo "---------------------------------------"
ssh $HOST "python3 << 'PYEOF'
import numpy as np
import time
from concurrent.futures import ThreadPoolExecutor

def matrix_task(size):
    a = np.random.rand(size, size)
    b = np.random.rand(size, size)
    return np.dot(a, b)

start = time.time()
with ThreadPoolExecutor(max_workers=4) as executor:
    futures = [executor.submit(matrix_task, 800) for _ in range(4)]
    results = [f.result() for f in futures]
elapsed = time.time() - start
print(f'  4 concurrent 800x800 matrices: {elapsed:.4f}s')
PYEOF
"
echo ""

# Summary
echo "✅ Benchmark Complete!"
echo "======================"
echo ""
echo "System Info:"
ssh $HOST "cat /proc/cpuinfo | grep -E 'Model|Hardware' | head -2"
ssh $HOST "free -h | grep Mem"
echo "Current temp: $(ssh $HOST 'vcgencmd measure_temp')"
echo "CPU freq: $(ssh $HOST 'vcgencmd measure_clock arm')"
echo ""
