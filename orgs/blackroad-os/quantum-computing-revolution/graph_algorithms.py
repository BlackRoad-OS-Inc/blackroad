#!/usr/bin/env python3
"""GRAPH ALGORITHMS - Pure arithmetic graph theory"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  GRAPH ALGORITHMS - {hostname}")
print(f"{'='*70}\n")

results = {}

# 1. BFS (Breadth-First Search)
print("[1] BFS (1000-node graph)")
print("-" * 50)

def bfs(adj, start, n):
    visited = [False] * n
    distances = [-1] * n
    queue = [start]
    visited[start] = True
    distances[start] = 0
    while queue:
        node = queue.pop(0)
        for neighbor in adj[node]:
            if not visited[neighbor]:
                visited[neighbor] = True
                distances[neighbor] = distances[node] + 1
                queue.append(neighbor)
    return distances

# Build random-ish graph
n = 1000
adj = [[] for _ in range(n)]
for i in range(n):
    for j in range(5):
        neighbor = (i * 7 + j * 13 + 17) % n
        if neighbor != i:
            adj[i].append(neighbor)

t0 = time.time()
for _ in range(100):
    dists = bfs(adj, 0, n)
elapsed = time.time() - t0
avg_dist = sum(d for d in dists if d >= 0) / n
print(f"    100×BFS(1000 nodes): {elapsed*1000:.2f}ms ({100/elapsed:.0f} BFS/sec)")
print(f"    Avg distance from node 0: {avg_dist:.2f}")
results['bfs'] = 100/elapsed

# 2. DFS (Depth-First Search)
print("\n[2] DFS (1000-node graph)")
print("-" * 50)

def dfs(adj, start, n):
    visited = [False] * n
    order = []
    stack = [start]
    while stack:
        node = stack.pop()
        if not visited[node]:
            visited[node] = True
            order.append(node)
            for neighbor in reversed(adj[node]):
                if not visited[neighbor]:
                    stack.append(neighbor)
    return order

t0 = time.time()
for _ in range(100):
    order = dfs(adj, 0, n)
elapsed = time.time() - t0
print(f"    100×DFS(1000 nodes): {elapsed*1000:.2f}ms ({100/elapsed:.0f} DFS/sec)")
results['dfs'] = 100/elapsed

# 3. DIJKSTRA'S SHORTEST PATH
print("\n[3] DIJKSTRA (500-node weighted graph)")
print("-" * 50)

def dijkstra(adj_weighted, start, n):
    INF = float('inf')
    dist = [INF] * n
    dist[start] = 0
    visited = [False] * n
    
    for _ in range(n):
        # Find min unvisited
        min_dist = INF
        u = -1
        for i in range(n):
            if not visited[i] and dist[i] < min_dist:
                min_dist = dist[i]
                u = i
        if u == -1:
            break
        visited[u] = True
        for v, w in adj_weighted[u]:
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
    return dist

# Build weighted graph
n2 = 500
adj_w = [[] for _ in range(n2)]
for i in range(n2):
    for j in range(3):
        neighbor = (i * 7 + j * 13 + 17) % n2
        weight = (i + j) % 10 + 1
        if neighbor != i:
            adj_w[i].append((neighbor, weight))

t0 = time.time()
for _ in range(20):
    dists = dijkstra(adj_w, 0, n2)
elapsed = time.time() - t0
print(f"    20×Dijkstra(500 nodes): {elapsed*1000:.2f}ms ({20/elapsed:.1f} Dijkstra/sec)")
results['dijkstra'] = 20/elapsed

# 4. FLOYD-WARSHALL
print("\n[4] FLOYD-WARSHALL (100-node graph)")
print("-" * 50)

def floyd_warshall(adj_matrix):
    n = len(adj_matrix)
    dist = [[adj_matrix[i][j] for j in range(n)] for i in range(n)]
    for k in range(n):
        for i in range(n):
            for j in range(n):
                if dist[i][k] + dist[k][j] < dist[i][j]:
                    dist[i][j] = dist[i][k] + dist[k][j]
    return dist

INF = 10000
n3 = 100
adj_mat = [[INF]*n3 for _ in range(n3)]
for i in range(n3):
    adj_mat[i][i] = 0
    for j in range(3):
        neighbor = (i * 7 + j * 13 + 17) % n3
        if neighbor != i:
            adj_mat[i][neighbor] = (i + j) % 10 + 1

t0 = time.time()
for _ in range(5):
    all_dists = floyd_warshall(adj_mat)
elapsed = time.time() - t0
print(f"    5×Floyd-Warshall(100): {elapsed*1000:.2f}ms ({5/elapsed:.1f} FW/sec)")
results['floyd_warshall'] = 5/elapsed

# 5. TOPOLOGICAL SORT
print("\n[5] TOPOLOGICAL SORT (DAG)")
print("-" * 50)

def topo_sort(adj, n):
    in_degree = [0] * n
    for u in range(n):
        for v in adj[u]:
            in_degree[v] += 1
    queue = [i for i in range(n) if in_degree[i] == 0]
    order = []
    while queue:
        u = queue.pop(0)
        order.append(u)
        for v in adj[u]:
            in_degree[v] -= 1
            if in_degree[v] == 0:
                queue.append(v)
    return order

# Build DAG
n4 = 1000
dag = [[] for _ in range(n4)]
for i in range(n4):
    for j in range(3):
        neighbor = i + (j + 1) * 10
        if neighbor < n4:
            dag[i].append(neighbor)

t0 = time.time()
for _ in range(100):
    order = topo_sort(dag, n4)
elapsed = time.time() - t0
print(f"    100×TopSort(1000): {elapsed*1000:.2f}ms ({100/elapsed:.0f} sorts/sec)")
results['topo'] = 100/elapsed

# 6. CONNECTED COMPONENTS
print("\n[6] CONNECTED COMPONENTS")
print("-" * 50)

def find_components(adj, n):
    visited = [False] * n
    components = 0
    for start in range(n):
        if not visited[start]:
            components += 1
            stack = [start]
            while stack:
                node = stack.pop()
                if not visited[node]:
                    visited[node] = True
                    stack.extend(adj[node])
    return components

t0 = time.time()
for _ in range(100):
    num_comp = find_components(adj, n)
elapsed = time.time() - t0
print(f"    100×FindComponents(1000): {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
print(f"    Components found: {num_comp}")
results['components'] = 100/elapsed

# 7. MINIMUM SPANNING TREE (Prim's)
print("\n[7] MST - PRIM'S ALGORITHM")
print("-" * 50)

def prim_mst(adj_w, n):
    INF = float('inf')
    key = [INF] * n
    in_mst = [False] * n
    key[0] = 0
    total_weight = 0
    
    for _ in range(n):
        # Find min key vertex not in MST
        min_key = INF
        u = -1
        for i in range(n):
            if not in_mst[i] and key[i] < min_key:
                min_key = key[i]
                u = i
        if u == -1:
            break
        in_mst[u] = True
        total_weight += key[u]
        for v, w in adj_w[u]:
            if not in_mst[v] and w < key[v]:
                key[v] = w
    return total_weight

t0 = time.time()
for _ in range(20):
    mst_weight = prim_mst(adj_w, n2)
elapsed = time.time() - t0
print(f"    20×Prim(500): {elapsed*1000:.2f}ms ({20/elapsed:.1f} MST/sec)")
print(f"    MST weight: {mst_weight}")
results['prim'] = 20/elapsed

# 8. GRAPH COLORING (Greedy)
print("\n[8] GRAPH COLORING (Greedy)")
print("-" * 50)

def greedy_coloring(adj, n):
    colors = [-1] * n
    for node in range(n):
        neighbor_colors = set(colors[neighbor] for neighbor in adj[node] if colors[neighbor] >= 0)
        color = 0
        while color in neighbor_colors:
            color += 1
        colors[node] = color
    return max(colors) + 1

t0 = time.time()
for _ in range(100):
    num_colors = greedy_coloring(adj, n)
elapsed = time.time() - t0
print(f"    100×Coloring(1000): {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
print(f"    Colors used: {num_colors}")
results['coloring'] = 100/elapsed

# 9. PAGERANK
print("\n[9] PAGERANK (100 iterations)")
print("-" * 50)

def pagerank(adj, n, damping=0.85, iterations=100):
    pr = [1.0 / n] * n
    out_degree = [len(adj[i]) for i in range(n)]
    
    for _ in range(iterations):
        new_pr = [(1 - damping) / n] * n
        for i in range(n):
            if out_degree[i] > 0:
                contrib = damping * pr[i] / out_degree[i]
                for j in adj[i]:
                    new_pr[j] += contrib
        pr = new_pr
    return pr

t0 = time.time()
for _ in range(10):
    pr = pagerank(adj, n)
elapsed = time.time() - t0
top_node = pr.index(max(pr))
print(f"    10×PageRank(1000, 100 iters): {elapsed*1000:.2f}ms ({10/elapsed:.1f} PR/sec)")
print(f"    Top node: {top_node} (PR={max(pr):.6f})")
results['pagerank'] = 10/elapsed

# 10. TRIANGLE COUNTING
print("\n[10] TRIANGLE COUNTING")
print("-" * 50)

def count_triangles(adj, n):
    triangles = 0
    adj_set = [set(adj[i]) for i in range(n)]
    for u in range(n):
        for v in adj[u]:
            if v > u:
                for w in adj[v]:
                    if w > v and u in adj_set[w]:
                        triangles += 1
    return triangles

t0 = time.time()
for _ in range(10):
    num_tri = count_triangles(adj, n)
elapsed = time.time() - t0
print(f"    10×TriangleCount(1000): {elapsed*1000:.2f}ms ({10/elapsed:.1f}/sec)")
print(f"    Triangles found: {num_tri}")
results['triangles'] = 10/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  GRAPH ALGORITHMS SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  BFS:               {results['bfs']:.0f}/sec
  DFS:               {results['dfs']:.0f}/sec
  Dijkstra:          {results['dijkstra']:.1f}/sec
  Floyd-Warshall:    {results['floyd_warshall']:.1f}/sec
  Topological Sort:  {results['topo']:.0f}/sec
  Components:        {results['components']:.0f}/sec
  Prim's MST:        {results['prim']:.1f}/sec
  Graph Coloring:    {results['coloring']:.0f}/sec
  PageRank:          {results['pagerank']:.1f}/sec
  Triangle Count:    {results['triangles']:.1f}/sec
  
  TOTAL GRAPH SCORE: {total:.0f} points
""")
