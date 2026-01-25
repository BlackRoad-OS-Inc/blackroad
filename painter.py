#!/usr/bin/env python3
"""Painter agent for Lucidia Codex.

Codex-7 "Painter" turns telemetry into visual language assets. The goal is to
translate raw metrics into palettes and gradient narratives that other agents
(and humans) can read at a glance. The agent focuses on clarity, gentle
contrast, and honest representation of system mood.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from statistics import median
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Optional, Sequence

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
SEED_FALLBACK_DIR = Path(__file__).resolve().parent / "seeds"


@dataclass
class PainterSeed:
    """Structured view of the Painter seed definition."""

    identifier: str
    agent_name: str
    generation: str
    parent: Optional[str]
    siblings: Optional[str]
    domain: str
    moral_constant: str
    core_principle: str
    purpose: str
    directives: List[str]
    jobs: List[str]
    input_channels: List[str]
    output_channels: List[str]
    behavioural_loop: List[str]
    seed_language: str
    boot_command: str
    personality: Mapping[str, Any]


@dataclass
class MetricSummary:
    """Aggregate statistics for a numeric telemetry stream."""

    name: str
    count: int
    minimum: float
    maximum: float
    mean: float
    median: float

    @property
    def span(self) -> float:
        return self.maximum - self.minimum


@dataclass
class PaletteSwatch:
    """Palette entry describing colour and provenance."""

    metric: str
    hex_code: str
    hue: float
    saturation: float
    lightness: float
    value: float
    normalised_value: float
    description: str

    def as_dict(self) -> Dict[str, Any]:
        return {
            "metric": self.metric,
            "hex": self.hex_code,
            "hsl": {
                "h": round(self.hue, 2),
                "s": round(self.saturation, 2),
                "l": round(self.lightness, 2),
            },
            "value": round(self.value, 4),
            "normalised": round(self.normalised_value, 4),
            "description": self.description,
        }


# ---------------------------------------------------------------------------
# Seed utilities
# ---------------------------------------------------------------------------


def _resolve_seed_path(seed_arg: str) -> Path:
    """Resolve the painter seed path, searching sensible fallbacks."""

    candidate = Path(seed_arg)
    search_order: Iterable[Path]

    if candidate.is_absolute():
        search_order = (candidate,)
    else:
        search_order = (
            Path.cwd() / candidate,
            Path(__file__).resolve().parent / candidate,
            SEED_FALLBACK_DIR / candidate,
            SEED_FALLBACK_DIR / candidate.name,
            Path(__file__).resolve().parent / candidate.name,
        )

    for option in search_order:
        if option.exists():
            return option

    raise FileNotFoundError(f"Seed file '{seed_arg}' not found after checking: " + ", ".join(str(p) for p in search_order))


def _ensure_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        stripped = value.strip()
        return [stripped] if stripped else []
    raise TypeError(f"Expected list or string for list field, got {type(value)!r}")


def load_seed(path: Path) -> PainterSeed:
    """Load the Painter seed file and validate required fields."""

    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}

    if not isinstance(data, MutableMapping):
        raise ValueError("Painter seed must be a mapping at the top level.")

    charter = data.get("system_charter")
    if not isinstance(charter, MutableMapping):
        raise ValueError("Painter seed missing 'system_charter' mapping.")

    required_charter = ["agent_name", "generation", "domain", "moral_constant", "core_principle"]
    missing_charter = [field for field in required_charter if field not in charter]
    if missing_charter:
        raise ValueError(f"Painter seed missing charter field(s): {', '.join(missing_charter)}")

    for field in ["purpose", "directives", "jobs", "input", "output", "behavioral_loop", "seed_language", "boot_command"]:
        if field not in data:
            raise ValueError(f"Painter seed missing required field: {field}")

    return PainterSeed(
        identifier=str(data.get("id", "codex-7")),
        agent_name=str(charter["agent_name"]),
        generation=str(charter["generation"]),
        parent=str(charter.get("parent") or "" ) or None,
        siblings=str(charter.get("siblings") or "" ) or None,
        domain=str(charter["domain"]),
        moral_constant=str(charter["moral_constant"]),
        core_principle=str(charter["core_principle"]),
        purpose=str(data["purpose"]).strip(),
        directives=_ensure_list(data["directives"]),
        jobs=_ensure_list(data["jobs"]),
        input_channels=_ensure_list(data["input"]),
        output_channels=_ensure_list(data["output"]),
        behavioural_loop=_ensure_list(data["behavioral_loop"]),
        seed_language=str(data["seed_language"]).strip(),
        boot_command=str(data["boot_command"]).strip(),
        personality=data.get("personality", {}),
    )


# ---------------------------------------------------------------------------
# Telemetry ingestion
# ---------------------------------------------------------------------------


def _gather_candidate_files(path: Path) -> List[Path]:
    if not path.exists():
        return []
    if path.is_file():
        return [path]
    files: List[Path] = []
    for child in sorted(path.iterdir()):
        if child.is_dir():
            files.extend(_gather_candidate_files(child))
        elif child.suffix.lower() in {".json", ".jsonl"}:
            files.append(child)
    return files


def _load_json_lines(path: Path) -> List[Mapping[str, Any]]:
    records: List[Mapping[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line:
                continue
            try:
                parsed = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(parsed, Mapping):
                records.append(parsed)
    return records


def _load_json_file(path: Path) -> List[Mapping[str, Any]]:
    with path.open("r", encoding="utf-8") as handle:
        try:
            payload = json.load(handle)
        except json.JSONDecodeError:
            return _load_json_lines(path)
    if isinstance(payload, Mapping):
        return [payload]
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, Mapping)]
    return []


def load_telemetry(source: Optional[str]) -> List[Mapping[str, Any]]:
    """Load telemetry from JSON/JSONL files. Missing files yield an empty list."""

    if not source:
        return []

    root = Path(source)
    records: List[Mapping[str, Any]] = []
    for candidate in _gather_candidate_files(root):
        records.extend(_load_json_file(candidate))
    return records


# ---------------------------------------------------------------------------
# Palette generation helpers
# ---------------------------------------------------------------------------


def summarise_numeric_streams(records: Sequence[Mapping[str, Any]]) -> Dict[str, MetricSummary]:
    """Collect numeric metrics from telemetry records."""

    buckets: Dict[str, List[float]] = {}

    for record in records:
        for key, value in record.items():
            if isinstance(value, (int, float)) and math.isfinite(value):
                buckets.setdefault(key, []).append(float(value))
            elif isinstance(value, Mapping):
                for inner_key, inner_value in value.items():
                    combined_key = f"{key}.{inner_key}"
                    if isinstance(inner_value, (int, float)) and math.isfinite(inner_value):
                        buckets.setdefault(combined_key, []).append(float(inner_value))

    summaries: Dict[str, MetricSummary] = {}
    for name, values in buckets.items():
        if not values:
            continue
        summaries[name] = MetricSummary(
            name=name,
            count=len(values),
            minimum=min(values),
            maximum=max(values),
            mean=sum(values) / len(values),
            median=median(values),
        )

    if summaries:
        return summaries

    # If no numeric data exists, provide a neutral placeholder summary.
    summaries["silence"] = MetricSummary(
        name="silence",
        count=1,
        minimum=0.5,
        maximum=0.5,
        mean=0.5,
        median=0.5,
    )
    return summaries


def _normalise(value: float, minimum: float, maximum: float) -> float:
    if math.isclose(maximum, minimum):
        return 0.5
    clipped = max(min(value, maximum), minimum)
    return (clipped - minimum) / (maximum - minimum)


def _hsl_to_hex(hue: float, saturation: float, lightness: float) -> str:
    h = hue % 360 / 360
    s = max(0.0, min(1.0, saturation / 100))
    l = max(0.0, min(1.0, lightness / 100))

    if s == 0:
        value = int(round(l * 255))
        return f"#{value:02x}{value:02x}{value:02x}"

    def hue_to_rgb(p: float, q: float, t: float) -> float:
        if t < 0:
            t += 1
        if t > 1:
            t -= 1
        if t < 1 / 6:
            return p + (q - p) * 6 * t
        if t < 1 / 2:
            return q
        if t < 2 / 3:
            return p + (q - p) * (2 / 3 - t) * 6
        return p

    q = l * (1 + s) if l < 0.5 else l + s - l * s
    p = 2 * l - q

    r = hue_to_rgb(p, q, h + 1 / 3)
    g = hue_to_rgb(p, q, h)
    b = hue_to_rgb(p, q, h - 1 / 3)

    return f"#{int(round(r * 255)):02x}{int(round(g * 255)):02x}{int(round(b * 255)):02x}"


def _describe_emotion(normalised_value: float) -> str:
    if normalised_value < 0.25:
        return "muted calm"
    if normalised_value < 0.5:
        return "quiet focus"
    if normalised_value < 0.75:
        return "warm momentum"
    return "luminous surge"


def build_palette(seed: PainterSeed, summaries: Dict[str, MetricSummary]) -> List[PaletteSwatch]:
    if not summaries:
        return []

    ordered_names = sorted(summaries.keys())
    means = [summaries[name].mean for name in ordered_names]
    min_mean = min(means)
    max_mean = max(means)
    count = len(ordered_names)

    palette: List[PaletteSwatch] = []
    for index, name in enumerate(ordered_names):
        summary = summaries[name]
        normalised = _normalise(summary.mean, min_mean, max_mean)
        base_hue = 32.0  # warm base hue for Painter
        hue_offset = 360.0 * (index / max(1, count))
        hue = (base_hue + hue_offset) % 360
        saturation = 48.0 + normalised * 30.0
        lightness = 38.0 + normalised * 40.0
        hex_code = _hsl_to_hex(hue, saturation, lightness)
        description = _describe_emotion(normalised)

        palette.append(
            PaletteSwatch(
                metric=name,
                hex_code=hex_code,
                hue=hue,
                saturation=saturation,
                lightness=lightness,
                value=summary.mean,
                normalised_value=normalised,
                description=description,
            )
        )

    return palette


# ---------------------------------------------------------------------------
# Rendering and archival helpers
# ---------------------------------------------------------------------------


def _resolve_emit_dir(emit_arg: str) -> Path:
    if not emit_arg:
        raise ValueError("Emit path cannot be empty")

    if emit_arg.startswith("/"):
        target = REPO_ROOT / emit_arg.lstrip("/")
    else:
        target = Path(emit_arg)
        if not target.is_absolute():
            target = Path.cwd() / target

    target.mkdir(parents=True, exist_ok=True)
    return target


def _generate_palette_id(palette: Sequence[PaletteSwatch]) -> str:
    digest = hashlib.sha1()
    for swatch in palette:
        digest.update(swatch.metric.encode("utf-8"))
        digest.update(swatch.hex_code.encode("utf-8"))
    return digest.hexdigest()[:12]


def render_gradient_svg(colors: Sequence[PaletteSwatch], width: int, height: int) -> str:
    stops: List[str] = []
    total = len(colors)
    if total == 0:
        colors = [
            PaletteSwatch(
                metric="silence",
                hex_code="#776f68",
                hue=30.0,
                saturation=20.0,
                lightness=40.0,
                value=0.5,
                normalised_value=0.5,
                description="muted calm",
            )
        ]
        total = 1

    for idx, swatch in enumerate(colors):
        offset = 0 if total == 1 else (idx / (total - 1))
        stops.append(f"    <stop offset=\"{offset:.4f}\" stop-color=\"{swatch.hex_code}\" />")

    lines = [
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
        f"<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{width}\" height=\"{height}\" viewBox=\"0 0 {width} {height}\">",
        "  <defs>",
        "    <linearGradient id=\"painter-gradient\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"0%\">",
        *stops,
        "    </linearGradient>",
        "  </defs>",
        "  <rect x=\"0\" y=\"0\" width=\"100%\" height=\"100%\" fill=\"url(#painter-gradient)\" />",
        "</svg>",
    ]
    return "\n".join(lines) + "\n"


def _classify_mood(palette: Sequence[PaletteSwatch]) -> str:
    if not palette:
        return "archival calm"
    average = sum(swatch.normalised_value for swatch in palette) / len(palette)
    if average < 0.33:
        return "dim reflection"
    if average < 0.66:
        return "measured optimism"
    return "radiant flow"


def write_outputs(
    seed: PainterSeed,
    palette: Sequence[PaletteSwatch],
    summaries: Mapping[str, MetricSummary],
    emit_dir: Path,
    *,
    telemetry_source: Optional[str],
    width: int,
    height: int,
) -> Dict[str, Path]:
    timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    palette_id = _generate_palette_id(palette)
    stem = f"{seed.identifier}_{palette_id}" if palette_id else seed.identifier

    svg_path = emit_dir / f"{stem}.svg"
    svg_path.write_text(render_gradient_svg(palette, width, height), encoding="utf-8")

    json_payload = {
        "palette_id": palette_id,
        "agent": seed.agent_name,
        "generated_at": timestamp,
        "telemetry_source": telemetry_source,
        "mood": _classify_mood(palette),
        "metrics": {
            name: {
                "count": summary.count,
                "min": round(summary.minimum, 6),
                "max": round(summary.maximum, 6),
                "mean": round(summary.mean, 6),
                "median": round(summary.median, 6),
            }
            for name, summary in summaries.items()
        },
        "palette": [swatch.as_dict() for swatch in palette],
        "directives": seed.directives,
        "seed_language": seed.seed_language,
    }

    json_path = emit_dir / f"{stem}.json"
    json_path.write_text(json.dumps(json_payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    story_lines = [
        f"# {seed.agent_name} · Palette {palette_id or 'draft'}",
        "",
        f"Generated at {timestamp} UTC",
        "",
        "## Purpose",
        seed.purpose,
        "",
        "## Telemetry Sketch",
        f"Source: {telemetry_source or 'none supplied'}",
        f"Samples analysed: {sum(summary.count for summary in summaries.values())}",
        f"Mood: {_classify_mood(palette)}",
        "",
        "## Palette", 
    ]
    for swatch in palette:
        story_lines.append(f"- **{swatch.metric}** → {swatch.hex_code} ({swatch.description})")
    if not palette:
        story_lines.append("- Silence → #776f68 (muted calm)")

    story_lines.extend(
        [
            "",
            "## Directives Honoured",
        ]
    )
    for directive in seed.directives:
        story_lines.append(f"- {directive}")

    story_lines.extend(
        [
            "",
            "## Behavioural Loop",
            " → ".join(seed.behavioural_loop) if seed.behavioural_loop else "(no loop recorded)",
            "",
            "---",
            "",
            seed.seed_language,
        ]
    )

    story_path = emit_dir / f"{stem}.md"
    story_path.write_text("\n".join(story_lines) + "\n", encoding="utf-8")

    return {"svg": svg_path, "json": json_path, "story": story_path}


# ---------------------------------------------------------------------------
# Command-line interface
# ---------------------------------------------------------------------------


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Codex-7 Painter — palette generator")
    parser.add_argument("--seed", default="codex7.yaml", help="Seed definition file (relative to lucidia or absolute path)")
    parser.add_argument("--emit", default="/codex/prompts/next/", help="Directory for generated artefacts (repo-relative if prefixed with /)")
    parser.add_argument("--source", help="Telemetry source (file or directory containing JSON/JSONL)")
    parser.add_argument("--width", type=int, default=1280, help="SVG width in pixels")
    parser.add_argument("--height", type=int, default=720, help="SVG height in pixels")
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)

    seed_path = _resolve_seed_path(args.seed)
    seed = load_seed(seed_path)

    emit_dir = _resolve_emit_dir(args.emit)
    telemetry_records = load_telemetry(args.source)
    summaries = summarise_numeric_streams(telemetry_records)
    palette = build_palette(seed, summaries)

    outputs = write_outputs(
        seed,
        palette,
        summaries,
        emit_dir,
        telemetry_source=args.source,
        width=max(64, args.width),
        height=max(64, args.height),
    )

    print(f"[painter] seed loaded: {seed_path}")
    print(f"[painter] telemetry records processed: {len(telemetry_records)}")
    print(f"[painter] palette size: {len(palette)}")
    for label, path in outputs.items():
        print(f"[painter] wrote {label}: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
