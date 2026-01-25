import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { execSync } from 'node:child_process';

export type GateCheckState = 'success' | 'failure' | 'neutral';

interface PolicyCaseRecord {
  case?: string;
  label?: string;
  rules?: unknown[];
  warnings?: unknown[];
  violations?: unknown[];
}

export interface CaseSummary {
  id: string;
  label: string;
  rules: number;
  warnings: number;
  violations: number;
}

export interface EvaluationSummary {
  cases: CaseSummary[];
  totalRules: number;
  totalWarnings: number;
  totalViolations: number;
  goodViolations: CaseSummary[];
  failingCases: CaseSummary[];
}

const CONSIDERED_LABELS = new Set(['good', 'borderline']);

export async function loadPolicyCases(casesDir: string): Promise<PolicyCaseRecord[]> {
  let entries: string[] = [];
  try {
    entries = await fs.readdir(casesDir);
  } catch (error: unknown) {
    if ((error as NodeJS.ErrnoException)?.code === 'ENOENT') {
      return [];
    }
    throw error;
  }

  const records: PolicyCaseRecord[] = [];
  for (const entry of entries) {
    if (!entry.endsWith('.json')) {
      continue;
    }
    const filePath = path.join(casesDir, entry);
    const raw = await fs.readFile(filePath, 'utf-8');
    try {
      records.push(JSON.parse(raw) as PolicyCaseRecord);
    } catch (error) {
      throw new Error(`Failed to parse policy case ${entry}: ${(error as Error).message}`);
    }
  }
  return records;
}

export function evaluatePolicyCases(records: PolicyCaseRecord[]): EvaluationSummary {
  const cases: CaseSummary[] = [];
  for (const record of records) {
    const label = typeof record.label === 'string' ? record.label.toLowerCase() : '';
    if (!CONSIDERED_LABELS.has(label)) {
      continue;
    }
    const id = typeof record.case === 'string' && record.case.trim() ? record.case.trim() : 'unlabelled';
    const rules = Array.isArray(record.rules) ? record.rules.length : 0;
    const warnings = Array.isArray(record.warnings) ? record.warnings.length : 0;
    const violations = Array.isArray(record.violations) ? record.violations.length : 0;
    cases.push({ id, label, rules, warnings, violations });
  }

  const totalRules = cases.reduce((acc, current) => acc + current.rules, 0);
  const totalWarnings = cases.reduce((acc, current) => acc + current.warnings, 0);
  const totalViolations = cases.reduce((acc, current) => acc + current.violations, 0);
  const goodViolations = cases.filter((item) => item.label === 'good' && item.violations > 0);
  const failingCases = cases.filter((item) => item.violations > 0);

  return { cases, totalRules, totalWarnings, totalViolations, goodViolations, failingCases };
}

export function formatSummaryTable(summary: EvaluationSummary): string {
  const header = ['| Case | Label | Rules | Violations | Warnings |', '| --- | --- | --- | --- | --- |'];
  const rows = summary.cases.map((item) => `| ${item.id} | ${item.label} | ${item.rules} | ${item.violations} | ${item.warnings} |`);
  if (rows.length === 0) {
    rows.push('| _none_ | _n/a_ | 0 | 0 | 0 |');
  }
  return [...header, ...rows].join('\n');
}

export function determineConclusion(summary: EvaluationSummary): GateCheckState {
  if (summary.cases.length === 0) {
    return 'failure';
  }
  if (summary.goodViolations.length > 0) {
    return 'failure';
  }
  if (summary.totalViolations > 0) {
    return 'failure';
  }
  return 'success';
}

function resolveRepository(): { owner: string; repo: string } | null {
  const source = process.env.GATE_GITHUB_REPOSITORY || process.env.GITHUB_REPOSITORY;
  if (!source) {
    return null;
  }
  const [owner, repo] = source.split('/');
  if (!owner || !repo) {
    return null;
  }
  return { owner, repo };
}

async function callGatekeeperEndpoint(payload: { commit: string; name: string; status: GateCheckState; summary: string }, endpoint: string): Promise<void> {
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Gatekeeper endpoint error: ${response.status} ${text}`);
  }
}

async function createOrUpdateCheck(payload: { commit: string; name: string; status: GateCheckState; summary: string }): Promise<void> {
  const token = process.env.GH_CHECKS_PAT || process.env.GITHUB_TOKEN;
  if (!token) {
    console.warn('Policy Gate: no GitHub token provided; skipping check run update');
    return;
  }
  const repository = resolveRepository();
  if (!repository) {
    console.warn('Policy Gate: unable to resolve repository; skipping check run update');
    return;
  }

  const headers = {
    Accept: 'application/vnd.github+json',
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
    'User-Agent': 'blackroad-policy-gate',
    'X-GitHub-Api-Version': '2022-11-28',
  } as const;

  const listUrl = `https://api.github.com/repos/${repository.owner}/${repository.repo}/commits/${payload.commit}/check-runs`;
  const listResponse = await fetch(listUrl, { headers });
  if (!listResponse.ok) {
    throw new Error(`Unable to list check runs: ${listResponse.status}`);
  }
  const data = (await listResponse.json()) as { check_runs?: { id: number; name: string }[] };
  const existing = data.check_runs?.find((run) => run.name === payload.name);
  const body = {
    name: payload.name,
    status: 'completed',
    conclusion: payload.status,
    output: {
      title: payload.name,
      summary: payload.summary,
    },
  };

  if (existing) {
    const updateUrl = `https://api.github.com/repos/${repository.owner}/${repository.repo}/check-runs/${existing.id}`;
    const updateResponse = await fetch(updateUrl, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ ...body, completed_at: new Date().toISOString() }),
    });
    if (!updateResponse.ok) {
      throw new Error(`Unable to update check run: ${updateResponse.status}`);
    }
    return;
  }

  const createUrl = `https://api.github.com/repos/${repository.owner}/${repository.repo}/check-runs`;
  const createResponse = await fetch(createUrl, {
    method: 'POST',
    headers,
    body: JSON.stringify({ ...body, head_sha: payload.commit }),
  });
  if (!createResponse.ok) {
    throw new Error(`Unable to create check run: ${createResponse.status}`);
  }
}

export async function postPolicyGateCheck(payload: { commit: string; summary: string; status: GateCheckState; endpoint?: string; name?: string }): Promise<void> {
  const name = payload.name ?? 'Policy Gate';
  const message = { commit: payload.commit, name, status: payload.status, summary: payload.summary };
  if (payload.endpoint) {
    await callGatekeeperEndpoint(message, payload.endpoint);
    return;
  }
  await createOrUpdateCheck(message);
}

function detectCommitSha(): string {
  if (process.env.GITHUB_SHA) {
    return process.env.GITHUB_SHA;
  }
  try {
    return execSync('git rev-parse HEAD', { encoding: 'utf-8' }).trim();
  } catch (error) {
    throw new Error('Unable to determine commit SHA');
  }
}

async function run(): Promise<void> {
  const repoRoot = process.env.PRISM_CONSOLE_ROOT ? path.resolve(process.env.PRISM_CONSOLE_ROOT) : process.cwd();
  const casesDir = process.env.POLICY_CASES_DIR || path.join(repoRoot, 'demo', 'cases');
  const records = await loadPolicyCases(casesDir);
  const evaluation = evaluatePolicyCases(records);
  const summaryTable = formatSummaryTable(evaluation);
  const status = determineConclusion(evaluation);
  const summary = `${summaryTable}\n\nTotal rules: ${evaluation.totalRules}\\nViolations: ${evaluation.totalViolations}\\nWarnings: ${evaluation.totalWarnings}`;
  console.log(summary);

  const commit = detectCommitSha();
  const endpoint = process.env.GATEKEEPER_ENDPOINT;
  try {
    await postPolicyGateCheck({ commit, summary, status, endpoint });
  } catch (error) {
    console.warn(`Policy Gate check update failed: ${(error as Error).message}`);
  }

  if (status === 'failure') {
    throw new Error('Policy Gate failed');
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  run().catch((error) => {
    console.error(error instanceof Error ? error.message : error);
    process.exit(1);
  });
}
