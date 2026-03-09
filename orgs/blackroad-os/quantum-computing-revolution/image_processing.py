#!/usr/bin/env python3
"""IMAGE PROCESSING - Pure arithmetic pixel manipulation"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🖼️ IMAGE PROCESSING - {hostname}")
print(f"{'='*70}\n")

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

results = {}

# Create test image (grayscale 64x64)
def create_test_image(w, h):
    return [[((x*y + x + y) % 256) for x in range(w)] for y in range(h)]

img = create_test_image(64, 64)
W, H = 64, 64

# 1. CONVOLUTION
print("[1] 🔲 IMAGE CONVOLUTION")
print("-" * 50)

def convolve2d(image, kernel):
    h, w = len(image), len(image[0])
    kh, kw = len(kernel), len(kernel[0])
    pad_h, pad_w = kh // 2, kw // 2
    
    result = [[0] * w for _ in range(h)]
    for y in range(pad_h, h - pad_h):
        for x in range(pad_w, w - pad_w):
            val = 0
            for ky in range(kh):
                for kx in range(kw):
                    val += image[y - pad_h + ky][x - pad_w + kx] * kernel[ky][kx]
            result[y][x] = max(0, min(255, int(val)))
    return result

# Sobel kernel
sobel_x = [[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]]
sobel_y = [[-1, -2, -1], [0, 0, 0], [1, 2, 1]]

t0 = time.time()
for _ in range(100):
    edge_x = convolve2d(img, sobel_x)
    edge_y = convolve2d(img, sobel_y)
elapsed = time.time() - t0
print(f"    100 × 2 Sobel convolutions (64x64): {elapsed*1000:.2f}ms ({200/elapsed:.0f} convs/sec)")
results['conv2d'] = 200/elapsed

# 2. EDGE DETECTION (Sobel magnitude)
print("\n[2] 📐 EDGE DETECTION")
print("-" * 50)

def sobel_magnitude(image):
    gx = convolve2d(image, sobel_x)
    gy = convolve2d(image, sobel_y)
    h, w = len(image), len(image[0])
    mag = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            mag[y][x] = int(sqrt(gx[y][x]**2 + gy[y][x]**2))
    return mag

t0 = time.time()
for _ in range(100):
    edges = sobel_magnitude(img)
elapsed = time.time() - t0
print(f"    100 Sobel magnitude: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
results['sobel'] = 100/elapsed

# 3. GAUSSIAN BLUR
print("\n[3] 🌫️ GAUSSIAN BLUR")
print("-" * 50)

def gaussian_kernel(size, sigma=1.0):
    PI = 3.14159265358979
    k = [[0.0] * size for _ in range(size)]
    center = size // 2
    total = 0
    for y in range(size):
        for x in range(size):
            dx, dy = x - center, y - center
            val = (1.0 / (2 * PI * sigma**2)) * (2.718281828 ** (-(dx**2 + dy**2) / (2 * sigma**2)))
            k[y][x] = val
            total += val
    # Normalize
    for y in range(size):
        for x in range(size):
            k[y][x] /= total
    return k

gaussian_3x3 = gaussian_kernel(3, 1.0)

t0 = time.time()
for _ in range(100):
    blurred = convolve2d(img, gaussian_3x3)
elapsed = time.time() - t0
print(f"    100 Gaussian blurs: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
results['blur'] = 100/elapsed

# 4. HISTOGRAM
print("\n[4] 📊 HISTOGRAM")
print("-" * 50)

def histogram(image):
    hist = [0] * 256
    for row in image:
        for pixel in row:
            hist[pixel] += 1
    return hist

t0 = time.time()
for _ in range(10000):
    hist = histogram(img)
elapsed = time.time() - t0
print(f"    10K histograms: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
results['histogram'] = 10000/elapsed

# 5. HISTOGRAM EQUALIZATION
print("\n[5] ⚖️ HISTOGRAM EQUALIZATION")
print("-" * 50)

def histogram_equalize(image):
    h, w = len(image), len(image[0])
    hist = histogram(image)
    
    # CDF
    cdf = [0] * 256
    cdf[0] = hist[0]
    for i in range(1, 256):
        cdf[i] = cdf[i-1] + hist[i]
    
    # Normalize
    cdf_min = min(c for c in cdf if c > 0)
    total = h * w
    
    # LUT
    lut = [0] * 256
    for i in range(256):
        lut[i] = int(255 * (cdf[i] - cdf_min) / (total - cdf_min))
    
    # Apply
    result = [[lut[image[y][x]] for x in range(w)] for y in range(h)]
    return result

t0 = time.time()
for _ in range(1000):
    equalized = histogram_equalize(img)
elapsed = time.time() - t0
print(f"    1K histogram equalizations: {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
results['equalize'] = 1000/elapsed

# 6. THRESHOLDING
print("\n[6] ⬛⬜ THRESHOLDING")
print("-" * 50)

def threshold(image, thresh):
    return [[255 if p > thresh else 0 for p in row] for row in image]

def otsu_threshold(image):
    hist = histogram(image)
    total = sum(sum(row) for row in image)
    n = len(image) * len(image[0])
    
    sum_all = sum(i * hist[i] for i in range(256))
    sumB, wB, wF = 0, 0, 0
    max_var, thresh = 0, 0
    
    for i in range(256):
        wB += hist[i]
        if wB == 0: continue
        wF = n - wB
        if wF == 0: break
        
        sumB += i * hist[i]
        mB = sumB / wB
        mF = (sum_all - sumB) / wF
        
        var = wB * wF * (mB - mF) ** 2
        if var > max_var:
            max_var = var
            thresh = i
    
    return thresh

t0 = time.time()
for _ in range(1000):
    t = otsu_threshold(img)
    binary = threshold(img, t)
elapsed = time.time() - t0
print(f"    1K Otsu thresholds: {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
print(f"    Otsu threshold: {t}")
results['threshold'] = 1000/elapsed

# 7. MORPHOLOGICAL OPERATIONS
print("\n[7] 🔳 MORPHOLOGICAL OPS")
print("-" * 50)

def erode(image, kernel_size=3):
    h, w = len(image), len(image[0])
    pad = kernel_size // 2
    result = [[0] * w for _ in range(h)]
    
    for y in range(pad, h - pad):
        for x in range(pad, w - pad):
            min_val = 255
            for ky in range(-pad, pad + 1):
                for kx in range(-pad, pad + 1):
                    min_val = min(min_val, image[y + ky][x + kx])
            result[y][x] = min_val
    return result

def dilate(image, kernel_size=3):
    h, w = len(image), len(image[0])
    pad = kernel_size // 2
    result = [[0] * w for _ in range(h)]
    
    for y in range(pad, h - pad):
        for x in range(pad, w - pad):
            max_val = 0
            for ky in range(-pad, pad + 1):
                for kx in range(-pad, pad + 1):
                    max_val = max(max_val, image[y + ky][x + kx])
            result[y][x] = max_val
    return result

t0 = time.time()
for _ in range(100):
    eroded = erode(img)
    dilated = dilate(img)
elapsed = time.time() - t0
print(f"    100 × erode + dilate: {elapsed*1000:.2f}ms ({200/elapsed:.0f}/sec)")
results['morph'] = 200/elapsed

# 8. CONNECTED COMPONENTS
print("\n[8] 🔢 CONNECTED COMPONENTS")
print("-" * 50)

def connected_components(binary):
    h, w = len(binary), len(binary[0])
    labels = [[0] * w for _ in range(h)]
    current_label = 0
    
    for y in range(h):
        for x in range(w):
            if binary[y][x] > 0 and labels[y][x] == 0:
                current_label += 1
                # BFS
                queue = [(y, x)]
                while queue:
                    cy, cx = queue.pop(0)
                    if labels[cy][cx] != 0:
                        continue
                    if binary[cy][cx] == 0:
                        continue
                    labels[cy][cx] = current_label
                    for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w:
                            if binary[ny][nx] > 0 and labels[ny][nx] == 0:
                                queue.append((ny, nx))
    
    return labels, current_label

binary_img = threshold(img, 128)

t0 = time.time()
for _ in range(100):
    labels, n_comp = connected_components(binary_img)
elapsed = time.time() - t0
print(f"    100 connected component analyses: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
print(f"    Components found: {n_comp}")
results['cc'] = 100/elapsed

# 9. IMAGE ROTATION
print("\n[9] 🔄 IMAGE ROTATION")
print("-" * 50)

def rotate_90(image):
    h, w = len(image), len(image[0])
    return [[image[h - 1 - x][y] for x in range(h)] for y in range(w)]

def rotate_arbitrary(image, angle_deg):
    import math  # Only for this rotation (approximated below)
    PI = 3.14159265358979
    angle = angle_deg * PI / 180
    
    def sin(x):
        while x > PI: x -= 2*PI
        while x < -PI: x += 2*PI
        r, t = 0.0, x
        for n in range(15):
            r = r + t if n % 2 == 0 else r - t
            t = t * x * x / ((2*n+2) * (2*n+3))
        return r
    
    def cos(x):
        while x > PI: x -= 2*PI
        while x < -PI: x += 2*PI
        r, t = 1.0, 1.0
        for n in range(1, 15):
            t = t * (-x*x) / ((2*n-1) * (2*n))
            r += t
        return r
    
    h, w = len(image), len(image[0])
    cx, cy = w / 2, h / 2
    cos_a, sin_a = cos(angle), sin(angle)
    
    result = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            dx, dy = x - cx, y - cy
            src_x = int(dx * cos_a + dy * sin_a + cx)
            src_y = int(-dx * sin_a + dy * cos_a + cy)
            if 0 <= src_x < w and 0 <= src_y < h:
                result[y][x] = image[src_y][src_x]
    
    return result

t0 = time.time()
for _ in range(100):
    rot90 = rotate_90(img)
    rot45 = rotate_arbitrary(img, 45)
elapsed = time.time() - t0
print(f"    100 × (90° + 45°) rotations: {elapsed*1000:.2f}ms ({200/elapsed:.0f}/sec)")
results['rotate'] = 200/elapsed

# 10. IMAGE SCALING
print("\n[10] 📐 IMAGE SCALING (Bilinear)")
print("-" * 50)

def bilinear_scale(image, new_w, new_h):
    h, w = len(image), len(image[0])
    result = [[0] * new_w for _ in range(new_h)]
    
    x_ratio = w / new_w
    y_ratio = h / new_h
    
    for y in range(new_h):
        for x in range(new_w):
            src_x = x * x_ratio
            src_y = y * y_ratio
            
            x1 = int(src_x)
            y1 = int(src_y)
            x2 = min(x1 + 1, w - 1)
            y2 = min(y1 + 1, h - 1)
            
            x_frac = src_x - x1
            y_frac = src_y - y1
            
            top = image[y1][x1] * (1 - x_frac) + image[y1][x2] * x_frac
            bot = image[y2][x1] * (1 - x_frac) + image[y2][x2] * x_frac
            result[y][x] = int(top * (1 - y_frac) + bot * y_frac)
    
    return result

t0 = time.time()
for _ in range(100):
    scaled = bilinear_scale(img, 128, 128)  # 2x upscale
elapsed = time.time() - t0
print(f"    100 bilinear scales (64→128): {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
results['scale'] = 100/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 IMAGE PROCESSING SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Convolution:          {results['conv2d']:.0f} convs/sec
  Sobel Edge:           {results['sobel']:.0f}/sec
  Gaussian Blur:        {results['blur']:.0f}/sec
  Histogram:            {results['histogram']:.0f}/sec
  Histogram Eq:         {results['equalize']:.0f}/sec
  Otsu Threshold:       {results['threshold']:.0f}/sec
  Morphological:        {results['morph']:.0f}/sec
  Connected Comp:       {results['cc']:.0f}/sec
  Rotation:             {results['rotate']:.0f}/sec
  Bilinear Scale:       {results['scale']:.0f}/sec
  
  🖼️ TOTAL IMAGE SCORE: {total:.0f} points
""")
