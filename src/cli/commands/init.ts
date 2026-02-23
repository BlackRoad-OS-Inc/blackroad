// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { logger } from '../../core/logger.js'

export const initCommand = new Command('init')
  .description('Initialize a new BlackRoad project')
  .argument('[name]', 'Project name')
  .action((name?: string) => {
    const projectName = name ?? 'blackroad-project'
    logger.info(`Initializing project: ${projectName}`)
    logger.warn('Project scaffolding not yet implemented.')
    logger.info('For now, clone a template from BlackRoad-OS-Inc.')
  })
