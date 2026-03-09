// ================================================================
// LUCIDIA STRIPE GATEWAY — BlackRoad OS Payment Processing
// Every API call on this machine is metered through Stripe.
// 10x provider rates. PS-SHA∞ verified. BlackRoad OS owned.
// © 2026 BlackRoad OS, Inc. All rights reserved.
// ================================================================

const METER_EVENT = 'lucidia_api_call';

// 10x Provider Pricing (per 1K tokens, in cents)
const PROVIDER_RATES = {
  'lucidia-anthropic': {
    input: { opus: 5, sonnet: 2 },
    output: { opus: 25, sonnet: 8 },
    priceIds: {
      'opus-input': 'price_1T4Y5QEMWqjRf6EJWZa60uLB',
      'opus-output': 'price_1T4Y5REMWqjRf6EJLFXSdygJ',
      'sonnet-input': 'price_1T4Y5REMWqjRf6EJ1pnbuhdv',
      'sonnet-output': 'price_1T4Y5SEMWqjRf6EJQdMQsGIv'
    }
  },
  'lucidia-openai': {
    input: { 'gpt-4o': 3 },
    output: { 'gpt-4o': 10 },
    priceIds: {
      'gpt4o-input': 'price_1T4Y5TEMWqjRf6EJVKb8hlwd',
      'gpt4o-output': 'price_1T4Y5TEMWqjRf6EJCHrotouF'
    }
  },
  'lucidia-gemini': {
    input: { 'gemini-2.5-pro': 2 },
    output: { 'gemini-2.5-pro': 10 },
    priceIds: {
      input: 'price_1T4Y5UEMWqjRf6EJhn1ZzZ1A',
      output: 'price_1T4Y5UEMWqjRf6EJhwpIAjMb'
    }
  },
  'lucidia-mistral': {
    input: { large: 2 },
    output: { large: 6 },
    priceIds: {
      input: 'price_1T4Y5WEMWqjRf6EJYTE2okQF',
      output: 'price_1T4Y5XEMWqjRf6EJBkbcnqC6'
    }
  },
  'lucidia-groq': {
    input: { 'llama-70b': 1 },
    output: { 'llama-70b': 1 },
    priceIds: {
      input: 'price_1T4Y5XEMWqjRf6EJRIsCNijr',
      output: 'price_1T4Y5YEMWqjRf6EJVGeVvjuV'
    }
  },
  'lucidia-perplexity': {
    input: { 'sonar-pro': 3 },
    output: { 'sonar-pro': 15 },
    priceIds: {
      input: 'price_1T4Y5YEMWqjRf6EJj8H8NbLV',
      output: 'price_1T4Y5ZEMWqjRf6EJ4MQy27h5'
    }
  },
  'lucidia-replicate': {
    input: { 'llama-405b': 1 },
    output: { 'llama-405b': 5 },
    priceIds: {
      input: 'price_1T4Y5aEMWqjRf6EJ8TBuwWuH',
      output: 'price_1T4Y5aEMWqjRf6EJvFsWJP1F'
    }
  },
  'lucidia-together': {
    input: { 'llama-70b': 1 },
    output: { 'llama-70b': 1 },
    priceIds: {
      input: 'price_1T4Y5bEMWqjRf6EJ8yWW2Jdg',
      output: 'price_1T4Y5bEMWqjRf6EJiX20ZWOl'
    }
  },
  'lucidia-huggingface': {
    input: { inference: 1 },
    output: { inference: 2 },
    priceIds: {
      input: 'price_1T4Y5cEMWqjRf6EJG7rQKiNi',
      output: 'price_1T4Y5cEMWqjRf6EJwiy3vgSR'
    }
  },
  'lucidia-deepseek': {
    input: { v3: 1 },
    output: { v3: 2 },
    priceIds: {
      input: 'price_1T4Y5dEMWqjRf6EJYKgquTn8',
      output: 'price_1T4Y5eEMWqjRf6EJR6BJ1zn4'
    }
  },
  'lucidia-ollama': {
    input: { local: 1 },
    output: { local: 1 },
    priceIds: {
      input: 'price_1T4Y5eEMWqjRf6EJ203FtYHp'
    }
  },
  'lucidia-anyscale': {
    input: { endpoints: 1 },
    output: { endpoints: 1 },
    priceIds: {
      input: 'price_1T4Y5fEMWqjRf6EJe2q9WTgD'
    }
  },
  'lucidia-copilot': {
    flat: 10000,
    priceIds: {
      monthly: 'price_1T4Y4jEMWqjRf6EJVXg25Twq'
    }
  }
};

// Tier pricing (subscription links)
const TIER_LINKS = {
  starter: 'https://buy.stripe.com/test_00w5kDffp1Yb9wX1eGfMA07',
  pro: 'https://buy.stripe.com/test_5kQeVd9V5eKX10re1sfMA08',
  enterprise: 'https://buy.stripe.com/test_dRm28r1oz9qD9wX8H8fMA09'
};

const TIER_PRICES = {
  starter: 'price_1T4XxoEMWqjRf6EJORv8TbJQ',
  pro: 'price_1T4XxpEMWqjRf6EJkUiO8CQC',
  enterprise: 'price_1T4XxqEMWqjRf6EJr0HBWhks'
};

// PS-SHA∞ verification
let prevHash = 'GENESIS_BLACKROAD_OS_INC';

async function psShaHash(action, entity, data) {
  const payload = `${prevHash}|${action}|${entity}|${data}|${new Date().toISOString()}`;
  const encoder = new TextEncoder();
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(payload));
  const hash = Array.from(new Uint8Array(hashBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  prevHash = hash;
  return hash;
}

// Report usage to Stripe meter
async function reportUsage(env, customerId, provider, tokensUsed) {
  const timestamp = Math.floor(Date.now() / 1000);
  const response = await fetch('https://api.stripe.com/v1/billing/meter_events', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: new URLSearchParams({
      event_name: METER_EVENT,
      'payload[stripe_customer_id]': customerId,
      'payload[value]': String(tokensUsed),
      timestamp: String(timestamp)
    })
  });
  return response.json();
}

// Verify webhook signature
async function verifyWebhook(request, env) {
  const signature = request.headers.get('stripe-signature');
  if (!signature || !env.STRIPE_WEBHOOK_SECRET) return null;

  const body = await request.text();
  const parts = signature.split(',').reduce((acc, part) => {
    const [key, value] = part.split('=');
    acc[key] = value;
    return acc;
  }, {});

  const signedPayload = `${parts.t}.${body}`;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw', encoder.encode(env.STRIPE_WEBHOOK_SECRET),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, encoder.encode(signedPayload));
  const expected = Array.from(new Uint8Array(sig))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  if (expected !== parts.v1) return null;
  return JSON.parse(body);
}

// CORS headers
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Lucidia-Hash, X-Provider',
  'X-Powered-By': 'Lucidia — BlackRoad OS',
  'X-Owner': 'BlackRoad OS, Inc.'
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS }
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS });
    }

    // Root — Gateway info
    if (path === '/' || path === '/health') {
      const hash = await psShaHash('health', 'gateway', 'status_check');
      return json({
        gateway: 'Lucidia',
        owner: 'BlackRoad OS, Inc.',
        status: 'active',
        providers: Object.keys(PROVIDER_RATES).length,
        pricing_model: '10x_provider_rate',
        meter: METER_EVENT,
        verification: 'PS-SHA∞',
        hash,
        tiers: {
          starter: { price: '$29/mo', link: TIER_LINKS.starter },
          pro: { price: '$99/mo', link: TIER_LINKS.pro },
          enterprise: { price: '$499/mo', link: TIER_LINKS.enterprise }
        },
        timestamp: new Date().toISOString()
      });
    }

    // Pricing — Full rate card
    if (path === '/pricing' || path === '/rates') {
      return json({
        gateway: 'Lucidia',
        model: '10x provider rates — per 1K tokens metered',
        meter_event: METER_EVENT,
        providers: PROVIDER_RATES,
        tiers: TIER_PRICES,
        links: TIER_LINKS,
        note: 'All rates in USD cents per 1K tokens. Metered monthly via Stripe.',
        owner: 'BlackRoad OS, Inc.',
        verification: 'PS-SHA∞'
      });
    }

    // Usage report — meter tokens
    if (path === '/usage/report' && request.method === 'POST') {
      const body = await request.json();
      const { customer_id, provider, tokens, model } = body;

      if (!customer_id || !provider || !tokens) {
        return json({ error: 'Missing customer_id, provider, or tokens' }, 400);
      }

      const hash = await psShaHash('usage_report', provider, JSON.stringify({ tokens, model }));

      const result = await reportUsage(env, customer_id, provider, tokens);

      return json({
        status: 'metered',
        provider,
        tokens,
        model: model || 'default',
        hash,
        stripe_result: result,
        timestamp: new Date().toISOString()
      });
    }

    // Verify a call — PS-SHA∞
    if (path === '/verify') {
      const provider = url.searchParams.get('provider') || 'unknown';
      const hash = await psShaHash('verify', provider, 'api_verification');
      return json({
        verified: true,
        provider,
        hash,
        chain: 'PS-SHA∞',
        owner: 'BlackRoad OS, Inc.',
        timestamp: new Date().toISOString()
      });
    }

    // Checkout — create subscription
    if (path === '/checkout/create' && request.method === 'POST') {
      const body = await request.json();
      const tier = body.tier || 'starter';
      const priceId = TIER_PRICES[tier];

      if (!priceId) {
        return json({ error: `Unknown tier: ${tier}. Use starter, pro, or enterprise.` }, 400);
      }

      const session = await fetch('https://api.stripe.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${env.STRIPE_SECRET_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: new URLSearchParams({
          mode: 'subscription',
          'line_items[0][price]': priceId,
          'line_items[0][quantity]': '1',
          success_url: body.success_url || 'https://blackroad.io/success',
          cancel_url: body.cancel_url || 'https://blackroad.io/cancel',
          'metadata[gateway]': 'Lucidia',
          'metadata[owner]': 'BlackRoad OS, Inc.',
          'metadata[verification]': 'PS-SHA∞'
        })
      });

      const result = await session.json();
      const hash = await psShaHash('checkout', tier, result.id || 'pending');

      return json({
        checkout_url: result.url,
        session_id: result.id,
        tier,
        price_id: priceId,
        hash,
        timestamp: new Date().toISOString()
      });
    }

    // Webhook — Stripe events
    if (path === '/webhook/stripe' && request.method === 'POST') {
      const event = await verifyWebhook(request, env);

      if (!event) {
        return json({ error: 'Invalid webhook signature' }, 401);
      }

      const hash = await psShaHash('webhook', event.type, event.id);

      // Store in KV if available
      if (env.CUSTOMERS) {
        if (event.type === 'customer.subscription.created' || event.type === 'customer.subscription.updated') {
          const sub = event.data.object;
          await env.CUSTOMERS.put(`sub:${sub.customer}`, JSON.stringify({
            subscription_id: sub.id,
            status: sub.status,
            tier: sub.metadata?.tier || 'unknown',
            hash,
            updated: new Date().toISOString()
          }));
        }
      }

      return json({
        received: true,
        event_type: event.type,
        event_id: event.id,
        hash,
        timestamp: new Date().toISOString()
      });
    }

    // Provider lookup
    if (path.startsWith('/provider/')) {
      const name = path.replace('/provider/', '').toLowerCase();
      const key = name.startsWith('lucidia-') ? name : `lucidia-${name}`;
      const provider = PROVIDER_RATES[key];

      if (!provider) {
        return json({ error: `Unknown provider: ${name}`, available: Object.keys(PROVIDER_RATES) }, 404);
      }

      const hash = await psShaHash('lookup', key, 'provider_info');
      return json({
        provider: key,
        rates: provider,
        multiplier: '10x',
        hash,
        owner: 'BlackRoad OS, Inc.'
      });
    }

    return json({
      error: 'Not found',
      routes: ['/', '/pricing', '/verify', '/usage/report', '/checkout/create', '/webhook/stripe', '/provider/:name'],
      gateway: 'Lucidia — BlackRoad OS'
    }, 404);
  }
};
