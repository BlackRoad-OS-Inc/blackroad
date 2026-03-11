import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import os from 'os';
import Telemetry from '../lib/telemetry.js';

describe('Telemetry', () => {
  let telemetry;
  let tmpDir;
  let origHome;

  beforeEach(() => {
    // Use a temp directory to avoid polluting the real ~/.blackroad
    tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'br-telemetry-test-'));
    origHome = os.homedir;
    // Patch homedir for the Telemetry constructor
    os.homedir = () => tmpDir;
    telemetry = new Telemetry();
  });

  afterEach(() => {
    os.homedir = origHome;
    fs.rmSync(tmpDir, { recursive: true, force: true });
  });

  describe('constructor', () => {
    it('creates telemetry directory', () => {
      assert.ok(fs.existsSync(telemetry.telemetryDir));
    });

    it('sets metricsFile path', () => {
      assert.ok(telemetry.metricsFile.endsWith('metrics.jsonl'));
    });
  });

  describe('record()', () => {
    it('writes a metric to the file', () => {
      telemetry.record({ type: 'test', value: 42 });
      const content = fs.readFileSync(telemetry.metricsFile, 'utf-8');
      const parsed = JSON.parse(content.trim());
      assert.equal(parsed.type, 'test');
      assert.equal(parsed.value, 42);
      assert.ok(parsed.timestamp);
    });

    it('appends multiple metrics', () => {
      telemetry.record({ type: 'a' });
      telemetry.record({ type: 'b' });
      telemetry.record({ type: 'c' });
      const lines = fs.readFileSync(telemetry.metricsFile, 'utf-8').trim().split('\n');
      assert.equal(lines.length, 3);
    });

    it('adds session from env', () => {
      process.env.BR_SESSION_ID = 'test-session-123';
      telemetry.record({ type: 'test' });
      const content = fs.readFileSync(telemetry.metricsFile, 'utf-8');
      const parsed = JSON.parse(content.trim());
      assert.equal(parsed.session, 'test-session-123');
      delete process.env.BR_SESSION_ID;
    });
  });

  describe('recordCommand()', () => {
    it('records a command metric', () => {
      telemetry.recordCommand('status', 150, true);
      const metrics = telemetry.getMetrics();
      assert.equal(metrics.length, 1);
      assert.equal(metrics[0].type, 'command');
      assert.equal(metrics[0].command, 'status');
      assert.equal(metrics[0].duration, 150);
      assert.equal(metrics[0].success, true);
    });
  });

  describe('recordError()', () => {
    it('records an error metric', () => {
      const err = new Error('test failure');
      telemetry.recordError(err, { command: 'deploy' });
      const metrics = telemetry.getMetrics();
      assert.equal(metrics.length, 1);
      assert.equal(metrics[0].type, 'error');
      assert.equal(metrics[0].error, 'test failure');
      assert.equal(metrics[0].command, 'deploy');
      assert.ok(metrics[0].stack);
    });
  });

  describe('getMetrics()', () => {
    it('returns empty array when no file exists', () => {
      // Remove the file if it was created
      if (fs.existsSync(telemetry.metricsFile)) {
        fs.unlinkSync(telemetry.metricsFile);
      }
      const metrics = telemetry.getMetrics();
      assert.deepEqual(metrics, []);
    });

    it('respects limit parameter', () => {
      for (let i = 0; i < 20; i++) {
        telemetry.record({ type: 'test', index: i });
      }
      const metrics = telemetry.getMetrics(5);
      assert.equal(metrics.length, 5);
      // Should return the last 5 (most recent)
      assert.equal(metrics[0].index, 15);
    });
  });

  describe('getCommandStats()', () => {
    it('aggregates command statistics', () => {
      telemetry.recordCommand('status', 100, true);
      telemetry.recordCommand('status', 200, true);
      telemetry.recordCommand('status', 300, false);
      telemetry.recordCommand('deploy', 500, true);

      const stats = telemetry.getCommandStats();
      const statusStat = stats.find((s) => s.command === 'status');
      const deployStat = stats.find((s) => s.command === 'deploy');

      assert.ok(statusStat);
      assert.equal(statusStat.count, 3);
      assert.equal(statusStat.avgDuration, 200);
      assert.equal(statusStat.successRate, 67);

      assert.ok(deployStat);
      assert.equal(deployStat.count, 1);
      assert.equal(deployStat.avgDuration, 500);
      assert.equal(deployStat.successRate, 100);
    });

    it('returns empty array when no commands recorded', () => {
      const stats = telemetry.getCommandStats();
      assert.deepEqual(stats, []);
    });
  });
});
