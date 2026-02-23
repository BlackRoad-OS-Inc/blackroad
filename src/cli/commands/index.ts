// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { statusCommand } from './status.js'
import { agentsCommand } from './agents.js'
import { deployCommand } from './deploy.js'
import { logsCommand } from './logs.js'
import { configCommand } from './config.js'
import { gatewayCommand } from './gateway.js'
import { invokeCommand } from './invoke.js'
import { initCommand } from './init.js'

export const program = new Command()
  .name('br')
  .description('BlackRoad OS operator CLI')
  .version('0.1.0')

program.addCommand(statusCommand)
program.addCommand(agentsCommand)
program.addCommand(deployCommand)
program.addCommand(logsCommand)
program.addCommand(configCommand)
program.addCommand(gatewayCommand)
program.addCommand(invokeCommand)
program.addCommand(initCommand)
