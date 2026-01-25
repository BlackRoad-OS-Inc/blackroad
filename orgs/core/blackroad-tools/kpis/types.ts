export interface KPIReport {
  generatedAt: string;
  lighthouse: {
    sampleCount: number;
    perfScore: number | null;
    a11yScore: number | null;
    lcpCoverage: number | null;
    tbtMedian: number | null;
    weekly: {
      perf: Record<string, number | null>;
      a11y: Record<string, number | null>;
      lcp: Record<string, number | null>;
      tbt: Record<string, number | null>;
    };
    latest: Record<string, unknown> | null;
    previous: Record<string, unknown> | null;
    latestLcp: number | null;
    previousLcp: number | null;
    lcpDeltaPercent: number | null;
    weeklySummaries: Array<{
      week: string;
      perf: number | null;
      lcp: number | null;
      tbt: number | null;
    }>;
    slo: {
      totalWeeks: number;
      passingWeeks: number;
      compliance: number | null;
    };
  };
  ci: {
    totalRuns: number;
    failureRate: number | null;
    mttrHours: number | null;
    weeklyDeploys: Record<string, number>;
    lastDeployAt: string | null;
    weeklyRuns: Record<string, number>;
    currentDeployWeek: string | null;
    currentDeployCount: number;
  };
  k6: {
    components: Record<string, { p95: number }>;
  };
  alerts: {
    total: number;
    weeklyCounts: Record<string, number>;
    latestWeek: string | null;
    latestWeekCount: number;
  };
  sim: {
    maeMean: number | null;
    maeSamples: number;
    latestRun: string | null;
  };
  agents: {
    plannedRoles: number | null;
    completedRoles: number | null;
    coverage: number | null;
  };
  slo: {
    thresholds: {
      perf: number;
      lcp: number;
      tbt: number;
      latencyP95: number;
    };
    lighthouseCompliance: {
      totalWeeks: number;
      passingWeeks: number;
      compliance: number | null;
    };
    latencyOk: boolean;
    overallCompliance: number | null;
  };
}
