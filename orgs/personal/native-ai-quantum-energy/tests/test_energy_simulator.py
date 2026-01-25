import pytest
from native_ai_quantum_energy.energy_simulator import (
    battery_discharge,
    simulate_particle_collision,
    solar_panel_output,
)



def test_solar_panel_output_valid():
    energy = solar_panel_output(100, 2, 0.5)
    assert energy == pytest.approx(100 * 0.5 * 2 * 3600)


def test_solar_panel_output_negative_power():
    with pytest.raises(ValueError):
        solar_panel_output(-10, 1)


def test_solar_panel_output_negative_hours():
    with pytest.raises(ValueError):
        solar_panel_output(10, -1)


def test_battery_discharge_partial_consumption():
    remaining = battery_discharge(2000, 500, 2)
    assert remaining == pytest.approx(2000 - 1000)


def test_battery_discharge_invalid_inputs():
    with pytest.raises(ValueError):
        battery_discharge(-1, 100, 1)


def test_particle_collision_conserves_symmetry():
    v1_final, v2_final = simulate_particle_collision(1.0, 1.0, 1.0, -1.0)
    assert v1_final == pytest.approx(-1.0)
    assert v2_final == pytest.approx(1.0)


def test_particle_collision_requires_positive_mass():
    with pytest.raises(ValueError):
        simulate_particle_collision(0.0, 1.0, 1.0, -1.0)
