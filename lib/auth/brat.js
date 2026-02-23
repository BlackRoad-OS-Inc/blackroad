/**
 * BRAT — BlackRoad Auth Token  v1
 * ─────────────────────────────────────────────────────────────────────────────
 * Format:  BRAT_v1.<payload_b64url>.<hmac_sha256_b64url>
 *
 * Payload (JSON):
 *   v      int     protocol version = 1
 *   iss    string  issuer instance-id  (e.g. "copilot-cli")
 *   sub    string  subject identity    (e.g. "alexa@blackroad")
 *   iat    int     issued-at  (unix seconds)
 *   exp    int     expires-at (unix seconds)
 *   jti    string  unique token id     (8 hex chars)
 *   role   string  trust level: "owner" | "coordinator" | "agent" | "guest"
 *   scope  array   permitted ops:  ["mesh:*", "agents:read", "workers:write"]
 *   chain  string  (optional) PS-SHA∞ journal hash at mint time
 *
 * Trust hierarchy (implicit scopes):
 *   owner        →  ["*"]
 *   coordinator  →  ["mesh:*","agents:read","workers:read","api:read"]
 *   agent        →  ["mesh:read","agents:read"]
 *   guest        →  ["api:read"]
 *
 * Signing:  HMAC-SHA256( "BRAT_v1." + payload_b64url, master_key_bytes )
 * Keys are 32-byte (256-bit) random values stored as hex strings.
 */

const HEADER = 'BRAT_v1';
const VERSION = 1;

// Default TTLs (seconds)
const TTL = {
  owner: 86400,        // 24h
  coordinator: 14400,  // 4h
  agent: 3600,         // 1h
  guest: 900,          // 15m
};

const IMPLICIT_SCOPES = {
  owner:       ['*'],
  coordinator: ['mesh:*', 'agents:read', 'workers:read', 'api:read'],
  agent:       ['mesh:read', 'agents:read'],
  guest:       ['api:read'],
};

// ─── Crypto helpers (Node.js) ─────────────────────────────────────────────────
function _hmac(key, msg) {
  const { createHmac } = require('crypto');
  return createHmac('sha256', Buffer.from(key, 'hex')).update(msg).digest();
}

function _b64enc(buf) {
  return (Buffer.isBuffer(buf) ? buf : Buffer.from(buf))
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function _b64dec(str) {
  const padded = str + '='.repeat((4 - str.length % 4) % 4);
  return Buffer.from(padded.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

function _randHex(bytes = 8) {
  return require('crypto').randomBytes(bytes).toString('hex');
}

function _timingSafeEqual(a, b) {
  const { timingSafeEqual } = require('crypto');
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

// ─── Crypto helpers (Cloudflare Workers / Web Crypto) ─────────────────────────
async function _hmacCF(keyHex, msg) {
  const keyBytes = hexToBytes(keyHex);
  const cryptoKey = await crypto.subtle.importKey(
    'raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', cryptoKey, new TextEncoder().encode(msg));
  return new Uint8Array(sig);
}

async function _verifyCF(keyHex, msg, sigBytes) {
  const keyBytes = hexToBytes(keyHex);
  const cryptoKey = await crypto.subtle.importKey(
    'raw', keyBytes, { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']
  );
  const sigB64 = _b64enc(sigBytes);
  const expected = _b64enc(new Uint8Array(await crypto.subtle.sign(
    'HMAC', cryptoKey, new TextEncoder().encode(msg)
  )));
  return sigB64 === expected;
}

function hexToBytes(hex) {
  const arr = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) arr[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  return arr;
}

// ─── BRAT core ────────────────────────────────────────────────────────────────

/**
 * Mint a new BRAT token (Node.js).
 * @param {string} masterKeyHex  32-byte key as hex
 * @param {object} opts
 * @param {string} opts.sub      subject identity
 * @param {string} opts.iss      issuer instance id
 * @param {string} [opts.role]   "owner"|"coordinator"|"agent"|"guest"
 * @param {string[]} [opts.scope] explicit scopes (defaults to role implicit)
 * @param {number} [opts.ttl]    seconds until expiry
 * @param {string} [opts.chain]  current PS-SHA∞ journal hash
 * @returns {string}  BRAT_v1.<payload>.<sig>
 */
function mint(masterKeyHex, opts = {}) {
  const role = opts.role || 'agent';
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    v: VERSION,
    iss: opts.iss || 'blackroad',
    sub: opts.sub || 'unknown',
    iat: now,
    exp: now + (opts.ttl || TTL[role] || 3600),
    jti: _randHex(8),
    role,
    scope: opts.scope || IMPLICIT_SCOPES[role] || ['api:read'],
    ...(opts.chain && { chain: opts.chain }),
  };
  const payloadB64 = _b64enc(JSON.stringify(payload));
  const msg = `${HEADER}.${payloadB64}`;
  const sig = _hmac(masterKeyHex, msg);
  return `${msg}.${_b64enc(sig)}`;
}

/**
 * Verify and decode a BRAT token (Node.js).
 * @param {string} masterKeyHex
 * @param {string} token
 * @returns {{ ok: boolean, payload?: object, error?: string }}
 */
function verify(masterKeyHex, token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return { ok: false, error: 'malformed token' };
    const [header, payloadB64, sigB64] = parts;
    if (header !== HEADER) return { ok: false, error: 'invalid header' };

    // Verify signature (timing-safe)
    const msg = `${header}.${payloadB64}`;
    const expected = _hmac(masterKeyHex, msg);
    const actual = _b64dec(sigB64);
    if (!_timingSafeEqual(expected, actual)) return { ok: false, error: 'invalid signature' };

    // Decode payload
    const payload = JSON.parse(_b64dec(payloadB64).toString('utf8'));

    // Check expiry
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) return { ok: false, error: 'token expired', payload };

    return { ok: true, payload };
  } catch (e) {
    return { ok: false, error: `parse error: ${e.message}` };
  }
}

/**
 * Verify a BRAT token (Cloudflare Worker / async Web Crypto).
 */
async function verifyAsync(masterKeyHex, token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return { ok: false, error: 'malformed token' };
    const [header, payloadB64, sigB64] = parts;
    if (header !== HEADER) return { ok: false, error: 'invalid header' };

    const msg = `${header}.${payloadB64}`;
    const sigBytes = hexToBytes(sigB64.replace(/-/g, '+').replace(/_/g, '/'));
    const valid = await _verifyCF(masterKeyHex, msg, sigBytes);
    if (!valid) return { ok: false, error: 'invalid signature' };

    const payloadJson = atob(payloadB64.replace(/-/g, '+').replace(/_/g, '/'));
    const payload = JSON.parse(payloadJson);
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) return { ok: false, error: 'token expired', payload };

    return { ok: true, payload };
  } catch (e) {
    return { ok: false, error: `parse error: ${e.message}` };
  }
}

/**
 * Check if a token payload has a required scope.
 * Supports wildcards: "mesh:*" matches "mesh:read", "mesh:write", etc.
 */
function hasScope(payload, required) {
  const scopes = payload.scope || [];
  if (scopes.includes('*')) return true;
  if (scopes.includes(required)) return true;
  const [res] = required.split(':');
  return scopes.includes(`${res}:*`);
}

/**
 * Decode without verifying (for inspection only).
 */
function decode(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    return JSON.parse(_b64dec(parts[1]).toString('utf8'));
  } catch { return null; }
}

/**
 * Generate a random 32-byte master key (hex).
 */
function generateKey() {
  return require('crypto').randomBytes(32).toString('hex');
}

module.exports = {
  mint, verify, verifyAsync, decode, hasScope, generateKey,
  HEADER, VERSION, TTL, IMPLICIT_SCOPES,
};
