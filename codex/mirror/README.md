# Mirror Modules

This directory contains modules and documentation for the mirror mechanics used in Lucidia.

- `mirror_friend_equation.md` — explanation of the mirror friend equation, including the mirror operator \(\Psi'\) and breath operator \(\mathfrak{B}\), the conserved quantity, and perturbation resilience.
- `mirror_mechanics.py` — implementation of the mirror operator and breath operator for harmonic oscillators.
- `number_mirror_mu.py` — implementation of the number‑theoretic mirror based on the Mobius function, including functions to compute mu(n), positive/negative splits, and the Mertens function.
- `quantum_mirror_qi.py` — implementation of the quantum information mirror, including functions to split a qubit into logical and phase components, evolve under unitary dynamics, apply delta‑kicks, compute Bloch coordinates, and measure two‑qubit entanglement via concurrence.
- `README_qi.md` — documentation for the quantum mirror module explaining its purpose, features, and usage.
- `graph_network_mirror.py` — implementation of the graph/network mirror, including functions to split an adjacency matrix into symmetric and antisymmetric components, compute degree distributions, apply breath updates, and introduce delta-kick perturbations to network edges.
- `README_graph_network.md` — documentation for the graph/network mirror module explaining its purpose, features, and usage.
- `thermodynamic_entropy_mirror.py` — implementation of the thermodynamic/entropy mirror, providing functions to split a probability distribution into reversible and irreversible parts, apply the breath operator toward equilibrium, introduce perturbations, and measure entropy changes.
- `README_thermodynamic_entropy.md` — documentation for the thermodynamic/entropy mirror module explaining its purpose, features, and usage.
- `mirror_engine.py` — orchestrates multiple mirror domains, aggregates invariants across physics, quantum, number, network and thermodynamic mirrors, applies adaptive breath control, and logs aggregated history.
- `capability_optimizer.py` — performs a random search over mirror engine parameters to maximise the harmonic mean of reach and stability, and reports top configurations.
