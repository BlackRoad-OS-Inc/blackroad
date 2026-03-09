#!/usr/bin/env python3
"""BlackRoad Social Scheduler - Social media post scheduler."""
from __future__ import annotations
import argparse, json, sqlite3
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

GREEN = "\033[0;32m"; RED = "\033[0;31m"; YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"; BLUE = "\033[0;34m"; MAGENTA = "\033[0;35m"; BOLD = "\033[1m"; NC = "\033[0m"
DB_PATH = Path.home() / ".blackroad" / "social_scheduler.db"
PLATFORMS = ["twitter", "instagram", "linkedin", "facebook", "threads", "bluesky"]
STATUSES = ["draft", "scheduled", "published", "failed", "cancelled"]


@dataclass
class Post:
    id: Optional[int]; title: str; content: str; platform: str; scheduled_at: str
    status: str = "draft"; tags: str = ""; media_url: str = ""
    published_at: Optional[str] = None; notes: str = ""
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class Campaign:
    id: Optional[int]; name: str; description: str; start_date: str; end_date: str
    status: str = "active"
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


class SocialSchedulerDB:
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""CREATE TABLE IF NOT EXISTS posts (
                id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
                content TEXT NOT NULL, platform TEXT NOT NULL, scheduled_at TEXT NOT NULL,
                status TEXT DEFAULT 'draft', tags TEXT DEFAULT '', media_url TEXT DEFAULT '',
                published_at TEXT, created_at TEXT, notes TEXT DEFAULT '', campaign_id INTEGER)""")
            conn.execute("""CREATE TABLE IF NOT EXISTS campaigns (
                id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
                description TEXT DEFAULT '', start_date TEXT NOT NULL,
                end_date TEXT NOT NULL, status TEXT DEFAULT 'active', created_at TEXT)""")
            conn.commit()

    def add_post(self, post: Post, campaign_id: Optional[int] = None) -> int:
        with sqlite3.connect(self.db_path) as conn:
            cur = conn.execute(
                "INSERT INTO posts (title,content,platform,scheduled_at,status,tags,"
                "media_url,published_at,created_at,notes,campaign_id) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                (post.title, post.content, post.platform, post.scheduled_at, post.status,
                 post.tags, post.media_url, post.published_at, post.created_at, post.notes, campaign_id))
            conn.commit(); return cur.lastrowid

    def add_campaign(self, campaign: Campaign) -> int:
        with sqlite3.connect(self.db_path) as conn:
            cur = conn.execute(
                "INSERT INTO campaigns (name,description,start_date,end_date,status,created_at)"
                " VALUES (?,?,?,?,?,?)",
                (campaign.name, campaign.description, campaign.start_date,
                 campaign.end_date, campaign.status, campaign.created_at))
            conn.commit(); return cur.lastrowid

    def update_post_status(self, post_id: int, status: str) -> bool:
        pub = datetime.now().isoformat() if status == "published" else None
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("UPDATE posts SET status=?,published_at=? WHERE id=?", (status, pub, post_id))
            conn.commit()
            return conn.execute("SELECT changes()").fetchone()[0] > 0

    def list_posts(self, platform: Optional[str] = None, status: Optional[str] = None) -> list:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            clauses, params = [], []
            if platform: clauses.append("platform=?"); params.append(platform)
            if status: clauses.append("status=?"); params.append(status)
            where = " WHERE " + " AND ".join(clauses) if clauses else ""
            return [dict(r) for r in conn.execute(
                f"SELECT * FROM posts{where} ORDER BY scheduled_at ASC", params).fetchall()]

    def list_upcoming(self) -> list:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute(
                "SELECT * FROM posts WHERE status='scheduled' AND scheduled_at > ? "
                "ORDER BY scheduled_at ASC LIMIT 10", (datetime.now().isoformat(),)).fetchall()]

    def get_stats(self) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            by_status = {r[0]: r[1] for r in conn.execute("SELECT status,COUNT(*) FROM posts GROUP BY status")}
            by_platform = {r[0]: r[1] for r in conn.execute("SELECT platform,COUNT(*) FROM posts GROUP BY platform")}
            tc = conn.execute("SELECT COUNT(*) FROM campaigns").fetchone()[0]
            return {"by_status": by_status, "by_platform": by_platform, "total_campaigns": tc}

    def export_json(self) -> str:
        return json.dumps({"posts": self.list_posts(), "stats": self.get_stats(),
                           "exported_at": datetime.now().isoformat()}, indent=2)


def _pc(p): return {"twitter": CYAN, "instagram": MAGENTA, "linkedin": BLUE,
                    "facebook": BLUE, "threads": "\033[0;90m", "bluesky": CYAN}.get(p, NC)
def _sc(s): return {"scheduled": BLUE, "published": GREEN, "failed": RED,
                    "draft": YELLOW, "cancelled": "\033[0;90m"}.get(s, NC)


def cmd_list(args, db):
    posts = db.list_posts(getattr(args, "platform", None), getattr(args, "filter_status", None))
    print(f"\n{BOLD}{CYAN}{'ID':<5} {'Title':<28} {'Platform':<12} {'Scheduled':<22} {'Status':<12} {'Tags'}{NC}")
    print("-" * 95)
    for p in posts:
        print(f"{p['id']:<5} {p['title'][:27]:<28} {_pc(p['platform'])}{p['platform']:<12}{NC} "
              f"{p['scheduled_at'][:19]:<22} {_sc(p['status'])}{p['status']:<12}{NC} {p['tags']}")
    print(f"\n{CYAN}Total: {len(posts)}{NC}\n")


def cmd_add(args, db):
    post = Post(id=None, title=args.title, content=args.content, platform=args.platform,
                scheduled_at=args.scheduled_at,
                status="scheduled" if args.scheduled_at else "draft",
                tags=args.tags, media_url=args.media_url)
    pid = db.add_post(post)
    print(f"{GREEN}Post #{pid} '{args.title}' scheduled for {args.platform} at {args.scheduled_at}{NC}")


def cmd_status(args, db):
    stats = db.get_stats()
    upcoming = db.list_upcoming()
    print(f"\n{BOLD}{CYAN}=== Social Scheduler Dashboard ==={NC}\n")
    print(f"{BOLD}Posts by Status:{NC}")
    for s, c in stats["by_status"].items():
        print(f"  {_sc(s)}{s:<14}{NC} {c}")
    print(f"\n{BOLD}Posts by Platform:{NC}")
    for pl, c in stats["by_platform"].items():
        print(f"  {_pc(pl)}{pl:<14}{NC} {c}")
    print(f"\n{BOLD}Campaigns:{NC} {stats['total_campaigns']}")
    if upcoming:
        print(f"\n{BOLD}{YELLOW}Next {min(5, len(upcoming))} upcoming:{NC}")
        for p in upcoming[:5]:
            print(f"  [{_pc(p['platform'])}{p['platform']}{NC}] {p['scheduled_at'][:16]} - {p['title'][:40]}")
    print()


def cmd_export(args, db):
    out = db.export_json()
    if args.output:
        Path(args.output).write_text(out); print(f"{GREEN}Exported to {args.output}{NC}")
    else:
        print(out)


def build_parser():
    p = argparse.ArgumentParser(prog="social-scheduler", description="BlackRoad Social Scheduler")
    sub = p.add_subparsers(dest="command", required=True)
    lp = sub.add_parser("list")
    lp.add_argument("--platform", choices=PLATFORMS)
    lp.add_argument("--filter-status", dest="filter_status", choices=STATUSES)
    ap = sub.add_parser("add")
    ap.add_argument("title"); ap.add_argument("--content", required=True)
    ap.add_argument("--platform", choices=PLATFORMS, required=True)
    ap.add_argument("--scheduled-at", dest="scheduled_at", default=datetime.now().isoformat())
    ap.add_argument("--tags", default=""); ap.add_argument("--media-url", dest="media_url", default="")
    sub.add_parser("status")
    ep = sub.add_parser("export"); ep.add_argument("--output", "-o")
    return p


def main():
    args = build_parser().parse_args()
    db = SocialSchedulerDB()
    {"list": cmd_list, "add": cmd_add, "status": cmd_status, "export": cmd_export}[args.command](args, db)


if __name__ == "__main__":
    main()
