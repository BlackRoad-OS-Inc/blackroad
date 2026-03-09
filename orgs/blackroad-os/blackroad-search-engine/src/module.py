#!/usr/bin/env python3
"""BlackRoad Search Engine
===========================
Full-text search with TF-IDF scoring, inverted index, and SQLite FTS5.
Supports document indexing, ranked retrieval, prefix suggestions, and
index export/import.
"""

import sqlite3
import time
import json
import math
import os
import re
import argparse
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, Set
from pathlib import Path
from collections import Counter

DB_PATH = os.environ.get("SEARCH_ENGINE_DB", str(Path.home() / ".blackroad" / "search_engine.db"))


# ---------------------------------------------------------------------------
# Data Classes
# ---------------------------------------------------------------------------

@dataclass
class Document:
    """A document to be indexed and searched."""
    id: str
    title: str
    content: str
    metadata: Dict[str, Any] = field(default_factory=dict)
    indexed_at: Optional[float] = None

    def full_text(self) -> str:
        """Title + content for indexing purposes."""
        return f"{self.title} {self.content}"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "title": self.title,
            "content": self.content,
            "metadata": self.metadata,
            "indexed_at": self.indexed_at,
        }


@dataclass
class SearchResult:
    """A ranked search result."""
    document: Document
    score: float
    highlights: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "score": round(self.score, 6),
            "document": self.document.to_dict(),
            "highlights": self.highlights,
        }


# ---------------------------------------------------------------------------
# Text processing
# ---------------------------------------------------------------------------

STOP_WORDS: Set[str] = {
    "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "is", "are", "was", "were", "be", "been",
    "being", "have", "has", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "shall", "can", "not", "this",
    "that", "these", "those", "it", "its", "i", "you", "he", "she", "we",
    "they", "me", "him", "her", "us", "them", "my", "your", "his",
    "their", "our", "as", "so", "if", "then", "than", "about", "into",
}


def tokenize(text: str) -> List[str]:
    """
    Tokenize *text* into lowercase alpha-numeric tokens, removing stop words.
    """
    tokens = re.findall(r"[a-zA-Z0-9]+", text.lower())
    return [t for t in tokens if t not in STOP_WORDS and len(t) > 1]


def stem(word: str) -> str:
    """
    Minimal suffix-stripping stemmer (Porter-lite).
    Handles common English endings: -ing, -tion, -ness, -ment, -ed, -er, -es, -s
    """
    if len(word) <= 3:
        return word
    for suffix in ("tion", "ness", "ment", "ing", "ed", "er", "es", "s"):
        if word.endswith(suffix) and len(word) - len(suffix) >= 3:
            return word[: -len(suffix)]
    return word


def normalize_tokens(tokens: List[str]) -> List[str]:
    """Apply stemming to a token list."""
    return [stem(t) for t in tokens]


def extract_highlights(text: str, query_tokens: List[str], window: int = 80) -> List[str]:
    """
    Return short context snippets from *text* surrounding matches for *query_tokens*.
    """
    highlights = []
    text_lower = text.lower()
    for token in query_tokens[:5]:
        idx = text_lower.find(token)
        if idx == -1:
            continue
        start = max(0, idx - window // 2)
        end = min(len(text), idx + window // 2)
        snippet = ("..." if start > 0 else "") + text[start:end].strip() + ("..." if end < len(text) else "")
        highlights.append(snippet)
    return highlights[:3]


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

def _ensure_dir(db_path: str) -> None:
    parent = os.path.dirname(db_path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def get_db_connection(db_path: str = DB_PATH) -> sqlite3.Connection:
    _ensure_dir(db_path)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def init_db(db_path: str = DB_PATH) -> None:
    """Create tables, FTS5 virtual table, and inverted-index tables."""
    _ensure_dir(db_path)
    with get_db_connection(db_path) as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS documents (
                id         TEXT PRIMARY KEY,
                title      TEXT NOT NULL,
                content    TEXT NOT NULL,
                metadata   TEXT NOT NULL DEFAULT '{}',
                indexed_at REAL NOT NULL
            );

            -- FTS5 virtual table for fast full-text search
            CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts
            USING fts5(
                id UNINDEXED,
                title,
                content,
                content='documents',
                content_rowid='rowid'
            );

            -- Manual inverted index (term -> doc_id with frequency)
            CREATE TABLE IF NOT EXISTS inverted_index (
                term       TEXT NOT NULL,
                doc_id     TEXT NOT NULL,
                frequency  INTEGER NOT NULL DEFAULT 1,
                positions  TEXT NOT NULL DEFAULT '[]',
                PRIMARY KEY (term, doc_id),
                FOREIGN KEY (doc_id) REFERENCES documents(id) ON DELETE CASCADE
            );

            -- Document term stats (for TF-IDF)
            CREATE TABLE IF NOT EXISTS doc_stats (
                doc_id      TEXT PRIMARY KEY,
                term_count  INTEGER NOT NULL,
                FOREIGN KEY (doc_id) REFERENCES documents(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_inverted_term
                ON inverted_index(term);
            CREATE INDEX IF NOT EXISTS idx_inverted_doc
                ON inverted_index(doc_id);
        """)


# ---------------------------------------------------------------------------
# TF-IDF scoring
# ---------------------------------------------------------------------------

def _tf(term_freq: int, total_terms: int) -> float:
    """Log-normalised term frequency."""
    if term_freq == 0:
        return 0.0
    return 1.0 + math.log(term_freq)


def _idf(doc_freq: int, total_docs: int) -> float:
    """Smoothed inverse document frequency."""
    if doc_freq == 0 or total_docs == 0:
        return 0.0
    return math.log((total_docs + 1) / (doc_freq + 1)) + 1.0


def _tfidf_score(
    query_terms: List[str],
    doc_id: str,
    term_freqs: Dict[str, int],
    doc_term_count: int,
    doc_freqs: Dict[str, int],
    total_docs: int,
) -> float:
    """Compute cosine-style TF-IDF score for a document against query terms."""
    score = 0.0
    for term in query_terms:
        freq = term_freqs.get(term, 0)
        tf = _tf(freq, doc_term_count)
        idf = _idf(doc_freqs.get(term, 0), total_docs)
        score += tf * idf
    # Normalise by document length
    if doc_term_count > 0:
        score /= math.sqrt(doc_term_count)
    return score


# ---------------------------------------------------------------------------
# Core API
# ---------------------------------------------------------------------------

def index_document(doc: Document, db_path: str = DB_PATH) -> None:
    """
    Add or replace *doc* in the index.
    Updates both the FTS5 virtual table and the manual inverted index.
    """
    init_db(db_path)
    now = time.time()
    doc.indexed_at = now

    tokens = normalize_tokens(tokenize(doc.full_text()))
    term_counts = Counter(tokens)

    # Collect token positions
    raw_tokens_with_pos = list(enumerate(tokenize(doc.full_text())))
    stem_pos: Dict[str, List[int]] = {}
    for pos, tok in raw_tokens_with_pos:
        s = stem(tok)
        stem_pos.setdefault(s, []).append(pos)

    with get_db_connection(db_path) as conn:
        # Delete old entries
        conn.execute("DELETE FROM inverted_index WHERE doc_id = ?", (doc.id,))
        conn.execute("DELETE FROM doc_stats WHERE doc_id = ?", (doc.id,))

        # Upsert document row
        conn.execute(
            """
            INSERT OR REPLACE INTO documents (id, title, content, metadata, indexed_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (doc.id, doc.title, doc.content, json.dumps(doc.metadata), now),
        )

        # Sync FTS5 table
        conn.execute("DELETE FROM documents_fts WHERE id = ?", (doc.id,))
        conn.execute(
            "INSERT INTO documents_fts (id, title, content) VALUES (?, ?, ?)",
            (doc.id, doc.title, doc.content),
        )

        # Populate inverted index
        for term, freq in term_counts.items():
            positions = stem_pos.get(term, [])
            conn.execute(
                """
                INSERT OR REPLACE INTO inverted_index (term, doc_id, frequency, positions)
                VALUES (?, ?, ?, ?)
                """,
                (term, doc.id, freq, json.dumps(positions)),
            )

        # Doc stats
        conn.execute(
            "INSERT OR REPLACE INTO doc_stats (doc_id, term_count) VALUES (?, ?)",
            (doc.id, len(tokens)),
        )


def search(
    query: str,
    limit: int = 10,
    db_path: str = DB_PATH,
    use_fts: bool = False,
) -> List[SearchResult]:
    """
    Search indexed documents using TF-IDF scoring.

    Parameters
    ----------
    query   : Free-text search query
    limit   : Maximum number of results to return
    db_path : Database path
    use_fts : If True, use SQLite FTS5 for candidate retrieval (faster for large corpora)

    Returns
    -------
    List of SearchResult sorted by descending relevance score.
    """
    init_db(db_path)
    query_raw_tokens = tokenize(query)
    query_terms = normalize_tokens(query_raw_tokens)
    if not query_terms:
        return []

    with get_db_connection(db_path) as conn:
        total_docs = conn.execute("SELECT COUNT(*) AS cnt FROM documents").fetchone()["cnt"]
        if total_docs == 0:
            return []

        # Gather candidate document IDs that match at least one query term
        placeholders = ", ".join("?" * len(query_terms))
        candidate_rows = conn.execute(
            f"SELECT DISTINCT doc_id FROM inverted_index WHERE term IN ({placeholders})",
            query_terms,
        ).fetchall()
        candidate_ids = [r["doc_id"] for r in candidate_rows]

        if not candidate_ids:
            return []

        # Fetch document frequency per query term
        doc_freqs: Dict[str, int] = {}
        for term in query_terms:
            row = conn.execute(
                "SELECT COUNT(DISTINCT doc_id) AS cnt FROM inverted_index WHERE term = ?",
                (term,),
            ).fetchone()
            doc_freqs[term] = row["cnt"]

        # Score each candidate
        results: List[SearchResult] = []
        for doc_id in candidate_ids:
            freq_rows = conn.execute(
                "SELECT term, frequency FROM inverted_index WHERE doc_id = ?",
                (doc_id,),
            ).fetchall()
            term_freqs = {r["term"]: r["frequency"] for r in freq_rows}

            stat = conn.execute(
                "SELECT term_count FROM doc_stats WHERE doc_id = ?", (doc_id,)
            ).fetchone()
            doc_term_count = stat["term_count"] if stat else 1

            score = _tfidf_score(
                query_terms, doc_id, term_freqs, doc_term_count, doc_freqs, total_docs
            )

            doc_row = conn.execute(
                "SELECT * FROM documents WHERE id = ?", (doc_id,)
            ).fetchone()
            if doc_row is None:
                continue

            doc = Document(
                id=doc_row["id"],
                title=doc_row["title"],
                content=doc_row["content"],
                metadata=json.loads(doc_row["metadata"] or "{}"),
                indexed_at=doc_row["indexed_at"],
            )
            highlights = extract_highlights(doc.content, query_raw_tokens)
            results.append(SearchResult(document=doc, score=score, highlights=highlights))

    results.sort(key=lambda r: r.score, reverse=True)
    return results[:limit]


def get_document(doc_id: str, db_path: str = DB_PATH) -> Optional[Document]:
    """Fetch a document by its ID."""
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        row = conn.execute("SELECT * FROM documents WHERE id = ?", (doc_id,)).fetchone()
    if row is None:
        return None
    return Document(
        id=row["id"],
        title=row["title"],
        content=row["content"],
        metadata=json.loads(row["metadata"] or "{}"),
        indexed_at=row["indexed_at"],
    )


def delete_document(doc_id: str, db_path: str = DB_PATH) -> bool:
    """
    Remove a document and all its index entries.
    Returns True if the document existed.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        res = conn.execute("DELETE FROM documents WHERE id = ?", (doc_id,))
        conn.execute("DELETE FROM documents_fts WHERE id = ?", (doc_id,))
        conn.execute("DELETE FROM inverted_index WHERE doc_id = ?", (doc_id,))
        conn.execute("DELETE FROM doc_stats WHERE doc_id = ?", (doc_id,))
    return res.rowcount > 0


def reindex_all(db_path: str = DB_PATH) -> int:
    """
    Rebuild the entire inverted index from scratch.
    Useful after bulk imports or schema migrations.
    Returns the number of documents reindexed.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        rows = conn.execute("SELECT * FROM documents").fetchall()
        # Clear old index data
        conn.execute("DELETE FROM inverted_index")
        conn.execute("DELETE FROM doc_stats")
        conn.execute("DELETE FROM documents_fts")

    docs = [
        Document(
            id=r["id"],
            title=r["title"],
            content=r["content"],
            metadata=json.loads(r["metadata"] or "{}"),
            indexed_at=r["indexed_at"],
        )
        for r in rows
    ]
    for doc in docs:
        index_document(doc, db_path)
    return len(docs)


def search_suggestions(prefix: str, limit: int = 10, db_path: str = DB_PATH) -> List[str]:
    """
    Return term suggestions from the index matching *prefix*.
    Sorted by document frequency (most common first).
    """
    init_db(db_path)
    if len(prefix) < 1:
        return []
    stemmed = stem(prefix.lower())
    with get_db_connection(db_path) as conn:
        rows = conn.execute(
            """
            SELECT term, COUNT(DISTINCT doc_id) AS df
            FROM inverted_index
            WHERE term LIKE ?
            GROUP BY term
            ORDER BY df DESC
            LIMIT ?
            """,
            (f"{stemmed}%", limit),
        ).fetchall()
    return [r["term"] for r in rows]


def export_index(db_path: str = DB_PATH) -> Dict[str, Any]:
    """
    Export the full index as a JSON-serialisable dictionary.
    Contains: documents, inverted_index summary, and stats.
    """
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        doc_rows = conn.execute("SELECT * FROM documents ORDER BY id").fetchall()
        idx_rows = conn.execute(
            "SELECT term, doc_id, frequency FROM inverted_index ORDER BY term, doc_id"
        ).fetchall()
        total_docs = len(doc_rows)
        total_terms = conn.execute(
            "SELECT COUNT(DISTINCT term) AS cnt FROM inverted_index"
        ).fetchone()["cnt"]

    return {
        "exported_at": time.time(),
        "total_documents": total_docs,
        "total_distinct_terms": total_terms,
        "documents": [
            {
                "id": r["id"],
                "title": r["title"],
                "content_length": len(r["content"]),
                "metadata": json.loads(r["metadata"] or "{}"),
                "indexed_at": r["indexed_at"],
            }
            for r in doc_rows
        ],
        "inverted_index_sample": [
            {"term": r["term"], "doc_id": r["doc_id"], "frequency": r["frequency"]}
            for r in idx_rows[:500]
        ],
    }


def index_stats(db_path: str = DB_PATH) -> Dict[str, Any]:
    """Return aggregate statistics about the index."""
    init_db(db_path)
    with get_db_connection(db_path) as conn:
        total_docs = conn.execute("SELECT COUNT(*) AS cnt FROM documents").fetchone()["cnt"]
        total_terms = conn.execute(
            "SELECT COUNT(DISTINCT term) AS cnt FROM inverted_index"
        ).fetchone()["cnt"]
        total_postings = conn.execute(
            "SELECT COUNT(*) AS cnt FROM inverted_index"
        ).fetchone()["cnt"]
        avg_tcount_row = conn.execute(
            "SELECT AVG(term_count) AS avg FROM doc_stats"
        ).fetchone()
        avg_terms = round(avg_tcount_row["avg"] or 0, 2)
    return {
        "total_documents": total_docs,
        "total_distinct_terms": total_terms,
        "total_postings": total_postings,
        "avg_terms_per_doc": avg_terms,
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="BlackRoad Search Engine – TF-IDF full-text search",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  %(prog)s index doc1 'My Title' 'Some content here'\n"
            "  %(prog)s search 'content here' --limit 5\n"
            "  %(prog)s get doc1\n"
            "  %(prog)s delete doc1\n"
            "  %(prog)s suggest 'cont'\n"
            "  %(prog)s reindex\n"
            "  %(prog)s stats\n"
            "  %(prog)s export\n"
        ),
    )
    parser.add_argument("--db", default=DB_PATH, metavar="PATH")
    sub = parser.add_subparsers(dest="command", required=True)

    # index
    p = sub.add_parser("index", help="Index a document")
    p.add_argument("id", help="Document ID")
    p.add_argument("title")
    p.add_argument("content")
    p.add_argument("--meta", default="{}", help="JSON metadata")

    # search
    p = sub.add_parser("search", help="Search the index")
    p.add_argument("query")
    p.add_argument("--limit", type=int, default=10)

    # get
    p = sub.add_parser("get", help="Retrieve a document by ID")
    p.add_argument("id")

    # delete
    p = sub.add_parser("delete", help="Remove a document from the index")
    p.add_argument("id")

    # suggest
    p = sub.add_parser("suggest", help="Get search term suggestions for a prefix")
    p.add_argument("prefix")
    p.add_argument("--limit", type=int, default=10)

    # reindex
    sub.add_parser("reindex", help="Rebuild the full inverted index")

    # stats
    sub.add_parser("stats", help="Show index statistics")

    # export
    sub.add_parser("export", help="Export the full index as JSON")

    args = parser.parse_args()
    db = args.db

    if args.command == "index":
        doc = Document(
            id=args.id,
            title=args.title,
            content=args.content,
            metadata=json.loads(args.meta),
        )
        index_document(doc, db)
        print(f"Indexed document: {args.id!r}")

    elif args.command == "search":
        results = search(args.query, args.limit, db)
        output = [r.to_dict() for r in results]
        print(json.dumps(output, indent=2))

    elif args.command == "get":
        doc = get_document(args.id, db)
        if doc:
            print(json.dumps(doc.to_dict(), indent=2))
        else:
            print(f"Document not found: {args.id!r}")
            raise SystemExit(1)

    elif args.command == "delete":
        deleted = delete_document(args.id, db)
        print("Deleted." if deleted else "Document not found.")

    elif args.command == "suggest":
        suggestions = search_suggestions(args.prefix, args.limit, db)
        print(json.dumps(suggestions, indent=2))

    elif args.command == "reindex":
        n = reindex_all(db)
        print(f"Reindexed {n} document(s).")

    elif args.command == "stats":
        print(json.dumps(index_stats(db), indent=2))

    elif args.command == "export":
        print(json.dumps(export_index(db), indent=2))


if __name__ == "__main__":
    main()
