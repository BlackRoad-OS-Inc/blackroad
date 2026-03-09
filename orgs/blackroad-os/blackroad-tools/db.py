"""Lightweight database adapter used by the Prism console.

The real system is expected to talk to production-grade data stores.  For the
console we provide a pragmatic implementation that can execute read-only SQL
statements against SQLite files and otherwise returns deterministic mock data.
This keeps the CLI functional without requiring external infrastructure while
still giving callers realistic shaped results.
"""

from __future__ import annotations

import contextlib
import sqlite3
from pathlib import Path
from typing import Sequence

Row = dict[str, object]


def _as_rows(cursor: sqlite3.Cursor) -> list[Row]:
    """Convert the cursor contents into dictionaries."""

    column_names = [column[0] for column in cursor.description or ()]
    rows = cursor.fetchall()
    return [dict(zip(column_names, row)) for row in rows]


def query(
    sql: str,
    db: str | Path | None = None,
    *,
    params: Sequence[object] | None = None,
) -> list[Row]:
    """Execute a read-only SQL query.

    If ``db`` points to an existing SQLite database, the statement is executed
    there with the provided parameters.  All statements are run in ``immutable``
    mode to prevent accidental writes.  When no database is supplied we return a
    deterministic mock response so higher level code can continue to operate.
    """

    if db is None:
        return [{"sql": sql, "result": "mock", "rows": 0}]

    database_path = Path(db).expanduser().resolve()
    if not database_path.exists():
        return [
            {
                "sql": sql,
                "result": "missing-database",
                "database": str(database_path),
                "rows": 0,
            }
        ]

    params = tuple(params or ())

    uri = f"file:{database_path.as_posix()}?mode=ro&immutable=1"

    with contextlib.closing(
        sqlite3.connect(uri, uri=True, check_same_thread=False, isolation_level=None)
    ) as connection:
        connection.row_factory = sqlite3.Row
        with contextlib.closing(connection.cursor()) as cursor:
            cursor.execute(sql, params)
            return _as_rows(cursor)


__all__ = ["query", "Row"]
def query(sql: str, db: str) -> list[dict]:
    """Return mock rows for a query."""
    return [{"sql": sql, "db": db, "result": 1}]
"""Stub database adapter.

All actions must be logged and no real database operations are executed.
"""


def query(sql: str):
    """Execute *sql* query.

    Raises
    ------
    NotImplementedError
        Always, as database access is disabled.
    """

    raise NotImplementedError("Database access disabled by guardrails")
