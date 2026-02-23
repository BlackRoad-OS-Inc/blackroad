'use strict'

// Ollama provider — routes to local Pi fleet first ($0 cost)
// Primary: octavia Pi bridge  http://192.168.4.38:4010
// Secondary: local Ollama     http://127.0.0.1:11434
// Env override: BLACKROAD_OLLAMA_URL

const PI_BRIDGE_URL = 'http://192.168.4.38:4010'
const LOCAL_OLLAMA_URL = 'http://127.0.0.1:11434'
const DEFAULT_BASE_URL = PI_BRIDGE_URL
const DEFAULT_MODEL = 'qwen2.5:3b'

function buildPrompt(system, input) {
  if (system && system.trim()) {
    return `${system}\n\n${input}`
  }
  return input
}

async function invoke({ input, system }) {
  if (typeof fetch !== 'function') {
    throw new Error('Global fetch is not available')
  }

  const requestedUrl = process.env.BLACKROAD_OLLAMA_URL || DEFAULT_BASE_URL
  const model = process.env.BLACKROAD_OLLAMA_MODEL || DEFAULT_MODEL
  const prompt = buildPrompt(system, input)

  // Try Pi bridge first, fall back to local Ollama — both $0 cost
  const urlsToTry = requestedUrl !== LOCAL_OLLAMA_URL
    ? [requestedUrl, LOCAL_OLLAMA_URL]
    : [requestedUrl]

  let lastError = null
  for (const baseUrl of urlsToTry) {
    try {
      const response = await fetch(`${baseUrl}/api/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, prompt, stream: false }),
        signal: AbortSignal.timeout ? AbortSignal.timeout(30000) : undefined
      })

      const data = await response.json().catch(() => ({}))
      if (!response.ok) {
        throw new Error(data.error || `Ollama error ${response.status}`)
      }

      if (typeof data.response === 'string') return data.response
      if (data.message && typeof data.message.content === 'string') return data.message.content
      return ''
    } catch (err) {
      lastError = err
      // Try next URL
    }
  }

  throw lastError || new Error('Ollama unreachable on all endpoints')
}

module.exports = {
  invoke
}
