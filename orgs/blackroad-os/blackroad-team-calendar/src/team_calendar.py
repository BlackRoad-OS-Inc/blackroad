#!/usr/bin/env python3
"""BlackRoad Team Calendar - Team calendar and event coordination."""
from __future__ import annotations
import argparse, json, sqlite3
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

GREEN = "\033[0;32m"; RED = "\033[0;31m"; YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"; BLUE = "\033[0;34m"; MAGENTA = "\033[0;35m"; BOLD = "\033[1m"; NC = "\033[0m"
DB_PATH = Path.home() / ".blackroad" / "team_calendar.db"
EVENT_TYPES = ["meeting", "deadline", "milestone", "social", "training", "review", "other"]
RSVP_STATUSES = ["pending", "accepted", "declined", "tentative"]


@dataclass
class TeamMember:
    id: Optional[int]; name: str; email: str; team: str = "default"
    role: str = ""; timezone: str = "UTC"
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class Event:
    id: Optional[int]; title: str; event_type: str; start_at: str; end_at: str
    location: str = ""; description: str = ""; organizer_id: Optional[int] = None
    recurring: str = "none"; status: str = "scheduled"; color: str = "blue"
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


class TeamCalendarDB:
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""CREATE TABLE IF NOT EXISTS members (
                id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE, team TEXT DEFAULT 'default',
                role TEXT DEFAULT '', timezone TEXT DEFAULT 'UTC', created_at TEXT)""")
            conn.execute("""CREATE TABLE IF NOT EXISTS events (
                id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
                event_type TEXT NOT NULL, start_at TEXT NOT NULL, end_at TEXT NOT NULL,
                location TEXT DEFAULT '', description TEXT DEFAULT '',
                organizer_id INTEGER, recurring TEXT DEFAULT 'none',
                status TEXT DEFAULT 'scheduled', color TEXT DEFAULT 'blue', created_at TEXT)""")
            conn.execute("""CREATE TABLE IF NOT EXISTS attendees (
                event_id INTEGER NOT NULL, member_id INTEGER NOT NULL,
                rsvp TEXT DEFAULT 'pending', notes TEXT DEFAULT '',
                PRIMARY KEY (event_id, member_id))""")
            conn.commit()

    def add_member(self, member: TeamMember) -> int:
        with sqlite3.connect(self.db_path) as conn:
            cur = conn.execute(
                "INSERT INTO members (name,email,team,role,timezone,created_at) VALUES (?,?,?,?,?,?)",
                (member.name, member.email, member.team, member.role,
                 member.timezone, member.created_at))
            conn.commit(); return cur.lastrowid

    def add_event(self, event: Event, attendee_ids: Optional[list] = None) -> int:
        with sqlite3.connect(self.db_path) as conn:
            cur = conn.execute(
                "INSERT INTO events (title,event_type,start_at,end_at,location,description,"
                "organizer_id,recurring,status,color,created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                (event.title, event.event_type, event.start_at, event.end_at, event.location,
                 event.description, event.organizer_id, event.recurring, event.status,
                 event.color, event.created_at))
            eid = cur.lastrowid
            if attendee_ids:
                conn.executemany("INSERT OR IGNORE INTO attendees (event_id,member_id) VALUES (?,?)",
                                 [(eid, mid) for mid in attendee_ids])
            conn.commit(); return eid

    def rsvp(self, event_id: int, member_id: int, status: str, notes: str = "") -> bool:
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT INTO attendees (event_id,member_id,rsvp,notes) VALUES (?,?,?,?)"
                " ON CONFLICT(event_id,member_id) DO UPDATE SET rsvp=?,notes=?",
                (event_id, member_id, status, notes, status, notes))
            conn.commit(); return True

    def list_events(self, event_type: Optional[str] = None,
                    from_date: Optional[str] = None, to_date: Optional[str] = None) -> list:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            clauses, params = [], []
            if event_type: clauses.append("event_type=?"); params.append(event_type)
            if from_date: clauses.append("start_at >= ?"); params.append(from_date)
            if to_date: clauses.append("start_at <= ?"); params.append(to_date)
            where = " WHERE " + " AND ".join(clauses) if clauses else ""
            return [dict(r) for r in conn.execute(
                f"SELECT * FROM events{where} ORDER BY start_at ASC", params).fetchall()]

    def list_members(self, team: Optional[str] = None) -> list:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            q, p = "SELECT * FROM members", ()
            if team: q += " WHERE team=?"; p = (team,)
            return [dict(r) for r in conn.execute(q + " ORDER BY name", p).fetchall()]

    def get_stats(self) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            nm = conn.execute("SELECT COUNT(*) FROM members").fetchone()[0]
            ne = conn.execute("SELECT COUNT(*) FROM events").fetchone()[0]
            by_type = {r[0]: r[1] for r in conn.execute(
                "SELECT event_type,COUNT(*) FROM events GROUP BY event_type")}
            upcoming = conn.execute(
                "SELECT COUNT(*) FROM events WHERE start_at > ? AND status='scheduled'",
                (datetime.now().isoformat(),)).fetchone()[0]
            by_team = {r[0]: r[1] for r in conn.execute(
                "SELECT team,COUNT(*) FROM members GROUP BY team")}
            return {"members": nm, "events": ne, "upcoming": upcoming,
                    "by_type": by_type, "by_team": by_team}

    def export_json(self) -> str:
        return json.dumps({"events": self.list_events(), "members": self.list_members(),
                           "stats": self.get_stats(),
                           "exported_at": datetime.now().isoformat()}, indent=2)


def _tc(t): return {"meeting": CYAN, "deadline": RED, "milestone": GREEN, "social": MAGENTA,
                    "training": BLUE, "review": YELLOW}.get(t, NC)


def cmd_list(args, db):
    if args.type == "events":
        events = db.list_events(getattr(args, "event_type", None),
                                getattr(args, "from_date", None), getattr(args, "to_date", None))
        print(f"\n{BOLD}{CYAN}{'ID':<5} {'Title':<28} {'Type':<12} {'Start':<22} {'Location'}{NC}")
        print("-" * 85)
        for e in events:
            print(f"{e['id']:<5} {e['title'][:27]:<28} {_tc(e['event_type'])}{e['event_type']:<12}{NC} "
                  f"{e['start_at'][:19]:<22} {e['location'][:25]}")
        print(f"\n{CYAN}Total: {len(events)}{NC}\n")
    else:
        members = db.list_members(getattr(args, "team", None))
        print(f"\n{BOLD}{CYAN}{'ID':<5} {'Name':<25} {'Email':<28} {'Team':<12} {'Role'}{NC}")
        print("-" * 82)
        for m in members:
            print(f"{m['id']:<5} {m['name'][:24]:<25} {m['email'][:27]:<28} {m['team']:<12} {m['role']}")
        print(f"\n{CYAN}Total: {len(members)}{NC}\n")


def cmd_add(args, db):
    if args.type == "member":
        mid = db.add_member(TeamMember(id=None, name=args.name, email=args.email,
                                       team=args.team, role=args.role, timezone=args.timezone))
        print(f"{GREEN}Added member #{mid}: {args.name} ({args.team}){NC}")
    else:
        eid = db.add_event(Event(id=None, title=args.title, event_type=args.event_type,
                                  start_at=args.start_at, end_at=args.end_at,
                                  location=args.location, description=args.description))
        print(f"{CYAN}Created event #{eid}: '{args.title}' on {args.start_at[:16]}{NC}")


def cmd_status(args, db):
    stats = db.get_stats()
    print(f"\n{BOLD}{CYAN}=== Team Calendar Dashboard ==={NC}\n")
    print(f"  {BOLD}Team members:{NC}  {stats['members']}")
    print(f"  {BOLD}Total events:{NC}  {stats['events']}")
    print(f"  {BOLD}Upcoming:{NC}      {GREEN}{stats['upcoming']}{NC}")
    print(f"\n  {BOLD}Events by type:{NC}")
    for t, c in stats["by_type"].items():
        print(f"    {_tc(t)}{t:<14}{NC} {c}")
    print(f"\n  {BOLD}Members by team:{NC}")
    for team, c in stats["by_team"].items():
        print(f"    {YELLOW}{team:<14}{NC} {c}")
    print()


def cmd_export(args, db):
    out = db.export_json()
    if args.output:
        Path(args.output).write_text(out); print(f"{GREEN}Exported to {args.output}{NC}")
    else:
        print(out)


def build_parser():
    p = argparse.ArgumentParser(prog="team-calendar", description="BlackRoad Team Calendar")
    sub = p.add_subparsers(dest="command", required=True)
    lp = sub.add_parser("list"); lp.add_argument("type", choices=["events", "members"])
    lp.add_argument("--event-type", dest="event_type", choices=EVENT_TYPES)
    lp.add_argument("--from-date", dest="from_date"); lp.add_argument("--to-date", dest="to_date")
    lp.add_argument("--team")
    ap = sub.add_parser("add"); ap.add_argument("type", choices=["member", "event"])
    ap.add_argument("--name", default=""); ap.add_argument("--email", default="")
    ap.add_argument("--team", default="default"); ap.add_argument("--role", default="")
    ap.add_argument("--timezone", default="UTC"); ap.add_argument("--title", default="")
    ap.add_argument("--event-type", dest="event_type", choices=EVENT_TYPES, default="meeting")
    ap.add_argument("--start-at", dest="start_at", default=datetime.now().isoformat())
    ap.add_argument("--end-at", dest="end_at", default=datetime.now().isoformat())
    ap.add_argument("--location", default=""); ap.add_argument("--description", default="")
    sub.add_parser("status")
    ep = sub.add_parser("export"); ep.add_argument("--output", "-o")
    return p


def main():
    args = build_parser().parse_args()
    db = TeamCalendarDB()
    {"list": cmd_list, "add": cmd_add, "status": cmd_status, "export": cmd_export}[args.command](args, db)


if __name__ == "__main__":
    main()
