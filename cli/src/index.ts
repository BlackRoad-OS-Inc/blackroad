#!/usr/bin/env node

import { Command } from 'commander';
import { deployCommand } from './commands/deploy';
import { logsCommand } from './commands/logs';
import { listCommand } from './commands/list';
import { envCommand } from './commands/env';
import { deleteCommand } from './commands/delete';
import { restartCommand } from './commands/restart';
import { loginCommand } from './commands/login';
import { initCommand } from './commands/init';

const program = new Command();

program
  .name('blackroad')
  .description('BlackRoad Deploy - Self-hosted deployment platform')
  .version('1.0.0');

// Commands
program.addCommand(initCommand);
program.addCommand(loginCommand);
program.addCommand(deployCommand);
program.addCommand(logsCommand);
program.addCommand(listCommand);
program.addCommand(envCommand);
program.addCommand(restartCommand);
program.addCommand(deleteCommand);

program.parse();
