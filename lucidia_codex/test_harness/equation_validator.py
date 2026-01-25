"""
equation_validator.py

Test harness for validating the coherence equation within the Lucidia codex.

This script imports the validated coherence equation implementation and
performs numerical checks on its boundedness and monotonicity. The harness
is designed to be simple and independent: run it directly to see a JSON
report summarizing the validation results.

Functions:
    test_coherence_samples() -> list[float]:
        Compute coherence for several representative input triples.

    validate_monotonicity(psi_m: float, alpha: float, deltas: list[float]) -> bool:
        Check that coherence is non-increasing as the magnitude of delta grows.

    generate_validation_report() -> dict[str, bool]:
        Run all tests and return a dictionary summarizing pass/fail.

Run this file as a script to print the report to stdout.
"""

from __future__ import annotations
from typing import List, Dict
import json
import sys
from pathlib import Path

# Attempt a relative import of the coherence equation.
try:
    from ..validated.coherence_equation import calculate_coherence
except ImportError:
    # Fallback: add the parent of this file's parent to sys.path.
    current_path = Path(__file__).resolve()
    # lucidia_codex/test_harness/equation_validator.py -> parents[2] == lucidia_codex
    parent_root = current_path.parents[2]
    sys.path.insert(0, str(parent_root))
    try:
        from validated.coherence_equation import calculate_coherence  # type: ignore
    except Exception as exc:
        raise ImportError("Unable to import calculate_coherence from validated.coherence_equation") from exc

def test_coherence_samples() -> List[float]:
    """Compute coherence for a set of representative input triples.

    Returns:
        A list of computed coherence values.
    """
    samples = [
        (0.5, 0.0, 0.3),
        (0.5, -2.0, 0.3),
        (1.0, 10.0, 1.0),
        (-1.0, 5.0, 1.0),
    ]
    return [calculate_coherence(psi_m, delta, alpha) for psi_m, delta, alpha in samples]

def validate_monotonicity(psi_m: float, alpha: float, deltas: List[float]) -> bool:
    """Check that coherence decreases or stays constant as |delta| increases.

    Args:
        psi_m: Truth value of memory (within [-1, 1]).
        alpha: Constructive contradiction weight (within [-1, 1]).
        deltas: A list of contradiction magnitudes in non-decreasing order.

    Returns:
        True if coherence is non-increasing across the provided deltas; False otherwise.
    """
    values = [calculate_coherence(psi_m, d, alpha) for d in deltas]
    # Verify each successive value is less than or equal to the previous.
    return all(earlier >= later for earlier, later in zip(values, values[1:]))

def generate_validation_report() -> Dict[str, bool]:
    """Generate a validation report for the coherence equation.

    The report currently includes boundedness and monotonicity checks.

    Returns:
        A dictionary with boolean results for each validation test.
    """
    report: Dict[str, bool] = {}
    # Boundedness: all sample results should lie in [0, 1]
    sample_results = test_coherence_samples()
    report["coherence_bounded"] = all(0.0 <= v <= 1.0 for v in sample_results)
    # Monotonicity: test with increasing absolute delta values.
    delta_values = [0, 1, 2, 3, 4, 5]
    report["coherence_monotonic"] = validate_monotonicity(0.5, 0.3, delta_values)
    return report

def main() -> None:
    """Run the validation tests and print a JSON report."""
    report = generate_validation_report()
    print(json.dumps(report, indent=2))

if __name__ == "__main__":
    main()
