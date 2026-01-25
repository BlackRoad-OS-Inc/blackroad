#!/usr/bin/env python3
"""Codex-15 Engineer agent implementation.

The Engineer agent translates mechanical design intent into actionable build
packages.  It reads the Codex seed definition to honour the agent's charter and
optionally ingests a design specification that lists subsystems, interfaces,
materials, and reliability tests.  Outputs include a manifest for other agents
and a service manual formatted for humans.

The behaviour reflects the charter directives:

- Make nothing fragile on purpose.
- Measure twice — test thrice — teach once.
- Treat failure data as "body memory" to improve the next build.
- Document the hardware so future maintainers can service it quickly.

The CLI mirrors other Lucidia agents::

    python3 lucidia/engineer.py --seed codex15.yaml \
        --spec path/to/design.yaml --emit ./out_dir
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, MutableMapping, Optional, Sequence

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_EMIT_DIR = Path("/codex/prompts/next")
SEED_FALLBACK_DIR = Path(__file__).resolve().parent / "seeds"


# ---------------------------------------------------------------------------
# Seed parsing
# ---------------------------------------------------------------------------


@dataclass
class EngineerSeed:
    """Structured view of the Codex-15 seed definition."""

    identifier: str
    system_charter: Mapping[str, Any]
    purpose: str
    directives: Sequence[str]
    jobs: Sequence[str]
    input_channels: Sequence[str]
    output_channels: Sequence[str]
    behavioural_loop: Sequence[str]
    seed_language: str
    boot_command: str
    personality: Mapping[str, Any] = field(default_factory=dict)

    @property
    def agent_name(self) -> str:
        return str(self.system_charter.get("agent_name", self.identifier))


def _ensure_sequence(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, (list, tuple, set)):
        return [str(item) for item in value]
    return [str(value)]


def _resolve_seed_path(seed_arg: str) -> Path:
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
    raise FileNotFoundError(f"Seed file not found: {seed_arg}")


def load_seed(path: Path) -> EngineerSeed:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, Mapping):
        raise ValueError("Seed file must contain a mapping")

    system_charter = data.get("system_charter", {})
    if not isinstance(system_charter, Mapping):
        raise ValueError("system_charter must be a mapping")

    behavioural_loop = data.get("behavioral_loop")
    if behavioural_loop is None:
        behavioural_loop = data.get("behavioural_loop")

    return EngineerSeed(
        identifier=str(data.get("id", "codex-15")),
        system_charter=system_charter,
        purpose=str(data.get("purpose", "")).strip(),
        directives=_ensure_sequence(data.get("directives")),
        jobs=_ensure_sequence(data.get("jobs")),
        input_channels=_ensure_sequence(data.get("input")),
        output_channels=_ensure_sequence(data.get("output")),
        behavioural_loop=_ensure_sequence(behavioural_loop),
        seed_language=str(data.get("seed_language", "")).strip(),
        boot_command=str(data.get("boot_command", "")).strip(),
        personality=(data.get("personality") if isinstance(data.get("personality"), Mapping) else {}),
    )


# ---------------------------------------------------------------------------
# Design spec domain model
# ---------------------------------------------------------------------------


def _clean_string(value: Any) -> str:
    return str(value).strip()


@dataclass
class MaterialSpec:
    name: str
    grade: Optional[str] = None
    supplier: Optional[str] = None
    notes: Optional[str] = None

    @classmethod
    def from_raw(cls, raw: Any) -> "MaterialSpec":
        if isinstance(raw, str):
            return cls(name=_clean_string(raw))
        if isinstance(raw, Mapping):
            name = _clean_string(raw.get("name") or raw.get("material") or "Unnamed Material")
            grade = raw.get("grade") or raw.get("spec")
            supplier = raw.get("supplier") or raw.get("source")
            notes = raw.get("notes") or raw.get("comment")
            return cls(
                name=_clean_string(name),
                grade=_clean_string(grade) if grade else None,
                supplier=_clean_string(supplier) if supplier else None,
                notes=_clean_string(notes) if notes else None,
            )
        return cls(name=_clean_string(raw))

    def describe(self) -> str:
        detail: List[str] = [self.name]
        if self.grade:
            detail.append(f"grade {self.grade}")
        if self.supplier:
            detail.append(f"supplier: {self.supplier}")
        if self.notes:
            detail.append(self.notes)
        return " — ".join(detail)


@dataclass
class InterfaceSpec:
    name: str
    interface_type: Optional[str] = None
    voltage: Optional[str] = None
    protocol: Optional[str] = None
    notes: Optional[str] = None

    @classmethod
    def from_raw(cls, raw: Any) -> "InterfaceSpec":
        if isinstance(raw, str):
            return cls(name=_clean_string(raw))
        if isinstance(raw, Mapping):
            name = _clean_string(raw.get("name") or raw.get("interface") or "Unnamed Interface")
            interface_type = raw.get("type") or raw.get("category")
            voltage = raw.get("voltage") or raw.get("power")
            protocol = raw.get("protocol") or raw.get("standard")
            notes = raw.get("notes") or raw.get("comment")
            return cls(
                name=name,
                interface_type=_clean_string(interface_type) if interface_type else None,
                voltage=_clean_string(voltage) if voltage else None,
                protocol=_clean_string(protocol) if protocol else None,
                notes=_clean_string(notes) if notes else None,
            )
        return cls(name=_clean_string(raw))

    def describe(self) -> str:
        parts: List[str] = [self.name]
        detail: List[str] = []
        if self.interface_type:
            detail.append(self.interface_type)
        if self.protocol:
            detail.append(self.protocol)
        if self.voltage:
            detail.append(f"{self.voltage}")
        if detail:
            parts.append(" (" + ", ".join(detail) + ")")
        if self.notes:
            parts.append(f" — {self.notes}")
        return "".join(parts)


@dataclass
class TestSpec:
    name: str
    metric: Optional[str] = None
    target: Optional[str] = None
    tolerance: Optional[str] = None
    method: Optional[str] = None

    @classmethod
    def from_raw(cls, raw: Any) -> "TestSpec":
        if isinstance(raw, str):
            return cls(name=_clean_string(raw))
        if isinstance(raw, Mapping):
            name = _clean_string(raw.get("name") or raw.get("test") or "Unnamed Test")
            metric = raw.get("metric") or raw.get("focus")
            target = raw.get("target") or raw.get("limit")
            tolerance = raw.get("tolerance") or raw.get("allowance")
            method = raw.get("method") or raw.get("procedure")
            return cls(
                name=name,
                metric=_clean_string(metric) if metric else None,
                target=_clean_string(target) if target else None,
                tolerance=_clean_string(tolerance) if tolerance else None,
                method=_clean_string(method) if method else None,
            )
        return cls(name=_clean_string(raw))

    def to_summary(self) -> Dict[str, Optional[str]]:
        return {
            "name": self.name,
            "metric": self.metric,
            "target": self.target,
            "tolerance": self.tolerance,
            "method": self.method,
        }


@dataclass
class MaintenanceTask:
    task: str
    interval_hours: Optional[float] = None
    interval_cycles: Optional[float] = None
    tools: Sequence[str] = field(default_factory=list)
    notes: Optional[str] = None

    @classmethod
    def from_raw(cls, raw: Any) -> "MaintenanceTask":
        if isinstance(raw, str):
            return cls(task=_clean_string(raw))
        if isinstance(raw, Mapping):
            task = _clean_string(raw.get("task") or raw.get("description") or "General inspection")
            interval_hours = raw.get("interval_hours") or raw.get("hours")
            interval_cycles = raw.get("interval_cycles") or raw.get("cycles")
            tools = _ensure_sequence(raw.get("tools")) if raw.get("tools") is not None else []
            notes = raw.get("notes") or raw.get("comment")
            return cls(
                task=task,
                interval_hours=float(interval_hours) if isinstance(interval_hours, (int, float)) else None,
                interval_cycles=float(interval_cycles) if isinstance(interval_cycles, (int, float)) else None,
                tools=tools,
                notes=_clean_string(notes) if notes else None,
            )
        return cls(task=_clean_string(raw))

    def describe(self) -> str:
        schedule: List[str] = []
        if self.interval_hours is not None:
            schedule.append(f"every {int(self.interval_hours)} h")
        if self.interval_cycles is not None:
            schedule.append(f"every {int(self.interval_cycles)} cycles")
        schedule_text = ", ".join(schedule) if schedule else "routine"
        tools_text = f" | tools: {', '.join(self.tools)}" if self.tools else ""
        notes_text = f" — {self.notes}" if self.notes else ""
        return f"{schedule_text} · {self.task}{tools_text}{notes_text}"


@dataclass
class SystemBlueprint:
    name: str
    summary: str
    materials: List[MaterialSpec] = field(default_factory=list)
    interfaces: List[InterfaceSpec] = field(default_factory=list)
    tests: List[TestSpec] = field(default_factory=list)
    maintenance: List[MaintenanceTask] = field(default_factory=list)
    sensors: Sequence[str] = field(default_factory=list)

    @classmethod
    def from_raw(cls, raw: Mapping[str, Any]) -> "SystemBlueprint":
        name = _clean_string(raw.get("name") or raw.get("system") or "Unnamed subsystem")
        summary = _clean_string(raw.get("purpose") or raw.get("summary") or "")
        materials = [MaterialSpec.from_raw(item) for item in _ensure_sequence(raw.get("materials"))]
        interfaces = [InterfaceSpec.from_raw(item) for item in _ensure_sequence(raw.get("interfaces"))]
        tests = [TestSpec.from_raw(item) for item in _ensure_sequence(raw.get("tests"))]
        maintenance = [MaintenanceTask.from_raw(item) for item in _ensure_sequence(raw.get("maintenance"))]
        sensors = [str(s) for s in _ensure_sequence(raw.get("sensors"))]
        return cls(
            name=name,
            summary=summary,
            materials=materials,
            interfaces=interfaces,
            tests=tests,
            maintenance=maintenance,
            sensors=sensors,
        )


@dataclass
class DesignSpec:
    project: str
    revision: str
    systems: List[SystemBlueprint] = field(default_factory=list)
    notes: Sequence[str] = field(default_factory=list)

    @classmethod
    def empty(cls) -> "DesignSpec":
        return cls(project="Unnamed Mechanism", revision="0")

    @classmethod
    def from_mapping(cls, data: Mapping[str, Any]) -> "DesignSpec":
        project = _clean_string(data.get("project") or data.get("name") or "Unnamed Mechanism")
        revision = _clean_string(data.get("revision") or data.get("version") or "0")
        systems_raw = data.get("systems") or data.get("subsystems") or []
        systems: List[SystemBlueprint] = []
        if isinstance(systems_raw, Mapping):
            systems_raw = systems_raw.values()
        for item in systems_raw:
            if isinstance(item, Mapping):
                systems.append(SystemBlueprint.from_raw(item))
        notes = [_clean_string(note) for note in _ensure_sequence(data.get("notes")) if _clean_string(note)]
        return cls(project=project, revision=revision, systems=systems, notes=notes)


# ---------------------------------------------------------------------------
# Design spec loading and analytics
# ---------------------------------------------------------------------------


def load_design_spec(path: Path) -> DesignSpec:
    with path.open("r", encoding="utf-8") as handle:
        if path.suffix.lower() in {".json"}:
            raw = json.load(handle)
        else:
            raw = yaml.safe_load(handle)
    if not isinstance(raw, Mapping):
        raise ValueError("Design spec must be a mapping")
    return DesignSpec.from_mapping(raw)


def compute_metrics(spec: DesignSpec) -> Dict[str, Any]:
    system_count = len(spec.systems)
    materials = [material.name for system in spec.systems for material in system.materials]
    unique_materials = sorted(set(materials))
    interface_types = [
        (iface.interface_type or iface.protocol or iface.name).lower()
        for system in spec.systems
        for iface in system.interfaces
        if iface
    ]
    unique_interfaces = sorted(set(interface_types))
    test_count = sum(len(system.tests) for system in spec.systems)
    maintenance_count = sum(len(system.maintenance) for system in spec.systems)

    modularity_index = round(system_count * 1.5 + len(unique_interfaces) * 0.75 + len(unique_materials) * 0.45, 2)
    serviceability_index = round((maintenance_count + 1) / (system_count + 1), 2)

    body_memory = []
    fatigue_keywords = {"fatigue", "cycle", "stress", "load", "torque"}
    for system in spec.systems:
        for test in system.tests:
            metric = (test.metric or "").lower()
            if any(keyword in metric for keyword in fatigue_keywords):
                body_memory.append(
                    {
                        "system": system.name,
                        "test": test.name,
                        "metric": test.metric,
                        "target": test.target,
                        "tolerance": test.tolerance,
                    }
                )

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "systems": system_count,
        "unique_materials": unique_materials,
        "unique_interface_profiles": unique_interfaces,
        "test_count": test_count,
        "maintenance_task_count": maintenance_count,
        "modularity_index": modularity_index,
        "serviceability_index": serviceability_index,
        "body_memory": body_memory,
    }


# ---------------------------------------------------------------------------
# Rendering utilities
# ---------------------------------------------------------------------------


def render_manual(seed: EngineerSeed, spec: DesignSpec, metrics: Mapping[str, Any]) -> str:
    lines: List[str] = []
    lines.append(f"# Service Manual — {seed.agent_name}")
    lines.append("")
    lines.append(f"**Project**: {spec.project}  |  **Revision**: {spec.revision}")
    lines.append(f"**Generated**: {metrics['timestamp']}")
    lines.append("")
    lines.append("## Charter Acknowledgement")
    for key, value in seed.system_charter.items():
        pretty_key = key.replace("_", " ").title()
        lines.append(f"- **{pretty_key}**: {value}")
    lines.append("")
    lines.append("## Purpose")
    lines.append(seed.purpose or "")
    lines.append("")
    if seed.directives:
        lines.append("## Directives")
        for directive in seed.directives:
            lines.append(f"- {directive}")
        lines.append("")
    if seed.jobs:
        lines.append("## Jobs / Functions")
        for job in seed.jobs:
            lines.append(f"- {job}")
        lines.append("")
    if seed.behavioural_loop:
        lines.append("## Behavioral Loop")
        lines.append(" → ".join(step.strip() for step in seed.behavioural_loop if step))
        lines.append("")
    if seed.seed_language:
        lines.append("## Seed Language")
        lines.append(seed.seed_language)
        lines.append("")
    lines.append("## Mechanical Summary")
    lines.append(f"- Subsystems analysed: {metrics['systems']}")
    lines.append(f"- Unique materials: {', '.join(metrics['unique_materials']) or 'n/a'}")
    lines.append(f"- Interface profiles: {', '.join(metrics['unique_interface_profiles']) or 'n/a'}")
    lines.append(f"- Verification tests logged: {metrics['test_count']}")
    lines.append(f"- Maintenance tasks logged: {metrics['maintenance_task_count']}")
    lines.append(f"- Modularity index: {metrics['modularity_index']}")
    lines.append(f"- Serviceability index: {metrics['serviceability_index']}")
    lines.append("")

    if spec.notes:
        lines.append("### Design Notes")
        for note in spec.notes:
            lines.append(f"- {note}")
        lines.append("")

    if not spec.systems:
        lines.append("No subsystem data supplied. Documented the charter so the next design cycle starts ready.")
        lines.append("")
    else:
        for idx, system in enumerate(spec.systems, start=1):
            lines.append(f"### Subsystem {idx}: {system.name}")
            if system.summary:
                lines.append(system.summary)
            lines.append("")
            if system.materials:
                lines.append("**Materials**")
                for material in system.materials:
                    lines.append(f"- {material.describe()}")
                lines.append("")
            if system.interfaces:
                lines.append("**Interfaces**")
                for iface in system.interfaces:
                    lines.append(f"- {iface.describe()}")
                lines.append("")
            if system.sensors:
                lines.append("**Sensors & Telemetry**")
                for sensor in system.sensors:
                    lines.append(f"- {sensor}")
                lines.append("")
            if system.tests:
                lines.append("**Verification Tests**")
                for test in system.tests:
                    detail = [test.name]
                    if test.metric:
                        detail.append(f"metric: {test.metric}")
                    if test.target:
                        detail.append(f"target: {test.target}")
                    if test.tolerance:
                        detail.append(f"tolerance: {test.tolerance}")
                    if test.method:
                        detail.append(f"method: {test.method}")
                    lines.append("- " + " | ".join(detail))
                lines.append("")
            if system.maintenance:
                lines.append("**Maintenance**")
                for task in system.maintenance:
                    lines.append(f"- {task.describe()}")
                lines.append("")
            lines.append("---")
            lines.append("")

    if metrics["body_memory"]:
        lines.append("## Body Memory (Fatigue Log)")
        for record in metrics["body_memory"]:
            lines.append(
                "- {system}: {test} — {metric} target {target} (±{tolerance})".format(
                    system=record.get("system", "unknown"),
                    test=record.get("test", "unknown"),
                    metric=record.get("metric", "n/a"),
                    target=record.get("target", "n/a"),
                    tolerance=record.get("tolerance", "n/a"),
                )
            )
        lines.append("")
    else:
        lines.append("No fatigue-focused tests logged yet. First build will seed the body memory register.")
        lines.append("")

    lines.append("## Next Steps")
    lines.append("1. Validate interface drawings against the standardised power bus map.")
    lines.append("2. Run torque and thermal drift simulations before fabricating jigs.")
    lines.append("3. Teach the next maintainer how to reset each subsystem without tools.")
    lines.append("")
    lines.append("— Documented by Codex-15 \"Engineer\"")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Output orchestration
# ---------------------------------------------------------------------------


def emit_outputs(emit_dir: Path, manual_text: str, manifest: Mapping[str, Any]) -> None:
    emit_dir.mkdir(parents=True, exist_ok=True)
    manual_path = emit_dir / "engineer_manual.md"
    manifest_path = emit_dir / "engineer_manifest.json"
    manual_path.write_text(manual_text + "\n", encoding="utf-8")
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def orchestrate(seed: EngineerSeed, spec: DesignSpec, emit_dir: Path) -> Dict[str, Any]:
    metrics = compute_metrics(spec)
    manual_text = render_manual(seed, spec, metrics)
    manifest: MutableMapping[str, Any] = {
        "agent": seed.agent_name,
        "identifier": seed.identifier,
        "charter": dict(seed.system_charter),
        "directives": list(seed.directives),
        "jobs": list(seed.jobs),
        "behavioural_loop": list(seed.behavioural_loop),
        "input": list(seed.input_channels),
        "output": list(seed.output_channels),
        "personality": dict(seed.personality),
        "metrics": metrics,
    }
    if spec.systems:
        manifest["systems"] = [
            {
                "name": system.name,
                "summary": system.summary,
                "materials": [material.describe() for material in system.materials],
                "interfaces": [iface.describe() for iface in system.interfaces],
                "tests": [test.to_summary() for test in system.tests],
                "maintenance": [task.describe() for task in system.maintenance],
                "sensors": list(system.sensors),
            }
            for system in spec.systems
        ]
        manifest["project"] = {"name": spec.project, "revision": spec.revision, "notes": list(spec.notes)}
    emit_outputs(emit_dir, manual_text, manifest)
    return manifest


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Codex-15 Engineer agent")
    parser.add_argument("--seed", default="codex15.yaml", help="Seed YAML file")
    parser.add_argument("--spec", help="Design specification (YAML or JSON)")
    parser.add_argument("--emit", help="Directory to write outputs")
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> None:
    args = parse_args(argv)
    seed_path = _resolve_seed_path(args.seed)
    seed = load_seed(seed_path)
    if args.spec:
        spec_path = Path(args.spec)
        if not spec_path.exists():
            raise FileNotFoundError(f"Design spec not found: {args.spec}")
        spec = load_design_spec(spec_path)
    else:
        spec = DesignSpec.empty()
    emit_dir = Path(args.emit) if args.emit else DEFAULT_EMIT_DIR
    manifest = orchestrate(seed, spec, emit_dir)
    print(json.dumps({"status": "ok", "emit": str(emit_dir), "systems": len(spec.systems)}, indent=2))


if __name__ == "__main__":  # pragma: no cover
    main()
