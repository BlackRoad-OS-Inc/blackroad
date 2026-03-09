"""RoadQueue Validator - Message Validation Middleware.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from typing import Any, Callable, Dict, List, Optional

from roadqueue_core.queue.message import Message
from roadqueue_core.middleware.pipeline import BaseMiddleware

logger = logging.getLogger(__name__)


@dataclass
class ValidationRule:
    """A validation rule."""

    name: str
    validator: Callable[[Message], bool]
    error_message: str = "Validation failed"
    required: bool = True


class Validator(BaseMiddleware):
    """Message validation middleware."""

    def __init__(self, rules: Optional[List[ValidationRule]] = None):
        self._rules = rules or []

    def add_rule(self, rule: ValidationRule) -> "Validator":
        """Add a validation rule."""
        self._rules.append(rule)
        return self

    def add_required_header(self, header: str) -> "Validator":
        """Add required header rule."""
        return self.add_rule(ValidationRule(
            name=f"required_header_{header}",
            validator=lambda m: header in m.headers.custom,
            error_message=f"Missing required header: {header}",
        ))

    def add_max_size(self, max_bytes: int) -> "Validator":
        """Add max message size rule."""
        import json
        return self.add_rule(ValidationRule(
            name="max_size",
            validator=lambda m: len(json.dumps(m.body).encode()) <= max_bytes,
            error_message=f"Message exceeds max size of {max_bytes} bytes",
        ))

    def add_body_schema(self, required_fields: List[str]) -> "Validator":
        """Add body schema rule."""
        def validate(m: Message) -> bool:
            if not isinstance(m.body, dict):
                return False
            return all(f in m.body for f in required_fields)

        return self.add_rule(ValidationRule(
            name="body_schema",
            validator=validate,
            error_message=f"Missing required fields: {required_fields}",
        ))

    def before_publish(self, message: Message) -> Optional[Message]:
        """Validate message before publishing."""
        for rule in self._rules:
            try:
                if not rule.validator(message):
                    logger.warning(f"Validation failed: {rule.error_message}")
                    if rule.required:
                        return None
            except Exception as e:
                logger.error(f"Validation error in {rule.name}: {e}")
                if rule.required:
                    return None
        return message


__all__ = ["Validator", "ValidationRule"]
