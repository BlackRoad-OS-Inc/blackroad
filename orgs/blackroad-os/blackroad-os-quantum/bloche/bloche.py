"""
Bloche - BlackRoad Quantum Engine
Ultra-minimal quantum computing on Raspberry Pi
"""
import numpy as np

class Bloche:
    """Bloche Quantum Engine - Pure quantum simulation"""
    
    def __init__(self, n):
        """n qubits"""
        self.n = n
        self.ψ = np.zeros(2**n, dtype=complex)
        self.ψ[0] = 1  # |0...0⟩
        
    def H(self, q):
        """Hadamard on qubit q"""
        H = np.array([[1,1],[1,-1]]) / np.sqrt(2)
        return self._apply(H, q)
    
    def X(self, q):
        """Pauli X (NOT) on qubit q"""
        X = np.array([[0,1],[1,0]])
        return self._apply(X, q)
    
    def Y(self, q):
        """Pauli Y on qubit q"""
        Y = np.array([[0,-1j],[1j,0]])
        return self._apply(Y, q)
    
    def Z(self, q):
        """Pauli Z (phase) on qubit q"""
        Z = np.array([[1,0],[0,-1]])
        return self._apply(Z, q)
    
    def RX(self, θ, q):
        """Rotate X by θ"""
        RX = np.array([
            [np.cos(θ/2), -1j*np.sin(θ/2)],
            [-1j*np.sin(θ/2), np.cos(θ/2)]
        ])
        return self._apply(RX, q)
    
    def RY(self, θ, q):
        """Rotate Y by θ"""
        RY = np.array([
            [np.cos(θ/2), -np.sin(θ/2)],
            [np.sin(θ/2), np.cos(θ/2)]
        ])
        return self._apply(RY, q)
    
    def RZ(self, θ, q):
        """Rotate Z by θ"""
        RZ = np.array([
            [np.exp(-1j*θ/2), 0],
            [0, np.exp(1j*θ/2)]
        ])
        return self._apply(RZ, q)
    
    def CX(self, c, t):
        """CNOT: control=c, target=t"""
        ψ_new = np.zeros_like(self.ψ)
        for i in range(2**self.n):
            bits = [(i >> j) & 1 for j in range(self.n)]
            if bits[c] == 1:
                bits[t] = 1 - bits[t]
                j = sum(b << k for k, b in enumerate(bits))
                ψ_new[j] += self.ψ[i]
            else:
                ψ_new[i] += self.ψ[i]
        self.ψ = ψ_new
        return self
    
    def measure(self, shots=1000):
        """Measure all qubits"""
        p = np.abs(self.ψ)**2
        results = {}
        for _ in range(shots):
            i = np.random.choice(len(self.ψ), p=p)
            state = format(i, f'0{self.n}b')
            results[state] = results.get(state, 0) + 1
        return results
    
    def _apply(self, gate, q):
        """Apply single-qubit gate to qubit q"""
        G = np.eye(1, dtype=complex)
        for i in range(self.n):
            G = np.kron(G, gate if i == q else np.eye(2))
        self.ψ = G @ self.ψ
        return self
    
    def bloch(self, q=0):
        """Bloch sphere coordinates for qubit q"""
        if self.n > 1:
            # Trace out other qubits (simplified - only works for separable states)
            return None
        α, β = self.ψ[0], self.ψ[1]
        x = 2 * np.real(np.conj(α) * β)
        y = 2 * np.imag(np.conj(α) * β)
        z = np.abs(α)**2 - np.abs(β)**2
        return (x, y, z)
    
    def show(self):
        """Show state vector"""
        print("State vector:")
        for i, amp in enumerate(self.ψ):
            if np.abs(amp) > 1e-10:
                state = format(i, f'0{self.n}b')
                print(f"  |{state}⟩: {amp:.4f}")


# Quick demos
if __name__ == "__main__":
    print("=" * 50)
    print("BLOCHE - BlackRoad Quantum Engine")
    print("=" * 50)
    
    # Bell state (entanglement)
    print("\n1. BELL STATE (Entanglement)")
    b = Bloche(2)
    b.H(0).CX(0, 1)
    b.show()
    r = b.measure(1000)
    for s, c in sorted(r.items()):
        print(f"  |{s}⟩: {c/10:.1f}%")
    
    # Superposition
    print("\n2. SUPERPOSITION")
    b = Bloche(3)
    b.H(0).H(1).H(2)
    r = b.measure(1000)
    for s, c in sorted(r.items()):
        print(f"  |{s}⟩: {c/10:.1f}%")
    
    # Quantum interference
    print("\n3. QUANTUM INTERFERENCE")
    b = Bloche(1)
    b.H(0).Z(0).H(0)
    b.show()
    r = b.measure(1000)
    for s, c in sorted(r.items()):
        print(f"  |{s}⟩: {c/10:.1f}%")
    
    # Bloch sphere
    print("\n4. BLOCH SPHERE")
    b = Bloche(1)
    b.RX(np.pi/4, 0)
    x, y, z = b.bloch()
    print(f"  Position: ({x:.3f}, {y:.3f}, {z:.3f})")
    print(f"  Radius: {np.sqrt(x**2 + y**2 + z**2):.3f}")
    
    # GHZ state (3-qubit entanglement)
    print("\n5. GHZ STATE (3-qubit entanglement)")
    b = Bloche(3)
    b.H(0).CX(0, 1).CX(0, 2)
    b.show()
    r = b.measure(1000)
    for s, c in sorted(r.items(), key=lambda x: -x[1]):
        print(f"  |{s}⟩: {c/10:.1f}%")
    
    print("\n✅ Bloche ready!")
