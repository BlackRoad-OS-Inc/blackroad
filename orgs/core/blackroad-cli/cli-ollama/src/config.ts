import fs from 'node:fs/promises'
import path from 'node:path'
import { fileExists } from './io.js'
import type { BlackroadConfig, OrchestratorMode } from './types.js'

const DEFAULT_CONFIG_NAME = 'blackroad.config.json'

export function defaultConfig(): BlackroadConfig {
  return {
    ollama: {
      host: process.env.OLLAMA_HOST ?? 'http://localhost:11434'
    },
    orchestrator: {
      mode: 'parallel'
    },
    agents: [
      {
        name: 'alpha',
        model: 'llama3.1:8b',
        system: 'You are Alpha, a strategic agent. Be concise and action oriented.'
      },
      {
        name: 'beta',
        model: 'llama3.1:8b',
        system: 'You are Beta, a builder. Provide implementation steps and details.'
      },
      {
        name: 'gamma',
        model: 'llama3.1:8b',
        system: 'You are Gamma, a skeptic. Call out risks, gaps, and tests.'
      }
    ],
    ui: {
      prefixStyle: 'brackets'
    }
  }
}

export function resolveConfigPath(explicitPath?: string): string {
  const rawPath = explicitPath ?? process.env.BLACKROAD_CONFIG ?? DEFAULT_CONFIG_NAME
  return path.resolve(process.cwd(), rawPath)
}

export async function loadConfig(explicitPath?: string): Promise<BlackroadConfig> {
  const configPath = resolveConfigPath(explicitPath)
  const hasExplicit = Boolean(explicitPath || process.env.BLACKROAD_CONFIG)
  const exists = await fileExists(configPath)

  if (!exists) {
    if (hasExplicit) {
      throw new Error(`Config file not found: ${configPath}`)
    }
    return defaultConfig()
  }

  const raw = await fs.readFile(configPath, 'utf8')
  let parsed: Partial<BlackroadConfig>
  try {
    parsed = JSON.parse(raw) as Partial<BlackroadConfig>
  } catch (err) {
    throw new Error(`Invalid JSON in config: ${configPath}`)
  }

  const merged = mergeConfig(defaultConfig(), parsed)
  validateConfig(merged)
  return merged
}

export async function writeDefaultConfig(filePath: string, force = false): Promise<void> {
  const resolved = path.resolve(process.cwd(), filePath)
  const exists = await fileExists(resolved)

  if (exists && !force) {
    throw new Error(`Config file already exists: ${resolved}`)
  }

  const data = JSON.stringify(defaultConfig(), null, 2) + '\n'
  await fs.mkdir(path.dirname(resolved), { recursive: true })
  await fs.writeFile(resolved, data, 'utf8')
}

function mergeConfig(base: BlackroadConfig, override: Partial<BlackroadConfig>): BlackroadConfig {
  const mergedAgents =
    Array.isArray(override.agents) && override.agents.length > 0
      ? override.agents
      : base.agents

  return {
    ...base,
    ...override,
    ollama: {
      ...base.ollama,
      ...(override.ollama ?? {})
    },
    orchestrator: {
      ...base.orchestrator,
      ...(override.orchestrator ?? {})
    },
    agents: mergedAgents,
    ui: {
      ...base.ui,
      ...(override.ui ?? {})
    }
  }
}

function validateConfig(config: BlackroadConfig) {
  if (!config.ollama.host || typeof config.ollama.host !== 'string') {
    throw new Error('Config missing ollama.host')
  }

  if (!config.agents || config.agents.length === 0) {
    throw new Error('Config must define at least one agent')
  }

  const modes: OrchestratorMode[] = ['parallel', 'round']
  if (!modes.includes(config.orchestrator.mode)) {
    throw new Error(`Unsupported orchestrator.mode: ${config.orchestrator.mode}`)
  }

  config.agents.forEach((agent, index) => {
    if (!agent.name) {
      throw new Error(`Agent at index ${index} is missing name`)
    }
    if (!agent.model) {
      throw new Error(`Agent ${agent.name} is missing model`)
    }
  })
}
