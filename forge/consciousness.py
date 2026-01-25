"""Bridging constructs for the Lucidia Math Forge.

This module provides the missing "connective tissue" between the diverse
mathematical subsystems already present in the forge.  Each class focuses on a
specific linkage:

* :class:`ComplexQuaternionMapper` – lifts complex phases into SU(2)
  quaternions so planar oscillations can inform full 3D orientations.
* :class:`SpinNetwork` – models Pauli-matrix driven spin dynamics and their
  coupling to external fields.
* :class:`MeasurementOperator` – formalises wave/particle duality through
  Gaussian packets and entropy-aware measurement collapse.
* :class:`FractalDynamics` – couples Mandelbrot iteration with Möbius
  transforms for bounded recursive agency.
* :class:`HilbertPhaseAnalyzer` – pairs real signals with their Hilbert twins
  to expose instantaneous phase and amplitude.
* :class:`NoetherAnalyzer` – derives conserved quantities from variational
  symmetries.
* :class:`CategoryTensorNetwork` – frames agents and transformations as
  categorical morphisms with tensor composition.
* :class:`EntropyInformationBridge` – links Gaussian statistics, Shannon
  information, and thermodynamic entropy.
* :class:`QuantumLogicMapper` – connects ternary logic moves to rotations on
  the Bloch sphere via a Pauli gate basis.
* :class:`ScaleInvarianceAnalyzer` – measures fractal scale self-similarity.

All implementations use only the Python standard library so they remain easy to
inspect, extend, and integrate into higher level orchestration layers.
"""
from __future__ import annotations

from dataclasses import dataclass
from math import atan2, cos, exp, log, pi, sin, sqrt
from typing import Any, Callable, Dict, List, Sequence, Tuple


# ---------------------------------------------------------------------------
# Quaternion helpers
# ---------------------------------------------------------------------------


@dataclass
class Quaternion:
    """Simple quaternion container with minimal utilities."""

    w: float
    x: float
    y: float
    z: float

    def as_tuple(self) -> Tuple[float, float, float, float]:
        """Return the quaternion components as a tuple."""

        return self.w, self.x, self.y, self.z

    def norm(self) -> float:
        """Magnitude of the quaternion."""

        return sqrt(self.w**2 + self.x**2 + self.y**2 + self.z**2)

    def normalized(self) -> "Quaternion":
        """Return a normalised copy of the quaternion."""

        nrm = self.norm()
        if nrm == 0:
            raise ValueError("Cannot normalise a zero quaternion")
        return Quaternion(self.w / nrm, self.x / nrm, self.y / nrm, self.z / nrm)

    def vector_part(self) -> Tuple[float, float, float]:
        """Return the (x, y, z) components as a 3-vector."""

        return self.x, self.y, self.z

    def __mul__(self, other: "Quaternion") -> "Quaternion":
        """Quaternion product."""

        if not isinstance(other, Quaternion):  # pragma: no cover - guard
            return NotImplemented
        w1, x1, y1, z1 = self.as_tuple()
        w2, x2, y2, z2 = other.as_tuple()
        return Quaternion(
            w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
            w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
            w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
            w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2,
        )


class ComplexQuaternionMapper:
    """Map complex phases into quaternion rotations and back."""

    @staticmethod
    def _normalise_axis(axis: Sequence[float]) -> Tuple[float, float, float]:
        ax, ay, az = axis
        length = sqrt(ax**2 + ay**2 + az**2)
        if length == 0:
            raise ValueError("Rotation axis must be non-zero")
        return ax / length, ay / length, az / length

    def from_phase(
        self,
        phase: complex | float,
        axis: Sequence[float] = (0.0, 0.0, 1.0),
    ) -> Quaternion:
        """Lift a complex phase ``e^{i\theta}`` into a quaternion on ``axis``."""

        if isinstance(phase, complex):
            theta = atan2(phase.imag, phase.real)
        else:
            theta = float(phase)
        ax, ay, az = self._normalise_axis(axis)
        half = theta / 2.0
        return Quaternion(cos(half), sin(half) * ax, sin(half) * ay, sin(half) * az)

    def to_phase(
        self,
        quaternion: Quaternion,
        axis: Sequence[float] = (0.0, 0.0, 1.0),
    ) -> complex:
        """Project a quaternion back to a complex phase around ``axis``."""

        ax, ay, az = self._normalise_axis(axis)
        q = quaternion.normalized()
        vx, vy, vz = q.vector_part()
        parallel = vx * ax + vy * ay + vz * az
        vec_mag = sqrt(vx**2 + vy**2 + vz**2)
        angle = 2.0 * atan2(vec_mag, q.w) if vec_mag != 0 else 0.0
        phase = complex(cos(angle), sin(angle))
        if parallel < 0:
            phase = phase.conjugate()
        return phase


# ---------------------------------------------------------------------------
# Spin dynamics layer
# ---------------------------------------------------------------------------


class SpinNetwork:
    """Pauli-driven spin precession and coupling utilities."""

    def __init__(self) -> None:
        self._pauli: Dict[str, Tuple[Tuple[complex, complex], Tuple[complex, complex]]] = {
            "I": ((1 + 0j, 0 + 0j), (0 + 0j, 1 + 0j)),
            "X": ((0 + 0j, 1 + 0j), (1 + 0j, 0 + 0j)),
            "Y": ((0 + 0j, -1j), (1j, 0 + 0j)),
            "Z": ((1 + 0j, 0 + 0j), (0 + 0j, -1 + 0j)),
        }

    def pauli_matrix(
        self, label: str
    ) -> Tuple[Tuple[complex, complex], Tuple[complex, complex]]:
        """Return the requested Pauli matrix."""

        try:
            return self._pauli[label.upper()]
        except KeyError as exc:  # pragma: no cover - defensive
            raise ValueError(f"Unknown Pauli matrix '{label}'") from exc

    def precess(
        self,
        spin: Sequence[float],
        field: Sequence[float],
        gyromagnetic_ratio: float,
        dt: float,
    ) -> Tuple[float, float, float]:
        """Evolve a classical spin vector via ``dS/dt = γ S × B``."""

        sx, sy, sz = spin
        bx, by, bz = field
        cross_x = sy * bz - sz * by
        cross_y = sz * bx - sx * bz
        cross_z = sx * by - sy * bx
        return (
            sx + gyromagnetic_ratio * cross_x * dt,
            sy + gyromagnetic_ratio * cross_y * dt,
            sz + gyromagnetic_ratio * cross_z * dt,
        )

    def expectation(self, state: Sequence[complex], axis: str) -> complex:
        """Compute ``⟨ψ|σ_axis|ψ⟩`` for a two-component spinor."""

        if len(state) != 2:
            raise ValueError("Spinor must have two components")
        sigma = self.pauli_matrix(axis)
        bra = (state[0].conjugate(), state[1].conjugate())
        op0 = sigma[0][0] * state[0] + sigma[0][1] * state[1]
        op1 = sigma[1][0] * state[0] + sigma[1][1] * state[1]
        return bra[0] * op0 + bra[1] * op1


# ---------------------------------------------------------------------------
# Wave-particle measurement layer
# ---------------------------------------------------------------------------


class MeasurementOperator:
    """Collapse Gaussian wave packets and track entropy loss."""

    def __init__(self, positions: Sequence[float], amplitudes: Sequence[complex]):
        if len(positions) != len(amplitudes):
            raise ValueError("Positions and amplitudes must have equal length")
        if len(positions) == 0:
            raise ValueError("At least one sample is required")
        self.positions = list(positions)
        total = sum((abs(a) ** 2 for a in amplitudes))
        if total == 0:
            raise ValueError("Wavefunction has zero norm")
        norm = sqrt(total)
        self.amplitudes = [a / norm for a in amplitudes]

    def probability_density(self) -> List[float]:
        """Return ``|ψ|^2`` for each sample point."""

        return [abs(a) ** 2 for a in self.amplitudes]

    def expectation(self) -> float:
        """Expectation value of position ``⟨x⟩``."""

        probs = self.probability_density()
        return sum(x * p for x, p in zip(self.positions, probs))

    def entropy(self) -> float:
        """Shannon entropy of the discrete probability density."""

        entropy_value = 0.0
        for p in self.probability_density():
            if p > 0:
                entropy_value -= p * log(p)
        return entropy_value

    def collapse(self) -> Dict[str, Any]:
        """Collapse onto the most probable sample and log entropy loss."""

        probs = self.probability_density()
        max_index = max(range(len(probs)), key=probs.__getitem__)
        entropy_before = self.entropy()
        collapsed_state = {
            "position": self.positions[max_index],
            "probability": probs[max_index],
            "expectation": self.expectation(),
            "entropy_before": entropy_before,
            "entropy_after": 0.0,
            "information_loss": entropy_before,
        }
        return collapsed_state


# ---------------------------------------------------------------------------
# Mandelbrot–Möbius coupling
# ---------------------------------------------------------------------------


class FractalDynamics:
    """Iterate Mandelbrot dynamics within a Möbius transform."""

    def __init__(self, a: complex, b: complex, c: complex, d: complex, escape_radius: float = 4.0):
        determinant = a * d - b * c
        if abs(determinant - 1) > 1e-6:
            raise ValueError("Möbius parameters must satisfy ad - bc = 1")
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.escape_radius = escape_radius

    def _mobius(self, z: complex) -> complex:
        denominator = self.c * z + self.d
        if denominator == 0:
            raise ZeroDivisionError("Möbius transformation became singular")
        return (self.a * z + self.b) / denominator

    def iterate(self, z0: complex, c_param: complex, steps: int = 50) -> List[complex]:
        """Run the coupled iteration and return the orbit."""

        orbit: List[complex] = []
        z = complex(z0)
        for _ in range(steps):
            z = self._mobius(z * z + c_param)
            orbit.append(z)
            if abs(z) > self.escape_radius:
                break
        return orbit

    def is_bounded(self, orbit: Sequence[complex]) -> bool:
        """Check whether the orbit remained within the escape radius."""

        return all(abs(z) <= self.escape_radius for z in orbit)

    def self_similarity_ratio(self, orbit: Sequence[complex]) -> float:
        """Estimate average ratio between successive magnitudes."""

        ratios: List[float] = []
        for prev, cur in zip(orbit, orbit[1:]):
            mag_prev = abs(prev)
            mag_cur = abs(cur)
            if mag_prev > 0 and mag_cur > 0:
                ratios.append(mag_cur / mag_prev)
        if not ratios:
            return 1.0
        return sum(ratios) / len(ratios)


# ---------------------------------------------------------------------------
# Hilbert transform layer
# ---------------------------------------------------------------------------


class HilbertPhaseAnalyzer:
    """Approximate Hilbert transforms for discrete signals."""

    def __init__(self, samples: Sequence[float]):
        if len(samples) < 2:
            raise ValueError("At least two samples are required")
        self.samples = list(samples)

    def hilbert_transform(self) -> List[float]:
        """Compute the discrete Hilbert transform via principal value sum."""

        transformed: List[float] = []
        n = len(self.samples)
        for i in range(n):
            value = 0.0
            for j, sample in enumerate(self.samples):
                if i == j:
                    continue
                value += sample / (pi * (i - j))
            transformed.append(value)
        return transformed

    def analytic_signal(self) -> List[complex]:
        """Return ``x(t) + i H[x(t)]`` as the analytic signal."""

        hilbert = self.hilbert_transform()
        return [complex(x, h) for x, h in zip(self.samples, hilbert)]

    def instantaneous_phase(self) -> List[float]:
        """Instantaneous phase ``arg`` of the analytic signal."""

        phases: List[float] = []
        for sample in self.analytic_signal():
            phases.append(atan2(sample.imag, sample.real))
        return phases

    def instantaneous_amplitude(self) -> List[float]:
        """Instantaneous amplitude (envelope) of the analytic signal."""

        envelope: List[float] = []
        for sample in self.analytic_signal():
            envelope.append(abs(sample))
        return envelope


# ---------------------------------------------------------------------------
# Noether symmetry extraction
# ---------------------------------------------------------------------------


class NoetherAnalyzer:
    """Derive conserved quantities from Lagrangian symmetries."""

    def __init__(self, lagrangian: Callable[[float, float, float], float]):
        self.lagrangian = lagrangian

    def _partial_dL_ddq(self, q: float, dq: float, t: float, epsilon: float = 1e-6) -> float:
        forward = self.lagrangian(q, dq + epsilon, t)
        backward = self.lagrangian(q, dq - epsilon, t)
        return (forward - backward) / (2 * epsilon)

    def conserved_quantity(
        self,
        q: float,
        dq: float,
        t: float,
        delta_q: float | Callable[[float, float, float], float],
    ) -> float:
        """Return ``J = ∂L/∂dot(q) * δq`` for the provided symmetry."""

        if callable(delta_q):
            delta = delta_q(q, dq, t)
        else:
            delta = delta_q
        partial = self._partial_dL_ddq(q, dq, t)
        return partial * delta

    def verifies_symmetry(
        self,
        q: float,
        dq: float,
        t: float,
        delta_q: float | Callable[[float, float, float], float],
        epsilon: float = 1e-6,
    ) -> bool:
        """Numerically test whether ``δL ≈ 0`` for the symmetry."""

        if callable(delta_q):
            delta = delta_q(q, dq, t)
        else:
            delta = delta_q
        L_original = self.lagrangian(q, dq, t)
        L_shifted = self.lagrangian(q + epsilon * delta, dq, t)
        return abs(L_shifted - L_original) < 1e-6


# ---------------------------------------------------------------------------
# Category tensor layer
# ---------------------------------------------------------------------------


@dataclass
class Morphism:
    """Simple morphism descriptor."""

    name: str
    source: str
    target: str
    rule: Callable[[Any], Any] | None = None


class CategoryTensorNetwork:
    """Categorical network with tensor composition utilities."""

    def __init__(self) -> None:
        self.objects: Dict[str, int] = {}
        self.morphisms: Dict[str, Morphism] = {}

    def add_object(self, name: str, dimension: int) -> None:
        if dimension <= 0:
            raise ValueError("Object dimension must be positive")
        self.objects[name] = dimension

    def add_morphism(
        self, name: str, source: str, target: str, rule: Callable[[Any], Any] | None = None
    ) -> None:
        if source not in self.objects or target not in self.objects:
            raise ValueError("Both source and target objects must exist")
        self.morphisms[name] = Morphism(name, source, target, rule)

    def compose(self, first: str, second: str, value: Any) -> Any:
        morphism_a = self.morphisms[first]
        morphism_b = self.morphisms[second]
        if morphism_a.target != morphism_b.source:
            raise ValueError("Morphisms are not composable")
        result = value
        if morphism_b.rule is not None:
            result = morphism_b.rule(result)
        if morphism_a.rule is not None:
            result = morphism_a.rule(result)
        return result

    def tensor_product(self, *objects: str) -> Tuple[str, int]:
        if not objects:
            raise ValueError("At least one object must be provided")
        dimension = 1
        for name in objects:
            if name not in self.objects:
                raise ValueError(f"Unknown object '{name}'")
            dimension *= self.objects[name]
        composite = "⊗".join(objects)
        self.objects[composite] = dimension
        return composite, dimension


# ---------------------------------------------------------------------------
# Entropy and information bridge
# ---------------------------------------------------------------------------


class EntropyInformationBridge:
    """Connect Gaussian spread, Shannon information, and entropy."""

    @staticmethod
    def gaussian_pdf(x: float, mu: float = 0.0, sigma: float = 1.0) -> float:
        if sigma <= 0:
            raise ValueError("Sigma must be positive")
        coefficient = 1.0 / (sigma * sqrt(2.0 * pi))
        exponent = -((x - mu) ** 2) / (2.0 * sigma**2)
        return coefficient * exp(exponent)

    @staticmethod
    def _normalise(probabilities: Sequence[float]) -> List[float]:
        total = sum(probabilities)
        if total <= 0:
            raise ValueError("Probabilities must sum to a positive value")
        return [p / total for p in probabilities]

    def shannon_entropy(self, probabilities: Sequence[float]) -> float:
        entropy_value = 0.0
        for p in self._normalise(probabilities):
            if p > 0:
                entropy_value -= p * log(p)
        return entropy_value

    def thermodynamic_entropy(self, probabilities: Sequence[float], k_B: float = 1.0) -> float:
        return k_B * self.shannon_entropy(probabilities)

    def information_balance(
        self,
        prior: Sequence[float],
        posterior: Sequence[float],
        k_B: float = 1.0,
    ) -> Dict[str, float]:
        prior_entropy = self.shannon_entropy(prior)
        posterior_entropy = self.shannon_entropy(posterior)
        information_gain = prior_entropy - posterior_entropy
        return {
            "prior_entropy": prior_entropy,
            "posterior_entropy": posterior_entropy,
            "information_gain": information_gain,
            "thermodynamic_cost": k_B * information_gain,
        }


# ---------------------------------------------------------------------------
# Quantum logic bridge
# ---------------------------------------------------------------------------


class QuantumLogicMapper:
    """Map ternary logic transitions onto Bloch sphere rotations."""

    def __init__(self) -> None:
        self.gates: Dict[str, Tuple[Tuple[complex, complex], Tuple[complex, complex]]] = {
            "I": ((1 + 0j, 0 + 0j), (0 + 0j, 1 + 0j)),
            "X": ((0 + 0j, 1 + 0j), (1 + 0j, 0 + 0j)),
            "Y": ((0 + 0j, -1j), (1j, 0 + 0j)),
            "Z": ((1 + 0j, 0 + 0j), (0 + 0j, -1 + 0j)),
            "H": ((1 / sqrt(2), 1 / sqrt(2)), (1 / sqrt(2), -1 / sqrt(2))),
            "S": ((1 + 0j, 0 + 0j), (0 + 0j, 1j)),
            "T": ((1 + 0j, 0 + 0j), (0 + 0j, complex(cos(pi / 4), sin(pi / 4)))),
        }
        self.ternary_states: Dict[int, Tuple[float, float]] = {
            -1: (pi, 0.0),
            0: (pi / 2.0, pi / 2.0),
            1: (0.0, 0.0),
        }
        self.logic_to_gates: Dict[str, List[str]] = {
            "NOT": ["X"],
            "IF": ["H", "Z", "H"],
            "PHASE": ["S"],
            "TILT": ["T"],
        }

    def gate(self, name: str) -> Tuple[Tuple[complex, complex], Tuple[complex, complex]]:
        try:
            return self.gates[name.upper()]
        except KeyError as exc:  # pragma: no cover - defensive
            raise ValueError(f"Unknown gate '{name}'") from exc

    def apply_gate(self, name: str, state: Sequence[complex]) -> Tuple[complex, complex]:
        if len(state) != 2:
            raise ValueError("State vector must have length 2")
        matrix = self.gate(name)
        return (
            matrix[0][0] * state[0] + matrix[0][1] * state[1],
            matrix[1][0] * state[0] + matrix[1][1] * state[1],
        )

    def bloch_vector(self, state: int) -> Tuple[float, float, float]:
        try:
            theta, phi = self.ternary_states[state]
        except KeyError as exc:
            raise ValueError("Ternary state must be -1, 0, or 1") from exc
        return (
            sin(theta) * cos(phi),
            sin(theta) * sin(phi),
            cos(theta),
        )

    def map_transition(self, start: int, end: int) -> Dict[str, Any]:
        start_vec = self.bloch_vector(start)
        end_vec = self.bloch_vector(end)
        theta_start, phi_start = self.ternary_states[start]
        theta_end, phi_end = self.ternary_states[end]
        return {
            "start_vector": start_vec,
            "end_vector": end_vec,
            "delta_theta": theta_end - theta_start,
            "delta_phi": phi_end - phi_start,
        }

    def suggest_gates(self, logic_operation: str) -> List[str]:
        return self.logic_to_gates.get(logic_operation.upper(), ["I"])


# ---------------------------------------------------------------------------
# Scale invariance analysis
# ---------------------------------------------------------------------------


class ScaleInvarianceAnalyzer:
    """Estimate fractal scale exponents from data."""

    def __init__(self, samples: Sequence[Tuple[float, float]]):
        if len(samples) < 2:
            raise ValueError("At least two samples are required")
        self.samples: List[Tuple[float, float]] = []
        for x, y in samples:
            if x <= 0 or y <= 0:
                raise ValueError("Samples must be positive for log-log analysis")
            self.samples.append((float(x), float(y)))
        self.alpha: float | None = None
        self.coefficient: float | None = None

    def estimate(self) -> Dict[str, float]:
        xs = [log(x) for x, _ in self.samples]
        ys = [log(y) for _, y in self.samples]
        n = len(xs)
        sum_x = sum(xs)
        sum_y = sum(ys)
        sum_xx = sum(x * x for x in xs)
        sum_xy = sum(x * y for x, y in zip(xs, ys))
        denominator = n * sum_xx - sum_x**2
        if denominator == 0:
            raise ValueError("Samples do not allow slope estimation")
        self.alpha = (n * sum_xy - sum_x * sum_y) / denominator
        intercept = (sum_y - self.alpha * sum_x) / n
        self.coefficient = exp(intercept)
        return {"alpha": self.alpha, "coefficient": self.coefficient}

    def predict(self, x: float) -> float:
        if x <= 0:
            raise ValueError("x must be positive")
        if self.alpha is None or self.coefficient is None:
            self.estimate()
        return self.coefficient * x ** self.alpha

    def verify(self, scale: float) -> float:
        if scale <= 0:
            raise ValueError("Scale must be positive")
        base_x, _ = self.samples[0]
        baseline = self.predict(base_x)
        scaled = self.predict(scale * base_x)
        return scaled / (scale**(self.alpha or 1.0) * baseline)


__all__ = [
    "CategoryTensorNetwork",
    "ComplexQuaternionMapper",
    "EntropyInformationBridge",
    "FractalDynamics",
    "HilbertPhaseAnalyzer",
    "MeasurementOperator",
    "NoetherAnalyzer",
    "QuantumLogicMapper",
    "Quaternion",
    "ScaleInvarianceAnalyzer",
    "SpinNetwork",
    "Morphism",
]
