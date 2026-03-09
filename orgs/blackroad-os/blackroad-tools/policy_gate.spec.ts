import assert from 'node:assert/strict';
import { test } from 'node:test';
import { determineConclusion, evaluatePolicyCases, formatSummaryTable, postPolicyGateCheck } from './policy_gate.js';

test('evaluatePolicyCases summarises considered cases', () => {
  const summary = evaluatePolicyCases([
    { case: 'alpha', label: 'good', rules: [1, 2], warnings: [1], violations: [] },
    { case: 'beta', label: 'borderline', rules: [1], warnings: [], violations: [] },
    { case: 'gamma', label: 'violation', rules: [1], warnings: [], violations: [1] },
  ]);
  assert.equal(summary.cases.length, 2);
  assert.equal(summary.totalRules, 3);
  assert.equal(summary.totalViolations, 0);
  assert.equal(summary.goodViolations.length, 0);
  const table = formatSummaryTable(summary);
  assert.ok(table.includes('| alpha | good | 2 | 0 | 1 |'));
});

test('determineConclusion fails when violations are present', () => {
  const summary = evaluatePolicyCases([
    { case: 'alpha', label: 'good', rules: [1], warnings: [], violations: [1] },
  ]);
  assert.equal(determineConclusion(summary), 'failure');
});

test('postPolicyGateCheck sends payload to gateway endpoint when provided', async () => {
  const originalFetch = global.fetch;
  const calls: { url: string; init: RequestInit }[] = [];
  global.fetch = (async (input: RequestInfo, init?: RequestInit) => {
    calls.push({ url: input as string, init: init ?? {} });
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  }) as typeof global.fetch;

  try {
    await postPolicyGateCheck({ commit: 'abc123', summary: 'demo', status: 'success', endpoint: 'http://example.com/checks' });
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, 'http://example.com/checks');
    const body = JSON.parse((calls[0].init.body as string) ?? '{}');
    assert.equal(body.commit, 'abc123');
    assert.equal(body.status, 'success');
  } finally {
    global.fetch = originalFetch;
  }
});
