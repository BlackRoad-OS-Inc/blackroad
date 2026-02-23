'use strict'

/**
 * DeepSeek provider for BlackRoad Gateway
 * Compatible with OpenAI API format
 */
async function chat({ model, messages, temperature, max_tokens, stream }, env) {
  const baseUrl = env.BLACKROAD_DEEPSEEK_URL || 'https://api.deepseek.com'
  const apiKey = env.BLACKROAD_DEEPSEEK_API_KEY
  if (!apiKey) throw new Error('BLACKROAD_DEEPSEEK_API_KEY not set')

  const resp = await fetch(`${baseUrl}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model: model || 'deepseek-chat',
      messages,
      temperature: temperature ?? 0.7,
      max_tokens: max_tokens || 4096,
      stream: stream || false
    })
  })

  if (!resp.ok) {
    const err = await resp.text()
    throw new Error(`DeepSeek error ${resp.status}: ${err}`)
  }
  const data = await resp.json()
  return data.choices?.[0]?.message?.content ?? ''
}

async function complete({ model, prompt, temperature, max_tokens }, env) {
  return chat({
    model,
    messages: [{ role: 'user', content: prompt }],
    temperature,
    max_tokens
  }, env)
}

module.exports = { chat, complete }
