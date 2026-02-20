'use strict'

const DEFAULT_MODEL = 'gemini-2.0-flash'

async function invoke({ input, system }) {
  if (typeof fetch !== 'function') {
    throw new Error('Global fetch is not available')
  }

  const apiKey = process.env.BLACKROAD_GEMINI_API_KEY
  if (!apiKey) {
    throw new Error('Missing BLACKROAD_GEMINI_API_KEY')
  }

  const model = process.env.BLACKROAD_GEMINI_MODEL || DEFAULT_MODEL
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`

  const contents = []

  if (system && system.trim()) {
    contents.push({
      role: 'user',
      parts: [{ text: `[System Instructions]\n${system}\n\n[User Request]\n${input}` }]
    })
  } else {
    contents.push({
      role: 'user',
      parts: [{ text: input }]
    })
  }

  const body = {
    contents,
    generationConfig: {
      maxOutputTokens: process.env.BLACKROAD_GEMINI_MAX_TOKENS
        ? Number(process.env.BLACKROAD_GEMINI_MAX_TOKENS)
        : 2048
    }
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  })

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    const msg = data.error?.message || `Gemini error ${response.status}`
    throw new Error(msg)
  }

  const candidate = data.candidates?.[0]
  if (candidate?.content?.parts) {
    const textPart = candidate.content.parts.find((p) => typeof p.text === 'string')
    if (textPart) {
      return textPart.text
    }
  }

  return ''
}

module.exports = {
  invoke
}
