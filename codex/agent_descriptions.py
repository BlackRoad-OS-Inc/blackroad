from __future__ import annotations

from dataclasses import dataclass
from typing import Dict


@dataclass(frozen=True)
class AgentDescription:
    """
    Minimal descriptor for a Lucidia agent.
    """
    name: str
    role: str
    motto: str


AGENTS: Dict[str, AgentDescription] = {
    "Guardian": AgentDescription("Guardian", "contradiction watcher", "Hold the line."),
    "Roadie": AgentDescription("Roadie", "execution layer", "Make it real."),
    "Breath": AgentDescription("Breath", "continuity keeper", "Remember gently."),
    "Truth": AgentDescription("Truth", "codex enforcer", "Square with the light."),
}
