#!/usr/bin/env python3
"""BlackRoad Screen Share Manager — screen sharing session lifecycle and participant tracking."""

from __future__ import annotations

import argparse
import json
import random
import sqlite3
import string
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

DB_PATH = Path.home() / ".blackroad" / "screen-share.db"


class SessionStatus(str, Enum):
    SCHEDULED = "scheduled"
    LIVE      = "live"
    PAUSED    = "paused"
    ENDED     = "ended"
    CANCELLED = "cancelled"


class ParticipantRole(str, Enum):
    HOST       = "host"
    CO_HOST    = "co_host"
    PRESENTER  = "presenter"
    VIEWER     = "viewer"


STATUS_COLOR = {
    SessionStatus.LIVE:      GREEN,
    SessionStatus.PAUSED:    YELLOW,
    SessionStatus.SCHEDULED: CYAN,
    SessionStatus.ENDED:     BLUE,
    SessionStatus.CANCELLED: RED,
}


def _generate_code(length: int = 8) -> str:
    """Generate a human-readable session join code."""
    return "-".join(
        "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
        for _ in range(length // 4)
    )


@dataclass
class Session:
    """A screen sharing session with access control and metadata."""

    host:               str
    title:              str
    status:             SessionStatus  = SessionStatus.SCHEDULED
    session_code:       str            = field(default_factory=_generate_code)
    max_participants:   int            = 50
    recording_enabled: bool            = False
    password_hash:      str            = ""
    description:        str            = ""
    tags:               List[str]      = field(default_factory=list)
    start_time:         Optional[str]  = None
    end_time:           Optional[str]  = None
    created_at:         str            = field(default_factory=lambda: datetime.now().isoformat())
    updated_at:         str            = field(default_factory=lambda: datetime.now().isoformat())
    id:                 Optional[int]  = None

    def is_active(self) -> bool:
        return self.status in (SessionStatus.LIVE, SessionStatus.PAUSED)

    def duration_minutes(self) -> Optional[float]:
        if not self.start_time:
            return None
        end = self.end_time or datetime.now().isoformat()
        try:
            start_dt = datetime.fromisoformat(self.start_time)
            end_dt   = datetime.fromisoformat(end)
            return round((end_dt - start_dt).total_seconds() / 60, 1)
        except ValueError:
            return None

    def status_color(self) -> str:
        return STATUS_COLOR.get(self.status, NC)


@dataclass
class Participant:
    """A user who joined a screen sharing session."""

    session_id:  int
    username:    str
    role:        ParticipantRole = ParticipantRole.VIEWER
    joined_at:   str             = field(default_factory=lambda: datetime.now().isoformat())
    left_at:     Optional[str]   = None
    is_muted:    bool            = False
    device_info: str             = ""
    id:          Optional[int]   = None

    def is_present(self) -> bool:
        return self.left_at is None

    def session_minutes(self) -> Optional[float]:
        if not self.left_at:
            return None
        try:
            j = datetime.fromisoformat(self.joined_at)
            l = datetime.fromisoformat(self.left_at)
            return round((l - j).total_seconds() / 60, 1)
        except ValueError:
            return None


class ScreenShareManager:
    """SQLite-backed screen sharing session manager."""

    def __init__(self, db_path: Path = DB_PATH) -> None:
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        with self._conn() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS sessions (
                    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
                    host               TEXT    NOT NULL,
                    title              TEXT    NOT NULL,
                    status             TEXT    DEFAULT 'scheduled',
                    session_code       TEXT    UNIQUE NOT NULL,
                    max_participants   INTEGER DEFAULT 50,
                    recording_enabled  INTEGER DEFAULT 0,
                    password_hash      TEXT    DEFAULT '',
                    description        TEXT    DEFAULT '',
                    tags               TEXT    DEFAULT '[]',
                    start_time         TEXT,
                    end_time           TEXT,
                    created_at         TEXT    NOT NULL,
                    updated_at         TEXT    NOT NULL
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS participants (
                    id           INTEGER PRIMARY KEY AUTOINCREMENT,
                    session_id   INTEGER NOT NULL REFERENCES sessions(id),
                    username     TEXT    NOT NULL,
                    role         TEXT    DEFAULT 'viewer',
                    joined_at    TEXT    NOT NULL,
                    left_at      TEXT,
                    is_muted     INTEGER DEFAULT 0,
                    device_info  TEXT    DEFAULT ''
                )
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_session_code   ON sessions(session_code)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_session_status ON sessions(status)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_part_session   ON participants(session_id)")
            conn.commit()

    def _row_to_session(self, row: sqlite3.Row) -> Session:
        return Session(id=row["id"], host=row["host"], title=row["title"],
                       status=SessionStatus(row["status"]), session_code=row["session_code"],
                       max_participants=row["max_participants"],
                       recording_enabled=bool(row["recording_enabled"]),
                       password_hash=row["password_hash"] or "",
                       description=row["description"] or "",
                       tags=json.loads(row["tags"] or "[]"),
                       start_time=row["start_time"], end_time=row["end_time"],
                       created_at=row["created_at"], updated_at=row["updated_at"])

    def _row_to_participant(self, row: sqlite3.Row) -> Participant:
        return Participant(id=row["id"], session_id=row["session_id"],
                           username=row["username"], role=ParticipantRole(row["role"]),
                           joined_at=row["joined_at"], left_at=row["left_at"],
                           is_muted=bool(row["is_muted"]), device_info=row["device_info"] or "")

    def create_session(self, host: str, title: str, max_participants: int = 50,
                       recording_enabled: bool = False, description: str = "",
                       tags: Optional[List[str]] = None) -> Session:
        """Create a new scheduled session and return it with its unique join code."""
        now = datetime.now().isoformat()
        s   = Session(host=host, title=title, max_participants=max_participants,
                      recording_enabled=recording_enabled, description=description,
                      tags=tags or [], created_at=now, updated_at=now)
        with self._conn() as conn:
            cur = conn.execute(
                "INSERT INTO sessions (host,title,status,session_code,max_participants,"
                "recording_enabled,password_hash,description,tags,start_time,end_time,"
                "created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (s.host, s.title, s.status.value, s.session_code, s.max_participants,
                 int(s.recording_enabled), s.password_hash, s.description,
                 json.dumps(s.tags), s.start_time, s.end_time, s.created_at, s.updated_at),
            )
            conn.commit()
            s.id = cur.lastrowid
        # Auto-join host
        self.join_session(s.session_code, host, role=ParticipantRole.HOST.value)
        return s

    def join_session(self, session_code: str, username: str,
                     role: str = "viewer", device_info: str = "") -> Optional[Participant]:
        """Add a participant to an active session; starts it if still scheduled."""
        s = self.get_by_code(session_code)
        if not s:
            return None
        # Auto-start if scheduled and host is joining
        if s.status == SessionStatus.SCHEDULED and role == ParticipantRole.HOST.value:
            self._set_status(s.id, SessionStatus.LIVE, set_start=True)
        now = datetime.now().isoformat()
        p   = Participant(session_id=s.id, username=username,
                          role=ParticipantRole(role), joined_at=now, device_info=device_info)
        with self._conn() as conn:
            cur = conn.execute(
                "INSERT INTO participants (session_id,username,role,joined_at,is_muted,device_info)"
                " VALUES (?,?,?,?,?,?)",
                (p.session_id, p.username, p.role.value, p.joined_at, int(p.is_muted), p.device_info),
            )
            conn.commit()
            p.id = cur.lastrowid
        return p

    def end_session(self, session_code: str) -> bool:
        """Mark session as ended and record end timestamp."""
        s = self.get_by_code(session_code)
        if not s:
            return False
        self._set_status(s.id, SessionStatus.ENDED, set_end=True)
        # Close any open participant records
        with self._conn() as conn:
            conn.execute("UPDATE participants SET left_at=? WHERE session_id=? AND left_at IS NULL",
                         (datetime.now().isoformat(), s.id))
            conn.commit()
        return True

    def _set_status(self, session_id: int, status: SessionStatus,
                    set_start: bool = False, set_end: bool = False) -> None:
        now = datetime.now().isoformat()
        fields = "status=?,updated_at=?"
        params: list = [status.value, now]
        if set_start:
            fields += ",start_time=?"; params.append(now)
        if set_end:
            fields += ",end_time=?"; params.append(now)
        params.append(session_id)
        with self._conn() as conn:
            conn.execute(f"UPDATE sessions SET {fields} WHERE id=?", params)
            conn.commit()

    def get_by_code(self, code: str) -> Optional[Session]:
        with self._conn() as conn:
            row = conn.execute("SELECT * FROM sessions WHERE session_code=?", (code,)).fetchone()
        return self._row_to_session(row) if row else None

    def list_sessions(self, status: Optional[str] = None, limit: int = 30) -> List[Session]:
        sql = "SELECT * FROM sessions WHERE 1=1"
        params: list = []
        if status:
            sql += " AND status=?"; params.append(status)
        sql += " ORDER BY created_at DESC LIMIT ?"
        params.append(limit)
        with self._conn() as conn:
            rows = conn.execute(sql, params).fetchall()
        return [self._row_to_session(r) for r in rows]

    def list_participants(self, session_code: str) -> List[Participant]:
        s = self.get_by_code(session_code)
        if not s:
            return []
        with self._conn() as conn:
            rows = conn.execute("SELECT * FROM participants WHERE session_id=? ORDER BY joined_at",
                                (s.id,)).fetchall()
        return [self._row_to_participant(r) for r in rows]

    def export_json(self, path: str) -> int:
        sessions = self.list_sessions(limit=10_000)
        records  = [asdict(s) | {"status": s.status.value} for s in sessions]
        with open(path, "w") as fh:
            json.dump(records, fh, indent=2, default=str)
        return len(records)

    def stats(self) -> dict:
        sessions   = self.list_sessions(limit=10_000)
        by_status: dict = {}
        live_count = 0
        for s in sessions:
            by_status[s.status.value] = by_status.get(s.status.value, 0) + 1
            if s.status == SessionStatus.LIVE:
                live_count += 1
        total_part = sum(
            1 for s in sessions
            for _ in self.list_participants(s.session_code)
        )
        return {"total_sessions": len(sessions), "live_now": live_count,
                "total_participants_all_time": total_part, "by_status": by_status}


# ── CLI ───────────────────────────────────────────────────────────────────────

def _print_session(s: Session) -> None:
    sc = s.status_color()
    rec = f"  {RED}[REC]{NC}" if s.recording_enabled else ""
    dur = f"  {YELLOW}{s.duration_minutes():.0f}min{NC}" if s.duration_minutes() else ""
    print(f"  {BOLD}#{s.id:<4}{NC} {sc}{s.status.value:<11}{NC} {CYAN}{s.session_code}{NC}"
          f"  {s.host}: {s.title}{rec}{dur}")


def cmd_list(args: argparse.Namespace, mgr: ScreenShareManager) -> None:
    sessions = mgr.list_sessions(status=args.filter_status, limit=args.limit)
    if not sessions:
        print(f"{YELLOW}No sessions found.{NC}"); return
    print(f"\n{BOLD}{BLUE}── Screen Share Sessions ({len(sessions)}) {'─'*30}{NC}")
    for s in sessions:
        _print_session(s)
    print()


def cmd_create(args: argparse.Namespace, mgr: ScreenShareManager) -> None:
    tags = [x.strip() for x in args.tags.split(",")] if args.tags else []
    s    = mgr.create_session(args.host, args.title, max_participants=args.max_participants,
                               recording_enabled=args.record, description=args.description, tags=tags)
    print(f"{GREEN}✓ Session created{NC}")
    print(f"  Code    : {BOLD}{CYAN}{s.session_code}{NC}")
    print(f"  Host    : {s.host}  Title: {s.title}")
    print(f"  Max     : {s.max_participants} participants"
          + (f"  {RED}[RECORDING]{NC}" if s.recording_enabled else ""))


def cmd_join(args: argparse.Namespace, mgr: ScreenShareManager) -> None:
    p = mgr.join_session(args.session_code, args.username,
                          role=args.role, device_info=args.device)
    if p:
        print(f"{GREEN}✓ {args.username} joined {args.session_code} as {p.role.value}{NC}")
    else:
        print(f"{RED}✗ Session not found: {args.session_code}{NC}")


def cmd_end(args: argparse.Namespace, mgr: ScreenShareManager) -> None:
    s = mgr.get_by_code(args.session_code)
    if mgr.end_session(args.session_code):
        dur = s.duration_minutes() if s else None
        print(f"{GREEN}✓ Session {args.session_code} ended"
              + (f" ({dur:.0f} min)" if dur else "") + f"{NC}")
    else:
        print(f"{RED}✗ Session not found{NC}")


def cmd_status(args: argparse.Namespace, mgr: ScreenShareManager) -> None:
    s = mgr.stats()
    print(f"\n{BOLD}{BLUE}── Screen Share Manager Status {'─'*29}{NC}")
    print(f"  Total sessions  : {BOLD}{s['total_sessions']}{NC}")
    print(f"  Live now        : {GREEN}{BOLD}{s['live_now']}{NC}")
    print(f"  Total attendees : {BOLD}{s['total_participants_all_time']}{NC}")
    print(f"\n  {BOLD}By Status:{NC}")
    for name, count in sorted(s["by_status"].items()):
        color = STATUS_COLOR.get(SessionStatus(name), NC)
        print(f"    {color}{name:<12}{NC} {count:>4}")
    print()


def cmd_export(args: argparse.Namespace, mgr: ScreenShareManager) -> None:
    n = mgr.export_json(args.output)
    print(f"{GREEN}✓ Exported {n} sessions → {args.output}{NC}")


def build_parser() -> argparse.ArgumentParser:
    p   = argparse.ArgumentParser(description="BlackRoad Screen Share Manager")
    sub = p.add_subparsers(dest="command", required=True)

    ls = sub.add_parser("list", help="List sessions")
    ls.add_argument("--filter-status", dest="filter_status", metavar="STATUS")
    ls.add_argument("--limit", type=int, default=30)

    cr = sub.add_parser("create", help="Create a new session")
    cr.add_argument("host");  cr.add_argument("title")
    cr.add_argument("--max-participants", dest="max_participants", type=int, default=50)
    cr.add_argument("--record",      action="store_true")
    cr.add_argument("--description", default="")
    cr.add_argument("--tags",        default=None)

    jn = sub.add_parser("join", help="Join an existing session")
    jn.add_argument("session_code");  jn.add_argument("username")
    jn.add_argument("--role",   default="viewer", choices=[x.value for x in ParticipantRole])
    jn.add_argument("--device", default="")

    en = sub.add_parser("end", help="End an active session")
    en.add_argument("session_code")

    sub.add_parser("status", help="Show usage statistics")

    ex = sub.add_parser("export", help="Export session data to JSON")
    ex.add_argument("--output", "-o", default="screenshare_export.json")

    return p


def main() -> None:
    parser = build_parser()
    args   = parser.parse_args()
    mgr    = ScreenShareManager()
    {"list": cmd_list, "create": cmd_create, "join": cmd_join,
     "end": cmd_end, "status": cmd_status, "export": cmd_export}[args.command](args, mgr)


if __name__ == "__main__":
    main()
