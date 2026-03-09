# 🌱 BlackRoad Soil Analytics

[![CI](https://github.com/BlackRoad-OS/blackroad-soil-analytics/actions/workflows/ci.yml/badge.svg)](https://github.com/BlackRoad-OS/blackroad-soil-analytics/actions/workflows/ci.yml)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/)
[![License: Proprietary](https://img.shields.io/badge/license-Proprietary-red.svg)](https://blackroad.io)

> Scientific soil analysis engine implementing real pedology algorithms — CEC, pH buffering, NPK ratios, Liebig yield modelling, and Langelier water quality indexing.

---

## Scientific Background

Soil health is determined by the interplay of chemistry, physics, and biology.
This module quantifies four primary dimensions:

### 1. Cation Exchange Capacity (CEC)

CEC represents the soil's ability to retain exchangeable cations (Ca²⁺, Mg²⁺, K⁺, Na⁺, H⁺, Al³⁺) and is the foundation of nutrient management.

```
CEC [cmol(+)/kg] = Σ exchangeable cations
                 + OM_pct × 2.0 × (1 + 0.05 × (pH − 6.0))
```

| Soil Class    | Typical CEC (cmol/kg) |
|---------------|----------------------|
| Sandy         | 2 – 10               |
| Loam          | 10 – 20              |
| Clay loam     | 20 – 35              |
| Clay          | 35 – 50              |
| Organic       | 50 – 100+            |

*Source: Brady & Weil, "The Nature and Properties of Soils", 15th Ed.*

---

### 2. pH Buffer Capacity (β)

β quantifies how much acid or base is required to shift soil pH by one unit.

```
β [mmol H⁺ kg⁻¹ (ΔpH)⁻¹] = (OM_pct × 12.5 + clay_pct × 0.8) × f_carbonate

f_carbonate = 1 + 0.4 × max(0, pH − 6.5)   (CaCO₃ dissolution above pH 6.5)
```

*Reference: Curtin & Trolove (2013), Soil Use Mgmt 29, 390-399.*

---

### 3. NPK Ratio

Normalised fraction of primary macronutrients:

```
(N_frac, P_frac, K_frac) = (N, P, K) / (N + P + K)
```

Nutrient mobility is pH-dependent:
- **P**: maximum at pH 6.5–7.5; drops ~8%/unit below, ~10%/unit above
- **N (NO₃⁻)**: broad range; nitrification inhibited below pH 5.5
- **K⁺**: reduced by Al³⁺ competition below pH 5.0 and cation exchange above pH 8.0

---

### 4. Yield Prediction — Liebig's Law of the Minimum

```
Y_predicted = Y_max × min(f_pH, f_N, f_P, f_K) × f_moisture

f_X = (C_X × mobility_X) / C_optimal_X   (capped at 1.0)
f_pH = 1.0 inside crop range; decreases 30%/unit outside
f_moisture = θv / θ_optimal; reduced under drought or waterlogging
```

*Reference: de Wit (1965) CABO Wageningen; Paris (1992) Am. J. Agric. Econ.*

---

### 5. Soil Health Index (SHI)

Composite score ∈ [0, 100]:

```
SHI = 0.20·s_pH + 0.20·s_OM + 0.15·s_N + 0.10·s_P + 0.10·s_K
    + 0.10·s_CEC + 0.10·s_moisture + 0.05·s_microbial

s_pH = 100 × exp(−½ × ((pH − 6.5)/0.8)²)   (Gaussian, μ=6.5, σ=0.8)
```

---

### 6. Langelier Saturation Index (LSI)

Water quality indicator for soil pore water:

```
LSI = pH_actual − pH_sat

pH_sat = (9.3 + A + B) − (C + D)
  A = log₁₀(TDS) / 10 − 1
  B = −13.12 × log₁₀(T + 273.15) + 34.55
  C = log₁₀(Ca hardness as CaCO₃) − 0.4
  D = log₁₀(M-alkalinity as CaCO₃)
```

LSI > 0 → scaling; LSI < 0 → corrosive; LSI = 0 → equilibrium.

*Reference: Langelier, W.F. (1936) AWWA 28:1500-1521.*

---

### 7. Gravimetric & Volumetric Moisture

```
θg [%]        = (W_wet − W_dry) / W_dry × 100        (gravimetric)
θv [cm³/cm³]  = θg × ρb / 100                         (ρb = bulk density)
n  [−]        = 1 − ρb / 2.65                          (total porosity; ρp = 2.65)
Sr [−]        = θv / n                                  (relative saturation)
PAWC          = (θv_FC − θv_WP)                        (plant available water)
```

*Reference: Hillel, "Introduction to Environmental Soil Physics" (2003).*

---

## Installation

```bash
git clone https://github.com/BlackRoad-OS/blackroad-soil-analytics
cd blackroad-soil-analytics
pip install pytest pytest-cov   # for testing only; no runtime deps beyond stdlib
```

---

## Usage

```bash
# Full soil analysis with ASCII charts and computed indices
python src/soil.py analyze

# Predict wheat yield
python src/soil.py predict --crop wheat

# Generate lime + fertiliser remediation plan
python src/soil.py remediate --crop corn

# Store sample to SQLite (~/.blackroad/soil_analytics.db)
python src/soil.py add-sample --id FIELD-042

# List stored samples
python src/soil.py list

# Export full JSON report
python src/soil.py report --output my_field_report.json
```

### Example Output

```
══════════════════════════════════════════════════════════
  Soil Sample  :  DEMO-001
══════════════════════════════════════════════════════════
  Location     : Field A, Sector 3
  pH           : 6.20 (optimal range)
  Org. Matter  : 2.80%
  Texture      : loam

━━━ Nutrient Profile (with pH mobility adjustment) ━━━
  N  (ppm) ████████████░░░░░░░░░░░░░░░░░░    55.0  mob=1.00
  P  (ppm) █████████░░░░░░░░░░░░░░░░░░░░░    28.0  mob=0.94
  K  (ppm) █████████░░░░░░░░░░░░░░░░░░░░░   180.0  mob=1.00

━━━ Computed Soil Indices ━━━
  CEC             : 23.87 cmol(+)/kg
  pH Buffer β     : 55.00 mmol H⁺/kg/ΔpH
  LSI (pore water): +0.142  [scaling]
  N:P:K ratio     : 0.213 : 0.108 : 0.699

━━━ Soil Health Index (SHI) ━━━
  pH           ████████████████████  93.2/100
  OM           ████████████░░░░░░░░  56.0/100
  SHI          ███████████████░░░░░  74.3/100
```

---

## Running Tests

```bash
pytest tests/ -v
pytest tests/ --cov=src --cov-report=term-missing
```

---

## Project Structure

```
blackroad-soil-analytics/
├── src/
│   └── soil.py          # Core analytics engine (870+ lines)
├── tests/
│   └── test_soil.py     # 35+ unit tests across 8 test classes
├── .github/
│   └── workflows/
│       └── ci.yml       # CI: Python 3.11, pytest + coverage
└── README.md
```

---

## Data Persistence

All samples are stored in `~/.blackroad/soil_analytics.db` (SQLite).
The schema is self-initialising on first run.

---

## Scientific References

1. Brady, N.C. & Weil, R.R. (2016). *The Nature and Properties of Soils*, 15th Ed. Pearson.
2. FAO (2006). *Guidelines for Soil Description*, 4th Ed. Rome.
3. USDA (2017). *Soil Survey Manual*. Handbook No. 18.
4. Langelier, W.F. (1936). The analytical control of anti-corrosion water treatment. *AWWA* 28:1500-1521.
5. Curtin, D. & Trolove, S. (2013). Predicting pH buffering capacity of New Zealand soils. *Soil Use Mgmt* 29, 390-399.
6. Hillel, D. (2003). *Introduction to Environmental Soil Physics*. Academic Press.
7. de Wit, C.T. (1965). *Photosynthesis of Leaf Canopies*. CABO, Wageningen.

---

© BlackRoad OS, Inc. All rights reserved. Proprietary — not open source.
