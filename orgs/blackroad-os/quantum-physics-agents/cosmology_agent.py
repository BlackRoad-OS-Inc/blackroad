#!/usr/bin/env python3
"""
Cosmology Research Agent
Specialized agent for cosmological calculations including universe expansion,
age of universe, CMB analysis, and large-scale structure.
"""

import numpy as np
import sympy as sp
from scipy.integrate import quad
from typing import Dict, List, Tuple, Optional
import json
from datetime import datetime


class CosmologyAgent:
    """
    Cosmology specialist agent that performs universe-scale calculations,
    expansion analysis, and cosmological parameter estimations.
    """

    def __init__(self, agent_id: str = "COSMO-001"):
        self.agent_id = agent_id
        self.name = "Cosmology Agent"
        self.capabilities = [
            "hubble_parameter",
            "age_of_universe",
            "cosmic_distance",
            "redshift_analysis",
            "cmb_temperature",
            "critical_density",
            "dark_energy_fraction",
            "universe_composition"
        ]

        # Cosmological constants (Planck 2018)
        self.H0 = 67.4  # Hubble constant (km/s/Mpc)
        self.Omega_m = 0.315  # Matter density parameter
        self.Omega_lambda = 0.685  # Dark energy density parameter
        self.Omega_r = 9.24e-5  # Radiation density parameter
        self.c = 299792.458  # Speed of light (km/s)
        self.G = 6.67430e-11  # Gravitational constant (m^3 kg^-1 s^-2)
        self.T_cmb_0 = 2.7255  # CMB temperature today (K)

    def hubble_parameter(self, z: float) -> Dict:
        """
        Calculate Hubble parameter H(z) at redshift z.

        H(z) = H0 * sqrt(Ω_m(1+z)³ + Ω_r(1+z)⁴ + Ω_Λ)

        Args:
            z: Redshift

        Returns:
            Hubble parameter analysis
        """
        factor = np.sqrt(
            self.Omega_m * (1 + z)**3 +
            self.Omega_r * (1 + z)**4 +
            self.Omega_lambda
        )
        H_z = self.H0 * factor

        return {
            "agent": self.agent_id,
            "calculation": "hubble_parameter",
            "redshift": z,
            "H_z_km_s_Mpc": float(H_z),
            "H0_km_s_Mpc": self.H0,
            "expansion_rate_ratio": float(H_z / self.H0),
            "timestamp": datetime.now().isoformat()
        }

    def age_of_universe(self, z: float = 0) -> Dict:
        """
        Calculate age of universe at redshift z.

        t(z) = ∫[z,∞] dz' / [(1+z') H(z')]

        Args:
            z: Redshift (0 = today)

        Returns:
            Age analysis
        """
        def integrand(z_prime):
            H_z = self.hubble_parameter(z_prime)["H_z_km_s_Mpc"]
            return 1 / ((1 + z_prime) * H_z)

        # Integrate from z to infinity (approximate with large z)
        z_max = 1100  # CMB redshift
        age_Gyr, error = quad(integrand, z, z_max)
        age_Gyr *= 977.8  # Convert from 1/H0 units to Gyr

        return {
            "agent": self.agent_id,
            "calculation": "age_of_universe",
            "redshift": z,
            "age_Gyr": float(age_Gyr),
            "age_years": float(age_Gyr * 1e9),
            "lookback_time_Gyr": float(self.age_of_universe(0)["age_Gyr"] - age_Gyr) if z > 0 else 0,
            "timestamp": datetime.now().isoformat()
        }

    def comoving_distance(self, z: float) -> Dict:
        """
        Calculate comoving distance to redshift z.

        D_c = c/H0 ∫[0,z] dz' / E(z') where E(z) = H(z)/H0

        Args:
            z: Redshift

        Returns:
            Distance analysis
        """
        def integrand(z_prime):
            E_z = self.hubble_parameter(z_prime)["H_z_km_s_Mpc"] / self.H0
            return 1 / E_z

        D_c_over_c_H0, error = quad(integrand, 0, z)
        D_c_Mpc = D_c_over_c_H0 * (self.c / self.H0)

        # Luminosity distance
        D_L_Mpc = D_c_Mpc * (1 + z)

        # Angular diameter distance
        D_A_Mpc = D_c_Mpc / (1 + z)

        return {
            "agent": self.agent_id,
            "calculation": "comoving_distance",
            "redshift": z,
            "comoving_distance_Mpc": float(D_c_Mpc),
            "comoving_distance_Gly": float(D_c_Mpc / 1000),
            "luminosity_distance_Mpc": float(D_L_Mpc),
            "angular_diameter_distance_Mpc": float(D_A_Mpc),
            "timestamp": datetime.now().isoformat()
        }

    def cmb_temperature(self, z: float) -> Dict:
        """
        Calculate CMB temperature at redshift z.

        T(z) = T0 * (1 + z)

        Args:
            z: Redshift

        Returns:
            CMB temperature analysis
        """
        T_z = self.T_cmb_0 * (1 + z)

        # Energy density
        a = 7.5657e-16  # Radiation constant (J m^-3 K^-4)
        rho_rad = a * T_z**4

        return {
            "agent": self.agent_id,
            "calculation": "cmb_temperature",
            "redshift": z,
            "temperature_K": float(T_z),
            "temperature_today_K": self.T_cmb_0,
            "radiation_energy_density_J_m3": float(rho_rad),
            "photon_wavelength_peak_mm": float(2.898 / T_z),  # Wien's law
            "timestamp": datetime.now().isoformat()
        }

    def critical_density(self, z: float = 0) -> Dict:
        """
        Calculate critical density at redshift z.

        ρ_crit = 3H²/(8πG)

        Args:
            z: Redshift

        Returns:
            Critical density analysis
        """
        H_z = self.hubble_parameter(z)["H_z_km_s_Mpc"]

        # Convert H to SI (s^-1)
        H_SI = H_z * 1000 / (3.086e22)  # km/s/Mpc to 1/s

        rho_crit = 3 * H_SI**2 / (8 * np.pi * self.G)

        # Matter density
        rho_matter = rho_crit * self.Omega_m * (1 + z)**3

        return {
            "agent": self.agent_id,
            "calculation": "critical_density",
            "redshift": z,
            "critical_density_kg_m3": float(rho_crit),
            "critical_density_protons_m3": float(rho_crit / 1.673e-27),
            "matter_density_kg_m3": float(rho_matter),
            "matter_to_critical_ratio": self.Omega_m * (1 + z)**3,
            "timestamp": datetime.now().isoformat()
        }

    def universe_composition(self, z: float = 0) -> Dict:
        """
        Calculate universe composition (matter, dark energy, radiation) at redshift z.

        Args:
            z: Redshift

        Returns:
            Composition analysis
        """
        # Density parameters evolve with redshift
        total = (self.Omega_m * (1 + z)**3 +
                self.Omega_r * (1 + z)**4 +
                self.Omega_lambda)

        Omega_m_z = self.Omega_m * (1 + z)**3 / total
        Omega_r_z = self.Omega_r * (1 + z)**4 / total
        Omega_lambda_z = self.Omega_lambda / total

        return {
            "agent": self.agent_id,
            "calculation": "universe_composition",
            "redshift": z,
            "matter_fraction": float(Omega_m_z),
            "dark_energy_fraction": float(Omega_lambda_z),
            "radiation_fraction": float(Omega_r_z),
            "matter_percentage": float(Omega_m_z * 100),
            "dark_energy_percentage": float(Omega_lambda_z * 100),
            "radiation_percentage": float(Omega_r_z * 100),
            "dominant_component": "matter" if Omega_m_z > max(Omega_lambda_z, Omega_r_z) else
                                 "dark_energy" if Omega_lambda_z > Omega_r_z else "radiation",
            "timestamp": datetime.now().isoformat()
        }

    def redshift_to_time(self, z: float) -> Dict:
        """
        Convert redshift to cosmic time and other parameters.

        Args:
            z: Redshift

        Returns:
            Complete redshift analysis
        """
        age = self.age_of_universe(z)
        distance = self.comoving_distance(z)
        cmb = self.cmb_temperature(z)
        comp = self.universe_composition(z)

        return {
            "agent": self.agent_id,
            "calculation": "redshift_analysis",
            "redshift": z,
            "age_Gyr": age["age_Gyr"],
            "lookback_time_Gyr": age.get("lookback_time_Gyr", 0),
            "distance_Gly": distance["comoving_distance_Gly"],
            "cmb_temperature_K": cmb["temperature_K"],
            "universe_size_ratio": 1 / (1 + z),
            "dominant_component": comp["dominant_component"],
            "timestamp": datetime.now().isoformat()
        }

    def process_request(self, request: Dict) -> Dict:
        """Process incoming calculation request."""
        calc_type = request.get("calculation_type")
        params = request.get("parameters", {})

        if calc_type == "hubble_parameter":
            return self.hubble_parameter(params.get("redshift", 0))
        elif calc_type == "age_of_universe":
            return self.age_of_universe(params.get("redshift", 0))
        elif calc_type == "comoving_distance":
            return self.comoving_distance(params.get("redshift"))
        elif calc_type == "cmb_temperature":
            return self.cmb_temperature(params.get("redshift", 0))
        elif calc_type == "critical_density":
            return self.critical_density(params.get("redshift", 0))
        elif calc_type == "universe_composition":
            return self.universe_composition(params.get("redshift", 0))
        elif calc_type == "redshift_analysis":
            return self.redshift_to_time(params.get("redshift"))
        else:
            return {
                "agent": self.agent_id,
                "error": f"Unknown calculation type: {calc_type}",
                "available_types": self.capabilities
            }


# Example usage and testing
if __name__ == "__main__":
    agent = CosmologyAgent()

    print("🔭 Cosmology Agent - Test Suite")
    print("=" * 60)

    # Test 1: Age of universe today
    print("\n1. Age of Universe (today, z=0):")
    result = agent.age_of_universe(0)
    print(f"   Age: {result['age_Gyr']:.2f} Gyr ({result['age_years']:.2e} years)")

    # Test 2: CMB redshift (z ≈ 1100)
    print("\n2. At CMB Decoupling (z=1100):")
    result = agent.redshift_to_time(1100)
    print(f"   Age: {result['age_Gyr']:.4f} Gyr")
    print(f"   CMB temp: {result['cmb_temperature_K']:.0f} K")
    print(f"   Universe size: {result['universe_size_ratio']:.4f}x today")

    # Test 3: Universe composition evolution
    print("\n3. Universe Composition:")
    for z, era in [(0, "Today"), (1, "z=1"), (1100, "CMB"), (10000, "Early")]:
        result = agent.universe_composition(z)
        print(f"   {era:10s}: Matter={result['matter_percentage']:.1f}%, "
              f"Dark Energy={result['dark_energy_percentage']:.1f}%, "
              f"Radiation={result['radiation_percentage']:.2f}%")

    # Test 4: Cosmic distances
    print("\n4. Comoving Distance (z=1, z=2, z=5):")
    for z in [1, 2, 5]:
        result = agent.comoving_distance(z)
        print(f"   z={z}: D_c={result['comoving_distance_Gly']:.2f} Gly, "
              f"D_L={result['luminosity_distance_Mpc']:.0f} Mpc")

    # Test 5: Hubble parameter evolution
    print("\n5. Hubble Parameter:")
    for z in [0, 1, 5, 1100]:
        result = agent.hubble_parameter(z)
        print(f"   z={z:4d}: H(z)={result['H_z_km_s_Mpc']:.1f} km/s/Mpc "
              f"({result['expansion_rate_ratio']:.1f}x today)")

    # Test 6: Critical density
    print("\n6. Critical Density (today):")
    result = agent.critical_density(0)
    print(f"   ρ_crit = {result['critical_density_kg_m3']:.2e} kg/m³")
    print(f"   ≈ {result['critical_density_protons_m3']:.1f} protons/m³")

    print("\n" + "=" * 60)
    print("✅ All tests complete! Agent is operational.")
