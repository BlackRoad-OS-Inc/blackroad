#!/usr/bin/env python3
"""Distributed Mandelbrot - Each node renders different region"""
import socket
import time

def mandelbrot_pixel(cr, ci, max_iter=100):
    zr, zi = 0.0, 0.0
    for i in range(max_iter):
        zr, zi = zr*zr - zi*zi + cr, 2*zr*zi + ci
        if zr*zr + zi*zi > 4:
            return i
    return max_iter

def render_section(x_min, x_max, y_min, y_max, width=60, height=20, max_iter=80):
    chars = " .'`^\",:;Il!i><~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$"
    result = []
    for row in range(height):
        line = ""
        for col in range(width):
            cr = x_min + (x_max - x_min) * col / width
            ci = y_max - (y_max - y_min) * row / height
            iters = mandelbrot_pixel(cr, ci, max_iter)
            char_idx = min(iters * len(chars) // max_iter, len(chars) - 1)
            line += chars[char_idx]
        result.append(line)
    return "\n".join(result)

hostname = socket.gethostname()

# Each host gets a different region of the Mandelbrot set
regions = {
    "octavia": (-0.75, -0.70, 0.10, 0.15, "Seahorse Valley"),
    "alice": (-1.5, -1.0, -0.5, 0.5, "Main Bulb Left"),
    "lucidia": (-0.2, 0.2, -0.8, -0.4, "Tail Region"),
    "aria": (-0.77, -0.74, 0.05, 0.08, "Deep Seahorse"),
    "shellfish": (-2.0, 0.5, -1.2, 1.2, "Full View"),
}

seed = sum(ord(c) for c in hostname)
default_region = (-2.0 + (seed%20)*0.05, -1.5 + (seed%20)*0.05, -1.0, 1.0, f"Region {seed%20}")
region = regions.get(hostname, default_region)

print(f"=== {hostname}: {region[4]} ===")
print(f"Bounds: x=[{region[0]:.3f}, {region[1]:.3f}] y=[{region[2]:.3f}, {region[3]:.3f}]")

t0 = time.time()
art = render_section(region[0], region[1], region[2], region[3], width=50, height=15)
elapsed = time.time() - t0

print(art)
print(f"\nRender time: {elapsed:.3f}s | Pixels: 750")
