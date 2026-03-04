// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
// Canonical pricing — single source of truth.
// br-stripe.sh mirrors these values. Keep them in sync.

export interface PriceTier {
  id: string
  name: string
  description: string
  features: string[]
  limits: { agents: number; tasksPerMonth: number }
  prices: {
    monthly: { amount: number; currency: string }
    yearly: { amount: number; currency: string }
  }
}

export const TIERS: Record<string, PriceTier> = {
  free: {
    id: 'free',
    name: 'Free',
    description: 'Get started with BlackRoad OS',
    features: [
      '5 AI Agents',
      '500 tasks/month',
      'Community support',
      'Public dashboard',
    ],
    limits: { agents: 5, tasksPerMonth: 500 },
    prices: {
      monthly: { amount: 0, currency: 'usd' },
      yearly: { amount: 0, currency: 'usd' },
    },
  },
  pro: {
    id: 'pro',
    name: 'BlackRoad OS Pro',
    description: '100 AI Agents, 10K tasks/mo, priority support',
    features: [
      '100 AI Agents',
      '10,000 tasks/month',
      'Priority support',
      'Custom agent configs',
      'Memory system access',
      'Pi cluster integration',
    ],
    limits: { agents: 100, tasksPerMonth: 10_000 },
    prices: {
      monthly: { amount: 2900, currency: 'usd' },   // $29.00
      yearly: { amount: 29000, currency: 'usd' },    // $290.00
    },
  },
  enterprise: {
    id: 'enterprise',
    name: 'BlackRoad OS Enterprise',
    description: 'Unlimited agents, SSO, SLA, dedicated support',
    features: [
      'Unlimited AI Agents',
      'Unlimited tasks',
      'SSO / SAML',
      '99.9% SLA',
      'Dedicated support',
      'Custom deployments',
      'On-prem / Pi cluster',
      'Federation support',
    ],
    limits: { agents: Infinity, tasksPerMonth: Infinity },
    prices: {
      monthly: { amount: 19900, currency: 'usd' },   // $199.00
      yearly: { amount: 199000, currency: 'usd' },    // $1,990.00
    },
  },
} as const

export function formatCents(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`
}

export function tierFromPriceId(priceId: string, env: StripeEnv): string | null {
  if (priceId === env.STRIPE_PRICE_PRO_MONTHLY || priceId === env.STRIPE_PRICE_PRO_YEARLY) return 'pro'
  if (priceId === env.STRIPE_PRICE_ENT_MONTHLY || priceId === env.STRIPE_PRICE_ENT_YEARLY) return 'enterprise'
  return null
}

export interface StripeEnv {
  STRIPE_SECRET_KEY: string
  STRIPE_WEBHOOK_SECRET: string
  STRIPE_PRICE_PRO_MONTHLY: string
  STRIPE_PRICE_PRO_YEARLY: string
  STRIPE_PRICE_ENT_MONTHLY: string
  STRIPE_PRICE_ENT_YEARLY: string
  PI_WEBHOOK_URL?: string
  PI_WEBHOOK_SECRET?: string
}
