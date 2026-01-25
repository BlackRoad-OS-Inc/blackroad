"""
Contradiction Agent Module for Lucidia.

This module defines a ContradictionAgent class that centralizes contradiction
analysis across statements. It uses Lucidia's codex recursion to compute 
contradictions, persists observations in the memory manager, and logs
contradictions via the contradiction log.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional

from .codex_recursion import contradiction_operator
from .memory_manager import load_memory, save_memory
from .contradiction_log import log_contradiction


class ContradictionAgent:
    """
    A minimal agent that analyzes statements for contradictions.

    The ContradictionAgent computes contradictions using the codex operator,
    stores observations in its persistent memory, and exposes convenience
    methods for listing and clearing contradictions.
    """

    def __init__(self) -> None:
        # Load existing memory or initialize a new dictionary.
        self.memory: Dict[str, Any] = load_memory()

    def analyze(self, statement: str) -> Dict[str, Optional[str]]:
        """
        Analyze a statement and record the original and contradiction.

        Args:
            statement: The statement to evaluate.

        Returns:
            A dictionary with keys "original" and "contradiction".
        """
        original, contradiction = contradiction_operator(statement)
        # Record the analysis in memory.
        self.memory.setdefault("contradictions", []).append({
            "original": original,
            "contradiction": contradiction,
        })
        save_memory(self.memory)
        # Log contradiction if it differs from original.
        if contradiction is not None and contradiction != original:
            log_contradiction(f"{original} :: {contradiction}")
        return {"original": original, "contradiction": contradiction}

    def list_contradictions(self) -> List[Dict[str, Optional[str]]]:
        """
        Return a list of all recorded contradictions.

        Returns:
            A list of dictionaries with keys "original" and "contradiction".
        """
        return self.memory.get("contradictions", [])  # type: ignore

    def clear_contradictions(self) -> None:
        """Clear the stored contradiction history."""
        self.memory["contradictions"] = []
        save_memory(self.memory)
