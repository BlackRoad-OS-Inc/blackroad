#!/usr/bin/env python3
"""BlackRoad Task Manager — production task management with priorities and deadlines."""

from __future__ import annotations

import argparse
import json
import sqlite3
from dataclasses import asdict, dataclass, field
from datetime import date, datetime
from enum import Enum
from pathlib import Path
from typing import List, Optional

# ── ANSI Colors ───────────────────────────────────────────────────────────────
GREEN  = "\033[0;32m"
RED    = "\033[0;31m"
YELLOW = "\033[1;33m"
CYAN   = "\033[0;36m"
BLUE   = "\033[0;34m"
BOLD   = "\033[1m"
NC     = "\033[0m"

DB_PATH = Path.home() / ".blackroad" / "task-manager.db"


class Priority(str, Enum):
    LOW    = "low"
    MEDIUM = "medium"
    HIGH   = "high"
    URGENT = "urgent"


class Status(str, Enum):
    PENDING     = "pending"
    IN_PROGRESS = "in_progress"
    DONE        = "done"
    CANCELLED   = "cancelled"


@dataclass
class Task:
    """Represents a single trackable task."""

    title:       str
    description: str           = ""
    priority:    Priority      = Priority.MEDIUM
    status:      Status        = Status.PENDING
    deadline:    Optional[str] = None
    tags:        List[str]     = field(default_factory=list)
    notes:       str           = ""
    created_at:  str           = field(default_factory=lambda: datetime.now().isoformat())
    updated_at:  str           = field(default_factory=lambda: datetime.now().isoformat())
    id:          Optional[int] = None

    def is_overdue(self) -> bool:
        """Return True if deadline has passed and task is still open."""
        if not self.deadline or self.status in (Status.DONE, Status.CANCELLED):
            return False
        try:
            return date.fromisoformat(self.deadline) < date.today()
        except ValueError:
            return False

    def priority_color(self) -> str:
        return {Priority.URGENT: RED, Priority.HIGH: YELLOW,
                Priority.MEDIUM: CYAN, Priority.LOW: GREEN}.get(self.priority, NC)

    def status_color(self) -> str:
        return {Status.DONE: GREEN, Status.CANCELLED: RED,
                Status.IN_PROGRESS: YELLOW, Status.PENDING: CYAN}.get(self.status, NC)


class TaskManager:
    """SQLite-backed task management engine."""

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
                CREATE TABLE IF NOT EXISTS tasks (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    title       TEXT    NOT NULL,
                    description TEXT    DEFAULT '',
                    priority    TEXT    DEFAULT 'medium',
                    status      TEXT    DEFAULT 'pending',
                    deadline    TEXT,
                    tags        TEXT    DEFAULT '[]',
                    notes       TEXT    DEFAULT '',
                    created_at  TEXT    NOT NULL,
                    updated_at  TEXT    NOT NULL
                )
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_status   ON tasks(status)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_priority ON tasks(priority)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_deadline ON tasks(deadline)")
            conn.commit()

    def _row_to_task(self, row: sqlite3.Row) -> Task:
        return Task(
            id=row["id"], title=row["title"],
            description=row["description"] or "",
            priority=Priority(row["priority"]), status=Status(row["status"]),
            deadline=row["deadline"], tags=json.loads(row["tags"] or "[]"),
            notes=row["notes"] or "", created_at=row["created_at"],
            updated_at=row["updated_at"],
        )

    def add(self, title: str, description: str = "", priority: str = "medium",
            deadline: Optional[str] = None, tags: Optional[List[str]] = None,
            notes: str = "") -> Task:
        """Persist a new task and return it with its assigned id."""
        now = datetime.now().isoformat()
        task = Task(title=title, description=description, priority=Priority(priority),
                    deadline=deadline, tags=tags or [], notes=notes,
                    created_at=now, updated_at=now)
        with self._conn() as conn:
            cur = conn.execute(
                "INSERT INTO tasks (title,description,priority,status,deadline,tags,notes,created_at,updated_at)"
                " VALUES (?,?,?,?,?,?,?,?,?)",
                (task.title, task.description, task.priority.value, task.status.value,
                 task.deadline, json.dumps(task.tags), task.notes, task.created_at, task.updated_at),
            )
            conn.commit()
            task.id = cur.lastrowid
        return task

    def list_tasks(self, status: Optional[str] = None, priority: Optional[str] = None,
                   search: Optional[str] = None) -> List[Task]:
        """Query tasks with optional filters; sorted by priority then deadline."""
        sql = "SELECT * FROM tasks WHERE 1=1"
        params: list = []
        if status:
            sql += " AND status=?"; params.append(status)
        if priority:
            sql += " AND priority=?"; params.append(priority)
        if search:
            sql += " AND (title LIKE ? OR description LIKE ?)"; params += [f"%{search}%"] * 2
        sql += (" ORDER BY CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2"
                " WHEN 'medium' THEN 3 ELSE 4 END, deadline NULLS LAST, created_at")
        with self._conn() as conn:
            rows = conn.execute(sql, params).fetchall()
        return [self._row_to_task(r) for r in rows]

    def update_status(self, task_id: int, new_status: str) -> bool:
        """Update a task's status by id; returns False if not found."""
        with self._conn() as conn:
            cur = conn.execute("UPDATE tasks SET status=?,updated_at=? WHERE id=?",
                               (new_status, datetime.now().isoformat(), task_id))
            conn.commit()
        return cur.rowcount > 0

    def delete(self, task_id: int) -> bool:
        """Hard-delete a task record; returns False if not found."""
        with self._conn() as conn:
            cur = conn.execute("DELETE FROM tasks WHERE id=?", (task_id,))
            conn.commit()
        return cur.rowcount > 0

    def export_json(self, path: str) -> int:
        """Dump all tasks as JSON; returns count written."""
        tasks = self.list_tasks()
        records = []
        for t in tasks:
            d = asdict(t)
            d["priority"] = t.priority.value
            d["status"]   = t.status.value
            records.append(d)
        with open(path, "w") as fh:
            json.dump(records, fh, indent=2, default=str)
        return len(records)

    def stats(self) -> dict:
        """Return aggregate counters across all tasks."""
        tasks = self.list_tasks()
        by_status: dict = {}
        by_priority: dict = {}
        overdue = 0
        for t in tasks:
            by_status[t.status.value]     = by_status.get(t.status.value, 0) + 1
            by_priority[t.priority.value] = by_priority.get(t.priority.value, 0) + 1
            if t.is_overdue():
                overdue += 1
        return {"total": len(tasks), "by_status": by_status,
                "by_priority": by_priority, "overdue": overdue}


# ── CLI ───────────────────────────────────────────────────────────────────────

def _print_task(t: Task) -> None:
    pc = t.priority_color()
    sc = t.status_color()
    ov = f" {RED}[OVERDUE]{NC}" if t.is_overdue() else ""
    dl = f"  due:{YELLOW}{t.deadline}{NC}" if t.deadline else ""
    tg = f"  [{', '.join(t.tags)}]" if t.tags else ""
    print(f"  {BOLD}#{t.id:<4}{NC} {pc}{t.priority.value:<8}{NC} {sc}{t.status.value:<13}{NC}"
          f" {t.title}{ov}{dl}{tg}")
    if t.description:
        print(f"            {t.description[:100]}")


def cmd_list(args: argparse.Namespace, mgr: TaskManager) -> None:
    tasks = mgr.list_tasks(status=args.filter_status, priority=args.filter_priority,
                           search=args.search)
    if not tasks:
        print(f"{YELLOW}No tasks found.{NC}"); return
    print(f"\n{BOLD}{BLUE}── Tasks ({len(tasks)}) {'─'*40}{NC}")
    print(f"  {'#':<5} {'Priority':<9} {'Status':<14} Title")
    print(f"  {'─'*5} {'─'*8} {'─'*13} {'─'*30}")
    for t in tasks:
        _print_task(t)
    print()


def cmd_add(args: argparse.Namespace, mgr: TaskManager) -> None:
    tags = [x.strip() for x in args.tags.split(",")] if args.tags else []
    task = mgr.add(args.title, description=args.description, priority=args.priority,
                   deadline=args.deadline, tags=tags, notes=args.notes)
    print(f"{GREEN}✓ Created task #{task.id}: {BOLD}{task.title}{NC}")
    if task.deadline:
        warn = f"  {RED}(already overdue!){NC}" if task.is_overdue() else ""
        print(f"  Deadline: {task.deadline}{warn}")


def cmd_status(args: argparse.Namespace, mgr: TaskManager) -> None:
    s = mgr.stats()
    print(f"\n{BOLD}{BLUE}── Task Manager Status {'─'*38}{NC}")
    print(f"  Total tasks : {BOLD}{s['total']}{NC}")
    print(f"\n  {BOLD}By Status:{NC}")
    for name, count in sorted(s["by_status"].items()):
        color = GREEN if name == "done" else (RED if name == "cancelled" else CYAN)
        bar   = "█" * min(count, 40)
        print(f"    {color}{name:<14}{NC} {count:>4}  {bar}")
    print(f"\n  {BOLD}By Priority:{NC}")
    for name, count in sorted(s["by_priority"].items()):
        print(f"    {name:<14} {count:>4}")
    if s["overdue"]:
        print(f"\n  {RED}⚠  Overdue tasks: {s['overdue']}{NC}")
    print()


def cmd_update(args: argparse.Namespace, mgr: TaskManager) -> None:
    if mgr.update_status(args.id, args.new_status):
        print(f"{GREEN}✓ Task #{args.id} status → {args.new_status}{NC}")
    else:
        print(f"{RED}✗ Task #{args.id} not found{NC}")


def cmd_export(args: argparse.Namespace, mgr: TaskManager) -> None:
    count = mgr.export_json(args.output)
    print(f"{GREEN}✓ Exported {count} tasks → {args.output}{NC}")


def build_parser() -> argparse.ArgumentParser:
    p   = argparse.ArgumentParser(description="BlackRoad Task Manager")
    sub = p.add_subparsers(dest="command", required=True)

    ls = sub.add_parser("list", help="List tasks")
    ls.add_argument("--filter-status",   dest="filter_status",   metavar="STATUS")
    ls.add_argument("--filter-priority", dest="filter_priority", metavar="PRIORITY")
    ls.add_argument("--search",          metavar="TERM")

    add = sub.add_parser("add", help="Create a new task")
    add.add_argument("title")
    add.add_argument("--description", "-d", default="")
    add.add_argument("--priority",    "-p", default="medium", choices=[x.value for x in Priority])
    add.add_argument("--deadline",          metavar="YYYY-MM-DD")
    add.add_argument("--tags",              help="Comma-separated tags")
    add.add_argument("--notes",             default="")

    sub.add_parser("status", help="Show statistics dashboard")

    up = sub.add_parser("update", help="Change task status")
    up.add_argument("id", type=int)
    up.add_argument("new_status", choices=[x.value for x in Status])

    ex = sub.add_parser("export", help="Export tasks to JSON")
    ex.add_argument("--output", "-o", default="tasks_export.json")

    return p


def main() -> None:
    parser = build_parser()
    args   = parser.parse_args()
    mgr    = TaskManager()
    {"list": cmd_list, "add": cmd_add, "status": cmd_status,
     "update": cmd_update, "export": cmd_export}[args.command](args, mgr)


if __name__ == "__main__":
    main()
