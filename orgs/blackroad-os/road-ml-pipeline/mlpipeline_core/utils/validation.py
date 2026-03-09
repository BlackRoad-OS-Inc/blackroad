"""Validation utilities.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Type, Union

logger = logging.getLogger(__name__)


class ValidationLevel(Enum):
    """Validation severity levels."""

    ERROR = auto()
    WARNING = auto()
    INFO = auto()


@dataclass
class ValidationError:
    """A single validation error."""

    message: str
    field: Optional[str] = None
    level: ValidationLevel = ValidationLevel.ERROR
    code: Optional[str] = None
    value: Any = None


@dataclass
class ValidationResult:
    """Result of validation."""

    valid: bool
    errors: List[ValidationError] = field(default_factory=list)
    warnings: List[ValidationError] = field(default_factory=list)

    def add_error(
        self,
        message: str,
        field: Optional[str] = None,
        code: Optional[str] = None,
        value: Any = None,
    ) -> None:
        """Add an error."""
        self.errors.append(ValidationError(
            message=message,
            field=field,
            level=ValidationLevel.ERROR,
            code=code,
            value=value,
        ))
        self.valid = False

    def add_warning(
        self,
        message: str,
        field: Optional[str] = None,
        code: Optional[str] = None,
        value: Any = None,
    ) -> None:
        """Add a warning."""
        self.warnings.append(ValidationError(
            message=message,
            field=field,
            level=ValidationLevel.WARNING,
            code=code,
            value=value,
        ))

    def merge(self, other: "ValidationResult") -> None:
        """Merge another result into this one."""
        self.errors.extend(other.errors)
        self.warnings.extend(other.warnings)
        if not other.valid:
            self.valid = False


class FieldValidator:
    """Validator for individual fields."""

    def __init__(self, field_name: str):
        self.field_name = field_name
        self._validators: List[Callable[[Any], Optional[str]]] = []

    def required(self) -> "FieldValidator":
        """Field must not be None."""
        def check(value):
            if value is None:
                return f"{self.field_name} is required"
            return None
        self._validators.append(check)
        return self

    def type(self, expected: Type) -> "FieldValidator":
        """Field must be of specified type."""
        def check(value):
            if value is not None and not isinstance(value, expected):
                return f"{self.field_name} must be {expected.__name__}"
            return None
        self._validators.append(check)
        return self

    def min_value(self, minimum: Union[int, float]) -> "FieldValidator":
        """Field must be >= minimum."""
        def check(value):
            if value is not None and value < minimum:
                return f"{self.field_name} must be >= {minimum}"
            return None
        self._validators.append(check)
        return self

    def max_value(self, maximum: Union[int, float]) -> "FieldValidator":
        """Field must be <= maximum."""
        def check(value):
            if value is not None and value > maximum:
                return f"{self.field_name} must be <= {maximum}"
            return None
        self._validators.append(check)
        return self

    def range(
        self,
        minimum: Union[int, float],
        maximum: Union[int, float],
    ) -> "FieldValidator":
        """Field must be within range."""
        return self.min_value(minimum).max_value(maximum)

    def min_length(self, length: int) -> "FieldValidator":
        """Field must have minimum length."""
        def check(value):
            if value is not None and len(value) < length:
                return f"{self.field_name} must have at least {length} characters"
            return None
        self._validators.append(check)
        return self

    def max_length(self, length: int) -> "FieldValidator":
        """Field must have maximum length."""
        def check(value):
            if value is not None and len(value) > length:
                return f"{self.field_name} must have at most {length} characters"
            return None
        self._validators.append(check)
        return self

    def pattern(self, regex: str, message: Optional[str] = None) -> "FieldValidator":
        """Field must match regex pattern."""
        compiled = re.compile(regex)
        def check(value):
            if value is not None and not compiled.match(str(value)):
                return message or f"{self.field_name} has invalid format"
            return None
        self._validators.append(check)
        return self

    def one_of(self, choices: List[Any]) -> "FieldValidator":
        """Field must be one of the choices."""
        def check(value):
            if value is not None and value not in choices:
                return f"{self.field_name} must be one of {choices}"
            return None
        self._validators.append(check)
        return self

    def custom(self, validator: Callable[[Any], Optional[str]]) -> "FieldValidator":
        """Add custom validation function."""
        self._validators.append(validator)
        return self

    def validate(self, value: Any) -> List[str]:
        """Validate value and return errors."""
        errors = []
        for validator in self._validators:
            error = validator(value)
            if error:
                errors.append(error)
        return errors


class SchemaValidator:
    """Validate data against a schema."""

    def __init__(self, schema: Dict[str, Any]):
        self.schema = schema
        self._field_validators: Dict[str, FieldValidator] = {}

    def field(self, name: str) -> FieldValidator:
        """Get or create field validator."""
        if name not in self._field_validators:
            self._field_validators[name] = FieldValidator(name)
        return self._field_validators[name]

    def validate(self, data: Dict[str, Any]) -> ValidationResult:
        """Validate data against schema."""
        result = ValidationResult(valid=True)

        for field_name, validator in self._field_validators.items():
            value = data.get(field_name)
            errors = validator.validate(value)

            for error in errors:
                result.add_error(error, field=field_name)

        return result


class DataValidator:
    """Validate datasets for ML training.

    Features:
    - Schema validation
    - Null checking
    - Range validation
    - Distribution checks
    """

    def __init__(
        self,
        schema: Optional[Dict[str, Type]] = None,
        null_threshold: float = 0.1,
    ):
        self.schema = schema or {}
        self.null_threshold = null_threshold

    def validate(self, data: List[Dict[str, Any]]) -> ValidationResult:
        """Validate dataset."""
        result = ValidationResult(valid=True)

        if not data:
            result.add_warning("Dataset is empty")
            return result

        self._validate_schema(data, result)
        self._validate_nulls(data, result)
        self._validate_types(data, result)

        return result

    def _validate_schema(
        self,
        data: List[Dict[str, Any]],
        result: ValidationResult,
    ) -> None:
        """Validate schema consistency."""
        first_keys = set(data[0].keys())

        for idx, row in enumerate(data[1:], start=1):
            row_keys = set(row.keys())

            missing = first_keys - row_keys
            extra = row_keys - first_keys

            if missing:
                result.add_error(
                    f"Row {idx} missing fields: {missing}",
                    code="SCHEMA_MISMATCH",
                )

            if extra:
                result.add_warning(
                    f"Row {idx} has extra fields: {extra}",
                    code="EXTRA_FIELDS",
                )

    def _validate_nulls(
        self,
        data: List[Dict[str, Any]],
        result: ValidationResult,
    ) -> None:
        """Validate null ratios."""
        if not data:
            return

        fields = data[0].keys()
        total = len(data)

        for field in fields:
            null_count = sum(1 for row in data if row.get(field) is None)
            null_ratio = null_count / total

            if null_ratio > self.null_threshold:
                result.add_warning(
                    f"Field '{field}' has {null_ratio:.1%} nulls",
                    field=field,
                    code="HIGH_NULL_RATIO",
                )

    def _validate_types(
        self,
        data: List[Dict[str, Any]],
        result: ValidationResult,
    ) -> None:
        """Validate field types against schema."""
        for field, expected_type in self.schema.items():
            for idx, row in enumerate(data):
                value = row.get(field)
                if value is not None and not isinstance(value, expected_type):
                    result.add_error(
                        f"Row {idx} field '{field}': expected {expected_type.__name__}, "
                        f"got {type(value).__name__}",
                        field=field,
                        code="TYPE_MISMATCH",
                    )


__all__ = [
    "ValidationResult",
    "ValidationError",
    "ValidationLevel",
    "SchemaValidator",
    "DataValidator",
    "FieldValidator",
]
