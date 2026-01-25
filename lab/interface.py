"""Command line interface for the Lucidia Math Lab."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

from .prime_explorer import PrimeVisualizer, plot_fourier, plot_residue, plot_ulam,
from .prime_explorer import fourier_prime_gaps, residue_grid, ulam_spiral
from .quantum_finance import QuantumFinanceSimulator
from .sine_wave_codex import plot_waves
from .trinary_logic import TrinaryLogicEngine

OUTPUT_DIR = Path("output")


def timestamp() -> str:
    return datetime.utcnow().strftime("%Y%m%d_%H%M%S")


def main() -> None:  # pragma: no cover - interactive
    engine = TrinaryLogicEngine.from_json(Path(__file__).with_name("trinary_operators.json"))
    visualizer = PrimeVisualizer(OUTPUT_DIR)
    finance = QuantumFinanceSimulator(price=100.0, volatility=1.0)

    menu = """
Lucidia Math Lab
-----------------
1. Show trinary logic AND table
2. Plot Ulam spiral
3. Plot residue grid (mod 10)
4. Fourier of prime gaps
5. Plot sine waves
6. Simulate quantum finance step
q. Quit
"""
    while True:
        choice = input(menu).strip()
        if choice == "1":
            print(engine.truth_table_ascii("AND"))
        elif choice == "2":
            grid, mask = ulam_spiral(25)
            fig = plot_ulam(grid, mask)
            visualizer.save_fig(fig, f"ulam_{timestamp()}")
        elif choice == "3":
            grid = residue_grid(10)
            fig = plot_residue(grid)
            visualizer.save_fig(fig, f"residue_{timestamp()}")
        elif choice == "4":
            gaps, fft = fourier_prime_gaps(100)
            fig = plot_fourier(gaps, fft)
            visualizer.save_fig(fig, f"fourier_{timestamp()}")
        elif choice == "5":
            fig = plot_waves([(1, 0, 1), (2, 0, 0.5)])
            visualizer.save_fig(fig, f"waves_{timestamp()}")
        elif choice == "6":
            dist = finance.step()
            price = finance.observe(dist)
            fig = finance.plot(dist)
            visualizer.save_fig(fig, f"finance_{timestamp()}")
            print(f"Collapsed price: {price:.2f}")
        elif choice.lower() == "q":
            break
        else:
            print("Unknown option")


if __name__ == "__main__":
    main()
