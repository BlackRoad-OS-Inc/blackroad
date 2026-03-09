#!/usr/bin/env python3
"""DATA STRUCTURES - Pure arithmetic implementations"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  🗄️ DATA STRUCTURES - {hostname}")
print(f"{'='*70}\n")

results = {}

# 1. BINARY SEARCH TREE
print("[1] 🌳 BINARY SEARCH TREE")
print("-" * 50)

class BSTNode:
    def __init__(self, val):
        self.val = val
        self.left = None
        self.right = None

def bst_insert(root, val):
    if root is None:
        return BSTNode(val)
    if val < root.val:
        root.left = bst_insert(root.left, val)
    else:
        root.right = bst_insert(root.right, val)
    return root

def bst_search(root, val):
    if root is None or root.val == val:
        return root
    if val < root.val:
        return bst_search(root.left, val)
    return bst_search(root.right, val)

def bst_inorder(root, result):
    if root:
        bst_inorder(root.left, result)
        result.append(root.val)
        bst_inorder(root.right, result)

t0 = time.time()
for _ in range(1000):
    root = None
    for val in [5, 3, 7, 1, 4, 6, 8, 2, 9, 0]:
        root = bst_insert(root, val)
    for val in [5, 3, 7, 1, 4, 6, 8, 2, 9, 0]:
        bst_search(root, val)
elapsed = time.time() - t0
print(f"    1000 × (10 inserts + 10 searches): {elapsed*1000:.2f}ms ({20000/elapsed:.0f} ops/sec)")
results['bst'] = 20000/elapsed

# 2. HEAP (Priority Queue)
print("\n[2] 📚 HEAP (MIN-HEAP)")
print("-" * 50)

class MinHeap:
    def __init__(self):
        self.heap = []
    
    def push(self, val):
        self.heap.append(val)
        i = len(self.heap) - 1
        while i > 0:
            parent = (i - 1) // 2
            if self.heap[parent] > self.heap[i]:
                self.heap[parent], self.heap[i] = self.heap[i], self.heap[parent]
                i = parent
            else:
                break
    
    def pop(self):
        if not self.heap:
            return None
        min_val = self.heap[0]
        self.heap[0] = self.heap[-1]
        self.heap.pop()
        i = 0
        while True:
            left = 2*i + 1
            right = 2*i + 2
            smallest = i
            if left < len(self.heap) and self.heap[left] < self.heap[smallest]:
                smallest = left
            if right < len(self.heap) and self.heap[right] < self.heap[smallest]:
                smallest = right
            if smallest != i:
                self.heap[i], self.heap[smallest] = self.heap[smallest], self.heap[i]
                i = smallest
            else:
                break
        return min_val

t0 = time.time()
for _ in range(1000):
    h = MinHeap()
    for val in range(100):
        h.push((val * 17) % 100)
    for _ in range(100):
        h.pop()
elapsed = time.time() - t0
print(f"    1000 × (100 pushes + 100 pops): {elapsed*1000:.2f}ms ({200000/elapsed:.0f} ops/sec)")
results['heap'] = 200000/elapsed

# 3. HASH TABLE
print("\n[3] #️⃣ HASH TABLE")
print("-" * 50)

class HashTable:
    def __init__(self, size=101):
        self.size = size
        self.buckets = [[] for _ in range(size)]
    
    def _hash(self, key):
        if isinstance(key, int):
            return key % self.size
        h = 0
        for c in str(key):
            h = (h * 31 + ord(c)) % self.size
        return h
    
    def put(self, key, value):
        idx = self._hash(key)
        for i, (k, v) in enumerate(self.buckets[idx]):
            if k == key:
                self.buckets[idx][i] = (key, value)
                return
        self.buckets[idx].append((key, value))
    
    def get(self, key):
        idx = self._hash(key)
        for k, v in self.buckets[idx]:
            if k == key:
                return v
        return None

t0 = time.time()
for _ in range(1000):
    ht = HashTable()
    for i in range(100):
        ht.put(f"key{i}", i * 2)
    for i in range(100):
        ht.get(f"key{i}")
elapsed = time.time() - t0
print(f"    1000 × (100 puts + 100 gets): {elapsed*1000:.2f}ms ({200000/elapsed:.0f} ops/sec)")
results['hashtable'] = 200000/elapsed

# 4. LINKED LIST
print("\n[4] 🔗 LINKED LIST")
print("-" * 50)

class ListNode:
    def __init__(self, val):
        self.val = val
        self.next = None

def list_insert(head, val):
    new_node = ListNode(val)
    new_node.next = head
    return new_node

def list_find(head, val):
    while head:
        if head.val == val:
            return head
        head = head.next
    return None

def list_reverse(head):
    prev = None
    while head:
        next_node = head.next
        head.next = prev
        prev = head
        head = next_node
    return prev

t0 = time.time()
for _ in range(10000):
    head = None
    for i in range(50):
        head = list_insert(head, i)
    for i in range(50):
        list_find(head, i)
    head = list_reverse(head)
elapsed = time.time() - t0
print(f"    10K × (50 inserts + 50 finds + reverse): {elapsed*1000:.2f}ms ({1010000/elapsed:.0f} ops/sec)")
results['linkedlist'] = 1010000/elapsed

# 5. STACK & QUEUE
print("\n[5] 📥📤 STACK & QUEUE")
print("-" * 50)

class Stack:
    def __init__(self):
        self.items = []
    def push(self, val): self.items.append(val)
    def pop(self): return self.items.pop() if self.items else None
    def peek(self): return self.items[-1] if self.items else None

class Queue:
    def __init__(self):
        self.items = []
    def enqueue(self, val): self.items.append(val)
    def dequeue(self): return self.items.pop(0) if self.items else None

t0 = time.time()
for _ in range(10000):
    s = Stack()
    q = Queue()
    for i in range(100):
        s.push(i)
        q.enqueue(i)
    for _ in range(100):
        s.pop()
        q.dequeue()
elapsed = time.time() - t0
print(f"    10K × (200 stack + 200 queue ops): {elapsed*1000:.2f}ms ({4000000/elapsed:.0f} ops/sec)")
results['stackqueue'] = 4000000/elapsed

# 6. TRIE (Prefix Tree)
print("\n[6] 🔤 TRIE")
print("-" * 50)

class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False

class Trie:
    def __init__(self):
        self.root = TrieNode()
    
    def insert(self, word):
        node = self.root
        for c in word:
            if c not in node.children:
                node.children[c] = TrieNode()
            node = node.children[c]
        node.is_end = True
    
    def search(self, word):
        node = self.root
        for c in word:
            if c not in node.children:
                return False
            node = node.children[c]
        return node.is_end
    
    def starts_with(self, prefix):
        node = self.root
        for c in prefix:
            if c not in node.children:
                return False
            node = node.children[c]
        return True

words = ["apple", "app", "application", "banana", "band", "bandana", "cat", "car", "card"]

t0 = time.time()
for _ in range(10000):
    t = Trie()
    for w in words:
        t.insert(w)
    for w in words:
        t.search(w)
        t.starts_with(w[:2])
elapsed = time.time() - t0
print(f"    10K × (9 inserts + 18 lookups): {elapsed*1000:.2f}ms ({270000/elapsed:.0f} ops/sec)")
results['trie'] = 270000/elapsed

# 7. DISJOINT SET (Union-Find)
print("\n[7] 🔀 UNION-FIND")
print("-" * 50)

class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))
        self.rank = [0] * n
    
    def find(self, x):
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]
    
    def union(self, x, y):
        px, py = self.find(x), self.find(y)
        if px == py:
            return
        if self.rank[px] < self.rank[py]:
            px, py = py, px
        self.parent[py] = px
        if self.rank[px] == self.rank[py]:
            self.rank[px] += 1

t0 = time.time()
for _ in range(10000):
    uf = UnionFind(100)
    for i in range(0, 100, 2):
        uf.union(i, i+1)
    for i in range(100):
        uf.find(i)
elapsed = time.time() - t0
print(f"    10K × (50 unions + 100 finds): {elapsed*1000:.2f}ms ({1500000/elapsed:.0f} ops/sec)")
results['unionfind'] = 1500000/elapsed

# 8. SEGMENT TREE
print("\n[8] 📊 SEGMENT TREE")
print("-" * 50)

class SegmentTree:
    def __init__(self, arr):
        self.n = len(arr)
        self.tree = [0] * (4 * self.n)
        self._build(arr, 0, 0, self.n - 1)
    
    def _build(self, arr, node, start, end):
        if start == end:
            self.tree[node] = arr[start]
        else:
            mid = (start + end) // 2
            self._build(arr, 2*node+1, start, mid)
            self._build(arr, 2*node+2, mid+1, end)
            self.tree[node] = self.tree[2*node+1] + self.tree[2*node+2]
    
    def query(self, l, r):
        return self._query(0, 0, self.n-1, l, r)
    
    def _query(self, node, start, end, l, r):
        if r < start or end < l:
            return 0
        if l <= start and end <= r:
            return self.tree[node]
        mid = (start + end) // 2
        left = self._query(2*node+1, start, mid, l, r)
        right = self._query(2*node+2, mid+1, end, l, r)
        return left + right

arr = list(range(64))

t0 = time.time()
for _ in range(10000):
    st = SegmentTree(arr)
    for i in range(10):
        st.query(i, i + 30)
elapsed = time.time() - t0
print(f"    10K × (build + 10 queries): {elapsed*1000:.2f}ms ({110000/elapsed:.0f} ops/sec)")
results['segtree'] = 110000/elapsed

# 9. LRU CACHE
print("\n[9] 💾 LRU CACHE")
print("-" * 50)

class LRUCache:
    def __init__(self, capacity):
        self.capacity = capacity
        self.cache = {}
        self.order = []
    
    def get(self, key):
        if key in self.cache:
            self.order.remove(key)
            self.order.append(key)
            return self.cache[key]
        return -1
    
    def put(self, key, value):
        if key in self.cache:
            self.order.remove(key)
        elif len(self.cache) >= self.capacity:
            lru = self.order.pop(0)
            del self.cache[lru]
        self.cache[key] = value
        self.order.append(key)

t0 = time.time()
for _ in range(10000):
    lru = LRUCache(10)
    for i in range(50):
        lru.put(i, i*2)
    for i in range(50):
        lru.get(i % 15)
elapsed = time.time() - t0
print(f"    10K × (50 puts + 50 gets): {elapsed*1000:.2f}ms ({1000000/elapsed:.0f} ops/sec)")
results['lru'] = 1000000/elapsed

# 10. BLOOM FILTER
print("\n[10] 🌸 BLOOM FILTER")
print("-" * 50)

class BloomFilter:
    def __init__(self, size=1000):
        self.size = size
        self.bits = [False] * size
    
    def _hashes(self, item):
        h1 = hash(str(item)) % self.size
        h2 = (hash(str(item) + "salt") * 31) % self.size
        h3 = (hash(str(item) + "pepper") * 37) % self.size
        return [abs(h) % self.size for h in [h1, h2, h3]]
    
    def add(self, item):
        for h in self._hashes(item):
            self.bits[h] = True
    
    def might_contain(self, item):
        return all(self.bits[h] for h in self._hashes(item))

t0 = time.time()
for _ in range(10000):
    bf = BloomFilter(1000)
    for i in range(50):
        bf.add(f"item{i}")
    for i in range(100):
        bf.might_contain(f"item{i}")
elapsed = time.time() - t0
print(f"    10K × (50 adds + 100 lookups): {elapsed*1000:.2f}ms ({1500000/elapsed:.0f} ops/sec)")
results['bloom'] = 1500000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 DATA STRUCTURES SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  BST:              {results['bst']:.0f} ops/sec
  Min-Heap:         {results['heap']:.0f} ops/sec
  Hash Table:       {results['hashtable']:.0f} ops/sec
  Linked List:      {results['linkedlist']:.0f} ops/sec
  Stack & Queue:    {results['stackqueue']:.0f} ops/sec
  Trie:             {results['trie']:.0f} ops/sec
  Union-Find:       {results['unionfind']:.0f} ops/sec
  Segment Tree:     {results['segtree']:.0f} ops/sec
  LRU Cache:        {results['lru']:.0f} ops/sec
  Bloom Filter:     {results['bloom']:.0f} ops/sec
  
  🗄️ TOTAL DATA STRUCTURES SCORE: {total:.0f} points
""")
