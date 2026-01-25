"""Lucidia Quantum Engine."""
from __future__ import annotations

from .archetypal_geometry import (
    PHI,
    PHI_SQUARED,
    SPIRAL_ANGLE_DEG,
    ALPHA_RESONANCE,
    AlphaResonanceConstant,
    ArchetypalGeometryEngine,
    MemoryArchetypeRegistry,
    PlatonicGeometryEngine,
    PlatonicSolid,
    QuantumOrbitalField,
    SophiaEquation,
)
from .backends import available_backends, backend_names, backend_summaries, get_backend
from .policy import enforce_import_block, guard_env, set_seed

enforce_import_block()

__all__ = [
    'enforce_import_block',
    'guard_env',
    'set_seed',
    'available_backends',
    'backend_names',
    'backend_summaries',
    'get_backend',
    'ALPHA_RESONANCE',
    'PHI',
    'PHI_SQUARED',
    'SPIRAL_ANGLE_DEG',
    'AlphaResonanceConstant',
    'ArchetypalGeometryEngine',
    'MemoryArchetypeRegistry',
    'PlatonicGeometryEngine',
    'PlatonicSolid',
    'QuantumOrbitalField',
    'SophiaEquation',
]
