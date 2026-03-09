import { watch } from 'chokidar'
import { execSync } from 'child_process'
import { existsSync } from 'fs'
import { join, homedir } from 'path'

export interface CodexEvent {
  type: 'codex-search' | 'codex-discovery' | 'codex-index'
  timestamp: string
  query?: string
  results?: number
  component?: string
  metadata: {
    totalComponents?: number
    searchTime?: number
  }
}

export class CodexAdapter {
  private codexPath: string
  private searchScript: string
  
  constructor() {
    this.codexPath = join(homedir(), 'blackroad-codex')
    this.searchScript = join(homedir(), 'blackroad-codex-search.py')
  }
  
  async start(callback: (event: CodexEvent) => void) {
    console.log('[Codex] Starting Codex adapter...')
    
    if (!existsSync(this.codexPath)) {
      console.log('[Codex] Codex directory not found, skipping')
      return
    }
    
    // Get total component count
    try {
      const result = execSync(`find "${this.codexPath}" -name "*.json" | wc -l`, { encoding: 'utf-8' })
      const count = parseInt(result.trim())
      
      callback({
        type: 'codex-index',
        timestamp: new Date().toISOString(),
        metadata: {
          totalComponents: count
        }
      })
      
      console.log(`[Codex] Indexed ${count} components`)
    } catch (err) {
      console.error('[Codex] Failed to count components:', err)
    }
    
    // Watch for codex searches (if search script exists)
    if (existsSync(this.searchScript)) {
      console.log('[Codex] Watching for search activity...')
    }
  }
  
  async search(query: string): Promise<CodexEvent> {
    const startTime = Date.now()
    
    try {
      const result = execSync(`python3 "${this.searchScript}" "${query}" | wc -l`, { 
        encoding: 'utf-8',
        timeout: 5000
      })
      
      const results = parseInt(result.trim())
      const searchTime = Date.now() - startTime
      
      return {
        type: 'codex-search',
        timestamp: new Date().toISOString(),
        query,
        results,
        metadata: {
          searchTime
        }
      }
    } catch (err) {
      return {
        type: 'codex-search',
        timestamp: new Date().toISOString(),
        query,
        results: 0,
        metadata: {
          searchTime: Date.now() - startTime
        }
      }
    }
  }
}
