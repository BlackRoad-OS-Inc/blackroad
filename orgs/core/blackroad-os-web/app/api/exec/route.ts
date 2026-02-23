import { NextResponse } from 'next/server'
import { execSync } from 'child_process'
import { headers } from 'next/headers'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

const ALLOWED_IPS = ['127.0.0.1', '::1', '::ffff:127.0.0.1']
const BLOCKED = ['rm -rf', 'dd if=', 'mkfs', '> /dev/', 'shutdown', 'reboot', 'passwd', 'sudo su']

function isLocalhost(ip: string) {
  return ALLOWED_IPS.some(a => ip.includes(a))
}

export async function POST(req: Request) {
  const headersList = await headers()
  const forwarded = headersList.get('x-forwarded-for') || ''
  const realIp = headersList.get('x-real-ip') || ''
  const host = headersList.get('host') || ''

  // Only allow localhost
  const isLocal = host.startsWith('localhost') || host.startsWith('127.0.0.1') ||
    isLocalhost(forwarded) || isLocalhost(realIp) ||
    process.env.NODE_ENV === 'development'

  if (!isLocal) {
    return NextResponse.json({ error: 'Terminal only available on localhost', allowed: false }, { status: 403 })
  }

  const { command, cwd = '/Users/alexa/blackroad' } = await req.json()
  if (!command) return NextResponse.json({ error: 'No command' }, { status: 400 })

  // Block destructive commands
  const lower = command.toLowerCase()
  for (const block of BLOCKED) {
    if (lower.includes(block)) {
      return NextResponse.json({ error: `Blocked: ${block}`, output: `⛔ Command blocked for safety` }, { status: 200 })
    }
  }

  const startMs = Date.now()
  try {
    const output = execSync(command, {
      cwd,
      encoding: 'utf8',
      timeout: 10000,
      maxBuffer: 1024 * 1024,
      env: { ...process.env, TERM: 'xterm-256color', FORCE_COLOR: '0' },
    })
    return NextResponse.json({
      output: output || '(no output)',
      exitCode: 0,
      duration: Date.now() - startMs,
      cwd,
    })
  } catch (e: any) {
    return NextResponse.json({
      output: e.stdout || e.stderr || e.message || 'Error',
      exitCode: e.status ?? 1,
      duration: Date.now() - startMs,
      cwd,
    })
  }
}

export async function GET() {
  return NextResponse.json({
    available: process.env.NODE_ENV === 'development',
    message: 'Terminal endpoint — POST with { command, cwd }',
  })
}
