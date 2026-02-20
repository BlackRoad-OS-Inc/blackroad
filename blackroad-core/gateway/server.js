'use strict'

const http = require('http')
const { randomUUID } = require('crypto')
const fs = require('fs/promises')
const path = require('path')
const { getProvider } = require('./providers')

const DEFAULT_CONFIG = {
  bind: '127.0.0.1',
  port: 8787,
  policyPath: path.join(__dirname, '..', 'policies', 'agent-permissions.json'),
  promptPath: path.join(__dirname, 'system-prompts.json'),
  logPath: path.join(__dirname, 'logs', 'gateway.jsonl'),
  maxBodyBytes: 1024 * 1024
}

async function loadJson(filePath) {
  try {
    const data = await fs.readFile(filePath, 'utf8')
    return JSON.parse(data)
  } catch (error) {
    if (error.code === 'ENOENT') {
      return null
    }
    throw error
  }
}

function readEnvConfig() {
  const env = process.env
  return {
    bind: env.BLACKROAD_GATEWAY_BIND || undefined,
    port: env.BLACKROAD_GATEWAY_PORT ? Number(env.BLACKROAD_GATEWAY_PORT) : undefined,
    policyPath: env.BLACKROAD_GATEWAY_POLICY_PATH || undefined,
    promptPath: env.BLACKROAD_GATEWAY_PROMPT_PATH || undefined,
    logPath: env.BLACKROAD_GATEWAY_LOG_PATH || undefined,
    maxBodyBytes: env.BLACKROAD_GATEWAY_MAX_BODY_BYTES
      ? Number(env.BLACKROAD_GATEWAY_MAX_BODY_BYTES)
      : undefined,
    allowRemote: env.BLACKROAD_GATEWAY_ALLOW_REMOTE === 'true'
  }
}

function mergeConfig(base, extra) {
  return {
    bind: extra.bind || base.bind,
    port: Number.isFinite(extra.port) ? extra.port : base.port,
    policyPath: extra.policyPath || base.policyPath,
    promptPath: extra.promptPath || base.promptPath,
    logPath: extra.logPath || base.logPath,
    maxBodyBytes: Number.isFinite(extra.maxBodyBytes) ? extra.maxBodyBytes : base.maxBodyBytes,
    allowRemote: typeof extra.allowRemote === 'boolean' ? extra.allowRemote : base.allowRemote
  }
}

function isLoopback(req) {
  const address = req.socket.remoteAddress || ''
  return (
    address === '127.0.0.1' ||
    address === '::1' ||
    address.startsWith('::ffff:127.')
  )
}

function buildSystemPrompt(prompts, agent, intent, context) {
  if (!prompts) {
    return ''
  }

  const parts = []
  if (typeof prompts.default === 'string' && prompts.default.trim()) {
    parts.push(prompts.default.trim())
  }
  if (prompts.agents && typeof prompts.agents[agent] === 'string') {
    parts.push(prompts.agents[agent].trim())
  }
  if (prompts.intents && typeof prompts.intents[intent] === 'string') {
    parts.push(prompts.intents[intent].trim())
  }
  if (context && Object.keys(context).length > 0) {
    parts.push(`Context JSON:\n${JSON.stringify(context)}`)
  }

  return parts.join('\n\n')
}

async function readBody(req, maxBytes) {
  return await new Promise((resolve, reject) => {
    let body = ''
    let bytes = 0
    req.on('data', (chunk) => {
      bytes += chunk.length
      if (bytes > maxBytes) {
        reject(new Error('Request body too large'))
        req.destroy()
        return
      }
      body += chunk
    })
    req.on('end', () => resolve(body))
    req.on('error', reject)
  })
}

async function appendLog(logPath, entry) {
  const logDir = path.dirname(logPath)
  await fs.mkdir(logDir, { recursive: true })
  await fs.appendFile(logPath, `${JSON.stringify(entry)}\n`, 'utf8')
}

function pickProvider(requested, policy, intent) {
  if (requested) {
    return requested
  }
  if (policy.intent_routes && policy.intent_routes[intent]) {
    return policy.intent_routes[intent]
  }
  return policy.default_provider || null
}

async function loadPolicy(policyPath) {
  const policy = await loadJson(policyPath)
  if (!policy || !policy.agents) {
    throw new Error('Policy file missing or invalid')
  }
  return policy
}

function validateRequest(payload) {
  if (!payload || typeof payload !== 'object') {
    return 'Invalid JSON payload'
  }
  if (!payload.agent || typeof payload.agent !== 'string') {
    return 'Missing agent'
  }
  if (!payload.intent || typeof payload.intent !== 'string') {
    return 'Missing intent'
  }
  if (typeof payload.input !== 'string') {
    return 'Missing input'
  }
  if (payload.context && typeof payload.context !== 'object') {
    return 'Context must be an object'
  }
  return null
}

async function start() {
  const configFilePath = process.env.BLACKROAD_GATEWAY_CONFIG
    ? path.resolve(process.env.BLACKROAD_GATEWAY_CONFIG)
    : path.join(__dirname, 'config.json')
  const fileConfig = (await loadJson(configFilePath)) || {}
  const config = mergeConfig(DEFAULT_CONFIG, mergeConfig(fileConfig, readEnvConfig()))

  const server = http.createServer(async (req, res) => {
    const startTime = Date.now()
    const requestId = randomUUID()
    let agentName = null
    let intent = null
    let providerName = null
    let status = 'error'
    let responsePayload = null
    let requestPayload = null

    const send = (code, payload) => {
      if (payload.status === 'error' && typeof payload.output !== 'string') {
        payload.output = ''
      }
      responsePayload = payload
      status = payload.status || status
      res.writeHead(code, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify(payload))
    }

    try {
      if (req.method === 'GET' && req.url === '/healthz') {
        return send(200, { status: 'ok' })
      }

      if (req.method !== 'POST' || req.url !== '/v1/agent') {
        return send(404, { status: 'error', error: 'Not found', request_id: requestId })
      }

      if (!config.allowRemote && !isLoopback(req)) {
        return send(403, {
          status: 'error',
          error: 'Remote access denied',
          request_id: requestId
        })
      }

      const body = await readBody(req, config.maxBodyBytes)
      let payload
      try {
        payload = JSON.parse(body)
      } catch (error) {
        return send(400, { status: 'error', error: 'Invalid JSON', request_id: requestId })
      }

      const validationError = validateRequest(payload)
      if (validationError) {
        return send(400, { status: 'error', error: validationError, request_id: requestId })
      }

      requestPayload = payload
      agentName = payload.agent
      intent = payload.intent
      const policy = await loadPolicy(config.policyPath)
      const agentPolicy = policy.agents[agentName]
      if (!agentPolicy) {
        return send(403, { status: 'error', error: 'Agent not allowed', request_id: requestId })
      }

      if (!agentPolicy.allowed_intents || !agentPolicy.allowed_intents.includes(intent)) {
        return send(403, { status: 'error', error: 'Intent not allowed', request_id: requestId })
      }

      if (
        agentPolicy.max_input_bytes &&
        Buffer.byteLength(payload.input, 'utf8') > agentPolicy.max_input_bytes
      ) {
        return send(413, { status: 'error', error: 'Input too large', request_id: requestId })
      }

      providerName = pickProvider(payload.provider, agentPolicy, intent)
      if (!providerName) {
        return send(400, {
          status: 'error',
          error: 'Provider not configured',
          request_id: requestId
        })
      }

      if (
        agentPolicy.allowed_providers &&
        !agentPolicy.allowed_providers.includes(providerName)
      ) {
        return send(403, { status: 'error', error: 'Provider not allowed', request_id: requestId })
      }

      const provider = getProvider(providerName)
      if (!provider) {
        return send(400, { status: 'error', error: 'Unknown provider', request_id: requestId })
      }

      const prompts = await loadJson(config.promptPath)
      const systemPrompt = buildSystemPrompt(prompts, agentName, intent, payload.context)
      const output = await provider.invoke({
        input: payload.input,
        system: systemPrompt,
        context: payload.context || {},
        requestId,
        agent: agentName,
        intent
      })

      status = 'ok'
      responsePayload = {
        status,
        provider: providerName,
        output,
        request_id: requestId,
        metadata: {
          latency_ms: Date.now() - startTime
        }
      }
      return send(200, responsePayload)
    } catch (error) {
      responsePayload = {
        status: 'error',
        error: error.message || 'Gateway error',
        request_id: requestId,
        metadata: { latency_ms: Date.now() - startTime }
      }
      if (providerName) {
        responsePayload.provider = providerName
      }
      return send(500, responsePayload)
    } finally {
      const requestLog = requestPayload
        ? {
            agent: requestPayload.agent,
            intent: requestPayload.intent,
            provider: requestPayload.provider || null,
            input: requestPayload.input,
            context: requestPayload.context || {},
            input_bytes: Buffer.byteLength(requestPayload.input || '', 'utf8')
          }
        : null
      const logEntry = {
        timestamp: new Date().toISOString(),
        request_id: requestId,
        agent: agentName,
        intent,
        provider: providerName,
        status,
        request: requestLog,
        response: responsePayload,
        remote_address: req.socket.remoteAddress || null
      }
      try {
        await appendLog(config.logPath, logEntry)
      } catch (error) {
      }
    }
  })

  server.listen(config.port, config.bind, () => {
    console.log(`BlackRoad Gateway listening on ${config.bind}:${config.port}`)
  })
}

start().catch((error) => {
  console.error('Failed to start gateway', error)
  process.exit(1)
})
