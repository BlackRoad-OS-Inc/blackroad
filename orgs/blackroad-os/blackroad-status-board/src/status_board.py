#!/usr/bin/env python3
"""
BlackRoad Status Board
Production module for monitoring service health and uptime.
"""

import sqlite3
import json
import sys
import os
import time
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from typing import Optional, List
import urllib.request
import urllib.error

GREEN = '\033[0;32m'
RED = '\033[0;31m'
CYAN = '\033[0;36m'
YELLOW = '\033[1;33m'
NC = '\033[0m'

DB_PATH = os.path.expanduser("~/.blackroad/status_board.db")
TIMEOUT = 10  # seconds


@dataclass
class Service:
    name: str
    url: str
    status: str = "unknown"
    response_time_ms: float = 0.0
    last_checked: Optional[str] = None
    uptime_pct: float = 100.0
    expected_status_code: int = 200
    id: Optional[int] = None
    created_at: Optional[str] = None


@dataclass
class StatusAlert:
    service_name: str
    alert_type: str  # down, degraded, recovered
    message: str
    response_time_ms: float
    status_code: int
    created_at: str


def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            url TEXT NOT NULL,
            status TEXT DEFAULT 'unknown',
            response_time_ms REAL DEFAULT 0,
            last_checked TEXT,
            uptime_pct REAL DEFAULT 100.0,
            expected_status_code INTEGER DEFAULT 200,
            created_at TEXT NOT NULL
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS checks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_name TEXT NOT NULL,
            status TEXT NOT NULL,
            response_time_ms REAL,
            status_code INTEGER,
            error_msg TEXT,
            checked_at TEXT NOT NULL
        )
    """)
    c.execute("""
        CREATE TABLE IF NOT EXISTS alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_name TEXT NOT NULL,
            alert_type TEXT NOT NULL,
            message TEXT,
            response_time_ms REAL,
            status_code INTEGER,
            created_at TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()


class StatusBoardManager:
    def __init__(self):
        init_db()
        self.conn = sqlite3.connect(DB_PATH)
        self.conn.row_factory = sqlite3.Row

    def close(self):
        self.conn.close()

    def add_service(self, service: Service) -> Service:
        service.created_at = datetime.utcnow().isoformat()
        c = self.conn.cursor()
        try:
            c.execute("""
                INSERT INTO services (name, url, status, response_time_ms,
                    uptime_pct, expected_status_code, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (service.name, service.url, service.status,
                  service.response_time_ms, service.uptime_pct,
                  service.expected_status_code, service.created_at))
            self.conn.commit()
            service.id = c.lastrowid
            print(f"{GREEN}✓ Added service: {service.name}{NC}")
        except sqlite3.IntegrityError:
            print(f"{YELLOW}⚠ Service '{service.name}' already exists{NC}")
        return service

    def check_service(self, name: str) -> Optional[Service]:
        c = self.conn.cursor()
        c.execute("SELECT * FROM services WHERE name = ?", (name,))
        row = c.fetchone()
        if not row:
            print(f"{RED}✗ Service not found: {name}{NC}")
            return None

        url = row["url"]
        expected_code = row["expected_status_code"]
        start = time.time()
        status_code = 0
        error_msg = None
        new_status = "down"

        try:
            req = urllib.request.Request(url, headers={"User-Agent": "BlackRoad-StatusBoard/1.0"})
            with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
                status_code = resp.status
                elapsed_ms = (time.time() - start) * 1000
                if status_code == expected_code:
                    new_status = "operational" if elapsed_ms < 2000 else "degraded"
                else:
                    new_status = "degraded"
        except urllib.error.HTTPError as e:
            status_code = e.code
            elapsed_ms = (time.time() - start) * 1000
            new_status = "degraded" if status_code < 500 else "down"
            error_msg = str(e)
        except Exception as e:
            elapsed_ms = (time.time() - start) * 1000
            new_status = "down"
            error_msg = str(e)

        now = datetime.utcnow().isoformat()
        c.execute("""
            INSERT INTO checks (service_name, status, response_time_ms, status_code, error_msg, checked_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (name, new_status, round(elapsed_ms, 2), status_code, error_msg, now))

        # Calculate uptime from last 100 checks
        c.execute("""
            SELECT COUNT(*) as total,
                   SUM(CASE WHEN status = 'operational' THEN 1 ELSE 0 END) as up
            FROM (SELECT status FROM checks WHERE service_name = ? ORDER BY id DESC LIMIT 100)
        """, (name,))
        stats = c.fetchone()
        uptime = (stats["up"] / stats["total"] * 100.0) if stats["total"] > 0 else 100.0

        c.execute("""
            UPDATE services SET status = ?, response_time_ms = ?, last_checked = ?, uptime_pct = ?
            WHERE name = ?
        """, (new_status, round(elapsed_ms, 2), now, round(uptime, 2), name))

        # Alert if status changed
        if row["status"] != new_status and new_status == "down":
            c.execute("""
                INSERT INTO alerts (service_name, alert_type, message, response_time_ms, status_code, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (name, "down", f"Service went down: {error_msg or 'No response'}", elapsed_ms, status_code, now))

        self.conn.commit()

        c.execute("SELECT * FROM services WHERE name = ?", (name,))
        r = c.fetchone()
        return self._row_to_service(r)

    def check_all(self) -> List[Service]:
        c = self.conn.cursor()
        c.execute("SELECT name FROM services")
        names = [r["name"] for r in c.fetchall()]
        results = []
        for name in names:
            svc = self.check_service(name)
            if svc:
                results.append(svc)
        return results

    def get_status(self) -> List[Service]:
        c = self.conn.cursor()
        c.execute("SELECT * FROM services ORDER BY name")
        return [self._row_to_service(r) for r in c.fetchall()]

    def _row_to_service(self, r) -> Service:
        return Service(id=r["id"], name=r["name"], url=r["url"],
                       status=r["status"], response_time_ms=r["response_time_ms"],
                       last_checked=r["last_checked"], uptime_pct=r["uptime_pct"],
                       expected_status_code=r["expected_status_code"],
                       created_at=r["created_at"])

    def export_report(self, output_path: str = "/tmp/status_report.json"):
        services = self.get_status()
        c = self.conn.cursor()
        c.execute("SELECT * FROM alerts ORDER BY created_at DESC LIMIT 50")
        alerts = [dict(r) for r in c.fetchall()]
        data = {"services": [asdict(s) for s in services],
                "recent_alerts": alerts,
                "summary": {
                    "total": len(services),
                    "operational": sum(1 for s in services if s.status == "operational"),
                    "degraded": sum(1 for s in services if s.status == "degraded"),
                    "down": sum(1 for s in services if s.status == "down"),
                },
                "exported_at": datetime.utcnow().isoformat()}
        with open(output_path, "w") as f:
            json.dump(data, f, indent=2)
        print(f"{GREEN}✓ Report exported to {output_path}{NC}")
        return output_path


def status_color(status: str) -> str:
    if status == "operational":
        return GREEN
    if status == "degraded":
        return YELLOW
    return RED


def print_service(s: Service):
    sc = status_color(s.status)
    icon = "✓" if s.status == "operational" else ("⚠" if s.status == "degraded" else "✗")
    print(f"  {sc}{icon} {s.name}{NC} | {s.url[:40]} | "
          f"{sc}{s.status}{NC} | {s.response_time_ms:.0f}ms | "
          f"Uptime: {s.uptime_pct:.1f}%")


def main():
    manager = StatusBoardManager()
    args = sys.argv[1:]
    if not args:
        print(f"{CYAN}BlackRoad Status Board{NC}")
        print("Commands: list, add <name> <url>, check [name], export")
        manager.close()
        return
    cmd = args[0]
    rest = args[1:]
    if cmd == "list":
        services = manager.get_status()
        if not services:
            print(f"{YELLOW}No services configured.{NC}")
        else:
            print(f"\n{CYAN}=== Service Status ({len(services)}) ==={NC}")
            for s in services:
                print_service(s)
    elif cmd == "add":
        if len(rest) < 2:
            print(f"{RED}Usage: add <name> <url> [expected_code]{NC}")
        else:
            code = int(rest[2]) if len(rest) > 2 else 200
            svc = Service(name=rest[0], url=rest[1], expected_status_code=code)
            manager.add_service(svc)
    elif cmd == "check":
        if rest:
            svc = manager.check_service(rest[0])
            if svc:
                print_service(svc)
        else:
            results = manager.check_all()
            print(f"\n{CYAN}=== Check Results ({len(results)}) ==={NC}")
            for s in results:
                print_service(s)
    elif cmd == "export":
        path = rest[0] if rest else "/tmp/status_report.json"
        manager.export_report(path)
    else:
        print(f"{RED}Unknown command: {cmd}{NC}")
    manager.close()


if __name__ == "__main__":
    main()
