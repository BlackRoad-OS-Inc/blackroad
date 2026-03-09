"""
BlackRoad Warehouse Robot - Robot task coordination, picking list management,
zone assignment, and completion tracking.
"""

import sqlite3
import json
import time
import math
import heapq
import argparse
import sys
import os
import random
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Tuple
from datetime import datetime

RED    = '\033[0;31m'; GREEN  = '\033[0;32m'; YELLOW = '\033[1;33m'
CYAN   = '\033[0;36m'; BLUE   = '\033[0;34m'; BOLD   = '\033[1m'
DIM    = '\033[2m';    NC     = '\033[0m'

DB_PATH = os.environ.get("ROBOT_DB", os.path.expanduser("~/.blackroad/warehouse_robot.db"))

# ── Dataclasses ───────────────────────────────────────────────────────────────

@dataclass
class Zone:
    id: str
    name: str
    aisle_start: int
    aisle_end: int
    shelf_start: int
    shelf_end: int
    category: str = "general"   # refrigerated | hazmat | general | bulk
    capacity: int = 100


@dataclass
class Item:
    id: str
    sku: str
    name: str
    zone_id: str
    aisle: int
    shelf: int
    bin: str
    quantity: int
    weight_kg: float = 1.0
    barcode: str = ""


@dataclass
class Robot:
    id: str
    name: str
    zone_id: str
    current_aisle: int = 1
    current_shelf: int = 1
    battery_pct: float = 100.0
    status: str = "idle"        # idle | picking | charging | error
    speed_m_per_s: float = 1.5
    payload_kg: float = 30.0
    tasks_completed: int = 0
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class PickTask:
    id: str
    pick_list_id: str
    item_id: str
    sku: str
    quantity: int
    aisle: int
    shelf: int
    bin: str
    status: str = "pending"     # pending | assigned | picking | done | error
    robot_id: Optional[str] = None
    assigned_at: Optional[str] = None
    completed_at: Optional[str] = None
    sequence: int = 0


@dataclass
class PickList:
    id: str
    order_ref: str
    priority: int = 2           # 1=urgent 2=normal 3=bulk
    status: str = "open"        # open | in_progress | complete | cancelled
    total_items: int = 0
    picked_items: int = 0
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class AssignmentResult:
    pick_list_id: str
    assigned_tasks: int
    robots_used: List[str]
    estimated_time_s: float
    total_distance_m: float
    sequence_optimized: bool


# ── DB ─────────────────────────────────────────────────────────────────────────

def get_conn(db_path=DB_PATH):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(db_path=DB_PATH):
    with get_conn(db_path) as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS zones (
            id TEXT PRIMARY KEY, name TEXT UNIQUE,
            aisle_start INTEGER, aisle_end INTEGER,
            shelf_start INTEGER, shelf_end INTEGER,
            category TEXT DEFAULT 'general', capacity INTEGER DEFAULT 100
        );
        CREATE TABLE IF NOT EXISTS items (
            id TEXT PRIMARY KEY, sku TEXT UNIQUE, name TEXT,
            zone_id TEXT, aisle INTEGER, shelf INTEGER, bin TEXT,
            quantity INTEGER DEFAULT 0, weight_kg REAL DEFAULT 1.0, barcode TEXT DEFAULT '',
            FOREIGN KEY(zone_id) REFERENCES zones(id)
        );
        CREATE TABLE IF NOT EXISTS robots (
            id TEXT PRIMARY KEY, name TEXT UNIQUE, zone_id TEXT,
            current_aisle INTEGER DEFAULT 1, current_shelf INTEGER DEFAULT 1,
            battery_pct REAL DEFAULT 100.0, status TEXT DEFAULT 'idle',
            speed_m_per_s REAL DEFAULT 1.5, payload_kg REAL DEFAULT 30.0,
            tasks_completed INTEGER DEFAULT 0, created_at TEXT,
            FOREIGN KEY(zone_id) REFERENCES zones(id)
        );
        CREATE TABLE IF NOT EXISTS pick_lists (
            id TEXT PRIMARY KEY, order_ref TEXT, priority INTEGER DEFAULT 2,
            status TEXT DEFAULT 'open',
            total_items INTEGER DEFAULT 0, picked_items INTEGER DEFAULT 0,
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS pick_tasks (
            id TEXT PRIMARY KEY, pick_list_id TEXT, item_id TEXT,
            sku TEXT, quantity INTEGER, aisle INTEGER, shelf INTEGER, bin TEXT,
            status TEXT DEFAULT 'pending', robot_id TEXT, sequence INTEGER DEFAULT 0,
            assigned_at TEXT, completed_at TEXT,
            FOREIGN KEY(pick_list_id) REFERENCES pick_lists(id),
            FOREIGN KEY(item_id) REFERENCES items(id)
        );
        CREATE INDEX IF NOT EXISTS idx_pt_list ON pick_tasks(pick_list_id);
        CREATE INDEX IF NOT EXISTS idx_pt_robot ON pick_tasks(robot_id);
        """)


# ── Spatial helpers ────────────────────────────────────────────────────────────

AISLE_WIDTH_M = 3.0
SHELF_DEPTH_M = 1.5

def pick_distance(a1: int, s1: int, a2: int, s2: int) -> float:
    """Manhattan distance in metres between two pick locations."""
    return abs(a2-a1)*AISLE_WIDTH_M + abs(s2-s1)*SHELF_DEPTH_M


def optimize_pick_sequence(tasks: List[Dict], start_aisle: int, start_shelf: int) -> List[Dict]:
    """
    Greedy nearest-pick sequencing (S-shape + nearest-neighbour).
    Groups by aisle, alternates direction to minimize travel.
    """
    if not tasks: return tasks
    by_aisle: Dict[int, List[Dict]] = {}
    for t in tasks:
        by_aisle.setdefault(t["aisle"], []).append(t)
    # Sort shelves within each aisle, alternating direction
    result = []
    aisles = sorted(by_aisle.keys())
    for i, aisle in enumerate(aisles):
        shelf_tasks = sorted(by_aisle[aisle], key=lambda t: t["shelf"],
                             reverse=(i % 2 == 1))
        result.extend(shelf_tasks)
    for seq, t in enumerate(result):
        t["sequence"] = seq
    return result


# ── Core class ─────────────────────────────────────────────────────────────────

class RobotCoordinator:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        init_db(db_path)

    # ── Zone management ──
    def add_zone(self, name: str, aisle_start: int, aisle_end: int,
                 shelf_start: int, shelf_end: int,
                 category: str = "general", capacity: int = 100) -> Zone:
        zid = f"z_{int(time.time()*1000)}"
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO zones (id,name,aisle_start,aisle_end,shelf_start,shelf_end,category,capacity)
                VALUES (?,?,?,?,?,?,?,?)""",
                (zid,name,aisle_start,aisle_end,shelf_start,shelf_end,category,capacity))
        return Zone(id=zid,name=name,aisle_start=aisle_start,aisle_end=aisle_end,
                    shelf_start=shelf_start,shelf_end=shelf_end,category=category,capacity=capacity)

    # ── Item management ──
    def add_item(self, sku: str, name: str, zone_name: str,
                 aisle: int, shelf: int, bin_loc: str,
                 quantity: int, weight: float = 1.0) -> Item:
        with get_conn(self.db_path) as c:
            z = c.execute("SELECT id FROM zones WHERE name=?", (zone_name,)).fetchone()
        if not z: raise ValueError(f"Zone '{zone_name}' not found")
        iid = f"i_{int(time.time()*1000)}"
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO items (id,sku,name,zone_id,aisle,shelf,bin,quantity,weight_kg)
                VALUES (?,?,?,?,?,?,?,?,?)""",
                (iid,sku,name,z["id"],aisle,shelf,bin_loc,quantity,weight))
        return Item(id=iid,sku=sku,name=name,zone_id=z["id"],
                    aisle=aisle,shelf=shelf,bin=bin_loc,quantity=quantity,weight_kg=weight)

    # ── Robot management ──
    def add_robot(self, name: str, zone_name: str,
                  speed: float = 1.5, payload: float = 30.0) -> Robot:
        with get_conn(self.db_path) as c:
            z = c.execute("SELECT id FROM zones WHERE name=?", (zone_name,)).fetchone()
        if not z: raise ValueError(f"Zone '{zone_name}' not found")
        rid = f"r_{int(time.time()*1000)}"
        now = datetime.now().isoformat()
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO robots
                (id,name,zone_id,speed_m_per_s,payload_kg,created_at)
                VALUES (?,?,?,?,?,?)""", (rid,name,z["id"],speed,payload,now))
        return Robot(id=rid,name=name,zone_id=z["id"],speed_m_per_s=speed,
                     payload_kg=payload,created_at=now)

    # ── Pick list management ──
    def create_pick_list(self, order_ref: str,
                         items: List[Tuple[str,int]],  # [(sku, qty), ...]
                         priority: int = 2) -> PickList:
        plid = f"pl_{int(time.time()*1000)}"
        now = datetime.now().isoformat()
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO pick_lists (id,order_ref,priority,status,total_items,created_at)
                VALUES (?,?,?,?,?,?)""", (plid,order_ref,priority,"open",len(items),now))
            for sku, qty in items:
                irow = c.execute("SELECT id,aisle,shelf,bin FROM items WHERE sku=?", (sku,)).fetchone()
                if not irow: continue
                tid = f"pt_{int(time.time()*1000)}_{sku}"
                c.execute("""INSERT INTO pick_tasks
                    (id,pick_list_id,item_id,sku,quantity,aisle,shelf,bin,status)
                    VALUES (?,?,?,?,?,?,?,?,?)""",
                    (tid,plid,irow["id"],sku,qty,irow["aisle"],irow["shelf"],irow["bin"],"pending"))
        return PickList(id=plid,order_ref=order_ref,priority=priority,total_items=len(items),created_at=now)

    # ── Assignment engine ──
    def assign_pick_list(self, pick_list_id: str) -> Optional[AssignmentResult]:
        """Assign tasks from pick list to idle robots, optimizing sequences."""
        with get_conn(self.db_path) as c:
            tasks = [dict(r) for r in c.execute(
                "SELECT * FROM pick_tasks WHERE pick_list_id=? AND status='pending'",
                (pick_list_id,)).fetchall()]
            robots = [dict(r) for r in c.execute(
                "SELECT * FROM robots WHERE status='idle'").fetchall()]

        if not tasks or not robots: return None

        # Optimize task sequence
        optimized = optimize_pick_sequence(tasks, robots[0]["current_aisle"], robots[0]["current_shelf"])

        # Distribute tasks round-robin among available robots
        robot_tasks: Dict[str, List[Dict]] = {r["id"]: [] for r in robots}
        for i, task in enumerate(optimized):
            robot_id = robots[i % len(robots)]["id"]
            robot_tasks[robot_id].append(task)

        total_dist = 0.0
        total_time = 0.0
        assigned = 0
        robots_used = []
        now = datetime.now().isoformat()

        with get_conn(self.db_path) as c:
            for robot in robots:
                rid = robot["id"]
                my_tasks = robot_tasks[rid]
                if not my_tasks: continue
                robots_used.append(robot["name"])
                prev_a, prev_s = robot["current_aisle"], robot["current_shelf"]
                for task in my_tasks:
                    dist = pick_distance(prev_a, prev_s, task["aisle"], task["shelf"])
                    total_dist += dist
                    total_time += dist / robot["speed_m_per_s"] + 10  # 10s per pick
                    prev_a, prev_s = task["aisle"], task["shelf"]
                    c.execute("""UPDATE pick_tasks SET status='assigned', robot_id=?,
                        sequence=?, assigned_at=? WHERE id=?""",
                        (rid, task["sequence"], now, task["id"]))
                    assigned += 1
                c.execute("UPDATE robots SET status='picking' WHERE id=?", (rid,))
            c.execute("UPDATE pick_lists SET status='in_progress' WHERE id=?", (pick_list_id,))

        return AssignmentResult(
            pick_list_id=pick_list_id, assigned_tasks=assigned,
            robots_used=robots_used,
            estimated_time_s=round(total_time,1),
            total_distance_m=round(total_dist,1),
            sequence_optimized=True)

    def complete_task(self, task_id: str) -> bool:
        now = datetime.now().isoformat()
        with get_conn(self.db_path) as c:
            c.execute("UPDATE pick_tasks SET status='done', completed_at=? WHERE id=?", (now, task_id))
            row = c.execute("SELECT pick_list_id, robot_id FROM pick_tasks WHERE id=?", (task_id,)).fetchone()
            if not row: return False
            c.execute("""UPDATE pick_lists SET picked_items=picked_items+1,
                status=CASE WHEN picked_items+1>=total_items THEN 'complete' ELSE status END
                WHERE id=?""", (row["pick_list_id"],))
            if row["robot_id"]:
                c.execute("UPDATE robots SET tasks_completed=tasks_completed+1 WHERE id=?",
                          (row["robot_id"],))
                # Check if robot has remaining tasks
                remaining = c.execute(
                    "SELECT COUNT(*) as n FROM pick_tasks WHERE robot_id=? AND status='assigned'",
                    (row["robot_id"],)).fetchone()["n"]
                if remaining == 0:
                    c.execute("UPDATE robots SET status='idle' WHERE id=?", (row["robot_id"],))
        return True

    def robot_status(self) -> List[Dict]:
        with get_conn(self.db_path) as c:
            return [dict(r) for r in c.execute(
                """SELECT r.name, r.status, r.battery_pct, r.tasks_completed,
                          z.name as zone, r.current_aisle, r.current_shelf,
                          COUNT(pt.id) as pending_tasks
                   FROM robots r
                   LEFT JOIN zones z ON z.id=r.zone_id
                   LEFT JOIN pick_tasks pt ON pt.robot_id=r.id AND pt.status='assigned'
                   GROUP BY r.id ORDER BY r.name""")]

    def list_pick_lists(self) -> List[Dict]:
        with get_conn(self.db_path) as c:
            return [dict(r) for r in c.execute(
                """SELECT pl.id, pl.order_ref, pl.priority, pl.status,
                          pl.total_items, pl.picked_items, pl.created_at
                   FROM pick_lists pl ORDER BY pl.priority, pl.created_at""")]

    def warehouse_map(self, width: int = 60, height: int = 20) -> str:
        """ASCII warehouse map showing zones, robots, and items."""
        with get_conn(self.db_path) as c:
            zones = [dict(r) for r in c.execute("SELECT * FROM zones")]
            robots = [dict(r) for r in c.execute("SELECT * FROM robots")]
        grid = [[' ' for _ in range(width)] for _ in range(height)]
        colors = [CYAN, GREEN, YELLOW, BLUE, MAGENTA]
        for i, z in enumerate(zones):
            col = colors[i % len(colors)]
            for a in range(z["aisle_start"], min(z["aisle_end"]+1, height)):
                for s in range(z["shelf_start"], min(z["shelf_end"]+1, width)):
                    grid[a][s] = '░'
        for r in robots:
            a, s = min(r["current_aisle"], height-1), min(r["current_shelf"], width-1)
            grid[a][s] = 'R'
        border = "+" + "-"*width + "+"
        rows = [border]
        rows += [f"|{''.join(row)}|" for row in grid]
        rows += [border]
        return '\n'.join(rows)


# ── Rich output ────────────────────────────────────────────────────────────────

def status_color(s):
    return {
        "idle": GREEN, "picking": YELLOW, "charging": BLUE,
        "error": RED, "complete": GREEN, "in_progress": YELLOW,
        "open": CYAN, "cancelled": DIM
    }.get(s, NC)


def table(hdrs, rows, widths=None):
    if not widths:
        widths = [max(len(str(h)),max((len(str(r[i])) for r in rows),default=0))
                  for i,h in enumerate(hdrs)]
    sep = "+"+"+ ".join("-"*(w+1) for w in widths)+"+"
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
    ap = argparse.ArgumentParser(prog="warehouse_robot",
        description=f"{BOLD}BlackRoad Warehouse Robot Coordinator{NC}")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("add-zone", help="Create a warehouse zone")
    p.add_argument("name"); p.add_argument("aisle_start",type=int); p.add_argument("aisle_end",type=int)
    p.add_argument("shelf_start",type=int); p.add_argument("shelf_end",type=int)
    p.add_argument("--category",default="general"); p.add_argument("--capacity",type=int,default=100)

    p = sub.add_parser("add-robot", help="Register a robot")
    p.add_argument("name"); p.add_argument("zone")
    p.add_argument("--speed",type=float,default=1.5); p.add_argument("--payload",type=float,default=30.0)

    p = sub.add_parser("add-item", help="Register an item in the warehouse")
    p.add_argument("sku"); p.add_argument("name"); p.add_argument("zone")
    p.add_argument("aisle",type=int); p.add_argument("shelf",type=int); p.add_argument("bin")
    p.add_argument("quantity",type=int); p.add_argument("--weight",type=float,default=1.0)

    p = sub.add_parser("create-picklist", help="Create a pick list")
    p.add_argument("order_ref")
    p.add_argument("--items",required=True,help="Comma-separated SKU:QTY pairs")
    p.add_argument("--priority",type=int,default=2)

    p = sub.add_parser("assign", help="Assign a pick list to robots")
    p.add_argument("pick_list_id")

    p = sub.add_parser("complete", help="Mark a pick task as done")
    p.add_argument("task_id")

    sub.add_parser("status", help="Show all robot statuses")
    sub.add_parser("list-picklists", help="List all pick lists")
    sub.add_parser("map", help="Show ASCII warehouse map")

    args = ap.parse_args()
    coord = RobotCoordinator()

    if args.cmd == "add-zone":
        z = coord.add_zone(args.name,args.aisle_start,args.aisle_end,
                           args.shelf_start,args.shelf_end,args.category,args.capacity)
        ok(f"Zone {BOLD}{z.name}{NC} aisles {z.aisle_start}-{z.aisle_end} shelves {z.shelf_start}-{z.shelf_end}")

    elif args.cmd == "add-robot":
        r = coord.add_robot(args.name, args.zone, args.speed, args.payload)
        ok(f"Robot {BOLD}{r.name}{NC} in zone {args.zone} speed={r.speed_m_per_s}m/s payload={r.payload_kg}kg")

    elif args.cmd == "add-item":
        item = coord.add_item(args.sku,args.name,args.zone,args.aisle,
                              args.shelf,args.bin,args.quantity,args.weight)
        ok(f"Item {BOLD}{item.sku}{NC} '{item.name}' → aisle {item.aisle} shelf {item.shelf} bin {item.bin}")

    elif args.cmd == "create-picklist":
        pairs = []
        for pair in args.items.split(","):
            sku, qty = pair.strip().split(":")
            pairs.append((sku.strip(), int(qty.strip())))
        pl = coord.create_pick_list(args.order_ref, pairs, args.priority)
        ok(f"Pick list {BOLD}{pl.id}{NC} for order {pl.order_ref} – {pl.total_items} items (priority {pl.priority})")

    elif args.cmd == "assign":
        result = coord.assign_pick_list(args.pick_list_id)
        if not result: err("Assignment failed – check pick list ID and available robots")
        ok(f"Assigned {result.assigned_tasks} tasks to {len(result.robots_used)} robots")
        print(f"  Robots     : {', '.join(result.robots_used)}")
        print(f"  Est. time  : {result.estimated_time_s}s")
        print(f"  Distance   : {result.total_distance_m}m")

    elif args.cmd == "complete":
        if coord.complete_task(args.task_id):
            ok(f"Task {args.task_id} marked complete")
        else: err("Task not found")

    elif args.cmd == "status":
        rows = coord.robot_status()
        if not rows: info("No robots registered."); return
        table(["Robot","Status","Battery","Zone","Aisle","Tasks Done","Pending"],
              [[r["name"], status_color(r["status"])+r["status"]+NC,
                f"{r['battery_pct']}%",r["zone"],r["current_aisle"],
                r["tasks_completed"],r["pending_tasks"]] for r in rows])

    elif args.cmd == "list-picklists":
        rows = coord.list_pick_lists()
        if not rows: info("No pick lists."); return
        table(["ID","Order","Priority","Status","Total","Picked","Created"],
              [[r["id"][:14],r["order_ref"],r["priority"],
                status_color(r["status"])+r["status"]+NC,
                r["total_items"],r["picked_items"],r["created_at"][:19]] for r in rows])

    elif args.cmd == "map":
        print(f"\n{BOLD}Warehouse Map{NC} {DIM}(R=robot, ░=zone){NC}")
        print(coord.warehouse_map())


if __name__ == "__main__":
    main()
