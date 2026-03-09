"""
BlackRoad Vehicle Maintenance - Fleet maintenance scheduler with cost tracking,
predictive service alerts, and full service history.
"""

import sqlite3
import json
import time
import math
import argparse
import sys
import os
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

RED    = '\033[0;31m'; GREEN  = '\033[0;32m'; YELLOW = '\033[1;33m'
CYAN   = '\033[0;36m'; BLUE   = '\033[0;34m'; BOLD   = '\033[1m'
DIM    = '\033[2m';    NC     = '\033[0m'

DB_PATH = os.environ.get("MAINT_DB", os.path.expanduser("~/.blackroad/vehicle_maintenance.db"))

# ── Dataclasses ───────────────────────────────────────────────────────────────

@dataclass
class Vehicle:
    id: str
    name: str
    make: str
    model: str
    year: int
    vin: str
    odometer_km: float
    fuel_type: str = "petrol"
    status: str = "active"       # active | maintenance | retired
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class ServiceType:
    id: str
    name: str
    interval_km: float
    interval_days: int
    estimated_cost: float
    criticality: str = "routine"  # routine | important | critical


@dataclass
class MaintenanceRecord:
    id: str
    vehicle_id: str
    service_type_id: str
    odometer_km: float
    cost: float
    technician: str
    notes: str
    parts_replaced: str
    service_date: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class ServiceAlert:
    vehicle_id: str
    vehicle_name: str
    service_type: str
    criticality: str
    last_service_km: float
    current_km: float
    interval_km: float
    km_overdue: float
    last_service_date: str
    days_since_service: int
    interval_days: int
    days_overdue: int

    @property
    def severity(self) -> str:
        if self.criticality == "critical" and (self.km_overdue > 0 or self.days_overdue > 0):
            return "CRITICAL"
        if self.km_overdue > 0 or self.days_overdue > 0:
            return "OVERDUE"
        if self.km_overdue > -500 or self.days_overdue > -14:
            return "DUE_SOON"
        return "OK"


@dataclass
class CostAnalysis:
    vehicle_id: str
    vehicle_name: str
    total_services: int
    total_cost: float
    avg_cost_per_service: float
    cost_per_km: float
    most_expensive_service: str
    costliest_month: str
    breakdown: Dict[str, float]


# ── DB ─────────────────────────────────────────────────────────────────────────

def get_conn(db_path=DB_PATH):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(db_path=DB_PATH):
    with get_conn(db_path) as c:
        c.executescript("""
        CREATE TABLE IF NOT EXISTS vehicles (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, make TEXT, model TEXT,
            year INTEGER, vin TEXT UNIQUE, odometer_km REAL DEFAULT 0,
            fuel_type TEXT DEFAULT 'petrol', status TEXT DEFAULT 'active',
            created_at TEXT
        );
        CREATE TABLE IF NOT EXISTS service_types (
            id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE,
            interval_km REAL, interval_days INTEGER,
            estimated_cost REAL DEFAULT 0.0,
            criticality TEXT DEFAULT 'routine'
        );
        CREATE TABLE IF NOT EXISTS maintenance_records (
            id TEXT PRIMARY KEY, vehicle_id TEXT, service_type_id TEXT,
            odometer_km REAL, cost REAL DEFAULT 0.0, technician TEXT DEFAULT '',
            notes TEXT DEFAULT '', parts_replaced TEXT DEFAULT '',
            service_date TEXT,
            FOREIGN KEY(vehicle_id) REFERENCES vehicles(id),
            FOREIGN KEY(service_type_id) REFERENCES service_types(id)
        );
        CREATE INDEX IF NOT EXISTS idx_mr_vehicle ON maintenance_records(vehicle_id);
        CREATE INDEX IF NOT EXISTS idx_mr_date ON maintenance_records(service_date);

        -- Seed standard service types
        INSERT OR IGNORE INTO service_types VALUES
            ('st_oil','Oil Change',10000,180,80.0,'routine'),
            ('st_tire','Tire Rotation',12000,365,50.0,'routine'),
            ('st_brake','Brake Inspection',25000,365,120.0,'important'),
            ('st_trans','Transmission Service',50000,730,350.0,'important'),
            ('st_timing','Timing Belt',100000,1825,600.0,'critical'),
            ('st_coolant','Coolant Flush',40000,730,150.0,'routine'),
            ('st_airfil','Air Filter',15000,365,40.0,'routine'),
            ('st_spark','Spark Plugs',60000,1095,180.0,'important');
        """)


# ── Core class ─────────────────────────────────────────────────────────────────

class MaintenanceManager:
    def __init__(self, db_path=DB_PATH):
        self.db_path = db_path
        init_db(db_path)

    def add_vehicle(self, name: str, make: str, model: str, year: int,
                    vin: str, odometer: float = 0.0, fuel: str = "petrol") -> Vehicle:
        vid = f"v_{int(time.time()*1000)}"
        v = Vehicle(id=vid, name=name, make=make, model=model, year=year,
                    vin=vin, odometer_km=odometer, fuel_type=fuel)
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO vehicles (id,name,make,model,year,vin,odometer_km,fuel_type,created_at)
                VALUES (?,?,?,?,?,?,?,?,?)""",
                (vid,name,make,model,year,vin,odometer,fuel,v.created_at))
        return v

    def update_odometer(self, vehicle_name: str, km: float):
        with get_conn(self.db_path) as c:
            c.execute("UPDATE vehicles SET odometer_km=? WHERE name=?", (km, vehicle_name))

    def record_service(self, vehicle_name: str, service_name: str, odometer: float,
                       cost: float, technician: str = "", notes: str = "",
                       parts: str = "") -> MaintenanceRecord:
        with get_conn(self.db_path) as c:
            vrow = c.execute("SELECT id FROM vehicles WHERE name=?", (vehicle_name,)).fetchone()
            srow = c.execute("SELECT id FROM service_types WHERE name=?", (service_name,)).fetchone()
        if not vrow: raise ValueError(f"Vehicle '{vehicle_name}' not found")
        if not srow: raise ValueError(f"Service type '{service_name}' not found")
        mid = f"mr_{int(time.time()*1000)}"
        rec = MaintenanceRecord(id=mid, vehicle_id=vrow["id"], service_type_id=srow["id"],
                                odometer_km=odometer, cost=cost, technician=technician,
                                notes=notes, parts_replaced=parts)
        with get_conn(self.db_path) as c:
            c.execute("""INSERT INTO maintenance_records
                (id,vehicle_id,service_type_id,odometer_km,cost,technician,notes,parts_replaced,service_date)
                VALUES (?,?,?,?,?,?,?,?,?)""",
                (mid,vrow["id"],srow["id"],odometer,cost,technician,notes,parts,rec.service_date))
            # Update vehicle odometer if higher
            c.execute("UPDATE vehicles SET odometer_km=MAX(odometer_km,?) WHERE id=?",
                      (odometer, vrow["id"]))
        return rec

    def get_alerts(self, vehicle_name: Optional[str] = None) -> List[ServiceAlert]:
        """Calculate service alerts for all (or one) vehicles."""
        with get_conn(self.db_path) as c:
            if vehicle_name:
                vehicles = c.execute(
                    "SELECT * FROM vehicles WHERE name=? AND status='active'",
                    (vehicle_name,)).fetchall()
            else:
                vehicles = c.execute(
                    "SELECT * FROM vehicles WHERE status='active'").fetchall()
            service_types = {r["id"]: dict(r) for r in
                             c.execute("SELECT * FROM service_types").fetchall()}

        alerts = []
        with get_conn(self.db_path) as c:
            for v in vehicles:
                for st_id, st in service_types.items():
                    last = c.execute(
                        """SELECT odometer_km, service_date FROM maintenance_records
                           WHERE vehicle_id=? AND service_type_id=?
                           ORDER BY service_date DESC LIMIT 1""",
                        (v["id"], st_id)).fetchone()
                    if not last:
                        last_km, last_date = 0.0, v["created_at"][:10]
                    else:
                        last_km, last_date = last["odometer_km"], last["service_date"][:10]

                    km_overdue = v["odometer_km"] - last_km - st["interval_km"]
                    try:
                        last_dt = datetime.fromisoformat(last_date)
                    except Exception:
                        last_dt = datetime.now()
                    days_since = (datetime.now() - last_dt).days
                    days_overdue = days_since - st["interval_days"]

                    alerts.append(ServiceAlert(
                        vehicle_id=v["id"], vehicle_name=v["name"],
                        service_type=st["name"], criticality=st["criticality"],
                        last_service_km=last_km, current_km=v["odometer_km"],
                        interval_km=st["interval_km"], km_overdue=km_overdue,
                        last_service_date=last_date, days_since_service=days_since,
                        interval_days=st["interval_days"], days_overdue=days_overdue))
        # Sort by severity
        sev_order = {"CRITICAL":0,"OVERDUE":1,"DUE_SOON":2,"OK":3}
        alerts.sort(key=lambda a: sev_order.get(a.severity, 9))
        return alerts

    def cost_analysis(self, vehicle_name: str) -> Optional[CostAnalysis]:
        with get_conn(self.db_path) as c:
            vrow = c.execute("SELECT * FROM vehicles WHERE name=?", (vehicle_name,)).fetchone()
            if not vrow: return None
            recs = c.execute(
                """SELECT mr.cost, mr.service_date, st.name as svc_name, mr.odometer_km
                   FROM maintenance_records mr
                   JOIN service_types st ON st.id=mr.service_type_id
                   WHERE mr.vehicle_id=?""", (vrow["id"],)).fetchall()

        if not recs:
            return CostAnalysis(vrow["id"], vrow["name"], 0, 0.0, 0.0, 0.0, "-", "-", {})

        total = sum(r["cost"] for r in recs)
        by_type: Dict[str, float] = {}
        by_month: Dict[str, float] = {}
        for r in recs:
            by_type[r["svc_name"]] = by_type.get(r["svc_name"], 0) + r["cost"]
            month = r["service_date"][:7]
            by_month[month] = by_month.get(month, 0) + r["cost"]

        total_km = vrow["odometer_km"] or 1
        most_exp = max(by_type, key=by_type.get) if by_type else "-"
        costliest = max(by_month, key=by_month.get) if by_month else "-"
        return CostAnalysis(
            vehicle_id=vrow["id"], vehicle_name=vrow["name"],
            total_services=len(recs), total_cost=round(total,2),
            avg_cost_per_service=round(total/len(recs),2) if recs else 0,
            cost_per_km=round(total/total_km,4),
            most_expensive_service=most_exp, costliest_month=costliest,
            breakdown=by_type)

    def service_history(self, vehicle_name: str, limit: int = 20) -> List[Dict]:
        with get_conn(self.db_path) as c:
            vrow = c.execute("SELECT id FROM vehicles WHERE name=?", (vehicle_name,)).fetchone()
            if not vrow: return []
            rows = c.execute(
                """SELECT mr.id, st.name as service, mr.odometer_km, mr.cost,
                          mr.technician, mr.service_date, mr.notes, mr.parts_replaced
                   FROM maintenance_records mr
                   JOIN service_types st ON st.id=mr.service_type_id
                   WHERE mr.vehicle_id=?
                   ORDER BY mr.service_date DESC LIMIT ?""",
                (vrow["id"], limit)).fetchall()
        return [dict(r) for r in rows]

    def list_vehicles(self) -> List[Dict]:
        with get_conn(self.db_path) as c:
            return [dict(r) for r in c.execute(
                "SELECT id,name,make,model,year,odometer_km,status,fuel_type FROM vehicles ORDER BY name")]

    def schedule_forecast(self, vehicle_name: str, horizon_km: float = 20000) -> List[Dict]:
        """Predict upcoming services within a km horizon."""
        alerts = self.get_alerts(vehicle_name)
        forecasts = []
        for a in alerts:
            km_until = a.interval_km - (a.current_km - a.last_service_km)
            if km_until <= horizon_km:
                forecasts.append({
                    "service": a.service_type,
                    "km_until": round(km_until,0),
                    "severity": a.severity,
                    "criticality": a.criticality
                })
        forecasts.sort(key=lambda x: x["km_until"])
        return forecasts


# ── Rich output ────────────────────────────────────────────────────────────────

def sev_color(sev):
    return {
        "CRITICAL": RED+BOLD, "OVERDUE": RED, "DUE_SOON": YELLOW, "OK": GREEN
    }.get(sev, NC)


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
    ap = argparse.ArgumentParser(prog="vehicle_maintenance",
        description=f"{BOLD}BlackRoad Vehicle Maintenance{NC}")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("add-vehicle", help="Register a new vehicle")
    p.add_argument("name"); p.add_argument("make"); p.add_argument("model")
    p.add_argument("year", type=int); p.add_argument("vin")
    p.add_argument("--odometer", type=float, default=0.0)
    p.add_argument("--fuel", default="petrol")

    p = sub.add_parser("record-service", help="Log a completed service")
    p.add_argument("vehicle"); p.add_argument("service")
    p.add_argument("odometer", type=float); p.add_argument("cost", type=float)
    p.add_argument("--tech", default=""); p.add_argument("--notes", default="")
    p.add_argument("--parts", default="")

    p = sub.add_parser("update-odometer", help="Update vehicle odometer")
    p.add_argument("vehicle"); p.add_argument("km", type=float)

    p = sub.add_parser("due-now", help="Show overdue / due-soon alerts")
    p.add_argument("--vehicle", default=None)

    p = sub.add_parser("cost-report", help="Cost analysis for a vehicle")
    p.add_argument("vehicle")

    p = sub.add_parser("history", help="Show service history")
    p.add_argument("vehicle"); p.add_argument("--limit", type=int, default=20)

    p = sub.add_parser("schedule", help="Forecast upcoming services")
    p.add_argument("vehicle"); p.add_argument("--horizon", type=float, default=20000)

    sub.add_parser("list-vehicles", help="List all vehicles")

    args = ap.parse_args()
    mgr = MaintenanceManager()

    if args.cmd == "add-vehicle":
        v = mgr.add_vehicle(args.name, args.make, args.model, args.year,
                             args.vin, args.odometer, args.fuel)
        ok(f"Vehicle {BOLD}{v.name}{NC} ({v.year} {v.make} {v.model}) registered")

    elif args.cmd == "record-service":
        r = mgr.record_service(args.vehicle, args.service, args.odometer,
                               args.cost, args.tech, args.notes, args.parts)
        ok(f"Service recorded: {BOLD}{args.service}{NC} on {args.vehicle} @ {args.odometer}km – ${args.cost}")

    elif args.cmd == "update-odometer":
        mgr.update_odometer(args.vehicle, args.km)
        ok(f"Odometer for {BOLD}{args.vehicle}{NC} updated to {args.km} km")

    elif args.cmd == "due-now":
        alerts = mgr.get_alerts(args.vehicle)
        relevant = [a for a in alerts if a.severity in ("CRITICAL","OVERDUE","DUE_SOON")]
        if not relevant: ok("All vehicles up to date!"); return
        rows = [[sev_color(a.severity)+a.severity+NC, a.vehicle_name,
                 a.service_type, a.criticality,
                 f"+{round(a.km_overdue)}km" if a.km_overdue>0 else f"{round(-a.km_overdue)}km left",
                 f"+{a.days_overdue}d" if a.days_overdue>0 else f"{abs(a.days_overdue)}d left"]
                for a in relevant]
        table(["Severity","Vehicle","Service","Level","KM Status","Day Status"], rows)

    elif args.cmd == "cost-report":
        ca = mgr.cost_analysis(args.vehicle)
        if not ca: err(f"Vehicle '{args.vehicle}' not found")
        print(f"\n{BOLD}Cost Report: {ca.vehicle_name}{NC}")
        print(f"  Total services      : {ca.total_services}")
        print(f"  Total cost          : {GREEN}${ca.total_cost}{NC}")
        print(f"  Avg per service     : ${ca.avg_cost_per_service}")
        print(f"  Cost per km         : ${ca.cost_per_km}")
        print(f"  Most expensive svc  : {YELLOW}{ca.most_expensive_service}{NC}")
        print(f"  Costliest month     : {ca.costliest_month}")
        if ca.breakdown:
            print(f"\n{BOLD}  By Service Type:{NC}")
            for svc, cost in sorted(ca.breakdown.items(), key=lambda x: -x[1]):
                bar = "█" * int(cost / max(ca.breakdown.values()) * 20)
                print(f"  {svc:<30} ${cost:>8.2f}  {CYAN}{bar}{NC}")

    elif args.cmd == "history":
        hist = mgr.service_history(args.vehicle, args.limit)
        if not hist: info("No service records."); return
        table(["Date","Service","Odometer","Cost","Technician","Parts"],
              [[h["service_date"][:10],h["service"],f"{h['odometer_km']}km",
                f"${h['cost']}",h["technician"][:15],h["parts_replaced"][:20]] for h in hist])

    elif args.cmd == "schedule":
        forecasts = mgr.schedule_forecast(args.vehicle, args.horizon)
        if not forecasts: ok(f"No services due within {args.horizon}km"); return
        print(f"\n{BOLD}Upcoming Services for {args.vehicle} (next {args.horizon}km):{NC}")
        table(["Service","KM Until","Severity","Criticality"],
              [[f["service"],f["km_until"],sev_color(f["severity"])+f["severity"]+NC,
                f["criticality"]] for f in forecasts])

    elif args.cmd == "list-vehicles":
        vehicles = mgr.list_vehicles()
        if not vehicles: info("No vehicles registered."); return
        table(["Name","Make","Model","Year","Odometer","Status","Fuel"],
              [[v["name"],v["make"],v["model"],v["year"],
                f"{v['odometer_km']}km",v["status"],v["fuel_type"]] for v in vehicles])


if __name__ == "__main__":
    main()
