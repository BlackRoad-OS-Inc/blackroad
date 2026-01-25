"""
quantum_mirror_qi.py

This module demonstrates the mirror operator Ψ' and breath operator ℂ for a single qubit and an entangled two-qubit state.
It splits a qubit state into global-phase-free (logical) and phase components, evolves the state under a Hamiltonian, applies a delta kick,
and measures a simple entanglement invariant for a Bell state. The results are saved in CSV files and plots when run directly.

Dependencies: numpy, matplotlib (for plotting).
"""

import numpy as np
import math

try:
    from scipy.linalg import expm
except ImportError:
    expm = None

def normalize(state: np.ndarray) -> np.ndarray:
    """Normalize a state vector."""
    norm = np.linalg.norm(state)
    if norm == 0:
        return state
    return state / norm

def mirror_split_qubit(state: np.ndarray) -> tuple[np.ndarray, complex]:
    """
    Split a single-qubit state into a logical component (phase removed) and the global phase factor.

    Parameters
    ----------
    state : np.ndarray
        Complex two-element vector representing a qubit.

    Returns
    -------
    logical : np.ndarray
        Normalized qubit with global phase removed.
    phase : complex
        The global phase factor such that state = phase * logical.
    """
    state = normalize(state)
    # choose a reference amplitude that is non-zero
    if abs(state[0]) > 1e-12:
        phase = state[0] / abs(state[0])
    else:
        phase = state[1] / abs(state[1])
    logical = state * np.conj(phase)
    return logical, phase

def evolve_state(state: np.ndarray, H: np.ndarray, dt: float) -> np.ndarray:
    """
    Evolve a qubit state under a Hamiltonian for a small time dt using matrix exponential.

    Parameters
    ----------
    state : np.ndarray
        State vector.
    H : np.ndarray
        2x2 Hermitian matrix.
    dt : float
        Time step.

    Returns
    -------
    np.ndarray
        The evolved state.
    """
    if expm is not None:
        U = expm(-1j * H * dt)
    else:
        # fallback using eigen decomposition
        vals, vecs = np.linalg.eigh(H)
        U = vecs @ np.diag(np.exp(-1j * vals * dt)) @ vecs.conj().T
    return U @ state

def delta_kick(state: np.ndarray, phase_kick: float) -> np.ndarray:
    """
    Apply a delta phase kick to the first component of a qubit state.

    Parameters
    ----------
    state : np.ndarray
        Qubit state.
    phase_kick : float
        Phase shift in radians.

    Returns
    -------
    np.ndarray
        New state with phase applied to the |0> amplitude.
    """
    state = state.copy()
    state[0] *= np.exp(1j * phase_kick)
    return state

def bloch_coords(state: np.ndarray) -> tuple[float, float, float]:
    """
    Compute Bloch sphere coordinates (x,y,z) for a qubit state.

    Parameters
    ----------
    state : np.ndarray
        Qubit state.

    Returns
    -------
    (x, y, z) : tuple[float, float, float]
    """
    state = normalize(state)
    a = state[0]
    b = state[1]
    x = 2 * (a.conjugate() * b).real
    y = 2 * (a.conjugate() * b).imag
    z = abs(a)**2 - abs(b)**2
    return x, y, z

def run_single_qubit_demo(steps: int = 500, dt: float = 0.02, omega: float = 1.0, phase_kick: float = math.pi/2, kick_step: int = 250):
    """
    Simulate a single-qubit mirror breathing under a Z Hamiltonian with an optional phase kick.

    Returns
    -------
    dict
        Dictionary containing time array, Bloch coordinates, logical/phase components before and after kick.
    """
    # Hamiltonian for a single qubit (Pauli Z)
    H = 0.5 * omega * np.array([[1, 0], [0, -1]], dtype=complex)
    # initial state |0>
    state = np.array([1.0 + 0j, 0.0 + 0j], dtype=complex)
    times = np.arange(steps) * dt
    xs, ys, zs = [], [], []
    phases = []
    logical_angles = []
    for i in range(steps):
        # record Bloch coords
        x, y, z = bloch_coords(state)
        xs.append(x)
        ys.append(y)
        zs.append(z)
        logical, phase = mirror_split_qubit(state)
        phases.append(np.angle(phase))
        # compute polar angle of logical state on Bloch sphere (theta)
        theta = math.atan2(abs(logical[1]), abs(logical[0]))
        logical_angles.append(theta)
        # apply kick at specified step
        if i == kick_step:
            state = delta_kick(state, phase_kick)
        # evolve state
        state = evolve_state(state, H, dt)
    return {
        "time": times,
        "x": np.array(xs),
        "y": np.array(ys),
        "z": np.array(zs),
        "phase_angle": np.array(phases),
        "logical_theta": np.array(logical_angles),
    }

def concurrence_two_qubit(state: np.ndarray) -> float:
    """
    Compute the concurrence (a measure of entanglement) for a two-qubit state.

    Parameters
    ----------
    state : np.ndarray
        Four-element complex vector representing a two-qubit state.

    Returns
    -------
    float
        The concurrence value.
    """
    # define the Pauli Y tensor product
    sigma_y = np.array([[0, -1j], [1j, 0]], dtype=complex)
    Y = np.kron(sigma_y, sigma_y)
    # spin-flipped state
    state_tilde = Y @ state.conjugate()
    rho = np.outer(state, state.conjugate())
    R = rho @ state_tilde[:, None] @ state_tilde.conjugate()[None, :]
    # eigenvalues of R
    eigvals = np.sort(np.real(np.linalg.eigvals(R)))[::-1]
    # compute concurrence
    return max(0.0, math.sqrt(eigvals[0]) - sum(math.sqrt(eigvals[1:])))

def run_bell_demo():
    """
    Prepare a Bell state and compute its concurrence.

    Returns
    -------
    float
        The concurrence of the Bell state (should be 1.0).
    """
    bell = (1/np.sqrt(2)) * np.array([1.0, 0.0, 0.0, 1.0], dtype=complex)
    return concurrence_two_qubit(bell)

if __name__ == "__main__":
    data = run_single_qubit_demo()
    # Save results to CSV
    import csv
    with open("out_qi_single.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["time", "x", "y", "z", "phase_angle", "logical_theta"])
        for i in range(len(data["time"])):
            writer.writerow([data["time"][i], data["x"][i], data["y"][i], data["z"][i], data["phase_angle"][i], data["logical_theta"][i]])
    try:
        import matplotlib.pyplot as plt
        # plot Bloch coordinates
        plt.figure()
        plt.plot(data["time"], data["x"], label="x")
        plt.plot(data["time"], data["y"], label="y")
        plt.plot(data["time"], data["z"], label="z")
        plt.title("Bloch coordinates of a qubit under Z evolution with a phase kick")
        plt.xlabel("time")
        plt.ylabel("coordinate")
        plt.legend()
        plt.savefig("out_qi_bloch.png")
        # plot phase and logical angle
        plt.figure()
        plt.plot(data["time"], data["phase_angle"], label="phase angle")
        plt.plot(data["time"], data["logical_theta"], label="logical polar angle")
        plt.title("Phase and logical angles over time")
        plt.xlabel("time")
        plt.ylabel("angle (rad)")
        plt.legend()
        plt.savefig("out_qi_angles.png")
    except Exception:
        pass
    # compute concurrence of Bell state
    c = run_bell_demo()
    print(f"Concurrence of Bell state: {c:.3f}")
