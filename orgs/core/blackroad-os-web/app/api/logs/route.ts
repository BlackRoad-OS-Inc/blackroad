import { NextResponse } from 'next/server'
import { readdirSync, readFileSync, statSync } from 'fs'
import { join } from 'path'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const SHARED = '/Users/alexa/blackroad/shared'
const LEDGER = '/Users/alexa/.blackroad/memory/ledger/memory-ledger.jsonl'

function getAgentMessages() {
  const entries: any[] = []
  try {
    const agents = readdirSync(join(SHARED, 'inbox'))
    for (const agent of agents) {
      const dir = join(SHARED, 'inbox', agent)
      try {
        const files = readdirSync(dir).filter(f => f.endsWith('.json')).slice(-5)
        for (const file of files) {
          try {
            const stat = statSync(join(dir, file))
            const raw = JSON.parse(readFileSync(join(dir, file), 'utf8'))
            entries.push({ type: 'mesh', level: 'info', source: `agent:${agent}`, message: raw.subject || raw.message?.slice(0, 80) || file, timestamp: raw.timestamp || stat.mtime.toISOString(), from: raw.from || 'system' })
          } catch {}
        }
      } catch {}
    }
  } catch {}
  return entries
}

function getMemoryEntries() {
  const entries: any[] = []
  try {
    const lines = readFileSync(LEDGER, 'utf8').trim().split('\n').filter(Boolean)
    for (const line of lines.slice(-20)) {
      try {
        const e = JSON.parse(line)
        entries.push({ type: 'memory', level: 'info', source: 'memory:ledger', message: `[${e.action}] ${e.entity || ''} ${e.details || ''}`.trim(), timestamp: e.timestamp, hash: e.hash?.slice(0, 8) })
      } catch {}
    }
  } catch {}
  return entries
}

function getMeshQueue() {
  const entries: any[] = []
  try {
    const dir = join(SHARED, 'mesh', 'queue')
    const files = readdirSync(dir).filter(f => f.endsWith('.json')).slice(-10)
    for (const file of files) {
      try {
        const raw = JSON.parse(readFileSync(join(dir, file), 'utf8'))
        entries.push({ type: 'broadcast', level: 'info', source: 'mesh:queue', message: `BROADCAST → ${raw.subject || raw.message?.slice(0, 60) || file}`, timestamp: raw.timestamp || new Date().toISOString(), from: raw.from || 'system' })
      } catch {}
    }
  } catch {}
  return entries
}

export async function GET(req: Request) {
  const url = new URL(req.url)
  const filter = url.searchParams.get('filter') || 'all'

  let logs = [...getMemoryEntries(), ...getMeshQueue(), ...getAgentMessages()]
  if (filter !== 'all') logs = logs.filter(l => l.type === filter || l.source.startsWith(filter))
  logs.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())

  return NextResponse.json({ logs: logs.slice(0, 100), total: logs.length, timestamp: new Date().toISOString() })
}
