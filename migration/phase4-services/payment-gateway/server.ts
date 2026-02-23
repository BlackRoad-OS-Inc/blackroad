/**
 * BlackRoad Payment Gateway - Self-Hosted (Hono)
 *
 * Ported from Cloudflare Worker: workers/payment-gateway/src/index.ts
 * Replaces: pay.blackroad.io, payments.blackroad.io
 * Port: 3002
 *
 * RUNS ON CECILIA (same machine as PostgreSQL for security)
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { serve } from '@hono/node-server';
import { KVNamespace } from '../adapters/kv-adapter.js';
import { D1Database } from '../adapters/d1-adapter.js';
import { PRICING, getTier, getStripePriceId, type PricingTier } from './pricing.js';
import { verifyWebhookSignature } from './webhook-verify.js';

const app = new Hono();

// Adapters
const SUBSCRIPTIONS_KV = new KVNamespace('SUBSCRIPTIONS_KV');
const USERS_KV = new KVNamespace('USERS_KV');
const REVENUE_D1 = new D1Database('blackroad_revenue');

const CORS_ORIGIN = process.env.CORS_ORIGIN || 'https://blackroad.io';

app.use('*', cors({
  origin: CORS_ORIGIN,
  allowMethods: ['GET', 'POST', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// ─── HTML Helpers ───
function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// ─── Health ───
app.get('/health', (c) => c.json({
  status: 'healthy',
  version: '3.0.0',
  source: 'self-hosted',
  timestamp: new Date().toISOString(),
}));

// ─── Pricing ───
app.get('/api/pricing', (c) => c.json(PRICING));

// ─── Pricing Page ───
app.get('/', (c) => {
  return c.html(renderPricingPage());
});

app.get('/success', (c) => c.html(renderSuccessPage()));
app.get('/cancel', (c) => c.html(renderCancelPage()));

// ─── Checkout Session ───
app.post('/create-checkout-session', async (c) => {
  const body = await c.req.json<{
    tierId?: string;
    billingPeriod?: string;
    userId?: string;
    email?: string;
  }>();
  const { tierId, billingPeriod = 'monthly', userId, email } = body;

  const tier = getTier(tierId || '');
  if (!tier || tier.id === 'free' || tier.id === 'custom') {
    return c.json({ error: 'Invalid tier for checkout' }, 400);
  }

  const priceId = getStripePriceId(tier, billingPeriod as 'monthly' | 'yearly');
  if (!priceId) {
    return c.json({ error: 'Price not configured. Set Stripe price ID env vars.' }, 500);
  }

  const params = new URLSearchParams({
    'mode': 'subscription',
    'payment_method_types[]': 'card',
    'line_items[0][price]': priceId,
    'line_items[0][quantity]': '1',
    'success_url': 'https://pay.blackroad.io/success?session_id={CHECKOUT_SESSION_ID}',
    'cancel_url': 'https://pay.blackroad.io/cancel',
    'allow_promotion_codes': 'true',
    'automatic_tax[enabled]': 'true',
    'billing_address_collection': 'required',
    'tax_id_collection[enabled]': 'true',
    'metadata[tier_id]': tier.id,
  });

  if (email) params.set('customer_email', email);
  if (userId) {
    params.set('client_reference_id', userId);
    params.set('metadata[user_id]', userId);
  }
  if (tier.trialDays > 0) {
    params.set('subscription_data[trial_period_days]', String(tier.trialDays));
  }

  const res = await stripeAPI('POST', '/v1/checkout/sessions', params.toString());
  const session = await res.json() as { id?: string; url?: string; error?: { message?: string } };

  if (session.error) {
    return c.json({ error: session.error.message || 'Stripe error' }, 400);
  }

  return c.json({ sessionId: session.id, url: session.url });
});

// ─── Portal Session ───
app.post('/create-portal-session', async (c) => {
  const { customerId } = await c.req.json<{ customerId?: string }>();
  if (!customerId) return c.json({ error: 'Missing customerId' }, 400);

  const params = new URLSearchParams({
    'customer': customerId,
    'return_url': 'https://pay.blackroad.io/',
  });

  const res = await stripeAPI('POST', '/v1/billing_portal/sessions', params.toString());
  const session = await res.json() as { url?: string; error?: { message?: string } };

  if (session.error) {
    return c.json({ error: session.error.message || 'Stripe error' }, 400);
  }

  return c.json({ url: session.url });
});

// ─── Webhook ───
app.post('/webhook', async (c) => {
  const sigHeader = c.req.header('stripe-signature');
  if (!sigHeader) {
    return c.json({ error: 'Missing Stripe-Signature header' }, 400);
  }

  const body = await c.req.text();
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret) {
    return c.json({ error: 'Webhook secret not configured' }, 500);
  }

  const verification = await verifyWebhookSignature(body, sigHeader, secret);
  if (!verification.valid) {
    console.error('Webhook verification failed:', verification.error);
    return c.json({ error: 'Invalid signature' }, 400);
  }

  const event = JSON.parse(body) as { id: string; type: string; data: { object: any } };

  // Idempotency check
  const existing = await REVENUE_D1.prepare(
    'SELECT stripe_event_id FROM webhook_events WHERE stripe_event_id = ?'
  ).bind(event.id).first();

  if (existing) {
    return c.json({ received: true, duplicate: true });
  }

  let success = true;
  try {
    switch (event.type) {
      case 'checkout.session.completed':
        await handleCheckoutCompleted(event.data.object);
        break;
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await handleSubscriptionUpdate(event.data.object);
        break;
      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;
      case 'invoice.payment_succeeded':
        await handlePaymentSucceeded(event.data.object);
        break;
      case 'invoice.payment_failed':
        console.error('Payment failed for invoice:', event.data.object.id);
        break;
    }
  } catch (err) {
    console.error(`Webhook handler error for ${event.type}:`, err);
    success = false;
  }

  await REVENUE_D1.prepare(
    'INSERT INTO webhook_events (stripe_event_id, event_type, processed_at, success) VALUES (?, ?, ?, ?)'
  ).bind(event.id, event.type, new Date().toISOString(), success ? 1 : 0).run();

  return c.json({ received: true });
});

// ─── Subscription Status ───
app.get('/subscription-status', async (c) => {
  const userId = c.req.query('userId');
  if (!userId) return c.json({ error: 'Missing userId' }, 400);

  const subscription = await SUBSCRIPTIONS_KV.get(`user:${userId}`, 'json');
  return c.json(subscription || { status: 'none' });
});

// ─── Webhook Handlers ───
async function handleCheckoutCompleted(session: any): Promise<void> {
  const userId = session.client_reference_id || session.metadata?.user_id;
  const tierId = session.metadata?.tier_id;
  if (!userId) return;

  if (session.subscription) {
    const now = new Date().toISOString();
    await REVENUE_D1.prepare(`
      INSERT INTO subscriptions (stripe_subscription_id, stripe_customer_id, user_id, tier_id, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, 'active', ?, ?)
      ON CONFLICT(stripe_subscription_id) DO UPDATE SET status='active', updated_at=?
    `).bind(
      session.subscription, session.customer, userId, tierId || 'pro', now, now, now
    ).run();
  }

  await SUBSCRIPTIONS_KV.put(
    `user:${userId}`,
    JSON.stringify({
      userId, tierId,
      customerId: session.customer,
      subscriptionId: session.subscription,
      status: 'active',
      createdAt: new Date().toISOString(),
    })
  );

  if (session.amount_total) {
    await REVENUE_D1.prepare(
      'INSERT INTO revenue (user_id, tier_id, amount, currency, created_at) VALUES (?, ?, ?, ?, ?)'
    ).bind(userId, tierId, session.amount_total / 100, session.currency || 'usd', new Date().toISOString()).run();
  }
}

async function handleSubscriptionUpdate(subscription: any): Promise<void> {
  const userId = subscription.metadata?.user_id;
  const now = new Date().toISOString();
  const periodEnd = subscription.current_period_end
    ? new Date(subscription.current_period_end * 1000).toISOString()
    : null;

  await REVENUE_D1.prepare(`
    UPDATE subscriptions
    SET status = ?, current_period_end = ?, cancel_at_period_end = ?, updated_at = ?
    WHERE stripe_subscription_id = ?
  `).bind(subscription.status, periodEnd, subscription.cancel_at_period_end ? 1 : 0, now, subscription.id).run();

  if (userId) {
    const existing = await SUBSCRIPTIONS_KV.get(`user:${userId}`, 'json') as any;
    if (existing) {
      await SUBSCRIPTIONS_KV.put(`user:${userId}`, JSON.stringify({
        ...existing, status: subscription.status, currentPeriodEnd: periodEnd, updatedAt: now,
      }));
    }
  }
}

async function handleSubscriptionDeleted(subscription: any): Promise<void> {
  const userId = subscription.metadata?.user_id;
  const now = new Date().toISOString();

  await REVENUE_D1.prepare(
    'UPDATE subscriptions SET status = ?, updated_at = ? WHERE stripe_subscription_id = ?'
  ).bind('canceled', now, subscription.id).run();

  if (userId) {
    const existing = await SUBSCRIPTIONS_KV.get(`user:${userId}`, 'json') as any;
    if (existing) {
      await SUBSCRIPTIONS_KV.put(`user:${userId}`, JSON.stringify({
        ...existing, status: 'canceled', canceledAt: now,
      }));
    }
  }
}

async function handlePaymentSucceeded(invoice: any): Promise<void> {
  const userId = invoice.subscription_details?.metadata?.user_id || invoice.metadata?.user_id;
  if (!userId) return;

  await REVENUE_D1.prepare(
    'INSERT INTO revenue (user_id, amount, currency, created_at) VALUES (?, ?, ?, ?)'
  ).bind(userId, (invoice.amount_paid || 0) / 100, invoice.currency || 'usd', new Date().toISOString()).run();
}

// ─── Stripe API Helper ───
async function stripeAPI(method: string, endpoint: string, body?: string): Promise<globalThis.Response> {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) throw new Error('STRIPE_SECRET_KEY not set');

  return fetch(`https://api.stripe.com${endpoint}`, {
    method,
    headers: {
      'Authorization': `Bearer ${key}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });
}

// ─── HTML Pages ───
function pageShell(title: string, content: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${title} - BlackRoad OS</title>
<style>
  :root {
    --black: #000000; --white: #FFFFFF; --amber: #F5A623;
    --hot-pink: #FF1D6C; --electric-blue: #2979FF; --violet: #9C27B0;
    --gradient-brand: linear-gradient(135deg, #F5A623 0%, #FF1D6C 38.2%, #9C27B0 61.8%, #2979FF 100%);
    --space-xs: 8px; --space-sm: 13px; --space-md: 21px;
    --space-lg: 34px; --space-xl: 55px; --space-2xl: 89px;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
    background: var(--black); color: var(--white); line-height: 1.618; min-height: 100vh; }
  a { color: var(--hot-pink); text-decoration: none; }
  a:hover { text-decoration: underline; }
</style>
${content}`;
}

function renderPricingPage(): string {
  const tierCards = PRICING.map((tier) => {
    const isPopular = tier.popular;
    const isCustom = tier.id === 'custom';
    const isFree = tier.id === 'free';
    const monthlyDisplay = isCustom ? 'Custom' : isFree ? '$0' : `$${tier.priceMonthly}`;
    const yearlyDisplay = isCustom ? 'Custom' : isFree ? '$0' : `$${Math.round(tier.priceYearly / 12)}`;
    const featuresHtml = tier.features.map(f => `<li><span class="check">&#10003;</span> ${f}</li>`).join('');
    const buttonAction = isFree
      ? 'onclick="window.location.href=\'https://blackroad.io/signup\'"'
      : isCustom
        ? 'onclick="window.location.href=\'mailto:sales@blackroad.io?subject=Enterprise%20Custom%20Inquiry\'"'
        : `onclick="checkout('${tier.id}')"`;

    return `<div class="tier-card${isPopular ? ' popular' : ''}">
      ${isPopular ? '<div class="popular-badge">Most Popular</div>' : ''}
      <h3>${tier.name}</h3>
      <div class="price">
        <span class="amount monthly-price">${monthlyDisplay}</span>
        <span class="amount yearly-price" style="display:none">${yearlyDisplay}</span>
        ${!isCustom && !isFree ? '<span class="period monthly-label">/mo</span><span class="period yearly-label" style="display:none">/mo (billed yearly)</span>' : ''}
      </div>
      ${tier.trialDays > 0 ? `<p class="trial">${tier.trialDays}-day free trial</p>` : ''}
      <ul class="features">${featuresHtml}</ul>
      <button class="cta-btn${isPopular ? ' cta-primary' : ''}" ${buttonAction}>${tier.cta}</button>
    </div>`;
  }).join('');

  return pageShell('Pricing', `
<style>
  .hero{text-align:center;padding:var(--space-2xl) var(--space-lg) var(--space-xl)}
  .hero h1{font-size:3rem;font-weight:800;background:var(--gradient-brand);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:var(--space-sm)}
  .hero p{color:#aaa;font-size:1.2rem;max-width:600px;margin:0 auto}
  .toggle-wrap{display:flex;align-items:center;justify-content:center;gap:var(--space-sm);margin-top:var(--space-lg)}
  .toggle-label{font-size:.95rem;color:#888;cursor:pointer}.toggle-label.active{color:var(--white);font-weight:600}
  .toggle{width:48px;height:26px;border-radius:13px;background:#333;position:relative;cursor:pointer;transition:background .2s}
  .toggle.yearly{background:var(--hot-pink)}.toggle::after{content:'';position:absolute;top:3px;left:3px;width:20px;height:20px;border-radius:50%;background:var(--white);transition:transform .2s}.toggle.yearly::after{transform:translateX(22px)}
  .save-badge{background:var(--hot-pink);color:var(--white);font-size:.75rem;padding:2px 8px;border-radius:10px;font-weight:600}
  .tiers{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:var(--space-lg);max-width:1200px;margin:0 auto;padding:0 var(--space-lg) var(--space-2xl)}
  .tier-card{background:#111;border:1px solid #222;border-radius:var(--space-sm);padding:var(--space-lg);display:flex;flex-direction:column;position:relative}
  .tier-card.popular{border-color:var(--hot-pink);box-shadow:0 0 34px rgba(255,29,108,.15)}
  .popular-badge{position:absolute;top:-13px;left:50%;transform:translateX(-50%);background:var(--gradient-brand);color:var(--white);font-size:.75rem;font-weight:700;padding:4px 16px;border-radius:10px;white-space:nowrap}
  .tier-card h3{font-size:1.3rem;margin-bottom:var(--space-xs)}.price{margin-bottom:var(--space-sm)}.price .amount{font-size:2.5rem;font-weight:800}.price .period{color:#666;font-size:.9rem}
  .trial{color:var(--amber);font-size:.85rem;margin-bottom:var(--space-sm)}
  .features{list-style:none;flex:1;margin-bottom:var(--space-lg)}.features li{padding:6px 0;font-size:.9rem;color:#ccc}.features .check{color:var(--hot-pink);margin-right:6px}
  .cta-btn{width:100%;padding:var(--space-sm) var(--space-md);border:1px solid #333;border-radius:8px;background:transparent;color:var(--white);font-size:1rem;font-weight:600;cursor:pointer;transition:all .2s}
  .cta-btn:hover{border-color:var(--hot-pink);background:rgba(255,29,108,.1)}.cta-btn.cta-primary{background:var(--gradient-brand);border:none}.cta-btn.cta-primary:hover{opacity:.9}
  footer{text-align:center;padding:var(--space-xl) var(--space-lg);color:#444;font-size:.85rem}
  @media(max-width:768px){.hero h1{font-size:2rem}.tiers{grid-template-columns:1fr;padding:0 var(--space-md) var(--space-xl)}}
</style>
</head>
<body>
  <div class="hero">
    <h1>BlackRoad OS Pricing</h1>
    <p>Your AI. Your Hardware. Your Rules. Choose the plan that scales with you.</p>
    <div class="toggle-wrap">
      <span class="toggle-label active" id="lbl-monthly" onclick="setPeriod('monthly')">Monthly</span>
      <div class="toggle" id="period-toggle" onclick="togglePeriod()"></div>
      <span class="toggle-label" id="lbl-yearly" onclick="setPeriod('yearly')">Yearly</span>
      <span class="save-badge">Save 17%</span>
    </div>
  </div>
  <div class="tiers">${tierCards}</div>
  <footer>&copy; ${new Date().getFullYear()} BlackRoad OS, Inc. All rights reserved.</footer>
  <script>
    let period='monthly';
    function setPeriod(p){period=p;const t=document.getElementById('period-toggle'),m=document.getElementById('lbl-monthly'),y=document.getElementById('lbl-yearly');t.classList.toggle('yearly',p==='yearly');m.classList.toggle('active',p==='monthly');y.classList.toggle('active',p==='yearly');document.querySelectorAll('.monthly-price').forEach(el=>el.style.display=p==='monthly'?'':'none');document.querySelectorAll('.yearly-price').forEach(el=>el.style.display=p==='yearly'?'':'none');document.querySelectorAll('.monthly-label').forEach(el=>el.style.display=p==='monthly'?'':'none');document.querySelectorAll('.yearly-label').forEach(el=>el.style.display=p==='yearly'?'':'none');}
    function togglePeriod(){setPeriod(period==='monthly'?'yearly':'monthly');}
    async function checkout(tierId){const btn=event.target;btn.textContent='Loading...';btn.disabled=true;try{const res=await fetch('/create-checkout-session',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tierId,billingPeriod:period})});const data=await res.json();if(data.url){window.location.href=data.url}else{alert(data.error||'Something went wrong');btn.textContent='Try Again';btn.disabled=false}}catch(e){alert('Network error.');btn.textContent='Try Again';btn.disabled=false}}
  </script>
</body></html>`);
}

function renderSuccessPage(): string {
  return pageShell('Payment Successful', `
<style>.container{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:var(--space-lg)}.card{background:#111;border:1px solid #222;border-radius:var(--space-sm);padding:var(--space-xl);text-align:center;max-width:500px;width:100%}.card h1{font-size:2rem;font-weight:800;background:var(--gradient-brand);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;margin-bottom:var(--space-md)}.card p{color:#aaa;margin-bottom:var(--space-lg)}.card .icon{font-size:3rem;margin-bottom:var(--space-md)}.btn{display:inline-block;padding:var(--space-sm) var(--space-lg);background:var(--gradient-brand);color:var(--white);border-radius:8px;font-weight:600;text-decoration:none}.btn:hover{opacity:.9;text-decoration:none}</style>
</head><body>
  <div class="container"><div class="card">
    <div class="icon">&#10003;</div>
    <h1>Welcome to BlackRoad OS</h1>
    <p>Your subscription is active. You now have access to all the features in your plan.</p>
    <a class="btn" href="https://blackroad.io/dashboard">Go to Dashboard</a>
  </div></div>
</body></html>`);
}

function renderCancelPage(): string {
  return pageShell('Checkout Canceled', `
<style>.container{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:var(--space-lg)}.card{background:#111;border:1px solid #222;border-radius:var(--space-sm);padding:var(--space-xl);text-align:center;max-width:500px;width:100%}.card h1{font-size:1.8rem;margin-bottom:var(--space-md)}.card p{color:#aaa;margin-bottom:var(--space-lg)}.btn{display:inline-block;padding:var(--space-sm) var(--space-lg);border:1px solid var(--hot-pink);color:var(--hot-pink);border-radius:8px;font-weight:600;text-decoration:none}.btn:hover{background:rgba(255,29,108,.1);text-decoration:none}</style>
</head><body>
  <div class="container"><div class="card">
    <h1>No worries!</h1>
    <p>Your checkout was canceled. No charges were made. Come back anytime.</p>
    <a class="btn" href="https://pay.blackroad.io/">Back to Pricing</a>
  </div></div>
</body></html>`);
}

// ─── Start ───
const PORT = parseInt(process.env.PORT || '3002');
console.log(`[payment-gateway] Starting on port ${PORT}`);

serve({ fetch: app.fetch, port: PORT }, (info) => {
  console.log(`[payment-gateway] Listening on http://0.0.0.0:${info.port}`);
});

export default app;
