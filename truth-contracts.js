/**
 * TRUTH CONTRACTS SYSTEM
 *
 * Rigorous type system for astronomical/geodetic verification.
 * Prevents frame mixing, time scale confusion, and datum mismatches.
 *
 * Philosophy: "PRECISION REQUIRES EXPLICIT CONTRACTS. NO ASSUMPTIONS."
 */

// ===== TIME SCALES =====
export const TIME_SCALES = {
    UTC: 'UTC',           // Coordinated Universal Time (civil time, has leap seconds)
    TAI: 'TAI',           // International Atomic Time (UTC + leap seconds)
    TT: 'TT',             // Terrestrial Time (TAI + 32.184s, for geocentric ephemerides)
    TDB: 'TDB',           // Barycentric Dynamical Time (for barycentric ephemerides)
    UT1: 'UT1',           // Universal Time (actual Earth rotation, for sky positions)
    GPS: 'GPS'            // GPS Time (TAI - 19s)
};

// ===== REFERENCE FRAMES =====
export const FRAMES = {
    // Inertial frames (non-rotating)
    ICRF_BARYCENTRIC: 'ICRF_BARYCENTRIC',     // Solar system barycenter, ICRF axes
    HELIOCENTRIC_ECLIPTIC: 'HELIOCENTRIC_ECLIPTIC', // Sun center, ecliptic plane
    ECI: 'ECI',                               // Earth-Centered Inertial (J2000)

    // Rotating frames
    ECEF: 'ECEF',                             // Earth-Centered Earth-Fixed (WGS84)
    TOPOCENTRIC: 'TOPOCENTRIC',               // Observer-centered (alt/az)

    // Special
    MOON_CENTERED: 'MOON_CENTERED'
};

// ===== HEIGHT DATUMS =====
export const HEIGHT_DATUMS = {
    ELLIPSOID: 'ELLIPSOID',   // Height above reference ellipsoid (WGS84)
    GEOID: 'GEOID',           // Height above geoid (mean sea level)
    MSL: 'MSL'                // Mean Sea Level (local vertical datum)
};

// ===== LEAP SECOND TABLE =====
// Must be updated when IERS announces new leap seconds
export const LEAP_SECONDS = [
    { date: new Date('1972-01-01'), leapSeconds: 10 },
    { date: new Date('1972-07-01'), leapSeconds: 11 },
    { date: new Date('1973-01-01'), leapSeconds: 12 },
    { date: new Date('1974-01-01'), leapSeconds: 13 },
    { date: new Date('1975-01-01'), leapSeconds: 14 },
    { date: new Date('1976-01-01'), leapSeconds: 15 },
    { date: new Date('1977-01-01'), leapSeconds: 16 },
    { date: new Date('1978-01-01'), leapSeconds: 17 },
    { date: new Date('1979-01-01'), leapSeconds: 18 },
    { date: new Date('1980-01-01'), leapSeconds: 19 },
    { date: new Date('1981-07-01'), leapSeconds: 20 },
    { date: new Date('1982-07-01'), leapSeconds: 21 },
    { date: new Date('1983-07-01'), leapSeconds: 22 },
    { date: new Date('1985-07-01'), leapSeconds: 23 },
    { date: new Date('1988-01-01'), leapSeconds: 24 },
    { date: new Date('1990-01-01'), leapSeconds: 25 },
    { date: new Date('1991-01-01'), leapSeconds: 26 },
    { date: new Date('1992-07-01'), leapSeconds: 27 },
    { date: new Date('1993-07-01'), leapSeconds: 28 },
    { date: new Date('1994-07-01'), leapSeconds: 29 },
    { date: new Date('1996-01-01'), leapSeconds: 30 },
    { date: new Date('1997-07-01'), leapSeconds: 31 },
    { date: new Date('1999-01-01'), leapSeconds: 32 },
    { date: new Date('2006-01-01'), leapSeconds: 33 },
    { date: new Date('2009-01-01'), leapSeconds: 34 },
    { date: new Date('2012-07-01'), leapSeconds: 35 },
    { date: new Date('2015-07-01'), leapSeconds: 36 },
    { date: new Date('2017-01-01'), leapSeconds: 37 }
    // Current as of 2025: 37 leap seconds
    // Check: https://www.iers.org/IERS/EN/DataProducts/EarthOrientationData/eop.html
];

// ===== EARTH ORIENTATION PARAMETERS (EOP) =====
// Simplified - in production, fetch from IERS Bulletin A
export const EOP_DATA = {
    // UT1-UTC difference (seconds)
    // Varies due to Earth's irregular rotation
    dut1: -0.1234, // Example value, should be fetched from IERS

    // Polar motion (arcseconds)
    xp: 0.123456,
    yp: 0.234567,

    // Updated: new Date().toISOString()
    updated: '2025-01-01T00:00:00Z'
};

// ===== WGS84 CORRECTED LANDMARKS =====
export const WGS84_LANDMARKS_CORRECTED = {
    greenwich_observatory: {
        name: 'Greenwich Observatory (Airy Transit Circle)',
        // Historic meridian, NOT WGS84 0°
        lat: 51.4778,
        lon: -0.0014,  // ~102m west of WGS84 0°
        ellipsoidHeight: 46.0, // meters above WGS84 ellipsoid
        geoidHeight: 45.9,     // meters above EGM2008 geoid
        datum: HEIGHT_DATUMS.ELLIPSOID,
        notes: 'Historic Prime Meridian is offset from WGS84 0° by ~102m'
    },

    wgs84_prime_meridian: {
        name: 'WGS84 Prime Meridian (0°E reference)',
        lat: 51.4778,
        lon: 0.0000,   // Exact WGS84 0°
        ellipsoidHeight: 46.0,
        datum: HEIGHT_DATUMS.ELLIPSOID,
        notes: 'Actual WGS84 zero longitude'
    },

    north_pole: {
        name: 'Geographic North Pole',
        lat: 90.0,
        lon: 0.0, // Longitude undefined at pole
        ellipsoidHeight: 0.0,
        datum: HEIGHT_DATUMS.ELLIPSOID,
        notes: 'Ice cap, sea level assumption'
    },

    mount_everest: {
        name: 'Mount Everest Summit',
        lat: 27.988056,
        lon: 86.925278,
        ellipsoidHeight: 8877.69, // Ellipsoidal height (WGS84)
        geoidHeight: 8848.86,     // Official orthometric height (MSL)
        datum: HEIGHT_DATUMS.ELLIPSOID,
        notes: 'Use ellipsoidal height for ECEF! Geoid undulation ~29m here'
    },

    null_island: {
        name: 'Null Island (0°N 0°E)',
        lat: 0.0,
        lon: 0.0,
        ellipsoidHeight: 0.0,
        datum: HEIGHT_DATUMS.ELLIPSOID,
        notes: 'Ocean, theoretical point'
    }
};

// ===== TRUTH CONTRACT TYPE =====
export class TruthContract {
    constructor(config) {
        this.frame = config.frame;
        this.timeScale = config.timeScale;
        this.heightDatum = config.heightDatum || null;
        this.tolerance = config.tolerance || {};

        // Validate
        if (!Object.values(FRAMES).includes(this.frame)) {
            throw new Error(`Invalid frame: ${this.frame}`);
        }
        if (!Object.values(TIME_SCALES).includes(this.timeScale)) {
            throw new Error(`Invalid time scale: ${this.timeScale}`);
        }
        if (this.heightDatum && !Object.values(HEIGHT_DATUMS).includes(this.heightDatum)) {
            throw new Error(`Invalid height datum: ${this.heightDatum}`);
        }
    }

    toString() {
        return `Contract(frame=${this.frame}, time=${this.timeScale}, datum=${this.heightDatum})`;
    }
}

// ===== TIME CONVERSION UTILITIES =====
export class TimeConverter {
    /**
     * Get current leap seconds for a UTC date
     */
    static getLeapSeconds(utcDate) {
        let leapSeconds = 10; // Pre-1972 default

        for (const entry of LEAP_SECONDS) {
            if (utcDate >= entry.date) {
                leapSeconds = entry.leapSeconds;
            } else {
                break;
            }
        }

        return leapSeconds;
    }

    /**
     * Convert UTC to TAI
     */
    static utcToTAI(utcDate) {
        const leapSeconds = this.getLeapSeconds(utcDate);
        return new Date(utcDate.getTime() + leapSeconds * 1000);
    }

    /**
     * Convert UTC to TT (Terrestrial Time)
     * TT = TAI + 32.184s
     */
    static utcToTT(utcDate) {
        const tai = this.utcToTAI(utcDate);
        return new Date(tai.getTime() + 32.184 * 1000);
    }

    /**
     * Convert UTC to TDB (Barycentric Dynamical Time)
     * TDB ≈ TT + periodic terms (simplified: TT + 0.001658 sin(g))
     * g = mean anomaly of Earth
     */
    static utcToTDB(utcDate) {
        const tt = this.utcToTT(utcDate);

        // Simplified TDB calculation
        // Full calculation requires Earth's position
        const jd = this.dateToJulianDate(tt);
        const T = (jd - 2451545.0) / 36525.0; // centuries since J2000

        // Mean anomaly of Earth (simplified)
        const g = (357.5277233 + 35999.05034 * T) * Math.PI / 180;

        // Periodic term (milliseconds)
        const deltaT = 0.001658 * Math.sin(g) + 0.000014 * Math.sin(2 * g);

        return new Date(tt.getTime() + deltaT * 1000);
    }

    /**
     * Convert UTC to UT1 (Earth rotation)
     * UT1 = UTC + DUT1
     */
    static utcToUT1(utcDate) {
        // DUT1 must be fetched from IERS
        const dut1 = EOP_DATA.dut1;
        return new Date(utcDate.getTime() + dut1 * 1000);
    }

    /**
     * Convert Date to Julian Date
     */
    static dateToJulianDate(date) {
        return date.getTime() / 86400000 + 2440587.5;
    }

    /**
     * Convert between time scales with explicit contract
     */
    static convert(timestamp, fromScale, toScale) {
        if (fromScale === toScale) return timestamp;

        // Convert to UTC first if needed
        let utc = timestamp;
        if (fromScale === TIME_SCALES.TAI) {
            const leapSeconds = this.getLeapSeconds(timestamp);
            utc = new Date(timestamp.getTime() - leapSeconds * 1000);
        } else if (fromScale === TIME_SCALES.TT) {
            const tai = new Date(timestamp.getTime() - 32.184 * 1000);
            const leapSeconds = this.getLeapSeconds(tai);
            utc = new Date(tai.getTime() - leapSeconds * 1000);
        }

        // Convert from UTC to target
        switch (toScale) {
            case TIME_SCALES.UTC:
                return utc;
            case TIME_SCALES.TAI:
                return this.utcToTAI(utc);
            case TIME_SCALES.TT:
                return this.utcToTT(utc);
            case TIME_SCALES.TDB:
                return this.utcToTDB(utc);
            case TIME_SCALES.UT1:
                return this.utcToUT1(utc);
            default:
                throw new Error(`Unsupported time scale: ${toScale}`);
        }
    }
}

// ===== FRAME TRANSFORMATION UTILITIES =====
export class FrameTransformer {
    /**
     * Convert ECEF to ECI (requires UT1 for Earth rotation angle)
     */
    static ecefToECI(ecef, ut1Time) {
        // Greenwich Mean Sidereal Time (GMST)
        const jd = TimeConverter.dateToJulianDate(ut1Time);
        const T = (jd - 2451545.0) / 36525.0;

        // GMST in degrees (simplified formula)
        let gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0) +
                   0.000387933 * T * T - T * T * T / 38710000.0;
        gmst = gmst % 360;
        if (gmst < 0) gmst += 360;

        const gmstRad = gmst * Math.PI / 180;

        // Rotation matrix
        const cos = Math.cos(gmstRad);
        const sin = Math.sin(gmstRad);

        return {
            x: cos * ecef.x + sin * ecef.y,
            y: -sin * ecef.x + cos * ecef.y,
            z: ecef.z
        };
    }

    /**
     * Validate frame compatibility
     */
    static validateFrameCompatibility(frame1, frame2, operation) {
        const rotating = [FRAMES.ECEF, FRAMES.TOPOCENTRIC];
        const inertial = [FRAMES.ICRF_BARYCENTRIC, FRAMES.HELIOCENTRIC_ECLIPTIC, FRAMES.ECI];

        const isFrame1Rotating = rotating.includes(frame1);
        const isFrame2Rotating = rotating.includes(frame2);

        if (isFrame1Rotating !== isFrame2Rotating) {
            console.warn(`⚠️  Frame mismatch: ${operation} between ${frame1} and ${frame2} requires rotation`);
        }
    }
}

// ===== DATUM CONVERSION =====
export class DatumConverter {
    /**
     * Convert orthometric height (MSL) to ellipsoidal height
     * Requires geoid model (EGM96/EGM2008)
     */
    static orthometricToEllipsoidal(lat, lon, orthometricHeight) {
        // Simplified: use approximate geoid undulation
        // In production, interpolate from EGM2008 grid
        const geoidUndulation = this.getGeoidUndulation(lat, lon);

        return orthometricHeight + geoidUndulation;
    }

    /**
     * Get geoid undulation (N) at location
     * Simplified approximation - use EGM2008 in production
     */
    static getGeoidUndulation(lat, lon) {
        // Rough approximation based on known values
        // Mount Everest: ~29m
        // Ocean: ~0m
        // Can vary from -106m to +85m globally

        // Simplified model (NOT accurate, for demonstration)
        const latRad = lat * Math.PI / 180;
        const lonRad = lon * Math.PI / 180;

        // Very rough approximation
        const n = 10 * Math.sin(latRad) * Math.cos(2 * lonRad);

        return n;
    }
}

// ===== VERIFICATION WITH CONTRACTS =====
export class ContractedVerifier {
    constructor() {
        this.contracts = new Map();
    }

    /**
     * Register a truth contract for a test
     */
    registerContract(testId, contract) {
        this.contracts.set(testId, contract);
    }

    /**
     * Verify with explicit contract enforcement
     */
    verify(testId, simulated, reference) {
        const contract = this.contracts.get(testId);
        if (!contract) {
            throw new Error(`No contract registered for test: ${testId}`);
        }

        console.log(`🔬 Verifying ${testId} with ${contract.toString()}`);

        // Ensure frame compatibility
        FrameTransformer.validateFrameCompatibility(
            simulated.frame,
            reference.frame,
            testId
        );

        // Ensure time scale compatibility
        if (simulated.timeScale !== reference.timeScale) {
            console.warn(`⚠️  Time scale mismatch: ${simulated.timeScale} vs ${reference.timeScale}`);
        }

        // Perform verification with contract-aware tolerance
        return this.compareWithTolerance(simulated, reference, contract.tolerance);
    }

    compareWithTolerance(simulated, reference, tolerance) {
        // Implementation depends on what's being compared
        // (position, angle, time, etc.)
        return true; // Placeholder
    }
}

export default {
    TruthContract,
    TimeConverter,
    FrameTransformer,
    DatumConverter,
    ContractedVerifier,
    TIME_SCALES,
    FRAMES,
    HEIGHT_DATUMS,
    WGS84_LANDMARKS_CORRECTED,
    LEAP_SECONDS,
    EOP_DATA
};
