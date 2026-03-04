// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
// E2E tests for the pay.blackroad.io Cloudflare Worker
import { describe, it, expect, vi, beforeEach } from 'vitest'

// Import the worker module
// We test the exported fetch handler directly
import worker from '../../workers/pay-blackroadio/src/index.js'

// Mock environment
const env = {
  STRIPE_SECRET_KEY: 'sk_test_fake_key_for_testing',
  STRIPE_WEBHOOK_SECRET: 'whsec_test_secret',
  STRIPE_PRICE_PRO_MONTHLY: 'price_pro_monthly_test',
  STRIPE_PRICE_PRO_YEARLY: 'price_pro_yearly_test',
  STRIPE_PRICE_ENT_MONTHLY: 'price_ent_monthly_test',
  STRIPE_PRICE_ENT_YEARLY: 'price_ent_yearly_test',
  CORS_ORIGIN: 'https://blackroad.io',
  SUCCESS_URL: 'https://blackroad.io/welcome',
  CANCEL_URL: 'https://blackroad.io/pricing',
  PI_WEBHOOK_PRIMARY: 'https://agent.blackroad.ai/webhooks/stripe',
  PI_WEBHOOK_SECONDARY: 'https://api.blackroad.ai/webhooks/stripe',
  PRICE_PRO_MONTHLY: '2900',
  PRICE_PRO_YEARLY: '29000',
  PRICE_ENT_MONTHLY: '19900',
  PRICE_ENT_YEARLY: '199000',
}

const ctx = {
  waitUntil: vi.fn(),
}

function makeRequest(path: string, method = 'GET', body?: unknown): Request {
  const opts: RequestInit = { method, headers: {} }
  if (body) {
    opts.body = JSON.stringify(body)
    ;(opts.headers as Record<string, string>)['Content-Type'] = 'application/json'
  }
  return new Request(`https://pay.blackroad.io${path}`, opts)
}

describe('pay-blackroadio worker', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    ctx.waitUntil.mockClear()
  })

  // ─── Health endpoint ───
  describe('GET /health', () => {
    it('returns status ok with pricing', async () => {
      const res = await worker.fetch(makeRequest('/health'), env, ctx)
      const data = await res.json()

      expect(res.status).toBe(200)
      expect(data.status).toBe('ok')
      expect(data.service).toBe('pay.blackroad.io')
      expect(data.version).toBe('1.0.0')
      expect(data.pricing.pro_monthly).toBe(2900)
      expect(data.pricing.pro_yearly).toBe(29000)
      expect(data.pricing.enterprise_monthly).toBe(19900)
      expect(data.pricing.enterprise_yearly).toBe(199000)
    })
  })

  // ─── Root path ───
  describe('GET /', () => {
    it('returns health response', async () => {
      const res = await worker.fetch(makeRequest('/'), env, ctx)
      expect(res.status).toBe(200)
    })
  })

  // ─── CORS ───
  describe('OPTIONS (CORS preflight)', () => {
    it('returns 204 with CORS headers', async () => {
      const req = new Request('https://pay.blackroad.io/checkout', { method: 'OPTIONS' })
      const res = await worker.fetch(req, env, ctx)

      expect(res.status).toBe(204)
      expect(res.headers.get('Access-Control-Allow-Origin')).toBe('https://blackroad.io')
      expect(res.headers.get('Access-Control-Allow-Methods')).toContain('POST')
    })
  })

  // ─── Checkout ───
  describe('POST /checkout', () => {
    it('rejects invalid tier', async () => {
      const res = await worker.fetch(
        makeRequest('/checkout', 'POST', { tier: 'invalid', interval: 'month' }),
        env,
        ctx,
      )
      const data = await res.json()

      expect(res.status).toBe(400)
      expect(data.error).toContain('Invalid tier/interval')
    })

    it('rejects missing body', async () => {
      const req = new Request('https://pay.blackroad.io/checkout', {
        method: 'POST',
        body: 'not json',
        headers: { 'Content-Type': 'text/plain' },
      })
      const res = await worker.fetch(req, env, ctx)
      expect(res.status).toBe(400)
    })

    it('creates checkout session for valid pro monthly', async () => {
      // Mock Stripe API
      const mockStripeResponse = {
        id: 'cs_test_123',
        url: 'https://checkout.stripe.com/pay/cs_test_123',
      }

      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          json: async () => mockStripeResponse,
        }),
      )

      const res = await worker.fetch(
        makeRequest('/checkout', 'POST', { tier: 'pro', interval: 'month', customer_email: 'test@blackroad.io' }),
        env,
        ctx,
      )
      const data = await res.json()

      expect(res.status).toBe(200)
      expect(data.url).toBe('https://checkout.stripe.com/pay/cs_test_123')
      expect(data.session_id).toBe('cs_test_123')

      // Verify Stripe was called correctly
      const fetchCalls = (fetch as ReturnType<typeof vi.fn>).mock.calls
      expect(fetchCalls.length).toBeGreaterThan(0)
      const [stripeUrl, stripeOpts] = fetchCalls[0]
      expect(stripeUrl).toBe('https://api.stripe.com/v1/checkout/sessions')
      expect(stripeOpts.method).toBe('POST')
      expect(stripeOpts.headers.Authorization).toBe('Bearer sk_test_fake_key_for_testing')
      expect(stripeOpts.body).toContain('price_pro_monthly_test')

      vi.unstubAllGlobals()
    })

    it('creates checkout session for enterprise yearly', async () => {
      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          json: async () => ({ id: 'cs_test_ent', url: 'https://checkout.stripe.com/pay/cs_test_ent' }),
        }),
      )

      const res = await worker.fetch(
        makeRequest('/checkout', 'POST', { tier: 'enterprise', interval: 'year' }),
        env,
        ctx,
      )
      const data = await res.json()

      expect(res.status).toBe(200)
      expect(data.session_id).toBe('cs_test_ent')

      const fetchCalls = (fetch as ReturnType<typeof vi.fn>).mock.calls
      expect(fetchCalls[0][1].body).toContain('price_ent_yearly_test')

      vi.unstubAllGlobals()
    })
  })

  // ─── Portal ───
  describe('POST /portal', () => {
    it('rejects missing customer_id', async () => {
      const res = await worker.fetch(makeRequest('/portal', 'POST', {}), env, ctx)
      const data = await res.json()

      expect(res.status).toBe(400)
      expect(data.error).toBe('customer_id required')
    })

    it('creates portal session', async () => {
      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          json: async () => ({ url: 'https://billing.stripe.com/session/test' }),
        }),
      )

      const res = await worker.fetch(
        makeRequest('/portal', 'POST', { customer_id: 'cus_test123' }),
        env,
        ctx,
      )
      const data = await res.json()

      expect(res.status).toBe(200)
      expect(data.url).toBe('https://billing.stripe.com/session/test')

      vi.unstubAllGlobals()
    })
  })

  // ─── Subscriptions ───
  describe('GET /subscriptions', () => {
    it('rejects missing customer_id', async () => {
      const res = await worker.fetch(makeRequest('/subscriptions'), env, ctx)
      const data = await res.json()

      expect(res.status).toBe(400)
      expect(data.error).toContain('customer_id')
    })

    it('returns subscriptions for a customer', async () => {
      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          json: async () => ({
            data: [
              {
                id: 'sub_test',
                status: 'active',
                metadata: { tier: 'pro' },
                current_period_end: 1735689600,
                cancel_at_period_end: false,
                items: {
                  data: [
                    {
                      price: { id: 'price_test', unit_amount: 2900, recurring: { interval: 'month' } },
                    },
                  ],
                },
              },
            ],
          }),
        }),
      )

      const res = await worker.fetch(
        makeRequest('/subscriptions?customer_id=cus_test123'),
        env,
        ctx,
      )
      const data = await res.json()

      expect(res.status).toBe(200)
      expect(data.subscriptions).toHaveLength(1)
      expect(data.subscriptions[0].id).toBe('sub_test')
      expect(data.subscriptions[0].status).toBe('active')
      expect(data.subscriptions[0].tier).toBe('pro')

      vi.unstubAllGlobals()
    })
  })

  // ─── Revenue ───
  describe('GET /revenue', () => {
    it('returns balance and subscription count', async () => {
      vi.stubGlobal(
        'fetch',
        vi.fn().mockResolvedValue({
          json: async () => ({
            available: [{ amount: 125000, currency: 'usd' }],
            pending: [{ amount: 29000, currency: 'usd' }],
            data: [{ id: 'sub_1' }],
            has_more: false,
          }),
        }),
      )

      const res = await worker.fetch(makeRequest('/revenue'), env, ctx)
      const data = await res.json()

      expect(res.status).toBe(200)
      expect(data.balance.available).toBe(125000)
      expect(data.balance.pending).toBe(29000)

      vi.unstubAllGlobals()
    })
  })

  // ─── Webhooks ───
  describe('POST /webhooks/stripe', () => {
    it('rejects missing signature', async () => {
      const req = new Request('https://pay.blackroad.io/webhooks/stripe', {
        method: 'POST',
        body: '{}',
      })
      const res = await worker.fetch(req, env, ctx)
      const data = await res.json()

      expect(res.status).toBe(401)
      expect(data.error).toBe('Invalid webhook signature')
    })

    it('rejects invalid signature', async () => {
      const req = new Request('https://pay.blackroad.io/webhooks/stripe', {
        method: 'POST',
        body: '{"type":"test"}',
        headers: {
          'Stripe-Signature': 't=1234567890,v1=invalid_signature',
        },
      })
      const res = await worker.fetch(req, env, ctx)
      const data = await res.json()

      expect(res.status).toBe(401)
    })
  })

  // ─── 404 ───
  describe('Unknown routes', () => {
    it('returns 404 with endpoint list', async () => {
      const res = await worker.fetch(makeRequest('/unknown'), env, ctx)
      const data = await res.json()

      expect(res.status).toBe(404)
      expect(data.error).toBe('Not found')
      expect(data.endpoints).toContain('/checkout')
      expect(data.endpoints).toContain('/webhooks/stripe')
      expect(data.endpoints).toContain('/revenue')
    })
  })
})
