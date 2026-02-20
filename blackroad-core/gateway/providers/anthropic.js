'use strict'

const DEFAULT_BASE_URL = 'https://api.anthropic.com/v1'
const DEFAULT_MODEL = 'claude-3-5-sonnet-20240620'
const DEFAULT_MAX_TOKENS = 1024

async function invoke({ input, system }) {
  if (typeof fetch !== 'function') {
    throw new Error('Global fetch is not available')
  }

  const apiKey = process.env.BLACKROAD_ANTHROPIC_API_KEY
  if (!apiKey) {
    throw new Error('Missing BLACKROAD_ANTHROPIC_API_KEY')
  }

  const baseUrl = process.env.BLACKROAD_ANTHROPIC_BASE_URL || DEFAULT_BASE_URL
  const model = process.env.BLACKROAD_ANTHROPIC_MODEL || DEFAULT_MODEL
  const maxTokens = process.env.BLACKROAD_ANTHROPIC_MAX_TOKENS
    ? Number(process.env.BLACKROAD_ANTHROPIC_MAX_TOKENS)
    : DEFAULT_MAX_TOKENS

  const body = {
    model,
    max_tokens: maxTokens,
    messages: [
      {
        role: 'user',
        content: input
      }
    ]
  }

  if (system && system.trim()) {
    body.system = system
  }

  const response = await fetch(`${baseUrl}/messages`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify(body)
  })

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new Error(data.error?.message || `Anthropic error ${response.status}`)
  }

  const content = data.content || []
  const textBlock = content.find((block) => block.type === 'text')
  if (textBlock && typeof textBlock.text === 'string') {
    return textBlock.text
  }

  return ''
}

module.exports = {
  invoke
}
