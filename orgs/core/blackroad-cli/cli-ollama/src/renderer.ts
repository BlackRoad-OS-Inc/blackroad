import type { UiConfig } from './types.js'

type RenderState = {
  atLineStart: boolean
}

export class Renderer {
  private states = new Map<string, RenderState>()
  private prefixStyle: UiConfig['prefixStyle']

  constructor(ui?: UiConfig) {
    this.prefixStyle = ui?.prefixStyle ?? 'brackets'
  }

  write(agentName: string, text: string) {
    if (!text) return

    const state = this.getState(agentName)
    const parts = text.split('\n')
    const prefix = this.formatPrefix(agentName)

    parts.forEach((part, index) => {
      if (part.length > 0) {
        if (state.atLineStart) {
          process.stdout.write(prefix)
        }
        process.stdout.write(part)
        state.atLineStart = false
      }

      if (index < parts.length - 1) {
        process.stdout.write('\n')
        state.atLineStart = true
      }
    })
  }

  finalize(agentName: string) {
    const state = this.getState(agentName)
    if (!state.atLineStart) {
      process.stdout.write('\n')
      state.atLineStart = true
    }
  }

  private formatPrefix(agentName: string) {
    if (this.prefixStyle === 'brackets') {
      return `[${agentName}] `
    }

    return `${agentName}: `
  }

  private getState(agentName: string): RenderState {
    const existing = this.states.get(agentName)
    if (existing) return existing

    const state = { atLineStart: true }
    this.states.set(agentName, state)
    return state
  }
}
