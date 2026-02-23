// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { loadConfig } from '../core/config.js'
import { logger } from '../core/logger.js'

export function runSetup(gatewayUrl?: string): void {
  const config = loadConfig()

  if (gatewayUrl) {
    config.set('gatewayUrl', gatewayUrl)
  }

  logger.success('Configuration saved')
  logger.info(`Gateway URL: ${config.get('gatewayUrl')}`)
  logger.info(`Default agent: ${config.get('defaultAgent')}`)
}
