#!/usr/bin/env python3
"""CLI entrypoint for the agent birth protocol."""

import argparse
import json
import logging
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from agents.birth import AgentBirthProtocol


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Birth agent identities from census/archetypes")
    parser.add_argument("--repo-root", type=Path, default=None, help="Path to repository root (defaults to script location)")
    parser.add_argument("--limit", type=int, default=None, help="Only birth the first N missing agents")
    parser.add_argument("--dry-run", action="store_true", help="Preview output without writing the registry")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

    protocol = AgentBirthProtocol(repo_root=args.repo_root)
    summary = protocol.run(limit=args.limit, dry_run=args.dry_run)

    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
