// stripe-webhook-router — Routes payment events to Raspberry Pis
// Receives forwarded Stripe events from roadgateway and fans out to Pi fleet.
// BlackRoad OS, Inc. © 2026 — All Rights Reserved

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

async function verifySignature(payload, signature, secret) {
  if (!signature || !secret) return false;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(payload));
  const expected = Array.from(new Uint8Array(sig))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  return expected === signature;
}

async function forwardToPi(url, payload, headers) {
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      body: payload,
    });
    return { url, status: res.status, ok: res.ok };
  } catch (err) {
    return { url, status: 0, ok: false, error: err.message };
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/health') {
      return json({
        status: 'ok',
        worker: 'stripe-webhook-router',
        targets: {
          primary: !!env.PI_PRIMARY_URL,
          secondary: !!env.PI_SECONDARY_URL,
        },
        ts: Date.now(),
      });
    }

    if (request.method !== 'POST') {
      return json({ error: 'POST only' }, 405);
    }

    const payload = await request.text();
    const sig = request.headers.get('X-Roadgateway-Signature');
    const eventType = request.headers.get('X-Roadgateway-Event') || 'unknown';

    // Verify origin is roadgateway
    if (env.ROADGATEWAY_SECRET) {
      const valid = await verifySignature(payload, sig, env.ROADGATEWAY_SECRET);
      if (!valid) {
        return json({ error: 'Invalid signature' }, 401);
      }
    }

    console.log(`[webhook-router] Routing ${eventType} to Pi fleet`);

    // Fan out to all configured Pis
    const targets = [];
    const fwdHeaders = {
      'X-Stripe-Event': eventType,
      'X-Router-Timestamp': new Date().toISOString(),
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
      fwdHeaders['X-Pi-Signature'] = Array.from(new Uint8Array(sigBytes))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
    }

    if (env.PI_PRIMARY_URL) {
      targets.push(forwardToPi(env.PI_PRIMARY_URL, payload, fwdHeaders));
    }
    if (env.PI_SECONDARY_URL) {
      targets.push(forwardToPi(env.PI_SECONDARY_URL, payload, fwdHeaders));
    }

    const results = await Promise.allSettled(targets);
    const deliveries = results.map(r => r.status === 'fulfilled' ? r.value : { error: r.reason?.message });

    return json({
      received: true,
      event: eventType,
      deliveries,
      ts: Date.now(),
    });
  },
};
