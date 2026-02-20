'use strict'

// Tests for BlackRoad Core Gateway v2
// Run: node tests/gateway.test.js

process.env.NODE_ENV = 'test'

const {
  RateLimiter,
  validateRequest,
  pickProvider,
  buildSystemPrompt,
  mergeConfig,
  metrics
} = require('../gateway/server')

let passed = 0
let failed = 0

function assert(condition, msg) {
  if (condition) {
    passed++
    console.log(`  \x1b[32m✓\x1b[0m ${msg}`)
  } else {
    failed++
    console.log(`  \x1b[31m✗\x1b[0m ${msg}`)
  }
}

function assertEqual(actual, expected, msg) {
  assert(actual === expected, `${msg} (got ${JSON.stringify(actual)}, expected ${JSON.stringify(expected)})`)
}

function assertNull(actual, msg) {
  assert(actual === null, `${msg} (got ${JSON.stringify(actual)})`)
}

function suite(name, fn) {
  console.log(`\n\x1b[1m${name}\x1b[0m`)
  fn()
}

// ---------------------------------------------------------------------------
// validateRequest
// ---------------------------------------------------------------------------
suite('validateRequest', () => {
  assertNull(
    validateRequest({ agent: 'planner', intent: 'analyze', input: 'hello' }),
    'accepts valid request'
  )

  assertEqual(
    validateRequest(null),
    'Invalid JSON payload',
    'rejects null'
  )

  assertEqual(
    validateRequest({}),
    'Missing agent',
    'rejects missing agent'
  )

  assertEqual(
    validateRequest({ agent: 'planner' }),
    'Missing intent',
    'rejects missing intent'
  )

  assertEqual(
    validateRequest({ agent: 'planner', intent: 'analyze' }),
    'Missing input',
    'rejects missing input'
  )

  assertEqual(
    validateRequest({ agent: 'planner', intent: 'analyze', input: 'hi', context: 'bad' }),
    'Context must be an object',
    'rejects non-object context'
  )

  assertNull(
    validateRequest({ agent: 'planner', intent: 'analyze', input: 'hi', context: { foo: 1 } }),
    'accepts valid context object'
  )
})

// ---------------------------------------------------------------------------
// pickProvider
// ---------------------------------------------------------------------------
suite('pickProvider', () => {
  const policy = {
    default_provider: 'ollama',
    intent_routes: {
      analyze: 'ollama',
      plan: 'claude'
    }
  }

  assertEqual(
    pickProvider('openai', policy, 'analyze'),
    'openai',
    'explicit provider takes priority'
  )

  assertEqual(
    pickProvider(null, policy, 'plan'),
    'claude',
    'uses intent route when no explicit provider'
  )

  assertEqual(
    pickProvider(null, policy, 'analyze'),
    'ollama',
    'uses intent route for analyze'
  )

  assertEqual(
    pickProvider(null, policy, 'unknown'),
    'ollama',
    'falls back to default provider for unknown intent'
  )

  assertEqual(
    pickProvider(null, { intent_routes: {} }, 'anything'),
    null,
    'returns null when no default provider'
  )
})

// ---------------------------------------------------------------------------
// buildSystemPrompt
// ---------------------------------------------------------------------------
suite('buildSystemPrompt', () => {
  const prompts = {
    default: 'You are a BlackRoad agent.',
    agents: {
      planner: 'You plan things.',
      octavia: 'You architect systems.'
    },
    intents: {
      analyze: 'Analyze carefully.',
      plan: 'Create phased plans.'
    }
  }

  const result = buildSystemPrompt(prompts, 'planner', 'analyze', null)
  assert(result.includes('BlackRoad agent'), 'includes default prompt')
  assert(result.includes('plan things'), 'includes agent prompt')
  assert(result.includes('Analyze carefully'), 'includes intent prompt')

  const withContext = buildSystemPrompt(prompts, 'planner', 'analyze', { phase: 'Q1' })
  assert(withContext.includes('Context JSON'), 'includes context')
  assert(withContext.includes('"phase"'), 'includes context data')

  assertEqual(
    buildSystemPrompt(null, 'planner', 'analyze', null),
    '',
    'returns empty string when no prompts'
  )

  const unknownAgent = buildSystemPrompt(prompts, 'unknown', 'unknown', null)
  assert(unknownAgent.includes('BlackRoad agent'), 'includes default for unknown agent')
  assert(!unknownAgent.includes('plan things'), 'does not include wrong agent prompt')
})

// ---------------------------------------------------------------------------
// RateLimiter
// ---------------------------------------------------------------------------
suite('RateLimiter', () => {
  const limiter = new RateLimiter()

  assert(limiter.check('test-agent', 5), 'allows first request')
  assertEqual(limiter.getUsage('test-agent'), 0, 'usage is 0 before recording')

  limiter.record('test-agent')
  limiter.record('test-agent')
  limiter.record('test-agent')
  assertEqual(limiter.getUsage('test-agent'), 3, 'usage reflects recorded requests')

  assert(limiter.check('test-agent', 5), 'allows when under limit')

  limiter.record('test-agent')
  limiter.record('test-agent')
  assertEqual(limiter.getUsage('test-agent'), 5, 'usage at limit')
  assert(!limiter.check('test-agent', 5), 'rejects when at limit')

  assert(limiter.check('test-agent', 0), 'allows when limit is 0 (disabled)')
  assert(limiter.check('other-agent', 10), 'allows other agents independently')
})

// ---------------------------------------------------------------------------
// mergeConfig
// ---------------------------------------------------------------------------
suite('mergeConfig', () => {
  const base = {
    bind: '127.0.0.1',
    port: 8787,
    policyPath: '/default/policy.json',
    promptPath: '/default/prompts.json',
    logPath: '/default/logs/gateway.jsonl',
    maxBodyBytes: 1048576,
    allowRemote: false
  }

  const result = mergeConfig(base, { port: 9000 })
  assertEqual(result.port, 9000, 'overrides port')
  assertEqual(result.bind, '127.0.0.1', 'preserves bind')

  const remoteResult = mergeConfig(base, { allowRemote: true })
  assertEqual(remoteResult.allowRemote, true, 'overrides allowRemote')

  const noOverride = mergeConfig(base, {})
  assertEqual(noOverride.port, 8787, 'preserves defaults when no override')
})

// ---------------------------------------------------------------------------
// Metrics
// ---------------------------------------------------------------------------
suite('Metrics', () => {
  // Reset metrics for clean test
  metrics.totalRequests = 0
  metrics.totalErrors = 0
  metrics.totalOk = 0
  metrics.byAgent = {}
  metrics.byProvider = {}

  metrics.record('planner', 'ollama', 'ok')
  metrics.record('planner', 'claude', 'ok')
  metrics.record('octavia', 'claude', 'error')

  const snap = metrics.snapshot()
  assertEqual(snap.total_requests, 3, 'tracks total requests')
  assertEqual(snap.total_ok, 2, 'tracks ok responses')
  assertEqual(snap.total_errors, 1, 'tracks errors')
  assertEqual(snap.by_agent.planner, 2, 'tracks by agent')
  assertEqual(snap.by_agent.octavia, 1, 'tracks octavia')
  assertEqual(snap.by_provider.ollama, 1, 'tracks ollama')
  assertEqual(snap.by_provider.claude, 2, 'tracks claude')
  assert(snap.uptime_seconds >= 0, 'reports uptime')
})

// ---------------------------------------------------------------------------
// Provider registry
// ---------------------------------------------------------------------------
suite('Provider registry', () => {
  const { getProvider } = require('../gateway/providers')

  assert(getProvider('ollama') !== null, 'ollama provider exists')
  assert(getProvider('openai') !== null, 'openai provider exists')
  assert(getProvider('claude') !== null, 'claude provider exists')
  assert(getProvider('anthropic') !== null, 'anthropic provider exists')
  assert(getProvider('gemini') !== null, 'gemini provider exists')
  assertNull(getProvider('nonexistent'), 'returns null for unknown provider')

  assert(typeof getProvider('ollama').invoke === 'function', 'ollama has invoke')
  assert(typeof getProvider('gemini').invoke === 'function', 'gemini has invoke')
})

// ---------------------------------------------------------------------------
// Policy structure validation
// ---------------------------------------------------------------------------
suite('Policy file structure', () => {
  const policy = require('../policies/agent-permissions.json')

  assertEqual(policy.version, 2, 'policy version is 2')
  assert(policy.global !== undefined, 'has global config')
  assert(policy.global.rate_limit_per_minute > 0, 'has global rate limit')

  const expectedAgents = ['planner', 'octavia', 'lucidia', 'alice', 'cipher', 'prism']
  for (const name of expectedAgents) {
    assert(policy.agents[name] !== undefined, `has ${name} agent`)
    assert(Array.isArray(policy.agents[name].allowed_intents), `${name} has allowed_intents`)
    assert(Array.isArray(policy.agents[name].allowed_providers), `${name} has allowed_providers`)
    assert(typeof policy.agents[name].default_provider === 'string', `${name} has default_provider`)
    assert(Array.isArray(policy.agents[name].fallback_chain), `${name} has fallback_chain`)
    assert(policy.agents[name].max_input_bytes > 0, `${name} has max_input_bytes`)
  }

  assert(policy.cost_tiers !== undefined, 'has cost tiers')
  assert(policy.cost_tiers.standard !== undefined, 'has standard tier')
  assert(policy.cost_tiers.premium !== undefined, 'has premium tier')
})

// ---------------------------------------------------------------------------
// System prompts structure
// ---------------------------------------------------------------------------
suite('System prompts structure', () => {
  const prompts = require('../gateway/system-prompts.json')

  assert(typeof prompts.default === 'string', 'has default prompt')
  assert(prompts.default.length > 20, 'default prompt is substantial')

  const expectedAgents = ['planner', 'octavia', 'lucidia', 'alice', 'cipher', 'prism']
  for (const name of expectedAgents) {
    assert(typeof prompts.agents[name] === 'string', `has ${name} agent prompt`)
    assert(prompts.agents[name].length > 50, `${name} prompt is substantial`)
  }

  const expectedIntents = [
    'analyze', 'plan', 'architect', 'review', 'optimize', 'diagnose',
    'vision', 'synthesize', 'mentor', 'explore',
    'deploy', 'automate', 'route', 'monitor',
    'audit', 'harden', 'scan', 'encrypt',
    'correlate', 'report', 'forecast'
  ]
  for (const intent of expectedIntents) {
    assert(typeof prompts.intents[intent] === 'string', `has ${intent} intent prompt`)
  }
})

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log(`\n${'='.repeat(50)}`)
console.log(`\x1b[1mResults: ${passed} passed, ${failed} failed\x1b[0m`)
console.log(`${'='.repeat(50)}`)
process.exit(failed > 0 ? 1 : 0)
