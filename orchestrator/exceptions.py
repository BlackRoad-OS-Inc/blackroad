"""Custom exceptions for orchestrator workflows."""

from __future__ import annotations


class OrchestratorError(Exception):
    """Base class for orchestrator-related errors."""


class BotNotRegisteredError(OrchestratorError):
    """Raised when routing references an unknown bot."""


class TaskNotFoundError(OrchestratorError):
    """Raised when a requested task ID does not exist."""


class PolicyViolationError(OrchestratorError):
    """Raised when policy checks fail for a task."""


class ApprovalRequiredError(PolicyViolationError):
    """Raised when a task requires approval before execution."""


class RedactionError(OrchestratorError):
    """Raised when redaction fails to process sensitive content."""


class MemoryWriteError(OrchestratorError):
    """Raised when memory persistence encounters an error."""


class ConsentViolationError(OrchestratorError):
    """Raised when an action is attempted without the required consent."""
class ConsentError(OrchestratorError):
    """Raised when consent validation fails for a sensitive operation."""
