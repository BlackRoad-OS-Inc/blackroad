"""
BlackRoad Route Optimizer - Delivery route optimization using nearest-neighbor
heuristic + 2-opt improvement algorithm.
"""

import math
import sqlite3
import json
import time
import argparse
import sys
import os
import random
from dataclasses import dataclass, field
from typing import Optional, List, Tuple, Dict
from datetime import datetime

RED    = '\033[0;31m'; GREEN  = '\033[0;32m'; YELLOW = '\033[1;33m'
CYAN   = '\033[0;36m'; BLUE   = '\033[0;34m'; BOLD   = '\033[1m'
DIM    = '\033[2m';    NC     = '\033[0m'

DB_PATH = os.environ.get("ROUTE_DB", os.path.expanduser("~/.blackroad/route_optimizer.db"))

# ── Dataclasses ───────────────────────────────────────────────────────────────

@dataclass
class Location:
    id: str
    name: str
    lat: float
    lon: float
    address: str = ""
    is_depot: bool = False
    time_window_open: Optional[float] = None   # minutes from midnight
    time_window_close: Optional[float] = None
    service_time: float = 5.0                  # minutes to service

    def dist_km(self, other: "Location") -> float:
        """Haversine distance in km."""
        R = 6371.0
        phi1, phi2 = math.radians(self.lat), math.radians(other.lat)
        dphi = math.radians(other.lat - self.lat)
        dlam = math.radians(other.lon - self.lon)
        a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlam/2)**2
        return 2*R*math.asin(math.sqrt(a))


@dataclass
class Delivery:
    id: str
    location_id: str
    weight_kg: float
    priority: int = 2          # 1=high 2=normal 3=low
    notes: str = ""
    status: str = "pending"
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class Vehicle:
    id: str
    name: str
    capacity_kg: float
    speed_kmh: float = 60.0
    fuel_cost_per_km: float = 0.12
    available: bool = True


@dataclass
class Route:
    id: str
    vehicle_id: str
    location_ids: List[str]   # ordered visit sequence
    total_distance_km: float
    total_time_min: float
    total_load_kg: float
    algorithm: str
    cost_estimate: float
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class OptimizationResult:
    route_id: str
    vehicle: str
    stops: int
    distance_before_km: float
    distance_after_km: float
    improvement_pct: float
    iterations: int
    time_ms: float
    sequence: List[str]


# ── DB ─────────────────────────────────────────────────────────────────────────

def get_conn(db_path=DB_PATH):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(db_path=DB_PATH):
    with get_conn(db_path) as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS locations (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, lat REAL, lon REAL,
            address TEXT DEFAULT '', is_depot INTEGER DEFAULT 0,
            tw_open REAL, tw_close REAL, service_time REAL DEFAULT 5.0
        );
        CREATE TABLE IF NOT EXISTS deliveries (
            id TEXT PRIMARY KEY, location_id TEXT, weight_kg REAL,
            priority INTEGER DEFAULT 2, notes TEXT DEFAULT '',
            status TEXT DEFAULT 'pending', created_at TEXT,
            FOREIGN KEY(location_id) REFERENCES locations(id)
        );
        CREATE TABLE IF NOT EXISTS vehicles (
            id TEXT PRIMARY KEY, name TEXT NOT NULL,
            capacity_kg REAL, speed_kmh REAL DEFAULT 60,
            fuel_cost_per_km REAL DEFAULT 0.12, available INTEGER DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS routes (
            id TEXT PRIMARY KEY, vehicle_id TEXT, location_ids TEXT,
            total_distance_km REAL, total_time_min REAL, total_load_kg REAL,
            algorithm TEXT, cost_estimate REAL, created_at TEXT,
            FOREIGN KEY(vehicle_id) REFERENCES vehicles(id)
        );
        """)


# ── Distance matrix ────────────────────────────────────────────────────────────

def build_matrix(locs: List[Location]) -> List[List[float]]:
    n = len(locs)
    m = [[0.0]*n for _ in range(n)]
    for i in range(n):
        for j in range(i+1, n):
            d = locs[i].dist_km(locs[j])
            m[i][j] = m[j][i] = d
    return m


# ── Core algorithms ────────────────────────────────────────────────────────────

def nearest_neighbor(depot_idx: int, visit_indices: List[int],
                     matrix: List[List[float]]) -> List[int]:
    """Nearest-neighbor greedy construction heuristic."""
    unvisited = set(visit_indices)
    tour = [depot_idx]
    current = depot_idx
    while unvisited:
        nearest = min(unvisited, key=lambda j: matrix[current][j])
        tour.append(nearest); unvisited.remove(nearest); current = nearest
    tour.append(depot_idx)   # return to depot
    return tour


def tour_distance(tour: List[int], matrix: List[List[float]]) -> float:
    return sum(matrix[tour[i]][tour[i+1]] for i in range(len(tour)-1))


def two_opt(tour: List[int], matrix: List[List[float]],
            max_iter: int = 1000) -> Tuple[List[int], int]:
    """2-opt local search improvement. Returns (improved_tour, iterations_used)."""
    best = tour[:]
    best_dist = tour_distance(best, matrix)
    n = len(best)
    iters = 0

    for _ in range(max_iter):
        improved = False
        for i in range(1, n-2):
            for j in range(i+1, n-1):
                d_before = (matrix[best[i-1]][best[i]] + matrix[best[j]][best[j+1]])
                d_after  = (matrix[best[i-1]][best[j]] + matrix[best[i]][best[j+1]])
                if d_after < d_before - 1e-10:
                    best[i:j+1] = best[i:j+1][::-1]
                    best_dist = tour_distance(best, matrix)
                    improved = True
        iters += 1
        if not improved:
            break
    return best, iters


def or_opt(tour: List[int], matrix: List[List[float]]) -> List[int]:
    """Or-opt: relocate single cities for further improvement."""
    best = tour[:]
    best_dist = tour_distance(best, matrix)
    n = len(best)
    for i in range(1, n-1):
        city = best[i]
        candidate = best[:i] + best[i+1:]
        for j in range(1, len(candidate)):
            new_tour = candidate[:j] + [city] + candidate[j:]
            d = tour_distance(new_tour, matrix)
            if d < best_dist - 1e-10:
                best = new_tour; best_dist = d
    return best


# ── Optimizer class ────────────────────────────────────────────────────────────

class RouteOptimizer:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        init_db(db_path)

    # ── Location management ──
    def add_location(self, name: str, lat: float, lon: float,
                     address: str = "", is_depot: bool = False,
                     service_time: float = 5.0) -> Location:
        lid = f"loc_{int(time.time()*1000)}"
        loc = Location(id=lid, name=name, lat=lat, lon=lon,
                       address=address, is_depot=is_depot, service_time=service_time)
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO locations (id,name,lat,lon,address,is_depot,service_time)
                VALUES (?,?,?,?,?,?,?)""",
                (lid,name,lat,lon,address,int(is_depot),service_time))
        return loc

    def list_locations(self) -> List[Dict]:
        with get_conn(self.db_path) as c:
            return [dict(r) for r in c.execute(
                "SELECT id,name,lat,lon,address,is_depot,service_time FROM locations ORDER BY name")]

    # ── Delivery management ──
    def add_delivery(self, location_name: str, weight_kg: float,
                     priority: int = 2, notes: str = "") -> Delivery:
        with get_conn(self.db_path) as c:
            row = c.execute("SELECT id FROM locations WHERE name=?", (location_name,)).fetchone()
        if not row: raise ValueError(f"Location '{location_name}' not found")
        did = f"del_{int(time.time()*1000)}"
        d = Delivery(id=did, location_id=row["id"], weight_kg=weight_kg,
                     priority=priority, notes=notes)
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO deliveries (id,location_id,weight_kg,priority,notes,created_at)
                VALUES (?,?,?,?,?,?)""", (did,row["id"],weight_kg,priority,notes,d.created_at))
        return d

    # ── Vehicle management ──
    def add_vehicle(self, name: str, capacity: float,
                    speed: float = 60.0, fuel_cost: float = 0.12) -> Vehicle:
        vid = f"veh_{int(time.time()*1000)}"
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO vehicles (id,name,capacity_kg,speed_kmh,fuel_cost_per_km)
                VALUES (?,?,?,?,?)""", (vid,name,capacity,speed,fuel_cost))
        return Vehicle(id=vid,name=name,capacity_kg=capacity,speed_kmh=speed,fuel_cost_per_km=fuel_cost)

    def _load_locs(self) -> Dict[str, Location]:
        with get_conn(self.db_path) as c:
            rows = c.execute("SELECT * FROM locations").fetchall()
        return {r["id"]: Location(id=r["id"],name=r["name"],lat=r["lat"],lon=r["lon"],
                                  address=r["address"],is_depot=bool(r["is_depot"]),
                                  service_time=r["service_time"]) for r in rows}

    # ── Core optimize ──
    def optimize(self, vehicle_name: str,
                 use_2opt: bool = True, use_or_opt: bool = True) -> Optional[OptimizationResult]:
        t0 = time.time()
        with get_conn(self.db_path) as c:
            vrow = c.execute("SELECT * FROM vehicles WHERE name=?", (vehicle_name,)).fetchone()
            if not vrow: return None
            pend = c.execute(
                """SELECT d.location_id, SUM(d.weight_kg) as total_w
                   FROM deliveries d WHERE d.status='pending'
                   GROUP BY d.location_id""").fetchall()

        locs = self._load_locs()
        depot_ids = [lid for lid, l in locs.items() if l.is_depot]
        if not depot_ids: return None
        depot_id = depot_ids[0]

        # Filter deliveries that fit in vehicle
        capacity = vrow["capacity_kg"]
        stop_ids = [r["location_id"] for r in pend
                    if r["location_id"] in locs and r["location_id"] != depot_id]

        all_ids = [depot_id] + stop_ids
        all_locs = [locs[i] for i in all_ids]
        matrix = build_matrix(all_locs)
        id_to_idx = {lid: i for i, lid in enumerate(all_ids)}

        depot_idx = 0
        visit_idx = list(range(1, len(all_ids)))

        # Nearest-neighbor construction
        nn_tour = nearest_neighbor(depot_idx, visit_idx, matrix)
        d_before = tour_distance(nn_tour, matrix)

        # 2-opt improvement
        final_tour, iters = nn_tour, 0
        if use_2opt:
            final_tour, iters = two_opt(nn_tour, matrix)
        if use_or_opt:
            final_tour = or_opt(final_tour, matrix)

        d_after = tour_distance(final_tour, matrix)
        impr = (d_before - d_after) / d_before * 100 if d_before > 0 else 0

        seq_names = [locs[all_ids[i]].name for i in final_tour]
        total_time = d_after / vrow["speed_kmh"] * 60 + len(stop_ids) * locs[depot_id].service_time
        cost = d_after * vrow["fuel_cost_per_km"]

        rid = f"route_{int(time.time()*1000)}"
        loc_seq = [all_ids[i] for i in final_tour]
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO routes
                (id,vehicle_id,location_ids,total_distance_km,total_time_min,
                 total_load_kg,algorithm,cost_estimate,created_at)
                VALUES (?,?,?,?,?,?,?,?,?)""",
                (rid, vrow["id"], json.dumps(loc_seq),
                 round(d_after,3), round(total_time,1),
                 sum(r["total_w"] for r in pend),
                 f"NN+2opt+OrOpt", round(cost,2), datetime.now().isoformat()))

        return OptimizationResult(
            route_id=rid, vehicle=vehicle_name, stops=len(stop_ids),
            distance_before_km=round(d_before,3), distance_after_km=round(d_after,3),
            improvement_pct=round(impr,2), iterations=iters,
            time_ms=round((time.time()-t0)*1000,2), sequence=seq_names)

    def route_stats(self, route_id: str) -> Optional[Dict]:
        with get_conn(self.db_path) as c:
            row = c.execute("SELECT * FROM routes WHERE id=?", (route_id,)).fetchone()
        if not row: return None
        return dict(row)

    def list_routes(self) -> List[Dict]:
        with get_conn(self.db_path) as c:
            return [dict(r) for r in c.execute(
                "SELECT id,vehicle_id,total_distance_km,total_time_min,cost_estimate,created_at FROM routes ORDER BY created_at DESC")]

    def compare_algorithms(self, locs_subset: Optional[List[str]] = None) -> Dict:
        """Compare NN vs NN+2opt on current deliveries."""
        locs = self._load_locs()
        depot_id = next((lid for lid,l in locs.items() if l.is_depot), None)
        if not depot_id: return {}
        ids = [depot_id] + [lid for lid in locs if lid != depot_id]
        all_locs = [locs[i] for i in ids]
        matrix = build_matrix(all_locs)
        nn_tour = nearest_neighbor(0, list(range(1, len(ids))), matrix)
        nn_dist = tour_distance(nn_tour, matrix)
        opt_tour, _ = two_opt(nn_tour, matrix)
        opt_dist = tour_distance(opt_tour, matrix)
        return {
            "nn_distance_km": round(nn_dist, 3),
            "2opt_distance_km": round(opt_dist, 3),
            "improvement_km": round(nn_dist - opt_dist, 3),
            "improvement_pct": round((nn_dist-opt_dist)/nn_dist*100, 2) if nn_dist else 0
        }


# ── Rich output ────────────────────────────────────────────────────────────────

def table(hdrs, rows, widths=None):
    if not widths:
        widths = [max(len(str(h)), max((len(str(r[i])) for r in rows),default=0))
                  for i,h in enumerate(hdrs)]
    sep = "+" + "+".join("-"*(w+2) for w in widths) + "+"
    def fmt(vals):
        return "|"+"| ".join(f"{str(v):<{widths[i]}} " for i,v in enumerate(vals))+"|"
    print(f"{CYAN}{sep}{NC}"); print(f"{BOLD}{fmt(hdrs)}{NC}"); print(f"{CYAN}{sep}{NC}")
    for row in rows: print(fmt(row))
    print(f"{CYAN}{sep}{NC}")

def ok(m): print(f"{GREEN}✔{NC} {m}")
def err(m): print(f"{RED}✖{NC} {m}"); sys.exit(1)
def info(m): print(f"{CYAN}ℹ{NC} {m}")


# ── CLI ────────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(prog="route_optimizer",
                                 description=f"{BOLD}BlackRoad Route Optimizer{NC}")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("add-location", help="Add a delivery location")
    p.add_argument("name"); p.add_argument("lat", type=float); p.add_argument("lon", type=float)
    p.add_argument("--address", default=""); p.add_argument("--depot", action="store_true")
    p.add_argument("--service-time", type=float, default=5.0, dest="service_time")

    p = sub.add_parser("add-delivery", help="Add a delivery to a location")
    p.add_argument("location"); p.add_argument("weight", type=float)
    p.add_argument("--priority", type=int, default=2, choices=[1,2,3])
    p.add_argument("--notes", default="")

    p = sub.add_parser("add-vehicle", help="Register a vehicle")
    p.add_argument("name"); p.add_argument("capacity", type=float)
    p.add_argument("--speed", type=float, default=60.0)
    p.add_argument("--fuel-cost", type=float, default=0.12, dest="fuel_cost")

    p = sub.add_parser("optimize", help="Optimize delivery route")
    p.add_argument("vehicle"); p.add_argument("--no-2opt", action="store_true", dest="no2opt")

    p = sub.add_parser("compare", help="Compare NN vs 2-opt algorithms")

    p = sub.add_parser("stats", help="Show route statistics")
    p.add_argument("route_id")

    sub.add_parser("list-routes", help="List all computed routes")
    sub.add_parser("list-locations", help="List all locations")

    args = ap.parse_args()
    opt = RouteOptimizer()

    if args.cmd == "add-location":
        loc = opt.add_location(args.name, args.lat, args.lon,
                               args.address, args.depot, args.service_time)
        tag = f"{GREEN}[DEPOT]{NC}" if loc.is_depot else ""
        ok(f"Location {BOLD}{loc.name}{NC} ({loc.lat:.4f},{loc.lon:.4f}) {tag}")

    elif args.cmd == "add-delivery":
        d = opt.add_delivery(args.location, args.weight, args.priority, args.notes)
        ok(f"Delivery {BOLD}{d.id}{NC} – {args.weight}kg to {args.location} (priority {args.priority})")

    elif args.cmd == "add-vehicle":
        v = opt.add_vehicle(args.name, args.capacity, args.speed, args.fuel_cost)
        ok(f"Vehicle {BOLD}{v.name}{NC} – cap={v.capacity_kg}kg speed={v.speed_kmh}km/h")

    elif args.cmd == "optimize":
        info(f"Optimizing route for {BOLD}{args.vehicle}{NC} …")
        res = opt.optimize(args.vehicle, use_2opt=not args.no2opt)
        if not res: err("Optimization failed — check vehicle name and depot exists")
        impr_col = GREEN if res.improvement_pct > 0 else YELLOW
        print(f"\n{BOLD}  Route:{NC} {res.route_id}")
        print(f"  Stops     : {res.stops}")
        print(f"  Before    : {YELLOW}{res.distance_before_km} km{NC}")
        print(f"  After     : {YELLOW}{res.distance_after_km} km{NC}")
        print(f"  Improved  : {impr_col}{res.improvement_pct}%{NC}")
        print(f"  2-opt itr : {res.iterations}")
        print(f"  Time      : {res.time_ms} ms")
        print(f"\n{BOLD}  Sequence:{NC} {' → '.join(res.sequence)}")

    elif args.cmd == "compare":
        r = opt.compare_algorithms()
        if not r: err("No data — add locations first")
        print(f"\n{BOLD}Algorithm Comparison{NC}")
        table(["Algorithm","Distance (km)","Savings (km)","Savings (%)"],
              [["Nearest-Neighbor", r["nn_distance_km"], "-", "-"],
               ["NN + 2-opt", r["2opt_distance_km"],
                r["improvement_km"], f"{r['improvement_pct']}%"]])

    elif args.cmd == "stats":
        s = opt.route_stats(args.route_id)
        if not s: err("Route not found")
        for k,v in s.items():
            if k not in ("location_ids",):
                print(f"  {CYAN}{k:<22}{NC} {v}")

    elif args.cmd == "list-routes":
        rows = opt.list_routes()
        if not rows: info("No routes yet."); return
        table(["ID","Vehicle","Distance(km)","Time(min)","Cost($)","Created"],
              [[r["id"][:14],r["vehicle_id"][:12],r["total_distance_km"],
                r["total_time_min"],r["cost_estimate"],r["created_at"][:19]] for r in rows])

    elif args.cmd == "list-locations":
        rows = opt.list_locations()
        if not rows: info("No locations."); return
        table(["ID","Name","Lat","Lon","Depot"],
              [[r["id"][:12],r["name"],r["lat"],r["lon"],
                f"{GREEN}✔{NC}" if r["is_depot"] else ""] for r in rows])


if __name__ == "__main__":
    main()
