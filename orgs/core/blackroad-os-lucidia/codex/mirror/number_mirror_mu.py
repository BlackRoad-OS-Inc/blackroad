"""
number_mirror_mu.py

This module implements a simple Möbius mirror demonstration.
It defines functions to compute the Möbius function µ(n), split
positive and negative values, compute the Mertens function, and
verify the Dirichlet generating identity.

Functions:
    mobius(n) -> int
    mirror_split_mu(N) -> (pos_indices, neg_indices)
    mertens(N) -> list[int]
    dirichlet_sum(s, N) -> complex
"""

import cmath

def mobius(n: int) -> int:
    """Compute the Möbius function µ(n)."""
    if n == 1:
        return 1
    primes = {}
    i = 2
    m = n
    while i * i <= m:
        while m % i == 0:
            primes[i] = primes.get(i, 0) + 1
            m //= i
        i += 1
    if m > 1:
        primes[m] = primes.get(m, 0) + 1
    for exp in primes.values():
        if exp > 1:
            return 0
    return -1 if len(primes) % 2 else 1

def mirror_split_mu(N: int):
    """Return indices where µ(n) = +1 and µ(n) = -1 up to N."""
    pos = []
    neg = []
    for n in range(1, N + 1):
        mu = mobius(n)
        if mu == 1:
            pos.append(n)
        elif mu == -1:
            neg.append(n)
    return pos, neg

def mertens(N: int):
    """Compute the Mertens function M(x) for x = 1..N."""
    total = 0
    M = []
    for n in range(1, N + 1):
        total += mobius(n)
        M.append(total)
    return M

def dirichlet_sum(s: complex, N: int):
    """Compute the partial Dirichlet sum \u2211_{n=1..N} µ(n)/n^s."""
    total = 0+0j
    for n in range(1, N + 1):
        mu = mobius(n)
        if mu != 0:
            total += mu / (n ** s)
    return total
