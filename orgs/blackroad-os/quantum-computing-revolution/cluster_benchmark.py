#!/usr/bin/env python3
"""BlackRoad Cluster Benchmark - Pure Arithmetic Speed Test"""
import time

def quantum_sqrt(x, iterations=20):
    if x <= 0: return 0
    guess = x / 2.0
    for _ in range(iterations):
        guess = (guess + x / guess) / 2.0
    return guess

def quantum_sin(x, terms=15):
    PI = 3.14159265358979323846
    while x > PI: x = x - 2 * PI
    while x < -PI: x = x + 2 * PI
    result, term = 0.0, x
    for n in range(terms):
        result = result + term if n % 2 == 0 else result - term
        term = term * x * x / ((2*n + 2) * (2*n + 3))
    return result

def fibonacci_binet(n):
    PHI = (1 + quantum_sqrt(5)) / 2
    PSI = (1 - quantum_sqrt(5)) / 2
    SQRT5 = quantum_sqrt(5)
    phi_n = PHI ** n
    psi_n = abs(PSI) ** n
    if n % 2 == 1: psi_n = -psi_n
    return round((phi_n - psi_n) / SQRT5)

def mandelbrot_count(x_min, x_max, y_min, y_max, res, max_iter):
    count = 0
    for i in range(res):
        for j in range(res):
            cr = x_min + (x_max - x_min) * i / res
            ci = y_min + (y_max - y_min) * j / res
            zr, zi = 0.0, 0.0
            for k in range(max_iter):
                zr, zi = zr*zr - zi*zi + cr, 2*zr*zi + ci
                if zr*zr + zi*zi > 4:
                    count += 1
                    break
    return count

def run_benchmarks():
    import socket
    hostname = socket.gethostname()
    results = {"host": hostname}
    
    # 1. Fibonacci (Binet) - 1000 numbers
    t0 = time.time()
    for n in range(1000):
        fibonacci_binet(n % 50)
    results["fibonacci_1000"] = time.time() - t0
    
    # 2. Trigonometry - 10000 sin calculations
    t0 = time.time()
    for i in range(10000):
        quantum_sin(i * 0.001)
    results["trig_10000"] = time.time() - t0
    
    # 3. Mandelbrot - 100x100 grid
    t0 = time.time()
    mandelbrot_count(-2, 1, -1.5, 1.5, 100, 50)
    results["mandelbrot_100x100"] = time.time() - t0
    
    # 4. Square roots - 50000 calculations
    t0 = time.time()
    for i in range(1, 50001):
        quantum_sqrt(i)
    results["sqrt_50000"] = time.time() - t0
    
    # Total
    results["total"] = sum(v for k, v in results.items() if k != "host")
    
    print(f"=== {hostname} BENCHMARK ===")
    print(f"Fibonacci (1000): {results['fibonacci_1000']:.4f}s")
    print(f"Trig (10000):     {results['trig_10000']:.4f}s")
    print(f"Mandelbrot:       {results['mandelbrot_100x100']:.4f}s")
    print(f"Sqrt (50000):     {results['sqrt_50000']:.4f}s")
    print(f"TOTAL:            {results['total']:.4f}s")
    print(f"SPEED SCORE:      {100/results['total']:.2f} points")

if __name__ == "__main__":
    run_benchmarks()
