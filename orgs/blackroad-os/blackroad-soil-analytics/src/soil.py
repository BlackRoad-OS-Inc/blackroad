#!/usr/bin/env python3
"""
BlackRoad Soil Analytics Engine
================================
Scientific soil analysis module implementing real pedology algorithms.

References:
  - Brady & Weil, "The Nature and Properties of Soils", 15th Ed.
  - USDA Soil Survey Manual (2017)
  - FAO Guidelines for Soil Description, 4th Ed. (2006)
  - Curtin & Trolove (2013), Soil Use Mgmt 29, 390-399.
  - Langelier, W.F. (1936), AWWA Journal 28, 1500-1521.
"""

from __future__ import annotations

import argparse
import json
import math
import sqlite3
import sys
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional

# ─── ANSI Colours ─────────────────────────────────────────────────────────────
GREEN  = "\033[0;32m"
RED    = "\033[0;31m"
YELLOW = "\033[1;33m"
CYAN   = "\033[0;36m"
BLUE   = "\033[0;34m"
MAGENTA= "\033[0;35m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

# ─── Scientific Constants ──────────────────────────────────────────────────────

# Optimal pH ranges per crop type  (min_pH, max_pH)
CROP_PH_RANGES: dict[str, tuple[float, float]] = {
    "wheat":     (6.0, 7.0),
    "corn":      (5.8, 7.0),
    "soybean":   (6.0, 7.0),
    "rice":      (5.5, 6.5),
    "potato":    (5.0, 6.5),
    "tomato":    (5.5, 7.0),
    "alfalfa":   (6.5, 7.5),
    "cotton":    (5.8, 7.0),
    "blueberry": (4.5, 5.5),
    "sugarcane": (5.5, 6.5),
    "barley":    (6.0, 7.5),
    "oats":      (5.5, 7.0),
    "sunflower": (6.0, 7.5),
    "canola":    (5.5, 7.0),
}

# Nutrient concentration thresholds  (mg/kg = ppm)
NUTRIENT_THRESHOLDS: dict[str, dict[str, float]] = {
    "N":  {"deficient": 20,  "low": 40,   "optimal": 80,   "high": 150,  "excessive": 250},
    "P":  {"deficient": 10,  "low": 20,   "optimal": 40,   "high": 80,   "excessive": 150},
    "K":  {"deficient": 80,  "low": 120,  "optimal": 200,  "high": 350,  "excessive": 600},
    "Ca": {"deficient": 500, "low": 1000, "optimal": 2000, "high": 4000, "excessive": 8000},
    "Mg": {"deficient": 50,  "low": 100,  "optimal": 200,  "high": 400,  "excessive": 800},
    "S":  {"deficient": 10,  "low": 15,   "optimal": 30,   "high": 60,   "excessive": 120},
}

# Lime requirement kg CaCO3 / ha per 0.1 pH unit increase, by texture class
LIME_REQUIREMENT: dict[str, float] = {
    "sandy":    500.0,
    "loam":     1500.0,
    "clay_loam":2500.0,
    "clay":     3500.0,
}

# Nutrient mobility as a function of soil pH
# ─────────────────────────────────────────────────────────────────────────────
def _p_mobility_factor(ph: float) -> float:
    """Phosphorus availability peaks at pH 6.5-7.5; drops ~8%/unit below, ~10%/unit above."""
    if 6.5 <= ph <= 7.5:
        return 1.0
    if ph < 6.5:
        return max(0.05, 1.0 - 0.08 * (6.5 - ph))
    return max(0.05, 1.0 - 0.10 * (ph - 7.5))


def _n_mobility_factor(ph: float) -> float:
    """Nitrate mobility is broad; nitrification inhibited below pH 5.5."""
    if ph < 5.5:
        return max(0.3, 0.5 + 0.09 * (ph - 4.0))
    return 1.0


def _k_mobility_factor(ph: float) -> float:
    """K⁺ availability reduced below pH 5.0 (Al competition) and above pH 8.0."""
    if ph < 5.0:
        return max(0.5, 0.6 + 0.04 * (ph - 4.0))
    if ph > 8.0:
        return max(0.6, 0.75 + 0.05 * (8.0 - ph))
    return 1.0


# ─── Data Classes ─────────────────────────────────────────────────────────────

@dataclass
class NutrientProfile:
    """Macro- and micro-nutrient concentrations plus exchangeable cation pool."""
    nitrogen_ppm:   float          # N   (mg/kg)
    phosphorus_ppm: float          # P   (mg/kg)
    potassium_ppm:  float          # K   (mg/kg)
    calcium_ppm:    float = 1500.0 # Ca  (mg/kg)
    magnesium_ppm:  float = 150.0  # Mg  (mg/kg)
    sulfur_ppm:     float = 20.0   # S   (mg/kg)
    # Exchangeable cations for CEC determination  (cmol(+)/kg)
    exch_ca:  float = 8.0   # Ca²⁺
    exch_mg:  float = 2.0   # Mg²⁺
    exch_k:   float = 0.5   # K⁺
    exch_na:  float = 0.2   # Na⁺
    exch_h:   float = 1.5   # H⁺  (exchangeable acidity)
    exch_al:  float = 0.3   # Al³⁺ (toxic at low pH)


@dataclass
class MoistureReading:
    """Gravimetric and volumetric moisture parameters."""
    wet_weight_g:   float          # Moist soil mass (g)
    dry_weight_g:   float          # Oven-dry soil mass (105 °C, 24 h)  (g)
    field_capacity: float = 30.0   # Volumetric % at field capacity  (−33 kPa)
    wilting_point:  float = 12.0   # Volumetric % at permanent wilting point (−1500 kPa)
    bulk_density:   float = 1.3    # Dry bulk density  (g/cm³)


@dataclass
class SoilSample:
    """Complete soil sample descriptor."""
    sample_id:       str
    location:        str
    collection_date: str
    ph:              float
    organic_matter:  float        # Weight percent (%)
    texture:         str          # sandy | loam | clay_loam | clay
    nutrients:       NutrientProfile
    moisture:        MoistureReading
    depth_cm:        float = 20.0
    temperature_c:   float = 20.0
    notes:           str   = ""


@dataclass
class CropYieldPrediction:
    """Liebig's Law of Minimum based yield forecast."""
    crop:                  str
    predicted_yield_t_ha:  float
    yield_limiting_factor: str
    confidence_pct:        float
    nutrient_sufficiency:  dict   # {N, P, K} → 0-1
    ph_suitability:        float  # 0-1


@dataclass
class RemediationPlan:
    """Actionable soil improvement recommendations."""
    sample_id:             str
    issues:                list
    lime_kg_ha:            float
    n_fertiliser_kg:       float
    p_fertiliser_kg:       float
    k_fertiliser_kg:       float
    organic_amendment_t_ha:float
    priority:              str    # critical | high | medium | low
    estimated_cost_usd:    float
    notes:                 list


# ─── SQLite Persistence ────────────────────────────────────────────────────────

DB_PATH = Path.home() / ".blackroad" / "soil_analytics.db"


def _get_connection(db_path: Path = DB_PATH) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    _init_schema(conn)
    return conn


def _init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript("""
    CREATE TABLE IF NOT EXISTS soil_samples (
        sample_id       TEXT PRIMARY KEY,
        location        TEXT,
        collection_date TEXT,
        ph              REAL,
        organic_matter  REAL,
        texture         TEXT,
        depth_cm        REAL,
        temperature_c   REAL,
        notes           TEXT,
        n_ppm  REAL, p_ppm  REAL, k_ppm  REAL,
        ca_ppm REAL, mg_ppm REAL, s_ppm  REAL,
        exch_ca REAL, exch_mg REAL, exch_k REAL,
        exch_na REAL, exch_h  REAL, exch_al REAL,
        wet_weight_g  REAL, dry_weight_g  REAL,
        field_capacity REAL, wilting_point REAL, bulk_density REAL,
        created_at TEXT DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS analysis_results (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        sample_id    TEXT,
        analysed_at  TEXT,
        cec          REAL,
        shi          REAL,
        moisture_pct REAL,
        npk_ratio    TEXT,
        lsi          REAL,
        result_json  TEXT
    );
    """)
    conn.commit()


def save_sample(sample: SoilSample, db_path: Path = DB_PATH) -> None:
    n, m = sample.nutrients, sample.moisture
    with _get_connection(db_path) as conn:
        conn.execute(
            """INSERT OR REPLACE INTO soil_samples VALUES (
               :sid,:loc,:date,:ph,:om,:tex,:dep,:tmp,:notes,
               :np,:pp,:kp,:cap,:mgp,:sp,
               :eca,:emg,:ek,:ena,:eh,:eal,
               :ww,:dw,:fc,:wp,:bd, datetime('now'))""",
            {
                "sid": sample.sample_id, "loc": sample.location,
                "date": sample.collection_date, "ph": sample.ph,
                "om": sample.organic_matter, "tex": sample.texture,
                "dep": sample.depth_cm, "tmp": sample.temperature_c,
                "notes": sample.notes,
                "np": n.nitrogen_ppm, "pp": n.phosphorus_ppm,
                "kp": n.potassium_ppm, "cap": n.calcium_ppm,
                "mgp": n.magnesium_ppm, "sp": n.sulfur_ppm,
                "eca": n.exch_ca, "emg": n.exch_mg, "ek": n.exch_k,
                "ena": n.exch_na, "eh": n.exch_h, "eal": n.exch_al,
                "ww": m.wet_weight_g, "dw": m.dry_weight_g,
                "fc": m.field_capacity, "wp": m.wilting_point,
                "bd": m.bulk_density,
            },
        )
        conn.commit()


def load_all_samples(db_path: Path = DB_PATH) -> list:
    samples = []
    with _get_connection(db_path) as conn:
        for r in conn.execute("SELECT * FROM soil_samples ORDER BY created_at DESC"):
            np_ = NutrientProfile(
                nitrogen_ppm=r["n_ppm"], phosphorus_ppm=r["p_ppm"],
                potassium_ppm=r["k_ppm"], calcium_ppm=r["ca_ppm"],
                magnesium_ppm=r["mg_ppm"], sulfur_ppm=r["s_ppm"],
                exch_ca=r["exch_ca"], exch_mg=r["exch_mg"], exch_k=r["exch_k"],
                exch_na=r["exch_na"], exch_h=r["exch_h"], exch_al=r["exch_al"],
            )
            mr = MoistureReading(
                wet_weight_g=r["wet_weight_g"], dry_weight_g=r["dry_weight_g"],
                field_capacity=r["field_capacity"], wilting_point=r["wilting_point"],
                bulk_density=r["bulk_density"],
            )
            samples.append(SoilSample(
                sample_id=r["sample_id"], location=r["location"],
                collection_date=r["collection_date"], ph=r["ph"],
                organic_matter=r["organic_matter"], texture=r["texture"],
                nutrients=np_, moisture=mr,
                depth_cm=r["depth_cm"], temperature_c=r["temperature_c"],
                notes=r["notes"],
            ))
    return samples


# ─── Core Scientific Algorithms ───────────────────────────────────────────────

def calculate_npk_ratio(nutrients: NutrientProfile) -> tuple:
    """
    Normalise N, P, K concentrations to a unit-sum ratio.

    Returns (n_frac, p_frac, k_frac) each ∈ [0, 1] summing to 1.0.
    A balanced fertiliser recommendation targets N:P:K ≈ 0.5:0.25:0.25
    but optimal ratios are crop-specific.
    """
    total = nutrients.nitrogen_ppm + nutrients.phosphorus_ppm + nutrients.potassium_ppm
    if total == 0.0:
        return (0.0, 0.0, 0.0)
    return (
        round(nutrients.nitrogen_ppm   / total, 4),
        round(nutrients.phosphorus_ppm / total, 4),
        round(nutrients.potassium_ppm  / total, 4),
    )


def compute_ph_buffer_capacity(ph: float, organic_matter_pct: float,
                                clay_content_pct: float = 25.0) -> float:
    """
    Estimate soil pH buffer capacity (β) in mmol H⁺ kg⁻¹ (ΔpH)⁻¹.

    Three contributions are summed:
      β_OM   = OM_pct × 12.5   [humic/fulvic acid functional groups; pKa 4.5-6.0]
               Source: Brady & Weil Table 9-1; ~12.5 mmol/kg per % OM
      β_clay = clay_pct × 0.8  [permanent + pH-dependent aluminosilicate charge]
               Source: Curtin & Trolove (2013) regression coefficient
      β_CO3  = carbonate dissolution buffering, significant only above pH 6.5

    Reference values: sandy loam ≈ 30-50; clay loam ≈ 80-120 mmol/kg/ΔpH.
    """
    beta_om   = organic_matter_pct * 12.5
    beta_clay = clay_content_pct   * 0.8
    # Carbonate dissolution adds ~40% extra buffering per pH unit above 6.5
    carbonate_factor = 1.0 + 0.4 * max(0.0, ph - 6.5)
    return round((beta_om + beta_clay) * carbonate_factor, 3)


def estimate_cation_exchange_capacity(nutrients: NutrientProfile,
                                       organic_matter_pct: float,
                                       ph: float) -> float:
    """
    Cation Exchange Capacity (CEC) in cmol(+) kg⁻¹.

    CEC = Σ exchangeable cations  [Brady & Weil Eq. 9-1]
        = exch_Ca + exch_Mg + exch_K + exch_Na + exch_H + exch_Al

    Additional variable-charge CEC from organic matter:
        CEC_OM = OM_pct × 2.0 × (1 + 0.05 × (pH − 6.0))
        [~200 cmol/kg per unit OM fraction; pH-dependent dissociation]

    Typical ranges:
        Sandy soil:    2–10 cmol/kg
        Loam:         10–20 cmol/kg
        Clay:         20–50 cmol/kg
        Organic soil: 50–100+ cmol/kg
    """
    n = nutrients
    ionic_sum = n.exch_ca + n.exch_mg + n.exch_k + n.exch_na + n.exch_h + n.exch_al
    om_cec    = organic_matter_pct * 2.0 * (1.0 + 0.05 * (ph - 6.0))
    return round(ionic_sum + max(om_cec, 0.0), 3)


def calculate_moisture_content(moisture: MoistureReading) -> dict:
    """
    Compute gravimetric and volumetric water content plus derived indices.

    θg  = (W_wet − W_dry) / W_dry × 100          [%, gravimetric]
    θv  = θg × ρb / ρw                            [cm³/cm³; ρw = 1.0 g/cm³]
    n   = 1 − ρb / ρp                             [total porosity; ρp = 2.65 g/cm³]
    Sr  = θv / n                                   [relative saturation, 0-1]
    PAWC= (θv_FC − θv_WP)                         [plant available water capacity]

    Reference: Hillel, "Introduction to Environmental Soil Physics" (2003).
    """
    m = moisture
    if m.dry_weight_g <= 0:
        raise ValueError("dry_weight_g must be > 0")
    theta_g  = (m.wet_weight_g - m.dry_weight_g) / m.dry_weight_g * 100.0
    theta_v  = theta_g * m.bulk_density / 100.0   # fraction
    porosity = 1.0 - m.bulk_density / 2.65
    rel_sat  = theta_v / porosity if porosity > 0 else 0.0
    # Plant available water capacity from matric potential limits
    pawc = (m.field_capacity - m.wilting_point) * m.bulk_density / 100.0
    return {
        "gravimetric_pct":            round(theta_g,  3),
        "volumetric_cm3_cm3":         round(theta_v,  4),
        "porosity":                   round(porosity, 4),
        "relative_saturation":        round(min(rel_sat, 1.0), 4),
        "plant_available_water_cm3_cm3": round(max(pawc, 0.0), 4),
    }


def langelier_saturation_index(ph: float, ca_hardness_ppm: float,
                                 alkalinity_ppm: float,
                                 tds_ppm: float = 500.0,
                                 temp_c: float = 20.0) -> float:
    """
    Langelier Saturation Index (LSI) for soil pore water.

    LSI = pH_actual − pH_sat

    pH_sat = (9.3 + A + B) − (C + D)
      A = log₁₀(TDS) / 10 − 1
      B = −13.12 × log₁₀(T + 273.15) + 34.55
      C = log₁₀(Ca hardness as CaCO₃) − 0.4
      D = log₁₀(M-alkalinity as CaCO₃)

    Interpretation:
      LSI > 0 → CaCO₃ precipitation tendency (scaling)
      LSI = 0 → equilibrium
      LSI < 0 → CaCO₃ dissolution (corrosive)

    Reference: Langelier, W.F. (1936) AWWA 28:1500-1521.
    """
    if ca_hardness_ppm <= 0 or alkalinity_ppm <= 0 or tds_ppm <= 0:
        return 0.0
    A = math.log10(tds_ppm) / 10.0 - 1.0
    B = -13.12 * math.log10(temp_c + 273.15) + 34.55
    C = math.log10(ca_hardness_ppm) - 0.4
    D = math.log10(alkalinity_ppm)
    ph_sat = (9.3 + A + B) - (C + D)
    return round(ph - ph_sat, 3)


def _nutrient_score(value: float, thresholds: dict) -> float:
    """
    Map a nutrient concentration to a sub-score ∈ [0, 100].
    Score peaks at 100 at the optimal centre; deficiency and excess
    both reduce the score linearly through defined breakpoints.
    """
    d = thresholds["deficient"]
    lo = thresholds["low"]
    opt = thresholds["optimal"]
    hi  = thresholds["high"]
    ex  = thresholds["excessive"]
    if value <= d:
        return 0.0
    if value < lo:
        return 40.0 * (value - d)  / (lo  - d)
    if value < opt:
        return 40.0 + 60.0 * (value - lo) / (opt - lo)
    if value <= hi:
        return 100.0 - 40.0 * (value - opt) / (hi - opt)
    if value <= ex:
        return 60.0  - 50.0 * (value - hi)  / (ex  - hi)
    return 10.0


def assess_soil_health_index(sample: SoilSample) -> dict:
    """
    Soil Health Index (SHI) — composite score ∈ [0, 100].

    SHI = Σ wᵢ × sᵢ

    Sub-scores and weights:
      pH          (w=0.20)  Gaussian, μ=6.5, σ=0.8
      Organic matter(w=0.20) linear 0%→0 … ≥5%→100
      Nitrogen    (w=0.15)  threshold scoring
      Phosphorus  (w=0.10)  threshold scoring
      Potassium   (w=0.10)  threshold scoring
      CEC         (w=0.10)  Gaussian, μ=22.5 cmol/kg, σ=8
      Moisture    (w=0.10)  PAW relative to 0.20 cm³/cm³ optimum
      Microbial   (w=0.05)  proxy = OM × √(θg) / 10 (Wardle 1992 proxy)

    Returns dict of sub-scores + composite SHI.
    """
    n = sample.nutrients
    m = sample.moisture

    ph_score   = 100.0 * math.exp(-0.5 * ((sample.ph - 6.5) / 0.8) ** 2)
    om_score   = min(sample.organic_matter / 5.0 * 100.0, 100.0)
    n_score    = _nutrient_score(n.nitrogen_ppm,   NUTRIENT_THRESHOLDS["N"])
    p_score    = _nutrient_score(n.phosphorus_ppm, NUTRIENT_THRESHOLDS["P"])
    k_score    = _nutrient_score(n.potassium_ppm,  NUTRIENT_THRESHOLDS["K"])

    cec        = estimate_cation_exchange_capacity(n, sample.organic_matter, sample.ph)
    cec_score  = 100.0 * math.exp(-0.5 * ((cec - 22.5) / 8.0) ** 2)

    mc         = calculate_moisture_content(m)
    pawc       = mc["plant_available_water_cm3_cm3"]
    moist_score= min(pawc / 0.20 * 100.0, 100.0)

    micro_proxy= min(
        sample.organic_matter * math.sqrt(max(mc["gravimetric_pct"], 0.01)) / 10.0 * 100,
        100.0,
    )

    weights = {
        "pH":        (ph_score,    0.20),
        "OM":        (om_score,    0.20),
        "N":         (n_score,     0.15),
        "P":         (p_score,     0.10),
        "K":         (k_score,     0.10),
        "CEC":       (cec_score,   0.10),
        "Moisture":  (moist_score, 0.10),
        "Microbial": (micro_proxy, 0.05),
    }
    shi = sum(s * w for s, w in weights.values())
    result = {k: round(v[0], 2) for k, v in weights.items()}
    result["SHI"] = round(shi, 2)
    return result


def predict_crop_yield(sample: SoilSample, crop: str,
                        max_yield_t_ha: float = 10.0) -> CropYieldPrediction:
    """
    Liebig's Law of the Minimum yield model.

    Predicted yield = Y_max × min(f_pH, f_N, f_P, f_K) × f_moisture

    Sufficiency factor for nutrient X:
      f_X = (available_X × mobility_factor_X) / threshold_optimal_X  capped at 1.0

    pH suitability factor:
      1.0 inside crop range; decreases 30% per pH unit outside.

    Moisture correction factor:
      f_θ = θv / θ_optimal;  reduced when waterlogged (Sr > 0.95).

    Reference: Paris (1992), Am. J. Agric. Econ.; de Wit (1965) CABO Wageningen.
    """
    n  = sample.nutrients
    ph_lo, ph_hi = CROP_PH_RANGES.get(crop.lower(), (6.0, 7.0))

    if ph_lo <= sample.ph <= ph_hi:
        ph_suit = 1.0
    elif sample.ph < ph_lo:
        ph_suit = max(0.0, 1.0 - 0.3 * (ph_lo - sample.ph))
    else:
        ph_suit = max(0.0, 1.0 - 0.3 * (sample.ph - ph_hi))

    def suff(val: float, nutrient: str) -> float:
        mob = {"N": _n_mobility_factor(sample.ph),
               "P": _p_mobility_factor(sample.ph),
               "K": _k_mobility_factor(sample.ph)}.get(nutrient, 1.0)
        opt = NUTRIENT_THRESHOLDS[nutrient]["optimal"]
        return min(val * mob / opt, 1.0)

    n_s = suff(n.nitrogen_ppm,   "N")
    p_s = suff(n.phosphorus_ppm, "P")
    k_s = suff(n.potassium_ppm,  "K")

    limiting_map = {"N": n_s, "P": p_s, "K": k_s, "pH": ph_suit}
    limiting_factor = min(limiting_map, key=limiting_map.get)
    min_suff = min(limiting_map.values())

    mc = calculate_moisture_content(sample.moisture)
    sr = mc["relative_saturation"]
    if sr < 0.30:
        moisture_factor = sr / 0.30           # drought stress
    elif sr <= 0.80:
        moisture_factor = 1.0                 # optimal range
    elif sr <= 0.95:
        moisture_factor = 1.0 - 0.5 * (sr - 0.80) / 0.15   # approaching saturation
    else:
        moisture_factor = max(0.2, 0.5 - (sr - 0.95) * 2.0) # waterlogging

    predicted  = max_yield_t_ha * min_suff * moisture_factor
    confidence = 75.0 + ph_suit * 10.0 - abs(sample.ph - 6.5) * 2.0

    return CropYieldPrediction(
        crop=crop,
        predicted_yield_t_ha=round(predicted, 2),
        yield_limiting_factor=limiting_factor,
        confidence_pct=round(min(max(confidence, 40.0), 95.0), 1),
        nutrient_sufficiency={"N": round(n_s,3), "P": round(p_s,3), "K": round(k_s,3)},
        ph_suitability=round(ph_suit, 3),
    )


def generate_remediation_plan(sample: SoilSample, target_ph: float = 6.5,
                               crop: str = "wheat") -> RemediationPlan:
    """
    Generate lime and fertiliser recommendations.

    Lime requirement (LIME_REQ method):
      ΔpH = target_pH − current_pH
      lime_kg/ha = ΔpH × lime_rate × 10
      (lime_rate in kg/ha per 0.1 pH unit; ×10 for full unit conversion)

    Fertiliser deficit (mass-balance method):
      vol_soil = depth_cm/100 × 10,000 m² × ρb × 1000  [kg/ha]
      deficit_kg/ha = (C_target − C_actual) × vol_soil / 1×10⁶

    Organic matter amendment:
      If OM < 3% target, add compost; ~10× OM deficit converted to t/ha.
    """
    n, m = sample.nutrients, sample.moisture
    issues: list = []
    notes: list  = []

    texture = sample.texture if sample.texture in LIME_REQUIREMENT else "loam"
    delta_ph = target_ph - sample.ph
    if delta_ph > 0.05:
        lime_kg_ha = delta_ph * LIME_REQUIREMENT[texture] * 10.0
        issues.append(
            f"pH {sample.ph:.2f} below target {target_ph} for {crop}; ΔpH={delta_ph:.2f}"
        )
        notes.append(
            f"Apply {lime_kg_ha:.0f} kg/ha agricultural lime (CaCO₃) and incorporate to {sample.depth_cm:.0f} cm depth"
        )
    elif delta_ph < -0.5:
        lime_kg_ha = 0.0
        issues.append(f"pH {sample.ph:.2f} exceeds target {target_ph}; acidification needed")
        notes.append("Apply 200–500 kg/ha elemental sulfur or ammonium sulfate to lower pH")
    else:
        lime_kg_ha = 0.0

    # Soil volume in kg/ha for mass-balance calculations
    vol_kg_per_ha = (sample.depth_cm / 100.0) * 1e4 * m.bulk_density * 1e3  # kg/ha

    def deficit_kg_ha(current_ppm: float, nutrient: str) -> float:
        """kg/ha needed to reach optimal concentration."""
        target_ppm = NUTRIENT_THRESHOLDS[nutrient]["optimal"]
        if current_ppm >= target_ppm:
            return 0.0
        return (target_ppm - current_ppm) * vol_kg_per_ha / 1e6

    n_def = deficit_kg_ha(n.nitrogen_ppm,   "N")
    p_def = deficit_kg_ha(n.phosphorus_ppm, "P")
    k_def = deficit_kg_ha(n.potassium_ppm,  "K")

    for nutr, defic, label in [
        ("N", n_def, n.nitrogen_ppm),
        ("P", p_def, n.phosphorus_ppm),
        ("K", k_def, n.potassium_ppm),
    ]:
        if defic > 0:
            issues.append(
                f"{nutr} deficient: {label:.1f} ppm (optimal {NUTRIENT_THRESHOLDS[nutr]['optimal']} ppm)"
            )

    om_deficit      = max(0.0, 3.0 - sample.organic_matter)
    organic_t_ha    = om_deficit * vol_kg_per_ha / 1e6 * 10.0

    if not issues:
        issues.append("No significant nutrient deficiencies detected")

    # Priority matrix
    if sample.ph < 5.0 or len(issues) >= 4:
        priority = "critical"
    elif len(issues) >= 3 or sample.ph < 5.5:
        priority = "high"
    elif len(issues) >= 2:
        priority = "medium"
    else:
        priority = "low"

    cost = (lime_kg_ha * 0.05 + n_def * 0.80 + p_def * 1.20 +
            k_def * 0.60 + organic_t_ha * 20.0)

    return RemediationPlan(
        sample_id=sample.sample_id,
        issues=issues,
        lime_kg_ha=round(lime_kg_ha, 1),
        n_fertiliser_kg=round(n_def, 1),
        p_fertiliser_kg=round(p_def, 1),
        k_fertiliser_kg=round(k_def, 1),
        organic_amendment_t_ha=round(organic_t_ha, 2),
        priority=priority,
        estimated_cost_usd=round(cost, 2),
        notes=notes,
    )


# ─── ASCII Visualisation ───────────────────────────────────────────────────────

def _bar(value: float, max_val: float, width: int = 30, color: str = GREEN) -> str:
    filled = int(round(value / max_val * width)) if max_val > 0 else 0
    filled = min(filled, width)
    return f"{color}{'█' * filled}{'░' * (width - filled)}{RESET}"


def _ph_label(ph: float) -> str:
    if ph < 5.0:
        return f"{RED}{ph:.2f} (very strongly acidic){RESET}"
    if ph < 5.5:
        return f"{RED}{ph:.2f} (strongly acidic){RESET}"
    if ph < 6.0:
        return f"{YELLOW}{ph:.2f} (moderately acidic){RESET}"
    if ph <= 7.0:
        return f"{GREEN}{ph:.2f} (optimal range){RESET}"
    if ph <= 7.5:
        return f"{YELLOW}{ph:.2f} (mildly alkaline){RESET}"
    return f"{RED}{ph:.2f} (strongly alkaline){RESET}"


def print_nutrient_chart(nutrients: NutrientProfile, ph: float) -> None:
    print(f"\n{BOLD}{CYAN}━━━ Nutrient Profile (with pH mobility adjustment) ━━━{RESET}")
    rows = [
        ("N  (ppm)", nutrients.nitrogen_ppm,   250, _n_mobility_factor(ph)),
        ("P  (ppm)", nutrients.phosphorus_ppm,  150, _p_mobility_factor(ph)),
        ("K  (ppm)", nutrients.potassium_ppm,   600, _k_mobility_factor(ph)),
        ("Ca (ppm)", nutrients.calcium_ppm,    8000, 1.0),
        ("Mg (ppm)", nutrients.magnesium_ppm,   800, 1.0),
        ("S  (ppm)", nutrients.sulfur_ppm,      120, 1.0),
    ]
    for label, val, mx, mob in rows:
        bar = _bar(val, mx)
        mob_str = f"  {YELLOW}mob={mob:.2f}{RESET}" if label.startswith(("N","P","K")) else ""
        print(f"  {label:8s} {bar} {val:8.1f}{mob_str}")


def print_sample_summary(sample: SoilSample) -> None:
    sep = "═" * 58
    print(f"\n{BOLD}{BLUE}{sep}{RESET}")
    print(f"{BOLD}  Soil Sample  :  {sample.sample_id}{RESET}")
    print(f"{BLUE}{sep}{RESET}")
    print(f"  Location     : {sample.location}")
    print(f"  Collected    : {sample.collection_date}")
    print(f"  pH           : {_ph_label(sample.ph)}")
    print(f"  Org. Matter  : {sample.organic_matter:.2f}%")
    print(f"  Texture      : {sample.texture}")
    print(f"  Depth        : {sample.depth_cm} cm  |  Temp: {sample.temperature_c}°C")
    if sample.notes:
        print(f"  Notes        : {sample.notes}")
    print_nutrient_chart(sample.nutrients, sample.ph)
    mc = calculate_moisture_content(sample.moisture)
    print(f"\n{BOLD}{CYAN}━━━ Moisture ━━━{RESET}")
    print(f"  Gravimetric θg  : {mc['gravimetric_pct']:.2f}%")
    print(f"  Volumetric  θv  : {mc['volumetric_cm3_cm3']:.4f} cm³/cm³")
    print(f"  Total Porosity  : {mc['porosity']:.4f}")
    print(f"  Relative Sat. Sr: {mc['relative_saturation']*100:.1f}%")
    print(f"  PAW capacity    : {mc['plant_available_water_cm3_cm3']:.4f} cm³/cm³")


def export_report(sample: SoilSample, path: Optional[str] = None) -> str:
    """Export comprehensive analysis to a JSON file."""
    cec    = estimate_cation_exchange_capacity(sample.nutrients, sample.organic_matter, sample.ph)
    shi    = assess_soil_health_index(sample)
    mc     = calculate_moisture_content(sample.moisture)
    npk    = calculate_npk_ratio(sample.nutrients)
    lsi    = langelier_saturation_index(
                 sample.ph, sample.nutrients.calcium_ppm,
                 sample.nutrients.calcium_ppm * 0.4, temp_c=sample.temperature_c)
    buf    = compute_ph_buffer_capacity(sample.ph, sample.organic_matter)
    remed  = generate_remediation_plan(sample)

    report = {
        "generated_at": datetime.now().isoformat(),
        "sample": {
            "id": sample.sample_id, "location": sample.location,
            "date": sample.collection_date, "ph": sample.ph,
            "organic_matter_pct": sample.organic_matter, "texture": sample.texture,
        },
        "analysis": {
            "CEC_cmol_kg": cec, "soil_health_index": shi,
            "moisture": mc,
            "npk_ratio": {"N": npk[0], "P": npk[1], "K": npk[2]},
            "langelier_saturation_index": lsi,
            "ph_buffer_capacity_mmol_kg_per_pH": buf,
        },
        "remediation": {
            "priority": remed.priority, "issues": remed.issues,
            "lime_kg_ha": remed.lime_kg_ha,
            "N_kg_ha": remed.n_fertiliser_kg,
            "P_kg_ha": remed.p_fertiliser_kg,
            "K_kg_ha": remed.k_fertiliser_kg,
            "organic_amendment_t_ha": remed.organic_amendment_t_ha,
            "estimated_cost_usd_ha": remed.estimated_cost_usd,
            "notes": remed.notes,
        },
    }
    if path is None:
        path = f"soil_report_{sample.sample_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(path, "w") as fh:
        json.dump(report, fh, indent=2)
    return path


# ─── Demo Data Factory ────────────────────────────────────────────────────────

def _demo_sample(ph: float = 6.2) -> SoilSample:
    return SoilSample(
        sample_id="DEMO-001",
        location="Field A, Sector 3 — BlackRoad Test Farm",
        collection_date=datetime.today().strftime("%Y-%m-%d"),
        ph=ph,
        organic_matter=2.8,
        texture="loam",
        nutrients=NutrientProfile(
            nitrogen_ppm=55.0, phosphorus_ppm=28.0, potassium_ppm=180.0,
            calcium_ppm=1800.0, magnesium_ppm=220.0, sulfur_ppm=22.0,
            exch_ca=9.2, exch_mg=2.5, exch_k=0.6,
            exch_na=0.3, exch_h=1.8, exch_al=0.4,
        ),
        moisture=MoistureReading(
            wet_weight_g=125.0, dry_weight_g=100.0,
            field_capacity=32.0, wilting_point=13.0, bulk_density=1.25,
        ),
        depth_cm=20.0,
        temperature_c=18.0,
    )


# ─── CLI Commands ─────────────────────────────────────────────────────────────

def cmd_analyze(args) -> None:
    sample = _demo_sample()
    print_sample_summary(sample)
    print(f"\n{BOLD}{CYAN}━━━ Computed Soil Indices ━━━{RESET}")
    cec = estimate_cation_exchange_capacity(sample.nutrients, sample.organic_matter, sample.ph)
    buf = compute_ph_buffer_capacity(sample.ph, sample.organic_matter)
    lsi = langelier_saturation_index(sample.ph, sample.nutrients.calcium_ppm,
                                      sample.nutrients.calcium_ppm * 0.4,
                                      temp_c=sample.temperature_c)
    npk = calculate_npk_ratio(sample.nutrients)
    print(f"  CEC             : {cec:.2f} cmol(+)/kg")
    print(f"  pH Buffer β     : {buf:.2f} mmol H⁺/kg/ΔpH")
    tag = f"{GREEN}scaling{RESET}" if lsi > 0 else (f"{RED}corrosive{RESET}" if lsi < 0 else "balanced")
    print(f"  LSI (pore water): {lsi:+.3f}  [{tag}]")
    print(f"  N:P:K ratio     : {npk[0]:.3f} : {npk[1]:.3f} : {npk[2]:.3f}")
    shi = assess_soil_health_index(sample)
    print(f"\n{BOLD}{CYAN}━━━ Soil Health Index (SHI) ━━━{RESET}")
    for k, v in shi.items():
        color = GREEN if v >= 70 else (YELLOW if v >= 40 else RED)
        print(f"  {k:12s} {_bar(v, 100.0, 20, color)} {v:5.1f}/100")


def cmd_add_sample(args) -> None:
    sample = _demo_sample()
    sample.sample_id = args.id or f"S-{datetime.now().strftime('%Y%m%d%H%M%S')}"
    save_sample(sample)
    print(f"{GREEN}✓ Sample '{sample.sample_id}' saved to {DB_PATH}{RESET}")


def cmd_list(args) -> None:
    samples = load_all_samples()
    if not samples:
        print(f"{YELLOW}No samples in database.  Run 'add-sample' first.{RESET}")
        return
    print(f"\n{BOLD}{CYAN}{'ID':<22} {'Location':<28} {'Date':<12} {'pH':>5} {'OM%':>5}{RESET}")
    print("─" * 76)
    for s in samples:
        print(f"{s.sample_id:<22} {s.location[:27]:<28} {s.collection_date:<12} "
              f"{s.ph:>5.2f} {s.organic_matter:>5.1f}")


def cmd_predict(args) -> None:
    sample = _demo_sample()
    crop   = args.crop or "wheat"
    pred   = predict_crop_yield(sample, crop)
    print(f"\n{BOLD}{CYAN}━━━ Yield Prediction — {crop.title()} ━━━{RESET}")
    print(f"  Predicted yield     : {GREEN}{pred.predicted_yield_t_ha:.2f} t/ha{RESET}")
    print(f"  Limiting factor     : {YELLOW}{pred.yield_limiting_factor}{RESET}")
    print(f"  pH suitability      : {pred.ph_suitability:.3f}")
    print(f"  Confidence          : {pred.confidence_pct:.1f}%")
    ns = pred.nutrient_sufficiency
    print(f"  Sufficiency N/P/K   : {ns['N']:.3f} / {ns['P']:.3f} / {ns['K']:.3f}")


def cmd_remediate(args) -> None:
    sample = _demo_sample()
    crop   = args.crop or "wheat"
    plan   = generate_remediation_plan(sample, crop=crop)
    print(f"\n{BOLD}{CYAN}━━━ Remediation Plan ━━━{RESET}")
    color  = RED if plan.priority == "critical" else (YELLOW if plan.priority == "high" else GREEN)
    print(f"  Priority            : {color}{plan.priority.upper()}{RESET}")
    for issue in plan.issues:
        print(f"  {YELLOW}⚠{RESET}  {issue}")
    print(f"\n  Lime (CaCO₃)        : {plan.lime_kg_ha:.0f} kg/ha")
    print(f"  N fertiliser        : {plan.n_fertiliser_kg:.1f} kg N/ha")
    print(f"  P fertiliser        : {plan.p_fertiliser_kg:.1f} kg P/ha")
    print(f"  K fertiliser        : {plan.k_fertiliser_kg:.1f} kg K/ha")
    print(f"  Organic amendment   : {plan.organic_amendment_t_ha:.2f} t/ha compost")
    print(f"  Estimated cost      : ${plan.estimated_cost_usd:.2f}/ha")
    for note in plan.notes:
        print(f"  {CYAN}→{RESET} {note}")


def cmd_report(args) -> None:
    sample = _demo_sample()
    out    = export_report(sample, args.output)
    print(f"{GREEN}✓ Report exported → {out}{RESET}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="BlackRoad Soil Analytics Engine — pedology-grade soil analysis CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  soil.py analyze\n"
            "  soil.py predict --crop corn\n"
            "  soil.py remediate --crop wheat\n"
            "  soil.py add-sample --id FIELD-042\n"
            "  soil.py report --output my_field.json\n"
        ),
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("analyze",    help="Full soil analysis with indices and charts")
    p_add = sub.add_parser("add-sample", help="Store a sample in the SQLite database")
    p_add.add_argument("--id", help="Custom sample ID (auto-generated if omitted)")
    sub.add_parser("list",       help="List all stored samples")
    p_pred = sub.add_parser("predict",   help="Predict crop yield via Liebig's Law")
    p_pred.add_argument("--crop", default="wheat",
                        choices=list(CROP_PH_RANGES), help="Target crop")
    p_rem  = sub.add_parser("remediate", help="Generate lime + fertiliser recommendations")
    p_rem.add_argument("--crop", default="wheat",
                       choices=list(CROP_PH_RANGES))
    p_rep  = sub.add_parser("report",    help="Export full JSON analysis report")
    p_rep.add_argument("--output", help="Output file path (default: auto-named)")

    args = parser.parse_args()
    {
        "analyze":    cmd_analyze,
        "add-sample": cmd_add_sample,
        "list":       cmd_list,
        "predict":    cmd_predict,
        "remediate":  cmd_remediate,
        "report":     cmd_report,
    }[args.command](args)


if __name__ == "__main__":
    main()
