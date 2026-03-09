#!/usr/bin/env python3
"""MEMORY BANDWIDTH TEST"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*60}")
print(f"  MEMORY BANDWIDTH - {hostname}")
print(f"{'='*60}\n")

# Test 1: List operations
print("[1] LIST OPERATIONS")
t0 = time.time()
data = list(range(1000000))
create_time = time.time() - t0

t0 = time.time()
total = sum(data)
sum_time = time.time() - t0

t0 = time.time()
data2 = [x * 2 for x in data]
map_time = time.time() - t0

print(f"    Create 1M list:  {create_time*1000:.2f}ms ({1000000/create_time/1e6:.2f}M items/sec)")
print(f"    Sum 1M items:    {sum_time*1000:.2f}ms ({1000000/sum_time/1e6:.2f}M items/sec)")
print(f"    Map 1M items:    {map_time*1000:.2f}ms ({1000000/map_time/1e6:.2f}M items/sec)")

# Test 2: Dictionary operations
print("\n[2] DICTIONARY OPERATIONS")
t0 = time.time()
d = {i: i*2 for i in range(100000)}
create_time = time.time() - t0

t0 = time.time()
for i in range(100000):
    _ = d.get(i)
lookup_time = time.time() - t0

print(f"    Create 100K dict: {create_time*1000:.2f}ms ({100000/create_time/1e6:.2f}M ops/sec)")
print(f"    100K lookups:     {lookup_time*1000:.2f}ms ({100000/lookup_time/1e6:.2f}M ops/sec)")

# Test 3: String operations
print("\n[3] STRING OPERATIONS")
t0 = time.time()
s = "x" * 1000000
str_time = time.time() - t0

t0 = time.time()
count = s.count("x")
count_time = time.time() - t0

t0 = time.time()
s2 = s.replace("x", "y")
replace_time = time.time() - t0

print(f"    Create 1MB string:   {str_time*1000:.2f}ms")
print(f"    Count 1M chars:      {count_time*1000:.2f}ms ({1000000/count_time/1e6:.2f}M chars/sec)")
print(f"    Replace 1M chars:    {replace_time*1000:.2f}ms ({1000000/replace_time/1e6:.2f}M chars/sec)")

# Test 4: Array-like numeric operations
print("\n[4] NUMERIC ARRAY OPERATIONS")
arr = list(range(100000))

t0 = time.time()
for _ in range(100):
    total = 0
    for x in arr:
        total += x
loop_time = time.time() - t0

t0 = time.time()
for _ in range(100):
    arr2 = [x * x for x in arr]
square_time = time.time() - t0

print(f"    100x sum 100K:    {loop_time*1000:.2f}ms ({100*100000/loop_time/1e6:.2f}M ops/sec)")
print(f"    100x square 100K: {square_time*1000:.2f}ms ({100*100000/square_time/1e6:.2f}M ops/sec)")

# Test 5: Bytes operations
print("\n[5] BYTES OPERATIONS")
t0 = time.time()
b = bytes(range(256)) * 10000
bytes_time = time.time() - t0
size_mb = len(b) / 1e6

t0 = time.time()
b2 = b + b
concat_time = time.time() - t0

print(f"    Create {size_mb:.1f}MB bytes: {bytes_time*1000:.2f}ms ({size_mb/bytes_time:.0f} MB/sec)")
print(f"    Concat {size_mb*2:.1f}MB:      {concat_time*1000:.2f}ms ({size_mb*2/concat_time:.0f} MB/sec)")

print(f"\n{'='*60}")
print(f"  MEMORY SUMMARY - {hostname}")
print(f"{'='*60}")
