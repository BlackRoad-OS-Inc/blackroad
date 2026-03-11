"""Tests for projective.cross_ratio — cross-ratio, homography, warp."""

import numpy as np
import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from projective.cross_ratio import (
    line_coord,
    cross_ratio,
    homography_from_quad,
    warp_point,
)


class TestLineCoord:
    def test_at_a(self):
        assert line_coord((0, 0), (0, 0), (1, 0)) == pytest.approx(0.0)

    def test_at_b(self):
        assert line_coord((1, 0), (0, 0), (1, 0)) == pytest.approx(1.0)

    def test_midpoint(self):
        assert line_coord((0.5, 0), (0, 0), (1, 0)) == pytest.approx(0.5)

    def test_negative_direction(self):
        assert line_coord((-1, 0), (0, 0), (1, 0)) == pytest.approx(-1.0)

    def test_coincident_raises(self):
        with pytest.raises(ValueError, match="distinct"):
            line_coord((0, 0), (1, 1), (1, 1))


class TestCrossRatio:
    def test_four_collinear_points(self):
        # Points on x-axis: (0,0), (1,0), (2,0), (3,0)
        cr = cross_ratio((0, 0), (1, 0), (2, 0), (3, 0))
        # Manual: (0-2)(1-3) / (0-3)(1-2) = (-2)(-2) / (-3)(-1) = 4/3
        assert cr == pytest.approx(4.0 / 3.0)

    def test_harmonic_range(self):
        # Harmonic conjugates: A=0, B=inf→approx, C=1, D=-1 → CR = -1
        # Use (0,0), (3,0), (1,0), (-1,0)
        cr = cross_ratio((0, 0), (3, 0), (1, 0), (-1, 0))
        # (0-1)(3-(-1)) / (0-(-1))(3-1) = (-1)(4) / (1)(2) = -2
        assert cr == pytest.approx(-2.0)


class TestHomography:
    def test_unit_square_identity(self):
        quad = [(0, 0), (1, 0), (1, 1), (0, 1)]
        target = [(0, 0), (1, 0), (1, 1), (0, 1)]
        H = homography_from_quad(quad, target)
        assert H.shape == (3, 3)
        # Should be close to identity (scaled)
        warped = warp_point((0.5, 0.5), H)
        assert warped[0] == pytest.approx(0.5, abs=0.01)
        assert warped[1] == pytest.approx(0.5, abs=0.01)

    def test_warp_corner(self):
        quad = [(0, 0), (2, 0), (2, 2), (0, 2)]
        target = [(0, 0), (1, 0), (1, 1), (0, 1)]
        H = homography_from_quad(quad, target)
        warped = warp_point((2, 2), H)
        assert warped[0] == pytest.approx(1.0, abs=0.01)
        assert warped[1] == pytest.approx(1.0, abs=0.01)

    def test_wrong_point_count_raises(self):
        with pytest.raises(ValueError, match="four"):
            homography_from_quad([(0, 0), (1, 0), (1, 1)])


class TestWarpPoint:
    def test_bad_matrix_shape_raises(self):
        with pytest.raises(ValueError, match="3x3"):
            warp_point((0, 0), np.eye(2))
