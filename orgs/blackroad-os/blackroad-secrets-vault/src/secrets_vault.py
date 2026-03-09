#!/usr/bin/env python3
"""BlackRoad Secrets Vault — encrypted credential storage using PBKDF2 + Fernet-like XOR cipher."""

from __future__ import annotations

import argparse
import base64
import getpass
import hashlib
import json
import os
import secrets
import sqlite3
from dataclasses import asdict, dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import List, Optional

# ── ANSI Colors ───────────────────────────────────────────────────────────────
GREEN   = "\033[0;32m"
RED     = "\033[0;31m"
YELLOW  = "\033[1;33m"
CYAN    = "\033[0;36m"
BLUE    = "\033[0;34m"
MAGENTA = "\033[0;35m"
BOLD    = "\033[1m"
NC      = "\033[0m"

DB_PATH    = Path.home() / ".blackroad" / "secrets-vault.db"
ENV_MASTER = "BR_VAULT_PASS"


class SecretCategory(str, Enum):
    API_KEY     = "api_key"
    PASSWORD    = "password"
    TOKEN       = "token"
    CERTIFICATE = "certificate"
    SSH_KEY     = "ssh_key"
    OTHER       = "other"


@dataclass
class VaultSecret:
    """A single encrypted credential entry."""

    name:            str
    category:        SecretCategory  = SecretCategory.OTHER
    encrypted_value: str             = ""
    description:     str             = ""
    tags:            List[str]       = field(default_factory=list)
    rotation_days:   int             = 90
    last_rotated:    Optional[str]   = None
    created_at:      str             = field(default_factory=lambda: datetime.now().isoformat())
    updated_at:      str             = field(default_factory=lambda: datetime.now().isoformat())
    last_accessed:   Optional[str]   = None
    id:              Optional[int]   = None

    def days_until_rotation(self) -> Optional[int]:
        """Return days remaining before recommended rotation, or None if never rotated."""
        ref_date = self.last_rotated or self.created_at
        try:
            from datetime import date as dt_date
            rotated = datetime.fromisoformat(ref_date).date()
            delta   = (rotated - dt_date.today()).days + self.rotation_days
            return delta
        except (ValueError, TypeError):
            return None

    def needs_rotation(self) -> bool:
        d = self.days_until_rotation()
        return d is not None and d <= 0


# ── Crypto Helpers ────────────────────────────────────────────────────────────

def _derive_key(master_password: str, salt: bytes) -> bytes:
    """Derive a 32-byte key from master password using PBKDF2-HMAC-SHA256."""
    return hashlib.pbkdf2_hmac("sha256", master_password.encode(), salt, iterations=260_000, dklen=32)


def _encrypt(plaintext: str, key: bytes) -> str:
    """XOR-based stream cipher: PBKDF2-derived key + random nonce → base64 ciphertext.
    NOTE: For production use, replace with cryptography.Fernet or AES-GCM.
    """
    nonce     = secrets.token_bytes(32)
    key_stream = hashlib.pbkdf2_hmac("sha256", key, nonce, iterations=1, dklen=len(plaintext.encode()))
    ciphertext = bytes(a ^ b for a, b in zip(plaintext.encode(), key_stream))
    payload    = nonce + ciphertext
    return base64.b64encode(payload).decode()


def _decrypt(encoded: str, key: bytes) -> str:
    """Reverse of _encrypt; raises ValueError on corrupt data."""
    try:
        payload    = base64.b64decode(encoded.encode())
        nonce      = payload[:32]
        ciphertext = payload[32:]
        key_stream = hashlib.pbkdf2_hmac("sha256", key, nonce, iterations=1, dklen=len(ciphertext))
        return bytes(a ^ b for a, b in zip(ciphertext, key_stream)).decode()
    except Exception as exc:
        raise ValueError(f"Decryption failed: {exc}") from exc


class SecretsVault:
    """SQLite-backed encrypted secrets vault."""

    def __init__(self, db_path: Path = DB_PATH, master_password: Optional[str] = None) -> None:
        self.db_path  = db_path
        self._master  = master_password or os.environ.get(ENV_MASTER) or ""
        self._salt    = b""
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        with self._conn() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS vault_meta (
                    key   TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS secrets (
                    id              INTEGER PRIMARY KEY AUTOINCREMENT,
                    name            TEXT    UNIQUE NOT NULL,
                    category        TEXT    DEFAULT 'other',
                    encrypted_value TEXT    NOT NULL,
                    description     TEXT    DEFAULT '',
                    tags            TEXT    DEFAULT '[]',
                    rotation_days   INTEGER DEFAULT 90,
                    last_rotated    TEXT,
                    created_at      TEXT    NOT NULL,
                    updated_at      TEXT    NOT NULL,
                    last_accessed   TEXT
                )
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_name     ON secrets(name)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_category ON secrets(category)")
            # Bootstrap vault salt if not present
            row = conn.execute("SELECT value FROM vault_meta WHERE key='salt'").fetchone()
            if row:
                self._salt = base64.b64decode(row["value"])
            else:
                self._salt = secrets.token_bytes(32)
                conn.execute("INSERT INTO vault_meta VALUES ('salt',?)",
                             (base64.b64encode(self._salt).decode(),))
            conn.commit()

    def _key(self) -> bytes:
        if not self._master:
            self._master = getpass.getpass(f"{YELLOW}Vault master password: {NC}")
        return _derive_key(self._master, self._salt)

    def _row_to_secret(self, row: sqlite3.Row) -> VaultSecret:
        return VaultSecret(
            id=row["id"], name=row["name"],
            category=SecretCategory(row["category"]),
            encrypted_value=row["encrypted_value"],
            description=row["description"] or "",
            tags=json.loads(row["tags"] or "[]"),
            rotation_days=row["rotation_days"],
            last_rotated=row["last_rotated"],
            created_at=row["created_at"],
            updated_at=row["updated_at"],
            last_accessed=row["last_accessed"],
        )

    def add(self, name: str, plaintext_value: str, category: str = "other",
            description: str = "", tags: Optional[List[str]] = None,
            rotation_days: int = 90) -> VaultSecret:
        """Encrypt and store a new secret; raises if name already exists."""
        encrypted = _encrypt(plaintext_value, self._key())
        now       = datetime.now().isoformat()
        s = VaultSecret(name=name, category=SecretCategory(category),
                        encrypted_value=encrypted, description=description,
                        tags=tags or [], rotation_days=rotation_days,
                        last_rotated=now, created_at=now, updated_at=now)
        with self._conn() as conn:
            cur = conn.execute(
                "INSERT INTO secrets (name,category,encrypted_value,description,tags,"
                "rotation_days,last_rotated,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?)",
                (s.name, s.category.value, s.encrypted_value, s.description,
                 json.dumps(s.tags), s.rotation_days, s.last_rotated, s.created_at, s.updated_at),
            )
            conn.commit()
            s.id = cur.lastrowid
        return s

    def get(self, name: str) -> Optional[str]:
        """Decrypt and return the plaintext value; updates last_accessed timestamp."""
        with self._conn() as conn:
            row = conn.execute("SELECT * FROM secrets WHERE name=?", (name,)).fetchone()
            if not row:
                return None
            conn.execute("UPDATE secrets SET last_accessed=? WHERE name=?",
                         (datetime.now().isoformat(), name))
            conn.commit()
        return _decrypt(row["encrypted_value"], self._key())

    def list_secrets(self, category: Optional[str] = None) -> List[VaultSecret]:
        sql = "SELECT * FROM secrets WHERE 1=1"
        params: list = []
        if category:
            sql += " AND category=?"; params.append(category)
        sql += " ORDER BY name"
        with self._conn() as conn:
            rows = conn.execute(sql, params).fetchall()
        return [self._row_to_secret(r) for r in rows]

    def delete(self, name: str) -> bool:
        with self._conn() as conn:
            cur = conn.execute("DELETE FROM secrets WHERE name=?", (name,))
            conn.commit()
        return cur.rowcount > 0

    def rotate(self, name: str, new_plaintext: str) -> bool:
        """Re-encrypt a secret with the same master key (simulates rotation)."""
        encrypted = _encrypt(new_plaintext, self._key())
        now       = datetime.now().isoformat()
        with self._conn() as conn:
            cur = conn.execute(
                "UPDATE secrets SET encrypted_value=?,last_rotated=?,updated_at=? WHERE name=?",
                (encrypted, now, now, name),
            )
            conn.commit()
        return cur.rowcount > 0

    def export_json(self, path: str, include_values: bool = False) -> int:
        """Export metadata (never plaintext by default) to JSON."""
        items = self.list_secrets()
        records = []
        for s in items:
            d = asdict(s)
            d["category"] = s.category.value
            if not include_values:
                d.pop("encrypted_value", None)
            records.append(d)
        with open(path, "w") as fh:
            json.dump(records, fh, indent=2, default=str)
        return len(records)

    def stats(self) -> dict:
        items = self.list_secrets()
        by_cat: dict = {}
        needs_rotation = 0
        for s in items:
            by_cat[s.category.value] = by_cat.get(s.category.value, 0) + 1
            if s.needs_rotation():
                needs_rotation += 1
        return {"total": len(items), "by_category": by_cat, "needs_rotation": needs_rotation}


# ── CLI ───────────────────────────────────────────────────────────────────────

def cmd_list(args: argparse.Namespace, vault: SecretsVault) -> None:
    items = vault.list_secrets(category=args.filter_category)
    if not items:
        print(f"{YELLOW}No secrets found.{NC}"); return
    print(f"\n{BOLD}{BLUE}── Secrets Vault ({len(items)}) {'─'*37}{NC}")
    for s in items:
        rot_color = RED if s.needs_rotation() else GREEN
        days      = s.days_until_rotation()
        rot_note  = f" {rot_color}[rotate in {days}d]{NC}" if days is not None else ""
        cat_color = MAGENTA if s.category == SecretCategory.API_KEY else CYAN
        print(f"  {BOLD}{s.name:<30}{NC} {cat_color}{s.category.value:<14}{NC}{rot_note}")
        if s.description:
            print(f"    {s.description[:80]}")
    print()


def cmd_add(args: argparse.Namespace, vault: SecretsVault) -> None:
    value = args.value or getpass.getpass(f"{CYAN}Secret value: {NC}")
    tags  = [x.strip() for x in args.tags.split(",")] if args.tags else []
    s     = vault.add(args.name, value, category=args.category,
                      description=args.description, tags=tags,
                      rotation_days=args.rotation_days)
    print(f"{GREEN}✓ Secret '{s.name}' stored (id={s.id}, category={s.category.value}){NC}")


def cmd_get(args: argparse.Namespace, vault: SecretsVault) -> None:
    value = vault.get(args.name)
    if value is None:
        print(f"{RED}✗ Secret '{args.name}' not found{NC}")
    else:
        print(f"{GREEN}{value}{NC}")


def cmd_status(args: argparse.Namespace, vault: SecretsVault) -> None:
    s = vault.stats()
    print(f"\n{BOLD}{BLUE}── Vault Status {'─'*45}{NC}")
    print(f"  Total secrets   : {BOLD}{s['total']}{NC}")
    if s["needs_rotation"]:
        print(f"  {RED}⚠  Needs rotation : {s['needs_rotation']}{NC}")
    print(f"\n  {BOLD}By Category:{NC}")
    for cat, count in sorted(s["by_category"].items()):
        print(f"    {cat:<16} {count:>4}")
    print()


def cmd_export(args: argparse.Namespace, vault: SecretsVault) -> None:
    n = vault.export_json(args.output, include_values=False)
    print(f"{GREEN}✓ Exported {n} secret metadata → {args.output}{NC}")
    print(f"  {YELLOW}Note: plaintext values are never written to export.{NC}")


def build_parser() -> argparse.ArgumentParser:
    p   = argparse.ArgumentParser(description="BlackRoad Secrets Vault")
    sub = p.add_subparsers(dest="command", required=True)

    ls = sub.add_parser("list", help="List stored secrets")
    ls.add_argument("--filter-category", dest="filter_category", metavar="CAT")

    add = sub.add_parser("add", help="Store a new secret")
    add.add_argument("name")
    add.add_argument("--value",         metavar="VALUE",  default=None)
    add.add_argument("--category",      default="other",  choices=[x.value for x in SecretCategory])
    add.add_argument("--description",   default="")
    add.add_argument("--tags",          default=None)
    add.add_argument("--rotation-days", dest="rotation_days", type=int, default=90)

    ge = sub.add_parser("get", help="Retrieve a secret value")
    ge.add_argument("name")

    sub.add_parser("status", help="Show vault statistics")

    ex = sub.add_parser("export", help="Export secret metadata (no values)")
    ex.add_argument("--output", "-o", default="vault_export.json")

    return p


def main() -> None:
    parser = build_parser()
    args   = parser.parse_args()
    vault  = SecretsVault()
    {"list": cmd_list, "add": cmd_add, "get": cmd_get,
     "status": cmd_status, "export": cmd_export}[args.command](args, vault)


if __name__ == "__main__":
    main()
