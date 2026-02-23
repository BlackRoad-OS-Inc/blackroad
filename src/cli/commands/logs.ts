// Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
import { Command } from 'commander'
import { logger } from '../../core/logger.js'

export const logsCommand = new Command('logs')
  .description('Tail gateway logs')
  .option('-n <lines>', 'Number of lines', '50')
  .action((opts: { n: string }) => {
    logger.info(`Tailing last ${opts.n} log lines...`)
    logger.warn('Log tailing not yet implemented. Use wrangler tail or railway logs.')
  })
