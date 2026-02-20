'use strict'

const DEFAULT_BASE_URL = 'http://127.0.0.1:11434'
const DEFAULT_MODEL = 'llama3.1'

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

  const baseUrl = process.env.BLACKROAD_OLLAMA_URL || DEFAULT_BASE_URL
  const model = process.env.BLACKROAD_OLLAMA_MODEL || DEFAULT_MODEL
  const prompt = buildPrompt(system, input)

  const response = await fetch(`${baseUrl}/api/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model,
      prompt,
      stream: false
    })
  })

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new Error(data.error || `Ollama error ${response.status}`)
  }

  if (typeof data.response === 'string') {
    return data.response
  }

  if (data.message && typeof data.message.content === 'string') {
    return data.message.content
  }

  return ''
}

module.exports = {
  invoke
}
