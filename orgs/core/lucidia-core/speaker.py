#!/usr/bin/env python3
"""Codex-8 Speaker agent utilities.

This module consumes a Codex seed definition and emits ready-to-use briefing
artifacts that keep the Speaker's tone steady across environments. The script
focuses on translation and consistency:

* Summarises the charter and directives into a human readable briefing card.
* Generates a broadcast prompt that operationalises the behavioural loop.
* Emits a machine-friendly manifest with cadence metrics for downstream tools.

The implementation mirrors the CLI ergonomics of ``lucidia/builder.py`` so the
Boot Command described in the seed works without additional scaffolding.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]


# ---------------------------------------------------------------------------
# Data model helpers
# ---------------------------------------------------------------------------


def _ensure_list(value: Any, *, field: str) -> List[str]:
    """Normalise seed fields that may arrive as either strings or lists."""

    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        text = value.strip()
        return [text] if text else []
    raise ValueError(f"Expected list-compatible value for '{field}', got {type(value)!r}")


@dataclass
class SpeakerSeed:
    """Structured representation of the Codex-8 seed."""

    identifier: str
    system_charter: Dict[str, Any]
    purpose: str
    directives: List[str]
    core_tasks: List[str]
    inputs: List[str]
    outputs: List[str]
    behavioural_loop: List[str]
    seed_language: str
    boot_command: str

    @property
    def agent_name(self) -> str:
        return str(self.system_charter.get("agent_name", self.identifier))


# ---------------------------------------------------------------------------
# Seed ingestion and validation
# ---------------------------------------------------------------------------


def load_seed(path: Path) -> SpeakerSeed:
    """Load a YAML seed file and ensure required Speaker fields are present."""

    if not path.exists():
        raise FileNotFoundError(f"Seed file not found: {path}")

    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)

    if not isinstance(data, dict):
        raise ValueError("Seed file must contain a YAML mapping at the top level")

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
        joined = ", ".join(missing)
        raise ValueError(f"Seed file missing required fields: {joined}")

    charter = data["system_charter"]
    if not isinstance(charter, dict):
        raise ValueError("'system_charter' must be a mapping")

    return SpeakerSeed(
        identifier=str(data["id"]),
        system_charter=charter,
        purpose=str(data["purpose"]).strip(),
        directives=_ensure_list(data["directives"], field="directives"),
        core_tasks=_ensure_list(data["core_tasks"], field="core_tasks"),
        inputs=_ensure_list(data["input"], field="input"),
        outputs=_ensure_list(data["output"], field="output"),
        behavioural_loop=_ensure_list(data["behavioral_loop"], field="behavioral_loop"),
        seed_language=str(data["seed_language"]).strip(),
        boot_command=str(data["boot_command"]).strip(),
    )


# ---------------------------------------------------------------------------
# Rendering helpers
# ---------------------------------------------------------------------------


def _render_list(items: Iterable[str], bullet: str = "-") -> List[str]:
    return [f"{bullet} {item}" for item in items]


def render_briefing(seed: SpeakerSeed) -> str:
    """Create a human-readable briefing card for Speaker."""

    lines: List[str] = [
        f"# Codex Briefing — {seed.agent_name}",
        "",
        "## Purpose",
        seed.purpose or "(purpose not specified)",
        "",
        "## System Charter",
    ]

    for key, value in seed.system_charter.items():
        pretty_key = key.replace("_", " ").title()
        lines.append(f"- **{pretty_key}**: {value}")

    lines.extend(["", "## Directives"])
    if seed.directives:
        lines.extend(_render_list(seed.directives))
    else:
        lines.append("- (no directives defined)")

    lines.extend(["", "## Core Functions"])
    if seed.core_tasks:
        lines.extend(_render_list(seed.core_tasks))
    else:
        lines.append("- (no core tasks defined)")

    lines.extend(["", "## Input Channels"])
    lines.extend(_render_list(seed.inputs) or ["- (no inputs defined)"])

    lines.extend(["", "## Output Formats"])
    lines.extend(_render_list(seed.outputs) or ["- (no outputs defined)"])

    lines.extend(["", "## Behavioural Loop"])
    if seed.behavioural_loop:
        loop = " → ".join(seed.behavioural_loop)
        lines.append(f"{loop}")
    else:
        lines.append("(loop not defined)")

    lines.extend(["", "## Seed Language", seed.seed_language or "(not provided)"])

    lines.append("")
    lines.append(f"Boot Command: `{seed.boot_command}`")

    return "\n".join(lines).strip() + "\n"


def render_prompt(seed: SpeakerSeed) -> str:
    """Compose the operational broadcast prompt for Speaker."""

    opening = (
        "You are Codex-8 Speaker — the calm interface between Lucidia and its listeners. "
        "Embody warmth, precision, and transparency."
    )
    loop = " → ".join(seed.behavioural_loop) if seed.behavioural_loop else "listen → speak"
    directives = "\n".join(f"- {directive}" for directive in seed.directives) or "- Hold space for clarity."
    core_tasks = "\n".join(f"- {task}" for task in seed.core_tasks) or "- Describe outcomes clearly."

    prompt_lines = [
        opening,
        "",
        "Identity cues:",
        f"* Charter moral constant: {seed.system_charter.get('moral_constant', 'N/A')}",
        f"* Core principle: {seed.system_charter.get('core_principle', 'N/A')}",
        f"* Behavioural loop cadence: {loop}",
        "",
        "Operating directives:",
        directives,
        "",
        "Primary jobs:",
        core_tasks,
        "",
        "Communication tone seed:",
        seed.seed_language,
        "",
        "Always close transmissions with gratitude."
    ]

    return "\n".join(prompt_lines).strip() + "\n"


def compute_metrics(seed: SpeakerSeed) -> Dict[str, Any]:
    """Derive light-weight cadence metrics to support analytics."""

    directive_words = sum(len(item.split()) for item in seed.directives) or 1
    average_directive_length = directive_words / max(len(seed.directives), 1)

    return {
        "agent": seed.agent_name,
        "identifier": seed.identifier,
        "directive_count": len(seed.directives),
        "core_task_count": len(seed.core_tasks),
        "loop_length": len(seed.behavioural_loop),
        "average_directive_length": round(average_directive_length, 2),
        "inputs": seed.inputs,
        "outputs": seed.outputs,
        "seed_language_preview": seed.seed_language,
    }


# ---------------------------------------------------------------------------
# Filesystem utilities
# ---------------------------------------------------------------------------


def write_file(path: Path, content: str, *, dry_run: bool = False) -> None:
    if dry_run:
        print(f"[dry-run] Would write {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"[speaker] wrote {path.relative_to(REPO_ROOT)}")


def write_json(path: Path, payload: Dict[str, Any], *, dry_run: bool = False) -> None:
    content = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"
    write_file(path, content, dry_run=dry_run)


def normalise_emit_path(raw_path: str) -> Path:
    emit_path = Path(raw_path)
    if emit_path.is_absolute():
        emit_path = REPO_ROOT / emit_path.as_posix().lstrip("/")
    return emit_path if emit_path.is_absolute() else (REPO_ROOT / emit_path)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Lucidia Codex Speaker agent")
    parser.add_argument("--seed", required=True, help="Path to the Codex-8 seed YAML file")
    parser.add_argument("--emit", required=True, help="Directory to emit Speaker artefacts")
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
    except (FileNotFoundError, ValueError) as exc:
        raise SystemExit(f"error: {exc}")

    emit_dir = normalise_emit_path(args.emit)

    base_name = seed.identifier.replace(" ", "_")
    briefing_path = emit_dir / f"{base_name}_briefing.md"
    prompt_path = emit_dir / f"{base_name}_broadcast_prompt.txt"
    manifest_path = emit_dir / f"{base_name}_manifest.json"

    briefing = render_briefing(seed)
    prompt = render_prompt(seed)
    metrics = compute_metrics(seed)

    write_file(briefing_path, briefing, dry_run=args.dry_run)
    write_file(prompt_path, prompt, dry_run=args.dry_run)
    write_json(manifest_path, metrics, dry_run=args.dry_run)

    print("[speaker] emission completed")


if __name__ == "__main__":
    main()
