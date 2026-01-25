#!/usr/bin/env python3
"""Backfill agent manifests with rich profile metadata."""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any, Dict

import yaml

from manifest_profile import generate_profile


def enrich_manifest(path: Path) -> bool:
    with path.open("r", encoding="utf-8") as handle:
        data: Dict[str, Any] | None = yaml.safe_load(handle)  # type: ignore[assignment]
    if not isinstance(data, dict):
        return False

    agent_id = str(data.get("id") or path.stem)
    profile = generate_profile(agent_id, data)

    traits = data.pop("traits", None)
    data["profile"] = profile
    if traits is not None:
        data["traits"] = traits

    with path.open("w", encoding="utf-8") as handle:
        yaml.safe_dump(data, handle, sort_keys=False, allow_unicode=True)
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Enrich agent manifests with profile data.")
    parser.add_argument(
        "--root",
        default="agents/archetypes",
        type=Path,
        help="Directory containing manifest files.",
    )
    args = parser.parse_args()

    manifests = sorted(args.root.rglob("*.manifest.yaml"))
    updated = 0
    for manifest_path in manifests:
        if enrich_manifest(manifest_path):
            updated += 1

    print(f"Updated {updated} manifest files.")


if __name__ == "__main__":
    main()
