/**
 * RoadDocs Paywall & Subscription Gating
 *
 * Gate premium documentation content behind subscriptions.
 *
 * Features:
 * - Content access control
 * - Preview/teaser mode
 * - Subscription status checking
 * - Upgrade prompts
 * - Usage tracking
 */

import { Hono } from 'hono';

// BlackRoad Design Colors
const COLORS = {
  primary: '#F5A623',
  secondary: '#FF1D6C',
  background: '#000000',
  surface: '#111111',
  text: '#FFFFFF',
  textMuted: '#888888',
  border: '#333333',
};

type AccessLevel = 'free' | 'starter' | 'pro' | 'enterprise';

interface ContentRule {
  pattern: string;
  minLevel: AccessLevel;
  previewLines?: number;
  previewPercentage?: number;
}

interface SubscriptionStatus {
  customerId: string;
  level: AccessLevel;
  active: boolean;
  expiresAt?: number;
  features: string[];
}

interface GatedContent {
  accessible: boolean;
  content?: string;
  preview?: string;
  requiredLevel: AccessLevel;
  currentLevel: AccessLevel;
  upgradeUrl?: string;
}

/**
 * Access Control Manager
 */
export class AccessControlManager {
  private rules: ContentRule[] = [];
  private levelHierarchy: Record<AccessLevel, number> = {
    free: 0,
    starter: 1,
    pro: 2,
    enterprise: 3,
  };

  /**
   * Add a content access rule
   */
  addRule(rule: ContentRule): void {
    this.rules.push(rule);
  }

  /**
   * Load rules from configuration
   */
  loadRules(rules: ContentRule[]): void {
    this.rules = rules;
  }

  /**
   * Check if path matches a rule pattern
   */
  private matchPattern(path: string, pattern: string): boolean {
    // Support wildcards: /docs/pro/* matches /docs/pro/anything
    const regex = new RegExp(
      '^' + pattern.replace(/\*/g, '.*').replace(/\//g, '\\/') + '$'
    );
    return regex.test(path);
  }

  /**
   * Get rule for path
   */
  getRuleForPath(path: string): ContentRule | null {
    for (const rule of this.rules) {
      if (this.matchPattern(path, rule.pattern)) {
        return rule;
      }
    }
    return null;
  }

  /**
   * Check if user has access to content
   */
  hasAccess(userLevel: AccessLevel, requiredLevel: AccessLevel): boolean {
    return this.levelHierarchy[userLevel] >= this.levelHierarchy[requiredLevel];
  }

  /**
   * Get required level for path
   */
  getRequiredLevel(path: string): AccessLevel {
    const rule = this.getRuleForPath(path);
    return rule?.minLevel || 'free';
  }

  /**
   * Generate preview of gated content
   */
  generatePreview(
    content: string,
    rule: ContentRule,
  ): string {
    if (rule.previewLines) {
      const lines = content.split('\n');
      return lines.slice(0, rule.previewLines).join('\n');
    }

    if (rule.previewPercentage) {
      const chars = Math.floor(content.length * (rule.previewPercentage / 100));
      return content.slice(0, chars);
    }

    // Default: first 20% or 500 chars
    return content.slice(0, Math.min(500, content.length * 0.2));
  }
}

/**
 * Subscription Checker
 */
export class SubscriptionChecker {
  private kv: KVNamespace;
  private stripeKey?: string;

  constructor(kv: KVNamespace, stripeKey?: string) {
    this.kv = kv;
    this.stripeKey = stripeKey;
  }

  /**
   * Get subscription status from cache or Stripe
   */
  async getStatus(customerId: string): Promise<SubscriptionStatus> {
    // Check cache first
    const cached = await this.kv.get(`subscription:${customerId}`, 'json') as SubscriptionStatus | null;
    if (cached && (!cached.expiresAt || cached.expiresAt > Date.now())) {
      return cached;
    }

    // Fetch from Stripe if configured
    if (this.stripeKey) {
      const status = await this.fetchFromStripe(customerId);
      // Cache for 5 minutes
      await this.kv.put(`subscription:${customerId}`, JSON.stringify(status), {
        expirationTtl: 300,
      });
      return status;
    }

    // Default to free tier
    return {
      customerId,
      level: 'free',
      active: true,
      features: [],
    };
  }

  /**
   * Fetch subscription from Stripe
   */
  private async fetchFromStripe(customerId: string): Promise<SubscriptionStatus> {
    try {
      const response = await fetch(
        `https://api.stripe.com/v1/subscriptions?customer=${customerId}&status=active`,
        {
          headers: {
            Authorization: `Bearer ${this.stripeKey}`,
          },
        }
      );

      const data = await response.json() as any;

      if (data.data && data.data.length > 0) {
        const sub = data.data[0];
        const priceId = sub.items.data[0]?.price?.id;

        // Map price to level (configure these in your Stripe dashboard)
        const level = this.mapPriceToLevel(priceId);

        return {
          customerId,
          level,
          active: true,
          expiresAt: sub.current_period_end * 1000,
          features: this.getFeaturesForLevel(level),
        };
      }
    } catch (e) {
      console.error('Failed to fetch subscription from Stripe', e);
    }

    return {
      customerId,
      level: 'free',
      active: true,
      features: [],
    };
  }

  /**
   * Map Stripe price ID to access level
   */
  private mapPriceToLevel(priceId: string): AccessLevel {
    // Configure these mappings for your prices
    const mappings: Record<string, AccessLevel> = {
      'price_starter_monthly': 'starter',
      'price_starter_yearly': 'starter',
      'price_pro_monthly': 'pro',
      'price_pro_yearly': 'pro',
      'price_enterprise_monthly': 'enterprise',
      'price_enterprise_yearly': 'enterprise',
    };

    return mappings[priceId] || 'free';
  }

  /**
   * Get features for access level
   */
  private getFeaturesForLevel(level: AccessLevel): string[] {
    const features: Record<AccessLevel, string[]> = {
      free: ['basic_docs', 'community_support'],
      starter: ['basic_docs', 'api_reference', 'email_support'],
      pro: ['basic_docs', 'api_reference', 'tutorials', 'priority_support', 'examples'],
      enterprise: ['basic_docs', 'api_reference', 'tutorials', 'priority_support', 'examples', 'custom_docs', 'sla'],
    };

    return features[level];
  }

  /**
   * Set subscription status (for webhooks)
   */
  async setStatus(status: SubscriptionStatus): Promise<void> {
    await this.kv.put(`subscription:${status.customerId}`, JSON.stringify(status));
  }
}

/**
 * Paywall Widget Generator
 */
export class PaywallWidget {
  private upgradeBaseUrl: string;

  constructor(upgradeBaseUrl: string) {
    this.upgradeBaseUrl = upgradeBaseUrl;
  }

  /**
   * Generate paywall HTML
   */
  generatePaywall(options: {
    requiredLevel: AccessLevel;
    currentLevel: AccessLevel;
    title?: string;
    preview?: string;
  }): string {
    const levelNames: Record<AccessLevel, string> = {
      free: 'Free',
      starter: 'Starter',
      pro: 'Pro',
      enterprise: 'Enterprise',
    };

    const levelPrices: Record<AccessLevel, string> = {
      free: '$0',
      starter: '$19/mo',
      pro: '$49/mo',
      enterprise: 'Contact us',
    };

    const features: Record<AccessLevel, string[]> = {
      free: [],
      starter: ['API Reference', 'Email Support'],
      pro: ['All Starter features', 'Tutorials & Examples', 'Priority Support'],
      enterprise: ['All Pro features', 'Custom Documentation', 'SLA Guarantee'],
    };

    const upgradeUrl = `${this.upgradeBaseUrl}?plan=${options.requiredLevel}`;

    return `
<div class="paywall" style="
  background: ${COLORS.surface};
  border: 1px solid ${COLORS.border};
  border-radius: 16px;
  padding: 40px;
  text-align: center;
  margin: 40px 0;
">
  ${options.preview ? `
    <div class="preview" style="
      text-align: left;
      padding-bottom: 24px;
      margin-bottom: 24px;
      border-bottom: 1px solid ${COLORS.border};
      color: ${COLORS.textMuted};
      position: relative;
      max-height: 200px;
      overflow: hidden;
    ">
      ${options.preview}
      <div style="
        position: absolute;
        bottom: 0;
        left: 0;
        right: 0;
        height: 100px;
        background: linear-gradient(transparent, ${COLORS.surface});
      "></div>
    </div>
  ` : ''}

  <div style="font-size: 48px; margin-bottom: 16px;">🔒</div>

  <h3 style="
    color: ${COLORS.text};
    font-size: 24px;
    margin-bottom: 8px;
  ">${options.title || 'Premium Content'}</h3>

  <p style="
    color: ${COLORS.textMuted};
    margin-bottom: 24px;
  ">
    This content requires a <strong style="color: ${COLORS.primary}">${levelNames[options.requiredLevel]}</strong> subscription.
  </p>

  <div style="
    background: ${COLORS.background};
    border: 1px solid ${COLORS.primary};
    border-radius: 12px;
    padding: 24px;
    margin-bottom: 24px;
    text-align: left;
  ">
    <div style="
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
    ">
      <span style="
        color: ${COLORS.primary};
        font-size: 20px;
        font-weight: 600;
      ">${levelNames[options.requiredLevel]}</span>
      <span style="
        color: ${COLORS.text};
        font-size: 24px;
        font-weight: 700;
      ">${levelPrices[options.requiredLevel]}</span>
    </div>
    <ul style="
      list-style: none;
      padding: 0;
      margin: 0;
    ">
      ${features[options.requiredLevel].map(f => `
        <li style="
          color: ${COLORS.textMuted};
          padding: 8px 0;
          border-top: 1px solid ${COLORS.border};
        ">
          <span style="color: ${COLORS.primary}">✓</span> ${f}
        </li>
      `).join('')}
    </ul>
  </div>

  <a href="${upgradeUrl}" style="
    display: inline-block;
    background: linear-gradient(135deg, ${COLORS.primary}, ${COLORS.secondary});
    color: white;
    text-decoration: none;
    padding: 16px 48px;
    border-radius: 8px;
    font-weight: 600;
    font-size: 16px;
    transition: transform 0.2s, box-shadow 0.2s;
    box-shadow: 0 4px 24px rgba(245, 166, 35, 0.3);
  " onmouseover="this.style.transform='translateY(-2px)'" onmouseout="this.style.transform='translateY(0)'">
    Upgrade to ${levelNames[options.requiredLevel]}
  </a>

  <p style="
    color: ${COLORS.textMuted};
    font-size: 12px;
    margin-top: 16px;
  ">
    ${options.currentLevel !== 'free' ? `You're currently on the ${levelNames[options.currentLevel]} plan.` : 'Start your free trial today.'}
  </p>
</div>
`;
  }

  /**
   * Generate inline upgrade prompt
   */
  generateInlinePrompt(requiredLevel: AccessLevel): string {
    const upgradeUrl = `${this.upgradeBaseUrl}?plan=${requiredLevel}`;

    return `
<div style="
  background: linear-gradient(135deg, rgba(245, 166, 35, 0.1), rgba(255, 29, 108, 0.1));
  border: 1px solid ${COLORS.primary};
  border-radius: 8px;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin: 16px 0;
">
  <div style="display: flex; align-items: center; gap: 12px;">
    <span style="font-size: 24px;">⭐</span>
    <span style="color: ${COLORS.text};">
      Unlock this section with a <strong>${requiredLevel}</strong> subscription
    </span>
  </div>
  <a href="${upgradeUrl}" style="
    background: ${COLORS.primary};
    color: white;
    text-decoration: none;
    padding: 8px 20px;
    border-radius: 6px;
    font-weight: 600;
    font-size: 14px;
    white-space: nowrap;
  ">Upgrade</a>
</div>
`;
  }
}

/**
 * Content Gating Middleware
 */
export class ContentGatingMiddleware {
  private accessControl: AccessControlManager;
  private subscriptionChecker: SubscriptionChecker;
  private paywallWidget: PaywallWidget;

  constructor(
    accessControl: AccessControlManager,
    subscriptionChecker: SubscriptionChecker,
    paywallWidget: PaywallWidget,
  ) {
    this.accessControl = accessControl;
    this.subscriptionChecker = subscriptionChecker;
    this.paywallWidget = paywallWidget;
  }

  /**
   * Gate content based on subscription
   */
  async gateContent(
    path: string,
    content: string,
    customerId?: string,
  ): Promise<GatedContent> {
    const requiredLevel = this.accessControl.getRequiredLevel(path);

    // Free content is always accessible
    if (requiredLevel === 'free') {
      return {
        accessible: true,
        content,
        requiredLevel,
        currentLevel: 'free',
      };
    }

    // Check subscription if customer ID provided
    if (customerId) {
      const status = await this.subscriptionChecker.getStatus(customerId);
      const hasAccess = this.accessControl.hasAccess(status.level, requiredLevel);

      if (hasAccess) {
        return {
          accessible: true,
          content,
          requiredLevel,
          currentLevel: status.level,
        };
      }

      // Generate preview for subscribers without access
      const rule = this.accessControl.getRuleForPath(path);
      const preview = rule
        ? this.accessControl.generatePreview(content, rule)
        : undefined;

      return {
        accessible: false,
        preview,
        requiredLevel,
        currentLevel: status.level,
        upgradeUrl: '/upgrade',
      };
    }

    // No customer ID - show preview only
    const rule = this.accessControl.getRuleForPath(path);
    const preview = rule
      ? this.accessControl.generatePreview(content, rule)
      : undefined;

    return {
      accessible: false,
      preview,
      requiredLevel,
      currentLevel: 'free',
      upgradeUrl: '/upgrade',
    };
  }

  /**
   * Wrap gated content with paywall
   */
  async wrapWithPaywall(
    path: string,
    content: string,
    customerId?: string,
  ): Promise<string> {
    const gated = await this.gateContent(path, content, customerId);

    if (gated.accessible) {
      return gated.content!;
    }

    return this.paywallWidget.generatePaywall({
      requiredLevel: gated.requiredLevel,
      currentLevel: gated.currentLevel,
      preview: gated.preview,
    });
  }
}

/**
 * Usage Tracker for Gated Content
 */
export class GatedContentUsageTracker {
  private kv: KVNamespace;

  constructor(kv: KVNamespace) {
    this.kv = kv;
  }

  /**
   * Track content access attempt
   */
  async trackAccess(
    customerId: string,
    path: string,
    granted: boolean,
    requiredLevel: AccessLevel,
  ): Promise<void> {
    const today = new Date().toISOString().split('T')[0];
    const key = `access:${today}:${customerId}`;

    const data = await this.kv.get(key, 'json') as any[] || [];
    data.push({
      path,
      granted,
      requiredLevel,
      timestamp: Date.now(),
    });

    await this.kv.put(key, JSON.stringify(data), {
      expirationTtl: 86400 * 30,
    });
  }

  /**
   * Track paywall view
   */
  async trackPaywallView(
    customerId: string,
    path: string,
    requiredLevel: AccessLevel,
  ): Promise<void> {
    const key = `paywall_view:${requiredLevel}:${new Date().toISOString().split('T')[0]}`;
    const count = parseInt(await this.kv.get(key) || '0');
    await this.kv.put(key, String(count + 1), {
      expirationTtl: 86400 * 90,
    });
  }

  /**
   * Get upgrade conversion metrics
   */
  async getConversionMetrics(days: number = 30): Promise<{
    paywallViews: Record<AccessLevel, number>;
    conversions: number;
  }> {
    const paywallViews: Record<AccessLevel, number> = {
      free: 0,
      starter: 0,
      pro: 0,
      enterprise: 0,
    };

    const now = new Date();
    for (let i = 0; i < days; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() - i);
      const dateStr = date.toISOString().split('T')[0];

      for (const level of ['starter', 'pro', 'enterprise'] as AccessLevel[]) {
        const key = `paywall_view:${level}:${dateStr}`;
        const count = parseInt(await this.kv.get(key) || '0');
        paywallViews[level] += count;
      }
    }

    return {
      paywallViews,
      conversions: 0, // Would need to track actual upgrades
    };
  }
}

/**
 * Create paywall routes
 */
export function createPaywallRoutes(
  accessControl: AccessControlManager,
  subscriptionChecker: SubscriptionChecker,
  upgradeBaseUrl: string,
): Hono {
  const app = new Hono();
  const widget = new PaywallWidget(upgradeBaseUrl);
  const middleware = new ContentGatingMiddleware(
    accessControl,
    subscriptionChecker,
    widget,
  );

  // Check access for a path
  app.get('/access/check', async (c) => {
    const path = c.req.query('path') || '/';
    const customerId = c.req.header('X-Customer-ID');

    const result = await middleware.gateContent(path, '', customerId);
    return c.json({
      accessible: result.accessible,
      requiredLevel: result.requiredLevel,
      currentLevel: result.currentLevel,
    });
  });

  // Get subscription status
  app.get('/subscription/:customerId', async (c) => {
    const customerId = c.req.param('customerId');
    const status = await subscriptionChecker.getStatus(customerId);
    return c.json(status);
  });

  // Set subscription (webhook endpoint)
  app.post('/subscription/webhook', async (c) => {
    const payload = await c.req.json();
    // Verify webhook signature in production
    const customerId = payload.data?.object?.customer;
    if (customerId) {
      await subscriptionChecker.setStatus({
        customerId,
        level: 'pro', // Map from payload
        active: true,
        features: [],
      });
    }
    return c.json({ received: true });
  });

  // Preview paywall widget
  app.get('/widget/preview', (c) => {
    const level = c.req.query('level') as AccessLevel || 'pro';
    const html = widget.generatePaywall({
      requiredLevel: level,
      currentLevel: 'free',
      title: 'Premium Documentation',
      preview: 'This is a preview of the premium content that would be shown to users before the paywall...',
    });
    return c.html(html);
  });

  return app;
}

export default createPaywallRoutes;
