#!/usr/bin/env python3
"""STRING ALGORITHMS - Pure arithmetic text processing"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  📝 STRING ALGORITHMS - {hostname}")
print(f"{'='*70}\n")

results = {}

# 1. KMP (Knuth-Morris-Pratt)
print("[1] 🔍 KMP PATTERN MATCHING")
print("-" * 50)

def kmp_table(pattern):
    m = len(pattern)
    lps = [0] * m
    length = 0
    i = 1
    while i < m:
        if pattern[i] == pattern[length]:
            length += 1
            lps[i] = length
            i += 1
        elif length != 0:
            length = lps[length - 1]
        else:
            lps[i] = 0
            i += 1
    return lps

def kmp_search(text, pattern):
    n, m = len(text), len(pattern)
    lps = kmp_table(pattern)
    matches = []
    i = j = 0
    while i < n:
        if pattern[j] == text[i]:
            i += 1
            j += 1
        if j == m:
            matches.append(i - j)
            j = lps[j - 1]
        elif i < n and pattern[j] != text[i]:
            if j != 0:
                j = lps[j - 1]
            else:
                i += 1
    return matches

text = "ababcababcababcababc" * 100
pattern = "ababc"

t0 = time.time()
for _ in range(10000):
    matches = kmp_search(text, pattern)
elapsed = time.time() - t0
print(f"    10K searches in 2000-char text: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
print(f"    Found {len(matches)} matches")
results['kmp'] = 10000/elapsed

# 2. RABIN-KARP
print("\n[2] 🔢 RABIN-KARP HASHING")
print("-" * 50)

def rabin_karp(text, pattern, base=256, prime=101):
    n, m = len(text), len(pattern)
    h_pattern = 0
    h_text = 0
    h = 1
    
    for i in range(m - 1):
        h = (h * base) % prime
    
    for i in range(m):
        h_pattern = (base * h_pattern + ord(pattern[i])) % prime
        h_text = (base * h_text + ord(text[i])) % prime
    
    matches = []
    for i in range(n - m + 1):
        if h_pattern == h_text:
            if text[i:i+m] == pattern:
                matches.append(i)
        if i < n - m:
            h_text = (base * (h_text - ord(text[i]) * h) + ord(text[i + m])) % prime
            if h_text < 0:
                h_text += prime
    
    return matches

t0 = time.time()
for _ in range(10000):
    matches = rabin_karp(text, pattern)
elapsed = time.time() - t0
print(f"    10K Rabin-Karp searches: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
results['rabinkarp'] = 10000/elapsed

# 3. BOYER-MOORE (simplified)
print("\n[3] ⚡ BOYER-MOORE BAD CHARACTER")
print("-" * 50)

def boyer_moore_bad(text, pattern):
    n, m = len(text), len(pattern)
    
    # Bad character table
    bad = {}
    for i, c in enumerate(pattern):
        bad[c] = i
    
    matches = []
    s = 0
    while s <= n - m:
        j = m - 1
        while j >= 0 and pattern[j] == text[s + j]:
            j -= 1
        if j < 0:
            matches.append(s)
            s += 1
        else:
            s += max(1, j - bad.get(text[s + j], -1))
    
    return matches

t0 = time.time()
for _ in range(10000):
    matches = boyer_moore_bad(text, pattern)
elapsed = time.time() - t0
print(f"    10K Boyer-Moore searches: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
results['boyermoore'] = 10000/elapsed

# 4. SUFFIX ARRAY
print("\n[4] 📊 SUFFIX ARRAY")
print("-" * 50)

def suffix_array(s):
    n = len(s)
    suffixes = [(s[i:], i) for i in range(n)]
    suffixes.sort()
    return [idx for _, idx in suffixes]

def lcp_array(s, sa):
    n = len(s)
    rank = [0] * n
    for i, idx in enumerate(sa):
        rank[idx] = i
    
    lcp = [0] * (n - 1)
    k = 0
    for i in range(n):
        if rank[i] == n - 1:
            k = 0
            continue
        j = sa[rank[i] + 1]
        while i + k < n and j + k < n and s[i + k] == s[j + k]:
            k += 1
        lcp[rank[i]] = k
        if k > 0:
            k -= 1
    return lcp

short_text = "banana$"

t0 = time.time()
for _ in range(10000):
    sa = suffix_array(short_text)
    lcp = lcp_array(short_text, sa)
elapsed = time.time() - t0
print(f"    10K suffix+LCP arrays: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
print(f"    SA: {sa}, LCP: {lcp}")
results['suffix'] = 10000/elapsed

# 5. LONGEST COMMON SUBSEQUENCE
print("\n[5] 📏 LONGEST COMMON SUBSEQUENCE")
print("-" * 50)

def lcs_length(s1, s2):
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if s1[i-1] == s2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    return dp[m][n]

s1 = "AGGTAB"
s2 = "GXTXAYB"

t0 = time.time()
for _ in range(100000):
    length = lcs_length(s1, s2)
elapsed = time.time() - t0
print(f"    100K LCS computations: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
print(f"    LCS length of '{s1}' and '{s2}': {length}")
results['lcs'] = 100000/elapsed

# 6. LONGEST PALINDROMIC SUBSTRING
print("\n[6] 🔄 LONGEST PALINDROME")
print("-" * 50)

def longest_palindrome(s):
    if not s: return ""
    n = len(s)
    start, max_len = 0, 1
    
    for i in range(n):
        # Odd length
        l, r = i, i
        while l >= 0 and r < n and s[l] == s[r]:
            if r - l + 1 > max_len:
                start = l
                max_len = r - l + 1
            l -= 1
            r += 1
        
        # Even length
        l, r = i, i + 1
        while l >= 0 and r < n and s[l] == s[r]:
            if r - l + 1 > max_len:
                start = l
                max_len = r - l + 1
            l -= 1
            r += 1
    
    return s[start:start + max_len]

test_str = "babad" * 20

t0 = time.time()
for _ in range(10000):
    pal = longest_palindrome(test_str)
elapsed = time.time() - t0
print(f"    10K palindrome searches: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
print(f"    Longest palindrome: '{pal[:20]}...'")
results['palindrome'] = 10000/elapsed

# 7. Z-ALGORITHM
print("\n[7] 📐 Z-ALGORITHM")
print("-" * 50)

def z_array(s):
    n = len(s)
    z = [0] * n
    l, r = 0, 0
    
    for i in range(1, n):
        if i > r:
            l, r = i, i
            while r < n and s[r - l] == s[r]:
                r += 1
            z[i] = r - l
            r -= 1
        else:
            k = i - l
            if z[k] < r - i + 1:
                z[i] = z[k]
            else:
                l = i
                while r < n and s[r - l] == s[r]:
                    r += 1
                z[i] = r - l
                r -= 1
    
    return z

t0 = time.time()
for _ in range(50000):
    z = z_array("aabxaabxcaabxaabxay")
elapsed = time.time() - t0
print(f"    50K Z-array computations: {elapsed*1000:.2f}ms ({50000/elapsed:.0f}/sec)")
results['zalgo'] = 50000/elapsed

# 8. MANACHER'S ALGORITHM
print("\n[8] 🎯 MANACHER'S ALGORITHM")
print("-" * 50)

def manacher(s):
    # Transform string
    t = '#' + '#'.join(s) + '#'
    n = len(t)
    p = [0] * n
    c, r = 0, 0
    
    for i in range(n):
        mirror = 2 * c - i
        if i < r:
            p[i] = min(r - i, p[mirror])
        
        while i + p[i] + 1 < n and i - p[i] - 1 >= 0 and t[i + p[i] + 1] == t[i - p[i] - 1]:
            p[i] += 1
        
        if i + p[i] > r:
            c, r = i, i + p[i]
    
    max_len = max(p)
    center = p.index(max_len)
    start = (center - max_len) // 2
    return s[start:start + max_len]

t0 = time.time()
for _ in range(50000):
    pal = manacher("abacaba")
elapsed = time.time() - t0
print(f"    50K Manacher's: {elapsed*1000:.2f}ms ({50000/elapsed:.0f}/sec)")
results['manacher'] = 50000/elapsed

# 9. TERNARY SEARCH IN SORTED STRINGS
print("\n[9] 🔎 STRING BINARY SEARCH")
print("-" * 50)

def string_compare(s1, s2):
    min_len = min(len(s1), len(s2))
    for i in range(min_len):
        if s1[i] < s2[i]: return -1
        if s1[i] > s2[i]: return 1
    if len(s1) < len(s2): return -1
    if len(s1) > len(s2): return 1
    return 0

def binary_search_string(arr, target):
    lo, hi = 0, len(arr) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        cmp = string_compare(arr[mid], target)
        if cmp == 0:
            return mid
        elif cmp < 0:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1

words = sorted(["apple", "banana", "cherry", "date", "elderberry", "fig", "grape"] * 100)

t0 = time.time()
for _ in range(100000):
    idx = binary_search_string(words, "cherry")
elapsed = time.time() - t0
print(f"    100K string binary searches: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
results['binsearch'] = 100000/elapsed

# 10. STRING HASHING
print("\n[10] #️⃣ STRING HASHING")
print("-" * 50)

def polynomial_hash(s, base=31, mod=10**9+7):
    h = 0
    p = 1
    for c in s:
        h = (h + (ord(c) - ord('a') + 1) * p) % mod
        p = (p * base) % mod
    return h

def rolling_hash_compare(s1, s2):
    """Compare all substrings of s1 with s2 using rolling hash"""
    m = len(s2)
    h2 = polynomial_hash(s2)
    
    base, mod = 31, 10**9+7
    h1 = polynomial_hash(s1[:m])
    p_m = pow(base, m, mod)
    
    matches = []
    if h1 == h2:
        matches.append(0)
    
    for i in range(1, len(s1) - m + 1):
        h1 = ((h1 - (ord(s1[i-1]) - ord('a') + 1)) * pow(base, mod-2, mod)) % mod
        h1 = (h1 * base + (ord(s1[i+m-1]) - ord('a') + 1)) % mod
        if h1 == h2:
            matches.append(i)
    
    return matches

t0 = time.time()
for _ in range(100000):
    h = polynomial_hash("hello world this is a test")
elapsed = time.time() - t0
print(f"    100K polynomial hashes: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
results['strhash'] = 100000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 STRING ALGORITHMS SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  KMP Search:          {results['kmp']:.0f} searches/sec
  Rabin-Karp:          {results['rabinkarp']:.0f} searches/sec
  Boyer-Moore:         {results['boyermoore']:.0f} searches/sec
  Suffix Array:        {results['suffix']:.0f} arrays/sec
  LCS:                 {results['lcs']:.0f} computations/sec
  Longest Palindrome:  {results['palindrome']:.0f} searches/sec
  Z-Algorithm:         {results['zalgo']:.0f} arrays/sec
  Manacher's:          {results['manacher']:.0f} arrays/sec
  Binary Search:       {results['binsearch']:.0f} searches/sec
  String Hashing:      {results['strhash']:.0f} hashes/sec
  
  📝 TOTAL STRING SCORE: {total:.0f} points
""")
