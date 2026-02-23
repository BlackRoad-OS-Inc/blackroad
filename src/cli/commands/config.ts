// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { loadConfig } from '../../core/config.js'
import { logger } from '../../core/logger.js'

export const configCommand = new Command('config')
  .description('View or set configuration')
  .argument('[key]', 'Config key to get')
  .argument('[value]', 'Config value to set')
  .action((key?: string, value?: string) => {
    const config = loadConfig()
    if (!key) {
      console.log(JSON.stringify(config.store, null, 2))
      return
    }
    if (value) {
      config.set(key, value)
      logger.success(`Set ${key} = ${value}`)
    } else {
      const val = config.get(key)
      if (val !== undefined) {
        console.log(val)
      } else {
        logger.warn(`Key "${key}" not found.`)
      }
    }
  })
