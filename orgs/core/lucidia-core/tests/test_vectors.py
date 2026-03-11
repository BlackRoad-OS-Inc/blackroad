"""Tests for core.vectors.Vector3."""

from __future__ import annotations

import math

import pytest

from core.vectors import Vector3


class TestVector3:

    def test_add(self):
        v = Vector3(1, 2, 3) + Vector3(4, 5, 6)
        assert v == Vector3(5, 7, 9)

    def test_sub(self):
        v = Vector3(5, 7, 9) - Vector3(4, 5, 6)
        assert v == Vector3(1, 2, 3)

    def test_scalar_mul(self):
        v = Vector3(1, 2, 3) * 2
        assert v == Vector3(2, 4, 6)

    def test_rmul(self):
        v = 3 * Vector3(1, 1, 1)
        assert v == Vector3(3, 3, 3)

    def test_dot(self):
        assert Vector3(1, 0, 0).dot(Vector3(0, 1, 0)) == 0.0
        assert Vector3(2, 3, 4).dot(Vector3(2, 3, 4)) == 29.0

    def test_norm(self):
        assert Vector3(3, 4, 0).norm() == pytest.approx(5.0)

    def test_norm_zero(self):
        assert Vector3(0, 0, 0).norm() == 0.0

    def test_as_tuple(self):
        assert Vector3(1.5, 2.5, 3.5).as_tuple() == (1.5, 2.5, 3.5)

    def test_immutable(self):
        v = Vector3(1, 2, 3)
        with pytest.raises(AttributeError):
            v.x = 10  # type: ignore[misc]
