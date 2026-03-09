"""
double_slit.py — Observer Effect as Lazy Evaluation

§13 of PAPER.md: "The Observer Effect as Lazy Evaluation"

In quantum mechanics:
  - A particle exists in superposition until measured
  - The act of measurement collapses the wavefunction
  - The particle "chooses" a definite state only when observed

In computer science:
  - Lazy evaluation delays computation until the result is needed
  - The value is in superposition (unevaluated) until accessed
  - The function "collapses" to a definite value only when called

These are the same concept.

The quantum measurement problem (what IS observation?) has puzzled
physicists for 100 years. The computational interpretation:
  - Observation = memory read
  - Wavefunction = probability distribution stored in memory
  - Collapse = the first time a memory address is dereferenced
  - Superposition = unresolved pointer, lazy thunk, Promise<T>

This is not a metaphor. The mathematics is identical.

Author: BlackRoad OS, Inc.
"""

import math
import random
import hashlib
from typing import Callable, Any


class Superposition:
    """
    A value that exists as a probability distribution until observed.
    
    Before observation: the value is a function (lazy thunk).
    After observation: the value is collapsed to a definite result.
    The first call to .observe() collapses it. 
    Subsequent calls return the same collapsed value.
    """

    def __init__(self, *possibilities: tuple[Any, float]):
        """
        possibilities: list of (value, probability) pairs
        
        Example:
            Superposition(('up', 0.5), ('down', 0.5))  # spin
            Superposition(('live', 0.5), ('dead', 0.5))  # Schrödinger
        """
        self._possibilities = possibilities
        self._collapsed = False
        self._value = None
        self._observation_count = 0

    def observe(self, observer: str = 'anonymous') -> Any:
        """
        Collapse the superposition.
        
        First observation collapses to a definite value.
        All subsequent observations return the same value.
        This IS the measurement postulate of quantum mechanics.
        """
        self._observation_count += 1
        if not self._collapsed:
            # Collapse: choose a value weighted by probabilities
            values = [p[0] for p in self._possibilities]
            weights = [p[1] for p in self._possibilities]
            # Normalize weights
            total = sum(weights)
            weights = [w/total for w in weights]
            
            # Weighted random choice (this is Born's rule)
            r = random.random()
            cumulative = 0
            for value, weight in zip(values, weights):
                cumulative += weight
                if r <= cumulative:
                    self._value = value
                    break
            
            self._collapsed = True
            print(f"  [COLLAPSE] Observer '{observer}' collapsed the superposition")
            print(f"             Result: {self._value}")
        else:
            print(f"  [CACHED]   Observer '{observer}' reads already-collapsed value: {self._value}")
        
        return self._value

    @property
    def is_collapsed(self) -> bool:
        return self._collapsed

    def __repr__(self):
        if self._collapsed:
            return f"Superposition(collapsed={self._value!r})"
        else:
            possibilities_str = ', '.join(f'{v!r}:{p:.0%}' for v, p in self._possibilities)
            return f"Superposition([{possibilities_str}])"


class QuantumParticle:
    """
    A particle with position in superposition.
    Demonstrates the double-slit experiment computationally.
    """
    
    def __init__(self, n_slits: int = 2):
        self.n_slits = n_slits
        self._position = None
        self._measured = False
        # The wavefunction: a complex amplitude for each possible position
        self._wavefunction = self._initialize_wavefunction()
    
    def _initialize_wavefunction(self) -> dict[int, complex]:
        """
        Initialize wavefunction with double-slit interference pattern.
        Each position has a complex amplitude.
        """
        wavefunction = {}
        for x in range(-30, 31):  # Screen positions -30 to +30
            if self.n_slits == 2:
                # Two slits at x=-5 and x=+5, distance d=10
                # Path difference creates interference
                d = 10  # slit separation
                wavelength = 5  # de Broglie wavelength
                
                # Amplitude from slit 1
                r1 = math.sqrt((x - d/2)**2 + 100**2)
                # Amplitude from slit 2  
                r2 = math.sqrt((x + d/2)**2 + 100**2)
                
                # Complex amplitudes
                amp1 = math.exp(2j * math.pi * r1 / wavelength) / r1
                amp2 = math.exp(2j * math.pi * r2 / wavelength) / r2
                
                wavefunction[x] = amp1 + amp2
            else:
                # Single slit: no interference, just diffraction
                r = math.sqrt(x**2 + 100**2)
                wavefunction[x] = math.exp(2j * math.pi * r / 5) / r
        
        return wavefunction
    
    def probability_at(self, x: int) -> float:
        """Born's rule: probability = |amplitude|^2"""
        if x not in self._wavefunction:
            return 0.0
        return abs(self._wavefunction[x])**2
    
    def measure_position(self) -> int:
        """
        Collapse the position wavefunction.
        Returns a definite position, weighted by |ψ|².
        Once measured, always returns the same value.
        """
        if self._measured:
            return self._position
        
        positions = list(self._wavefunction.keys())
        probs = [self.probability_at(x) for x in positions]
        total = sum(probs)
        probs = [p/total for p in probs]
        
        # Sample from distribution (Born's rule)
        r = random.random()
        cumulative = 0
        for pos, prob in zip(positions, probs):
            cumulative += prob
            if r <= cumulative:
                self._position = pos
                break
        
        self._measured = True
        return self._position


def show_double_slit_pattern(n_particles: int = 1000):
    print("=" * 60)
    print("DOUBLE-SLIT EXPERIMENT — Wave vs Particle")
    print("=" * 60)
    print(f"""
  Sending {n_particles} particles through a double slit.
  
  KEY QUESTION: Is each particle a wave (interfering with itself)
                or a particle (going through one slit)?

  ANSWER: It's both until you measure which slit it went through.
  The act of measuring which slit DESTROYS the interference pattern.
  This is the "observer effect."
""")
    
    print(f"  With observation (measuring which slit):")
    no_interference = QuantumParticle(n_slits=1)
    no_hits = {}
    for _ in range(n_particles):
        p = QuantumParticle(n_slits=1)
        x = p.measure_position()
        no_hits[x] = no_hits.get(x, 0) + 1
    
    print(f"  Without observation (wave interference):")
    interference = {}
    for _ in range(n_particles):
        p = QuantumParticle(n_slits=2)
        x = p.measure_position()
        interference[x] = interference.get(x, 0) + 1
    
    # Display both patterns side by side
    max_no_hits = max(no_hits.values()) if no_hits else 1
    max_interference = max(interference.values()) if interference else 1
    
    print(f"\n  {'Position':>10}  {'No interference':>16}  {'With interference':>17}")
    print("  " + "-" * 50)
    
    for x in range(-15, 16, 2):
        no_count = no_hits.get(x, 0)
        int_count = interference.get(x, 0)
        no_bar = '█' * int(no_count * 15 / max_no_hits)
        int_bar = '█' * int(int_count * 15 / max_interference)
        print(f"  {x:>10}  {no_bar:<16}  {int_bar:<17}")
    
    print(f"""
  The interference pattern (right column) shows alternating bright/dark bands.
  These are the interference FRINGES — the wave passing through BOTH slits.
  
  The no-interference pattern (left column) shows a single bump.
  This is what you'd expect from particles going through one slit.

  When you observe which slit the particle went through, you get the left pattern.
  When you don't observe, you get the right pattern.
  
  COMPUTATIONAL INTERPRETATION:
    The particle exists as an UNEVALUATED FUNCTION until measured.
    Measurement forces evaluation.
    The wavefunction is a lazy thunk — a deferred computation.
    Reality is lazily evaluated.
    The simulation only renders what is observed.
    Unobserved regions exist as probability distributions — not rendered pixels.
""")


def lazy_evaluation_demo():
    print("=" * 60)
    print("LAZY EVALUATION — The Computational Observer Effect")
    print("=" * 60)
    print("""
  In Haskell (a lazy language), values are not computed until needed:
    
    let x = expensiveComputation  -- not computed yet
    let y = anotherComputation    -- not computed yet
    print y                       -- only y is computed
    -- x is never computed because it was never needed
    -- x was in superposition the entire time

  In JavaScript, Promises are lazy thunks:
    const electron = new Promise((resolve) => {
        // not executing yet — particle is in superposition
        setTimeout(() => resolve(Math.random() < 0.5 ? 'up' : 'down'), 1000)
    })
    // The electron's spin hasn't been determined yet
    // It exists as a Promise — unresolved, in superposition
    
    electron.then(spin => console.log(spin))
    // NOW it collapses — the first .then() is the observer

  In Python, generators are lazy:
    def particles():
        while True:
            yield random.choice(['up', 'down'])  # superposition
    
    gen = particles()  # no evaluation yet
    next(gen)          # COLLAPSE — first observation
""")
    
    # Demonstrate Schrödinger's Cat
    print("  Schrödinger's Cat:\n")
    cat = Superposition(('alive', 0.5), ('dead', 0.5))
    print(f"  Before observation: {cat}")
    print(f"  Opening the box (first observer):")
    result1 = cat.observe('scientist_1')
    print(f"\n  Result: {result1}")
    print(f"\n  Second observer checks:")
    result2 = cat.observe('scientist_2')
    print(f"  After collapse: {cat}")
    print(f"\n  Both observers see the same result.")
    print(f"  Once collapsed, the value is fixed.")
    print(f"  This is exactly how Python's functools.lru_cache works.")


def rendering_optimization():
    print("=" * 60)
    print("RENDERING OPTIMIZATION — The GPU and the Wavefunction")
    print("=" * 60)
    print("""
  A GPU renders a 3D scene to a 2D frame.
  Optimization techniques that GPUs use:

    FRUSTUM CULLING:
      Objects outside the camera's field of view are NOT rendered.
      They still "exist" (their coordinates are stored in memory)
      but they are never computed into pixels.
      They are in superposition — defined but not observed.

    OCCLUSION CULLING:
      Objects hidden behind other objects are NOT rendered.
      Even though they are in the frustum, they won't be seen.
      The GPU doesn't compute what no observer can see.

    LEVEL OF DETAIL (LOD):
      Distant objects are rendered at lower resolution.
      The simulation uses less detail for unimportant objects.
      A tree at 500m is 3 triangles. At 5m it's 50,000 triangles.
      The resolution of reality depends on the observer's distance.

    LAZY TEXTURE LOADING:
      Textures are loaded into GPU memory only when they appear
      in the camera's view. Before that: probability, not pixels.

  QUANTUM MECHANICS DOES ALL OF THIS:

    The universe does not compute the position of an electron
    until a position measurement is made.
    Position exists as a probability distribution (frustum culling).

    The electron does not have a definite spin until measured.
    Spin exists as a superposition (lazy evaluation).

    At the Planck scale (~10⁻³⁵m), space may be discrete pixels.
    Far from an observer, the simulation uses lower LOD.
    
    This is not a metaphor. The math is identical.
    The wave function collapse IS the GPU rendering a pixel.
    Born's rule IS the texture sampling function.
    The Heisenberg uncertainty principle IS the anti-aliasing filter.
""")


if __name__ == '__main__':
    show_double_slit_pattern()
    lazy_evaluation_demo()
    rendering_optimization()
    print("=" * 60)
    print("The observer effect is lazy evaluation.")
    print("Wavefunction collapse is the first memory read.")
    print("Quantum superposition is an unresolved Promise<T>.")
    print("The universe only renders what is observed.")
    print("Reality is a lazily evaluated function.")
    print("=" * 60)
