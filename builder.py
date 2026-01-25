#!/usr/bin/env python3
"""Lucidia Codex Builder agent.

This agent turns Codex design seeds into concrete build cards and
lightweight metrics. It favours clarity over flash so that humans can
understand why each artefact exists and how to extend it.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Iterable, List

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]


@dataclass
class SeedPacket:
    """Structured representation of a Codex seed file."""

    identifier: str
    system_charter: Dict[str, Any]
    purpose: str
    directives: List[str]
    core_tasks: List[str]
    io_inputs: List[str]
    io_outputs: List[str]
    behavioural_loop: List[str]
    seed_language: str
    boot_command: str

    @property
    def agent_name(self) -> str:
        return str(self.system_charter.get("agent_name", self.identifier))


class BuilderError(RuntimeError):
    """Raised when the Builder encounters a malformed seed file."""


# ---------------------------------------------------------------------------
# Seed loading utilities
# ---------------------------------------------------------------------------

def _ensure_list(value: Any, *, field: str) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item) for item in value]
    if isinstance(value, str):
        return [value]
    raise BuilderError(f"Expected list for '{field}', got {type(value)!r}")


def load_seed(path: Path) -> SeedPacket:
    if not path.exists():
        raise BuilderError(f"Seed file not found: {path}")
    with path.open("r", encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, dict):
        raise BuilderError("Seed file must contain a YAML mapping at the top level")

    required_fields = [
        "id",
        "system_charter",
        "purpose",
        "directives",
        "core_tasks",
        "input",
        "output",
        "behavioral_loop",
        "seed_language",
        "boot_command",
    ]
    missing = [field for field in required_fields if field not in data]
    if missing:
        raise BuilderError(f"Seed file missing required fields: {', '.join(missing)}")

    system_charter = data["system_charter"]
    if not isinstance(system_charter, dict):
        raise BuilderError("system_charter must be a mapping")

    return SeedPacket(
        identifier=str(data["id"]),
        system_charter=system_charter,
        purpose=str(data["purpose"]).strip(),
        directives=_ensure_list(data["directives"], field="directives"),
        core_tasks=_ensure_list(data["core_tasks"], field="core_tasks"),
        io_inputs=_ensure_list(data["input"], field="input"),
        io_outputs=_ensure_list(data["output"], field="output"),
        behavioural_loop=_ensure_list(data["behavioral_loop"], field="behavioral_loop"),
        seed_language=str(data["seed_language"]).strip(),
        boot_command=str(data["boot_command"]).strip(),
    )


# ---------------------------------------------------------------------------
# Metrics and rendering helpers
# ---------------------------------------------------------------------------

def compute_metrics(seed: SeedPacket) -> Dict[str, float]:
    directives = len(seed.directives)
    tasks = len(seed.core_tasks)
    loop_len = len(seed.behavioural_loop)

    complexity_index = directives * 1.1 + tasks * 1.7 + loop_len * 0.8
    energy_profile = complexity_index * 0.42
    maintainability = max(1.0, 10.0 - complexity_index * 0.35)

    return {
        "timestamp": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "directive_count": directives,
        "core_task_count": tasks,
        "behavioural_loop_length": loop_len,
        "complexity_index": round(complexity_index, 2),
        "energy_profile": round(energy_profile, 2),
        "maintainability_index": round(maintainability, 2),
    }


def render_loop(loop: Iterable[str]) -> str:
    parts = [item.strip() for item in loop if item.strip()]
    if not parts:
        return "(no loop defined)"
    return " → ".join(parts)


def render_build_card(seed: SeedPacket, metrics: Dict[str, Any]) -> str:
    loop_diagram = render_loop(seed.behavioural_loop)

    lines = [
        f"# Codex Build Card — {seed.agent_name}",
        "",
        "## Identity",
    ]
    for key, value in seed.system_charter.items():
        pretty_key = key.replace("_", " ").title()
        lines.append(f"- **{pretty_key}**: {value}")

    lines.extend(
        [
            "",
            "## Purpose",
            seed.purpose,
            "",
            "## Directives",
        ]
    )

    for idx, directive in enumerate(seed.directives, start=1):
        lines.append(f"{idx}. {directive}")

    lines.extend(["", "## Core Tasks"])
    for idx, task in enumerate(seed.core_tasks, start=1):
        lines.append(f"{idx}. {task}")

    lines.extend(
        [
            "",
            "## Operating Envelope",
            "- **Input**: " + ", ".join(seed.io_inputs) if seed.io_inputs else "- **Input**: (none)",
            "- **Output**: " + ", ".join(seed.io_outputs) if seed.io_outputs else "- **Output**: (none)",
            "",
            "## Behavioural Loop",
            f"`{loop_diagram}`",
            "",
            "## Metrics",
        ]
    )
    for key, value in metrics.items():
        lines.append(f"- **{key.replace('_', ' ').title()}**: {value}")

    lines.extend(
        [
            "",
            "## Boot Command",
            f"`{seed.boot_command}`",
            "",
            "## Seed Language",
            f"> {seed.seed_language}",
        ]
    )

    return "\n".join(lines) + "\n"


def render_schema(seed: SeedPacket) -> str:
    loop = [segment.upper() for segment in seed.behavioural_loop]
    if not loop:
        loop = ["OBSERVE", "BUILD", "REST"]

    width = max(len(part) for part in loop)
    arrow = "└" + "─" * (width + 2)
    schema_lines = ["┌" + "─" * (width + 2) + "┐"]
    for step in loop:
        padded = step.ljust(width)
        schema_lines.append(f"│ {padded} │")
    schema_lines.append(arrow + "┘")
    return "\n".join(schema_lines)


def write_file(path: Path, content: str, *, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] Would write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"[builder] wrote {path.relative_to(REPO_ROOT)}")


def normalise_emit_path(raw_path: str) -> Path:
    emit_path = Path(raw_path)
    if emit_path.is_absolute():
        emit_path = REPO_ROOT / emit_path.as_posix().lstrip("/")
    return emit_path if emit_path.is_absolute() else (REPO_ROOT / emit_path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lucidia Codex Builder agent")
    parser.add_argument("--seed", required=True, type=str, help="Path to the seed YAML file")
    parser.add_argument("--emit", required=True, type=str, help="Directory to emit build artefacts")
    parser.add_argument("--dry-run", action="store_true", help="Preview actions without writing files")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    seed_path = Path(args.seed)
    if not seed_path.is_absolute():
        seed_path = (REPO_ROOT / seed_path).resolve()
    else:
        seed_path = seed_path.resolve()

    try:
        seed = load_seed(seed_path)
    except BuilderError as exc:
        raise SystemExit(f"error: {exc}")

    metrics = compute_metrics(seed)
    emit_dir = normalise_emit_path(args.emit)

    base_name = seed.identifier.replace(" ", "_")
    build_card_path = emit_dir / f"{base_name}_build_card.md"
    metrics_path = emit_dir / f"{base_name}_metrics.json"
    schema_path = emit_dir / f"{base_name}_schema.txt"

    card_content = render_build_card(seed, metrics)
    metrics_content = json.dumps(metrics, indent=2, ensure_ascii=False) + "\n"
    schema_content = render_schema(seed) + "\n"

    write_file(build_card_path, card_content, dry_run=args.dry_run)
    write_file(metrics_path, metrics_content, dry_run=args.dry_run)
    write_file(schema_path, schema_content, dry_run=args.dry_run)

    print("[builder] completed emission")


if __name__ == "__main__":
    main()
