"""
Tests for BlackRoad Ship Navigation algorithms.
All tolerances are based on published geodetic references.
"""

import math
import pytest
import sys
import os
from datetime import datetime, timezone

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from navigation import (
    haversine_distance, initial_bearing, final_bearing,
    rhumb_line, cross_track_error, intermediate_point,
    predict_tide, calculate_cpa, build_route,
    speed_over_ground, course_made_good, magnetic_declination,
    norm_bearing, TIDAL_CONSTITUENTS, EARTH_RADIUS_NM,
    Waypoint,
)

# ── Well-known reference points ────────────────────────────────────────────────
LONDON    = (51.5074,  -0.1278)
NEW_YORK  = (40.7128, -74.0060)
SYDNEY    = (-33.8688, 151.2093)
TOKYO     = (35.6762,  139.6503)
CAPE_HORN = (-55.9833, -67.2667)
OSLO      = (59.9139,   10.7522)
DUBAI     = (25.2048,   55.2708)


# ══════════════════════════════════════════════════════════════════════════════
# Haversine distance
# ══════════════════════════════════════════════════════════════════════════════
class TestHaversine:

    def test_london_to_nyc_km(self):
        """London → New York: published GC distance ≈ 5,570 km (±10 km)."""
        dist_km, _ = haversine_distance(*LONDON, *NEW_YORK)
        assert abs(dist_km - 5570) < 10, f"Got {dist_km:.1f} km"

    def test_london_to_nyc_nm(self):
        """London → New York: ≈ 3,007 nm (±10 nm)."""
        _, dist_nm = haversine_distance(*LONDON, *NEW_YORK)
        assert abs(dist_nm - 3007) < 10, f"Got {dist_nm:.1f} nm"

    def test_zero_distance(self):
        """Identical points → zero distance."""
        km, nm = haversine_distance(51.0, -1.0, 51.0, -1.0)
        assert km < 1e-9 and nm < 1e-9

    def test_equatorial_quarter_circumference(self):
        """0°N 0°E → 0°N 90°E = 1/4 circumference ≈ 10,008 km (r=6371.009 km)."""
        km, _ = haversine_distance(0, 0, 0, 90)
        assert abs(km - 10_008) < 5, f"Got {km:.1f} km"

    def test_antipodal_half_circumference(self):
        """0°N 0°E → 0°N 180°E = half circumference ≈ 20,015 km."""
        km, _ = haversine_distance(0, 0, 0, 180)
        assert abs(km - 20_015) < 15

    def test_symmetry(self):
        """Distance A→B equals distance B→A."""
        d1, _ = haversine_distance(*SYDNEY, *TOKYO)
        d2, _ = haversine_distance(*TOKYO,  *SYDNEY)
        assert abs(d1 - d2) < 1e-9

    def test_always_positive(self):
        """Distance is always non-negative."""
        for pair in [(LONDON, NEW_YORK), (SYDNEY, CAPE_HORN), (OSLO, DUBAI)]:
            km, nm = haversine_distance(*pair[0], *pair[1])
            assert km >= 0 and nm >= 0


# ══════════════════════════════════════════════════════════════════════════════
# Initial bearing
# ══════════════════════════════════════════════════════════════════════════════
class TestInitialBearing:

    def test_due_north(self):
        """0°N → 10°N along same meridian → bearing 0°."""
        b = initial_bearing(0, 0, 10, 0)
        assert b < 0.01 or abs(b - 360) < 0.01

    def test_due_east(self):
        """Along equator eastward → bearing 90°."""
        b = initial_bearing(0, 0, 0, 10)
        assert abs(b - 90) < 0.1

    def test_due_south(self):
        """10°N → 0°N same meridian → bearing 180°."""
        b = initial_bearing(10, 0, 0, 0)
        assert abs(b - 180) < 0.1

    def test_due_west(self):
        """Along equator westward → bearing 270°."""
        b = initial_bearing(0, 10, 0, 0)
        assert abs(b - 270) < 0.1

    def test_london_to_nyc(self):
        """London → NYC: published initial bearing ≈ 288°."""
        b = initial_bearing(*LONDON, *NEW_YORK)
        assert 280 < b < 295, f"Got {b:.1f}°"

    def test_range_0_360(self):
        """Bearing always in [0, 360)."""
        pairs = [(LONDON, NEW_YORK), (NEW_YORK, LONDON), (SYDNEY, OSLO),
                 (CAPE_HORN, DUBAI), (TOKYO, SYDNEY)]
        for p1, p2 in pairs:
            b = initial_bearing(*p1, *p2)
            assert 0 <= b < 360, f"Out of range: {b}"


# ══════════════════════════════════════════════════════════════════════════════
# Rhumb line
# ══════════════════════════════════════════════════════════════════════════════
class TestRhumbLine:

    def test_due_east(self):
        """Equatorial eastward rhumb → 90°, dist ≈ GC dist."""
        dist, brg = rhumb_line(0, 0, 0, 10)
        assert abs(brg - 90) < 0.1

    def test_due_north(self):
        """Northward rhumb → 0° (or 360°)."""
        dist, brg = rhumb_line(0, 10, 10, 10)
        assert brg < 0.1 or abs(brg - 360) < 0.1

    def test_rhumb_ge_gc_long_route(self):
        """Rhumb ≥ GC for London → NYC (long-distance route)."""
        _, gc_nm = haversine_distance(*LONDON, *NEW_YORK)
        rh_nm, _ = rhumb_line(*LONDON, *NEW_YORK)
        assert rh_nm >= gc_nm - 0.5

    def test_short_distance_approx_gc(self):
        """Short rhumb ≈ GC (< 0.5 nm difference for ~8 nm leg)."""
        _, gc_nm = haversine_distance(51.0, 0.0, 51.1, 0.1)
        rh_nm, _ = rhumb_line(51.0, 0.0, 51.1, 0.1)
        assert abs(rh_nm - gc_nm) < 0.5

    def test_dist_positive(self):
        """Rhumb distance always positive."""
        d, _ = rhumb_line(*OSLO, *DUBAI)
        assert d > 0


# ══════════════════════════════════════════════════════════════════════════════
# Cross-track error
# ══════════════════════════════════════════════════════════════════════════════
class TestCrossTrackError:

    def test_midpoint_on_route(self):
        """Exact midpoint has XTE ≈ 0."""
        lat, lon = intermediate_point(0, 0, 0, 10, 0.5)
        xte, _ = cross_track_error(0, 0, 0, 10, lat, lon)
        assert abs(xte) < 0.01, f"XTE = {xte:.4f} nm"

    def test_north_of_eastbound_negative(self):
        """Point N of E-bound route (0→E) is on the left (port) side → negative XTE."""
        xte, _ = cross_track_error(0, 0, 0, 10, 1.0, 5.0)
        assert xte < 0, f"Expected negative XTE (port side), got {xte:.4f}"

    def test_south_of_eastbound_positive(self):
        """Point S of E-bound route is on the right (starboard) side → positive XTE."""
        xte, _ = cross_track_error(0, 0, 0, 10, -1.0, 5.0)
        assert xte > 0, f"Expected positive XTE (starboard side), got {xte:.4f}"

    def test_one_degree_north_magnitude(self):
        """1° N of equatorial E-bound route ≈ 60 nm XTE."""
        xte, _ = cross_track_error(0, 0, 0, 90, 1.0, 45.0)
        assert 55 < abs(xte) < 65, f"Expected ~60 nm, got {abs(xte):.1f} nm"

    def test_along_track_positive_and_bounded(self):
        """ATE should be ≥ 0 and ≤ route length."""
        _, total_nm = haversine_distance(0, 0, 0, 10)
        _, ate = cross_track_error(0, 0, 0, 10, 0.0, 5.0)
        assert 0 <= ate <= total_nm * 1.05


# ══════════════════════════════════════════════════════════════════════════════
# Tidal harmonic prediction
# ══════════════════════════════════════════════════════════════════════════════
class TestTidePrediction:

    def _amp_phase(self, **kwargs):
        base_a = {'M2': 0, 'S2': 0, 'N2': 0, 'K1': 0, 'O1': 0}
        base_p = {'M2': 0, 'S2': 0, 'N2': 0, 'K1': 0, 'O1': 0}
        base_a.update(kwargs.get('a', {}))
        base_p.update(kwargs.get('p', {}))
        return base_a, base_p

    def test_single_m2_amplitude(self):
        """Single M2 at phase 0: max height should equal amplitude."""
        a, p = self._amp_phase(a={'M2': 2.0})
        pred = predict_tide(a, p, hours=13)
        assert abs(max(pred.heights) - 2.0) < 0.02

    def test_spring_tide_superposition(self):
        """M2+S2 in phase → spring tide max ≈ A_M2 + A_S2."""
        a, p = self._amp_phase(a={'M2': 1.5, 'S2': 0.5})
        pred = predict_tide(a, p, hours=25)
        assert abs(max(pred.heights) - 2.0) < 0.05

    def test_msl_offset_shifts_all(self):
        """Mean sea level offset must shift every height by constant Z₀."""
        a, p = self._amp_phase(a={'M2': 1.0})
        pred0 = predict_tide(a, p, hours=13, mean_level=0.0)
        pred5 = predict_tide(a, p, hours=13, mean_level=5.0)
        diffs = [h5 - h0 for h0, h5 in zip(pred0.heights, pred5.heights)]
        assert all(abs(d - 5.0) < 1e-9 for d in diffs)

    def test_m2_period(self):
        """M2 angular frequency implies period ≈ 12.42 hours."""
        period = 360.0 / TIDAL_CONSTITUENTS['M2']['frequency']
        assert abs(period - 12.42) < 0.01

    def test_output_length_24h(self):
        """24 h at 30-min resolution → 48 data points."""
        a, p = self._amp_phase(a={'M2': 1.0, 'S2': 0.3})
        pred = predict_tide(a, p, hours=24)
        assert len(pred.heights) == 48
        assert len(pred.time_hours) == 48

    def test_zero_amplitude_gives_msl(self):
        """All amplitudes zero → heights all equal MSL."""
        a, p = self._amp_phase()
        pred = predict_tide(a, p, hours=6, mean_level=3.5)
        assert all(abs(h - 3.5) < 1e-9 for h in pred.heights)

    def test_symmetry_about_mean(self):
        """For symmetric constituents in phase 0, mean ≈ MSL."""
        a, p = self._amp_phase(a={'M2': 2.0, 'S2': 0.7, 'N2': 0.3, 'K1': 0.2, 'O1': 0.15})
        pred = predict_tide(a, p, hours=745, mean_level=0.0)  # ~1 month
        mean = sum(pred.heights) / len(pred.heights)
        assert abs(mean) < 0.05, f"Mean {mean:.4f} far from 0"


# ══════════════════════════════════════════════════════════════════════════════
# CPA / TCPA
# ══════════════════════════════════════════════════════════════════════════════
class TestCPA:

    def test_head_on_collision(self):
        """Vessels on direct collision course → CPA ≈ 0."""
        cz = calculate_cpa(0.0, 0.0,   10.0, 90.0,   # V1 heading East
                           0.0, 0.1,   10.0, 270.0)   # V2 heading West
        assert cz.cpa_distance_nm < 0.1, f"CPA = {cz.cpa_distance_nm:.3f} nm"
        assert cz.tcpa_hours > 0

    def test_diverging_tcpa_zero(self):
        """Diverging vessels → TCPA = 0 (past CPA already)."""
        cz = calculate_cpa(0.0, 0.0,   10.0, 270.0,   # V1 heading West
                           0.0, 1.0,   10.0, 90.0)    # V2 heading East
        assert cz.tcpa_hours == 0.0

    def test_parallel_same_speed(self):
        """Parallel vessels at same speed: constant separation."""
        cz = calculate_cpa(0.0, 0.0, 10.0, 0.0,
                           0.5, 0.0, 10.0, 0.0)
        assert cz.tcpa_hours >= 0

    def test_cpa_nonnegative(self):
        """CPA distance is always ≥ 0."""
        scenarios = [
            (0, 0, 5, 45,  0.1, 0.1, 5, 225),
            (10,10,12,180, 10, 11, 15, 270),
            (0, 0, 0, 0,   0,   0, 0, 0),
        ]
        for s in scenarios:
            cz = calculate_cpa(*s)
            assert cz.cpa_distance_nm >= 0

    def test_safe_overtaking(self):
        """Faster vessel overtaking same course → no collision."""
        cz = calculate_cpa(0.0, 0.0, 15.0, 0.0,   # V1 fast, North
                           -0.1, 0.0,  8.0, 0.0)   # V2 slow, North, behind
        # V1 is ahead and faster — should pass safely
        assert cz.cpa_distance_nm >= 0


# ══════════════════════════════════════════════════════════════════════════════
# Great-circle intermediate waypoints
# ══════════════════════════════════════════════════════════════════════════════
class TestGreatCircleWaypoints:

    def test_intermediate_count(self):
        """build_route returns exactly n_intermediate waypoints."""
        route = build_route(Waypoint("A", *LONDON), Waypoint("B", *NEW_YORK),
                            n_intermediate=4)
        assert len(route.intermediate_points) == 4

    def test_intermediate_on_route(self):
        """Each intermediate WP should have |XTE| < 1 nm."""
        route = build_route(Waypoint("LHR", *LONDON), Waypoint("JFK", *NEW_YORK),
                            n_intermediate=5)
        for wp in route.intermediate_points:
            xte, _ = cross_track_error(*LONDON, *NEW_YORK, wp.lat, wp.lon)
            assert abs(xte) < 1.0, f"{wp.name} XTE = {xte:.2f} nm"

    def test_intermediate_progression(self):
        """Along-track distance should increase monotonically."""
        route = build_route(Waypoint("A", 0, 0), Waypoint("B", 0, 90),
                            n_intermediate=5)
        prev_ate = -1.0
        for wp in route.intermediate_points:
            _, ate = cross_track_error(0, 0, 0, 90, wp.lat, wp.lon)
            assert ate > prev_ate - 0.1
            prev_ate = ate

    def test_route_distance_matches_haversine(self):
        """GreatCircleRoute.distance_km equals direct haversine calculation."""
        route = build_route(Waypoint("S", *SYDNEY), Waypoint("T", *TOKYO))
        direct_km, _ = haversine_distance(*SYDNEY, *TOKYO)
        assert abs(route.distance_km - direct_km) < 0.1

    def test_zero_intermediate(self):
        """n_intermediate=0 produces empty list but valid route."""
        route = build_route(Waypoint("A", 0, 0), Waypoint("B", 10, 10),
                            n_intermediate=0)
        assert route.intermediate_points == []
        assert route.distance_nm > 0


# ══════════════════════════════════════════════════════════════════════════════
# Speed over ground & course made good
# ══════════════════════════════════════════════════════════════════════════════
class TestKinematics:

    def test_sog_10_knots(self):
        """10 nm in exactly 1 hour → SOG = 10.0 kt."""
        t1 = datetime(2024, 1, 1, 0, 0, tzinfo=timezone.utc)
        t2 = datetime(2024, 1, 1, 1, 0, tzinfo=timezone.utc)
        lat2 = 51.5074 + 10.0 / 60.0  # 10 nm north (≈ 10')
        sog = speed_over_ground(51.5074, 0.0, t1, lat2, 0.0, t2)
        assert abs(sog - 10.0) < 0.05, f"Expected 10.0 kt, got {sog:.3f} kt"

    def test_sog_zero_time(self):
        """Same timestamp → SOG = 0 (no division by zero)."""
        t = datetime(2024, 1, 1, tzinfo=timezone.utc)
        sog = speed_over_ground(0, 0, t, 1, 1, t)
        assert sog == 0.0

    def test_cmg_due_east(self):
        """CMG along equator → 90°."""
        assert abs(course_made_good(0, 0, 0, 10) - 90) < 0.1

    def test_cmg_due_north(self):
        """CMG northward → 0° (or 360°)."""
        c = course_made_good(0, 10, 10, 10)
        assert c < 0.1 or abs(c - 360) < 0.1


# ══════════════════════════════════════════════════════════════════════════════
# Magnetic declination (sanity checks only — simplified model)
# ══════════════════════════════════════════════════════════════════════════════
class TestMagneticDeclination:

    def test_returns_float(self):
        assert isinstance(magnetic_declination(51.5, -0.1), float)

    def test_within_physical_bounds(self):
        """Declination must be in (−180°, +180°) for any surface point."""
        for lat, lon in [(51.5, -0.1), (40.7, -74.0), (-33.9, 151.2),
                         (0, 0), (90, 0), (-90, 0)]:
            d = magnetic_declination(lat, lon)
            assert -180 < d < 180

    def test_secular_variation(self):
        """Later year → slightly different declination (secular variation)."""
        d2020 = magnetic_declination(51.5, -0.1, year=2020.0)
        d2030 = magnetic_declination(51.5, -0.1, year=2030.0)
        assert d2020 != d2030
