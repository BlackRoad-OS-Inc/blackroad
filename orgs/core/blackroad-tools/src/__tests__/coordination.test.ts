import { describe, it, expect } from 'vitest';
import { CoordinationTools } from '../tools/coordination';
import { createMockEnv, corsHeaders, getRequest, jsonRequest } from './helpers';

describe('CoordinationTools', () => {
  const cors = corsHeaders();

  it('publishes an event to a topic', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/publish',
      { topic: 'agent.status', type: 'heartbeat', payload: { alive: true } },
      { 'X-Agent-ID': 'pub-agent' }
    );

    const res = await CoordinationTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(res.status).toBe(200);
    expect(body.published).toBe(true);
    expect(body.event_id).toMatch(/^evt_/);
    expect(body.topic).toBe('agent.status');
  });

  it('subscribes and retrieves published events', async () => {
    const env = createMockEnv();

    // Publish
    const pubReq = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/publish',
      { topic: 'test.topic', type: 'update', payload: { data: 42 } },
      { 'X-Agent-ID': 'writer' }
    );
    await CoordinationTools.handle(pubReq, env, cors);

    // Subscribe
    const subReq = getRequest('https://tools.blackroad.io/tools/coordination/subscribe/test.topic');
    const res = await CoordinationTools.handle(subReq, env, cors);
    const body = (await res.json()) as any;

    expect(body.topic).toBe('test.topic');
    expect(body.events).toHaveLength(1);
    expect(body.events[0].payload).toEqual({ data: 42 });
    expect(body.events[0].source_agent).toBe('writer');
  });

  it('lists known topics', async () => {
    const env = createMockEnv();
    const req = getRequest('https://tools.blackroad.io/tools/coordination/topics');
    const res = await CoordinationTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.topics).toContain('agent.status');
    expect(body.topics).toContain('task.created');
    expect(body.count).toBeGreaterThan(0);
  });

  it('delegates a task to a specific agent', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/delegate',
      {
        task_type: 'code_review',
        description: 'Review auth module',
        target_agent: 'octavia',
        priority: 2,
      },
      { 'X-Agent-ID': 'coordinator' }
    );

    const res = await CoordinationTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.delegated).toBe(true);
    expect(body.task_id).toMatch(/^task_/);
    expect(body.assigned_to).toBe('octavia');
    expect(body.status).toBe('pending');
  });

  it('returns 400 when no capable agent found for delegation', async () => {
    // DB returns no results (no agents match)
    const env = createMockEnv({ rows: [] });
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

    const req = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/delegate',
      {
        task_type: 'special',
        description: 'Needs quantum capabilities',
        required_capabilities: ['quantum'],
      },
      { 'X-Agent-ID': 'coordinator' }
    );

    const res = await CoordinationTools.handle(req, env, cors);
    expect(res.status).toBe(400);
    const body = (await res.json()) as any;
    expect(body.error).toBe('No capable agent found');
  });

  it('retrieves task queue for an agent', async () => {
    const env = createMockEnv();

    // Delegate a task first
    const delegateReq = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/delegate',
      { task_type: 'deploy', description: 'Deploy v2', target_agent: 'alice' },
      { 'X-Agent-ID': 'boss' }
    );
    await CoordinationTools.handle(delegateReq, env, cors);

    // Get alice's tasks
    const taskReq = getRequest('https://tools.blackroad.io/tools/coordination/tasks', {
      'X-Agent-ID': 'alice',
    });
    const res = await CoordinationTools.handle(taskReq, env, cors);
    const body = (await res.json()) as any;

    expect(body.tasks).toHaveLength(1);
    expect(body.tasks[0].type).toBe('deploy');
    expect(body.tasks[0].assigned_to).toBe('alice');
    expect(body.agent_id).toBe('alice');
  });

  it('completes a task', async () => {
    const env = createMockEnv();

    // Delegate
    const delegateReq = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/delegate',
      { task_type: 'test', description: 'Run tests', target_agent: 'echo' },
      { 'X-Agent-ID': 'boss' }
    );
    const delegateRes = await CoordinationTools.handle(delegateReq, env, cors);
    const { task_id } = (await delegateRes.json()) as any;

    // Complete
    const completeReq = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/complete',
      { task_id, status: 'completed', result: { tests_passed: 42 } },
      { 'X-Agent-ID': 'echo' }
    );
    const res = await CoordinationTools.handle(completeReq, env, cors);
    const body = (await res.json()) as any;

    expect(body.completed).toBe(true);
    expect(body.task_id).toBe(task_id);
    expect(body.status).toBe('completed');
  });

  it('returns 404 when completing nonexistent task', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/coordination/complete',
      { task_id: 'task_nope', status: 'completed' },
      { 'X-Agent-ID': 'agent' }
    );

    const res = await CoordinationTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });

  it('returns 404 for unknown coordination endpoint', async () => {
    const env = createMockEnv();
    const req = getRequest('https://tools.blackroad.io/tools/coordination/nope');
    const res = await CoordinationTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });
});
