#!/usr/bin/env python3
"""Export Lucidia embeddings to Embedding Atlas compatible Parquet.

Writes a Parquet file with the schema required by the Embedding Atlas
viewer. The script performs a light redaction pass to strip secrets or
email-like strings from textual metadata before serialization.

Example:
    python tools/export_embeddings.py --out data/atlas.parquet
"""
from __future__ import annotations

import argparse
import datetime as dt
import re
from typing import Iterable, Dict, Any

import pyarrow as pa
import pyarrow.parquet as pq


RE_EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
RE_TOKEN = re.compile(r"[A-Za-z0-9_\-]{32,}")


def redact(text: str) -> str:
    """Redact obvious secrets from text fields."""
    text = RE_EMAIL.sub("[redacted]", text)
    text = RE_TOKEN.sub("[redacted]", text)
    return text


def records() -> Iterable[Dict[str, Any]]:
    """Yield embedding records.

    In a real deployment this function would stream data from Lucidia's
    memory store. Here we emit a tiny synthetic example so the exporter
    can run in isolation.
    """
    yield {
        "id": "demo-0",
        "embedding": [0.0, 0.1, 0.2],
        "projection_2d": [0.0, 0.0],
        "text": "hello world",
        "source_uri": "/demo",
        "agent": "guardian",
        "doc_type": "chat",
        "truth_state": 0,
        "contradiction_level": 0.0,
        "ps_sha_inf": "deadbeef",
        "timestamp": dt.datetime.now(dt.timezone.utc),
        "tags": ["demo"],
    }


def build_table(rows: Iterable[Dict[str, Any]]) -> pa.Table:
    schema = pa.schema([
        pa.field("id", pa.string()),
        pa.field("embedding", pa.list_(pa.float32())),
        pa.field("projection_2d", pa.list_(pa.float32())),
        pa.field("text", pa.string()),
        pa.field("source_uri", pa.string()),
        pa.field("agent", pa.string()),
        pa.field("doc_type", pa.string()),
        pa.field("truth_state", pa.int8()),
        pa.field("contradiction_level", pa.float32()),
        pa.field("ps_sha_inf", pa.string()),
        pa.field("timestamp", pa.timestamp("ms")),
        pa.field("tags", pa.list_(pa.string())),
    ])

    cleaned = []
    for r in rows:
        r = r.copy()
        r["text"] = redact(r.get("text", ""))
        r["source_uri"] = redact(r.get("source_uri", ""))
        cleaned.append(r)

    return pa.Table.from_pylist(cleaned, schema=schema)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="data/atlas.parquet", help="Output Parquet file")
    args = parser.parse_args()

    table = build_table(records())
    pq.write_table(table, args.out)
    print(f"wrote {table.num_rows} rows to {args.out}")


if __name__ == "__main__":
    main()
