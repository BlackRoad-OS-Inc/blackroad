"""Gate tests."""
import numpy as np
from roadquantum_core.gates.standard import HGate, XGate, CXGate

def test_hadamard():
    h = HGate()
    m = h.to_matrix()
    assert np.allclose(m @ m, np.eye(2))

def test_pauli_x():
    x = XGate()
    m = x.to_matrix()
    assert np.allclose(m @ m, np.eye(2))
