"""Tests for number_theory.trig_roots — sqrt01, cheb_root, log_spiral_pitch."""

import math
import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from number_theory.trig_roots import sqrt01, cheb_root, log_spiral_pitch, demo_spiral_pitch


class TestSqrt01:
    def test_zero(self):
        assert sqrt01(0.0) == pytest.approx(0.0)

    def test_one(self):
        assert sqrt01(1.0) == pytest.approx(1.0)

    def test_quarter(self):
        assert sqrt01(0.25) == pytest.approx(0.5)

    def test_half(self):
        assert sqrt01(0.5) == pytest.approx(math.sqrt(0.5))

    def test_out_of_range_raises(self):
        with pytest.raises(ValueError):
            sqrt01(1.5)
        with pytest.raises(ValueError):
            sqrt01(-0.1)


class TestChebRoot:
    def test_identity_n1(self):
        # T_1(y) = y, so cheb_root(x, 1) = x
        assert cheb_root(0.5, 1) == pytest.approx(0.5)

    def test_n2(self):
        # T_2(y) = 2y^2 - 1, if x = 0 then y = cos(pi/(2*2)) = cos(pi/4)
        y = cheb_root(0.0, 2)
        assert y == pytest.approx(math.cos(math.pi / 4))

    def test_negative_n_raises(self):
        with pytest.raises(ValueError, match="positive"):
            cheb_root(0.5, 0)

    def test_out_of_range_raises(self):
        with pytest.raises(ValueError, match="must not exceed"):
            cheb_root(1.5, 2)


class TestLogSpiralPitch:
    def test_returns_c(self):
        assert log_spiral_pitch(0.5, 2.0) == 0.5

    def test_negative_c(self):
        assert log_spiral_pitch(-0.3, 1.0) == -0.3

    def test_zero_power_raises(self):
        with pytest.raises(ValueError, match="non-zero"):
            log_spiral_pitch(0.5, 0)


class TestDemoSpiralPitch:
    def test_output_format(self):
        report = demo_spiral_pitch(0.5, 2.0)
        assert "Input pitch: 0.5" in report
        assert "z -> z^2.0" in report
        assert "Resulting pitch: 0.5" in report
