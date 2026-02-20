'use strict'

const DEFAULT_BASE_URL = 'https://api.openai.com/v1'
const DEFAULT_MODEL = 'gpt-4o-mini'

async function invoke({ input, system }) {
  if (typeof fetch !== 'function') {
    throw new Error('Global fetch is not available')
  }

  const apiKey = process.env.BLACKROAD_OPENAI_API_KEY
  if (!apiKey) {
    throw new Error('Missing BLACKROAD_OPENAI_API_KEY')
  }

  const baseUrl = process.env.BLACKROAD_OPENAI_BASE_URL || DEFAULT_BASE_URL
  const model = process.env.BLACKROAD_OPENAI_MODEL || DEFAULT_MODEL

  const messages = []
  if (system && system.trim()) {
    messages.push({ role: 'system', content: system })
  }
  messages.push({ role: 'user', content: input })

  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model,
      messages
    })
  })

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new Error(data.error?.message || `OpenAI error ${response.status}`)
  }

  const message = data.choices?.[0]?.message?.content
  if (typeof message === 'string') {
    return message
  }

  return ''
}

module.exports = {
  invoke
}
