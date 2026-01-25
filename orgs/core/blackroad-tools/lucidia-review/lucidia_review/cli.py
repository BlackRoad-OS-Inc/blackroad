"""Command line interface for the Lucidia Peer-Review Agent.

This module wires together lightweight stubs for the eventual review
pipeline.  It parses a few common flags and prints placeholders so the
surrounding tooling can be exercised without implementing the full
engine yet.
"""

from __future__ import annotations

import argparse
import pathlib
from typing import Sequence


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lucidia Peer-Review Agent")
    parser.add_argument("path", nargs="*", default=["."], help="Paths to review")
    parser.add_argument("--fast", action="store_true", help="Run a minimal set of checks")
    parser.add_argument("--sbom", action="store_true", help="Generate a SBOM")
    parser.add_argument("--lock", action="store_true", help="Refresh lockfiles")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    for p in map(pathlib.Path, args.path):
        if not p.exists():
            print(f"warning: path {p} does not exist")
    if args.sbom:
        print("[lucidia-review] SBOM generation is not yet implemented")
    elif args.lock:
        print("[lucidia-review] Lockfile refresh is not yet implemented")
    else:
        mode = "fast" if args.fast else "full"
        print(f"[lucidia-review] Running {mode} review on: {', '.join(args.path)}")
    return 0


if __name__ == "__main__":  # pragma: no cover - entry point
    raise SystemExit(main())
