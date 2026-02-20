'use strict'

const ollama = require('./ollama')
const openai = require('./openai')
const anthropic = require('./anthropic')
const gemini = require('./gemini')

const providers = {
  ollama,
  openai,
  claude: anthropic,
  anthropic,
  gemini
}

function getProvider(name) {
  return providers[name] || null
}

module.exports = {
  getProvider
}
