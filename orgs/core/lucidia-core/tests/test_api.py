"""Tests for the FastAPI endpoints in lucidia_core.api."""

from __future__ import annotations

import pytest

from fastapi.testclient import TestClient

from lucidia_core.api import app


@pytest.fixture
def client():
    return TestClient(app)


class TestHealthEndpoint:

    def test_health_returns_200(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "healthy"
        assert "physicist" in data["agents"]
        assert data["version"] == "0.1.0"


class TestPhysicistEndpoints:

    def test_analyze(self, client):
        resp = client.post("/physicist/analyze", json={"query": "energy conservation"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["agent"] == "physicist"
        assert "energy conservation" in data["result"]["query"]

    def test_energy_flow(self, client):
        resp = client.post("/physicist/energy-flow", json={"query": "heat transfer"})
        assert resp.status_code == 200
        assert resp.json()["agent"] == "physicist"


class TestMathematicianEndpoints:

    def test_compute(self, client):
        resp = client.post("/mathematician/compute", json={"query": "2 + 2"})
        assert resp.status_code == 200
        assert resp.json()["agent"] == "mathematician"

    def test_prove(self, client):
        resp = client.post("/mathematician/prove", json={"query": "Fermat's last theorem"})
        assert resp.status_code == 200
        data = resp.json()
        assert data["result"]["proof_status"] == "pending"


class TestChemistEndpoint:

    def test_analyze(self, client):
        resp = client.post("/chemist/analyze", json={"query": "H2O"})
        assert resp.status_code == 200
        assert resp.json()["agent"] == "chemist"


class TestGeologistEndpoint:

    def test_terrain(self, client):
        resp = client.post("/geologist/terrain", json={"query": "granite formation"})
        assert resp.status_code == 200
        assert resp.json()["agent"] == "geologist"


class TestAnalystEndpoint:

    def test_insights(self, client):
        resp = client.post("/analyst/insights", json={"query": "sales data"})
        assert resp.status_code == 200
        assert resp.json()["agent"] == "analyst"


class TestArchitectEndpoint:

    def test_design(self, client):
        resp = client.post("/architect/design", json={"query": "microservices"})
        assert resp.status_code == 200
        assert resp.json()["agent"] == "architect"


class TestRequestValidation:

    def test_missing_query_field(self, client):
        resp = client.post("/physicist/analyze", json={"not_query": "x"})
        assert resp.status_code == 422  # Pydantic validation error

    def test_extra_fields_ignored(self, client):
        resp = client.post("/chemist/analyze", json={"query": "NaCl", "extra": "ignored"})
        assert resp.status_code == 200
