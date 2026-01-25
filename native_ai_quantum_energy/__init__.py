"""Top‑level package for Native AI Quantum Energy Lab.

This package exposes the core simulation classes for quantum circuits and
energy/particle dynamics.  Importing from the package will pull in
`QuantumCircuit` and the energy‑simulation functions directly.
"""

from .quantum_simulator import QuantumCircuit
from .energy_simulator import (
    solar_panel_output,
    battery_discharge,
    simulate_particle_collision,
)

__all__ = [
    "QuantumCircuit",
    "solar_panel_output",
    "battery_discharge",
    "simulate_particle_collision",
]
