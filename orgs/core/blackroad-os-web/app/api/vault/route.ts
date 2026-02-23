import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import { readdirSync, readFileSync, statSync } from 'fs'
import { join } from 'path'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const VAULT_DIR = '/Users/alexa/.blackroad/vault'

function listSecrets() {
  try {
    const files = readdirSync(VAULT_DIR).filter(f => !f.startsWith('.') && !f.endsWith('.key'))
    return files.map(f => {
      try {
        const p = join(VAULT_DIR, f)
        const stat = statSync(p)
        return { name: f, size: stat.size, modifiedAt: stat.mtime.toISOString(), isDir: stat.isDirectory() }
      } catch { return { name: f, size: 0, modifiedAt: '', isDir: false } }
    })
  } catch { return [] }
}

function runVault(args: string) {
  try {
    return execSync(`cd /Users/alexa/blackroad && br vault ${args} 2>&1`, { timeout: 10000, encoding: 'utf8' })
  } catch (e: any) { return e.stdout || e.stderr || 'Command failed' }
}

export async function GET(req: Request) {
  const url = new URL(req.url)
  const action = url.searchParams.get('action') || 'list'

  if (action === 'list') {
    const secrets = listSecrets()
    const vaultExists = (() => { try { statSync(VAULT_DIR); return true } catch { return false } })()
    return NextResponse.json({ secrets, vaultExists, vaultDir: VAULT_DIR })
  }

  if (action === 'status') {
    const output = runVault('status')
    return NextResponse.json({ output })
  }

  return NextResponse.json({ error: 'Unknown action' }, { status: 400 })
}

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}))
  const { action, name, value, category } = body

  if (action === 'add' && name && value) {
    const output = runVault(`add "${name}" "${value}" ${category || 'general'}`)
    return NextResponse.json({ output, success: !output.toLowerCase().includes('error') })
  }

  if (action === 'get' && name) {
    const output = runVault(`get "${name}"`)
    return NextResponse.json({ output })
  }

  if (action === 'delete' && name) {
    const output = runVault(`delete "${name}"`)
    return NextResponse.json({ output, success: !output.toLowerCase().includes('error') })
  }

  return NextResponse.json({ error: 'Invalid action' }, { status: 400 })
}
