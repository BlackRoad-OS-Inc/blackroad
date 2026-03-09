# BlackRoad Ship Navigation

Real maritime navigation algorithms — great-circle routing, tidal harmonic analysis, collision avoidance, and magnetic declination. Every formula is sourced from primary geodetic and hydrographic references.

---

## Navigation Science

### Great-Circle Distance — Haversine Formula

The shortest path between two points on a sphere (Sinnott, 1984):

```
a = sin²(Δφ/2) + cos φ₁ · cos φ₂ · sin²(Δλ/2)
d = 2r · arcsin(√a)
```

More numerically stable than the spherical law of cosines for short distances where floating-point cancellation occurs.

### Initial Bearing (Forward Azimuth)

```
θ = atan2( sin Δλ · cos φ₂ ,
           cos φ₁ · sin φ₂ − sin φ₁ · cos φ₂ · cos Δλ )
```

Result in degrees clockwise from True North, range [0°, 360°).

### Rhumb Line (Loxodrome)

A loxodrome crosses every meridian at the same angle and appears as a straight line on a Mercator chart. For the same origin and destination it is always ≥ the great-circle distance.

```
Δψ = ln( tan(π/4 + φ₂/2) / tan(π/4 + φ₁/2) )   ← isometric latitude difference

θ_rhumb = atan2(Δλ, Δψ)

d_rhumb = Δφ / cos θ_rhumb     (if Δφ ≠ 0)
        = cos φ · |Δλ|          (E–W track)
```

### Cross-Track Error (XTE)

Signed distance of a vessel from its intended great-circle track:

```
d_xt = asin( sin(d₁₃/R) · sin(θ₁₃ − θ₁₂) ) · R
```

Along-track distance to the closest point on route:

```
d_at = acos( cos(d₁₃/R) / cos(d_xt/R) ) · R
```

Positive XTE = right of route (starboard), negative = left (port).

### Great-Circle Intermediate Points

Spherical linear interpolation (slerp) on the unit sphere:

```
P(f) = ( sin((1−f)d) · P₁ + sin(fd) · P₂ ) / sin(d)
```

### Tidal Harmonic Analysis

The equilibrium tide is decomposed into sinusoidal constituents (Kelvin/Darwin 1880, Doodson 1921):

```
T(t) = Z₀ + Σᵢ Aᵢ · cos(ωᵢ t − gᵢ)
```

| Symbol | Meaning |
|--------|---------|
| Z₀     | Mean sea level offset (m) |
| Aᵢ     | Harmonic amplitude (m) |
| ωᵢ     | Angular speed (°/hour) |
| gᵢ     | Phase lag — local high water behind equilibrium (°) |
| t      | Time since reference epoch (hours) |

**Standard constituents** (covering ~95 % of tidal energy at most ports):

| Const | ω (°/hr) | Period (h) | Origin |
|-------|----------|------------|--------|
| M2    | 28.9841  | 12.42      | Principal lunar semidiurnal |
| S2    | 30.0000  | 12.00      | Principal solar semidiurnal |
| N2    | 28.4397  | 12.66      | Larger lunar elliptic |
| K1    | 15.0411  | 23.93      | Luni-solar diurnal |
| O1    | 13.9430  | 25.82      | Principal lunar diurnal |

M2 + S2 in phase → *spring tide* (Aᴹ² + Aˢ²).  
M2 − S2 in opposition → *neap tide* (Aᴹ² − Aˢ²).

### Closest Point of Approach (CPA) & Time to CPA (TCPA)

Vector algebra on relative motion:

```
r⃗  = position of V2 relative to V1 (nm)
v⃗  = velocity of V2 relative to V1 (kt)

TCPA = −(r⃗ · v⃗) / |v⃗|²    [hours]
CPA  = |r⃗ + v⃗ · TCPA|       [nm]
```

TCPA < 0 → vessels are already diverging. CPA < 0.5 nm → collision risk (COLREGS stand-on/give-way rules apply).

### Magnetic Declination

Simplified IGRF-13 tilted-dipole model (Geomagnetic North Pole ≈ 80.7°N 72.7°W, epoch 2024):

```
D ≈ atan2( cos φₚ · sin(λ − λₚ) ,
           sin φₚ · cos φ − cos φₚ · sin φ · cos(λ − λₚ) )
```

Secular variation applied at ~0.08°/year. **For operational use, consult the full WMM or IGRF-13.**

---

## Installation

```bash
pip install pytest pytest-cov    # test dependencies only; no runtime deps beyond stdlib
```

## Usage

### Route planning

```bash
python src/navigation.py route 51.5074 -0.1278 40.7128 -74.006 \
    --origin-name LHR --dest-name JFK --waypoints 6
```

### Bearing & magnetic declination

```bash
python src/navigation.py bearing 51.5074 -0.1278 40.7128 -74.006
```

### Tidal prediction (Dover example)

```bash
python src/navigation.py tide \
    --location Dover \
    --m2 2.14 --m2-phase 290 \
    --s2 0.71 --s2-phase 330 \
    --n2 0.42 --n2-phase 263 \
    --k1 0.09 --k1-phase 287 \
    --o1 0.06 --o1-phase 265 \
    --msl 3.67 --hours 72
```

### Collision avoidance (CPA/TCPA)

```bash
python src/navigation.py cpa \
    --v1 TANKER --lat1 51.2 --lon1 1.4 --sog1 8 --cog1 270 \
    --v2 FERRY  --lat2 51.2 --lon2 0.8 --sog2 14 --cog2 090
```

### Vessel track

```bash
python src/navigation.py track add ORCA --lat 51.0 --lon 1.0 --sog 12 --cog 90
python src/navigation.py track add ORCA --lat 51.0 --lon 2.0 --sog 12 --cog 90
python src/navigation.py track show ORCA
```

### Waypoints

```bash
python src/navigation.py waypoint add --name DOVER --lat 51.127 --lon 1.315
python src/navigation.py waypoint list
```

### Database report

```bash
python src/navigation.py report
```

---

## Testing

```bash
pytest tests/ -v --cov=src --cov-report=term-missing
```

---

## References

- Bowditch, N. (2017). *The American Practical Navigator*. NGA Pub. 9
- Admiralty Manual of Navigation, Vol. 1. HMSO, 1987
- Schureman, P. (1958). *Manual of Harmonic Analysis and Prediction of Tides*. NOS Special Pub. 98
- Doodson, A.T. (1921). Harmonic development of the tide-generating potential. *Proc. Royal Soc. A*, 100, 305–329
- Sinnott, R.W. (1984). Virtues of the Haversine. *Sky & Telescope*, 68(2), 159
- Thébault, E. et al. (2015). International Geomagnetic Reference Field: the 12th generation. *Earth Planets Space*, 67, 79
- Williams, E. (2024). *Aviation Formulary v1.47*. https://edwilliams.org/avform147.htm
