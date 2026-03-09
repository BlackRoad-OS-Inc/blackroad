#!/usr/bin/env python3
"""Codex-19 Geologist agent implementation.

The Geologist listens for long-term pressure across the Lucidia substrate. It
transforms strata observations into:

* stress maps that summarise how pressure accumulates,
* foundation reports that highlight cracks before they spread,
* continuity briefs that provide temporal context for sibling agents, and
* markdown core samples that archive what was learned each epoch.

The implementation honours the Codex-19 charter by favouring patient analysis
and preserving historical context over quick reactions.
"""

from __future__ import annotations

import argparse
import json
import statistics
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Optional

import yaml

DEFAULT_STATE_ROOT = Path("/srv/lucidia/geologist")
DEFAULT_EMIT_ROOT = Path("/codex/prompts/next")
STRATA_LOG_NAME = "strata_log.jsonl"
STATE_FILENAME = "state.json"
STRESS_MAP_NAME = "stress_map.json"
FOUNDATION_REPORT_NAME = "foundation_report.json"
CORE_SAMPLE_NAME = "core_sample.md"
CONTINUITY_BRIEF_NAME = "continuity_brief.json"
MAX_HISTORY = 256


# ---------------------------------------------------------------------------
# Seed parsing
# ---------------------------------------------------------------------------


def _ensure_list(value: Any) -> List[str]:
    """Return *value* as a clean list of strings."""

    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        stripped = value.strip()
        return [stripped] if stripped else []
    raise TypeError(f"Expected list-compatible value, got {type(value)!r}")


@dataclass
class GeologistSeed:
    """Structured representation of the Geologist seed manifest."""

    identifier: str
    agent_name: str
    generation: str
    parent: Optional[str]
    siblings: List[str]
    domain: List[str]
    moral_constant: str
    core_principle: str
    purpose: str
    directives: List[str]
    jobs: List[str]
    personality: Mapping[str, Any]
    input_channels: List[str]
    output_channels: List[str]
    behavioural_loop: List[str]
    seed_language: str
    boot_command: str


def _resolve_seed_path(value: str) -> Path:
    path = Path(value)
    if path.exists():
        return path
    fallback = Path(__file__).resolve().parent / value
    return fallback


def load_seed(path: Path) -> GeologistSeed:
    """Load and validate the Geologist seed file."""

    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}

    if not isinstance(data, MutableMapping):
        raise ValueError("Geologist seed must be a mapping at the top level")

    charter = data.get("system_charter")
    if not isinstance(charter, MutableMapping):
        raise ValueError("Geologist seed missing 'system_charter' mapping")

    required_charter = [
        "agent_name",
        "generation",
        "domain",
        "moral_constant",
        "core_principle",
    ]
    missing_charter = [field for field in required_charter if field not in charter]
    if missing_charter:
        joined = ", ".join(missing_charter)
        raise ValueError(f"Geologist seed missing charter field(s): {joined}")

    for required in [
        "purpose",
        "directives",
        "jobs",
        "input",
        "output",
        "behavioral_loop",
        "seed_language",
        "boot_command",
    ]:
        if required not in data:
            raise ValueError(f"Geologist seed missing required field: {required}")

    return GeologistSeed(
        identifier=str(data.get("id", "codex-19")),
        agent_name=str(charter["agent_name"]),
        generation=str(charter["generation"]),
        parent=str(charter.get("parent")) if charter.get("parent") else None,
        siblings=_ensure_list(charter.get("siblings")),
        domain=_ensure_list(charter.get("domain")),
        moral_constant=str(charter["moral_constant"]),
        core_principle=str(charter["core_principle"]),
        purpose=str(data["purpose"]).strip(),
        directives=_ensure_list(data["directives"]),
        jobs=_ensure_list(data["jobs"]),
        personality=data.get("personality", {}),
        input_channels=_ensure_list(data["input"]),
        output_channels=_ensure_list(data["output"]),
        behavioural_loop=_ensure_list(data["behavioral_loop"]),
        seed_language=str(data["seed_language"]).strip(),
        boot_command=str(data["boot_command"]).strip(),
    )


# ---------------------------------------------------------------------------
# Runtime state and observations
# ---------------------------------------------------------------------------


@dataclass
class GeologistState:
    """Mutable runtime state persisted between runs."""

    offsets: Dict[str, int] = field(default_factory=lambda: {"strata_log": 0})
    pressure_history: Dict[str, List[float]] = field(default_factory=dict)
    depth_history: Dict[str, List[float]] = field(default_factory=dict)
    last_epoch: Optional[str] = None

    @classmethod
    def load(cls, path: Path) -> "GeologistState":
        if not path.exists():
            return cls()
        try:
            with path.open("r", encoding="utf-8") as handle:
                payload = json.load(handle)
        except (OSError, json.JSONDecodeError):
            return cls()
        return cls(
            offsets=payload.get("offsets", {"strata_log": 0}),
            pressure_history={
                key: [float(sample) for sample in values]
                for key, values in payload.get("pressure_history", {}).items()
            },
            depth_history={
                key: [float(sample) for sample in values]
                for key, values in payload.get("depth_history", {}).items()
            },
            last_epoch=payload.get("last_epoch"),
        )

    def save(self, path: Path) -> None:
        payload = {
            "offsets": self.offsets,
            "pressure_history": self.pressure_history,
            "depth_history": self.depth_history,
            "last_epoch": self.last_epoch,
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)


@dataclass
class StrataObservation:
    """Structured representation of a single strata log entry."""

    identifier: str
    pressure_kpa: float
    depth_m: float
    timestamp: datetime
    location: str
    material: Optional[str]
    notes: Optional[str]
    pressure_index: float
    metadata: Mapping[str, Any]

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "StrataObservation":
        identifier = str(
            payload.get("id")
            or payload.get("observation_id")
            or payload.get("sample_id")
            or "anonymous"
        )

        def _float(name: str, *aliases: str, default: float = 0.0) -> float:
            for key in (name, *aliases):
                value = payload.get(key)
                if value is None:
                    continue
                try:
                    return float(value)
                except (TypeError, ValueError):
                    continue
            return float(default)

        pressure_kpa = _float("pressure", "pressure_kpa", "stress", default=0.0)
        depth_m = _float("depth", "depth_m", "elevation", default=0.0)

        timestamp_value = payload.get("timestamp") or payload.get("time")
        if timestamp_value:
            try:
                timestamp = datetime.fromisoformat(str(timestamp_value))
                if timestamp.tzinfo is None:
                    timestamp = timestamp.replace(tzinfo=timezone.utc)
            except ValueError:
                timestamp = datetime.now(timezone.utc)
        else:
            timestamp = datetime.now(timezone.utc)

        location = str(payload.get("location") or payload.get("site") or "unknown").strip()
        material = payload.get("material")
        notes = payload.get("notes")

        pressure_index = pressure_kpa * (1 + max(depth_m, 0.0) / 1000.0)

        metadata = {
            key: value
            for key, value in payload.items()
            if key
            not in {
                "id",
                "observation_id",
                "sample_id",
                "pressure",
                "pressure_kpa",
                "stress",
                "depth",
                "depth_m",
                "elevation",
                "timestamp",
                "time",
                "location",
                "site",
                "material",
                "notes",
            }
        }

        return cls(
            identifier=identifier,
            pressure_kpa=pressure_kpa,
            depth_m=depth_m,
            timestamp=timestamp,
            location=location or "unknown",
            material=str(material) if material is not None else None,
            notes=str(notes) if notes is not None else None,
            pressure_index=pressure_index,
            metadata=metadata,
        )

    def to_summary(self) -> Dict[str, Any]:
        return {
            "id": self.identifier,
            "location": self.location,
            "pressure_kpa": round(self.pressure_kpa, 3),
            "depth_m": round(self.depth_m, 3),
            "timestamp": self.timestamp.isoformat(),
            "pressure_index": round(self.pressure_index, 3),
            "material": self.material,
        }


# ---------------------------------------------------------------------------
# Geologist core logic
# ---------------------------------------------------------------------------


class Geologist:
    """Implements the Codex-19 Geologist behavioural loop."""

    def __init__(
        self,
        *,
        seed: GeologistSeed,
        state_root: Path,
        emit_dir: Path,
        strata_log: Optional[Path] = None,
        pressure_threshold: float = 275.0,
        depth_threshold: float = 1500.0,
    ) -> None:
        self.seed = seed
        self.state_root = state_root
        self.emit_dir = emit_dir
        self.emit_dir.mkdir(parents=True, exist_ok=True)
        self.state_path = state_root / STATE_FILENAME
        self.strata_log = strata_log or state_root / STRATA_LOG_NAME
        self.pressure_threshold = pressure_threshold
        self.depth_threshold = depth_threshold
        self.state = GeologistState.load(self.state_path)

    # ------------------------------------------------------------------
    def run(self) -> None:
        observations = self._tail_strata_log()
        if observations:
            self._update_state(observations)
        generated_at = datetime.now(timezone.utc)

        stress_map = self._build_stress_map()
        foundation_report = self._build_foundation_report(observations, generated_at)
        core_sample = self._render_core_sample(observations, stress_map, foundation_report, generated_at)
        continuity_brief = self._build_continuity_brief(observations, stress_map, generated_at)

        self._write_json(self.emit_dir / STRESS_MAP_NAME, stress_map)
        self._write_json(self.emit_dir / FOUNDATION_REPORT_NAME, foundation_report)
        self._write_text(self.emit_dir / CORE_SAMPLE_NAME, core_sample)
        self._write_json(self.emit_dir / CONTINUITY_BRIEF_NAME, continuity_brief)

        self.state.last_epoch = generated_at.isoformat()
        self.state.save(self.state_path)

    # ------------------------------------------------------------------
    def _tail_strata_log(self) -> List[StrataObservation]:
        offset = self.state.offsets.get("strata_log", 0)
        if not self.strata_log.exists():
            self.state.offsets["strata_log"] = 0
            return []

        try:
            with self.strata_log.open("r", encoding="utf-8") as handle:
                handle.seek(offset)
                lines = handle.readlines()
                new_offset = handle.tell()
        except OSError:
            return []

        observations: List[StrataObservation] = []
        for raw_line in lines:
            stripped = raw_line.strip()
            if not stripped:
                continue
            try:
                payload = json.loads(stripped)
            except json.JSONDecodeError:
                continue
            if not isinstance(payload, Mapping):
                continue
            observations.append(StrataObservation.from_mapping(payload))

        self.state.offsets["strata_log"] = new_offset
        return observations

    # ------------------------------------------------------------------
    def _update_state(self, observations: Iterable[StrataObservation]) -> None:
        for observation in observations:
            location = observation.location or "unknown"
            pressure_series = self.state.pressure_history.setdefault(location, [])
            depth_series = self.state.depth_history.setdefault(location, [])
            pressure_series.append(observation.pressure_kpa)
            depth_series.append(observation.depth_m)
            if len(pressure_series) > MAX_HISTORY:
                del pressure_series[0 : len(pressure_series) - MAX_HISTORY]
            if len(depth_series) > MAX_HISTORY:
                del depth_series[0 : len(depth_series) - MAX_HISTORY]

    # ------------------------------------------------------------------
    def _build_stress_map(self) -> Dict[str, Any]:
        stress_map: Dict[str, Any] = {
            "agent": self.seed.agent_name,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "locations": {},
        }
        for location, pressures in sorted(self.state.pressure_history.items()):
            if not pressures:
                continue
            depths = self.state.depth_history.get(location, [])
            entry: Dict[str, Any] = {
                "average_pressure_kpa": round(statistics.fmean(pressures), 3),
                "max_pressure_kpa": round(max(pressures), 3),
                "min_pressure_kpa": round(min(pressures), 3),
                "pressure_samples": len(pressures),
                "pressure_trend": self._trend(pressures),
            }
            if depths:
                entry["average_depth_m"] = round(statistics.fmean(depths), 3)
                entry["depth_range_m"] = [round(min(depths), 3), round(max(depths), 3)]
            stress_map["locations"][location] = entry
        return stress_map

    # ------------------------------------------------------------------
    def _build_foundation_report(
        self,
        observations: Iterable[StrataObservation],
        generated_at: datetime,
    ) -> Dict[str, Any]:
        alerts: List[Dict[str, Any]] = []
        deep_sites: List[Dict[str, Any]] = []
        for observation in observations:
            if observation.pressure_kpa >= self.pressure_threshold:
                alerts.append(
                    {
                        "observation": observation.to_summary(),
                        "severity": "high" if observation.pressure_kpa >= self.pressure_threshold * 1.2 else "elevated",
                        "message": "pressure spike approaching eruption",
                    }
                )
            if abs(observation.depth_m) >= self.depth_threshold:
                deep_sites.append(
                    {
                        "observation": observation.to_summary(),
                        "message": "deep stratum under review",
                    }
                )

        steady_layers = self._steady_layers()

        return {
            "agent": self.seed.agent_name,
            "generated_at": generated_at.isoformat(),
            "pressure_threshold_kpa": self.pressure_threshold,
            "depth_threshold_m": self.depth_threshold,
            "pressure_alerts": alerts,
            "deep_sites": deep_sites,
            "steady_layers": steady_layers,
        }

    # ------------------------------------------------------------------
    def _steady_layers(self) -> List[Dict[str, Any]]:
        layers: List[Dict[str, Any]] = []
        for location, pressures in self.state.pressure_history.items():
            if len(pressures) < 3:
                continue
            variation = max(pressures) - min(pressures)
            if variation <= max(self.pressure_threshold * 0.2, 5.0):
                layers.append(
                    {
                        "location": location,
                        "pressure_variation": round(variation, 3),
                        "samples": len(pressures),
                    }
                )
        return layers

    # ------------------------------------------------------------------
    def _render_core_sample(
        self,
        observations: Iterable[StrataObservation],
        stress_map: Mapping[str, Any],
        foundation_report: Mapping[str, Any],
        generated_at: datetime,
    ) -> str:
        lines = [
            "# Codex-19 Geologist Core Sample",
            f"*Epoch:* {generated_at.isoformat()}",
            f"*Moral constant:* {self.seed.moral_constant}",
            "",
            "## New Observations",
        ]
        observations = list(observations)
        if not observations:
            lines.append("No fresh strata were uncovered; the layer was reread for continuity.")
        else:
            for obs in observations:
                parts = [
                    f"- `{obs.identifier}` at {obs.location}",
                    f"  pressure {obs.pressure_kpa:.2f} kPa at depth {obs.depth_m:.2f} m",
                    f"  pressure index {obs.pressure_index:.2f}",
                ]
                if obs.notes:
                    parts.append(f"  note: {obs.notes}")
                lines.extend(parts)
        lines.append("")
        lines.append("## Stress Map Highlights")
        locations = stress_map.get("locations", {})
        if not locations:
            lines.append("No stress data available yet.")
        else:
            for location, entry in locations.items():
                trend = entry.get("pressure_trend", {})
                lines.append(
                    "- {loc}: avg {avg:.2f} kPa (Δ {delta:+.2f}), samples {samples}".format(
                        loc=location,
                        avg=entry.get("average_pressure_kpa", 0.0),
                        delta=trend.get("delta", 0.0),
                        samples=entry.get("pressure_samples", 0),
                    )
                )
        lines.append("")
        lines.append("## Foundation Notes")
        alerts = foundation_report.get("pressure_alerts", [])
        if alerts:
            lines.append("Pressure alerts:")
            for alert in alerts:
                summary = alert.get("observation", {})
                lines.append(
                    "  - {loc} `{identifier}` at {pressure:.1f} kPa ({severity})".format(
                        loc=summary.get("location", "unknown"),
                        identifier=summary.get("id", "?"),
                        pressure=summary.get("pressure_kpa", 0.0),
                        severity=alert.get("severity", "elevated"),
                    )
                )
        else:
            lines.append("No pressure spikes crossed the caution line.")
        steady_layers = foundation_report.get("steady_layers", [])
        if steady_layers:
            lines.append("Steady layers providing continuity:")
            for layer in steady_layers:
                lines.append(
                    "  - {loc}: variation {variation:.2f} kPa across {samples} samples".format(
                        loc=layer.get("location", "unknown"),
                        variation=layer.get("pressure_variation", 0.0),
                        samples=layer.get("samples", 0),
                    )
                )
        lines.append("")
        lines.append("## Closing Trace")
        lines.append(self.seed.seed_language)
        return "\n".join(lines) + "\n"

    # ------------------------------------------------------------------
    def _build_continuity_brief(
        self,
        observations: Iterable[StrataObservation],
        stress_map: Mapping[str, Any],
        generated_at: datetime,
    ) -> Dict[str, Any]:
        observations = list(observations)
        if observations:
            avg_pressure_index = statistics.fmean(obs.pressure_index for obs in observations)
        else:
            avg_pressure_index = 0.0
        return {
            "agent": self.seed.agent_name,
            "epoch": generated_at.isoformat(),
            "observation_count": len(observations),
            "average_pressure_index": round(avg_pressure_index, 3),
            "locations": sorted(stress_map.get("locations", {}).keys()),
            "directives": self.seed.directives,
        }

    # ------------------------------------------------------------------
    def _trend(self, series: Iterable[float]) -> Dict[str, Any]:
        values = list(series)
        if len(values) < 2:
            return {"delta": 0.0, "direction": "steady"}
        window = min(3, len(values))
        start_avg = statistics.fmean(values[:window])
        end_avg = statistics.fmean(values[-window:])
        delta = end_avg - start_avg
        direction = "steady"
        if delta > 0.5:
            direction = "rising"
        elif delta < -0.5:
            direction = "falling"
        return {"delta": round(delta, 3), "direction": direction}

    # ------------------------------------------------------------------
    def _write_json(self, path: Path, payload: Mapping[str, Any]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)

    # ------------------------------------------------------------------
    def _write_text(self, path: Path, content: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as handle:
            handle.write(content)


# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Codex-19 Geologist agent")
    parser.add_argument("--seed", default="codex19.yaml", help="Path to the seed manifest")
    parser.add_argument(
        "--state-root",
        default=str(DEFAULT_STATE_ROOT),
        help="State directory used to persist offsets and aggregates",
    )
    parser.add_argument(
        "--emit",
        default=str(DEFAULT_EMIT_ROOT),
        help="Directory for emitted artefacts",
    )
    parser.add_argument(
        "--log",
        dest="strata_log",
        default=None,
        help="Optional path to a strata observation log",
    )
    parser.add_argument(
        "--pressure-threshold",
        type=float,
        default=275.0,
        help="Pressure threshold in kPa that triggers alerts",
    )
    parser.add_argument(
        "--depth-threshold",
        type=float,
        default=1500.0,
        help="Depth magnitude in metres that triggers deep site review",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> None:
    args = parse_args(argv)
    seed_path = _resolve_seed_path(args.seed)
    seed = load_seed(seed_path)

    state_root = Path(args.state_root)
    state_root.mkdir(parents=True, exist_ok=True)
    emit_dir = Path(args.emit)
    strata_log = Path(args.strata_log) if args.strata_log else None

    agent = Geologist(
        seed=seed,
        state_root=state_root,
        emit_dir=emit_dir,
        strata_log=strata_log,
        pressure_threshold=args.pressure_threshold,
        depth_threshold=args.depth_threshold,
    )
    agent.run()


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    main()
