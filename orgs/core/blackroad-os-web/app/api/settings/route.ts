import { NextResponse } from 'next/server'
import { readFileSync, writeFileSync, mkdirSync } from 'fs'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const SETTINGS_PATH = '/Users/alexa/.blackroad/settings.json'

const DEFAULTS = {
  gatewayUrl: 'http://127.0.0.1:8787',
  ollamaUrl: 'http://localhost:11434',
  piNodes: [
    { name: 'aria64', ip: '192.168.4.38', role: 'primary', capacity: 22500 },
    { name: 'blackroad-pi', ip: '192.168.4.64', role: 'secondary', capacity: 7500 },
    { name: 'alice', ip: '192.168.4.49', role: 'mesh', capacity: 5000 },
    { name: 'cecilia', ip: '192.168.4.89', role: 'ai', capacity: 5000 },
  ],
  tunnelId: '8ae67ab0-71fb-4461-befc-a91302369a7e',
  brand: { primary: '#FF1D6C', secondary: '#2979FF', accent: '#F5A623' },
}

function load() {
  try { return { ...DEFAULTS, ...JSON.parse(readFileSync(SETTINGS_PATH, 'utf8')) } }
  catch { return DEFAULTS }
}

export async function GET() {
  const settings = load()
  // Mask secrets
  const safe = { ...settings, cloudflareToken: settings.cloudflareToken ? '***' : '', vercelToken: settings.vercelToken ? '***' : '' }
  return NextResponse.json(safe)
}

export async function POST(req: Request) {
  const updates = await req.json()
  const current = load()
  const merged = { ...current, ...updates, updatedAt: new Date().toISOString() }
  try {
    mkdirSync('/Users/alexa/.blackroad', { recursive: true })
    writeFileSync(SETTINGS_PATH, JSON.stringify(merged, null, 2))
    return NextResponse.json({ ok: true, saved: Object.keys(updates) })
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 })
  }
}
