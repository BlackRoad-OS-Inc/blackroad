"""Amundson coherence, energy, and learning equations.

This module encodes the first entry in the proposed Amundson
series—*Amundson I: The Coherence Gradient Equation*—and
provides scaffolding for the follow-up energy and learning
laws.  The implementation mirrors the conversation blueprint:
phase accelerates with connection and slows with decoherence.

The key constructs follow the original exposition:

* :class:`AmundsonCoherenceModel` captures the differential
  dynamics

  .. math::

     \frac{d\phi}{dt} = \omega_0 + \lambda C(x, y) - \eta E_\phi

  where ``C`` measures cosine coherence and ``E`` denotes the
  decoherence energy penalty.

* :func:`coherence` isolates the cosine alignment term
  :math:`C(x, y)=\cos(\phi_x-\phi_y)`.

* :func:`decoherence_energy` implements the thermal energy
  penalty :math:`E_\phi = k_B T \, \lambda \, r_x r_y (1-\cos(\phi_x-\phi_y))`.

* :func:`phase_derivative` exposes the coherence gradient as a
  reusable utility.

Placeholders for **Amundson II** and **Amundson III** are
included so future work can extend the energy balance and
learning formulations in situ.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Protocol

import numpy as np
from numpy.typing import ArrayLike


def coherence(phi_x: float, phi_y: float) -> float:
    """Return the cosine coherence term :math:`C(x, y)`.

    Parameters
    ----------
    phi_x, phi_y:
        Phases whose alignment is being measured.
    """

    return math.cos(phi_x - phi_y)


def decoherence_energy(
    *,
    phi_x: float,
    phi_y: float,
    r_x: float,
    r_y: float,
    lambda_: float,
    k_b_t: float,
) -> float:
    """Compute the decoherence energy :math:`E_\phi`.

    Parameters mirror the seed formulation: ``r_x`` and ``r_y``
    are participation amplitudes, ``lambda_`` controls coupling,
    and ``k_b_t`` is the thermal scale :math:`k_B T`.
    """

    return k_b_t * lambda_ * r_x * r_y * (1.0 - coherence(phi_x, phi_y))


def phase_derivative(
    *,
    omega_0: float,
    lambda_: float,
    eta: float,
    phi_x: float,
    phi_y: float,
    r_x: float,
    r_y: float,
    k_b_t: float,
) -> float:
    """Evaluate the Amundson I coherence gradient equation.

    This function computes :math:`\frac{d\phi}{dt}` from the
    provided state, matching the proposed dynamic:

    .. math::

       \omega_0 + \lambda\,C(x,y) - \eta\,E_\phi
    """

    c_term = coherence(phi_x, phi_y)
    energy = decoherence_energy(
        phi_x=phi_x,
        phi_y=phi_y,
        r_x=r_x,
        r_y=r_y,
        lambda_=lambda_,
        k_b_t=k_b_t,
    )
    return omega_0 + lambda_ * c_term - eta * energy


class SupportsPhaseUpdate(Protocol):
    """Protocol for objects that can consume phase derivatives."""

    def update_phase(self, d_phi_dt: float) -> None:  # pragma: no cover - protocol signature
        """Apply the derivative to internal state."""


@dataclass(slots=True)
class AmundsonCoherenceModel:
    """Stateful helper implementing Amundson I dynamics."""

    omega_0: float
    lambda_: float
    eta: float
    k_b_t: float

    def dphi_dt(
        self,
        *,
        phi_x: float,
        phi_y: float,
        r_x: float,
        r_y: float,
    ) -> float:
        """Return the instantaneous phase derivative."""

        return phase_derivative(
            omega_0=self.omega_0,
            lambda_=self.lambda_,
            eta=self.eta,
            phi_x=phi_x,
            phi_y=phi_y,
            r_x=r_x,
            r_y=r_y,
            k_b_t=self.k_b_t,
        )

    def evolve(self, system: SupportsPhaseUpdate, **state: float) -> float:
        """Evaluate the derivative and forward it to *system*.

        The method is intentionally lightweight: it returns the
        derivative so callers can both inspect and apply it.
        """

        derivative = self.dphi_dt(**state)
        system.update_phase(derivative)
        return derivative


def amundson_energy_balance(*, energy: float, dissipation: float) -> float:
    """Return the net resonant energy after accounting for dissipation.

    The current Amundson II formulation focuses on conserving the
    available coherence energy while subtracting the irreversible loss
    channel ``dissipation``.  We assume ``dissipation`` is expressed in
    the same units as ``energy`` over the integration horizon.  The
    balance therefore follows the simple conservation law

    .. math::

       E_{t+1} = \max(0, E_t - D_t),

    which clamps the output at zero to avoid non-physical negative
    energies.

    Parameters
    ----------
    energy:
        The current coherence energy :math:`E_t`.
    dissipation:
        The total dissipative loss :math:`D_t` over the step.
    """

    if energy < 0:
        raise ValueError("energy must be non-negative to preserve physical meaning")
    if dissipation < 0:
        raise ValueError("dissipation must be non-negative")

    return max(0.0, energy - dissipation)


def _ensure_vector(name: str, value: ArrayLike) -> np.ndarray:
    """Return *value* as a 1-D float vector."""

    array = np.asarray(value, dtype=float)
    if array.ndim == 0:
        return array.reshape(1)
    if array.ndim != 1:
        raise ValueError(f"{name} must be a 1-D vector, received shape {array.shape}.")
    return array


def _ensure_metric(name: str, value: ArrayLike, dimension: int) -> np.ndarray:
    """Validate that *value* is a symmetric positive-definite matrix."""

    matrix = np.asarray(value, dtype=float)
    if matrix.ndim == 0:
        matrix = matrix.reshape(1, 1)
    if matrix.ndim != 2 or matrix.shape[0] != matrix.shape[1]:
        raise ValueError(f"{name} must be a square matrix, received shape {matrix.shape}.")
    if matrix.shape[0] != dimension:
        raise ValueError(
            f"{name} dimension {matrix.shape[0]} does not match vector length {dimension}."
        )
    if not np.allclose(matrix, matrix.T, atol=1e-10):
        raise ValueError(f"{name} must be symmetric to act as a metric tensor.")
    try:
        np.linalg.cholesky(matrix)
    except np.linalg.LinAlgError as exc:  # pragma: no cover - defensive branch
        raise ValueError(f"{name} must be positive definite.") from exc
    return matrix


def amundson_learning_update(
    *,
    weights: ArrayLike,
    gradient: ArrayLike,
    metric: ArrayLike,
    learning_rate: float,
    k_b_t: float,
    noise: ArrayLike | None = None,
    rng: np.random.Generator | None = None,
) -> np.ndarray:
    r"""Apply the Amundson III Resonant Natural Gradient update.

    The update follows the stochastic natural-gradient rule described
    for the Resonant Natural Gradient option:

    .. math::

       \theta_{t+1} = \theta_t - \eta G^{-1} \nabla_\theta \mathcal F
       + \sqrt{2\eta k_B T}\, G^{-1/2} \xi,

    where ``weights`` is :math:`\theta_t`, ``gradient`` is the free-energy
    gradient, ``metric`` is the Fisher (or Gauss–Newton) metric
    :math:`G`, and ``noise`` supplies the standard-normal samples
    :math:`\xi`.  Setting ``k_b_t`` to zero removes the stochastic term
    and recovers standard gradient descent when the metric is the
    identity.
    """

    weight_vec = _ensure_vector("weights", weights)
    grad_vec = _ensure_vector("gradient", gradient)
    if weight_vec.shape != grad_vec.shape:
        raise ValueError(
            "weights and gradient must share the same shape, "
            f"received {weight_vec.shape} and {grad_vec.shape}."
        )

    metric_tensor = _ensure_metric("metric", metric, weight_vec.size)
    chol = np.linalg.cholesky(metric_tensor)

    natural_grad = np.linalg.solve(metric_tensor, grad_vec)
    deterministic_step = -learning_rate * natural_grad

    scale = math.sqrt(max(0.0, 2.0 * learning_rate * k_b_t))
    if noise is None:
        if scale == 0.0:
            stochastic_step = np.zeros_like(weight_vec)
        else:
            generator = rng if rng is not None else np.random.default_rng()
            xi = generator.standard_normal(size=weight_vec.shape)
            stochastic_step = scale * np.linalg.solve(chol.T, xi)
    else:
        xi = _ensure_vector("noise", noise)
        if xi.shape != weight_vec.shape:
            raise ValueError(
                "noise must match the dimensionality of the weights, "
                f"received {xi.shape} and {weight_vec.shape}."
            )
        if scale == 0.0:
            stochastic_step = np.zeros_like(weight_vec)
        else:
            stochastic_step = scale * np.linalg.solve(chol.T, xi)

    return weight_vec + deterministic_step + stochastic_step
