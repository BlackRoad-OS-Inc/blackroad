#!/usr/bin/env python3
"""MACHINE LEARNING PRIMITIVES - Pure arithmetic ML"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  MACHINE LEARNING PRIMITIVES - {hostname}")
print(f"{'='*70}\n")

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

def exp(x):
    if x > 700: return 1e308
    if x < -700: return 0
    r, t = 1.0, 1.0
    for n in range(1, 30):
        t = t * x / n
        r += t
        if abs(t) < 1e-15: break
    return r

def ln(x):
    if x <= 0: return -1e308
    k = 0
    while x > 2.718281828: x /= 2.718281828; k += 1
    while x < 0.367879441: x *= 2.718281828; k -= 1
    z = (x-1)/(x+1)
    r, t = 0.0, z
    for n in range(50):
        r += t / (2*n+1)
        t *= z*z
    return 2*r + k

results = {}

# 1. SIGMOID ACTIVATION
print("[1] ACTIVATIONS (10M operations)")
print("-" * 50)

def sigmoid(x):
    return 1.0 / (1.0 + exp(-x))

def relu(x):
    return max(0, x)

def tanh(x):
    e2x = exp(2*x)
    return (e2x - 1) / (e2x + 1)

def softmax(x):
    max_x = max(x)
    exps = [exp(xi - max_x) for xi in x]
    s = sum(exps)
    return [e/s for e in exps]

t0 = time.time()
for i in range(1000000):
    x = (i % 200 - 100) / 10
    s = sigmoid(x)
    r = relu(x)
    t = tanh(x)
elapsed = time.time() - t0
print(f"    1M×(sigmoid+relu+tanh): {elapsed*1000:.2f}ms ({3000000/elapsed/1e6:.2f}M ops/sec)")
results['activations'] = 3000000/elapsed

# 2. SOFTMAX
print("\n[2] SOFTMAX (100K batches)")
print("-" * 50)

t0 = time.time()
for i in range(100000):
    logits = [(i*j%100)/10 - 5 for j in range(10)]
    probs = softmax(logits)
elapsed = time.time() - t0
print(f"    100K×softmax(10): {elapsed*1000:.2f}ms ({100000/elapsed/1e3:.1f}K softmax/sec)")
results['softmax'] = 100000/elapsed

# 3. DOT PRODUCT
print("\n[3] DOT PRODUCT (1M operations)")
print("-" * 50)

def dot(a, b):
    return sum(ai * bi for ai, bi in zip(a, b))

vec_a = [i * 0.01 for i in range(100)]
vec_b = [(100-i) * 0.01 for i in range(100)]

t0 = time.time()
for _ in range(1000000):
    d = dot(vec_a, vec_b)
elapsed = time.time() - t0
print(f"    1M×dot(100): {elapsed*1000:.2f}ms ({1000000/elapsed/1e6:.2f}M dots/sec)")
results['dot'] = 1000000/elapsed

# 4. MATRIX MULTIPLY
print("\n[4] MATRIX MULTIPLY")
print("-" * 50)

def matmul(A, B):
    m, k = len(A), len(A[0])
    k2, n = len(B), len(B[0])
    C = [[0]*n for _ in range(m)]
    for i in range(m):
        for j in range(n):
            for p in range(k):
                C[i][j] += A[i][p] * B[p][j]
    return C

A = [[i*8+j for j in range(8)] for i in range(8)]
B = [[i*8+j+1 for j in range(8)] for i in range(8)]

t0 = time.time()
for _ in range(10000):
    C = matmul(A, B)
elapsed = time.time() - t0
print(f"    10K×matmul(8×8): {elapsed*1000:.2f}ms ({10000/elapsed/1e3:.1f}K matmuls/sec)")
results['matmul'] = 10000/elapsed

# 5. GRADIENT DESCENT
print("\n[5] GRADIENT DESCENT (Linear Regression)")
print("-" * 50)

# Generate data: y = 2x + 1 + noise
data_x = [i * 0.1 for i in range(100)]
data_y = [2 * x + 1 + ((i*17)%100-50)/100 for i, x in enumerate(data_x)]

def linear_regression_gd(X, Y, lr=0.01, epochs=100):
    w, b = 0.0, 0.0
    n = len(X)
    for _ in range(epochs):
        # Predictions
        preds = [w * x + b for x in X]
        # Gradients
        dw = -2/n * sum((Y[i] - preds[i]) * X[i] for i in range(n))
        db = -2/n * sum(Y[i] - preds[i] for i in range(n))
        # Update
        w -= lr * dw
        b -= lr * db
    return w, b

t0 = time.time()
for _ in range(1000):
    w, b = linear_regression_gd(data_x, data_y)
elapsed = time.time() - t0
print(f"    1000×GD(100 samples, 100 epochs): {elapsed*1000:.2f}ms")
print(f"    Learned: y = {w:.3f}x + {b:.3f} (true: y = 2x + 1)")
results['gd'] = 1000/elapsed

# 6. NEURAL NETWORK FORWARD PASS
print("\n[6] NEURAL NETWORK (3-layer)")
print("-" * 50)

def nn_forward(inputs, W1, W2, W3):
    # Layer 1: 10 -> 32
    h1 = [0]*32
    for j in range(32):
        s = sum(inputs[i] * W1[i][j] for i in range(10))
        h1[j] = relu(s)
    # Layer 2: 32 -> 16
    h2 = [0]*16
    for j in range(16):
        s = sum(h1[i] * W2[i][j] for i in range(32))
        h2[j] = relu(s)
    # Layer 3: 16 -> 10
    out = [0]*10
    for j in range(10):
        out[j] = sum(h2[i] * W3[i][j] for i in range(16))
    return softmax(out)

# Initialize weights
W1 = [[(i*j%100-50)/100 for j in range(32)] for i in range(10)]
W2 = [[(i*j%100-50)/100 for j in range(16)] for i in range(32)]
W3 = [[(i*j%100-50)/100 for j in range(10)] for i in range(16)]

t0 = time.time()
for i in range(1000):
    inputs = [(i+j)%10/10 for j in range(10)]
    out = nn_forward(inputs, W1, W2, W3)
elapsed = time.time() - t0
print(f"    1000 forward passes: {elapsed*1000:.2f}ms ({1000/elapsed:.0f} inferences/sec)")
results['nn_forward'] = 1000/elapsed

# 7. BACKPROPAGATION
print("\n[7] BACKPROPAGATION (single layer)")
print("-" * 50)

def backprop_single(inputs, targets, W, lr=0.01):
    """Single layer backprop with sigmoid"""
    n_in, n_out = len(inputs), len(targets)
    # Forward
    outputs = [sigmoid(sum(inputs[i] * W[i][j] for i in range(n_in))) for j in range(n_out)]
    # Backward
    errors = [targets[j] - outputs[j] for j in range(n_out)]
    for i in range(n_in):
        for j in range(n_out):
            grad = errors[j] * outputs[j] * (1 - outputs[j]) * inputs[i]
            W[i][j] += lr * grad
    return sum(e*e for e in errors)

W = [[(i*j%100-50)/500 for j in range(5)] for i in range(10)]
inputs = [0.1 * i for i in range(10)]
targets = [0.2, 0.4, 0.6, 0.8, 0.5]

t0 = time.time()
for _ in range(10000):
    loss = backprop_single(inputs, targets, W)
elapsed = time.time() - t0
print(f"    10K backprop steps: {elapsed*1000:.2f}ms ({10000/elapsed:.0f} steps/sec)")
print(f"    Final loss: {loss:.6f}")
results['backprop'] = 10000/elapsed

# 8. K-MEANS CLUSTERING
print("\n[8] K-MEANS CLUSTERING")
print("-" * 50)

def kmeans(points, k, max_iter=20):
    # Initialize centroids
    centroids = points[:k]
    for _ in range(max_iter):
        # Assign points to clusters
        clusters = [[] for _ in range(k)]
        for p in points:
            dists = [sum((p[d] - c[d])**2 for d in range(len(p))) for c in centroids]
            closest = dists.index(min(dists))
            clusters[closest].append(p)
        # Update centroids
        for i in range(k):
            if clusters[i]:
                centroids[i] = [sum(p[d] for p in clusters[i])/len(clusters[i]) for d in range(len(points[0]))]
    return centroids, clusters

# Generate clustered data
points = []
for c in range(3):
    for i in range(100):
        points.append([c*5 + (i%10-5)*0.3, c*3 + (i//10-5)*0.3])

t0 = time.time()
for _ in range(100):
    centroids, clusters = kmeans(points, 3)
elapsed = time.time() - t0
print(f"    100×kmeans(300 pts, k=3): {elapsed*1000:.2f}ms ({100/elapsed:.0f} clusterings/sec)")
results['kmeans'] = 100/elapsed

# 9. LOSS FUNCTIONS
print("\n[9] LOSS FUNCTIONS (1M computations)")
print("-" * 50)

def mse_loss(pred, target):
    return sum((p-t)**2 for p, t in zip(pred, target)) / len(pred)

def cross_entropy(pred, target):
    eps = 1e-15
    return -sum(t * ln(max(p, eps)) for p, t in zip(pred, target))

def binary_cross_entropy(pred, target):
    eps = 1e-15
    return -sum(t*ln(max(p,eps)) + (1-t)*ln(max(1-p,eps)) for p, t in zip(pred, target)) / len(pred)

pred = [0.1, 0.3, 0.6]
target = [0.0, 0.0, 1.0]

t0 = time.time()
for _ in range(1000000):
    l1 = mse_loss(pred, target)
    l2 = cross_entropy(pred, target)
elapsed = time.time() - t0
print(f"    1M×(MSE+CE): {elapsed*1000:.2f}ms ({2000000/elapsed/1e6:.2f}M loss calcs/sec)")
results['loss'] = 2000000/elapsed

# 10. BATCH NORMALIZATION
print("\n[10] BATCH NORMALIZATION")
print("-" * 50)

def batch_norm(batch, gamma=1.0, beta=0.0, eps=1e-5):
    """Batch normalize a list of values"""
    mean = sum(batch) / len(batch)
    var = sum((x - mean)**2 for x in batch) / len(batch)
    std = sqrt(var + eps)
    return [(gamma * (x - mean) / std + beta) for x in batch]

batch = [i * 0.1 - 5 for i in range(100)]

t0 = time.time()
for _ in range(100000):
    normed = batch_norm(batch)
elapsed = time.time() - t0
print(f"    100K×batchnorm(100): {elapsed*1000:.2f}ms ({100000/elapsed/1e3:.1f}K norms/sec)")
results['batchnorm'] = 100000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  ML PRIMITIVES SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Activations:       {results['activations']/1e6:.2f}M ops/sec
  Softmax:           {results['softmax']/1e3:.1f}K/sec
  Dot Product:       {results['dot']/1e6:.2f}M dots/sec
  Matrix Multiply:   {results['matmul']/1e3:.1f}K matmuls/sec
  Gradient Descent:  {results['gd']:.0f} GD/sec
  NN Forward:        {results['nn_forward']:.0f} inferences/sec
  Backprop:          {results['backprop']:.0f} steps/sec
  K-Means:           {results['kmeans']:.0f} clusterings/sec
  Loss Functions:    {results['loss']/1e6:.2f}M calcs/sec
  Batch Norm:        {results['batchnorm']/1e3:.1f}K norms/sec
  
  TOTAL ML SCORE: {total/1e6:.2f}M points
""")
