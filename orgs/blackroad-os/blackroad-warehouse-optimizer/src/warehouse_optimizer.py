"""
BlackRoad Warehouse Optimizer - Warehouse layout optimization with slot
utilization analytics, ABC analysis, and placement recommendation engine.
"""

import sqlite3
import json
import math
import time
import argparse
import sys
import os
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Tuple
from datetime import datetime, timedelta
from collections import defaultdict

RED    = '\033[0;31m'; GREEN  = '\033[0;32m'; YELLOW = '\033[1;33m'
CYAN   = '\033[0;36m'; BLUE   = '\033[0;34m'; MAGENTA= '\033[0;35m'
BOLD   = '\033[1m';    DIM    = '\033[2m';    NC     = '\033[0m'

DB_PATH = os.environ.get("WOPT_DB", os.path.expanduser("~/.blackroad/warehouse_optimizer.db"))

# ── Dataclasses ───────────────────────────────────────────────────────────────

@dataclass
class Slot:
    id: str
    aisle: int
    row: int
    level: int          # 0=floor 1=low 2=mid 3=high
    slot_type: str = "standard"   # standard | bulk | refrigerated | hazmat
    max_weight_kg: float = 200.0
    width_m: float = 1.0
    depth_m: float = 0.8
    height_m: float = 0.5
    zone: str = "A"
    occupied_by: Optional[str] = None   # product_id
    fill_pct: float = 0.0


@dataclass
class Product:
    id: str
    sku: str
    name: str
    category: str
    weight_kg: float
    width_m: float = 0.3
    depth_m: float = 0.2
    height_m: float = 0.2
    velocity: str = "B"    # A=fast | B=medium | C=slow (ABC analysis)
    picks_30d: int = 0
    replenishment_days: int = 7
    min_stock: int = 5
    current_stock: int = 0
    current_slot_id: Optional[str] = None


@dataclass
class SlotUsageRecord:
    id: str
    slot_id: str
    product_id: str
    event: str          # place | pick | move | replenish
    quantity: int
    timestamp: str


@dataclass
class OptimizationReport:
    total_slots: int
    occupied_slots: int
    utilization_pct: float
    a_items_golden_zone: int    # fast movers in aisle 1-3
    b_items_mid_zone: int
    c_items_far_zone: int
    misplaced_items: int        # fast movers in far aisles
    recommendations: List[Dict]
    potential_travel_reduction_pct: float


@dataclass
class ABCResult:
    sku: str
    name: str
    picks_30d: int
    cumulative_pct: float
    class_label: str    # A | B | C


# ── DB ─────────────────────────────────────────────────────────────────────────

def get_conn(db_path=DB_PATH):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(db_path=DB_PATH):
    with get_conn(db_path) as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS slots (
            id TEXT PRIMARY KEY,
            aisle INTEGER, row INTEGER, level INTEGER,
            slot_type TEXT DEFAULT 'standard',
            max_weight_kg REAL DEFAULT 200.0,
            width_m REAL DEFAULT 1.0, depth_m REAL DEFAULT 0.8, height_m REAL DEFAULT 0.5,
            zone TEXT DEFAULT 'A',
            occupied_by TEXT DEFAULT NULL, fill_pct REAL DEFAULT 0.0
        );
        CREATE TABLE IF NOT EXISTS products (
            id TEXT PRIMARY KEY, sku TEXT UNIQUE, name TEXT, category TEXT,
            weight_kg REAL DEFAULT 1.0,
            width_m REAL DEFAULT 0.3, depth_m REAL DEFAULT 0.2, height_m REAL DEFAULT 0.2,
            velocity TEXT DEFAULT 'B',
            picks_30d INTEGER DEFAULT 0, replenishment_days INTEGER DEFAULT 7,
            min_stock INTEGER DEFAULT 5, current_stock INTEGER DEFAULT 0,
            current_slot_id TEXT,
            FOREIGN KEY(current_slot_id) REFERENCES slots(id)
        );
        CREATE TABLE IF NOT EXISTS slot_usage (
            id TEXT PRIMARY KEY, slot_id TEXT, product_id TEXT,
            event TEXT, quantity INTEGER DEFAULT 0, timestamp TEXT,
            FOREIGN KEY(slot_id) REFERENCES slots(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
        );
        CREATE INDEX IF NOT EXISTS idx_su_slot ON slot_usage(slot_id);
        CREATE INDEX IF NOT EXISTS idx_su_prod ON slot_usage(product_id);
        CREATE INDEX IF NOT EXISTS idx_slot_aisle ON slots(aisle, zone);
        """)


# ── ABC Analysis ───────────────────────────────────────────────────────────────

def abc_analysis(products: List[Dict]) -> List[ABCResult]:
    """Classify products A/B/C based on 80/15/5 Pareto rule."""
    if not products: return []
    total_picks = sum(p["picks_30d"] for p in products)
    if total_picks == 0: total_picks = 1
    sorted_prods = sorted(products, key=lambda p: p["picks_30d"], reverse=True)
    results = []
    cum = 0.0
    for p in sorted_prods:
        cum += p["picks_30d"] / total_picks * 100
        label = "A" if cum <= 80 else ("B" if cum <= 95 else "C")
        results.append(ABCResult(
            sku=p["sku"], name=p["name"], picks_30d=p["picks_30d"],
            cumulative_pct=round(cum, 2), class_label=label))
    return results


# ── Slot scoring ───────────────────────────────────────────────────────────────

def slot_score(slot: Dict, product: Dict) -> float:
    """Score a slot for a product; higher = better placement."""
    score = 100.0
    # Proximity bonus: aisle 1-3 best for A items
    aisle_dist = slot["aisle"]
    velocity = product.get("velocity","B")
    if velocity == "A": score -= aisle_dist * 5
    elif velocity == "B": score -= aisle_dist * 2
    else: score -= (20 - aisle_dist) * 2   # C items prefer far aisles

    # Level penalty: level 0 (floor) and 1 (low) best for heavy items
    if product["weight_kg"] > 20 and slot["level"] > 1: score -= 20
    if slot["level"] == 0: score += 5   # floor accessible

    # Fill efficiency
    slot_vol = slot["width_m"] * slot["depth_m"] * slot["height_m"]
    prod_vol = product["width_m"] * product["depth_m"] * product["height_m"]
    if slot_vol > 0:
        fit_pct = min(prod_vol / slot_vol, 1.0)
        score += fit_pct * 10

    # Slot type match
    cat = product.get("category","")
    if "refrig" in cat.lower() and slot["slot_type"] == "refrigerated": score += 30
    if "hazmat" in cat.lower() and slot["slot_type"] == "hazmat": score += 30

    return score


# ── Core class ─────────────────────────────────────────────────────────────────

class WarehouseOptimizer:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        init_db(db_path)

    # ── Slot management ──
    def add_slot(self, aisle: int, row: int, level: int,
                 zone: str = "A", slot_type: str = "standard",
                 max_weight: float = 200.0) -> Slot:
        sid = f"s{aisle:02d}{row:02d}{level}"
        with get_conn(self.db_path) as c:
            c.execute("""INSERT OR REPLACE INTO slots
                (id,aisle,row,level,slot_type,max_weight_kg,zone)
                VALUES (?,?,?,?,?,?,?)""",
                (sid,aisle,row,level,slot_type,max_weight,zone))
        return Slot(id=sid,aisle=aisle,row=row,level=level,
                    slot_type=slot_type,max_weight_kg=max_weight,zone=zone)

    def bulk_create_slots(self, aisles: int, rows_per_aisle: int,
                          levels: int = 4, zone: str = "A"):
        count = 0
        with get_conn(self.db_path) as c:
            for a in range(1, aisles+1):
                for r in range(1, rows_per_aisle+1):
                    for l in range(levels):
                        sid = f"s{a:02d}{r:02d}{l}"
                        c.execute("""INSERT OR IGNORE INTO slots
                            (id,aisle,row,level,zone) VALUES (?,?,?,?,?)""",
                            (sid,a,r,l,zone))
                        count += 1
        return count

    # ── Product management ──
    def add_product(self, sku: str, name: str, category: str,
                    weight: float, picks_30d: int = 0,
                    stock: int = 0, min_stock: int = 5) -> Product:
        pid = f"p_{int(time.time()*1000)}"
        # Auto-assign velocity
        v = "A" if picks_30d >= 50 else ("B" if picks_30d >= 10 else "C")
        with get_conn(self.db_path) as c:
            c.execute("""INSERT OR REPLACE INTO products
                (id,sku,name,category,weight_kg,velocity,picks_30d,current_stock,min_stock)
                VALUES (?,?,?,?,?,?,?,?,?)""",
                (pid,sku,name,category,weight,v,picks_30d,stock,min_stock))
        return Product(id=pid,sku=sku,name=name,category=category,
                       weight_kg=weight,velocity=v,picks_30d=picks_30d,
                       current_stock=stock,min_stock=min_stock)

    def place_product(self, sku: str, slot_id: str, quantity: int = 1) -> bool:
        with get_conn(self.db_path) as c:
            p = c.execute("SELECT id FROM products WHERE sku=?", (sku,)).fetchone()
            s = c.execute("SELECT id,occupied_by FROM slots WHERE id=?", (slot_id,)).fetchone()
        if not p or not s: return False
        now = datetime.now().isoformat()
        with get_conn(self.db_path) as c:
            c.execute("UPDATE slots SET occupied_by=?, fill_pct=50 WHERE id=?", (p["id"], slot_id))
            c.execute("UPDATE products SET current_slot_id=?, current_stock=? WHERE id=?",
                      (slot_id, quantity, p["id"]))
            uid = f"su_{int(time.time()*1000)}"
            c.execute("""INSERT INTO slot_usage (id,slot_id,product_id,event,quantity,timestamp)
                VALUES (?,?,?,?,?,?)""", (uid, slot_id, p["id"], "place", quantity, now))
        return True

    # ── Recommend placement ──
    def recommend_placement(self, sku: str, top_n: int = 5) -> List[Dict]:
        with get_conn(self.db_path) as c:
            p = c.execute("SELECT * FROM products WHERE sku=?", (sku,)).fetchone()
            free_slots = c.execute(
                "SELECT * FROM slots WHERE occupied_by IS NULL ORDER BY aisle,row,level"
            ).fetchall()
        if not p or not free_slots: return []
        prod_d = dict(p)
        scored = [(slot_score(dict(s), prod_d), dict(s)) for s in free_slots]
        scored.sort(key=lambda x: -x[0])
        return [{"score": round(sc,1), **sl} for sc, sl in scored[:top_n]]

    # ── Analytics ──
    def abc_classify(self) -> List[ABCResult]:
        with get_conn(self.db_path) as c:
            prods = [dict(r) for r in c.execute("SELECT sku,name,picks_30d FROM products")]
        return abc_analysis(prods)

    def utilization_stats(self) -> Dict:
        with get_conn(self.db_path) as c:
            total = c.execute("SELECT COUNT(*) as n FROM slots").fetchone()["n"]
            occupied = c.execute("SELECT COUNT(*) as n FROM slots WHERE occupied_by IS NOT NULL").fetchone()["n"]
            by_zone = c.execute(
                """SELECT zone, COUNT(*) as total,
                   SUM(CASE WHEN occupied_by IS NOT NULL THEN 1 ELSE 0 END) as occ
                   FROM slots GROUP BY zone""").fetchall()
            by_level = c.execute(
                """SELECT level, COUNT(*) as total,
                   SUM(CASE WHEN occupied_by IS NOT NULL THEN 1 ELSE 0 END) as occ
                   FROM slots GROUP BY level ORDER BY level""").fetchall()
        return {
            "total_slots": total, "occupied": occupied,
            "utilization_pct": round(occupied/total*100,1) if total else 0,
            "free": total-occupied,
            "by_zone": [dict(r) for r in by_zone],
            "by_level": [dict(r) for r in by_level]
        }

    # ── Optimization engine ──
    def optimize(self) -> OptimizationReport:
        """Generate layout optimization recommendations."""
        with get_conn(self.db_path) as c:
            products = [dict(r) for r in c.execute("SELECT * FROM products")]
            slots = {r["id"]: dict(r) for r in c.execute("SELECT * FROM slots")}

        abc = {r.sku: r.class_label for r in abc_analysis(products)}
        stats = self.utilization_stats()

        # Find misplaced items: A-class in aisle > 5, C-class in aisle <= 2
        recommendations = []
        a_golden = b_mid = c_far = misplaced = 0
        for p in products:
            label = abc.get(p["sku"], "C")
            slot_id = p.get("current_slot_id")
            if not slot_id or slot_id not in slots:
                continue
            s = slots[slot_id]
            if label == "A":
                if s["aisle"] <= 3: a_golden += 1
                else:
                    misplaced += 1
                    # Find a better slot
                    best = self.recommend_placement(p["sku"], top_n=1)
                    if best:
                        recommendations.append({
                            "action": "MOVE",
                            "sku": p["sku"],
                            "name": p["name"],
                            "current_slot": slot_id,
                            "suggested_slot": best[0]["id"],
                            "reason": f"A-class item in aisle {s['aisle']} → move to aisle {best[0]['aisle']}",
                            "priority": "HIGH"
                        })
            elif label == "B":
                if 3 < s["aisle"] <= 7: b_mid += 1
            elif label == "C":
                if s["aisle"] > 5: c_far += 1

        # Low stock alerts
        low_stock = [p for p in products if p["current_stock"] < p["min_stock"]]
        for p in low_stock[:5]:
            recommendations.append({
                "action": "REPLENISH",
                "sku": p["sku"],
                "name": p["name"],
                "current_stock": p["current_stock"],
                "min_stock": p["min_stock"],
                "reason": "Stock below minimum",
                "priority": "MEDIUM"
            })

        travel_reduction = min(misplaced / max(len(products),1) * 35, 35)
        return OptimizationReport(
            total_slots=stats["total_slots"],
            occupied_slots=stats["occupied"],
            utilization_pct=stats["utilization_pct"],
            a_items_golden_zone=a_golden,
            b_items_mid_zone=b_mid,
            c_items_far_zone=c_far,
            misplaced_items=misplaced,
            recommendations=recommendations,
            potential_travel_reduction_pct=round(travel_reduction,1))

    def slot_heatmap(self, max_aisles: int = 10, max_rows: int = 20) -> str:
        """ASCII heatmap of slot utilization."""
        with get_conn(self.db_path) as c:
            slots = [dict(r) for r in c.execute(
                "SELECT aisle,row,occupied_by FROM slots WHERE aisle<=? AND row<=?",
                (max_aisles, max_rows))]
        grid: Dict[Tuple[int,int], bool] = {}
        for s in slots:
            grid[(s["aisle"], s["row"])] = s["occupied_by"] is not None
        lines = [f"{DIM}     " + "".join(f"{r:2}" for r in range(1,max_rows+1)) + f"{NC}"]
        for a in range(1, max_aisles+1):
            row_chars = []
            for r in range(1, max_rows+1):
                occ = grid.get((a,r), False)
                row_chars.append(f"{GREEN}██{NC}" if occ else f"{DIM}··{NC}")
            lines.append(f"  A{a:02d} {''.join(row_chars)}")
        lines.append(f"\n  {GREEN}██{NC} Occupied  {DIM}··{NC} Empty")
        return '\n'.join(lines)

    def list_products(self) -> List[Dict]:
        with get_conn(self.db_path) as c:
            return [dict(r) for r in c.execute(
                "SELECT sku,name,category,velocity,picks_30d,current_stock,min_stock,current_slot_id FROM products ORDER BY picks_30d DESC")]


# ── Rich output ────────────────────────────────────────────────────────────────

def vel_color(v):
    return {RED+BOLD: "A", YELLOW: "B", DIM: "C"}.get(v,NC) if False else \
           (RED+BOLD if v=="A" else (YELLOW if v=="B" else DIM))


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
    ap = argparse.ArgumentParser(prog="warehouse_optimizer",
        description=f"{BOLD}BlackRoad Warehouse Optimizer{NC}")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("add-slot", help="Add a warehouse slot")
    p.add_argument("aisle",type=int); p.add_argument("row",type=int); p.add_argument("level",type=int)
    p.add_argument("--zone",default="A"); p.add_argument("--type",default="standard",dest="slot_type")
    p.add_argument("--max-weight",type=float,default=200.0,dest="max_weight")

    p = sub.add_parser("bulk-slots", help="Bulk create slots")
    p.add_argument("aisles",type=int); p.add_argument("rows",type=int)
    p.add_argument("--levels",type=int,default=4); p.add_argument("--zone",default="A")

    p = sub.add_parser("add-product", help="Register a product")
    p.add_argument("sku"); p.add_argument("name"); p.add_argument("category")
    p.add_argument("weight",type=float)
    p.add_argument("--picks",type=int,default=0,dest="picks_30d")
    p.add_argument("--stock",type=int,default=0); p.add_argument("--min-stock",type=int,default=5,dest="min_stock")

    p = sub.add_parser("place", help="Place a product in a slot")
    p.add_argument("sku"); p.add_argument("slot_id"); p.add_argument("--qty",type=int,default=1)

    p = sub.add_parser("recommend", help="Get slot placement recommendations for a product")
    p.add_argument("sku"); p.add_argument("--top",type=int,default=5)

    sub.add_parser("analyze", help="Run ABC analysis on all products")
    sub.add_parser("optimize", help="Generate optimization recommendations")
    sub.add_parser("report", help="Show utilization report")
    sub.add_parser("heatmap", help="Show slot utilization heatmap")
    sub.add_parser("list-products", help="List all products")

    args = ap.parse_args()
    wopt = WarehouseOptimizer()

    if args.cmd == "add-slot":
        s = wopt.add_slot(args.aisle,args.row,args.level,args.zone,args.slot_type,args.max_weight)
        ok(f"Slot {BOLD}{s.id}{NC} aisle={s.aisle} row={s.row} level={s.level} zone={s.zone}")

    elif args.cmd == "bulk-slots":
        n = wopt.bulk_create_slots(args.aisles, args.rows, args.levels, args.zone)
        ok(f"Created {BOLD}{n}{NC} slots ({args.aisles} aisles × {args.rows} rows × {args.levels} levels)")

    elif args.cmd == "add-product":
        p = wopt.add_product(args.sku,args.name,args.category,args.weight,
                              args.picks_30d,args.stock,args.min_stock)
        print(f"{GREEN}✔{NC} Product {BOLD}{p.sku}{NC} '{p.name}' velocity={vel_color(p.velocity)}{p.velocity}{NC}")

    elif args.cmd == "place":
        if wopt.place_product(args.sku, args.slot_id, args.qty):
            ok(f"Placed {BOLD}{args.sku}{NC} (qty={args.qty}) in slot {args.slot_id}")
        else: err("Product or slot not found")

    elif args.cmd == "recommend":
        recs = wopt.recommend_placement(args.sku, args.top)
        if not recs: info("No free slots found."); return
        print(f"\n{BOLD}Top {args.top} Slots for {args.sku}{NC}")
        table(["Score","Slot ID","Aisle","Row","Level","Type","Zone"],
              [[r["score"],r["id"],r["aisle"],r["row"],r["level"],r["slot_type"],r["zone"]] for r in recs])

    elif args.cmd == "analyze":
        results = wopt.abc_classify()
        if not results: info("No products."); return
        counts = {"A":0,"B":0,"C":0}
        rows = []
        for r in results:
            counts[r.class_label] += 1
            rows.append([vel_color(r.class_label)+r.class_label+NC,
                         r.sku,r.name[:25],r.picks_30d,f"{r.cumulative_pct}%"])
        table(["Class","SKU","Name","Picks/30d","Cumulative%"], rows)
        print(f"\n  {RED+BOLD}A{NC} (top 80% picks): {counts['A']} items  "
              f"{YELLOW}B{NC}: {counts['B']} items  {DIM}C{NC}: {counts['C']} items")

    elif args.cmd == "optimize":
        rpt = wopt.optimize()
        print(f"\n{BOLD}Optimization Report{NC}")
        print(f"  Slots        : {rpt.occupied_slots}/{rpt.total_slots} ({rpt.utilization_pct}% utilized)")
        print(f"  A in golden  : {GREEN}{rpt.a_items_golden_zone}{NC}")
        print(f"  B in mid     : {YELLOW}{rpt.b_items_mid_zone}{NC}")
        print(f"  C in far     : {DIM}{rpt.c_items_far_zone}{NC}")
        print(f"  Misplaced    : {RED}{rpt.misplaced_items}{NC}")
        print(f"  Travel saving: {GREEN}~{rpt.potential_travel_reduction_pct}%{NC}")
        if rpt.recommendations:
            print(f"\n{BOLD}Recommendations:{NC}")
            for rec in rpt.recommendations[:10]:
                prio_c = RED if rec["priority"]=="HIGH" else YELLOW
                print(f"  {prio_c}[{rec['priority']}]{NC} {rec['action']}: {rec['sku']} – {rec['reason']}")

    elif args.cmd == "report":
        stats = wopt.utilization_stats()
        print(f"\n{BOLD}Utilization Report{NC}")
        print(f"  Total slots  : {stats['total_slots']}")
        print(f"  Occupied     : {GREEN}{stats['occupied']}{NC}")
        print(f"  Free         : {YELLOW}{stats['free']}{NC}")
        pct = stats["utilization_pct"]
        bar_len = int(pct / 2)
        bar = f"{GREEN}{'█'*bar_len}{NC}{'░'*(50-bar_len)}"
        print(f"  Utilization  : [{bar}] {pct}%")
        if stats["by_zone"]:
            print(f"\n{BOLD}By Zone:{NC}")
            for z in stats["by_zone"]:
                zpct = round(z["occ"]/z["total"]*100,1) if z["total"] else 0
                print(f"  Zone {z['zone']}: {z['occ']}/{z['total']} ({zpct}%)")

    elif args.cmd == "heatmap":
        print(f"\n{BOLD}Slot Utilization Heatmap{NC}")
        print(wopt.slot_heatmap())

    elif args.cmd == "list-products":
        rows = wopt.list_products()
        if not rows: info("No products."); return
        table(["SKU","Name","Category","Vel","Picks/30d","Stock","Min","Slot"],
              [[r["sku"],r["name"][:20],r["category"],
                vel_color(r["velocity"])+r["velocity"]+NC,
                r["picks_30d"],r["current_stock"],r["min_stock"],
                (r["current_slot_id"] or "-")[:10]] for r in rows])


if __name__ == "__main__":
    main()
