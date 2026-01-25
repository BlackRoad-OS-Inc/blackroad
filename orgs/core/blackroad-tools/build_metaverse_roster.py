#!/usr/bin/env python3
"""Build a consolidated roster of BlackRoad agents for the metaverse layer.

The generator walks the canonical archetype clusters, normalizes the manifest
metadata, and emits a JSON document that can be consumed by the metaverse API
and client surfaces. The output defaults to
``metaverse/data/agent_roster.json`` and contains:

* metadata (generated timestamp, totals, per-cluster counts)
* up to the requested number of agents (default: 1,000)
* pre-computed metaverse spawn hints (zones, avatar styles, ordering)

Usage:
    python tools/build_metaverse_roster.py [--limit 1000] [--output <path>]
"""
from __future__ import annotations

import argparse
import json
from collections import OrderedDict
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
AGENT_ROOT = REPO_ROOT / "agents" / "archetypes"
DEFAULT_OUTPUT = REPO_ROOT / "metaverse" / "data" / "agent_roster.json"

# Canonical cluster ordering used across the repository.
CLUSTERS: Sequence[tuple[str, str]] = (
    ("aether", "Aether"),
    ("athenaeum", "Athenaeum"),
    ("aurum", "Aurum"),
    ("blackroad", "BlackRoad"),
    ("continuum", "Continuum"),
    ("eidos", "Eidos"),
    ("lucidia", "Lucidia"),
    ("mycelia", "Mycelia"),
    ("parallax", "Parallax"),
    ("soma", "Soma"),
)

# Mirror of the avatar metadata baked into the TypeScript runtime so we can
# emit deterministic spawn hints for the metaverse services.
CLUSTER_METAVERSE_CONFIG: Dict[str, dict] = {
    "athenaeum": {
        "avatarVariant": "scholar",
        "color": [0.2, 0.3, 0.8],
        "zones": ["europe", "north-america"],
    },
    "lucidia": {
        "avatarVariant": "creator",
        "color": [0.8, 0.5, 0.2],
        "zones": ["asia", "oceania"],
    },
    "blackroad": {
        "avatarVariant": "engineer",
        "color": [0.1, 0.1, 0.1],
        "zones": ["north-america", "europe"],
    },
    "eidos": {
        "avatarVariant": "philosopher",
        "color": [0.6, 0.2, 0.6],
        "zones": ["europe", "asia"],
    },
    "mycelia": {
        "avatarVariant": "networker",
        "color": [0.2, 0.8, 0.3],
        "zones": ["south-america", "africa"],
    },
    "soma": {
        "avatarVariant": "healer",
        "color": [0.9, 0.7, 0.4],
        "zones": ["africa", "south-america"],
    },
    "aurum": {
        "avatarVariant": "trader",
        "color": [0.9, 0.8, 0.2],
        "zones": ["atlantic-hub", "pacific-hub"],
    },
    "aether": {
        "avatarVariant": "explorer",
        "color": [0.8, 0.8, 0.9],
        "zones": ["orbital-station"],
    },
    "parallax": {
        "avatarVariant": "observer",
        "color": [0.5, 0.5, 0.5],
        "zones": ["antarctica", "orbital-station"],
    },
    "continuum": {
        "avatarVariant": "chronicler",
        "color": [0.3, 0.6, 0.8],
        "zones": ["pacific-hub", "atlantic-hub"],
    },
}

DEFAULT_LIMIT = 1_000


def _flatten_strings(values: Iterable) -> List[str]:
    """Flatten nested lists/dicts of strings from manifest attributes."""
    flattened: List[str] = []
    for value in values:
        if value is None:
            continue
        if isinstance(value, str):
            flattened.append(value.strip())
        elif isinstance(value, (list, tuple, set)):
            flattened.extend(_flatten_strings(value))
        elif isinstance(value, dict):
            flattened.extend(_flatten_strings(value.values()))
        else:
            flattened.append(str(value))
    return [s for s in flattened if s]


def _normalize_capabilities(raw: Optional[object]) -> List[str]:
    if raw is None:
        return []
    if isinstance(raw, dict):
        return sorted({cap for cap in _flatten_strings(raw.values()) if cap})
    if isinstance(raw, (list, tuple, set)):
        return sorted({cap for cap in _flatten_strings(raw) if cap})
    if isinstance(raw, str):
        return [raw.strip()] if raw.strip() else []
    return [str(raw)]


def _normalize_covenants(raw: Optional[object]) -> List[str]:
    if raw is None:
        return []
    if isinstance(raw, dict):
        tags = raw.get("tags") or raw.get("values") or raw.values()
        return sorted({tag for tag in _flatten_strings(tags) if tag})
    elif isinstance(raw, str):
        return [raw.strip()] if raw.strip() else []
    elif isinstance(raw, Iterable) and not isinstance(raw, str):
        return sorted({tag for tag in _flatten_strings(raw) if tag})
    return [str(raw)]


def _normalize_traits(raw: Optional[dict]) -> Dict[str, float]:
    traits: Dict[str, float] = {}
    if not isinstance(raw, dict):
        return traits
    mapping = {
        "kindness_index": "kindnessIndex",
        "creativity_bias": "creativityBias",
        "reflection_frequency": "reflectionFrequency",
        "reflection_frequency_hours": "reflectionFrequencyHours",
    }
    for key, value in raw.items():
        camel_key = mapping.get(key, key)
        try:
            traits[camel_key] = float(value)
        except (TypeError, ValueError):
            continue
    return traits


def _profile_summary(raw: Optional[dict]) -> Dict[str, str]:
    if not isinstance(raw, dict):
        return {}
    interesting_keys = (
        "home_haven",
        "unity_compass",
        "worldbuilder_path",
        "heart_practice",
        "remembrance_ritual",
    )
    summary: Dict[str, str] = {}
    for key in interesting_keys:
        if key in raw and isinstance(raw[key], str):
            summary[key] = raw[key]
    return summary


def _normalize_lineage(raw: Optional[dict]) -> Dict[str, object]:
    if not isinstance(raw, dict):
        return {}
    lineage: Dict[str, object] = {}
    if "parent" in raw:
        lineage["parent"] = raw["parent"]
    if "mentors" in raw and isinstance(raw["mentors"], (list, tuple, set)):
        lineage["mentors"] = [str(m) for m in raw["mentors"]]
    ancestry_key = "ancestry_depth" if "ancestry_depth" in raw else "ancestryDepth"
    if ancestry_key in raw:
        try:
            lineage["ancestryDepth"] = int(raw[ancestry_key])
        except (TypeError, ValueError):
            # If ancestry depth is not numeric, omit it instead of failing the build.
            pass
    return lineage


def _determine_generation(manifest: dict, candidate: str | None, path: Path) -> str:
    if candidate:
        return str(candidate).lower()
    parts = {p.lower() for p in path.parts}
    for generation in ("apprentice", "hybrid", "elder"):
        if generation in parts:
            return generation
    return "seed"


def load_manifests(limit: int) -> tuple[List[dict], Dict[str, int]]:
    seen_ids: set[str] = set()
    roster: List[dict] = []
    cluster_counts: Dict[str, int] = {cluster: 0 for cluster, _ in CLUSTERS}

    for cluster, label in CLUSTERS:
        cluster_dir = AGENT_ROOT / cluster
        if not cluster_dir.exists():
            continue
        manifests = sorted(cluster_dir.rglob("*.manifest.yaml"))
        for manifest_path in manifests:
            try:
                data = yaml.safe_load(manifest_path.read_text(encoding="utf-8")) or {}
            except yaml.YAMLError as exc:  # pragma: no cover - defensive
                raise RuntimeError(f"Failed to parse {manifest_path}: {exc}") from exc

            manifest_id = str(data.get("id") or manifest_path.stem)
            if manifest_id in seen_ids:
                continue
            seen_ids.add(manifest_id)

            generation = _determine_generation(data, data.get("generation"), manifest_path)
            metaverse_cfg = CLUSTER_METAVERSE_CONFIG.get(cluster, {})
            cluster_counts[cluster] += 1
            zone_options = metaverse_cfg.get("zones") or ["orbital-station"]
            zone_index = (cluster_counts[cluster] - 1) % len(zone_options)
            preferred_zone = zone_options[zone_index]

            entry = OrderedDict(
                (
                    ("id", manifest_id),
                    ("cluster", cluster),
                    ("clusterLabel", label),
                    # Fallback priority: name > title > manifest_id (title-cased, spaced).
                    ("name", data.get("name") or data.get("title") or manifest_id.replace("-", " ").title()),
                    ("title", data.get("title") or manifest_id.title()),
                    ("role", data.get("role") or data.get("title") or "Agent"),
                    ("generation", generation),
                    ("ethos", data.get("ethos")),
                    ("capabilities", _normalize_capabilities(data.get("capabilities"))),
                    ("covenants", _normalize_covenants(data.get("covenants"))),
                    ("traits", _normalize_traits(data.get("traits"))),
                    ("profileSummary", _profile_summary(data.get("profile"))),
                    ("lineage", _normalize_lineage(data.get("lineage"))),
                    (
                        "metaverse",
                        {
                            "preferredZone": preferred_zone,
                            "avatarVariant": metaverse_cfg.get("avatarVariant", "explorer"),
                            "color": metaverse_cfg.get("color", [0.8, 0.8, 0.9]),
                            "spawnIndex": cluster_counts[cluster] - 1,
                        },
                    ),
                    (
                        "sourceManifest",
                        manifest_path.relative_to(REPO_ROOT).as_posix(),
                    ),
                )
            )

            roster.append(entry)
            if len(roster) >= limit:
                break
        if len(roster) >= limit:
            break

    return roster, cluster_counts


def build_roster(limit: int) -> dict:
    roster, cluster_counts = load_manifests(limit)
    metadata = {
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "totalAgents": len(roster),
        "clusterCounts": cluster_counts,
        "source": "tools/build_metaverse_roster.py",
        "limit": limit,
    }
    return {
        "metadata": metadata,
        "agents": roster,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--limit",
        type=int,
        default=DEFAULT_LIMIT,
        help="Maximum number of agents to include (default: 1000)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help="Destination path for the roster JSON (default: metaverse/data/agent_roster.json)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.limit <= 0:
        raise SystemExit("--limit must be greater than zero")

    payload = build_roster(args.limit)

    output_path: Path = args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    cluster_counts = payload["metadata"]["clusterCounts"]
    summary = ", ".join(f"{cluster}: {count}" for cluster, count in cluster_counts.items())
    print(
        f"Generated roster with {payload['metadata']['totalAgents']} agents "
        f"→ {output_path.relative_to(REPO_ROOT)}"
    )
    print(f"Cluster distribution: {summary}")


if __name__ == "__main__":  # pragma: no cover - CLI entry point
    main()
