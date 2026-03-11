import { describe, it, expect } from 'vitest';
import { AgentTools } from '../tools/agent';
import { createMockEnv, corsHeaders, getRequest, jsonRequest } from './helpers';

describe('AgentTools', () => {
  const cors = corsHeaders();

  it('lists agents from DB', async () => {
    const env = createMockEnv({
      rows: [
        { id: 'agent-001', type: 'backend', capabilities: '["python","api"]', status: 'active' },
        { id: 'agent-002', type: 'frontend', capabilities: '["react"]', status: 'active' },
      ],
    });

    const req = getRequest('https://tools.blackroad.io/tools/agent/list');
    const res = await AgentTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(res.status).toBe(200);
    expect(body.agents).toHaveLength(2);
    expect(body.count).toBe(2);
    expect(body.offset).toBe(0);
    expect(body.limit).toBe(50);
  });

  it('respects limit and offset params', async () => {
    const env = createMockEnv({ rows: [{ id: 'agent-001' }] });
    const req = getRequest('https://tools.blackroad.io/tools/agent/list?limit=10&offset=5');
    const res = await AgentTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.limit).toBe(10);
    expect(body.offset).toBe(5);
  });

  it('gets a specific agent by ID', async () => {
    const env = createMockEnv({
      rows: [{ id: 'agent-001', type: 'backend', capabilities: '["python"]', status: 'active' }],
    });

    const req = getRequest('https://tools.blackroad.io/tools/agent/get/agent-001');
    const res = await AgentTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(res.status).toBe(200);
    expect(body.agent).toBeDefined();
  });

  it('returns 404 for missing agent', async () => {
    const env = createMockEnv({ rows: [] });
    // Override first() to return null
    env.DB = {
      ...env.DB,
      prepare: () => ({
        bind: () => ({
          all: async () => ({ results: [], success: true, meta: {} }),
          first: async () => null,
          run: async () => ({ success: true, meta: {} }),
        }),
      }),
    } as any;

    const req = getRequest('https://tools.blackroad.io/tools/agent/get/nonexistent');
    const res = await AgentTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });

  it('lists capabilities from active agents', async () => {
    const env = createMockEnv({
      rows: [
        { type: 'backend', capabilities: '["python","api"]' },
        { type: 'frontend', capabilities: '["react","css"]' },
      ],
    });

    const req = getRequest('https://tools.blackroad.io/tools/agent/capabilities');
    const res = await AgentTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.capabilities).toContain('python');
    expect(body.capabilities).toContain('react');
    expect(body.byType).toHaveProperty('backend');
    expect(body.byType).toHaveProperty('frontend');
  });

  it('lists agent types with counts', async () => {
    const env = createMockEnv({
      rows: [
        { type: 'backend', count: 5 },
        { type: 'frontend', count: 3 },
      ],
    });

    const req = getRequest('https://tools.blackroad.io/tools/agent/types');
    const res = await AgentTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.types).toHaveLength(2);
  });

  it('finds agents by capabilities (matchAll=false)', async () => {
    const env = createMockEnv({
      rows: [{ id: 'agent-001', capabilities: '["python","api"]', status: 'active' }],
    });

    const req = jsonRequest('https://tools.blackroad.io/tools/agent/find', {
      capabilities: ['python'],
      matchAll: false,
    });
    const res = await AgentTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.agents).toBeDefined();
    expect(body.query.capabilities).toEqual(['python']);
    expect(body.query.matchAll).toBe(false);
  });

  it('returns 404 for unknown agent endpoint', async () => {
    const env = createMockEnv();
    const req = getRequest('https://tools.blackroad.io/tools/agent/nope');
    const res = await AgentTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });
});
