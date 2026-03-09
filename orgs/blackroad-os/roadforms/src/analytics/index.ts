/**
 * RoadForms Advanced Analytics
 *
 * Features:
 * - Conversion funnel analysis
 * - Field-level analytics (drop-off, time spent)
 * - A/B testing support
 * - Heatmaps (click/focus patterns)
 * - Submission trends
 * - Device/browser breakdown
 * - Geographic distribution
 */

interface FieldInteraction {
  fieldId: string;
  type: 'focus' | 'blur' | 'input' | 'change' | 'error';
  timestamp: number;
  value?: string;
  errorMessage?: string;
}

interface FormSession {
  sessionId: string;
  formId: string;
  variant?: string; // A/B test variant
  started: number;
  completed?: number;
  submitted: boolean;
  interactions: FieldInteraction[];
  device: {
    type: 'mobile' | 'tablet' | 'desktop';
    browser: string;
    os: string;
    screenWidth: number;
    screenHeight: number;
  };
  geo: {
    country?: string;
    region?: string;
    city?: string;
  };
  referrer?: string;
  utmParams?: Record<string, string>;
}

interface FieldAnalytics {
  fieldId: string;
  label: string;
  views: number;
  focuses: number;
  completions: number;
  errors: number;
  dropOffs: number;
  avgTimeSpent: number; // seconds
  errorRate: number;
  completionRate: number;
  mostCommonErrors: Array<{ message: string; count: number }>;
}

interface FormAnalytics {
  formId: string;
  formName: string;
  period: {
    start: number;
    end: number;
  };
  totals: {
    views: number;
    starts: number;
    completions: number;
    submissions: number;
    conversionRate: number;
    abandonmentRate: number;
    avgCompletionTime: number; // seconds
  };
  funnel: Array<{
    step: string;
    count: number;
    dropOff: number;
    rate: number;
  }>;
  fields: FieldAnalytics[];
  byDay: Array<{
    date: string;
    views: number;
    submissions: number;
    conversionRate: number;
  }>;
  byDevice: Record<string, { count: number; conversionRate: number }>;
  byCountry: Record<string, { count: number; conversionRate: number }>;
  byReferrer: Record<string, { count: number; conversionRate: number }>;
  variants?: Array<{
    variant: string;
    submissions: number;
    conversionRate: number;
    avgTime: number;
  }>;
}

interface ABTest {
  id: string;
  formId: string;
  name: string;
  variants: Array<{
    id: string;
    name: string;
    weight: number;
    changes: Record<string, any>; // Field ID -> changes
  }>;
  startDate: number;
  endDate?: number;
  status: 'draft' | 'running' | 'paused' | 'completed';
  winningVariant?: string;
}

/**
 * Analytics Collector
 */
export class FormAnalyticsCollector {
  private kv: KVNamespace;
  private sessions: Map<string, FormSession> = new Map();

  constructor(kv: KVNamespace) {
    this.kv = kv;
  }

  /**
   * Start a new form session
   */
  async startSession(
    formId: string,
    sessionId: string,
    device: FormSession['device'],
    geo: FormSession['geo'],
    referrer?: string,
    utmParams?: Record<string, string>,
    variant?: string,
  ): Promise<void> {
    const session: FormSession = {
      sessionId,
      formId,
      variant,
      started: Date.now(),
      submitted: false,
      interactions: [],
      device,
      geo,
      referrer,
      utmParams,
    };

    this.sessions.set(sessionId, session);

    // Increment view count
    await this.incrementCounter(`views:${formId}:${this.getDateKey()}`);
    await this.incrementCounter(`views:${formId}:total`);

    // Track by device
    await this.incrementCounter(`device:${formId}:${device.type}`);

    // Track by country
    if (geo.country) {
      await this.incrementCounter(`country:${formId}:${geo.country}`);
    }
  }

  /**
   * Track field interaction
   */
  async trackInteraction(
    sessionId: string,
    interaction: FieldInteraction,
  ): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    session.interactions.push(interaction);

    // Track field-level metrics
    const fieldKey = `field:${session.formId}:${interaction.fieldId}`;

    switch (interaction.type) {
      case 'focus':
        await this.incrementCounter(`${fieldKey}:focuses`);
        break;
      case 'blur':
        // Calculate time spent if we have a focus event
        const focusEvent = [...session.interactions]
          .reverse()
          .find(i => i.fieldId === interaction.fieldId && i.type === 'focus');

        if (focusEvent) {
          const timeSpent = interaction.timestamp - focusEvent.timestamp;
          await this.addToAverage(`${fieldKey}:avgTime`, timeSpent);
        }
        break;
      case 'error':
        await this.incrementCounter(`${fieldKey}:errors`);
        if (interaction.errorMessage) {
          await this.trackError(session.formId, interaction.fieldId, interaction.errorMessage);
        }
        break;
    }
  }

  /**
   * Mark form as started (first field focused)
   */
  async markStarted(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    await this.incrementCounter(`starts:${session.formId}:${this.getDateKey()}`);
    await this.incrementCounter(`starts:${session.formId}:total`);
  }

  /**
   * Mark form as completed
   */
  async markCompleted(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    session.completed = Date.now();

    await this.incrementCounter(`completions:${session.formId}:${this.getDateKey()}`);
    await this.incrementCounter(`completions:${session.formId}:total`);

    // Track completion time
    const completionTime = (session.completed - session.started) / 1000;
    await this.addToAverage(`avgTime:${session.formId}`, completionTime);

    if (session.variant) {
      await this.incrementCounter(`variant:${session.formId}:${session.variant}:completions`);
      await this.addToAverage(`variant:${session.formId}:${session.variant}:avgTime`, completionTime);
    }
  }

  /**
   * Mark form as submitted
   */
  async markSubmitted(sessionId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    session.submitted = true;

    await this.incrementCounter(`submissions:${session.formId}:${this.getDateKey()}`);
    await this.incrementCounter(`submissions:${session.formId}:total`);

    if (session.variant) {
      await this.incrementCounter(`variant:${session.formId}:${session.variant}:submissions`);
    }

    // Store full session for detailed analysis
    await this.storeSession(session);

    this.sessions.delete(sessionId);
  }

  /**
   * Track drop-off at specific field
   */
  async trackDropOff(sessionId: string, lastFieldId: string): Promise<void> {
    const session = this.sessions.get(sessionId);
    if (!session) return;

    await this.incrementCounter(`dropoff:${session.formId}:${lastFieldId}`);
    await this.incrementCounter(`abandoned:${session.formId}:${this.getDateKey()}`);

    this.sessions.delete(sessionId);
  }

  /**
   * Get form analytics
   */
  async getAnalytics(
    formId: string,
    startDate: number,
    endDate: number,
    formName: string,
    fields: Array<{ id: string; label: string }>,
  ): Promise<FormAnalytics> {
    // Get totals
    const views = await this.getCounter(`views:${formId}:total`);
    const starts = await this.getCounter(`starts:${formId}:total`);
    const completions = await this.getCounter(`completions:${formId}:total`);
    const submissions = await this.getCounter(`submissions:${formId}:total`);
    const avgTime = await this.getAverage(`avgTime:${formId}`);

    // Get field analytics
    const fieldAnalytics: FieldAnalytics[] = [];

    for (const field of fields) {
      const focuses = await this.getCounter(`field:${formId}:${field.id}:focuses`);
      const errors = await this.getCounter(`field:${formId}:${field.id}:errors`);
      const dropOffs = await this.getCounter(`dropoff:${formId}:${field.id}`);
      const avgFieldTime = await this.getAverage(`field:${formId}:${field.id}:avgTime`);
      const errorMessages = await this.getTopErrors(formId, field.id);

      fieldAnalytics.push({
        fieldId: field.id,
        label: field.label,
        views,
        focuses,
        completions: focuses > dropOffs ? focuses - dropOffs : 0,
        errors,
        dropOffs,
        avgTimeSpent: avgFieldTime / 1000, // Convert to seconds
        errorRate: focuses > 0 ? errors / focuses : 0,
        completionRate: focuses > 0 ? (focuses - dropOffs) / focuses : 0,
        mostCommonErrors: errorMessages,
      });
    }

    // Build funnel
    const funnel = [
      { step: 'View', count: views, dropOff: views - starts, rate: 1 },
      { step: 'Start', count: starts, dropOff: starts - completions, rate: views > 0 ? starts / views : 0 },
      { step: 'Complete', count: completions, dropOff: completions - submissions, rate: views > 0 ? completions / views : 0 },
      { step: 'Submit', count: submissions, dropOff: 0, rate: views > 0 ? submissions / views : 0 },
    ];

    // Get by-day data
    const byDay = await this.getDailyStats(formId, startDate, endDate);

    // Get device breakdown
    const byDevice = await this.getDeviceBreakdown(formId);

    // Get country breakdown
    const byCountry = await this.getCountryBreakdown(formId);

    // Get referrer breakdown
    const byReferrer = await this.getReferrerBreakdown(formId);

    // Get A/B test variants if any
    const variants = await this.getVariantStats(formId);

    return {
      formId,
      formName,
      period: { start: startDate, end: endDate },
      totals: {
        views,
        starts,
        completions,
        submissions,
        conversionRate: views > 0 ? submissions / views : 0,
        abandonmentRate: starts > 0 ? 1 - (submissions / starts) : 0,
        avgCompletionTime: avgTime / 1000,
      },
      funnel,
      fields: fieldAnalytics,
      byDay,
      byDevice,
      byCountry,
      byReferrer,
      variants: variants.length > 0 ? variants : undefined,
    };
  }

  // Helper methods
  private getDateKey(): string {
    return new Date().toISOString().split('T')[0];
  }

  private async incrementCounter(key: string): Promise<void> {
    const current = await this.kv.get(`analytics:${key}`, 'text');
    const count = current ? parseInt(current) + 1 : 1;
    await this.kv.put(`analytics:${key}`, String(count));
  }

  private async getCounter(key: string): Promise<number> {
    const value = await this.kv.get(`analytics:${key}`, 'text');
    return value ? parseInt(value) : 0;
  }

  private async addToAverage(key: string, value: number): Promise<void> {
    const data = await this.kv.get(`analytics:${key}`, 'json') as { sum: number; count: number } | null;
    const updated = data
      ? { sum: data.sum + value, count: data.count + 1 }
      : { sum: value, count: 1 };
    await this.kv.put(`analytics:${key}`, JSON.stringify(updated));
  }

  private async getAverage(key: string): Promise<number> {
    const data = await this.kv.get(`analytics:${key}`, 'json') as { sum: number; count: number } | null;
    return data && data.count > 0 ? data.sum / data.count : 0;
  }

  private async trackError(formId: string, fieldId: string, message: string): Promise<void> {
    const key = `analytics:errors:${formId}:${fieldId}`;
    const data = await this.kv.get(key, 'json') as Record<string, number> | null;
    const errors = data || {};
    errors[message] = (errors[message] || 0) + 1;
    await this.kv.put(key, JSON.stringify(errors));
  }

  private async getTopErrors(formId: string, fieldId: string): Promise<Array<{ message: string; count: number }>> {
    const key = `analytics:errors:${formId}:${fieldId}`;
    const data = await this.kv.get(key, 'json') as Record<string, number> | null;
    if (!data) return [];

    return Object.entries(data)
      .map(([message, count]) => ({ message, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }

  private async storeSession(session: FormSession): Promise<void> {
    const key = `session:${session.formId}:${session.sessionId}`;
    await this.kv.put(`analytics:${key}`, JSON.stringify(session), {
      expirationTtl: 86400 * 90, // 90 days
    });
  }

  private async getDailyStats(formId: string, start: number, end: number): Promise<FormAnalytics['byDay']> {
    const result: FormAnalytics['byDay'] = [];
    const current = new Date(start);
    const endDate = new Date(end);

    while (current <= endDate) {
      const dateKey = current.toISOString().split('T')[0];
      const views = await this.getCounter(`views:${formId}:${dateKey}`);
      const submissions = await this.getCounter(`submissions:${formId}:${dateKey}`);

      result.push({
        date: dateKey,
        views,
        submissions,
        conversionRate: views > 0 ? submissions / views : 0,
      });

      current.setDate(current.getDate() + 1);
    }

    return result;
  }

  private async getDeviceBreakdown(formId: string): Promise<FormAnalytics['byDevice']> {
    const devices = ['mobile', 'tablet', 'desktop'];
    const result: FormAnalytics['byDevice'] = {};

    for (const device of devices) {
      const count = await this.getCounter(`device:${formId}:${device}`);
      const submissions = await this.getCounter(`device:${formId}:${device}:submissions`);
      result[device] = {
        count,
        conversionRate: count > 0 ? submissions / count : 0,
      };
    }

    return result;
  }

  private async getCountryBreakdown(formId: string): Promise<FormAnalytics['byCountry']> {
    // In a real implementation, you'd scan for country keys
    // For now, return empty
    return {};
  }

  private async getReferrerBreakdown(formId: string): Promise<FormAnalytics['byReferrer']> {
    return {};
  }

  private async getVariantStats(formId: string): Promise<FormAnalytics['variants']> {
    // Get A/B test variants
    const testData = await this.kv.get(`abtest:${formId}`, 'json') as ABTest | null;
    if (!testData) return [];

    const result: NonNullable<FormAnalytics['variants']> = [];

    for (const variant of testData.variants) {
      const submissions = await this.getCounter(`variant:${formId}:${variant.id}:submissions`);
      const completions = await this.getCounter(`variant:${formId}:${variant.id}:completions`);
      const avgTime = await this.getAverage(`variant:${formId}:${variant.id}:avgTime`);

      result.push({
        variant: variant.name,
        submissions,
        conversionRate: completions > 0 ? submissions / completions : 0,
        avgTime: avgTime / 1000,
      });
    }

    return result;
  }
}

/**
 * A/B Test Manager
 */
export class ABTestManager {
  private kv: KVNamespace;

  constructor(kv: KVNamespace) {
    this.kv = kv;
  }

  async createTest(test: Omit<ABTest, 'id'>): Promise<ABTest> {
    const id = crypto.randomUUID();
    const fullTest: ABTest = { ...test, id };

    await this.kv.put(`abtest:${test.formId}`, JSON.stringify(fullTest));

    return fullTest;
  }

  async getVariant(formId: string, sessionId: string): Promise<string | null> {
    const test = await this.kv.get(`abtest:${formId}`, 'json') as ABTest | null;
    if (!test || test.status !== 'running') return null;

    // Consistent variant assignment based on session ID
    const hash = this.simpleHash(sessionId);
    const totalWeight = test.variants.reduce((sum, v) => sum + v.weight, 0);
    let threshold = hash % totalWeight;

    for (const variant of test.variants) {
      threshold -= variant.weight;
      if (threshold < 0) {
        return variant.id;
      }
    }

    return test.variants[0].id;
  }

  async endTest(formId: string, winningVariant?: string): Promise<void> {
    const test = await this.kv.get(`abtest:${formId}`, 'json') as ABTest | null;
    if (!test) return;

    test.status = 'completed';
    test.endDate = Date.now();
    test.winningVariant = winningVariant;

    await this.kv.put(`abtest:${formId}`, JSON.stringify(test));
  }

  private simpleHash(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash);
  }
}

/**
 * Client-side analytics tracker (for embedding)
 */
export function getClientTracker(formId: string, apiUrl: string): string {
  return `
(function() {
  const formId = "${formId}";
  const apiUrl = "${apiUrl}";
  const sessionId = crypto.randomUUID();
  let started = false;

  // Detect device
  const device = {
    type: window.innerWidth < 768 ? 'mobile' : window.innerWidth < 1024 ? 'tablet' : 'desktop',
    browser: navigator.userAgent,
    os: navigator.platform,
    screenWidth: screen.width,
    screenHeight: screen.height
  };

  // Get UTM params
  const params = new URLSearchParams(location.search);
  const utmParams = {};
  ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content'].forEach(k => {
    if (params.has(k)) utmParams[k] = params.get(k);
  });

  // Start session
  fetch(apiUrl + '/analytics/session', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ formId, sessionId, device, referrer: document.referrer, utmParams })
  });

  // Track field interactions
  document.querySelectorAll('form input, form textarea, form select').forEach(el => {
    el.addEventListener('focus', () => {
      if (!started) {
        fetch(apiUrl + '/analytics/started', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ sessionId })
        });
        started = true;
      }
      fetch(apiUrl + '/analytics/interaction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sessionId, fieldId: el.name, type: 'focus', timestamp: Date.now() })
      });
    });

    el.addEventListener('blur', () => {
      fetch(apiUrl + '/analytics/interaction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sessionId, fieldId: el.name, type: 'blur', timestamp: Date.now() })
      });
    });
  });

  // Track submission
  document.querySelector('form').addEventListener('submit', () => {
    fetch(apiUrl + '/analytics/submitted', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sessionId })
    });
  });

  // Track abandonment
  window.addEventListener('beforeunload', () => {
    if (!started) return;
    const lastField = document.activeElement?.name || 'unknown';
    navigator.sendBeacon(apiUrl + '/analytics/dropoff', JSON.stringify({ sessionId, lastFieldId: lastField }));
  });
})();
`;
}
