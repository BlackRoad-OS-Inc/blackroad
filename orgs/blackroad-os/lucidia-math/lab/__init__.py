"""Lucidia Math Lab modules with optional backend selection."""

from __future__ import annotations

from importlib import import_module
from typing import Any, Dict, Tuple

__all__ = [
    "TrinaryLogicEngine",
    "ulam_spiral",
    "residue_grid",
    "fourier_prime_gaps",
    "RecursiveSandbox",
    "superposition",
    "classify_wave",
    "QuantumFinanceSimulator",
    "available_backends",
    "backend_names",
    "select_backend",
    "GaussianSignalAnalyzer",
    "ArithmeticSymmetryEngine",
    "ComplexMatrixMapper",
    "QuaternionicRotationEngine",
    "QuantumFieldManifold",
    "FractalMobiusCoupler",
    "NoetherAnalyzer",
    "EntropyFieldMapper",
    "HilbertPhaseAnalyzer",
    "AmundsonCoherenceModel",
    "coherence",
    "decoherence_energy",
    "phase_derivative",
    "amundson_energy_balance",
    "amundson_learning_update",
]

_MODULE_MAP: Dict[str, Tuple[str, str]] = {
    "TrinaryLogicEngine": ("trinary_logic", "TrinaryLogicEngine"),
    "SimpleDiGraph": ("trinary_logic", "SimpleDiGraph"),
    "SimpleEdge": ("trinary_logic", "SimpleEdge"),
    "ulam_spiral": ("prime_explorer", "ulam_spiral"),
    "residue_grid": ("prime_explorer", "residue_grid"),
    "fourier_prime_gaps": ("prime_explorer", "fourier_prime_gaps"),
    "RecursiveSandbox": ("recursion_sandbox", "RecursiveSandbox"),
    "superposition": ("sine_wave_codex", "superposition"),
    "classify_wave": ("sine_wave_codex", "classify_wave"),
    "QuantumFinanceSimulator": ("quantum_finance", "QuantumFinanceSimulator"),
    "available_backends": ("frameworks", "available_backends"),
    "backend_names": ("frameworks", "backend_names"),
    "select_backend": ("frameworks", "select_backend"),
    "GaussianSignalAnalyzer": ("unified_geometry_engine", "GaussianSignalAnalyzer"),
    "ArithmeticSymmetryEngine": ("unified_geometry_engine", "ArithmeticSymmetryEngine"),
    "ComplexMatrixMapper": ("unified_geometry_engine", "ComplexMatrixMapper"),
    "QuaternionicRotationEngine": ("unified_geometry_engine", "QuaternionicRotationEngine"),
    "QuantumFieldManifold": ("unified_geometry_engine", "QuantumFieldManifold"),
    "FractalMobiusCoupler": ("unified_geometry_engine", "FractalMobiusCoupler"),
    "NoetherAnalyzer": ("unified_geometry_engine", "NoetherAnalyzer"),
    "EntropyFieldMapper": ("unified_geometry_engine", "EntropyFieldMapper"),
    "HilbertPhaseAnalyzer": ("unified_geometry_engine", "HilbertPhaseAnalyzer"),
    "AmundsonCoherenceModel": ("amundson_equations", "AmundsonCoherenceModel"),
    "coherence": ("amundson_equations", "coherence"),
    "decoherence_energy": ("amundson_equations", "decoherence_energy"),
    "phase_derivative": ("amundson_equations", "phase_derivative"),
    "amundson_energy_balance": ("amundson_equations", "amundson_energy_balance"),
    "amundson_learning_update": ("amundson_equations", "amundson_learning_update"),
}


def __getattr__(name: str) -> Any:
    if name not in _MODULE_MAP:
        raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
    module_name, attr_name = _MODULE_MAP[name]
    module = import_module(f".{module_name}", __name__)
    return getattr(module, attr_name)


def __dir__() -> list[str]:
    return sorted(__all__)
