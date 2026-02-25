#!/usr/bin/env node
import path from 'node:path'
import { loadConfig, writeDefaultConfig } from './config.js'
import { readStdin } from './io.js'
import { runPrompt } from './orchestrator.js'
import type { BlackroadConfig, OrchestratorMode } from './types.js'

type RunOverrides = {
  configPath?: string
  mode?: OrchestratorMode
  model?: string
  agents?: number
}

type ConfigInitOptions = {
  path: string
  force: boolean
}

const argv = process.argv.slice(2)

try {
  await main(argv)
} catch (err) {
  const message = err instanceof Error ? err.message : String(err)
  console.error(`Error: ${message}`)
  process.exit(1)
}

async function main(args: string[]) {
  if (args.length === 0 || args.includes('-h') || args.includes('--help')) {
    printHelp()
    return
  }

  const [command, ...rest] = args

  if (command === 'help') {
    printHelp()
    return
  }

  if (command === 'config' && rest[0] === 'init') {
    const options = parseConfigInitArgs(rest.slice(1))
    await writeDefaultConfig(options.path, options.force)
    const resolved = path.resolve(process.cwd(), options.path)
    console.log(`Wrote config: ${resolved}`)
    return
  }

  if (command === 'run') {
    await handleRun(rest)
    return
  }

  await handleRun(args)
}

async function handleRun(args: string[]) {
  const parsed = parseRunArgs(args)
  if (parsed.help) {
    printHelp()
    return
  }

  let prompt = parsed.prompt
  if (!prompt && !process.stdin.isTTY) {
    prompt = (await readStdin()).trim()
  }

  if (!prompt) {
    throw new Error('Missing prompt. Provide a prompt or pipe input via stdin.')
  }

  const config = applyOverrides(await loadConfig(parsed.configPath), parsed)
  await runPrompt(config, prompt)
}

function parseRunArgs(args: string[]) {
  let configPath: string | undefined
  let mode: OrchestratorMode | undefined
  let model: string | undefined
  let agents: number | undefined
  let help = false
  const promptParts: string[] = []

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i]
    if (arg === undefined) continue
    if (arg === '--') {
      promptParts.push(...args.slice(i + 1))
      break
    }

    if (arg === '-h' || arg === '--help') {
      help = true
      continue
    }

    if (arg === '--config') {
      const value = args[i + 1]
      if (!value) throw new Error('Missing value for --config')
      configPath = value
      i += 1
      continue
    }

    if (arg === '--mode') {
      const value = args[i + 1]
      if (!value) throw new Error('Missing value for --mode')
      if (value !== 'parallel' && value !== 'round') {
        throw new Error(`Invalid mode: ${value}`)
      }
      mode = value
      i += 1
      continue
    }

    if (arg === '--model') {
      const value = args[i + 1]
      if (!value) throw new Error('Missing value for --model')
      model = value
      i += 1
      continue
    }

    if (arg === '--agents') {
      const value = args[i + 1]
      if (!value) throw new Error('Missing value for --agents')
      const parsedValue = Number.parseInt(value, 10)
      if (!Number.isFinite(parsedValue) || parsedValue <= 0) {
        throw new Error(`Invalid agent count: ${value}`)
      }
      agents = parsedValue
      i += 1
      continue
    }

    if (arg.startsWith('-')) {
      throw new Error(`Unknown option: ${arg}`)
    }

    promptParts.push(arg)
  }

  const result: RunOverrides & { help: boolean; prompt: string } = {
    help,
    prompt: promptParts.join(' ').trim()
  }

  if (configPath) result.configPath = configPath
  if (mode) result.mode = mode
  if (model) result.model = model
  if (typeof agents === 'number') result.agents = agents

  return result
}

function parseConfigInitArgs(args: string[]): ConfigInitOptions {
  let targetPath = 'blackroad.config.json'
  let force = false

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i]
    if (arg === undefined) continue
    if (arg === '--path') {
      const value = args[i + 1]
      if (!value) throw new Error('Missing value for --path')
      targetPath = value
      i += 1
      continue
    }

    if (arg === '--force') {
      force = true
      continue
    }

    if (arg.startsWith('-')) {
      throw new Error(`Unknown option: ${arg}`)
    }
  }

  return { path: targetPath, force }
}

function applyOverrides(config: BlackroadConfig, overrides: RunOverrides): BlackroadConfig {
  const updated: BlackroadConfig = {
    ...config,
    orchestrator: { ...config.orchestrator },
    agents: config.agents.map(agent => ({ ...agent }))
  }

  if (config.ui) {
    updated.ui = { ...config.ui }
  }

  if (overrides.mode) {
    updated.orchestrator.mode = overrides.mode
  }

  if (overrides.model) {
    updated.agents = updated.agents.map(agent => ({
      ...agent,
      model: overrides.model as string
    }))
  }

  if (typeof overrides.agents === 'number') {
    const modelFallback =
      overrides.model ?? updated.agents[0]?.model ?? 'llama3.1:8b'
    updated.agents = resizeAgents(updated.agents, overrides.agents, modelFallback)
  }

  return updated
}

function resizeAgents(
  agents: BlackroadConfig['agents'],
  count: number,
  modelFallback: string
) {
  const trimmed = agents.slice(0, count).map(agent => ({ ...agent }))
  if (trimmed.length === count) return trimmed

  const expanded = [...trimmed]
  for (let i = trimmed.length; i < count; i += 1) {
    expanded.push({
      name: `agent-${i + 1}`,
      model: modelFallback
    })
  }

  return expanded
}

function printHelp() {
  console.log(`Blackroad CLI (Ollama)

Usage:
  blackroad run [options] <prompt>
  blackroad <prompt>
  blackroad config init [--path <file>] [--force]

Options:
  --config <file>       Path to config (default: ./blackroad.config.json)
  --mode <parallel|round>
  --agents <number>     Override agent count
  --model <name>        Override model for all agents
  -h, --help            Show help

Examples:
  blackroad run "Draft a product launch brief"
  blackroad --mode round "Review this plan"
  blackroad --agents 2 --model llama3.1:8b "Pair program a fix"
  blackroad config init --path ./blackroad.config.json
`)
}
