"""Utilities for building the Time Machine index."""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

ISO_FORMAT = "%Y-%m-%dT%H:%M:%SZ"
MAX_EMBEDDED_BYTES = 16_384


def _read_text(path: Path, limit: int = MAX_EMBEDDED_BYTES) -> str:
    data = path.read_bytes()[:limit]
    return data.decode("utf-8", errors="replace")


def _load_json(path: Optional[Path], default: Any) -> Any:
    if not path:
        return default
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError:
        return default
    except json.JSONDecodeError as exc:
        raise ValueError(f"Failed to decode JSON from {path}") from exc


def _load_jsonl(path: Optional[Path]) -> List[Any]:
    if not path:
        return []
    try:
        lines: List[Any] = []
        with path.open("r", encoding="utf-8") as handle:
            for raw in handle:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    lines.append(json.loads(raw))
                except json.JSONDecodeError:
                    lines.append({"raw": raw})
        return lines
    except FileNotFoundError:
        return []


def _collect_directory_metadata(base: Optional[Path]) -> List[Dict[str, Any]]:
    if not base or not base.exists():
        return []

    results: List[Dict[str, Any]] = []
    for file_path in sorted(p for p in base.rglob("*") if p.is_file()):
        rel_path = file_path.relative_to(base).as_posix()
        stat = file_path.stat()
        entry: Dict[str, Any] = {
            "path": rel_path,
            "size": stat.st_size,
            "modified": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).strftime(ISO_FORMAT),
        }

        if file_path.suffix.lower() in {".json", ".jsonl"} and stat.st_size <= MAX_EMBEDDED_BYTES:
            try:
                entry["data"] = json.loads(_read_text(file_path))
            except json.JSONDecodeError:
                entry["preview"] = _read_text(file_path)
        elif file_path.suffix.lower() in {".md", ".txt", ".log"}:
            entry["preview"] = _read_text(file_path)
        else:
            entry["preview"] = _read_text(file_path, limit=2048)

        results.append(entry)
    return results


def _resolve_path(path_str: Optional[str]) -> Optional[Path]:
    if not path_str:
        return None
    resolved = Path(path_str).expanduser().resolve()
    return resolved if resolved.exists() else resolved


def build_index(
    lh_path: Optional[Path] = None,
    ci_path: Optional[Path] = None,
    k6_path: Optional[Path] = None,
    run_meta_path: Optional[Path] = None,
    alerts_path: Optional[Path] = None,
    runtime_path: Optional[Path] = None,
    agents_path: Optional[Path] = None,
) -> Dict[str, Any]:
    """Build the consolidated time machine index."""

    index: Dict[str, Any] = {
        "generated_at": datetime.now(tz=timezone.utc).strftime(ISO_FORMAT),
        "lh": _load_json(lh_path, default={}),
        "ci": _load_json(ci_path, default={}),
        "k6": _load_json(k6_path, default={}),
        "sim": _load_json(run_meta_path, default={}),
        "alerts": _load_jsonl(alerts_path),
        "runtime": _collect_directory_metadata(runtime_path),
        "agents": _collect_directory_metadata(agents_path),
    }
    return index


def _parse_args(argv: Optional[Iterable[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build the Time Machine index")
    parser.add_argument("--lh", dest="lh", help="Path to Lighthouse history JSON")
    parser.add_argument("--ci", dest="ci", help="Path to CI runs JSON")
    parser.add_argument("--k6", dest="k6", help="Path to k6 summary JSON")
    parser.add_argument("--runmeta", dest="runmeta", help="Path to run_meta.json")
    parser.add_argument("--alerts", dest="alerts", help="Path to alerts JSONL stream")
    parser.add_argument("--runtime", dest="runtime", help="Directory of runtime logs")
    parser.add_argument("--agents", dest="agents", help="Directory for agent lineage data")
    parser.add_argument("--out", dest="out", required=True, help="Destination JSON file")
    return parser.parse_args(argv)


def main(argv: Optional[Iterable[str]] = None) -> int:
    args = _parse_args(argv)
    index = build_index(
        lh_path=_resolve_path(args.lh),
        ci_path=_resolve_path(args.ci),
        k6_path=_resolve_path(args.k6),
        run_meta_path=_resolve_path(args.runmeta),
        alerts_path=_resolve_path(args.alerts),
        runtime_path=_resolve_path(args.runtime),
        agents_path=_resolve_path(args.agents),
    )

    out_path = Path(args.out).expanduser().resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as handle:
        json.dump(index, handle, indent=2, sort_keys=True)
        handle.write("\n")
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    sys.exit(main(sys.argv[1:]))
