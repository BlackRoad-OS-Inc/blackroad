import type { KPIReport } from './types';
export type { KPIReport } from './types';
export { computeKPIs } from './compute.js';

export type LighthouseSummary = KPIReport['lighthouse'];
export type CIInsights = KPIReport['ci'];
export type K6Summary = KPIReport['k6'];
export type AlertsSummary = KPIReport['alerts'];
export type SimulationSummary = KPIReport['sim'];
export type AgentSummary = KPIReport['agents'];
export type SLOSummary = KPIReport['slo'];
