import { describe, it, expect } from 'vitest';
import { ReasoningTools } from '../tools/reasoning';
import { createMockEnv, corsHeaders, getRequest, jsonRequest } from './helpers';

describe('ReasoningTools', () => {
  const cors = corsHeaders();

  it('evaluates a claim and returns unknown state', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/evaluate',
      { claim: 'The API uses REST' },
      { 'X-Agent-ID': 'eval-agent' }
    );

    const res = await ReasoningTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(res.status).toBe(200);
    expect(body.evaluated).toBe(true);
    expect(body.initial_state).toBe(0); // Unknown
    expect(body.contradictions.detected).toBe(false);
  });

  it('commits a claim with truth state', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/commit',
      { claim: 'Server uses PostgreSQL', truth_state: 1, confidence: 0.95 },
      { 'X-Agent-ID': 'commit-agent' }
    );

    const res = await ReasoningTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.committed).toBe(true);
    expect(body.claim.truth_state).toBe(1);
    expect(body.claim.confidence).toBe(0.95);
    expect(body.truth_state_label).toBe('true');
  });

  it('clamps confidence to [0, 1]', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/commit',
      { claim: 'overconfident', truth_state: 1, confidence: 5.0 },
      { 'X-Agent-ID': 'clamp-agent' }
    );

    const res = await ReasoningTools.handle(req, env, cors);
    const body = (await res.json()) as any;
    expect(body.claim.confidence).toBe(1);
  });

  it('labels false truth state', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/commit',
      { claim: 'This is wrong', truth_state: -1, confidence: 0.8 },
      { 'X-Agent-ID': 'false-agent' }
    );

    const res = await ReasoningTools.handle(req, env, cors);
    const body = (await res.json()) as any;
    expect(body.truth_state_label).toBe('false');
  });

  it('quarantines contradicting claims', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/quarantine',
      {
        claim_ids: ['claim_1', 'claim_2'],
        reason: 'Contradicting API protocol claims',
        resolution_strategy: 'human_review',
      },
      { 'X-Agent-ID': 'q-agent' }
    );

    const res = await ReasoningTools.handle(req, env, cors);
    const body = (await res.json()) as any;

    expect(body.quarantined).toBe(true);
    expect(body.claims_affected).toBe(2);
    expect(body.resolution_strategy).toBe('human_review');
  });

  it('resolves a quarantine', async () => {
    const env = createMockEnv();

    // Quarantine first
    const qReq = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/quarantine',
      { claim_ids: ['c1'], reason: 'test' },
      { 'X-Agent-ID': 'resolve-agent' }
    );
    const qRes = await ReasoningTools.handle(qReq, env, cors);
    const { quarantine_id } = (await qRes.json()) as any;

    // Resolve
    const rReq = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/resolve',
      {
        quarantine_id,
        resolution: 'accept_first',
        justification: 'First claim has higher confidence',
      },
      { 'X-Agent-ID': 'resolve-agent' }
    );
    const rRes = await ReasoningTools.handle(rReq, env, cors);
    const body = (await rRes.json()) as any;

    expect(body.resolved).toBe(true);
    expect(body.resolution).toBe('accept_first');
  });

  it('returns 404 for missing quarantine on resolve', async () => {
    const env = createMockEnv();
    const req = jsonRequest(
      'https://tools.blackroad.io/tools/reasoning/resolve',
      { quarantine_id: 'nonexistent', resolution: 'reject_both', justification: 'nope' },
      { 'X-Agent-ID': 'agent' }
    );

    const res = await ReasoningTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });

  it('lists committed claims', async () => {
    const env = createMockEnv();

    // Commit two claims
    for (const claim of ['claim A', 'claim B']) {
      const req = jsonRequest(
        'https://tools.blackroad.io/tools/reasoning/commit',
        { claim, truth_state: 1, confidence: 0.9 },
        { 'X-Agent-ID': 'list-agent' }
      );
      await ReasoningTools.handle(req, env, cors);
    }

    const listReq = getRequest('https://tools.blackroad.io/tools/reasoning/claims', { 'X-Agent-ID': 'list-agent' });
    const res = await ReasoningTools.handle(listReq, env, cors);
    const body = (await res.json()) as any;

    expect(body.claims).toHaveLength(2);
    expect(body.count).toBe(2);
  });

  it('returns 404 for unknown reasoning endpoint', async () => {
    const env = createMockEnv();
    const req = getRequest('https://tools.blackroad.io/tools/reasoning/nope');
    const res = await ReasoningTools.handle(req, env, cors);
    expect(res.status).toBe(404);
  });
});
