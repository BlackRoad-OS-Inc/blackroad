"""Policy enforcement for task routing."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Mapping, Sequence

import yaml

from orchestrator.exceptions import ApprovalRequiredError


@dataclass(slots=True)
class PolicyRule:
    """Definition of a single policy rule."""

    requires_approval: bool
    approvers: Sequence[str]
    sla_hours: int | None = None


@dataclass(slots=True)
class PolicyDecision:
    """Result of evaluating a policy rule."""

    approved: bool
    message: str
    outstanding_approvers: Sequence[str]


class PolicyEngine:
    """Loads and evaluates policy rules."""

    def __init__(self, rules: Mapping[str, PolicyRule]):
        self._rules = dict(rules)

    @classmethod
    def from_file(cls, path: Path) -> "PolicyEngine":
        """Load policy rules from a YAML file."""

        if not path.exists():
            return cls({})
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        raw_rules = data.get("policies", {})
        rules: Dict[str, PolicyRule] = {}
        for name, payload in raw_rules.items():
            rules[name.lower()] = PolicyRule(
                requires_approval=bool(payload.get("requires_approval", False)),
                approvers=tuple(payload.get("approvers", [])),
                sla_hours=payload.get("sla_hours"),
            )
        return cls(rules)

    def check(self, policy_name: str, approved_by: Sequence[str] | None = None) -> PolicyDecision:
        """Evaluate a policy by name and return the decision."""

        rule = self._rules.get(policy_name.lower())
        if not rule:
            return PolicyDecision(True, "No policy defined", [])
        approved_by = tuple(approved_by or [])
        if not rule.requires_approval:
            return PolicyDecision(True, "Approval not required", [])
        outstanding = [approver for approver in rule.approvers if approver not in approved_by]
        if outstanding:
            message = "Approval required" if not approved_by else "Additional approvers required"
            return PolicyDecision(False, message, outstanding)
        return PolicyDecision(True, "All approvals captured", [])

    def enforce(self, policy_name: str, approved_by: Sequence[str] | None = None) -> None:
        """Raise when approvals are missing for the given policy."""

        decision = self.check(policy_name, approved_by)
        if not decision.approved:
            outstanding = ", ".join(decision.outstanding_approvers)
            raise ApprovalRequiredError(
                f"Policy '{policy_name}' requires approvals from: {outstanding}"
            )

    def list_policies(self) -> Mapping[str, PolicyRule]:
        """Return the loaded policy rules."""

        return dict(self._rules)
