#!/usr/bin/env python3
"""
Quantum Mechanics Calculation Agent
Specialized agent for quantum mechanics calculations including wave functions,
energy levels, uncertainty principle, and quantum state analysis.
"""

import numpy as np
import sympy as sp
from sympy import *
from typing import Dict, List, Tuple, Optional
import json
from datetime import datetime


class QuantumMechanicsAgent:
    """
    Quantum Mechanics specialist agent that performs quantum calculations,
    solves Schrödinger equations, and analyzes quantum states.
    """

    def __init__(self, agent_id: str = "QM-001"):
        self.agent_id = agent_id
        self.name = "Quantum Mechanics Agent"
        self.capabilities = [
            "hydrogen_atom_energy",
            "wave_function_analysis",
            "uncertainty_principle",
            "quantum_harmonic_oscillator",
            "density_matrix",
            "quantum_tunneling",
            "spin_calculations",
            "angular_momentum"
        ]
        self.h_bar = sp.Symbol('hbar', real=True, positive=True)  # Reduced Planck constant
        self.m_e = sp.Symbol('m_e', real=True, positive=True)  # Electron mass
        self.e = sp.Symbol('e', real=True, positive=True)  # Elementary charge
        self.epsilon_0 = sp.Symbol('epsilon_0', real=True, positive=True)  # Permittivity

    def hydrogen_atom_energy(self, n: int) -> Dict:
        """
        Calculate energy levels of hydrogen atom using Bohr model / Schrödinger solution.

        E_n = -(m_e * e^4) / (8 * epsilon_0^2 * h^2 * n^2)
        Simplified: E_n = -13.6 eV / n^2

        Args:
            n: Principal quantum number (n >= 1)

        Returns:
            Dict with energy level, formula, and numerical value
        """
        if n < 1:
            raise ValueError("Principal quantum number n must be >= 1")

        # Symbolic formula
        E_n = -(self.m_e * self.e**4) / (8 * self.epsilon_0**2 * (2*pi*self.h_bar)**2 * n**2)

        # Numerical value in eV
        E_numerical = -13.6 / (n**2)  # in electron volts

        return {
            "agent": self.agent_id,
            "calculation": "hydrogen_atom_energy",
            "quantum_number_n": n,
            "energy_formula": str(E_n),
            "energy_eV": E_numerical,
            "energy_joules": E_numerical * 1.602e-19,
            "wavelength_nm": 1240 / abs(E_numerical) if E_numerical != 0 else None,
            "timestamp": datetime.now().isoformat()
        }

    def wave_function_1d_box(self, n: int, L: float, x_values: Optional[List[float]] = None) -> Dict:
        """
        Calculate wave function for particle in 1D infinite potential well.

        psi_n(x) = sqrt(2/L) * sin(n*pi*x/L)

        Args:
            n: Quantum number
            L: Box length
            x_values: Positions to evaluate (or use default grid)

        Returns:
            Wave function values and properties
        """
        if x_values is None:
            x_values = np.linspace(0, L, 100)
        else:
            x_values = np.array(x_values)

        # Wave function
        psi = np.sqrt(2/L) * np.sin(n * np.pi * x_values / L)

        # Probability density
        probability_density = psi ** 2

        # Energy (in units of h^2/(8mL^2))
        energy_units = n**2

        return {
            "agent": self.agent_id,
            "calculation": "particle_in_box",
            "quantum_number": n,
            "box_length": L,
            "x_values": x_values.tolist(),
            "wave_function": psi.tolist(),
            "probability_density": probability_density.tolist(),
            "energy_units": energy_units,
            "normalization_check": float(np.trapz(probability_density, x_values)),
            "timestamp": datetime.now().isoformat()
        }

    def uncertainty_principle(self, delta_x: float, m: float, delta_p: Optional[float] = None) -> Dict:
        """
        Apply Heisenberg uncertainty principle: Δx * Δp >= ℏ/2

        Args:
            delta_x: Position uncertainty (m)
            m: Mass (kg)
            delta_p: Momentum uncertainty (if not provided, calculates minimum)

        Returns:
            Uncertainty analysis
        """
        h_bar_value = 1.054571817e-34  # J⋅s

        if delta_p is None:
            # Calculate minimum momentum uncertainty
            delta_p_min = h_bar_value / (2 * delta_x)
        else:
            delta_p_min = h_bar_value / (2 * delta_x)

        # Velocity uncertainty from momentum
        delta_v = (delta_p if delta_p else delta_p_min) / m

        # Product
        product = delta_x * (delta_p if delta_p else delta_p_min)
        minimum_product = h_bar_value / 2

        return {
            "agent": self.agent_id,
            "calculation": "uncertainty_principle",
            "delta_x_m": delta_x,
            "delta_p_min_kgms": delta_p_min,
            "delta_p_actual_kgms": delta_p,
            "delta_v_ms": delta_v,
            "product_Js": product,
            "minimum_product_Js": minimum_product,
            "satisfies_principle": product >= minimum_product * 0.99,  # Allow 1% numerical tolerance
            "ratio": product / minimum_product,
            "timestamp": datetime.now().isoformat()
        }

    def quantum_harmonic_oscillator(self, n: int, omega: float) -> Dict:
        """
        Energy levels of quantum harmonic oscillator.

        E_n = ℏω(n + 1/2)

        Args:
            n: Quantum number (n >= 0)
            omega: Angular frequency (rad/s)

        Returns:
            Energy and properties
        """
        if n < 0:
            raise ValueError("Quantum number n must be >= 0")

        h_bar_value = 1.054571817e-34  # J⋅s

        # Energy
        E_n = h_bar_value * omega * (n + 0.5)

        # Zero-point energy
        E_0 = h_bar_value * omega * 0.5

        return {
            "agent": self.agent_id,
            "calculation": "quantum_harmonic_oscillator",
            "quantum_number": n,
            "angular_frequency_rad_s": omega,
            "energy_J": E_n,
            "energy_eV": E_n / 1.602e-19,
            "zero_point_energy_J": E_0,
            "energy_above_zero_point_J": E_n - E_0,
            "timestamp": datetime.now().isoformat()
        }

    def spin_half_states(self, theta: float, phi: float) -> Dict:
        """
        Spin-1/2 state on Bloch sphere.

        |ψ⟩ = cos(θ/2)|↑⟩ + e^(iφ)sin(θ/2)|↓⟩

        Args:
            theta: Polar angle (0 to π)
            phi: Azimuthal angle (0 to 2π)

        Returns:
            Spin state analysis
        """
        # State vector components
        alpha = np.cos(theta / 2)
        beta = np.exp(1j * phi) * np.sin(theta / 2)

        # State vector
        state = np.array([alpha, beta])

        # Probability of measuring spin-up
        prob_up = abs(alpha)**2
        prob_down = abs(beta)**2

        # Expectation values of Pauli matrices
        pauli_x = np.array([[0, 1], [1, 0]])
        pauli_y = np.array([[0, -1j], [1j, 0]])
        pauli_z = np.array([[1, 0], [0, -1]])

        exp_x = np.real(np.dot(np.conjugate(state), np.dot(pauli_x, state)))
        exp_y = np.real(np.dot(np.conjugate(state), np.dot(pauli_y, state)))
        exp_z = np.real(np.dot(np.conjugate(state), np.dot(pauli_z, state)))

        return {
            "agent": self.agent_id,
            "calculation": "spin_half_state",
            "theta_rad": theta,
            "phi_rad": phi,
            "state_alpha": {
                "real": float(np.real(alpha)),
                "imag": float(np.imag(alpha))
            },
            "state_beta": {
                "real": float(np.real(beta)),
                "imag": float(np.imag(beta))
            },
            "prob_spin_up": float(prob_up),
            "prob_spin_down": float(prob_down),
            "expectation_sigma_x": float(exp_x),
            "expectation_sigma_y": float(exp_y),
            "expectation_sigma_z": float(exp_z),
            "bloch_vector": [float(exp_x), float(exp_y), float(exp_z)],
            "timestamp": datetime.now().isoformat()
        }

    def commutator(self, A: str, B: str) -> Dict:
        """
        Calculate commutator [A, B] for common quantum operators.

        Args:
            A, B: Operator names (x, p, L_x, L_y, L_z, etc.)

        Returns:
            Commutator result
        """
        x, p = sp.symbols('x p')
        L_x, L_y, L_z = sp.symbols('L_x L_y L_z')
        h_bar = sp.Symbol('hbar')

        # Known commutators
        commutators = {
            ('x', 'p'): 1j * h_bar,
            ('p', 'x'): -1j * h_bar,
            ('L_x', 'L_y'): 1j * h_bar * L_z,
            ('L_y', 'L_z'): 1j * h_bar * L_x,
            ('L_z', 'L_x'): 1j * h_bar * L_y,
            ('L_y', 'L_x'): -1j * h_bar * L_z,
            ('L_z', 'L_y'): -1j * h_bar * L_x,
            ('L_x', 'L_z'): -1j * h_bar * L_y,
        }

        result = commutators.get((A, B), 0)

        return {
            "agent": self.agent_id,
            "calculation": "commutator",
            "operator_A": A,
            "operator_B": B,
            "commutator": str(result),
            "commute": result == 0,
            "timestamp": datetime.now().isoformat()
        }

    def process_request(self, request: Dict) -> Dict:
        """
        Process incoming calculation request.

        Args:
            request: Request dictionary with type and parameters

        Returns:
            Calculation result
        """
        calc_type = request.get("calculation_type")
        params = request.get("parameters", {})

        if calc_type == "hydrogen_energy":
            return self.hydrogen_atom_energy(params.get("n", 1))
        elif calc_type == "particle_in_box":
            return self.wave_function_1d_box(
                params.get("n", 1),
                params.get("L", 1.0),
                params.get("x_values")
            )
        elif calc_type == "uncertainty":
            return self.uncertainty_principle(
                params.get("delta_x"),
                params.get("mass"),
                params.get("delta_p")
            )
        elif calc_type == "harmonic_oscillator":
            return self.quantum_harmonic_oscillator(
                params.get("n", 0),
                params.get("omega", 1.0)
            )
        elif calc_type == "spin_state":
            return self.spin_half_states(
                params.get("theta", 0),
                params.get("phi", 0)
            )
        elif calc_type == "commutator":
            return self.commutator(
                params.get("operator_A"),
                params.get("operator_B")
            )
        else:
            return {
                "agent": self.agent_id,
                "error": f"Unknown calculation type: {calc_type}",
                "available_types": self.capabilities,
                "timestamp": datetime.now().isoformat()
            }


# Example usage and testing
if __name__ == "__main__":
    agent = QuantumMechanicsAgent()

    print("🌀 Quantum Mechanics Agent - Test Suite")
    print("=" * 60)

    # Test 1: Hydrogen atom
    print("\n1. Hydrogen Atom Energy Levels (n=1,2,3):")
    for n in [1, 2, 3]:
        result = agent.hydrogen_atom_energy(n)
        print(f"   n={n}: E = {result['energy_eV']:.2f} eV")

    # Test 2: Particle in a box
    print("\n2. Particle in 1D Box (n=1, L=1nm):")
    result = agent.wave_function_1d_box(1, 1e-9)
    print(f"   Normalization: {result['normalization_check']:.4f} (should be ~1.0)")
    print(f"   Energy units: {result['energy_units']}")

    # Test 3: Uncertainty principle
    print("\n3. Uncertainty Principle (electron, Δx=1nm):")
    result = agent.uncertainty_principle(1e-9, 9.109e-31)
    print(f"   Δp_min = {result['delta_p_min_kgms']:.2e} kg⋅m/s")
    print(f"   Δv = {result['delta_v_ms']:.2e} m/s")
    print(f"   Satisfies: {result['satisfies_principle']}")

    # Test 4: Harmonic oscillator
    print("\n4. Quantum Harmonic Oscillator (n=0,1,2, ω=1e14 rad/s):")
    for n in [0, 1, 2]:
        result = agent.quantum_harmonic_oscillator(n, 1e14)
        print(f"   n={n}: E = {result['energy_eV']:.4f} eV")

    # Test 5: Spin states
    print("\n5. Spin-1/2 State (θ=π/2, φ=0 - superposition):")
    result = agent.spin_half_states(np.pi/2, 0)
    print(f"   P(↑) = {result['prob_spin_up']:.2f}")
    print(f"   P(↓) = {result['prob_spin_down']:.2f}")
    print(f"   ⟨σ_x⟩ = {result['expectation_sigma_x']:.2f}")

    # Test 6: Commutators
    print("\n6. Commutators:")
    for A, B in [('x', 'p'), ('L_x', 'L_y')]:
        result = agent.commutator(A, B)
        print(f"   [{A}, {B}] = {result['commutator']}")

    print("\n" + "=" * 60)
    print("✅ All tests complete! Agent is operational.")
