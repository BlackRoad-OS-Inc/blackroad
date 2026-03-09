"""
Unit tests for the BlackRoad Soil Analytics Engine.
Run with:  pytest tests/ -v --tb=short
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import pytest
from soil import (
    NutrientProfile,
    MoistureReading,
    SoilSample,
    calculate_npk_ratio,
    compute_ph_buffer_capacity,
    estimate_cation_exchange_capacity,
    predict_crop_yield,
    assess_soil_health_index,
    calculate_moisture_content,
    generate_remediation_plan,
    langelier_saturation_index,
    _p_mobility_factor,
    _n_mobility_factor,
    _k_mobility_factor,
)


# ─── Fixtures ─────────────────────────────────────────────────────────────────

@pytest.fixture
def nutrients_balanced():
    """NPK balanced nutrient profile — all at optimal thresholds."""
    return NutrientProfile(
        nitrogen_ppm=80.0, phosphorus_ppm=40.0, potassium_ppm=200.0,
        calcium_ppm=2000.0, magnesium_ppm=200.0, sulfur_ppm=30.0,
        exch_ca=10.0, exch_mg=3.0, exch_k=0.8,
        exch_na=0.3, exch_h=2.0, exch_al=0.5,
    )


@pytest.fixture
def nutrients_deficient():
    """Severely nutrient-deficient profile."""
    return NutrientProfile(
        nitrogen_ppm=10.0, phosphorus_ppm=5.0, potassium_ppm=40.0,
        calcium_ppm=300.0, magnesium_ppm=30.0, sulfur_ppm=5.0,
        exch_ca=2.0, exch_mg=0.5, exch_k=0.1,
        exch_na=0.1, exch_h=4.0, exch_al=2.5,
    )


@pytest.fixture
def moisture_standard():
    """Standard loam moisture at ~25% gravimetric."""
    return MoistureReading(
        wet_weight_g=125.0, dry_weight_g=100.0,
        field_capacity=32.0, wilting_point=12.0, bulk_density=1.3,
    )


@pytest.fixture
def sample_healthy(nutrients_balanced, moisture_standard):
    return SoilSample(
        sample_id="T-HEALTHY",
        location="Test Lab",
        collection_date="2024-06-15",
        ph=6.5,
        organic_matter=3.5,
        texture="loam",
        nutrients=nutrients_balanced,
        moisture=moisture_standard,
        depth_cm=20.0,
        temperature_c=20.0,
    )


@pytest.fixture
def sample_acidic(nutrients_deficient, moisture_standard):
    return SoilSample(
        sample_id="T-ACIDIC",
        location="Acid Field",
        collection_date="2024-06-15",
        ph=4.8,
        organic_matter=1.0,
        texture="sandy",
        nutrients=nutrients_deficient,
        moisture=moisture_standard,
        depth_cm=20.0,
        temperature_c=20.0,
    )


# ─── NPK Ratio Tests ──────────────────────────────────────────────────────────

class TestNPKRatio:
    def test_values_sum_to_one(self, nutrients_balanced):
        n, p, k = calculate_npk_ratio(nutrients_balanced)
        assert abs(n + p + k - 1.0) < 1e-6

    def test_correct_fractions(self, nutrients_balanced):
        # N=80, P=40, K=200  → total=320
        # fractions: 0.25, 0.125, 0.625
        n, p, k = calculate_npk_ratio(nutrients_balanced)
        assert abs(n - 80/320) < 1e-3
        assert abs(p - 40/320) < 1e-3
        assert abs(k - 200/320) < 1e-3

    def test_zero_nutrients_returns_zeros(self):
        zero = NutrientProfile(
            nitrogen_ppm=0.0, phosphorus_ppm=0.0, potassium_ppm=0.0)
        assert calculate_npk_ratio(zero) == (0.0, 0.0, 0.0)

    def test_fractions_in_unit_interval(self, nutrients_balanced):
        for frac in calculate_npk_ratio(nutrients_balanced):
            assert 0.0 <= frac <= 1.0

    def test_dominant_nutrient_has_highest_fraction(self):
        """K dominates when K >> N, P."""
        n = NutrientProfile(nitrogen_ppm=10, phosphorus_ppm=10, potassium_ppm=500)
        nf, pf, kf = calculate_npk_ratio(n)
        assert kf > nf
        assert kf > pf


# ─── pH Buffer Capacity Tests ─────────────────────────────────────────────────

class TestPhBufferCapacity:
    def test_higher_om_increases_buffer(self):
        β_low  = compute_ph_buffer_capacity(6.5, 1.0, 25.0)
        β_high = compute_ph_buffer_capacity(6.5, 5.0, 25.0)
        assert β_high > β_low

    def test_higher_clay_increases_buffer(self):
        β_sand = compute_ph_buffer_capacity(6.5, 2.0, clay_content_pct=5.0)
        β_clay = compute_ph_buffer_capacity(6.5, 2.0, clay_content_pct=60.0)
        assert β_clay > β_sand

    def test_above_65_carbonate_boost(self):
        β_acid    = compute_ph_buffer_capacity(5.5, 2.0, 25.0)
        β_neutral = compute_ph_buffer_capacity(7.5, 2.0, 25.0)
        # Carbonate buffering increases β above pH 6.5
        assert β_neutral > β_acid

    def test_known_value_loam(self):
        # Loam: OM=2.5%, clay≈25%  → β ≈ 2.5*12.5 + 25*0.8 = 31.25+20 = 51.25
        # At pH 6.5: carbonate_factor=1.0
        β = compute_ph_buffer_capacity(6.5, 2.5, 25.0)
        assert abs(β - 51.25) < 0.5

    def test_returns_positive_float(self):
        β = compute_ph_buffer_capacity(6.0, 3.0)
        assert β > 0.0
        assert isinstance(β, float)


# ─── CEC Tests ────────────────────────────────────────────────────────────────

class TestCationExchangeCapacity:
    def test_known_ionic_sum(self, nutrients_balanced):
        # ionic sum = 10+3+0.8+0.3+2.0+0.5 = 16.6
        # OM-CEC = 3.5 * 2.0 * (1 + 0.05*(6.5-6.0)) = 7.0 * 1.025 = 7.175
        # total ≈ 23.775
        cec = estimate_cation_exchange_capacity(nutrients_balanced, 3.5, 6.5)
        assert abs(cec - (16.6 + 3.5 * 2.0 * 1.025)) < 0.1

    def test_higher_om_gives_higher_cec(self, nutrients_balanced):
        cec_low  = estimate_cation_exchange_capacity(nutrients_balanced, 1.0, 6.5)
        cec_high = estimate_cation_exchange_capacity(nutrients_balanced, 6.0, 6.5)
        assert cec_high > cec_low

    def test_cec_increases_with_ph(self, nutrients_balanced):
        """Variable charge increases with pH (pH-dependent sites on OM and clay)."""
        cec_acid = estimate_cation_exchange_capacity(nutrients_balanced, 3.0, 5.0)
        cec_alk  = estimate_cation_exchange_capacity(nutrients_balanced, 3.0, 7.5)
        assert cec_alk > cec_acid

    def test_cec_in_realistic_range(self, nutrients_balanced):
        cec = estimate_cation_exchange_capacity(nutrients_balanced, 3.0, 6.5)
        assert 2.0 <= cec <= 100.0

    def test_deficient_soil_lower_cec(self, nutrients_deficient):
        cec = estimate_cation_exchange_capacity(nutrients_deficient, 1.0, 4.8)
        # ionic sum = 2+0.5+0.1+0.1+4.0+2.5 = 9.2; om small
        assert cec < 20.0


# ─── Crop Yield Prediction Tests ──────────────────────────────────────────────

class TestCropYieldPrediction:
    def test_healthy_soil_high_yield(self, sample_healthy):
        pred = predict_crop_yield(sample_healthy, "wheat", max_yield_t_ha=10.0)
        assert pred.predicted_yield_t_ha > 5.0, "Healthy soil should give >50% max yield"

    def test_acidic_soil_reduces_yield(self, sample_acidic):
        pred = predict_crop_yield(sample_acidic, "wheat", max_yield_t_ha=10.0)
        assert pred.predicted_yield_t_ha < 5.0

    def test_yield_within_bounds(self, sample_healthy):
        pred = predict_crop_yield(sample_healthy, "wheat", max_yield_t_ha=10.0)
        assert 0.0 <= pred.predicted_yield_t_ha <= 10.0

    def test_blueberry_thrives_in_acid(self, sample_acidic):
        """Blueberry prefers pH 4.5-5.5; sample_acidic pH=4.8 should suit."""
        pred = predict_crop_yield(sample_acidic, "blueberry", max_yield_t_ha=8.0)
        assert pred.ph_suitability > 0.8

    def test_limiting_factor_is_valid_key(self, sample_acidic):
        pred = predict_crop_yield(sample_acidic, "wheat")
        assert pred.yield_limiting_factor in {"N", "P", "K", "pH"}

    def test_confidence_in_range(self, sample_healthy):
        pred = predict_crop_yield(sample_healthy, "wheat")
        assert 40.0 <= pred.confidence_pct <= 95.0

    def test_nutrient_sufficiency_bounded(self, sample_healthy):
        pred = predict_crop_yield(sample_healthy, "wheat")
        for v in pred.nutrient_sufficiency.values():
            assert 0.0 <= v <= 1.0


# ─── Soil Health Index Tests ──────────────────────────────────────────────────

class TestSoilHealthIndex:
    def test_shi_in_zero_to_hundred(self, sample_healthy):
        shi_result = assess_soil_health_index(sample_healthy)
        assert 0.0 <= shi_result["SHI"] <= 100.0

    def test_healthy_soil_high_shi(self, sample_healthy):
        shi_result = assess_soil_health_index(sample_healthy)
        assert shi_result["SHI"] > 60.0, "Healthy soil should score above 60"

    def test_acidic_soil_low_shi(self, sample_acidic):
        shi_result = assess_soil_health_index(sample_acidic)
        assert shi_result["SHI"] < 60.0

    def test_all_subscores_present(self, sample_healthy):
        expected_keys = {"pH", "OM", "N", "P", "K", "CEC", "Moisture", "Microbial", "SHI"}
        shi_result = assess_soil_health_index(sample_healthy)
        assert expected_keys == set(shi_result.keys())

    def test_subscores_bounded(self, sample_healthy):
        shi_result = assess_soil_health_index(sample_healthy)
        for k, v in shi_result.items():
            assert 0.0 <= v <= 100.0, f"Sub-score {k}={v} out of [0,100]"

    def test_ph_score_peaks_at_65(self):
        """pH score should be highest at 6.5 (Gaussian centre)."""
        nutrients = NutrientProfile(80, 40, 200)
        moisture  = MoistureReading(125, 100)

        def shi_at_ph(ph):
            s = SoilSample("x","x","2024-01-01",ph,3.0,"loam",nutrients,moisture)
            return assess_soil_health_index(s)["pH"]

        assert shi_at_ph(6.5) > shi_at_ph(5.0)
        assert shi_at_ph(6.5) > shi_at_ph(8.0)
        assert abs(shi_at_ph(6.5) - 100.0) < 0.1


# ─── Moisture Content Tests ───────────────────────────────────────────────────

class TestMoistureContent:
    def test_gravimetric_formula(self):
        """θg = (125-100)/100 × 100 = 25.0%"""
        m = MoistureReading(wet_weight_g=125.0, dry_weight_g=100.0, bulk_density=1.3)
        mc = calculate_moisture_content(m)
        assert abs(mc["gravimetric_pct"] - 25.0) < 0.001

    def test_volumetric_derived_correctly(self):
        """θv = θg × ρb / 100 = 25.0 × 1.3 / 100 = 0.325"""
        m = MoistureReading(125.0, 100.0, bulk_density=1.3)
        mc = calculate_moisture_content(m)
        assert abs(mc["volumetric_cm3_cm3"] - 0.325) < 1e-4

    def test_porosity_formula(self):
        """n = 1 - 1.3/2.65 ≈ 0.5094"""
        m = MoistureReading(125.0, 100.0, bulk_density=1.3)
        mc = calculate_moisture_content(m)
        expected_porosity = 1.0 - 1.3 / 2.65
        assert abs(mc["porosity"] - expected_porosity) < 1e-4

    def test_relative_saturation_range(self):
        m = MoistureReading(125.0, 100.0, bulk_density=1.3)
        mc = calculate_moisture_content(m)
        assert 0.0 <= mc["relative_saturation"] <= 1.0

    def test_pawc_positive(self, moisture_standard):
        mc = calculate_moisture_content(moisture_standard)
        assert mc["plant_available_water_cm3_cm3"] > 0.0

    def test_zero_dry_weight_raises(self):
        with pytest.raises(ValueError):
            calculate_moisture_content(MoistureReading(100.0, 0.0))


# ─── Remediation Plan Tests ───────────────────────────────────────────────────

class TestRemediationPlan:
    def test_acidic_soil_requires_lime(self, sample_acidic):
        plan = generate_remediation_plan(sample_acidic, target_ph=6.5)
        assert plan.lime_kg_ha > 0.0

    def test_lime_amount_scales_with_ph_deficit(self):
        """Greater pH deficit → more lime needed."""
        n = NutrientProfile(80, 40, 200)
        m = MoistureReading(125, 100)
        s_mild   = SoilSample("A","L","2024-01-01", 6.0, 3.0,"loam",n,m)
        s_severe = SoilSample("B","L","2024-01-01", 4.5, 3.0,"loam",n,m)
        plan_mild   = generate_remediation_plan(s_mild,   target_ph=6.5)
        plan_severe = generate_remediation_plan(s_severe, target_ph=6.5)
        assert plan_severe.lime_kg_ha > plan_mild.lime_kg_ha

    def test_healthy_soil_low_priority(self, sample_healthy):
        plan = generate_remediation_plan(sample_healthy)
        assert plan.priority in {"low", "medium"}

    def test_acidic_soil_high_priority(self, sample_acidic):
        plan = generate_remediation_plan(sample_acidic, target_ph=6.5)
        assert plan.priority in {"critical", "high"}

    def test_deficient_n_triggers_n_recommendation(self, sample_acidic):
        plan = generate_remediation_plan(sample_acidic)
        assert plan.n_fertiliser_kg > 0.0

    def test_no_lime_for_alkaline_soil(self):
        """Soil already above target pH should not receive lime."""
        n = NutrientProfile(80, 40, 200)
        m = MoistureReading(125, 100)
        s = SoilSample("C","L","2024-01-01", 7.8, 3.0, "loam", n, m)
        plan = generate_remediation_plan(s, target_ph=6.5)
        assert plan.lime_kg_ha == 0.0

    def test_cost_positive(self, sample_acidic):
        plan = generate_remediation_plan(sample_acidic)
        assert plan.estimated_cost_usd >= 0.0

    def test_remediation_identifies_issues(self, sample_acidic):
        plan = generate_remediation_plan(sample_acidic, target_ph=6.5)
        assert len(plan.issues) >= 1


# ─── Langelier Saturation Index Tests ────────────────────────────────────────

class TestLangelierSaturationIndex:
    def test_positive_lsi_scaling_water(self):
        """High pH + high alkalinity → positive LSI (scaling tendency)."""
        lsi = langelier_saturation_index(
            ph=8.2, ca_hardness_ppm=200.0, alkalinity_ppm=250.0,
            tds_ppm=600.0, temp_c=20.0)
        assert lsi > 0.0

    def test_negative_lsi_corrosive_water(self):
        """Low pH → negative LSI (corrosive/dissolving tendency)."""
        lsi = langelier_saturation_index(
            ph=5.5, ca_hardness_ppm=50.0, alkalinity_ppm=40.0,
            tds_ppm=200.0, temp_c=20.0)
        assert lsi < 0.0

    def test_zero_inputs_return_zero(self):
        assert langelier_saturation_index(7.0, 0.0, 0.0) == 0.0

    def test_temperature_effect(self):
        """Higher temperature lowers pH_sat → higher LSI."""
        lsi_cold = langelier_saturation_index(7.5, 150.0, 150.0, temp_c=10.0)
        lsi_warm = langelier_saturation_index(7.5, 150.0, 150.0, temp_c=30.0)
        assert lsi_warm > lsi_cold


# ─── Nutrient Mobility Factor Tests ──────────────────────────────────────────

class TestNutrientMobility:
    def test_p_mobility_peaks_at_optimal_ph(self):
        assert _p_mobility_factor(7.0) == 1.0
        assert _p_mobility_factor(5.0) < 1.0
        assert _p_mobility_factor(8.5) < 1.0

    def test_n_mobility_reduced_at_low_ph(self):
        assert _n_mobility_factor(7.0) == 1.0
        assert _n_mobility_factor(5.0) < 1.0

    def test_k_mobility_high_at_neutral_ph(self):
        assert _k_mobility_factor(6.5) == 1.0
        assert _k_mobility_factor(4.5) < 1.0

    def test_all_mobility_factors_positive(self):
        for ph in [4.0, 5.0, 6.0, 7.0, 8.0, 9.0]:
            assert _p_mobility_factor(ph) > 0.0
            assert _n_mobility_factor(ph) > 0.0
            assert _k_mobility_factor(ph) > 0.0
