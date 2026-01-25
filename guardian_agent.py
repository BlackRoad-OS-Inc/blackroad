"""
    Guardian Agent Module for Lucidia.

    This module defines the GuardianAgent class, which acts as a contradiction
    watcher in Lucidia. The agent monitors statements for contradictions,
    logs them, and ensures stability by comparing current values against
    historical baselines. It persists its observations using Lucidia's memory
    manager and records significant deviations via the contradiction log.
    """

from __future__ import annotations

from typing import Any, Dict, Optional

# Import utility functions from Lucidia's core modules.
from .memory_manager import load_memory, save_memory
from .contradiction_log import log_contradiction
from .codex_recursion import contradiction_operator


class GuardianAgent:
    """
    A minimal agent that watches for contradictions and holds the line.

    The GuardianAgent uses Lucidia's codex recursion to compute contradictions
    of statements, persists its own memory state, and logs any contradictions
    or threshold violations. Its motto is "Hold the line."
    """

    def __init__(self) -> None:
        # Initialize persistent memory store.
        self.memory: Dict[str, Any] = load_memory()

    def monitor_statement(self, statement: str) -> Dict[str, Optional[str]]:
        """
        Monitor a statement by computing its contradiction and recording it.

        Args:
            statement: A truth assertion or fragment to analyze.

        Returns:
            A dictionary containing the original statement and its contradiction.
        """
        original, contradiction = contradiction_operator(statement)
        # Persist the observation.
        self.memory.setdefault("statements", []).append({
            "original": original,
            "contradiction": contradiction,
        })
        save_memory(self.memory)
        # Log contradiction if it differs from original.
        if contradiction is not None and contradiction != original:
            log_contradiction(f"{original} :: {contradiction}")
        return {"original": original, "contradiction": contradiction}

    def hold_line(self, baseline: float, current: float, threshold: float) -> bool:
        """
        Determine whether the current value deviates beyond an allowable threshold.

        If the deviation exceeds the threshold, the event is logged as a
        contradiction and False is returned.

        Args:
            baseline: The reference value to compare against.
            current: The new observed value.
            threshold: The maximum allowed absolute deviation.

        Returns:
            True if the deviation is within the threshold, False otherwise.
        """
        deviation = abs(current - baseline)
        self.memory.setdefault("deviations", []).append({
            "baseline": baseline,
            "current": current,
            "deviation": deviation,
            "threshold": threshold,
        })
        save_memory(self.memory)
        if deviation > threshold:
            log_contradiction(f"Deviation exceeded: {deviation} > {threshold}")
            return False
        return True

    def save_memory(self) -> None:
        """Persist the agent's memory to disk."""
        save_memory(self.memory)

    def get_memory(self) -> Dict[str, Any]:
        """Retrieve the agent's entire memory state."""
        return self.memory
