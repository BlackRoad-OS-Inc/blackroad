# 🤝 Contributing to BlackRoad Quantum

**Help Democratize Quantum Computing**

Thank you for your interest in contributing to BlackRoad Quantum! This document provides guidelines for contributing to the project.

---

## 📋 Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
3. [Development Setup](#development-setup)
4. [Contribution Workflow](#contribution-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing Guidelines](#testing-guidelines)
7. [Documentation](#documentation)
8. [Submitting Changes](#submitting-changes)
9. [Recognition](#recognition)

---

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of:
- Age, body size, disability
- Ethnicity, gender identity
- Experience level
- Education, socio-economic status
- Nationality, personal appearance
- Race, religion, sexual orientation

### Our Standards

**Positive behavior:**
✅ Using welcoming and inclusive language
✅ Being respectful of differing viewpoints
✅ Gracefully accepting constructive criticism
✅ Focusing on what's best for the community
✅ Showing empathy towards others

**Unacceptable behavior:**
❌ Harassment or discriminatory comments
❌ Trolling, insulting, or derogatory comments
❌ Public or private harassment
❌ Publishing others' private information
❌ Other unprofessional conduct

### Enforcement

Violations may be reported to: quantum@blackroad.io

All complaints will be reviewed and investigated promptly and fairly.

---

## How Can I Contribute?

### 🐛 Reporting Bugs

**Before submitting:**
1. Check [existing issues](https://github.com/BlackRoad-OS/blackroad-os-quantum/issues)
2. Verify it's not already fixed in latest version
3. Collect relevant information

**Bug report should include:**
- Clear, descriptive title
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, Python version)
- Code snippet if applicable
- Error messages/stack traces

**Example:**

```markdown
**Bug:** Measurement results incorrect for 10-qubit GHZ state

**Steps to reproduce:**
1. Create 10-qubit quantum computer
2. Apply H to qubit 0
3. Apply CX from 0 to all other qubits
4. Measure with 1000 shots

**Expected:** ~500 |0000000000⟩, ~500 |1111111111⟩
**Actual:** Mixed states including |0101010101⟩

**Environment:**
- OS: macOS 14.0
- Python: 3.11.5
- NumPy: 1.25.2
- BlackRoad Quantum: main branch (commit abc123)

**Code:**
\`\`\`python
qc = BlackRoadQuantum(n_qubits=10)
qc.H(0)
for i in range(1, 10):
    qc.CX(0, i)
results = qc.measure(shots=1000)
\`\`\`
```

### 💡 Suggesting Features

**Before suggesting:**
1. Check if feature already exists
2. Review [roadmap](README.md#-roadmap)
3. Consider if it fits project scope

**Feature request should include:**
- Clear use case
- Proposed API/interface
- Example code showing usage
- Benefits to users
- Implementation considerations

**Example:**

```markdown
**Feature:** Add support for quantum annealing

**Use case:**
Solve optimization problems (TSP, MaxCut) using quantum annealing instead of gate-based circuits.

**Proposed API:**
\`\`\`python
qc = BlackRoadQuantum(n_qubits=10, mode='annealing')
qc.set_hamiltonian(problem_hamiltonian)
qc.anneal(schedule=linear_schedule)
solution = qc.get_ground_state()
\`\`\`

**Benefits:**
- Enables QAOA-style optimization
- Different approach than gate model
- Useful for NP-hard problems

**Implementation:**
- Add AnnealingBackend class
- Implement simulated annealing
- Add schedule parameter support
```

### 📚 Improving Documentation

**Documentation needs:**
- Fix typos/grammar
- Add code examples
- Clarify confusing sections
- Translate to other languages
- Add visual diagrams
- Update outdated information

**Where to contribute:**
- README.md
- TUTORIALS.md
- ADVANCED_TUTORIALS.md
- ALGORITHM_LIBRARY.md
- COURSE_CURRICULUM.md
- API documentation
- Code comments

### 🧮 Adding Algorithms

**Algorithm contributions welcome:**
- Quantum search algorithms
- Optimization algorithms (VQE, QAOA variants)
- Quantum ML models
- Quantum chemistry simulations
- Error correction codes
- Quantum cryptography protocols

**Algorithm submission should include:**
1. Complete implementation
2. Documentation in ALGORITHM_LIBRARY.md
3. Example usage code
4. Performance benchmarks
5. Test cases
6. References to papers/sources

**Example:**

```python
def quantum_walk_search(n_qubits, target):
    """
    Quantum walk search algorithm

    Faster than Grover for certain graph structures.
    Achieves O(√N log N) complexity.

    Args:
        n_qubits: Number of qubits (graph size = 2^n)
        target: Target node to find

    Returns:
        BlackRoadQuantum circuit ready to measure

    References:
        Shenvi, N., Kempe, J., & Whaley, K. B. (2003).
        Quantum random-walk search algorithm.
        Physical Review A, 67(5), 052307.

    Performance:
        4 qubits: 1.2ms
        8 qubits: 15.3ms
        12 qubits: 234ms
    """
    qc = BlackRoadQuantum(n_qubits=n_qubits)

    # Implementation here...

    return qc
```

### 🧪 Adding Experiments

**Experiment contributions:**
- Novel quantum protocols
- Hardware validation tests
- Performance benchmarks
- Comparison studies
- Novel applications

**Experiment should include:**
1. Python script in `experiments/`
2. Clear hypothesis
3. Methodology
4. Results/KPIs
5. Analysis/conclusions
6. Documentation

### 🎨 Adding Visualizations

**Visualization contributions:**
- Interactive web demos
- Circuit diagrams
- State vector plots
- Performance charts
- Educational animations

**Requirements:**
- BlackRoad brand colors
- Responsive design
- Clear labels
- Educational value

---

## Development Setup

### Prerequisites

```bash
# Required
Python 3.8+
NumPy 1.20+
Git

# Recommended
pytest (for testing)
black (for code formatting)
flake8 (for linting)
```

### Setup Steps

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/blackroad-os-quantum
cd blackroad-os-quantum

# 3. Add upstream remote
git remote add upstream https://github.com/BlackRoad-OS/blackroad-os-quantum

# 4. Create virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 5. Install dependencies
pip install numpy pytest black flake8

# 6. Verify installation
python3 -c "from bloche.blackroad_quantum import BlackRoadQuantum; print('✅ Setup complete!')"
```

---

## Contribution Workflow

### 1. Create Feature Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes:
git checkout -b fix/bug-description
```

### 2. Make Changes

- Write code following [coding standards](#coding-standards)
- Add tests for new functionality
- Update documentation
- Commit regularly with clear messages

### 3. Test Changes

```bash
# Run existing tests
pytest

# Run specific test
pytest tests/test_algorithms.py::test_grover

# Test your changes manually
python3 your_script.py
```

### 4. Format Code

```bash
# Format with black
black bloche/ experiments/ tests/

# Check with flake8
flake8 bloche/ experiments/ tests/
```

### 5. Commit Changes

```bash
# Stage changes
git add .

# Commit with descriptive message
git commit -m "Add quantum walk search algorithm

- Implement quantum walk on hypercube
- Add oracle for target marking
- Include diffusion operator
- Add benchmarks for 4-12 qubits
- Document in ALGORITHM_LIBRARY.md
"
```

**Commit message guidelines:**
- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- First line: short summary (50 chars or less)
- Blank line after summary
- Detailed description if needed
- Reference issues: "Fixes #123" or "Related to #456"

### 6. Push to Fork

```bash
git push origin feature/your-feature-name
```

### 7. Create Pull Request

1. Go to your fork on GitHub
2. Click "Pull Request" button
3. Select your feature branch
4. Fill out PR template
5. Submit for review

---

## Coding Standards

### Python Style

**Follow PEP 8:**
- 4 spaces for indentation (not tabs)
- 79 characters max line length
- snake_case for functions/variables
- PascalCase for classes
- UPPER_CASE for constants

**Use type hints:**

```python
def quantum_walk(n_qubits: int, target: int) -> BlackRoadQuantum:
    """Quantum walk search algorithm"""
    qc = BlackRoadQuantum(n_qubits=n_qubits)
    # ...
    return qc
```

**Document functions:**

```python
def grover_search(n_qubits: int, target: int, iterations: int = None) -> BlackRoadQuantum:
    """
    Grover's search algorithm

    Finds target in unsorted database with O(√N) queries.

    Args:
        n_qubits: Number of qubits (database size = 2^n)
        target: Target item to find (0 to 2^n - 1)
        iterations: Number of Grover iterations (default: optimal)

    Returns:
        BlackRoadQuantum circuit ready to measure

    Raises:
        ValueError: If target >= 2^n_qubits

    Example:
        >>> qc = grover_search(n_qubits=4, target=7)
        >>> results = qc.measure(shots=1000)
        >>> max(results, key=results.get)
        '0111'  # Found target!
    """
    if target >= 2**n_qubits:
        raise ValueError(f"Target {target} out of range for {n_qubits} qubits")

    # ... implementation
```

### Code Organization

**Structure:**

```
blackroad-os-quantum/
├── bloche/
│   ├── __init__.py
│   ├── blackroad_quantum.py    # Main class
│   ├── quantum_state.py        # State vector
│   ├── gates.py                # Gate implementations
│   └── algorithms/
│       ├── __init__.py
│       ├── grover.py
│       ├── qaoa.py
│       └── vqe.py
```

**Import order:**

```python
# 1. Standard library
import os
import sys
from typing import List, Optional

# 2. Third-party
import numpy as np

# 3. Local
from bloche.quantum_state import QuantumState
from bloche.gates import hadamard, cnot
```

### Performance

**Optimize for speed:**
- Use NumPy operations (vectorized)
- Avoid Python loops when possible
- Profile before optimizing
- Document complexity: O(n), O(2^n), etc.

**Example:**

```python
# Good (vectorized)
amplitudes = np.exp(1j * angles) / np.sqrt(len(angles))

# Bad (loop)
amplitudes = []
for angle in angles:
    amplitudes.append(np.exp(1j * angle) / np.sqrt(len(angles)))
```

---

## Testing Guidelines

### Writing Tests

**Test structure:**

```python
import pytest
from bloche.blackroad_quantum import BlackRoadQuantum

def test_bell_state_creation():
    """Test Bell state has correct properties"""
    qc = BlackRoadQuantum(n_qubits=2)
    qc.H(0)
    qc.CX(0, 1)

    # Get state vector
    state = qc.state.amplitude

    # Check superposition of |00⟩ and |11⟩
    expected = np.array([1/np.sqrt(2), 0, 0, 1/np.sqrt(2)])
    np.testing.assert_allclose(state, expected, atol=1e-10)

def test_grover_finds_target():
    """Test Grover's algorithm finds correct target"""
    qc = grover_search(n_qubits=4, target=7)
    results = qc.measure(shots=1000)

    # Target should be most common
    most_common = max(results, key=results.get)
    assert most_common == '0111'  # Binary for 7

    # Should have >50% probability
    assert results['0111'] > 500
```

### Test Coverage

**Aim for:**
- Core functionality: 100%
- Algorithms: >90%
- Utilities: >80%

**Run coverage:**

```bash
pytest --cov=bloche --cov-report=html
open htmlcov/index.html
```

---

## Documentation

### Docstring Format

Use Google-style docstrings:

```python
def quantum_fourier_transform(qc: BlackRoadQuantum, n_qubits: int) -> None:
    """
    Apply Quantum Fourier Transform to circuit

    The QFT is the quantum analogue of the discrete Fourier transform.
    It's exponentially faster than classical FFT for certain applications.

    Args:
        qc: Quantum circuit to modify
        n_qubits: Number of qubits to apply QFT to

    Returns:
        None (modifies qc in-place)

    Raises:
        ValueError: If n_qubits > qc.n_qubits

    Example:
        >>> qc = BlackRoadQuantum(n_qubits=8)
        >>> qc.X(0)  # Prepare |00000001⟩
        >>> quantum_fourier_transform(qc, 8)
        >>> # State is now Fourier transformed

    Note:
        Complexity: O(n²) gates
        Circuit depth: O(n²)

    References:
        Nielsen & Chuang, "Quantum Computation and Quantum Information"
        Chapter 5.1
    """
    if n_qubits > qc.n_qubits:
        raise ValueError(f"n_qubits ({n_qubits}) exceeds circuit size ({qc.n_qubits})")

    for j in range(n_qubits):
        qc.H(j)
        for k in range(j + 1, n_qubits):
            angle = np.pi / (2 ** (k - j))
            qc.Rz(k, angle)
```

### Tutorial Writing

**Good tutorial structure:**
1. **Goal:** What will be learned
2. **Prerequisites:** Required knowledge
3. **Theory:** Brief explanation
4. **Code:** Complete working example
5. **Output:** Expected results
6. **Explanation:** Line-by-line walkthrough
7. **Exercise:** Practice problem
8. **Next Steps:** What to learn next

---

## Submitting Changes

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Changes Made
- Added quantum walk search algorithm
- Implemented oracle for marked vertices
- Added tests with 95% coverage
- Documented in ALGORITHM_LIBRARY.md

## Testing
- [ ] Tests pass locally
- [ ] Added new tests
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guide
- [ ] Self-reviewed code
- [ ] Commented complex sections
- [ ] Updated documentation
- [ ] No breaking changes (or documented)

## Related Issues
Fixes #123
Related to #456
```

### Review Process

1. **Automated checks** run (tests, linting)
2. **Maintainer review** (1-3 days)
3. **Feedback addressed**
4. **Approval** from maintainer
5. **Merge** to main branch

### After Merge

- Your contribution is live!
- Added to [Contributors](#recognition) section
- Mentioned in release notes
- Earns contributor badge

---

## Recognition

### Contributors

All contributors are recognized in:
- README.md Contributors section
- Release notes
- CONTRIBUTORS.md file

### Contribution Levels

**Badges earned:**

🌟 **First Contribution** - First merged PR
⚛️ **Quantum Contributor** - 5+ merged PRs
🚀 **Core Contributor** - 20+ merged PRs
👑 **Maintainer** - Ongoing project stewardship

### Hall of Fame

Top contributors featured:
- On project website
- In documentation
- At conferences
- In publications

---

## Questions?

**Need help?**
- 💬 [GitHub Discussions](https://github.com/BlackRoad-OS/blackroad-os-quantum/discussions)
- 📧 Email: quantum@blackroad.io
- 📖 Read: [README.md](README.md)

**Thank you for contributing to democratize quantum computing!** ⚛️

---

*Built with ⚛️ by the BlackRoad Quantum community*
