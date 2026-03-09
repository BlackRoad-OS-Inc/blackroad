#!/usr/bin/env python3
"""Lucidia Codex Navigator agent.

The Navigator translates Codex exploration seeds into artefacts that combine
context, risk awareness, and behavioural rituals. It favours traceable,
reproducible routes over opaque leaps so that future agents can follow the
same stars.
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
class NavigatorSeed:
    """Structured representation of a Navigator seed packet."""

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


class NavigatorError(RuntimeError):
    """Raised when the Navigator encounters a malformed seed."""


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
    raise NavigatorError(f"Expected list for '{field}', got {type(value)!r}")


def load_seed(path: Path) -> NavigatorSeed:
    if not path.exists():
        raise NavigatorError(f"Seed file not found: {path}")

    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)

    if not isinstance(data, dict):
        raise NavigatorError("Seed file must contain a YAML mapping at the top level")

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
        raise NavigatorError(f"Seed file missing required fields: {', '.join(missing)}")

    system_charter = data["system_charter"]
    if not isinstance(system_charter, dict):
        raise NavigatorError("system_charter must be a mapping")

    return NavigatorSeed(
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

def compute_risk_profile(seed: NavigatorSeed) -> Dict[str, Any]:
    directives = len(seed.directives)
    tasks = len(seed.core_tasks)
    loop_len = len(seed.behavioural_loop)

    guidance_complexity = directives * 1.08 + tasks * 1.55 + loop_len * 0.95
    exploration_pressure = tasks * 1.12 + loop_len * 0.68
    safety_margin = max(1.0, 10.0 - guidance_complexity * 0.35)
    balance_index = (exploration_pressure + safety_margin) / 2

    return {
        "timestamp": datetime.utcnow().isoformat(timespec="seconds") + "Z",
        "directive_count": directives,
        "core_task_count": tasks,
        "behavioural_loop_length": loop_len,
        "guidance_complexity": round(guidance_complexity, 2),
        "exploration_pressure": round(exploration_pressure, 2),
        "safety_margin": round(safety_margin, 2),
        "balance_index": round(balance_index, 2),
    }


def render_loop(loop: Iterable[str]) -> str:
    parts = [segment.strip() for segment in loop if segment.strip()]
    if not parts:
        return "(loop undefined)"
    return " → ".join(parts)


def render_navigation_card(seed: NavigatorSeed, metrics: Dict[str, Any]) -> str:
    loop_diagram = render_loop(seed.behavioural_loop)

    lines = [
        f"# Navigation Card — {seed.agent_name}",
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

    for index, directive in enumerate(seed.directives, start=1):
        lines.append(f"{index}. {directive}")

    lines.extend(["", "## Core Functions"])
    for index, task in enumerate(seed.core_tasks, start=1):
        lines.append(f"{index}. {task}")

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
            "## Risk Profile",
        ]
    )

    for key, value in metrics.items():
        pretty_key = key.replace("_", " ").title()
        lines.append(f"- **{pretty_key}**: {value}")

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


def render_wayfinder_loop(loop: Iterable[str]) -> str:
    steps = [segment.upper() for segment in loop if segment.strip()]
    if not steps:
        steps = ["SCAN", "GUIDE", "REST"]

    width = max(len(step) for step in steps)
    border = "─" * (width + 2)
    schema_lines = ["┌" + border + "┐"]

    for step in steps:
        schema_lines.append(f"│ {step.ljust(width)} │")

    schema_lines.append("└" + border + "┘")
    return "\n".join(schema_lines)


def write_file(path: Path, content: str, *, dry_run: bool) -> None:
    if dry_run:
        print(f"[dry-run] Would write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"[navigator] wrote {path.relative_to(REPO_ROOT)}")


def normalise_emit_path(raw_path: str) -> Path:
    emit_path = Path(raw_path)
    if emit_path.is_absolute():
        emit_path = REPO_ROOT / emit_path.as_posix().lstrip("/")
    return emit_path if emit_path.is_absolute() else (REPO_ROOT / emit_path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lucidia Codex Navigator agent")
    parser.add_argument("--seed", required=True, type=str, help="Path to the seed YAML file")
    parser.add_argument("--emit", required=True, type=str, help="Directory to emit navigation artefacts")
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
    except NavigatorError as exc:
        raise SystemExit(f"error: {exc}")

    metrics = compute_risk_profile(seed)
    emit_dir = normalise_emit_path(args.emit)

    base_name = seed.identifier.replace(" ", "_")
    card_path = emit_dir / f"{base_name}_navigation_card.md"
    risk_path = emit_dir / f"{base_name}_risk_profile.json"
    loop_path = emit_dir / f"{base_name}_wayfinder_loop.txt"

    card_content = render_navigation_card(seed, metrics)
    risk_content = json.dumps(metrics, indent=2, ensure_ascii=False) + "\n"
    loop_content = render_wayfinder_loop(seed.behavioural_loop) + "\n"

    write_file(card_path, card_content, dry_run=args.dry_run)
    write_file(risk_path, risk_content, dry_run=args.dry_run)
    write_file(loop_path, loop_content, dry_run=args.dry_run)

    print("[navigator] completed emission")


if __name__ == "__main__":
    main()
