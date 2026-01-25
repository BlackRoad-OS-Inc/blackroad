"""
Breath Keeper A/B analysis and persistence metrics.

This module provides utilities for analyzing oscillator signals, including
calculation of unbiased autocorrelation, coherence half-life, beat period,
phase-slip, and energy drift. It also implements a breath keeper (phase-locked
loop with node snapping, amplitude control, and symplectic oscillator) to
maintain phase coherence and conserve energy. A command-line interface is
provided for running baseline vs keeper-enabled analysis on a CSV file of
time series data.
"""

from __future__ import annotations
import numpy as np
from dataclasses import dataclass
from typing import Tuple, Optional, Dict

try:
    from scipy.signal import hilbert, find_peaks
except Exception as e:
    raise SystemExit("Please install scipy via 'pip install scipy' to use breath_keeper.") from e

# Utility functions
def unbiased_autocorr(x: np.ndarray) -> np.ndarray:
    x = x.astype(np.float64)
    x = x - np.mean(x)
    N = len(x)
    ac = np.correlate(x, x, mode='full')
    ac = ac[N-1:]
    norm = np.arange(N, 0, -1, dtype=np.float64)
    ac_unbiased = ac / norm
    return ac_unbiased / ac_unbiased[0]

def fit_coherence_half_life(ac: np.ndarray, Fs: float, min_lag_s: float = 2.0, max_lag_frac: float = 0.5) -> Tuple[float, Tuple[float, float]]:
    N = len(ac)
    t = np.arange(N)/Fs
    lo = int(min_lag_s*Fs)
    hi = int(min(N-1, max_lag_frac*N))
    if hi <= lo+5:
        return float('nan'), (float('nan'), float('nan'))
    y = np.clip(ac[lo:hi], 1e-12, 1.0)
    tt = t[lo:hi]
    A = np.vstack([tt, np.ones_like(tt)]).T
    coeff, _, _, _ = np.linalg.lstsq(A, np.log(y), rcond=None)
    slope, intercept = coeff
    tau = -1.0 / slope if slope < 0 else float('nan')
    residuals = np.log(y) - (A @ coeff)
    sigma = np.std(residuals)
    denom = np.sum((tt - np.mean(tt))**2)
    if denom <= 0:
        return tau, (float('nan'), float('nan'))
    var_slope = sigma**2 / denom
    se_slope = np.sqrt(var_slope)
    slope_lo = slope - 2*se_slope
    slope_hi = slope + 2*se_slope
    tau_lo = -1.0/slope_hi if slope_hi < 0 else float('nan')
    tau_hi = -1.0/slope_lo if slope_lo < 0 else float('nan')
    return float(tau), (float(tau_lo), float(tau_hi))

def analytic_envelope(x: np.ndarray) -> np.ndarray:
    return np.abs(hilbert(x))

def beat_period_from_envelope(env: np.ndarray, Fs: float, min_period_s: float = 0.5, max_period_s: float = 10.0) -> float:
    ac = unbiased_autocorr(env)
    lags = np.arange(len(ac))/Fs
    lo = int(min_period_s*Fs)
    hi = int(min(len(ac)-1, max_period_s*Fs))
    if hi <= lo+3:
        return float('nan')
    peaks, _ = find_peaks(ac[lo:hi], height=0.2)
    if len(peaks) == 0:
        return float('nan')
    first = peaks[0] + lo
    return lags[first]

def node_trough_indices(env: np.ndarray, Tb: float, Fs: float) -> np.ndarray:
    if not np.isfinite(Tb) or Tb <= 0:
        idx, _ = find_peaks(-env, distance=int(0.25*Fs))
        return idx
    idx, _ = find_peaks(-env, distance=int(0.8*Tb*Fs))
    return idx

def phase_from_analytic(x: np.ndarray) -> np.ndarray:
    return np.unwrap(np.angle(hilbert(x)))

def energy_series(x: np.ndarray, Fs: float, win_periods: float = 1.0, carrier_Hz: Optional[float] = None) -> np.ndarray:
    if carrier_Hz and carrier_Hz > 0:
        win = int(max(1, round(Fs/carrier_Hz*win_periods)))
    else:
        win = int(max(1, round(Fs/10)))
    kernel = np.ones(win)/win
    rms = np.sqrt(np.convolve(x**2, kernel, mode='same'))
    return rms**2

def wrap_pi(a):
    return (a + np.pi) % (2*np.pi) - np.pi

@dataclass
class KeeperConfig:
    Fs: float
    Kp: float = 0.05
    Ki: float = 0.001
    agc_tau: float = 0.5
    snap_thresh: float = 0.05
    omega_init: Optional[float] = None

class BreathKeeper:
    def __init__(self, cfg: KeeperConfig):
        self.cfg = cfg
        self._phi_int = 0.0
        self._amp = 1.0
        self.q = 0.0
        self.p = 0.0
        self.omega = cfg.omega_init if cfg.omega_init else 2*np.pi*1.0

    def phase_est(self) -> float:
        return np.arctan2(self.p, self.q + 1e-12)

    def set_phase(self, phi: float):
        A = max(1e-9, self._amp)
        self.q = A * np.cos(phi)
        self.p = A * np.sin(phi)

    def step(self, x_t: float, env_t: float, phi_meas: float) -> float:
        phi_err = wrap_pi(phi_meas - self.phase_est())
        self._phi_int += self.cfg.Ki * phi_err
        dphi = self.cfg.Kp * phi_err + self._phi_int
        self.omega = max(1e-6, self.omega + dphi)
        if env_t < self.cfg.snap_thresh * (self._amp + 1e-9):
            self.set_phase(np.round(self.phase_est()/np.pi)*np.pi)
        alpha = np.exp(-1.0/(self.cfg.agc_tau*self.cfg.Fs))
        self._amp = alpha*self._amp + (1-alpha)*abs(x_t)
        dt = 1.0/self.cfg.Fs
        self.p -= (self.omega**2)*self.q*(dt*0.5)
        self.q += self.p*dt
        self.p -= (self.omega**2)*self.q*(dt*0.5)
        return self.phase_est()

@dataclass
class Metrics:
    Tb: float
    tau_c: float
    tau_ci: Tuple[float,float]
    phase_slip_rad_per_beat: float
    energy_drift_per_beat: float

def compute_metrics(x: np.ndarray, Fs: float) -> Metrics:
    env = analytic_envelope(x)
    Tb = beat_period_from_envelope(env, Fs)
    ac = unbiased_autocorr(env)
    tau_c, tau_ci = fit_coherence_half_life(ac, Fs)
    nodes = node_trough_indices(env, Tb, Fs)
    phi = phase_from_analytic(x)
    if len(nodes) >= 2:
        dphi = wrap_pi(np.diff(phi[nodes]))
        phase_slip = float(np.mean(np.abs(dphi)))
    else:
        phase_slip = float('nan')
    E = energy_series(x, Fs)
    if len(nodes) >= 2:
        Eb = E[nodes]
        rel_changes = np.diff(Eb)/(Eb[:-1]+1e-12)
        energy_drift = float(np.mean(rel_changes))
    else:
        energy_drift = float('nan')
    return Metrics(Tb=Tb, tau_c=float(tau_c), tau_ci=(float(tau_ci[0]), float(tau_ci[1])), phase_slip_rad_per_beat=phase_slip, energy_drift_per_beat=energy_drift)

def keeper_follow(x: np.ndarray, Fs: float) -> np.ndarray:
    env = analytic_envelope(x)
    phi_meas = np.unwrap(np.angle(hilbert(x)))
    cfg = KeeperConfig(Fs=Fs)
    k = BreathKeeper(cfg)
    y = np.zeros_like(x)
    for n in range(len(x)):
        phi = k.step(x[n], env[n], phi_meas[n])
        y[n] = np.cos(phi)
    return y

def analyze_ab(x: np.ndarray, Fs: float) -> Dict[str, Metrics]:
    base_metrics = compute_metrics(x, Fs)
    y = keeper_follow(x, Fs)
    keep_metrics = compute_metrics(y, Fs)
    return {"baseline": base_metrics, "keeper": keep_metrics}

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Breath keeper analysis: compute baseline and keeper metrics on CSV file.")
    parser.add_argument("--csv", type=str, required=True, help="Path to CSV with columns t,x or x.")
    parser.add_argument("--fs", type=float, required=False, help="Sampling rate in Hz if no t column.")
    args = parser.parse_args()
    import numpy as np
    data = np.genfromtxt(args.csv, delimiter=",", names=True, dtype=None, encoding=None)
    if "x" in data.dtype.names:
        x = data["x"].astype(np.float64)
        if "t" in data.dtype.names:
            t = data["t"].astype(np.float64)
            Fs_val = 1.0/np.mean(np.diff(t))
        else:
            if args.fs is None:
                raise ValueError("Sampling rate must be provided if no t column.")
            Fs_val = float(args.fs)
    else:
        raw = np.genfromtxt(args.csv, delimiter=",")
        if raw.ndim == 1:
            if args.fs is None:
                raise ValueError("Sampling rate must be provided for single column CSV.")
            x = raw.astype(np.float64)
            Fs_val = float(args.fs)
        else:
            t = raw[:,0].astype(np.float64)
            x = raw[:,1].astype(np.float64)
            Fs_val = 1.0/np.mean(np.diff(t))
    results = analyze_ab(x, Fs_val)
    for label, m in results.items():
        print(f"[{label}]")
        print(f"  Beat period Tb (s):         {m.Tb:.6f}")
        print(f"  Coherence half-life \u03c4c (s): {m.tau_c:.6f}  (CI ~ {m.tau_ci[0]:.3f}, {m.tau_ci[1]:.3f})")
        print(f"  Phase slip |\u03c6̇| (rad/beat):  {m.phase_slip_rad_per_beat:.6e}")
        print(f"  Energy drift \u0110 (/beat):      {m.energy_drift_per_beat:.6e}")
