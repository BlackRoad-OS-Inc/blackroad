"""Base classes for bot implementations."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Mapping, Sequence

from orchestrator.consent import ConsentRegistry
from orchestrator.exceptions import ConsentError
from orchestrator.protocols import BotResponse, Task


@dataclass(slots=True)
class BotMetadata:
    """Structured metadata describing bot responsibilities."""

    name: str
    mission: str
    inputs: Sequence[str]
    outputs: Sequence[str]
    kpis: Sequence[str]
    guardrails: Sequence[str]
    handoffs: Sequence[str]
    tags: Sequence[str] = field(default_factory=tuple)


class BaseBot(ABC):
    """Abstract base class for all bots."""

    metadata: BotMetadata

    def __init__(self) -> None:
        if not hasattr(self, "metadata"):
            raise ValueError("Bots must define metadata of type BotMetadata")

    @abstractmethod
    def handle_task(self, task: Task) -> BotResponse:
        """Execute the task and return a structured response."""

    def run(self, task: Task) -> BotResponse:
        """Wrapper around :meth:`handle_task` for future instrumentation."""

        owner = task.owner or "system"
        registry = ConsentRegistry.get_default()
        registry.check_consent(
            from_agent=owner,
            to_agent=self.metadata.name,
            consent_type="task_assignment",
            scope=(f"task:{task.id}", "task_assignment"),
        )

        response = self.handle_task(task)
        if not isinstance(response, BotResponse):
            raise ConsentError("bot responses must be structured for consent auditing")
        return response

    def describe(self) -> Mapping[str, Sequence[str]]:
        """Return human-readable metadata about the bot."""

        return {
            "mission": [self.metadata.mission],
            "inputs": list(self.metadata.inputs),
            "outputs": list(self.metadata.outputs),
            "kpis": list(self.metadata.kpis),
            "guardrails": list(self.metadata.guardrails),
            "handoffs": list(self.metadata.handoffs),
            "tags": list(self.metadata.tags),
        }
from abc import ABC, abstractmethod
from .protocols import Task, BotResponse


class BaseBot(ABC):
    """Abstract base class for bots."""

    name: str
    mission: str

    @abstractmethod
    def run(self, task: Task) -> BotResponse:  # pragma: no cover - interface
        """Run the bot on a task."""
        raise NotImplementedError


def assert_guardrails(response: BotResponse) -> None:
    """Ensure required fields in a BotResponse."""
    if not response.summary or not response.summary.strip():
        raise AssertionError("Summary required")
    if not response.steps:
        raise AssertionError("Steps required")
    if not isinstance(response.data, dict):
        raise AssertionError("Data must be a dict")
    if not response.risks:
        raise AssertionError("Risks required")
    if not response.artifacts:
        raise AssertionError("Artifacts required")
    if not response.next_actions:
        raise AssertionError("Next actions required")
    if response.ok is None:
        raise AssertionError("ok flag required")
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Dict, List, Protocol


@dataclass
class Task:
    id: str
    goal: str
    context: Dict[str, Any] | None = None


@dataclass
class BotResponse:
    summary: str
    artifacts: Dict[str, Any] = field(default_factory=dict)
    risks: List[str] = field(default_factory=list)


class BaseBot(Protocol):
    """Interface that all bots must implement."""

    NAME: str
    MISSION: str
    SUPPORTED_TASKS: List[str]

    def run(self, task: Task) -> BotResponse:
        ...


__all__ = ["Task", "BotResponse", "BaseBot", "asdict"]
