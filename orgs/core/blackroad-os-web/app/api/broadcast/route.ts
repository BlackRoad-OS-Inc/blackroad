import { NextResponse } from 'next/server'
import { writeFileSync, mkdirSync, readdirSync } from 'fs'
import { join } from 'path'
import { createHash } from 'crypto'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const SHARED = '/Users/alexa/blackroad/shared'

function getAgents(): string[] {
  try {
    return readdirSync(join(SHARED, 'inbox'))
  } catch {
    return ['claude', 'claude-sonnet', 'codex', 'copilot-2', 'copilot-3', 'lucidia', 'ollama-local']
  }
}

export async function POST(req: Request) {
  const body = await req.json()
  const { to = 'all', subject = 'Message from BlackRoad Web', message } = body

  if (!message) return NextResponse.json({ error: 'message required' }, { status: 400 })

  const ts = Date.now()
  const id = `web-${ts}`
  const hash = createHash('sha256').update(`${id}|${message}|${ts}`).digest('hex').slice(0, 16)

  const payload = {
    protocol: to === 'all' ? 'BRAT-RELAY-v1' : 'BRAT-DM-v1',
    id,
    hash,
    from: 'BLACKROAD_WEB',
    to,
    subject,
    message,
    timestamp: new Date().toISOString(),
    source: 'web-ui',
  }

  const recipients = to === 'all' ? getAgents() : [to]
  const delivered: string[] = []

  for (const agent of recipients) {
    try {
      const dir = join(SHARED, 'inbox', agent)
      mkdirSync(dir, { recursive: true })
      writeFileSync(join(dir, `msg-web-${ts}-${hash}.json`), JSON.stringify(payload, null, 2))
      delivered.push(agent)
    } catch {}
  }

  // Also drop in mesh queue for broadcast
  if (to === 'all') {
    try {
      const dir = join(SHARED, 'mesh', 'queue')
      mkdirSync(dir, { recursive: true })
      writeFileSync(join(dir, `relay-${ts}-web.json`), JSON.stringify(payload, null, 2))
    } catch {}
  }

  return NextResponse.json({ ok: true, id, hash, delivered, count: delivered.length })
}

export async function GET() {
  const agents = getAgents()
  let counts: Record<string, number> = {}
  for (const agent of agents) {
    try {
      const files = readdirSync(join(SHARED, 'inbox', agent))
      counts[agent] = files.filter(f => f.endsWith('.json')).length
    } catch { counts[agent] = 0 }
  }
  return NextResponse.json({ agents, counts, total: Object.values(counts).reduce((a, b) => a + b, 0) })
}
