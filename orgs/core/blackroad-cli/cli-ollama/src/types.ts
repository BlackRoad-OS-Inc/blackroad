export type AgentConfig = {
  name: string
  model: string
  system?: string
  temperature?: number
  top_p?: number
}

export type OllamaConfig = {
  host: string
}

export type OrchestratorMode = 'parallel' | 'round'

export type OrchestratorConfig = {
  mode: OrchestratorMode
}

export type UiConfig = {
  prefixStyle?: 'brackets'
}

export type BlackroadConfig = {
  ollama: OllamaConfig
  orchestrator: OrchestratorConfig
  agents: AgentConfig[]
  ui?: UiConfig
}

export type ChatMessage = {
  role: 'system' | 'user' | 'assistant'
  content: string
}
