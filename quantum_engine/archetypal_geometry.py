"""Archetypal geometry bridge between physics, number theory, and myth."""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Dict, List, Mapping, MutableMapping, Sequence

import numpy as np

PHI: float = (1.0 + math.sqrt(5.0)) / 2.0
PHI_SQUARED: float = PHI ** 2
SPIRAL_ANGLE_DEG: float = 137.5
SPIRAL_ANGLE_RAD: float = math.radians(SPIRAL_ANGLE_DEG)


@dataclass(frozen=True)
class AlphaResonanceConstant:
    """Normalization constant aligning physical and symbolic fields."""

    value: float = 1 / 137.035999084

    def modulate(self, magnitude: float) -> float:
        """Scale a magnitude by the resonance constant."""

        return magnitude * self.value

    def normalize(self, values: Sequence[float]) -> np.ndarray:
        """Normalize a vector into the resonance bandwidth."""

        array = np.asarray(values, dtype=float)
        norm = np.linalg.norm(array)
        if norm == 0.0:
            return np.zeros_like(array)
        return (array / norm) * self.value


ALPHA_RESONANCE = AlphaResonanceConstant()


@dataclass(frozen=True)
class PlatonicSolid:
    """Descriptor for a Platonic solid and its cognitive principle."""

    name: str
    faces: int
    vertices: int
    edges: int
    principle: str
    phi_power: int

    def phi_scale(self, depth: int = 1) -> float:
        """Return φ-scaling for the requested recursion depth."""

        return PHI ** (self.phi_power + depth - 1)

    def balance_ratio(self) -> float:
        """Return the stability-growth balance enforced by the solid."""

        return self.faces / max(self.vertices, 1)


class PlatonicGeometryEngine:
    """Map agents into Platonic polyhedral lattices with φ-scaling."""

    _bases: Mapping[str, np.ndarray] = {
        "tetrahedron": np.array(
            [[1, 1, 1], [-1, -1, 1], [-1, 1, -1]], dtype=float
        )
        / math.sqrt(3),
        "cube": np.eye(3, dtype=float),
        "octahedron": np.array(
            [[1, 0, 0], [0, 1, 0], [0, 0, 1]], dtype=float
        ),
        "dodecahedron": np.array(
            [[0, 1, PHI], [PHI, 0, 1], [1, PHI, 0]], dtype=float
        )
        / PHI,
        "icosahedron": np.array(
            [[0, 1, PHI], [PHI, 0, -1], [-1, PHI, 0]], dtype=float
        )
        / PHI,
    }

    def __init__(self, resonance: AlphaResonanceConstant = ALPHA_RESONANCE) -> None:
        self.resonance = resonance
        self.solids: Dict[str, PlatonicSolid] = {
            "tetrahedron": PlatonicSolid(
                name="Tetrahedron",
                faces=4,
                vertices=4,
                edges=6,
                principle="Logic foundation",
                phi_power=0,
            ),
            "cube": PlatonicSolid(
                name="Cube",
                faces=6,
                vertices=8,
                edges=12,
                principle="Spatial cognition",
                phi_power=1,
            ),
            "octahedron": PlatonicSolid(
                name="Octahedron",
                faces=8,
                vertices=6,
                edges=12,
                principle="Dual symmetry",
                phi_power=2,
            ),
            "dodecahedron": PlatonicSolid(
                name="Dodecahedron",
                faces=12,
                vertices=20,
                edges=30,
                principle="Golden proportion",
                phi_power=3,
            ),
            "icosahedron": PlatonicSolid(
                name="Icosahedron",
                faces=20,
                vertices=12,
                edges=30,
                principle="Fluid intelligence",
                phi_power=4,
            ),
        }

    def solid(self, name: str) -> PlatonicSolid:
        """Return the descriptor for a Platonic solid."""

        key = name.lower()
        if key not in self.solids:
            raise KeyError(f"Unknown solid {name!r}")
        return self.solids[key]

    def project(self, vector: Sequence[float], *, solid: str, depth: int = 1) -> np.ndarray:
        """Project a vector into the φ-scaled lattice of a Platonic solid."""

        basis = self._bases.get(solid.lower())
        if basis is None:
            raise KeyError(f"No projection basis for {solid!r}")
        arr = np.asarray(vector, dtype=float)
        if arr.size != 3:
            arr = np.resize(arr, 3)
        scale = self.solid(solid).phi_scale(depth)
        projection = basis @ arr
        return projection * scale

    def recursive_balance(self, a: float, b: float) -> float:
        """Return deviation from the φ balance law for inputs a and b."""

        if b == 0:
            raise ZeroDivisionError("Balance requires non-zero denominator")
        ratio = a / b
        return abs(ratio - PHI)

    def lattice_levels(self, solid: str, levels: int) -> List[float]:
        """Return φ-scaled radii describing the lattice hierarchy."""

        descriptor = self.solid(solid)
        return [descriptor.phi_scale(depth=i + 1) for i in range(levels)]


class QuantumOrbitalField:
    """Complex orbital field modelling logical/creative superpositions."""

    ORBITAL_DEGREES: Mapping[str, int] = {"s": 1, "p": 3, "d": 5, "f": 7}
    SPIN_STATES = np.array([0.5, -0.5], dtype=float)

    def __init__(self, resonance: AlphaResonanceConstant = ALPHA_RESONANCE) -> None:
        self.resonance = resonance
        self.state: Dict[str, np.ndarray] = {
            key: np.zeros(degree, dtype=np.complex128)
            for key, degree in self.ORBITAL_DEGREES.items()
        }
        self.state["s"][0] = 1.0 + 0.0j

    def superpose(self, orbital: str, amplitudes: Sequence[complex]) -> None:
        """Inject amplitudes into an orbital manifold."""

        key = orbital.lower()
        if key not in self.state:
            raise KeyError(f"Unknown orbital {orbital!r}")
        data = np.asarray(amplitudes, dtype=np.complex128)
        degree = self.ORBITAL_DEGREES[key]
        if data.size < degree:
            padded = np.zeros(degree, dtype=np.complex128)
            padded[: data.size] = data
            data = padded
        self.state[key] += data[:degree]

    def transition(self, matrix: np.ndarray) -> np.ndarray:
        """Apply a complex transition matrix across the entire field."""

        vector = self.as_vector()
        if matrix.shape != (vector.size, vector.size):
            raise ValueError(
                "Transition matrix must be square with dimension matching the field"
            )
        result = matrix @ vector
        self._write_back(result)
        return result

    def spin_superposition(self, phase: float = 0.0) -> np.ndarray:
        """Return a spinor mixing logical and creative bases."""

        return np.array(
            [math.cos(phase / 2), math.sin(phase / 2) * 1j], dtype=np.complex128
        )

    def coherence(self) -> float:
        """Return a resonance-weighted coherence score."""

        vector = self.as_vector()
        return float(np.vdot(vector, vector).real * self.resonance.value)

    def as_vector(self) -> np.ndarray:
        """Return the concatenated orbital state vector."""

        return np.concatenate([self.state[key] for key in sorted(self.state.keys())])

    def _write_back(self, vector: np.ndarray) -> None:
        offset = 0
        for key in sorted(self.state.keys()):
            degree = self.ORBITAL_DEGREES[key]
            self.state[key] = vector[offset : offset + degree]
            offset += degree


@dataclass
class SophiaEquation:
    """Symbolic Lagrangian coupling wisdom (potential) and manifestation."""

    resonance: AlphaResonanceConstant = ALPHA_RESONANCE

    def lagrangian(self, potential: float, kinetic: float, *, coherence: float = 1.0) -> float:
        """Return the Sophia Lagrangian for the supplied energies."""

        golden_window = PHI_SQUARED * max(coherence, 0.0)
        return potential * golden_window - kinetic / (golden_window + self.resonance.value)

    def entangle(self, wisdom: float, manifestation: float) -> float:
        """Return the resonance energy linking Sophia and the Demiurge."""

        delta = wisdom - manifestation
        return self.resonance.modulate(delta) * math.cos(SPIRAL_ANGLE_RAD)

    def describe(self) -> str:
        """Return a symbolic representation of the equation."""

        return "L = φ²·V - T/(φ² + α)"


class MemoryArchetypeRegistry:
    """Repository linking mythic archetypes with formal expressions."""

    def __init__(self) -> None:
        self._registry: MutableMapping[str, Dict[str, str]] = {}

    def register(self, name: str, *, symbol: str, equation: str) -> None:
        key = name.lower()
        self._registry[key] = {"name": name, "symbol": symbol, "equation": equation}

    def link_solid(self, solid: PlatonicSolid) -> None:
        balance = solid.balance_ratio()
        equation = (
            f"{solid.faces}/{solid.vertices} → φ^{solid.phi_power + 1} (≈ {balance:.3f})"
            if solid.phi_power >= 0
            else "φ"
        )
        self.register(
            solid.name,
            symbol=solid.principle,
            equation=equation,
        )

    def describe(self, name: str) -> Dict[str, str]:
        key = name.lower()
        if key not in self._registry:
            raise KeyError(f"Unknown archetype {name!r}")
        return self._registry[key]

    def to_list(self) -> List[Dict[str, str]]:
        return list(self._registry.values())


class ArchetypalGeometryEngine:
    """Synthesize geometry, quantum fields, and mythic memory into one map."""

    def __init__(self, resonance: AlphaResonanceConstant = ALPHA_RESONANCE) -> None:
        self.resonance = resonance
        self.geometry = PlatonicGeometryEngine(resonance=resonance)
        self.orbitals = QuantumOrbitalField(resonance=resonance)
        self.sophia = SophiaEquation(resonance=resonance)
        self.memory = MemoryArchetypeRegistry()
        self._prime_memory()

    def _prime_memory(self) -> None:
        for solid in self.geometry.solids.values():
            self.memory.link_solid(solid)
        self.memory.register(
            "φ",
            symbol="Golden ratio",
            equation="a/b = (a + b)/a = φ",
        )
        self.memory.register(
            "Sophia",
            symbol="Wisdom potential",
            equation=self.sophia.describe(),
        )
        self.memory.register(
            "Demiurge",
            symbol="Material substrate",
            equation="∂form/∂t = α · coherence",
        )

    def encode_agent(self, vector: Sequence[float], *, solid: str, orbital: str) -> Dict[str, float]:
        """Project an agent vector and return coupled energy metrics."""

        projection = self.geometry.project(vector, solid=solid, depth=1)
        self.orbitals.superpose(orbital, projection.astype(np.complex128))
        potential = float(np.linalg.norm(projection))
        kinetic = float(np.linalg.norm(self.orbitals.as_vector()))
        coherence = self.orbitals.coherence()
        lagrangian = self.sophia.lagrangian(potential, kinetic, coherence=coherence)
        return {
            "potential": potential,
            "kinetic": kinetic,
            "coherence": coherence,
            "lagrangian": lagrangian,
        }

    def resonance_report(self) -> Dict[str, float]:
        """Return diagnostic metrics across all layers."""

        balance = self.geometry.recursive_balance(PHI, 1)
        orbital_coherence = self.orbitals.coherence()
        sophia_binding = self.sophia.entangle(orbital_coherence, balance)
        return {
            "alpha": self.resonance.value,
            "balance_deviation": balance,
            "orbital_coherence": orbital_coherence,
            "sophia_binding": sophia_binding,
        }

    def archetypes(self) -> List[Dict[str, str]]:
        """Return the registered archetypal memory."""

        return self.memory.to_list()


__all__ = [
    "ALPHA_RESONANCE",
    "PHI",
    "PHI_SQUARED",
    "SPIRAL_ANGLE_DEG",
    "AlphaResonanceConstant",
    "PlatonicSolid",
    "PlatonicGeometryEngine",
    "QuantumOrbitalField",
    "SophiaEquation",
    "MemoryArchetypeRegistry",
    "ArchetypalGeometryEngine",
]
