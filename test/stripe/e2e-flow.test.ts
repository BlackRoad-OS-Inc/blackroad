// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
// E2E integration test: full payment lifecycle
// checkout → webhook → subscription query → portal → revenue
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

import worker from '../../workers/pay-blackroadio/src/index.js'

const env = {
  STRIPE_SECRET_KEY: 'sk_test_e2e',
  STRIPE_WEBHOOK_SECRET: 'whsec_e2e_secret',
  STRIPE_PRICE_PRO_MONTHLY: 'price_pro_m',
  STRIPE_PRICE_PRO_YEARLY: 'price_pro_y',
  STRIPE_PRICE_ENT_MONTHLY: 'price_ent_m',
  STRIPE_PRICE_ENT_YEARLY: 'price_ent_y',
  CORS_ORIGIN: '*',
  SUCCESS_URL: 'https://blackroad.io/welcome',
  CANCEL_URL: 'https://blackroad.io/pricing',
  PI_WEBHOOK_PRIMARY: 'https://agent.blackroad.ai/webhooks/stripe',
  PI_WEBHOOK_SECONDARY: '',
  PRICE_PRO_MONTHLY: '2900',
  PRICE_PRO_YEARLY: '29000',
  PRICE_ENT_MONTHLY: '19900',
  PRICE_ENT_YEARLY: '199000',
}

const piRelayResults: Array<{ url: string; body: string }> = []
const ctx = {
  waitUntil: vi.fn((promise: Promise<unknown>) => {
    // Capture the relay promise so we can inspect it
    promise.catch(() => {})
  }),
}

// Helper to build HMAC signature matching the worker's verification
async function signPayload(payload: string, secret: string, timestamp: number): Promise<string> {
  const enc = new TextEncoder()
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(`${timestamp}.${payload}`))
  const hex = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
  return `t=${timestamp},v1=${hex}`
}

function req(path: string, method = 'GET', body?: unknown, headers?: Record<string, string>): Request {
  const opts: RequestInit = { method, headers: { ...headers } }
  if (body) {
    opts.body = typeof body === 'string' ? body : JSON.stringify(body)
    if (typeof body !== 'string') {
      ;(opts.headers as Record<string, string>)['Content-Type'] = 'application/json'
    }
  }
  return new Request(`https://pay.blackroad.io${path}`, opts)
}

describe('E2E Stripe Payment Lifecycle', () => {
  let originalFetch: typeof fetch

  beforeEach(() => {
    originalFetch = globalThis.fetch
    ctx.waitUntil.mockClear()
    piRelayResults.length = 0
  })

  afterEach(() => {
    globalThis.fetch = originalFetch
  })

  it('Step 1: Health check passes', async () => {
    const res = await worker.fetch(req('/health'), env, ctx)
    const data = await res.json()

    expect(data.status).toBe('ok')
    expect(data.pricing.pro_monthly).toBe(2900)
    expect(data.pricing.enterprise_yearly).toBe(199000)
  })

  it('Step 2: Checkout creates session and returns URL', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: async () => ({
        id: 'cs_e2e_001',
        url: 'https://checkout.stripe.com/pay/cs_e2e_001',
      }),
    })

    const res = await worker.fetch(
      req('/checkout', 'POST', {
        tier: 'pro',
        interval: 'month',
        customer_email: 'alexa@blackroad.io',
      }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(res.status).toBe(200)
    expect(data.url).toContain('checkout.stripe.com')
    expect(data.session_id).toBe('cs_e2e_001')

    // Verify the Stripe API call included correct params
    const call = (globalThis.fetch as ReturnType<typeof vi.fn>).mock.calls[0]
    const body = call[1].body as string
    expect(body).toContain('price_pro_m')
    expect(body).toContain('alexa%40blackroad.io')
    expect(body).toContain('trial_period_days')
  })

  it('Step 3: Webhook processes checkout.session.completed and relays to Pi', async () => {
    const webhookEvent = {
      id: 'evt_e2e_001',
      type: 'checkout.session.completed',
      data: {
        object: {
          customer: 'cus_e2e_001',
          customer_email: 'alexa@blackroad.io',
          subscription: 'sub_e2e_001',
          amount_total: 2900,
        },
      },
    }

    const payload = JSON.stringify(webhookEvent)
    const timestamp = Math.floor(Date.now() / 1000)
    const signature = await signPayload(payload, env.STRIPE_WEBHOOK_SECRET, timestamp)

    // Mock fetch for Pi relay (the worker calls fetch to relay to Pis)
    globalThis.fetch = vi.fn().mockResolvedValue({
      status: 200,
      ok: true,
    })

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(res.status).toBe(200)
    expect(data.received).toBe(true)
    expect(data.type).toBe('checkout.session.completed')
    expect(data.result.action).toBe('new_checkout')
    expect(data.result.customer).toBe('cus_e2e_001')
    expect(data.result.email).toBe('alexa@blackroad.io')
    expect(data.result.subscription).toBe('sub_e2e_001')

    // Verify Pi relay was triggered via waitUntil
    expect(ctx.waitUntil).toHaveBeenCalledTimes(1)
  })

  it('Step 4: Webhook processes subscription created', async () => {
    const webhookEvent = {
      id: 'evt_e2e_002',
      type: 'customer.subscription.created',
      data: {
        object: {
          id: 'sub_e2e_001',
          customer: 'cus_e2e_001',
          status: 'active',
          metadata: { tier: 'pro' },
        },
      },
    }

    const payload = JSON.stringify(webhookEvent)
    const timestamp = Math.floor(Date.now() / 1000)
    const signature = await signPayload(payload, env.STRIPE_WEBHOOK_SECRET, timestamp)

    globalThis.fetch = vi.fn().mockResolvedValue({ status: 200, ok: true })

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(data.received).toBe(true)
    expect(data.result.action).toBe('subscription_created')
    expect(data.result.status).toBe('active')
    expect(data.result.tier).toBe('pro')
  })

  it('Step 5: Webhook processes payment succeeded', async () => {
    const webhookEvent = {
      id: 'evt_e2e_003',
      type: 'invoice.payment_succeeded',
      data: {
        object: {
          id: 'in_e2e_001',
          customer: 'cus_e2e_001',
          amount_paid: 2900,
        },
      },
    }

    const payload = JSON.stringify(webhookEvent)
    const timestamp = Math.floor(Date.now() / 1000)
    const signature = await signPayload(payload, env.STRIPE_WEBHOOK_SECRET, timestamp)

    globalThis.fetch = vi.fn().mockResolvedValue({ status: 200, ok: true })

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(data.received).toBe(true)
    expect(data.result.action).toBe('payment_succeeded')
    expect(data.result.amount_paid).toBe(2900)
  })

  it('Step 6: Webhook processes payment failed', async () => {
    const webhookEvent = {
      id: 'evt_e2e_004',
      type: 'invoice.payment_failed',
      data: {
        object: {
          id: 'in_e2e_002',
          customer: 'cus_e2e_001',
          amount_due: 2900,
          attempt_count: 1,
        },
      },
    }

    const payload = JSON.stringify(webhookEvent)
    const timestamp = Math.floor(Date.now() / 1000)
    const signature = await signPayload(payload, env.STRIPE_WEBHOOK_SECRET, timestamp)

    globalThis.fetch = vi.fn().mockResolvedValue({ status: 200, ok: true })

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(data.received).toBe(true)
    expect(data.result.action).toBe('payment_failed')
    expect(data.result.attempt_count).toBe(1)
  })

  it('Step 7: Webhook processes subscription deleted (churn)', async () => {
    const webhookEvent = {
      id: 'evt_e2e_005',
      type: 'customer.subscription.deleted',
      data: {
        object: {
          id: 'sub_e2e_001',
          customer: 'cus_e2e_001',
        },
      },
    }

    const payload = JSON.stringify(webhookEvent)
    const timestamp = Math.floor(Date.now() / 1000)
    const signature = await signPayload(payload, env.STRIPE_WEBHOOK_SECRET, timestamp)

    globalThis.fetch = vi.fn().mockResolvedValue({ status: 200, ok: true })

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(data.received).toBe(true)
    expect(data.result.action).toBe('subscription_deleted')
  })

  it('Step 8: Subscriptions endpoint queries Stripe', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: async () => ({
        data: [
          {
            id: 'sub_e2e_001',
            status: 'active',
            metadata: { tier: 'pro' },
            current_period_end: 1735689600,
            cancel_at_period_end: false,
            items: {
              data: [
                {
                  price: { id: 'price_pro_m', unit_amount: 2900, recurring: { interval: 'month' } },
                },
              ],
            },
          },
        ],
      }),
    })

    const res = await worker.fetch(req('/subscriptions?customer_id=cus_e2e_001'), env, ctx)
    const data = await res.json()

    expect(res.status).toBe(200)
    expect(data.subscriptions).toHaveLength(1)
    expect(data.subscriptions[0].items[0].amount).toBe(2900)
  })

  it('Step 9: Portal creates billing session', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: async () => ({ url: 'https://billing.stripe.com/p/session/e2e_test' }),
    })

    const res = await worker.fetch(
      req('/portal', 'POST', { customer_id: 'cus_e2e_001' }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(res.status).toBe(200)
    expect(data.url).toContain('billing.stripe.com')
  })

  it('Step 10: Revenue returns balance data', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: async () => ({
        available: [{ amount: 290000, currency: 'usd' }],
        pending: [{ amount: 29000, currency: 'usd' }],
        data: [{ id: 'sub_1' }, { id: 'sub_2' }],
        has_more: false,
      }),
    })

    const res = await worker.fetch(req('/revenue'), env, ctx)
    const data = await res.json()

    expect(res.status).toBe(200)
    expect(data.balance.available).toBe(290000)
    expect(data.balance.pending).toBe(29000)
  })
})

describe('Webhook security', () => {
  let originalFetch: typeof fetch

  beforeEach(() => {
    originalFetch = globalThis.fetch
  })

  afterEach(() => {
    globalThis.fetch = originalFetch
  })

  it('rejects expired timestamps (replay attack prevention)', async () => {
    const payload = '{"type":"test"}'
    const oldTimestamp = Math.floor(Date.now() / 1000) - 600 // 10 minutes ago
    const signature = await signPayload(payload, env.STRIPE_WEBHOOK_SECRET, oldTimestamp)

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )

    expect(res.status).toBe(401)
  })

  it('rejects wrong secret', async () => {
    const payload = '{"type":"test"}'
    const timestamp = Math.floor(Date.now() / 1000)
    const signature = await signPayload(payload, 'wrong_secret', timestamp)

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )

    expect(res.status).toBe(401)
  })

  it('accepts valid signature within tolerance', async () => {
    const event = { id: 'evt_valid', type: 'test.event', data: { object: {} } }
    const payload = JSON.stringify(event)
    const timestamp = Math.floor(Date.now() / 1000)
    const signature = await signPayload(payload, env.STRIPE_WEBHOOK_SECRET, timestamp)

    globalThis.fetch = vi.fn().mockResolvedValue({ status: 200, ok: true })

    const res = await worker.fetch(
      req('/webhooks/stripe', 'POST', payload, { 'Stripe-Signature': signature }),
      env,
      ctx,
    )
    const data = await res.json()

    expect(res.status).toBe(200)
    expect(data.received).toBe(true)
  })
})
