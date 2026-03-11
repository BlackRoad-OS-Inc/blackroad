import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import SelectorEngine from '../lib/selector.js';

describe('SelectorEngine', () => {
  const inventory = {
    nodes: [
      { name: 'alice', role: 'pi', env: 'prod', tag: 'gateway' },
      { name: 'cecilia', role: 'pi', env: 'prod', tag: 'ai' },
      { name: 'octavia', role: 'pi', env: 'prod', tag: 'storage' },
      { name: 'aria', role: 'pi', env: 'staging', tag: 'ui' },
      { name: 'gematria', role: 'droplet', env: 'prod', tag: 'hub' },
      { name: 'anastasia', role: 'droplet', env: 'prod', tag: 'deprecated' },
    ],
  };

  describe('parse()', () => {
    it('parses simple equality filter', () => {
      const engine = new SelectorEngine(inventory);
      const result = engine.parse('role=pi');
      assert.equal(result.filters.length, 1);
      assert.equal(result.filters[0].field, 'role');
      assert.equal(result.filters[0].operator, '=');
      assert.equal(result.filters[0].value, 'pi');
      assert.equal(result.limit, null);
      assert.equal(result.percent, null);
    });

    it('parses inequality filter', () => {
      const engine = new SelectorEngine(inventory);
      const result = engine.parse('tag!=deprecated');
      assert.equal(result.filters.length, 1);
      assert.equal(result.filters[0].operator, '!=');
      assert.equal(result.filters[0].value, 'deprecated');
    });

    it('parses limit', () => {
      const engine = new SelectorEngine(inventory);
      const result = engine.parse('role=pi,limit=2');
      assert.equal(result.limit, 2);
    });

    it('parses percent', () => {
      const engine = new SelectorEngine(inventory);
      const result = engine.parse('role=pi,percent=50');
      assert.equal(result.percent, 50);
    });

    it('parses multiple filters', () => {
      const engine = new SelectorEngine(inventory);
      const result = engine.parse('role=pi,env=prod');
      assert.equal(result.filters.length, 2);
    });
  });

  describe('parseFilter()', () => {
    it('handles equality operator', () => {
      const engine = new SelectorEngine(inventory);
      const filter = engine.parseFilter('role=pi');
      assert.deepEqual(filter, { field: 'role', operator: '=', value: 'pi' });
    });

    it('handles inequality operator', () => {
      const engine = new SelectorEngine(inventory);
      const filter = engine.parseFilter('env!=staging');
      assert.deepEqual(filter, { field: 'env', operator: '!=', value: 'staging' });
    });
  });

  describe('resolve()', () => {
    it('filters by role', () => {
      const engine = new SelectorEngine(inventory);
      const results = engine.resolve('role=pi');
      assert.equal(results.length, 4);
      assert.ok(results.every((n) => n.role === 'pi'));
    });

    it('filters by role and env', () => {
      const engine = new SelectorEngine(inventory);
      const results = engine.resolve('role=pi,env=prod');
      assert.equal(results.length, 3);
      assert.ok(results.every((n) => n.role === 'pi' && n.env === 'prod'));
    });

    it('filters with inequality', () => {
      const engine = new SelectorEngine(inventory);
      const results = engine.resolve('tag!=deprecated');
      assert.equal(results.length, 5);
      assert.ok(results.every((n) => n.tag !== 'deprecated'));
    });

    it('applies limit', () => {
      const engine = new SelectorEngine(inventory);
      const results = engine.resolve('role=pi,limit=2');
      assert.equal(results.length, 2);
    });

    it('applies percent sampling', () => {
      const engine = new SelectorEngine(inventory);
      const results = engine.resolve('role=pi,percent=50');
      // 50% of 4 pi nodes = 2
      assert.equal(results.length, 2);
    });

    it('returns empty array when nothing matches', () => {
      const engine = new SelectorEngine(inventory);
      const results = engine.resolve('role=laptop');
      assert.equal(results.length, 0);
    });

    it('returns all nodes with broad filter', () => {
      const engine = new SelectorEngine(inventory);
      const results = engine.resolve('env=prod');
      assert.equal(results.length, 5);
    });
  });

  describe('matchFilter()', () => {
    it('matches equality', () => {
      const engine = new SelectorEngine(inventory);
      const node = { role: 'pi', env: 'prod' };
      assert.equal(engine.matchFilter(node, { field: 'role', operator: '=', value: 'pi' }), true);
    });

    it('rejects non-match', () => {
      const engine = new SelectorEngine(inventory);
      const node = { role: 'droplet', env: 'prod' };
      assert.equal(engine.matchFilter(node, { field: 'role', operator: '=', value: 'pi' }), false);
    });

    it('handles inequality match', () => {
      const engine = new SelectorEngine(inventory);
      const node = { role: 'pi', tag: 'active' };
      assert.equal(
        engine.matchFilter(node, { field: 'tag', operator: '!=', value: 'deprecated' }),
        true
      );
    });

    it('returns false for unknown operator', () => {
      const engine = new SelectorEngine(inventory);
      const node = { role: 'pi' };
      assert.equal(engine.matchFilter(node, { field: 'role', operator: '>', value: 'pi' }), false);
    });
  });

  describe('simpleHash()', () => {
    it('returns a non-negative integer', () => {
      const engine = new SelectorEngine(inventory);
      const hash = engine.simpleHash('test-string');
      assert.equal(typeof hash, 'number');
      assert.ok(hash >= 0);
    });

    it('returns consistent results', () => {
      const engine = new SelectorEngine(inventory);
      const hash1 = engine.simpleHash('hello');
      const hash2 = engine.simpleHash('hello');
      assert.equal(hash1, hash2);
    });

    it('returns different hashes for different inputs', () => {
      const engine = new SelectorEngine(inventory);
      const hash1 = engine.simpleHash('alice');
      const hash2 = engine.simpleHash('bob');
      assert.notEqual(hash1, hash2);
    });
  });

  describe('stableSample()', () => {
    it('returns requested count', () => {
      const engine = new SelectorEngine(inventory);
      const items = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }, { id: 5 }];
      const sampled = engine.stableSample(items, 3);
      assert.equal(sampled.length, 3);
    });

    it('returns stable results across calls', () => {
      const engine = new SelectorEngine(inventory);
      const items = [{ id: 'a' }, { id: 'b' }, { id: 'c' }, { id: 'd' }];
      const sample1 = engine.stableSample(items, 2);
      const sample2 = engine.stableSample(items, 2);
      assert.deepEqual(sample1, sample2);
    });

    it('handles count larger than items', () => {
      const engine = new SelectorEngine(inventory);
      const items = [{ id: 1 }, { id: 2 }];
      const sampled = engine.stableSample(items, 5);
      assert.equal(sampled.length, 2);
    });
  });
});
