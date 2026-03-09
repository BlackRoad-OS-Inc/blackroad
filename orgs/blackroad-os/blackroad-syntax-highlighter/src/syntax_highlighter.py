#!/usr/bin/env python3
"""BlackRoad Syntax Highlighter - Code syntax highlighting engine."""
from __future__ import annotations
import argparse, json, re, sqlite3
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional

GREEN = "\033[0;32m"; RED = "\033[0;31m"; YELLOW = "\033[1;33m"
CYAN = "\033[0;36m"; BLUE = "\033[0;34m"; BOLD = "\033[1m"; NC = "\033[0m"
DB_PATH = Path.home() / ".blackroad" / "syntax_highlighter.db"

KW = "\033[1;34m"; STR = "\033[0;32m"; CMT = "\033[0;90m"
NUM = "\033[0;35m"; FN = "\033[0;33m"; OP = "\033[0;36m"

LANG_RULES: dict = {
    "python": [
        (r"(#[^\n]*)", CMT),
        (r'("""[\s\S]*?"""|\'\'\'[\s\S]*?\'\'\'|"[^"\n]*"|\'[^\'\n]*\')', STR),
        (r"\b(def|class|import|from|return|if|elif|else|for|while|try|except|"
         r"finally|with|as|pass|break|continue|lambda|yield|async|await|not|and|or|in|is)\b", KW),
        (r"\b([A-Z][a-zA-Z0-9_]*)\s*(?=\()", FN),
        (r"\b([0-9]+(?:\.[0-9]+)?)\b", NUM),
        (r"(==|!=|<=|>=|<|>|\+=|-=|\*=|/=|=|\+|-|\*|/|%|//|\*\*)", OP),
    ],
    "javascript": [
        (r"(//[^\n]*|/\*[\s\S]*?\*/)", CMT),
        (r'("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'|`(?:[^`\\]|\\.)*`)', STR),
        (r"\b(const|let|var|function|return|if|else|for|while|do|switch|case|"
         r"break|continue|new|this|class|extends|import|export|default|async|await|"
         r"try|catch|finally|typeof|instanceof|null|undefined|true|false)\b", KW),
        (r"\b([a-zA-Z_$][a-zA-Z0-9_$]*)\s*(?=\s*\()", FN),
        (r"\b([0-9]+(?:\.[0-9]+)?)\b", NUM),
        (r"(===|!==|==|!=|<=|>=|<|>|\+=|-=|\*=|/=|=|\+|-|\*|/|%)", OP),
    ],
    "bash": [
        (r"(#[^\n]*)", CMT),
        (r'("(?:[^"\\]|\\.)*"|\'[^\']*\')', STR),
        (r"\b(if|then|else|elif|fi|for|while|do|done|case|esac|in|function|"
         r"return|exit|export|local|readonly|echo|printf|cd|ls|grep|awk|sed|find|mkdir|rm|cp|mv)\b", KW),
        (r"(\$\{[^}]+\}|\$[a-zA-Z_][a-zA-Z0-9_]*)", FN),
        (r"\b([0-9]+)\b", NUM),
        (r"(&&|\|\||>>|>|<|\|)", OP),
    ],
    "sql": [
        (r"(--[^\n]*|/\*[\s\S]*?\*/)", CMT),
        (r"('(?:[^'\\]|\\.)*')", STR),
        (r"\b(SELECT|FROM|WHERE|INSERT|INTO|UPDATE|SET|DELETE|CREATE|TABLE|INDEX|DROP|ALTER|"
         r"ADD|COLUMN|PRIMARY|KEY|FOREIGN|REFERENCES|JOIN|LEFT|RIGHT|INNER|ON|AS|ORDER|BY|"
         r"GROUP|HAVING|LIMIT|OFFSET|AND|OR|NOT|IN|IS|NULL|EXISTS|DISTINCT|COUNT|SUM|AVG|"
         r"MAX|MIN|LIKE|BETWEEN|UNION|ALL|VALUES|DEFAULT|CASE|WHEN|THEN|ELSE|END)\b", KW),
        (r"\b([0-9]+(?:\.[0-9]+)?)\b", NUM),
        (r"(=|!=|<>|<=|>=|<|>|\*)", OP),
    ],
}


@dataclass
class HighlightSession:
    id: Optional[int]; filename: str; language: str; line_count: int; char_count: int
    highlighted_at: str = field(default_factory=lambda: datetime.now().isoformat())


@dataclass
class Snippet:
    id: Optional[int]; name: str; language: str; code: str; tags: str = ""
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())


class SyntaxHighlighterDB:
    def __init__(self, db_path: Path = DB_PATH):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_db()

    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""CREATE TABLE IF NOT EXISTS sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT, filename TEXT NOT NULL,
                language TEXT NOT NULL, line_count INTEGER,
                char_count INTEGER, highlighted_at TEXT)""")
            conn.execute("""CREATE TABLE IF NOT EXISTS snippets (
                id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
                language TEXT NOT NULL, code TEXT NOT NULL,
                tags TEXT DEFAULT '', created_at TEXT)""")
            conn.commit()

    def log_session(self, s: HighlightSession) -> int:
        with sqlite3.connect(self.db_path) as conn:
            cur = conn.execute(
                "INSERT INTO sessions (filename,language,line_count,char_count,highlighted_at)"
                " VALUES (?,?,?,?,?)",
                (s.filename, s.language, s.line_count, s.char_count, s.highlighted_at))
            conn.commit(); return cur.lastrowid

    def save_snippet(self, snippet: Snippet) -> int:
        with sqlite3.connect(self.db_path) as conn:
            cur = conn.execute(
                "INSERT OR REPLACE INTO snippets (name,language,code,tags,created_at)"
                " VALUES (?,?,?,?,?)",
                (snippet.name, snippet.language, snippet.code, snippet.tags, snippet.created_at))
            conn.commit(); return cur.lastrowid

    def list_sessions(self) -> list:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute(
                "SELECT * FROM sessions ORDER BY highlighted_at DESC").fetchall()]

    def list_snippets(self, language: Optional[str] = None) -> list:
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            q, p = "SELECT * FROM snippets", ()
            if language:
                q += " WHERE language=?"; p = (language,)
            return [dict(r) for r in conn.execute(q, p).fetchall()]

    def get_stats(self) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            ts = conn.execute("SELECT COUNT(*) FROM sessions").fetchone()[0]
            tsnip = conn.execute("SELECT COUNT(*) FROM snippets").fetchone()[0]
            by_lang = {r[0]: r[1] for r in conn.execute(
                "SELECT language,COUNT(*) FROM sessions GROUP BY language")}
            return {"total_sessions": ts, "total_snippets": tsnip,
                    "sessions_by_language": by_lang}

    def export_json(self) -> str:
        return json.dumps({"sessions": self.list_sessions(), "snippets": self.list_snippets(),
                           "stats": self.get_stats(),
                           "exported_at": datetime.now().isoformat()}, indent=2)


class SyntaxHighlighter:
    def __init__(self, db: SyntaxHighlighterDB):
        self.db = db

    def detect_language(self, filename: str) -> str:
        return {".py": "python", ".js": "javascript", ".ts": "javascript",
                ".sh": "bash", ".bash": "bash", ".sql": "sql"}.get(
            Path(filename).suffix.lower(), "python")

    def highlight(self, code: str, language: str) -> str:
        rules = LANG_RULES.get(language, [])
        result, ph = code, {}
        for i, (pattern, color) in enumerate(rules):
            def replacer(m, c=color, idx=i):
                key = f"\x00PH{idx}_{len(ph)}\x00"
                ph[key] = f"{c}{m.group(0)}{NC}"; return key
            result = re.sub(pattern, replacer, result,
                            flags=re.IGNORECASE if language == "sql" else 0)
        for key, val in ph.items():
            result = result.replace(key, val)
        return result

    def highlight_file(self, filepath: str, log: bool = True) -> str:
        path = Path(filepath)
        code = path.read_text(encoding="utf-8", errors="replace")
        lang = self.detect_language(filepath)
        highlighted = self.highlight(code, lang)
        if log:
            self.db.log_session(HighlightSession(id=None, filename=path.name, language=lang,
                                                  line_count=code.count("\n") + 1, char_count=len(code)))
        return highlighted


def cmd_list(args, db):
    if args.type == "sessions":
        sessions = db.list_sessions()
        print(f"\n{BOLD}{CYAN}{'ID':<5} {'File':<30} {'Lang':<14} {'Lines':<8} {'Date'}{NC}")
        print("-" * 75)
        for s in sessions:
            print(f"{s['id']:<5} {s['filename'][:29]:<30} {YELLOW}{s['language']:<14}{NC}"
                  f" {s['line_count']:<8} {s['highlighted_at'][:19]}")
        print(f"\n{CYAN}Total: {len(sessions)}{NC}\n")
    else:
        snippets = db.list_snippets(getattr(args, "language", None))
        print(f"\n{BOLD}{CYAN}{'ID':<5} {'Name':<25} {'Lang':<14} {'Tags':<20} {'Created'}{NC}")
        print("-" * 80)
        for s in snippets:
            print(f"{s['id']:<5} {s['name'][:24]:<25} {YELLOW}{s['language']:<14}{NC}"
                  f" {s['tags']:<20} {s['created_at'][:19]}")
        print(f"\n{CYAN}Total: {len(snippets)}{NC}\n")


def cmd_add(args, db):
    hl = SyntaxHighlighter(db)
    if args.type == "file":
        print(hl.highlight_file(args.path, log=True))
        print(f"\n{GREEN}Highlighted and logged: {args.path}{NC}")
    else:
        code = Path(args.code_file).read_text() if args.code_file else (args.code or "")
        sid = db.save_snippet(Snippet(id=None, name=args.name, language=args.language,
                                      code=code, tags=args.tags))
        print(f"{GREEN}Saved snippet #{sid}: {args.name} ({args.language}){NC}")


def cmd_status(args, db):
    stats = db.get_stats()
    print(f"\n{BOLD}{CYAN}=== Syntax Highlighter Stats ==={NC}\n")
    print(f"  {BOLD}Total sessions:{NC}  {GREEN}{stats['total_sessions']}{NC}")
    print(f"  {BOLD}Total snippets:{NC}  {GREEN}{stats['total_snippets']}{NC}")
    print(f"\n  {BOLD}Sessions by language:{NC}")
    for lang, cnt in stats["sessions_by_language"].items():
        print(f"    {YELLOW}{lang:<14}{NC} {cnt}")
    print(f"\n  {BOLD}Supported langs:{NC} {CYAN}{', '.join(LANG_RULES)}{NC}\n")


def cmd_export(args, db):
    out = db.export_json()
    if args.output:
        Path(args.output).write_text(out); print(f"{GREEN}Exported to {args.output}{NC}")
    else:
        print(out)


def build_parser():
    p = argparse.ArgumentParser(prog="syntax-highlighter",
                                description="BlackRoad Syntax Highlighter")
    sub = p.add_subparsers(dest="command", required=True)
    lp = sub.add_parser("list"); lp.add_argument("type", choices=["sessions", "snippets"])
    lp.add_argument("--language")
    ap = sub.add_parser("add"); ap.add_argument("type", choices=["file", "snippet"])
    ap.add_argument("--path"); ap.add_argument("--name"); ap.add_argument("--language", default="python")
    ap.add_argument("--code"); ap.add_argument("--code-file", dest="code_file")
    ap.add_argument("--tags", default="")
    sub.add_parser("status")
    ep = sub.add_parser("export"); ep.add_argument("--output", "-o")
    return p


def main():
    args = build_parser().parse_args()
    db = SyntaxHighlighterDB()
    {"list": cmd_list, "add": cmd_add, "status": cmd_status, "export": cmd_export}[args.command](args, db)


if __name__ == "__main__":
    main()
