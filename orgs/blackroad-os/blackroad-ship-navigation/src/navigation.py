#!/usr/bin/env python3
"""
BlackRoad Ship Navigation — Maritime Navigation Algorithms
Real scientific navigation computations based on geodesy and maritime standards.

References:
  Bowditch (2017) The American Practical Navigator, NGA Pub. 9
  Bowring (1985) The Geodesic Line and the Distance Between Two Points on an Ellipsoid
  Schureman (1958) Manual of Harmonic Analysis and Prediction of Tides, NOS
  IGRF-13 (2020) International Geomagnetic Reference Field
"""

import math
import sqlite3
import argparse
import sys
import os
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional, List, Tuple

# ── ANSI Colour Palette ────────────────────────────────────────────────────────
RED     = '\033[0;31m'
GREEN   = '\033[0;32m'
YELLOW  = '\033[1;33m'
CYAN    = '\033[0;36m'
BLUE    = '\033[0;34m'
MAGENTA = '\033[0;35m'
BOLD    = '\033[1m'
NC      = '\033[0m'

# ── Physical Constants ─────────────────────────────────────────────────────────
EARTH_RADIUS_KM = 6371.0087714   # Mean Earth radius (IUGG 2015), km
EARTH_RADIUS_NM = 3440.0650      # Mean Earth radius, nautical miles

# ── Tidal Harmonic Constituents ────────────────────────────────────────────────
# Darwin symbol, angular speed (°/hour), description
# Derived from the equilibrium tide theory (Kelvin/Darwin 1880, Doodson 1921)
TIDAL_CONSTITUENTS = {
    'M2': {'frequency': 28.9841042, 'description': 'Principal lunar semidiurnal'},
    'S2': {'frequency': 30.0000000, 'description': 'Principal solar semidiurnal'},
    'N2': {'frequency': 28.4397295, 'description': 'Larger lunar elliptic semidiurnal'},
    'K1': {'frequency': 15.0410686, 'description': 'Luni-solar diurnal'},
    'O1': {'frequency': 13.9430356, 'description': 'Principal lunar diurnal'},
}


# ── Data Classes ───────────────────────────────────────────────────────────────
@dataclass
class Waypoint:
    name: str
    lat: float          # decimal degrees, positive = North
    lon: float          # decimal degrees, positive = East
    description: str = ""
    timestamp: Optional[datetime] = None


@dataclass
class GreatCircleRoute:
    origin: Waypoint
    destination: Waypoint
    distance_km: float = 0.0
    distance_nm: float = 0.0
    initial_bearing: float = 0.0
    final_bearing: float = 0.0
    intermediate_points: List[Waypoint] = field(default_factory=list)


@dataclass
class TidePrediction:
    location: str
    time_hours: List[float] = field(default_factory=list)
    heights: List[float] = field(default_factory=list)
    constituents: dict = field(default_factory=dict)


@dataclass
class VesselTrack:
    vessel_id: str
    positions: List[Tuple] = field(default_factory=list)  # (lat, lon, ts, sog, cog)


@dataclass
class CollisionZone:
    vessel1_id: str
    vessel2_id: str
    cpa_distance_nm: float
    tcpa_hours: float
    cpa_lat: float
    cpa_lon: float


@dataclass
class BearingCalculation:
    from_point: Waypoint
    to_point: Waypoint
    true_bearing: float
    magnetic_bearing: float
    magnetic_declination: float
    distance_nm: float
    rhumb_bearing: float
    rhumb_distance_nm: float


# ── Core Math Utilities ────────────────────────────────────────────────────────
def to_rad(deg: float) -> float:
    return deg * math.pi / 180.0


def to_deg(rad: float) -> float:
    return rad * 180.0 / math.pi


def norm_bearing(b: float) -> float:
    """Normalise bearing to [0, 360)."""
    return b % 360.0


# ── Geodesy Functions ──────────────────────────────────────────────────────────
def haversine_distance(lat1: float, lon1: float,
                       lat2: float, lon2: float) -> Tuple[float, float]:
    """
    Great-circle distance via Haversine formula (Sinnott 1984):
        a = sin²(Δφ/2) + cos φ₁ · cos φ₂ · sin²(Δλ/2)
        d = 2r · arcsin(√a)

    More numerically stable than the spherical law of cosines for short distances.
    Returns (distance_km, distance_nm).
    """
    phi1, phi2 = to_rad(lat1), to_rad(lat2)
    dphi = to_rad(lat2 - lat1)
    dlam = to_rad(lon2 - lon1)

    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    c = 2.0 * math.asin(math.sqrt(a))

    return EARTH_RADIUS_KM * c, EARTH_RADIUS_NM * c


def initial_bearing(lat1: float, lon1: float,
                    lat2: float, lon2: float) -> float:
    """
    Forward azimuth from point 1 → point 2 on the great circle:
        θ = atan2(sin Δλ · cos φ₂,
                  cos φ₁ · sin φ₂ − sin φ₁ · cos φ₂ · cos Δλ)

    Returns bearing in degrees clockwise from True North, range [0, 360).
    """
    phi1, phi2 = to_rad(lat1), to_rad(lat2)
    dlam = to_rad(lon2 - lon1)

    y = math.sin(dlam) * math.cos(phi2)
    x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(dlam)
    return norm_bearing(to_deg(math.atan2(y, x)))


def final_bearing(lat1: float, lon1: float,
                  lat2: float, lon2: float) -> float:
    """Final bearing at destination = reverse initial bearing + 180°."""
    return norm_bearing(initial_bearing(lat2, lon2, lat1, lon1) + 180.0)


def rhumb_line(lat1: float, lon1: float,
               lat2: float, lon2: float) -> Tuple[float, float]:
    """
    Rhumb-line (loxodrome) distance and bearing.
    A loxodrome crosses all meridians at the same angle; it appears as a
    straight line on a Mercator projection.

    Mercator isometric latitude: ψ = ln tan(π/4 + φ/2)
    Rhumb bearing:               θ = atan2(Δλ, Δψ)
    Rhumb distance:              d = Δφ / cos θ  (if Δφ ≠ 0)
                                   = cos φ · |Δλ|  (if Δφ ≈ 0)

    Returns (distance_nm, bearing_degrees).
    """
    phi1, phi2 = to_rad(lat1), to_rad(lat2)
    dphi = phi2 - phi1
    dlam = to_rad(lon2 - lon1)

    # Normalise Δλ to [−π, π]
    if abs(dlam) > math.pi:
        dlam -= math.copysign(2.0 * math.pi, dlam)

    dpsi = math.log(math.tan(math.pi / 4 + phi2 / 2) /
                    math.tan(math.pi / 4 + phi1 / 2))
    q = dphi / dpsi if abs(dpsi) > 1e-12 else math.cos(phi1)

    if abs(dphi) < 1e-10:
        dist_rad = abs(dlam) * math.cos(phi1)
    else:
        dist_rad = math.sqrt(dphi ** 2 + q ** 2 * dlam ** 2)

    return dist_rad * EARTH_RADIUS_NM, norm_bearing(to_deg(math.atan2(dlam, dpsi)))


def cross_track_error(lat1: float, lon1: float,
                      lat2: float, lon2: float,
                      lat3: float, lon3: float) -> Tuple[float, float]:
    """
    Cross-track and along-track distance for point P₃ relative to the
    great-circle route P₁ → P₂.

    Cross-track (signed, + = right of route):
        d_xt = asin(sin(d₁₃/R) · sin(θ₁₃ − θ₁₂)) · R

    Along-track:
        d_at = acos(cos(d₁₃/R) / cos(d_xt/R)) · R

    Returns (cross_track_nm, along_track_nm).
    """
    d13_km, _ = haversine_distance(lat1, lon1, lat3, lon3)
    d13 = d13_km / EARTH_RADIUS_KM  # radians

    t13 = to_rad(initial_bearing(lat1, lon1, lat3, lon3))
    t12 = to_rad(initial_bearing(lat1, lon1, lat2, lon2))

    xt = math.asin(math.sin(d13) * math.sin(t13 - t12))
    cos_xt = math.cos(xt)
    at = math.acos(max(-1.0, min(1.0, math.cos(d13) / cos_xt))) if abs(cos_xt) > 1e-12 else 0.0

    return xt * EARTH_RADIUS_NM, at * EARTH_RADIUS_NM


def intermediate_point(lat1: float, lon1: float,
                       lat2: float, lon2: float,
                       fraction: float) -> Tuple[float, float]:
    """
    Intermediate point at fraction f ∈ [0,1] along great-circle route.
    Uses spherical linear interpolation (slerp) on the unit sphere:
        P = (sin((1−f)d) · P₁ + sin(fd) · P₂) / sin(d)
    """
    phi1, lam1 = to_rad(lat1), to_rad(lon1)
    phi2, lam2 = to_rad(lat2), to_rad(lon2)

    _, d_nm = haversine_distance(lat1, lon1, lat2, lon2)
    d = d_nm / EARTH_RADIUS_NM
    if d < 1e-12:
        return lat1, lon1

    A = math.sin((1.0 - fraction) * d) / math.sin(d)
    B = math.sin(fraction * d) / math.sin(d)

    x = A * math.cos(phi1) * math.cos(lam1) + B * math.cos(phi2) * math.cos(lam2)
    y = A * math.cos(phi1) * math.sin(lam1) + B * math.cos(phi2) * math.sin(lam2)
    z = A * math.sin(phi1) + B * math.sin(phi2)

    return (to_deg(math.atan2(z, math.sqrt(x ** 2 + y ** 2))),
            to_deg(math.atan2(y, x)))


# ── Tidal Harmonic Analysis ────────────────────────────────────────────────────
def predict_tide(amplitudes: dict, phases: dict,
                 hours: int = 24, mean_level: float = 0.0) -> TidePrediction:
    """
    Harmonic tidal prediction (Kelvin/Darwin method, formalised by Doodson 1921):

        T(t) = Z₀ + Σᵢ Aᵢ · cos(ωᵢ t − gᵢ)

    where:
        Z₀ = mean sea level offset (m)
        Aᵢ = harmonic amplitude (m)
        ωᵢ = angular speed (°/hour), converted to rad/hour for computation
        gᵢ = phase lag (°) — local high-water lag behind equilibrium tide
        t  = time since reference epoch (hours)

    Constituents: M2, S2, N2, K1, O1 (covers ~95 % of tidal energy at most ports).
    Output resolution: 30-minute intervals.
    """
    times = [t * 0.5 for t in range(hours * 2)]  # 30-min steps
    heights = []
    for t in times:
        h = mean_level
        for name, data in TIDAL_CONSTITUENTS.items():
            if name in amplitudes and amplitudes[name] != 0:
                omega = math.radians(data['frequency'])  # rad/hour
                phi = math.radians(phases.get(name, 0.0))
                h += amplitudes[name] * math.cos(omega * t - phi)
        heights.append(round(h, 4))

    return TidePrediction(
        location="computed",
        time_hours=times,
        heights=heights,
        constituents={k: TIDAL_CONSTITUENTS[k] for k in amplitudes if k in TIDAL_CONSTITUENTS},
    )


# ── Collision Avoidance — CPA/TCPA ────────────────────────────────────────────
def calculate_cpa(lat1: float, lon1: float, sog1: float, cog1: float,
                  lat2: float, lon2: float, sog2: float, cog2: float) -> CollisionZone:
    """
    Closest Point of Approach (CPA) and Time to CPA (TCPA) by relative motion:

        r⃗  = relative position vector (V2 − V1) in nm
        v⃗  = relative velocity vector (V2 − V1) in knots

        TCPA = −(r⃗ · v⃗) / |v⃗|²   [hours]
        CPA  = |r⃗ + v⃗ · TCPA|      [nm]

    Uses a flat-earth approximation valid for distances < ~100 nm;
    longitude scaled by cos(mean lat) to account for meridian convergence.
    """
    cos_lat = math.cos(to_rad((lat1 + lat2) / 2.0))

    # Position in nm (relative to V1)
    rx = (lon2 - lon1) * cos_lat * 60.0
    ry = (lat2 - lat1) * 60.0

    # Velocity components in nm/hr
    v1x = sog1 * math.sin(to_rad(cog1));  v1y = sog1 * math.cos(to_rad(cog1))
    v2x = sog2 * math.sin(to_rad(cog2));  v2y = sog2 * math.cos(to_rad(cog2))

    vx = v2x - v1x;  vy = v2y - v1y
    vv = vx ** 2 + vy ** 2

    if vv < 1e-12:
        tcpa = 0.0
        cpa_dist = math.sqrt(rx ** 2 + ry ** 2)
    else:
        tcpa = max(0.0, -(rx * vx + ry * vy) / vv)
        dx = rx + vx * tcpa;  dy = ry + vy * tcpa
        cpa_dist = math.sqrt(dx ** 2 + dy ** 2)

    cpa_lat = lat1 + (v1y * tcpa) / 60.0
    cpa_lon = lon1 + (v1x * tcpa) / (60.0 * cos_lat) if cos_lat > 1e-6 else lon1

    return CollisionZone("V1", "V2",
                         round(cpa_dist, 4), round(tcpa, 4),
                         round(cpa_lat, 6), round(cpa_lon, 6))


# ── Magnetic Declination (IGRF-13 simplified dipole) ─────────────────────────
def magnetic_declination(lat: float, lon: float, year: float = 2024.0) -> float:
    """
    Simplified dipole approximation of IGRF-13 magnetic declination.

    The geomagnetic field is approximated as a tilted geocentric dipole.
    Geomagnetic north pole (2024): φ_p ≈ 80.7°N, λ_p ≈ 72.7°W.

    D ≈ atan2(cos φ_p · sin(λ − λ_p),
              sin φ_p · cos φ − cos φ_p · sin φ · cos(λ − λ_p))

    Note: For operational use, consult the full WMM or IGRF model.
    Returns declination in degrees (positive = East).
    """
    phi_p, lam_p = to_rad(80.7), to_rad(-72.7)
    phi, lam = to_rad(lat), to_rad(lon)
    dl = lam - lam_p

    y = math.cos(phi_p) * math.sin(dl)
    x = math.sin(phi_p) * math.cos(phi) - math.cos(phi_p) * math.sin(phi) * math.cos(dl)
    decl = to_deg(math.atan2(y, x))
    # Secular variation: ~0.08°/year westward drift of north magnetic pole
    decl += (year - 2020.0) * 0.08
    return round(decl, 2)


# ── Kinematics ─────────────────────────────────────────────────────────────────
def speed_over_ground(lat1: float, lon1: float, t1: datetime,
                      lat2: float, lon2: float, t2: datetime) -> float:
    """Speed over ground (knots) derived from two GPS fixes."""
    _, d_nm = haversine_distance(lat1, lon1, lat2, lon2)
    dt_hr = (t2 - t1).total_seconds() / 3600.0
    return round(d_nm / dt_hr, 3) if dt_hr > 1e-9 else 0.0


def course_made_good(lat1: float, lon1: float,
                     lat2: float, lon2: float) -> float:
    """Course made good (CMG) — actual track direction over the ground (°T)."""
    return initial_bearing(lat1, lon1, lat2, lon2)


# ── Route Builder ──────────────────────────────────────────────────────────────
def build_route(origin: Waypoint, destination: Waypoint,
                n_intermediate: int = 5) -> GreatCircleRoute:
    """Construct great-circle route with equally-spaced intermediate waypoints."""
    dk, dn = haversine_distance(origin.lat, origin.lon, destination.lat, destination.lon)
    ib = initial_bearing(origin.lat, origin.lon, destination.lat, destination.lon)
    fb = final_bearing(origin.lat, origin.lon, destination.lat, destination.lon)

    pts = []
    for i in range(1, n_intermediate + 1):
        f = i / (n_intermediate + 1)
        ilat, ilon = intermediate_point(origin.lat, origin.lon,
                                        destination.lat, destination.lon, f)
        pts.append(Waypoint(f"WP{i:02d}", round(ilat, 6), round(ilon, 6),
                            f"GC intermediate {i}/{n_intermediate}"))

    return GreatCircleRoute(origin, destination,
                            round(dk, 3), round(dn, 3),
                            round(ib, 2), round(fb, 2), pts)


# ── SQLite Persistence ─────────────────────────────────────────────────────────
_DB_DEFAULT = os.path.join(os.path.dirname(__file__), '..', 'navigation.db')


def init_db(db_path: str = _DB_DEFAULT) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS waypoints (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            lat         REAL    NOT NULL,
            lon         REAL    NOT NULL,
            description TEXT    DEFAULT '',
            created_at  TEXT    DEFAULT (datetime('now','utc'))
        );
        CREATE TABLE IF NOT EXISTS routes (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            origin          TEXT NOT NULL,
            destination     TEXT NOT NULL,
            distance_km     REAL,
            distance_nm     REAL,
            initial_bearing REAL,
            final_bearing   REAL,
            created_at      TEXT DEFAULT (datetime('now','utc'))
        );
        CREATE TABLE IF NOT EXISTS vessel_tracks (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            vessel_id TEXT NOT NULL,
            lat       REAL NOT NULL,
            lon       REAL NOT NULL,
            sog       REAL DEFAULT 0,
            cog       REAL DEFAULT 0,
            ts        TEXT DEFAULT (datetime('now','utc'))
        );
        CREATE TABLE IF NOT EXISTS cpa_alerts (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            vessel1_id      TEXT,
            vessel2_id      TEXT,
            cpa_distance_nm REAL,
            tcpa_hours      REAL,
            cpa_lat         REAL,
            cpa_lon         REAL,
            created_at      TEXT DEFAULT (datetime('now','utc'))
        );
    """)
    conn.commit()
    return conn


def save_waypoint(conn, wp: Waypoint) -> int:
    cur = conn.execute(
        "INSERT INTO waypoints(name,lat,lon,description) VALUES(?,?,?,?)",
        (wp.name, wp.lat, wp.lon, wp.description))
    conn.commit()
    return cur.lastrowid


def save_route(conn, route: GreatCircleRoute) -> int:
    cur = conn.execute(
        "INSERT INTO routes(origin,destination,distance_km,distance_nm,"
        "initial_bearing,final_bearing) VALUES(?,?,?,?,?,?)",
        (route.origin.name, route.destination.name,
         route.distance_km, route.distance_nm,
         route.initial_bearing, route.final_bearing))
    conn.commit()
    return cur.lastrowid


def save_cpa_alert(conn, cz: CollisionZone) -> int:
    cur = conn.execute(
        "INSERT INTO cpa_alerts(vessel1_id,vessel2_id,cpa_distance_nm,"
        "tcpa_hours,cpa_lat,cpa_lon) VALUES(?,?,?,?,?,?)",
        (cz.vessel1_id, cz.vessel2_id, cz.cpa_distance_nm,
         cz.tcpa_hours, cz.cpa_lat, cz.cpa_lon))
    conn.commit()
    return cur.lastrowid


# ── ASCII Tide Chart ───────────────────────────────────────────────────────────
def render_tide_chart(pred: TidePrediction, width: int = 64, height: int = 10) -> str:
    """Render an ASCII bar chart of tidal heights."""
    if not pred.heights:
        return "  (no data)"

    mn, mx = min(pred.heights), max(pred.heights)
    span = mx - mn or 1.0

    step = max(1, len(pred.heights) // width)
    sampled_h = pred.heights[::step][:width]
    sampled_t = pred.times if hasattr(pred, 'times') else pred.time_hours[::step][:width]

    lines = [f"\n{CYAN}  Tide Prediction — {pred.location}{NC}"]
    lines.append(f"  {'─' * (len(sampled_h) + 8)}")

    for row in range(height, -1, -1):
        threshold = mn + (row / height) * span
        label = f"  {threshold:5.2f}│"
        bar = ""
        for h in sampled_h:
            bar += (f"{BLUE}▐{NC}" if h >= threshold else " ")
        lines.append(label + bar)

    lines.append(f"       └{'─' * len(sampled_h)}")
    tick_line = "        "
    for i, t in enumerate(sampled_t):
        tick_line += f"{int(t):02d}h" if i % max(1, len(sampled_t) // 8) == 0 else "   "
    lines.append(tick_line[:8 + len(sampled_h)])

    mean_h = sum(pred.heights) / len(pred.heights)
    lines.append(
        f"\n  {GREEN}HW {mx:.3f} m{NC}  {RED}LW {mn:.3f} m{NC}"
        f"  Range {mx - mn:.3f} m  Mean {mean_h:.3f} m"
        f"  Period M2≈{360.0/TIDAL_CONSTITUENTS['M2']['frequency']:.2f} h")
    return "\n".join(lines)


# ── CLI Commands ───────────────────────────────────────────────────────────────
def cmd_route(args):
    origin = Waypoint(args.origin_name, args.lat1, args.lon1)
    dest   = Waypoint(args.dest_name,   args.lat2, args.lon2)
    route  = build_route(origin, dest, n_intermediate=args.waypoints)

    rh_nm, rh_brg = rhumb_line(args.lat1, args.lon1, args.lat2, args.lon2)
    saving = rh_nm - route.distance_nm

    print(f"\n{BOLD}{CYAN}╔══ GREAT-CIRCLE ROUTE ══╗{NC}")
    print(f"  {BOLD}Origin:{NC}      {origin.name} ({origin.lat:+.4f}°, {origin.lon:+.4f}°)")
    print(f"  {BOLD}Destination:{NC} {dest.name} ({dest.lat:+.4f}°, {dest.lon:+.4f}°)")
    print(f"\n  {GREEN}GC Distance:{NC}     {route.distance_km:.1f} km  /  {route.distance_nm:.1f} nm")
    print(f"  {YELLOW}Initial Bearing:{NC} {route.initial_bearing:.2f}°T")
    print(f"  {YELLOW}Final Bearing:{NC}   {route.final_bearing:.2f}°T")
    print(f"\n  {CYAN}Rhumb-line:{NC}      {rh_nm:.1f} nm  @  {rh_brg:.2f}°T")
    print(f"  {GREEN}GC savings:{NC}      {saving:.1f} nm  ({saving / rh_nm * 100:.1f} %)")

    if route.intermediate_points:
        print(f"\n  {BOLD}Intermediate waypoints:{NC}")
        for wp in route.intermediate_points:
            print(f"    {wp.name}: {wp.lat:+.4f}°  {wp.lon:+.4f}°")

    if not args.no_db:
        conn = init_db()
        rid = save_route(conn, route)
        print(f"\n  {GREEN}✓ Route #{rid} saved to navigation.db{NC}")
    print()


def cmd_bearing(args):
    tb   = initial_bearing(args.lat1, args.lon1, args.lat2, args.lon2)
    _, dn = haversine_distance(args.lat1, args.lon1, args.lat2, args.lon2)
    rh_nm, rh_brg = rhumb_line(args.lat1, args.lon1, args.lat2, args.lon2)
    decl = magnetic_declination(args.lat1, args.lon1)
    mb   = norm_bearing(tb - decl)

    print(f"\n{BOLD}{CYAN}╔══ BEARING CALCULATION ══╗{NC}")
    print(f"  From: ({args.lat1:+.4f}°, {args.lon1:+.4f}°)")
    print(f"  To:   ({args.lat2:+.4f}°, {args.lon2:+.4f}°)")
    print(f"\n  {GREEN}True Bearing:{NC}       {tb:.2f}°T")
    print(f"  {YELLOW}Mag Declination:{NC}    {decl:+.2f}°")
    print(f"  {MAGENTA}Magnetic Bearing:{NC}   {mb:.2f}°M")
    print(f"\n  {CYAN}GC Distance:{NC}        {dn:.2f} nm")
    print(f"  {CYAN}Rhumb Bearing:{NC}       {rh_brg:.2f}°  ({rh_nm:.2f} nm)")
    print()


def cmd_tide(args):
    amplitudes = {'M2': args.m2, 'S2': args.s2, 'N2': args.n2,
                  'K1': args.k1, 'O1': args.o1}
    phases     = {'M2': args.m2_phase, 'S2': args.s2_phase, 'N2': args.n2_phase,
                  'K1': args.k1_phase, 'O1': args.o1_phase}

    pred = predict_tide(amplitudes, phases, hours=args.hours, mean_level=args.msl)
    pred.location = args.location

    print(f"\n{BOLD}{CYAN}╔══ TIDAL PREDICTION: {args.location.upper()} ══╗{NC}")
    print(f"  Duration {args.hours} h  ·  Δt = 30 min  ·  Z₀ = {args.msl:.2f} m")
    print(f"\n  {'Const':4s}  {'A (m)':>7s}  {'g (°)':>7s}  {'ω (°/hr)':>10s}  Description")
    print(f"  {'─'*4}  {'─'*7}  {'─'*7}  {'─'*10}  {'─'*30}")
    for c in amplitudes:
        print(f"  {c:4s}  {amplitudes[c]:7.3f}  {phases[c]:7.1f}  "
              f"{TIDAL_CONSTITUENTS[c]['frequency']:10.7f}  {TIDAL_CONSTITUENTS[c]['description']}")

    print(render_tide_chart(pred))


def cmd_track(args):
    conn = init_db()
    if args.action == 'add':
        conn.execute(
            "INSERT INTO vessel_tracks(vessel_id,lat,lon,sog,cog,ts) VALUES(?,?,?,?,?,?)",
            (args.vessel_id, args.lat, args.lon, args.sog, args.cog,
             datetime.now(timezone.utc).isoformat()))
        conn.commit()
        print(f"{GREEN}✓ Position fix logged for {args.vessel_id}{NC}")
    elif args.action == 'show':
        rows = conn.execute(
            "SELECT lat,lon,sog,cog,ts FROM vessel_tracks "
            "WHERE vessel_id=? ORDER BY ts", (args.vessel_id,)).fetchall()
        if not rows:
            print(f"{RED}No track for {args.vessel_id}{NC}"); return
        print(f"\n{BOLD}{CYAN}╔══ VESSEL TRACK: {args.vessel_id} ══╗{NC}")
        total = 0.0
        for i, (lat, lon, sog, cog, ts) in enumerate(rows):
            if i:
                _, dn = haversine_distance(rows[i-1][0], rows[i-1][1], lat, lon)
                total += dn
                cmg = course_made_good(rows[i-1][0], rows[i-1][1], lat, lon)
                print(f"  [{i:3d}] {lat:+.4f}° {lon:+.4f}°  "
                      f"SOG {sog:.1f} kt  COG {cog:.0f}°  Leg {dn:.2f} nm  CMG {cmg:.0f}°")
            else:
                print(f"  [  0] {lat:+.4f}° {lon:+.4f}°  SOG {sog:.1f} kt  (START)")
        print(f"\n  {GREEN}Total distance: {total:.2f} nm{NC}")


def cmd_cpa(args):
    cz = calculate_cpa(args.lat1, args.lon1, args.sog1, args.cog1,
                       args.lat2, args.lon2, args.sog2, args.cog2)
    cz.vessel1_id = args.v1;  cz.vessel2_id = args.v2

    risk = RED if cz.cpa_distance_nm < 0.5 else YELLOW if cz.cpa_distance_nm < 2.0 else GREEN

    print(f"\n{BOLD}{CYAN}╔══ COLLISION AVOIDANCE — CPA ══╗{NC}")
    print(f"  {BOLD}V1 {cz.vessel1_id}:{NC} ({args.lat1:+.4f}°, {args.lon1:+.4f}°) "
          f"SOG {args.sog1:.1f} kt  COG {args.cog1:.0f}°T")
    print(f"  {BOLD}V2 {cz.vessel2_id}:{NC} ({args.lat2:+.4f}°, {args.lon2:+.4f}°) "
          f"SOG {args.sog2:.1f} kt  COG {args.cog2:.0f}°T")
    print(f"\n  {risk}CPA Distance: {cz.cpa_distance_nm:.3f} nm{NC}")
    print(f"  {CYAN}TCPA:         {cz.tcpa_hours:.3f} h  ({cz.tcpa_hours * 60:.1f} min){NC}")
    print(f"  CPA Position: {cz.cpa_lat:+.4f}°  {cz.cpa_lon:+.4f}°")

    if cz.cpa_distance_nm < 0.5:
        print(f"\n  {RED}⚠  COLLISION RISK — TAKE AVOIDING ACTION IMMEDIATELY{NC}")
    elif cz.cpa_distance_nm < 2.0:
        print(f"\n  {YELLOW}⚠  CLOSE-QUARTERS — MONITOR & STAND BY{NC}")
    else:
        print(f"\n  {GREEN}✓  SAFE PASSING DISTANCE{NC}")

    if not args.no_db:
        conn = init_db()
        aid = save_cpa_alert(conn, cz)
        print(f"  {GREEN}✓ CPA alert #{aid} saved{NC}")
    print()


def cmd_waypoint(args):
    conn = init_db()
    if args.action == 'add':
        wp = Waypoint(args.name, args.lat, args.lon, args.description or "")
        wid = save_waypoint(conn, wp)
        print(f"{GREEN}✓ Waypoint '{args.name}' saved (#{wid}){NC}")
    elif args.action == 'list':
        rows = conn.execute(
            "SELECT name,lat,lon,description FROM waypoints ORDER BY created_at DESC"
        ).fetchall()
        if not rows:
            print(f"{YELLOW}No waypoints saved.{NC}"); return
        print(f"\n{BOLD}{CYAN}╔══ SAVED WAYPOINTS ══╗{NC}")
        for name, lat, lon, desc in rows:
            print(f"  {BOLD}{name:16s}{NC} {lat:+.4f}°  {lon:+.4f}°  {desc}")
        print()


def cmd_report(args):
    conn = init_db()
    n_wp  = conn.execute("SELECT COUNT(*) FROM waypoints").fetchone()[0]
    n_rt  = conn.execute("SELECT COUNT(*) FROM routes").fetchone()[0]
    n_tr  = conn.execute("SELECT COUNT(*) FROM vessel_tracks").fetchone()[0]
    n_cpa = conn.execute("SELECT COUNT(*) FROM cpa_alerts WHERE cpa_distance_nm < 0.5"
                         ).fetchone()[0]

    print(f"\n{BOLD}{CYAN}╔═══════════════════════════════════╗{NC}")
    print(f"{BOLD}{CYAN}║  NAVIGATION SYSTEM REPORT         ║{NC}")
    print(f"{BOLD}{CYAN}╚═══════════════════════════════════╝{NC}")
    print(f"  {GREEN}Waypoints:{NC}    {n_wp}")
    print(f"  {GREEN}Routes:{NC}       {n_rt}")
    print(f"  {GREEN}Track fixes:{NC}  {n_tr}")
    print(f"  {RED if n_cpa else GREEN}CPA alerts:{NC}   {n_cpa}")
    print(f"\n  Earth radius (IUGG):  {EARTH_RADIUS_KM} km  /  {EARTH_RADIUS_NM} nm")
    print(f"  Tidal constituents:   {', '.join(TIDAL_CONSTITUENTS)}")
    print(f"  Database:             {os.path.abspath(_DB_DEFAULT)}")
    print()


# ── Argument Parser ────────────────────────────────────────────────────────────
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="BlackRoad Ship Navigation — real maritime navigation science",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Algorithms: Haversine · Rhumb line · CPA/TCPA · Tidal harmonics · IGRF")
    p.add_argument('--no-db', action='store_true', help='Skip database persistence')
    sub = p.add_subparsers(dest='command')

    # route ──────────────────────────────────────────────────────────────────
    r = sub.add_parser('route', help='Great-circle route calculation')
    r.add_argument('lat1', type=float);  r.add_argument('lon1', type=float)
    r.add_argument('lat2', type=float);  r.add_argument('lon2', type=float)
    r.add_argument('--origin-name', default='ORIGIN')
    r.add_argument('--dest-name',   default='DEST')
    r.add_argument('--waypoints', type=int, default=5,
                   help='Number of intermediate waypoints (default 5)')
    r.set_defaults(func=cmd_route)

    # bearing ────────────────────────────────────────────────────────────────
    b = sub.add_parser('bearing', help='True & magnetic bearing + distances')
    b.add_argument('lat1', type=float);  b.add_argument('lon1', type=float)
    b.add_argument('lat2', type=float);  b.add_argument('lon2', type=float)
    b.set_defaults(func=cmd_bearing)

    # tide ───────────────────────────────────────────────────────────────────
    t = sub.add_parser('tide', help='Harmonic tidal prediction')
    t.add_argument('--location', default='PORT')
    t.add_argument('--hours',    type=int,   default=24)
    t.add_argument('--msl',      type=float, default=0.0)
    for c, a, ph in [('m2',1.2,0),('s2',0.4,30),('n2',0.23,340),
                     ('k1',0.15,290),('o1',0.12,280)]:
        t.add_argument(f'--{c}',       type=float, default=a,  metavar='M')
        t.add_argument(f'--{c}-phase', type=float, default=ph, metavar='G')
    t.set_defaults(func=cmd_tide)

    # track ──────────────────────────────────────────────────────────────────
    tr = sub.add_parser('track', help='Vessel track management')
    tr.add_argument('action', choices=['add','show']);  tr.add_argument('vessel_id')
    tr.add_argument('--lat', type=float, default=0.0)
    tr.add_argument('--lon', type=float, default=0.0)
    tr.add_argument('--sog', type=float, default=0.0, help='Speed over ground (kt)')
    tr.add_argument('--cog', type=float, default=0.0, help='Course over ground (°T)')
    tr.set_defaults(func=cmd_track)

    # cpa ────────────────────────────────────────────────────────────────────
    c = sub.add_parser('cpa', help='Closest Point of Approach / TCPA')
    c.add_argument('--v1', default='V1');  c.add_argument('--v2', default='V2')
    for n in ('1','2'):
        c.add_argument(f'--lat{n}', type=float, required=True)
        c.add_argument(f'--lon{n}', type=float, required=True)
        c.add_argument(f'--sog{n}', type=float, required=True)
        c.add_argument(f'--cog{n}', type=float, required=True)
    c.set_defaults(func=cmd_cpa)

    # waypoint ───────────────────────────────────────────────────────────────
    wp = sub.add_parser('waypoint', help='Manage saved waypoints')
    wp.add_argument('action', choices=['add','list'])
    wp.add_argument('--name', default='WP')
    wp.add_argument('--lat',  type=float, default=0.0)
    wp.add_argument('--lon',  type=float, default=0.0)
    wp.add_argument('--description', default='')
    wp.set_defaults(func=cmd_waypoint)

    # report ─────────────────────────────────────────────────────────────────
    rp = sub.add_parser('report', help='Navigation database report')
    rp.set_defaults(func=cmd_report)

    return p


def main():
    parser = build_parser()
    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(0)
    args.func(args)


if __name__ == '__main__':
    main()
