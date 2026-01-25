import fs from 'fs';
import path from 'path';

const DEFAULT_TEMPLATE = 'docs/pulses/template-06-performance-reliability-pulse.md';

function loadJson(filePath) {
  const raw = fs.readFileSync(path.resolve(filePath), 'utf-8');
  return JSON.parse(raw);
}

function loadTemplate(templatePath) {
  return fs.readFileSync(path.resolve(templatePath), 'utf-8');
}

function formatPercent(value, digits = 1) {
  if (value == null || Number.isNaN(value)) return 'n/a';
  return `${(value * 100).toFixed(digits)}%`;
}

function formatMs(value) {
  if (value == null || Number.isNaN(value)) return 'n/a';
  return `${Math.round(value)} ms`;
}

function formatHours(value) {
  if (value == null || Number.isNaN(value)) return 'n/a';
  if (value < 1) {
    return `${(value * 60).toFixed(1)} min`;
  }
  return `${value.toFixed(1)} h`;
}

function pickFrontendLatency(k6) {
  const components = k6?.components || {};
  if (components.frontend) return components.frontend.p95;
  if (components.global) return components.global.p95;
  const first = Object.values(components)[0];
  return first ? first.p95 : null;
}

function buildPerfTable(lighthouse) {
  const weeks = Object.keys(lighthouse.weekly.perf || {}).sort();
  if (!weeks.length) return '_No weekly Lighthouse history found._';
  const rows = weeks.slice(-6).map((week) => `| ${week} | ${formatPercent(lighthouse.weekly.perf[week], 1)} | ${formatPercent(lighthouse.weekly.a11y[week], 1)} |`);
  return ['| Week | Perf | A11y |', '| --- | --- | --- |', ...rows].join('\n');
}

function buildLcpTable(lighthouse) {
  const weeks = Object.keys(lighthouse.weekly.lcp || {}).sort();
  if (!weeks.length) return '_No LCP/TBT samples available._';
  const rows = weeks
    .slice(-6)
    .map((week) => `| ${week} | ${formatMs(lighthouse.weekly.lcp[week])} | ${formatMs(lighthouse.weekly.tbt[week])} |`);
  return ['| Week | LCP | TBT |', '| --- | --- | --- |', ...rows].join('\n');
}

function buildAlertTrend(alerts) {
  const entries = Object.entries(alerts.weeklyCounts || {}).sort(([a], [b]) => (a < b ? -1 : 1));
  if (!entries.length) return 'No alerts recorded.';
  return entries.slice(-6).map(([week, count]) => `${week}: ${count}`).join(', ');
}

function deriveIsoWeek(lighthouse, fallback = null) {
  const weeks = Object.keys(lighthouse.weekly.perf || {}).sort();
  return weeks[weeks.length - 1] || fallback;
}

function renderContext(report) {
  const latency = pickFrontendLatency(report.k6);
  const isoWeek = deriveIsoWeek(report.lighthouse, report.ci.currentDeployWeek);
  const latestLighthouseTs = report.lighthouse.latest?.ts || report.lighthouse.latest?.timestamp || null;
  const latestDeploy = report.ci.lastDeployAt ? new Date(report.ci.lastDeployAt).toISOString() : 'n/a';

  return {
    generatedAt: report.generatedAt,
    isoWeek: isoWeek || 'n/a',
    perfScore: formatPercent(report.lighthouse.perfScore, 1),
    a11yScore: formatPercent(report.lighthouse.a11yScore, 1),
    lcpCoverage: formatPercent(report.lighthouse.lcpCoverage, 1),
    tbtMedian: formatMs(report.lighthouse.tbtMedian),
    ciFailureRate: formatPercent(report.ci.failureRate, 1),
    mttr: formatHours(report.ci.mttrHours),
    deployFrequency:
      report.ci.currentDeployWeek
        ? `${report.ci.currentDeployCount} deploy(s) in ${report.ci.currentDeployWeek}`
        : 'n/a',
    p95Latency: formatMs(latency),
    sloCompliance: formatPercent(report.slo?.lighthouseCompliance?.compliance ?? null, 1),
    alertVolume:
      report.alerts.latestWeek
        ? `${report.alerts.latestWeekCount} in ${report.alerts.latestWeek}`
        : `${report.alerts.total}`,
    simMae: report.sim.maeMean != null ? report.sim.maeMean.toFixed(3) : 'n/a',
    agentCoverage: formatPercent(report.agents.coverage, 1),
    weeklyPerfTable: buildPerfTable(report.lighthouse),
    weeklyLcpTable: buildLcpTable(report.lighthouse),
    ciRunCount: String(report.ci.totalRuns ?? 0),
    alertTrend: buildAlertTrend(report.alerts),
    latestLighthouse: latestLighthouseTs ? new Date(latestLighthouseTs).toISOString() : 'n/a',
    latestDeploy,
  };
}

function renderTemplate(template, context) {
  return template.replace(/{{\s*(\w+)\s*}}/g, (match, key) => {
    if (Object.prototype.hasOwnProperty.call(context, key)) {
      return context[key];
    }
    return match;
  });
}

function main(argv) {
  if (!argv.length) {
    console.error('Usage: node write.js <kpi.json> [--template path]');
    process.exit(1);
  }

  let templatePath = DEFAULT_TEMPLATE;
  let kpiPath = null;
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--template') {
      templatePath = argv[i + 1];
      i += 1;
      continue;
    }
    if (!kpiPath) {
      kpiPath = arg;
    }
  }

  if (!kpiPath) {
    console.error('Missing KPI JSON path.');
    process.exit(1);
  }

  const report = loadJson(kpiPath);
  const template = loadTemplate(templatePath || DEFAULT_TEMPLATE);
  const context = renderContext(report);
  const output = renderTemplate(template, context);
  process.stdout.write(output);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main(process.argv.slice(2));
}
// tools/pulse/write.js
// Usage: node tools/pulse/write.js data/kpis/latest.json > pulses/SYS-PERF-YYYY-WW.md
import fs from "node:fs";
import path from "node:path";

function isoWeek(dt=new Date()){
  const d=new Date(Date.UTC(dt.getFullYear(), dt.getMonth(), dt.getDate()));
  const dayNum = d.getUTCDay()||7; d.setUTCDate(d.getUTCDate()+4-dayNum);
  const yearStart=new Date(Date.UTC(d.getUTCFullYear(),0,1));
  const week=Math.ceil((((d - yearStart) / 86400000) + 1)/7);
  return {year:d.getUTCFullYear(), week};
}
function readJSON(p){ try{return JSON.parse(fs.readFileSync(p,"utf8"));}catch{return null;} }
function pct(x){ return (x==null)? "—" : (Math.round(x*1000)/10).toFixed(1)+"%"; }
function num(x, unit=""){ return (x==null)? "—" : `${Math.round(x)}${unit}`; }
function ms(x){ return (x==null)? "—" : `${Math.round(x)} ms`; }
function okBadge(b){ return b==null ? "–" : (b? "🟢" : "🔴"); }
function ensureDir(p){ fs.mkdirSync(path.dirname(p), {recursive:true}); }

const latest = readJSON(process.argv[2] || "data/kpis/latest.json") || {};
const {year, week} = isoWeek();
const title = `SYS-PERF-${year}-W${String(week).padStart(2,"0")}`;

const web = latest.kpis?.web||{};
const ci = latest.kpis?.ci||{};
const k6 = latest.kpis?.k6||{};
const sim = latest.kpis?.sim||{};
const flags = latest.flags||{};

const md = `# 📈 Performance & Reliability Pulse — ${title}

## Summary
- Web: perf=${web.perf_mean_7d??"—"} a11y=${web.a11y_mean_7d??"—"} LCP p75=${ms(web.lcp_p75_ms)} TBT p75=${ms(web.tbt_p75_ms)}
- CI: failure rate=${pct(ci.failure_rate_7d)} MTTR=${ms(ci.mttr_ms_7d)} deploys/7d=${ci.deploys_per_7d??"—"}
- k6 p95: ${Object.entries(k6.components||{}).map(([k,v])=>`${k}:${ms(v.p95)}`).join("  ")}
- Sim(solid): MAE=${sim.solid?.mae_mean_7d??"—"} RMSE=${sim.solid?.rmse_mean_7d??"—"} pass=${pct(sim.solid?.pass_fraction_mean_7d)}

## Budgets / SLOs
- Web: ${okBadge(flags.web?.perf_ok)} perf≥${latest.budgets?.web?.perf}  ${okBadge(flags.web?.a11y_ok)} a11y≥${latest.budgets?.web?.a11y}  ${okBadge(flags.web?.lcp_ok)} LCP p75≤${latest.budgets?.web?.lcp_p75_ms}ms  ${okBadge(flags.web?.tbt_ok)} TBT p75≤${latest.budgets?.web?.tbt_p75_ms}ms  ${okBadge(flags.web?.cls_ok)} CLS p95≤${latest.budgets?.web?.cls_p95}
- CI: ${okBadge(flags.ci?.failure_rate_ok)} fail≤${pct(latest.budgets?.ci?.failure_rate)}  ${okBadge(flags.ci?.mttr_ok)} MTTR≤${ms(latest.budgets?.ci?.mttr_ms)}  ${okBadge(flags.ci?.deploys_ok)} deploys≥${latest.budgets?.ci?.deploys_min_7d}
- k6: ${okBadge(flags.k6?.frontend_ok)} frontend p95≤${ms(latest.budgets?.k6?.frontend_p95_ms)}  ${okBadge(flags.k6?.quantum_ok)} quantum p95≤${ms(latest.budgets?.k6?.quantum_p95_ms)}  ${okBadge(flags.k6?.materials_ok)} materials p95≤${ms(latest.budgets?.k6?.materials_p95_ms)}

## Details
### Web (7d)
- perf=${web.perf_mean_7d??"—"}, a11y=${web.a11y_mean_7d??"—"}, best-practices=${web.bp_mean_7d??"—"}, SEO=${web.seo_mean_7d??"—"}
- LCP<2s coverage=${pct(web.lcp_lt2000_coverage_7d)}  TBT median=${ms(web.tbt_median_7d)}  CLS p95=${web.cls_p95_7d??"—"}

### CI (7d)
- failures/total=${pct(ci.failure_rate_7d)}  MTTR=${ms(ci.mttr_ms_7d)}  deploys=${ci.deploys_per_7d??"—"}

### k6 (latest)
${Object.entries(k6.components||{}).map(([k,v])=>`- ${k}: p50=${ms(v.p50)} p90=${ms(v.p90)} p95=${ms(v.p95)}`).join("\n")}

### Simulation (7d)
- solid: MAE=${sim.solid?.mae_mean_7d??"—"}, RMSE=${sim.solid?.rmse_mean_7d??"—"}, pass=${pct(sim.solid?.pass_fraction_mean_7d)}
- fluid: MAE=${sim.fluid?.mae_mean_7d??"—"}, RMSE=${sim.fluid?.rmse_mean_7d??"—"}, pass=${pct(sim.fluid?.pass_fraction_mean_7d)}

`;

const outPath = `pulses/${title}.md`;
ensureDir(outPath);
fs.writeFileSync(outPath, md, "utf8");
process.stdout.write(md);
