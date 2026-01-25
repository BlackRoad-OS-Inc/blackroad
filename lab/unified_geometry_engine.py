"""Unified Geometry Engine (Package 6).

This module collects analytical machinery described in the Black Road
framework notes.  It couples probability, number theory, complex analysis,
quantum field operators, and symmetry analysis into a cohesive toolkit.
Each class encapsulates the equations referenced in the specification.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from fractions import Fraction
import cmath
import math
from typing import Callable

import numpy as np
from numpy.typing import ArrayLike, NDArray


Array1D = NDArray[np.float64]
ComplexArray = NDArray[np.complex128]


@dataclass
class GaussianSignalAnalyzer:
    r"""Track a normalized Gaussian in time and frequency domains.

    The probability density is

    .. math::
        f(x) = \frac{1}{\sigma \sqrt{2\pi}} e^{-\frac{(x-\mu)^2}{2\sigma^2}}

    The Fourier transform remains Gaussian with variance ``1/σ`` and the
    derivative property maps to multiplication by ``i ω`` in frequency space.
    """

    mean: float = 0.0
    sigma: float = 1.0

    def __post_init__(self) -> None:
        if self.sigma <= 0:
            raise ValueError("sigma must be positive")

    @property
    def normalization(self) -> float:
        return float(1.0 / (self.sigma * math.sqrt(2.0 * math.pi)))

    def time_domain(self, x: ArrayLike) -> Array1D:
        values = np.asarray(x, dtype=float)
        exponent = -0.5 * ((values - self.mean) / self.sigma) ** 2
        return np.asarray(self.normalization * np.exp(exponent), dtype=float)

    def derivative_time_domain(self, x: ArrayLike) -> Array1D:
        values = np.asarray(x, dtype=float)
        return -((values - self.mean) / (self.sigma**2)) * self.time_domain(values)

    def frequency_domain(self, omega: ArrayLike) -> ComplexArray:
        freqs = np.asarray(omega, dtype=float)
        envelope = np.exp(-0.5 * (self.sigma**2) * freqs**2)
        phase = np.exp(-1j * self.mean * freqs)
        return np.asarray(envelope * phase, dtype=np.complex128)

    def derivative_frequency_domain(self, omega: ArrayLike) -> ComplexArray:
        freqs = np.asarray(omega, dtype=float)
        return np.asarray(1j * freqs * self.frequency_domain(freqs), dtype=np.complex128)

    def coherence(self) -> dict[str, float]:
        sigma_t = float(self.sigma)
        sigma_w = float(1.0 / self.sigma)
        return {
            "time_spread": sigma_t,
            "frequency_spread": sigma_w,
            "uncertainty_product": sigma_t * sigma_w,
        }


@dataclass
class ArithmeticSymmetryEngine:
    """Compute discrete-continuous invariants.

    Combines Ramanujan sums, Faulhaber polynomials, and Euler products to
    characterise symmetry signatures.  The ``fractal_limit`` helper mirrors the
    Mandelbrot iteration bound used elsewhere in the Black Road notebooks.
    """

    _bernoulli_cache: dict[int, Fraction] = field(default_factory=dict, init=False)
    _prime_cache: list[int] = field(default_factory=lambda: [2], init=False)

    def ramanujan_sum(self, q: int, n: int) -> complex:
        if q <= 0:
            raise ValueError("q must be positive")
        total = 0.0j
        for a in range(1, q + 1):
            if math.gcd(a, q) == 1:
                total += cmath.exp(2j * math.pi * a * n / q)
        return total

    def _bernoulli_numbers(self, order: int) -> list[Fraction]:
        if order in self._bernoulli_cache:
            max_cached = max(self._bernoulli_cache)
        else:
            max_cached = -1
        if max_cached >= order:
            return [self._bernoulli_cache[i] for i in range(order + 1)]

        bernoullis: list[Fraction] = []
        for m in range(order + 1):
            a = [Fraction(0) for _ in range(m + 1)]
            for j in range(m + 1):
                a[j] = Fraction(1, j + 1)
                for k in range(j, 0, -1):
                    a[k - 1] = k * (a[k - 1] - a[k])
            bernoullis.append(a[0])
            self._bernoulli_cache[m] = a[0]
        return bernoullis

    def faulhaber_sum(self, power: int, n: int) -> float:
        if power < 0:
            raise ValueError("power must be non-negative")
        if n < 0:
            raise ValueError("n must be non-negative")
        bernoullis = self._bernoulli_numbers(power)
        total = Fraction(0)
        for j in range(power + 1):
            coeff = Fraction(math.comb(power + 1, j))
            total += coeff * bernoullis[j] * Fraction(n ** (power + 1 - j), power + 1)
        return float(total)

    def _generate_primes(self, count: int) -> list[int]:
        if count <= 0:
            raise ValueError("count must be positive")
        candidate = self._prime_cache[-1]
        while len(self._prime_cache) < count:
            candidate += 1
            is_prime = True
            limit = int(math.sqrt(candidate))
            for prime in self._prime_cache:
                if prime > limit:
                    break
                if candidate % prime == 0:
                    is_prime = False
                    break
            if is_prime:
                self._prime_cache.append(candidate)
        return self._prime_cache[:count]

    def euler_product(self, s: complex, terms: int = 10) -> complex:
        primes = self._generate_primes(terms)
        product = 1.0 + 0.0j
        for prime in primes:
            product *= 1.0 / (1.0 - prime ** (-s))
        return product

    def fractal_limit(self, c: complex, max_iter: int = 64, threshold: float = 2.0) -> int:
        z = 0 + 0j
        for iteration in range(1, max_iter + 1):
            z = z**2 + c
            if abs(z) > threshold:
                return iteration
        return max_iter

    def symmetry_signature(
        self,
        q: int,
        n: int,
        power: int,
        s: complex,
        *,
        fractal_seed: complex = 0 + 0j,
        terms: int = 10,
        max_iter: int = 64,
        threshold: float = 2.0,
    ) -> dict[str, complex | float | int]:
        return {
            "ramanujan": self.ramanujan_sum(q, n),
            "faulhaber": self.faulhaber_sum(power, n),
            "euler_product": self.euler_product(s, terms),
            "fractal_limit": self.fractal_limit(fractal_seed, max_iter, threshold),
        }


class ComplexMatrixMapper:
    """Convert between complex scalars, rotation matrices, and quaternions."""

    @staticmethod
    def to_matrix(value: complex) -> NDArray[np.float64]:
        a = float(value.real)
        b = float(value.imag)
        return np.array([[a, -b], [b, a]], dtype=float)

    @staticmethod
    def from_matrix(matrix: ArrayLike) -> complex:
        mat = np.asarray(matrix, dtype=float)
        if mat.shape != (2, 2):
            raise ValueError("matrix must be 2x2")
        if not np.allclose(mat[1, 0], -mat[0, 1]):
            raise ValueError("matrix does not encode a complex number")
        return complex(mat[0, 0], mat[1, 0])

    @staticmethod
    def to_quaternion(value: complex) -> Array1D:
        return np.asarray([value.real, value.imag, 0.0, 0.0], dtype=float)

    @staticmethod
    def rotate_vector(matrix: ArrayLike, vector: ArrayLike) -> Array1D:
        mat = np.asarray(matrix, dtype=float)
        vec = np.asarray(vector, dtype=float)
        return np.asarray(mat @ vec, dtype=float)


@dataclass
class QuaternionicRotationEngine:
    """Handle quaternion rotations for 3D orientation updates."""

    quaternion: Array1D

    def __post_init__(self) -> None:
        self.quaternion = np.asarray(self.quaternion, dtype=float)
        if self.quaternion.shape != (4,):
            raise ValueError("quaternion must be length 4")
        self.normalize()

    @staticmethod
    def from_axis_angle(axis: ArrayLike, angle: float) -> QuaternionicRotationEngine:
        axis_vec = np.asarray(axis, dtype=float)
        if axis_vec.shape != (3,):
            raise ValueError("axis must be a 3-vector")
        norm = np.linalg.norm(axis_vec)
        if norm == 0:
            raise ValueError("axis must be non-zero")
        unit = axis_vec / norm
        half = angle / 2.0
        quat = np.concatenate(([math.cos(half)], unit * math.sin(half)))
        return QuaternionicRotationEngine(quat)

    def normalize(self) -> None:
        norm = np.linalg.norm(self.quaternion)
        if norm == 0:
            raise ValueError("quaternion norm must not be zero")
        self.quaternion = self.quaternion / norm

    def conjugate(self) -> Array1D:
        w, x, y, z = self.quaternion
        return np.asarray([w, -x, -y, -z], dtype=float)

    @staticmethod
    def _multiply(q1: Array1D, q2: Array1D) -> Array1D:
        w1, x1, y1, z1 = q1
        w2, x2, y2, z2 = q2
        return np.asarray(
            [
                w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2,
                w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2,
                w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2,
                w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2,
            ],
            dtype=float,
        )

    def rotate(self, vector: ArrayLike) -> Array1D:
        vec = np.asarray(vector, dtype=float)
        if vec.shape != (3,):
            raise ValueError("vector must be length 3")
        q_vec = np.concatenate(([0.0], vec))
        rotated = self._multiply(self._multiply(self.quaternion, q_vec), self.conjugate())
        return rotated[1:]

    def compose(self, other: QuaternionicRotationEngine) -> QuaternionicRotationEngine:
        combined = self._multiply(self.quaternion, other.quaternion)
        return QuaternionicRotationEngine(combined)

    def as_matrix(self) -> NDArray[np.float64]:
        w, x, y, z = self.quaternion
        return np.array(
            [
                [1 - 2 * (y**2 + z**2), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                [2 * (x * y + z * w), 1 - 2 * (x**2 + z**2), 2 * (y * z - x * w)],
                [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x**2 + y**2)],
            ],
            dtype=float,
        )


def _dirac_gamma_matrices() -> tuple[ComplexArray, ComplexArray, ComplexArray, ComplexArray]:
    sigma_x = np.array([[0, 1], [1, 0]], dtype=complex)
    sigma_y = np.array([[0, -1j], [1j, 0]], dtype=complex)
    sigma_z = np.array([[1, 0], [0, -1]], dtype=complex)
    identity = np.eye(2, dtype=complex)

    gamma0 = np.block([[identity, np.zeros((2, 2), dtype=complex)], [np.zeros((2, 2), dtype=complex), -identity]])
    gamma_i = []
    for sigma in (sigma_x, sigma_y, sigma_z):
        upper = np.zeros((2, 2), dtype=complex)
        lower = np.zeros((2, 2), dtype=complex)
        block = np.block([[upper, sigma], [-sigma, lower]])
        gamma_i.append(block)
    return (gamma0, *gamma_i)


@dataclass
class QuantumFieldManifold:
    """Bridge Schrödinger, Dirac, and Hamiltonian structures."""

    hamiltonian: ComplexArray
    mass: float = 1.0
    hbar: float = 1.0

    def __post_init__(self) -> None:
        self.hamiltonian = np.asarray(self.hamiltonian, dtype=complex)
        if self.hamiltonian.shape[0] != self.hamiltonian.shape[1]:
            raise ValueError("hamiltonian must be square")
        self._gamma = _dirac_gamma_matrices()

    def schrodinger_rhs(self, psi: ArrayLike) -> ComplexArray:
        state = np.asarray(psi, dtype=complex)
        return np.asarray(-1j / self.hbar * (self.hamiltonian @ state), dtype=complex)

    def probability_density(self, psi: ArrayLike) -> Array1D:
        state = np.asarray(psi, dtype=complex)
        return np.asarray(np.abs(state) ** 2, dtype=float)

    def dirac_operator(self, momentum: ArrayLike) -> ComplexArray:
        p = np.asarray(momentum, dtype=float)
        if p.shape != (3,):
            raise ValueError("momentum must be length 3")
        energy = math.sqrt(float(np.dot(p, p)) + self.mass**2)
        p_mu = np.array([energy, p[0], p[1], p[2]], dtype=float)
        operator = sum(gamma * value for gamma, value in zip(self._gamma, p_mu))
        operator -= self.mass * np.eye(operator.shape[0], dtype=complex)
        return operator

    def dirac_residual(self, psi: ArrayLike, momentum: ArrayLike) -> ComplexArray:
        state = np.asarray(psi, dtype=complex)
        operator = self.dirac_operator(momentum)
        return np.asarray(operator @ state, dtype=complex)

    def energy_expectation(self, psi: ArrayLike) -> float:
        state = np.asarray(psi, dtype=complex)
        norm = np.vdot(state, state)
        if norm == 0:
            raise ValueError("state norm must be non-zero")
        value = np.vdot(state, self.hamiltonian @ state) / norm
        return float(value.real)


@dataclass
class FractalMobiusCoupler:
    """Iterate Möbius transformations with Mandelbrot-style bounds."""

    a: complex
    b: complex
    c: complex
    d: complex

    def __post_init__(self) -> None:
        determinant = self.a * self.d - self.b * self.c
        if abs(determinant) == 0:
            raise ValueError("Möbius transformation must have non-zero determinant")
        scale = cmath.sqrt(determinant)
        self.a /= scale
        self.b /= scale
        self.c /= scale
        self.d /= scale
        self._determinant = self.a * self.d - self.b * self.c

    def transform(self, z: complex) -> complex:
        return (self.a * z + self.b) / (self.c * z + self.d)

    def iterate(self, seed: complex, max_iter: int = 64, threshold: float = 2.0) -> list[complex]:
        values = [seed]
        z = seed
        for _ in range(max_iter):
            z = self.transform(z)
            values.append(z)
            if abs(z) > threshold:
                break
        return values

    def bounded(self, seed: complex, max_iter: int = 64, threshold: float = 2.0) -> bool:
        for value in self.iterate(seed, max_iter=max_iter, threshold=threshold):
            if abs(value) > threshold:
                return False
        return True


@dataclass
class NoetherAnalyzer:
    """Numerically evaluate conserved quantities from a Lagrangian."""

    lagrangian: Callable[[float, Array1D, Array1D], float]
    epsilon: float = 1e-6

    def conjugate_momentum(self, t: float, q: ArrayLike, qdot: ArrayLike) -> Array1D:
        coords = np.asarray(q, dtype=float)
        velocities = np.asarray(qdot, dtype=float)
        if coords.shape != velocities.shape:
            raise ValueError("q and qdot must share shape")
        momenta = np.zeros_like(velocities, dtype=float)
        for index in range(len(velocities)):
            delta = np.zeros_like(velocities)
            delta[index] = self.epsilon
            plus = self.lagrangian(t, coords, velocities + delta)
            minus = self.lagrangian(t, coords, velocities - delta)
            momenta[index] = (plus - minus) / (2.0 * self.epsilon)
        return momenta

    def conserved_quantity(self, t: float, q: ArrayLike, qdot: ArrayLike, delta_q: ArrayLike) -> float:
        momentum = self.conjugate_momentum(t, q, qdot)
        variation = np.asarray(delta_q, dtype=float)
        if variation.shape != momentum.shape:
            raise ValueError("delta_q must match configuration shape")
        return float(np.dot(momentum, variation))


@dataclass
class EntropyFieldMapper:
    """Translate Gaussian variance into Shannon-style entropy."""

    k_B: float = 1.0

    def gaussian_entropy(self, sigma: float) -> float:
        if sigma <= 0:
            raise ValueError("sigma must be positive")
        return float(self.k_B * math.log(sigma * math.sqrt(2.0 * math.pi * math.e)))

    def coherence_entropy(self, analyzer: GaussianSignalAnalyzer) -> float:
        return self.gaussian_entropy(analyzer.sigma)


@dataclass
class HilbertPhaseAnalyzer:
    """Hilbert transform utilities for analytic signal analysis."""

    dt: float = 1.0

    def _hilbert_transform(self, signal: ArrayLike) -> ComplexArray:
        values = np.asarray(signal, dtype=float)
        n = values.size
        spectrum = np.fft.fft(values)
        h = np.zeros(n)
        if n % 2 == 0:
            h[0] = 1
            h[n // 2] = 1
            h[1 : n // 2] = 2
        else:
            h[0] = 1
            h[1 : (n + 1) // 2] = 2
        analytic = np.fft.ifft(spectrum * h)
        return np.asarray(analytic, dtype=np.complex128)

    def analytic_signal(self, signal: ArrayLike) -> ComplexArray:
        return self._hilbert_transform(signal)

    def instantaneous_amplitude(self, signal: ArrayLike) -> Array1D:
        analytic = self.analytic_signal(signal)
        return np.asarray(np.abs(analytic), dtype=float)

    def instantaneous_phase(self, signal: ArrayLike) -> Array1D:
        analytic = self.analytic_signal(signal)
        phase = np.unwrap(np.angle(analytic))
        return np.asarray(phase, dtype=float)

    def instantaneous_frequency(self, signal: ArrayLike) -> Array1D:
        phase = self.instantaneous_phase(signal)
        derivative = np.gradient(phase, self.dt)
        return np.asarray(derivative / (2.0 * math.pi), dtype=float)

    def frequency_response(self, signal: ArrayLike) -> tuple[Array1D, ComplexArray]:
        values = np.asarray(signal, dtype=float)
        freq = np.fft.fftfreq(values.size, d=self.dt)
        transform = np.fft.fft(values)
        return np.asarray(freq, dtype=float), np.asarray(transform, dtype=np.complex128)

    def differentiate_via_fourier(self, signal: ArrayLike) -> Array1D:
        freq, transform = self.frequency_response(signal)
        derivative_freq = 1j * 2.0 * math.pi * freq * transform
        derivative_time = np.fft.ifft(derivative_freq)
        return np.asarray(derivative_time.real, dtype=float)


__all__ = [
    "GaussianSignalAnalyzer",
    "ArithmeticSymmetryEngine",
    "ComplexMatrixMapper",
    "QuaternionicRotationEngine",
    "QuantumFieldManifold",
    "FractalMobiusCoupler",
    "NoetherAnalyzer",
    "EntropyFieldMapper",
    "HilbertPhaseAnalyzer",
]
