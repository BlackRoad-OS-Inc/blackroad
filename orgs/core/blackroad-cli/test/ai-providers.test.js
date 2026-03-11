import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { ClaudeProvider, OllamaProvider } from '../lib/ai-providers.js';

describe('ClaudeProvider', () => {
  describe('constructor', () => {
    it('defaults to env variable', () => {
      const origKey = process.env.ANTHROPIC_API_KEY;
      process.env.ANTHROPIC_API_KEY = 'test-key-123';
      const provider = new ClaudeProvider();
      assert.equal(provider.apiKey, 'test-key-123');
      if (origKey) {
        process.env.ANTHROPIC_API_KEY = origKey;
      } else {
        delete process.env.ANTHROPIC_API_KEY;
      }
    });

    it('accepts explicit API key', () => {
      const provider = new ClaudeProvider('explicit-key');
      assert.equal(provider.apiKey, 'explicit-key');
    });

    it('initializes empty conversation history', () => {
      const provider = new ClaudeProvider('key');
      assert.deepEqual(provider.conversationHistory, []);
    });

    it('sets default model', () => {
      const provider = new ClaudeProvider('key');
      assert.ok(provider.model.startsWith('claude-'));
    });
  });

  describe('chat() without API key', () => {
    it('returns error message when no key set', async () => {
      const provider = new ClaudeProvider(undefined);
      // Force apiKey to be falsy
      provider.apiKey = '';
      const result = await provider.chat('hello');
      assert.ok(result.includes('Error'));
      assert.ok(result.includes('ANTHROPIC_API_KEY'));
    });
  });

  describe('clear()', () => {
    it('clears conversation history', () => {
      const provider = new ClaudeProvider('key');
      provider.conversationHistory.push({ role: 'user', content: 'test' });
      const result = provider.clear();
      assert.deepEqual(provider.conversationHistory, []);
      assert.ok(result.includes('cleared'));
    });
  });
});

describe('OllamaProvider', () => {
  let provider;

  beforeEach(() => {
    provider = new OllamaProvider();
  });

  describe('constructor', () => {
    it('sets default model', () => {
      assert.equal(provider.currentModel, 'llama3.2');
    });

    it('initializes empty conversation history', () => {
      assert.deepEqual(provider.conversationHistory, []);
    });

    it('sets base URL to localhost', () => {
      assert.equal(provider.baseUrl, 'http://localhost:11434');
    });
  });

  describe('clear()', () => {
    it('clears conversation history', () => {
      provider.conversationHistory.push({ role: 'user', content: 'test' });
      const result = provider.clear();
      assert.deepEqual(provider.conversationHistory, []);
      assert.ok(result.includes('cleared'));
    });
  });

  describe('chat() with connection refused', () => {
    it('returns helpful error when Ollama is not running', async () => {
      // Use a port that's definitely not serving Ollama
      provider.baseUrl = 'http://localhost:19999';
      const result = await provider.chat('hello');
      assert.ok(result.includes('Error'));
    });
  });
});
