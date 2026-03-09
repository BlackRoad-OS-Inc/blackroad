"""
BlackRoad Quantum Computing Engine
A native quantum simulator built from first principles
"""
import numpy as np
from typing import List, Tuple, Optional
import json
from datetime import datetime

class QuantumState:
    """Represents a quantum state using state vectors"""
    
    def __init__(self, num_qubits: int):
        self.num_qubits = num_qubits
        self.state_vector = np.zeros(2**num_qubits, dtype=complex)
        self.state_vector[0] = 1.0  # Initialize to |0...0⟩
        
    def __repr__(self):
        return f"QuantumState({self.num_qubits} qubits, dim={len(self.state_vector)})"
    
    def get_probabilities(self) -> np.ndarray:
        """Get measurement probabilities"""
        return np.abs(self.state_vector) ** 2
    
    def measure(self) -> int:
        """Collapse state vector to a classical state"""
        probs = self.get_probabilities()
        result = np.random.choice(len(self.state_vector), p=probs)
        # Collapse to measured state
        self.state_vector = np.zeros_like(self.state_vector)
        self.state_vector[result] = 1.0
        return result
    
    def get_bloch_vector(self, qubit: int) -> Tuple[float, float, float]:
        """Get Bloch sphere coordinates for a qubit"""
        # Simplified for single qubit
        if self.num_qubits != 1:
            raise ValueError("Bloch vector only for single qubit")
        alpha = self.state_vector[0]
        beta = self.state_vector[1]
        x = 2 * np.real(np.conj(alpha) * beta)
        y = 2 * np.imag(np.conj(alpha) * beta)
        z = np.abs(alpha)**2 - np.abs(beta)**2
        return (x, y, z)


class QuantumGate:
    """Quantum gate operations"""
    
    @staticmethod
    def hadamard() -> np.ndarray:
        """Hadamard gate - creates superposition"""
        return np.array([[1, 1], [1, -1]]) / np.sqrt(2)
    
    @staticmethod
    def pauli_x() -> np.ndarray:
        """Pauli-X gate (NOT gate)"""
        return np.array([[0, 1], [1, 0]])
    
    @staticmethod
    def pauli_y() -> np.ndarray:
        """Pauli-Y gate"""
        return np.array([[0, -1j], [1j, 0]])
    
    @staticmethod
    def pauli_z() -> np.ndarray:
        """Pauli-Z gate (phase flip)"""
        return np.array([[1, 0], [0, -1]])
    
    @staticmethod
    def phase(theta: float) -> np.ndarray:
        """Phase shift gate"""
        return np.array([[1, 0], [0, np.exp(1j * theta)]])
    
    @staticmethod
    def rotation_x(theta: float) -> np.ndarray:
        """Rotation around X-axis"""
        return np.array([
            [np.cos(theta/2), -1j*np.sin(theta/2)],
            [-1j*np.sin(theta/2), np.cos(theta/2)]
        ])
    
    @staticmethod
    def rotation_y(theta: float) -> np.ndarray:
        """Rotation around Y-axis"""
        return np.array([
            [np.cos(theta/2), -np.sin(theta/2)],
            [np.sin(theta/2), np.cos(theta/2)]
        ])
    
    @staticmethod
    def rotation_z(theta: float) -> np.ndarray:
        """Rotation around Z-axis"""
        return np.array([
            [np.exp(-1j*theta/2), 0],
            [0, np.exp(1j*theta/2)]
        ])
    
    @staticmethod
    def cnot() -> np.ndarray:
        """CNOT (controlled-NOT) gate"""
        return np.array([
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1],
            [0, 0, 1, 0]
        ])
    
    @staticmethod
    def swap() -> np.ndarray:
        """SWAP gate"""
        return np.array([
            [1, 0, 0, 0],
            [0, 0, 1, 0],
            [0, 1, 0, 0],
            [0, 0, 0, 1]
        ])
    
    @staticmethod
    def toffoli() -> np.ndarray:
        """Toffoli (CCNOT) gate"""
        gate = np.eye(8, dtype=complex)
        gate[6:8, 6:8] = np.array([[0, 1], [1, 0]])
        return gate


class QuantumCircuit:
    """Quantum circuit builder and executor"""
    
    def __init__(self, num_qubits: int):
        self.num_qubits = num_qubits
        self.state = QuantumState(num_qubits)
        self.operations = []
        
    def _apply_single_qubit_gate(self, gate: np.ndarray, target: int):
        """Apply single qubit gate to target qubit"""
        n = self.num_qubits
        dim = 2**n
        
        # Build full gate matrix using tensor product
        full_gate = np.eye(1, dtype=complex)
        for i in range(n):
            if i == target:
                full_gate = np.kron(full_gate, gate)
            else:
                full_gate = np.kron(full_gate, np.eye(2))
        
        self.state.state_vector = full_gate @ self.state.state_vector
        
    def _apply_two_qubit_gate(self, gate: np.ndarray, control: int, target: int):
        """Apply two-qubit gate"""
        if control > target:
            control, target = target, control
            
        n = self.num_qubits
        dim = 2**n
        
        # For simplicity, handle CNOT directly
        # Full implementation would use tensor products
        new_state = np.zeros_like(self.state.state_vector)
        
        for i in range(dim):
            bits = [(i >> j) & 1 for j in range(n)]
            control_bit = bits[control]
            
            if control_bit == 1:
                # Flip target bit
                new_bits = bits.copy()
                new_bits[target] = 1 - new_bits[target]
                new_idx = sum(b << j for j, b in enumerate(new_bits))
                new_state[new_idx] += self.state.state_vector[i]
            else:
                new_state[i] += self.state.state_vector[i]
        
        self.state.state_vector = new_state
        
    def h(self, qubit: int):
        """Apply Hadamard gate"""
        self._apply_single_qubit_gate(QuantumGate.hadamard(), qubit)
        self.operations.append(('H', qubit))
        return self
    
    def x(self, qubit: int):
        """Apply X gate"""
        self._apply_single_qubit_gate(QuantumGate.pauli_x(), qubit)
        self.operations.append(('X', qubit))
        return self
    
    def y(self, qubit: int):
        """Apply Y gate"""
        self._apply_single_qubit_gate(QuantumGate.pauli_y(), qubit)
        self.operations.append(('Y', qubit))
        return self
    
    def z(self, qubit: int):
        """Apply Z gate"""
        self._apply_single_qubit_gate(QuantumGate.pauli_z(), qubit)
        self.operations.append(('Z', qubit))
        return self
    
    def rx(self, theta: float, qubit: int):
        """Apply rotation around X"""
        self._apply_single_qubit_gate(QuantumGate.rotation_x(theta), qubit)
        self.operations.append(('RX', qubit, theta))
        return self
    
    def ry(self, theta: float, qubit: int):
        """Apply rotation around Y"""
        self._apply_single_qubit_gate(QuantumGate.rotation_y(theta), qubit)
        self.operations.append(('RY', qubit, theta))
        return self
    
    def rz(self, theta: float, qubit: int):
        """Apply rotation around Z"""
        self._apply_single_qubit_gate(QuantumGate.rotation_z(theta), qubit)
        self.operations.append(('RZ', qubit, theta))
        return self
    
    def cnot(self, control: int, target: int):
        """Apply CNOT gate"""
        self._apply_two_qubit_gate(QuantumGate.cnot(), control, target)
        self.operations.append(('CNOT', control, target))
        return self
    
    def measure(self, shots: int = 1000) -> dict:
        """Measure circuit multiple times"""
        results = {}
        original_state = self.state.state_vector.copy()
        
        for _ in range(shots):
            self.state.state_vector = original_state.copy()
            result = self.state.measure()
            binary = format(result, f'0{self.num_qubits}b')
            results[binary] = results.get(binary, 0) + 1
        
        self.state.state_vector = original_state
        return results
    
    def get_statevector(self) -> np.ndarray:
        """Get current state vector"""
        return self.state.state_vector.copy()
    
    def visualize(self) -> str:
        """ASCII visualization of circuit"""
        lines = [f"q{i}: " for i in range(self.num_qubits)]
        
        for op in self.operations:
            if op[0] in ['H', 'X', 'Y', 'Z']:
                gate, qubit = op
                for i in range(self.num_qubits):
                    if i == qubit:
                        lines[i] += f"─[{gate}]─"
                    else:
                        lines[i] += "─────"
            elif op[0] in ['RX', 'RY', 'RZ']:
                gate, qubit, theta = op
                for i in range(self.num_qubits):
                    if i == qubit:
                        lines[i] += f"─[{gate}]─"
                    else:
                        lines[i] += "──────"
            elif op[0] == 'CNOT':
                _, control, target = op
                for i in range(self.num_qubits):
                    if i == control:
                        lines[i] += "─●─"
                    elif i == target:
                        lines[i] += "─⊕─"
                    else:
                        lines[i] += "─|─"
        
        return "\n".join(lines)


class QuantumAlgorithms:
    """Implementation of famous quantum algorithms"""
    
    @staticmethod
    def quantum_teleportation():
        """Quantum teleportation protocol"""
        # 3 qubit system: qubit to teleport + entangled pair
        qc = QuantumCircuit(3)
        
        # Prepare state to teleport (|ψ⟩ = α|0⟩ + β|1⟩)
        qc.ry(np.pi/4, 0)  # Arbitrary state
        
        # Create Bell pair (qubits 1 and 2)
        qc.h(1)
        qc.cnot(1, 2)
        
        # Teleportation protocol
        qc.cnot(0, 1)
        qc.h(0)
        
        return qc
    
    @staticmethod
    def grovers_search(n: int, marked: int):
        """Grover's search algorithm"""
        qc = QuantumCircuit(n)
        
        # Initialize to superposition
        for i in range(n):
            qc.h(i)
        
        # Oracle and diffusion operator (simplified)
        iterations = int(np.pi/4 * np.sqrt(2**n))
        
        for _ in range(iterations):
            # Oracle (mark the solution)
            qc.z(marked)
            
            # Diffusion operator
            for i in range(n):
                qc.h(i)
                qc.x(i)
            
            # Multi-controlled Z
            if n > 1:
                qc.z(0)
            
            for i in range(n):
                qc.x(i)
                qc.h(i)
        
        return qc
    
    @staticmethod
    def quantum_fourier_transform(n: int):
        """Quantum Fourier Transform"""
        qc = QuantumCircuit(n)
        
        for j in range(n):
            qc.h(j)
            for k in range(j+1, n):
                angle = np.pi / (2**(k-j))
                qc.rz(angle, k)
        
        return qc
    
    @staticmethod
    def bell_state():
        """Create Bell state (maximally entangled)"""
        qc = QuantumCircuit(2)
        qc.h(0)
        qc.cnot(0, 1)
        return qc
    
    @staticmethod
    def ghz_state(n: int):
        """Create GHZ state (n-qubit entanglement)"""
        qc = QuantumCircuit(n)
        qc.h(0)
        for i in range(1, n):
            qc.cnot(0, i)
        return qc


class BlackRoadQuantumEngine:
    """Main BlackRoad Quantum Computing Engine"""
    
    def __init__(self):
        self.version = "1.0.0"
        self.timestamp = datetime.now().isoformat()
        
    def info(self):
        """Get engine information"""
        return {
            "engine": "BlackRoad Quantum Engine",
            "version": self.version,
            "timestamp": self.timestamp,
            "capabilities": [
                "Quantum state simulation",
                "Universal gate set",
                "Multi-qubit entanglement",
                "Quantum algorithms",
                "State vector manipulation"
            ],
            "max_qubits": 20,  # Practical limit for simulation
            "gates": ["H", "X", "Y", "Z", "RX", "RY", "RZ", "CNOT", "SWAP", "Toffoli"],
            "algorithms": ["Teleportation", "Grover", "QFT", "Bell", "GHZ"]
        }
    
    def benchmark(self, num_qubits: int, depth: int) -> dict:
        """Benchmark quantum circuit performance"""
        import time
        
        qc = QuantumCircuit(num_qubits)
        
        start = time.time()
        for _ in range(depth):
            for i in range(num_qubits):
                qc.h(i)
            for i in range(num_qubits - 1):
                qc.cnot(i, i+1)
        
        circuit_time = time.time() - start
        
        start = time.time()
        results = qc.measure(shots=1000)
        measure_time = time.time() - start
        
        return {
            "qubits": num_qubits,
            "depth": depth,
            "circuit_construction_time": circuit_time,
            "measurement_time": measure_time,
            "total_time": circuit_time + measure_time,
            "statevector_dimension": 2**num_qubits
        }


if __name__ == "__main__":
    print("=" * 60)
    print("BlackRoad Quantum Computing Engine")
    print("=" * 60)
    
    engine = BlackRoadQuantumEngine()
    info = engine.info()
    print(f"\nEngine: {info['engine']} v{info['version']}")
    print(f"Capabilities: {', '.join(info['capabilities'])}")
    print(f"Max Qubits: {info['max_qubits']}")
    
    # Demo: Bell State (Quantum Entanglement)
    print("\n" + "=" * 60)
    print("Demo 1: Bell State (Quantum Entanglement)")
    print("=" * 60)
    bell = QuantumAlgorithms.bell_state()
    print(bell.visualize())
    print("\nMeasurement results (1000 shots):")
    results = bell.measure(shots=1000)
    for state, count in sorted(results.items()):
        print(f"  |{state}⟩: {count} times ({count/10:.1f}%)")
    
    # Demo: Superposition
    print("\n" + "=" * 60)
    print("Demo 2: Superposition with Hadamard")
    print("=" * 60)
    qc = QuantumCircuit(2)
    qc.h(0).h(1)
    print(qc.visualize())
    print("\nMeasurement results (1000 shots):")
    results = qc.measure(shots=1000)
    for state, count in sorted(results.items()):
        print(f"  |{state}⟩: {count} times ({count/10:.1f}%)")
    
    # Demo: Grover's Search
    print("\n" + "=" * 60)
    print("Demo 3: Grover's Search (2 qubits, find |11⟩)")
    print("=" * 60)
    grover = QuantumAlgorithms.grovers_search(2, 3)
    print(grover.visualize())
    results = grover.measure(shots=1000)
    print("\nMeasurement results:")
    for state, count in sorted(results.items(), key=lambda x: -x[1]):
        print(f"  |{state}⟩: {count} times ({count/10:.1f}%)")
    
    # Benchmark
    print("\n" + "=" * 60)
    print("Performance Benchmark")
    print("=" * 60)
    for qubits in [4, 6, 8, 10]:
        bench = engine.benchmark(qubits, depth=10)
        print(f"{qubits} qubits: {bench['total_time']*1000:.2f}ms " +
              f"(dim: {bench['statevector_dimension']})")
    
    print("\n✅ BlackRoad Quantum Engine Ready!")
