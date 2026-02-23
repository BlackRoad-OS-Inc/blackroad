import { NextResponse } from 'next/server';
import { createHmac, randomBytes } from 'crypto';

const MASTER_KEY = process.env.BRAT_MASTER_KEY || 'dev-insecure-key-change-in-production';
const INSTANCE_ID = process.env.BRAT_INSTANCE || 'blackroad-os-web';

// Simple credential store — in production, this hits a real DB / Cloudflare KV
const VALID_EMAILS = new Set([
  'alexa@blackroad.io',
  'lucidia@blackroad.io',
  'alice@blackroad.io',
  'octavia@blackroad.io',
  'aria@blackroad.io',
  'shellfish@blackroad.io',
  'cipher@blackroad.io',
  'cecilia@blackroad.io',
]);

function roleFor(email: string): string {
  if (email === 'alexa@blackroad.io') return 'owner';
  if (email.endsWith('@blackroad.io')) return 'coordinator';
  return 'member';
}

function scopeFor(role: string): string[] {
  if (role === 'owner') return ['*'];
  if (role === 'coordinator') return ['mesh:*', 'agents:read', 'workers:read', 'api:read'];
  return ['mesh:read', 'agents:read'];
}

function mintBRAT(sub: string, role: string): string {
  const now = Math.floor(Date.now() / 1000);
  const jti = randomBytes(4).toString('hex');

  const payload = {
    v: 1,
    iss: INSTANCE_ID,
    sub,
    iat: now,
    exp: now + 86400 * 30, // 30 days
    jti,
    role,
    scope: scopeFor(role),
  };

  const encoded = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = createHmac('sha256', MASTER_KEY).update(`BRAT_v1.${encoded}`).digest('base64url');

  return `BRAT_v1.${encoded}.${sig}`;
}

export async function POST(req: Request) {
  try {
    const { email, password, name } = await req.json();

    if (!email || typeof email !== 'string') {
      return NextResponse.json({ error: 'Email required' }, { status: 400 });
    }

    // In dev/demo mode, accept any @blackroad.io email or allow
    // known emails without password check (since we have no real DB yet)
    const isBlackRoadEmail = email.endsWith('@blackroad.io');
    const isKnownEmail = VALID_EMAILS.has(email.toLowerCase());

    // For now: accept any @blackroad.io address OR any email in dev
    // TODO: Replace with real credential check against KV / DB
    const isDev = process.env.NODE_ENV === 'development' || !process.env.BRAT_MASTER_KEY;

    if (!isBlackRoadEmail && !isDev) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const role = roleFor(email.toLowerCase());
    const token = mintBRAT(email.toLowerCase(), role);

    const user = {
      id: email.toLowerCase().replace('@', '_').replace('.', '_'),
      email: email.toLowerCase(),
      name: name || email.split('@')[0].charAt(0).toUpperCase() + email.split('@')[0].slice(1),
      workspaceId: 'blackroad-default',
      role: role === 'owner' ? 'admin' : 'member' as 'admin' | 'member',
    };

    return NextResponse.json({ token, user });
  } catch (err) {
    return NextResponse.json({ error: 'Auth failed' }, { status: 500 });
  }
}
