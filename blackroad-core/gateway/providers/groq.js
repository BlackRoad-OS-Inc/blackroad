'use strict'

/**
 * Groq provider for BlackRoad Gateway
 * Ultra-fast inference via Groq Cloud
 */
const GROQ_MODELS = {
  'llama3-8b': 'llama3-8b-8192',
  'llama3-70b': 'llama3-70b-8192',
  'mixtral-8x7b': 'mixtral-8x7b-32768',
  'gemma-7b': 'gemma-7b-it',
  'deepseek-r1': 'deepseek-r1-distill-llama-70b'
}

async function chat({ model, messages, temperature, max_tokens }, env) {
  const apiKey = env.BLACKROAD_GROQ_API_KEY
  if (!apiKey) throw new Error('BLACKROAD_GROQ_API_KEY not set')

  const groqModel = GROQ_MODELS[model] || model || 'llama3-70b-8192'

  const resp = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: groqModel,
      messages,
      temperature: temperature ?? 0.7,
      max_tokens: max_tokens || 4096
    })
  })

  if (!resp.ok) {
    const err = await resp.text()
    throw new Error(`Groq error ${resp.status}: ${err}`)
  }
  const data = await resp.json()
  return data.choices?.[0]?.message?.content ?? ''
}

async function complete({ model, prompt, temperature, max_tokens }, env) {
  return chat({ model, messages: [{ role: 'user', content: prompt }], temperature, max_tokens }, env)
}

module.exports = { chat, complete, GROQ_MODELS }
