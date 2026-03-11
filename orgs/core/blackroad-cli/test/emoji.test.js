import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { emoji } from '../lib/emoji.js';

describe('emoji dictionary', () => {
  it('exports an object', () => {
    assert.equal(typeof emoji, 'object');
    assert.ok(!Array.isArray(emoji));
  });

  it('has core emotion entries', () => {
    assert.ok(emoji.happy);
    assert.ok(emoji.sad);
    assert.ok(emoji.angry);
    assert.ok(emoji.love);
  });

  it('has tech-related entries', () => {
    assert.ok(emoji.robot);
  });

  it('all values are strings', () => {
    for (const [key, value] of Object.entries(emoji)) {
      assert.equal(typeof value, 'string', `emoji.${key} should be a string`);
    }
  });

  it('has a reasonable number of entries', () => {
    const count = Object.keys(emoji).length;
    assert.ok(count > 20, `expected more than 20 emoji entries, got ${count}`);
  });

  it('values are non-empty', () => {
    for (const [key, value] of Object.entries(emoji)) {
      assert.ok(value.length > 0, `emoji.${key} should not be empty`);
    }
  });
});
