# RF Spiral Loss Demo

This directory contains a self-contained proof that the spiral pitch estimator
can recover distributed attenuation from a single complex-reflection sweep.

## Sample trace

* `data/spiral_loss_sample.csv` – synthetic one-port reflection sweep that
  mimics a lossy coaxial run.  The vendor datasheet claims a distributed loss of
  **|α| = 2.4 × 10⁻¹⁰** (in the same units produced by the regression, nepers per
  sweep unit).

## Reproducing the fit

```bash
python -m tools.rf.spiral_loss \
  tools/rf/data/spiral_loss_sample.csv \
  --distance frequency_hz \
  --real real --imag imag \
  --vendor-alpha 2.4e-10 \
  --figure figures/rf_spiral_loss.png
```

The CLI prints the estimated pitch, attenuation, and beta.  It also writes a
PNG overlay comparing the measured spiral with the least-squares reconstruction.
The figure is intentionally ignored by Git; regenerate it locally with the
command above.

On the bundled trace the recovered |α| is within 5 % of the datasheet value and
the derived pitch (ĉ = -α/β) is reported alongside the spiralness score.
