# Spiral metrics quickstart

This directory collects minimal CLIs around the pitch invariant ``c = d\ln r / d\theta`` so experiments can stay reproducible and scriptable.

## Claims
- `spiral_pitch.py` estimates the logarithmic pitch and spiralness of complex traces.

## Run
```bash
python -m tools.metrics.spiral_pitch samples.csv --real real --imag imag
```

## Good looks like
- Stable pitch estimates across repeated runs (|Δc| < 5e-3).
- Spiralness ≥ 0.85 when the data hugs a clean log spiral.
# Spiral pitch CLI (30-second brief)

Measure how log-spiral a 2D trajectory is right from the shell.

1. Capture your trace as comma-separated `real,imag` samples. Any delimiter works; skip headers with `--skip-rows`.
2. Run the analyser: `python tools/metrics/spiral_pitch.py trace.csv --delimiter ,`.
3. Read the report:
   - `pitch_per_radian` is the growth rate \(c\).
   - `pitch_per_turn` multiplies that by \(2\pi\).
   - `spiralness` \(\in [0,1]\) is 1 minus the normalised MSE.
4. Need the fitted spiral? Add `--reconstruction fit.csv` for `real,imag,magnitude,theta` samples.

Inputs can stream from STDIN (`-`). Column selection flags (`--real-col`, `--imag-col`) unlock multi-column CSVs. Keep zeros out of the trace—the log fit assumes non-zero magnitude.
