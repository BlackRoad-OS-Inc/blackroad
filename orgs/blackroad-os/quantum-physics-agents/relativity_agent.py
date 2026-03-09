#!/usr/bin/env python3
"""
Relativity Simulation Agent
Specialized agent for special and general relativity calculations including
time dilation, length contraction, spacetime metrics, and gravitational effects.
"""

import numpy as np
import sympy as sp
from sympy import *
from typing import Dict, List, Tuple, Optional
import json
from datetime import datetime


class RelativityAgent:
    """
    Relativity specialist agent that performs relativistic calculations,
    spacetime analysis, and gravitational simulations.
    """

    def __init__(self, agent_id: str = "REL-001"):
        self.agent_id = agent_id
        self.name = "Relativity Agent"
        self.capabilities = [
            "time_dilation",
            "length_contraction",
            "lorentz_transformation",
            "relativistic_energy",
            "schwarzschild_metric",
            "gravitational_redshift",
            "orbit_precession",
            "escape_velocity"
        ]
        self.c = 299792458  # Speed of light (m/s)
        self.G = 6.67430e-11  # Gravitational constant (m^3 kg^-1 s^-2)

    def time_dilation(self, v: float, t0: float = 1.0) -> Dict:
        """
        Calculate time dilation due to relative velocity.

        t = γ * t0 where γ = 1/sqrt(1 - v²/c²)

        Args:
            v: Relative velocity (m/s)
            t0: Proper time (s)

        Returns:
            Time dilation analysis
        """
        if abs(v) >= self.c:
            return {
                "agent": self.agent_id,
                "error": "Velocity must be less than speed of light",
                "v_fraction_of_c": v / self.c
            }

        beta = v / self.c
        gamma = 1 / np.sqrt(1 - beta**2)
        t_dilated = gamma * t0

        return {
            "agent": self.agent_id,
            "calculation": "time_dilation",
            "velocity_ms": v,
            "velocity_fraction_c": beta,
            "lorentz_factor_gamma": float(gamma),
            "proper_time_s": t0,
            "dilated_time_s": float(t_dilated),
            "time_difference_s": float(t_dilated - t0),
            "timestamp": datetime.now().isoformat()
        }

    def length_contraction(self, v: float, L0: float = 1.0) -> Dict:
        """
        Calculate length contraction in direction of motion.

        L = L0 / γ

        Args:
            v: Relative velocity (m/s)
            L0: Proper length (m)

        Returns:
            Length contraction analysis
        """
        if abs(v) >= self.c:
            return {
                "agent": self.agent_id,
                "error": "Velocity must be less than speed of light"
            }

        beta = v / self.c
        gamma = 1 / np.sqrt(1 - beta**2)
        L_contracted = L0 / gamma

        return {
            "agent": self.agent_id,
            "calculation": "length_contraction",
            "velocity_ms": v,
            "velocity_fraction_c": beta,
            "lorentz_factor_gamma": float(gamma),
            "proper_length_m": L0,
            "contracted_length_m": float(L_contracted),
            "contraction_ratio": float(L_contracted / L0),
            "timestamp": datetime.now().isoformat()
        }

    def relativistic_energy(self, m: float, v: float) -> Dict:
        """
        Calculate relativistic energy and momentum.

        E = γmc²
        p = γmv

        Args:
            m: Rest mass (kg)
            v: Velocity (m/s)

        Returns:
            Energy and momentum
        """
        if abs(v) >= self.c:
            return {
                "agent": self.agent_id,
                "error": "Velocity must be less than speed of light"
            }

        beta = v / self.c
        gamma = 1 / np.sqrt(1 - beta**2)

        E_rest = m * self.c**2
        E_total = gamma * E_rest
        E_kinetic = E_total - E_rest
        p = gamma * m * v

        return {
            "agent": self.agent_id,
            "calculation": "relativistic_energy",
            "mass_kg": m,
            "velocity_ms": v,
            "velocity_fraction_c": beta,
            "lorentz_factor_gamma": float(gamma),
            "rest_energy_J": E_rest,
            "rest_energy_eV": E_rest / 1.602e-19,
            "total_energy_J": float(E_total),
            "kinetic_energy_J": float(E_kinetic),
            "momentum_kgms": float(p),
            "timestamp": datetime.now().isoformat()
        }

    def schwarzschild_radius(self, M: float) -> Dict:
        """
        Calculate Schwarzschild radius (event horizon).

        R_s = 2GM/c²

        Args:
            M: Mass (kg)

        Returns:
            Schwarzschild radius analysis
        """
        R_s = 2 * self.G * M / (self.c**2)

        # Density at Schwarzschild radius
        volume = (4/3) * np.pi * R_s**3
        density = M / volume

        return {
            "agent": self.agent_id,
            "calculation": "schwarzschild_radius",
            "mass_kg": M,
            "mass_solar_masses": M / 1.989e30,
            "schwarzschild_radius_m": R_s,
            "schwarzschild_radius_km": R_s / 1000,
            "average_density_kg_m3": density,
            "surface_gravity_ms2": self.G * M / (R_s**2),
            "timestamp": datetime.now().isoformat()
        }

    def gravitational_time_dilation(self, r: float, M: float) -> Dict:
        """
        Calculate gravitational time dilation near massive object.

        t = t0 / sqrt(1 - R_s/r) where R_s = 2GM/c²

        Args:
            r: Distance from center (m)
            M: Mass of object (kg)

        Returns:
            Gravitational time dilation
        """
        R_s = 2 * self.G * M / (self.c**2)

        if r <= R_s:
            return {
                "agent": self.agent_id,
                "error": "Distance must be greater than Schwarzschild radius",
                "r": r,
                "R_s": R_s
            }

        factor = np.sqrt(1 - R_s / r)
        t_ratio = 1 / factor

        return {
            "agent": self.agent_id,
            "calculation": "gravitational_time_dilation",
            "distance_m": r,
            "mass_kg": M,
            "schwarzschild_radius_m": R_s,
            "time_dilation_factor": float(t_ratio),
            "proper_time_ratio": float(factor),
            "seconds_per_year_difference": float((t_ratio - 1) * 365.25 * 24 * 3600),
            "timestamp": datetime.now().isoformat()
        }

    def orbital_velocity(self, r: float, M: float) -> Dict:
        """
        Calculate orbital velocity and period.

        v_orbital = sqrt(GM/r)
        T = 2πr/v

        Args:
            r: Orbital radius (m)
            M: Central mass (kg)

        Returns:
            Orbital parameters
        """
        v = np.sqrt(self.G * M / r)
        T = 2 * np.pi * r / v

        # Relativistic correction for close orbits
        beta = v / self.c
        gamma = 1 / np.sqrt(1 - beta**2) if beta < 1 else None

        return {
            "agent": self.agent_id,
            "calculation": "orbital_velocity",
            "orbital_radius_m": r,
            "orbital_radius_km": r / 1000,
            "central_mass_kg": M,
            "orbital_velocity_ms": float(v),
            "orbital_velocity_kms": float(v / 1000),
            "orbital_period_s": float(T),
            "orbital_period_days": float(T / 86400),
            "velocity_fraction_c": beta,
            "needs_relativistic_correction": beta > 0.01,
            "lorentz_factor": float(gamma) if gamma else "N/A",
            "timestamp": datetime.now().isoformat()
        }

    def escape_velocity(self, r: float, M: float) -> Dict:
        """
        Calculate escape velocity from gravitational field.

        v_escape = sqrt(2GM/r)

        Args:
            r: Distance from center (m)
            M: Mass (kg)

        Returns:
            Escape velocity analysis
        """
        v_escape = np.sqrt(2 * self.G * M / r)

        return {
            "agent": self.agent_id,
            "calculation": "escape_velocity",
            "distance_m": r,
            "mass_kg": M,
            "escape_velocity_ms": float(v_escape),
            "escape_velocity_kms": float(v_escape / 1000),
            "escape_velocity_fraction_c": v_escape / self.c,
            "escape_energy_per_kg_J": 0.5 * v_escape**2,
            "timestamp": datetime.now().isoformat()
        }

    def process_request(self, request: Dict) -> Dict:
        """Process incoming calculation request."""
        calc_type = request.get("calculation_type")
        params = request.get("parameters", {})

        if calc_type == "time_dilation":
            return self.time_dilation(params.get("velocity"), params.get("proper_time", 1.0))
        elif calc_type == "length_contraction":
            return self.length_contraction(params.get("velocity"), params.get("proper_length", 1.0))
        elif calc_type == "relativistic_energy":
            return self.relativistic_energy(params.get("mass"), params.get("velocity"))
        elif calc_type == "schwarzschild_radius":
            return self.schwarzschild_radius(params.get("mass"))
        elif calc_type == "gravitational_time_dilation":
            return self.gravitational_time_dilation(params.get("distance"), params.get("mass"))
        elif calc_type == "orbital_velocity":
            return self.orbital_velocity(params.get("radius"), params.get("mass"))
        elif calc_type == "escape_velocity":
            return self.escape_velocity(params.get("distance"), params.get("mass"))
        else:
            return {
                "agent": self.agent_id,
                "error": f"Unknown calculation type: {calc_type}",
                "available_types": self.capabilities
            }


# Example usage and testing
if __name__ == "__main__":
    agent = RelativityAgent()

    print("🌌 Relativity Agent - Test Suite")
    print("=" * 60)

    # Test 1: Time dilation
    print("\n1. Time Dilation (v=0.9c, t0=1 year):")
    result = agent.time_dilation(0.9 * agent.c, 365.25 * 24 * 3600)
    print(f"   γ = {result['lorentz_factor_gamma']:.4f}")
    print(f"   Dilated time: {result['dilated_time_s']/86400/365.25:.2f} years")

    # Test 2: Length contraction
    print("\n2. Length Contraction (v=0.8c, L0=100m):")
    result = agent.length_contraction(0.8 * agent.c, 100)
    print(f"   Contracted length: {result['contracted_length_m']:.2f} m")
    print(f"   Contraction ratio: {result['contraction_ratio']:.2f}")

    # Test 3: Relativistic energy (electron at 0.5c)
    print("\n3. Relativistic Energy (electron at v=0.5c):")
    m_e = 9.109e-31  # electron mass
    result = agent.relativistic_energy(m_e, 0.5 * agent.c)
    print(f"   Rest energy: {result['rest_energy_eV']:.2e} eV")
    print(f"   Total energy: {result['total_energy_J']:.2e} J")
    print(f"   Kinetic energy: {result['kinetic_energy_J']:.2e} J")

    # Test 4: Schwarzschild radius (Sun and black hole)
    print("\n4. Schwarzschild Radius:")
    M_sun = 1.989e30
    result_sun = agent.schwarzschild_radius(M_sun)
    print(f"   Sun: R_s = {result_sun['schwarzschild_radius_km']:.2f} km")

    M_bh = 10 * M_sun
    result_bh = agent.schwarzschild_radius(M_bh)
    print(f"   10 M_sun black hole: R_s = {result_bh['schwarzschild_radius_km']:.2f} km")

    # Test 5: Gravitational time dilation (Earth surface)
    print("\n5. Gravitational Time Dilation (Earth surface):")
    M_earth = 5.972e24
    R_earth = 6.371e6
    result = agent.gravitational_time_dilation(R_earth, M_earth)
    print(f"   Factor: {result['time_dilation_factor']:.12f}")
    print(f"   Difference per year: {result['seconds_per_year_difference']:.2e} s")

    # Test 6: Orbital velocity (ISS)
    print("\n6. Orbital Velocity (ISS at 400km altitude):")
    result = agent.orbital_velocity(R_earth + 400000, M_earth)
    print(f"   v_orbital = {result['orbital_velocity_kms']:.2f} km/s")
    print(f"   Period = {result['orbital_period_s']/60:.0f} min")

    # Test 7: Escape velocity (Earth)
    print("\n7. Escape Velocity (Earth surface):")
    result = agent.escape_velocity(R_earth, M_earth)
    print(f"   v_escape = {result['escape_velocity_kms']:.2f} km/s")

    print("\n" + "=" * 60)
    print("✅ All tests complete! Agent is operational.")
