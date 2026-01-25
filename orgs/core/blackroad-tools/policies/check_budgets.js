import fs from 'fs';
import path from 'path';

import { computeKPIs } from '../kpis/compute.js';

export const DEFAULT_THRESHOLDS = {
  perfTarget: Number.parseFloat(process.env.LH_PERF_TARGET || '0.9'),
  lcpDeltaPercentMax: Number.parseFloat(process.env.LCP_DELTA_MAX || '5'),
  latencyP95: Number.parseFloat(process.env.K6_P95_TARGET || '750'),
};

export function evaluateBudgets(report, thresholds = DEFAULT_THRESHOLDS) {
  const issues = [];
  if (report?.lighthouse?.perfScore != null && report.lighthouse.perfScore < thresholds.perfTarget) {
    issues.push(`Lighthouse performance score ${report.lighthouse.perfScore.toFixed(3)} below target ${thresholds.perfTarget}`);
  }

  const lcpDelta = report?.lighthouse?.lcpDeltaPercent;
  if (lcpDelta != null && lcpDelta > thresholds.lcpDeltaPercentMax) {
    issues.push(`LCP regression ${lcpDelta.toFixed(2)}% exceeds allowed ${thresholds.lcpDeltaPercentMax}%`);
  }

  const components = report?.k6?.components || {};
  for (const [name, metrics] of Object.entries(components)) {
    if (metrics?.p95 != null && metrics.p95 > thresholds.latencyP95) {
      issues.push(`k6 p95 latency for ${name} = ${metrics.p95}ms exceeds ${thresholds.latencyP95}ms`);
    }
  }

  if (report?.slo?.lighthouseCompliance?.compliance != null) {
    const compliance = report.slo.lighthouseCompliance.compliance;
    if (compliance < 0.9) {
      issues.push(`Weekly SLO compliance ${formatPercent(compliance)} below 90% threshold`);
    }
  }

  return issues;
}

function formatPercent(value) {
  return `${(value * 100).toFixed(1)}%`;
}

function loadIndex(indexPath) {
  const resolved = path.resolve(indexPath);
  const raw = fs.readFileSync(resolved, 'utf-8');
  return JSON.parse(raw);
}

function loadReportFromKpis(kpiPath) {
  const resolved = path.resolve(kpiPath);
  const raw = fs.readFileSync(resolved, 'utf-8');
  return JSON.parse(raw);
}

function parseArgs(argv) {
  const options = { indexPath: null, kpiPath: null };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--index') {
      options.indexPath = argv[i + 1];
      i += 1;
    } else if (arg === '--kpis') {
      options.kpiPath = argv[i + 1];
      i += 1;
    }
  }
  return options;
}

function main(argv) {
  const options = parseArgs(argv);
  if (!options.indexPath && !options.kpiPath) {
    console.error('Usage: node check_budgets.js [--index path] [--kpis path]');
    process.exit(1);
  }

  let report;
  if (options.kpiPath) {
    report = loadReportFromKpis(options.kpiPath);
  } else {
    const index = loadIndex(options.indexPath);
    report = computeKPIs(index);
  }

  const issues = evaluateBudgets(report);
  if (issues.length) {
    for (const issue of issues) {
      console.error(issue);
    }
    process.exit(1);
  } else {
    console.log('All budgets are within thresholds.');
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main(process.argv.slice(2));
}
// tools/policies/check_budgets.js
// Usage: node tools/policies/check_budgets.js data/kpis/latest.json
import fs from "node:fs";

const file = process.argv[2] || "data/kpis/latest.json";
const latest = JSON.parse(fs.readFileSync(file, "utf8"));

function fail(msg){ console.error("❌", msg); process.exitCode = 1; }
function ok(msg){ console.log("✅", msg); }

const f = latest.flags || {};
const checks = [
  ["web.perf_ok", f.web?.perf_ok],
  ["web.a11y_ok", f.web?.a11y_ok],
  ["web.lcp_ok", f.web?.lcp_ok],
  ["web.tbt_ok", f.web?.tbt_ok],
  ["web.cls_ok", f.web?.cls_ok],
  ["ci.failure_rate_ok", f.ci?.failure_rate_ok],
  ["ci.mttr_ok", f.ci?.mttr_ok],
  ["ci.deploys_ok", f.ci?.deploys_ok],
  ["k6.frontend_ok", f.k6?.frontend_ok],
  ["k6.quantum_ok", f.k6?.quantum_ok],
  ["k6.materials_ok", f.k6?.materials_ok],
];

let anyFail = false;
for (const [name, flag] of checks){
  if (flag === null || flag === undefined) { console.log("–", name, "n/a"); continue; }
  if (flag){ ok(name); } else { fail(name); anyFail = true; }
}

if (anyFail) process.exit(1);
console.log("All budgets satisfied.");
