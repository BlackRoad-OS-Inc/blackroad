import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import { readdirSync, readFileSync, statSync } from 'fs'
import { join } from 'path'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const WORKFLOWS_DIR = '/Users/alexa/blackroad/.github/workflows'
const ROOT = '/Users/alexa/blackroad'

function getWorkflows() {
  try {
    return readdirSync(WORKFLOWS_DIR)
      .filter(f => f.endsWith('.yml') || f.endsWith('.yaml'))
      .map(f => {
        try {
          const content = readFileSync(join(WORKFLOWS_DIR, f), 'utf8')
          const nameMatch = content.match(/^name:\s*(.+)/m)
          const onMatch = content.match(/^on:\s*(.+)/m)
          const stat = statSync(join(WORKFLOWS_DIR, f))
          return { file: f, name: nameMatch?.[1]?.trim() || f, on: onMatch?.[1]?.trim() || 'unknown', size: stat.size, modifiedAt: stat.mtime.toISOString(), content: content.slice(0, 2000) }
        } catch { return { file: f, name: f, on: 'unknown', size: 0, modifiedAt: '', content: '' } }
      })
  } catch { return [] }
}

function getRecentRuns() {
  try {
    const out = execSync('gh run list --limit 15 --json name,status,conclusion,startedAt,updatedAt,url,displayTitle 2>/dev/null', { cwd: ROOT, timeout: 8000, encoding: 'utf8' })
    return JSON.parse(out)
  } catch { return [] }
}

function triggerWorkflow(workflow: string) {
  try {
    return execSync(`gh workflow run "${workflow}" 2>&1`, { cwd: ROOT, timeout: 10000, encoding: 'utf8' })
  } catch (e: any) { return e.stdout || e.stderr || 'Failed' }
}

export async function GET(req: Request) {
  const url = new URL(req.url)
  const action = url.searchParams.get('action') || 'list'

  if (action === 'runs') {
    return NextResponse.json({ runs: getRecentRuns() })
  }
  const workflows = getWorkflows()
  return NextResponse.json({ workflows, count: workflows.length })
}

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}))
  if (body.action === 'trigger' && body.workflow) {
    const output = triggerWorkflow(body.workflow)
    return NextResponse.json({ output, success: !output.toLowerCase().includes('error') })
  }
  return NextResponse.json({ error: 'Invalid action' }, { status: 400 })
}
