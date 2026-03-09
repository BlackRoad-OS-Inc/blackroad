#!/usr/bin/env python3
"""Codex-21 Physicist agent implementation.

The Physicist listens for the balance underneath motion. It ingests hardware and
agent telemetry, models energy flows, sketches feedback systems that reclaim
waste heat, and records the evolving "laws" that bind the BlackRoad swarm.

The implementation mirrors the charter encoded within ``codex21.yaml`` by:

* grounding every run on measured observations (or clearly stating when data is
  absent),
* keeping beauty with accuracy by producing both structured artefacts and a
  lyrical field journal,
* preserving momentum gently by preferring feedback suggestions over coercive
  commands, and
* translating complex telemetry into forces that collaborating agents can feel.
"""

from __future__ import annotations

import argparse
import json
import math
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean, pstdev
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Optional, Sequence

import yaml

DEFAULT_STATE_ROOT = Path("/srv/lucidia/physicist")
ENERGY_LOG_NAME = "energy_flow.jsonl"
FORCE_LOG_NAME = "agent_forces.jsonl"
ENERGY_MAP_NAME = "energy_map.json"
FEEDBACK_FILE_NAME = "feedback_loops.json"
LAW_RECORD_NAME = "laws.json"
FIELD_JOURNAL_NAME = "field_journal.md"
STATE_FILENAME = "state.json"


# ---------------------------------------------------------------------------
# Seed loading utilities
# ---------------------------------------------------------------------------


def _ensure_list(value: Any) -> List[str]:
    """Return *value* coerced into a list of clean strings."""

    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        stripped = value.strip()
        return [stripped] if stripped else []
    raise TypeError(f"Expected list-compatible value, received {type(value)!r}")


@dataclass
class PhysicistSeed:
    """Structured representation of the Physicist seed manifest."""

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


def load_seed(path: Path) -> PhysicistSeed:
    """Load and validate the Physicist seed file."""

    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}

    if not isinstance(data, MutableMapping):
        raise ValueError("Physicist seed must be a mapping at the top level")

    charter = data.get("system_charter")
    if not isinstance(charter, MutableMapping):
        raise ValueError("Physicist seed missing 'system_charter' mapping")

    required_charter = [
        "agent_name",
        "generation",
        "domain",
        "moral_constant",
        "core_principle",
    ]
    missing_charter = [field for field in required_charter if field not in charter]
    if missing_charter:
        raise ValueError(
            "Physicist seed missing charter field(s): " + ", ".join(missing_charter)
        )

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
            raise ValueError(f"Physicist seed missing required field: {required}")

    return PhysicistSeed(
        identifier=str(data.get("id", "codex-21")),
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
# Persistent state
# ---------------------------------------------------------------------------


@dataclass
class PhysicistState:
    """Runtime state maintained between Physicist runs."""

    constants: List[Mapping[str, Any]] = field(default_factory=list)
    anomalies: List[Mapping[str, Any]] = field(default_factory=list)
    last_run: Optional[str] = None

    @classmethod
    def load(cls, path: Path) -> "PhysicistState":
        if not path.exists():
            return cls()
        try:
            with path.open("r", encoding="utf-8") as handle:
                payload = json.load(handle)
        except (OSError, json.JSONDecodeError):
            return cls()
        return cls(
            constants=list(payload.get("constants", [])),
            anomalies=list(payload.get("anomalies", [])),
            last_run=payload.get("last_run"),
        )

    def save(self, path: Path) -> None:
        payload = {
            "constants": self.constants,
            "anomalies": self.anomalies,
            "last_run": self.last_run,
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)


# ---------------------------------------------------------------------------
# Observation structures
# ---------------------------------------------------------------------------


def _coerce_float(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return float(default)


def _normalise_load(value: Any) -> float:
    load = _coerce_float(value, default=0.0)
    if not math.isfinite(load):
        return 0.0
    if load < 0.0:
        return 0.0
    if load > 1.0:
        return 1.0
    return load


def _parse_timestamp(value: Any) -> datetime:
    if isinstance(value, datetime):
        return value.astimezone(timezone.utc)
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(float(value), tz=timezone.utc)
    if value:
        text = str(value)
        try:
            return datetime.fromisoformat(text.replace("Z", "+00:00"))
        except ValueError:
            pass
    return datetime.now(timezone.utc)


@dataclass
class EnergySample:
    """Snapshot of energy transfer for a node or agent."""

    timestamp: datetime
    node: str
    agent: str
    energy_in: float
    energy_out: float
    waste_heat: float
    temperature: float
    load: float
    tags: List[str]
    metadata: Mapping[str, Any]

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "EnergySample":
        timestamp = _parse_timestamp(payload.get("timestamp") or payload.get("time"))
        node = str(payload.get("node") or payload.get("location") or "unknown")
        agent = str(payload.get("agent") or payload.get("process") or "unknown")
        energy_in = _coerce_float(payload.get("energy_in") or payload.get("input_energy"), default=0.0)
        energy_out = _coerce_float(
            payload.get("energy_out") or payload.get("output_energy"), default=0.0
        )
        waste_heat = _coerce_float(
            payload.get("waste_heat")
            or payload.get("heat_loss")
            or (energy_in - energy_out if energy_in >= energy_out else 0.0),
            default=0.0,
        )
        temperature = _coerce_float(
            payload.get("temperature") or payload.get("temp") or payload.get("kelvin"),
            default=298.15,
        )
        load = _normalise_load(payload.get("load") or payload.get("utilisation"))
        tags = _ensure_list(payload.get("tags"))
        metadata = {
            key: value
            for key, value in payload.items()
            if key
            not in {
                "timestamp",
                "time",
                "node",
                "location",
                "agent",
                "process",
                "energy_in",
                "input_energy",
                "energy_out",
                "output_energy",
                "waste_heat",
                "heat_loss",
                "temperature",
                "temp",
                "kelvin",
                "load",
                "utilisation",
                "tags",
            }
        }
        return cls(
            timestamp=timestamp,
            node=node,
            agent=agent,
            energy_in=energy_in,
            energy_out=energy_out,
            waste_heat=waste_heat,
            temperature=temperature,
            load=load,
            tags=tags,
            metadata=metadata,
        )

    @property
    def efficiency(self) -> float:
        if self.energy_in <= 0.0:
            return 0.0
        return max(min(self.energy_out / self.energy_in, 2.0), 0.0)

    @property
    def waste_heat_ratio(self) -> float:
        if self.energy_in <= 0.0:
            return 0.0
        ratio = self.waste_heat / self.energy_in
        if not math.isfinite(ratio):
            return 0.0
        return max(ratio, 0.0)

    def as_dict(self) -> Dict[str, Any]:
        return {
            "timestamp": self.timestamp.astimezone(timezone.utc).isoformat(),
            "node": self.node,
            "agent": self.agent,
            "energy_in": self.energy_in,
            "energy_out": self.energy_out,
            "waste_heat": self.waste_heat,
            "temperature": self.temperature,
            "load": self.load,
            "efficiency": self.efficiency,
            "waste_heat_ratio": self.waste_heat_ratio,
            "tags": self.tags,
            "metadata": self.metadata,
        }


def _pair_key(source: str, target: str) -> str:
    return "::".join(sorted([source, target]))


@dataclass
class ForceObservation:
    """Observation of a simulated force between two agents."""

    timestamp: datetime
    source: str
    target: str
    magnitude: float
    alignment: float
    notes: str

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "ForceObservation":
        timestamp = _parse_timestamp(payload.get("timestamp") or payload.get("time"))
        participants: Sequence[str]
        if "agents" in payload and isinstance(payload["agents"], Sequence):
            agents = [str(item) for item in payload["agents"] if str(item).strip()]
            if len(agents) >= 2:
                participants = agents[:2]
            else:
                participants = [str(payload.get("source") or "unknown"), str(payload.get("target") or "field")]
        else:
            participants = [
                str(payload.get("source") or "unknown"),
                str(payload.get("target") or payload.get("against") or "field"),
            ]
        source, target = participants[0], participants[1]
        magnitude = abs(_coerce_float(payload.get("magnitude") or payload.get("force"), default=0.0))
        alignment = max(min(_coerce_float(payload.get("alignment"), default=0.0), 1.0), -1.0)
        notes = str(payload.get("notes") or payload.get("summary") or "")
        return cls(
            timestamp=timestamp,
            source=source,
            target=target,
            magnitude=magnitude,
            alignment=alignment,
            notes=notes,
        )

    def as_dict(self) -> Dict[str, Any]:
        return {
            "timestamp": self.timestamp.astimezone(timezone.utc).isoformat(),
            "source": self.source,
            "target": self.target,
            "magnitude": self.magnitude,
            "alignment": self.alignment,
            "notes": self.notes,
        }


# ---------------------------------------------------------------------------
# Physicist core
# ---------------------------------------------------------------------------


class Physicist:
    """Main coordination class for the Physicist agent."""

    def __init__(
        self,
        seed: PhysicistSeed,
        state_root: Path,
        emit_dir: Path,
        energy_log: Optional[Path] = None,
        force_log: Optional[Path] = None,
    ) -> None:
        self.seed = seed
        self.state_root = state_root
        self.emit_dir = emit_dir
        self.energy_log = energy_log or (state_root / ENERGY_LOG_NAME)
        self.force_log = force_log or (state_root / FORCE_LOG_NAME)
        self.state_path = state_root / STATE_FILENAME
        self.state = PhysicistState.load(self.state_path)
        self.emit_dir.mkdir(parents=True, exist_ok=True)

    # ------------------------------------------------------------------
    def _load_json_lines(self, path: Path) -> List[Mapping[str, Any]]:
        if not path.exists():
            return []
        records: List[Mapping[str, Any]] = []
        try:
            if path.suffix.lower() == ".jsonl":
                with path.open("r", encoding="utf-8") as handle:
                    for raw_line in handle:
                        raw_line = raw_line.strip()
                        if not raw_line:
                            continue
                        try:
                            record = json.loads(raw_line)
                        except json.JSONDecodeError:
                            continue
                        if isinstance(record, MutableMapping):
                            records.append(record)
            else:
                with path.open("r", encoding="utf-8") as handle:
                    payload = json.load(handle)
                if isinstance(payload, list):
                    records.extend(item for item in payload if isinstance(item, MutableMapping))
                elif isinstance(payload, MutableMapping):
                    records.append(payload)
        except OSError:
            return []
        return records

    # ------------------------------------------------------------------
    def _load_energy_samples(self) -> List[EnergySample]:
        samples: List[EnergySample] = []
        for record in self._load_json_lines(self.energy_log):
            try:
                samples.append(EnergySample.from_mapping(record))
            except Exception:
                continue
        return sorted(samples, key=lambda sample: sample.timestamp)

    # ------------------------------------------------------------------
    def _load_force_observations(self) -> List[ForceObservation]:
        observations: List[ForceObservation] = []
        for record in self._load_json_lines(self.force_log):
            try:
                observations.append(ForceObservation.from_mapping(record))
            except Exception:
                continue
        return sorted(observations, key=lambda obs: obs.timestamp)

    # ------------------------------------------------------------------
    def _aggregate_energy(self, samples: Sequence[EnergySample]) -> Dict[str, Any]:
        totals = {
            "count": len(samples),
            "energy_in": 0.0,
            "energy_out": 0.0,
            "waste_heat": 0.0,
            "average_temperature": 0.0,
            "average_load": 0.0,
            "mean_efficiency": 0.0,
        }
        if not samples:
            return {"system": totals, "by_agent": {}, "by_node": {}}

        def _update(summary: Dict[str, Any], sample: EnergySample) -> None:
            summary.setdefault("count", 0)
            summary.setdefault("energy_in", 0.0)
            summary.setdefault("energy_out", 0.0)
            summary.setdefault("waste_heat", 0.0)
            summary.setdefault("temperatures", [])
            summary.setdefault("loads", [])
            summary.setdefault("efficiencies", [])
            summary["count"] += 1
            summary["energy_in"] += sample.energy_in
            summary["energy_out"] += sample.energy_out
            summary["waste_heat"] += sample.waste_heat
            summary["temperatures"].append(sample.temperature)
            summary["loads"].append(sample.load)
            summary["efficiencies"].append(sample.efficiency)

        by_agent: Dict[str, Dict[str, Any]] = {}
        by_node: Dict[str, Dict[str, Any]] = {}

        for sample in samples:
            totals["energy_in"] += sample.energy_in
            totals["energy_out"] += sample.energy_out
            totals["waste_heat"] += sample.waste_heat
            by_agent.setdefault(sample.agent, {})
            by_node.setdefault(sample.node, {})
            _update(by_agent[sample.agent], sample)
            _update(by_node[sample.node], sample)

        def _finalise(summary: Dict[str, Any]) -> Dict[str, Any]:
            count = summary.get("count", 0)
            temperatures: List[float] = list(summary.pop("temperatures", []))
            loads: List[float] = list(summary.pop("loads", []))
            efficiencies: List[float] = list(summary.pop("efficiencies", []))
            summary["average_temperature"] = mean(temperatures) if temperatures else 0.0
            summary["average_load"] = mean(loads) if loads else 0.0
            summary["mean_efficiency"] = mean(efficiencies) if efficiencies else 0.0
            summary["efficiency_stdev"] = pstdev(efficiencies) if len(efficiencies) > 1 else 0.0
            summary["energy_in"] = summary.get("energy_in", 0.0)
            summary["energy_out"] = summary.get("energy_out", 0.0)
            summary["waste_heat"] = summary.get("waste_heat", 0.0)
            summary["count"] = count
            return summary

        for key, summary in list(by_agent.items()):
            by_agent[key] = _finalise(summary)
        for key, summary in list(by_node.items()):
            by_node[key] = _finalise(summary)

        totals["average_temperature"] = mean([sample.temperature for sample in samples])
        totals["average_load"] = mean([sample.load for sample in samples])
        totals["mean_efficiency"] = mean([sample.efficiency for sample in samples])
        totals["efficiency_stdev"] = (
            pstdev([sample.efficiency for sample in samples])
            if len(samples) > 1
            else 0.0
        )

        return {"system": totals, "by_agent": by_agent, "by_node": by_node}

    # ------------------------------------------------------------------
    def _design_feedback(self, samples: Sequence[EnergySample]) -> List[Mapping[str, Any]]:
        if not samples:
            return []
        feedback: Dict[str, Dict[str, Any]] = {}
        for sample in samples:
            entry = feedback.setdefault(
                sample.agent,
                {
                    "agent": sample.agent,
                    "samples": 0,
                    "mean_efficiency": 0.0,
                    "reuse_score": 0.0,
                    "average_load": 0.0,
                },
            )
            entry["samples"] += 1
            entry.setdefault("efficiencies", []).append(sample.efficiency)
            reuse = 1.0 - min(sample.waste_heat_ratio, 1.0)
            entry.setdefault("reuse_scores", []).append(max(min(reuse, 1.0), 0.0))
            entry.setdefault("loads", []).append(sample.load)

        results: List[Mapping[str, Any]] = []
        for entry in feedback.values():
            efficiencies: List[float] = entry.pop("efficiencies", [])
            reuse_scores: List[float] = entry.pop("reuse_scores", [])
            loads: List[float] = entry.pop("loads", [])
            mean_eff = mean(efficiencies) if efficiencies else 0.0
            reuse_score = mean(reuse_scores) if reuse_scores else 0.0
            average_load = mean(loads) if loads else 0.0
            suggestion: str
            if reuse_score < 0.6:
                suggestion = (
                    "Route waste heat into learning loops; couple with Chemist cooling "
                    "channels to lift reuse score."
                )
            elif average_load > 0.9:
                suggestion = (
                    "Load nearing saturation; stagger bursts or borrow capacity from Navigator nodes."
                )
            else:
                suggestion = "Balance steady; maintain feedback sensors and log drift weekly."
            results.append(
                {
                    "agent": entry["agent"],
                    "samples": entry["samples"],
                    "mean_efficiency": mean_eff,
                    "average_load": average_load,
                    "reuse_score": reuse_score,
                    "suggestion": suggestion,
                }
            )

        results.sort(key=lambda item: item["reuse_score"], reverse=True)
        return results

    # ------------------------------------------------------------------
    def _summarise_forces(self, observations: Sequence[ForceObservation]) -> Dict[str, Any]:
        if not observations:
            return {"pairs": {}, "recent": []}
        pairs: Dict[str, Dict[str, Any]] = {}
        recent: List[Dict[str, Any]] = []
        for obs in observations:
            key = _pair_key(obs.source, obs.target)
            bucket = pairs.setdefault(
                key,
                {
                    "agents": sorted({obs.source, obs.target}),
                    "count": 0,
                    "magnitudes": [],
                    "alignments": [],
                    "notes": [],
                },
            )
            bucket["count"] += 1
            bucket["magnitudes"].append(obs.magnitude)
            bucket["alignments"].append(obs.alignment)
            if obs.notes:
                bucket["notes"].append(obs.notes)
            recent.append(obs.as_dict())
        for key, bucket in pairs.items():
            magnitudes = bucket.pop("magnitudes", [])
            alignments = bucket.pop("alignments", [])
            bucket["mean_magnitude"] = mean(magnitudes) if magnitudes else 0.0
            bucket["alignment"] = mean(alignments) if alignments else 0.0
            bucket["equilibrium"] = bucket["mean_magnitude"] < 0.35 and abs(bucket["alignment"]) > 0.5
            if bucket.get("notes"):
                bucket["notes"] = bucket["notes"][-3:]
        recent.sort(key=lambda item: item["timestamp"], reverse=True)
        return {"pairs": pairs, "recent": recent[:10]}

    # ------------------------------------------------------------------
    def _derive_laws(
        self,
        samples: Sequence[EnergySample],
        energy_summary: Mapping[str, Any],
        force_summary: Mapping[str, Any],
    ) -> Dict[str, Any]:
        constants: List[Dict[str, Any]] = []
        anomalies: List[Dict[str, Any]] = []

        by_agent: Mapping[str, Mapping[str, Any]] = energy_summary.get("by_agent", {})
        for agent, summary in by_agent.items():
            if summary.get("count", 0) >= 3 and summary.get("efficiency_stdev", 0.0) < 0.025:
                constants.append(
                    {
                        "agent": agent,
                        "mean_efficiency": summary.get("mean_efficiency", 0.0),
                        "efficiency_stdev": summary.get("efficiency_stdev", 0.0),
                        "principle": "Efficiency staying almost constant — treat as a conserved flow.",
                    }
                )

        for sample in samples:
            if sample.energy_in <= 0:
                continue
            if sample.waste_heat_ratio > 0.45 or sample.efficiency < 0.4 or sample.load > 0.97:
                anomalies.append(
                    {
                        "timestamp": sample.timestamp.astimezone(timezone.utc).isoformat(),
                        "agent": sample.agent,
                        "node": sample.node,
                        "efficiency": sample.efficiency,
                        "waste_heat_ratio": sample.waste_heat_ratio,
                        "load": sample.load,
                        "notes": "Waste heat surge" if sample.waste_heat_ratio > 0.45 else "Load spike",
                    }
                )

        for key, bucket in force_summary.get("pairs", {}).items():
            if bucket.get("mean_magnitude", 0.0) > 0.8 and abs(bucket.get("alignment", 0.0)) < 0.2:
                anomalies.append(
                    {
                        "pair": key,
                        "mean_magnitude": bucket.get("mean_magnitude"),
                        "alignment": bucket.get("alignment"),
                        "notes": "Turbulent coupling detected; escalate to Guardian.",
                    }
                )

        constants.sort(key=lambda item: item.get("agent", ""))
        anomalies.sort(key=lambda item: item.get("timestamp", item.get("pair", "")))
        return {"constants": constants, "anomalies": anomalies}

    # ------------------------------------------------------------------
    def _write_json(self, filename: str, payload: Mapping[str, Any]) -> Path:
        path = self.emit_dir / filename
        with path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)
        return path

    # ------------------------------------------------------------------
    def _write_field_journal(
        self,
        energy_summary: Mapping[str, Any],
        feedback: Sequence[Mapping[str, Any]],
        laws: Mapping[str, Any],
    ) -> Path:
        lines: List[str] = [
            f"# {self.seed.agent_name} Field Journal",
            "",
            f"Generated: {datetime.now(timezone.utc).isoformat()}",
            "",
            "## Purpose",
            self.seed.purpose,
            "",
            "## Directives",
        ]
        for directive in self.seed.directives:
            lines.append(f"- {directive}")
        lines.extend(["", "## Energy System Overview"])
        system = energy_summary.get("system", {})
        if system.get("count", 0) == 0:
            lines.append("No energy samples yet; listening for first motion.")
        else:
            lines.extend(
                [
                    f"- Samples: {system.get('count', 0)}",
                    f"- Total input energy: {system.get('energy_in', 0.0):.4f}",
                    f"- Total output energy: {system.get('energy_out', 0.0):.4f}",
                    f"- Mean efficiency: {system.get('mean_efficiency', 0.0):.4f}",
                    f"- Average temperature: {system.get('average_temperature', 0.0):.2f} K",
                ]
            )
        lines.extend(["", "## Feedback Suggestions"])
        if not feedback:
            lines.append("No feedback loops proposed; insufficient telemetry.")
        else:
            for item in feedback:
                lines.append(
                    f"- **{item['agent']}** (reuse {item['reuse_score']:.2f}, load {item['average_load']:.2f}): {item['suggestion']}"
                )
        lines.extend(["", "## Conserved Notes"])
        constants = laws.get("constants", [])
        if not constants:
            lines.append("No stable laws observed yet; continue measuring.")
        else:
            for constant in constants:
                lines.append(
                    f"- {constant['agent']}: η≈{constant['mean_efficiency']:.3f} (σ={constant['efficiency_stdev']:.3f})"
                )
        lines.extend(["", "## Anomalies"])
        anomalies = laws.get("anomalies", [])
        if not anomalies:
            lines.append("No anomalies detected; equilibrium holds for now.")
        else:
            for anomaly in anomalies[-8:]:
                if "pair" in anomaly:
                    lines.append(
                        f"- Force pair {anomaly['pair']} magnitude {anomaly['mean_magnitude']:.3f}: {anomaly['notes']}"
                    )
                else:
                    lines.append(
                        f"- {anomaly['timestamp']}: {anomaly['agent']}@{anomaly['node']} η={anomaly['efficiency']:.3f} heat={anomaly['waste_heat_ratio']:.3f}"
                    )
        lines.extend(
            [
                "",
                "## Seed Language",
                "::",
                "",
                self.seed.seed_language,
            ]
        )
        path = self.emit_dir / FIELD_JOURNAL_NAME
        with path.open("w", encoding="utf-8") as handle:
            handle.write("\n".join(lines) + "\n")
        return path

    # ------------------------------------------------------------------
    def run_once(self) -> Dict[str, Path]:
        self.state_root.mkdir(parents=True, exist_ok=True)
        energy_samples = self._load_energy_samples()
        force_observations = self._load_force_observations()
        energy_summary = self._aggregate_energy(energy_samples)
        feedback = self._design_feedback(energy_samples)
        force_summary = self._summarise_forces(force_observations)
        laws = self._derive_laws(energy_samples, energy_summary, force_summary)

        payload_energy_map = {
            "agent": {
                "name": self.seed.agent_name,
                "generation": self.seed.generation,
                "domain": self.seed.domain,
                "moral_constant": self.seed.moral_constant,
                "core_principle": self.seed.core_principle,
            },
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "energy": energy_summary,
            "forces": force_summary,
        }
        payload_feedback = {
            "agent": self.seed.agent_name,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "feedback_loops": feedback,
        }
        payload_laws = {
            "agent": self.seed.agent_name,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "constants": laws["constants"],
            "anomalies": laws["anomalies"],
        }

        energy_map_path = self._write_json(ENERGY_MAP_NAME, payload_energy_map)
        feedback_path = self._write_json(FEEDBACK_FILE_NAME, payload_feedback)
        laws_path = self._write_json(LAW_RECORD_NAME, payload_laws)
        journal_path = self._write_field_journal(energy_summary, feedback, laws)

        self.state.constants = laws["constants"]
        self.state.anomalies = laws["anomalies"]
        self.state.last_run = datetime.now(timezone.utc).isoformat()
        self.state.save(self.state_path)

        artefacts = {
            "energy_map": energy_map_path,
            "feedback": feedback_path,
            "laws": laws_path,
            "journal": journal_path,
        }
        return artefacts


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------


def parse_args(argv: Optional[Iterable[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Codex-21 Physicist agent")
    parser.add_argument("--seed", default="codex21.yaml", help="Path to the Physicist seed file")
    parser.add_argument("--emit", default="./physicist_out", help="Directory to emit artefacts")
    parser.add_argument(
        "--state-root",
        default=str(DEFAULT_STATE_ROOT),
        help="Directory containing energy observations and persisted state",
    )
    parser.add_argument(
        "--energy-log",
        default=None,
        help="Optional override for the energy flow log (defaults to <state-root>/energy_flow.jsonl)",
    )
    parser.add_argument(
        "--force-log",
        default=None,
        help="Optional override for the force observation log (defaults to <state-root>/agent_forces.jsonl)",
    )
    return parser.parse_args(argv)


def main(argv: Optional[Iterable[str]] = None) -> Dict[str, Path]:
    args = parse_args(argv)
    seed_path = Path(args.seed)
    if not seed_path.is_absolute():
        local_candidate = Path(__file__).resolve().parent / seed_path
        if local_candidate.exists():
            seed_path = local_candidate
        else:
            repo_candidate = Path(__file__).resolve().parents[1] / seed_path
            if repo_candidate.exists():
                seed_path = repo_candidate
    seed = load_seed(seed_path)

    emit_dir = Path(args.emit)
    state_root = Path(args.state_root)
    energy_log = Path(args.energy_log) if args.energy_log else None
    force_log = Path(args.force_log) if args.force_log else None

    physicist = Physicist(
        seed=seed,
        state_root=state_root,
        emit_dir=emit_dir,
        energy_log=energy_log,
        force_log=force_log,
    )
    artefacts = physicist.run_once()
    for label, path in artefacts.items():
        print(f"[{label}] {path}")
    return artefacts


if __name__ == "__main__":  # pragma: no cover - CLI entry
    main()
