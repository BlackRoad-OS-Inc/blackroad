// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { GatewayClient } from '../../core/client.js'
import { logger } from '../../core/logger.js'

export const invokeCommand = new Command('invoke')
  .description('Invoke an agent with a task')
  .argument('<agent>', 'Agent name')
  .argument('<task>', 'Task description')
  .action(async (agent: string, task: string) => {
    const client = new GatewayClient()
    try {
      const result = await client.post<{ content: string }>('/v1/invoke', { agent, task })
      console.log(result.content)
    } catch {
      logger.error(`Failed to invoke agent "${agent}".`)
    }
  })
