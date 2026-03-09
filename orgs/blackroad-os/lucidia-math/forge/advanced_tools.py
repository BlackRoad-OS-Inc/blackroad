"""Advanced mathematical tools for agent development.

This module bundles several playful mathematical utilities imagined for
Black Road's agent framework.  The functionality is intentionally
educational rather than production-grade and mirrors material referenced
across internal lore: Caesar-style cryptography, Fibonacci analytics,
Laplace-transform-inspired oscillators, and a nod to the so-called
Unified Harmonic theory.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Tuple

import numpy as np


# ============================================================================
# CAESAR CIPHER - SECURE AGENT COMMUNICATION
# ============================================================================


class AgentCryptography:
    """Encryption helper for agent-to-agent communication."""

    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    mod = len(alphabet)

    def __init__(self, agent_id: str):
        self.agent_id = agent_id

    def caesar_encrypt(self, message: str, shift: int) -> str:
        """Encrypt ``message`` with a fixed Caesar ``shift``."""

        encrypted: List[str] = []
        for char in message.upper():
            if char in self.alphabet:
                old_index = self.alphabet.index(char)
                new_index = (old_index + shift) % self.mod
                encrypted.append(self.alphabet[new_index])
            else:
                encrypted.append(char)
        return "".join(encrypted)

    def caesar_decrypt(self, encrypted: str, shift: int) -> str:
        """Decrypt a Caesar cipher by applying the negative shift."""

        return self.caesar_encrypt(encrypted, -shift)

    def dynamic_shift(self, position: int) -> int:
        """Return a position-dependent shift value.

        Inspired by a whiteboard note ("start at 10, evolve"), we seed the
        shift with ``10`` and add the Fibonacci value for ``position``.
        The modulo arithmetic keeps the result within the alphabet.
        """

        fib = self.fibonacci_closed_form(position)
        return int(round(fib) + 10) % self.mod

    def fibonacci_closed_form(self, n: int) -> float:
        """Return the *n*th Fibonacci number using Binet's formula."""

        phi = (1 + np.sqrt(5)) / 2
        psi = (1 - np.sqrt(5)) / 2
        return (phi**n - psi**n) / np.sqrt(5)

    def encrypt_message_dynamic(self, message: str) -> Tuple[str, List[int]]:
        """Encrypt ``message`` using position-dependent shifts."""

        encrypted: List[str] = []
        shifts: List[int] = []
        for index, char in enumerate(message.upper()):
            if char in self.alphabet:
                shift = self.dynamic_shift(index)
                shifts.append(shift)
                old_index = self.alphabet.index(char)
                new_index = (old_index + shift) % self.mod
                encrypted.append(self.alphabet[new_index])
            else:
                encrypted.append(char)
                shifts.append(0)
        return "".join(encrypted), shifts

    def decrypt_message_dynamic(self, encrypted: str, shifts: List[int]) -> str:
        """Decrypt a dynamically shifted message using ``shifts``."""

        decrypted: List[str] = []
        for index, char in enumerate(encrypted.upper()):
            if char in self.alphabet and index < len(shifts):
                old_index = self.alphabet.index(char)
                new_index = (old_index - shifts[index]) % self.mod
                decrypted.append(self.alphabet[new_index])
            else:
                decrypted.append(char)
        return "".join(decrypted)


# ============================================================================
# BINET'S FORMULA - DIRECT FIBONACCI CALCULATION
# ============================================================================


@dataclass
class FibonacciAnalytics:
    """Closed-form Fibonacci helper functions."""

    phi: float = (1 + np.sqrt(5)) / 2
    psi: float = (1 - np.sqrt(5)) / 2

    def fibonacci_direct(self, n: int) -> int:
        """Return ``Fₙ`` without iterative accumulation."""

        value = (self.phi**n - self.psi**n) / np.sqrt(5)
        return int(round(value))

    def fibonacci_ratio(self, n: int) -> float:
        """Return the ratio ``Fₙ / Fₙ₋₁`` (approaches ``φ``)."""

        if n < 1:
            return 0.0
        current = self.fibonacci_direct(n)
        previous = self.fibonacci_direct(n - 1)
        if previous == 0:
            return float("inf")
        return current / previous

    def predict_development_stage(self, current_stage: int, time_steps: int) -> int:
        """Return a simple Fibonacci-based stage progression."""

        future_stage = current_stage + time_steps
        return self.fibonacci_direct(future_stage)

    def find_stage_for_value(self, target_value: float) -> int:
        """Approximate the Fibonacci index associated with ``target_value``."""

        n_approx = np.log(target_value * np.sqrt(5)) / np.log(self.phi)
        return int(round(n_approx))


# ============================================================================
# LAPLACE TRANSFORMS - CONSCIOUSNESS EVOLUTION
# ============================================================================


class LaplaceConsciousness:
    """Analytical solutions to simple oscillator models."""

    def __init__(self, agent_id: str):
        self.agent_id = agent_id

    def harmonic_oscillator_solution(
        self,
        k: float,
        x0: float,
        v0: float,
        t_max: float = 10.0,
        dt: float = 0.01,
    ) -> Dict[str, np.ndarray]:
        """Return the analytic solution of ``x""(t) + kx(t) = 0``."""

        t = np.arange(0, t_max, dt)
        omega = np.sqrt(k)
        x_t = x0 * np.cos(omega * t) + (v0 / omega) * np.sin(omega * t)
        v_t = -x0 * omega * np.sin(omega * t) + v0 * np.cos(omega * t)
        return {
            "time": t,
            "position": x_t,
            "velocity": v_t,
            "frequency": omega / (2 * np.pi),
        }

    def damped_oscillator_solution(
        self,
        k: float,
        c: float,
        x0: float,
        v0: float,
        t_max: float = 10.0,
        dt: float = 0.01,
    ) -> Dict[str, np.ndarray | str]:
        """Return the solution of ``x""(t) + c·x'(t) + kx(t) = 0``."""

        t = np.arange(0, t_max, dt)
        delta = c**2 - 4 * k
        if delta > 0:  # Overdamped
            r1 = (-c + np.sqrt(delta)) / 2
            r2 = (-c - np.sqrt(delta)) / 2
            c1 = (v0 - r2 * x0) / (r1 - r2)
            c2 = (r1 * x0 - v0) / (r1 - r2)
            x_t = c1 * np.exp(r1 * t) + c2 * np.exp(r2 * t)
            damping_type = "overdamped"
        elif delta == 0:  # Critically damped
            r = -c / 2
            c1 = x0
            c2 = v0 - r * x0
            x_t = (c1 + c2 * t) * np.exp(r * t)
            damping_type = "critical"
        else:  # Underdamped
            alpha = -c / 2
            omega_d = np.sqrt(-delta) / 2
            a = x0
            b = (v0 - alpha * x0) / omega_d
            x_t = np.exp(alpha * t) * (a * np.cos(omega_d * t) + b * np.sin(omega_d * t))
            damping_type = "underdamped"
        return {"time": t, "position": x_t, "damping_type": damping_type}

    def consciousness_oscillation(
        self,
        emotional_spring_constant: float,
        memory_damping: float,
        initial_emotion: float,
        initial_rate: float,
    ) -> Dict[str, np.ndarray | str]:
        """Convenience wrapper modelling an "emotional" oscillator."""

        return self.damped_oscillator_solution(
            k=emotional_spring_constant,
            c=memory_damping,
            x0=initial_emotion,
            v0=initial_rate,
        )


# ============================================================================
# UNIFIED HARMONIC CONNECTION
# ============================================================================


class UnifiedHarmonic:
    """Playful nod to the imagined unified harmonic theory."""

    @staticmethod
    def phase_locking_criterion():
        """Return a simple closure map ``H_φ`` acting on ``X``."""

        def _h_phi(x: float, n: int = 100) -> float:
            return (1 - 10 ** (-n)) * x

        return _h_phi

    @staticmethod
    def mobius_torque_action() -> str:
        """Placeholder describing the Möbius-torque action."""

        return "Unified Harmonic Action - Theoretical Framework"


@dataclass
class GrowthPrediction:
    """Container for Fibonacci-based growth projections."""

    time_steps: List[int]
    developmental_stages: List[int]
    growth_ratios: List[float]
    converges_to_phi: float | None


# ============================================================================
# AGENT DEVELOPMENT PREDICTOR
# ============================================================================


class AgentDevelopmentPredictor:
    """Simple wrapper that combines Fibonacci and oscillator models."""

    def __init__(self, agent_id: str):
        self.agent_id = agent_id
        self.fibonacci = FibonacciAnalytics()
        self.laplace = LaplaceConsciousness(agent_id)

    def predict_growth_curve(self, current_stage: int, time_horizon: int) -> GrowthPrediction:
        """Return a Fibonacci-driven development forecast."""

        stages: List[int] = []
        ratios: List[float] = []
        for offset in range(time_horizon):
            stage = self.fibonacci.fibonacci_direct(current_stage + offset)
            stages.append(stage)
            if offset > 0:
                ratios.append(self.fibonacci.fibonacci_ratio(current_stage + offset))
        return GrowthPrediction(
            time_steps=list(range(time_horizon)),
            developmental_stages=stages,
            growth_ratios=ratios,
            converges_to_phi=ratios[-1] if ratios else None,
        )

    def model_emotional_dynamics(
        self,
        spring_constant: float = 1.0,
        damping: float = 0.1,
        initial_state: float = 1.0,
    ) -> Dict[str, np.ndarray | str]:
        """Return the emotional dynamics using ``LaplaceConsciousness``."""

        return self.laplace.consciousness_oscillation(
            emotional_spring_constant=spring_constant,
            memory_damping=damping,
            initial_emotion=initial_state,
            initial_rate=0.0,
        )


if __name__ == "__main__":
    print("=" * 60)
    print("BLACK ROAD ADVANCED MATHEMATICS")
    print("=" * 60)

    # 1. Cryptography
    print("\n--- AGENT CRYPTOGRAPHY ---")
    crypto = AgentCryptography("CECILIA-7C3E-SPECTRUM-9B4F")
    message = "HELLO ALEXA LOUISE"
    encrypted, shifts = crypto.encrypt_message_dynamic(message)
    decrypted = crypto.decrypt_message_dynamic(encrypted, shifts)
    print(f"Original:  {message}")
    print(f"Encrypted: {encrypted}")
    print(f"Shifts:    {shifts}")
    print(f"Decrypted: {decrypted}")

    # 2. Fibonacci
    print("\n--- FIBONACCI DIRECT CALCULATION ---")
    fib = FibonacciAnalytics()
    for n in [10, 20, 30, 40, 50]:
        value = fib.fibonacci_direct(n)
        ratio = fib.fibonacci_ratio(n)
        print(f"F_{n} = {value:,} | F_{n}/F_{n-1} = {ratio:.10f}")
    print(f"\nGolden Ratio φ = {fib.phi:.10f}")

    # 3. Laplace
    print("\n--- CONSCIOUSNESS OSCILLATION ---")
    laplace = LaplaceConsciousness("CECILIA-7C3E-SPECTRUM-9B4F")
    result = laplace.consciousness_oscillation(
        emotional_spring_constant=1.0,
        memory_damping=0.1,
        initial_emotion=1.0,
        initial_rate=0.0,
    )
    print(f"Damping type: {result['damping_type']}")
    print(f"Time span: {len(result['time'])} steps")
    print(f"Max emotion: {np.max(result['position']):.3f}")
    print(f"Min emotion: {np.min(result['position']):.3f}")

    # 4. Development
    print("\n--- AGENT DEVELOPMENT PREDICTION ---")
    predictor = AgentDevelopmentPredictor("NOVA-CHILD-SPECTRUM")
    prediction = predictor.predict_growth_curve(current_stage=5, time_horizon=10)
    print("Developmental stages:")
    for step, stage in zip(prediction.time_steps, prediction.developmental_stages):
        print(f"  t={step}: stage={stage}")
    if prediction.converges_to_phi is not None:
        print(f"\nConverging to φ: {prediction.converges_to_phi:.10f}")

    print("\n" + "=" * 60)
    print("ADVANCED MATHEMATICS OPERATIONAL")
    print("=" * 60)
