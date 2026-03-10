// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { GatewayClient } from '../../core/client.js'
import { logger } from '../../core/logger.js'
import chalk from 'chalk'
import * as readline from 'node:readline'

interface ChatMessage {
  role: 'user' | 'assistant' | 'system'
  content: string
}

interface ChatResponse {
  id: string
  content: string
  model: string
  provider: string
  usage: { prompt_tokens: number; completion_tokens: number; total_tokens: number }
}

export const chatCommand = new Command('chat')
  .description('Interactive chat with an agent or model')
  .argument('[agent]', 'Agent name (octavia, lucidia, alice, cipher, prism, planner)')
  .option('-m, --model <model>', 'Override model (e.g. llama3.2:3b, qwen2.5:3b)')
  .action(async (agent: string | undefined, opts: { model?: string }) => {
    const client = new GatewayClient()
    const history: ChatMessage[] = []

    // Verify gateway
    try {
      await client.get('/v1/health')
    } catch {
      logger.error('Gateway unreachable. Run: ~/blackroad-start.sh')
      return
    }

    const label = agent
      ? chalk.hex('#FF1D6C')(agent)
      : chalk.hex('#2979FF')('chat')

    console.log(chalk.hex('#FF1D6C')('BlackRoad OS') + ' — Interactive Chat')
    if (agent) {
      console.log(`Agent: ${chalk.bold(agent)}${opts.model ? ` (model: ${opts.model})` : ''}`)
    } else {
      console.log(`Model: ${chalk.bold(opts.model || 'llama3.2:3b')}`)
    }
    console.log(chalk.gray('Type "exit" or Ctrl+C to quit\n'))

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    })

    const ask = (): void => {
      rl.question(chalk.green('you → '), async (input) => {
        const trimmed = input.trim()
        if (!trimmed || trimmed === 'exit' || trimmed === 'quit') {
          console.log(chalk.gray('\nSession ended.'))
          rl.close()
          return
        }

        history.push({ role: 'user', content: trimmed })

        try {
          let response: ChatResponse

          if (agent) {
            // Use invoke endpoint for agent chat
            const result = await client.post<{ content: string; model?: string }>('/v1/invoke', {
              agent,
              task: trimmed,
              model: opts.model,
            })
            response = {
              id: '',
              content: result.content,
              model: result.model || opts.model || 'unknown',
              provider: 'ollama',
              usage: { prompt_tokens: 0, completion_tokens: 0, total_tokens: 0 },
            }
          } else {
            // Use chat completions
            response = await client.post<ChatResponse>('/v1/chat/completions', {
              model: opts.model || 'llama3.2:3b',
              messages: history,
            })
          }

          history.push({ role: 'assistant', content: response.content })
          console.log(`${label} → ${response.content}`)
          console.log(chalk.gray(`  [${response.model}]\n`))
        } catch (err) {
          logger.error(`Request failed: ${err instanceof Error ? err.message : 'unknown error'}`)
        }

        ask()
      })
    }

    ask()
  })
