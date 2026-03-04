// roadgateway — BlackRoad OS Payment Gateway
// Cloudflare Worker: pay.blackroad.io
// Handles Stripe Checkout, webhooks, billing portal, and Pi forwarding.
// BlackRoad OS, Inc. © 2026 — All Rights Reserved

// ─── Helpers ────────────────────────────────────────────────────────────────

function json(data, status = 200, headers = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      ...headers,
    },
  });
}

function cors() {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization, Stripe-Signature',
    },
  });
}

async function stripeAPI(method, endpoint, body, env) {
  const url = `https://api.stripe.com/v1${endpoint}`;
  const opts = {
    method,
    headers: {
      'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  };
  if (body) opts.body = body;
  const res = await fetch(url, opts);
  return res.json();
}

// ─── Webhook Signature Verification ─────────────────────────────────────────

async function verifyStripeSignature(payload, sigHeader, secret) {
  const parts = sigHeader.split(',').reduce((acc, part) => {
    const [k, v] = part.split('=');
    acc[k] = v;
    return acc;
  }, {});

  const timestamp = parts['t'];
  const signature = parts['v1'];
  if (!timestamp || !signature) return false;

  // Reject events older than 5 minutes
  const age = Math.floor(Date.now() / 1000) - parseInt(timestamp, 10);
  if (age > 300) return false;

  const signedPayload = `${timestamp}.${payload}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signedPayload));
  const expected = Array.from(new Uint8Array(sig))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  return expected === signature;
}

// ─── Pricing (must match src/stripe/pricing.ts & br-stripe.sh) ─────────────

const TIERS = {
  free: { name: 'Free', agents: 5, tasks: 500, monthly: 0, yearly: 0 },
  pro: { name: 'BlackRoad OS Pro', agents: 100, tasks: 10000, monthly: 2900, yearly: 29000 },
  enterprise: { name: 'BlackRoad OS Enterprise', agents: -1, tasks: -1, monthly: 19900, yearly: 199000 },
};

function fmtCents(c) { return `$${(c / 100).toFixed(2)}`; }

// ─── Route: Create Checkout Session ─────────────────────────────────────────

async function createCheckout(request, env) {
  const body = await request.json();
  const { tier, period, email, successUrl, cancelUrl } = body;

  if (!tier || !period) {
    return json({ error: 'Missing tier or period' }, 400);
  }

  const priceMap = {
    'pro:monthly': env.STRIPE_PRICE_PRO_MONTHLY,
    'pro:yearly': env.STRIPE_PRICE_PRO_YEARLY,
    'enterprise:monthly': env.STRIPE_PRICE_ENT_MONTHLY,
    'enterprise:yearly': env.STRIPE_PRICE_ENT_YEARLY,
  };

  const priceId = priceMap[`${tier}:${period}`];
  if (!priceId) {
    return json({ error: `Invalid tier/period: ${tier}/${period}` }, 400);
  }

  const params = new URLSearchParams({
    'mode': 'subscription',
    'line_items[0][price]': priceId,
    'line_items[0][quantity]': '1',
    'success_url': successUrl || env.SUCCESS_URL || 'https://blackroad.io/welcome?session_id={CHECKOUT_SESSION_ID}',
    'cancel_url': cancelUrl || env.CANCEL_URL || 'https://store.blackroad.io',
    'metadata[tier]': tier,
    'metadata[period]': period,
    'metadata[source]': 'roadgateway',
  });

  if (email) {
    params.set('customer_email', email);
  }

  const session = await stripeAPI('POST', '/checkout/sessions', params.toString(), env);

  if (session.error) {
    return json({ error: session.error.message }, 400);
  }

  return json({ sessionId: session.id, url: session.url });
}

// ─── Route: Billing Portal ──────────────────────────────────────────────────

async function createPortal(request, env) {
  const body = await request.json();
  const { customerId, returnUrl } = body;

  if (!customerId) {
    return json({ error: 'Missing customerId' }, 400);
  }

  const params = new URLSearchParams({
    'customer': customerId,
    'return_url': returnUrl || 'https://blackroad.io/account',
  });

  const session = await stripeAPI('POST', '/billing_portal/sessions', params.toString(), env);

  if (session.error) {
    return json({ error: session.error.message }, 400);
  }

  return json({ url: session.url });
}

// ─── Route: Webhook Handler ─────────────────────────────────────────────────

async function handleWebhook(request, env) {
  const payload = await request.text();
  const sig = request.headers.get('Stripe-Signature');

  if (!sig) {
    return json({ error: 'Missing Stripe-Signature header' }, 400);
  }

  const valid = await verifyStripeSignature(payload, sig, env.STRIPE_WEBHOOK_SECRET);
  if (!valid) {
    return json({ error: 'Invalid signature' }, 401);
  }

  const event = JSON.parse(payload);
  const type = event.type;
  const data = event.data?.object;

  console.log(`[roadgateway] Webhook: ${type} — ${data?.id || 'unknown'}`);

  // Forward to Pi webhook router if configured
  if (env.PI_WEBHOOK_URL) {
    try {
      const fwdHeaders = {
        'Content-Type': 'application/json',
        'X-Roadgateway-Event': type,
        'X-Roadgateway-Timestamp': new Date().toISOString(),
      };
      if (env.PI_WEBHOOK_SECRET) {
        const key = await crypto.subtle.importKey(
          'raw',
          new TextEncoder().encode(env.PI_WEBHOOK_SECRET),
          { name: 'HMAC', hash: 'SHA-256' },
          false,
          ['sign']
        );
        const sigBytes = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload));
        fwdHeaders['X-Roadgateway-Signature'] = Array.from(new Uint8Array(sigBytes))
          .map(b => b.toString(16).padStart(2, '0'))
          .join('');
      }
      await fetch(env.PI_WEBHOOK_URL, {
        method: 'POST',
        headers: fwdHeaders,
        body: payload,
      });
    } catch (err) {
      console.error(`[roadgateway] Pi forward failed: ${err.message}`);
    }
  }

  // Process event
  switch (type) {
    case 'checkout.session.completed': {
      const customerId = data.customer;
      const tier = data.metadata?.tier;
      const period = data.metadata?.period;
      console.log(`[roadgateway] New subscription: ${customerId} → ${tier}/${period}`);
      break;
    }
    case 'customer.subscription.updated': {
      console.log(`[roadgateway] Subscription updated: ${data.id} → ${data.status}`);
      break;
    }
    case 'customer.subscription.deleted': {
      console.log(`[roadgateway] Subscription canceled: ${data.id}`);
      break;
    }
    case 'invoice.payment_succeeded': {
      console.log(`[roadgateway] Payment received: ${data.id} — ${fmtCents(data.amount_paid || 0)}`);
      break;
    }
    case 'invoice.payment_failed': {
      console.log(`[roadgateway] Payment failed: ${data.id} — ${data.customer}`);
      break;
    }
    default:
      console.log(`[roadgateway] Unhandled event: ${type}`);
  }

  return json({ received: true, type });
}

// ─── Route: Pricing API ─────────────────────────────────────────────────────

function getPricing() {
  return json({
    tiers: Object.entries(TIERS).map(([id, t]) => ({
      id,
      name: t.name,
      agents: t.agents === -1 ? 'Unlimited' : t.agents,
      tasksPerMonth: t.tasks === -1 ? 'Unlimited' : t.tasks,
      prices: {
        monthly: fmtCents(t.monthly),
        yearly: fmtCents(t.yearly),
        monthlyCents: t.monthly,
        yearlyCents: t.yearly,
      },
    })),
    currency: 'usd',
  });
}

// ─── Landing Page ───────────────────────────────────────────────────────────

function landingPage(env) {
  const CSS = `*{margin:0;padding:0;box-sizing:border-box}:root{--pink:#FF1D6C;--amber:#F5A623;--violet:#9C27B0;--blue:#2979FF;--bg:#000;--surface:#0a0a0a;--border:#1a1a1a;--text:#fff;--muted:#888;--gradient:linear-gradient(135deg,var(--amber) 0%,var(--pink) 38.2%,var(--violet) 61.8%,var(--blue) 100%)}body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display',sans-serif;background:var(--bg);color:var(--text);min-height:100vh}header{padding:60px 40px;text-align:center}header h1{font-size:3rem;font-weight:800;background:var(--gradient);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:8px}header p{color:var(--muted);font-size:1.1rem}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:20px;padding:40px;max-width:1000px;margin:0 auto}.card{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:28px;text-align:center;transition:.2s}.card:hover{border-color:var(--pink);transform:translateY(-2px)}.card h2{font-size:1.3rem;margin-bottom:8px}.card .price{font-size:2.2rem;font-weight:700;color:var(--pink);margin:16px 0}.card .period{color:var(--muted);font-size:.9rem}.card ul{list-style:none;margin:16px 0;text-align:left}.card li{padding:6px 0;font-size:.9rem;color:var(--muted)}.card li::before{content:'✓ ';color:var(--pink)}.btn{display:inline-block;padding:12px 32px;background:var(--gradient);color:#fff;font-weight:600;border:none;border-radius:8px;cursor:pointer;font-size:1rem;text-decoration:none;margin-top:16px;transition:.2s}.btn:hover{opacity:.9;transform:scale(1.02)}.btn-outline{background:transparent;border:1px solid var(--border);color:var(--text)}.btn-outline:hover{border-color:var(--pink)}footer{text-align:center;padding:40px;color:#333;font-size:.8rem;border-top:1px solid var(--border)}`;

  const tiers = [
    { id: 'free', name: 'Free', price: '$0', period: '/forever', features: ['5 AI Agents', '500 tasks/month', 'Community support', 'Public dashboard'], cta: 'Get Started', outline: true },
    { id: 'pro', name: 'Pro', price: '$29', period: '/month', features: ['100 AI Agents', '10,000 tasks/month', 'Priority support', 'Custom agent configs', 'Memory system', 'Pi cluster integration'], cta: 'Subscribe', outline: false },
    { id: 'enterprise', name: 'Enterprise', price: '$199', period: '/month', features: ['Unlimited Agents', 'Unlimited tasks', 'SSO / SAML', '99.9% SLA', 'Dedicated support', 'Custom deployments', 'On-prem / Pi cluster'], cta: 'Subscribe', outline: false },
  ];

  const cards = tiers.map(t => `
    <div class="card">
      <h2>${t.name}</h2>
      <div class="price">${t.price}<span class="period">${t.period}</span></div>
      <ul>${t.features.map(f => `<li>${f}</li>`).join('')}</ul>
      ${t.id === 'free'
        ? `<a href="https://blackroad.io/signup" class="btn btn-outline">${t.cta}</a>`
        : `<button class="btn" onclick="checkout('${t.id}','monthly')">${t.cta}</button>`
      }
    </div>`).join('');

  return new Response(`<!DOCTYPE html><html lang="en"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>BlackRoad OS — Pricing</title>
<style>${CSS}</style>
</head><body>
<header>
  <h1>BlackRoad OS</h1>
  <p>Your AI. Your Hardware. Your Rules.</p>
</header>
<div class="grid">${cards}</div>
<footer>© 2026 BlackRoad OS, Inc. All Rights Reserved</footer>
<script>
async function checkout(tier, period) {
  try {
    const res = await fetch('/api/checkout', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tier, period }),
    });
    const data = await res.json();
    if (data.url) {
      window.location.href = data.url;
    } else {
      alert(data.error || 'Checkout failed');
    }
  } catch (e) {
    alert('Connection error');
  }
}
</script>
</body></html>`, { headers: { 'Content-Type': 'text/html;charset=UTF-8', 'Cache-Control': 'public, max-age=60' } });
}

// ─── Worker Entry ───────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname, method } = { pathname: url.pathname, method: request.method };

    if (method === 'OPTIONS') return cors();

    // Health check
    if (pathname === '/health') {
      return json({
        status: 'ok',
        worker: 'roadgateway',
        stripe: !!env.STRIPE_SECRET_KEY,
        piForward: !!env.PI_WEBHOOK_URL,
        ts: Date.now(),
      });
    }

    // Pricing
    if (pathname === '/api/pricing') {
      return getPricing();
    }

    // Create checkout session
    if (pathname === '/api/checkout' && method === 'POST') {
      if (!env.STRIPE_SECRET_KEY) return json({ error: 'Stripe not configured' }, 503);
      return createCheckout(request, env);
    }

    // Billing portal
    if (pathname === '/api/portal' && method === 'POST') {
      if (!env.STRIPE_SECRET_KEY) return json({ error: 'Stripe not configured' }, 503);
      return createPortal(request, env);
    }

    // Stripe webhook
    if (pathname === '/webhook' && method === 'POST') {
      if (!env.STRIPE_WEBHOOK_SECRET) return json({ error: 'Webhook not configured' }, 503);
      return handleWebhook(request, env);
    }

    // Landing / pricing page
    if (pathname === '/' || pathname === '/pricing') {
      return landingPage(env);
    }

    return json({ error: 'Not found' }, 404);
  },
};
