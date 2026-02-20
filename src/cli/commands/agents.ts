// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { GatewayClient } from '../../core/client.js'
import { logger } from '../../core/logger.js'
import { formatTable } from '../../formatters/table.js'

interface Agent {
  name: string
  title: string
  role: string
}

export const agentsCommand = new Command('agents')
  .description('List all agents')
  .option('--json', 'Output as JSON')
  .action(async (opts: { json?: boolean }) => {
    const client = new GatewayClient()
    try {
      const data = await client.get<{ agents: Agent[] }>('/v1/agents')
      if (opts.json) {
        console.log(JSON.stringify(data.agents, null, 2))
        return
      }
      console.log(formatTable(
        ['Name', 'Title', 'Role'],
        data.agents.map((a) => [a.name, a.title, a.role]),
      ))
    } catch {
      logger.error('Failed to fetch agents from gateway.')
    }
  })
