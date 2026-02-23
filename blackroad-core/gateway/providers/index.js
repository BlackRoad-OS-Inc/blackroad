'use strict'

const ollama = require('./ollama')
const openai = require('./openai')
const anthropic = require('./anthropic')
const gemini = require('./gemini')
const deepseek = require('./deepseek')
const groq = require('./groq')
const mistral = require('./mistral')

const providers = {
  ollama,
  openai,
  claude: anthropic,
  anthropic,
  gemini,
  deepseek,
  groq
}

function getProvider(name) {
  return providers[name.toLowerCase()] || null
}

function listProviders() {
  return Object.keys(providers)
}

module.exports = {
  getProvider,
  listProviders
}
