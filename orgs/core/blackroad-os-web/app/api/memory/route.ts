import { NextResponse } from 'next/server'
import { readFileSync, readdirSync, statSync } from 'fs'
import { join } from 'path'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const LEDGER = '/Users/alexa/.blackroad/memory/ledger/memory-ledger.jsonl'
const CONTEXT_DIR = '/Users/alexa/.blackroad/memory'

function readLedger() {
  try {
    const lines = readFileSync(LEDGER, 'utf8').trim().split('\n').filter(Boolean)
    return lines.map((line, i) => {
      try { return { ...JSON.parse(line), lineNumber: i + 1 } }
      catch { return { raw: line.slice(0, 200), lineNumber: i + 1, parse_error: true } }
    })
  } catch { return [] }
}

function getContextFiles() {
  const files: any[] = []
  for (const dir of ['cece', 'sessions', 'context', 'journals']) {
    try {
      for (const item of readdirSync(join(CONTEXT_DIR, dir)).slice(0, 5)) {
        try {
          const p = join(CONTEXT_DIR, dir, item)
          const stat = statSync(p)
          files.push({ path: `${dir}/${item}`, size: stat.size, modifiedAt: stat.mtime.toISOString(), preview: readFileSync(p, 'utf8').slice(0, 300) })
        } catch {}
      }
    } catch {}
  }
  return files
}

export async function GET(req: Request) {
  const url = new URL(req.url)
  const view = url.searchParams.get('view') || 'ledger'
  const search = url.searchParams.get('search') || ''
  const page = parseInt(url.searchParams.get('page') || '1')
  const limit = 50

  if (view === 'files') return NextResponse.json({ files: getContextFiles() })

  let entries = readLedger().reverse()
  if (search) entries = entries.filter(e => JSON.stringify(e).toLowerCase().includes(search.toLowerCase()))

  const total = entries.length
  return NextResponse.json({
    entries: entries.slice((page - 1) * limit, page * limit),
    total, page,
    pages: Math.ceil(total / limit),
    ledgerPath: LEDGER,
  })
}
