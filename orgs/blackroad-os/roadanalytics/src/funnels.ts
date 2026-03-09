/**
 * Funnel Analysis Module for RoadAnalytics
 *
 * Track user journeys through conversion funnels
 */

interface FunnelStep {
  name: string;
  event: string;
  count: number;
  conversionRate?: number;
  dropoffRate?: number;
}

interface Funnel {
  id: string;
  name: string;
  steps: FunnelStep[];
  totalStarted: number;
  totalCompleted: number;
  overallConversion: number;
  averageTimeToComplete?: number;
}

interface FunnelEvent {
  userId: string;
  sessionId: string;
  event: string;
  timestamp: number;
  properties?: Record<string, any>;
}

interface FunnelDefinition {
  id: string;
  name: string;
  steps: string[]; // Event names in order
  timeWindowHours?: number; // Max time to complete funnel
}

/**
 * FunnelAnalyzer - Analyze conversion funnels
 */
export class FunnelAnalyzer {
  private funnels: Map<string, FunnelDefinition> = new Map();
  private events: FunnelEvent[] = [];
  private userJourneys: Map<string, FunnelEvent[]> = new Map();

  /**
   * Define a new funnel
   */
  defineFunnel(definition: FunnelDefinition): void {
    this.funnels.set(definition.id, definition);
  }

  /**
   * Record a funnel event
   */
  recordEvent(event: FunnelEvent): void {
    this.events.push(event);

    // Track user journey
    if (!this.userJourneys.has(event.userId)) {
      this.userJourneys.set(event.userId, []);
    }
    this.userJourneys.get(event.userId)!.push(event);
  }

  /**
   * Analyze a funnel
   */
  analyze(funnelId: string, startDate?: number, endDate?: number): Funnel | null {
    const definition = this.funnels.get(funnelId);
    if (!definition) return null;

    const now = Date.now();
    const start = startDate || (now - 30 * 24 * 60 * 60 * 1000); // Default 30 days
    const end = endDate || now;
    const timeWindow = (definition.timeWindowHours || 24) * 60 * 60 * 1000;

    // Filter events in time range
    const relevantEvents = this.events.filter(
      e => e.timestamp >= start && e.timestamp <= end
    );

    // Group by user
    const userEvents: Map<string, FunnelEvent[]> = new Map();
    for (const event of relevantEvents) {
      if (!userEvents.has(event.userId)) {
        userEvents.set(event.userId, []);
      }
      userEvents.get(event.userId)!.push(event);
    }

    // Analyze each step
    const stepCounts: number[] = new Array(definition.steps.length).fill(0);
    const completionTimes: number[] = [];

    for (const [userId, events] of userEvents) {
      // Sort by timestamp
      const sorted = events.sort((a, b) => a.timestamp - b.timestamp);

      let lastStepIndex = -1;
      let lastStepTime = 0;
      let firstStepTime = 0;

      for (const event of sorted) {
        const stepIndex = definition.steps.indexOf(event.event);

        if (stepIndex === -1) continue;

        // Must complete steps in order
        if (stepIndex === lastStepIndex + 1) {
          // Check time window
          if (lastStepIndex >= 0 && event.timestamp - lastStepTime > timeWindow) {
            // Funnel timed out, reset
            lastStepIndex = -1;
            if (stepIndex !== 0) continue;
          }

          if (stepIndex === 0) {
            firstStepTime = event.timestamp;
          }

          stepCounts[stepIndex]++;
          lastStepIndex = stepIndex;
          lastStepTime = event.timestamp;

          // Completed funnel
          if (stepIndex === definition.steps.length - 1) {
            completionTimes.push(event.timestamp - firstStepTime);
          }
        }
      }
    }

    // Build funnel result
    const steps: FunnelStep[] = definition.steps.map((name, index) => {
      const count = stepCounts[index];
      const previousCount = index > 0 ? stepCounts[index - 1] : count;
      const conversionRate = previousCount > 0 ? (count / previousCount) * 100 : 0;
      const dropoffRate = 100 - conversionRate;

      return {
        name,
        event: name,
        count,
        conversionRate: Math.round(conversionRate * 100) / 100,
        dropoffRate: Math.round(dropoffRate * 100) / 100,
      };
    });

    const totalStarted = stepCounts[0] || 0;
    const totalCompleted = stepCounts[stepCounts.length - 1] || 0;
    const overallConversion = totalStarted > 0
      ? Math.round((totalCompleted / totalStarted) * 10000) / 100
      : 0;

    const averageTimeToComplete = completionTimes.length > 0
      ? completionTimes.reduce((a, b) => a + b, 0) / completionTimes.length
      : undefined;

    return {
      id: funnelId,
      name: definition.name,
      steps,
      totalStarted,
      totalCompleted,
      overallConversion,
      averageTimeToComplete,
    };
  }

  /**
   * Get users who dropped off at a specific step
   */
  getDropoffs(funnelId: string, stepIndex: number): string[] {
    const definition = this.funnels.get(funnelId);
    if (!definition || stepIndex >= definition.steps.length) return [];

    const dropoffs: string[] = [];
    const targetStep = definition.steps[stepIndex];
    const nextStep = definition.steps[stepIndex + 1];

    for (const [userId, events] of this.userJourneys) {
      const userEventNames = events.map(e => e.event);

      // User reached this step but not the next
      if (userEventNames.includes(targetStep) && !userEventNames.includes(nextStep)) {
        dropoffs.push(userId);
      }
    }

    return dropoffs;
  }

  /**
   * Compare funnels (A/B testing)
   */
  compare(funnelIdA: string, funnelIdB: string): {
    funnelA: Funnel | null;
    funnelB: Funnel | null;
    conversionDifference: number;
    winner: string | null;
  } {
    const funnelA = this.analyze(funnelIdA);
    const funnelB = this.analyze(funnelIdB);

    const conversionDifference = funnelA && funnelB
      ? funnelA.overallConversion - funnelB.overallConversion
      : 0;

    let winner: string | null = null;
    if (funnelA && funnelB) {
      if (funnelA.overallConversion > funnelB.overallConversion) {
        winner = funnelIdA;
      } else if (funnelB.overallConversion > funnelA.overallConversion) {
        winner = funnelIdB;
      }
    }

    return {
      funnelA,
      funnelB,
      conversionDifference,
      winner,
    };
  }

  /**
   * Get funnel trends over time
   */
  getTrends(funnelId: string, days: number = 30): {
    date: string;
    conversion: number;
    started: number;
    completed: number;
  }[] {
    const trends: {
      date: string;
      conversion: number;
      started: number;
      completed: number;
    }[] = [];

    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;

    for (let i = days - 1; i >= 0; i--) {
      const dayStart = now - (i + 1) * dayMs;
      const dayEnd = now - i * dayMs;

      const funnel = this.analyze(funnelId, dayStart, dayEnd);

      if (funnel) {
        const date = new Date(dayStart).toISOString().split('T')[0];
        trends.push({
          date,
          conversion: funnel.overallConversion,
          started: funnel.totalStarted,
          completed: funnel.totalCompleted,
        });
      }
    }

    return trends;
  }

  /**
   * Clear all data
   */
  clear(): void {
    this.events = [];
    this.userJourneys.clear();
  }

  /**
   * Get statistics
   */
  stats(): {
    totalEvents: number;
    uniqueUsers: number;
    funnelsDefined: number;
  } {
    return {
      totalEvents: this.events.length,
      uniqueUsers: this.userJourneys.size,
      funnelsDefined: this.funnels.size,
    };
  }
}

// Export singleton
export const funnelAnalyzer = new FunnelAnalyzer();

// Pre-define common e-commerce funnel
funnelAnalyzer.defineFunnel({
  id: 'ecommerce-checkout',
  name: 'E-commerce Checkout',
  steps: [
    'product_view',
    'add_to_cart',
    'begin_checkout',
    'add_payment_info',
    'purchase',
  ],
  timeWindowHours: 72,
});

// SaaS signup funnel
funnelAnalyzer.defineFunnel({
  id: 'saas-signup',
  name: 'SaaS Signup',
  steps: [
    'landing_page',
    'pricing_view',
    'signup_start',
    'email_verified',
    'onboarding_complete',
  ],
  timeWindowHours: 168, // 1 week
});
