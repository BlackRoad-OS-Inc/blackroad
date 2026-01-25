"""Decision logic for Lucidia reasoning duet rounds."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

from .validator import ValidationResult

Decision = Literal["accept", "revise", "reject"]
Winner = Literal["LLM", "Ψ′"]


@dataclass
class ArbiterDecision:
    decision: Decision
    winner: Winner
    reasons: list[str]

    def to_payload(self) -> dict[str, object]:
        return {
            "decision": self.decision,
            "winner": self.winner,
            "reasons": list(self.reasons),
        }


def decide(validation: ValidationResult) -> ArbiterDecision:
    """Derive an arbiter decision from a validation result."""

    reasons: list[str] = []
    if not validation.logic_chain_valid or validation.contradictions or validation.banned_fallbacks_detected:
        if not validation.logic_chain_valid:
            reasons.append("logic_chain_invalid")
        if validation.contradictions:
            reasons.append("contradictions")
        if validation.banned_fallbacks_detected:
            reasons.append("banned_fallbacks")
        return ArbiterDecision(decision="reject", winner="Ψ′", reasons=reasons or ["validation_failure"])

    if validation.missing_premises or validation.missing_compliance_steps:
        if validation.missing_premises:
            reasons.append("missing_premises")
        if validation.missing_compliance_steps:
            reasons.append("missing_compliance_steps")
        return ArbiterDecision(decision="revise", winner="Ψ′", reasons=reasons)

    return ArbiterDecision(decision="accept", winner="LLM", reasons=["passes_all_checks"])


__all__ = ["ArbiterDecision", "decide"]
