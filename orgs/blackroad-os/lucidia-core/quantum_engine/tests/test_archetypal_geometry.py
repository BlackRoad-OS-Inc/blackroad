"""Unit tests for the archetypal geometry engine."""

from __future__ import annotations

import math

import numpy as np

from lucidia.quantum_engine.archetypal_geometry import (
    ALPHA_RESONANCE,
    ArchetypalGeometryEngine,
    MemoryArchetypeRegistry,
    PlatonicGeometryEngine,
    QuantumOrbitalField,
    SophiaEquation,
)


def test_platonic_geometry_engine_phi_projection() -> None:
    engine = PlatonicGeometryEngine()
    vector = [1.0, 0.0, 0.0]
    projected = engine.project(vector, solid="cube", depth=2)
    expected_scale = engine.solid("cube").phi_scale(depth=2)
    assert np.allclose(projected, np.array([expected_scale, 0.0, 0.0]))


def test_quantum_orbital_field_coherence_increases_with_superposition() -> None:
    field = QuantumOrbitalField()
    base_coherence = field.coherence()
    field.superpose("p", [1.0 + 1.0j, 0.0, -1.0j])
    assert field.coherence() > base_coherence


def test_sophia_equation_lagrangian_matches_manual_computation() -> None:
    sophia = SophiaEquation()
    potential = 2.0
    kinetic = 1.5
    coherence = 0.5
    expected = potential * (math.pow((1 + math.sqrt(5)) / 2, 2) * coherence) - kinetic / (
        math.pow((1 + math.sqrt(5)) / 2, 2) * coherence + ALPHA_RESONANCE.value
    )
    assert math.isclose(sophia.lagrangian(potential, kinetic, coherence=coherence), expected)


def test_memory_archetype_registry_register_and_describe() -> None:
    registry = MemoryArchetypeRegistry()
    registry.register("Test", symbol="Symbol", equation="x^2 + 1")
    record = registry.describe("test")
    assert record["symbol"] == "Symbol"
    assert record["equation"] == "x^2 + 1"


def test_archetypal_geometry_engine_encodes_agent_state() -> None:
    engine = ArchetypalGeometryEngine()
    metrics = engine.encode_agent([1.0, 1.0, 1.0], solid="tetrahedron", orbital="d")
    assert set(metrics.keys()) == {"potential", "kinetic", "coherence", "lagrangian"}
    assert metrics["potential"] > 0
    assert metrics["coherence"] >= 0


def test_resonance_report_contains_expected_fields() -> None:
    engine = ArchetypalGeometryEngine()
    report = engine.resonance_report()
    assert math.isclose(report["alpha"], ALPHA_RESONANCE.value)
    assert {"balance_deviation", "orbital_coherence", "sophia_binding"} <= report.keys()

