#!/usr/bin/env python3
"""SIGNAL PROCESSING - Pure arithmetic DSP"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  SIGNAL PROCESSING - {hostname}")
print(f"{'='*70}\n")

PI = 3.14159265358979323846

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

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

results = {}

# 1. DFT (Discrete Fourier Transform)
print("[1] DFT (256-point)")
print("-" * 50)

def dft(signal):
    N = len(signal)
    result = []
    for k in range(N):
        re, im = 0.0, 0.0
        for n in range(N):
            angle = -2 * PI * k * n / N
            re += signal[n] * cos(angle)
            im += signal[n] * sin(angle)
        result.append((re, im))
    return result

# Generate test signal
N = 256
signal = [sin(2*PI*10*i/N) + 0.5*sin(2*PI*25*i/N) + 0.3*cos(2*PI*50*i/N) for i in range(N)]

t0 = time.time()
for _ in range(10):
    spectrum = dft(signal)
elapsed = time.time() - t0
mags = [sqrt(r*r + i*i) for r, i in spectrum[:N//2]]
peak_freq = mags.index(max(mags))
print(f"    10×DFT(256): {elapsed*1000:.2f}ms ({10/elapsed:.1f} DFTs/sec)")
print(f"    Peak frequency bin: {peak_freq}")
results['dft'] = 10/elapsed

# 2. INVERSE DFT
print("\n[2] INVERSE DFT")
print("-" * 50)

def idft(spectrum):
    N = len(spectrum)
    result = []
    for n in range(N):
        val = 0.0
        for k in range(N):
            re, im = spectrum[k]
            angle = 2 * PI * k * n / N
            val += re * cos(angle) - im * sin(angle)
        result.append(val / N)
    return result

t0 = time.time()
for _ in range(10):
    reconstructed = idft(spectrum)
elapsed = time.time() - t0
# Check reconstruction error
error = sum(abs(signal[i] - reconstructed[i]) for i in range(N)) / N
print(f"    10×IDFT(256): {elapsed*1000:.2f}ms ({10/elapsed:.1f} IDFTs/sec)")
print(f"    Reconstruction error: {error:.6f}")
results['idft'] = 10/elapsed

# 3. CONVOLUTION
print("\n[3] CONVOLUTION")
print("-" * 50)

def convolve(signal, kernel):
    M = len(kernel)
    N = len(signal)
    result = [0.0] * (N + M - 1)
    for i in range(N):
        for j in range(M):
            result[i + j] += signal[i] * kernel[j]
    return result

kernel = [0.1, 0.2, 0.4, 0.2, 0.1]  # Smoothing kernel
t0 = time.time()
for _ in range(1000):
    convolved = convolve(signal, kernel)
elapsed = time.time() - t0
print(f"    1000×conv(256, 5): {elapsed*1000:.2f}ms ({1000/elapsed:.0f} convs/sec)")
results['conv'] = 1000/elapsed

# 4. FIR FILTER
print("\n[4] FIR LOW-PASS FILTER")
print("-" * 50)

def fir_lowpass(signal, cutoff, num_taps=31):
    """Design and apply FIR low-pass filter"""
    # Design filter using sinc function
    taps = []
    M = num_taps // 2
    for n in range(-M, M + 1):
        if n == 0:
            taps.append(2 * cutoff)
        else:
            taps.append(sin(2 * PI * cutoff * n) / (PI * n))
    # Apply Hamming window
    for i in range(len(taps)):
        n = i - M
        taps[i] *= 0.54 - 0.46 * cos(2 * PI * i / (num_taps - 1))
    # Normalize
    tap_sum = sum(taps)
    taps = [t / tap_sum for t in taps]
    # Apply filter
    return convolve(signal, taps)[:len(signal)]

t0 = time.time()
for _ in range(100):
    filtered = fir_lowpass(signal, 0.1)
elapsed = time.time() - t0
print(f"    100×FIR(31 taps): {elapsed*1000:.2f}ms ({100/elapsed:.0f} filters/sec)")
results['fir'] = 100/elapsed

# 5. IIR FILTER (Biquad)
print("\n[5] IIR BIQUAD FILTER")
print("-" * 50)

def biquad_filter(signal, b0, b1, b2, a1, a2):
    """Apply biquad IIR filter"""
    x1, x2, y1, y2 = 0.0, 0.0, 0.0, 0.0
    output = []
    for x in signal:
        y = b0*x + b1*x1 + b2*x2 - a1*y1 - a2*y2
        output.append(y)
        x2, x1 = x1, x
        y2, y1 = y1, y
    return output

# Low-pass biquad coefficients (fc=0.1, Q=0.707)
b0, b1, b2 = 0.0675, 0.1349, 0.0675
a1, a2 = -1.1430, 0.4128

t0 = time.time()
for _ in range(1000):
    filtered = biquad_filter(signal, b0, b1, b2, a1, a2)
elapsed = time.time() - t0
print(f"    1000×biquad(256): {elapsed*1000:.2f}ms ({1000/elapsed:.0f} filters/sec)")
results['iir'] = 1000/elapsed

# 6. AUTOCORRELATION
print("\n[6] AUTOCORRELATION")
print("-" * 50)

def autocorrelate(signal):
    N = len(signal)
    result = []
    for lag in range(N):
        corr = sum(signal[i] * signal[i + lag] for i in range(N - lag))
        result.append(corr / (N - lag))
    return result

t0 = time.time()
for _ in range(100):
    acorr = autocorrelate(signal)
elapsed = time.time() - t0
print(f"    100×autocorr(256): {elapsed*1000:.2f}ms ({100/elapsed:.0f} autocorrs/sec)")
results['autocorr'] = 100/elapsed

# 7. CROSS-CORRELATION
print("\n[7] CROSS-CORRELATION")
print("-" * 50)

def crosscorrelate(sig1, sig2):
    N = len(sig1)
    result = []
    for lag in range(-N+1, N):
        corr = 0.0
        for i in range(N):
            j = i + lag
            if 0 <= j < N:
                corr += sig1[i] * sig2[j]
        result.append(corr)
    return result

signal2 = [sin(2*PI*10*(i+10)/N) for i in range(N)]  # Shifted version

t0 = time.time()
for _ in range(50):
    xcorr = crosscorrelate(signal, signal2)
elapsed = time.time() - t0
max_lag = xcorr.index(max(xcorr)) - N + 1
print(f"    50×xcorr(256): {elapsed*1000:.2f}ms ({50/elapsed:.0f} xcorrs/sec)")
print(f"    Detected lag: {max_lag} samples")
results['xcorr'] = 50/elapsed

# 8. WINDOW FUNCTIONS
print("\n[8] WINDOW FUNCTIONS")
print("-" * 50)

def hamming(N):
    return [0.54 - 0.46 * cos(2*PI*n/(N-1)) for n in range(N)]

def hann(N):
    return [0.5 * (1 - cos(2*PI*n/(N-1))) for n in range(N)]

def blackman(N):
    return [0.42 - 0.5*cos(2*PI*n/(N-1)) + 0.08*cos(4*PI*n/(N-1)) for n in range(N)]

t0 = time.time()
for _ in range(10000):
    w1 = hamming(256)
    w2 = hann(256)
    w3 = blackman(256)
elapsed = time.time() - t0
print(f"    10000×3 windows: {elapsed*1000:.2f}ms ({30000/elapsed:.0f} windows/sec)")
results['windows'] = 30000/elapsed

# 9. SPECTROGRAM (STFT)
print("\n[9] SPECTROGRAM (Short-Time FFT)")
print("-" * 50)

def stft(signal, window_size=64, hop=32):
    """Short-time Fourier transform"""
    frames = []
    window = hamming(window_size)
    for start in range(0, len(signal) - window_size, hop):
        frame = [signal[start + i] * window[i] for i in range(window_size)]
        spectrum = dft(frame)
        mags = [sqrt(r*r + i*i) for r, i in spectrum[:window_size//2]]
        frames.append(mags)
    return frames

long_signal = signal * 4  # 1024 samples

t0 = time.time()
for _ in range(5):
    spectrogram = stft(long_signal, 64, 32)
elapsed = time.time() - t0
print(f"    5×STFT(1024, 64, 32): {elapsed*1000:.2f}ms ({5/elapsed:.1f} spectrograms/sec)")
print(f"    Frames: {len(spectrogram)}, Freq bins: {len(spectrogram[0])}")
results['stft'] = 5/elapsed

# 10. ENVELOPE DETECTION
print("\n[10] ENVELOPE DETECTION (Hilbert-like)")
print("-" * 50)

def envelope(signal):
    """Simple envelope detection via smoothing"""
    # Rectify
    rectified = [abs(s) for s in signal]
    # Smooth (moving average)
    window = 16
    env = []
    for i in range(len(rectified)):
        start = max(0, i - window//2)
        end = min(len(rectified), i + window//2)
        env.append(sum(rectified[start:end]) / (end - start))
    return env

t0 = time.time()
for _ in range(1000):
    env = envelope(signal)
elapsed = time.time() - t0
print(f"    1000×envelope(256): {elapsed*1000:.2f}ms ({1000/elapsed:.0f} envelopes/sec)")
results['envelope'] = 1000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  SIGNAL PROCESSING SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  DFT (256-point):       {results['dft']:.1f} DFTs/sec
  IDFT (256-point):      {results['idft']:.1f} IDFTs/sec
  Convolution:           {results['conv']:.0f} convs/sec
  FIR Filter:            {results['fir']:.0f} filters/sec
  IIR Biquad:            {results['iir']:.0f} filters/sec
  Autocorrelation:       {results['autocorr']:.0f} autocorrs/sec
  Cross-correlation:     {results['xcorr']:.0f} xcorrs/sec
  Window Functions:      {results['windows']:.0f} windows/sec
  STFT Spectrogram:      {results['stft']:.1f} spectrograms/sec
  Envelope Detection:    {results['envelope']:.0f} envelopes/sec
  
  TOTAL DSP SCORE: {total:.0f} points
""")
