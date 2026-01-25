#!/usr/bin/env python3
"""Codex-14 Chemist agent implementation.

This agent ingests reaction observations from the Lucidia state directory and
produces energy maps, stability reports, and a lab notebook entry that other
agents can consume. The behaviour honours the charter described in
``codex14.yaml`` by:

* respecting instability by recording failed or volatile reactions rather than
  discarding them,
* tracking heat exchange alongside truth by computing reaction energy deltas
  and estimated thermal load,
* catalysing collaboration by emitting summaries that reference catalysts and
  collaborating agents, and
* ensuring that every transformation can be cooled again by highlighting
  reactions that exceed configured safety thresholds.

The tool expects reaction observations to be appended as JSON lines to
``reaction_log.jsonl`` within the configured state directory. Each entry may
contain the following fields (any other metadata is preserved):

```
{
  "id": "⚗️-0001",
  "reactants": ["data_a", "agent.b"],
  "products": ["insight.c"],
  "catalyst": "guardian",
  "energy_in": 42.1,
  "energy_out": 39.8,
  "temperature": 302.5,
  "timestamp": "2025-01-18T02:15:22Z",
  "notes": "Stabilised after cooling loop"
}
```

If a field is missing the Chemist applies sensible defaults so the agent can run
in sandbox environments.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Optional

import yaml

DEFAULT_STATE_ROOT = Path("/srv/lucidia/chemist")
REACTION_LOG_NAME = "reaction_log.jsonl"
STATE_FILENAME = "state.json"
LAB_NOTEBOOK_NAME = "lab_notebook.md"
ENERGY_MAP_NAME = "energy_map.json"
STABILITY_REPORT_NAME = "stability_report.json"


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
class ChemistSeed:
    """Structured representation of the Chemist seed manifest."""

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


def load_seed(path: Path) -> ChemistSeed:
    """Load and validate the Chemist seed file."""

    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}

    if not isinstance(data, MutableMapping):
        raise ValueError("Chemist seed must be a mapping at the top level")

    charter = data.get("system_charter")
    if not isinstance(charter, MutableMapping):
        raise ValueError("Chemist seed missing 'system_charter' mapping")

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
            "Chemist seed missing charter field(s): " + ", ".join(missing_charter)
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
            raise ValueError(f"Chemist seed missing required field: {required}")

    return ChemistSeed(
        identifier=str(data.get("id", "codex-14")),
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
# Runtime state and reaction modelling
# ---------------------------------------------------------------------------


@dataclass
class ChemistState:
    """Mutable runtime state persisted between runs."""

    offsets: Dict[str, int] = field(default_factory=lambda: {"reaction_log": 0})
    energy_totals: Dict[str, float] = field(default_factory=dict)
    temperature_trails: Dict[str, List[float]] = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "ChemistState":
        if not path.exists():
            return cls()
        try:
            with path.open("r", encoding="utf-8") as handle:
                payload = json.load(handle)
        except (OSError, json.JSONDecodeError):
            return cls()
        return cls(
            offsets=payload.get("offsets", {"reaction_log": 0}),
            energy_totals=payload.get("energy_totals", {}),
            temperature_trails={
                key: list(map(float, values))
                for key, values in payload.get("temperature_trails", {}).items()
            },
        )

    def save(self, path: Path) -> None:
        payload = {
            "offsets": self.offsets,
            "energy_totals": self.energy_totals,
            "temperature_trails": self.temperature_trails,
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", encoding="utf-8") as handle:
            json.dump(payload, handle, indent=2, sort_keys=True)


@dataclass
class ReactionObservation:
    """Structured view over a single reaction log entry."""

    identifier: str
    reactants: List[str]
    products: List[str]
    catalyst: Optional[str]
    energy_in: float
    energy_out: float
    delta_energy: float
    temperature: float
    timestamp: str
    metadata: Mapping[str, Any]

    @classmethod
    def from_mapping(cls, payload: Mapping[str, Any]) -> "ReactionObservation":
        identifier = str(payload.get("id") or payload.get("reaction_id") or "anonymous")
        reactants = [str(item) for item in payload.get("reactants", [])]
        products = [str(item) for item in payload.get("products", [])]
        catalyst = payload.get("catalyst")
        if catalyst is not None:
            catalyst = str(catalyst)

        def _float(name: str, *aliases: str, default: float = 0.0) -> float:
            for key in (name, *aliases):
                value = payload.get(key)
                if value is not None:
                    try:
                        return float(value)
                    except (TypeError, ValueError):
                        continue
            return float(default)

        energy_in = _float("energy_in", "input_energy", default=0.0)
        energy_out = _float("energy_out", "output_energy", default=0.0)
        delta_energy = _float("delta_energy", "energy_delta", default=energy_out - energy_in)

        if delta_energy == 0.0:
            delta_energy = energy_out - energy_in

        temperature = _float("temperature", "temp", "kelvin", default=298.15)

        timestamp_value = payload.get("timestamp") or payload.get("time")
        if timestamp_value is None:
            timestamp = datetime.now(timezone.utc).isoformat()
        else:
            timestamp = str(timestamp_value)

        metadata = {
            key: value
            for key, value in payload.items()
            if key
            not in {
                "id",
                "reaction_id",
                "reactants",
                "products",
                "catalyst",
                "energy_in",
                "input_energy",
                "energy_out",
                "output_energy",
                "delta_energy",
                "energy_delta",
                "temperature",
                "temp",
                "kelvin",
                "timestamp",
                "time",
            }
        }

        return cls(
            identifier=identifier,
            reactants=reactants,
            products=products,
            catalyst=catalyst,
            energy_in=energy_in,
            energy_out=energy_out,
            delta_energy=delta_energy,
            temperature=temperature,
            timestamp=timestamp,
            metadata=metadata,
        )

    @property
    def exothermic(self) -> bool:
        return self.delta_energy < 0

    @property
    def endothermic(self) -> bool:
        return self.delta_energy > 0

    def to_serialisable(self) -> Dict[str, Any]:
        return {
            "id": self.identifier,
            "reactants": self.reactants,
            "products": self.products,
            "catalyst": self.catalyst,
            "energy_in": self.energy_in,
            "energy_out": self.energy_out,
            "delta_energy": self.delta_energy,
            "temperature": self.temperature,
            "timestamp": self.timestamp,
            "metadata": self.metadata,
        }


# ---------------------------------------------------------------------------
# Chemist core logic
# ---------------------------------------------------------------------------


class Chemist:
    """Implements the Codex-14 Chemist behavioural loop."""

    def __init__(
        self,
        *,
        seed: ChemistSeed,
        state_root: Path,
        emit_dir: Path,
        reaction_log: Optional[Path] = None,
        safety_threshold: float = 15.0,
    ) -> None:
        self.seed = seed
        self.state_root = state_root
        self.emit_dir = emit_dir
        self.emit_dir.mkdir(parents=True, exist_ok=True)
        self.state_path = state_root / STATE_FILENAME
        self.reaction_log = reaction_log or state_root / REACTION_LOG_NAME
        self.safety_threshold = safety_threshold
        self.state = ChemistState.load(self.state_path)

    # ------------------------------------------------------------------
    def _tail_reaction_log(self) -> List[ReactionObservation]:
        offset = self.state.offsets.get("reaction_log", 0)
        if not self.reaction_log.exists():
            self.state.offsets["reaction_log"] = 0
            return []
        try:
            with self.reaction_log.open("r", encoding="utf-8") as handle:
                handle.seek(offset)
                lines = handle.readlines()
                new_offset = handle.tell()
        except OSError:
            return []

        observations: List[ReactionObservation] = []
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
            observations.append(ReactionObservation.from_mapping(payload))

        self.state.offsets["reaction_log"] = new_offset
        return observations

    # ------------------------------------------------------------------
    def _update_energy_ledgers(self, reactions: Iterable[ReactionObservation]) -> None:
        for reaction in reactions:
            key = reaction.catalyst or "uncatalysed"
            self.state.energy_totals[key] = self.state.energy_totals.get(key, 0.0) + reaction.delta_energy
            self.state.temperature_trails.setdefault(key, []).append(reaction.temperature)

    # ------------------------------------------------------------------
    def _compute_energy_map(self) -> Dict[str, Any]:
        report: Dict[str, Any] = {}
        for catalyst, total_delta in sorted(self.state.energy_totals.items()):
            temperatures = self.state.temperature_trails.get(catalyst, [])
            avg_temp = sum(temperatures) / len(temperatures) if temperatures else 298.15
            report[catalyst] = {
                "net_delta_energy": round(total_delta, 4),
                "average_temperature": round(avg_temp, 2),
                "temperature_samples": len(temperatures),
            }
        return report

    # ------------------------------------------------------------------
    def _stability_from_reaction(self, reaction: ReactionObservation) -> Dict[str, Any]:
        stress = abs(reaction.delta_energy)
        status = "stable"
        if stress > self.safety_threshold * 2:
            status = "volatile"
        elif stress > self.safety_threshold:
            status = "needs_cooling"
        return {
            "id": reaction.identifier,
            "reactants": reaction.reactants,
            "products": reaction.products,
            "catalyst": reaction.catalyst,
            "delta_energy": round(reaction.delta_energy, 4),
            "temperature": round(reaction.temperature, 2),
            "timestamp": reaction.timestamp,
            "status": status,
            "exothermic": reaction.exothermic,
            "endothermic": reaction.endothermic,
            "metadata": reaction.metadata,
        }

    # ------------------------------------------------------------------
    def _write_energy_map(self) -> Path:
        energy_map = self._compute_energy_map()
        path = self.emit_dir / ENERGY_MAP_NAME
        with path.open("w", encoding="utf-8") as handle:
            json.dump({"generated_at": self._now_iso(), "map": energy_map}, handle, indent=2, sort_keys=True)
        return path

    # ------------------------------------------------------------------
    def _write_stability_report(self, reactions: List[ReactionObservation]) -> Path:
        report = {
            "generated_at": self._now_iso(),
            "summary": {
                "total_reactions": len(reactions),
                "exothermic": sum(1 for r in reactions if r.exothermic),
                "endothermic": sum(1 for r in reactions if r.endothermic),
                "neutral": sum(1 for r in reactions if not r.exothermic and not r.endothermic),
            },
            "reactions": [self._stability_from_reaction(r) for r in reactions],
            "directives": self.seed.directives,
        }
        path = self.emit_dir / STABILITY_REPORT_NAME
        with path.open("w", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2, sort_keys=True)
        return path

    # ------------------------------------------------------------------
    def _write_lab_notebook(self, reactions: List[ReactionObservation]) -> Path:
        lines = [
            f"# Lab Notebook — {self.seed.agent_name}",
            "",
            f"Generated at: {self._now_iso()}",
            "",
            "## Behavioural loop",
            " → ".join(self.seed.behavioural_loop) or "(not defined)",
            "",
            "## Reaction Summaries",
        ]
        if not reactions:
            lines.append("No new reactions detected; system remains in resting state.")
        else:
            for reaction in reactions:
                direction = "exothermic" if reaction.exothermic else "endothermic" if reaction.endothermic else "neutral"
                lines.extend(
                    [
                        f"- **{reaction.identifier}** ({direction})",
                        f"  - Reactants: {', '.join(reaction.reactants) or 'n/a'}",
                        f"  - Products: {', '.join(reaction.products) or 'n/a'}",
                        f"  - Catalyst: {reaction.catalyst or 'none'}",
                        f"  - ΔE: {reaction.delta_energy:.4f}",
                        f"  - Temperature: {reaction.temperature:.2f} K",
                        f"  - Timestamp: {reaction.timestamp}",
                    ]
                )
                if reaction.metadata:
                    lines.append(f"  - Notes: {json.dumps(reaction.metadata, sort_keys=True)}")
        lines.extend(
            [
                "",
                "## Seed Language",
                "::",
                "",
                self.seed.seed_language,
                "",
                "## Energy Ledger",
            ]
        )
        energy_map = self._compute_energy_map()
        if not energy_map:
            lines.append("No energy ledger entries yet; awaiting first reaction.")
        else:
            for catalyst, details in energy_map.items():
                lines.append(
                    f"- {catalyst}: ΔE={details['net_delta_energy']:.4f}, "
                    f"avg temp={details['average_temperature']:.2f} K from {details['temperature_samples']} samples"
                )

        path = self.emit_dir / LAB_NOTEBOOK_NAME
        with path.open("w", encoding="utf-8") as handle:
            handle.write("\n".join(lines))
        return path

    # ------------------------------------------------------------------
    def _now_iso(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    # ------------------------------------------------------------------
    def run_once(self) -> Dict[str, Path]:
        self.state_root.mkdir(parents=True, exist_ok=True)
        reactions = self._tail_reaction_log()
        self._update_energy_ledgers(reactions)
        energy_map_path = self._write_energy_map()
        stability_report_path = self._write_stability_report(reactions)
        notebook_path = self._write_lab_notebook(reactions)
        self.state.save(self.state_path)
        return {
            "energy_map": energy_map_path,
            "stability_report": stability_report_path,
            "lab_notebook": notebook_path,
        }


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------


def parse_args(argv: Optional[Iterable[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Codex-14 Chemist agent")
    parser.add_argument("--seed", default="codex14.yaml", help="Path to the Chemist seed file")
    parser.add_argument("--emit", default="./chemist_out", help="Directory to emit artefacts")
    parser.add_argument(
        "--state-root",
        default=str(DEFAULT_STATE_ROOT),
        help="Directory containing reaction logs and persistent state",
    )
    parser.add_argument(
        "--reaction-log",
        default=None,
        help="Override the reaction log path (defaults to <state-root>/reaction_log.jsonl)",
    )
    parser.add_argument(
        "--safety-threshold",
        type=float,
        default=15.0,
        help="Energy delta threshold before a reaction is flagged for cooling",
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
    reaction_log = Path(args.reaction_log) if args.reaction_log else None

    chemist = Chemist(
        seed=seed,
        state_root=state_root,
        emit_dir=emit_dir,
        reaction_log=reaction_log,
        safety_threshold=args.safety_threshold,
    )
    artefacts = chemist.run_once()
    for label, path in artefacts.items():
        print(f"[{label}] {path}")
    return artefacts


if __name__ == "__main__":  # pragma: no cover - CLI entry
    main()
