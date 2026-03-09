#!/usr/bin/env python3
"""COMPUTATIONAL GEOMETRY - Pure arithmetic geometric algorithms"""
import time
import socket

hostname = socket.gethostname()
print(f"{'='*70}")
print(f"  📐 COMPUTATIONAL GEOMETRY - {hostname}")
print(f"{'='*70}\n")

def sqrt(x):
    if x <= 0: return 0
    g = x / 2.0
    for _ in range(20): g = (g + x/g) / 2.0
    return g

PI = 3.14159265358979

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

# 1. POINT IN POLYGON
print("[1] 🎯 POINT IN POLYGON")
print("-" * 50)

def point_in_polygon(point, polygon):
    x, y = point
    n = len(polygon)
    inside = False
    j = n - 1
    for i in range(n):
        xi, yi = polygon[i]
        xj, yj = polygon[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi):
            inside = not inside
        j = i
    return inside

polygon = [(0, 0), (10, 0), (10, 10), (5, 15), (0, 10)]
test_points = [(5, 5), (15, 5), (5, 12), (0, 0), (10, 10)]

t0 = time.time()
for _ in range(100000):
    for p in test_points:
        point_in_polygon(p, polygon)
elapsed = time.time() - t0
print(f"    500K point-in-polygon tests: {elapsed*1000:.2f}ms ({500000/elapsed:.0f}/sec)")
results['pip'] = 500000/elapsed

# 2. CONVEX HULL (Graham Scan)
print("\n[2] 🔺 CONVEX HULL")
print("-" * 50)

def cross(o, a, b):
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

def convex_hull(points):
    points = sorted(set(points))
    if len(points) <= 1:
        return points
    
    lower = []
    for p in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    
    upper = []
    for p in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    
    return lower[:-1] + upper[:-1]

class LCG:
    def __init__(self, seed): self.state = seed
    def next(self):
        self.state = (self.state * 1103515245 + 12345) & 0x7FFFFFFF
        return self.state / 0x7FFFFFFF

rng = LCG(42)
random_points = [(rng.next() * 100, rng.next() * 100) for _ in range(100)]

t0 = time.time()
for _ in range(1000):
    hull = convex_hull(random_points)
elapsed = time.time() - t0
print(f"    1000 convex hulls (100 pts): {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
print(f"    Hull size: {len(hull)} points")
results['hull'] = 1000/elapsed

# 3. LINE INTERSECTION
print("\n[3] ✖️ LINE INTERSECTION")
print("-" * 50)

def line_intersection(p1, p2, p3, p4):
    x1, y1 = p1; x2, y2 = p2
    x3, y3 = p3; x4, y4 = p4
    
    denom = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4)
    if abs(denom) < 1e-10:
        return None
    
    t = ((x1-x3)*(y3-y4) - (y1-y3)*(x3-x4)) / denom
    x = x1 + t*(x2-x1)
    y = y1 + t*(y2-y1)
    return (x, y)

lines = [((0, 0), (10, 10)), ((0, 10), (10, 0)), ((5, 0), (5, 10)), ((0, 5), (10, 5))]

t0 = time.time()
for _ in range(100000):
    for i in range(len(lines)):
        for j in range(i+1, len(lines)):
            line_intersection(lines[i][0], lines[i][1], lines[j][0], lines[j][1])
elapsed = time.time() - t0
print(f"    600K line intersections: {elapsed*1000:.2f}ms ({600000/elapsed:.0f}/sec)")
results['intersect'] = 600000/elapsed

# 4. POLYGON AREA
print("\n[4] 📏 POLYGON AREA (Shoelace)")
print("-" * 50)

def polygon_area(vertices):
    n = len(vertices)
    area = 0
    for i in range(n):
        j = (i + 1) % n
        area += vertices[i][0] * vertices[j][1]
        area -= vertices[j][0] * vertices[i][1]
    return abs(area) / 2

t0 = time.time()
for _ in range(100000):
    polygon_area(polygon)
    polygon_area(random_points[:20])
elapsed = time.time() - t0
print(f"    200K area calculations: {elapsed*1000:.2f}ms ({200000/elapsed:.0f}/sec)")
results['area'] = 200000/elapsed

# 5. DISTANCE CALCULATIONS
print("\n[5] 📍 DISTANCE CALCULATIONS")
print("-" * 50)

def point_distance(p1, p2):
    return sqrt((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)

def point_to_line_distance(point, line_start, line_end):
    x0, y0 = point
    x1, y1 = line_start
    x2, y2 = line_end
    
    num = abs((y2-y1)*x0 - (x2-x1)*y0 + x2*y1 - y2*x1)
    den = sqrt((y2-y1)**2 + (x2-x1)**2)
    return num / den if den > 0 else 0

t0 = time.time()
for _ in range(100000):
    point_distance((0, 0), (3, 4))
    point_to_line_distance((5, 5), (0, 0), (10, 0))
elapsed = time.time() - t0
print(f"    200K distance calcs: {elapsed*1000:.2f}ms ({200000/elapsed:.0f}/sec)")
results['distance'] = 200000/elapsed

# 6. TRIANGLE OPERATIONS
print("\n[6] 🔺 TRIANGLE OPERATIONS")
print("-" * 50)

def triangle_area(p1, p2, p3):
    return abs((p2[0]-p1[0])*(p3[1]-p1[1]) - (p3[0]-p1[0])*(p2[1]-p1[1])) / 2

def triangle_circumcircle(p1, p2, p3):
    ax, ay = p1; bx, by = p2; cx, cy = p3
    d = 2 * (ax*(by-cy) + bx*(cy-ay) + cx*(ay-by))
    if abs(d) < 1e-10:
        return None, None
    ux = ((ax*ax+ay*ay)*(by-cy) + (bx*bx+by*by)*(cy-ay) + (cx*cx+cy*cy)*(ay-by)) / d
    uy = ((ax*ax+ay*ay)*(cx-bx) + (bx*bx+by*by)*(ax-cx) + (cx*cx+cy*cy)*(bx-ax)) / d
    return (ux, uy), sqrt((ax-ux)**2 + (ay-uy)**2)

def point_in_triangle(p, t1, t2, t3):
    def sign(p1, p2, p3):
        return (p1[0]-p3[0])*(p2[1]-p3[1]) - (p2[0]-p3[0])*(p1[1]-p3[1])
    d1 = sign(p, t1, t2)
    d2 = sign(p, t2, t3)
    d3 = sign(p, t3, t1)
    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (has_neg and has_pos)

t0 = time.time()
for _ in range(50000):
    triangle_area((0, 0), (10, 0), (5, 10))
    triangle_circumcircle((0, 0), (10, 0), (5, 10))
    point_in_triangle((5, 5), (0, 0), (10, 0), (5, 10))
elapsed = time.time() - t0
print(f"    150K triangle ops: {elapsed*1000:.2f}ms ({150000/elapsed:.0f}/sec)")
results['triangle'] = 150000/elapsed

# 7. CLOSEST PAIR OF POINTS
print("\n[7] 👫 CLOSEST PAIR")
print("-" * 50)

def closest_pair_brute(points):
    n = len(points)
    min_dist = float('inf')
    for i in range(n):
        for j in range(i+1, n):
            d = sqrt((points[i][0]-points[j][0])**2 + (points[i][1]-points[j][1])**2)
            if d < min_dist:
                min_dist = d
    return min_dist

small_points = random_points[:30]

t0 = time.time()
for _ in range(1000):
    closest_pair_brute(small_points)
elapsed = time.time() - t0
print(f"    1000 closest pair (30 pts): {elapsed*1000:.2f}ms ({1000/elapsed:.0f}/sec)")
results['closest'] = 1000/elapsed

# 8. BOUNDING BOX
print("\n[8] 📦 BOUNDING BOX")
print("-" * 50)

def bounding_box(points):
    min_x = min(p[0] for p in points)
    max_x = max(p[0] for p in points)
    min_y = min(p[1] for p in points)
    max_y = max(p[1] for p in points)
    return (min_x, min_y), (max_x, max_y)

def minimum_bounding_circle(points):
    # Simple approximation: center at centroid, radius to farthest
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    r = max(sqrt((p[0]-cx)**2 + (p[1]-cy)**2) for p in points)
    return (cx, cy), r

t0 = time.time()
for _ in range(50000):
    bounding_box(random_points)
    minimum_bounding_circle(random_points)
elapsed = time.time() - t0
print(f"    100K bounding calcs: {elapsed*1000:.2f}ms ({100000/elapsed:.0f}/sec)")
results['bounds'] = 100000/elapsed

# 9. VORONOI (Simple approximation)
print("\n[9] 🔷 VORONOI REGIONS")
print("-" * 50)

def nearest_site(point, sites):
    min_dist = float('inf')
    nearest = 0
    for i, site in enumerate(sites):
        d = (point[0]-site[0])**2 + (point[1]-site[1])**2
        if d < min_dist:
            min_dist = d
            nearest = i
    return nearest

def voronoi_grid(sites, width, height, resolution):
    grid = [[0] * width for _ in range(height)]
    for y in range(0, height, resolution):
        for x in range(0, width, resolution):
            grid[y][x] = nearest_site((x, y), sites)
    return grid

sites = [(rng.next()*50, rng.next()*50) for _ in range(10)]

t0 = time.time()
for _ in range(100):
    voronoi_grid(sites, 50, 50, 5)
elapsed = time.time() - t0
print(f"    100 Voronoi grids: {elapsed*1000:.2f}ms ({100/elapsed:.0f}/sec)")
results['voronoi'] = 100/elapsed

# 10. ROTATION & TRANSFORMATION
print("\n[10] 🔄 2D TRANSFORMATIONS")
print("-" * 50)

def rotate_point(point, angle, center=(0, 0)):
    x, y = point[0] - center[0], point[1] - center[1]
    c, s = cos(angle), sin(angle)
    return (x*c - y*s + center[0], x*s + y*c + center[1])

def scale_point(point, sx, sy, center=(0, 0)):
    x, y = point[0] - center[0], point[1] - center[1]
    return (x*sx + center[0], y*sy + center[1])

def transform_polygon(vertices, angle, scale, translate):
    result = []
    for v in vertices:
        v = rotate_point(v, angle)
        v = scale_point(v, scale, scale)
        v = (v[0] + translate[0], v[1] + translate[1])
        result.append(v)
    return result

t0 = time.time()
for _ in range(10000):
    transform_polygon(polygon, 0.5, 2.0, (10, 10))
elapsed = time.time() - t0
print(f"    10K polygon transforms: {elapsed*1000:.2f}ms ({10000/elapsed:.0f}/sec)")
results['transform'] = 10000/elapsed

# SUMMARY
print(f"\n{'='*70}")
print(f"  🏆 COMPUTATIONAL GEOMETRY SUMMARY - {hostname}")
print(f"{'='*70}")
total = sum(results.values())
print(f"""
  Point-in-Polygon:    {results['pip']:.0f}/sec
  Convex Hull:         {results['hull']:.0f}/sec
  Line Intersection:   {results['intersect']:.0f}/sec
  Polygon Area:        {results['area']:.0f}/sec
  Distance Calcs:      {results['distance']:.0f}/sec
  Triangle Ops:        {results['triangle']:.0f}/sec
  Closest Pair:        {results['closest']:.0f}/sec
  Bounding Box:        {results['bounds']:.0f}/sec
  Voronoi Regions:     {results['voronoi']:.0f}/sec
  2D Transforms:       {results['transform']:.0f}/sec
  
  📐 TOTAL GEOMETRY SCORE: {total:.0f} points
""")
