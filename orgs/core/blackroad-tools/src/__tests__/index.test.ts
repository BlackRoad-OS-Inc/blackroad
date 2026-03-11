import { describe, it, expect } from 'vitest';
import handler from '../index';
import { createMockEnv, getRequest } from './helpers';

describe('index (fetch handler)', () => {
  const env = createMockEnv();

  it('returns CORS headers on OPTIONS', async () => {
    const req = new Request('https://tools.blackroad.io/tools', { method: 'OPTIONS' });
    const res = await handler.fetch(req, env);
    expect(res.status).toBe(200);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
    expect(res.headers.get('Access-Control-Allow-Methods')).toContain('POST');
  });

  it('returns tool registry at /tools', async () => {
    const req = getRequest('https://tools.blackroad.io/tools');
    const res = await handler.fetch(req, env);
    const body = (await res.json()) as any;

    expect(res.status).toBe(200);
    expect(body.tools).toHaveLength(4);
    expect(body.tools.map((t: any) => t.name).sort()).toEqual(['agent', 'coordination', 'memory', 'reasoning']);
    expect(body.version).toBe('1.0.0');
    expect(body.timestamp).toBeDefined();
  });

  it('returns 404 for unknown paths', async () => {
    const req = getRequest('https://tools.blackroad.io/nope');
    const res = await handler.fetch(req, env);
    expect(res.status).toBe(404);
    const body = (await res.json()) as any;
    expect(body.error).toBe('Tool not found');
  });

  it('routes /tools/agent/* to AgentTools', async () => {
    const req = getRequest('https://tools.blackroad.io/tools/agent/list');
    const res = await handler.fetch(req, env);
    expect(res.status).toBe(200);
    const body = (await res.json()) as any;
    expect(body).toHaveProperty('agents');
  });

  it('routes /tools/memory/* to MemoryTools', async () => {
    const req = getRequest('https://tools.blackroad.io/tools/memory/list');
    const res = await handler.fetch(req, env);
    expect(res.status).toBe(200);
    const body = (await res.json()) as any;
    expect(body).toHaveProperty('memories');
  });

  it('routes /tools/reasoning/* to ReasoningTools', async () => {
    const req = getRequest('https://tools.blackroad.io/tools/reasoning/claims');
    const res = await handler.fetch(req, env);
    expect(res.status).toBe(200);
  });

  it('routes /tools/coordination/* to CoordinationTools', async () => {
    const req = getRequest('https://tools.blackroad.io/tools/coordination/topics');
    const res = await handler.fetch(req, env);
    expect(res.status).toBe(200);
  });
});
