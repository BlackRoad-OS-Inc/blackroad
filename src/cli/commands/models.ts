// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { GatewayClient } from '../../core/client.js'
import { logger } from '../../core/logger.js'
import chalk from 'chalk'

interface NodeModels {
  node: string
  status: string
  models: string[]
}

export const modelsCommand = new Command('models')
  .description('List all models across the fleet')
  .option('--json', 'Output as JSON')
  .action(async (opts: { json?: boolean }) => {
    const client = new GatewayClient()
    try {
      const data = await client.get<{ nodes: NodeModels[] }>('/v1/models')
      if (opts.json) {
        console.log(JSON.stringify(data.nodes, null, 2))
        return
      }
      let totalModels = 0
      for (const node of data.nodes) {
        const status = node.status === 'up'
          ? chalk.green('UP')
          : chalk.red('DOWN')
        console.log(`${status}  ${chalk.bold(node.node)} — ${node.models.length} models`)
        for (const model of node.models) {
          console.log(`     ${chalk.gray(model)}`)
          totalModels++
        }
      }
      console.log(`\n${chalk.cyan(String(totalModels))} models across ${chalk.cyan(String(data.nodes.length))} nodes`)
    } catch {
      logger.error('Failed to fetch models from gateway.')
    }
  })
