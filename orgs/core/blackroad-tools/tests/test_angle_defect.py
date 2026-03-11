"""Tests for geometry.angle_defect — discrete Gaussian curvature."""

import math
import numpy as np
import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from geometry.angle_defect import angle, angle_defects


class TestAngle:
    def test_right_angle(self):
        # Angle at B in a right triangle
        a = angle((1, 0, 0), (0, 0, 0), (0, 1, 0))
        assert a == pytest.approx(math.pi / 2)

    def test_straight_line(self):
        a = angle((-1, 0, 0), (0, 0, 0), (1, 0, 0))
        assert a == pytest.approx(math.pi)

    def test_acute_angle(self):
        a = angle((1, 0, 0), (0, 0, 0), (1, 1, 0))
        assert 0 < a < math.pi / 2

    def test_degenerate_raises(self):
        with pytest.raises(ValueError, match="positive length"):
            angle((0, 0, 0), (0, 0, 0), (1, 0, 0))


class TestAngleDefects:
    def test_tetrahedron(self):
        # Regular tetrahedron: all vertices should have positive curvature
        # summing to 4π (Gauss-Bonnet for sphere-like topology, χ=2)
        v = [
            (1, 1, 1),
            (1, -1, -1),
            (-1, 1, -1),
            (-1, -1, 1),
        ]
        f = [(0, 1, 2), (0, 1, 3), (0, 2, 3), (1, 2, 3)]
        defects = angle_defects(v, f)
        assert len(defects) == 4
        total = float(defects.sum())
        assert total == pytest.approx(4 * math.pi, rel=0.01)

    def test_flat_quad(self):
        # Two triangles forming a flat square — interior vertex has 0 defect
        v = [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)]
        f = [(0, 1, 2), (0, 2, 3)]
        defects = angle_defects(v, f)
        assert len(defects) == 4

    def test_empty_vertices_raises(self):
        with pytest.raises(ValueError, match="vertices"):
            angle_defects([], [(0, 1, 2)])

    def test_non_triangular_face_raises(self):
        with pytest.raises(ValueError, match="triangular"):
            angle_defects([(0, 0, 0), (1, 0, 0)], [(0, 1)])
