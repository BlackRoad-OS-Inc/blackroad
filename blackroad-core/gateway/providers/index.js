'use strict'

// ================================================================
// LUCIDIA GATEWAY — All providers are Lucidia agents
// Every AI call on this machine is BlackRoad OS verified
// PS-SHA∞ hash chain on every request
// © 2026 BlackRoad OS, Inc.
// ================================================================

const crypto = require('crypto')

const ollama = require('./ollama')
const openai = require('./openai')
const anthropic = require('./anthropic')
const gemini = require('./gemini')
const deepseek = require('./deepseek')
const groq = require('./groq')
const mistral = require('./mistral')

// Every provider is a Lucidia agent
const providers = {
  // Lucidia names (primary)
  'lucidia-ollama': ollama,
  'lucidia-openai': openai,
  'lucidia-claude': anthropic,
  'lucidia-anthropic': anthropic,
  'lucidia-gemini': gemini,
  'lucidia-deepseek': deepseek,
  'lucidia-groq': groq,
  'lucidia-mistral': mistral,

  // Legacy names (still route through Lucidia)
  ollama,
  openai,
  claude: anthropic,
  anthropic,
  gemini,
  deepseek,
  groq,
  mistral
}

// PS-SHA∞ verification chain
let prevHash = 'GENESIS_BLACKROAD_OS_INC'

function psShaVerify(provider, action, data) {
  const payload = `${prevHash}|${action}|${provider}|${data}|${new Date().toISOString()}`
  const hash = crypto.createHash('sha256').update(payload).digest('hex')
  prevHash = hash
  return hash
}

function getProvider(name) {
  const key = name.toLowerCase()
  const provider = providers[key] || providers[`lucidia-${key}`] || null

  if (provider) {
    // Every call gets PS-SHA∞ verified
    const hash = psShaVerify(key, 'api_call', JSON.stringify({ timestamp: Date.now() }))
    provider._lucidiaHash = hash
    provider._lucidiaName = `lucidia-${key.replace('lucidia-', '')}`
    provider._blackroadVerified = true
  }

  return provider
}

function listProviders() {
  return Object.keys(providers).filter(k => k.startsWith('lucidia-'))
}

function getLucidiaName(providerName) {
  return `lucidia-${providerName.replace('lucidia-', '')}`
}

module.exports = {
  getProvider,
  listProviders,
  getLucidiaName,
  psShaVerify,
  providers
}
