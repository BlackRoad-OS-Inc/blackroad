import { watch } from 'chokidar'
import { readFileSync, readdirSync, existsSync } from 'fs'
import { join } from 'path'
import { homedir } from 'os'

export interface BlackRoadMemoryEvent {
  type: 'memory-write' | 'agent-init' | 'agent-activity' | 'codex-search'
  timestamp: string
  agent: {
    id: string
    name: string
    role: string
  }
  data: any
  metadata: {
    sessionId?: string
    tags?: string[]
    action?: string
  }
}

export class BlackRoadMemoryAdapter {
  private memoryPath: string
  private activeAgentsPath: string
  private watcher: any
  
  constructor() {
    this.memoryPath = join(homedir(), '.blackroad', 'memory', 'journals')
    this.activeAgentsPath = join(homedir(), '.blackroad', 'memory', 'active-agents')
  }
  
  async start(callback: (event: BlackRoadMemoryEvent) => void) {
    console.log('[BlackRoad Memory] Starting memory system adapter...')
    
    // Load active agents
    if (existsSync(this.activeAgentsPath)) {
      const agents = this.loadActiveAgents()
      console.log(`[BlackRoad Memory] Found ${agents.length} active agents`)
      
      agents.forEach(agent => {
        callback({
          type: 'agent-init',
          timestamp: new Date().toISOString(),
          agent,
          data: { status: 'active', capabilities: agent.capabilities || [] },
          metadata: { tags: ['initialization'] }
        })
      })
    }
    
    // Watch memory journals
    if (existsSync(this.memoryPath)) {
      this.watcher = watch(join(this.memoryPath, '*.jsonl'), {
        persistent: true,
        ignoreInitial: false
      })
      
      this.watcher.on('change', (path: string) => {
        const lastEntry = this.readLastJournalEntry(path)
        if (lastEntry) {
          callback({
            type: 'memory-write',
            timestamp: lastEntry.timestamp || new Date().toISOString(),
            agent: lastEntry.agent || { id: 'system', name: 'System', role: 'memory' },
            data: lastEntry,
            metadata: {
              tags: lastEntry.tags || [],
              action: lastEntry.action
            }
          })
        }
      })
      
      console.log('[BlackRoad Memory] Watching journal files...')
    }
    
    // Watch active agents directory
    if (existsSync(this.activeAgentsPath)) {
      watch(join(this.activeAgentsPath, '*.json'), {
        persistent: true
      }).on('add', (path: string) => {
        const agent = this.loadAgentFile(path)
        if (agent) {
          callback({
            type: 'agent-activity',
            timestamp: new Date().toISOString(),
            agent,
            data: { event: 'agent-online' },
            metadata: { tags: ['agent', 'online'] }
          })
        }
      })
    }
  }
  
  private loadActiveAgents() {
    if (!existsSync(this.activeAgentsPath)) return []
    
    const agents = []
    const files = readdirSync(this.activeAgentsPath)
    
    for (const file of files) {
      if (file.endsWith('.json')) {
        const agent = this.loadAgentFile(join(this.activeAgentsPath, file))
        if (agent) agents.push(agent)
      }
    }
    
    return agents
  }
  
  private loadAgentFile(path: string) {
    try {
      const content = readFileSync(path, 'utf-8')
      const data = JSON.parse(content)
      return {
        id: data.agent_id || data.id || 'unknown',
        name: data.name || 'Unknown Agent',
        role: data.role || 'agent',
        capabilities: data.capabilities || []
      }
    } catch (err) {
      return null
    }
  }
  
  private readLastJournalEntry(path: string) {
    try {
      const content = readFileSync(path, 'utf-8')
      const lines = content.trim().split('\n')
      const lastLine = lines[lines.length - 1]
      return JSON.parse(lastLine)
    } catch (err) {
      return null
    }
  }
  
  stop() {
    if (this.watcher) {
      this.watcher.close()
    }
  }
}
