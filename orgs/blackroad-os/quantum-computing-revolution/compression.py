#!/usr/bin/env python3
"""COMPRESSION ALGORITHMS - Pure arithmetic data compression"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🗜️ COMPRESSION ALGORITHMS - {hostname}")
print(f"{'='*70}\n")

results = {}

# 1. RUN-LENGTH ENCODING
print("[1] 📊 RUN-LENGTH ENCODING")
print("-" * 50)

def rle_encode(data):
    if not data: return []
    result = []
    count = 1
    prev = data[0]
    for i in range(1, len(data)):
        if data[i] == prev:
            count += 1
        else:
            result.append((prev, count))
            prev = data[i]
            count = 1
    result.append((prev, count))
    return result

def rle_decode(encoded):
    result = []
    for val, count in encoded:
        result.extend([val] * count)
    return result

test_data = [1,1,1,1,2,2,3,3,3,3,3,4,4,5,5,5,5,5,5,5,6,6,6] * 100

t0 = time.time()
for _ in range(10000):
    encoded = rle_encode(test_data)
    decoded = rle_decode(encoded)
elapsed = time.time() - t0
ratio = len(test_data) / (len(encoded) * 2)
print(f"    10K encode+decode: {elapsed*1000:.2f}ms ({20000/elapsed:.0f} ops/sec)")
print(f"    Compression ratio: {ratio:.2f}x")
results['rle'] = 20000/elapsed

# 2. LZ77-LIKE COMPRESSION
print("\n[2] 🔍 LZ77 SLIDING WINDOW")
print("-" * 50)

def lz77_encode(data, window_size=256, lookahead=16):
    result = []
    pos = 0
    while pos < len(data):
        best_len, best_dist = 0, 0
        start = max(0, pos - window_size)
        for i in range(start, pos):
            match_len = 0
            while (pos + match_len < len(data) and 
                   match_len < lookahead and 
                   data[i + match_len] == data[pos + match_len]):
                match_len += 1
            if match_len > best_len:
                best_len = match_len
                best_dist = pos - i
        if best_len >= 3:
            result.append((best_dist, best_len))
            pos += best_len
        else:
            result.append((0, data[pos]))
            pos += 1
    return result

def lz77_decode(encoded):
    result = []
    for item in encoded:
        if item[0] == 0:
            result.append(item[1])
        else:
            dist, length = item
            start = len(result) - dist
            for i in range(length):
                result.append(result[start + i])
    return result

# Repetitive data for LZ77
test_lz = [ord(c) for c in "abracadabra" * 50 + "mississippi" * 50]

t0 = time.time()
for _ in range(100):
    encoded = lz77_encode(test_lz)
    decoded = lz77_decode(encoded)
elapsed = time.time() - t0
ratio = len(test_lz) / len(encoded)
print(f"    100 encode+decode: {elapsed*1000:.2f}ms ({200/elapsed:.0f} ops/sec)")
print(f"    Compression ratio: {ratio:.2f}x")
results['lz77'] = 200/elapsed

# 3. HUFFMAN CODING
print("\n[3] 🌳 HUFFMAN CODING")
print("-" * 50)

def build_huffman(freq):
    """Build Huffman tree and return codes"""
    # Priority queue as list of (freq, id, node)
    heap = []
    node_id = 0
    for symbol, f in freq.items():
        heap.append((f, node_id, ('leaf', symbol)))
        node_id += 1
    
    while len(heap) > 1:
        heap.sort()
        f1, _, n1 = heap.pop(0)
        f2, _, n2 = heap.pop(0)
        heap.append((f1 + f2, node_id, ('node', n1, n2)))
        node_id += 1
    
    # Extract codes
    codes = {}
    def traverse(node, code):
        if node[0] == 'leaf':
            codes[node[1]] = code if code else '0'
        else:
            traverse(node[1], code + '0')
            traverse(node[2], code + '1')
    
    if heap:
        traverse(heap[0][2], '')
    return codes

def huffman_encode(data, codes):
    return ''.join(codes[d] for d in data)

def huffman_decode(bits, root):
    result = []
    node = root
    for bit in bits:
        if bit == '0':
            node = node[1] if node[0] == 'node' else node
        else:
            node = node[2] if node[0] == 'node' else node
        if node[0] == 'leaf':
            result.append(node[1])
            node = root
    return result

# Build frequency table
text_data = list("the quick brown fox jumps over the lazy dog " * 100)
freq = {}
for c in text_data:
    freq[c] = freq.get(c, 0) + 1

t0 = time.time()
for _ in range(1000):
    codes = build_huffman(freq)
    encoded = huffman_encode(text_data, codes)
elapsed = time.time() - t0
ratio = len(text_data) * 8 / len(encoded)
print(f"    1000 Huffman builds+encodes: {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
print(f"    Compression ratio: {ratio:.2f}x ({len(encoded)} bits for {len(text_data)} chars)")
results['huffman'] = 1000/elapsed

# 4. DELTA ENCODING
print("\n[4] 📈 DELTA ENCODING")
print("-" * 50)

def delta_encode(data):
    if not data: return []
    result = [data[0]]
    for i in range(1, len(data)):
        result.append(data[i] - data[i-1])
    return result

def delta_decode(encoded):
    if not encoded: return []
    result = [encoded[0]]
    for i in range(1, len(encoded)):
        result.append(result[-1] + encoded[i])
    return result

# Monotonic data (good for delta)
mono_data = list(range(0, 10000, 3))

t0 = time.time()
for _ in range(10000):
    encoded = delta_encode(mono_data)
    decoded = delta_decode(encoded)
elapsed = time.time() - t0
print(f"    10K encode+decode: {elapsed*1000:.2f}ms ({20000/elapsed:.0f} ops/sec)")
print(f"    Original range: [0, {max(mono_data)}], Delta range: [{min(encoded)}, {max(encoded)}]")
results['delta'] = 20000/elapsed

# 5. BWT (Burrows-Wheeler Transform)
print("\n[5] 🔄 BURROWS-WHEELER TRANSFORM")
print("-" * 50)

def bwt_encode(s):
    """BWT encode string"""
    n = len(s)
    # Create all rotations
    rotations = [(s[i:] + s[:i], i) for i in range(n)]
    rotations.sort()
    # Return last column and original index
    last_col = ''.join(r[0][-1] for r in rotations)
    orig_idx = [i for i, (r, idx) in enumerate(rotations) if idx == 0][0]
    return last_col, orig_idx

def bwt_decode(last_col, orig_idx):
    """BWT decode"""
    n = len(last_col)
    # Build first column
    first_col = sorted(last_col)
    # Build T-ranking
    count = {}
    ranks = []
    for c in last_col:
        ranks.append(count.get(c, 0))
        count[c] = count.get(c, 0) + 1
    
    # Build next array
    count = {}
    first_occ = {}
    for i, c in enumerate(first_col):
        if c not in first_occ:
            first_occ[c] = i
    
    # Decode
    result = []
    idx = orig_idx
    for _ in range(n):
        c = last_col[idx]
        result.append(c)
        idx = first_occ[c] + ranks[idx]
    
    return ''.join(result)

test_str = "banana" * 50

t0 = time.time()
for _ in range(100):
    encoded, idx = bwt_encode(test_str)
    decoded = bwt_decode(encoded, idx)
elapsed = time.time() - t0
print(f"    100 BWT encode+decode: {elapsed*1000:.2f}ms ({200/elapsed:.0f} ops/sec)")
print(f"    'banana' BWT: '{bwt_encode('banana')[0]}'")
results['bwt'] = 200/elapsed

# 6. MTF (Move-to-Front)
print("\n[6] ➡️ MOVE-TO-FRONT")
print("-" * 50)

def mtf_encode(data, alphabet=None):
    if alphabet is None:
        alphabet = sorted(set(data))
    symbols = list(alphabet)
    result = []
    for c in data:
        idx = symbols.index(c)
        result.append(idx)
        symbols.insert(0, symbols.pop(idx))
    return result, alphabet

def mtf_decode(encoded, alphabet):
    symbols = list(alphabet)
    result = []
    for idx in encoded:
        c = symbols[idx]
        result.append(c)
        symbols.insert(0, symbols.pop(idx))
    return result

# MTF works great after BWT
bwt_out, _ = bwt_encode(test_str)

t0 = time.time()
for _ in range(1000):
    encoded, alpha = mtf_encode(list(bwt_out))
    decoded = mtf_decode(encoded, alpha)
elapsed = time.time() - t0
print(f"    1000 MTF encode+decode: {elapsed*1000:.2f}ms ({2000/elapsed:.0f} ops/sec)")
avg_val = sum(encoded) / len(encoded)
print(f"    Average MTF index: {avg_val:.2f} (lower = better for entropy coding)")
results['mtf'] = 2000/elapsed

# 7. ARITHMETIC-LIKE CODING (Simplified)
print("\n[7] 🔢 RANGE CODING (Simplified)")
print("-" * 50)

def range_encode(data, probs):
    """Simplified range encoding"""
    low, high = 0, 0xFFFFFFFF
    
    for symbol in data:
        range_size = high - low + 1
        cum = 0
        for s, p in probs.items():
            if s == symbol:
                new_low = low + (range_size * cum) // 10000
                new_high = low + (range_size * (cum + p)) // 10000 - 1
                low, high = new_low, new_high
                break
            cum += p
        
        # Renormalize
        while (high ^ low) < 0x80000000:
            high = (high << 1) | 1
            low = low << 1
            high &= 0xFFFFFFFF
            low &= 0xFFFFFFFF
    
    return low

# Simple probability model
probs = {'a': 4000, 'b': 3000, 'c': 2000, 'd': 1000}  # Must sum to 10000
test_range = ['a', 'b', 'a', 'c', 'a', 'b', 'd'] * 10

t0 = time.time()
for _ in range(10000):
    encoded = range_encode(test_range, probs)
elapsed = time.time() - t0
print(f"    10K range encodings: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
print(f"    Encoded value: {encoded:08x}")
results['range'] = 10000/elapsed

# 8. DICTIONARY CODING
print("\n[8] 📖 DICTIONARY CODING")
print("-" * 50)

def dict_encode(text, min_len=3, max_entries=256):
    """Simple dictionary-based compression"""
    dictionary = {}
    next_code = 256
    output = []
    
    i = 0
    while i < len(text):
        # Find longest match
        best_match = text[i]
        best_len = 1
        
        for length in range(min_len, min(32, len(text) - i + 1)):
            substr = text[i:i+length]
            if substr in dictionary:
                best_match = dictionary[substr]
                best_len = length
        
        output.append(best_match)
        
        # Add new phrase to dictionary
        if i + best_len < len(text) and next_code < max_entries + 256:
            new_phrase = text[i:i+best_len+1]
            if new_phrase not in dictionary:
                dictionary[new_phrase] = next_code
                next_code += 1
        
        i += best_len
    
    return output

test_dict = "abracadabra" * 100 + "alakazam" * 50

t0 = time.time()
for _ in range(100):
    encoded = dict_encode(test_dict)
elapsed = time.time() - t0
ratio = len(test_dict) / len(encoded)
print(f"    100 dictionary encodings: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
print(f"    Compression ratio: {ratio:.2f}x")
results['dictionary'] = 100/elapsed

# 9. BIT PACKING
print("\n[9] 📦 BIT PACKING")
print("-" * 50)

def bit_pack(values, bits_per_value):
    """Pack integers into minimal bits"""
    result = 0
    shift = 0
    for v in values:
        result |= (v & ((1 << bits_per_value) - 1)) << shift
        shift += bits_per_value
    return result, shift

def bit_unpack(packed, bits_per_value, count):
    """Unpack integers"""
    mask = (1 << bits_per_value) - 1
    result = []
    for i in range(count):
        result.append((packed >> (i * bits_per_value)) & mask)
    return result

# Pack 4-bit values
values = [i % 16 for i in range(100)]

t0 = time.time()
for _ in range(100000):
    packed, total_bits = bit_pack(values, 4)
    unpacked = bit_unpack(packed, 4, len(values))
elapsed = time.time() - t0
print(f"    100K pack+unpack: {elapsed*1000:.2f}ms ({200000/elapsed:.0f} ops/sec)")
print(f"    100 values × 4 bits = {total_bits} bits (vs 800 for 8-bit)")
results['bitpack'] = 200000/elapsed

# 10. ENTROPY CALCULATION
print("\n[10] 📊 ENTROPY ANALYSIS")
print("-" * 50)

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

def log2(x):
    return ln(x) / 0.693147180559945

def entropy(data):
    """Calculate Shannon entropy in bits"""
    freq = {}
    for d in data:
        freq[d] = freq.get(d, 0) + 1
    n = len(data)
    h = 0
    for f in freq.values():
        p = f / n
        if p > 0:
            h -= p * log2(p)
    return h

# Different data distributions
uniform_data = list(range(256)) * 10
skewed_data = [0] * 1000 + [1] * 500 + [2] * 250 + [3] * 125
text_bytes = [ord(c) for c in "the quick brown fox" * 100]

t0 = time.time()
for _ in range(10000):
    e1 = entropy(uniform_data)
    e2 = entropy(skewed_data)
    e3 = entropy(text_bytes)
elapsed = time.time() - t0
print(f"    30K entropy calculations: {elapsed*1000:.2f}ms ({30000/elapsed:.0f}/sec)")
print(f"    Uniform: {e1:.2f} bits, Skewed: {e2:.2f} bits, Text: {e3:.2f} bits")
results['entropy'] = 30000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 COMPRESSION SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  RLE:              {results['rle']:.0f} ops/sec
  LZ77:             {results['lz77']:.0f} ops/sec
  Huffman:          {results['huffman']:.0f} ops/sec
  Delta:            {results['delta']:.0f} ops/sec
  BWT:              {results['bwt']:.0f} ops/sec
  Move-to-Front:    {results['mtf']:.0f} ops/sec
  Range Coding:     {results['range']:.0f} ops/sec
  Dictionary:       {results['dictionary']:.0f} ops/sec
  Bit Packing:      {results['bitpack']:.0f} ops/sec
  Entropy:          {results['entropy']:.0f} ops/sec
  
  🗜️ TOTAL COMPRESSION SCORE: {total:.0f} points
""")
