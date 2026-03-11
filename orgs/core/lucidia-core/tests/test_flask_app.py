"""Tests for the Flask app (app.py) math endpoints."""

from __future__ import annotations

import pytest

from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as c:
        yield c


class TestFlaskIndex:

    def test_index(self, client):
        resp = client.get("/")
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["service"] == "Lucidia Core"
        assert "mathematician" in data["engines"]


class TestFlaskHealth:

    def test_health(self, client):
        resp = client.get("/health")
        assert resp.status_code == 200
        assert resp.get_json()["status"] == "healthy"


class TestFlaskMath:

    def test_evaluate_expression(self, client):
        resp = client.post("/math", json={"expression": "2 + 3"})
        assert resp.status_code == 200
        data = resp.get_json()
        # SymPy evalf returns a float representation for numeric results.
        assert "5" in data["result"]

    def test_missing_expression(self, client):
        resp = client.post("/math", json={})
        assert resp.status_code == 400

    def test_invalid_expression(self, client):
        resp = client.post("/math", json={"expression": "+++invalid+++"})
        assert resp.status_code == 400


class TestFlaskDerivative:

    def test_derivative(self, client):
        resp = client.post("/derivative", json={"expression": "x**2", "variable": "x"})
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["derivative"] == "2*x"

    def test_missing_expression(self, client):
        resp = client.post("/derivative", json={})
        assert resp.status_code == 400


class TestFlaskSimplify:

    def test_simplify(self, client):
        resp = client.post("/simplify", json={"expression": "x + x"})
        assert resp.status_code == 200
        data = resp.get_json()
        assert data["simplified"] == "2*x"

    def test_missing_expression(self, client):
        resp = client.post("/simplify", json={})
        assert resp.status_code == 400
