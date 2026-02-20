// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { GatewayClient } from '../../core/client.js'
import { logger } from '../../core/logger.js'

export const gatewayCommand = new Command('gateway')
  .description('Gateway management')

gatewayCommand
  .command('health')
  .description('Check gateway health')
  .action(async () => {
    const client = new GatewayClient()
    try {
      const health = await client.get<{ status: string; version: string }>('/v1/health')
      logger.success(`Gateway is ${health.status} (v${health.version})`)
    } catch {
      logger.error('Gateway is unreachable.')
    }
  })

gatewayCommand
  .command('url')
  .description('Show gateway URL')
  .action(() => {
    const client = new GatewayClient()
    console.log(client.baseUrl)
  })
