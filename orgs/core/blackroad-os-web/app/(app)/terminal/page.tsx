'use client'
import { useEffect, useRef, useState } from 'react'
import { Terminal, ChevronRight, AlertTriangle } from 'lucide-react'

interface HistoryEntry { command: string; output: string; exitCode: number; duration: number; cwd: string; ts: string }

const PROMPT_COLOR = '#22c55e'
const BANNER = `BlackRoad OS Terminal — localhost only
Type 'help' for available commands, 'clear' to clear screen.
`

const BUILT_INS: Record<string, () => string> = {
  help: () => `Available commands:
  git status / log / diff     — git operations
  br <cmd>                    — BlackRoad CLI
  ls / cat / head / tail      — file ops
  curl http://localhost:...   — local API calls
  ping <ip>                   — network check
  ps aux | grep <name>        — process search
  clear                       — clear terminal`,
  clear: () => '__CLEAR__',
}

export default function TerminalPage() {
  const [history, setHistory] = useState<HistoryEntry[]>([])
  const [input, setInput] = useState('')
  const [cwd, setCwd] = useState('/Users/alexa/blackroad')
  const [running, setRunning] = useState(false)
  const [cmdHistory, setCmdHistory] = useState<string[]>([])
  const [histIdx, setHistIdx] = useState(-1)
  const [isLocal, setIsLocal] = useState(true)
  const inputRef = useRef<HTMLInputElement>(null)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    // Check if we're on localhost
    if (typeof window !== 'undefined') {
      setIsLocal(window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    }
    fetch('/api/exec').then(r => r.json()).then(d => setIsLocal(d.available)).catch(() => {})
  }, [])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [history])

  const run = async (cmd: string) => {
    if (!cmd.trim()) return
    const trimmed = cmd.trim()

    // Built-ins
    if (BUILT_INS[trimmed]) {
      const out = BUILT_INS[trimmed]()
      if (out === '__CLEAR__') { setHistory([]); setInput(''); return }
      setHistory(h => [...h, { command: trimmed, output: out, exitCode: 0, duration: 0, cwd, ts: new Date().toISOString() }])
      setInput('')
      return
    }

    setCmdHistory(h => [trimmed, ...h.slice(0, 49)])
    setHistIdx(-1)
    setRunning(true)

    try {
      const r = await fetch('/api/exec', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command: trimmed, cwd }),
      })
      const d = await r.json()
      if (d.error && !d.output) {
        setHistory(h => [...h, { command: trimmed, output: `⛔ ${d.error}`, exitCode: 1, duration: 0, cwd, ts: new Date().toISOString() }])
      } else {
        setHistory(h => [...h, { command: trimmed, output: d.output || '', exitCode: d.exitCode ?? 0, duration: d.duration || 0, cwd, ts: new Date().toISOString() }])
        if (trimmed.startsWith('cd ')) {
          const newDir = trimmed.slice(3).trim()
          setCwd(prev => newDir.startsWith('/') ? newDir : `${prev}/${newDir}`)
        }
      }
    } catch {
      setHistory(h => [...h, { command: trimmed, output: 'Connection error — is the dev server running?', exitCode: 1, duration: 0, cwd, ts: new Date().toISOString() }])
    } finally {
      setRunning(false)
      setInput('')
      inputRef.current?.focus()
    }
  }

  const handleKey = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') { run(input); return }
    if (e.key === 'ArrowUp') {
      const idx = Math.min(histIdx + 1, cmdHistory.length - 1)
      setHistIdx(idx)
      setInput(cmdHistory[idx] || '')
    }
    if (e.key === 'ArrowDown') {
      const idx = Math.max(histIdx - 1, -1)
      setHistIdx(idx)
      setInput(idx === -1 ? '' : cmdHistory[idx])
    }
    if (e.key === 'l' && e.ctrlKey) { e.preventDefault(); setHistory([]) }
  }

  const shortCwd = cwd.replace('/Users/alexa', '~')

  if (!isLocal) {
    return (
      <div style={{ padding: 32, maxWidth: 700 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <Terminal size={28} style={{ color: '#22c55e' }} />
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Terminal</h1>
        </div>
        <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 12, padding: 24, display: 'flex', alignItems: 'flex-start', gap: 14 }}>
          <AlertTriangle size={20} style={{ color: '#ef4444', flexShrink: 0, marginTop: 2 }} />
          <div>
            <div style={{ color: '#ef4444', fontWeight: 600, marginBottom: 8 }}>Terminal unavailable on remote deployments</div>
            <div style={{ color: 'rgba(255,255,255,0.5)', fontSize: 13 }}>
              The web terminal only works when running the app locally at <code style={{ fontFamily: 'monospace', color: '#F5A623' }}>localhost:3000</code>.
              <br /><br />
              Use the <code style={{ fontFamily: 'monospace', color: '#22c55e' }}>br</code> CLI for remote operations, or SSH directly to your Pi nodes.
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div style={{ padding: 32, height: 'calc(100vh - 40px)', display: 'flex', flexDirection: 'column', maxWidth: 1000 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20, flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Terminal size={28} style={{ color: '#22c55e' }} />
          <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, color: '#fff', margin: 0 }}>Terminal</h1>
            <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: 13, margin: 0 }}>{shortCwd} · {history.length} commands run</p>
          </div>
        </div>
        <button onClick={() => setHistory([])} style={{ padding: '6px 14px', background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 8, color: '#888', fontSize: 12, cursor: 'pointer' }}>
          Clear
        </button>
      </div>

      <div
        onClick={() => inputRef.current?.focus()}
        style={{ flex: 1, overflowY: 'auto', background: '#0a0a0a', border: '1px solid rgba(255,255,255,0.08)', borderRadius: 12, padding: 16, fontFamily: 'monospace', fontSize: 13, cursor: 'text' }}
      >
        {/* Banner */}
        <div style={{ color: 'rgba(255,255,255,0.3)', marginBottom: 12, whiteSpace: 'pre' }}>{BANNER}</div>

        {/* History */}
        {history.map((entry, i) => (
          <div key={i} style={{ marginBottom: 10 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
              <span style={{ color: PROMPT_COLOR }}>{entry.cwd.replace('/Users/alexa', '~')}</span>
              <ChevronRight size={12} style={{ color: PROMPT_COLOR }} />
              <span style={{ color: '#fff' }}>{entry.command}</span>
              <span style={{ color: 'rgba(255,255,255,0.2)', fontSize: 11, marginLeft: 'auto' }}>{entry.duration}ms</span>
            </div>
            <div style={{ color: entry.exitCode === 0 ? 'rgba(255,255,255,0.7)' : '#ef4444', whiteSpace: 'pre-wrap', wordBreak: 'break-word', paddingLeft: 16 }}>
              {entry.output}
            </div>
          </div>
        ))}

        {/* Current input line */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ color: PROMPT_COLOR }}>{shortCwd}</span>
          <ChevronRight size={12} style={{ color: PROMPT_COLOR }} />
          <input
            ref={inputRef}
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={handleKey}
            disabled={running}
            autoFocus
            style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', color: '#fff', fontFamily: 'monospace', fontSize: 13, caretColor: PROMPT_COLOR }}
            placeholder={running ? 'Running…' : ''}
          />
          {running && <span style={{ color: PROMPT_COLOR, animation: 'pulse 1s infinite' }}>▋</span>}
        </div>
        <div ref={bottomRef} />
      </div>
    </div>
  )
}
