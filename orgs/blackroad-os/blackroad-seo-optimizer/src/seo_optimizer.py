"""
BR SEO Optimizer - SEO analysis and optimization recommendation engine.
SQLite persistence at ~/.blackroad/seo_optimizer.db
"""
import argparse
import csv
import json
import sqlite3
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional

GREEN = "\033[0;32m"
RED = "\033[0;31m"
YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"
BLUE = "\033[0;34m"
BOLD = "\033[1m"
RESET = "\033[0m"

DB_PATH = Path.home() / ".blackroad" / "seo_optimizer.db"
ISSUE_TYPES = [
    "missing_title", "missing_description", "short_content",
    "missing_keywords", "slow_load", "duplicate_content",
]

ISSUE_COLOR = {
    "missing_title": RED, "missing_description": RED, "short_content": YELLOW,
    "missing_keywords": YELLOW, "slow_load": RED, "duplicate_content": CYAN,
}


@dataclass
class SEOIssue:
    issue_type: str
    severity: str
    detail: str
    page_url: str


@dataclass
class SEOReport:
    page_url: str
    score: int
    issues: List[SEOIssue] = field(default_factory=list)
    generated_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class Page:
    id: Optional[int]
    url: str
    title: str
    description: str
    keywords: str
    content_length: int
    load_time_ms: int
    score: int = 0
    last_analyzed: str = field(default_factory=lambda: datetime.now().isoformat())
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


class SEOOptimizer:
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def _init_db(self) -> None:
        with self._conn() as conn:
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS pages (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    url TEXT UNIQUE NOT NULL,
                    title TEXT,
                    description TEXT,
                    keywords TEXT,
                    content_length INTEGER DEFAULT 0,
                    load_time_ms INTEGER DEFAULT 0,
                    score INTEGER DEFAULT 0,
                    last_analyzed TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
                CREATE TABLE IF NOT EXISTS issues (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    page_id INTEGER REFERENCES pages(id) ON DELETE CASCADE,
                    issue_type TEXT NOT NULL,
                    severity TEXT DEFAULT 'warning',
                    detail TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
                CREATE TABLE IF NOT EXISTS recommendations (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    page_id INTEGER REFERENCES pages(id) ON DELETE CASCADE,
                    recommendation TEXT NOT NULL,
                    priority TEXT DEFAULT 'medium',
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
            """)

    def add_page(self, url: str, title: str = "", description: str = "",
                 keywords: str = "", content_length: int = 0, load_time_ms: int = 0) -> Page:
        now = datetime.now().isoformat()
        with self._conn() as conn:
            try:
                cur = conn.execute(
                    "INSERT INTO pages (url, title, description, keywords, content_length, "
                    "load_time_ms, created_at) VALUES (?,?,?,?,?,?,?)",
                    (url, title, description, keywords, content_length, load_time_ms, now),
                )
                page_id = cur.lastrowid
            except sqlite3.IntegrityError:
                row = conn.execute("SELECT * FROM pages WHERE url=?", (url,)).fetchone()
                return Page(**{k: row[k] for k in row.keys()})
        return Page(id=page_id, url=url, title=title, description=description, keywords=keywords,
                    content_length=content_length, load_time_ms=load_time_ms, created_at=now)

    def analyze_page(self, url: str) -> Optional[SEOReport]:
        with self._conn() as conn:
            row = conn.execute("SELECT * FROM pages WHERE url=?", (url,)).fetchone()
            if not row:
                return None
            page = dict(row)
            page_id = page["id"]
            issues: List[SEOIssue] = []
            score = 100

            if not page.get("title"):
                issues.append(SEOIssue("missing_title", "critical", "Page has no title tag", url))
                score -= 25
            elif len(page["title"]) < 10:
                issues.append(SEOIssue("missing_title", "warning", "Title is too short (<10 chars)", url))
                score -= 10

            if not page.get("description"):
                issues.append(SEOIssue("missing_description", "critical", "Meta description missing", url))
                score -= 20
            elif len(page["description"]) < 50:
                issues.append(SEOIssue("missing_description", "warning", "Meta description too short (<50 chars)", url))
                score -= 8

            if page.get("content_length", 0) < 300:
                issues.append(SEOIssue("short_content", "warning", f"Content too short ({page['content_length']} chars)", url))
                score -= 15

            if not page.get("keywords"):
                issues.append(SEOIssue("missing_keywords", "warning", "No keywords defined for page", url))
                score -= 10

            if page.get("load_time_ms", 0) > 3000:
                issues.append(SEOIssue("slow_load", "critical", f"Load time {page['load_time_ms']}ms exceeds 3s threshold", url))
                score -= 20

            score = max(0, score)
            now = datetime.now().isoformat()
            conn.execute("DELETE FROM issues WHERE page_id=?", (page_id,))
            for issue in issues:
                conn.execute(
                    "INSERT INTO issues (page_id, issue_type, severity, detail) VALUES (?,?,?,?)",
                    (page_id, issue.issue_type, issue.severity, issue.detail),
                )
            if issues:
                recs = [f"Fix '{i.issue_type}': {i.detail}" for i in issues[:3]]
                conn.execute("DELETE FROM recommendations WHERE page_id=?", (page_id,))
                for rec in recs:
                    conn.execute(
                        "INSERT INTO recommendations (page_id, recommendation, priority) VALUES (?,?,?)",
                        (page_id, rec, "high" if len(issues) > 3 else "medium"),
                    )
            conn.execute("UPDATE pages SET score=?, last_analyzed=? WHERE id=?", (score, now, page_id))
        return SEOReport(page_url=url, score=score, issues=issues, generated_at=now)

    def add_recommendation(self, url: str, recommendation: str, priority: str = "medium") -> bool:
        with self._conn() as conn:
            row = conn.execute("SELECT id FROM pages WHERE url=?", (url,)).fetchone()
            if not row:
                return False
            conn.execute(
                "INSERT INTO recommendations (page_id, recommendation, priority) VALUES (?,?,?)",
                (row["id"], recommendation, priority),
            )
        return True

    def list_pages(self, score_below: Optional[int] = None) -> List[dict]:
        with self._conn() as conn:
            query = "SELECT * FROM pages WHERE 1=1"
            params: list = []
            if score_below is not None:
                query += " AND score < ?"
                params.append(score_below)
            query += " ORDER BY score ASC"
            return [dict(r) for r in conn.execute(query, params).fetchall()]

    def get_status(self) -> dict:
        with self._conn() as conn:
            total = conn.execute("SELECT COUNT(*) as c FROM pages").fetchone()["c"]
            avg_score = conn.execute("SELECT AVG(score) as s FROM pages WHERE last_analyzed IS NOT NULL").fetchone()["s"]
            issues = conn.execute("SELECT COUNT(*) as c FROM issues").fetchone()["c"]
            by_type = conn.execute("SELECT issue_type, COUNT(*) as c FROM issues GROUP BY issue_type").fetchall()
            low_score = conn.execute("SELECT COUNT(*) as c FROM pages WHERE score < 50").fetchone()["c"]
        return {"total_pages": total, "avg_score": round(avg_score or 0, 1),
                "total_issues": issues, "low_score_pages": low_score,
                "issues_by_type": {r["issue_type"]: r["c"] for r in by_type}}

    def export(self, output_path: str, fmt: str = "json") -> None:
        pages = self.list_pages()
        if fmt == "json":
            with open(output_path, "w") as f:
                json.dump(pages, f, indent=2)
        else:
            fields = ["id", "url", "title", "score", "content_length", "load_time_ms", "last_analyzed"]
            with open(output_path, "w", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(pages)


def _score_color(score: int) -> str:
    if score >= 80:
        return GREEN
    if score >= 50:
        return YELLOW
    return RED


def main():
    parser = argparse.ArgumentParser(description="BR SEO Optimizer")
    sub = parser.add_subparsers(dest="cmd")

    p_list = sub.add_parser("list", help="List pages")
    p_list.add_argument("--score-below", type=int, help="Filter pages with score below N")

    p_add = sub.add_parser("add", help="Add a page")
    p_add.add_argument("url")
    p_add.add_argument("title")
    p_add.add_argument("--description", default="")
    p_add.add_argument("--keywords", default="")
    p_add.add_argument("--content-length", type=int, default=0)
    p_add.add_argument("--load-time", type=int, default=0, dest="load_time_ms")

    sub.add_parser("status", help="Show system status")

    p_exp = sub.add_parser("export", help="Export pages")
    p_exp.add_argument("output")
    p_exp.add_argument("--format", dest="fmt", choices=["json", "csv"], default="json")

    p_analyze = sub.add_parser("analyze", help="Analyze a page")
    p_analyze.add_argument("url")

    args = parser.parse_args()
    opt = SEOOptimizer()

    if args.cmd == "list":
        pages = opt.list_pages(score_below=args.score_below)
        if not pages:
            print(f"{YELLOW}No pages found.{RESET}")
            return
        print(f"{BOLD}{CYAN}{'ID':<5} {'URL':<50} {'Score':>6} {'Content':>10} {'Analyzed'}{RESET}")
        print(f"{CYAN}{'-'*95}{RESET}")
        for p in pages:
            sc = _score_color(p.get("score", 0))
            analyzed = (p.get("last_analyzed") or "never")[:10]
            print(f"{GREEN}{p['id']:<5}{RESET} {p['url']:<50} {sc}{p.get('score', 0):>6}{RESET} "
                  f"{p.get('content_length', 0):>10} {analyzed}")
    elif args.cmd == "add":
        page = opt.add_page(args.url, args.title, args.description, args.keywords,
                            args.content_length, args.load_time_ms)
        print(f"{GREEN}✓ Added page '{page.url}' (ID: {page.id}){RESET}")
    elif args.cmd == "status":
        s = opt.get_status()
        print(f"{BOLD}{CYAN}SEO Optimizer Status{RESET}")
        print(f"  {BLUE}Total Pages    :{RESET} {GREEN}{s['total_pages']}{RESET}")
        print(f"  {BLUE}Avg Score      :{RESET} {_score_color(int(s['avg_score']))}{s['avg_score']}{RESET}")
        print(f"  {BLUE}Total Issues   :{RESET} {RED}{s['total_issues']}{RESET}")
        print(f"  {BLUE}Low Score (<50):{RESET} {RED}{s['low_score_pages']}{RESET}")
        for it, c in s["issues_by_type"].items():
            ic = ISSUE_COLOR.get(it, RESET)
            print(f"    {ic}{it:<25}{RESET} {c}")
    elif args.cmd == "export":
        opt.export(args.output, args.fmt)
        print(f"{GREEN}✓ Exported to {args.output}{RESET}")
    elif args.cmd == "analyze":
        report = opt.analyze_page(args.url)
        if report:
            sc = _score_color(report.score)
            print(f"{BOLD}SEO Analysis: {CYAN}{args.url}{RESET}")
            print(f"  Score   : {sc}{report.score}/100{RESET}")
            print(f"  Issues  : {len(report.issues)}")
            for issue in report.issues:
                ic = ISSUE_COLOR.get(issue.issue_type, RESET)
                print(f"    {ic}[{issue.severity.upper()}]{RESET} {issue.issue_type} — {issue.detail}")
        else:
            print(f"{RED}✗ Page '{args.url}' not found. Use 'add' first.{RESET}")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
