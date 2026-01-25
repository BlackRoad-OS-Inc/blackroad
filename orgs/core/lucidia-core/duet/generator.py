"""Generator interfaces for Lucidia's reasoning duet."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable, Dict, List, Optional, Protocol


@dataclass
class ProposeInput:
    """Minimal information required to form a proposal."""

    goal: str
    context: Dict[str, Any]
    constraints: Optional[List[str]] = None


@dataclass
class Proposal:
    """Structured generator response."""

    summary: str
    rationale: List[str]
    plan: List[str]
    raw: Dict[str, Any] = field(default_factory=dict)

    def to_payload(self) -> Dict[str, Any]:
        """Convert to a serialisable payload."""

        return {
            "summary": self.summary,
            "rationale": list(self.rationale),
            "plan": list(self.plan),
            "raw": dict(self.raw),
        }


class GeneratorBackend(Protocol):
    """Callable signature for lightweight local LLMs."""

    def __call__(self, prompt: str) -> Dict[str, Any]:  # pragma: no cover - protocol definition
        ...


class LocalGenerator:
    """Wraps a lightweight local LLM backend with prompt scaffolding."""

    def __init__(self, model_name: str, backend: GeneratorBackend, prompt_builder: Callable[[ProposeInput], str]) -> None:
        self.model_name = model_name
        self._backend = backend
        self._prompt_builder = prompt_builder

    def build_prompt(self, payload: ProposeInput) -> str:
        """Build the structured system prompt."""

        return self._prompt_builder(payload)

    def propose(self, payload: ProposeInput) -> Proposal:
        """Invoke the backend and normalise output."""

        prompt = self.build_prompt(payload)
        response = self._backend(prompt)
        summary = response.get("summary") or response.get("SUMMARY")
        rationale = response.get("rationale") or response.get("RATIONALE")
        plan = response.get("plan") or response.get("PLAN")

        if not isinstance(summary, str):
            raise ValueError("Generator response must include a 'summary' string.")
        if not isinstance(rationale, list) or not all(isinstance(item, str) for item in rationale):
            raise ValueError("Generator response must include a 'rationale' list of strings.")
        if not isinstance(plan, list) or not all(isinstance(item, str) for item in plan):
            raise ValueError("Generator response must include a 'plan' list of strings.")

        raw = {key: value for key, value in response.items() if key not in {"summary", "SUMMARY", "rationale", "RATIONALE", "plan", "PLAN"}}

        return Proposal(summary=summary.strip(), rationale=[item.strip() for item in rationale], plan=[item.strip() for item in plan], raw=raw)


def default_prompt_builder(payload: ProposeInput) -> str:
    """Default prompt template aligned with duet requirements."""

    constraints = "\n".join(f"- {c}" for c in (payload.constraints or []))
    context_repr = "\n".join(f"{key}: {value}" for key, value in payload.context.items())
    return (
        "SYSTEM: You propose; Codex Ψ′ will validate. No filler. Provide:\n"
        "1) SUMMARY (≤120 words), 2) RATIONALE (bullet steps), 3) PLAN (3 actions).\n"
        "CONSTRAINTS:\n"
        f"{constraints}\n"
        "TASK: {goal}\n"
        "CONTEXT:\n{context}\n"
    ).format(goal=payload.goal, context=context_repr)


__all__ = ["Proposal", "ProposeInput", "LocalGenerator", "default_prompt_builder"]
