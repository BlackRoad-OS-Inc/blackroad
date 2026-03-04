// pay.blackroad.io — Stripe Payment Gateway
// Handles checkout sessions, webhooks, subscription lifecycle, and Pi relay.
// BlackRoad OS, Inc. © 2026 — All Rights Reserved

// ─── Helpers ───────────────────────────────────────────────────────────────

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'X-BlackRoad-Worker': 'pay-blackroadio',
    },
  });
}

function cors(response, origin) {
  const headers = new Headers(response.headers);
  headers.set('Access-Control-Allow-Origin', origin || '*');
  headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  headers.set('Access-Control-Allow-Headers', 'Content-Type, Stripe-Signature');
  return new Response(response.body, { status: response.status, headers });
}

// Stripe API helper — all Stripe calls go through this
async function stripeAPI(method, endpoint, body, secretKey) {
  const url = `https://api.stripe.com/v1${endpoint}`;
  const opts = {
    method,
    headers: {
      Authorization: `Bearer ${secretKey}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  };
  if (body) opts.body = body;
  const res = await fetch(url, opts);
  return res.json();
}

// HMAC-SHA256 for webhook signature verification (Web Crypto API)
async function computeHMAC(secret, payload) {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(payload));
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// Verify Stripe webhook signature
async function verifyWebhookSignature(payload, sigHeader, webhookSecret) {
  if (!sigHeader) return false;
  const parts = {};
  for (const item of sigHeader.split(',')) {
    const [k, v] = item.split('=');
    if (k === 't') parts.t = v;
    if (k === 'v1') parts.v1 = v;
  }
  if (!parts.t || !parts.v1) return false;

  // Tolerance: reject if timestamp is > 5 minutes old
  const tolerance = 300;
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - parseInt(parts.t, 10)) > tolerance) return false;

  const signedPayload = `${parts.t}.${payload}`;
  const expected = await computeHMAC(webhookSecret, signedPayload);
  return expected === parts.v1;
}

// URL-encode form data from an object
function formEncode(obj) {
  const pairs = [];
  function encode(prefix, val) {
    if (val === null || val === undefined) return;
    if (typeof val === 'object' && !Array.isArray(val)) {
      for (const k of Object.keys(val)) {
        encode(`${prefix}[${k}]`, val[k]);
      }
    } else {
      pairs.push(`${encodeURIComponent(prefix)}=${encodeURIComponent(val)}`);
    }
  }
  for (const k of Object.keys(obj)) encode(k, obj[k]);
  return pairs.join('&');
}

// ─── Route Handlers ────────────────────────────────────────────────────────

// GET /health — liveness probe
function handleHealth(env) {
  return json({
    status: 'ok',
    service: 'pay.blackroad.io',
    version: '1.0.0',
    pricing: {
      pro_monthly: parseInt(env.PRICE_PRO_MONTHLY || '2900', 10),
      pro_yearly: parseInt(env.PRICE_PRO_YEARLY || '29000', 10),
      enterprise_monthly: parseInt(env.PRICE_ENT_MONTHLY || '19900', 10),
      enterprise_yearly: parseInt(env.PRICE_ENT_YEARLY || '199000', 10),
    },
  });
}

// POST /checkout — create a Stripe Checkout Session
async function handleCheckout(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  const { tier, interval, customer_email } = body;

  // Resolve price ID from tier + interval
  const priceMap = {
    'pro:month': env.STRIPE_PRICE_PRO_MONTHLY,
    'pro:year': env.STRIPE_PRICE_PRO_YEARLY,
    'enterprise:month': env.STRIPE_PRICE_ENT_MONTHLY,
    'enterprise:year': env.STRIPE_PRICE_ENT_YEARLY,
  };

  const priceKey = `${tier}:${interval}`;
  const priceId = priceMap[priceKey];

  if (!priceId) {
    return json(
      { error: `Invalid tier/interval: ${priceKey}`, valid: Object.keys(priceMap) },
      400,
    );
  }

  const params = {
    mode: 'subscription',
    'line_items[0][price]': priceId,
    'line_items[0][quantity]': '1',
    success_url: `${env.SUCCESS_URL}?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: env.CANCEL_URL,
    'subscription_data[trial_period_days]': '14',
    'subscription_data[metadata][tier]': tier,
    'subscription_data[metadata][source]': 'pay.blackroad.io',
  };
  if (customer_email) params.customer_email = customer_email;

  const session = await stripeAPI('POST', '/checkout/sessions', formEncode(params), env.STRIPE_SECRET_KEY);

  if (session.error) {
    return json({ error: session.error.message, code: session.error.code }, 400);
  }

  return json({ url: session.url, session_id: session.id });
}

// POST /portal — create a Stripe Billing Portal session
async function handlePortal(request, env) {
  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  const { customer_id } = body;
  if (!customer_id) return json({ error: 'customer_id required' }, 400);

  const session = await stripeAPI(
    'POST',
    '/billing_portal/sessions',
    formEncode({
      customer: customer_id,
      return_url: env.SUCCESS_URL,
    }),
    env.STRIPE_SECRET_KEY,
  );

  if (session.error) {
    return json({ error: session.error.message }, 400);
  }

  return json({ url: session.url });
}

// POST /webhooks/stripe — receive and process Stripe webhook events
async function handleWebhook(request, env, ctx) {
  const payload = await request.text();
  const sig = request.headers.get('Stripe-Signature');

  // Verify signature
  const valid = await verifyWebhookSignature(payload, sig, env.STRIPE_WEBHOOK_SECRET);
  if (!valid) {
    return json({ error: 'Invalid webhook signature' }, 401);
  }

  let event;
  try {
    event = JSON.parse(payload);
  } catch {
    return json({ error: 'Invalid JSON payload' }, 400);
  }

  const { type, data } = event;
  const obj = data?.object;

  // Process event synchronously for the response, relay async
  const result = processEvent(type, obj);

  // Relay to Pi infrastructure (fire and forget via waitUntil)
  ctx.waitUntil(relayToPi(env, event));

  return json({ received: true, type, result });
}

// Process a Stripe event and return a summary
function processEvent(type, obj) {
  switch (type) {
    case 'checkout.session.completed':
      return {
        action: 'new_checkout',
        customer: obj.customer,
        email: obj.customer_email || obj.customer_details?.email,
        subscription: obj.subscription,
        amount_total: obj.amount_total,
      };

    case 'customer.subscription.created':
      return {
        action: 'subscription_created',
        customer: obj.customer,
        subscription_id: obj.id,
        status: obj.status,
        tier: obj.metadata?.tier,
      };

    case 'customer.subscription.updated':
      return {
        action: 'subscription_updated',
        customer: obj.customer,
        subscription_id: obj.id,
        status: obj.status,
        cancel_at_period_end: obj.cancel_at_period_end,
      };

    case 'customer.subscription.deleted':
      return {
        action: 'subscription_deleted',
        customer: obj.customer,
        subscription_id: obj.id,
      };

    case 'invoice.payment_succeeded':
      return {
        action: 'payment_succeeded',
        customer: obj.customer,
        amount_paid: obj.amount_paid,
        invoice_id: obj.id,
      };

    case 'invoice.payment_failed':
      return {
        action: 'payment_failed',
        customer: obj.customer,
        amount_due: obj.amount_due,
        invoice_id: obj.id,
        attempt_count: obj.attempt_count,
      };

    default:
      return { action: 'unhandled', type };
  }
}

// Relay webhook event to Pi infrastructure via Cloudflare Tunnel
async function relayToPi(env, event) {
  const targets = [env.PI_WEBHOOK_PRIMARY, env.PI_WEBHOOK_SECONDARY].filter(Boolean);
  const body = JSON.stringify(event);

  const results = await Promise.allSettled(
    targets.map((url) =>
      fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-BlackRoad-Source': 'pay-blackroadio',
          'X-BlackRoad-Event': event.type,
        },
        body,
      }).then((r) => ({ url, status: r.status, ok: r.ok })),
    ),
  );

  return results.map((r) => (r.status === 'fulfilled' ? r.value : { error: r.reason?.message }));
}

// GET /subscriptions?customer_id=... — list customer subscriptions
async function handleSubscriptions(request, env) {
  const url = new URL(request.url);
  const customerId = url.searchParams.get('customer_id');
  if (!customerId) return json({ error: 'customer_id query param required' }, 400);

  const subs = await stripeAPI(
    'GET',
    `/subscriptions?customer=${encodeURIComponent(customerId)}&limit=10`,
    null,
    env.STRIPE_SECRET_KEY,
  );

  if (subs.error) return json({ error: subs.error.message }, 400);

  return json({
    subscriptions: (subs.data || []).map((s) => ({
      id: s.id,
      status: s.status,
      tier: s.metadata?.tier,
      current_period_end: s.current_period_end,
      cancel_at_period_end: s.cancel_at_period_end,
      items: (s.items?.data || []).map((i) => ({
        price_id: i.price?.id,
        amount: i.price?.unit_amount,
        interval: i.price?.recurring?.interval,
      })),
    })),
  });
}

// GET /revenue — revenue summary (balance + active sub count)
async function handleRevenue(env) {
  const [balance, subs] = await Promise.all([
    stripeAPI('GET', '/balance', null, env.STRIPE_SECRET_KEY),
    stripeAPI('GET', '/subscriptions?status=active&limit=1', null, env.STRIPE_SECRET_KEY),
  ]);

  if (balance.error) return json({ error: balance.error.message }, 400);

  const available = balance.available?.[0]?.amount || 0;
  const pending = balance.pending?.[0]?.amount || 0;

  return json({
    balance: { available, pending, currency: 'usd' },
    active_subscriptions: subs.data?.length || 0,
    has_more: subs.has_more || false,
  });
}

// ─── Router ────────────────────────────────────────────────────────────────

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return cors(new Response(null, { status: 204 }), env.CORS_ORIGIN);
    }

    let response;

    try {
      // Health check (no auth required)
      if (path === '/health' || path === '/') {
        response = handleHealth(env);
      }
      // Checkout session (POST)
      else if (path === '/checkout' && request.method === 'POST') {
        response = await handleCheckout(request, env);
      }
      // Billing portal (POST)
      else if (path === '/portal' && request.method === 'POST') {
        response = await handlePortal(request, env);
      }
      // Webhook receiver (POST)
      else if (path === '/webhooks/stripe' && request.method === 'POST') {
        response = await handleWebhook(request, env, ctx);
      }
      // Subscriptions query (GET)
      else if (path === '/subscriptions' && request.method === 'GET') {
        response = await handleSubscriptions(request, env);
      }
      // Revenue dashboard (GET)
      else if (path === '/revenue' && request.method === 'GET') {
        response = await handleRevenue(env);
      }
      // 404
      else {
        response = json({ error: 'Not found', endpoints: ['/health', '/checkout', '/portal', '/webhooks/stripe', '/subscriptions', '/revenue'] }, 404);
      }
    } catch (err) {
      response = json({ error: 'Internal server error', message: err.message }, 500);
    }

    return cors(response, env.CORS_ORIGIN);
  },
};
