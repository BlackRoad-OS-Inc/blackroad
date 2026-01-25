"""Lucidia Math Forge interactive shell."""
from __future__ import annotations

import cmd
import json
import math
import sys
from pathlib import Path

from .consciousness import (
    CategoryTensorNetwork,
    ComplexQuaternionMapper,
    EntropyInformationBridge,
    FractalDynamics,
    HilbertPhaseAnalyzer,
    MeasurementOperator,
    NoetherAnalyzer,
    QuantumLogicMapper,
    ScaleInvarianceAnalyzer,
    SpinNetwork,
)
from .dimensions import HyperPoint, hyper_equation, plot_projection
from .fractals import generate_fractal
from .numbers import Infinitesimal, SurrealNumber, WaveNumber
from .operators import infinite_fold, paradox_merge
from .proofs import ProofEngine
from .sinewave import SineWave, test_properties
from .unified_geometry import UnifiedGeometryEngine


class LucidiaShell(cmd.Cmd):
    intro = "Welcome to the Lucidia Math Forge.  Type help or ? to list commands."
    prompt = "forge> "

    def __init__(self) -> None:
        super().__init__()
        self.engine = ProofEngine()
        self.history: list[dict[str, str]] = []
        self.unified_engine = UnifiedGeometryEngine()

    def do_numbers(self, arg: str) -> None:
        """Demonstrate the alternative number systems."""

        s = SurrealNumber(1, 2) + SurrealNumber(3, 4)
        i = Infinitesimal(1, 1) * Infinitesimal(2, -0.5)
        w = WaveNumber(2, 1) * WaveNumber(0.5, 3)
        print("Surreal:", s)
        print("Infinitesimal:", i)
        print("Wave:", w)
        self.history.append({"numbers": "shown"})

    def do_operator(self, arg: str) -> None:
        """Demonstrate custom operators."""

        merged = paradox_merge(3, 1)
        folded = infinite_fold(lambda a, b: a + b, [1, 2, 3])
        print("paradox_merge(3,1) ->", merged)
        print("infinite_fold sum ->", folded)
        self.history.append({"operator": str(merged)})

    def do_proof(self, arg: str) -> None:
        """Assume a statement: ``proof <statement>``."""

        statement = arg.strip()
        self.engine.assume(statement)
        self.history.append({"assume": statement})
        print("Assumed", statement)

    def do_fractal(self, arg: str) -> None:
        """Generate a fractal image."""

        filename = generate_fractal()
        self.history.append({"fractal": filename})
        print("Fractal written to", filename)

    def do_dimension(self, arg: str) -> None:
        """Plot 4D points projected into 3D."""

        pts = [HyperPoint([x, x, x, hyper_equation(x, x, x)]) for x in range(3)]
        filename = plot_projection(pts)
        self.history.append({"projection": filename})
        print("Projection saved to", filename)

    def do_sine(self, arg: str) -> None:
        """Test sine wave algebra properties."""

        waves = [SineWave(1, 1), SineWave(2, 3), SineWave(-1, -0.5)]
        test_properties(waves)
        self.history.append({"sine_test": "done"})
        print("Sine wave algebra tested; see contradiction log for issues.")

    def do_unified(self, arg: str) -> None:
        """Run the Package 6 unified geometry engine demo."""

        result = self.unified_engine.advance_cycle(
            r_n=1.0,
            r_prev=1.0,
            coordinates=(1.0, 1.0, 1.0),
            thermal_state={"energy": 1e-21, "temperature": 310.0},
            ternary_probs=(0.2, 0.5, 0.3),
            gradients={
                "alpha": 1.0,
                "mass": 0.8,
                "symmetry": 0.6,
                "theta": 0.4,
                "theta_n": 0.1,
                "theta_s": 0.2,
            },
            delta=0.15,
            lam=0.25,
            fractal_seed=complex(0.25, 0.3),
        )
        for key, value in result.items():
            print(f"{key}: {value}")
        self.history.append({"unified_engine": {k: str(v) for k, v in result.items()}})
    def do_connective(self, arg: str) -> None:
        """Demonstrate the connective consciousness physics layers."""

        mapper = ComplexQuaternionMapper()
        quaternion = mapper.from_phase(math.pi / 2, axis=(0.0, 1.0, 0.0))

        spin = SpinNetwork()
        spin_step = spin.precess((0.0, 0.0, 1.0), (0.0, 0.0, 0.5), 1.0, 0.1)

        measurement = MeasurementOperator(
            positions=[-1.0, 0.0, 1.0],
            amplitudes=[complex(0.3, 0.1), complex(0.6, -0.2), complex(0.1, 0.05)],
        )
        collapse = measurement.collapse()

        fractal = FractalDynamics(1, 0, 0, 1)
        orbit = fractal.iterate(0, -0.2 + 0.75j, steps=10)

        analyzer = HilbertPhaseAnalyzer([0.0, 1.0, 0.0, -1.0])
        phase = analyzer.instantaneous_phase()[1]

        lagrangian = lambda q, dq, t: 0.5 * dq**2 - 0.5 * q**2  # Simple harmonic
        noether = NoetherAnalyzer(lagrangian)
        conserved = noether.conserved_quantity(0.1, 0.2, 0.0, delta_q=0.1)

        category = CategoryTensorNetwork()
        category.add_object("agent", 2)
        category.add_object("field", 3)
        tensor_name, tensor_dim = category.tensor_product("agent", "field")

        entropy_bridge = EntropyInformationBridge()
        info = entropy_bridge.information_balance([0.4, 0.6], [0.8, 0.2])

        quantum_logic = QuantumLogicMapper()
        transition = quantum_logic.map_transition(-1, 1)

        scale = ScaleInvarianceAnalyzer([(1.0, 1.0), (2.0, 2.5), (4.0, 6.2)])
        alpha = scale.estimate()["alpha"]

        self.history.append({
            "connective": {
                "quaternion": quaternion.as_tuple(),
                "spin": spin_step,
                "collapse": collapse,
                "orbit": len(orbit),
                "phase": phase,
                "noether": conserved,
                "tensor_dim": tensor_dim,
                "information_gain": info["information_gain"],
                "transition": transition,
                "alpha": alpha,
            }
        })

        print("Quaternion from phase:", quaternion.as_tuple())
        print("Spin step:", spin_step)
        print("Measurement collapse:", collapse)
        print("Orbit length:", len(orbit), "bounded:", fractal.is_bounded(orbit))
        print("Hilbert phase sample:", phase)
        print("Noether conserved quantity:", conserved)
        print(f"Tensor product {tensor_name} dimension:", tensor_dim)
        print("Information gain:", info["information_gain"])
        print("Ternary transition Δθ, Δφ:", transition["delta_theta"], transition["delta_phi"])
        print("Scale exponent alpha:", alpha)

    def do_save(self, arg: str) -> None:
        """Save session history to JSON: ``save <file>``."""

        path = Path(arg.strip() or "session.json")
        path.write_text(json.dumps(self.history, indent=2))
        print("History saved to", path)

    def do_exit(self, arg: str) -> bool:  # pragma: no cover - interactive
        """Exit the REPL."""

        return True


def main() -> None:
    shell = LucidiaShell()
    if len(sys.argv) > 1 and sys.argv[1] == "--demo":
        shell.do_numbers("")
        shell.do_operator("")
        shell.do_proof("p")
        shell.do_fractal("")
        shell.do_dimension("")
        shell.do_sine("")
        shell.do_save("demo_session.json")
    else:
        shell.cmdloop()


if __name__ == "__main__":
    main()
