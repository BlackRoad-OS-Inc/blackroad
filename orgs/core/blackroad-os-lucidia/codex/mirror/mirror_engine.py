"""
Mirror Engine: orchestrates multiple mirror domains to compute aggregated invariants
and run adaptive breath control to explore the state space while maintaining stability.

This module aggregates invariants from each sub-mirror (physics, quantum, number theory,
graph/network, thermodynamics) and uses a simple control loop to adjust step size
(analogous to the "breath" parameter) based on the deviation of the aggregate invariant
from a target value. It also logs the invariants and step sizes for analysis.

The invariants are computed by invoking helper functions in the respective modules if
available. Where a module does not expose a specialised invariant, randomised fallback
values are used to ensure the engine can run without errors.

Outputs:
 - CSV file with per-iteration aggregate invariant and step size
 - JSON file summarising the invariant trajectories and final capability metrics

"""
import json
import csv
import os
import numpy as np

# attempt to import mirror modules; fall back gracefully if unavailable
try:
    import mirror_mechanics
except Exception:
    mirror_mechanics = None
try:
    import quantum_mirror_qi
except Exception:
    quantum_mirror_qi = None
try:
    import number_mirror_mu
except Exception:
    number_mirror_mu = None
try:
    import graph_network_mirror
except Exception:
    graph_network_mirror = None
try:
    import thermodynamic_entropy_mirror
except Exception:
    thermodynamic_entropy_mirror = None

# reproducible random generator
_rng = np.random.default_rng(12345)

def compute_physics_invariants():
    """Compute simplified physics invariants (action and energy)."""
    if mirror_mechanics and hasattr(mirror_mechanics, "run_oscillator_demo"):
        try:
            # run the demo; expect it to generate a CSV file with energy diagnostics
            mirror_mechanics.run_oscillator_demo()
            diag_path = "out/energy_diagnostics.csv"
            if os.path.exists(diag_path):
                energies = []
                with open(diag_path, newline="") as f:
                    reader = csv.DictReader(f)
                    for row in reader:
                        if "energy" in row:
                            energies.append(float(row["energy"]))
                if energies:
                    energy = float(np.mean(energies))
                else:
                    energy = float(_rng.random())
            else:
                energy = float(_rng.random())
            # approximate action from energy (placeholder)
            action = energy * 0.5
            return {"action": action, "energy": energy}
        except Exception:
            pass
    # fallback random values
    return {"action": float(_rng.random()), "energy": float(_rng.random())}

def compute_quantum_invariants():
    """Compute simplified quantum invariants (purity and concurrence)."""
    purity = float(_rng.random())
    concurrence = float(_rng.random())
    if quantum_mirror_qi:
        try:
            # attempt to use concurrence function on a Bell state
            if hasattr(quantum_mirror_qi, "concurrence_two_qubit"):
                # build simple Bell state
                psi = np.array([1/np.sqrt(2), 0, 0, 1/np.sqrt(2)], dtype=complex)
                conc = quantum_mirror_qi.concurrence_two_qubit(psi)
                concurrence = float(conc)
            if hasattr(quantum_mirror_qi, "purity"):
                # build density matrix and compute purity
                rho = np.array([[0.5, 0, 0, 0.5],
                                [0, 0, 0, 0],
                                [0, 0, 0, 0],
                                [0.5, 0, 0, 0.5]], dtype=complex)
                purity = float(np.real(np.trace(rho @ rho)))
        except Exception:
            pass
    return {"purity": purity, "concurrence": concurrence}

def compute_number_invariants():
    """Compute simplified number theory invariant (Dirichlet residual)."""
    residual = float(_rng.random())
    if number_mirror_mu:
        try:
            # compute residual using Möbius function up to N and compare to reciprocal harmonic sum
            if hasattr(number_mirror_mu, "mu"):
                N = 1000
                s = 2.0
                vals = []
                for n in range(1, N+1):
                    try:
                        mu_val = number_mirror_mu.mu(n)
                    except Exception:
                        mu_val = 0
                    vals.append(mu_val / (n**s))
                partial_sum = np.sum(vals)
                # harmonic sum as approximation to zeta(s)
                zeta_approx = np.sum(1.0 / (np.arange(1, N+1) ** s))
                residual = float(abs(partial_sum - 1.0 / zeta_approx))
        except Exception:
            pass
    return {"dirichlet_residual": residual}

def compute_graph_invariants():
    """Compute simplified graph invariants (algebraic connectivity and degree entropy)."""
    connectivity = float(_rng.random())
    entropy = float(_rng.random())
    if graph_network_mirror and hasattr(graph_network_mirror, "run_network_demo"):
        try:
            # run the network demo to produce adjacency matrix and out-degree distribution
            result = graph_network_mirror.run_network_demo()
            # expect result as dictionary with adjacency and degree distribution
            if isinstance(result, dict) and "adjacency" in result:
                A = np.array(result["adjacency"])
                deg = A.sum(axis=1)
                # Laplacian
                L = np.diag(deg) - A
                eigvals = np.linalg.eigvals(L)
                eigvals = np.real(eigvals)
                eigvals.sort()
                if len(eigvals) > 1:
                    connectivity = float(eigvals[1])
                # entropy of degree distribution
                prob = deg / deg.sum() if deg.sum() > 0 else np.zeros_like(deg)
                entropy = float(-np.sum(prob * np.log(prob + 1e-12)))
        except Exception:
            pass
    return {"connectivity": connectivity, "entropy": entropy}

def compute_thermo_invariants():
    """Compute simplified thermodynamic invariant (free energy)."""
    free_energy = float(_rng.random())
    if thermodynamic_entropy_mirror and hasattr(thermodynamic_entropy_mirror, "run_entropy_demo"):
        try:
            # run the thermo demo; expect it to produce energy and entropy lists in a dict
            result = thermodynamic_entropy_mirror.run_entropy_demo()
            if isinstance(result, dict) and "energy" in result and "entropy" in result:
                energy_arr = np.array(result["energy"], dtype=float)
                entropy_arr = np.array(result["entropy"], dtype=float)
                T = 1.0
                fe = energy_arr - T * entropy_arr
                free_energy = float(np.mean(fe))
        except Exception:
            pass
    return {"free_energy": free_energy}

def aggregate_invariants(inv_dict):
    """Aggregate multiple invariants into a single scalar."""
    vals = []
    for k, v in inv_dict.items():
        try:
            vals.append(abs(float(v)))
        except Exception:
            pass
    if not vals:
        return 0.0
    return float(np.mean(vals))

def run_mirror_engine(iterations=20, target=0.5, threshold=0.1, step_init=1.0,
                      min_step=0.01, max_step=10.0):
    """
    Run the mirror engine for a number of iterations. On each iteration the engine
    samples invariants from each domain, computes an aggregated invariant and adjusts
    the step size based on the deviation from the target. A simple proportional
    control is used: if the aggregate invariant is too high, the step is reduced;
    if too low, the step is increased.
    Parameters:
      iterations: number of iterations to run
      target: desired aggregate invariant
      threshold: acceptable deviation before adjusting step
      step_init: initial step size
      min_step: minimum step size
      max_step: maximum step size
    Returns:
      history: list of dictionaries containing iteration, step size, aggregate invariant and domain invariants
    """
    step = float(step_init)
    history = []
    for i in range(int(iterations)):
        physics_inv = compute_physics_invariants()
        quantum_inv = compute_quantum_invariants()
        number_inv = compute_number_invariants()
        graph_inv = compute_graph_invariants()
        thermo_inv = compute_thermo_invariants()

        # combine invariants into one dictionary
        inv_all = {}
        inv_all.update(physics_inv)
        inv_all.update(quantum_inv)
        inv_all.update(number_inv)
        inv_all.update(graph_inv)
        inv_all.update(thermo_inv)

        agg = aggregate_invariants(inv_all)

        # adjust step size
        error = agg - target
        if abs(error) > threshold:
            # adjust inversely to sign of error
            if error > 0:
                step = max(min_step, step * 0.9)
            else:
                step = min(max_step, step * 1.1)

        history.append({
            "iteration": i,
            "step_size": step,
            "aggregate": agg,
            "invariants": inv_all
        })
    return history

def save_history(history, out_dir="out_engine"):
    """
    Save history of the engine run to CSV and JSON files in the specified directory.
    """
    os.makedirs(out_dir, exist_ok=True)
    csv_path = os.path.join(out_dir, "engine_history.csv")
    json_path = os.path.join(out_dir, "engine_history.json")

    # write CSV
    fieldnames = ["iteration", "step_size", "aggregate"] + list(history[0]["invariants"].keys())
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for record in history:
            row = {
                "iteration": record["iteration"],
                "step_size": record["step_size"],
                "aggregate": record["aggregate"],
            }
            row.update(record["invariants"])
            writer.writerow(row)
    # write JSON summary
    with open(json_path, "w") as f:
        json.dump(history, f, indent=2)
    return csv_path, json_path

if __name__ == "__main__":
    hist = run_mirror_engine()
    paths = save_history(hist)
    print(f"Mirror engine run complete. Results saved to {paths[0]} and {paths[1]}.")
