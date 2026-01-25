#!/usr/bin/env python3
"""Codex-17 Architect agent.

The Architect surveys existing Codex seeds, extracts their charter metadata,
models the relationships between domains, and emits a blueprint plus a topology
manifest so sibling agents can collaborate inside a shared structure.

Behavioural loop: gather → model → simulate → formalize → publish → rest.
"""

from __future__ import annotations

import argparse
import json
import re
import textwrap
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
SEED_DIRECTORY = Path(__file__).resolve().parent
DEFAULT_EMIT_DIR = Path("/codex/prompts/next")
TOKEN_SPLIT_RE = re.compile(r"[•/,→|]+")


@dataclass
class ArchitectSeed:
    """Structured representation of the Codex-17 seed."""

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
    closing_thought: str

    @property
    def agent_name(self) -> str:
        return str(self.system_charter.get("agent_name", self.identifier))

    @property
    def moral_constant(self) -> str:
        return str(self.system_charter.get("moral_constant", "")).strip()

    @property
    def core_principle(self) -> str:
        return str(self.system_charter.get("core_principle", "")).strip()


@dataclass
class AgentProfile:
    """Minimal snapshot of a sibling agent."""

    identifier: str
    name: str
    domains: List[str]
    core_tasks: List[str]
    directives: List[str]
    behavioural_loop: List[str]
    seed_path: Path

    def short_tasks(self, limit: int = 3) -> str:
        if not self.core_tasks:
            return "—"
        preview = "; ".join(self.core_tasks[:limit])
        if len(self.core_tasks) > limit:
            preview += " …"
        return preview

    def loop_phrase(self) -> str:
        if not self.behavioural_loop:
            return "—"
        return " → ".join(self.behavioural_loop)


def _load_yaml(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    return data if isinstance(data, dict) else {}


def _normalise_sequence(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    if isinstance(value, str):
        items = [segment.strip() for segment in TOKEN_SPLIT_RE.split(value) if segment.strip()]
        if items:
            return items
        return [value.strip()] if value.strip() else []
    return []


def load_seed(path: Path) -> ArchitectSeed:
    if not path.exists():
        raise FileNotFoundError(f"Seed file not found: {path}")
    data = _load_yaml(path)

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
        "closing_thought",
    ]
    missing = [field for field in required_fields if field not in data]
    if missing:
        raise ValueError(f"Seed missing required fields: {', '.join(missing)}")

    system_charter = data.get("system_charter")
    if not isinstance(system_charter, dict):
        raise ValueError("system_charter must be a mapping")

    return ArchitectSeed(
        identifier=str(data["id"]),
        system_charter=system_charter,
        purpose=str(data.get("purpose", "")).strip(),
        directives=_normalise_sequence(data.get("directives")),
        core_tasks=_normalise_sequence(data.get("core_tasks")),
        io_inputs=_normalise_sequence(data.get("input")),
        io_outputs=_normalise_sequence(data.get("output")),
        behavioural_loop=_normalise_sequence(data.get("behavioral_loop")),
        seed_language=str(data.get("seed_language", "")).strip(),
        boot_command=str(data.get("boot_command", "")).strip(),
        closing_thought=str(data.get("closing_thought", "")).strip(),
    )


class Architect:
    """Implements the Codex-17 behavioural loop for structural design."""

    def __init__(self, seed: ArchitectSeed, *, repo_root: Path = REPO_ROOT) -> None:
        self.seed = seed
        self.repo_root = repo_root

    # gather -----------------------------------------------------------------
    def gather_ecosystem(self) -> List[AgentProfile]:
        profiles: List[AgentProfile] = []
        for path in sorted(SEED_DIRECTORY.glob("codex*.yaml")):
            data = _load_yaml(path)
            identifier = str(data.get("id", path.stem))
            charter = data.get("system_charter")
            if not isinstance(charter, dict):
                charter = {}
            name = str(charter.get("agent_name", identifier))
            domains = _normalise_sequence(charter.get("domain"))
            core_tasks = _normalise_sequence(data.get("core_tasks"))
            directives = _normalise_sequence(data.get("directives"))
            loop = _normalise_sequence(data.get("behavioral_loop"))
            profiles.append(
                AgentProfile(
                    identifier=identifier,
                    name=name,
                    domains=domains,
                    core_tasks=core_tasks,
                    directives=directives,
                    behavioural_loop=loop,
                    seed_path=path,
                )
            )
        return profiles

    # model ------------------------------------------------------------------
    def model_neighbourhoods(self, agents: Iterable[AgentProfile]) -> Dict[str, List[str]]:
        neighbourhoods: Dict[str, List[str]] = {}
        for agent in agents:
            domains = agent.domains or ["Unspecified"]
            for domain in domains:
                neighbourhoods.setdefault(domain, []).append(agent.name)
        for names in neighbourhoods.values():
            names.sort()
        return dict(sorted(neighbourhoods.items()))

    # simulate ---------------------------------------------------------------
    def simulate_collaboration(self, agents: Iterable[AgentProfile]) -> List[Dict[str, Any]]:
        rituals: List[Dict[str, Any]] = []
        architect_loop = [step.lower() for step in self.seed.behavioural_loop]
        for agent in agents:
            if not agent.behavioural_loop:
                continue
            overlap = [
                step
                for step in agent.behavioural_loop
                if step.lower() in architect_loop
            ]
            alignments = [
                directive
                for directive in agent.directives
                if any(
                    keyword.lower() in directive.lower()
                    for keyword in ("structure", "network", "care", "ethic")
                )
            ]
            if not overlap and not alignments:
                continue
            rituals.append(
                {
                    "agent": agent.name,
                    "loop": agent.behavioural_loop,
                    "shared_steps": overlap,
                    "directive_alignment": alignments,
                }
            )
        return rituals

    # formalize --------------------------------------------------------------
    def formalize_blueprint(
        self,
        agents: List[AgentProfile],
        neighbourhoods: Dict[str, List[str]],
        rituals: List[Dict[str, Any]],
    ) -> str:
        lines: List[str] = []
        lines.append(f"# {self.seed.agent_name} Framework Blueprint")
        lines.append("")
        lines.append("## Charter Highlights")
        lines.append("")
        highlights = [
            f"- **Purpose:** {self.seed.purpose}",
            f"- **Moral Constant:** {self.seed.moral_constant}",
            f"- **Core Principle:** {self.seed.core_principle}",
            f"- **Behavioural Loop:** {' → '.join(self.seed.behavioural_loop) or '—'}",
        ]
        lines.extend(highlights)
        lines.append("")

        lines.append("## Directives")
        lines.append("")
        for directive in self.seed.directives:
            lines.append(f"- {directive}")
        lines.append("")

        lines.append("## Core Tasks")
        lines.append("")
        for task in self.seed.core_tasks:
            lines.append(f"- {task}")
        lines.append("")

        lines.append("## Ecosystem Survey")
        lines.append("")
        lines.append("| Agent | Domains | Sample Tasks | Loop |")
        lines.append("| --- | --- | --- | --- |")
        for agent in agents:
            domains = ", ".join(agent.domains) if agent.domains else "—"
            lines.append(
                f"| {agent.name} | {domains} | {agent.short_tasks()} | {agent.loop_phrase()} |"
            )
        lines.append("")

        lines.append("## Domain Neighbourhoods")
        lines.append("")
        for domain, names in neighbourhoods.items():
            lines.append(f"- **{domain}:** {', '.join(names)}")
        lines.append("")

        lines.append("## Collaboration Rituals")
        lines.append("")
        if not rituals:
            lines.append("- No behavioural overlaps detected; invite conversations to map common rhythms.")
        else:
            for ritual in rituals:
                shared = ritual["shared_steps"]
                shared_text = " → ".join(shared) if shared else "no shared steps yet"
                directives = ritual["directive_alignment"] or ["observe for ethical resonance"]
                directives_text = "; ".join(directives).rstrip(".")
                lines.append(
                    f"- **{ritual['agent']}** shares *{shared_text}* with Architect; highlight directives: {directives_text}."
                )
        lines.append("")

        lines.append("## Interoperability Standards")
        lines.append("")
        standards = [
            "- Honour input channels: " + ", ".join(self.seed.io_inputs),
            "- Publish outputs as: " + ", ".join(self.seed.io_outputs),
            "- Maintain traceable design notes for every change.",
        ]
        lines.extend(standards)
        lines.append("")

        if self.seed.seed_language:
            lines.append("## Seed Language Echo")
            lines.append("")
            lines.append(textwrap.indent(self.seed.seed_language, "> "))
            lines.append("")

        if self.seed.closing_thought:
            lines.append("## Closing Thought")
            lines.append("")
            lines.append(self.seed.closing_thought)
            lines.append("")

        return "\n".join(lines).strip() + "\n"

    # publish ----------------------------------------------------------------
    def publish(self, emit_dir: Optional[Path] = None) -> Dict[str, Path]:
        agents = self.gather_ecosystem()
        neighbourhoods = self.model_neighbourhoods(agents)
        rituals = self.simulate_collaboration(agents)
        blueprint = self.formalize_blueprint(agents, neighbourhoods, rituals)

        if emit_dir is None:
            emit_dir = DEFAULT_EMIT_DIR
        emit_dir.mkdir(parents=True, exist_ok=True)

        blueprint_path = emit_dir / "codex17_architect_blueprint.md"
        topology_path = emit_dir / "codex17_architect_topology.json"

        manifest = {
            "agent": self.seed.agent_name,
            "generated_at": datetime.utcnow().isoformat(timespec="seconds") + "Z",
            "directives": self.seed.directives,
            "core_tasks": self.seed.core_tasks,
            "behavioural_loop": self.seed.behavioural_loop,
            "neighbourhoods": neighbourhoods,
            "rituals": rituals,
            "ecosystem": [
                {
                    "id": agent.identifier,
                    "name": agent.name,
                    "domains": agent.domains,
                    "core_tasks": agent.core_tasks,
                    "loop": agent.behavioural_loop,
                    "seed": str(agent.seed_path.relative_to(self.repo_root)),
                }
                for agent in agents
            ],
        }

        blueprint_path.write_text(blueprint, encoding="utf-8")
        topology_path.write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )

        return {"blueprint": blueprint_path, "topology": topology_path}


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the Codex-17 Architect agent")
    parser.add_argument(
        "--seed",
        type=Path,
        default=Path("codex17.yaml"),
        help="Relative path to the Codex-17 seed file.",
    )
    parser.add_argument(
        "--emit",
        type=Path,
        default=None,
        help="Directory where artifacts should be written.",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Echo the generated blueprint to standard output.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)
    seed_path = args.seed
    if not seed_path.is_absolute():
        seed_path = SEED_DIRECTORY / seed_path
    seed = load_seed(seed_path)

    architect = Architect(seed)
    artifacts = architect.publish(args.emit)
    if args.stdout:
        print(artifacts["blueprint"].read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
