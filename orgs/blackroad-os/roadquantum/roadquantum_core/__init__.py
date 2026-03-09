"""RoadQuantum - Enterprise Quantum Computing Framework.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

A comprehensive quantum computing framework providing:
- Quantum circuit construction and manipulation
- Universal gate set with custom gates
- Quantum algorithms (VQE, QAOA, Grover, Shor)
- Quantum optimization (QAOA, VQE, QUBO)
- Noise models and error mitigation
- Multi-backend simulator support
- Hardware abstraction layer

Architecture:
┌──────────────────────────────────────────────────────────────────────────────┐
│                         RoadQuantum Framework                                 │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐   │
│  │                      Circuit Construction                              │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌───────────────────┐   │   │
│  │  │ Qubit   │───▶│  Gate   │───▶│ Circuit │───▶│  Circuit Compiler │   │   │
│  │  │ Register│    │  Apply  │    │  Build  │    │   (Optimization)  │   │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └───────────────────┘   │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────────────┐  │
│  │  Gate Library  │  │   Algorithms   │  │       Optimization             │  │
│  │                │  │                │  │                                │  │
│  │ - Pauli (X,Y,Z)│  │ - VQE          │  │ - QAOA                         │  │
│  │ - Hadamard     │  │ - QAOA         │  │ - VQE                          │  │
│  │ - Phase (S,T)  │  │ - Grover       │  │ - QUBO Solver                  │  │
│  │ - CNOT, CZ     │  │ - Shor         │  │ - MaxCut                       │  │
│  │ - Rotation     │  │ - QPE          │  │ - Traveling Salesman           │  │
│  │ - Custom       │  │ - QFT          │  │ - Graph Coloring               │  │
│  └────────────────┘  └────────────────┘  └────────────────────────────────┘  │
│                                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────────────┐  │
│  │  Noise Models  │  │   Simulator    │  │    Hardware Backend            │  │
│  │                │  │                │  │                                │  │
│  │ - Depolarizing │  │ - Statevector  │  │ - IBM Quantum                  │  │
│  │ - Bit flip     │  │ - Density Mtx  │  │ - IonQ                         │  │
│  │ - Phase flip   │  │ - Tensor Net   │  │ - Rigetti                      │  │
│  │ - Amplitude    │  │ - MPS          │  │ - Local Simulator              │  │
│  │ - Thermal      │  │ - GPU Accel    │  │ - Cloud Services               │  │
│  └────────────────┘  └────────────────┘  └────────────────────────────────┘  │
│                                                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐   │
│  │                      Measurement & Results                             │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────────────┐  │   │
│  │  │ Measurement │  │ Expectation │  │    Result Analysis            │  │   │
│  │  │  Sampling   │  │   Values    │  │    (Statistics, Plotting)     │  │   │
│  │  └─────────────┘  └─────────────┘  └───────────────────────────────┘  │   │
│  └───────────────────────────────────────────────────────────────────────┘   │
│                                                                               │
└──────────────────────────────────────────────────────────────────────────────┘

Quick Start:
    from roadquantum_core import QuantumCircuit, QuantumRegister

    # Create circuit
    qr = QuantumRegister(2)
    circuit = QuantumCircuit(qr)

    # Apply gates
    circuit.h(0)       # Hadamard on qubit 0
    circuit.cx(0, 1)   # CNOT: control=0, target=1

    # Simulate
    from roadquantum_core.simulator import Simulator
    sim = Simulator()
    result = sim.run(circuit, shots=1000)

    # Get measurement counts
    print(result.get_counts())  # {'00': 500, '11': 500}

Quantum Algorithms:
    from roadquantum_core.algorithms import VQE, QAOA, Grover

    # VQE for chemistry
    vqe = VQE(ansatz, hamiltonian, optimizer)
    result = vqe.run()

    # QAOA for optimization
    qaoa = QAOA(cost_hamiltonian, mixer_hamiltonian, p=3)
    result = qaoa.run()

    # Grover search
    grover = Grover(oracle)
    result = grover.run()
"""

__version__ = "1.0.0"
__author__ = "BlackRoad OS"

from roadquantum_core.circuit.register import QuantumRegister, ClassicalRegister
from roadquantum_core.circuit.circuit import QuantumCircuit
from roadquantum_core.gates.standard import H, X, Y, Z, S, T, CNOT, CZ, SWAP
from roadquantum_core.gates.rotation import RX, RY, RZ, U1, U2, U3

__all__ = [
    "QuantumRegister",
    "ClassicalRegister",
    "QuantumCircuit",
    "H", "X", "Y", "Z", "S", "T",
    "CNOT", "CZ", "SWAP",
    "RX", "RY", "RZ", "U1", "U2", "U3",
]
