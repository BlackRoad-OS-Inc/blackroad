#!/usr/bin/env python3
"""BlackRoad XML Parser — parse, validate, XPath query, transform to JSON, diff XML docs."""

import sqlite3
import json
import uuid
import os
import sys
import argparse
import hashlib
import re
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List, Dict, Any, Union, Tuple
from xml.etree import ElementTree as ET
from xml.etree.ElementTree import Element
from io import StringIO

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

DB_PATH = os.environ.get("XML_DB", os.path.expanduser("~/.blackroad/xml_parser.db"))


@dataclass
class XMLDocument:
    id: str
    name: str
    source: str
    doc_type: str
    content_hash: str
    element_count: int
    depth: int
    namespaces: Dict[str, str]
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class SchemaRule:
    id: str
    name: str
    rule_type: str
    path: str
    constraint: str
    required: bool = True
    description: str = ""
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class XPathResult:
    query: str
    document_id: str
    matches: List[Dict[str, Any]]
    match_count: int
    executed_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class TransformResult:
    document_id: str
    format_out: str
    content: Any
    rules_applied: int
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class DiffResult:
    doc_a_id: str
    doc_b_id: str
    added: List[Dict]
    removed: List[Dict]
    modified: List[Dict]
    unchanged_count: int
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())

    @property
    def total_changes(self) -> int:
        return len(self.added) + len(self.removed) + len(self.modified)


class XMLDB:
    def __init__(self, db_path: str = DB_PATH):
        os.makedirs(os.path.dirname(db_path) or ".", exist_ok=True)
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self._init_schema()

    def _init_schema(self):
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS documents (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                source TEXT NOT NULL,
                doc_type TEXT DEFAULT 'xml',
                content_hash TEXT NOT NULL,
                content TEXT NOT NULL,
                element_count INTEGER DEFAULT 0,
                depth INTEGER DEFAULT 0,
                namespaces TEXT DEFAULT '{}',
                metadata TEXT DEFAULT '{}',
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS schema_rules (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                rule_type TEXT NOT NULL,
                path TEXT NOT NULL,
                constraint_val TEXT NOT NULL,
                required INTEGER DEFAULT 1,
                description TEXT DEFAULT '',
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS xpath_history (
                id TEXT PRIMARY KEY,
                document_id TEXT NOT NULL,
                query TEXT NOT NULL,
                match_count INTEGER DEFAULT 0,
                result_json TEXT DEFAULT '[]',
                executed_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS transforms (
                id TEXT PRIMARY KEY,
                document_id TEXT NOT NULL,
                format_out TEXT NOT NULL,
                content TEXT NOT NULL,
                rules_applied INTEGER DEFAULT 0,
                created_at TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_docs_name ON documents(name, created_at DESC);
            CREATE INDEX IF NOT EXISTS idx_xpath_doc ON xpath_history(document_id, executed_at DESC);
        """)
        self.conn.commit()


class XMLParser:
    """Core XML parsing, validation, XPath, transformation, and diffing engine."""

    def __init__(self, db: XMLDB):
        self.db = db

    # ── Parsing ────────────────────────────────────────────────────────────

    def parse(self, source: str, name: str = None,
              from_file: bool = False) -> XMLDocument:
        """Parse XML/RSS/Atom from string or file, store in DB."""
        if from_file:
            with open(source) as f:
                content = f.read()
        else:
            content = source

        try:
            root = ET.fromstring(content)
        except ET.ParseError as e:
            raise ValueError(f"XML parse error: {e}")

        namespaces = self._extract_namespaces(content)
        element_count = sum(1 for _ in root.iter())
        depth = self._max_depth(root)
        doc_type = self._detect_type(root)
        content_hash = hashlib.sha256(content.encode()).hexdigest()[:16]

        doc_name = name or (os.path.basename(source) if from_file else f"doc_{content_hash[:8]}")
        doc = XMLDocument(
            id=str(uuid.uuid4()), name=doc_name, source=source[:200],
            doc_type=doc_type, content_hash=content_hash,
            element_count=element_count, depth=depth, namespaces=namespaces
        )
        self.db.conn.execute(
            "INSERT INTO documents VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            (doc.id, doc.name, doc.source, doc.doc_type, doc.content_hash,
             content, doc.element_count, doc.depth,
             json.dumps(doc.namespaces), json.dumps(doc.metadata), doc.created_at)
        )
        self.db.conn.commit()
        return doc

    def _detect_type(self, root: Element) -> str:
        tag = root.tag.lower()
        if "rss" in tag:
            return "rss"
        if "feed" in tag:
            return "atom"
        if "html" in tag:
            return "html"
        return "xml"

    def _extract_namespaces(self, content: str) -> Dict[str, str]:
        ns = {}
        for match in re.finditer(r'xmlns(?::(\w+))?="([^"]+)"', content):
            prefix = match.group(1) or "default"
            uri = match.group(2)
            ns[prefix] = uri
        return ns

    def _max_depth(self, element: Element, current: int = 0) -> int:
        if not list(element):
            return current
        return max(self._max_depth(child, current + 1) for child in element)

    def _element_to_dict(self, element: Element) -> Dict[str, Any]:
        result: Dict[str, Any] = {
            "tag": element.tag,
            "text": (element.text or "").strip() or None,
            "attribs": dict(element.attrib),
        }
        children = [self._element_to_dict(child) for child in element]
        if children:
            result["children"] = children
        return result

    # ── XPath queries ──────────────────────────────────────────────────────

    def xpath_query(self, doc_id: str, query: str) -> XPathResult:
        """Execute XPath-like query using ElementTree findall."""
        row = self.db.conn.execute(
            "SELECT content FROM documents WHERE id=?", (doc_id,)
        ).fetchone()
        if not row:
            raise ValueError(f"Document {doc_id} not found")

        root = ET.fromstring(row["content"])
        try:
            elements = root.findall(query)
        except ET.ParseError as e:
            raise ValueError(f"XPath syntax error: {e}")

        matches = []
        for el in elements:
            matches.append({
                "tag": el.tag,
                "text": (el.text or "").strip(),
                "attribs": dict(el.attrib),
                "child_count": len(list(el)),
            })

        result = XPathResult(
            query=query, document_id=doc_id,
            matches=matches, match_count=len(matches)
        )
        self.db.conn.execute(
            "INSERT INTO xpath_history VALUES (?,?,?,?,?,?)",
            (str(uuid.uuid4()), doc_id, query, len(matches),
             json.dumps(matches[:50]), result.executed_at)
        )
        self.db.conn.commit()
        return result

    # ── Schema validation ──────────────────────────────────────────────────

    def add_schema_rule(self, name: str, rule_type: str, path: str,
                        constraint: str, required: bool = True,
                        description: str = "") -> SchemaRule:
        rule = SchemaRule(
            id=str(uuid.uuid4()), name=name, rule_type=rule_type,
            path=path, constraint=constraint, required=required,
            description=description
        )
        self.db.conn.execute(
            "INSERT INTO schema_rules VALUES (?,?,?,?,?,?,?,?)",
            (rule.id, rule.name, rule.rule_type, rule.path,
             rule.constraint, int(rule.required), rule.description, rule.created_at)
        )
        self.db.conn.commit()
        return rule

    def validate_schema(self, doc_id: str, schema_name: str = None) -> Dict[str, Any]:
        """Validate document against schema rules."""
        doc_row = self.db.conn.execute(
            "SELECT * FROM documents WHERE id=?", (doc_id,)
        ).fetchone()
        if not doc_row:
            return {"valid": False, "error": "document not found"}

        query = "SELECT * FROM schema_rules"
        params = ()
        if schema_name:
            query += " WHERE name=?"
            params = (schema_name,)
        rules = self.db.conn.execute(query, params).fetchall()

        root = ET.fromstring(doc_row["content"])
        violations = []
        warnings = []
        passed = 0

        for rule in rules:
            rule_type = rule["rule_type"]
            path = rule["path"]
            constraint = rule["constraint_val"]
            required = bool(rule["required"])

            if rule_type == "required_element":
                elements = root.findall(path)
                if not elements:
                    (violations if required else warnings).append({
                        "rule": rule["name"],
                        "type": rule_type,
                        "path": path,
                        "message": f"Required element '{path}' not found"
                    })
                else:
                    passed += 1

            elif rule_type == "attribute_required":
                parts = path.rsplit("@", 1)
                if len(parts) == 2:
                    elem_path, attr = parts
                    elements = root.findall(elem_path.rstrip("/")) if elem_path else [root]
                    for el in elements:
                        if attr not in el.attrib:
                            (violations if required else warnings).append({
                                "rule": rule["name"],
                                "type": rule_type,
                                "path": path,
                                "message": f"Attribute '{attr}' missing on {el.tag}"
                            })
                        else:
                            passed += 1

            elif rule_type == "text_pattern":
                elements = root.findall(path)
                for el in elements:
                    text = (el.text or "").strip()
                    if not re.match(constraint, text):
                        violations.append({
                            "rule": rule["name"],
                            "type": rule_type,
                            "path": path,
                            "message": f"Text '{text}' does not match pattern '{constraint}'"
                        })
                    else:
                        passed += 1

            elif rule_type == "max_occurrences":
                elements = root.findall(path)
                max_count = int(constraint)
                if len(elements) > max_count:
                    violations.append({
                        "rule": rule["name"],
                        "type": rule_type,
                        "path": path,
                        "message": f"Element '{path}' occurs {len(elements)} times, max is {max_count}"
                    })
                else:
                    passed += 1

        return {
            "valid": len(violations) == 0,
            "violations": violations,
            "warnings": warnings,
            "rules_checked": len(rules),
            "rules_passed": passed,
            "document": doc_row["name"],
        }

    # ── Transform to JSON ──────────────────────────────────────────────────

    def transform_to_json(self, doc_id: str, flatten: bool = False,
                           include_attrs: bool = True) -> TransformResult:
        row = self.db.conn.execute(
            "SELECT content, doc_type FROM documents WHERE id=?", (doc_id,)
        ).fetchone()
        if not row:
            raise ValueError("Document not found")

        root = ET.fromstring(row["content"])
        doc_type = row["doc_type"]

        if doc_type == "rss":
            result_data = self._transform_rss(root)
        elif doc_type == "atom":
            result_data = self._transform_atom(root)
        else:
            result_data = self._element_to_dict(root) if include_attrs else self._flatten_element(root)

        if flatten and doc_type == "xml":
            result_data = self._flatten_doc(root)

        rules_applied = 3 if doc_type in ("rss", "atom") else 1
        result = TransformResult(
            document_id=doc_id, format_out="json",
            content=result_data, rules_applied=rules_applied
        )
        self.db.conn.execute(
            "INSERT INTO transforms VALUES (?,?,?,?,?,?)",
            (str(uuid.uuid4()), doc_id, "json",
             json.dumps(result_data), rules_applied, result.created_at)
        )
        self.db.conn.commit()
        return result

    def _transform_rss(self, root: Element) -> Dict:
        channel = root.find("channel") or root
        items = []
        for item in channel.findall("item"):
            items.append({
                "title": (item.findtext("title") or "").strip(),
                "link": (item.findtext("link") or "").strip(),
                "description": (item.findtext("description") or "").strip(),
                "pubDate": (item.findtext("pubDate") or "").strip(),
                "guid": (item.findtext("guid") or "").strip(),
            })
        return {
            "type": "rss",
            "title": (channel.findtext("title") or "").strip(),
            "link": (channel.findtext("link") or "").strip(),
            "description": (channel.findtext("description") or "").strip(),
            "items": items,
            "item_count": len(items),
        }

    def _transform_atom(self, root: Element) -> Dict:
        ns = {"atom": "http://www.w3.org/2005/Atom"}
        entries = []
        for entry in root.findall("{http://www.w3.org/2005/Atom}entry"):
            title_el = entry.find("{http://www.w3.org/2005/Atom}title")
            link_el = entry.find("{http://www.w3.org/2005/Atom}link")
            entries.append({
                "title": title_el.text if title_el is not None else "",
                "link": link_el.get("href", "") if link_el is not None else "",
                "updated": (entry.findtext("{http://www.w3.org/2005/Atom}updated") or ""),
                "summary": (entry.findtext("{http://www.w3.org/2005/Atom}summary") or ""),
            })
        title_el = root.find("{http://www.w3.org/2005/Atom}title")
        return {
            "type": "atom",
            "title": title_el.text if title_el is not None else "",
            "entries": entries,
            "entry_count": len(entries),
        }

    def _flatten_element(self, element: Element, prefix: str = "") -> Dict:
        result: Dict[str, Any] = {}
        key = f"{prefix}/{element.tag}" if prefix else element.tag
        if element.text and element.text.strip():
            result[key] = element.text.strip()
        for child in element:
            result.update(self._flatten_element(child, key))
        return result

    def _flatten_doc(self, root: Element) -> List[Dict]:
        rows = []
        for el in root.iter():
            if el.text and el.text.strip():
                rows.append({
                    "tag": el.tag,
                    "text": el.text.strip(),
                    "attribs": dict(el.attrib),
                })
        return rows

    # ── Diff two documents ─────────────────────────────────────────────────

    def diff_documents(self, doc_a_id: str, doc_b_id: str) -> DiffResult:
        def get_content(doc_id: str) -> str:
            row = self.db.conn.execute(
                "SELECT content FROM documents WHERE id=?", (doc_id,)
            ).fetchone()
            if not row:
                raise ValueError(f"Document {doc_id} not found")
            return row["content"]

        root_a = ET.fromstring(get_content(doc_a_id))
        root_b = ET.fromstring(get_content(doc_b_id))

        def element_signature(el: Element, path: str = "") -> Dict[str, Any]:
            current_path = f"{path}/{el.tag}" if path else el.tag
            return {
                "path": current_path,
                "tag": el.tag,
                "text": (el.text or "").strip(),
                "attribs": dict(el.attrib),
            }

        def flatten_tree(root: Element) -> Dict[str, Dict]:
            result = {}
            counter: Dict[str, int] = {}

            def recurse(el: Element, path: str = ""):
                tag_path = f"{path}/{el.tag}" if path else el.tag
                counter[tag_path] = counter.get(tag_path, 0) + 1
                key = f"{tag_path}[{counter[tag_path]}]"
                result[key] = {
                    "tag": el.tag,
                    "text": (el.text or "").strip(),
                    "attribs": dict(el.attrib),
                }
                for child in el:
                    recurse(child, tag_path)

            recurse(root)
            return result

        tree_a = flatten_tree(root_a)
        tree_b = flatten_tree(root_b)
        keys_a = set(tree_a.keys())
        keys_b = set(tree_b.keys())

        added = [{"path": k, **tree_b[k]} for k in keys_b - keys_a]
        removed = [{"path": k, **tree_a[k]} for k in keys_a - keys_b]
        modified = []
        unchanged = 0

        for key in keys_a & keys_b:
            a, b = tree_a[key], tree_b[key]
            if a["text"] != b["text"] or a["attribs"] != b["attribs"]:
                modified.append({
                    "path": key,
                    "before": {"text": a["text"], "attribs": a["attribs"]},
                    "after": {"text": b["text"], "attribs": b["attribs"]},
                })
            else:
                unchanged += 1

        return DiffResult(
            doc_a_id=doc_a_id, doc_b_id=doc_b_id,
            added=added, removed=removed,
            modified=modified, unchanged_count=unchanged
        )

    def list_documents(self) -> List[Dict]:
        rows = self.db.conn.execute(
            "SELECT id, name, doc_type, element_count, depth, content_hash, created_at "
            "FROM documents ORDER BY created_at DESC"
        ).fetchall()
        return [dict(r) for r in rows]


# ── CLI ───────────────────────────────────────────────────────────────────────

def _banner():
    print(f"\n{BOLD}{GREEN}╔══════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{GREEN}║   BlackRoad XML Parser  v1.0.0           ║{RESET}")
    print(f"{BOLD}{GREEN}╚══════════════════════════════════════════╝{RESET}\n")


def _get_parser() -> XMLParser:
    return XMLParser(XMLDB())


def cmd_parse(args):
    p = _get_parser()
    try:
        doc = p.parse(args.source, args.name, from_file=args.file)
    except (ValueError, FileNotFoundError) as e:
        print(f"{RED}✗ Parse error: {e}{RESET}")
        sys.exit(1)
    print(f"{GREEN}✓ Document parsed{RESET}")
    print(f"  {DIM}ID:{RESET}       {CYAN}{doc.id[:12]}…{RESET}")
    print(f"  {DIM}Name:{RESET}     {doc.name}")
    print(f"  {DIM}Type:{RESET}     {doc.doc_type}")
    print(f"  {DIM}Elements:{RESET} {doc.element_count}")
    print(f"  {DIM}Depth:{RESET}    {doc.depth}")
    print(f"  {DIM}Hash:{RESET}     {doc.content_hash}")
    if doc.namespaces:
        print(f"  {DIM}Namespaces:{RESET} {json.dumps(doc.namespaces)}")


def cmd_validate(args):
    p = _get_parser()
    row = p.db.conn.execute("SELECT id FROM documents WHERE name=?", (args.document,)).fetchone()
    if not row:
        print(f"{RED}✗ Document '{args.document}' not found{RESET}")
        sys.exit(1)
    result = p.validate_schema(row["id"], args.schema)
    icon = f"{GREEN}✓ VALID{RESET}" if result["valid"] else f"{RED}✗ INVALID{RESET}"
    print(f"\n{BOLD}Schema Validation — {args.document}: {icon}{RESET}")
    print(f"  Rules checked: {result['rules_checked']}  Passed: {result['rules_passed']}")
    for v in result.get("violations", []):
        print(f"  {RED}✗ [{v['type']}] {v['message']}{RESET}")
    for w in result.get("warnings", []):
        print(f"  {YELLOW}⚠ [{w['type']}] {w['message']}{RESET}")
    if not result["valid"]:
        sys.exit(1)


def cmd_xpath(args):
    p = _get_parser()
    row = p.db.conn.execute("SELECT id FROM documents WHERE name=?", (args.document,)).fetchone()
    if not row:
        print(f"{RED}✗ Document not found{RESET}")
        sys.exit(1)
    try:
        result = p.xpath_query(row["id"], args.query)
    except ValueError as e:
        print(f"{RED}✗ XPath error: {e}{RESET}")
        sys.exit(1)
    print(f"\n{BOLD}XPath Results — {result.match_count} match(es){RESET}")
    print(f"  Query: {CYAN}{args.query}{RESET}")
    for i, m in enumerate(result.matches[:args.limit], 1):
        attrs = f" {DIM}{m['attribs']}{RESET}" if m["attribs"] else ""
        text = f"  {YELLOW}{m['text'][:60]}{RESET}" if m["text"] else ""
        print(f"  {i:>3}. {BOLD}<{m['tag']}>{RESET}{attrs}{text}")


def cmd_transform(args):
    p = _get_parser()
    row = p.db.conn.execute("SELECT id FROM documents WHERE name=?", (args.document,)).fetchone()
    if not row:
        print(f"{RED}✗ Document not found{RESET}")
        sys.exit(1)
    result = p.transform_to_json(row["id"], args.flatten, not args.no_attrs)
    output = json.dumps(result.content, indent=2)
    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"{GREEN}✓ Transformed to JSON → {args.output}{RESET}")
        print(f"  Rules applied: {result.rules_applied}")
    else:
        print(output)


def cmd_diff(args):
    p = _get_parser()
    row_a = p.db.conn.execute("SELECT id FROM documents WHERE name=?", (args.doc_a,)).fetchone()
    row_b = p.db.conn.execute("SELECT id FROM documents WHERE name=?", (args.doc_b,)).fetchone()
    if not row_a or not row_b:
        print(f"{RED}✗ One or both documents not found{RESET}")
        sys.exit(1)
    result = p.diff_documents(row_a["id"], row_b["id"])
    print(f"\n{BOLD}Diff: {args.doc_a} ↔ {args.doc_b}{RESET}")
    print(f"  {GREEN}+{len(result.added)} added{RESET}  "
          f"{RED}-{len(result.removed)} removed{RESET}  "
          f"{YELLOW}~{len(result.modified)} modified{RESET}  "
          f"{DIM}{result.unchanged_count} unchanged{RESET}")
    if args.verbose:
        for item in result.added[:10]:
            print(f"  {GREEN}+ {item['path']}: {item.get('text','')[:40]}{RESET}")
        for item in result.removed[:10]:
            print(f"  {RED}- {item['path']}: {item.get('text','')[:40]}{RESET}")
        for item in result.modified[:10]:
            before = item["before"]["text"][:20]
            after = item["after"]["text"][:20]
            print(f"  {YELLOW}~ {item['path']}: '{before}' → '{after}'{RESET}")


def cmd_list(args):
    p = _get_parser()
    docs = p.list_documents()
    print(f"\n{BOLD}Documents ({len(docs)}){RESET}")
    print(f"  {'Name':<25} {'Type':<8} {'Elements':>9} {'Depth':>6}  {'Hash':<16}  Created")
    print(f"  {'─'*25} {'─'*8} {'─'*9} {'─'*6}  {'─'*16}  {'─'*10}")
    for d in docs:
        print(f"  {CYAN}{d['name']:<25}{RESET} {d['doc_type']:<8} "
              f"{d['element_count']:>9} {d['depth']:>6}  "
              f"{DIM}{d['content_hash']:<16}{RESET}  {d['created_at'][:10]}")


def main():
    _banner()
    parser = argparse.ArgumentParser(prog="xml-parser", description="BlackRoad XML Parser")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("parse", help="Parse an XML/RSS/Atom document")
    p.add_argument("source", help="XML string or file path")
    p.add_argument("--name", default=None)
    p.add_argument("--file", action="store_true", help="Source is a file path")

    p = sub.add_parser("validate", help="Validate document against schema rules")
    p.add_argument("document")
    p.add_argument("--schema", default=None)

    p = sub.add_parser("xpath", help="Execute XPath query")
    p.add_argument("document")
    p.add_argument("query")
    p.add_argument("--limit", type=int, default=20)

    p = sub.add_parser("transform", help="Transform XML to JSON")
    p.add_argument("document")
    p.add_argument("--output", "-o", default=None)
    p.add_argument("--flatten", action="store_true")
    p.add_argument("--no-attrs", action="store_true")

    p = sub.add_parser("diff", help="Diff two XML documents")
    p.add_argument("doc_a")
    p.add_argument("doc_b")
    p.add_argument("--verbose", "-v", action="store_true")

    sub.add_parser("list", help="List parsed documents")

    args = parser.parse_args()
    cmds = {
        "parse": cmd_parse, "validate": cmd_validate,
        "xpath": cmd_xpath, "transform": cmd_transform,
        "diff": cmd_diff, "list": cmd_list,
    }
    cmds[args.command](args)


if __name__ == "__main__":
    main()
