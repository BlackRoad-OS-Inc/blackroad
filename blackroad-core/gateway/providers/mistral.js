'use strict'

/**
 * Mistral AI provider for BlackRoad Gateway
 */
const MISTRAL_MODELS = {
  'mistral-tiny': 'mistral-tiny',
  'mistral-small': 'mistral-small-latest',
  'mistral-medium': 'mistral-medium-latest',
  'mistral-large': 'mistral-large-latest',
  'codestral': 'codestral-latest',
  'mixtral-8x7b': 'open-mixtral-8x7b',
  'mixtral-8x22b': 'open-mixtral-8x22b'
}

async function chat({ model, messages, temperature, max_tokens }, env) {
  const apiKey = env.BLACKROAD_MISTRAL_API_KEY
  if (!apiKey) throw new Error('BLACKROAD_MISTRAL_API_KEY not set')

  const mistralModel = MISTRAL_MODELS[model] || model || 'mistral-small-latest'

  const resp = await fetch('https://api.mistral.ai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: mistralModel,
      messages,
      temperature: temperature ?? 0.7,
      max_tokens: max_tokens || 4096
    })
  })

  if (!resp.ok) {
    const err = await resp.text()
    throw new Error(`Mistral error ${resp.status}: ${err}`)
  }
  const data = await resp.json()
  return data.choices?.[0]?.message?.content ?? ''
}

async function complete({ model, prompt, temperature, max_tokens }, env) {
  return chat({ model, messages: [{ role: 'user', content: prompt }], temperature, max_tokens }, env)
}

module.exports = { chat, complete, MISTRAL_MODELS }
