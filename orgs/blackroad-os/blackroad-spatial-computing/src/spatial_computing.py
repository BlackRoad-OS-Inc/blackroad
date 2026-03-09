#!/usr/bin/env python3
"""BlackRoad Spatial Computing - 3D coordinates, zones, proximity detection."""

from __future__ import annotations
import argparse
import json
import math
import sqlite3
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path

GREEN = "\033[0;32m"
RED = "\033[0;31m"
CYAN = "\033[0;36m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
BOLD = "\033[1m"
NC = "\033[0m"

DB_PATH = Path.home() / ".blackroad" / "spatial-computing.db"


@dataclass
class Point3D:
    x: float
    y: float
    z: float

    def distance_to(self, other: "Point3D") -> float:
        return math.sqrt((self.x - other.x) ** 2 + (self.y - other.y) ** 2 + (self.z - other.z) ** 2)

    def __str__(self) -> str:
        return f"({self.x:.2f}, {self.y:.2f}, {self.z:.2f})"


@dataclass
class Zone:
    id: int
    name: str
    center_x: float
    center_y: float
    center_z: float
    radius: float
    zone_type: str
    created_at: str
    active: int

    @property
    def center(self) -> Point3D:
        return Point3D(self.center_x, self.center_y, self.center_z)


@dataclass
class SpatialEntity:
    id: int
    name: str
    x: float
    y: float
    z: float
    entity_type: str
    metadata: str
    last_updated: str

    @property
    def position(self) -> Point3D:
        return Point3D(self.x, self.y, self.z)


class SpatialComputing:
    """Core spatial computing engine with SQLite persistence."""

    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self) -> None:
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS zones (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL UNIQUE,
                    center_x REAL NOT NULL,
                    center_y REAL NOT NULL,
                    center_z REAL NOT NULL,
                    radius REAL NOT NULL,
                    zone_type TEXT DEFAULT 'generic',
                    created_at TEXT NOT NULL,
                    active INTEGER DEFAULT 1
                );
                CREATE TABLE IF NOT EXISTS entities (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    x REAL NOT NULL,
                    y REAL NOT NULL,
                    z REAL NOT NULL,
                    entity_type TEXT DEFAULT 'object',
                    metadata TEXT DEFAULT '{}',
                    last_updated TEXT NOT NULL
                );
            """)

    def add_zone(self, name: str, cx: float, cy: float, cz: float,
                 radius: float, zone_type: str = "generic") -> Zone:
        """Create a new 3D spatial zone."""
        with sqlite3.connect(self.db_path) as conn:
            now = datetime.now().isoformat()
            cur = conn.execute(
                "INSERT INTO zones (name,center_x,center_y,center_z,radius,zone_type,created_at)"
                " VALUES (?,?,?,?,?,?,?)",
                (name, cx, cy, cz, radius, zone_type, now),
            )
            return Zone(cur.lastrowid, name, cx, cy, cz, radius, zone_type, now, 1)

    def add_entity(self, name: str, x: float, y: float, z: float,
                   entity_type: str = "object", metadata: dict = None) -> SpatialEntity:
        """Register a spatial entity at given coordinates."""
        meta = json.dumps(metadata or {})
        with sqlite3.connect(self.db_path) as conn:
            now = datetime.now().isoformat()
            cur = conn.execute(
                "INSERT INTO entities (name,x,y,z,entity_type,metadata,last_updated)"
                " VALUES (?,?,?,?,?,?,?)",
                (name, x, y, z, entity_type, meta, now),
            )
            return SpatialEntity(cur.lastrowid, name, x, y, z, entity_type, meta, now)

    def list_zones(self, active_only: bool = True) -> list:
        """Return all (active) zones."""
        with sqlite3.connect(self.db_path) as conn:
            q = "SELECT * FROM zones" + (" WHERE active=1" if active_only else "")
            return [Zone(*r) for r in conn.execute(q).fetchall()]

    def list_entities(self) -> list:
        """Return all registered entities."""
        with sqlite3.connect(self.db_path) as conn:
            return [SpatialEntity(*r) for r in conn.execute("SELECT * FROM entities").fetchall()]

    def find_entities_in_zone(self, zone_name: str) -> list:
        """Return entities located inside the named zone, sorted by distance."""
        with sqlite3.connect(self.db_path) as conn:
            row = conn.execute("SELECT * FROM zones WHERE name=?", (zone_name,)).fetchone()
        if not row:
            return []
        zone = Zone(*row)
        results = []
        for entity in self.list_entities():
            dist = entity.position.distance_to(zone.center)
            if dist <= zone.radius:
                results.append((entity, dist))
        return sorted(results, key=lambda t: t[1])

    def proximity_check(self, entity_name: str, threshold: float) -> list:
        """Find all entities within threshold distance of the named entity."""
        with sqlite3.connect(self.db_path) as conn:
            row = conn.execute("SELECT * FROM entities WHERE name=?", (entity_name,)).fetchone()
        if not row:
            return []
        target = SpatialEntity(*row)
        results = []
        for entity in self.list_entities():
            if entity.id == target.id:
                continue
            dist = entity.position.distance_to(target.position)
            if dist <= threshold:
                results.append((entity, dist))
        return sorted(results, key=lambda t: t[1])

    def status(self) -> dict:
        """Return summary statistics."""
        return {
            "active_zones": len(self.list_zones()),
            "total_entities": len(self.list_entities()),
            "db_path": str(self.db_path),
        }

    def export_data(self) -> dict:
        """Export all spatial data as a JSON-serialisable dict."""
        return {
            "zones": [asdict(z) for z in self.list_zones(active_only=False)],
            "entities": [asdict(e) for e in self.list_entities()],
            "exported_at": datetime.now().isoformat(),
        }


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _fmt_zone(zone: Zone) -> None:
    st = f"{GREEN}active{NC}" if zone.active else f"{RED}inactive{NC}"
    print(f"  {CYAN}[{zone.id}]{NC} {BOLD}{zone.name}{NC}  center={zone.center}"
          f"  r={zone.radius:.1f}  type={YELLOW}{zone.zone_type}{NC}  {st}")


def _fmt_entity(entity: SpatialEntity, dist: float = None) -> None:
    d = f"  dist={CYAN}{dist:.2f}{NC}" if dist is not None else ""
    print(f"  {CYAN}[{entity.id}]{NC} {BOLD}{entity.name}{NC}  pos={entity.position}"
          f"  type={YELLOW}{entity.entity_type}{NC}{d}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        prog="spatial_computing",
        description=f"{BOLD}BlackRoad Spatial Computing{NC} — 3D zones & proximity",
    )
    sub = parser.add_subparsers(dest="cmd")

    sub.add_parser("status", help="Show system status")
    sub.add_parser("export", help="Export all data as JSON")

    ls = sub.add_parser("list", help="List zones or entities")
    ls.add_argument("target", choices=["zones", "entities"], nargs="?", default="zones")

    az = sub.add_parser("add-zone", help="Add a 3D zone")
    az.add_argument("name")
    az.add_argument("--cx", type=float, default=0.0)
    az.add_argument("--cy", type=float, default=0.0)
    az.add_argument("--cz", type=float, default=0.0)
    az.add_argument("--radius", type=float, default=10.0)
    az.add_argument("--type", dest="zone_type", default="generic")

    ae = sub.add_parser("add-entity", help="Add a spatial entity")
    ae.add_argument("name")
    ae.add_argument("--x", type=float, default=0.0)
    ae.add_argument("--y", type=float, default=0.0)
    ae.add_argument("--z", type=float, default=0.0)
    ae.add_argument("--type", dest="entity_type", default="object")

    prox = sub.add_parser("proximity", help="Find entities near a named entity")
    prox.add_argument("entity_name")
    prox.add_argument("--threshold", type=float, default=50.0)

    iz = sub.add_parser("in-zone", help="Find entities inside a zone")
    iz.add_argument("zone_name")

    args = parser.parse_args()
    sc = SpatialComputing()

    if args.cmd == "list":
        target = getattr(args, "target", "zones")
        if target == "zones":
            zones = sc.list_zones()
            print(f"\n{BOLD}{BLUE}Zones ({len(zones)}){NC}")
            [_fmt_zone(z) for z in zones] or print(f"  {YELLOW}none{NC}")
        else:
            entities = sc.list_entities()
            print(f"\n{BOLD}{BLUE}Entities ({len(entities)}){NC}")
            [_fmt_entity(e) for e in entities] or print(f"  {YELLOW}none{NC}")

    elif args.cmd == "add-zone":
        z = sc.add_zone(args.name, args.cx, args.cy, args.cz, args.radius, args.zone_type)
        print(f"{GREEN}✓{NC} Zone {BOLD}{z.name}{NC} created (id={z.id})")

    elif args.cmd == "add-entity":
        e = sc.add_entity(args.name, args.x, args.y, args.z, args.entity_type)
        print(f"{GREEN}✓{NC} Entity {BOLD}{e.name}{NC} registered (id={e.id})")

    elif args.cmd == "proximity":
        results = sc.proximity_check(args.entity_name, args.threshold)
        print(f"\n{BOLD}{BLUE}Entities within {args.threshold} of '{args.entity_name}'{NC}")
        [_fmt_entity(e, d) for e, d in results] or print(f"  {YELLOW}none found{NC}")

    elif args.cmd == "in-zone":
        results = sc.find_entities_in_zone(args.zone_name)
        print(f"\n{BOLD}{BLUE}Entities in zone '{args.zone_name}'{NC}")
        [_fmt_entity(e, d) for e, d in results] or print(f"  {YELLOW}none found{NC}")

    elif args.cmd == "status":
        st = sc.status()
        print(f"\n{BOLD}{BLUE}Spatial Computing Status{NC}")
        print(f"  Active zones:    {GREEN}{st['active_zones']}{NC}")
        print(f"  Total entities:  {GREEN}{st['total_entities']}{NC}")
        print(f"  Database:        {CYAN}{st['db_path']}{NC}")

    elif args.cmd == "export":
        print(json.dumps(sc.export_data(), indent=2))

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
