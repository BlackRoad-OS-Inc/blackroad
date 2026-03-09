"""
BR SSL Automator - SSL certificate automation and renewal manager.
SQLite persistence at ~/.blackroad/ssl_automator.db
"""
import argparse
import csv
import json
import sqlite3
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Optional

GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BLUE = "\033[0;34m"
BOLD = "\033[1m"
RESET = "\033[0m"

DB_PATH = Path.home() / ".blackroad" / "ssl_automator.db"
CERT_STATUSES = ["active", "expired", "pending", "revoked"]
RENEWAL_THRESHOLD_DAYS = 30

STATUS_COLOR = {
    "active": GREEN, "expired": RED, "pending": YELLOW, "revoked": RED,
}


@dataclass
class Domain:
    id: Optional[int]
    name: str
    provider: str
    contact_email: str
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class Certificate:
    id: Optional[int]
    domain_id: int
    domain_name: str
    status: str
    issued_at: str
    expiry_date: str
    provider: str
    days_until_expiry: int = 0

    def __post_init__(self):
        try:
            exp = datetime.fromisoformat(self.expiry_date)
            self.days_until_expiry = (exp - datetime.now()).days
        except (ValueError, TypeError):
            self.days_until_expiry = -1


class SSLAutomator:
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        return conn

    def _init_db(self) -> None:
        with self._conn() as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS domains (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT UNIQUE NOT NULL,
                    provider TEXT DEFAULT 'letsencrypt',
                    contact_email TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
                CREATE TABLE IF NOT EXISTS certificates (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    domain_id INTEGER REFERENCES domains(id) ON DELETE CASCADE,
                    status TEXT DEFAULT 'pending',
                    issued_at TEXT,
                    expiry_date TEXT,
                    provider TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
            """)

    def add_domain(self, name: str, provider: str = "letsencrypt", email: str = "") -> Domain:
        now = datetime.now().isoformat()
        issued = now
        expiry = (datetime.now() + timedelta(days=90)).isoformat()
        with self._conn() as conn:
            try:
                cur = conn.execute(
                    "INSERT INTO domains (name, provider, contact_email, created_at) VALUES (?,?,?,?)",
                    (name, provider, email, now),
                )
                domain_id = cur.lastrowid
                conn.execute(
                    "INSERT INTO certificates (domain_id, status, issued_at, expiry_date, provider) "
                    "VALUES (?,?,?,?,?)",
                    (domain_id, "active", issued, expiry, provider),
                )
            except sqlite3.IntegrityError:
                raise ValueError(f"Domain '{name}' already exists.")
        return Domain(id=domain_id, name=name, provider=provider, contact_email=email, created_at=now)

    def check_expiry(self, domain_name: str) -> Optional[Certificate]:
        with self._conn() as conn:
            row = conn.execute(
                "SELECT c.*, d.name as domain_name FROM certificates c "
                "JOIN domains d ON c.domain_id=d.id WHERE d.name=? ORDER BY c.id DESC LIMIT 1",
                (domain_name,),
            ).fetchone()
            if not row:
                return None
            cert = Certificate(
                id=row["id"], domain_id=row["domain_id"], domain_name=row["domain_name"],
                status=row["status"], issued_at=row["issued_at"] or "",
                expiry_date=row["expiry_date"] or "", provider=row["provider"] or "",
            )
            if cert.days_until_expiry < 0:
                conn.execute("UPDATE certificates SET status='expired' WHERE id=?", (cert.id,))
                cert.status = "expired"
        return cert

    def renew_certificate(self, domain_name: str) -> Optional[Certificate]:
        now = datetime.now().isoformat()
        expiry = (datetime.now() + timedelta(days=90)).isoformat()
        with self._conn() as conn:
            dom = conn.execute("SELECT id, provider FROM domains WHERE name=?", (domain_name,)).fetchone()
            if not dom:
                return None
            conn.execute("UPDATE certificates SET status='revoked' WHERE domain_id=?", (dom["id"],))
            cur = conn.execute(
                "INSERT INTO certificates (domain_id, status, issued_at, expiry_date, provider) "
                "VALUES (?,?,?,?,?)",
                (dom["id"], "active", now, expiry, dom["provider"]),
            )
        return Certificate(id=cur.lastrowid, domain_id=dom["id"], domain_name=domain_name,
                           status="active", issued_at=now, expiry_date=expiry, provider=dom["provider"])

    def list_certificates(self, expiring_soon: bool = False) -> List[dict]:
        with self._conn() as conn:
            rows = conn.execute(
                "SELECT c.*, d.name as domain_name, d.provider as domain_provider "
                "FROM certificates c JOIN domains d ON c.domain_id=d.id ORDER BY c.expiry_date"
            ).fetchall()
            result = []
            for row in rows:
                d = dict(row)
                try:
                    exp = datetime.fromisoformat(d["expiry_date"])
                    d["days_until_expiry"] = (exp - datetime.now()).days
                except (ValueError, TypeError):
                    d["days_until_expiry"] = -1
                if expiring_soon and d["days_until_expiry"] > RENEWAL_THRESHOLD_DAYS:
                    continue
                result.append(d)
            return result

    def get_status(self) -> dict:
        with self._conn() as conn:
            total_domains = conn.execute("SELECT COUNT(*) as c FROM domains").fetchone()["c"]
            total_certs = conn.execute("SELECT COUNT(*) as c FROM certificates").fetchone()["c"]
            by_status = conn.execute(
                "SELECT status, COUNT(*) as c FROM certificates GROUP BY status"
            ).fetchall()
            expiring = conn.execute(
                "SELECT COUNT(*) as c FROM certificates WHERE status='active' AND "
                "julianday(expiry_date) - julianday('now') < ?",
                (RENEWAL_THRESHOLD_DAYS,),
            ).fetchone()["c"]
        return {"total_domains": total_domains, "total_certificates": total_certs,
                "expiring_soon": expiring, "by_status": {r["status"]: r["c"] for r in by_status}}

    def export(self, output_path: str, fmt: str = "json") -> None:
        certs = self.list_certificates()
        if fmt == "json":
            with open(output_path, "w") as f:
                json.dump(certs, f, indent=2, default=str)
        else:
            fields = ["id", "domain_name", "status", "issued_at", "expiry_date", "days_until_expiry", "provider"]
            with open(output_path, "w", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(certs)


def main():
    parser = argparse.ArgumentParser(description="BR SSL Automator")
    sub = parser.add_subparsers(dest="cmd")

    p_list = sub.add_parser("list", help="List certificates")
    p_list.add_argument("--expiring-soon", action="store_true", help=f"Show certs expiring within {RENEWAL_THRESHOLD_DAYS}d")

    p_add = sub.add_parser("add", help="Add domain")
    p_add.add_argument("domain")
    p_add.add_argument("provider", nargs="?", default="letsencrypt")
    p_add.add_argument("--email", default="")

    sub.add_parser("status", help="Show system status")

    p_exp = sub.add_parser("export", help="Export certificates")
    p_exp.add_argument("output")
    p_exp.add_argument("--format", dest="fmt", choices=["json", "csv"], default="json")

    p_check = sub.add_parser("check", help="Check a domain certificate")
    p_check.add_argument("domain")

    args = parser.parse_args()
    mgr = SSLAutomator()

    if args.cmd == "list":
        certs = mgr.list_certificates(expiring_soon=args.expiring_soon)
        if not certs:
            print(f"{YELLOW}No certificates found.{RESET}")
            return
        print(f"{BOLD}{CYAN}{'ID':<5} {'Domain':<35} {'Status':<10} {'Days Left':>10} {'Expiry'}{RESET}")
        print(f"{CYAN}{'-'*80}{RESET}")
        for c in certs:
            sc = STATUS_COLOR.get(c["status"], RESET)
            days = c.get("days_until_expiry", 0)
            day_color = RED if days < 14 else YELLOW if days < RENEWAL_THRESHOLD_DAYS else GREEN
            print(f"{GREEN}{c['id']:<5}{RESET} {c['domain_name']:<35} {sc}{c['status']:<10}{RESET} "
                  f"{day_color}{days:>10}d{RESET} {c.get('expiry_date', '')[:10]}")
    elif args.cmd == "add":
        try:
            dom = mgr.add_domain(args.domain, args.provider, args.email)
            print(f"{GREEN}✓ Added domain '{dom.name}' with provider '{dom.provider}'{RESET}")
        except ValueError as e:
            print(f"{RED}✗ {e}{RESET}")
    elif args.cmd == "status":
        s = mgr.get_status()
        print(f"{BOLD}{CYAN}SSL Automator Status{RESET}")
        print(f"  {BLUE}Total Domains      :{RESET} {GREEN}{s['total_domains']}{RESET}")
        print(f"  {BLUE}Total Certificates :{RESET} {GREEN}{s['total_certificates']}{RESET}")
        print(f"  {BLUE}Expiring Soon      :{RESET} {YELLOW}{s['expiring_soon']}{RESET}")
        for st, c in s["by_status"].items():
            sc = STATUS_COLOR.get(st, RESET)
            print(f"    {sc}{st:<12}{RESET} {c}")
    elif args.cmd == "export":
        mgr.export(args.output, args.fmt)
        print(f"{GREEN}✓ Exported to {args.output}{RESET}")
    elif args.cmd == "check":
        cert = mgr.check_expiry(args.domain)
        if cert:
            sc = STATUS_COLOR.get(cert.status, RESET)
            day_color = RED if cert.days_until_expiry < 14 else YELLOW if cert.days_until_expiry < 30 else GREEN
            print(f"{BOLD}Certificate for {CYAN}{args.domain}{RESET}")
            print(f"  Status  : {sc}{cert.status}{RESET}")
            print(f"  Expiry  : {cert.expiry_date[:10]}")
            print(f"  Days    : {day_color}{cert.days_until_expiry}d remaining{RESET}")
        else:
            print(f"{RED}✗ Domain '{args.domain}' not found{RESET}")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
