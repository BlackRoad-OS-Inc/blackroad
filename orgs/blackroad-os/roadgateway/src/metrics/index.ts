/**
 * RoadGateway Metrics & Monitoring
 *
 * Features:
 * - Request metrics (latency, count, errors)
 * - Rate limit metrics
 * - Upstream health checks
 * - Real-time dashboard data
 */

interface RequestMetric {
  path: string;
  method: string;
  statusCode: number;
  latencyMs: number;
  timestamp: number;
  upstream?: string;
  cached: boolean;
  rateLimit?: {
    remaining: number;
    limit: number;
  };
}

interface AggregatedMetrics {
  requests: {
    total: number;
    success: number;
    errors: number;
    cached: number;
  };
  latency: {
    avg: number;
    p50: number;
    p95: number;
    p99: number;
    min: number;
    max: number;
  };
  rateLimit: {
    limited: number;
    remaining: number;
  };
  byPath: Record<string, {
    count: number;
    avgLatency: number;
    errors: number;
  }>;
  byStatus: Record<number, number>;
  byUpstream: Record<string, {
    count: number;
    avgLatency: number;
    errors: number;
    healthy: boolean;
  }>;
}

interface HealthCheckResult {
  upstream: string;
  healthy: boolean;
  latencyMs: number;
  lastCheck: number;
  consecutiveFailures: number;
  error?: string;
}

/**
 * Metrics Collector for Gateway
 */
export class MetricsCollector {
  private metrics: RequestMetric[] = [];
  private maxMetrics: number = 10000;
  private healthChecks: Map<string, HealthCheckResult> = new Map();
  private flushInterval: number = 60000; // 1 minute

  constructor(maxMetrics: number = 10000) {
    this.maxMetrics = maxMetrics;
  }

  /**
   * Record a request metric
   */
  record(metric: RequestMetric): void {
    this.metrics.push(metric);

    // Trim old metrics
    if (this.metrics.length > this.maxMetrics) {
      this.metrics = this.metrics.slice(-this.maxMetrics);
    }
  }

  /**
   * Create metric from request/response
   */
  static fromRequest(
    request: Request,
    response: Response,
    startTime: number,
    upstream?: string,
    cached: boolean = false,
  ): RequestMetric {
    const url = new URL(request.url);
    return {
      path: url.pathname,
      method: request.method,
      statusCode: response.status,
      latencyMs: Date.now() - startTime,
      timestamp: Date.now(),
      upstream,
      cached,
    };
  }

  /**
   * Get aggregated metrics for time window
   */
  getAggregated(windowMinutes: number = 5): AggregatedMetrics {
    const cutoff = Date.now() - windowMinutes * 60 * 1000;
    const relevant = this.metrics.filter(m => m.timestamp >= cutoff);

    if (relevant.length === 0) {
      return this._emptyMetrics();
    }

    // Sort latencies for percentiles
    const latencies = relevant.map(m => m.latencyMs).sort((a, b) => a - b);

    // By path
    const byPath: Record<string, { count: number; totalLatency: number; errors: number }> = {};
    // By status
    const byStatus: Record<number, number> = {};
    // By upstream
    const byUpstream: Record<string, { count: number; totalLatency: number; errors: number }> = {};

    let success = 0;
    let errors = 0;
    let cached = 0;
    let rateLimited = 0;

    for (const m of relevant) {
      // Status categorization
      if (m.statusCode >= 200 && m.statusCode < 400) {
        success++;
      } else {
        errors++;
      }

      if (m.cached) cached++;
      if (m.statusCode === 429) rateLimited++;

      // By path
      if (!byPath[m.path]) {
        byPath[m.path] = { count: 0, totalLatency: 0, errors: 0 };
      }
      byPath[m.path].count++;
      byPath[m.path].totalLatency += m.latencyMs;
      if (m.statusCode >= 400) byPath[m.path].errors++;

      // By status
      byStatus[m.statusCode] = (byStatus[m.statusCode] || 0) + 1;

      // By upstream
      if (m.upstream) {
        if (!byUpstream[m.upstream]) {
          byUpstream[m.upstream] = { count: 0, totalLatency: 0, errors: 0 };
        }
        byUpstream[m.upstream].count++;
        byUpstream[m.upstream].totalLatency += m.latencyMs;
        if (m.statusCode >= 500) byUpstream[m.upstream].errors++;
      }
    }

    return {
      requests: {
        total: relevant.length,
        success,
        errors,
        cached,
      },
      latency: {
        avg: latencies.reduce((a, b) => a + b, 0) / latencies.length,
        p50: this._percentile(latencies, 50),
        p95: this._percentile(latencies, 95),
        p99: this._percentile(latencies, 99),
        min: latencies[0],
        max: latencies[latencies.length - 1],
      },
      rateLimit: {
        limited: rateLimited,
        remaining: 0, // Would need to track per-client
      },
      byPath: Object.fromEntries(
        Object.entries(byPath).map(([path, data]) => [
          path,
          {
            count: data.count,
            avgLatency: data.totalLatency / data.count,
            errors: data.errors,
          },
        ])
      ),
      byStatus,
      byUpstream: Object.fromEntries(
        Object.entries(byUpstream).map(([upstream, data]) => [
          upstream,
          {
            count: data.count,
            avgLatency: data.totalLatency / data.count,
            errors: data.errors,
            healthy: this.healthChecks.get(upstream)?.healthy ?? true,
          },
        ])
      ),
    };
  }

  /**
   * Perform health check on upstream
   */
  async checkUpstream(
    upstream: string,
    healthEndpoint: string = '/health',
    timeoutMs: number = 5000,
  ): Promise<HealthCheckResult> {
    const existing = this.healthChecks.get(upstream);
    const startTime = Date.now();

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), timeoutMs);

      const response = await fetch(`${upstream}${healthEndpoint}`, {
        signal: controller.signal,
      });

      clearTimeout(timeout);

      const result: HealthCheckResult = {
        upstream,
        healthy: response.ok,
        latencyMs: Date.now() - startTime,
        lastCheck: Date.now(),
        consecutiveFailures: response.ok ? 0 : (existing?.consecutiveFailures || 0) + 1,
      };

      this.healthChecks.set(upstream, result);
      return result;

    } catch (e) {
      const result: HealthCheckResult = {
        upstream,
        healthy: false,
        latencyMs: Date.now() - startTime,
        lastCheck: Date.now(),
        consecutiveFailures: (existing?.consecutiveFailures || 0) + 1,
        error: (e as Error).message,
      };

      this.healthChecks.set(upstream, result);
      return result;
    }
  }

  /**
   * Get all health check results
   */
  getHealthStatus(): HealthCheckResult[] {
    return Array.from(this.healthChecks.values());
  }

  /**
   * Get time series data for charting
   */
  getTimeSeries(
    windowMinutes: number = 60,
    bucketMinutes: number = 1,
  ): Array<{
    timestamp: number;
    requests: number;
    errors: number;
    avgLatency: number;
  }> {
    const cutoff = Date.now() - windowMinutes * 60 * 1000;
    const bucketMs = bucketMinutes * 60 * 1000;
    const buckets: Map<number, RequestMetric[]> = new Map();

    // Group metrics into buckets
    for (const m of this.metrics) {
      if (m.timestamp < cutoff) continue;

      const bucketTime = Math.floor(m.timestamp / bucketMs) * bucketMs;
      if (!buckets.has(bucketTime)) {
        buckets.set(bucketTime, []);
      }
      buckets.get(bucketTime)!.push(m);
    }

    // Convert to time series
    return Array.from(buckets.entries())
      .map(([timestamp, metrics]) => ({
        timestamp,
        requests: metrics.length,
        errors: metrics.filter(m => m.statusCode >= 400).length,
        avgLatency: metrics.reduce((sum, m) => sum + m.latencyMs, 0) / metrics.length,
      }))
      .sort((a, b) => a.timestamp - b.timestamp);
  }

  /**
   * Get top paths by request count
   */
  getTopPaths(limit: number = 10, windowMinutes: number = 60): Array<{
    path: string;
    count: number;
    avgLatency: number;
    errorRate: number;
  }> {
    const metrics = this.getAggregated(windowMinutes);

    return Object.entries(metrics.byPath)
      .map(([path, data]) => ({
        path,
        count: data.count,
        avgLatency: data.avgLatency,
        errorRate: data.errors / data.count,
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, limit);
  }

  /**
   * Get slow endpoints
   */
  getSlowEndpoints(thresholdMs: number = 1000, windowMinutes: number = 60): Array<{
    path: string;
    avgLatency: number;
    count: number;
  }> {
    const metrics = this.getAggregated(windowMinutes);

    return Object.entries(metrics.byPath)
      .filter(([_, data]) => data.avgLatency > thresholdMs)
      .map(([path, data]) => ({
        path,
        avgLatency: data.avgLatency,
        count: data.count,
      }))
      .sort((a, b) => b.avgLatency - a.avgLatency);
  }

  /**
   * Export metrics in Prometheus format
   */
  toPrometheus(): string {
    const metrics = this.getAggregated(5);
    const lines: string[] = [];

    // Request count
    lines.push('# HELP gateway_requests_total Total number of requests');
    lines.push('# TYPE gateway_requests_total counter');
    lines.push(`gateway_requests_total ${metrics.requests.total}`);

    // Error count
    lines.push('# HELP gateway_errors_total Total number of errors');
    lines.push('# TYPE gateway_errors_total counter');
    lines.push(`gateway_errors_total ${metrics.requests.errors}`);

    // Latency
    lines.push('# HELP gateway_latency_ms Request latency in milliseconds');
    lines.push('# TYPE gateway_latency_ms summary');
    lines.push(`gateway_latency_ms{quantile="0.5"} ${metrics.latency.p50}`);
    lines.push(`gateway_latency_ms{quantile="0.95"} ${metrics.latency.p95}`);
    lines.push(`gateway_latency_ms{quantile="0.99"} ${metrics.latency.p99}`);

    // Upstream health
    for (const health of this.healthChecks.values()) {
      lines.push(`gateway_upstream_healthy{upstream="${health.upstream}"} ${health.healthy ? 1 : 0}`);
    }

    return lines.join('\n');
  }

  /**
   * Clear all metrics
   */
  clear(): void {
    this.metrics = [];
  }

  private _percentile(sorted: number[], p: number): number {
    const index = Math.ceil((p / 100) * sorted.length) - 1;
    return sorted[Math.max(0, index)];
  }

  private _emptyMetrics(): AggregatedMetrics {
    return {
      requests: { total: 0, success: 0, errors: 0, cached: 0 },
      latency: { avg: 0, p50: 0, p95: 0, p99: 0, min: 0, max: 0 },
      rateLimit: { limited: 0, remaining: 0 },
      byPath: {},
      byStatus: {},
      byUpstream: {},
    };
  }
}

// Singleton instance
export const metricsCollector = new MetricsCollector();

/**
 * Middleware to collect metrics
 */
export function withMetrics<E extends { METRICS?: MetricsCollector }>(
  handler: (request: Request, env: E, ctx: ExecutionContext) => Promise<Response>,
) {
  return async (request: Request, env: E, ctx: ExecutionContext): Promise<Response> => {
    const startTime = Date.now();
    const collector = env.METRICS || metricsCollector;

    const response = await handler(request, env, ctx);

    const metric = MetricsCollector.fromRequest(
      request,
      response,
      startTime,
      response.headers.get('X-Upstream') || undefined,
      response.headers.get('X-Cache') === 'HIT',
    );

    collector.record(metric);

    return response;
  };
}
