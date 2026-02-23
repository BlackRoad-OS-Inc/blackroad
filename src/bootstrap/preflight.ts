// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { GatewayClient } from '../core/client.js'
import { logger } from '../core/logger.js'

export async function runPreflight(): Promise<boolean> {
  const nodeVersion = parseInt(process.versions.node.split('.')[0], 10)
  if (nodeVersion < 22) {
    logger.error(`Node.js 22+ required. Current: ${process.versions.node}`)
    return false
  }
  logger.success(`Node.js ${process.versions.node}`)

  const client = new GatewayClient()
  try {
    await client.get('/v1/health')
    logger.success('Gateway reachable')
  } catch {
    logger.warn('Gateway unreachable (some commands will not work)')
  }

  return true
}
