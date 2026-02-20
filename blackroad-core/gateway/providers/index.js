'use strict'

const ollama = require('./ollama')
const openai = require('./openai')
const anthropic = require('./anthropic')

const providers = {
  ollama,
  openai,
  claude: anthropic
}

function getProvider(name) {
  return providers[name] || null
}

module.exports = {
  getProvider
}
