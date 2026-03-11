"""Tests for perspective_calc — 3D to 2D projection."""

import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from perspective_calc import (
    Point3D,
    ProjectedPoint,
    Direction,
    VanishingPoint,
    ProjectionError,
    project_points,
    compute_vanishing_points,
)


class TestProjectPoints:
    def test_origin(self):
        points = [Point3D(x=0, y=0, z=0, d=10)]
        result = project_points(points)
        assert len(result) == 1
        assert result[0].x_proj == pytest.approx(0.0)
        assert result[0].y_proj == pytest.approx(0.0)

    def test_projection_formula(self):
        # x' = d * x / (z + d) = 10 * 5 / (5 + 10) = 50/15 ≈ 3.333
        points = [Point3D(x=5, y=3, z=5, d=10)]
        result = project_points(points)
        assert result[0].x_proj == pytest.approx(50 / 15)
        assert result[0].y_proj == pytest.approx(30 / 15)

    def test_z_plus_d_zero_raises(self):
        points = [Point3D(x=1, y=1, z=-10, d=10)]
        with pytest.raises(ProjectionError, match="z \\+ d == 0"):
            project_points(points)

    def test_multiple_points(self):
        points = [
            Point3D(x=1, y=0, z=0, d=10),
            Point3D(x=0, y=1, z=0, d=10),
        ]
        result = project_points(points)
        assert len(result) == 2
        assert result[0].x_proj == pytest.approx(1.0)
        assert result[1].y_proj == pytest.approx(1.0)


class TestComputeVanishingPoints:
    def test_finite_vanishing_point(self):
        directions = [Direction(vx=1, vy=0, vz=1)]
        vps = compute_vanishing_points(directions, distance=10)
        assert len(vps) == 1
        assert vps[0].is_finite
        assert vps[0].x == pytest.approx(10.0)
        assert vps[0].y == pytest.approx(0.0)

    def test_infinite_vanishing_point(self):
        # vz=0 means parallel to picture plane → vanishing at infinity
        directions = [Direction(vx=1, vy=0, vz=0)]
        vps = compute_vanishing_points(directions, distance=10)
        assert not vps[0].is_finite
        assert vps[0].x is None

    def test_multiple_directions(self):
        directions = [
            Direction(vx=1, vy=0, vz=1, label="x-axis"),
            Direction(vx=0, vy=1, vz=1, label="y-axis"),
        ]
        vps = compute_vanishing_points(directions, distance=5)
        assert len(vps) == 2
        assert all(vp.is_finite for vp in vps)


class TestVanishingPoint:
    def test_is_finite_true(self):
        vp = VanishingPoint(Direction(1, 0, 1), x=10.0, y=0.0)
        assert vp.is_finite is True

    def test_is_finite_false(self):
        vp = VanishingPoint(Direction(1, 0, 0), x=None, y=None)
        assert vp.is_finite is False
