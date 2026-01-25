"""Compliance policy enforcement helpers for SEC rule 204-2."""

from __future__ import annotations

import logging
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Mapping, Sequence

from regopy import Input, Interpreter

from orchestrator.exceptions import PolicyViolationError
from orchestrator.protocols import Task


logger = logging.getLogger(__name__)

OVERRIDE_ENV_VAR = "PRISM_SEC_204_2_OVERRIDE"
OVERRIDE_TOKEN = "I_ACKNOWLEDGE_SEC_204_2_RISK"


@dataclass(slots=True)
class SecPolicyResult:
    """Result of evaluating the SEC 204-2 policy."""

    allowed: bool
    messages: Sequence[str]


class SecRule2042Gate:
    """Evaluate the SEC 204-2 forecast policy using a Rego module."""

    def __init__(self, policy_path: Path | None = None) -> None:
        self.policy_path = policy_path or Path("policies/sec_rule_204_2.rego")
        self._interpreter = Interpreter()
        self._module_name = self.policy_path.name
        self._load_policy()

    def _load_policy(self) -> None:
        source = self.policy_path.read_text(encoding="utf-8")
        self._interpreter.add_module(self._module_name, source)

    def evaluate(self, task: Task) -> SecPolicyResult:
        """Evaluate the policy for a task and return the decision."""

        payload = _build_policy_input(task)
        self._interpreter.set_input(Input(payload))

        violations = _extract_strings(self._interpreter.query("data.sec.rule_204_2.deny"))
        if violations:
            return SecPolicyResult(False, tuple(violations))

        allow = _extract_bools(self._interpreter.query("data.sec.rule_204_2.allow"))
        is_allowed = allow[0] if allow else False
        return SecPolicyResult(is_allowed, ())

    def enforce(self, task: Task) -> None:
        """Raise when the policy denies execution for the task."""

        override = os.getenv(OVERRIDE_ENV_VAR)
        if override:
            if override != OVERRIDE_TOKEN:
                raise PolicyViolationError(
                    "SEC rule 204-2 override token invalid; expected explicit acknowledgement"
                )
            logger.warning("SEC rule 204-2 override engaged for task %s", task.id)
            return

        result = self.evaluate(task)
        if not result.allowed:
            message = "; ".join(result.messages) if result.messages else "SEC rule 204-2 policy denied"
            raise PolicyViolationError(message)


def _build_policy_input(task: Task) -> Dict[str, Any]:
    """Construct the input document for the Rego policy."""

    metadata = dict(task.metadata or {})
    context = dict(task.context or {})
    forecast_section = _select_mapping((context.get("forecast"), metadata.get("forecast")))

    deviation = _coerce_number(
        forecast_section.get("deviation")
        if forecast_section
        else None
    )
    baseline = _coerce_number(_first_present(forecast_section, ("baseline", "baseline_revenue")))
    projection = _coerce_number(_first_present(forecast_section, ("projection", "projected", "forecast")))
    actual = _coerce_number(_first_present(forecast_section, ("actual", "actuals")))

    if deviation is None and baseline is not None and projection is not None and baseline != 0:
        deviation = abs(projection - baseline) / abs(baseline)
    elif deviation is None and baseline is not None and actual is not None and baseline != 0:
        deviation = abs(actual - baseline) / abs(baseline)

    citations = _normalise_citations(forecast_section)

    return {
        "task": {
            "id": task.id,
            "goal": task.goal,
            "owner": task.owner,
            "tags": list(task.tags),
            "metadata": metadata,
            "context": context,
        },
        "forecast": {
            "deviation": deviation,
            "baseline": baseline,
            "projection": projection if projection is not None else actual,
            "citations": citations,
        },
    }


def _select_mapping(candidates: Iterable[Any]) -> Mapping[str, Any]:
    for candidate in candidates:
        if isinstance(candidate, Mapping):
            return candidate
    return {}


def _first_present(data: Mapping[str, Any] | None, keys: Sequence[str]) -> Any:
    if not isinstance(data, Mapping):
        return None
    for key in keys:
        if key in data:
            return data[key]
    return None


def _coerce_number(value: Any) -> float | None:
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        stripped = value.strip()
        if not stripped:
            return None
        try:
            return float(stripped)
        except ValueError:
            return None
    return None


def _normalise_citations(data: Mapping[str, Any] | None) -> List[str]:
    raw: Sequence[Any] | None = None
    if isinstance(data, Mapping):
        citations = data.get("citations")
        if isinstance(citations, Sequence) and not isinstance(citations, (str, bytes)):
            raw = citations
        else:
            citation = data.get("citation")
            if isinstance(citation, (str, bytes)):
                raw = [citation]
    if raw is None:
        return []
    cleaned: List[str] = []
    for value in raw:
        if not isinstance(value, (str, bytes)):
            continue
        text = str(value).strip()
        if text:
            cleaned.append(text)
    return cleaned


def _extract_strings(output) -> List[str]:
    messages: List[str] = []
    for result in getattr(output, "results", []):
        for expression in result.expressions:
            if isinstance(expression, list):
                messages.extend(str(item) for item in expression if isinstance(item, str))
            elif isinstance(expression, str):
                messages.append(expression)
            elif isinstance(expression, Mapping):
                for key, value in expression.items():
                    if value is True:
                        messages.append(str(key))
    return messages


def _extract_bools(output) -> List[bool]:
    values: List[bool] = []
    for result in getattr(output, "results", []):
        for expression in result.expressions:
            if isinstance(expression, bool):
                values.append(expression)
    return values


__all__ = ["SecRule2042Gate", "SecPolicyResult", "OVERRIDE_ENV_VAR", "OVERRIDE_TOKEN"]
