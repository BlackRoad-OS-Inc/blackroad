/**
 * RoadForms Conversion Tracking
 *
 * Track form conversions and optimize for customer acquisition.
 *
 * Features:
 * - Conversion funnel tracking
 * - Drop-off analysis
 * - A/B test integration
 * - Revenue attribution
 * - Customer journey mapping
 */

import { Hono } from 'hono';

interface ConversionEvent {
  formId: string;
  sessionId: string;
  userId?: string;
  eventType: 'view' | 'start' | 'field_complete' | 'submit' | 'success' | 'error';
  fieldName?: string;
  timestamp: number;
  metadata: Record<string, unknown>;
}

interface ConversionFunnel {
  formId: string;
  steps: FunnelStep[];
  period: { start: number; end: number };
}

interface FunnelStep {
  name: string;
  count: number;
  conversionRate: number;
  dropOffRate: number;
  avgTimeToNext: number;
}

interface FormPerformance {
  formId: string;
  views: number;
  starts: number;
  submissions: number;
  successRate: number;
  avgCompletionTime: number;
  revenueGenerated: number;
  topDropOffFields: string[];
}

interface ABTestResult {
  testId: string;
  variants: {
    id: string;
    name: string;
    views: number;
    conversions: number;
    conversionRate: number;
    revenue: number;
    isWinner: boolean;
    confidence: number;
  }[];
  startedAt: number;
  status: 'running' | 'completed' | 'stopped';
}

/**
 * Conversion Tracker
 */
export class ConversionTracker {
  private kv: KVNamespace;
  private analytics?: AnalyticsEngineDataset;

  constructor(kv: KVNamespace, analytics?: AnalyticsEngineDataset) {
    this.kv = kv;
    this.analytics = analytics;
  }

  /**
   * Track a conversion event
   */
  async trackEvent(event: ConversionEvent): Promise<void> {
    // Write to Analytics Engine if available
    if (this.analytics) {
      this.analytics.writeDataPoint({
        blobs: [
          event.formId,
          event.sessionId,
          event.eventType,
          event.fieldName || '',
          event.userId || '',
        ],
        doubles: [event.timestamp],
        indexes: [event.formId],
      });
    }

    // Also store in KV for real-time access
    const key = `event:${event.formId}:${event.sessionId}:${event.eventType}:${event.timestamp}`;
    await this.kv.put(key, JSON.stringify(event), {
      expirationTtl: 86400 * 30, // 30 days
    });

    // Update aggregates
    await this.updateAggregates(event);
  }

  /**
   * Track form view
   */
  async trackView(
    formId: string,
    sessionId: string,
    metadata: Record<string, unknown> = {},
  ): Promise<void> {
    await this.trackEvent({
      formId,
      sessionId,
      eventType: 'view',
      timestamp: Date.now(),
      metadata,
    });
  }

  /**
   * Track form start (first field interaction)
   */
  async trackStart(
    formId: string,
    sessionId: string,
    metadata: Record<string, unknown> = {},
  ): Promise<void> {
    await this.trackEvent({
      formId,
      sessionId,
      eventType: 'start',
      timestamp: Date.now(),
      metadata,
    });
  }

  /**
   * Track field completion
   */
  async trackFieldComplete(
    formId: string,
    sessionId: string,
    fieldName: string,
    metadata: Record<string, unknown> = {},
  ): Promise<void> {
    await this.trackEvent({
      formId,
      sessionId,
      eventType: 'field_complete',
      fieldName,
      timestamp: Date.now(),
      metadata,
    });
  }

  /**
   * Track form submission
   */
  async trackSubmit(
    formId: string,
    sessionId: string,
    userId?: string,
    metadata: Record<string, unknown> = {},
  ): Promise<void> {
    await this.trackEvent({
      formId,
      sessionId,
      userId,
      eventType: 'submit',
      timestamp: Date.now(),
      metadata,
    });
  }

  /**
   * Track successful conversion
   */
  async trackSuccess(
    formId: string,
    sessionId: string,
    userId?: string,
    revenue?: number,
    metadata: Record<string, unknown> = {},
  ): Promise<void> {
    await this.trackEvent({
      formId,
      sessionId,
      userId,
      eventType: 'success',
      timestamp: Date.now(),
      metadata: { ...metadata, revenue },
    });

    // Update revenue tracking
    if (revenue) {
      await this.trackRevenue(formId, revenue);
    }
  }

  /**
   * Update aggregate metrics
   */
  private async updateAggregates(event: ConversionEvent): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    const key = `aggregate:${event.formId}:${today}`;

    const data = await this.kv.get(key, 'json') as Record<string, number> | null || {
      views: 0,
      starts: 0,
      submits: 0,
      successes: 0,
      errors: 0,
    };

    switch (event.eventType) {
      case 'view':
        data.views = (data.views || 0) + 1;
        break;
      case 'start':
        data.starts = (data.starts || 0) + 1;
        break;
      case 'submit':
        data.submits = (data.submits || 0) + 1;
        break;
      case 'success':
        data.successes = (data.successes || 0) + 1;
        break;
      case 'error':
        data.errors = (data.errors || 0) + 1;
        break;
    }

    await this.kv.put(key, JSON.stringify(data), {
      expirationTtl: 86400 * 90, // 90 days
    });
  }

  /**
   * Track revenue
   */
  private async trackRevenue(formId: string, amount: number): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    const key = `revenue:${formId}:${today}`;

    const current = await this.kv.get(key, 'json') as { total: number; count: number } | null || {
      total: 0,
      count: 0,
    };

    current.total += amount;
    current.count += 1;

    await this.kv.put(key, JSON.stringify(current), {
      expirationTtl: 86400 * 365, // 1 year
    });
  }

  /**
   * Get form performance metrics
   */
  async getPerformance(formId: string, days: number = 30): Promise<FormPerformance> {
    let views = 0;
    let starts = 0;
    let submissions = 0;
    let successes = 0;
    let revenue = 0;

    const now = new Date();

    for (let i = 0; i < days; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];

      // Get aggregates
      const aggKey = `aggregate:${formId}:${dateStr}`;
      const agg = await this.kv.get(aggKey, 'json') as Record<string, number> | null;
      if (agg) {
        views += agg.views || 0;
        starts += agg.starts || 0;
        submissions += agg.submits || 0;
        successes += agg.successes || 0;
      }

      // Get revenue
      const revKey = `revenue:${formId}:${dateStr}`;
      const rev = await this.kv.get(revKey, 'json') as { total: number } | null;
      if (rev) {
        revenue += rev.total;
      }
    }

    return {
      formId,
      views,
      starts,
      submissions: successes, // Successful submissions
      successRate: submissions > 0 ? (successes / submissions) * 100 : 0,
      avgCompletionTime: 0, // Would need session timing data
      revenueGenerated: revenue,
      topDropOffFields: [], // Would need field-level analysis
    };
  }

  /**
   * Get conversion funnel
   */
  async getFunnel(formId: string, days: number = 30): Promise<ConversionFunnel> {
    const perf = await this.getPerformance(formId, days);

    const now = Date.now();
    const periodStart = now - (days * 86400 * 1000);

    return {
      formId,
      steps: [
        {
          name: 'View',
          count: perf.views,
          conversionRate: 100,
          dropOffRate: 0,
          avgTimeToNext: 0,
        },
        {
          name: 'Start',
          count: perf.starts,
          conversionRate: perf.views > 0 ? (perf.starts / perf.views) * 100 : 0,
          dropOffRate: perf.views > 0 ? ((perf.views - perf.starts) / perf.views) * 100 : 0,
          avgTimeToNext: 0,
        },
        {
          name: 'Submit',
          count: perf.submissions,
          conversionRate: perf.starts > 0 ? (perf.submissions / perf.starts) * 100 : 0,
          dropOffRate: perf.starts > 0 ? ((perf.starts - perf.submissions) / perf.starts) * 100 : 0,
          avgTimeToNext: 0,
        },
      ],
      period: { start: periodStart, end: now },
    };
  }
}

/**
 * A/B Test Manager for Forms
 */
export class FormABTestManager {
  private kv: KVNamespace;
  private tracker: ConversionTracker;

  constructor(kv: KVNamespace, tracker: ConversionTracker) {
    this.kv = kv;
    this.tracker = tracker;
  }

  /**
   * Create a new A/B test
   */
  async createTest(config: {
    formId: string;
    name: string;
    variants: { id: string; name: string; config: Record<string, unknown> }[];
    trafficSplit?: number[]; // Percentage for each variant
  }): Promise<string> {
    const testId = `test_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

    const test = {
      id: testId,
      formId: config.formId,
      name: config.name,
      variants: config.variants.map((v, i) => ({
        ...v,
        traffic: config.trafficSplit?.[i] || 100 / config.variants.length,
        views: 0,
        conversions: 0,
        revenue: 0,
      })),
      startedAt: Date.now(),
      status: 'running',
    };

    await this.kv.put(`abtest:${testId}`, JSON.stringify(test));
    await this.kv.put(`abtest:form:${config.formId}`, testId);

    return testId;
  }

  /**
   * Get variant for a session
   */
  async getVariant(
    formId: string,
    sessionId: string,
  ): Promise<{ variantId: string; config: Record<string, unknown> } | null> {
    // Check if there's an active test
    const testId = await this.kv.get(`abtest:form:${formId}`);
    if (!testId) return null;

    // Check if session already assigned
    const assignmentKey = `abtest:assignment:${testId}:${sessionId}`;
    const existing = await this.kv.get(assignmentKey);
    if (existing) {
      const test = await this.kv.get(`abtest:${testId}`, 'json') as any;
      const variant = test?.variants.find((v: any) => v.id === existing);
      return variant ? { variantId: variant.id, config: variant.config } : null;
    }

    // Assign variant based on traffic split
    const test = await this.kv.get(`abtest:${testId}`, 'json') as any;
    if (!test || test.status !== 'running') return null;

    const random = Math.random() * 100;
    let cumulative = 0;
    let selectedVariant = test.variants[0];

    for (const variant of test.variants) {
      cumulative += variant.traffic;
      if (random <= cumulative) {
        selectedVariant = variant;
        break;
      }
    }

    // Store assignment
    await this.kv.put(assignmentKey, selectedVariant.id, {
      expirationTtl: 86400 * 30,
    });

    // Increment view count
    await this.recordView(testId, selectedVariant.id);

    return { variantId: selectedVariant.id, config: selectedVariant.config };
  }

  /**
   * Record a view for a variant
   */
  async recordView(testId: string, variantId: string): Promise<void> {
    const test = await this.kv.get(`abtest:${testId}`, 'json') as any;
    if (!test) return;

    const variant = test.variants.find((v: any) => v.id === variantId);
    if (variant) {
      variant.views += 1;
      await this.kv.put(`abtest:${testId}`, JSON.stringify(test));
    }
  }

  /**
   * Record a conversion for a variant
   */
  async recordConversion(
    testId: string,
    variantId: string,
    revenue?: number,
  ): Promise<void> {
    const test = await this.kv.get(`abtest:${testId}`, 'json') as any;
    if (!test) return;

    const variant = test.variants.find((v: any) => v.id === variantId);
    if (variant) {
      variant.conversions += 1;
      if (revenue) {
        variant.revenue += revenue;
      }
      await this.kv.put(`abtest:${testId}`, JSON.stringify(test));
    }
  }

  /**
   * Get test results
   */
  async getResults(testId: string): Promise<ABTestResult | null> {
    const test = await this.kv.get(`abtest:${testId}`, 'json') as any;
    if (!test) return null;

    // Calculate statistics
    const variants = test.variants.map((v: any) => {
      const conversionRate = v.views > 0 ? (v.conversions / v.views) * 100 : 0;
      return {
        id: v.id,
        name: v.name,
        views: v.views,
        conversions: v.conversions,
        conversionRate,
        revenue: v.revenue,
        isWinner: false,
        confidence: 0,
      };
    });

    // Determine winner (simple highest conversion rate)
    if (variants.length > 0) {
      const sorted = [...variants].sort((a, b) => b.conversionRate - a.conversionRate);
      if (sorted[0].views >= 100 && sorted[0].conversions >= 10) {
        sorted[0].isWinner = true;
        // Simple confidence calculation (would use proper statistical test in production)
        sorted[0].confidence = Math.min(95, 50 + (sorted[0].views / 10));
      }
    }

    return {
      testId,
      variants,
      startedAt: test.startedAt,
      status: test.status,
    };
  }

  /**
   * Stop a test
   */
  async stopTest(testId: string): Promise<void> {
    const test = await this.kv.get(`abtest:${testId}`, 'json') as any;
    if (!test) return;

    test.status = 'stopped';
    test.stoppedAt = Date.now();
    await this.kv.put(`abtest:${testId}`, JSON.stringify(test));
  }
}

/**
 * Customer Journey Tracker
 */
export class CustomerJourneyTracker {
  private kv: KVNamespace;

  constructor(kv: KVNamespace) {
    this.kv = kv;
  }

  /**
   * Track a touchpoint in the customer journey
   */
  async trackTouchpoint(
    customerId: string,
    touchpoint: {
      type: 'form_view' | 'form_submit' | 'email_open' | 'page_view' | 'purchase';
      formId?: string;
      value?: number;
      metadata?: Record<string, unknown>;
    },
  ): Promise<void> {
    const key = `journey:${customerId}`;
    const journey = await this.kv.get(key, 'json') as any[] || [];

    journey.push({
      ...touchpoint,
      timestamp: Date.now(),
    });

    // Keep last 100 touchpoints
    const trimmed = journey.slice(-100);

    await this.kv.put(key, JSON.stringify(trimmed), {
      expirationTtl: 86400 * 365,
    });
  }

  /**
   * Get customer journey
   */
  async getJourney(customerId: string): Promise<any[]> {
    const key = `journey:${customerId}`;
    return await this.kv.get(key, 'json') as any[] || [];
  }

  /**
   * Calculate customer value from journey
   */
  async calculateValue(customerId: string): Promise<{
    totalValue: number;
    touchpoints: number;
    firstTouch: number;
    lastTouch: number;
    formConversions: number;
  }> {
    const journey = await this.getJourney(customerId);

    let totalValue = 0;
    let formConversions = 0;

    for (const touch of journey) {
      if (touch.value) {
        totalValue += touch.value;
      }
      if (touch.type === 'form_submit') {
        formConversions += 1;
      }
    }

    return {
      totalValue,
      touchpoints: journey.length,
      firstTouch: journey[0]?.timestamp || 0,
      lastTouch: journey[journey.length - 1]?.timestamp || 0,
      formConversions,
    };
  }
}

/**
 * Create conversion tracking routes
 */
export function createConversionRoutes(
  tracker: ConversionTracker,
  abTest: FormABTestManager,
  journey: CustomerJourneyTracker,
): Hono {
  const app = new Hono();

  // Track events
  app.post('/track', async (c) => {
    const event = await c.req.json() as ConversionEvent;
    await tracker.trackEvent(event);
    return c.json({ success: true });
  });

  // Get form performance
  app.get('/performance/:formId', async (c) => {
    const formId = c.req.param('formId');
    const days = parseInt(c.req.query('days') || '30');
    const perf = await tracker.getPerformance(formId, days);
    return c.json(perf);
  });

  // Get conversion funnel
  app.get('/funnel/:formId', async (c) => {
    const formId = c.req.param('formId');
    const days = parseInt(c.req.query('days') || '30');
    const funnel = await tracker.getFunnel(formId, days);
    return c.json(funnel);
  });

  // A/B testing
  app.post('/abtest', async (c) => {
    const config = await c.req.json();
    const testId = await abTest.createTest(config);
    return c.json({ testId });
  });

  app.get('/abtest/:testId', async (c) => {
    const testId = c.req.param('testId');
    const results = await abTest.getResults(testId);
    return c.json(results);
  });

  app.get('/variant/:formId/:sessionId', async (c) => {
    const formId = c.req.param('formId');
    const sessionId = c.req.param('sessionId');
    const variant = await abTest.getVariant(formId, sessionId);
    return c.json(variant || { variantId: 'control', config: {} });
  });

  // Customer journey
  app.get('/journey/:customerId', async (c) => {
    const customerId = c.req.param('customerId');
    const j = await journey.getJourney(customerId);
    return c.json({ touchpoints: j });
  });

  app.get('/journey/:customerId/value', async (c) => {
    const customerId = c.req.param('customerId');
    const value = await journey.calculateValue(customerId);
    return c.json(value);
  });

  return app;
}

export default createConversionRoutes;
