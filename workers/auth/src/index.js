/**
 * BlackRoad Auth Worker — BRAT v1
 *
 * Endpoints:
 *   POST /auth/token   — issue a token (requires BRAT_MASTER_KEY secret)
 *   POST /auth/verify  — verify a token
 *   GET  /auth/me      — decode token from Authorization header
 *   POST /auth/revoke  — revoke by JTI (owner only)
 *   GET  /auth/status  — public health
 *
 * Env secrets required:
 *   BRAT_MASTER_KEY   — 32-byte hex master key
 *   BRAT_ADMIN_KEY    — (optional) separate key for admin ops
 *
 * KV binding:
 *   REVOCATIONS       — stores revoked JTIs  (key: jti, value: reason)
 */

const HEADER = 'BRAT_v1';

function b64enc(bytes) {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function b64dec(str) {
  const padded = str + '='.repeat((4 - str.length % 4) % 4);
  const bin = atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
  return Uint8Array.from(bin, c => c.charCodeAt(0));
}

function hexToBytes(hex) {
  const arr = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) arr[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  return arr;
}

async function hmacSign(keyHex, msg) {
  const key = await crypto.subtle.importKey(
    'raw', hexToBytes(keyHex),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(msg));
  return b64enc(new Uint8Array(sig));
}

async function hmacVerify(keyHex, msg, sigB64) {
  const expected = await hmacSign(keyHex, msg);
  return expected === sigB64;
}

function randHex(bytes = 8) {
  const arr = new Uint8Array(bytes);
  crypto.getRandomValues(arr);
  return Array.from(arr).map(b => b.toString(16).padStart(2, '0')).join('');
}

const IMPLICIT_SCOPES = {
  owner:       ['*'],
  coordinator: ['mesh:*', 'agents:read', 'workers:read', 'api:read'],
  agent:       ['mesh:read', 'agents:read'],
  guest:       ['api:read'],
};

const TTL_DEFAULT = { owner: 86400, coordinator: 14400, agent: 3600, guest: 900 };

function hasScope(payload, required) {
  const scopes = payload.scope || [];
  if (scopes.includes('*')) return true;
  if (scopes.includes(required)) return true;
  const [res] = required.split(':');
  return scopes.includes(`${res}:*`);
}

// ─── Mint ─────────────────────────────────────────────────────────────────────
async function mintToken(env, opts) {
  const role = opts.role || 'agent';
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    v: 1,
    iss: opts.iss || 'blackroad-auth',
    sub: opts.sub || 'unknown',
    iat: now,
    exp: now + (opts.ttl || TTL_DEFAULT[role] || 3600),
    jti: randHex(8),
    role,
    scope: opts.scope || IMPLICIT_SCOPES[role] || ['api:read'],
  };
  const payloadB64 = b64enc(new TextEncoder().encode(JSON.stringify(payload)));
  const msg = `${HEADER}.${payloadB64}`;
  const sig = await hmacSign(env.BRAT_MASTER_KEY, msg);
  return { token: `${msg}.${sig}`, payload };
}

// ─── Verify ───────────────────────────────────────────────────────────────────
async function verifyToken(env, token) {
  const parts = token.trim().split('.');
  if (parts.length !== 3) return { ok: false, error: 'malformed token' };
  const [hdr, payloadB64, sigB64] = parts;
  if (hdr !== HEADER) return { ok: false, error: `invalid header: ${hdr}` };

  const msg = `${hdr}.${payloadB64}`;
  const valid = await hmacVerify(env.BRAT_MASTER_KEY, msg, sigB64);
  if (!valid) return { ok: false, error: 'invalid signature' };

  let payload;
  try {
    payload = JSON.parse(new TextDecoder().decode(b64dec(payloadB64)));
  } catch (e) {
    return { ok: false, error: 'payload decode error' };
  }

  const now = Math.floor(Date.now() / 1000);
  if (payload.exp < now) return { ok: false, error: `token expired ${now - payload.exp}s ago`, payload };

  // Check revocation list
  if (env.REVOCATIONS) {
    const revoked = await env.REVOCATIONS.get(payload.jti);
    if (revoked) return { ok: false, error: 'token revoked', payload };
  }

  return { ok: true, payload };
}

// ─── Extract token from request ───────────────────────────────────────────────
function extractToken(request) {
  const auth = request.headers.get('Authorization') || '';
  if (auth.startsWith('Bearer ')) return auth.slice(7).trim();
  const url = new URL(request.url);
  return url.searchParams.get('token') || '';
}

// ─── Response helpers ─────────────────────────────────────────────────────────
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status, headers: { 'Content-Type': 'application/json', ...CORS },
  });
}

// ─── Route handlers ───────────────────────────────────────────────────────────
async function handleToken(request, env) {
  if (!env.BRAT_MASTER_KEY) return json({ error: 'server not configured' }, 500);
  let body;
  try { body = await request.json(); } catch { return json({ error: 'invalid JSON' }, 400); }

  const { sub, iss, role, ttl, scope } = body;
  if (!sub) return json({ error: 'sub required' }, 400);

  // Require caller to authenticate for elevated roles
  const callerToken = extractToken(request);
  if (role === 'owner' || role === 'coordinator') {
    if (!callerToken) return json({ error: 'coordinator/owner tokens require caller auth' }, 401);
    const callerResult = await verifyToken(env, callerToken);
    if (!callerResult.ok) return json({ error: `caller auth failed: ${callerResult.error}` }, 401);
    if (!hasScope(callerResult.payload, 'auth:issue') && !callerResult.payload.scope?.includes('*')) {
      return json({ error: 'caller lacks auth:issue scope' }, 403);
    }
  }

  const { token, payload } = await mintToken(env, { sub, iss, role, ttl, scope });
  return json({ ok: true, token, payload });
}

async function handleVerify(request, env) {
  if (!env.BRAT_MASTER_KEY) return json({ error: 'server not configured' }, 500);
  let token;
  try {
    const body = await request.json();
    token = body.token;
  } catch { token = null; }
  if (!token) token = extractToken(request);
  if (!token) return json({ error: 'token required (body.token or Authorization: Bearer)' }, 400);

  const result = await verifyToken(env, token);
  return json(result, result.ok ? 200 : 401);
}

async function handleMe(request, env) {
  if (!env.BRAT_MASTER_KEY) return json({ error: 'server not configured' }, 500);
  const token = extractToken(request);
  if (!token) return json({ error: 'no token provided' }, 401);
  const result = await verifyToken(env, token);
  if (!result.ok) return json({ error: result.error }, 401);
  return json({ ok: true, identity: result.payload });
}

async function handleRevoke(request, env) {
  if (!env.BRAT_MASTER_KEY) return json({ error: 'server not configured' }, 500);

  // Must be owner to revoke
  const callerToken = extractToken(request);
  if (!callerToken) return json({ error: 'unauthorized' }, 401);
  const caller = await verifyToken(env, callerToken);
  if (!caller.ok) return json({ error: caller.error }, 401);
  if (caller.payload.role !== 'owner' && !caller.payload.scope?.includes('*')) {
    return json({ error: 'owner role required to revoke' }, 403);
  }

  let body;
  try { body = await request.json(); } catch { return json({ error: 'invalid JSON' }, 400); }
  const { jti, reason } = body;
  if (!jti) return json({ error: 'jti required' }, 400);

  if (env.REVOCATIONS) {
    await env.REVOCATIONS.put(jti, reason || 'manual', { expirationTtl: 2592000 }); // 30 days
  }
  return json({ ok: true, revoked: jti });
}

async function handleStatus(request, env) {
  return json({
    ok: true,
    protocol: 'BRAT v1',
    signing: 'HMAC-SHA256',
    configured: !!env.BRAT_MASTER_KEY,
    endpoints: ['/auth/token', '/auth/verify', '/auth/me', '/auth/revoke', '/auth/status'],
    roles: Object.keys(IMPLICIT_SCOPES),
    ts: new Date().toISOString(),
  });
}

// ─── Main ─────────────────────────────────────────────────────────────────────
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    if (method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });

    if (method === 'POST' && path === '/auth/token')  return handleToken(request, env);
    if (method === 'POST' && path === '/auth/verify') return handleVerify(request, env);
    if (method === 'GET'  && path === '/auth/me')     return handleMe(request, env);
    if (method === 'POST' && path === '/auth/revoke') return handleRevoke(request, env);
    if (method === 'GET'  && path === '/auth/status') return handleStatus(request, env);

    return json({ error: `not found: ${method} ${path}` }, 404);
  },
};
