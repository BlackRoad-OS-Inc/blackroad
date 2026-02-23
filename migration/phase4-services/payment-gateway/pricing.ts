/**
 * BlackRoad OS Canonical Pricing - Single Source of Truth
 * Ported 1:1 from workers/payment-gateway/src/pricing.ts
 * Stripe price IDs now come from process.env instead of Worker secrets.
 */

export interface PricingTier {
  id: string;
  name: string;
  priceMonthly: number;
  priceYearly: number;
  features: string[];
  agentLimit: number;
  trialDays: number;
  stripePriceEnvMonthly: string;
  stripePriceEnvYearly: string;
  cta: string;
  popular?: boolean;
}

export const PRICING: PricingTier[] = [
  {
    id: 'free',
    name: 'Free',
    priceMonthly: 0,
    priceYearly: 0,
    features: [
      '3 AI Agents',
      '100 tasks/month',
      'Community support',
      'Basic analytics',
      'Public API (rate-limited)',
    ],
    agentLimit: 3,
    trialDays: 0,
    stripePriceEnvMonthly: '',
    stripePriceEnvYearly: '',
    cta: 'Get Started',
  },
  {
    id: 'pro',
    name: 'Pro',
    priceMonthly: 29,
    priceYearly: 290,
    features: [
      '100 AI Agents',
      '10,000 tasks/month',
      'Priority support',
      'Advanced analytics',
      'Custom integrations',
      'API access (unlimited)',
      'Webhook notifications',
    ],
    agentLimit: 100,
    trialDays: 14,
    stripePriceEnvMonthly: 'STRIPE_PRICE_PRO_MONTHLY',
    stripePriceEnvYearly: 'STRIPE_PRICE_PRO_YEARLY',
    cta: 'Start Free Trial',
    popular: true,
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    priceMonthly: 199,
    priceYearly: 1990,
    features: [
      'Unlimited AI Agents',
      'Unlimited tasks',
      '24/7 phone + Slack support',
      'Custom analytics dashboards',
      'Dedicated account manager',
      'On-premise deployment option',
      'SLA guarantees (99.9%)',
      'SSO / SAML',
      'Audit logs',
    ],
    agentLimit: -1,
    trialDays: 14,
    stripePriceEnvMonthly: 'STRIPE_PRICE_ENT_MONTHLY',
    stripePriceEnvYearly: 'STRIPE_PRICE_ENT_YEARLY',
    cta: 'Start Free Trial',
  },
  {
    id: 'custom',
    name: 'Enterprise Custom',
    priceMonthly: -1,
    priceYearly: -1,
    features: [
      'Everything in Enterprise',
      'Custom agent limits',
      'White-label options',
      'Custom SLA',
      'Dedicated infrastructure',
      'Professional services',
      'Volume discounts',
    ],
    agentLimit: -1,
    trialDays: 0,
    stripePriceEnvMonthly: '',
    stripePriceEnvYearly: '',
    cta: 'Contact Sales',
  },
];

export function getTier(id: string): PricingTier | undefined {
  return PRICING.find((t) => t.id === id);
}

export function getStripePriceId(
  tier: PricingTier,
  period: 'monthly' | 'yearly',
): string {
  const envKey = period === 'yearly' ? tier.stripePriceEnvYearly : tier.stripePriceEnvMonthly;
  if (!envKey) return '';
  return process.env[envKey] || '';
}
