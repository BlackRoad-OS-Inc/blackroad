#!/usr/bin/env python3
"""
blackroad-zip-service: ZIP/Archive utility with SQLite history.
"""

import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import sys
import tarfile
import zipfile
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Callable, Iterator, List, Optional

DB_PATH = Path.home() / ".blackroad" / "zip-service.db"

SUPPORTED_FORMATS = {"zip", "tar", "tar.gz", "tar.bz2", "tar.xz"}


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class ArchiveEntry:
    path: str
    size: int
    compressed_size: Optional[int]
    modified: Optional[str]
    is_dir: bool = False


@dataclass
class ArchiveInfo:
    path: str
    format: str
    size: int
    entry_count: int
    checksum: str
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    history_id: Optional[int] = None


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def get_db(db_path: Path = DB_PATH) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    _init_schema(conn)
    return conn


def _init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS archive_history (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            operation       TEXT    NOT NULL,   -- create, extract, add, verify
            archive_path    TEXT    NOT NULL,
            format          TEXT,
            file_count      INTEGER DEFAULT 0,
            archive_size    INTEGER DEFAULT 0,
            checksum        TEXT,
            status          TEXT    NOT NULL DEFAULT 'ok',
            error_msg       TEXT,
            created_at      TEXT    NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS archive_entries (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            history_id      INTEGER NOT NULL REFERENCES archive_history(id) ON DELETE CASCADE,
            entry_path      TEXT    NOT NULL,
            entry_size      INTEGER,
            compressed_size INTEGER,
            is_dir          INTEGER DEFAULT 0
        );

        CREATE INDEX IF NOT EXISTS idx_history_path ON archive_history(archive_path);
        CREATE INDEX IF NOT EXISTS idx_history_op   ON archive_history(operation);
    """)
    conn.commit()


def _record_operation(conn: sqlite3.Connection, operation: str, archive_path: str,
                      fmt: Optional[str] = None, file_count: int = 0,
                      archive_size: int = 0, checksum: Optional[str] = None,
                      status: str = "ok", error_msg: Optional[str] = None) -> int:
    cur = conn.execute(
        "INSERT INTO archive_history(operation, archive_path, format, file_count, "
        "archive_size, checksum, status, error_msg) VALUES(?,?,?,?,?,?,?,?)",
        (operation, archive_path, fmt, file_count, archive_size, checksum, status, error_msg),
    )
    conn.commit()
    return cur.lastrowid


# ---------------------------------------------------------------------------
# Format detection
# ---------------------------------------------------------------------------

def detect_format(path: str) -> str:
    p = path.lower()
    if p.endswith(".tar.gz") or p.endswith(".tgz"):
        return "tar.gz"
    if p.endswith(".tar.bz2") or p.endswith(".tbz2"):
        return "tar.bz2"
    if p.endswith(".tar.xz") or p.endswith(".txz"):
        return "tar.xz"
    if p.endswith(".tar"):
        return "tar"
    if p.endswith(".zip"):
        return "zip"
    raise ValueError(f"Cannot detect archive format from path: {path}")


# ---------------------------------------------------------------------------
# Checksum
# ---------------------------------------------------------------------------

def compute_checksum(path: str, algorithm: str = "sha256") -> str:
    h = hashlib.new(algorithm)
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


# ---------------------------------------------------------------------------
# Core operations
# ---------------------------------------------------------------------------

def create_archive(
    files: List[str],
    output: str,
    compression: str = "zip",
    conn: Optional[sqlite3.Connection] = None,
) -> ArchiveInfo:
    """
    Create an archive from a list of file/directory paths.
    compression: zip | tar | tar.gz | tar.bz2 | tar.xz
    """
    if compression not in SUPPORTED_FORMATS:
        raise ValueError(f"Unsupported format: {compression}. Choose from {SUPPORTED_FORMATS}")

    out_path = Path(output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    entry_count = 0

    if compression == "zip":
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for src in files:
                src_path = Path(src)
                if src_path.is_dir():
                    for child in src_path.rglob("*"):
                        arcname = child.relative_to(src_path.parent)
                        zf.write(child, arcname)
                        entry_count += 1
                elif src_path.is_file():
                    zf.write(src, src_path.name)
                    entry_count += 1
                else:
                    raise FileNotFoundError(f"Not found: {src}")
    else:
        mode_map = {
            "tar": "w",
            "tar.gz": "w:gz",
            "tar.bz2": "w:bz2",
            "tar.xz": "w:xz",
        }
        mode = mode_map[compression]
        with tarfile.open(output, mode) as tf:
            for src in files:
                src_path = Path(src)
                if not src_path.exists():
                    raise FileNotFoundError(f"Not found: {src}")
                tf.add(src, arcname=src_path.name)
                entry_count += 1 if src_path.is_file() else sum(1 for _ in src_path.rglob("*"))

    size = os.path.getsize(output)
    checksum = compute_checksum(output)
    info = ArchiveInfo(
        path=output, format=compression, size=size,
        entry_count=entry_count, checksum=checksum,
    )

    if conn:
        info.history_id = _record_operation(
            conn, "create", output, compression, entry_count, size, checksum,
        )
    return info


def extract_archive(
    path: str,
    dest: str,
    conn: Optional[sqlite3.Connection] = None,
) -> List[str]:
    """Extract archive to destination directory. Returns list of extracted paths."""
    dest_path = Path(dest)
    dest_path.mkdir(parents=True, exist_ok=True)
    fmt = detect_format(path)
    extracted = []

    if fmt == "zip":
        with zipfile.ZipFile(path, "r") as zf:
            zf.extractall(dest_path)
            extracted = zf.namelist()
    else:
        with tarfile.open(path, "r:*") as tf:
            tf.extractall(dest_path)
            extracted = tf.getnames()

    if conn:
        size = os.path.getsize(path)
        checksum = compute_checksum(path)
        _record_operation(conn, "extract", path, fmt, len(extracted), size, checksum)

    return extracted


def list_contents(path: str) -> List[ArchiveEntry]:
    """List entries in an archive without extracting."""
    fmt = detect_format(path)
    entries: List[ArchiveEntry] = []

    if fmt == "zip":
        with zipfile.ZipFile(path, "r") as zf:
            for info in zf.infolist():
                entries.append(ArchiveEntry(
                    path=info.filename,
                    size=info.file_size,
                    compressed_size=info.compress_size,
                    modified="{}-{:02d}-{:02d}".format(*info.date_time[:3]),
                    is_dir=info.filename.endswith("/"),
                ))
    else:
        with tarfile.open(path, "r:*") as tf:
            for member in tf.getmembers():
                entries.append(ArchiveEntry(
                    path=member.name,
                    size=member.size,
                    compressed_size=None,
                    modified=datetime.utcfromtimestamp(member.mtime).strftime("%Y-%m-%d"),
                    is_dir=member.isdir(),
                ))
    return entries


def add_to_archive(archive: str, file: str,
                   conn: Optional[sqlite3.Connection] = None) -> ArchiveInfo:
    """Add a file to an existing ZIP archive (tar archives are immutable)."""
    fmt = detect_format(archive)
    if fmt != "zip":
        raise ValueError(f"add_to_archive only supports zip, not {fmt}")
    if not Path(file).exists():
        raise FileNotFoundError(f"File not found: {file}")

    with zipfile.ZipFile(archive, "a", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.write(file, Path(file).name)
        entry_count = len(zf.namelist())

    size = os.path.getsize(archive)
    checksum = compute_checksum(archive)
    info = ArchiveInfo(path=archive, format=fmt, size=size,
                       entry_count=entry_count, checksum=checksum)

    if conn:
        info.history_id = _record_operation(conn, "add", archive, fmt, entry_count, size, checksum)
    return info


def checksum_verify(archive: str, expected: Optional[str] = None,
                    conn: Optional[sqlite3.Connection] = None) -> dict:
    """
    Verify archive integrity:
    1. Try to open and read all entries
    2. Compare checksum if expected is provided
    Returns dict with 'valid', 'checksum', 'error' keys.
    """
    result = {"valid": False, "checksum": None, "error": None, "path": archive}
    try:
        fmt = detect_format(archive)
        # Test archive integrity
        if fmt == "zip":
            with zipfile.ZipFile(archive, "r") as zf:
                bad = zf.testzip()
                if bad:
                    result["error"] = f"Bad file in zip: {bad}"
                    return result
        else:
            with tarfile.open(archive, "r:*") as tf:
                for member in tf.getmembers():
                    if member.isfile():
                        fh = tf.extractfile(member)
                        if fh:
                            while fh.read(65536):
                                pass

        checksum = compute_checksum(archive)
        result["checksum"] = checksum
        if expected:
            result["valid"] = checksum == expected
            if not result["valid"]:
                result["error"] = f"Checksum mismatch: expected {expected}, got {checksum}"
        else:
            result["valid"] = True

    except (zipfile.BadZipFile, tarfile.TarError, OSError) as exc:
        result["error"] = str(exc)

    if conn:
        status = "ok" if result["valid"] else "error"
        _record_operation(conn, "verify", archive, status=status, error_msg=result.get("error"))

    return result


def streaming_extract(
    archive: str,
    handler: Callable[[str, bytes], None],
    conn: Optional[sqlite3.Connection] = None,
) -> int:
    """
    Stream-extract archive calling handler(name, data) for each file entry.
    Returns count of processed entries. Memory-efficient for large archives.
    """
    fmt = detect_format(archive)
    count = 0

    if fmt == "zip":
        with zipfile.ZipFile(archive, "r") as zf:
            for name in zf.namelist():
                info = zf.getinfo(name)
                if not info.is_dir():
                    data = zf.read(name)
                    handler(name, data)
                    count += 1
    else:
        with tarfile.open(archive, "r:*") as tf:
            for member in tf.getmembers():
                if member.isfile():
                    fh = tf.extractfile(member)
                    if fh:
                        data = fh.read()
                        handler(member.name, data)
                        count += 1

    if conn:
        size = os.path.getsize(archive)
        _record_operation(conn, "stream_extract", archive, detect_format(archive), count, size)

    return count


# ---------------------------------------------------------------------------
# History queries
# ---------------------------------------------------------------------------

def get_history(conn: sqlite3.Connection, limit: int = 50) -> list:
    rows = conn.execute(
        "SELECT id, operation, archive_path, format, file_count, archive_size, checksum, "
        "status, error_msg, created_at FROM archive_history ORDER BY created_at DESC LIMIT ?",
        (limit,),
    ).fetchall()
    return [dict(r) for r in rows]


def get_archive_info(archive_path: str, conn: sqlite3.Connection) -> Optional[dict]:
    row = conn.execute(
        "SELECT * FROM archive_history WHERE archive_path=? ORDER BY created_at DESC LIMIT 1",
        (archive_path,),
    ).fetchone()
    return dict(row) if row else None


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="zip-service",
        description="ZIP/Archive Service — blackroad-zip-service",
    )
    p.add_argument("--db", default=str(DB_PATH), help="SQLite database path")
    sub = p.add_subparsers(dest="command", required=True)

    # create
    c = sub.add_parser("create", help="Create archive from files")
    c.add_argument("output", help="Output archive path")
    c.add_argument("files", nargs="+", help="Files/directories to archive")
    c.add_argument("--format", "-f", default="zip",
                   choices=list(SUPPORTED_FORMATS), help="Archive format")

    # extract
    ex = sub.add_parser("extract", help="Extract archive")
    ex.add_argument("archive", help="Archive path")
    ex.add_argument("dest", help="Destination directory")

    # list
    ls = sub.add_parser("list", help="List archive contents")
    ls.add_argument("archive", help="Archive path")

    # add
    add = sub.add_parser("add", help="Add file to existing ZIP archive")
    add.add_argument("archive", help="Archive path (.zip only)")
    add.add_argument("file", help="File to add")

    # verify
    v = sub.add_parser("verify", help="Verify archive integrity and checksum")
    v.add_argument("archive", help="Archive path")
    v.add_argument("--expected", help="Expected SHA-256 checksum")

    # checksum
    cs = sub.add_parser("checksum", help="Compute archive checksum")
    cs.add_argument("archive", help="Archive path")
    cs.add_argument("--algorithm", default="sha256")

    # history
    h = sub.add_parser("history", help="Show operation history")
    h.add_argument("--limit", type=int, default=20)

    return p


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    conn = get_db(Path(args.db))

    if args.command == "create":
        info = create_archive(args.files, args.output, compression=args.format, conn=conn)
        print(f"✓ Created {info.path} ({info.format}, {info.entry_count} entries, "
              f"{info.size:,} bytes)")
        print(f"  SHA-256: {info.checksum}")

    elif args.command == "extract":
        extracted = extract_archive(args.archive, args.dest, conn=conn)
        print(f"✓ Extracted {len(extracted)} entries to {args.dest}")

    elif args.command == "list":
        entries = list_contents(args.archive)
        print(f"{'Path':<60} {'Size':>10} {'Compressed':>12} {'Modified':<12}")
        print("-" * 96)
        for e in entries:
            cs = str(e.compressed_size) if e.compressed_size is not None else "-"
            marker = "/" if e.is_dir else ""
            print(f"{e.path + marker:<60} {e.size:>10,} {cs:>12} {e.modified or '-':<12}")
        print(f"\n{len(entries)} entries")

    elif args.command == "add":
        info = add_to_archive(args.archive, args.file, conn=conn)
        print(f"✓ Added {args.file} to {info.path} ({info.entry_count} entries total)")

    elif args.command == "verify":
        result = checksum_verify(args.archive, expected=args.expected, conn=conn)
        if result["valid"]:
            print(f"✓ Archive is valid")
            print(f"  SHA-256: {result['checksum']}")
        else:
            print(f"✗ Archive invalid: {result['error']}", file=sys.stderr)
            sys.exit(1)

    elif args.command == "checksum":
        cs = compute_checksum(args.archive, args.algorithm)
        print(f"{args.algorithm}: {cs}  {args.archive}")

    elif args.command == "history":
        rows = get_history(conn, limit=args.limit)
        if not rows:
            print("No history found.")
        for row in rows:
            status = "✓" if row["status"] == "ok" else "✗"
            print(f"{status} [{row['created_at']}] {row['operation']:15s} "
                  f"{row['archive_path']} ({row['file_count']} files, "
                  f"{row.get('archive_size', 0):,} bytes)")


if __name__ == "__main__":
    main()
