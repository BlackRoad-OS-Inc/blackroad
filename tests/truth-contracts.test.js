import assert from 'node:assert/strict';
import test from 'node:test';

import {
    TruthContract,
    TimeConverter,
    FrameTransformer,
    DatumConverter,
    TIME_SCALES,
    FRAMES,
    HEIGHT_DATUMS
} from '../truth-contracts.js';

test('TruthContract validates frames, time scales, and datums', () => {
    const contract = new TruthContract({
        frame: FRAMES.ECI,
        timeScale: TIME_SCALES.UTC,
        heightDatum: HEIGHT_DATUMS.ELLIPSOID,
        tolerance: { meters: 1 }
    });

    assert.equal(
        contract.toString(),
        `Contract(frame=${FRAMES.ECI}, time=${TIME_SCALES.UTC}, datum=${HEIGHT_DATUMS.ELLIPSOID})`
    );

    assert.throws(
        () => new TruthContract({ frame: 'BAD', timeScale: TIME_SCALES.UTC }),
        /Invalid frame/
    );
    assert.throws(
        () => new TruthContract({ frame: FRAMES.ECI, timeScale: 'BAD' }),
        /Invalid time scale/
    );
    assert.throws(
        () => new TruthContract({ frame: FRAMES.ECI, timeScale: TIME_SCALES.UTC, heightDatum: 'BAD' }),
        /Invalid height datum/
    );
});

test('TimeConverter handles leap seconds and time conversions', () => {
    const preLeap = new Date('1972-06-30T23:59:59Z');
    const firstLeap = new Date('1972-07-01T00:00:00Z');
    const current = new Date('2017-01-01T00:00:00Z');

    assert.equal(TimeConverter.getLeapSeconds(preLeap), 10);
    assert.equal(TimeConverter.getLeapSeconds(firstLeap), 11);
    assert.equal(TimeConverter.getLeapSeconds(current), 37);

    const tai = TimeConverter.utcToTAI(current);
    assert.equal(tai.getTime() - current.getTime(), 37 * 1000);

    const roundTripUtc = TimeConverter.convert(tai, TIME_SCALES.TAI, TIME_SCALES.UTC);
    assert.equal(roundTripUtc.getTime(), current.getTime());
});

test('TimeConverter dateToJulianDate uses Unix epoch reference', () => {
    const epoch = new Date(Date.UTC(1970, 0, 1, 0, 0, 0));
    const jd = TimeConverter.dateToJulianDate(epoch);
    assert.equal(jd, 2440587.5);
});

test('FrameTransformer warns on rotating vs inertial frames', () => {
    const warnings = [];
    const originalWarn = console.warn;
    console.warn = (message) => warnings.push(message);

    FrameTransformer.validateFrameCompatibility(FRAMES.ECEF, FRAMES.ECI, 'test');

    console.warn = originalWarn;
    assert.equal(warnings.length, 1);
});

test('FrameTransformer does not warn for same frame category', () => {
    const warnings = [];
    const originalWarn = console.warn;
    console.warn = (message) => warnings.push(message);

    FrameTransformer.validateFrameCompatibility(FRAMES.ECEF, FRAMES.TOPOCENTRIC, 'test');

    console.warn = originalWarn;
    assert.equal(warnings.length, 0);
});

test('DatumConverter returns expected undulation at equator', () => {
    const undulation = DatumConverter.getGeoidUndulation(0, 0);
    assert.ok(Math.abs(undulation) < 1e-9);

    const height = DatumConverter.orthometricToEllipsoidal(0, 0, 100);
    assert.equal(height, 100);
});
