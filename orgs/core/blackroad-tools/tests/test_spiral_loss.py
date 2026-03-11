"""Tests for rf.spiral_loss — reflection spiral estimation."""

import numpy as np
import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from rf.spiral_loss import (
    ReflectionTrace,
    SpiralEstimate,
    LineEstimate,
    unwrap_angle,
    spiral_pitch,
    beta_from_trace,
    estimate_line,
    reconstruct_spiral,
)


class TestReflectionTrace:
    def test_valid(self):
        t = ReflectionTrace(np.array([1.0, 2.0]), np.array([0.5 + 0.1j, 0.4 + 0.2j]))
        assert t.position.size == 2

    def test_mismatched_length_raises(self):
        with pytest.raises(ValueError, match="same length"):
            ReflectionTrace(np.array([1.0, 2.0]), np.array([0.5 + 0.1j]))

    def test_non_finite_raises(self):
        with pytest.raises(ValueError, match="non-finite"):
            ReflectionTrace(np.array([1.0, np.nan]), np.array([0.5j, 0.3j]))


class TestUnwrapAngle:
    def test_no_wrap(self):
        z = np.array([1 + 0j, 0 + 1j, -1 + 0j])
        angles = unwrap_angle(z)
        assert angles[0] == pytest.approx(0.0)
        assert angles[1] == pytest.approx(np.pi / 2)
        assert angles[2] == pytest.approx(np.pi)


class TestSpiralPitch:
    def test_ideal_spiral(self):
        # Generate an ideal log spiral: r = exp(c * theta)
        theta = np.linspace(0, 4 * np.pi, 200)
        c = -0.05
        r = np.exp(c * theta)
        gamma = r * np.exp(1j * theta)
        est = spiral_pitch(gamma)
        assert est.pitch == pytest.approx(c, abs=0.01)
        assert est.spiralness > 0.95

    def test_circle_zero_pitch(self):
        theta = np.linspace(0, 2 * np.pi, 100)
        gamma = 0.5 * np.exp(1j * theta)
        est = spiral_pitch(gamma)
        assert abs(est.pitch) < 0.01


class TestLineEstimate:
    def test_alpha_magnitude(self):
        le = LineEstimate(alpha=-0.5, beta=1.0, slope_theta_vs_position=0, theta_intercept=0, pitch=0)
        assert le.alpha_magnitude == pytest.approx(0.5)

    def test_c_hat(self):
        le = LineEstimate(alpha=-0.1, beta=2.0, slope_theta_vs_position=0, theta_intercept=0, pitch=0)
        assert le.c_hat == pytest.approx(0.05)

    def test_c_hat_zero_beta(self):
        le = LineEstimate(alpha=-0.1, beta=0.0, slope_theta_vs_position=0, theta_intercept=0, pitch=0)
        assert np.isnan(le.c_hat)


class TestEstimateLine:
    def test_synthetic_trace(self):
        pos = np.linspace(0, 100, 500)
        beta_true = 0.1
        c_true = -0.02
        theta = -2 * beta_true * pos
        r = np.exp(c_true * theta)
        gamma = r * np.exp(1j * theta)
        trace = ReflectionTrace(pos, gamma)
        spiral, line = estimate_line(trace)
        assert spiral.spiralness > 0.9
        assert line.beta == pytest.approx(beta_true, rel=0.1)


class TestReconstructSpiral:
    def test_shape(self):
        pos = np.linspace(0, 10, 50)
        gamma = 0.8 * np.exp(1j * pos)
        trace = ReflectionTrace(pos, gamma)
        spiral, line = estimate_line(trace)
        fitted = reconstruct_spiral(trace, spiral, line)
        assert fitted.shape == gamma.shape
