"""Rule-based validator for the Lucidia reasoning duet."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Mapping, MutableMapping, Sequence

from .generator import Proposal


@dataclass
class RuleSet:
    """Validation configuration."""

    required_premises: Sequence[str] = ()
    compliance_steps: Sequence[str] = ()
    banned_fallbacks: Sequence[str] = ("as an ai", "cannot access", "do not have the ability")


@dataclass
class MemoryStore:
    """Simple in-memory fact registry."""

    facts: Mapping[str, str] = field(default_factory=dict)

    def referenced_keys(self, text_blocks: Iterable[str]) -> List[str]:
        """Return the memory keys that appear in any provided text block."""

        references: List[str] = []
        for key in self.facts:
            key_lower = key.lower()
            if any(key_lower in block.lower() for block in text_blocks):
                references.append(key)
        return references


@dataclass
class ValidationScore:
    truth: float
    completeness: float
    style_fit: float


@dataclass
class ValidationResult:
    """Normalised validation output."""

    logic_chain_valid: bool
    contradictions: List[str] = field(default_factory=list)
    missing_premises: List[str] = field(default_factory=list)
    missing_compliance_steps: List[str] = field(default_factory=list)
    banned_fallbacks_detected: List[str] = field(default_factory=list)
    memory_refs: List[str] = field(default_factory=list)
    score: ValidationScore = field(default_factory=lambda: ValidationScore(1.0, 1.0, 1.0))
    notes: List[str] = field(default_factory=list)

    def to_payload(self) -> MutableMapping[str, object]:
        return {
            "logic_chain_valid": self.logic_chain_valid,
            "contradictions": list(self.contradictions),
            "missing_premises": list(self.missing_premises),
            "missing_compliance_steps": list(self.missing_compliance_steps),
            "banned_fallbacks_detected": list(self.banned_fallbacks_detected),
            "memory_refs": list(self.memory_refs),
            "score": {
                "truth": self.score.truth,
                "completeness": self.score.completeness,
                "style_fit": self.score.style_fit,
            },
            "notes": list(self.notes),
        }


def _score(valid: ValidationResult) -> ValidationScore:
    truth = 1.0 if valid.logic_chain_valid and not valid.contradictions else 0.5
    completeness_penalty = len(valid.missing_premises) + len(valid.missing_compliance_steps)
    completeness = max(0.0, 1.0 - 0.2 * completeness_penalty)
    style_penalty = len(valid.banned_fallbacks_detected)
    style_fit = max(0.0, 1.0 - 0.3 * style_penalty)
    return ValidationScore(truth=truth, completeness=completeness, style_fit=style_fit)


def _detect_contradictions(proposal: Proposal) -> List[str]:
    """Very lightweight contradiction checks."""

    contradictions: List[str] = []
    text = " ".join([proposal.summary, *proposal.rationale, *proposal.plan]).lower()
    if "not required" in text and "required" in text:
        contradictions.append("Conflicting requirement statements detected")
    return contradictions


def _find_missing(items: Sequence[str], text_blocks: Iterable[str]) -> List[str]:
    missing: List[str] = []
    for item in items:
        if not any(item.lower() in block.lower() for block in text_blocks):
            missing.append(item)
    return missing


def _detect_banned_fallbacks(banned_terms: Sequence[str], text_blocks: Iterable[str]) -> List[str]:
    detected: List[str] = []
    for term in banned_terms:
        if any(term in block.lower() for block in text_blocks):
            detected.append(term)
    return detected


def validate(proposal: Proposal, rules: RuleSet, memory: MemoryStore) -> ValidationResult:
    """Validate a generator proposal against the duet rules."""

    text_blocks: List[str] = [proposal.summary, *proposal.rationale, *proposal.plan]
    contradictions = _detect_contradictions(proposal)
    missing_premises = _find_missing(rules.required_premises, text_blocks)
    missing_compliance = _find_missing(rules.compliance_steps, text_blocks)
    banned = _detect_banned_fallbacks(rules.banned_fallbacks, text_blocks)
    memory_refs = memory.referenced_keys(text_blocks)

    logic_chain_valid = bool(proposal.summary and proposal.rationale and proposal.plan and not contradictions)

    result = ValidationResult(
        logic_chain_valid=logic_chain_valid,
        contradictions=contradictions,
        missing_premises=missing_premises,
        missing_compliance_steps=missing_compliance,
        banned_fallbacks_detected=banned,
        memory_refs=memory_refs,
        notes=[],
    )

    if missing_premises:
        result.notes.append("Missing supporting premises for key claims.")
    if missing_compliance:
        result.notes.append("Compliance template requirements not satisfied.")
    if banned:
        result.notes.append("Banned fallback language detected.")

    result.score = _score(result)
    return result


__all__ = ["RuleSet", "MemoryStore", "ValidationResult", "ValidationScore", "validate"]
