import { describe, it, expect } from 'vitest';
import { MemoryTools } from '../tools/memory';
import { createMockEnv, corsHeaders, getRequest, jsonRequest } from './helpers';

describe('MemoryTools', () => {
  const cors = corsHeaders();

  it('stores a memory and returns hash', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/memory/store',
      { content: 'user prefers dark mode', type: 'fact' },
      { 'X-Agent-ID': 'test-agent' }
    );

    const res = await MemoryTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(res.status).toBe(200);
    expect(body.stored).toBe(true);
    expect(body.hash).toBeDefined();
    expect(body.hash.length).toBe(16);
    expect(body.key).toContain('memory:test-agent:');
    expect(body.timestamp).toBeGreaterThan(0);
  });

  it('retrieves a stored memory by hash', async () => {
    const env = createMockEnv();

    // Store first
    const storeReq = jsonRequest(
      'https://tools.blackroad.io/tools/memory/store',
      { content: 'test memory', type: 'observation' },
      { 'X-Agent-ID': 'agent-1' }
    );
    const storeRes = await MemoryTools.handle(storeReq, env, cors);
    const { hash } = (await storeRes.json()) as any;

    // Retrieve
    const retrieveReq = getRequest(`https://tools.blackroad.io/tools/memory/retrieve/${hash}`, {
      'X-Agent-ID': 'agent-1',
    });
    const retrieveRes = await MemoryTools.handle(retrieveReq, env, cors);
    const body = (await retrieveRes.json()) as any;

    expect(retrieveRes.status).toBe(200);
    expect(body.memory.content).toBe('test memory');
    expect(body.memory.type).toBe('observation');
    expect(body.memory.truth_state).toBe(1);
  });

  it('returns 404 for missing memory', async () => {
    const env = createMockEnv();
    const req = getRequest('https://tools.blackroad.io/tools/memory/retrieve/deadbeef', {
      'X-Agent-ID': 'agent-1',
    });
    const res = await MemoryTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });

  it('lists memories for an agent', async () => {
    const env = createMockEnv();

    // Store two memories
    for (const content of ['fact one', 'fact two']) {
      const req = jsonRequest(
        'https://tools.blackroad.io/tools/memory/store',
        { content, type: 'fact' },
        { 'X-Agent-ID': 'lister' }
      );
      await MemoryTools.handle(req, env, cors);
    }

    const listReq = getRequest('https://tools.blackroad.io/tools/memory/list', { 'X-Agent-ID': 'lister' });
    const res = await MemoryTools.handle(listReq, env, cors);
    const body = (await res.json()) as any;

    expect(body.memories).toHaveLength(2);
    expect(body.count).toBe(2);
  });

  it('returns empty list for agent with no memories', async () => {
    const env = createMockEnv();
    const req = getRequest('https://tools.blackroad.io/tools/memory/list', { 'X-Agent-ID': 'empty-agent' });
    const res = await MemoryTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.memories).toEqual([]);
    expect(body.count).toBe(0);
  });

  it('searches memories by content', async () => {
    const env = createMockEnv();

    // Store memories
    for (const content of ['dark mode preference', 'timezone is CST', 'dark theme enabled']) {
      const req = jsonRequest(
        'https://tools.blackroad.io/tools/memory/store',
        { content, type: 'fact' },
        { 'X-Agent-ID': 'searcher' }
      );
      await MemoryTools.handle(req, env, cors);
    }

    const searchReq = jsonRequest(
      'https://tools.blackroad.io/tools/memory/search',
      { query: 'dark' },
      { 'X-Agent-ID': 'searcher' }
    );
    const res = await MemoryTools.handle(searchReq, env, cors);
    const body = (await res.json()) as any;

    expect(body.results).toHaveLength(2);
    expect(body.results.every((r: any) => r.content.includes('dark'))).toBe(true);
  });

  it('invalidates a memory (sets truth_state to -1)', async () => {
    const env = createMockEnv();

    // Store
    const storeReq = jsonRequest(
      'https://tools.blackroad.io/tools/memory/store',
      { content: 'old fact', type: 'fact' },
      { 'X-Agent-ID': 'inv-agent' }
    );
    const storeRes = await MemoryTools.handle(storeReq, env, cors);
    const { hash } = (await storeRes.json()) as any;

    // Invalidate
    const invReq = new Request(`https://tools.blackroad.io/tools/memory/invalidate/${hash}`, {
      method: 'DELETE',
      headers: { 'X-Agent-ID': 'inv-agent' },
    });
    const invRes = await MemoryTools.handle(invReq, env, cors);
    const body = (await invRes.json()) as any;

    expect(body.invalidated).toBe(true);

    // Verify truth_state changed
    const getReq = getRequest(`https://tools.blackroad.io/tools/memory/retrieve/${hash}`, {
      'X-Agent-ID': 'inv-agent',
    });
    const getRes = await MemoryTools.handle(getReq, env, cors);
    const mem = (await getRes.json()) as any;
    expect(mem.memory.truth_state).toBe(-1);
  });

  it('returns 404 for unknown memory endpoint', async () => {
    const env = createMockEnv();
    const req = getRequest('https://tools.blackroad.io/tools/memory/nope');
    const res = await MemoryTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });
});
