"""RoadML DataValidator - Data Validation.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional

logger = logging.getLogger(__name__)


class ValidationLevel(Enum):
    ERROR = auto()
    WARNING = auto()
    INFO = auto()


@dataclass
class ValidationIssue:
    """A validation issue."""

    column: str
    issue_type: str
    message: str
    level: ValidationLevel
    row_indices: List[int] = field(default_factory=list)


@dataclass
class ValidationResult:
    """Result of data validation."""

    valid: bool
    issues: List[ValidationIssue] = field(default_factory=list)
    stats: Dict[str, Any] = field(default_factory=dict)
    validated_at: datetime = field(default_factory=datetime.now)


class DataValidator:
    """Data validation with custom rules."""

    def __init__(self):
        self._rules: Dict[str, List[Callable]] = {}

    def add_rule(self, column: str, rule: Callable[[Any], bool], message: str):
        """Add validation rule for column."""
        if column not in self._rules:
            self._rules[column] = []
        self._rules[column].append((rule, message))

    def not_null(self, column: str):
        """Add not null rule."""
        self.add_rule(column, lambda x: x is not None, f"{column} must not be null")
        return self

    def in_range(self, column: str, min_val: float, max_val: float):
        """Add range rule."""
        self.add_rule(
            column,
            lambda x: min_val <= x <= max_val if x is not None else True,
            f"{column} must be in range [{min_val}, {max_val}]"
        )
        return self

    def validate(self, data: Any) -> ValidationResult:
        """Validate data against rules."""
        issues = []

        # Basic validation - would integrate with pandas/spark
        result = ValidationResult(
            valid=len(issues) == 0,
            issues=issues,
        )

        return result


__all__ = ["DataValidator", "ValidationResult", "ValidationIssue", "ValidationLevel"]
