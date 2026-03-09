#!/usr/bin/env python3
"""COMBINATORICS & PUZZLES - Pure arithmetic problem solving"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🧩 COMBINATORICS & PUZZLES - {hostname}")
print(f"{'='*70}\n")

results = {}

# 1. N-QUEENS
print("[1] 👑 N-QUEENS SOLVER")
print("-" * 50)

def solve_nqueens(n):
    solutions = []
    def is_safe(board, row, col):
        for i in range(row):
            if board[i] == col or abs(board[i] - col) == row - i:
                return False
        return True
    
    def solve(board, row):
        if row == n:
            solutions.append(board[:])
            return
        for col in range(n):
            if is_safe(board, row, col):
                board[row] = col
                solve(board, row + 1)
    
    solve([-1] * n, 0)
    return len(solutions)

t0 = time.time()
for n in range(4, 11):
    count = solve_nqueens(n)
elapsed = time.time() - t0
print(f"    N-Queens (4-10): {elapsed*1000:.2f}ms")
print(f"    8-Queens solutions: {solve_nqueens(8)}")
results['nqueens'] = 7/elapsed

# 2. SUDOKU SOLVER
print("\n[2] 🔢 SUDOKU SOLVER")
print("-" * 50)

def solve_sudoku(board):
    def is_valid(board, row, col, num):
        for i in range(9):
            if board[row][i] == num or board[i][col] == num:
                return False
        box_row, box_col = 3 * (row // 3), 3 * (col // 3)
        for i in range(box_row, box_row + 3):
            for j in range(box_col, box_col + 3):
                if board[i][j] == num:
                    return False
        return True
    
    def solve(board):
        for i in range(9):
            for j in range(9):
                if board[i][j] == 0:
                    for num in range(1, 10):
                        if is_valid(board, i, j, num):
                            board[i][j] = num
                            if solve(board):
                                return True
                            board[i][j] = 0
                    return False
        return True
    
    return solve(board)

# Simple sudoku puzzle
puzzle = [
    [5,3,0,0,7,0,0,0,0],
    [6,0,0,1,9,5,0,0,0],
    [0,9,8,0,0,0,0,6,0],
    [8,0,0,0,6,0,0,0,3],
    [4,0,0,8,0,3,0,0,1],
    [7,0,0,0,2,0,0,0,6],
    [0,6,0,0,0,0,2,8,0],
    [0,0,0,4,1,9,0,0,5],
    [0,0,0,0,8,0,0,7,9]
]

t0 = time.time()
for _ in range(100):
    test = [row[:] for row in puzzle]
    solve_sudoku(test)
elapsed = time.time() - t0
print(f"    100 Sudoku solves: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
results['sudoku'] = 100/elapsed

# 3. PERMUTATIONS
print("\n[3] 🔄 PERMUTATIONS")
print("-" * 50)

def permutations(arr):
    if len(arr) <= 1:
        return [arr]
    result = []
    for i in range(len(arr)):
        rest = arr[:i] + arr[i+1:]
        for p in permutations(rest):
            result.append([arr[i]] + p)
    return result

t0 = time.time()
for _ in range(1000):
    perms = permutations([1,2,3,4,5,6])
elapsed = time.time() - t0
print(f"    1000 × P(6): {elapsed*1000:.2f}ms ({720000/elapsed:.0f} perms/sec)")
results['permutations'] = 720000/elapsed

# 4. COMBINATIONS
print("\n[4] 🎯 COMBINATIONS")
print("-" * 50)

def combinations(arr, k):
    if k == 0:
        return [[]]
    if len(arr) == 0:
        return []
    first = arr[0]
    rest = arr[1:]
    with_first = [[first] + c for c in combinations(rest, k-1)]
    without_first = combinations(rest, k)
    return with_first + without_first

t0 = time.time()
for _ in range(1000):
    combs = combinations([1,2,3,4,5,6,7,8], 4)
elapsed = time.time() - t0
print(f"    1000 × C(8,4): {elapsed*1000:.2f}ms ({70000/elapsed:.0f} combs/sec)")
results['combinations'] = 70000/elapsed

# 5. KNAPSACK PROBLEM
print("\n[5] 🎒 KNAPSACK PROBLEM")
print("-" * 50)

def knapsack_01(weights, values, capacity):
    n = len(weights)
    dp = [[0] * (capacity + 1) for _ in range(n + 1)]
    for i in range(1, n + 1):
        for w in range(capacity + 1):
            if weights[i-1] <= w:
                dp[i][w] = max(dp[i-1][w], values[i-1] + dp[i-1][w-weights[i-1]])
            else:
                dp[i][w] = dp[i-1][w]
    return dp[n][capacity]

weights = [2, 3, 4, 5, 9]
values = [3, 4, 5, 8, 10]

t0 = time.time()
for _ in range(10000):
    max_val = knapsack_01(weights, values, 20)
elapsed = time.time() - t0
print(f"    10K knapsack solves: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
print(f"    Max value: {max_val}")
results['knapsack'] = 10000/elapsed

# 6. COIN CHANGE
print("\n[6] 💰 COIN CHANGE")
print("-" * 50)

def coin_change(coins, amount):
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    for coin in coins:
        for x in range(coin, amount + 1):
            if dp[x - coin] + 1 < dp[x]:
                dp[x] = dp[x - coin] + 1
    return dp[amount] if dp[amount] != float('inf') else -1

t0 = time.time()
for _ in range(10000):
    result = coin_change([1, 5, 10, 25], 99)
elapsed = time.time() - t0
print(f"    10K coin change: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
print(f"    Min coins for 99¢: {result}")
results['coinchange'] = 10000/elapsed

# 7. TOWER OF HANOI
print("\n[7] 🗼 TOWER OF HANOI")
print("-" * 50)

def hanoi(n, source, target, auxiliary, moves):
    if n == 1:
        moves.append((source, target))
        return
    hanoi(n-1, source, auxiliary, target, moves)
    moves.append((source, target))
    hanoi(n-1, auxiliary, target, source, moves)

t0 = time.time()
for _ in range(1000):
    moves = []
    hanoi(15, 'A', 'C', 'B', moves)
elapsed = time.time() - t0
print(f"    1000 × Hanoi(15): {elapsed*1000:.2f}ms ({32767000/elapsed:.0f} moves/sec)")
results['hanoi'] = 32767000/elapsed

# 8. SUBSET SUM
print("\n[8] ➕ SUBSET SUM")
print("-" * 50)

def subset_sum(nums, target):
    dp = [False] * (target + 1)
    dp[0] = True
    for num in nums:
        for i in range(target, num - 1, -1):
            if dp[i - num]:
                dp[i] = True
    return dp[target]

nums = [3, 34, 4, 12, 5, 2]

t0 = time.time()
for _ in range(10000):
    for target in [9, 11, 13, 15]:
        result = subset_sum(nums, target)
elapsed = time.time() - t0
print(f"    40K subset sum checks: {elapsed*1000:.2f}ms ({40000/elapsed:.0f}/sec)")
results['subsetsum'] = 40000/elapsed

# 9. MAGIC SQUARE
print("\n[9] ✨ MAGIC SQUARE VERIFICATION")
print("-" * 50)

def is_magic_square(grid):
    n = len(grid)
    magic_sum = n * (n*n + 1) // 2
    
    # Check rows
    for row in grid:
        if sum(row) != magic_sum:
            return False
    
    # Check columns
    for j in range(n):
        if sum(grid[i][j] for i in range(n)) != magic_sum:
            return False
    
    # Check diagonals
    if sum(grid[i][i] for i in range(n)) != magic_sum:
        return False
    if sum(grid[i][n-1-i] for i in range(n)) != magic_sum:
        return False
    
    return True

magic_3x3 = [[2, 7, 6], [9, 5, 1], [4, 3, 8]]

t0 = time.time()
for _ in range(100000):
    is_magic_square(magic_3x3)
elapsed = time.time() - t0
print(f"    100K magic square checks: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
results['magic'] = 100000/elapsed

# 10. PARTITION PROBLEM
print("\n[10] ⚖️ PARTITION PROBLEM")
print("-" * 50)

def can_partition(nums):
    total = sum(nums)
    if total % 2 != 0:
        return False
    target = total // 2
    dp = [False] * (target + 1)
    dp[0] = True
    for num in nums:
        for i in range(target, num - 1, -1):
            if dp[i - num]:
                dp[i] = True
    return dp[target]

test_nums = [1, 5, 11, 5]

t0 = time.time()
for _ in range(50000):
    can_partition(test_nums)
elapsed = time.time() - t0
print(f"    50K partition checks: {elapsed*1000:.2f}ms ({50000/elapsed:.0f}/sec)")
print(f"    [1,5,11,5] partitionable: {can_partition(test_nums)}")
results['partition'] = 50000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 COMBINATORICS SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  N-Queens:          {results['nqueens']:.1f} problems/sec
  Sudoku:            {results['sudoku']:.0f} solves/sec
  Permutations:      {results['permutations']:.0f} perms/sec
  Combinations:      {results['combinations']:.0f} combs/sec
  Knapsack:          {results['knapsack']:.0f} solves/sec
  Coin Change:       {results['coinchange']:.0f} solves/sec
  Tower of Hanoi:    {results['hanoi']:.0f} moves/sec
  Subset Sum:        {results['subsetsum']:.0f} checks/sec
  Magic Square:      {results['magic']:.0f} checks/sec
  Partition:         {results['partition']:.0f} checks/sec
  
  🧩 TOTAL COMBINATORICS SCORE: {total:.0f} points
""")
