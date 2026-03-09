#!/usr/bin/env python3
"""
blackroad-zone-manager: DNS Zone Manager
Manages DNS zones and records with SQLite persistence.
"""

import argparse
import hashlib
import json
import re
import sqlite3
import sys
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional

DB_PATH = Path.home() / ".blackroad" / "zone-manager.db"


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class DnsRecord:
    record_type: str   # A, AAAA, CNAME, MX, TXT, NS, SOA, SRV, PTR
    name: str          # relative label, "@" for apex
    value: str
    ttl: int = 300
    priority: Optional[int] = None  # MX / SRV
    record_id: Optional[int] = None


@dataclass
class Zone:
    name: str          # e.g. "example.com"
    ttl: int = 3600    # default TTL
    serial: int = field(default_factory=lambda: int(datetime.utcnow().strftime("%Y%m%d01")))
    nameservers: list = field(default_factory=lambda: ["ns1.blackroad.io.", "ns2.blackroad.io."])
    records: list = field(default_factory=list)
    zone_id: Optional[int] = None


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def get_db(db_path: Path = DB_PATH) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    _init_schema(conn)
    return conn


def _init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS zones (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL UNIQUE,
            ttl         INTEGER NOT NULL DEFAULT 3600,
            serial      INTEGER NOT NULL,
            nameservers TEXT    NOT NULL DEFAULT '[]',
            created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
            updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS records (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id     INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
            record_type TEXT    NOT NULL,
            name        TEXT    NOT NULL,
            value       TEXT    NOT NULL,
            ttl         INTEGER NOT NULL DEFAULT 300,
            priority    INTEGER,
            created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
        );

        CREATE INDEX IF NOT EXISTS idx_records_zone ON records(zone_id);
        CREATE INDEX IF NOT EXISTS idx_records_type ON records(record_type);
    """)
    conn.commit()


# ---------------------------------------------------------------------------
# Zone CRUD
# ---------------------------------------------------------------------------

def save_zone(zone: Zone, conn: sqlite3.Connection) -> Zone:
    """Persist a zone; returns zone with zone_id populated."""
    ns_json = json.dumps(zone.nameservers)
    if zone.zone_id is None:
        cur = conn.execute(
            "INSERT INTO zones(name, ttl, serial, nameservers) VALUES(?,?,?,?)",
            (zone.name, zone.ttl, zone.serial, ns_json),
        )
        zone.zone_id = cur.lastrowid
    else:
        zone.serial = int(datetime.utcnow().strftime("%Y%m%d")) * 100 + 1
        conn.execute(
            "UPDATE zones SET ttl=?, serial=?, nameservers=?, updated_at=datetime('now') WHERE id=?",
            (zone.ttl, zone.serial, ns_json, zone.zone_id),
        )
    conn.commit()
    return zone


def load_zone(name: str, conn: sqlite3.Connection) -> Optional[Zone]:
    """Load zone with all records from DB."""
    row = conn.execute("SELECT * FROM zones WHERE name=?", (name,)).fetchone()
    if not row:
        return None
    zone = Zone(
        name=row["name"],
        ttl=row["ttl"],
        serial=row["serial"],
        nameservers=json.loads(row["nameservers"]),
        zone_id=row["id"],
    )
    recs = conn.execute("SELECT * FROM records WHERE zone_id=?", (zone.zone_id,)).fetchall()
    zone.records = [
        DnsRecord(
            record_type=r["record_type"],
            name=r["name"],
            value=r["value"],
            ttl=r["ttl"],
            priority=r["priority"],
            record_id=r["id"],
        )
        for r in recs
    ]
    return zone


def list_zones(conn: sqlite3.Connection) -> list:
    rows = conn.execute("SELECT name, ttl, serial, created_at FROM zones ORDER BY name").fetchall()
    return [dict(r) for r in rows]


def delete_zone(name: str, conn: sqlite3.Connection) -> bool:
    cur = conn.execute("DELETE FROM zones WHERE name=?", (name,))
    conn.commit()
    return cur.rowcount > 0


# ---------------------------------------------------------------------------
# Record management
# ---------------------------------------------------------------------------

VALID_TYPES = {"A", "AAAA", "CNAME", "MX", "TXT", "NS", "SOA", "SRV", "PTR", "CAA"}

_VALIDATORS = {
    "A": re.compile(
        r"^(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)\."
        r"(25[0-5]|2[0-4]\d|[01]?\d\d?)\.(25[0-5]|2[0-4]\d|[01]?\d\d?)$"
    ),
    "AAAA": re.compile(r"^[0-9a-fA-F:]{2,39}$"),
    "CNAME": re.compile(r"^[a-zA-Z0-9._-]+\.?$"),
    "MX": re.compile(r"^[a-zA-Z0-9._-]+\.?$"),
    "NS": re.compile(r"^[a-zA-Z0-9._-]+\.?$"),
    "PTR": re.compile(r"^[a-zA-Z0-9._-]+\.?$"),
}


def validate_record(record: DnsRecord) -> list:
    """Return list of validation error strings (empty = valid)."""
    errors = []
    if record.record_type not in VALID_TYPES:
        errors.append(f"Unknown record type: {record.record_type}")
    if not record.name:
        errors.append("Record name cannot be empty")
    if not record.value:
        errors.append("Record value cannot be empty")
    if record.ttl < 0:
        errors.append(f"TTL must be non-negative, got {record.ttl}")
    validator = _VALIDATORS.get(record.record_type)
    if validator and not validator.match(record.value):
        errors.append(f"Value '{record.value}' invalid for type {record.record_type}")
    if record.record_type in ("MX", "SRV") and record.priority is None:
        errors.append(f"{record.record_type} record requires a priority")
    return errors


def add_record(zone: Zone, record_type: str, name: str, value: str,
               ttl: int = 300, priority: Optional[int] = None,
               conn: Optional[sqlite3.Connection] = None) -> DnsRecord:
    """Add a DNS record to a zone (and persist if conn provided)."""
    rec = DnsRecord(record_type=record_type.upper(), name=name, value=value,
                    ttl=ttl, priority=priority)
    errs = validate_record(rec)
    if errs:
        raise ValueError(f"Invalid record: {'; '.join(errs)}")
    zone.records.append(rec)
    if conn and zone.zone_id:
        cur = conn.execute(
            "INSERT INTO records(zone_id, record_type, name, value, ttl, priority) VALUES(?,?,?,?,?,?)",
            (zone.zone_id, rec.record_type, rec.name, rec.value, rec.ttl, rec.priority),
        )
        rec.record_id = cur.lastrowid
        conn.commit()
    return rec


def remove_record(zone: Zone, record_id: int, conn: Optional[sqlite3.Connection] = None) -> bool:
    """Remove record by id from zone object and optionally DB."""
    before = len(zone.records)
    zone.records = [r for r in zone.records if r.record_id != record_id]
    removed = len(zone.records) < before
    if removed and conn:
        conn.execute("DELETE FROM records WHERE id=?", (record_id,))
        conn.commit()
    return removed


# ---------------------------------------------------------------------------
# Zone validation
# ---------------------------------------------------------------------------

def validate_zone(zone: Zone) -> list:
    """Return list of validation errors for the entire zone."""
    errors = []
    if not zone.name:
        errors.append("Zone name is required")
    if not re.match(r"^[a-zA-Z0-9._-]+$", zone.name or ""):
        errors.append(f"Invalid zone name: {zone.name}")
    if zone.ttl < 0:
        errors.append(f"Default TTL must be non-negative, got {zone.ttl}")

    has_soa = any(r.record_type == "SOA" for r in zone.records)
    has_ns = any(r.record_type == "NS" for r in zone.records)
    if not has_soa:
        errors.append("Zone is missing SOA record")
    if not has_ns:
        errors.append("Zone is missing NS record(s)")

    for rec in zone.records:
        rec_errors = validate_record(rec)
        for e in rec_errors:
            errors.append(f"Record ({rec.record_type} {rec.name}): {e}")

    names = [r.name for r in zone.records if r.record_type == "CNAME"]
    duplicates = [n for n in names if names.count(n) > 1]
    for dup in set(duplicates):
        errors.append(f"Duplicate CNAME for name: {dup}")

    return errors


# ---------------------------------------------------------------------------
# BIND zone file export / import
# ---------------------------------------------------------------------------

def export_bind_format(zone: Zone) -> str:
    """Export zone in BIND/RFC 1035 zone file format."""
    lines = [
        f"; Zone file for {zone.name}",
        f"; Generated by blackroad-zone-manager on {datetime.utcnow().isoformat()}Z",
        f"$ORIGIN {zone.name}.",
        f"$TTL {zone.ttl}",
        "",
    ]

    # SOA record first
    soa_records = [r for r in zone.records if r.record_type == "SOA"]
    if not soa_records:
        lines.append(
            f"@ {zone.ttl} IN SOA ns1.{zone.name}. hostmaster.{zone.name}. "
            f"( {zone.serial} 3600 900 604800 300 )"
        )
    else:
        for r in soa_records:
            lines.append(f"{r.name} {r.ttl} IN SOA {r.value}")

    lines.append("")

    # NS records
    for ns in zone.nameservers:
        lines.append(f"@ {zone.ttl} IN NS {ns}")
    lines.append("")

    # All other records sorted by type then name
    other = [r for r in zone.records if r.record_type not in ("SOA", "NS")]
    other.sort(key=lambda r: (r.record_type, r.name))

    for r in other:
        if r.priority is not None:
            lines.append(f"{r.name} {r.ttl} IN {r.record_type} {r.priority} {r.value}")
        else:
            lines.append(f"{r.name} {r.ttl} IN {r.record_type} {r.value}")

    return "\n".join(lines) + "\n"


def import_zone_file(path: str, conn: Optional[sqlite3.Connection] = None) -> Zone:
    """Parse a BIND zone file and return a Zone object."""
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"Zone file not found: {path}")

    zone_name = None
    default_ttl = 3600
    records = []
    origin = None

    with open(p) as fh:
        for raw_line in fh:
            line = raw_line.strip()
            if not line or line.startswith(";"):
                continue
            if line.startswith("$ORIGIN"):
                origin = line.split()[1].rstrip(".")
                zone_name = zone_name or origin
                continue
            if line.startswith("$TTL"):
                default_ttl = int(line.split()[1])
                continue
            parts = line.split()
            if len(parts) < 4:
                continue
            # name ttl IN type value  OR  name IN type value
            idx = 0
            name = parts[idx]; idx += 1
            ttl = default_ttl
            if parts[idx].isdigit():
                ttl = int(parts[idx]); idx += 1
            if parts[idx].upper() == "IN":
                idx += 1
            rtype = parts[idx].upper(); idx += 1
            value = " ".join(parts[idx:])
            priority = None
            if rtype in ("MX", "SRV") and value.split()[0].isdigit():
                priority = int(value.split()[0])
                value = " ".join(value.split()[1:])
            if rtype not in ("SOA",):
                records.append(DnsRecord(record_type=rtype, name=name,
                                         value=value, ttl=ttl, priority=priority))

    if zone_name is None:
        zone_name = p.stem
    zone = Zone(name=zone_name, ttl=default_ttl, records=records)
    if conn:
        save_zone(zone, conn)
        for rec in zone.records:
            if zone.zone_id:
                cur = conn.execute(
                    "INSERT INTO records(zone_id, record_type, name, value, ttl, priority) VALUES(?,?,?,?,?,?)",
                    (zone.zone_id, rec.record_type, rec.name, rec.value, rec.ttl, rec.priority),
                )
                rec.record_id = cur.lastrowid
        conn.commit()
    return zone


# ---------------------------------------------------------------------------
# Provider sync (Cloudflare stub)
# ---------------------------------------------------------------------------

def sync_with_provider(zone: Zone, provider: str = "cloudflare",
                       dry_run: bool = True) -> dict:
    """
    Sync zone with DNS provider.
    Returns a summary dict with planned/applied changes.
    Real implementation would call provider REST APIs.
    """
    summary = {
        "provider": provider,
        "zone": zone.name,
        "dry_run": dry_run,
        "records_to_create": [],
        "records_to_update": [],
        "records_to_delete": [],
        "errors": [],
    }

    if provider not in ("cloudflare", "route53", "digitalocean"):
        summary["errors"].append(f"Unsupported provider: {provider}")
        return summary

    # Simulate diffing against "existing" provider records
    existing_stub = {
        f"{r.record_type}:{r.name}": r for r in zone.records
        if r.record_type in ("A", "AAAA", "CNAME")
    }
    for key, rec in existing_stub.items():
        # In real implementation compare with provider state
        summary["records_to_create"].append({
            "type": rec.record_type,
            "name": rec.name,
            "value": rec.value,
            "ttl": rec.ttl,
        })

    if not dry_run:
        # Real implementation would POST/PUT/DELETE via provider API
        pass

    summary["total_changes"] = (
        len(summary["records_to_create"])
        + len(summary["records_to_update"])
        + len(summary["records_to_delete"])
    )
    return summary


# ---------------------------------------------------------------------------
# Checksum / fingerprint
# ---------------------------------------------------------------------------

def zone_checksum(zone: Zone) -> str:
    """SHA-256 fingerprint of zone content (deterministic)."""
    data = export_bind_format(zone).encode()
    return hashlib.sha256(data).hexdigest()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="zone-manager",
        description="DNS Zone Manager — blackroad-zone-manager",
    )
    p.add_argument("--db", default=str(DB_PATH), help="SQLite database path")
    sub = p.add_subparsers(dest="command", required=True)

    # create
    c = sub.add_parser("create", help="Create a new zone")
    c.add_argument("name", help="Zone name, e.g. example.com")
    c.add_argument("--ttl", type=int, default=3600)

    # add-record
    ar = sub.add_parser("add-record", help="Add a DNS record to a zone")
    ar.add_argument("zone", help="Zone name")
    ar.add_argument("type", help="Record type (A, AAAA, CNAME, MX, TXT, NS…)")
    ar.add_argument("name", help="Record name (@, www, mail, …)")
    ar.add_argument("value", help="Record value")
    ar.add_argument("--ttl", type=int, default=300)
    ar.add_argument("--priority", type=int)

    # validate
    v = sub.add_parser("validate", help="Validate a zone")
    v.add_argument("name", help="Zone name")

    # export
    ex = sub.add_parser("export", help="Export zone as BIND file")
    ex.add_argument("name", help="Zone name")
    ex.add_argument("--output", "-o", help="Output file (stdout if omitted)")

    # import
    im = sub.add_parser("import", help="Import BIND zone file")
    im.add_argument("path", help="Path to zone file")

    # sync
    sy = sub.add_parser("sync", help="Sync zone with provider")
    sy.add_argument("name", help="Zone name")
    sy.add_argument("--provider", default="cloudflare")
    sy.add_argument("--apply", action="store_true", help="Apply changes (default: dry-run)")

    # list
    sub.add_parser("list", help="List all zones")

    # delete
    d = sub.add_parser("delete", help="Delete a zone")
    d.add_argument("name", help="Zone name")

    # checksum
    cs = sub.add_parser("checksum", help="Print zone checksum")
    cs.add_argument("name")

    return p


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    conn = get_db(Path(args.db))

    if args.command == "create":
        zone = Zone(name=args.name, ttl=args.ttl)
        save_zone(zone, conn)
        print(f"✓ Zone '{args.name}' created (id={zone.zone_id})")

    elif args.command == "add-record":
        zone = load_zone(args.zone, conn)
        if not zone:
            print(f"Error: zone '{args.zone}' not found", file=sys.stderr)
            sys.exit(1)
        rec = add_record(zone, args.type, args.name, args.value,
                         ttl=args.ttl, priority=args.priority, conn=conn)
        print(f"✓ Added {rec.record_type} record '{rec.name}' → {rec.value}")

    elif args.command == "validate":
        zone = load_zone(args.name, conn)
        if not zone:
            print(f"Error: zone '{args.name}' not found", file=sys.stderr)
            sys.exit(1)
        errors = validate_zone(zone)
        if errors:
            print(f"✗ Zone '{args.name}' has {len(errors)} issue(s):")
            for e in errors:
                print(f"  - {e}")
            sys.exit(1)
        else:
            print(f"✓ Zone '{args.name}' is valid")

    elif args.command == "export":
        zone = load_zone(args.name, conn)
        if not zone:
            print(f"Error: zone '{args.name}' not found", file=sys.stderr)
            sys.exit(1)
        content = export_bind_format(zone)
        if args.output:
            Path(args.output).write_text(content)
            print(f"✓ Exported to {args.output}")
        else:
            print(content)

    elif args.command == "import":
        zone = import_zone_file(args.path, conn)
        print(f"✓ Imported zone '{zone.name}' with {len(zone.records)} record(s)")

    elif args.command == "sync":
        zone = load_zone(args.name, conn)
        if not zone:
            print(f"Error: zone '{args.name}' not found", file=sys.stderr)
            sys.exit(1)
        result = sync_with_provider(zone, provider=args.provider, dry_run=not args.apply)
        print(json.dumps(result, indent=2))

    elif args.command == "list":
        zones = list_zones(conn)
        if not zones:
            print("No zones found.")
        for z in zones:
            print(f"  {z['name']:40s} TTL={z['ttl']:6d}  serial={z['serial']}")

    elif args.command == "delete":
        if delete_zone(args.name, conn):
            print(f"✓ Zone '{args.name}' deleted")
        else:
            print(f"Zone '{args.name}' not found", file=sys.stderr)
            sys.exit(1)

    elif args.command == "checksum":
        zone = load_zone(args.name, conn)
        if not zone:
            print(f"Error: zone '{args.name}' not found", file=sys.stderr)
            sys.exit(1)
        print(zone_checksum(zone))


if __name__ == "__main__":
    main()
